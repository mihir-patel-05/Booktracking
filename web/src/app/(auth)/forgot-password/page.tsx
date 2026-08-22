import type { Metadata } from "next";
import Link from "next/link";
import { AuthShell } from "@/components/auth/auth-shell";
import { PasswordRecoveryForm } from "@/components/auth/password-recovery-form";

export const metadata: Metadata = { title: "Recover password" };

export default function ForgotPasswordPage() {
  return (
    <AuthShell eyebrow="Account recovery" title="Find your way back" description="We’ll send a secure link to reset your password.">
      <PasswordRecoveryForm mode="request" />
      <Link className="mt-5 block text-center text-xs text-gold-text" href="/login">Back to sign in</Link>
    </AuthShell>
  );
}
