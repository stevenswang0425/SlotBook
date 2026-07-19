/**
 * Auth-layer types for SlotBook hybrid authentication.
 */

import type { User, Session } from "@supabase/supabase-js";

import type { Profile, UserRole } from "@/lib/types";

export type AuthMode = "sign-in" | "sign-up" | "phone" | "phone-verify";

/** Why the auth modal was opened (drives post-auth behavior). */
export type AuthIntent =
  | { type: "standalone" }
  | {
      type: "booking";
      /** Opaque payload the booking layer resumes after auth. */
      draft: BookingDraftInput;
    };

/** Fields needed to create a booking after auth or as guest. */
export type BookingDraftInput = {
  storeId: string;
  itemId: string;
  timeSlotId: string;
  /** Display helpers for the modal summary */
  itemName?: string;
  slotLabel?: string;
};

export type GuestBookingInput = {
  guestName: string;
  guestPhone: string;
  guestEmail?: string;
};

export type EmailCredentials = {
  email: string;
  password: string;
  fullName?: string;
};

export type AuthState = {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  role: UserRole | null;
  isOwner: boolean;
  isCustomer: boolean;
};

export type AuthModalState = {
  open: boolean;
  mode: AuthMode;
  intent: AuthIntent;
};

export type AuthActionResult =
  | { ok: true; message?: string }
  | { ok: false; error: string };
