import type { Metadata } from "next";
import { AuthShell } from "@/components/auth/auth-shell";
import { EmailAuthForm } from "@/components/auth/email-auth-form";
import { GoogleAuthButton } from "@/components/auth/google-auth-button";

export const metadata: Metadata = { title: "Create account" };

export default function SignupPage() {
  return (
    <AuthShell description="A register of your own — no feed, no recommendations." eyebrow="Open an account" title="Begin the register">
      <GoogleAuthButton />
      <EmailAuthForm mode="signup" />
    </AuthShell>
  );
}
