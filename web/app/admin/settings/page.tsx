"use client";

/**
 * Admin store settings — read-only overview (P0).
 */

import { useAdminStore } from "@/lib/admin/AdminStoreContext";

import styles from "../admin.module.css";

export default function AdminSettingsPage() {
  const { store, loading, error } = useAdminStore();

  if (loading) {
    return (
      <div className={styles.loading} role="status">
        <div className="sb-spinner" aria-hidden />
        <p>Loading settings…</p>
      </div>
    );
  }

  return (
    <>
      <h1 className={styles.pageTitle}>Settings</h1>
      <p className={styles.pageSub}>
        Store profile. Branding and hours editors come next.
      </p>

      {error && (
        <div className={styles.error} role="alert">
          {error}
        </div>
      )}

      {!store ? (
        <div className={styles.panel}>
          <div className={styles.empty}>No store linked to this owner.</div>
        </div>
      ) : (
        <div className={styles.settingsCard}>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Name</span>
            <strong>{store.name}</strong>
          </div>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Slug</span>
            <strong>{store.slug}</strong>
          </div>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Timezone</span>
            <strong>{store.timezone}</strong>
          </div>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Brand color</span>
            <strong style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
              {store.brand_primary ? (
                <>
                  <span
                    aria-hidden
                    style={{
                      width: 14,
                      height: 14,
                      borderRadius: 4,
                      background: store.brand_primary,
                      border: "1px solid var(--sb-border)",
                    }}
                  />
                  {store.brand_primary}
                </>
              ) : (
                "—"
              )}
            </strong>
          </div>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Status</span>
            <strong>{store.is_active ? "Active" : "Inactive"}</strong>
          </div>
          <div className={styles.settingsRow}>
            <span className={styles.muted}>Store ID</span>
            <code style={{ fontSize: 12 }}>{store.id}</code>
          </div>
        </div>
      )}
    </>
  );
}
