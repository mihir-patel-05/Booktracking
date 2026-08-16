import type { Metadata } from "next";
import Link from "next/link";
import { AuthShell } from "@/components/auth/auth-shell";
import { PasswordRecoveryForm } from "@/components/auth/password-recovery-form";

export const metadata: Metadata = { title: "Recover password" };

export default function ForgotPasswordPage() {
  return (
    <AuthShell eyebrow="Account recovery" title="Find your way back." description="We’ll email a secure link to reset your password.">
      <PasswordRecoveryForm mode="request" />
      <Link className="flex min-h-11 items-center justify-center text-sm text-accent-light" href="/login">Back to sign in</Link>
    </AuthShell>
  );
}
