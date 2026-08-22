"use client";

import { useActionState } from "react";
import { updateProgress, type ProgressState } from "@/app/app/books/[id]/actions";
import { SHELF_STATUSES } from "@/lib/shelves";

export function ProgressForm({ book }: { book: { id: string; current_page: number; total_pages: number; status: string } }) {
  const [state, action, pending] = useActionState<ProgressState, FormData>(updateProgress, {});

  return (
    <form action={action}>
      <input name="id" type="hidden" value={book.id} />
      <input name="totalPages" type="hidden" value={book.total_pages} />
      <div className="grid gap-5 sm:grid-cols-2">
        <label className="block">
          <span className="field-label">Current page</span>
          <input className="input tnum" defaultValue={book.current_page} max={book.total_pages} min="0" name="currentPage" required type="number" />
        </label>
        <label className="block">
          <span className="field-label">Standing</span>
          <select className="input" defaultValue={book.status} name="status">
            {SHELF_STATUSES.map((status) => <option key={status}>{status}</option>)}
          </select>
        </label>
      </div>
      {state.error ? <p className="mt-4 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
      {state.success ? <p className="mt-4 text-sm text-[var(--success)]" role="status">Progress recorded.</p> : null}
      <button className="btn btn-primary btn-block mt-5" disabled={pending} type="submit">{pending ? "Recording…" : "Record progress"}</button>
    </form>
  );
}
