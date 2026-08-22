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
  if (finished) return <JournalFlow onDiscard={() => setFinished(undefined)} session={finished} userId={userId} />;

  return <>
    <PageHeading description="Set the volume and the length; the clock runs to a deadline, so it survives a refresh or a closed lid." eyebrow="The reading room" title="Set the clock" />
    <ReadingTimer books={books} initialBookId={initialBookId} onComplete={setFinished} userId={userId} />
  </>;
}
