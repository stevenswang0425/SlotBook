"use client";

/**
 * AuthModal — Sign in / Sign up / Phone OTP.
 *
 * Controlled by AuthProvider (`openAuthModal` / `closeAuthModal`).
 * Renders nothing when closed.
 */

import { useEffect, useId, useState, type FormEvent } from "react";

import { useAuth } from "@/hooks/useAuth";
import type { AuthMode } from "@/lib/auth/types";
import {
  formatPhoneMask,
  validateEmail,
  validateFullName,
  validateOtp,
  validatePassword,
  validatePhone,
} from "@/lib/auth/validation";

import styles from "./auth.module.css";

type FieldErrors = {
  email?: string;
  password?: string;
  fullName?: string;
  phone?: string;
  otp?: string;
};

export function AuthModal() {
  const {
    authModal,
    closeAuthModal,
    setAuthModalMode,
    signInWithEmail,
    signUpWithEmail,
    sendPhoneOtp,
    verifyPhoneOtp,
  } = useAuth();

  const titleId = useId();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Reset form when mode/open changes
  useEffect(() => {
    if (!authModal.open) return;
    setFieldErrors({});
    setFormError(null);
    setInfo(null);
    setOtp("");
    setSubmitting(false);
  }, [authModal.open, authModal.mode]);

  // Escape to close
  useEffect(() => {
    if (!authModal.open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !submitting) closeAuthModal();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [authModal.open, closeAuthModal, submitting]);

  if (!authModal.open) return null;

  const mode = authModal.mode;
  const isPhoneFlow = mode === "phone" || mode === "phone-verify";

  const switchMode = (next: AuthMode) => {
    setAuthModalMode(next);
    setFormError(null);
    setInfo(null);
    setFieldErrors({});
  };

  const onSubmitEmail = async (e: FormEvent) => {
    e.preventDefault();
    const errors: FieldErrors = {
      email: validateEmail(email) ?? undefined,
      password: validatePassword(password) ?? undefined,
    };
    if (mode === "sign-up") {
      errors.fullName = validateFullName(fullName) ?? undefined;
    }
    setFieldErrors(errors);
    if (Object.values(errors).some(Boolean)) return;

    setSubmitting(true);
    setFormError(null);
    setInfo(null);

    const result =
      mode === "sign-up"
        ? await signUpWithEmail({ email, password, fullName })
        : await signInWithEmail({ email, password });

    setSubmitting(false);

    if (!result.ok) {
      setFormError(result.error);
      return;
    }

    if (result.message) {
      setInfo(result.message);
      // Keep open so user can read confirmation message after sign-up
      if (mode === "sign-in") closeAuthModal();
      return;
    }

    closeAuthModal();
  };

  const onSendOtp = async (e: FormEvent) => {
    e.preventDefault();
    const phoneErr = validatePhone(phone);
    setFieldErrors({ phone: phoneErr ?? undefined });
    if (phoneErr) return;

    setSubmitting(true);
    setFormError(null);
    const result = await sendPhoneOtp(phone);
    setSubmitting(false);

    if (!result.ok) {
      setFormError(result.error);
      return;
    }

    setInfo(result.message ?? "Code sent.");
    switchMode("phone-verify");
  };

  const onVerifyOtp = async (e: FormEvent) => {
    e.preventDefault();
    const errors: FieldErrors = {
      phone: validatePhone(phone) ?? undefined,
      otp: validateOtp(otp) ?? undefined,
    };
    setFieldErrors(errors);
    if (Object.values(errors).some(Boolean)) return;

    setSubmitting(true);
    setFormError(null);
    const result = await verifyPhoneOtp(phone, otp);
    setSubmitting(false);

    if (!result.ok) {
      setFormError(result.error);
      return;
    }

    closeAuthModal();
  };

  return (
    <div
      className={styles.overlay}
      role="presentation"
      onClick={(e) => {
        if (e.target === e.currentTarget && !submitting) closeAuthModal();
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
              {mode === "sign-up" && "Create account"}
              {mode === "sign-in" && "Sign in"}
              {mode === "phone" && "Sign in with phone"}
              {mode === "phone-verify" && "Enter code"}
            </h2>
            <p className={styles.subtitle}>
              {authModal.intent.type === "booking"
                ? "Sign in to save this booking to your account."
                : "Welcome to SlotBook — calm, simple reservations."}
            </p>
          </div>
          <button
            type="button"
            className={styles.close}
            onClick={closeAuthModal}
            aria-label="Close"
            disabled={submitting}
          >
            ×
          </button>
        </div>

        <div className={styles.body}>
          {!isPhoneFlow && (
            <div className={styles.tabs} role="tablist" aria-label="Auth method">
              <button
                type="button"
                role="tab"
                className={`${styles.tab} ${mode === "sign-in" ? styles.tabActive : ""}`}
                aria-selected={mode === "sign-in"}
                onClick={() => switchMode("sign-in")}
              >
                Sign in
              </button>
              <button
                type="button"
                role="tab"
                className={`${styles.tab} ${mode === "sign-up" ? styles.tabActive : ""}`}
                aria-selected={mode === "sign-up"}
                onClick={() => switchMode("sign-up")}
              >
                Sign up
              </button>
            </div>
          )}

          {formError && (
            <div className={`${styles.banner} ${styles.bannerError}`} role="alert">
              {formError}
            </div>
          )}
          {info && (
            <div className={`${styles.banner} ${styles.bannerSuccess}`} role="status">
              {info}
            </div>
          )}

          {(mode === "sign-in" || mode === "sign-up") && (
            <form className={styles.stack} onSubmit={onSubmitEmail} noValidate>
              {mode === "sign-up" && (
                <div className={styles.field}>
                  <label className={styles.label} htmlFor="auth-name">
                    Full name
                  </label>
                  <input
                    id="auth-name"
                    className={`${styles.input} ${fieldErrors.fullName ? styles.inputError : ""}`}
                    autoComplete="name"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    disabled={submitting}
                  />
                  {fieldErrors.fullName && (
                    <p className={styles.fieldError}>{fieldErrors.fullName}</p>
                  )}
                </div>
              )}

              <div className={styles.field}>
                <label className={styles.label} htmlFor="auth-email">
                  Email
                </label>
                <input
                  id="auth-email"
                  type="email"
                  className={`${styles.input} ${fieldErrors.email ? styles.inputError : ""}`}
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={submitting}
                />
                {fieldErrors.email && (
                  <p className={styles.fieldError}>{fieldErrors.email}</p>
                )}
              </div>

              <div className={styles.field}>
                <label className={styles.label} htmlFor="auth-password">
                  Password
                </label>
                <input
                  id="auth-password"
                  type="password"
                  className={`${styles.input} ${fieldErrors.password ? styles.inputError : ""}`}
                  autoComplete={mode === "sign-up" ? "new-password" : "current-password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={submitting}
                />
                {fieldErrors.password && (
                  <p className={styles.fieldError}>{fieldErrors.password}</p>
                )}
              </div>

              <button type="submit" className={styles.primaryBtn} disabled={submitting}>
                {submitting
                  ? "Please wait…"
                  : mode === "sign-up"
                    ? "Create account"
                    : "Sign in"}
              </button>
            </form>
          )}

          {mode === "phone" && (
            <form className={styles.stack} onSubmit={onSendOtp} noValidate>
              <div className={styles.field}>
                <label className={styles.label} htmlFor="auth-phone">
                  Phone number
                </label>
                <input
                  id="auth-phone"
                  type="tel"
                  inputMode="tel"
                  className={`${styles.input} ${fieldErrors.phone ? styles.inputError : ""}`}
                  autoComplete="tel"
                  placeholder="(555) 123-4567"
                  value={phone}
                  onChange={(e) => setPhone(formatPhoneMask(e.target.value))}
                  disabled={submitting}
                />
                {fieldErrors.phone && (
                  <p className={styles.fieldError}>{fieldErrors.phone}</p>
                )}
              </div>
              <button type="submit" className={styles.primaryBtn} disabled={submitting}>
                {submitting ? "Sending…" : "Send code"}
              </button>
            </form>
          )}

          {mode === "phone-verify" && (
            <form className={styles.stack} onSubmit={onVerifyOtp} noValidate>
              <div className={styles.field}>
                <label className={styles.label} htmlFor="auth-otp">
                  6-digit code
                </label>
                <input
                  id="auth-otp"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  className={`${styles.input} ${fieldErrors.otp ? styles.inputError : ""}`}
                  placeholder="123456"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, "").slice(0, 6))}
                  disabled={submitting}
                />
                {fieldErrors.otp && (
                  <p className={styles.fieldError}>{fieldErrors.otp}</p>
                )}
              </div>
              <button type="submit" className={styles.primaryBtn} disabled={submitting}>
                {submitting ? "Verifying…" : "Verify & continue"}
              </button>
              <button
                type="button"
                className={styles.ghostBtn}
                disabled={submitting}
                onClick={() => switchMode("phone")}
              >
                Use a different number
              </button>
            </form>
          )}

          {!isPhoneFlow && (
            <button
              type="button"
              className={styles.secondaryBtn}
              onClick={() => switchMode("phone")}
              disabled={submitting}
            >
              Continue with phone
            </button>
          )}

          {isPhoneFlow && mode === "phone" && (
            <button
              type="button"
              className={styles.ghostBtn}
              onClick={() => switchMode("sign-in")}
              disabled={submitting}
            >
              Use email instead
            </button>
          )}

          <p className={styles.footerNote}>
            New accounts are created as <strong>customers</strong>. Owner access is
            granted separately by an admin.
          </p>
        </div>
      </div>
    </div>
  );
}
