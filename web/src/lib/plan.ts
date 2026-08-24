import { dateOffset } from "./dates";

/** The diary is ruled Monday first, as a week is read. */
export const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] as const;

const MONTH_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;

function noon(date: string) {
  return new Date(`${date}T12:00:00Z`);
}

/** The first of the month a date falls in: 2026-08-24 → 2026-08-01. */
export function monthStartOf(date: string) {
  return `${date.slice(0, 7)}-01`;
}

/** A month given in the query string, or the reader's own month. */
export function resolveMonth(requested: string | undefined, today: string) {
  return MONTH_PATTERN.test(requested ?? "") ? `${requested}-01` : monthStartOf(today);
}

/** Step whole months without ever landing on a shorter month's missing day. */
export function shiftMonth(monthStart: string, months: number) {
  const value = noon(monthStart);
  value.setUTCMonth(value.getUTCMonth() + months, 1);
  return value.toISOString().slice(0, 10);
}

export function daysInMonth(monthStart: string) {
  return Number(dateOffset(shiftMonth(monthStart, 1), -1).slice(-2));
}

export function monthLabel(monthStart: string, options: Intl.DateTimeFormatOptions = { month: "long", year: "numeric" }) {
  return new Intl.DateTimeFormat("en-GB", { ...options, timeZone: "UTC" }).format(noon(monthStart));
}

export function dayLabel(date: string) {
  return new Intl.DateTimeFormat("en-GB", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" }).format(noon(date));
}

/** Monday index of a date: Monday is 0, Sunday is 6. */
export function weekdayIndex(date: string) {
  return (noon(date).getUTCDay() + 6) % 7;
}

/**
 * The month laid out as whole weeks — leading and trailing days belong to the
 * neighbouring months and are marked as outside, so the grid never breaks rank.
 */
export function monthGrid(monthStart: string) {
  const total = daysInMonth(monthStart);
  const lead = weekdayIndex(monthStart);
  const cells = Math.ceil((lead + total) / 7) * 7;
  const first = dateOffset(monthStart, -lead);
  return Array.from({ length: cells }, (_, index) => {
    const date = dateOffset(first, index);
    return { date, outside: date.slice(0, 7) !== monthStart.slice(0, 7) };
  });
}

/** The pace a volume asks for: pages left, spread over the days left. */
export function pagesPerDay(currentPage: number, totalPages: number, days: number) {
  const left = Math.max(0, totalPages - currentPage);
  if (!left || days <= 0) return 0;
  return Math.max(1, Math.ceil(left / days));
}
