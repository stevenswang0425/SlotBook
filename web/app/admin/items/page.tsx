"use client";

/**
 * Admin items list — read-only catalog for the owner's store (P0).
 */

import { useCallback, useEffect, useState } from "react";

import { useAdminStore } from "@/lib/admin/AdminStoreContext";
import { fetchStoreItems } from "@/lib/admin/queries";
import { formatCents } from "@/lib/admin/types";
import type { Item } from "@/lib/types";

import styles from "../admin.module.css";

export default function AdminItemsPage() {
  const { store, loading: storeLoading } = useAdminStore();
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!store) {
      setItems([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      setItems(await fetchStoreItems(store.id));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load items");
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
        <p>Loading items…</p>
      </div>
    );
  }

  return (
    <>
      <h1 className={styles.pageTitle}>Items</h1>
      <p className={styles.pageSub}>
        Catalog for <strong>{store?.name ?? "your store"}</strong>. Create/edit
        lands in a later iteration.
      </p>

      {error && (
        <div className={styles.error} role="alert">
          {error}
        </div>
      )}

      {items.length === 0 ? (
        <div className={styles.panel}>
          <div className={styles.empty}>No items yet. Seed the catalog in Supabase.</div>
        </div>
      ) : (
        <div className={styles.itemGrid}>
          {items.map((item) => (
            <article key={item.id} className={styles.itemCard}>
              <h3>{item.name}</h3>
              <p className={styles.muted} style={{ margin: "0 0 0.5rem" }}>
                {item.category} · {item.duration_minutes} min ·{" "}
                {formatCents(item.price_cents)}
              </p>
              <p className={styles.muted} style={{ margin: 0, lineHeight: 1.4 }}>
                {item.description || "No description"}
              </p>
              <p className={styles.muted} style={{ margin: "0.65rem 0 0" }}>
                {item.is_active ? "Active" : "Inactive"}
              </p>
            </article>
          ))}
        </div>
      )}
    </>
  );
}
