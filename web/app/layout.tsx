import type { Metadata } from "next";
import type { ReactNode } from "react";

import { Providers } from "@/app/providers";
import { SiteHeader } from "@/components/layout/SiteHeader";

import "./globals.css";

export const metadata: Metadata = {
  title: "SlotBook",
  description: "Calm real-time booking — SlotBook",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <SiteHeader />
          {children}
        </Providers>
      </body>
    </html>
  );
}
