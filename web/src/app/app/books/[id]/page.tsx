import Link from "next/link";
import { notFound } from "next/navigation";
import { Clock, Timer } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { ProgressForm } from "@/components/books/progress-form";
import { createClient } from "@/lib/supabase/server";

export default async function BookPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const [{ data: book }, { data: sessions }] = await Promise.all([
    supabase.from("books").select("id,title,author,current_page,total_pages,status").eq("id", id).maybeSingle(),
    supabase.from("reading_sessions").select("id,started_at,duration_seconds,xp_earned").eq("book_id", id).order("started_at", { ascending: false }).limit(8),
  ]);
  if (!book) notFound();
  const percentage = Math.round((book.current_page / book.total_pages) * 100);

  return <><PageHeading eyebrow={book.status} title={book.title} description={`${book.author} · ${percentage}% complete`} action={<Link className="primary-button" href={`/app/timer?book=${book.id}`}><Timer size={18} />Read now</Link>} />
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(300px,.72fr)]">
      <section><div className="mb-5 h-3 overflow-hidden rounded-full bg-white/8"><div className="h-full rounded-full bg-gradient-to-r from-accent to-fuchsia-500" style={{ width: `${percentage}%` }} /></div><ProgressForm book={book} /></section>
      <section className="glass-card rounded-2xl p-5"><h2 className="font-display text-xl">Recent sessions</h2>{sessions?.length ? <ul className="mt-3 divide-y divide-[var(--border)]">{sessions.map((session) => <li className="flex min-h-14 items-center justify-between gap-3 py-3" key={session.id}><div><p className="text-sm">{new Intl.DateTimeFormat("en", { dateStyle: "medium" }).format(new Date(session.started_at))}</p><p className="mt-1 flex items-center gap-1 text-xs text-muted"><Clock size={13} />{Math.round(session.duration_seconds / 60)} min</p></div><span className="text-sm text-accent-light">+{session.xp_earned} XP</span></li>)}</ul> : <p className="mt-4 text-sm text-secondary">No reading sessions yet.</p>}</section>
    </div>
  </>;
}
