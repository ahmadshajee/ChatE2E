// ============================================================
//  Root Layout
//  Applies global fonts, styles, and providers.
// ============================================================

import type { Metadata } from "next";
import "./globals.css";
import Providers from "@/components/providers";

export const metadata: Metadata = {
  title: "Chatizy — End-to-End Encrypted Chat",
  description:
    "A WhatsApp-like end-to-end encrypted messaging application. Your messages are private — only you and the recipient can read them.",
  keywords: ["chat", "encrypted", "e2ee", "messaging", "private"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
