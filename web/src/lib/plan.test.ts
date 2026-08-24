import { describe, expect, it } from "vitest";
import { daysInMonth, monthGrid, monthStartOf, pagesPerDay, resolveMonth, shiftMonth, weekdayIndex } from "./plan";

describe("the reading diary's month", () => {
  it("takes the month a date falls in", () => {
    expect(monthStartOf("2026-08-24")).toBe("2026-08-01");
  });

  it("steps months without landing on a day the next month lacks", () => {
    expect(shiftMonth("2026-01-01", 1)).toBe("2026-02-01");
    expect(shiftMonth("2026-03-01", -1)).toBe("2026-02-01");
    expect(shiftMonth("2026-12-01", 1)).toBe("2027-01-01");
  });

  it("counts the days of a month, February included", () => {
    expect(daysInMonth("2026-02-01")).toBe(28);
    expect(daysInMonth("2028-02-01")).toBe(29);
    expect(daysInMonth("2026-08-01")).toBe(31);
  });

  it("only accepts a well-formed month from the query string", () => {
    expect(resolveMonth("2026-11", "2026-08-24")).toBe("2026-11-01");
    expect(resolveMonth("2026-13", "2026-08-24")).toBe("2026-08-01");
    expect(resolveMonth(undefined, "2026-08-24")).toBe("2026-08-01");
    expect(resolveMonth("not-a-month", "2026-08-24")).toBe("2026-08-01");
  });

  it("rules the week from Monday", () => {
    expect(weekdayIndex("2026-08-24")).toBe(0);
    expect(weekdayIndex("2026-08-30")).toBe(6);
  });
});

describe("the month grid", () => {
  it("fills whole weeks and marks the neighbouring days", () => {
    const grid = monthGrid("2026-08-01");
    expect(grid.length % 7).toBe(0);
    expect(grid[0]).toEqual({ date: "2026-07-27", outside: true });
    expect(grid.find((cell) => !cell.outside)?.date).toBe("2026-08-01");
    expect(grid.filter((cell) => !cell.outside)).toHaveLength(31);
    expect(grid.at(-1)?.date).toBe("2026-09-06");
  });

  it("starts flush when the first falls on a Monday", () => {
    const grid = monthGrid("2026-06-01");
    expect(grid[0]).toEqual({ date: "2026-06-01", outside: false });
    expect(grid).toHaveLength(35);
  });

  it("keeps every date in sequence across a month boundary", () => {
    const dates = monthGrid("2026-02-01").map((cell) => cell.date);
    expect(dates).toContain("2026-02-28");
    expect(dates).toContain("2026-03-01");
    expect(new Set(dates).size).toBe(dates.length);
  });
});

describe("the pace a volume asks for", () => {
  it("spreads the pages left over the days left", () => {
    expect(pagesPerDay(100, 300, 10)).toBe(20);
    expect(pagesPerDay(0, 301, 10)).toBe(31);
  });

  it("asks nothing of a volume already finished", () => {
    expect(pagesPerDay(300, 300, 10)).toBe(0);
    expect(pagesPerDay(0, 300, 0)).toBe(0);
  });
});
