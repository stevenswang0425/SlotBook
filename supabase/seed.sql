-- =============================================================================
-- SlotBook optional seed (run AFTER the initial migration)
-- Creates a demo owner, store, items, and sample slots.
--
-- IMPORTANT: Create the auth user first (Supabase Auth → Users → Add user),
-- then replace the UUID below with that user's id.
-- =============================================================================

-- Example (replace before running):
-- \set demo_owner_id '00000000-0000-0000-0000-000000000001'

-- For SQL Editor, paste the real owner uuid:
do $$
declare
  v_owner_id uuid := '00000000-0000-0000-0000-000000000001'; -- TODO: replace
  v_store_id uuid;
  v_item_id uuid;
  d date;
  h int;
  m int;
  slot_start timestamptz;
begin
  -- Ensure profile exists / is owner (trigger may have created it as customer)
  update public.profiles
  set role = 'owner',
      full_name = coalesce(full_name, 'Demo Owner')
  where id = v_owner_id;

  if not found then
    raise notice 'Profile % not found. Create the auth user first, then re-run seed.', v_owner_id;
    return;
  end if;

  insert into public.stores (owner_id, name, slug, description, brand_primary, timezone)
  values (
    v_owner_id,
    'Harbor Collective',
    'harbor-collective',
    'Calm experiences — cafe, wellness, and classes.',
    '#2563EB',
    'America/New_York'
  )
  on conflict (slug) do update
    set name = excluded.name
  returning id into v_store_id;

  -- Items
  insert into public.items (
    store_id, name, description, image_name, category,
    accent_r, accent_g, accent_b, duration_minutes, price_cents, sort_order
  )
  values
    (v_store_id, 'Pour-Over Flight',
     'Three single-origin pour-overs with guided tasting notes.',
     'cup.and.saucer.fill', 'cafe', 0.71, 0.47, 0.28, 45, 1800, 1),
    (v_store_id, 'Morning Flow Yoga',
     'A gentle 60-minute vinyasa to open the day.',
     'figure.yoga', 'wellness', 0.28, 0.63, 0.52, 60, 3200, 2),
    (v_store_id, 'Device Tune-Up',
     'Diagnostics, clean, and software refresh for phones and laptops.',
     'laptopcomputer.and.iphone', 'service', 0.27, 0.43, 0.78, 50, 6500, 3),
    (v_store_id, 'Pottery Basics',
     'Wheel-throwing intro for beginners.',
     'hands.sparkles', 'experiences', 0.59, 0.39, 0.71, 90, 4800, 4);

  -- Generate available slots for the next 7 days, 9:00–17:00 local (approx UTC offset ignored for seed)
  for v_item_id in
    select id from public.items where store_id = v_store_id
  loop
    for d in 0..6 loop
      for h in 9..16 loop
        for m in array[0, 30] loop
          slot_start := (current_date + d) + make_time(h, m, 0);
          insert into public.time_slots (item_id, store_id, starts_at, ends_at, status)
          values (
            v_item_id,
            v_store_id,
            slot_start,
            slot_start + interval '30 minutes',
            'available'
          )
          on conflict (item_id, starts_at) do nothing;
        end loop;
      end loop;
    end loop;
  end loop;

  raise notice 'Seed complete for store %', v_store_id;
end $$;
