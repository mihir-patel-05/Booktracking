import type { Metadata } from "next";
import Link from "next/link";
import { AuthShell } from "@/components/auth/auth-shell";

export const metadata: Metadata = { title: "Check your email" };

export default async function CheckEmailPage({ searchParams }: { searchParams: Promise<{ email?: string }> }) {
  const { email } = await searchParams;
  return (
    <AuthShell eyebrow="One more step" title="Check your inbox." description="Verify your email before opening your PageFlow library.">
      <div className="space-y-4 text-sm leading-6 text-secondary">
        <p>We sent a verification link{email ? <> to <strong className="text-white">{email}</strong></> : ""}.</p>
        <p>The link returns you securely to PageFlow. Check spam if it does not arrive after a few minutes.</p>
        <Link className="secondary-button w-full" href="/login">Return to sign in</Link>
      </div>
    </AuthShell>
  );
}
