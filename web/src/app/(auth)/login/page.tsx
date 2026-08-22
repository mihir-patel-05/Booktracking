import type { Metadata } from "next";
import { AuthShell } from "@/components/auth/auth-shell";
import { EmailAuthForm } from "@/components/auth/email-auth-form";
import { GoogleAuthButton } from "@/components/auth/google-auth-button";

export const metadata: Metadata = { title: "Sign in" };

export default function LoginPage() {
  return (
    <AuthShell description="Or open an account — it takes a minute." eyebrow="Welcome back" title="Sign in">
      <GoogleAuthButton />
      <EmailAuthForm mode="login" />
    </AuthShell>
  );
}
