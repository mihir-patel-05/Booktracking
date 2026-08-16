"use client";

import { Search, X } from "lucide-react";
import { useActionState, useEffect, useState, type FormEvent } from "react";
import { createBook, type BookActionState } from "@/app/app/library/actions";

type Result = { id: string; title: string; author: string; totalPages: number; coverUrl: string };

export function AddBookSheet() {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<Result[]>([]);
  const [searching, setSearching] = useState(false);
  const [selected, setSelected] = useState<Partial<Result>>({});
  const [state, action, pending] = useActionState<BookActionState, FormData>(createBook, {});

  useEffect(() => { if (state.success) setOpen(false); }, [state.success]);

  async function search(event: FormEvent) {
    event.preventDefault();
    if (query.trim().length < 2) return;
    setSearching(true);
    const response = await fetch(`/api/books/search?q=${encodeURIComponent(query)}`);
    const data = await response.json() as { items?: Result[] };
    setResults(data.items ?? []);
    setSearching(false);
  }

  return (
    <>
      <button className="primary-button" onClick={() => setOpen(true)} type="button">Add book</button>
      {open ? <div aria-modal="true" className="fixed inset-0 z-50 flex items-end bg-black/70 sm:items-center sm:justify-center sm:p-6" role="dialog">
        <div className="max-h-[94svh] w-full overflow-y-auto rounded-t-3xl border border-[var(--border)] bg-surface p-5 pb-[max(1.25rem,env(safe-area-inset-bottom))] sm:max-w-2xl sm:rounded-3xl sm:p-7">
          <div className="mb-5 flex items-center justify-between"><div><p className="text-xs font-bold uppercase tracking-[.16em] text-accent-light">Your library</p><h2 className="font-display text-2xl">Add a book</h2></div><button aria-label="Close" className="flex size-11 items-center justify-center rounded-xl border border-[var(--border)]" onClick={() => setOpen(false)}><X size={20} /></button></div>
          <form className="flex gap-2" onSubmit={search}><input aria-label="Search Google Books" className="min-h-12 min-w-0 flex-1 rounded-xl border border-[var(--border)] bg-black/20 px-4" onChange={(event) => setQuery(event.target.value)} placeholder="Title, author, or ISBN" value={query} /><button aria-label="Search" className="primary-button px-4" disabled={searching}><Search size={19} /></button></form>
          {results.length ? <div className="my-4 max-h-56 space-y-2 overflow-y-auto">{results.map((book) => <button className="w-full rounded-xl border border-[var(--border)] p-3 text-left" key={book.id} onClick={() => setSelected(book)} type="button"><span className="block font-semibold">{book.title}</span><span className="text-sm text-secondary">{book.author} · {book.totalPages} pages</span></button>)}</div> : null}
          <form action={action} className="mt-5 grid gap-4 sm:grid-cols-2">
            <Field defaultValue={selected.title} label="Title" name="title" required />
            <Field defaultValue={selected.author} label="Author" name="author" required />
            <Field defaultValue={selected.totalPages} label="Total pages" min="1" name="totalPages" required type="number" />
            <Field defaultValue={selected.coverUrl} label="Cover URL (optional)" name="coverUrl" type="url" />
            {state.error ? <p className="text-sm text-red-200 sm:col-span-2" role="alert">{state.error}</p> : null}
            <button className="primary-button sm:col-span-2" disabled={pending}>{pending ? "Saving…" : "Save to library"}</button>
          </form>
        </div>
      </div> : null}
    </>
  );
}

function Field({ label, name, ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string; name: string }) {
  return <label className="block"><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">{label}</span><input className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4" key={String(props.defaultValue ?? "")} name={name} {...props} /></label>;
}
