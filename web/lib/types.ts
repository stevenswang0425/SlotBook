/**
 * SlotBook database types (P0 schema).
 *
 * Mirrors `supabase/migrations/20260718120000_initial_schema.sql`.
 * When using the Supabase CLI, you can regenerate with:
 *   npx supabase gen types typescript --project-id <id> > lib/database.generated.ts
 * and keep this file as the hand-maintained domain layer.
 */

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

export type UserRole = "customer" | "owner";

export type ItemCategory = "cafe" | "wellness" | "service" | "experiences";

export type SlotStatus = "available" | "booked" | "blocked";

export type BookingStatus = "confirmed" | "cancelled" | "completed";

// ---------------------------------------------------------------------------
// Table rows
// ---------------------------------------------------------------------------

export interface Profile {
  id: string;
  email: string | null;
  full_name: string | null;
  phone: string | null;
  role: UserRole;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Store {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  description: string;
  /** Hex brand color, e.g. `#2563EB` */
  brand_primary: string | null;
  logo_url: string | null;
  timezone: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Item {
  id: string;
  store_id: string;
  name: string;
  description: string;
  image_url: string | null;
  /** SF Symbol name for iOS parity */
  image_name: string;
  category: ItemCategory;
  /** Accent RGB components in 0…1 */
  accent_r: number;
  accent_g: number;
  accent_b: number;
  duration_minutes: number;
  price_cents: number | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface TimeSlot {
  id: string;
  item_id: string;
  store_id: string;
  starts_at: string;
  ends_at: string;
  status: SlotStatus;
  created_at: string;
  updated_at: string;
}

/**
 * Booking for either:
 * - logged-in user (`user_id` set), or
 * - guest (`user_id` null + guest_name / guest_phone required).
 */
export interface Booking {
  id: string;
  store_id: string;
  item_id: string;
  time_slot_id: string;
  user_id: string | null;
  guest_name: string | null;
  guest_phone: string | null;
  guest_email: string | null;
  reference_code: string;
  status: BookingStatus;
  created_at: string;
  updated_at: string;
  cancelled_at: string | null;
}

// ---------------------------------------------------------------------------
// Insert / Update payloads (omit generated columns)
// ---------------------------------------------------------------------------

export type ProfileInsert = {
  id: string;
  email?: string | null;
  full_name?: string | null;
  phone?: string | null;
  role?: UserRole;
  avatar_url?: string | null;
};

export type ProfileUpdate = Partial<
  Omit<Profile, "id" | "created_at" | "updated_at">
>;

export type StoreInsert = {
  owner_id: string;
  name: string;
  slug: string;
  description?: string;
  brand_primary?: string | null;
  logo_url?: string | null;
  timezone?: string;
  is_active?: boolean;
};

export type StoreUpdate = Partial<
  Omit<Store, "id" | "owner_id" | "created_at" | "updated_at">
>;

export type ItemInsert = {
  store_id: string;
  name: string;
  description?: string;
  image_url?: string | null;
  image_name?: string;
  category?: ItemCategory;
  accent_r?: number;
  accent_g?: number;
  accent_b?: number;
  duration_minutes?: number;
  price_cents?: number | null;
  is_active?: boolean;
  sort_order?: number;
};

export type ItemUpdate = Partial<
  Omit<Item, "id" | "store_id" | "created_at" | "updated_at">
>;

export type TimeSlotInsert = {
  item_id: string;
  /** Optional — trigger fills from item.store_id if omitted */
  store_id?: string;
  starts_at: string;
  ends_at: string;
  status?: SlotStatus;
};

export type TimeSlotUpdate = Partial<
  Pick<TimeSlot, "starts_at" | "ends_at" | "status">
>;

export type BookingInsert = {
  store_id: string;
  item_id: string;
  time_slot_id: string;
  user_id?: string | null;
  guest_name?: string | null;
  guest_phone?: string | null;
  guest_email?: string | null;
  reference_code?: string;
  status?: BookingStatus;
};

export type BookingUpdate = Partial<
  Pick<Booking, "status" | "cancelled_at" | "guest_email">
>;

// ---------------------------------------------------------------------------
// Supabase Database interface (for typed createClient<Database>())
// ---------------------------------------------------------------------------

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

/**
 * Shape expected by `@supabase/supabase-js` generic client.
 */
export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: ProfileInsert;
        Update: ProfileUpdate;
        Relationships: [];
      };
      stores: {
        Row: Store;
        Insert: StoreInsert;
        Update: StoreUpdate;
        Relationships: [
          {
            foreignKeyName: "stores_owner_id_fkey";
            columns: ["owner_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      items: {
        Row: Item;
        Insert: ItemInsert;
        Update: ItemUpdate;
        Relationships: [
          {
            foreignKeyName: "items_store_id_fkey";
            columns: ["store_id"];
            isOneToOne: false;
            referencedRelation: "stores";
            referencedColumns: ["id"];
          },
        ];
      };
      time_slots: {
        Row: TimeSlot;
        Insert: TimeSlotInsert;
        Update: TimeSlotUpdate;
        Relationships: [
          {
            foreignKeyName: "time_slots_item_id_fkey";
            columns: ["item_id"];
            isOneToOne: false;
            referencedRelation: "items";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "time_slots_store_id_fkey";
            columns: ["store_id"];
            isOneToOne: false;
            referencedRelation: "stores";
            referencedColumns: ["id"];
          },
        ];
      };
      bookings: {
        Row: Booking;
        Insert: BookingInsert;
        Update: BookingUpdate;
        Relationships: [
          {
            foreignKeyName: "bookings_store_id_fkey";
            columns: ["store_id"];
            isOneToOne: false;
            referencedRelation: "stores";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "bookings_item_id_fkey";
            columns: ["item_id"];
            isOneToOne: false;
            referencedRelation: "items";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "bookings_time_slot_id_fkey";
            columns: ["time_slot_id"];
            isOneToOne: false;
            referencedRelation: "time_slots";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "bookings_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: Record<string, never>;
    Functions: {
      is_store_owner: {
        Args: { p_store_id: string };
        Returns: boolean;
      };
      is_owner_role: {
        Args: Record<string, never>;
        Returns: boolean;
      };
      generate_booking_reference: {
        Args: Record<string, never>;
        Returns: string;
      };
    };
    Enums: {
      user_role: UserRole;
      item_category: ItemCategory;
      slot_status: SlotStatus;
      booking_status: BookingStatus;
    };
    CompositeTypes: Record<string, never>;
  };
}

// ---------------------------------------------------------------------------
// Convenience joined shapes (app layer)
// ---------------------------------------------------------------------------

export type ItemWithStore = Item & { store: Pick<Store, "id" | "name" | "slug"> };

export type BookingWithDetails = Booking & {
  item: Pick<Item, "id" | "name" | "image_name" | "duration_minutes">;
  time_slot: Pick<TimeSlot, "id" | "starts_at" | "ends_at" | "status">;
};

export type TimeSlotWithItem = TimeSlot & {
  item: Pick<Item, "id" | "name" | "duration_minutes">;
};
