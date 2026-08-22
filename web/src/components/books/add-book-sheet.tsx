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

  if (!open) return <button className="btn btn-primary" onClick={() => setOpen(true)} type="button">Enter a volume</button>;

  return (
    <>
      <button className="btn btn-primary" onClick={() => setOpen(true)} type="button">Enter a volume</button>
      <div aria-modal="true" className="fixed inset-0 z-50 flex items-end justify-center bg-[rgba(45,43,43,.42)] sm:items-center sm:p-10" role="dialog">
        <div className="max-h-[94svh] w-full overflow-y-auto border border-[var(--border-strong)] bg-background shadow-[var(--shadow-lg)] sm:max-w-[720px]">

          <div className="flex items-start justify-between gap-4 border-b border-line px-6 py-6 sm:px-[34px] sm:py-7">
            <div>
              <p className="eyebrow">Accession</p>
              <h2 className="mt-2.5 font-display text-[30px] leading-none">Enter a volume</h2>
            </div>
            <button aria-label="Close" className="btn btn-icon btn-secondary shrink-0" onClick={() => setOpen(false)} type="button"><X size={15} strokeWidth={1.5} /></button>
          </div>

          <div className="px-6 pt-6 sm:px-[34px]">
            <form className="flex gap-2.5" onSubmit={search}>
              <input aria-label="Search Google Books" className="input min-w-0 flex-1" onChange={(event) => setQuery(event.target.value)} placeholder="Title, author, or ISBN" value={query} />
              <button className="btn btn-primary shrink-0" disabled={searching} type="submit"><Search size={15} strokeWidth={1.5} />Search</button>
            </form>

            {results.length ? (
              <>
                <p className="mb-2 mt-5 text-[10px] uppercase tracking-[.16em] text-faint">
                  {results.length} found in Google Books
                </p>
                <div className="max-h-56 overflow-y-auto border-t border-line">
                  {results.map((book) => {
                    const chosen = selected.id === book.id;
                    return (
                      <button
                        className={`flex w-full items-center justify-between gap-4 border-b border-line-soft px-3 py-3 text-left ${chosen ? "border-l-2 border-l-gold bg-[var(--gold-tint)]" : ""}`}
                        key={book.id}
                        onClick={() => setSelected(book)}
                        type="button"
                      >
                        <span>
                          <span className="block font-display text-[19px] leading-snug">{book.title}</span>
                          <span className="text-[12.5px] text-muted">{book.author}</span>
                        </span>
                        <span className="tnum shrink-0 text-xs text-muted">{book.totalPages} pp.</span>
                      </button>
                    );
                  })}
                </div>
              </>
            ) : null}
          </div>

          <form action={action} className="px-6 pb-7 pt-6 sm:px-[34px]">
            <p className="mb-3.5 text-[10px] uppercase tracking-[.16em] text-faint">Or set it down by hand</p>
            <div className="grid gap-4 sm:grid-cols-2">
              <Field defaultValue={selected.title} label="Title" name="title" required />
              <Field defaultValue={selected.author} label="Author" name="author" required />
              <Field className="input tnum" defaultValue={selected.totalPages} label="Total pages" min="1" name="totalPages" required type="number" />
              <Field defaultValue={selected.coverUrl} label="Cover URL (optional)" name="coverUrl" type="url" />
            </div>
            {state.error ? <p className="mt-4 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
            <div className="mt-6 flex justify-end gap-3 border-t border-line pt-6">
              <button className="btn btn-secondary" onClick={() => setOpen(false)} type="button">Cancel</button>
              <button className="btn btn-primary" disabled={pending} type="submit">{pending ? "Entering…" : "Enter into the register"}</button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}

function Field({ label, name, className = "input", ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string; name: string }) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <input className={className} key={String(props.defaultValue ?? "")} name={name} {...props} />
    </label>
  );
}
