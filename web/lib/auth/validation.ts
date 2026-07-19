/**
 * Lightweight form validation for auth + guest booking.
 * No external deps — keep the auth surface small.
 */

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Digits only, optional leading +. */
export function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

/** Format US-style as the user types: (555) 123-4567 */
export function formatPhoneMask(raw: string): string {
  const d = digitsOnly(raw).slice(0, 10);
  if (d.length === 0) return "";
  if (d.length < 4) return `(${d}`;
  if (d.length < 7) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
  return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
}

/**
 * Normalize to E.164 for Supabase phone auth.
 * Assumes US (+1) when 10 digits are provided.
 */
export function toE164(phone: string, defaultCountry = "1"): string | null {
  const d = digitsOnly(phone);
  if (d.length === 10) return `+${defaultCountry}${d}`;
  if (d.length === 11 && d.startsWith("1")) return `+${d}`;
  if (phone.trim().startsWith("+") && d.length >= 10 && d.length <= 15) {
    return `+${d}`;
  }
  return null;
}

export function validateEmail(email: string): string | null {
  const v = email.trim();
  if (!v) return "Email is required";
  if (!EMAIL_RE.test(v)) return "Enter a valid email address";
  return null;
}

export function validatePassword(password: string): string | null {
  if (!password) return "Password is required";
  if (password.length < 8) return "Use at least 8 characters";
  return null;
}

export function validateFullName(name: string): string | null {
  const v = name.trim();
  if (!v) return "Name is required";
  if (v.length < 2) return "Enter at least 2 characters";
  return null;
}

export function validatePhone(phone: string): string | null {
  if (!phone.trim()) return "Phone number is required";
  if (!toE164(phone)) return "Enter a valid phone number";
  return null;
}

export function validateOtp(code: string): string | null {
  const d = digitsOnly(code);
  if (d.length < 6) return "Enter the 6-digit code";
  return null;
}
