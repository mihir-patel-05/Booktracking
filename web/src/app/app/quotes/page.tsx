import { Shuffle } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { QuoteCard } from "@/components/quotes/quote-card";
import { createClient } from "@/lib/supabase/server";
import { saveQuote } from "./actions";

export default async function QuotesPage({ searchParams }: { searchParams: Promise<{ q?: string; random?: string }> }) {
  const filters = await searchParams;
  const supabase = await createClient();
  const [{ data: rawQuotes }, { data: books }] = await Promise.all([
    supabase.from("quotes").select("id,book_id,text,created_at,books(title)").order("updated_at", { ascending: false }).limit(250),
    supabase.from("books").select("id,title").order("title"),
  ]);
  const needle = filters.q?.trim().toLocaleLowerCase();
  let quotes = needle ? rawQuotes?.filter((quote) => `${quote.text} ${quote.books?.[0]?.title ?? ""}`.toLocaleLowerCase().includes(needle)) : rawQuotes;
  if (filters.random && quotes?.length) quotes = [quotes[Math.floor(Math.random() * quotes.length)]];

  return <><PageHeading eyebrow="Words worth keeping" title="Quotes" description="Collect favorite lines and turn any quote into a shareable image." />
    <form className="glass-card mb-5 flex gap-3 rounded-2xl p-4" method="get"><input aria-label="Search quotes" className="min-h-12 min-w-0 flex-1 rounded-xl border border-[var(--border)] bg-black/20 px-4" defaultValue={filters.q} name="q" placeholder="Search quotes or books" /><button className="secondary-button px-4">Search</button><button aria-label="Random quote" className="secondary-button px-4" name="random" value="1"><Shuffle size={18} /></button></form>
    <details className="glass-card mb-6 rounded-2xl p-5"><summary className="min-h-11 cursor-pointer font-semibold text-accent-light">Add a quote</summary><form action={saveQuote} className="mt-4 space-y-4"><select className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#141424] px-4" defaultValue="" name="bookId" required><option disabled value="">Choose a book</option>{books?.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}</select><textarea className="min-h-32 w-full rounded-xl border border-[var(--border)] bg-black/20 p-4" name="text" placeholder="The line you want to remember…" required /><button className="primary-button w-full">Save quote</button></form></details>
    {quotes?.length ? <div className="grid gap-5 lg:grid-cols-2">{quotes.map((quote) => <QuoteCard books={books ?? []} key={quote.id} quote={{ id: quote.id, book_id: quote.book_id, text: quote.text, bookTitle: quote.books?.[0]?.title ?? "Unknown book" }} />)}</div> : <div className="glass-card rounded-2xl p-8 text-center text-secondary">No quotes match this view.</div>}
  </>;
}
