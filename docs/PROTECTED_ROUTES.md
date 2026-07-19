# SlotBook P0 — Protected Routes & Auth Integration

Builds on Supabase schema + hybrid auth.

---

## Defense in depth for `/admin/*`

| Layer | File | Behavior |
|-------|------|----------|
| **Edge middleware** | `web/middleware.ts` + `lib/supabase/middleware.ts` | Must be signed in; `profiles.role === 'owner'` or redirect |
| **Server layout** | `app/admin/layout.tsx` | `requireOwner()` redirects unauthenticated / non-owners |
| **Client guard** | `ProtectedRoute` + `AdminShell` | Loading + forbidden UI while auth resolves |

Redirects:
- Not signed in → `/?auth=required&next=/admin`
- Signed in, not owner → `/?error=forbidden`

---

## AuthProvider enhancements

- `isLoading` — first session restore  
- `isProfileLoading` — profile fetch / auto-create  
- `ensureProfile` — upserts **customer** row if missing (first login)  
- `requireAuth(intent?)` — opens AuthModal when needed  
- Roles: `isOwner` / `isCustomer` from `profiles.role`

**Promote an owner (SQL):**

```sql
update public.profiles set role = 'owner' where email = 'you@example.com';
```

**RLS heal path:** run migration  
`supabase/migrations/20260719100000_profiles_insert_own.sql`  
so clients can insert their own `customer` profile when the auth trigger races.

---

## Components

| Component | Use |
|-----------|-----|
| `SiteHeader` / `UserMenu` | Avatar, role, Admin link, Sign out |
| `ProtectedRoute` | Client-side role gate |
| `BookingAuthGate` | Guest vs signed-in booking (waits for profile) |

---

## Server helpers

```ts
import { requireOwner, requireUser, getServerAuth } from "@/lib/auth/server";

// In a server layout / page:
const auth = await requireOwner();
```

---

## Local test checklist

1. Run profile insert migration in Supabase SQL Editor.  
2. `cd web && npm run dev`  
3. Visit `/admin` signed out → redirect + sign-in modal.  
4. Sign in as customer → `/admin` → forbidden home banner.  
5. Promote user to owner → `/admin` dashboard loads.  
6. Header shows avatar menu; owners see **Admin**.  
7. **Book selected slot** works for guest and signed-in users.
