/**
 * Browser Supabase client (Client Components, hooks, browser events).
 *
 * Uses the anon key — RLS is the security boundary.
 * Never import the service-role key here.
 */

import { createBrowserClient } from "@supabase/ssr";

import type { Database } from "@/lib/types";

export function createClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY. " +
        "Copy web/.env.example → web/.env.local and fill values from Supabase → Settings → API."
    );
  }

  return createBrowserClient<Database>(url, anonKey);
}
