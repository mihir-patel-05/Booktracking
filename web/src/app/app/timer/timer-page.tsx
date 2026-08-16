"use client";

import { useEffect, useState } from "react";
import { PageHeading } from "@/components/app/page-heading";
import { ReadingTimer } from "@/components/timer/reading-timer";
import { JournalFlow } from "@/components/journal/journal-flow";

type Session = { bookId: string; startedAt: string; durationSeconds: number };

export function TimerPageClient({ books, initialBookId, userId }: { books: Array<{ id: string; title: string; author: string }>; initialBookId?: string; userId: string }) {
  const [finished, setFinished] = useState<Session>();
  useEffect(() => {
    try {
      const saved = localStorage.getItem(`pageflow:journal-draft:${userId}`);
      if (saved) {
        const session = (JSON.parse(saved) as { session?: Session }).session;
        if (session?.bookId && session.startedAt && session.durationSeconds > 0) setFinished(session);
      }
    } catch { localStorage.removeItem(`pageflow:journal-draft:${userId}`); }
  }, [userId]);
  return <><PageHeading eyebrow="Focus mode" title="Reading timer" description="The deadline-based timer recovers accurately after a refresh or background pause." />
    {finished ? <JournalFlow onDiscard={() => setFinished(undefined)} session={finished} userId={userId} /> : <ReadingTimer books={books} initialBookId={initialBookId} onComplete={setFinished} userId={userId} />}
  </>;
}
