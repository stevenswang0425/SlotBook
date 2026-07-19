/**
 * Booking create helpers (guest + authenticated).
 *
 * Relies on RLS from Iteration 1:
 * - authenticated insert with user_id = auth.uid()
 * - anon insert with user_id null + guest fields
 */

import type { BookingDraftInput, GuestBookingInput } from "@/lib/auth/types";
import type { Booking } from "@/lib/types";

export type CreateBookingResult =
  | { ok: true; booking: Booking }
  | { ok: false; error: string };

/** Minimal surface we need from the Supabase client. */
type BookingClient = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  from: (table: string) => any;
};

/** Create a booking for the signed-in user. */
export async function createUserBooking(
  supabase: BookingClient,
  userId: string,
  draft: BookingDraftInput,
  extras?: { guestName?: string; guestPhone?: string; guestEmail?: string }
): Promise<CreateBookingResult> {
  const { data, error } = await supabase
    .from("bookings")
    .insert({
      store_id: draft.storeId,
      item_id: draft.itemId,
      time_slot_id: draft.timeSlotId,
      user_id: userId,
      guest_name: extras?.guestName ?? null,
      guest_phone: extras?.guestPhone ?? null,
      guest_email: extras?.guestEmail ?? null,
      status: "confirmed",
    })
    .select("*")
    .single();

  if (error) {
    return { ok: false, error: mapBookingError(error.message) };
  }

  return { ok: true, booking: data as Booking };
}

/** Create a guest booking (user_id = null). */
export async function createGuestBooking(
  supabase: BookingClient,
  draft: BookingDraftInput,
  guest: GuestBookingInput
): Promise<CreateBookingResult> {
  // Insert without SELECT — anon RLS allows insert but not select on bookings.
  const { error } = await supabase.from("bookings").insert({
    store_id: draft.storeId,
    item_id: draft.itemId,
    time_slot_id: draft.timeSlotId,
    user_id: null,
    guest_name: guest.guestName.trim(),
    guest_phone: guest.guestPhone.trim(),
    guest_email: guest.guestEmail?.trim() || null,
    status: "confirmed",
  });

  if (error) {
    return { ok: false, error: mapBookingError(error.message) };
  }

  const booking: Booking = {
    id: crypto.randomUUID(),
    store_id: draft.storeId,
    item_id: draft.itemId,
    time_slot_id: draft.timeSlotId,
    user_id: null,
    guest_name: guest.guestName.trim(),
    guest_phone: guest.guestPhone.trim(),
    guest_email: guest.guestEmail?.trim() || null,
    reference_code: "SB-GUEST",
    status: "confirmed",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    cancelled_at: null,
  };

  return { ok: true, booking };
}

function mapBookingError(message: string): string {
  const lower = message.toLowerCase();
  if (lower.includes("not available") || lower.includes("time slot")) {
    return "That time slot is no longer available. Pick another time.";
  }
  if (lower.includes("duplicate") || lower.includes("unique")) {
    return "This slot was just taken. Please choose another.";
  }
  return message || "Couldn't complete the booking. Please try again.";
}
