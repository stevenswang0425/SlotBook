"use client";

/**
 * Guest booking form — name + phone (email optional).
 * Submits with user_id = null via createGuestBooking.
 */

import { useState, type FormEvent } from "react";

import type { BookingDraftInput, GuestBookingInput } from "@/lib/auth/types";
import {
  formatPhoneMask,
  validateEmail,
  validateFullName,
  validatePhone,
} from "@/lib/auth/validation";
import { createGuestBooking } from "@/lib/booking/createBooking";
import { createClient } from "@/lib/supabase/client";
import type { Booking } from "@/lib/types";

import styles from "@/components/auth/auth.module.css";

export type GuestBookingFormProps = {
  draft: BookingDraftInput;
  onSuccess: (booking: Booking | null, referenceHint?: string) => void;
  onBack?: () => void;
  onCancel?: () => void;
};

export function GuestBookingForm({
  draft,
  onSuccess,
  onBack,
  onCancel,
}: GuestBookingFormProps) {
  const [guestName, setGuestName] = useState("");
  const [guestPhone, setGuestPhone] = useState("");
  const [guestEmail, setGuestEmail] = useState("");
  const [errors, setErrors] = useState<{
    guestName?: string;
    guestPhone?: string;
    guestEmail?: string;
  }>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();

    const nextErrors = {
      guestName: validateFullName(guestName) ?? undefined,
      guestPhone: validatePhone(guestPhone) ?? undefined,
      guestEmail: guestEmail.trim()
        ? (validateEmail(guestEmail) ?? undefined)
        : undefined,
    };
    setErrors(nextErrors);
    if (Object.values(nextErrors).some(Boolean)) return;

    const guest: GuestBookingInput = {
      guestName: guestName.trim(),
      guestPhone: guestPhone.trim(),
      guestEmail: guestEmail.trim() || undefined,
    };

    setSubmitting(true);
    setFormError(null);

    const supabase = createClient();
    const result = await createGuestBooking(supabase, draft, guest);

    setSubmitting(false);

    if (!result.ok) {
      setFormError(result.error);
      return;
    }

    onSuccess(result.booking);
  };

  return (
    <form className={styles.stack} onSubmit={onSubmit} noValidate>
      {(draft.itemName || draft.slotLabel) && (
        <div className={styles.summary}>
          {draft.itemName && (
            <div>
              <strong>{draft.itemName}</strong>
            </div>
          )}
          {draft.slotLabel && <div>{draft.slotLabel}</div>}
          <div style={{ marginTop: 6, opacity: 0.85 }}>Booking as guest</div>
        </div>
      )}

      {formError && (
        <div className={`${styles.banner} ${styles.bannerError}`} role="alert">
          {formError}
        </div>
      )}

      <div className={styles.field}>
        <label className={styles.label} htmlFor="guest-name">
          Full name
        </label>
        <input
          id="guest-name"
          className={`${styles.input} ${errors.guestName ? styles.inputError : ""}`}
          autoComplete="name"
          value={guestName}
          onChange={(e) => setGuestName(e.target.value)}
          disabled={submitting}
          required
        />
        {errors.guestName && (
          <p className={styles.fieldError}>{errors.guestName}</p>
        )}
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="guest-phone">
          Phone number
        </label>
        <input
          id="guest-phone"
          type="tel"
          className={`${styles.input} ${errors.guestPhone ? styles.inputError : ""}`}
          autoComplete="tel"
          placeholder="(555) 123-4567"
          value={guestPhone}
          onChange={(e) => setGuestPhone(formatPhoneMask(e.target.value))}
          disabled={submitting}
          required
        />
        {errors.guestPhone && (
          <p className={styles.fieldError}>{errors.guestPhone}</p>
        )}
      </div>

      <div className={styles.field}>
        <label className={styles.label} htmlFor="guest-email">
          Email <span style={{ fontWeight: 400 }}>(optional)</span>
        </label>
        <input
          id="guest-email"
          type="email"
          className={`${styles.input} ${errors.guestEmail ? styles.inputError : ""}`}
          autoComplete="email"
          value={guestEmail}
          onChange={(e) => setGuestEmail(e.target.value)}
          disabled={submitting}
        />
        {errors.guestEmail && (
          <p className={styles.fieldError}>{errors.guestEmail}</p>
        )}
      </div>

      <button type="submit" className={styles.primaryBtn} disabled={submitting}>
        {submitting ? "Booking…" : "Confirm guest booking"}
      </button>

      <div className={styles.stack}>
        {onBack && (
          <button
            type="button"
            className={styles.secondaryBtn}
            onClick={onBack}
            disabled={submitting}
          >
            Back
          </button>
        )}
        {onCancel && (
          <button
            type="button"
            className={styles.ghostBtn}
            onClick={onCancel}
            disabled={submitting}
          >
            Cancel
          </button>
        )}
      </div>

      <p className={styles.footerNote}>
        No account required. We only use your details for this reservation.
      </p>
    </form>
  );
}
