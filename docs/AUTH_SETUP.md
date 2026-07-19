# SlotBook P0 — Authentication (Hybrid + Roles)

Build on Iteration 1 (Supabase schema + clients).

---

## What you get

| Piece | Path |
|-------|------|
| Auth context + `useAuth` | `web/components/auth/AuthProvider.tsx`, `web/hooks/useAuth.ts` |
| Sign in / Sign up / Phone OTP modal | `web/components/auth/AuthModal.tsx` |
| Guest booking form | `web/components/booking/GuestBookingForm.tsx` |
| Booking choice gate | `web/components/booking/BookingAuthGate.tsx` |
| Booking insert helpers | `web/lib/booking/createBooking.ts` |
| App wiring | `web/app/providers.tsx`, `web/app/layout.tsx` |

---

## Supabase Auth configuration

### Email / password
1. Dashboard → **Authentication → Providers → Email**
2. Enable Email provider
3. Optional: disable “Confirm email” for local dev

### Phone OTP
1. **Authentication → Providers → Phone**
2. Enable Phone and configure an SMS provider (Twilio, MessageBird, etc.)
3. Without an SMS provider, phone OTP will fail in production (expected)

### Profiles & roles
- A `profiles` row is created by the DB trigger `handle_new_user` on signup
- Client **always** sends `role: "customer"` in user metadata
- To promote an owner:

```sql
update public.profiles
set role = 'owner'
where email = 'owner@example.com';
```

Never accept `owner` from an untrusted client form.

---

## Integration (already wired in this repo)

```tsx
// app/layout.tsx
import { Providers } from "./providers";

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

`Providers` mounts:
- `AuthProvider`
- `AuthModal` (global)
- `BookingAuthGate` (global)

---

## Usage patterns

### 1. Read auth state

```tsx
"use client";
import { useAuth } from "@/hooks/useAuth";

export function Header() {
  const { isAuthenticated, profile, openAuthModal, signOut, isOwner } = useAuth();

  if (!isAuthenticated) {
    return <button onClick={() => openAuthModal("sign-in")}>Sign in</button>;
  }

  return (
    <div>
      <span>{profile?.full_name ?? profile?.email}</span>
      {isOwner && <span>Owner</span>}
      <button onClick={() => void signOut()}>Sign out</button>
    </div>
  );
}
```

### 2. Start booking (item detail)

```tsx
"use client";
import { requestBooking } from "@/components/booking/BookingAuthGate";

function BookButton({ item, slot }) {
  return (
    <button
      onClick={() =>
        requestBooking({
          storeId: item.store_id,
          itemId: item.id,
          timeSlotId: slot.id,
          itemName: item.name,
          slotLabel: formatSlot(slot), // your formatter
        })
      }
    >
      Book selected slot
    </button>
  );
}
```

**Guest path:** choice → guest form → `bookings` insert with `user_id = null`  
**Signed-in path:** choice/sign-in → confirm → insert with `user_id = auth.uid()`

### 3. Open auth only

```tsx
openAuthModal("sign-up");
openAuthModal("phone");
openAuthModal("sign-in", { type: "booking", draft });
```

---

## Security notes

| Topic | Behavior |
|-------|----------|
| Role on signup | Forced to `customer` in `signUpWithEmail` / phone metadata |
| RLS | Guest insert allowed for anon; customers only see own bookings |
| Guest SELECT | Guest may not read the booking row back (RLS); UI still confirms submit |
| Service role | Only in `lib/supabase/admin.ts` — never client |

---

## Local run

```bash
cd web
cp .env.example .env.local   # if not already
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) — demo auth + booking gate.

---

## File map

```
web/
  app/
    layout.tsx
    providers.tsx
    page.tsx                 # auth demo
    globals.css
  components/
    auth/
      AuthProvider.tsx
      AuthModal.tsx
      auth.module.css
    booking/
      BookingAuthGate.tsx
      GuestBookingForm.tsx
  hooks/
    useAuth.ts
  lib/
    auth/
      types.ts
      validation.ts
      errors.ts
    booking/
      createBooking.ts
docs/
  AUTH_SETUP.md
```
