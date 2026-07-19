"use client";

/**
 * Global app header — wordmark + user menu.
 */

import Link from "next/link";

import { UserMenu } from "@/components/layout/UserMenu";
import { useAuth } from "@/hooks/useAuth";

import styles from "./header.module.css";

export function SiteHeader() {
  const { isOwner } = useAuth();

  return (
    <header className={styles.header}>
      <div className={styles.inner}>
        <Link href="/" className={styles.brand} aria-label="SlotBook home">
          <span className={styles.brandMark} aria-hidden>
            ◌
          </span>
          <span className={styles.brandName}>SlotBook</span>
        </Link>

        <nav className={styles.nav} aria-label="Primary">
          <Link href="/" className={styles.navLink}>
            Home
          </Link>
          {isOwner && (
            <Link href="/admin" className={styles.navLink}>
              Admin
            </Link>
          )}
        </nav>

        <UserMenu />
      </div>
    </header>
  );
}
