"use client";

import { useCallback, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { hasSupabaseConfig } from "@/lib/supabase/env";
import { Turnstile } from "@/components/auth/turnstile";

const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$/;

export function PasswordRecoveryForm({ mode }: { mode: "request" | "reset" }) {
  const router = useRouter();
  const [value, setValue] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [message, setMessage] = useState<string>();
  const [error, setError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);
  const [captchaToken, setCaptchaToken] = useState<string>();
  const onCaptcha = useCallback((token: string | undefined) => setCaptchaToken(token), []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(undefined);
    setMessage(undefined);
    if (!hasSupabaseConfig()) {
      setError("PageFlow is waiting for its Supabase project configuration.");
      return;
    }

    setSubmitting(true);
    const supabase = createClient();
    if (mode === "request") {
      const { error: authError } = await supabase.auth.resetPasswordForEmail(value, {
        redirectTo: `${window.location.origin}/auth/callback?next=/reset-password`,
        captchaToken,
      });
      if (authError) setError(authError.message);
      else setMessage("If that address belongs to an account, a recovery link is on its way.");
    } else if (!passwordPattern.test(value)) {
      setError("Use at least 12 characters with uppercase, lowercase, a number, and a symbol.");
    } else if (value !== confirmation) {
      setError("The passwords do not match.");
    } else {
      const { error: authError } = await supabase.auth.updateUser({ password: value });
      if (authError) setError(authError.message);
      else router.replace("/app/settings?password=updated");
    }
    setSubmitting(false);
  }

  return (
    <form className="space-y-4" onSubmit={submit}>
      <label className="block" htmlFor={mode === "request" ? "recovery-email" : "new-password"}>
        <span className="field-label">{mode === "request" ? "Email" : "New password"}</span>
        <input
          autoComplete={mode === "request" ? "email" : "new-password"}
          className="input min-h-[42px]"
          id={mode === "request" ? "recovery-email" : "new-password"}
          onChange={(event) => setValue(event.target.value)}
          required
          type={mode === "request" ? "email" : "password"}
          value={value}
        />
      </label>
      {mode === "reset" ? (
        <label className="block" htmlFor="confirm-password">
          <span className="field-label">Confirm password</span>
          <input
            autoComplete="new-password"
            className="input min-h-[42px]"
            id="confirm-password"
            onChange={(event) => setConfirmation(event.target.value)}
            required
            type="password"
            value={confirmation}
          />
          <span className="mt-2 block text-xs leading-5 text-faint">12+ characters with uppercase, lowercase, a number, and a symbol.</span>
        </label>
      ) : null}
      {mode === "request" ? <Turnstile onToken={onCaptcha} /> : null}
      {error ? <p className="border border-[var(--danger)] px-4 py-3 text-sm text-[var(--danger)]" role="alert">{error}</p> : null}
      {message ? <p className="border border-[var(--success)] px-4 py-3 text-sm text-[var(--success)]" role="status">{message}</p> : null}
      <button className="btn btn-primary btn-block min-h-[42px]" disabled={submitting} type="submit">
        {submitting ? "Working…" : mode === "request" ? "Send recovery link" : "Save new password"}
      </button>
    </form>
  );
}
