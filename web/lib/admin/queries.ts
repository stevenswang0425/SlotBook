/**
 * Admin data access (browser client, RLS-enforced).
 *
 * Owners only receive rows for stores they own via policies.
 */

import { createClient } from "@/lib/supabase/client";
import type { BookingStatus, Item } from "@/lib/types";

import type { AdminBookingRow, AdminMetrics, AdminStore } from "./types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Sb = { from: (t: string) => any };

function db(): Sb {
  return createClient() as unknown as Sb;
}

function startOfLocalDay(d = new Date()): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function endOfLocalDay(d = new Date()): Date {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x;
}

/** Stores owned by the current user (RLS). */
export async function fetchOwnerStores(): Promise<AdminStore[]> {
  const { data, error } = await db()
    .from("stores")
    .select("id, name, slug, timezone, brand_primary, is_active")
    .order("created_at", { ascending: true });

  if (error) throw new Error(error.message);
  return (data ?? []) as AdminStore[];
}

/** Bookings for a store with item, slot, and customer profile. */
export async function fetchStoreBookings(
  storeId: string,
  status?: BookingStatus | "all"
): Promise<AdminBookingRow[]> {
  let q = db()
    .from("bookings")
    .select(
      `
      *,
      item:items ( id, name, duration_minutes, price_cents, category ),
      time_slot:time_slots ( id, starts_at, ends_at, status ),
      customer:profiles ( id, full_name, phone, email )
    `
    )
    .eq("store_id", storeId)
    .order("created_at", { ascending: false });

  if (status && status !== "all") {
    q = q.eq("status", status);
  }

  const { data, error } = await q;
  if (error) throw new Error(error.message);

  // PostgREST may return customer as object or null; normalize relation key
  return (data ?? []).map((row: Record<string, unknown>) => ({
    ...row,
    item: row.item ?? null,
    time_slot: row.time_slot ?? null,
    customer: row.customer ?? null,
  })) as AdminBookingRow[];
}

export async function fetchStoreItems(storeId: string): Promise<Item[]> {
  const { data, error } = await db()
    .from("items")
    .select("*")
    .eq("store_id", storeId)
    .order("sort_order", { ascending: true });

  if (error) throw new Error(error.message);
  return (data ?? []) as Item[];
}

export async function fetchStoreMetrics(storeId: string, storeName: string): Promise<AdminMetrics> {
  const dayStart = startOfLocalDay().toISOString();
  const dayEnd = endOfLocalDay().toISOString();

  const client = db();

  // All bookings for revenue + counts
  const { data: bookings, error: bErr } = await client
    .from("bookings")
    .select(
      `
      id,
      status,
      item:items ( price_cents ),
      time_slot:time_slots ( starts_at )
    `
    )
    .eq("store_id", storeId);

  if (bErr) throw new Error(bErr.message);

  const rows = (bookings ?? []) as Array<{
    id: string;
    status: BookingStatus;
    item: { price_cents: number | null } | null;
    time_slot: { starts_at: string } | null;
  }>;

  let todaysBookings = 0;
  let totalRevenueCents = 0;
  let totalBookings = 0;
  let cancelledCount = 0;

  for (const row of rows) {
    if (row.status === "cancelled") {
      cancelledCount += 1;
      continue;
    }
    if (row.status === "confirmed" || row.status === "completed") {
      totalBookings += 1;
      totalRevenueCents += row.item?.price_cents ?? 0;

      const start = row.time_slot?.starts_at;
      if (start && start >= dayStart && start <= dayEnd && row.status === "confirmed") {
        todaysBookings += 1;
      }
      // Include completed today in "today's bookings" if slot was today
      if (start && start >= dayStart && start <= dayEnd && row.status === "completed") {
        todaysBookings += 1;
      }
    }
  }

  // Utilization: booked slots / total slots from start of today forward
  const { data: slots, error: sErr } = await client
    .from("time_slots")
    .select("id, status")
    .eq("store_id", storeId)
    .gte("starts_at", dayStart);

  if (sErr) throw new Error(sErr.message);

  const slotRows = (slots ?? []) as Array<{ id: string; status: string }>;
  const totalSlots = slotRows.length;
  const bookedSlots = slotRows.filter((s) => s.status === "booked").length;
  const openSlots = slotRows.filter((s) => s.status === "available").length;
  const utilizationRate = totalSlots === 0 ? 0 : bookedSlots / totalSlots;

  return {
    storeId,
    storeName,
    todaysBookings,
    totalRevenueCents,
    totalBookings,
    utilizationRate,
    openSlots,
    cancelledCount,
  };
}

/** Owner cancels a booking (frees slot via trigger). */
export async function cancelBooking(bookingId: string): Promise<void> {
  const { error } = await db()
    .from("bookings")
    .update({
      status: "cancelled",
      cancelled_at: new Date().toISOString(),
    })
    .eq("id", bookingId)
    .eq("status", "confirmed");

  if (error) throw new Error(error.message);
}

/** Owner marks booking completed. */
export async function completeBooking(bookingId: string): Promise<void> {
  const { error } = await db()
    .from("bookings")
    .update({ status: "completed" })
    .eq("id", bookingId)
    .eq("status", "confirmed");

  if (error) throw new Error(error.message);
}
