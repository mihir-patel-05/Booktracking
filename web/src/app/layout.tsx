import type { Metadata, Viewport } from "next";
import { Cormorant_Garamond, Lora } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import "./globals.css";

const cormorant = Cormorant_Garamond({
  subsets: ["latin"],
  weight: ["400", "600"],
  variable: "--font-cormorant",
  display: "swap",
});

const lora = Lora({
  subsets: ["latin"],
  weight: ["400", "600"],
  style: ["normal", "italic"],
  variable: "--font-lora",
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "PageFlow",
    template: "%s · PageFlow",
  },
  description: "A reading register. Keep the account of what you read.",
  applicationName: "PageFlow",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "PageFlow",
  },
};

export const viewport: Viewport = {
  colorScheme: "light dark",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f3f2f2" },
    { media: "(prefers-color-scheme: dark)", color: "#1a1917" },
  ],
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html className={`${cormorant.variable} ${lora.variable}`} lang="en" suppressHydrationWarning>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
