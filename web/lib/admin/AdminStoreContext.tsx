"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import { fetchOwnerStores } from "@/lib/admin/queries";
import type { AdminStore } from "@/lib/admin/types";

type AdminStoreContextValue = {
  store: AdminStore | null;
  stores: AdminStore[];
  loading: boolean;
  error: string | null;
  reload: () => Promise<void>;
  setStoreId: (id: string) => void;
};

const AdminStoreContext = createContext<AdminStoreContextValue | null>(null);

export function AdminStoreProvider({ children }: { children: ReactNode }) {
  const [stores, setStores] = useState<AdminStore[]>([]);
  const [storeId, setStoreId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const list = await fetchOwnerStores();
      setStores(list);
      setStoreId((prev) => {
        if (prev && list.some((s) => s.id === prev)) return prev;
        return list[0]?.id ?? null;
      });
      if (list.length === 0) {
        setError("No store found for this owner. Run the seed script or create a store.");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load store");
      setStores([]);
      setStoreId(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const store = useMemo(
    () => stores.find((s) => s.id === storeId) ?? null,
    [stores, storeId]
  );

  const value = useMemo(
    () => ({
      store,
      stores,
      loading,
      error,
      reload,
      setStoreId,
    }),
    [store, stores, loading, error, reload]
  );

  return (
    <AdminStoreContext.Provider value={value}>{children}</AdminStoreContext.Provider>
  );
}

export function useAdminStore(): AdminStoreContextValue {
  const ctx = useContext(AdminStoreContext);
  if (!ctx) {
    throw new Error("useAdminStore must be used within AdminStoreProvider");
  }
  return ctx;
}
