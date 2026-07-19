"use client";

/**
 * Public home — auth demo + booking gate + banners for middleware redirects.
 */

import { Suspense, useEffect, useState, type CSSProperties } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";

import { requestBooking } from "@/components/booking/BookingAuthGate";
import { useAuth } from "@/hooks/useAuth";

function HomeContent() {
  const searchParams = useSearchParams();
  const {
    user,
    profile,
    isLoading,
    isProfileLoading,
    isAuthenticated,
    isOwner,
    openAuthModal,
    error: authError,
  } = useAuth();

  const [banner, setBanner] = useState<string | null>(null);
  const [bannerTone, setBannerTone] = useState<"info" | "error">("info");

  useEffect(() => {
    const auth = searchParams.get("auth");
    const err = searchParams.get("error");
    const next = searchParams.get("next");

    if (auth === "required") {
      setBannerTone("info");
      setBanner(
        next?.startsWith("/admin")
          ? "Sign in with an owner account to access Admin."
          : "Sign in to continue."
      );
      openAuthModal("sign-in");
    } else if (err === "forbidden") {
      setBannerTone("error");
      setBanner("You don’t have permission to view that page.");
    }
  }, [searchParams, openAuthModal]);

  return (
    <main
      style={{
        maxWidth: 560,
        margin: "0 auto",
        padding: "2rem 1.25rem 3rem",
        display: "flex",
        flexDirection: "column",
        gap: "1.25rem",
      }}
    >
      <header>
        <p style={{ margin: 0, color: "var(--sb-text-secondary)", fontSize: 14 }}>
          SlotBook · P0 Protected routes
        </p>
        <h1 style={{ margin: "0.35rem 0 0", fontSize: "1.75rem", letterSpacing: "-0.03em" }}>
          Home
        </h1>
      </header>

      {banner && (
        <div
          className={`sb-banner ${bannerTone === "error" ? "sb-banner-error" : "sb-banner-info"}`}
          role="status"
        >
          {banner}
        </div>
      )}

      {authError && (
        <div className="sb-banner sb-banner-error" role="alert">
          {authError}
        </div>
      )}

      <section style={card}>
        {isLoading || isProfileLoading ? (
          <p style={{ margin: 0, color: "var(--sb-text-secondary)" }}>
            {isLoading ? "Restoring session…" : "Loading profile…"}
          </p>
        ) : isAuthenticated ? (
          <div style={{ display: "grid", gap: 8 }}>
            <p style={{ margin: 0 }}>
              Signed in as{" "}
              <strong>{profile?.full_name || user?.email || user?.phone}</strong>
            </p>
            <p style={{ margin: 0, color: "var(--sb-text-secondary)", fontSize: 14 }}>
              Role: <strong>{profile?.role ?? "customer"}</strong>
              {isOwner ? " · Owner tools available" : ""}
            </p>
            {isOwner && (
              <Link
                href="/admin"
                style={{
                  ...btnPrimary,
                  display: "inline-block",
                  textAlign: "center",
                  textDecoration: "none",
                }}
              >
                Open admin
              </Link>
            )}
          </div>
        ) : (
          <div style={{ display: "grid", gap: 10 }}>
            <p style={{ margin: 0, color: "var(--sb-text-secondary)", fontSize: 14 }}>
              Browsing as guest — book without an account, or sign in to save reservations.
            </p>
            <button type="button" onClick={() => openAuthModal("sign-in")} style={btnPrimary}>
              Sign in / Sign up
            </button>
          </div>
        )}
      </section>

      <section style={{ ...card, display: "grid", gap: 12 }}>
        <div>
          <h2 style={{ margin: 0, fontSize: "1.05rem" }}>Book a slot</h2>
          <p style={{ margin: "0.35rem 0 0", color: "var(--sb-text-secondary)", fontSize: 14 }}>
            Hybrid flow: guest or signed-in. Use real seeded IDs against your Supabase project.
          </p>
        </div>
        <button
          type="button"
          style={btnPrimary}
          onClick={() =>
            requestBooking({
              storeId: "00000000-0000-0000-0000-000000000010",
              itemId: "00000000-0000-0000-0000-000000000020",
              timeSlotId: "00000000-0000-0000-0000-000000000030",
              itemName: "Morning Flow Yoga",
              slotLabel: "Tomorrow · 9:00 – 9:30 AM",
            })
          }
        >
          Book selected slot
        </button>
      </section>
    </main>
  );
}

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <main style={{ padding: "3rem 1.25rem", textAlign: "center", color: "var(--sb-text-secondary)" }}>
          Loading…
        </main>
      }
    >
      <HomeContent />
    </Suspense>
  );
}

const card: CSSProperties = {
  border: "1px solid var(--sb-border)",
  borderRadius: 16,
  padding: "1.25rem",
  background: "var(--sb-card)",
};

const btnPrimary: CSSProperties = {
  border: "none",
  borderRadius: 12,
  padding: "0.8rem 1rem",
  fontWeight: 600,
  background: "var(--sb-primary)",
  color: "#fff",
  cursor: "pointer",
};
