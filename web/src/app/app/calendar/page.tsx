import Link from "next/link";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { Figure, FigureBand } from "@/components/app/register";
import { ReadingDiary, type DiaryDay, type PlannableBook } from "@/components/calendar/reading-diary";
import { localDate } from "@/lib/dates";
import { monthGrid, monthLabel, resolveMonth, shiftMonth } from "@/lib/plan";
import { createClient } from "@/lib/supabase/server";

export default async function CalendarPage({ searchParams }: { searchParams: Promise<{ month?: string }> }) {
  const [{ month }, supabase] = await Promise.all([searchParams, createClient()]);
  const { data: { user } } = await supabase.auth.getUser();

  const { data: profile } = await supabase.from("profiles").select("time_zone").eq("id", user!.id).maybeSingle();
  const today = localDate(profile?.time_zone || "UTC");
  const monthStart = resolveMonth(month, today);

  const grid = monthGrid(monthStart);
  const from = grid[0]!.date;
  const to = grid.at(-1)!.date;

  const [{ data: plans }, { data: sessions }, { data: books }] = await Promise.all([
    supabase
      .from("reading_plans")
      .select("id,book_id,planned_date,target_minutes,target_pages,note,books(title,author)")
      .gte("planned_date", from)
      .lte("planned_date", to)
      .order("created_at", { ascending: true }),
    supabase
      .from("reading_sessions")
      .select("book_id,session_local_date,duration_seconds")
      .gte("session_local_date", from)
      .lte("session_local_date", to),
    supabase
      .from("books")
      .select("id,title,author,current_page,total_pages,status")
      .in("status", ["Currently Reading", "Want to Read"])
      .order("status", { ascending: true })
      .order("updated_at", { ascending: false }),
  ]);

  const minutesByDay = new Map<string, number>();
  const attended = new Set<string>();
  for (const session of sessions ?? []) {
    minutesByDay.set(session.session_local_date, (minutesByDay.get(session.session_local_date) ?? 0) + session.duration_seconds / 60);
    attended.add(`${session.session_local_date}:${session.book_id}`);
  }

  const days: DiaryDay[] = grid.map(({ date, outside }) => ({
    date,
    outside,
    minutes: Math.round(minutesByDay.get(date) ?? 0),
    plans: (plans ?? [])
      .filter((plan) => plan.planned_date === date)
      .map((plan) => ({
        id: plan.id,
        bookId: plan.book_id,
        title: plan.books?.title ?? "Untitled",
        author: plan.books?.author ?? "",
        targetMinutes: plan.target_minutes,
        targetPages: plan.target_pages,
        note: plan.note,
        kept: attended.has(`${date}:${plan.book_id}`),
      })),
  }));

  const withinMonth = days.filter((day) => !day.outside);
  const plannedSittings = withinMonth.reduce((total, day) => total + day.plans.length, 0);
  const keptSittings = withinMonth.reduce((total, day) => total + day.plans.filter((plan) => plan.kept).length, 0);
  const daysPlanned = withinMonth.filter((day) => day.plans.length).length;
  const minutesRead = withinMonth.reduce((total, day) => total + day.minutes, 0);
  const shelf: PlannableBook[] = (books ?? []).map((book) => ({
    id: book.id, title: book.title, author: book.author,
    currentPage: book.current_page, totalPages: book.total_pages, status: book.status,
  }));

  const previous = shiftMonth(monthStart, -1).slice(0, 7);
  const next = shiftMonth(monthStart, 1).slice(0, 7);

  return (
    <>
      <PageHeading
        action={
          <div className="flex items-center gap-2">
            <Link aria-label={`Go to ${monthLabel(shiftMonth(monthStart, -1))}`} className="btn btn-icon btn-secondary" href={`/app/calendar?month=${previous}`}>
              <ChevronLeft size={16} strokeWidth={1.5} />
            </Link>
            <Link className="btn btn-secondary" href="/app/calendar">This month</Link>
            <Link aria-label={`Go to ${monthLabel(shiftMonth(monthStart, 1))}`} className="btn btn-icon btn-secondary" href={`/app/calendar?month=${next}`}>
              <ChevronRight size={16} strokeWidth={1.5} />
            </Link>
          </div>
        }
        description="Lay out the sittings ahead. A day is kept when a session for that volume is recorded against it."
        eyebrow="The reading diary"
        title={monthLabel(monthStart)}
      />

      <FigureBand cols={4}>
        <Figure label="Sittings planned" value={plannedSittings} />
        <Figure label="Sittings kept" value={keptSittings} />
        <Figure label="Days appointed" unit={`of ${withinMonth.length}`} value={daysPlanned} />
        <Figure label="Read this month" unit="min" value={minutesRead} />
      </FigureBand>

      <ReadingDiary books={shelf} days={days} monthStart={monthStart} today={today} />
    </>
  );
}
