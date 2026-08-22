"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export function DeleteAccount() {
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState<string>();
  const [deleting, setDeleting] = useState(false);

  async function remove() {
    if (confirmation !== "DELETE") return;
    setDeleting(true);
    setError(undefined);
    const { error: functionError } = await createClient().functions.invoke("delete-account", { method: "POST" });
    if (functionError) { setError(functionError.message); setDeleting(false); return; }
    localStorage.clear();
    sessionStorage.clear();
    window.location.replace("/");
  }

  return (
    <div className="grid gap-5">
      <p className="text-sm leading-6 text-muted">
        This permanently removes your account and every volume, sitting, note, line and figure in it.
        Export first if you want a copy.
      </p>
      <label className="block">
        <span className="field-label">Type DELETE to confirm</span>
        <input className="input" onChange={(event) => setConfirmation(event.target.value)} value={confirmation} />
      </label>
      {error ? <p className="text-sm text-[var(--danger)]" role="alert">{error}</p> : null}
      <button className="btn btn-danger btn-block" disabled={confirmation !== "DELETE" || deleting} onClick={remove} type="button">
        {deleting ? "Deleting…" : "Permanently delete account"}
      </button>
    </div>
  );
}
