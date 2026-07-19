"use client";

/**
 * Client-side route guard for role-gated sections.
 *
 * Prefer server `requireOwner()` in layouts for /admin (defense in depth).
 * Use this for progressive enhancement and clear loading/empty states.
 *
 *   <ProtectedRoute requireOwner>
 *     <OwnerDashboard />
 *   </ProtectedRoute>
 */

import { useEffect, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import { useAuth } from "@/hooks/useAuth";

export type ProtectedRouteProps = {
  children: ReactNode;
  /** Require any signed-in user */
  requireAuth?: boolean;
  /** Require profiles.role === 'owner' */
  requireOwner?: boolean;
  /** Where to send unauthenticated users */
  loginHref?: string;
  /** Where to send authenticated non-owners */
  forbiddenHref?: string;
  /** Optional custom loading UI */
  loadingFallback?: ReactNode;
  /** Optional custom forbidden UI (instead of redirect) */
  forbiddenFallback?: ReactNode;
};

export function ProtectedRoute({
  children,
  requireAuth = true,
  requireOwner = false,
  loginHref = "/?auth=required",
  forbiddenHref = "/?error=forbidden",
  loadingFallback,
  forbiddenFallback,
}: ProtectedRouteProps) {
  const { isLoading, isProfileLoading, isAuthenticated, isOwner } = useAuth();
  const router = useRouter();

  const waiting = isLoading || (isAuthenticated && isProfileLoading);

  useEffect(() => {
    if (waiting) return;

    if (requireAuth && !isAuthenticated) {
      router.replace(loginHref);
      return;
    }

    if (requireOwner && !isOwner) {
      if (!forbiddenFallback) {
        router.replace(forbiddenHref);
      }
    }
  }, [
    waiting,
    requireAuth,
    requireOwner,
    isAuthenticated,
    isOwner,
    router,
    loginHref,
    forbiddenHref,
    forbiddenFallback,
  ]);

  if (waiting) {
    return (
      <>
        {loadingFallback ?? (
          <div className="sb-protected-loading" role="status" aria-live="polite">
            <div className="sb-spinner" aria-hidden />
            <p>Checking access…</p>
          </div>
        )}
      </>
    );
  }

  if (requireAuth && !isAuthenticated) {
    return null;
  }

  if (requireOwner && !isOwner) {
    return (
      <>
        {forbiddenFallback ?? (
          <div className="sb-protected-loading" role="alert">
            <p>You don’t have access to this area.</p>
          </div>
        )}
      </>
    );
  }

  return <>{children}</>;
}
