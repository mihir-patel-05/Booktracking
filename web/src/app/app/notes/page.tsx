import Link from "next/link";
import { PageHeading } from "@/components/app/page-heading";
import { createClient } from "@/lib/supabase/server";
import { deleteNote, saveNote } from "./actions";

type Search = { q?: string; book?: string };

export default async function NotesPage({ searchParams }: { searchParams: Promise<Search> }) {
  const filters = await searchParams;
  const supabase = await createClient();
  let noteQuery = supabase.from("session_notes").select("id,book_id,title,content,tags,chapter_reference,created_at,books(title)").order("updated_at", { ascending: false }).limit(250);
  if (filters.book) noteQuery = noteQuery.eq("book_id", filters.book);
  const [{ data: rawNotes }, { data: books }] = await Promise.all([noteQuery, supabase.from("books").select("id,title").order("title")]);
  const needle = filters.q?.trim().toLocaleLowerCase();
  const notes = needle ? rawNotes?.filter((note) => `${note.title} ${note.content} ${note.tags.join(" ")}`.toLocaleLowerCase().includes(needle)) : rawNotes;

  return <><PageHeading eyebrow="Reading journal" title="Notes" description="Search, tag, revise, and connect ideas across your library." />
    <form className="glass-card mb-5 grid gap-3 rounded-2xl p-4 sm:grid-cols-[1fr_220px_auto]" method="get"><input aria-label="Search notes" className="min-h-12 rounded-xl border border-[var(--border)] bg-black/20 px-4" defaultValue={filters.q} name="q" placeholder="Search notes or tags" /><select aria-label="Filter by book" className="min-h-12 rounded-xl border border-[var(--border)] bg-[#141424] px-4" defaultValue={filters.book} name="book"><option value="">All books</option>{books?.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}</select><button className="secondary-button">Filter</button></form>
    <details className="glass-card mb-6 rounded-2xl p-5"><summary className="min-h-11 cursor-pointer font-semibold text-accent-light">Write a new note</summary><NoteForm books={books ?? []} /></details>
    {notes?.length ? <div className="grid gap-4 lg:grid-cols-2">{notes.map((note) => <article className="glass-card rounded-2xl p-5" key={note.id}><p className="text-xs uppercase tracking-[.12em] text-accent-light">{note.books?.title}{note.chapter_reference ? ` · ${note.chapter_reference}` : ""}</p><h2 className="mt-2 font-display text-xl">{note.title}</h2><p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-secondary">{note.content || "No additional text."}</p>{note.tags.length ? <div className="mt-4 flex flex-wrap gap-2">{note.tags.map((tag: string) => <Link className="rounded-full bg-accent/10 px-3 py-1 text-xs text-accent-light" href={`/app/notes?q=${encodeURIComponent(tag)}`} key={tag}>#{tag}</Link>)}</div> : null}<details className="mt-4 border-t border-[var(--border)] pt-2"><summary className="flex min-h-11 cursor-pointer items-center text-sm text-secondary">Edit note</summary><NoteForm books={books ?? []} note={{ id: note.id, book_id: note.book_id, title: note.title, content: note.content, tags: note.tags, chapter_reference: note.chapter_reference }} /><form action={deleteNote} className="mt-2"><input name="id" type="hidden" value={note.id} /><button className="flex min-h-11 items-center text-sm text-red-200">Delete note</button></form></details></article>)}</div> : <div className="glass-card rounded-2xl p-8 text-center text-secondary">No notes match this view.</div>}
  </>;
}

type Book = { id: string; title: string };
type Note = { id: string; book_id: string; title: string; content: string; tags: string[]; chapter_reference: string | null };
function NoteForm({ books, note }: { books: Book[]; note?: Note }) {
  return <form action={saveNote} className="mt-4 grid gap-4 sm:grid-cols-2">{note ? <input name="id" type="hidden" value={note.id} /> : null}<label><span className="mb-2 block text-xs text-muted">Book</span><select className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#141424] px-4" defaultValue={note?.book_id} name="bookId" required><option disabled value="">Choose a book</option>{books.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}</select></label><Field defaultValue={note?.title} label="Title" name="title" required /><label className="sm:col-span-2"><span className="mb-2 block text-xs text-muted">Note</span><textarea className="min-h-32 w-full rounded-xl border border-[var(--border)] bg-black/20 p-4" defaultValue={note?.content} name="content" /></label><Field defaultValue={note?.chapter_reference ?? ""} label="Chapter or page" name="chapter" /><Field defaultValue={note?.tags.join(", ")} label="Tags" name="tags" /><button className="primary-button sm:col-span-2">{note ? "Save changes" : "Save note"}</button></form>;
}
function Field(props: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) { const { label, ...input } = props; return <label><span className="mb-2 block text-xs text-muted">{label}</span><input className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4" {...input} /></label>; }
