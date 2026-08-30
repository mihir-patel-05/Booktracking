"use client";

import { Target } from "lucide-react";
import { useActionState, useEffect, useRef, useState } from "react";
import { createGoal, updateGoal, type GoalActionState } from "@/app/app/goals/actions";

type GoalValues = {
  id?: string;
  name: string;
  targetBooks: number;
  cadence: string;
  startsOn: string;
  endsOn: string | null;
};

export function GoalComposer({ today }: { today: string }) {
  const yearEnd = `${today.slice(0, 4)}-12-31`;
  const form = useRef<HTMLFormElement>(null);
  const [cadence, setCadence] = useState("overall");
  const [state, action, pending] = useActionState<GoalActionState, FormData>(createGoal, {});

  useEffect(() => {
    if (state.success) {
      form.current?.reset();
      setCadence("overall");
    }
  }, [state.success]);

  return (
    <form action={action} className="plate px-5 py-5" ref={form}>
      <p className="eyebrow mb-4">Set a goal</p>
      <GoalFields cadence={cadence} defaults={{ name: "", targetBooks: 20, cadence: "overall", startsOn: `${today.slice(0, 4)}-01-01`, endsOn: yearEnd }} onCadence={setCadence} />
      {state.error ? <p className="mt-3 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
      {state.success ? <p className="mt-3 text-sm text-[var(--success)]" role="status">Goal entered.</p> : null}
      <button className="btn btn-primary btn-block mt-4" disabled={pending} type="submit">
        <Target size={15} strokeWidth={1.5} />{pending ? "Entering…" : "Enter the goal"}
      </button>
    </form>
  );
}

export function GoalEditForm({ goal }: { goal: GoalValues }) {
  const [cadence, setCadence] = useState(goal.cadence);
  const [state, action, pending] = useActionState<GoalActionState, FormData>(updateGoal, {});
  return (
    <details className="mt-4 border-t border-line-soft pt-3">
      <summary className="cursor-pointer text-xs text-gold-text">Edit the terms</summary>
      <form action={action} className="mt-4">
        <input name="id" type="hidden" value={goal.id} />
        <GoalFields cadence={cadence} defaults={goal} onCadence={setCadence} />
        {state.error ? <p className="mt-3 text-sm text-[var(--danger)]" role="alert">{state.error}</p> : null}
        {state.success ? <p className="mt-3 text-sm text-[var(--success)]" role="status">Terms revised.</p> : null}
        <button className="btn btn-secondary btn-block mt-4" disabled={pending} type="submit">{pending ? "Saving…" : "Save the terms"}</button>
      </form>
    </details>
  );
}

function GoalFields({ defaults, cadence, onCadence }: { defaults: GoalValues; cadence: string; onCadence: (value: string) => void }) {
  return (
    <div className="grid gap-3">
      <label className="block">
        <span className="field-label">Name</span>
        <input className="input" defaultValue={defaults.name} maxLength={120} name="name" placeholder="Twenty books this year" required />
      </label>
      <div className="grid grid-cols-2 gap-3">
        <label className="block">
          <span className="field-label">Books</span>
          <input className="input tnum" defaultValue={defaults.targetBooks} max="10000" min="1" name="targetBooks" required type="number" />
        </label>
        <label className="block">
          <span className="field-label">Measure</span>
          <select className="input" defaultValue={defaults.cadence} name="cadence" onChange={(event) => onCadence(event.target.value)}>
            <option value="overall">Across the whole goal</option>
            <option value="monthly">Every month</option>
          </select>
        </label>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <label className="block">
          <span className="field-label">Begins</span>
          <input className="input tnum" defaultValue={defaults.startsOn} name="startsOn" required type="date" />
        </label>
        <label className="block">
          <span className="field-label">Ends {cadence === "monthly" ? "(optional)" : ""}</span>
          <input className="input tnum" defaultValue={defaults.endsOn ?? ""} name="endsOn" required={cadence !== "monthly"} type="date" />
        </label>
      </div>
      <p className="text-[11px] text-faint">
        {cadence === "monthly" ? "The count starts fresh each calendar month." : "Each finished volume counts once across these dates."}
      </p>
    </div>
  );
}
