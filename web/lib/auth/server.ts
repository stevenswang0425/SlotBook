/**
 * Server-side auth helpers for RSC, layouts, and route handlers.
 * Prefer these over trusting client-only role flags.
 */

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";
import type { Profile, UserRole } from "@/lib/types";

export type ServerAuth = {
  userId: string;
  email: string | null;
  profile: Profile | null;
  role: UserRole | null;
  isOwner: boolean;
  isCustomer: boolean;
};

/**
 * Returns the current user + profile, or null when unauthenticated.
 */
export async function getServerAuth(): Promise<ServerAuth | null> {
  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const db = supabase as any;

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) return null;

  const { data: profile } = await db
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  // Auto-heal missing profile (race with signup trigger, or legacy users).
  let resolved = profile as Profile | null;
  if (!resolved) {
    const { data: created } = await db
      .from("profiles")
      .upsert(
        {
          id: user.id,
          email: user.email ?? null,
          full_name:
            (user.user_metadata?.full_name as string | undefined) ??
            (user.user_metadata?.name as string | undefined) ??
            null,
          role: "customer",
        },
        { onConflict: "id" }
      )
      .select("*")
      .maybeSingle();
    resolved = (created as Profile | null) ?? null;
  }

  const role = resolved?.role ?? null;

  return {
    userId: user.id,
    email: user.email ?? null,
    profile: resolved,
    role,
    isOwner: role === "owner",
    isCustomer: role === "customer",
  };
}

/** Redirects to home (or login) when no session. */
export async function requireUser(redirectTo = "/?auth=required"): Promise<ServerAuth> {
  const auth = await getServerAuth();
  if (!auth) redirect(redirectTo);
  return auth;
}

/**
 * Owner-only guard for server layouts/pages under /admin.
 * Unauthenticated → /?auth=required
 * Authenticated non-owner → /?error=forbidden
 */
export async function requireOwner(
  loginRedirect = "/?auth=required&next=/admin",
  forbiddenRedirect = "/?error=forbidden"
): Promise<ServerAuth> {
  const auth = await getServerAuth();
  if (!auth) redirect(loginRedirect);
  if (!auth.isOwner) redirect(forbiddenRedirect);
  return auth;
}
