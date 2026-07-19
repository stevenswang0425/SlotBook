"use client";

/**
 * AuthProvider — session, profile, roles, modal control.
 *
 * - Loads session on mount with a dedicated loading flag
 * - Ensures a profiles row exists (auto-create customer on first sign-in)
 * - Exposes role helpers (isOwner / isCustomer)
 */

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { Session, User } from "@supabase/supabase-js";

import { friendlyAuthError } from "@/lib/auth/errors";
import type {
  AuthActionResult,
  AuthIntent,
  AuthMode,
  AuthModalState,
  EmailCredentials,
} from "@/lib/auth/types";
import { toE164 } from "@/lib/auth/validation";
import { createClient } from "@/lib/supabase/client";
import type { Profile, UserRole } from "@/lib/types";

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

export type AuthContextValue = {
  user: User | null;
  session: Session | null;
  profile: Profile | null;
  /** True until the first session + profile resolution finishes. */
  isLoading: boolean;
  /** True while profile is being fetched/created after a session exists. */
  isProfileLoading: boolean;
  isAuthenticated: boolean;
  role: UserRole | null;
  isOwner: boolean;
  isCustomer: boolean;
  /** Last profile/auth error (non-blocking). */
  error: string | null;

  signInWithEmail: (creds: EmailCredentials) => Promise<AuthActionResult>;
  signUpWithEmail: (creds: EmailCredentials) => Promise<AuthActionResult>;
  sendPhoneOtp: (phone: string) => Promise<AuthActionResult>;
  verifyPhoneOtp: (phone: string, token: string) => Promise<AuthActionResult>;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<Profile | null>;

  authModal: AuthModalState;
  openAuthModal: (mode?: AuthMode, intent?: AuthIntent) => void;
  closeAuthModal: () => void;
  setAuthModalMode: (mode: AuthMode) => void;

  /** Convenience: require auth, open modal if missing. Returns false if not signed in. */
  requireAuth: (intent?: AuthIntent) => boolean;
};

const AuthContext = createContext<AuthContextValue | null>(null);

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

export function AuthProvider({ children }: { children: ReactNode }) {
  const supabase = useMemo(() => createClient(), []);

  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isProfileLoading, setIsProfileLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [authModal, setAuthModal] = useState<AuthModalState>({
    open: false,
    mode: "sign-in",
    intent: { type: "standalone" },
  });

  const bootstrapped = useRef(false);

  /**
   * Load profile; if missing, create a customer row (first-login heal).
   * Role is never escalated to owner from the client.
   */
  const ensureProfile = useCallback(
    async (authUser: User): Promise<Profile | null> => {
      setIsProfileLoading(true);
      setError(null);

      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const client = supabase as any;

        const { data: existing, error: selectError } = await client
          .from("profiles")
          .select("*")
          .eq("id", authUser.id)
          .maybeSingle();

        if (selectError) {
          console.error("[AuthProvider] profile select failed", selectError);
          setError("Couldn't load your profile.");
          setProfile(null);
          return null;
        }

        if (existing) {
          setProfile(existing as Profile);
          return existing as Profile;
        }

        // Auto-create on first sign-in (trigger may have raced or failed).
        const fullName =
          (authUser.user_metadata?.full_name as string | undefined) ??
          (authUser.user_metadata?.name as string | undefined) ??
          null;

        const { data: created, error: upsertError } = await client
          .from("profiles")
          .upsert(
            {
              id: authUser.id,
              email: authUser.email ?? null,
              full_name: fullName,
              phone: authUser.phone ?? null,
              role: "customer",
            },
            { onConflict: "id" }
          )
          .select("*")
          .maybeSingle();

        if (upsertError) {
          console.error("[AuthProvider] profile upsert failed", upsertError);
          setError("Couldn't create your profile. Try refreshing.");
          setProfile(null);
          return null;
        }

        setProfile((created as Profile) ?? null);
        return (created as Profile) ?? null;
      } finally {
        setIsProfileLoading(false);
      }
    },
    [supabase]
  );

  const refreshProfile = useCallback(async () => {
    if (!user) {
      setProfile(null);
      return null;
    }
    return ensureProfile(user);
  }, [ensureProfile, user]);

  // ----- Session bootstrap --------------------------------------------------

  useEffect(() => {
    let mounted = true;

    const finishBoot = () => {
      if (mounted) {
        setIsLoading(false);
        bootstrapped.current = true;
      }
    };

    supabase.auth
      .getSession()
      .then(async ({ data }) => {
        if (!mounted) return;
        setSession(data.session ?? null);
        const nextUser = data.session?.user ?? null;
        setUser(nextUser);
        if (nextUser) {
          await ensureProfile(nextUser);
        }
      })
      .catch((err) => {
        console.error("[AuthProvider] getSession failed", err);
        setError("Couldn't restore your session.");
      })
      .finally(finishBoot);

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, nextSession) => {
      if (!mounted) return;

      setSession(nextSession);
      const nextUser = nextSession?.user ?? null;
      setUser(nextUser);

      if (nextUser) {
        // Defer profile work so we don't deadlock with auth lock
        // (Supabase recommendation: avoid await in callback body).
        queueMicrotask(() => {
          void ensureProfile(nextUser);
        });
      } else {
        setProfile(null);
      }

      // Close auth modal after successful sign-in/up
      if (
        event === "SIGNED_IN" ||
        event === "USER_UPDATED" ||
        event === "TOKEN_REFRESHED"
      ) {
        setAuthModal((prev) =>
          prev.open && prev.mode !== "phone" ? { ...prev, open: false } : prev
        );
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [supabase, ensureProfile]);

  // ----- Auth actions -------------------------------------------------------

  const signUpWithEmail = useCallback(
    async (creds: EmailCredentials): Promise<AuthActionResult> => {
      const { data, error } = await supabase.auth.signUp({
        email: creds.email.trim(),
        password: creds.password,
        options: {
          data: {
            full_name: creds.fullName?.trim() ?? null,
            role: "customer",
          },
        },
      });

      if (error) return { ok: false, error: friendlyAuthError(error) };

      // If email confirmation is off, session exists immediately — ensure profile.
      if (data.user) {
        await ensureProfile(data.user);
      }

      return {
        ok: true,
        message: data.session
          ? "Account created. You're signed in."
          : "Account created. Check your email to confirm if verification is enabled.",
      };
    },
    [supabase, ensureProfile]
  );

  const signInWithEmail = useCallback(
    async (creds: EmailCredentials): Promise<AuthActionResult> => {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: creds.email.trim(),
        password: creds.password,
      });

      if (error) return { ok: false, error: friendlyAuthError(error) };

      if (data.user) {
        await ensureProfile(data.user);
      }

      return { ok: true };
    },
    [supabase, ensureProfile]
  );

  const sendPhoneOtp = useCallback(
    async (phone: string): Promise<AuthActionResult> => {
      const e164 = toE164(phone);
      if (!e164) return { ok: false, error: "Enter a valid phone number." };

      const { error } = await supabase.auth.signInWithOtp({
        phone: e164,
        options: { data: { role: "customer" } },
      });

      if (error) return { ok: false, error: friendlyAuthError(error) };
      return { ok: true, message: "Code sent. Enter it below." };
    },
    [supabase]
  );

  const verifyPhoneOtp = useCallback(
    async (phone: string, token: string): Promise<AuthActionResult> => {
      const e164 = toE164(phone);
      if (!e164) return { ok: false, error: "Enter a valid phone number." };

      const { data, error } = await supabase.auth.verifyOtp({
        phone: e164,
        token: token.trim(),
        type: "sms",
      });

      if (error) return { ok: false, error: friendlyAuthError(error) };

      if (data.user) {
        await ensureProfile(data.user);
      }

      return { ok: true };
    },
    [supabase, ensureProfile]
  );

  const signOut = useCallback(async () => {
    setError(null);
    await supabase.auth.signOut();
    setUser(null);
    setSession(null);
    setProfile(null);
  }, [supabase]);

  // ----- Modal --------------------------------------------------------------

  const openAuthModal = useCallback(
    (mode: AuthMode = "sign-in", intent: AuthIntent = { type: "standalone" }) => {
      setAuthModal({ open: true, mode, intent });
    },
    []
  );

  const closeAuthModal = useCallback(() => {
    setAuthModal((prev) => ({ ...prev, open: false }));
  }, []);

  const setAuthModalMode = useCallback((mode: AuthMode) => {
    setAuthModal((prev) => ({ ...prev, mode }));
  }, []);

  const requireAuth = useCallback(
    (intent: AuthIntent = { type: "standalone" }) => {
      if (user) return true;
      openAuthModal("sign-in", intent);
      return false;
    },
    [user, openAuthModal]
  );

  // ----- Derived ------------------------------------------------------------

  const role = profile?.role ?? null;

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      session,
      profile,
      isLoading,
      isProfileLoading,
      isAuthenticated: !!user,
      role,
      isOwner: role === "owner",
      isCustomer: role === "customer",
      error,
      signInWithEmail,
      signUpWithEmail,
      sendPhoneOtp,
      verifyPhoneOtp,
      signOut,
      refreshProfile,
      authModal,
      openAuthModal,
      closeAuthModal,
      setAuthModalMode,
      requireAuth,
    }),
    [
      user,
      session,
      profile,
      isLoading,
      isProfileLoading,
      role,
      error,
      signInWithEmail,
      signUpWithEmail,
      sendPhoneOtp,
      verifyPhoneOtp,
      signOut,
      refreshProfile,
      authModal,
      openAuthModal,
      closeAuthModal,
      setAuthModalMode,
      requireAuth,
    ]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within <AuthProvider>");
  }
  return ctx;
}
