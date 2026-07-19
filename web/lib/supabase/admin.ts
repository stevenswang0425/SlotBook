/**
 * Service-role Supabase client (server-only).
 *
 * Bypasses RLS — use exclusively in trusted server contexts
 * (cron jobs, admin scripts, webhooks). Never import from Client Components.
 *
 * Requires SUPABASE_SERVICE_ROLE_KEY (not NEXT_PUBLIC_*).
 */

import { createClient } from "@supabase/supabase-js";

import type { Database } from "@/lib/types";

export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY for admin client."
    );
  }

  return createClient<Database>(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
