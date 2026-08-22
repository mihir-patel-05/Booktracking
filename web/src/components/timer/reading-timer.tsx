"use client";

import Image from "next/image";
import Link from "next/link";
import { Pause, Play, Square } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Ledger } from "@/components/app/register";
import { elapsedSeconds, formatClock, secondsRemaining, type TimerSnapshot } from "@/lib/timer";

type Book = { id: string; title: string; author: string };
type CompletedSession = { bookId: string; startedAt: string; durationSeconds: number };

const clock = new Intl.DateTimeFormat("en-GB", { hour: "2-digit", minute: "2-digit" });

export function ReadingTimer({ books, initialBookId, userId, onComplete }: { books: Book[]; initialBookId?: string; userId: string; onComplete?: (session: CompletedSession) => void }) {
  const storageKey = `pageflow:active-timer:${userId}`;
  const [bookId, setBookId] = useState(initialBookId && books.some((book) => book.id === initialBookId) ? initialBookId : books[0]?.id ?? "");
  const [minutes, setMinutes] = useState(25);
  const [snapshot, setSnapshot] = useState<TimerSnapshot | null>(null);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved) as TimerSnapshot;
        if (books.some((book) => book.id === parsed.bookId)) {
          setSnapshot(parsed);
          setBookId(parsed.bookId);
        }
      }
    } catch { localStorage.removeItem(storageKey); }
  }, [books, storageKey]);

  useEffect(() => {
    if (!snapshot) localStorage.removeItem(storageKey);
    else localStorage.setItem(storageKey, JSON.stringify(snapshot));
  }, [snapshot, storageKey]);

  useEffect(() => {
    if (!snapshot?.running) return;
    const tick = window.setInterval(() => setNow(Date.now()), 250);
    return () => window.clearInterval(tick);
  }, [snapshot?.running]);

  const remaining = snapshot ? secondsRemaining(snapshot, now) : minutes * 60;
  const progress = snapshot ? 1 - remaining / snapshot.durationSeconds : 0;

  useEffect(() => {
    if (snapshot?.running && remaining === 0) finish();
    // `finish` intentionally follows the current timer snapshot.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [remaining, snapshot?.running]);

  function start() {
    const durationSeconds = Math.max(60, Math.min(18 * 3600, Math.round(minutes * 60)));
    setNow(Date.now());
    setSnapshot({ bookId, startedAt: new Date().toISOString(), targetEnd: Date.now() + durationSeconds * 1000, remainingSeconds: durationSeconds, durationSeconds, running: true });
  }

  function pause() {
    if (!snapshot) return;
    setSnapshot({ ...snapshot, targetEnd: null, remainingSeconds: secondsRemaining(snapshot), running: false });
  }

  function resume() {
    if (!snapshot) return;
    setNow(Date.now());
    setSnapshot({ ...snapshot, targetEnd: Date.now() + snapshot.remainingSeconds * 1000, running: true });
  }

  function discard() { setSnapshot(null); setNow(Date.now()); }

  function finish() {
    if (!snapshot) return;
    const session = { bookId: snapshot.bookId, startedAt: snapshot.startedAt, durationSeconds: elapsedSeconds(snapshot) };
    setSnapshot(null);
    onComplete?.(session);
  }

  const activeBook = useMemo(() => books.find((book) => book.id === (snapshot?.bookId ?? bookId)), [bookId, books, snapshot?.bookId]);

  if (!books.length) {
    return (
      <div className="plate px-6 py-10 text-center">
        <p className="font-display text-[23px]">Enter a volume before the clock is set.</p>
        <p className="mt-2 text-sm text-muted">A sitting always belongs to one of your books.</p>
        <Link className="btn btn-secondary mt-5" href="/app/library">Go to the Library</Link>
      </div>
    );
  }

  /* Not yet running: the plain setting-out of the sitting, in whatever
     light the reader has chosen. */
  if (!snapshot) {
    return (
      <div className="max-w-[560px]">
        <div className="grid gap-5">
          <label className="block">
            <span className="field-label">Volume</span>
            <select className="input" onChange={(event) => setBookId(event.target.value)} value={bookId}>
              {books.map((book) => <option key={book.id} value={book.id}>{book.title} — {book.author}</option>)}
            </select>
          </label>
          <div>
            <span className="field-label">Length of the sitting</span>
            <div className="grid grid-cols-4 gap-2">
              {[15, 25, 45, 60].map((preset) => (
                <button
                  className={`btn ${minutes === preset ? "btn-primary" : "btn-secondary"}`}
                  key={preset}
                  onClick={() => setMinutes(preset)}
                  type="button"
                >
                  {preset} min
                </button>
              ))}
            </div>
            <label className="mt-3 flex items-center gap-3 text-sm text-muted">
              Or
              <input className="input tnum w-24" max="1080" min="1" onChange={(event) => setMinutes(Number(event.target.value))} type="number" value={minutes} />
              minutes
            </label>
          </div>
          <button className="btn btn-primary btn-block" disabled={!bookId} onClick={start} type="button">
            <Play size={15} strokeWidth={1.5} />Enter the reading room
          </button>
          <p className="text-xs leading-6 text-faint">
            The clock runs to a deadline, so it survives a refresh or a closed lid.
          </p>
        </div>
      </div>
    );
  }

  /* Running: the room goes dark, and takes the whole screen with it. */
  const started = clock.format(new Date(snapshot.startedAt));
  const elapsed = snapshot.durationSeconds - remaining;

  return (
    <div className="night fixed inset-0 z-40 flex flex-col overflow-y-auto bg-background text-foreground">
      <header className="flex items-center justify-between gap-4 border-b border-line px-5 py-5 lg:px-11">
        <div className="flex items-center gap-3.5">
          <Image alt="" className="rounded" height="24" src="/brand/pageflow-logo.svg" width="24" />
          <span className="font-display text-xl">PageFlow</span>
          <span className="hidden h-4 w-px bg-line sm:block" />
          <span className="hidden text-[9.5px] uppercase tracking-[.2em] text-muted sm:block">Reading room</span>
        </div>
        <button className="btn btn-secondary" onClick={discard} type="button">Leave the room</button>
      </header>

      <main className="grid flex-1 lg:grid-cols-[minmax(0,1fr)_400px]">
        <section className="grid place-items-center px-5 py-12 lg:px-14">
          <div className="text-center">
            <p className="eyebrow tracking-[.24em]">Tonight’s sitting</p>
            <p className="mt-3.5 font-display text-[30px] leading-tight">{activeBook?.title}</p>
            <p className="mt-1 text-[13.5px] italic text-muted">{activeBook?.author}</p>

            <div
              className="relative mx-auto mt-11 grid aspect-square w-full max-w-[396px] place-items-center rounded-full"
              style={{ background: `conic-gradient(var(--gold) ${progress * 360}deg, var(--border) 0)` }}
            >
              <div className="absolute inset-[2px] rounded-full bg-background" />
              <div className="absolute inset-5 rounded-full border border-line" />
              <div className="relative text-center">
                <p aria-live="polite" className="tnum font-display text-[64px] leading-none tracking-[-.02em] sm:text-[88px]">{formatClock(remaining)}</p>
                <p className="mt-3.5 text-[10px] uppercase tracking-[.22em] text-muted">
                  {snapshot.running ? `remaining of ${Math.round(snapshot.durationSeconds / 60)} min` : "paused"}
                </p>
                <span className="mx-auto mt-4 block h-px w-7 bg-gold" />
              </div>
            </div>

            <div className="mt-11 flex flex-wrap justify-center gap-3.5">
              <button className="btn btn-secondary" onClick={snapshot.running ? pause : resume} type="button">
                {snapshot.running ? <><Pause size={15} strokeWidth={1.5} />Pause</> : <><Play size={15} strokeWidth={1.5} />Resume</>}
              </button>
              <button className="btn btn-primary" onClick={finish} type="button"><Square size={14} strokeWidth={1.5} />End and record</button>
              <button className="btn text-muted" onClick={discard} type="button">Discard</button>
            </div>
            <p className="mt-6 text-xs text-faint">The clock runs to a deadline, so it survives a refresh or a closed lid.</p>
          </div>
        </section>

        <aside className="flex flex-col gap-8 border-t border-line px-5 py-10 lg:border-l lg:border-t-0 lg:px-9 lg:py-11">
          <div>
            <p className="eyebrow eyebrow-muted mb-3.5">This sitting</p>
            <Ledger
              rows={[
                { label: "Elapsed", value: formatClock(elapsed) },
                { label: "Started", value: started },
                { label: "Length set", value: `${Math.round(snapshot.durationSeconds / 60)} min` },
              ]}
            />
          </div>
          <div className="border-t border-line pt-6">
            <p className="eyebrow eyebrow-muted mb-3">When the bell rings</p>
            <p className="text-[12.5px] leading-7 text-muted">
              You’ll be asked for the mood of the sitting, a thought worth keeping, and any line you want copied out.
            </p>
          </div>
        </aside>
      </main>
    </div>
  );
}
