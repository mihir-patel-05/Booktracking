import Link from "next/link";
import { Trash2 } from "lucide-react";
import { AddBookSheet } from "@/components/books/add-book-sheet";
import { PageHeading } from "@/components/app/page-heading";
import { createClient } from "@/lib/supabase/server";
import { deleteBook } from "./actions";

export default async function LibraryPage({ searchParams }: { searchParams: Promise<{ status?: string }> }) {
  const { status } = await searchParams;
  const supabase = await createClient();
  let query = supabase.from("books").select("id,title,author,cover_url,total_pages,current_page,status").order("updated_at", { ascending: false });
  if (["Want to Read", "Currently Reading", "Completed", "Abandoned"].includes(status ?? "")) query = query.eq("status", status!);
  const { data: books } = await query;

  return <><PageHeading eyebrow="Your shelves" title="Library" description="Search Google Books or add any title manually." action={<AddBookSheet />} />
    <div className="mb-5 flex gap-2 overflow-x-auto pb-2">{["All", "Currently Reading", "Want to Read", "Completed"].map((item) => <Link className={`flex min-h-11 shrink-0 items-center rounded-xl border px-4 text-sm ${(!status && item === "All") || status === item ? "border-accent bg-accent/15 text-accent-light" : "border-[var(--border)] text-secondary"}`} href={item === "All" ? "/app/library" : `/app/library?status=${encodeURIComponent(item)}`} key={item}>{item}</Link>)}</div>
    {books?.length ? <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">{books.map((book) => <article className="glass-card group rounded-2xl p-5" key={book.id}><Link className="block min-h-24" href={`/app/books/${book.id}`}><p className="font-display text-xl leading-snug">{book.title}</p><p className="mt-1 text-sm text-secondary">{book.author}</p><p className="mt-4 text-xs uppercase tracking-[.1em] text-accent-light">{book.status}</p><p className="mt-2 text-xs text-muted">{book.current_page} / {book.total_pages} pages</p></Link><form action={deleteBook} className="mt-3 border-t border-[var(--border)] pt-2"><input name="id" type="hidden" value={book.id} /><button className="flex min-h-11 items-center gap-2 text-sm text-red-200" type="submit"><Trash2 size={16} />Delete</button></form></article>)}</div> : <div className="glass-card rounded-2xl p-8 text-center text-secondary">No books on this shelf yet.</div>}
  </>;
}
