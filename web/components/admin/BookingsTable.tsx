"use client";

import type { AdminBookingRow, BookingStatusFilter } from "@/lib/admin/types";
import {
  displayCustomer,
  formatCents,
  formatDateTime,
  statusLabel,
} from "@/lib/admin/types";
import type { BookingStatus } from "@/lib/types";

import styles from "@/app/admin/admin.module.css";

const FILTERS: { id: BookingStatusFilter; label: string }[] = [
  { id: "all", label: "All" },
  { id: "confirmed", label: "Confirmed" },
  { id: "completed", label: "Completed" },
  { id: "cancelled", label: "Cancelled" },
];

type Props = {
  rows: AdminBookingRow[];
  filter: BookingStatusFilter;
  onFilterChange: (f: BookingStatusFilter) => void;
  busyId: string | null;
  onView: (row: AdminBookingRow) => void;
  onCancel: (row: AdminBookingRow) => void;
  onComplete: (row: AdminBookingRow) => void;
};

function badgeClass(status: BookingStatus): string {
  if (status === "confirmed") return `${styles.badge} ${styles.badgeConfirmed}`;
  if (status === "completed") return `${styles.badge} ${styles.badgeCompleted}`;
  return `${styles.badge} ${styles.badgeCancelled}`;
}

export function BookingsTable({
  rows,
  filter,
  onFilterChange,
  busyId,
  onView,
  onCancel,
  onComplete,
}: Props) {
  return (
    <div className={styles.panel}>
      <div className={styles.panelHeader}>
        <h2 className={styles.panelTitle}>Bookings</h2>
        <div className={styles.filters} role="tablist" aria-label="Filter by status">
          {FILTERS.map((f) => (
            <button
              key={f.id}
              type="button"
              role="tab"
              aria-selected={filter === f.id}
              className={`${styles.chip} ${filter === f.id ? styles.chipActive : ""}`}
              onClick={() => onFilterChange(f.id)}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {rows.length === 0 ? (
        <div className={styles.empty}>No bookings for this filter.</div>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Customer</th>
                <th>Phone</th>
                <th>Item</th>
                <th>When</th>
                <th>Status</th>
                <th>Price</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => {
                const customer = displayCustomer(row);
                const busy = busyId === row.id;
                const canAct = row.status === "confirmed";

                return (
                  <tr key={row.id}>
                    <td>
                      <div>{customer.name}</div>
                      <div className={styles.muted}>
                        {customer.isGuest ? "Guest" : "Account"} · {row.reference_code}
                      </div>
                    </td>
                    <td>{customer.phone}</td>
                    <td>{row.item?.name ?? "—"}</td>
                    <td>
                      {row.time_slot?.starts_at
                        ? formatDateTime(row.time_slot.starts_at)
                        : "—"}
                    </td>
                    <td>
                      <span className={badgeClass(row.status)}>
                        {statusLabel(row.status)}
                      </span>
                    </td>
                    <td>{formatCents(row.item?.price_cents)}</td>
                    <td>
                      <div className={styles.rowActions}>
                        <button
                          type="button"
                          className={styles.btnSm}
                          disabled={busy}
                          onClick={() => onView(row)}
                        >
                          View
                        </button>
                        {canAct && (
                          <>
                            <button
                              type="button"
                              className={styles.btnSm}
                              disabled={busy}
                              onClick={() => onComplete(row)}
                            >
                              Complete
                            </button>
                            <button
                              type="button"
                              className={styles.btnDanger}
                              disabled={busy}
                              onClick={() => onCancel(row)}
                            >
                              Cancel
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
