# SlotBook P0 — Supabase Setup & Database Schema

Step-by-step guide for **Iteration 1: Supabase Setup & Database Schema**.

---

## 1. Create a Supabase project

1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New project**.
3. Choose organization, set:
   - **Name:** `SlotBook` (or your preference)
   - **Database password:** generate and store securely
   - **Region:** closest to your users
4. Wait until the project is **Healthy**.
5. Open **Project Settings → API** and copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon public** key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY` (server only)

---

## 2. Run the migration (SQL Editor)

1. In the Supabase dashboard, open **SQL → New query**.
2. Paste the full contents of:

   ```
   supabase/migrations/20260718120000_initial_schema.sql
   ```

3. Click **Run**.
4. Confirm tables exist under **Table Editor**:
   - `profiles`
   - `stores`
   - `items`
   - `time_slots`
   - `bookings`

### Optional seed

1. **Authentication → Users → Add user** (email + password).
2. Copy the new user’s UUID.
3. Open `supabase/seed.sql`, replace:

   ```sql
   v_owner_id uuid := '00000000-0000-0000-0000-000000000001';
   ```

   with that UUID.
4. Run the seed script in the SQL Editor.

---

## 3. Configure Next.js env

```bash
cd web
cp .env.example .env.local
# Edit .env.local with your Supabase URL + keys
npm install
```

`.env.local` keys:

| Variable | Where used |
|----------|------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Browser + server |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Browser + server (RLS enforced) |
| `SUPABASE_SERVICE_ROLE_KEY` | Server only (`lib/supabase/admin.ts`) |

---

## 4. Client usage (Next.js)

### Browser (Client Components)

```ts
import { createClient } from "@/lib/supabase/client";

const supabase = createClient();
const { data: items } = await supabase
  .from("items")
  .select("*")
  .eq("is_active", true);
```

### Server (RSC / Server Actions)

```ts
import { createClient } from "@/lib/supabase/server";

const supabase = await createClient();
const { data: { user } } = await supabase.auth.getUser();
```

### Admin (bypasses RLS — server only)

```ts
import { createAdminClient } from "@/lib/supabase/admin";

const admin = createAdminClient();
```

---

## 5. Schema overview

```
auth.users
    └── profiles (role: customer | owner)
            └── stores (owner_id)
                    ├── items
                    │     └── time_slots
                    └── bookings ──► time_slots (1 active booking per slot)
```

| Table | Purpose |
|-------|---------|
| `profiles` | App user + role |
| `stores` | Multi-store ready merchant |
| `items` | Catalog experiences |
| `time_slots` | Availability windows |
| `bookings` | Guest **or** logged-in reservations |

### Booking model

- **Logged-in:** `user_id` set  
- **Guest:** `user_id` null + `guest_name` + `guest_phone` required  
- Confirming a booking sets the slot to `booked` (trigger)  
- Cancelling a booking frees the slot back to `available`

---

## 6. RLS summary

| Resource | Public (anon) | Customer | Owner |
|----------|---------------|----------|-------|
| Active stores / items / slots | **Read** | Read | Read all own store |
| Own profile | — | Read/Update | Read/Update |
| Bookings | **Insert guest** | Read/cancel own; insert own | Read/update store bookings |
| Store CRUD | — | — | Own stores |
| Items / slots CRUD | — | — | Own store |

Guest **cancel-by-reference** is intentionally not open via RLS; add a `SECURITY DEFINER` RPC in a later iteration.

---

## 7. Regenerating types (optional)

```bash
npx supabase login
npx supabase link --project-ref <PROJECT_REF>
npx supabase gen types typescript --linked > web/lib/database.generated.ts
```

Hand-maintained domain types live in `web/lib/types.ts`.

---

## 8. File map

```
supabase/
  migrations/20260718120000_initial_schema.sql
  seed.sql
web/
  .env.example
  lib/types.ts
  lib/supabase/client.ts    # browser
  lib/supabase/server.ts    # RSC / actions
  lib/supabase/middleware.ts
  lib/supabase/admin.ts     # service role
  middleware.ts
docs/SUPABASE_SETUP.md      # this file
```

---

## Next

- **Auth UI** → see [`docs/AUTH_SETUP.md`](./AUTH_SETUP.md) (P0 Iteration 2)
- API routes / Server Actions for booking
- Owner dashboard for inventory
- Realtime subscriptions on `time_slots`
- Wire iOS `*Repository` implementations to Supabase REST
