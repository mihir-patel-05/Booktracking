"use client";

import { Pause, Play, RotateCcw, Square } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { elapsedSeconds, formatClock, secondsRemaining, type TimerSnapshot } from "@/lib/timer";

type Book = { id: string; title: string; author: string };
type CompletedSession = { bookId: string; startedAt: string; durationSeconds: number };

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

  function reset() { setSnapshot(null); setNow(Date.now()); }

  function finish() {
    if (!snapshot) return;
    const session = { bookId: snapshot.bookId, startedAt: snapshot.startedAt, durationSeconds: elapsedSeconds(snapshot) };
    setSnapshot(null);
    onComplete?.(session);
  }

  const activeBook = useMemo(() => books.find((book) => book.id === (snapshot?.bookId ?? bookId)), [bookId, books, snapshot?.bookId]);

  if (!books.length) return <div className="glass-card rounded-2xl p-8 text-center"><p className="font-display text-xl">Add a book before starting a timer.</p><p className="mt-2 text-sm text-secondary">A reading session always belongs to one of your books.</p></div>;

  return <div className="mx-auto max-w-2xl">
    <div className="glass-card rounded-3xl p-5 text-center sm:p-8">
      <p className="text-xs font-bold uppercase tracking-[.16em] text-accent-light">{snapshot ? activeBook?.title : "Plan a focused session"}</p>
      <div className="relative mx-auto my-7 grid aspect-square max-w-[280px] place-items-center rounded-full" style={{ background: `conic-gradient(var(--accent-light) ${progress * 360}deg, rgba(255,255,255,.07) 0)` }}><div className="grid size-[calc(100%-12px)] place-items-center rounded-full bg-[#171729]"><div><p aria-live="polite" className="font-display text-6xl tabular-nums">{formatClock(remaining)}</p><p className="mt-2 text-sm text-muted">{snapshot?.running ? "Reading now" : snapshot ? "Paused" : "Ready when you are"}</p></div></div></div>
      {!snapshot ? <div className="space-y-5 text-left">
        <label><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">Book</span><select className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-[#141424] px-4" onChange={(event) => setBookId(event.target.value)} value={bookId}>{books.map((book) => <option key={book.id} value={book.id}>{book.title} — {book.author}</option>)}</select></label>
        <div><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">Duration</span><div className="grid grid-cols-4 gap-2">{[15, 25, 45, 60].map((preset) => <button className={`min-h-11 rounded-xl border text-sm ${minutes === preset ? "border-accent bg-accent/15 text-accent-light" : "border-[var(--border)] text-secondary"}`} key={preset} onClick={() => setMinutes(preset)} type="button">{preset}m</button>)}</div><label className="mt-3 flex items-center gap-3 text-sm text-secondary">Custom <input className="min-h-11 min-w-0 flex-1 rounded-xl border border-[var(--border)] bg-black/20 px-3 text-white" max="1080" min="1" onChange={(event) => setMinutes(Number(event.target.value))} type="number" value={minutes} /> minutes</label></div>
        <button className="primary-button w-full" disabled={!bookId} onClick={start} type="button"><Play fill="currentColor" size={18} />Start timer</button>
      </div> : <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        <button className="secondary-button" onClick={snapshot.running ? pause : resume} type="button">{snapshot.running ? <><Pause size={18} />Pause</> : <><Play size={18} />Resume</>}</button>
        <button className="primary-button" onClick={finish} type="button"><Square size={17} />Finish now</button>
        <button className="secondary-button col-span-2 sm:col-span-1" onClick={reset} type="button"><RotateCcw size={17} />Cancel</button>
      </div>}
    </div>
  </div>;
}
