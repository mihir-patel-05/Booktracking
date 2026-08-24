"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { hasSupabaseConfig } from "@/lib/supabase/env";

export function GoogleAuthButton() {
  const [error, setError] = useState<string>();
  const [loading, setLoading] = useState(false);

  async function signIn() {
    setError(undefined);
    if (!hasSupabaseConfig()) {
      setError("PageFlow is waiting for its Supabase project configuration.");
      return;
    }

    setLoading(true);
    const { error: authError } = await createClient().auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=/app`,
        queryParams: { access_type: "offline", prompt: "consent" },
      },
    });
    if (authError) {
      setError(authError.message);
      setLoading(false);
    }
  }

  return (
    <div>
      <button className="btn btn-secondary btn-block min-h-[42px]" disabled={loading} onClick={signIn} type="button">
        <GoogleMark />
        {loading ? "Opening Google…" : "Continue with Google"}
      </button>
      {error ? <p className="mt-3 text-sm text-[var(--danger)]" role="alert">{error}</p> : null}
      <div className="my-6 flex items-center gap-3.5">
        <span className="h-px flex-1 bg-line" />
        <span className="text-[10px] uppercase tracking-[.16em] text-faint">or by email</span>
        <span className="h-px flex-1 bg-line" />
      </div>
    </div>
  );
}

function GoogleMark() {
  return (
    <svg aria-hidden="true" height="16" viewBox="0 0 24 24" width="16">
      <path d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4a4.6 4.6 0 0 1-2 3v2.5h3.3c1.9-1.8 2.9-4.4 2.9-7.3Z" fill="#4285F4" />
      <path d="M12 22c2.7 0 5-.9 6.7-2.5L15.4 17c-.9.6-2.1 1-3.4 1a5.9 5.9 0 0 1-5.5-4.1H3.1v2.6A10 10 0 0 0 12 22Z" fill="#34A853" />
      <path d="M6.5 13.9a6 6 0 0 1 0-3.8V7.5H3.1a10 10 0 0 0 0 9l3.4-2.6Z" fill="#FBBC05" />
      <path d="M12 6c1.5 0 2.9.5 3.9 1.5l2.9-2.8A9.8 9.8 0 0 0 3.1 7.5l3.4 2.6A5.9 5.9 0 0 1 12 6Z" fill="#EA4335" />
    </svg>
  );
}
