import type { ReactNode } from "react";

/* The furniture of the register: ruled figure bands, hairline meters,
   attendance squares and section heads, shared by Today, the Library,
   a volume's page and the Record. */

export function FigureBand({ cols, children }: { cols: number; children: ReactNode }) {
  return (
    <div
      className="grid grid-cols-2 border-y border-line md:grid-cols-[repeat(var(--cols),minmax(0,1fr))] [&>*:last-child]:border-r-0"
      style={{ "--cols": cols } as React.CSSProperties}
    >
      {children}
    </div>
  );
}

export function Figure({ label, value, unit, children }: { label: string; value: ReactNode; unit?: string; children?: ReactNode }) {
  return (
    <div className="border-r border-b border-line px-5 py-5 last:border-b-0 md:border-b-0 md:first:pl-0 md:last:pr-0">
      <p className="text-[9.5px] uppercase tracking-[.16em] text-muted">{label}</p>
      <p className="tnum mt-2 font-display text-[32px] leading-none">
        {value}
        {unit ? <span className="ml-1.5 font-sans text-[15px] text-muted">{unit}</span> : null}
      </p>
      {children}
    </div>
  );
}

export function Meter({ value, caption, thickness = 3 }: { value: number; caption?: ReactNode; thickness?: number }) {
  const pct = Math.max(0, Math.min(100, Math.round(value)));
  return (
    <div>
      <div className="bg-line-soft" style={{ height: thickness }}>
        <div className="bg-gold" style={{ height: thickness, width: `${pct}%` }} />
      </div>
      {caption ? <p className="tnum mt-[7px] text-[11px] text-faint">{caption}</p> : null}
    </div>
  );
}

export function SectionHeading({ title, note, aside }: { title: string; note?: string; aside?: ReactNode }) {
  return (
    <div className="mb-4">
      <div className="flex items-baseline justify-between gap-4">
        <h2 className="font-display text-[26px] leading-tight">{title}</h2>
        {aside}
      </div>
      {note ? <p className="mt-1 text-[12.5px] text-muted">{note}</p> : null}
    </div>
  );
}

/** One square to a day; the darker the ink, the longer the sitting. */
export function Attendance({ days }: { days: Array<{ date: string; minutes: number }> }) {
  return (
    <div className="grid grid-cols-7 gap-2">
      {days.map(({ date, minutes }) => {
        const step = minutes === 0 ? 0 : Math.min(4, Math.ceil(minutes / 15));
        const tint = [0, 0.16, 0.3, 0.45, 0.75][step];
        return (
          <div
            aria-label={`${date}: ${minutes} minutes`}
            className="aspect-square border border-line"
            key={date}
            style={tint ? { background: `color-mix(in srgb, var(--gold) ${tint * 100}%, transparent)` } : undefined}
            title={`${date}: ${minutes} min`}
          />
        );
      })}
    </div>
  );
}

/** A ruled key/value list, as on a volume's "in figures" plate. */
export function Ledger({ rows }: { rows: Array<{ label: string; value: ReactNode }> }) {
  return (
    <div className="flex flex-col">
      {rows.map(({ label, value }) => (
        <div className="tnum flex justify-between gap-4 border-b border-line-soft py-[9px] text-[13.5px] last:border-b-0" key={label}>
          <span className="text-secondary">{label}</span>
          <span>{value}</span>
        </div>
      ))}
    </div>
  );
}
