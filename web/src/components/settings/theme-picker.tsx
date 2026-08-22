import { setTheme } from "@/app/app/settings/actions";
import type { Theme } from "@/lib/theme";

type Choice = { value: Theme; name: string; note: string };

const CHOICES: Choice[] = [
  { value: "paper", name: "Paper", note: "Warm near-white, ink black" },
  { value: "night", name: "Night", note: "Warm near-black, gilt accent" },
  { value: "system", name: "Follow the system", note: "Whatever light the device is set to" },
];

/** A specimen of the light, set as a page of ruled type. */
function Specimen({ value }: { value: Theme }) {
  const ground = value === "paper" ? "#f3f2f2" : value === "night" ? "#1a1917" : "linear-gradient(105deg,#f3f2f2 0 50%,#1a1917 50% 100%)";
  const ink = value === "night" ? "#f3f2f2" : "#201f1d";
  const rule = value === "system" ? "#8a8785" : ink;
  const gold = value === "paper" ? "#b68235" : value === "night" ? "#e1ad66" : "#c69a4e";
  const opacity = value === "system" ? 1 : value === "night" ? 0.3 : 0.28;

  return (
    <span className="block h-[104px] px-3.5 py-3" style={{ background: ground }}>
      <span className="block h-[5px] w-[52%]" style={{ background: ink, opacity: value === "night" ? 0.85 : value === "system" ? 0.5 : 0.75 }} />
      {[78, 70, 74].map((width, index) => (
        <span className="block h-[3px]" key={width} style={{ background: rule, opacity, width: `${width}%`, marginTop: index === 0 ? 9 : 6 }} />
      ))}
      <span className="mt-3.5 block h-[2px] w-[34%]" style={{ background: gold }} />
    </span>
  );
}

export function ThemePicker({ current }: { current: Theme }) {
  return (
    <form action={setTheme}>
      <div className="grid gap-5 sm:grid-cols-3">
        {CHOICES.map((choice) => {
          const chosen = current === choice.value;
          return (
            <label className="block cursor-pointer" key={choice.value}>
              <input className="sr-only" defaultChecked={chosen} name="theme" type="radio" value={choice.value} />
              <span className={`block border ${chosen ? "border-gold shadow-[inset_0_0_0_1px_var(--gold)]" : "border-line"}`}>
                <Specimen value={choice.value} />
              </span>
              <span className="mt-3 flex items-center gap-2.5">
                <span className={`grid size-[15px] place-items-center rounded-full border ${chosen ? "border-gold" : "border-[var(--border-strong)]"}`}>
                  {chosen ? <span className="size-[7px] rounded-full bg-gold" /> : null}
                </span>
                <span className="font-display text-[19px]">{choice.name}</span>
              </span>
              <span className="mt-1 block text-xs text-muted">{choice.note}</span>
            </label>
          );
        })}
      </div>
      <button className="btn btn-primary mt-7" type="submit">Read by this light</button>
    </form>
  );
}
