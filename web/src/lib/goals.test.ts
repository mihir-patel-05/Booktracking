import { describe, expect, it } from "vitest";
import { goalAvailability, goalPercent, goalProgress, goalWindow } from "./goals";

describe("reading goal windows", () => {
  it("measures an overall goal across its full range", () => {
    const window = goalWindow({ cadence: "overall", starts_on: "2026-01-01", ends_on: "2026-12-31" }, "2026-08-30");
    expect(window).toEqual({ startsOn: "2026-01-01", endsOn: "2026-12-31" });
    expect(goalProgress(["2025-12-31", "2026-01-01", "2026-08-30", "2027-01-01"], window)).toBe(2);
  });

  it("measures a monthly goal inside the current calendar month", () => {
    const window = goalWindow({ cadence: "monthly", starts_on: "2026-01-15", ends_on: null }, "2026-08-30");
    expect(window).toEqual({ startsOn: "2026-08-01", endsOn: "2026-08-31" });
    expect(goalProgress(["2026-07-31", "2026-08-01", "2026-08-31", "2026-09-01"], window)).toBe(2);
  });

  it("clamps the first and final monthly windows to the goal dates", () => {
    const goal = { cadence: "monthly", starts_on: "2026-01-15", ends_on: "2026-03-10" };
    expect(goalWindow(goal, "2025-12-01")).toEqual({ startsOn: "2026-01-15", endsOn: "2026-01-31" });
    expect(goalWindow(goal, "2026-04-01")).toEqual({ startsOn: "2026-03-01", endsOn: "2026-03-10" });
  });

  it("reports availability and caps percentages at one hundred", () => {
    const goal = { cadence: "overall", starts_on: "2026-02-01", ends_on: "2026-06-30" };
    expect(goalAvailability(goal, "2026-01-31")).toBe("upcoming");
    expect(goalAvailability(goal, "2026-03-01")).toBe("active");
    expect(goalAvailability(goal, "2026-07-01")).toBe("ended");
    expect(goalPercent(5, 2)).toBe(100);
  });
});
