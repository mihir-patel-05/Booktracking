import type { Metadata } from "next";
import { AuthShell } from "@/components/auth/auth-shell";
import { PasswordRecoveryForm } from "@/components/auth/password-recovery-form";

export const metadata: Metadata = { title: "Set a new password" };

export default function ResetPasswordPage() {
  return (
    <AuthShell eyebrow="Secure your account" title="Choose a new password" description="It must meet PageFlow’s security requirements.">
      <PasswordRecoveryForm mode="reset" />
    </AuthShell>
  );
}
