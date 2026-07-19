"use client";

/**
 * Admin Dashboard — overview metrics for the owner's store.
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";

import { useAdminStore } from "@/lib/admin/AdminStoreContext";
import { fetchStoreMetrics } from "@/lib/admin/queries";
import type { AdminMetrics } from "@/lib/admin/types";
import { formatCents } from "@/lib/admin/types";

import styles from "./admin.module.css";

export default function AdminDashboardPage() {
  const { store, loading: storeLoading } = useAdminStore();
  const [metrics, setMetrics] = useState<AdminMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!store) {
      setMetrics(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const m = await fetchStoreMetrics(store.id, store.name);
      setMetrics(m);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load metrics");
    } finally {
      setLoading(false);
    }
  }, [store]);

  useEffect(() => {
    void load();
  }, [load]);

  if (storeLoading || loading) {
    return (
      <div className={styles.loading} role="status">
        <div className="sb-spinner" aria-hidden />
        <p>Loading dashboard…</p>
      </div>
    );
  }

  if (!store) {
    return (
      <>
        <h1 className={styles.pageTitle}>Dashboard</h1>
        <p className={styles.pageSub}>Connect a store to see metrics.</p>
      </>
    );
  }

  const utilPct = metrics
    ? Math.round(metrics.utilizationRate * 100)
    : 0;

  return (
    <>
      <h1 className={styles.pageTitle}>Dashboard</h1>
      <p className={styles.pageSub}>
        Overview for <strong>{store.name}</strong>
      </p>

      {error && (
        <div className={styles.error} role="alert">
          {error}
        </div>
      )}

      {metrics && (
        <div className={styles.metrics}>
          <div className={styles.metricCard}>
            <p className={styles.metricLabel}>Today&apos;s bookings</p>
            <p className={styles.metricValue}>{metrics.todaysBookings}</p>
            <p className={styles.metricHint}>Confirmed + completed today</p>
          </div>
          <div className={styles.metricCard}>
            <p className={styles.metricLabel}>Total revenue</p>
            <p className={styles.metricValue}>
              {formatCents(metrics.totalRevenueCents)}
            </p>
            <p className={styles.metricHint}>Confirmed + completed</p>
          </div>
          <div className={styles.metricCard}>
            <p className={styles.metricLabel}>Utilization</p>
            <p className={styles.metricValue}>{utilPct}%</p>
            <p className={styles.metricHint}>
              {metrics.openSlots} open slots ahead
            </p>
          </div>
          <div className={styles.metricCard}>
            <p className={styles.metricLabel}>All bookings</p>
            <p className={styles.metricValue}>{metrics.totalBookings}</p>
            <p className={styles.metricHint}>
              {metrics.cancelledCount} cancelled
            </p>
          </div>
        </div>
      )}

      <div className={styles.panel}>
        <div className={styles.panelHeader}>
          <h2 className={styles.panelTitle}>Quick actions</h2>
        </div>
        <div style={{ padding: "1rem", display: "flex", flexWrap: "wrap", gap: 8 }}>
          <Link href="/admin/bookings" className={styles.btnSm} style={{ textDecoration: "none" }}>
            Manage bookings
          </Link>
          <Link href="/admin/items" className={styles.btnSm} style={{ textDecoration: "none" }}>
            View items
          </Link>
          <Link href="/admin/settings" className={styles.btnSm} style={{ textDecoration: "none" }}>
            Store settings
          </Link>
        </div>
      </div>
    </>
  );
}
