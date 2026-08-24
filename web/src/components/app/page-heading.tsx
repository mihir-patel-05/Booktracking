import type { ReactNode } from "react";

export function PageHeading({ eyebrow, title, description, action }: { eyebrow?: string; title: string; description?: string; action?: ReactNode }) {
  return (
    <header className="mb-9 flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between sm:gap-8">
      <div>
        {eyebrow ? <p className="eyebrow mb-3">{eyebrow}</p> : null}
        <h1 className="font-display text-[34px] leading-[1.05] tracking-[-.02em] sm:text-[46px]">{title}</h1>
        {description ? <p className="mt-[10px] max-w-[50ch] text-sm leading-6 text-muted">{description}</p> : null}
      </div>
      {action ? <div className="flex shrink-0 flex-wrap gap-3">{action}</div> : null}
    </header>
  );
}
