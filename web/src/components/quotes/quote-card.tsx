"use client";

import { Download, Share2 } from "lucide-react";
import { useRef, useState } from "react";
import { toPng } from "html-to-image";
import { deleteQuote, saveQuote } from "@/app/app/quotes/actions";

type Book = { id: string; title: string };
export function QuoteCard({ quote, books }: { quote: { id: string; book_id: string; text: string; bookTitle: string }; books: Book[] }) {
  const card = useRef<HTMLDivElement>(null);
  const [sharing, setSharing] = useState(false);

  async function share() {
    if (!card.current) return;
    setSharing(true);
    const dataUrl = await toPng(card.current, { pixelRatio: 2, backgroundColor: "#171729", cacheBust: true });
    const blob = await (await fetch(dataUrl)).blob();
    const file = new File([blob], "pageflow-quote.png", { type: "image/png" });
    if (navigator.share && navigator.canShare?.({ files: [file] })) await navigator.share({ title: "A quote from PageFlow", files: [file] }).catch(() => undefined);
    else { const link = document.createElement("a"); link.download = file.name; link.href = dataUrl; link.click(); }
    setSharing(false);
  }

  return <article className="glass-card rounded-2xl p-5"><div className="rounded-2xl bg-gradient-to-br from-[#242044] to-[#151526] p-7" ref={card}><span className="font-display text-5xl leading-none text-accent-light">“</span><blockquote className="font-display text-xl leading-8 sm:text-2xl">{quote.text}</blockquote><p className="mt-5 text-xs uppercase tracking-[.14em] text-accent-light">{quote.bookTitle} · PageFlow</p></div><div className="mt-3 grid grid-cols-2 gap-2"><button className="secondary-button" disabled={sharing} onClick={share}><Share2 size={17} />{sharing ? "Preparing…" : "Share"}</button><button className="secondary-button" disabled={sharing} onClick={share}><Download size={17} />PNG</button></div><details className="mt-3"><summary className="flex min-h-11 cursor-pointer items-center text-sm text-secondary">Edit quote</summary><form action={saveQuote} className="space-y-3"><input name="id" type="hidden" value={quote.id} /><select className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#141424] px-4" defaultValue={quote.book_id} name="bookId">{books.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}</select><textarea className="min-h-28 w-full rounded-xl border border-[var(--border)] bg-black/20 p-4" defaultValue={quote.text} name="text" required /><button className="primary-button w-full">Save quote</button></form><form action={deleteQuote} className="mt-2"><input name="id" type="hidden" value={quote.id} /><button className="flex min-h-11 items-center text-sm text-red-200">Delete quote</button></form></details></article>;
}
