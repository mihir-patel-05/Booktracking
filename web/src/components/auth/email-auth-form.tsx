"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useState, type FormEvent } from "react";
import { Turnstile } from "@/components/auth/turnstile";
import { createClient } from "@/lib/supabase/client";
import { hasSupabaseConfig } from "@/lib/supabase/env";

type Mode = "login" | "signup";

const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$/;

export function EmailAuthForm({ mode }: { mode: Mode }) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [captchaToken, setCaptchaToken] = useState<string>();
  const [error, setError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);
  const onCaptcha = useCallback((token: string | undefined) => setCaptchaToken(token), []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(undefined);

    if (!hasSupabaseConfig()) {
      setError("PageFlow is waiting for its Supabase project configuration.");
      return;
    }
    if (mode === "signup" && !passwordPattern.test(password)) {
      setError("Use at least 12 characters with uppercase, lowercase, a number, and a symbol.");
      return;
    }

    setSubmitting(true);
    const supabase = createClient();

    if (mode === "signup") {
      const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
      const { data, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          captchaToken,
          emailRedirectTo: `${window.location.origin}/auth/callback?next=/app`,
          data: { display_name: displayName.trim(), time_zone: timeZone },
        },
      });
      if (authError) setError(authError.message);
      else if (data.session) router.replace("/app");
      else router.replace(`/check-email?email=${encodeURIComponent(email)}`);
    } else {
      const { error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
        options: { captchaToken },
      });
      if (authError) setError(authError.message);
      else {
        router.replace("/app");
        router.refresh();
      }
    }
    setSubmitting(false);
  }

  return (
    <form className="space-y-4" onSubmit={submit}>
      {mode === "signup" ? (
        <AuthField
          id="display-name"
          label="Name"
          value={displayName}
          onChange={setDisplayName}
          autoComplete="name"
          required
        />
      ) : null}
      <AuthField id="email" label="Email" type="email" value={email} onChange={setEmail} autoComplete="email" required />
      <AuthField
        id="password"
        label="Password"
        type="password"
        value={password}
        onChange={setPassword}
        autoComplete={mode === "signup" ? "new-password" : "current-password"}
        required
        hint={mode === "signup" ? "12+ characters, including uppercase, lowercase, a number, and a symbol." : undefined}
      />
      {mode === "login" ? (
        <div className="text-right">
          <Link className="text-xs text-gold-text" href="/forgot-password">Forgotten it?</Link>
        </div>
      ) : null}
      <Turnstile onToken={onCaptcha} />
      {error ? <p className="border border-[var(--danger)] px-4 py-3 text-sm text-[var(--danger)]" role="alert">{error}</p> : null}
      <button className="btn btn-primary btn-block min-h-[42px]" disabled={submitting} type="submit">
        {submitting ? "Working…" : mode === "signup" ? "Create account" : "Sign in"}
      </button>
      <p className="text-center text-xs text-muted">
        {mode === "signup" ? "Already have an account? " : "New to PageFlow? "}
        <Link className="text-gold-text" href={mode === "signup" ? "/login" : "/signup"}>
          {mode === "signup" ? "Sign in" : "Open an account"}
        </Link>
      </p>
      <p className="text-center text-[11.5px] leading-6 text-faint">
        Protected by Turnstile. Your reading log is yours alone and exportable as JSON at any time.
      </p>
    </form>
  );
}

type AuthFieldProps = {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  autoComplete?: string;
  required?: boolean;
  hint?: string;
};

function AuthField({ id, label, value, onChange, type = "text", autoComplete, required, hint }: AuthFieldProps) {
  return (
    <label className="block" htmlFor={id}>
      <span className="field-label">{label}</span>
      <input
        className="input min-h-[42px]"
        id={id}
        type={type}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        autoComplete={autoComplete}
        required={required}
        aria-describedby={hint ? `${id}-hint` : undefined}
      />
      {hint ? <span className="mt-2 block text-xs leading-5 text-faint" id={`${id}-hint`}>{hint}</span> : null}
    </label>
  );
}
