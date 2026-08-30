import Link from "next/link";
import { Archive, RotateCcw, X } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { Meter } from "@/components/app/register";
import { GoalComposer, GoalEditForm } from "@/components/goals/goal-forms";
import { localDate } from "@/lib/dates";
import { goalAvailability, goalPercent, goalProgress, goalWindow } from "@/lib/goals";
import { createClient } from "@/lib/supabase/server";
import { addBookToGoal, removeBookFromGoal, setGoalArchived } from "./actions";

const dateLabel = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });
function labelDate(date: string) { return dateLabel.format(new Date(`${date}T12:00:00Z`)); }

export default async function GoalsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const [{ data: profile }, { data: goals }, { data: memberships }, { data: completedBooks }] = await Promise.all([
    supabase.from("profiles").select("time_zone").eq("id", user!.id).maybeSingle(),
    supabase.from("reading_goals").select("id,name,target_books,cadence,starts_on,ends_on,archived_at").order("created_at", { ascending: false }),
    supabase.from("reading_goal_books").select("goal_id,book_id,completed_on,books(id,title,author)").order("completed_on", { ascending: false }),
    supabase.from("books").select("id,title,author,date_completed").eq("status", "Completed").not("date_completed", "is", null).order("date_completed", { ascending: false }),
  ]);
  const today = localDate(profile?.time_zone || "UTC");
  const active = (goals ?? []).filter((goal) => !goal.archived_at);
  const archived = (goals ?? []).filter((goal) => goal.archived_at);

  return (
    <>
      <PageHeading
        description="Choose the measure and the dates. A finished volume only counts when you enter it against the goal."
        eyebrow="Your intentions"
        title="Reading goals"
      />

      <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_336px] lg:gap-14">
        <section>
          {active.length ? (
            <div className="grid gap-5">
              {active.map((goal) => (
                <GoalCard completedBooks={completedBooks ?? []} goal={goal} memberships={memberships ?? []} key={goal.id} today={today} />
              ))}
            </div>
          ) : (
            <div className="plate px-6 py-10 text-center">
              <p className="font-display text-[24px]">Give the next shelf a horizon.</p>
              <p className="mt-2 text-sm text-muted">Set an annual finish line or a monthly rhythm.</p>
            </div>
          )}

          {archived.length ? (
            <details className="mt-9 border-t border-line pt-5">
              <summary className="cursor-pointer text-xs text-muted">Archived goals · {archived.length}</summary>
              <div className="mt-3 divide-y divide-line-soft">
                {archived.map((goal) => (
                  <div className="flex items-center justify-between gap-4 py-3" key={goal.id}>
                    <div>
                      <p className="font-display text-[18px]">{goal.name}</p>
                      <p className="tnum text-xs text-muted">{goal.target_books} {goal.target_books === 1 ? "book" : "books"}</p>
                    </div>
                    <form action={setGoalArchived}>
                      <input name="id" type="hidden" value={goal.id} />
                      <input name="archived" type="hidden" value="false" />
                      <button className="btn btn-ghost text-xs" type="submit"><RotateCcw size={13} strokeWidth={1.5} />Restore</button>
                    </form>
                  </div>
                ))}
              </div>
            </details>
          ) : null}
        </section>

        <aside className="lg:sticky lg:top-24 lg:self-start">
          <GoalComposer today={today} />
          <p className="mt-4 text-[11.5px] leading-relaxed text-muted">
            When you finish a book, choose one or more goals on its page. You can also enter earlier finished books here.
          </p>
        </aside>
      </div>
    </>
  );
}

type Goal = {
  archived_at: string | null;
  cadence: string;
  ends_on: string | null;
  id: string;
  name: string;
  starts_on: string;
  target_books: number;
};
type Membership = { goal_id: string; book_id: string; completed_on: string; books: { id: string; title: string; author: string } | null };
type CompletedBook = { id: string; title: string; author: string; date_completed: string | null };

function GoalCard({ goal, memberships, completedBooks, today }: { goal: Goal; memberships: Membership[]; completedBooks: CompletedBook[]; today: string }) {
  const allEntries = memberships.filter((entry) => entry.goal_id === goal.id);
  const window = goalWindow(goal, today);
  const progress = goalProgress(allEntries.map((entry) => entry.completed_on), window);
  const availability = goalAvailability(goal, today);
  const linked = new Set(allEntries.map((entry) => entry.book_id));
  const available = completedBooks.filter((book) => !linked.has(book.id));
  const period = goal.cadence === "monthly"
    ? `${labelDate(window.startsOn)} — ${labelDate(window.endsOn)}`
    : `${labelDate(goal.starts_on)} — ${labelDate(goal.ends_on!)}`;
  const relevant = allEntries.filter((entry) => entry.completed_on >= window.startsOn && entry.completed_on <= window.endsOn);

  return (
    <article className="plate px-5 py-5 sm:px-6">
      <div className="flex items-start justify-between gap-5">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <p className="eyebrow">{goal.cadence === "monthly" ? "Every month" : "One finish line"}</p>
            {availability !== "active" ? <span className="tag tag-neutral">{availability === "upcoming" ? "Upcoming" : "Ended"}</span> : null}
            {progress >= goal.target_books ? <span className="tag tag-accent">Reached</span> : null}
          </div>
          <h2 className="mt-2 font-display text-[27px] leading-tight">{goal.name}</h2>
          <p className="tnum mt-1 text-[12px] text-muted">{period}</p>
        </div>
        <form action={setGoalArchived}>
          <input name="id" type="hidden" value={goal.id} />
          <input name="archived" type="hidden" value="true" />
          <button aria-label={`Archive ${goal.name}`} className="btn btn-ghost text-muted" type="submit"><Archive size={15} strokeWidth={1.5} /></button>
        </form>
      </div>

      <div className="mt-5">
        <div className="tnum mb-2 flex items-baseline justify-between">
          <span className="font-display text-[30px]">{progress} <span className="font-sans text-[14px] text-muted">of {goal.target_books}</span></span>
          <span className="text-xs text-muted">{Math.max(0, goal.target_books - progress)} to go</span>
        </div>
        <Meter value={goalPercent(progress, goal.target_books)} />
      </div>

      {relevant.length ? (
        <div className="mt-5 border-t border-line-soft">
          {relevant.map((entry) => (
            <div className="flex items-center justify-between gap-3 border-b border-line-soft py-2.5 last:border-b-0" key={entry.book_id}>
              <div className="min-w-0">
                <Link className="block truncate font-display text-[17px]" href={`/app/books/${entry.book_id}`}>{entry.books?.title ?? "Finished volume"}</Link>
                <p className="tnum text-[11px] text-muted">{labelDate(entry.completed_on)}</p>
              </div>
              <form action={removeBookFromGoal}>
                <input name="goalId" type="hidden" value={goal.id} />
                <input name="bookId" type="hidden" value={entry.book_id} />
                <button aria-label={`Remove ${entry.books?.title ?? "book"} from ${goal.name}`} className="btn btn-ghost text-muted" type="submit"><X size={14} strokeWidth={1.5} /></button>
              </form>
            </div>
          ))}
        </div>
      ) : (
        <p className="mt-4 text-sm text-muted">No finished volumes entered in this measuring period.</p>
      )}

      {available.length ? (
        <form action={addBookToGoal} className="mt-5 flex flex-col gap-2 border-t border-line-soft pt-4 sm:flex-row">
          <input name="goalId" type="hidden" value={goal.id} />
          <select aria-label={`Add a finished book to ${goal.name}`} className="input min-w-0 flex-1" name="bookId" required>
            {available.map((book) => <option key={book.id} value={book.id}>{book.title} — {book.author}</option>)}
          </select>
          <button className="btn btn-secondary shrink-0" type="submit">Enter a finished book</button>
        </form>
      ) : null}

      <GoalEditForm goal={{ id: goal.id, name: goal.name, targetBooks: goal.target_books, cadence: goal.cadence, startsOn: goal.starts_on, endsOn: goal.ends_on }} />
    </article>
  );
}
