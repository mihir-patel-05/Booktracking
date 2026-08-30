export type GoalCadence = "overall" | "monthly";

export type GoalWindow = {
  startsOn: string;
  endsOn: string;
};

export type GoalDefinition = {
  cadence: string;
  starts_on: string;
  ends_on: string | null;
};

function monthBounds(date: string): GoalWindow {
  const [year, month] = date.slice(0, 7).split("-").map(Number);
  const last = new Date(Date.UTC(year!, month!, 0)).getUTCDate();
  return { startsOn: `${date.slice(0, 7)}-01`, endsOn: `${date.slice(0, 7)}-${String(last).padStart(2, "0")}` };
}

/** The active measuring window shown for a goal on a given day. */
export function goalWindow(goal: GoalDefinition, today: string): GoalWindow {
  if (goal.cadence !== "monthly") {
    return { startsOn: goal.starts_on, endsOn: goal.ends_on ?? goal.starts_on };
  }

  const reference = today < goal.starts_on
    ? goal.starts_on
    : goal.ends_on && today > goal.ends_on
      ? goal.ends_on
      : today;
  const month = monthBounds(reference);
  return {
    startsOn: goal.starts_on > month.startsOn ? goal.starts_on : month.startsOn,
    endsOn: goal.ends_on && goal.ends_on < month.endsOn ? goal.ends_on : month.endsOn,
  };
}

export function goalProgress(completedOn: string[], window: GoalWindow) {
  return completedOn.filter((date) => date >= window.startsOn && date <= window.endsOn).length;
}

export function goalPercent(progress: number, target: number) {
  return target > 0 ? Math.min(100, Math.round((progress / target) * 100)) : 0;
}

export function goalAvailability(goal: GoalDefinition, today: string) {
  if (today < goal.starts_on) return "upcoming" as const;
  if (goal.ends_on && today > goal.ends_on) return "ended" as const;
  return "active" as const;
}
