import type { Metadata } from "next";
import { AuthShell } from "@/components/auth/auth-shell";
import { EmailAuthForm } from "@/components/auth/email-auth-form";

export const metadata: Metadata = { title: "Sign in" };

export default function LoginPage() {
  return (
    <AuthShell eyebrow="Welcome back" title="Return to your flow." description="Your library, notes, and momentum are waiting.">
      <EmailAuthForm mode="login" />
    </AuthShell>
  );
}
