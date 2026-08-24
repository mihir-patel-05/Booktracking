"use client";

import Link from "next/link";
import { CalendarPlus, Check, Timer, Trash2 } from "lucide-react";
import { useActionState, useEffect, useMemo, useState } from "react";
import { movePlan, planReading, removePlan, type PlanActionState } from "@/app/app/calendar/actions";
import { dayLabel, pagesPerDay, WEEKDAYS } from "@/lib/plan";

export type DiaryPlan = {
  id: string;
  bookId: string;
  title: string;
  author: string;
  targetMinutes: number | null;
  targetPages: number | null;
  note: string | null;
  kept: boolean;
};

export type DiaryDay = {
  date: string;
  outside: boolean;
  minutes: number;
  plans: DiaryPlan[];
};

export type PlannableBook = { id: string; title: string; author: string; currentPage: number; totalPages: number; status: string };

export function ReadingDiary({ days, books, today, monthStart }: { days: DiaryDay[]; books: PlannableBook[]; today: string; monthStart: string }) {
  const inMonth = today.slice(0, 7) === monthStart.slice(0, 7);
  const [selected, setSelected] = useState(inMonth ? today : monthStart);
  const [chosen, setChosen] = useState(books[0]?.id ?? "");
  const [state, action, pending] = useActionState<PlanActionState, FormData>(planReading, {});

  useEffect(() => { setSelected(inMonth ? today : monthStart); }, [inMonth, monthStart, today]);

  const day = useMemo(() => days.find((entry) => entry.date === selected), [days, selected]);
  /** The pages a day the chosen volume asks for, if it is to close by month's end. */
  const pace = useMemo(() => {
    const book = books.find((entry) => entry.id === chosen);
    const daysLeft = days.filter((entry) => !entry.outside && entry.date >= selected).length || 1;
    return book ? pagesPerDay(book.currentPage, book.totalPages, daysLeft) : 0;
  }, [books, chosen, days, selected]);

  return (
    <div className="mt-8 grid gap-10 lg:grid-cols-[minmax(0,1fr)_336px]">
      <section aria-label="Reading diary">
        <div className="grid grid-cols-7 border-b border-line">
          {WEEKDAYS.map((weekday) => (
            <div className="px-1 pb-2 text-center text-[9.5px] uppercase tracking-[.16em] text-muted" key={weekday}>
              <span className="hidden sm:inline">{weekday}</span>
              <span className="sm:hidden">{weekday[0]}</span>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-7 border-l border-line">
          {days.map((entry) => (
            <DayCell
              current={entry.date === selected}
              day={entry}
              key={entry.date}
              onSelect={() => setSelected(entry.date)}
              today={today}
            />
          ))}
        </div>

        <div className="mt-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-[11px] text-muted">
          <Key className="border border-line bg-[var(--gold-tint)]" label="Planned" />
          <Key className="border border-line bg-[color-mix(in_srgb,var(--gold)_32%,transparent)]" label="Read" />
          <Key className="rounded-full border border-gold" label="Today" />
        </div>
      </section>

      <aside className="lg:sticky lg:top-24 lg:self-start">
        <p className="eyebrow">{day && day.date === today ? "Today" : "The day"}</p>
        <h2 className="mt-2.5 font-display text-[27px] leading-tight">{dayLabel(selected)}</h2>
        <p className="tnum mt-1 text-[12.5px] text-muted">
          {day?.minutes ? `${day.minutes} min read` : "Nothing read yet"}
          {day?.plans.length ? ` · ${day.plans.length} planned` : ""}
        </p>

        <div className="mt-6 border-t border-line">
          {day?.plans.length ? (
            day.plans.map((plan) => (
              <article className="border-b border-line-soft py-4" key={plan.id}>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <Link className="font-display text-[19px] leading-snug" href={`/app/books/${plan.bookId}`}>{plan.title}</Link>
                    <p className="mt-0.5 truncate text-xs text-muted">{plan.author}</p>
                  </div>
                  <span className={`tag shrink-0 ${plan.kept ? "tag-accent" : "tag-outline"}`}>
                    {plan.kept ? <><Check className="mr-1" size={11} strokeWidth={2} />Kept</> : "Awaited"}
                  </span>
                </div>

                {plan.targetMinutes || plan.targetPages || plan.note ? (
                  <p className="tnum mt-2 text-[12.5px] text-secondary">
                    {[plan.targetMinutes ? `${plan.targetMinutes} min` : null, plan.targetPages ? `${plan.targetPages} pp.` : null]
                      .filter(Boolean)
                      .join(" · ")}
                    {plan.note ? <span className="block font-sans text-[12.5px] text-muted">{plan.note}</span> : null}
                  </p>
                ) : null}

                <div className="mt-3 flex flex-wrap items-center gap-2">
                  <Link className="btn btn-ghost text-[12.5px]" href={`/app/timer?book=${plan.bookId}`}>
                    <Timer size={13} strokeWidth={1.5} />Sit down to it
                  </Link>
                  <form action={movePlan} className="flex items-center gap-1.5">
                    <input name="id" type="hidden" value={plan.id} />
                    <input aria-label={`Move ${plan.title} to another day`} className="input tnum h-8 min-h-8 w-[136px] px-2 py-1 text-[12.5px]" defaultValue={selected} name="date" type="date" />
                    <button className="btn btn-secondary h-8 min-h-8 px-2.5 text-[12.5px]" type="submit">Move</button>
                  </form>
                  <form action={removePlan} className="ml-auto">
                    <input name="id" type="hidden" value={plan.id} />
                    <button aria-label={`Strike ${plan.title} from ${selected}`} className="btn btn-ghost text-muted hover:text-[var(--danger)]" type="submit">
                      <Trash2 size={14} strokeWidth={1.5} />
                    </button>
                  </form>
                </div>
              </article>
            ))
          ) : (
            <p className="border-b border-line-soft py-5 text-sm text-muted">No sitting entered for this day.</p>
          )}
        </div>

        {books.length ? (
          <form action={action} className="mt-6">
            <p className="eyebrow eyebrow-muted mb-3">Enter a sitting</p>
            <input name="date" type="hidden" value={selected} />
            <label className="block">
              <span className="field-label">Volume</span>
              <select className="input" name="bookId" onChange={(event) => setChosen(event.target.value)} required value={chosen}>
                {books.map((book) => (
                  <option key={book.id} value={book.id}>{book.title} — {book.author}</option>
                ))}
              </select>
            </label>
            <div className="mt-3 grid grid-cols-2 gap-3">
              <label className="block">
                <span className="field-label">Minutes</span>
                <input className="input tnum" max="1440" min="5" name="targetMinutes" placeholder="30" type="number" />
              </label>
              <label className="block">
                <span className="field-label">Pages</span>
                <input className="input tnum" max="100000" min="1" name="targetPages" placeholder={String(pace || 20)} type="number" />
              </label>
            </div>
            {pace ? <p className="tnum mt-2 text-[11px] text-faint">{pace} pp. a day closes this volume by month&rsquo;s end.</p> : null}
            <label className="mt-3 block">
              <span className="field-label">Intention (optional)</span>
              <input className="input" maxLength={500} name="note" placeholder="Finish part two" />
            </label>
            {state.error ? <p className="mt-3 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
            <button className="btn btn-primary btn-block mt-4" disabled={pending} type="submit">
              <CalendarPlus size={15} strokeWidth={1.5} />{pending ? "Entering…" : "Enter into the diary"}
            </button>
          </form>
        ) : (
          <div className="plate mt-6 px-5 py-8 text-center">
            <p className="font-display text-[21px]">Nothing to plan yet.</p>
            <p className="mt-2 text-sm text-muted">Enter a volume in the library and the diary opens.</p>
            <Link className="btn btn-secondary mt-4" href="/app/library">Go to the library</Link>
          </div>
        )}
      </aside>
    </div>
  );
}

function DayCell({ day, current, today, onSelect }: { day: DiaryDay; current: boolean; today: string; onSelect: () => void }) {
  const planned = day.plans.length;
  /* The ink deepens with the minutes read; a day merely appointed keeps a wash. */
  const tint = day.minutes ? Math.min(0.32, 0.1 + day.minutes / 320) : planned ? 0.06 : 0;
  const number = Number(day.date.slice(-2));

  return (
    <button
      aria-current={current ? "date" : undefined}
      aria-label={`${dayLabel(day.date)} — ${planned} planned, ${day.minutes} minutes read`}
      className={`flex min-h-[74px] flex-col items-stretch gap-1 border-r border-b border-line p-1.5 text-left sm:min-h-[104px] sm:p-2 ${
        day.outside ? "opacity-45" : ""
      } ${current ? "outline outline-2 -outline-offset-2 outline-gold" : ""}`}
      onClick={onSelect}
      style={tint ? { background: `color-mix(in srgb, var(--gold) ${Math.round(tint * 100)}%, transparent)` } : undefined}
      type="button"
    >
      <span className="flex items-center justify-between">
        <span className={`tnum text-[12.5px] ${day.date === today ? "grid size-[21px] place-items-center rounded-full border border-gold text-gold-text" : "text-secondary"}`}>
          {number}
        </span>
        {planned ? <span className="tnum text-[10px] text-muted sm:hidden">{planned}</span> : null}
      </span>

      <span className="hidden min-w-0 flex-col gap-1 sm:flex">
        {day.plans.slice(0, 2).map((plan) => (
          <span
            className={`truncate border-l-2 px-1 py-0.5 text-[10.5px] leading-tight ${plan.kept ? "border-l-gold text-gold-text" : "border-l-[var(--border-strong)] text-secondary"}`}
            key={plan.id}
          >
            {plan.title}
          </span>
        ))}
        {planned > 2 ? <span className="tnum px-1 text-[10px] text-muted">+{planned - 2} more</span> : null}
      </span>

      {planned ? (
        <span className="mt-auto flex gap-0.5 sm:hidden">
          {day.plans.slice(0, 3).map((plan) => (
            <span className={`size-1.5 rounded-full ${plan.kept ? "bg-gold" : "bg-[var(--border-strong)]"}`} key={plan.id} />
          ))}
        </span>
      ) : null}
    </button>
  );
}

function Key({ label, className }: { label: string; className: string }) {
  return (
    <span className="flex items-center gap-2">
      <span className={`size-3 ${className}`} />
      {label}
    </span>
  );
}
