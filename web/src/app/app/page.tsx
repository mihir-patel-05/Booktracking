import Link from "next/link";
import { Timer } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { Attendance, Figure, FigureBand, Meter, SectionHeading } from "@/components/app/register";
import { dateOffset, localDate } from "@/lib/dates";
import { percentRead, roman } from "@/lib/format";
import { createClient } from "@/lib/supabase/server";

export default async function HomePage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  const { data: profile } = await supabase.from("profiles").select("time_zone").eq("id", user!.id).maybeSingle();
  const timeZone = profile?.time_zone || "UTC";
  const today = localDate(timeZone);
  const monthStart = `${today.slice(0, 7)}-01`;
  const yearStart = `${today.slice(0, 4)}-01-01`;

  const [{ data: books }, { data: stats }, { data: monthSessions }, { data: finished }, { data: quotes }, { data: notes }, { data: plans }] = await Promise.all([
    supabase.from("books").select("id,title,author,current_page,total_pages").eq("status", "Currently Reading").order("updated_at", { ascending: false }).limit(4),
    supabase.from("user_stats").select("current_streak,total_xp,total_seconds").maybeSingle(),
    supabase.from("reading_sessions").select("book_id,session_local_date,duration_seconds").gte("session_local_date", monthStart).lte("session_local_date", today),
    supabase.from("books").select("id,title,total_pages,date_completed").eq("status", "Completed").gte("date_completed", yearStart).order("date_completed", { ascending: true }).limit(40),
    supabase.from("quotes").select("id,text,books(title)").order("updated_at", { ascending: false }).limit(20),
    supabase.from("session_notes").select("id,title,chapter_reference,books(title)").order("updated_at", { ascending: false }).limit(3),
    supabase.from("reading_plans").select("id,book_id,target_minutes,target_pages,books(title)").eq("planned_date", today).order("created_at", { ascending: true }),
  ]);

  const minutesByDay = new Map<string, number>();
  /** The volumes actually opened today — what turns a plan into a sitting kept. */
  const readTodayBooks = new Set<string>();
  for (const session of monthSessions ?? []) {
    minutesByDay.set(session.session_local_date, (minutesByDay.get(session.session_local_date) ?? 0) + session.duration_seconds / 60);
    if (session.session_local_date === today) readTodayBooks.add(session.book_id);
  }
  const readToday = Math.round(minutesByDay.get(today) ?? 0);
  const daysThisMonth = Number(today.slice(-2));
  const attendance = Array.from({ length: daysThisMonth }, (_, index) => {
    const date = dateOffset(monthStart, index);
    return { date, minutes: Math.round(minutesByDay.get(date) ?? 0) };
  });

  const totalXp = stats?.total_xp ?? 0;
  const level = Math.floor(totalXp / 100) + 1;
  const levelXp = totalXp % 100;

  const spines = (finished ?? []).map((book) => book.total_pages || 0);
  const tallest = Math.max(1, ...spines);
  const quote = quotes?.length ? quotes[Math.floor(Math.random() * quotes.length)] : undefined;

  const headline = readToday
    ? `${readToday} minutes read, and the evening still open.`
    : "The page is where you left it.";

  return (
    <>
      <PageHeading
        action={<Link className="btn btn-primary" href="/app/timer"><Timer size={15} strokeWidth={1.5} />Begin a session</Link>}
        eyebrow="The reading day"
        title={headline}
      />

      <FigureBand cols={4}>
        <Figure label="Current streak" unit="days" value={stats?.current_streak ?? 0} />
        <Figure label="Read today" unit="min" value={readToday} />
        <Figure label="Standing" value={`Level ${roman(level)}`} />
        <Figure label={`Toward Level ${roman(level + 1)}`} value={levelXp}>
          <div className="mt-2.5"><Meter thickness={2} value={levelXp} /></div>
          <p className="tnum mt-2 text-[11px] text-faint">{levelXp} / 100 XP</p>
        </Figure>
      </FigureBand>

      <div className="mt-11 grid gap-12 lg:grid-cols-[minmax(0,1fr)_344px]">
        <section>
          <SectionHeading
            aside={<Link className="text-xs text-gold-text" href="/app/library">All shelves →</Link>}
            title="Currently reading"
          />
          {books?.length ? (
            <div className="border-t border-line">
              {books.map((book) => {
                const pct = percentRead(book.current_page, book.total_pages);
                return (
                  <Link className="grid grid-cols-[minmax(0,1fr)_78px] items-center gap-5 border-b border-line py-5 sm:grid-cols-[minmax(0,1fr)_132px_78px]" href={`/app/books/${book.id}`} key={book.id}>
                    <div>
                      <p className="font-display text-[23px] leading-tight">{book.title}</p>
                      <p className="mt-1 text-[13px] text-muted">{book.author}</p>
                    </div>
                    <div className="hidden sm:block">
                      <Meter caption={`${book.current_page} / ${book.total_pages} pp.`} value={pct} />
                    </div>
                    <p className="tnum text-right font-display text-[22px] text-secondary">{pct}%</p>
                  </Link>
                );
              })}
            </div>
          ) : (
            <div className="plate px-6 py-10 text-center">
              <p className="font-display text-[23px]">Your next chapter starts here.</p>
              <p className="mt-2 text-sm text-muted">Enter a volume and the register begins.</p>
              <Link className="btn btn-secondary mt-5" href="/app/library">Enter a volume</Link>
            </div>
          )}

          <div className="mt-11">
            <SectionHeading note="Each spine is a volume; its height, the pages within." title="Finished this year" />
            {spines.length ? (
              <>
                <div className="flex h-28 items-end gap-1.5 border-b border-foreground">
                  {spines.map((pages, index) => (
                    <div
                      className="border border-b-0 border-[var(--border-strong)]"
                      key={`${finished![index].id}`}
                      style={{
                        width: 9 + Math.round((pages / tallest) * 10),
                        height: `${Math.max(18, Math.round((pages / tallest) * 100))}%`,
                        background: `color-mix(in srgb, var(--gold) ${Math.round((pages / tallest) * 28)}%, transparent)`,
                      }}
                      title={`${finished![index].title} · ${pages} pp.`}
                    />
                  ))}
                </div>
                <div className="tnum mt-2.5 flex justify-between text-[10.5px] uppercase tracking-[.12em] text-muted">
                  <span>{spines.length} {spines.length === 1 ? "volume" : "volumes"}</span>
                  <span>{yearStart.slice(0, 4)}</span>
                </div>
              </>
            ) : (
              <p className="text-sm text-muted">Nothing closed yet this year.</p>
            )}
          </div>
        </section>

        <aside className="flex flex-col gap-9">
          <section>
            <p className="eyebrow mb-3.5">From the commonplace book</p>
            {quote ? (
              <>
                <blockquote className="border-l border-gold pl-5">
                  <p className="font-display text-[23px] leading-[1.34]">{quote.text}</p>
                  <footer className="mt-3 text-xs text-muted">{quote.books?.title}</footer>
                </blockquote>
                <Link className="btn btn-secondary mt-4" href="/app/quotes?random=1">Another line</Link>
              </>
            ) : (
              <p className="text-sm text-muted">No lines copied out yet.</p>
            )}
          </section>

          <div className="rule" />

          <section>
            <p className="eyebrow eyebrow-muted mb-3.5">Marginalia, this week</p>
            {notes?.length ? (
              <div>
                {notes.map((note) => (
                  <Link className="block border-b border-line-soft py-3.5" href="/app/notes" key={note.id}>
                    <p className="font-display text-[17px]">{note.title}</p>
                    <p className="mt-1 text-xs text-muted">{note.books?.title}{note.chapter_reference ? ` · ${note.chapter_reference}` : ""}</p>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted">Nothing written in the margins yet.</p>
            )}
          </section>

          <section>
            <div className="mb-3.5 flex items-baseline justify-between gap-4">
              <p className="eyebrow eyebrow-muted">In the diary today</p>
              <Link className="text-xs text-gold-text" href="/app/calendar">The diary →</Link>
            </div>
            {plans?.length ? (
              <div className="border-t border-line">
                {plans.map((plan) => {
                  const kept = readTodayBooks.has(plan.book_id);
                  const target = [plan.target_minutes ? `${plan.target_minutes} min` : null, plan.target_pages ? `${plan.target_pages} pp.` : null].filter(Boolean).join(" · ");
                  return (
                    <div className="flex items-center justify-between gap-3 border-b border-line-soft py-3" key={plan.id}>
                      <div className="min-w-0">
                        <Link className="block truncate font-display text-[17px]" href={`/app/books/${plan.book_id}`}>{plan.books?.title}</Link>
                        {target ? <p className="tnum mt-0.5 text-xs text-muted">{target}</p> : null}
                      </div>
                      {kept ? (
                        <span className="tag tag-accent shrink-0">Kept</span>
                      ) : (
                        <Link className="btn btn-ghost shrink-0 text-[12.5px]" href={`/app/timer?book=${plan.book_id}`}>Sit down</Link>
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
              <p className="text-sm text-muted">No sitting appointed for today. <Link className="text-gold-text" href="/app/calendar">Plan one →</Link></p>
            )}
          </section>

          <section>
            <p className="eyebrow eyebrow-muted mb-3">This month’s attendance</p>
            <Attendance days={attendance} />
          </section>
        </aside>
      </div>
    </>
  );
}
