"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { hasSupabaseConfig } from "@/lib/supabase/env";

const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$/;

export function PasswordRecoveryForm({ mode }: { mode: "request" | "reset" }) {
  const router = useRouter();
  const [value, setValue] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [message, setMessage] = useState<string>();
  const [error, setError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);

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
        <span className="mb-2 block text-xs font-bold uppercase tracking-[0.12em] text-muted">
          {mode === "request" ? "Email" : "New password"}
        </span>
        <input
          autoComplete={mode === "request" ? "email" : "new-password"}
          className="min-h-12 w-full rounded-2xl border border-[var(--border)] bg-black/20 px-4 text-base text-white focus:border-accent-light"
          id={mode === "request" ? "recovery-email" : "new-password"}
          onChange={(event) => setValue(event.target.value)}
          required
          type={mode === "request" ? "email" : "password"}
          value={value}
        />
      </label>
      {mode === "reset" ? (
        <label className="block" htmlFor="confirm-password">
          <span className="mb-2 block text-xs font-bold uppercase tracking-[0.12em] text-muted">Confirm password</span>
          <input
            autoComplete="new-password"
            className="min-h-12 w-full rounded-2xl border border-[var(--border)] bg-black/20 px-4 text-base text-white focus:border-accent-light"
            id="confirm-password"
            onChange={(event) => setConfirmation(event.target.value)}
            required
            type="password"
            value={confirmation}
          />
          <span className="mt-2 block text-xs leading-5 text-muted">12+ characters with uppercase, lowercase, a number, and a symbol.</span>
        </label>
      ) : null}
      {error ? <p className="rounded-xl border border-danger/30 bg-danger/10 p-3 text-sm text-red-200" role="alert">{error}</p> : null}
      {message ? <p className="rounded-xl border border-success/30 bg-success/10 p-3 text-sm text-emerald-100" role="status">{message}</p> : null}
      <button className="primary-button w-full" disabled={submitting} type="submit">
        {submitting ? "Working…" : mode === "request" ? "Send recovery link" : "Save new password"}
      </button>
    </form>
  );
}
