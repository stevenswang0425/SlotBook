"use client";

/**
 * Admin bookings management — list, view, cancel, complete.
 */

import { useCallback, useEffect, useState } from "react";

import { BookingDetailDrawer } from "@/components/admin/BookingDetailDrawer";
import { BookingsTable } from "@/components/admin/BookingsTable";
import { useAdminStore } from "@/lib/admin/AdminStoreContext";
import {
  cancelBooking,
  completeBooking,
  fetchStoreBookings,
} from "@/lib/admin/queries";
import type { AdminBookingRow, BookingStatusFilter } from "@/lib/admin/types";

import styles from "../admin.module.css";

export default function AdminBookingsPage() {
  const { store, loading: storeLoading } = useAdminStore();
  const [rows, setRows] = useState<AdminBookingRow[]>([]);
  const [filter, setFilter] = useState<BookingStatusFilter>("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [selected, setSelected] = useState<AdminBookingRow | null>(null);

  const load = useCallback(async () => {
    if (!store) {
      setRows([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await fetchStoreBookings(store.id, filter);
      setRows(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load bookings");
    } finally {
      setLoading(false);
    }
  }, [store, filter]);

  useEffect(() => {
    void load();
  }, [load]);

  const handleCancel = async (row: AdminBookingRow) => {
    if (
      !window.confirm(
        `Cancel booking ${row.reference_code}? The time slot will become available again.`
      )
    ) {
      return;
    }
    setBusyId(row.id);
    setError(null);
    try {
      await cancelBooking(row.id);
      setSelected(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Cancel failed");
    } finally {
      setBusyId(null);
    }
  };

  const handleComplete = async (row: AdminBookingRow) => {
    if (!window.confirm(`Mark ${row.reference_code} as completed?`)) return;
    setBusyId(row.id);
    setError(null);
    try {
      await completeBooking(row.id);
      setSelected(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Update failed");
    } finally {
      setBusyId(null);
    }
  };

  if (storeLoading || loading) {
    return (
      <div className={styles.loading} role="status">
        <div className="sb-spinner" aria-hidden />
        <p>Loading bookings…</p>
      </div>
    );
  }

  if (!store) {
    return (
      <>
        <h1 className={styles.pageTitle}>Bookings</h1>
        <p className={styles.pageSub}>No store available.</p>
      </>
    );
  }

  return (
    <>
      <h1 className={styles.pageTitle}>Bookings</h1>
      <p className={styles.pageSub}>
        All reservations for <strong>{store.name}</strong>
      </p>

      {error && (
        <div className={styles.error} role="alert">
          {error}
        </div>
      )}

      <BookingsTable
        rows={rows}
        filter={filter}
        onFilterChange={setFilter}
        busyId={busyId}
        onView={setSelected}
        onCancel={(row) => void handleCancel(row)}
        onComplete={(row) => void handleComplete(row)}
      />

      {selected && (
        <BookingDetailDrawer
          booking={selected}
          busy={busyId === selected.id}
          onClose={() => setSelected(null)}
          onCancel={() => void handleCancel(selected)}
          onComplete={() => void handleComplete(selected)}
        />
      )}
    </>
  );
}
