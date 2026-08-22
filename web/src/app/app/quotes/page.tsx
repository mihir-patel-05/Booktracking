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
  let quotes = needle ? rawQuotes?.filter((quote) => `${quote.text} ${quote.books?.title ?? ""}`.toLocaleLowerCase().includes(needle)) : rawQuotes;
  if (filters.random && quotes?.length) quotes = [quotes[Math.floor(Math.random() * quotes.length)]];

  return (
    <>
      <PageHeading
        action={
          <>
            <a className="btn btn-secondary" href="/app/quotes?random=1"><Shuffle size={15} strokeWidth={1.5} />Draw one at random</a>
            <a className="btn btn-primary" href="#copy-out">Copy out a line</a>
          </>
        }
        eyebrow="Words worth keeping"
        title="Quotes"
      />

      <form className="flex items-center gap-3 border-y border-line py-3.5" method="get">
        <input aria-label="Search lines or volumes" className="input flex-1" defaultValue={filters.q} name="q" placeholder="Search lines or volumes" />
        <button className="btn btn-secondary" type="submit">Search</button>
      </form>

      <details className="plate mb-9 mt-8 px-5 py-4" id="copy-out">
        <summary className="cursor-pointer font-display text-[20px] text-gold-text">Copy out a line</summary>
        <form action={saveQuote} className="mt-5 grid gap-4">
          <label className="block">
            <span className="field-label">Volume</span>
            <select className="input" defaultValue="" name="bookId" required>
              <option disabled value="">Choose a volume</option>
              {books?.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="field-label">The line</span>
            <textarea className="input" name="text" placeholder="The line you want to remember…" required />
          </label>
          <button className="btn btn-primary btn-block" type="submit">Keep this line</button>
        </form>
      </details>

      {quotes?.length ? (
        <div className="grid gap-8 lg:grid-cols-2">
          {quotes.map((quote) => (
            <QuoteCard books={books ?? []} key={quote.id} quote={{ id: quote.id, book_id: quote.book_id, text: quote.text, bookTitle: quote.books?.title ?? "Unattributed" }} />
          ))}
        </div>
      ) : (
        <p className="mt-10 text-center text-sm text-muted">No lines match this view.</p>
      )}
    </>
  );
}
