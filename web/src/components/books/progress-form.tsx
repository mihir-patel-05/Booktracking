"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { updateProgress, type ProgressState } from "@/app/app/books/[id]/actions";
import { SHELF_STATUSES } from "@/lib/shelves";

type GoalChoice = { id: string; name: string; target_books: number; cadence: string };

export function ProgressForm({ book, goals, goalIds }: { book: { id: string; current_page: number; total_pages: number; status: string }; goals: GoalChoice[]; goalIds: string[] }) {
  const [state, action, pending] = useActionState<ProgressState, FormData>(updateProgress, {});
  const [currentPage, setCurrentPage] = useState(book.current_page);
  const [status, setStatus] = useState(book.status);
  const finished = status === "Completed" || currentPage === book.total_pages;

  return (
    <form action={action}>
      <input name="id" type="hidden" value={book.id} />
      <input name="totalPages" type="hidden" value={book.total_pages} />
      <div className="grid gap-5 sm:grid-cols-2">
        <label className="block">
          <span className="field-label">Current page</span>
          <input className="input tnum" max={book.total_pages} min="0" name="currentPage" onChange={(event) => {
            const value = Number(event.target.value);
            setCurrentPage(value);
            if (value === book.total_pages) setStatus("Completed");
          }} required type="number" value={currentPage} />
        </label>
        <label className="block">
          <span className="field-label">Standing</span>
          <select className="input" name="status" onChange={(event) => setStatus(event.target.value)} value={status}>
            {SHELF_STATUSES.map((status) => <option key={status}>{status}</option>)}
          </select>
        </label>
      </div>
      {finished ? (
        <fieldset className="mt-5 border-t border-line-soft pt-4">
          <legend className="field-label">Count this finished volume toward</legend>
          {goals.length ? (
            <div className="grid gap-2 sm:grid-cols-2">
              {goals.map((goal) => (
                <label className="flex cursor-pointer items-start gap-2.5 border border-line-soft px-3 py-2.5 text-sm" key={goal.id}>
                  <input className="mt-1 accent-[var(--gold)]" defaultChecked={goalIds.includes(goal.id)} name="goalIds" type="checkbox" value={goal.id} />
                  <span>
                    <span className="block">{goal.name}</span>
                    <span className="tnum block text-[11px] text-muted">{goal.target_books} {goal.cadence === "monthly" ? "each month" : "in all"}</span>
                  </span>
                </label>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted">No goals yet. <Link className="text-gold-text" href="/app/goals">Set one first →</Link></p>
          )}
        </fieldset>
      ) : null}
      {state.error ? <p className="mt-4 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
      {state.success ? <p className="mt-4 text-sm text-[var(--success)]" role="status">Progress recorded.</p> : null}
      <button className="btn btn-primary btn-block mt-5" disabled={pending} type="submit">{pending ? "Recording…" : "Record progress"}</button>
    </form>
  );
}
