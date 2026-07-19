"use client";

/**
 * Client providers tree for SlotBook web.
 *
 * Integration:
 *   // app/layout.tsx
 *   import { Providers } from "./providers";
 *   <Providers>{children}</Providers>
 */

import type { ReactNode } from "react";

import { AuthModal } from "@/components/auth/AuthModal";
import { AuthProvider } from "@/components/auth/AuthProvider";
import { BookingAuthGate } from "@/components/booking/BookingAuthGate";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <AuthProvider>
      {children}
      {/* Global modals — available on every page */}
      <AuthModal />
      <BookingAuthGate />
    </AuthProvider>
  );
}
