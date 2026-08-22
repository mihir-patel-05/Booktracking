"use client";

import { useRef, useState } from "react";
import { toPng } from "html-to-image";
import { deleteQuote, saveQuote } from "@/app/app/quotes/actions";

type Book = { id: string; title: string };

export function QuoteCard({ quote, books }: { quote: { id: string; book_id: string; text: string; bookTitle: string }; books: Book[] }) {
  const plate = useRef<HTMLDivElement>(null);
  const [making, setMaking] = useState(false);

  /** "Make a plate": the line rendered out as an image worth keeping. */
  async function makePlate() {
    if (!plate.current) return;
    setMaking(true);
    const ground = getComputedStyle(document.documentElement).getPropertyValue("--panel").trim() || "#f8f4f4";
    const dataUrl = await toPng(plate.current, { pixelRatio: 2, backgroundColor: ground, cacheBust: true });
    const blob = await (await fetch(dataUrl)).blob();
    const file = new File([blob], "pageflow-quote.png", { type: "image/png" });
    if (navigator.share && navigator.canShare?.({ files: [file] })) await navigator.share({ title: "A line from PageFlow", files: [file] }).catch(() => undefined);
    else { const link = document.createElement("a"); link.download = file.name; link.href = dataUrl; link.click(); }
    setMaking(false);
  }

  return (
    <figure className="plate m-0">
      <div className="plate-filled border-b border-line px-8 py-10 sm:px-10 sm:py-11" ref={plate}>
        <span aria-hidden className="block h-6 font-display text-[56px] leading-[.4] text-gold">“</span>
        <blockquote className="m-0 font-display text-[24px] leading-[1.36] tracking-[-.01em] sm:text-[29px]">{quote.text}</blockquote>
      </div>

      <figcaption className="flex flex-wrap items-center justify-between gap-3 px-6 py-4 text-xs text-muted">
        <span>{quote.bookTitle}</span>
        <span className="flex gap-4">
          <button className="text-gold-text disabled:opacity-45" disabled={making} onClick={makePlate} type="button">
            {making ? "Setting…" : "Make a plate"}
          </button>
        </span>
      </figcaption>

      <details className="border-t border-line px-6 pb-5 pt-4">
        <summary className="cursor-pointer text-xs text-gold-text">Revise</summary>
        <form action={saveQuote} className="mt-4 grid gap-4">
          <input name="id" type="hidden" value={quote.id} />
          <label className="block">
            <span className="field-label">Volume</span>
            <select className="input" defaultValue={quote.book_id} name="bookId">
              {books.map((book) => <option key={book.id} value={book.id}>{book.title}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="field-label">The line</span>
            <textarea className="input" defaultValue={quote.text} name="text" required />
          </label>
          <button className="btn btn-primary btn-block" type="submit">Save the revision</button>
        </form>
        <form action={deleteQuote} className="mt-3">
          <input name="id" type="hidden" value={quote.id} />
          <button className="btn btn-ghost text-[var(--danger)]" type="submit">Strike this line out</button>
        </form>
      </details>
    </figure>
  );
}
