/**
 * Map Supabase Auth errors to calm, user-facing copy.
 */

export function friendlyAuthError(error: unknown): string {
  if (!error) return "Something went wrong. Please try again.";

  const message =
    typeof error === "object" && error !== null && "message" in error
      ? String((error as { message: string }).message)
      : String(error);

  const lower = message.toLowerCase();

  if (lower.includes("invalid login credentials")) {
    return "Email or password is incorrect.";
  }
  if (lower.includes("user already registered")) {
    return "An account with this email already exists. Try signing in.";
  }
  if (lower.includes("email not confirmed")) {
    return "Confirm your email before signing in. Check your inbox.";
  }
  if (lower.includes("otp") || lower.includes("token")) {
    return "That code is invalid or expired. Request a new one.";
  }
  if (lower.includes("phone")) {
    return "We couldn't verify that phone number. Check the format and try again.";
  }
  if (lower.includes("rate limit") || lower.includes("too many")) {
    return "Too many attempts. Wait a moment and try again.";
  }
  if (lower.includes("network") || lower.includes("fetch")) {
    return "Network error. Check your connection and try again.";
  }

  return message || "Something went wrong. Please try again.";
}
