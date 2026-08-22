import { PageHeading } from "@/components/app/page-heading";
import { Attendance, Figure, FigureBand, Meter, SectionHeading } from "@/components/app/register";
import { dateOffset, localDate } from "@/lib/dates";
import { roman } from "@/lib/format";
import { createClient } from "@/lib/supabase/server";

export default async function StatsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const [{ data: profile }, { data: stats }] = await Promise.all([
    supabase.from("profiles").select("time_zone").eq("id", user!.id).maybeSingle(),
    supabase.from("user_stats").select("total_xp,current_streak,longest_streak,total_sessions,total_seconds").maybeSingle(),
  ]);
  const timeZone = profile?.time_zone || "UTC";
  const today = localDate(timeZone);
  const firstDay = dateOffset(today, -27);
  const monthStart = `${today.slice(0, 7)}-01`;
  const [{ data: sessions }, { data: freezes }] = await Promise.all([
    supabase.from("reading_sessions").select("session_local_date,duration_seconds,mood_tags").gte("session_local_date", firstDay).lte("session_local_date", today),
    supabase.from("streak_freezes").select("id,missed_date").eq("month_start", monthStart),
  ]);

  const daily = new Map<string, number>();
  const moodCounts = new Map<string, number>();
  for (const session of sessions ?? []) {
    daily.set(session.session_local_date, (daily.get(session.session_local_date) ?? 0) + session.duration_seconds);
    for (const mood of session.mood_tags as string[]) moodCounts.set(mood, (moodCounts.get(mood) ?? 0) + 1);
  }
  const days = Array.from({ length: 28 }, (_, index) => {
    const date = dateOffset(firstDay, index);
    return { date, minutes: Math.round((daily.get(date) ?? 0) / 60) };
  });
  const weeklySeconds = days.slice(-7).reduce((sum, day) => sum + day.minutes * 60, 0);
  const moodTotal = [...moodCounts.values()].reduce((sum, value) => sum + value, 0);
  const ranked = [...moodCounts.entries()].sort((a, b) => b[1] - a[1]);

  const totalXp = stats?.total_xp ?? 0;
  const level = Math.floor(totalXp / 100) + 1;
  const levelXp = totalXp % 100;

  return (
    <>
      <PageHeading
        description="Dates are kept in your own time zone, so a streak survives travel and the clocks changing."
        eyebrow="Your momentum"
        title="The record"
      />

      <FigureBand cols={5}>
        <Figure label="Current streak" unit="days" value={stats?.current_streak ?? 0} />
        <Figure label="Longest streak" unit="days" value={stats?.longest_streak ?? 0} />
        <Figure label="Total XP" value={totalXp} />
        <Figure label="Sittings" value={stats?.total_sessions ?? 0} />
        <Figure label="Freezes left" unit="this month" value={Math.max(0, 2 - (freezes?.length ?? 0))} />
      </FigureBand>

      <div className="mt-11 grid gap-12 lg:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)] lg:gap-14">
        <section>
          <SectionHeading note="One square to a day; the darker the ink, the longer the sitting." title="Attendance, last twenty-eight days" />
          <Attendance days={days} />
          <div className="tnum mt-3 flex justify-between text-[10.5px] uppercase tracking-[.12em] text-muted">
            <span>{firstDay}</span>
            <span>{Math.round(weeklySeconds / 60)} min in the last seven</span>
          </div>
        </section>

        <section>
          <SectionHeading title={`Standing — Level ${roman(level)}`} />
          <div className="plate px-6 py-5">
            <div className="tnum flex items-baseline justify-between">
              <span className="font-display text-[30px]">{levelXp} <span className="font-sans text-[15px] text-muted">/ 100 XP</span></span>
              <span className="text-[13px] text-muted">toward Level {roman(level + 1)}</span>
            </div>
            <div className="mt-4"><Meter value={levelXp} /></div>
            <p className="tnum mt-5 border-t border-line-soft pt-4 text-[13.5px] text-secondary">
              {Math.round(Number(stats?.total_seconds ?? 0) / 3600)} hours logged in all
            </p>
          </div>

          <div className="mt-10">
            <SectionHeading note="Every mood you have set against a sitting." title="Moods recorded" />
            {moodTotal ? (
              <div className="flex flex-col">
                {ranked.map(([mood, count]) => (
                  <div className="border-b border-line-soft py-3 last:border-b-0" key={mood}>
                    <div className="tnum mb-2 flex justify-between text-[13.5px]">
                      <span>{mood}</span>
                      <span className="text-muted">{Math.round((count / moodTotal) * 100)}%</span>
                    </div>
                    <Meter thickness={2} value={(count / moodTotal) * 100} />
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted">Set a mood after a sitting and the pattern begins.</p>
            )}
          </div>
        </section>
      </div>
    </>
  );
}
