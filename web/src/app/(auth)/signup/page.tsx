import type { Metadata } from "next";
import { AuthShell } from "@/components/auth/auth-shell";
import { EmailAuthForm } from "@/components/auth/email-auth-form";
import { GoogleAuthButton } from "@/components/auth/google-auth-button";

export const metadata: Metadata = { title: "Create account" };

export default function SignupPage() {
  return (
    <AuthShell eyebrow="Start reading" title="Create your PageFlow." description="A private place for every book, idea, and reading streak.">
      <EmailAuthForm mode="signup" />
      <GoogleAuthButton />
    </AuthShell>
  );
}
