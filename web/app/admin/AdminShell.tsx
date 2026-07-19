"use client";

/**
 * Admin chrome: sidebar navigation + shared store context.
 */

import type { ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

import { ProtectedRoute } from "@/components/auth/ProtectedRoute";
import { AdminStoreProvider, useAdminStore } from "@/lib/admin/AdminStoreContext";

import styles from "./admin.module.css";

const NAV = [
  { href: "/admin", label: "Dashboard", match: (p: string) => p === "/admin" },
  {
    href: "/admin/bookings",
    label: "Bookings",
    match: (p: string) => p.startsWith("/admin/bookings"),
  },
  {
    href: "/admin/items",
    label: "Items",
    match: (p: string) => p.startsWith("/admin/items"),
  },
  {
    href: "/admin/settings",
    label: "Settings",
    match: (p: string) => p.startsWith("/admin/settings"),
  },
] as const;

function ShellInner({
  children,
  ownerName,
}: {
  children: ReactNode;
  ownerName: string;
}) {
  const pathname = usePathname();
  const { store, loading, error } = useAdminStore();

  return (
    <div className={styles.shell}>
      <aside className={styles.aside} aria-label="Admin navigation">
        <p className={styles.asideLabel}>Owner</p>
        <p className={styles.asideName}>{ownerName}</p>
        <p className={styles.asideStore}>
          {loading ? "Loading store…" : store ? store.name : "No store"}
        </p>
        <nav className={styles.asideNav}>
          {NAV.map((item) => {
            const active = item.match(pathname);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`${styles.asideLink} ${active ? styles.asideLinkActive : ""}`}
                aria-current={active ? "page" : undefined}
              >
                {item.label}
              </Link>
            );
          })}
          <Link href="/" className={styles.asideLinkMuted}>
            ← Back to site
          </Link>
        </nav>
      </aside>

      <div className={styles.main}>
        {error && !store && (
          <div className={styles.error} role="alert">
            {error}
          </div>
        )}
        {children}
      </div>
    </div>
  );
}

export function AdminShell({
  children,
  ownerName,
}: {
  children: ReactNode;
  ownerName: string;
}) {
  return (
    <ProtectedRoute requireOwner>
      <AdminStoreProvider>
        <ShellInner ownerName={ownerName}>{children}</ShellInner>
      </AdminStoreProvider>
    </ProtectedRoute>
  );
}
