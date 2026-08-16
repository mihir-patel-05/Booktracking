"use client";

import { useState } from "react";
import { PageHeading } from "@/components/app/page-heading";
import { ReadingTimer } from "@/components/timer/reading-timer";

type Session = { bookId: string; startedAt: string; durationSeconds: number };

export function TimerPageClient({ books, initialBookId, userId }: { books: Array<{ id: string; title: string; author: string }>; initialBookId?: string; userId: string }) {
  const [finished, setFinished] = useState<Session>();
  return <><PageHeading eyebrow="Focus mode" title="Reading timer" description="The deadline-based timer recovers accurately after a refresh or background pause." />
    {finished ? <div className="glass-card mx-auto max-w-2xl rounded-2xl p-7 text-center"><p className="font-display text-2xl">Session complete.</p><p className="mt-2 text-secondary">You read for {Math.max(1, Math.round(finished.durationSeconds / 60))} minutes. Journal prompts are coming next.</p><button className="secondary-button mt-5" onClick={() => setFinished(undefined)}>Start another</button></div> : <ReadingTimer books={books} initialBookId={initialBookId} onComplete={setFinished} userId={userId} />}
  </>;
}
