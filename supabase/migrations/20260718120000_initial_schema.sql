-- =============================================================================
-- SlotBook P0 — Initial schema + RLS
-- Run in Supabase SQL Editor (or via `supabase db push`)
-- =============================================================================

-- Extensions
create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- Enums
-- -----------------------------------------------------------------------------

create type public.user_role as enum ('customer', 'owner');

create type public.item_category as enum (
  'cafe',
  'wellness',
  'service',
  'experiences'
);

create type public.slot_status as enum (
  'available',
  'booked',
  'blocked'
);

create type public.booking_status as enum (
  'confirmed',
  'cancelled',
  'completed'
);

-- -----------------------------------------------------------------------------
-- Updated-at trigger helper
-- -----------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- profiles (1:1 with auth.users)
-- -----------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  phone text,
  role public.user_role not null default 'customer',
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index profiles_role_idx on public.profiles (role);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

comment on table public.profiles is 'App user profile; role is customer or owner.';

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    coalesce((new.raw_user_meta_data ->> 'role')::public.user_role, 'customer')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- stores (multi-store ready)
-- -----------------------------------------------------------------------------

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete restrict,
  name text not null,
  slug text not null,
  description text not null default '',
  brand_primary text, -- e.g. #2563EB for theming
  logo_url text,
  timezone text not null default 'America/New_York',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint stores_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint stores_slug_unique unique (slug)
);

create index stores_owner_id_idx on public.stores (owner_id);
create index stores_is_active_idx on public.stores (is_active) where is_active = true;

create trigger stores_set_updated_at
  before update on public.stores
  for each row execute function public.set_updated_at();

comment on table public.stores is 'Merchant storefronts; owner_id is a profiles row with role=owner.';

-- -----------------------------------------------------------------------------
-- items (bookable experiences)
-- -----------------------------------------------------------------------------

create table public.items (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  name text not null,
  description text not null default '',
  -- image_url for web assets; image_name for SF Symbol parity with iOS MVP
  image_url text,
  image_name text not null default 'sparkles',
  category public.item_category not null default 'experiences',
  accent_r double precision not null default 0.15
    check (accent_r >= 0 and accent_r <= 1),
  accent_g double precision not null default 0.39
    check (accent_g >= 0 and accent_g <= 1),
  accent_b double precision not null default 0.92
    check (accent_b >= 0 and accent_b <= 1),
  duration_minutes integer not null default 30
    check (duration_minutes > 0 and duration_minutes <= 24 * 60),
  price_cents integer
    check (price_cents is null or price_cents >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index items_store_id_idx on public.items (store_id);
create index items_category_idx on public.items (category);
create index items_active_store_idx on public.items (store_id, is_active)
  where is_active = true;

create trigger items_set_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

comment on table public.items is 'Bookable catalog items belonging to a store.';

-- -----------------------------------------------------------------------------
-- time_slots
-- -----------------------------------------------------------------------------

create table public.time_slots (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  -- Denormalized for simpler RLS / queries by store
  store_id uuid not null references public.stores (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.slot_status not null default 'available',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint time_slots_range_valid check (ends_at > starts_at),
  constraint time_slots_item_start_unique unique (item_id, starts_at)
);

create index time_slots_item_id_idx on public.time_slots (item_id);
create index time_slots_store_id_idx on public.time_slots (store_id);
create index time_slots_starts_at_idx on public.time_slots (starts_at);
create index time_slots_available_idx on public.time_slots (item_id, starts_at)
  where status = 'available';

create trigger time_slots_set_updated_at
  before update on public.time_slots
  for each row execute function public.set_updated_at();

comment on table public.time_slots is 'Bookable half-hour (or custom) windows for an item.';

-- Keep store_id in sync with item (defense in depth)
create or replace function public.time_slots_set_store_id()
returns trigger
language plpgsql
as $$
begin
  select i.store_id into new.store_id
  from public.items i
  where i.id = new.item_id;

  if new.store_id is null then
    raise exception 'item_id % has no store', new.item_id;
  end if;

  return new;
end;
$$;

create trigger time_slots_set_store_id_trg
  before insert or update of item_id on public.time_slots
  for each row execute function public.time_slots_set_store_id();

-- -----------------------------------------------------------------------------
-- bookings (guest + logged-in)
-- -----------------------------------------------------------------------------

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete restrict,
  item_id uuid not null references public.items (id) on delete restrict,
  time_slot_id uuid not null references public.time_slots (id) on delete restrict,
  -- null => guest booking
  user_id uuid references public.profiles (id) on delete set null,
  guest_name text,
  guest_phone text,
  guest_email text,
  reference_code text not null,
  status public.booking_status not null default 'confirmed',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  cancelled_at timestamptz,
  constraint bookings_reference_code_unique unique (reference_code),
  -- One active booking per slot (cancelled rows may keep the FK; enforce via partial unique)
  constraint bookings_guest_or_user check (
    user_id is not null
    or (
      guest_name is not null
      and length(trim(guest_name)) >= 2
      and guest_phone is not null
      and length(trim(guest_phone)) >= 7
    )
  )
);

-- Only one non-cancelled booking per time slot
create unique index bookings_active_slot_unique
  on public.bookings (time_slot_id)
  where status = 'confirmed';

create index bookings_user_id_idx on public.bookings (user_id);
create index bookings_store_id_idx on public.bookings (store_id);
create index bookings_item_id_idx on public.bookings (item_id);
create index bookings_status_idx on public.bookings (status);
create index bookings_created_at_idx on public.bookings (created_at desc);

create trigger bookings_set_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

comment on table public.bookings is 'Reservations for authenticated users or guests.';

-- Reference code generator: SB-XXXXXX
create or replace function public.generate_booking_reference()
returns text
language plpgsql
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := 'SB-';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  end loop;
  return result;
end;
$$;

create or replace function public.bookings_set_defaults()
returns trigger
language plpgsql
as $$
begin
  if new.reference_code is null or new.reference_code = '' then
    new.reference_code := public.generate_booking_reference();
  end if;

  if new.store_id is null then
    select i.store_id into new.store_id from public.items i where i.id = new.item_id;
  end if;

  if new.status = 'cancelled' and new.cancelled_at is null then
    new.cancelled_at := timezone('utc', now());
  end if;

  return new;
end;
$$;

create trigger bookings_set_defaults_trg
  before insert or update on public.bookings
  for each row execute function public.bookings_set_defaults();

-- When a booking is confirmed, mark the slot booked; on cancel, free it.
create or replace function public.bookings_sync_slot_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'confirmed' then
      update public.time_slots
      set status = 'booked', updated_at = timezone('utc', now())
      where id = new.time_slot_id
        and status = 'available';

      if not found then
        raise exception 'Time slot % is not available', new.time_slot_id;
      end if;
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if old.status = 'confirmed' and new.status = 'cancelled' then
      update public.time_slots
      set status = 'available', updated_at = timezone('utc', now())
      where id = new.time_slot_id
        and status = 'booked';
    end if;
    return new;
  end if;

  return new;
end;
$$;

create trigger bookings_sync_slot_status_trg
  after insert or update of status on public.bookings
  for each row execute function public.bookings_sync_slot_status();

-- -----------------------------------------------------------------------------
-- Helper: is the current user owner of a store?
-- -----------------------------------------------------------------------------

create or replace function public.is_store_owner(p_store_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.stores s
    where s.id = p_store_id
      and s.owner_id = auth.uid()
  );
$$;

create or replace function public.is_owner_role()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'owner'
  );
$$;

grant execute on function public.is_store_owner(uuid) to anon, authenticated;
grant execute on function public.is_owner_role() to anon, authenticated;

-- =============================================================================
-- Row Level Security
-- =============================================================================

alter table public.profiles enable row level security;
alter table public.stores enable row level security;
alter table public.items enable row level security;
alter table public.time_slots enable row level security;
alter table public.bookings enable row level security;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------

-- Users can read their own profile
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

-- Public can read minimal owner identity for store pages (optional; keep narrow)
create policy "profiles_select_owners_public"
  on public.profiles
  for select
  to anon, authenticated
  using (role = 'owner');

-- Users update own profile (cannot escalate role via client — enforced below)
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select p.role from public.profiles p where p.id = auth.uid())
  );

-- -----------------------------------------------------------------------------
-- stores
-- -----------------------------------------------------------------------------

-- Anyone can read active stores (public catalog)
create policy "stores_select_active_public"
  on public.stores
  for select
  to anon, authenticated
  using (is_active = true);

-- Owners can read their stores even if inactive
create policy "stores_select_own"
  on public.stores
  for select
  to authenticated
  using (owner_id = auth.uid());

-- Owners create stores for themselves
create policy "stores_insert_own"
  on public.stores
  for insert
  to authenticated
  with check (
    owner_id = auth.uid()
    and public.is_owner_role()
  );

-- Owners update / delete their stores
create policy "stores_update_own"
  on public.stores
  for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "stores_delete_own"
  on public.stores
  for delete
  to authenticated
  using (owner_id = auth.uid());

-- -----------------------------------------------------------------------------
-- items
-- -----------------------------------------------------------------------------

-- Public read active items under active stores
create policy "items_select_public"
  on public.items
  for select
  to anon, authenticated
  using (
    is_active = true
    and exists (
      select 1 from public.stores s
      where s.id = items.store_id
        and s.is_active = true
    )
  );

-- Owners read all items for their stores
create policy "items_select_owner"
  on public.items
  for select
  to authenticated
  using (public.is_store_owner(store_id));

create policy "items_insert_owner"
  on public.items
  for insert
  to authenticated
  with check (public.is_store_owner(store_id));

create policy "items_update_owner"
  on public.items
  for update
  to authenticated
  using (public.is_store_owner(store_id))
  with check (public.is_store_owner(store_id));

create policy "items_delete_owner"
  on public.items
  for delete
  to authenticated
  using (public.is_store_owner(store_id));

-- -----------------------------------------------------------------------------
-- time_slots
-- -----------------------------------------------------------------------------

-- Public can read slots for active public items (availability + booked state)
create policy "time_slots_select_public"
  on public.time_slots
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.items i
      join public.stores s on s.id = i.store_id
      where i.id = time_slots.item_id
        and i.is_active = true
        and s.is_active = true
    )
  );

-- Owners full read on their store slots
create policy "time_slots_select_owner"
  on public.time_slots
  for select
  to authenticated
  using (public.is_store_owner(store_id));

create policy "time_slots_insert_owner"
  on public.time_slots
  for insert
  to authenticated
  with check (public.is_store_owner(store_id));

create policy "time_slots_update_owner"
  on public.time_slots
  for update
  to authenticated
  using (public.is_store_owner(store_id))
  with check (public.is_store_owner(store_id));

create policy "time_slots_delete_owner"
  on public.time_slots
  for delete
  to authenticated
  using (public.is_store_owner(store_id));

-- -----------------------------------------------------------------------------
-- bookings
-- -----------------------------------------------------------------------------

-- Customers see only their own bookings
create policy "bookings_select_own"
  on public.bookings
  for select
  to authenticated
  using (user_id = auth.uid());

-- Owners see bookings for their stores
create policy "bookings_select_owner"
  on public.bookings
  for select
  to authenticated
  using (public.is_store_owner(store_id));

-- Authenticated customers create bookings for themselves
create policy "bookings_insert_authenticated"
  on public.bookings
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and status = 'confirmed'
  );

-- Guests (anon) may create guest bookings (no user_id)
create policy "bookings_insert_guest"
  on public.bookings
  for insert
  to anon
  with check (
    user_id is null
    and status = 'confirmed'
    and guest_name is not null
    and guest_phone is not null
  );

-- Customers can cancel their own confirmed bookings
create policy "bookings_update_own_cancel"
  on public.bookings
  for update
  to authenticated
  using (user_id = auth.uid() and status = 'confirmed')
  with check (
    user_id = auth.uid()
    and status in ('confirmed', 'cancelled')
  );

-- Owners can update bookings on their stores (cancel / complete)
create policy "bookings_update_owner"
  on public.bookings
  for update
  to authenticated
  using (public.is_store_owner(store_id))
  with check (public.is_store_owner(store_id));

-- Note: Guest cancel-by-reference should use a SECURITY DEFINER RPC in a later
-- migration (do not expose open guest update policies).

-- -----------------------------------------------------------------------------
-- Grants (Supabase roles)
-- -----------------------------------------------------------------------------

grant usage on schema public to anon, authenticated;

grant select on public.profiles to anon, authenticated;
grant update on public.profiles to authenticated;

grant select on public.stores to anon, authenticated;
grant insert, update, delete on public.stores to authenticated;

grant select on public.items to anon, authenticated;
grant insert, update, delete on public.items to authenticated;

grant select on public.time_slots to anon, authenticated;
grant insert, update, delete on public.time_slots to authenticated;

grant select on public.bookings to authenticated;
grant insert on public.bookings to anon, authenticated;
grant update on public.bookings to authenticated;

-- =============================================================================
-- End of migration
-- =============================================================================
