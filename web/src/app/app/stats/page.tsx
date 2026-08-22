import { Flame, Snowflake, Sparkles, Trophy } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { dateOffset, localDate } from "@/lib/dates";
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
  const daily = new Map<string, number>(); const moodCounts = new Map<string, number>();
  for (const session of sessions ?? []) { daily.set(session.session_local_date, (daily.get(session.session_local_date) ?? 0) + session.duration_seconds); for (const mood of session.mood_tags as string[]) moodCounts.set(mood, (moodCounts.get(mood) ?? 0) + 1); }
  const days = Array.from({ length: 28 }, (_, index) => dateOffset(firstDay, index));
  const weeklySeconds = days.slice(-7).reduce((sum, date) => sum + (daily.get(date) ?? 0), 0);
  const moodTotal = [...moodCounts.values()].reduce((sum, value) => sum + value, 0);
  const totalXp = stats?.total_xp ?? 0; const level = Math.floor(totalXp / 100) + 1; const levelXp = totalXp % 100;

  return <><PageHeading eyebrow="Your momentum" title="Reading stats" description={`Dates follow ${timeZone}, so streaks stay deterministic through travel and daylight-saving changes.`} />
    <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4"><Metric icon={<Flame />} label="Current streak" value={`${stats?.current_streak ?? 0} days`} /><Metric icon={<Trophy />} label="Longest streak" value={`${stats?.longest_streak ?? 0} days`} /><Metric icon={<Sparkles />} label="Total XP" value={String(totalXp)} /><Metric icon={<Snowflake />} label="Freezes left" value={`${Math.max(0, 2 - (freezes?.length ?? 0))} this month`} /></section>
    <div className="mt-6 grid gap-6 xl:grid-cols-2"><section className="glass-card rounded-2xl p-5"><div className="flex items-end justify-between"><div><p className="text-xs uppercase tracking-[.12em] text-muted">Level {level}</p><h2 className="font-display text-2xl">{levelXp} / 100 XP</h2></div><p className="text-sm text-secondary">{stats?.total_sessions ?? 0} sessions</p></div><div className="mt-4 h-3 overflow-hidden rounded-full bg-black/30"><div className="h-full rounded-full bg-gradient-to-r from-accent to-fuchsia-500" style={{ width: `${levelXp}%` }} /></div><div className="mt-6 grid grid-cols-2 gap-3"><Mini label="Last 7 days" value={`${Math.round(weeklySeconds / 60)} min`} /><Mini label="All time" value={`${Math.round(Number(stats?.total_seconds ?? 0) / 3600)} hr`} /></div></section>
      <section className="glass-card rounded-2xl p-5"><h2 className="font-display text-2xl">Mood distribution</h2>{moodTotal ? <div className="mt-4 space-y-3">{[...moodCounts.entries()].sort((a,b) => b[1]-a[1]).map(([mood,count]) => <div key={mood}><div className="flex justify-between text-sm"><span>{mood}</span><span className="text-muted">{Math.round(count/moodTotal*100)}%</span></div><div className="mt-1 h-2 rounded-full bg-black/30"><div className="h-full rounded-full bg-accent-light" style={{ width: `${count/moodTotal*100}%` }} /></div></div>)}</div> : <p className="mt-4 text-sm text-secondary">Add moods after reading to reveal your pattern.</p>}</section></div>
    <section className="glass-card mt-6 rounded-2xl p-5"><div className="mb-4 flex items-end justify-between"><div><p className="text-xs uppercase tracking-[.12em] text-muted">Last 28 days</p><h2 className="font-display text-2xl">Reading heatmap</h2></div><p className="text-xs text-muted">darker = longer</p></div><div className="grid grid-cols-7 gap-2">{days.map((date) => { const minutes = Math.round((daily.get(date) ?? 0)/60); const intensity = minutes === 0 ? 0 : Math.min(4, Math.ceil(minutes/15)); return <div aria-label={`${date}: ${minutes} minutes`} className={`aspect-square rounded-md border border-white/5 ${["bg-white/5","bg-violet-950","bg-violet-800","bg-violet-600","bg-violet-400"][intensity]}`} key={date} title={`${date}: ${minutes} min`} />; })}</div></section>
  </>;
}
function Metric({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) { return <div className="glass-card rounded-2xl p-4"><span className="text-accent-light">{icon}</span><p className="mt-4 text-xs uppercase tracking-[.12em] text-muted">{label}</p><p className="mt-1 font-display text-2xl">{value}</p></div>; }
function Mini({ label, value }: { label: string; value: string }) { return <div className="rounded-xl bg-black/20 p-3"><p className="text-xs text-muted">{label}</p><p className="mt-1 font-semibold">{value}</p></div>; }
