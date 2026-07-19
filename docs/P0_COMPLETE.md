# SlotBook P0 — Complete

End-to-end foundation: Supabase schema, hybrid auth, protected admin, owner dashboard.

---

## Run migrations (order)

In **Supabase → SQL Editor**, run:

1. `supabase/migrations/20260718120000_initial_schema.sql`
2. `supabase/migrations/20260719100000_profiles_insert_own.sql`
3. `supabase/migrations/20260719120000_final_rls_p0.sql` ← **final RLS**

Optional: `supabase/seed.sql` (replace owner UUID first).

---

## Full P0 test flow

### A. Owner setup
1. Create auth user in Supabase (or sign up in the app).
2. Promote to owner:
   ```sql
   update public.profiles set role = 'owner' where email = 'owner@example.com';
   ```
3. Ensure a store exists with `owner_id` = that user (seed script).
4. `cd web && cp .env.example .env.local` → fill keys → `npm install && npm run dev`

### B. Guest booking
1. Open `http://localhost:3000` signed out.
2. Click **Book selected slot** → **Continue as Guest**.
3. Enter name + phone → confirm.
4. As owner, open **Admin → Bookings** and see the guest name/phone.

> Use real `store_id` / `item_id` / `time_slot_id` from your seeded DB in `requestBooking` (demo page uses placeholders).

### C. Customer booking
1. Sign up / sign in as a customer.
2. Book a slot via the same gate → **Sign In** path.
3. Customer sees only their bookings (RLS); owner sees store bookings with customer name/phone.

### D. Admin access
1. Visit `/admin` as customer → redirected (`forbidden`).
2. Visit as owner → Dashboard metrics, Bookings, Items, Settings.
3. **Cancel** a confirmed booking → slot becomes available.
4. **Mark completed** → status completed; slot stays booked historically.

---

## Admin features (P0)

| Page | Features |
|------|----------|
| `/admin` | Today’s bookings, revenue, utilization, totals |
| `/admin/bookings` | Table with customer Name + Phone, filters, View / Complete / Cancel |
| `/admin/items` | Read-only catalog cards |
| `/admin/settings` | Store profile summary |

---

## Final RLS summary

| Actor | Access |
|-------|--------|
| **Public** | Read active stores, items, slots; insert guest bookings |
| **Customer** | Own profile; own bookings (read + cancel) |
| **Owner** | Full manage of owned store data; read booking customers’ profiles; update booking status |

---

## Key paths

```
web/app/admin/                 # dashboard, bookings, items, settings
web/components/admin/          # table + detail drawer
web/lib/admin/                 # queries, types, store context
supabase/migrations/           # schema + final RLS
docs/P0_COMPLETE.md            # this file
docs/SUPABASE_SETUP.md
docs/AUTH_SETUP.md
docs/PROTECTED_ROUTES.md
```

P0 is complete. Next: real catalog UI, slot calendar for owners, Supabase realtime, iOS repositories.
