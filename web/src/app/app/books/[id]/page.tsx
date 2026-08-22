import Link from "next/link";
import { notFound } from "next/navigation";
import { Timer } from "lucide-react";
import { Ledger, SectionHeading } from "@/components/app/register";
import { ProgressForm } from "@/components/books/progress-form";
import { percentRead } from "@/lib/format";
import { SHELF_BY_STATUS } from "@/lib/shelves";
import { createClient } from "@/lib/supabase/server";

const day = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" });

export default async function BookPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const [{ data: book }, { data: sessions }, { data: notes }] = await Promise.all([
    supabase.from("books").select("id,title,author,current_page,total_pages,status,date_added").eq("id", id).maybeSingle(),
    supabase.from("reading_sessions").select("id,started_at,duration_seconds,xp_earned,mood_tags").eq("book_id", id).order("started_at", { ascending: false }).limit(60),
    supabase.from("session_notes").select("id,title,chapter_reference,updated_at").eq("book_id", id).order("updated_at", { ascending: false }).limit(4),
  ]);
  if (!book) notFound();

  const pct = percentRead(book.current_page, book.total_pages);
  const shelf = SHELF_BY_STATUS.get(book.status);
  const sittings = sessions ?? [];
  const totalSeconds = sittings.reduce((sum, session) => sum + session.duration_seconds, 0);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.round((totalSeconds % 3600) / 60);
  const pagesPerHour = totalSeconds > 0 ? Math.round(book.current_page / (totalSeconds / 3600)) : 0;

  const moods = new Map<string, number>();
  for (const session of sittings) for (const mood of session.mood_tags as string[]) moods.set(mood, (moods.get(mood) ?? 0) + 1);
  const ranked = [...moods.entries()].sort((a, b) => b[1] - a[1]);

  return (
    <>
      <div className="border-b border-line pb-10 pt-6 text-center sm:pt-10">
        <p className="eyebrow tracking-[.24em]">{shelf?.label ?? book.status}</p>
        <h1 className="mt-5 font-display text-[38px] leading-[1.06] tracking-[-.02em] sm:text-[58px]">{book.title}</h1>
        <div className="mt-[18px] flex items-center justify-center gap-3.5">
          <span className="h-px w-10 bg-[var(--border-strong)]" />
          <span className="text-[15px] italic text-secondary">{book.author}</span>
          <span className="h-px w-10 bg-[var(--border-strong)]" />
        </div>
        <div className="mt-6 flex flex-wrap items-center justify-center gap-4">
          <Link className="btn btn-primary" href={`/app/timer?book=${book.id}`}><Timer size={15} strokeWidth={1.5} />Read now</Link>
          <Link className="btn btn-secondary" href="/app/notes">Add a note</Link>
          <Link className="btn btn-secondary" href="/app/quotes">Copy a line</Link>
        </div>
      </div>

      <div className="grid gap-12 pt-10 lg:grid-cols-[minmax(0,1fr)_384px] lg:gap-14">
        <section>
          <div className="flex items-baseline justify-between gap-4">
            <h2 className="font-display text-[26px]">Progress</h2>
            <span className="tnum font-display text-[30px]">{pct}%</span>
          </div>

          {/* A hairline through the volume, with the reader's place marked. */}
          <div className="relative mt-4 h-px bg-line">
            <div className="absolute left-0 top-[-1px] h-[3px] bg-gold" style={{ width: `${pct}%` }} />
            <div className="absolute top-[-8px] h-[17px] w-px bg-foreground" style={{ left: `${pct}%` }} />
          </div>
          <div className="tnum mt-2.5 flex justify-between text-[11px] text-faint">
            <span>p. 1</span>
            <span>p. {book.current_page}</span>
            <span>p. {book.total_pages}</span>
          </div>

          <div className="mt-9 border-t border-line pt-7">
            <ProgressForm book={book} />
          </div>

          <div className="mt-11">
            <SectionHeading
              note={sittings.length ? `${sittings.length} ${sittings.length === 1 ? "sitting" : "sittings"} entered against this volume.` : undefined}
              title="Reading ledger"
            />
            {sittings.length ? (
              <table className="table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th className="w-24 text-right">Minutes</th>
                    <th className="w-20 text-right">XP</th>
                  </tr>
                </thead>
                <tbody className="tnum">
                  {sittings.slice(0, 12).map((session) => (
                    <tr key={session.id}>
                      <td>{day.format(new Date(session.started_at))}</td>
                      <td className="text-right">{Math.round(session.duration_seconds / 60)}</td>
                      <td className="text-right text-gold-text">+{session.xp_earned}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="text-sm text-muted">No sittings entered against this volume yet.</p>
            )}
          </div>
        </section>

        <aside>
          <div className="plate px-6 py-5">
            <p className="eyebrow eyebrow-muted mb-4">This volume, in figures</p>
            <Ledger
              rows={[
                { label: "Hours inside", value: totalSeconds ? `${hours}h ${minutes}m` : "—" },
                { label: "Pages per hour", value: pagesPerHour || "—" },
                { label: "Opened", value: day.format(new Date(book.date_added)) },
                { label: "Pages remaining", value: Math.max(0, book.total_pages - book.current_page) },
              ]}
            />
          </div>

          {ranked.length ? (
            <div className="mt-8">
              <p className="eyebrow eyebrow-muted mb-3">Moods recorded</p>
              <div className="flex flex-wrap gap-[7px]">
                {ranked.map(([mood, count], index) => (
                  <span className={`tag ${index === 0 ? "tag-accent" : "tag-neutral"}`} key={mood}>{mood} · {count}</span>
                ))}
              </div>
            </div>
          ) : null}

          {notes?.length ? (
            <div className="mt-8 border-t border-line pt-6">
              <p className="eyebrow eyebrow-muted mb-3.5">Notes on this volume · {notes.length}</p>
              {notes.map((note) => (
                <Link className="block border-b border-line-soft py-3 last:border-b-0" href="/app/notes" key={note.id}>
                  <p className="font-display text-[17px]">{note.title}</p>
                  <p className="mt-0.5 text-xs text-muted">
                    {note.chapter_reference ? `${note.chapter_reference} · ` : ""}{day.format(new Date(note.updated_at))}
                  </p>
                </Link>
              ))}
            </div>
          ) : null}
        </aside>
      </div>
    </>
  );
}
