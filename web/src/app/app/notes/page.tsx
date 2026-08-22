import Link from "next/link";
import { PageHeading } from "@/components/app/page-heading";
import { createClient } from "@/lib/supabase/server";
import { deleteNote, saveNote } from "./actions";

type Search = { q?: string; book?: string };

const day = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "long", year: "numeric" });

export default async function NotesPage({ searchParams }: { searchParams: Promise<Search> }) {
  const filters = await searchParams;
  const supabase = await createClient();
  let noteQuery = supabase.from("session_notes").select("id,book_id,title,content,tags,chapter_reference,created_at,books(title)").order("updated_at", { ascending: false }).limit(250);
  if (filters.book) noteQuery = noteQuery.eq("book_id", filters.book);
  const [{ data: rawNotes }, { data: books }] = await Promise.all([noteQuery, supabase.from("books").select("id,title").order("title")]);
  const needle = filters.q?.trim().toLocaleLowerCase();
  const notes = needle ? rawNotes?.filter((note) => `${note.title} ${note.content} ${note.tags.join(" ")}`.toLocaleLowerCase().includes(needle)) : rawNotes;

  const tally = new Map<string, number>();
  for (const note of rawNotes ?? []) for (const tag of note.tags as string[]) tally.set(tag, (tally.get(tag) ?? 0) + 1);
  const mostUsed = [...tally.entries()].sort((a, b) => b[1] - a[1]).slice(0, 7).map(([tag]) => tag);

  return (
    <>
      <PageHeading
        description="Search, tag and revise; ideas from one volume find their way to another."
        eyebrow="Commonplace book"
        title="Notes"
      />

      <form className="flex flex-col gap-3 border-y border-line py-3.5 sm:flex-row sm:items-center" method="get">
        <input aria-label="Search notes" className="input flex-1" defaultValue={filters.q} name="q" placeholder="Search notes or tags" />
        <select aria-label="Filter by volume" className="input sm:w-[220px]" defaultValue={filters.book} name="book">
          <option value="">All volumes</option>
          {books?.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}
        </select>
        <button className="btn btn-secondary" type="submit">Filter</button>
      </form>

      {mostUsed.length ? (
        <div className="mb-7 mt-4 flex flex-wrap items-center gap-2">
          <span className="mr-1 text-[10px] uppercase tracking-[.16em] text-faint">Most used</span>
          {mostUsed.map((tag) => (
            <Link className={`tag ${filters.q === tag ? "tag-outline" : "tag-neutral"}`} href={`/app/notes?q=${encodeURIComponent(tag)}`} key={tag}>#{tag}</Link>
          ))}
        </div>
      ) : <div className="mb-7" />}

      <details className="plate mb-8 px-5 py-4">
        <summary className="cursor-pointer font-display text-[20px] text-gold-text">Write a note</summary>
        <NoteForm books={books ?? []} />
      </details>

      {notes?.length ? (
        <div className="lg:columns-2 lg:gap-10">
          {notes.map((note, index) => (
            <article className={`plate mb-6 break-inside-avoid px-6 py-6 ${index % 3 === 0 ? "plate-filled" : ""}`} key={note.id}>
              <p className="text-[10px] uppercase tracking-[.14em] text-gold">
                {note.books?.title}{note.chapter_reference ? ` · ${note.chapter_reference}` : ""}
              </p>
              <h2 className="my-2.5 font-display text-[23px] leading-tight">{note.title}</h2>
              <p className="m-0 whitespace-pre-wrap text-sm leading-[1.75] text-secondary [hyphens:auto] [text-align:justify]">
                {note.content || "No further text."}
              </p>
              {note.tags.length ? (
                <div className="mt-4 flex flex-wrap gap-[7px]">
                  {note.tags.map((tag: string) => (
                    <Link className="tag tag-outline" href={`/app/notes?q=${encodeURIComponent(tag)}`} key={tag}>#{tag}</Link>
                  ))}
                </div>
              ) : null}
              <details className="mt-4 border-t border-line-soft pt-3.5">
                <summary className="flex cursor-pointer items-center justify-between text-[11.5px] text-muted">
                  <span>{day.format(new Date(note.created_at))}</span>
                  <span className="text-gold-text">Revise</span>
                </summary>
                <NoteForm books={books ?? []} note={{ id: note.id, book_id: note.book_id, title: note.title, content: note.content, tags: note.tags, chapter_reference: note.chapter_reference }} />
                <form action={deleteNote} className="mt-3">
                  <input name="id" type="hidden" value={note.id} />
                  <button className="btn btn-ghost text-[var(--danger)]" type="submit">Strike this note out</button>
                </form>
              </details>
            </article>
          ))}
        </div>
      ) : (
        <p className="mt-10 text-center text-sm text-muted">No notes match this view.</p>
      )}
    </>
  );
}

type Book = { id: string; title: string };
type Note = { id: string; book_id: string; title: string; content: string; tags: string[]; chapter_reference: string | null };

function NoteForm({ books, note }: { books: Book[]; note?: Note }) {
  return (
    <form action={saveNote} className="mt-5 grid gap-5 sm:grid-cols-2">
      {note ? <input name="id" type="hidden" value={note.id} /> : null}
      <label className="block">
        <span className="field-label">Volume</span>
        <select className="input" defaultValue={note?.book_id} name="bookId" required>
          <option disabled value="">Choose a volume</option>
          {books.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}
        </select>
      </label>
      <Field defaultValue={note?.title} label="Title" name="title" required />
      <label className="block sm:col-span-2">
        <span className="field-label">The note</span>
        <textarea className="input min-h-32" defaultValue={note?.content} name="content" />
      </label>
      <Field defaultValue={note?.chapter_reference ?? ""} label="Chapter or page" name="chapter" />
      <Field defaultValue={note?.tags.join(", ")} label="Tags, comma separated" name="tags" />
      <button className="btn btn-primary btn-block sm:col-span-2" type="submit">{note ? "Save the revision" : "Enter the note"}</button>
    </form>
  );
}

function Field({ label, ...input }: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <input className="input" {...input} />
    </label>
  );
}
