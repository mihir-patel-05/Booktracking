import { describe, expect, it } from "vitest";
import { elapsedSeconds, formatClock, secondsRemaining, type TimerSnapshot } from "./timer";

const snapshot: TimerSnapshot = {
  bookId: "8f5808f8-d474-4af2-9d41-8a239dbf9f51",
  startedAt: "2026-08-16T12:00:00.000Z",
  targetEnd: 1_600_000,
  remainingSeconds: 900,
  durationSeconds: 1500,
  running: true,
};

describe("deadline reading timer", () => {
  it("recovers the remaining time from its absolute deadline", () => {
    expect(secondsRemaining(snapshot, 1_000_000)).toBe(600);
  });

  it("uses the frozen value while paused", () => {
    expect(secondsRemaining({ ...snapshot, running: false, targetEnd: null }, 9_000_000)).toBe(900);
  });

  it("never records a zero-second early completion", () => {
    expect(elapsedSeconds(snapshot, 100_000)).toBe(1);
  });

  it("formats short and long durations for the timer display", () => {
    expect(formatClock(65)).toBe("1:05");
    expect(formatClock(3661)).toBe("1:01:01");
  });
});
