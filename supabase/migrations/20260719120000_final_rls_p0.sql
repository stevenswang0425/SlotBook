-- =============================================================================
-- SlotBook P0 — Final RLS refinements
-- Run after 20260718120000_initial_schema.sql and 20260719100000_profiles_insert_own.sql
--
-- Goals:
--  • Public: browse active stores, items, slots
--  • Customers: only their own bookings
--  • Owners: only data for stores they own (+ customer profiles on those bookings)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Owners can read customer profiles for bookings on their stores
-- (needed to show Name + Phone for logged-in customers in Admin)
-- -----------------------------------------------------------------------------

drop policy if exists "profiles_select_booking_customers" on public.profiles;

create policy "profiles_select_booking_customers"
  on public.profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.bookings b
      where b.user_id = profiles.id
        and public.is_store_owner(b.store_id)
    )
  );

-- -----------------------------------------------------------------------------
-- Customers: cannot read other customers' bookings (already enforced by
-- bookings_select_own). Explicitly deny select of cancelled others — no change.
-- Ensure customers cannot insert bookings for another user_id.
-- (bookings_insert_authenticated already requires user_id = auth.uid())
-- -----------------------------------------------------------------------------

-- Owners: re-assert store-scoped booking select (idempotent drop/create)
drop policy if exists "bookings_select_owner" on public.bookings;
create policy "bookings_select_owner"
  on public.bookings
  for select
  to authenticated
  using (public.is_store_owner(store_id));

drop policy if exists "bookings_update_owner" on public.bookings;
create policy "bookings_update_owner"
  on public.bookings
  for update
  to authenticated
  using (public.is_store_owner(store_id))
  with check (public.is_store_owner(store_id));

-- Customers: update only own confirmed → cancelled/completed not required for P0
drop policy if exists "bookings_update_own_cancel" on public.bookings;
create policy "bookings_update_own_cancel"
  on public.bookings
  for update
  to authenticated
  using (user_id = auth.uid() and status = 'confirmed')
  with check (
    user_id = auth.uid()
    and status in ('confirmed', 'cancelled')
  );

-- -----------------------------------------------------------------------------
-- Items / slots: public read only when store + item active (already present).
-- Re-create owner policies to guarantee store scope via is_store_owner.
-- -----------------------------------------------------------------------------

drop policy if exists "items_select_public" on public.items;
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

drop policy if exists "time_slots_select_public" on public.time_slots;
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

-- -----------------------------------------------------------------------------
-- Helper: list store IDs owned by current user (for app queries / debugging)
-- -----------------------------------------------------------------------------

create or replace function public.owned_store_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select s.id
  from public.stores s
  where s.owner_id = auth.uid();
$$;

grant execute on function public.owned_store_ids() to authenticated;

-- -----------------------------------------------------------------------------
-- When marking booking completed, keep slot as booked (no free).
-- When cancelling, free slot — already handled by bookings_sync_slot_status.
-- Extend trigger to ignore completed → available (no-op).
-- -----------------------------------------------------------------------------

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
    -- Cancel → free slot
    if old.status = 'confirmed' and new.status = 'cancelled' then
      update public.time_slots
      set status = 'available', updated_at = timezone('utc', now())
      where id = new.time_slot_id
        and status = 'booked';
    end if;
    -- completed: leave slot booked (historical)
    return new;
  end if;

  return new;
end;
$$;

comment on policy "profiles_select_booking_customers" on public.profiles is
  'Owners may read profiles of customers who booked their stores.';
