"use client";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
export function DeleteAccount() {
  const [confirmation, setConfirmation] = useState(""); const [error, setError] = useState<string>(); const [deleting, setDeleting] = useState(false);
  async function remove() { if (confirmation !== "DELETE") return; setDeleting(true); setError(undefined); const { error: functionError } = await createClient().functions.invoke("delete-account", { method: "POST" }); if (functionError) { setError(functionError.message); setDeleting(false); return; } localStorage.clear(); sessionStorage.clear(); window.location.replace("/"); }
  return <div className="space-y-4"><p className="text-sm leading-6 text-secondary">This permanently removes your account and every book, session, note, quote, and statistic. Export first if you need a copy.</p><label><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">Type DELETE to confirm</span><input className="min-h-12 w-full rounded-xl border border-danger/30 bg-black/20 px-4" onChange={(event) => setConfirmation(event.target.value)} value={confirmation} /></label>{error ? <p className="text-sm text-red-200" role="alert">{error}</p> : null}<button className="flex min-h-12 w-full items-center justify-center rounded-xl border border-danger/40 bg-danger/10 font-semibold text-red-200 disabled:opacity-40" disabled={confirmation !== "DELETE" || deleting} onClick={remove}>{deleting ? "Deleting…" : "Permanently delete account"}</button></div>;
}
