import Link from "next/link";
import { ArrowRight, BookOpen, Flame, Timer } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { createClient } from "@/lib/supabase/server";

export default async function HomePage() {
  const supabase = await createClient();
  const [{ data: books }, { data: stats }] = await Promise.all([
    supabase.from("books").select("id,title,author,current_page,total_pages,status").eq("status", "Currently Reading").order("updated_at", { ascending: false }).limit(3),
    supabase.from("user_stats").select("current_streak,total_xp,total_seconds").maybeSingle(),
  ]);

  return (
    <>
      <PageHeading eyebrow="Your reading day" title="Keep the story moving." description="A calm place for today’s pages, thoughts, and momentum." action={<Link className="primary-button" href="/app/timer"><Timer size={18} />Start reading</Link>} />
      <section className="grid gap-3 sm:grid-cols-3" aria-label="Reading summary">
        <Metric icon={<Flame size={19} />} label="Current streak" value={`${stats?.current_streak ?? 0} days`} />
        <Metric icon={<BookOpen size={19} />} label="Minutes read" value={String(Math.round(Number(stats?.total_seconds ?? 0) / 60))} />
        <Metric label={`Level ${Math.floor((stats?.total_xp ?? 0) / 100) + 1}`} value={`${stats?.total_xp ?? 0} XP`} />
      </section>
      <section className="mt-8">
        <div className="mb-4 flex items-center justify-between"><h2 className="font-display text-2xl">Continue reading</h2><Link className="flex min-h-11 items-center gap-1 text-sm text-accent-light" href="/app/library">Library <ArrowRight size={16} /></Link></div>
        {books?.length ? <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{books.map((book) => <Link className="glass-card rounded-2xl p-5" href={`/app/books/${book.id}`} key={book.id}><p className="font-display text-xl">{book.title}</p><p className="mt-1 text-sm text-secondary">{book.author}</p><div className="mt-5 h-2 overflow-hidden rounded-full bg-black/30"><div className="h-full rounded-full bg-accent" style={{ width: `${Math.round((book.current_page / book.total_pages) * 100)}%` }} /></div><p className="mt-2 text-xs text-muted">Page {book.current_page} of {book.total_pages}</p></Link>)}</div> : <div className="glass-card rounded-2xl p-7 text-center"><p className="font-display text-xl">Your next chapter starts here.</p><p className="mt-2 text-sm text-secondary">Add a book to begin tracking your reading.</p><Link className="secondary-button mt-5" href="/app/library">Add your first book</Link></div>}
      </section>
    </>
  );
}

function Metric({ icon, label, value }: { icon?: React.ReactNode; label: string; value: string }) {
  return <div className="glass-card rounded-2xl p-4"><div className="flex items-center gap-2 text-xs uppercase tracking-[.12em] text-muted">{icon}{label}</div><p className="mt-2 font-display text-2xl">{value}</p></div>;
}
