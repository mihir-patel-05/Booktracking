export type TimerSnapshot = {
  bookId: string;
  startedAt: string;
  targetEnd: number | null;
  remainingSeconds: number;
  durationSeconds: number;
  running: boolean;
};

export function secondsRemaining(snapshot: TimerSnapshot, now = Date.now()) {
  return snapshot.running && snapshot.targetEnd
    ? Math.max(0, Math.ceil((snapshot.targetEnd - now) / 1000))
    : snapshot.remainingSeconds;
}

export function elapsedSeconds(snapshot: TimerSnapshot, now = Date.now()) {
  return Math.max(1, snapshot.durationSeconds - secondsRemaining(snapshot, now));
}

export function formatClock(seconds: number) {
  const safe = Math.max(0, seconds);
  const hours = Math.floor(safe / 3600);
  const minutes = Math.floor((safe % 3600) / 60);
  const remainder = safe % 60;
  return hours > 0
    ? `${hours}:${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`
    : `${minutes}:${String(remainder).padStart(2, "0")}`;
}
