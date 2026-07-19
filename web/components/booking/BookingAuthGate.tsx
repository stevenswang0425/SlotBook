"use client";

/**
 * BookingAuthGate
 * ---------------
 * Call `startBooking(draft)` when the user taps "Book selected slot".
 *
 * Flow:
 * 1. If authenticated → confirm as user (optional contact fields prefilled).
 * 2. If guest → choice modal: Continue as Guest | Sign In / Sign Up.
 * 3. Guest path → GuestBookingForm → createGuestBooking (user_id null).
 * 4. Sign-in path → AuthModal with booking intent → after auth, confirm as user.
 */

import { useCallback, useEffect, useId, useState } from "react";

import { GuestBookingForm } from "@/components/booking/GuestBookingForm";
import { useAuth } from "@/hooks/useAuth";
import type { BookingDraftInput } from "@/lib/auth/types";
import { createUserBooking } from "@/lib/booking/createBooking";
import { createClient } from "@/lib/supabase/client";
import type { Booking } from "@/lib/types";

import styles from "@/components/auth/auth.module.css";

type GateStep = "choice" | "guest-form" | "user-confirm" | "success";

export type BookingAuthGateProps = {
  /** Called after a successful booking (guest or user). */
  onBooked?: (booking: Booking | null) => void;
  /** Optional controlled close callback when the user dismisses. */
  onDismiss?: () => void;
};

export type BookingAuthGateHandle = {
  startBooking: (draft: BookingDraftInput) => void;
};

/**
 * Headless controller + modal UI for the hybrid booking entry.
 * Render once near the app root (inside AuthProvider) or on the item detail page.
 */
export function BookingAuthGate({ onBooked, onDismiss }: BookingAuthGateProps) {
  const {
    user,
    profile,
    isAuthenticated,
    isLoading,
    isProfileLoading,
    openAuthModal,
    authModal,
  } = useAuth();

  const titleId = useId();
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState<GateStep>("choice");
  const [draft, setDraft] = useState<BookingDraftInput | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [completed, setCompleted] = useState<Booking | null>(null);

  // Resume user booking after AuthModal success during a booking intent.
  // Wait until profile load finishes so we can prefill contact fields.
  useEffect(() => {
    if (!isAuthenticated || !user || !draft) return;
    if (authModal.open) return;
    if (!open) return;
    if (isProfileLoading) return;
    if (step === "guest-form" || step === "success") return;

    setStep("user-confirm");
  }, [isAuthenticated, user, draft, authModal.open, open, step, isProfileLoading]);

  const close = useCallback(() => {
    setOpen(false);
    setStep("choice");
    setDraft(null);
    setError(null);
    setSubmitting(false);
    setCompleted(null);
    onDismiss?.();
  }, [onDismiss]);

  const startBooking = useCallback(
    (next: BookingDraftInput) => {
      setDraft(next);
      setError(null);
      setCompleted(null);
      setOpen(true);

      if (isLoading) {
        setStep("choice");
        return;
      }

      if (isAuthenticated) {
        setStep("user-confirm");
      } else {
        setStep("choice");
      }
    },
    [isAuthenticated, isLoading]
  );

  // Expose startBooking for parent via custom event (avoids forwardRef complexity)
  useEffect(() => {
    const handler = (event: Event) => {
      const custom = event as CustomEvent<BookingDraftInput>;
      if (custom.detail) startBooking(custom.detail);
    };
    window.addEventListener("slotbook:start-booking", handler);
    return () => window.removeEventListener("slotbook:start-booking", handler);
  }, [startBooking]);

  const confirmAsUser = async () => {
    if (!user || !draft) return;
    setSubmitting(true);
    setError(null);

    const supabase = createClient();
    const result = await createUserBooking(supabase, user.id, draft, {
      guestName: profile?.full_name ?? undefined,
      guestPhone: profile?.phone ?? undefined,
      guestEmail: profile?.email ?? user.email ?? undefined,
    });

    setSubmitting(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }

    setCompleted(result.booking);
    setStep("success");
    onBooked?.(result.booking);
  };

  if (!open || !draft) return null;

  return (
    <div
      className={styles.overlay}
      role="presentation"
      onClick={(e) => {
        if (e.target === e.currentTarget && !submitting) close();
      }}
    >
      <div
        className={styles.modal}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
      >
        <div className={styles.header}>
          <div>
            <h2 id={titleId} className={styles.title}>
              {step === "choice" && "Complete your booking"}
              {step === "guest-form" && "Guest details"}
              {step === "user-confirm" && "Confirm booking"}
              {step === "success" && "You're booked"}
            </h2>
            <p className={styles.subtitle}>
              {step === "choice" &&
                "Continue as a guest or sign in to save this reservation."}
              {step === "guest-form" && "No account needed — just a few details."}
              {step === "user-confirm" && "Review and confirm your reservation."}
              {step === "success" && "We've reserved your slot."}
            </p>
          </div>
          <button
            type="button"
            className={styles.close}
            onClick={close}
            aria-label="Close"
            disabled={submitting}
          >
            ×
          </button>
        </div>

        <div className={styles.body}>
          {(draft.itemName || draft.slotLabel) && step !== "success" && (
            <div className={styles.summary}>
              {draft.itemName && (
                <div>
                  <strong>{draft.itemName}</strong>
                </div>
              )}
              {draft.slotLabel && <div>{draft.slotLabel}</div>}
            </div>
          )}

          {error && (
            <div className={`${styles.banner} ${styles.bannerError}`} role="alert">
              {error}
            </div>
          )}

          {step === "choice" && (
            <div className={styles.stack}>
              <button
                type="button"
                className={styles.choiceCard}
                onClick={() => setStep("guest-form")}
              >
                <span className={styles.choiceTitle}>Continue as Guest</span>
                <span className={styles.choiceDesc}>
                  Book quickly with your name and phone. No account required.
                </span>
              </button>

              <button
                type="button"
                className={styles.choiceCard}
                onClick={() => {
                  openAuthModal("sign-in", { type: "booking", draft });
                }}
              >
                <span className={styles.choiceTitle}>Sign In / Sign Up</span>
                <span className={styles.choiceDesc}>
                  Save this booking to your account and manage it later.
                </span>
              </button>

              <button type="button" className={styles.ghostBtn} onClick={close}>
                Not now
              </button>
            </div>
          )}

          {step === "guest-form" && (
            <GuestBookingForm
              draft={draft}
              onBack={() => setStep("choice")}
              onCancel={close}
              onSuccess={(booking) => {
                setCompleted(booking);
                setStep("success");
                onBooked?.(booking);
              }}
            />
          )}

          {step === "user-confirm" && (
            <div className={styles.stack}>
              {isProfileLoading ? (
                <p className={styles.footerNote} role="status">
                  Loading your profile…
                </p>
              ) : (
                <div className={styles.summary}>
                  <div>
                    Signed in as{" "}
                    <strong>
                      {profile?.full_name || profile?.email || user?.email || "member"}
                    </strong>
                  </div>
                  {profile?.role && (
                    <div style={{ marginTop: 4, opacity: 0.8 }}>
                      Role: {profile.role}
                    </div>
                  )}
                </div>
              )}

              <button
                type="button"
                className={styles.primaryBtn}
                disabled={submitting || isProfileLoading}
                onClick={() => void confirmAsUser()}
              >
                {submitting ? "Confirming…" : "Confirm booking"}
              </button>
              <button
                type="button"
                className={styles.ghostBtn}
                disabled={submitting}
                onClick={close}
              >
                Cancel
              </button>
            </div>
          )}

          {step === "success" && (
            <div className={styles.stack}>
              <div className={`${styles.banner} ${styles.bannerSuccess}`} role="status">
                {completed?.reference_code
                  ? `Reference ${completed.reference_code}`
                  : "Your reservation is confirmed."}
              </div>
              <button type="button" className={styles.primaryBtn} onClick={close}>
                Done
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/** Imperative helper — dispatch from any client component. */
export function requestBooking(draft: BookingDraftInput) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(
    new CustomEvent<BookingDraftInput>("slotbook:start-booking", { detail: draft })
  );
}
