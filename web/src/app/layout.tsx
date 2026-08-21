import type { Metadata, Viewport } from "next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "PageFlow",
    template: "%s · PageFlow",
  },
  description: "Read. Reflect. Grow.",
  applicationName: "PageFlow",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "PageFlow",
  },
};

export const viewport: Viewport = {
  colorScheme: "dark",
  themeColor: "#0d0d0d",
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        {children}
        <SpeedInsights />
      </body>
    </html>
  );
}
