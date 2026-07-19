/**
 * Admin dashboard domain types (P0).
 */

import type { Booking, BookingStatus, Item, ItemCategory, Store } from "@/lib/types";

export type AdminStore = Pick<
  Store,
  "id" | "name" | "slug" | "timezone" | "brand_primary" | "is_active"
>;

export type AdminBookingRow = Booking & {
  item: Pick<Item, "id" | "name" | "duration_minutes" | "price_cents" | "category"> | null;
  time_slot: {
    id: string;
    starts_at: string;
    ends_at: string;
    status: string;
  } | null;
  /** Joined customer profile when user_id is set */
  customer: {
    id: string;
    full_name: string | null;
    phone: string | null;
    email: string | null;
  } | null;
};

export type AdminMetrics = {
  storeId: string;
  storeName: string;
  /** Confirmed bookings with slot starting today (store timezone approximated as local) */
  todaysBookings: number;
  /** Sum of item.price_cents for confirmed + completed bookings (all time) */
  totalRevenueCents: number;
  /** confirmed + completed count */
  totalBookings: number;
  /** Booked slots / all slots with starts_at >= start of today */
  utilizationRate: number;
  /** Available slots from today forward */
  openSlots: number;
  cancelledCount: number;
};

export type AdminItemRow = Item;

export type BookingStatusFilter = BookingStatus | "all";

export type DisplayCustomer = {
  name: string;
  phone: string;
  email: string | null;
  isGuest: boolean;
};

export function displayCustomer(row: AdminBookingRow): DisplayCustomer {
  if (row.user_id && row.customer) {
    return {
      name: row.customer.full_name?.trim() || row.customer.email || "Customer",
      phone: row.customer.phone?.trim() || "—",
      email: row.customer.email,
      isGuest: false,
    };
  }
  return {
    name: row.guest_name?.trim() || "Guest",
    phone: row.guest_phone?.trim() || "—",
    email: row.guest_email,
    isGuest: true,
  };
}

export function formatCents(cents: number | null | undefined): string {
  if (cents == null) return "—";
  return new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(cents / 100);
}

export function formatDateTime(iso: string): string {
  try {
    return new Intl.DateTimeFormat(undefined, {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

export function statusLabel(status: BookingStatus): string {
  switch (status) {
    case "confirmed":
      return "Confirmed";
    case "cancelled":
      return "Cancelled";
    case "completed":
      return "Completed";
    default:
      return status;
  }
}

export type { ItemCategory };
