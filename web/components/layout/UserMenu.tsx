"use client";

/**
 * Compact avatar + dropdown: account label, optional Admin link, Sign out.
 */

import { useEffect, useId, useRef, useState } from "react";
import Link from "next/link";

import { useAuth } from "@/hooks/useAuth";

import styles from "./header.module.css";

function initials(name: string | null | undefined, email: string | null | undefined): string {
  if (name?.trim()) {
    const parts = name.trim().split(/\s+/);
    return parts
      .slice(0, 2)
      .map((p) => p[0]?.toUpperCase() ?? "")
      .join("");
  }
  if (email) return email[0]?.toUpperCase() ?? "?";
  return "?";
}

export function UserMenu() {
  const { user, profile, isLoading, isAuthenticated, isOwner, openAuthModal, signOut } =
    useAuth();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const menuId = useId();

  useEffect(() => {
    if (!open) return;
    const onPointer = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("mousedown", onPointer);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("mousedown", onPointer);
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  if (isLoading) {
    return <div className={styles.avatarSkeleton} aria-hidden />;
  }

  if (!isAuthenticated) {
    return (
      <button
        type="button"
        className={styles.signInBtn}
        onClick={() => openAuthModal("sign-in")}
      >
        Sign in
      </button>
    );
  }

  const label = profile?.full_name || profile?.email || user?.email || user?.phone || "Account";
  const avatarText = initials(profile?.full_name, profile?.email ?? user?.email);

  return (
    <div className={styles.userMenu} ref={rootRef}>
      <button
        type="button"
        className={styles.avatarBtn}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={menuId}
        onClick={() => setOpen((v) => !v)}
      >
        <span className={styles.avatar} aria-hidden>
          {avatarText}
        </span>
        <span className={styles.avatarLabel}>{label}</span>
      </button>

      {open && (
        <div className={styles.dropdown} role="menu" id={menuId}>
          <div className={styles.dropdownMeta}>
            <div className={styles.dropdownName}>{label}</div>
            <div className={styles.dropdownRole}>
              {isOwner ? "Owner" : "Customer"}
            </div>
          </div>

          {isOwner && (
            <Link
              href="/admin"
              role="menuitem"
              className={styles.dropdownItem}
              onClick={() => setOpen(false)}
            >
              Admin dashboard
            </Link>
          )}

          <button
            type="button"
            role="menuitem"
            className={styles.dropdownItem}
            onClick={() => {
              setOpen(false);
              void signOut();
            }}
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  );
}
