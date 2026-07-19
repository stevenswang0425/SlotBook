"use client";

import type { AdminBookingRow } from "@/lib/admin/types";
import {
  displayCustomer,
  formatCents,
  formatDateTime,
  statusLabel,
} from "@/lib/admin/types";

import styles from "@/app/admin/admin.module.css";

type Props = {
  booking: AdminBookingRow;
  busy: boolean;
  onClose: () => void;
  onCancel: () => void;
  onComplete: () => void;
};

export function BookingDetailDrawer({
  booking,
  busy,
  onClose,
  onCancel,
  onComplete,
}: Props) {
  const customer = displayCustomer(booking);
  const canAct = booking.status === "confirmed";

  return (
    <div
      className={styles.drawerOverlay}
      role="presentation"
      onClick={(e) => {
        if (e.target === e.currentTarget && !busy) onClose();
      }}
    >
      <aside
        className={styles.drawer}
        role="dialog"
        aria-modal="true"
        aria-label="Booking details"
      >
        <div style={{ display: "flex", justifyContent: "space-between", gap: 12 }}>
          <h2>Booking</h2>
          <button type="button" className={styles.btnGhost} onClick={onClose} disabled={busy}>
            Close
          </button>
        </div>
        <p className={styles.muted} style={{ marginTop: 0 }}>
          {booking.reference_code}
        </p>

        <div className={styles.drawerRow}>
          <span>Status</span>
          <span>{statusLabel(booking.status)}</span>
        </div>
        <div className={styles.drawerRow}>
          <span>Customer</span>
          <span>
            {customer.name}
            {customer.isGuest ? " (guest)" : ""}
          </span>
        </div>
        <div className={styles.drawerRow}>
          <span>Phone</span>
          <span>{customer.phone}</span>
        </div>
        {customer.email && (
          <div className={styles.drawerRow}>
            <span>Email</span>
            <span>{customer.email}</span>
          </div>
        )}
        <div className={styles.drawerRow}>
          <span>Item</span>
          <span>{booking.item?.name ?? "—"}</span>
        </div>
        <div className={styles.drawerRow}>
          <span>When</span>
          <span>
            {booking.time_slot?.starts_at
              ? formatDateTime(booking.time_slot.starts_at)
              : "—"}
          </span>
        </div>
        <div className={styles.drawerRow}>
          <span>Duration</span>
          <span>
            {booking.item?.duration_minutes
              ? `${booking.item.duration_minutes} min`
              : "—"}
          </span>
        </div>
        <div className={styles.drawerRow}>
          <span>Price</span>
          <span>{formatCents(booking.item?.price_cents)}</span>
        </div>
        <div className={styles.drawerRow}>
          <span>Created</span>
          <span>{formatDateTime(booking.created_at)}</span>
        </div>

        {canAct && (
          <div className={styles.drawerActions}>
            <button
              type="button"
              className={styles.btnPrimary}
              disabled={busy}
              onClick={onComplete}
            >
              {busy ? "Working…" : "Mark completed"}
            </button>
            <button
              type="button"
              className={styles.btnDanger}
              disabled={busy}
              onClick={onCancel}
              style={{ padding: "0.75rem 1rem", borderRadius: 12 }}
            >
              Cancel booking
            </button>
          </div>
        )}
      </aside>
    </div>
  );
}
