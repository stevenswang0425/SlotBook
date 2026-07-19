/**
 * Admin layout — server-side owner gate + client ProtectedRoute shell.
 * Middleware also blocks non-owners at the edge.
 */

import type { ReactNode } from "react";

import { AdminShell } from "@/app/admin/AdminShell";
import { requireOwner } from "@/lib/auth/server";

export const metadata = {
  title: "Admin · SlotBook",
};

export default async function AdminLayout({ children }: { children: ReactNode }) {
  // Server-side enforcement (redirects if not owner).
  const auth = await requireOwner();

  return (
    <AdminShell ownerName={auth.profile?.full_name ?? auth.email ?? "Owner"}>
      {children}
    </AdminShell>
  );
}
