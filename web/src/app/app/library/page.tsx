import Link from "next/link";
import { Trash2 } from "lucide-react";
import { AddBookSheet } from "@/components/books/add-book-sheet";
import { PageHeading } from "@/components/app/page-heading";
import { Meter } from "@/components/app/register";
import { percentRead } from "@/lib/format";
import { createClient } from "@/lib/supabase/server";
import { deleteBook } from "./actions";

/** The shelves, as the register names them. */
const SHELVES = [
  { status: "Currently Reading", label: "Reading", tag: "tag-accent" },
  { status: "Want to Read", label: "To read", tag: "tag-outline" },
  { status: "Completed", label: "Finished", tag: "tag-neutral" },
  { status: "Abandoned", label: "Set aside", tag: "tag-outline" },
] as const;

const SHELF_BY_STATUS = new Map(SHELVES.map((shelf) => [shelf.status as string, shelf]));

export default async function LibraryPage({ searchParams }: { searchParams: Promise<{ status?: string; q?: string }> }) {
  const { status, q } = await searchParams;
  const shelf = SHELF_BY_STATUS.has(status ?? "") ? status! : undefined;

  const supabase = await createClient();
  let query = supabase.from("books").select("id,title,author,total_pages,current_page,status,updated_at").order("updated_at", { ascending: false });
  if (shelf) query = query.eq("status", shelf);

  const [{ data: books }, { data: all }, { data: recent }] = await Promise.all([
    query,
    supabase.from("books").select("status"),
    supabase.from("reading_sessions").select("book_id,session_local_date").order("session_local_date", { ascending: false }).limit(500),
  ]);

  const lastRead = new Map<string, string>();
  for (const session of recent ?? []) if (!lastRead.has(session.book_id)) lastRead.set(session.book_id, session.session_local_date);

  const counts = new Map<string, number>();
  for (const book of all ?? []) counts.set(book.status, (counts.get(book.status) ?? 0) + 1);

  const needle = q?.trim().toLocaleLowerCase();
  const rows = (needle ? books?.filter((book) => `${book.title} ${book.author}`.toLocaleLowerCase().includes(needle)) : books) ?? [];
  const total = all?.length ?? 0;

  return (
    <>
      <PageHeading
        action={<AddBookSheet />}
        description="Every volume you have entered, searched from Google Books or catalogued by hand."
        eyebrow="Your shelves"
        title="Library"
      />

      <div className="flex flex-col gap-4 border-y border-line py-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex gap-6 overflow-x-auto text-[12.5px]">
          <ShelfLink active={!shelf} count={total} href="/app/library" label="All" />
          {SHELVES.map((entry) => (
            <ShelfLink
              active={shelf === entry.status}
              count={counts.get(entry.status) ?? 0}
              href={`/app/library?status=${encodeURIComponent(entry.status)}`}
              key={entry.status}
              label={entry.label}
            />
          ))}
        </div>
        <form className="flex items-center gap-2.5" method="get">
          {shelf ? <input name="status" type="hidden" value={shelf} /> : null}
          <input aria-label="Search title or author" className="input w-full lg:w-[230px]" defaultValue={q} name="q" placeholder="Search title or author" />
          <button className="btn btn-secondary" type="submit">Search</button>
        </form>
      </div>

      {rows.length ? (
        <table className="table mt-1">
          <thead>
            <tr>
              <th className="w-[46px]">No.</th>
              <th>Title</th>
              <th className="hidden w-[190px] md:table-cell">Author</th>
              <th className="hidden w-[130px] sm:table-cell">Standing</th>
              <th className="hidden w-[170px] lg:table-cell">Progress</th>
              <th className="hidden w-[110px] text-right lg:table-cell">Last read</th>
              <th className="w-[44px]"><span className="sr-only">Remove</span></th>
            </tr>
          </thead>
          <tbody className="tnum">
            {rows.map((book, index) => {
              const entry = SHELF_BY_STATUS.get(book.status);
              const pct = percentRead(book.current_page, book.total_pages);
              const read = lastRead.get(book.id);
              return (
                <tr key={book.id}>
                  <td className="text-faint">{String(rows.length - index).padStart(3, "0")}</td>
                  <td>
                    <Link className="font-display text-[19px] leading-snug" href={`/app/books/${book.id}`}>{book.title}</Link>
                    <span className="block text-xs text-muted md:hidden">{book.author}</span>
                  </td>
                  <td className="hidden md:table-cell">{book.author}</td>
                  <td className="hidden sm:table-cell"><span className={`tag ${entry?.tag ?? "tag-neutral"}`}>{entry?.label ?? book.status}</span></td>
                  <td className="hidden lg:table-cell"><Meter caption={`${book.current_page} / ${book.total_pages}`} thickness={2} value={pct} /></td>
                  <td className="hidden text-right text-secondary lg:table-cell">{read ?? "—"}</td>
                  <td className="text-right">
                    <form action={deleteBook}>
                      <input name="id" type="hidden" value={book.id} />
                      <button aria-label={`Remove ${book.title}`} className="btn btn-ghost text-muted hover:text-[var(--danger)]" type="submit"><Trash2 size={15} strokeWidth={1.5} /></button>
                    </form>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      ) : (
        <p className="mt-10 text-center text-sm text-muted">No volumes stand on this shelf yet.</p>
      )}

      {rows.length ? <p className="mt-5 text-xs text-muted">Showing {rows.length} of {total}</p> : null}
    </>
  );
}

function ShelfLink({ href, label, count, active }: { href: string; label: string; count: number; active: boolean }) {
  return (
    <Link
      aria-current={active ? "page" : undefined}
      className={`shrink-0 whitespace-nowrap pb-0.5 ${active ? "border-b border-gold text-gold-text" : "text-secondary hover:text-foreground"}`}
      href={href}
    >
      {label} <span className="tnum text-faint">{count}</span>
    </Link>
  );
}
