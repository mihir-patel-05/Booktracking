"use client";

import { useActionState } from "react";
import { updateProgress, type ProgressState } from "@/app/app/books/[id]/actions";

export function ProgressForm({ book }: { book: { id: string; current_page: number; total_pages: number; status: string } }) {
  const [state, action, pending] = useActionState<ProgressState, FormData>(updateProgress, {});
  return <form action={action} className="glass-card grid gap-4 rounded-2xl p-5 sm:grid-cols-2">
    <input name="id" type="hidden" value={book.id} /><input name="totalPages" type="hidden" value={book.total_pages} />
    <label><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">Current page</span><input className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4" defaultValue={book.current_page} max={book.total_pages} min="0" name="currentPage" required type="number" /></label>
    <label><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">Status</span><select className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#141424] px-4" defaultValue={book.status} name="status">{["Want to Read", "Currently Reading", "Completed", "Abandoned"].map((status) => <option key={status}>{status}</option>)}</select></label>
    {state.error ? <p className="text-sm text-red-200 sm:col-span-2" role="alert">{state.error}</p> : null}
    {state.success ? <p className="text-sm text-emerald-200 sm:col-span-2" role="status">Progress saved.</p> : null}
    <button className="primary-button sm:col-span-2" disabled={pending}>{pending ? "Saving…" : "Save progress"}</button>
  </form>;
}
