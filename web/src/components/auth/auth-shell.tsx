import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";

type AuthShellProps = {
  eyebrow: string;
  title: string;
  description: string;
  children: ReactNode;
};

export function AuthShell({ eyebrow, title, description, children }: AuthShellProps) {
  return (
    <main className="grid min-h-svh lg:grid-cols-2">
      {/* The title page: always dark, whatever light the reader keeps. */}
      <section className="night hidden flex-col justify-between bg-background px-16 py-14 text-foreground lg:flex">
        <Link className="flex items-center gap-2.5" href="/">
          <Image alt="" className="rounded-md" height={28} src="/brand/pageflow-logo.svg" width={28} />
          <span className="font-display text-2xl">PageFlow</span>
        </Link>

        <div>
          <p className="eyebrow tracking-[.24em]">Est. 2026 · a reading register</p>
          <h1 className="mt-6 font-display text-[64px] font-normal leading-[1.04] tracking-[-.02em]">
            Keep the account<br />of what you read.
          </h1>
          <div className="my-8 h-px w-14 bg-gold" />
          <p className="max-w-[44ch] text-[15px] leading-[1.85] text-secondary [hyphens:auto] [text-align:justify]">
            A timer that survives a closed laptop, a commonplace book for the lines worth keeping, and a
            streak counted in your own time zone. No feed, no recommendations, nobody else’s shelf.
          </p>
        </div>

        <p className="text-[11px] uppercase tracking-[.14em] text-faint">Your reading log is yours alone</p>
      </section>

      <section className="safe-page grid place-items-center px-6 py-12 lg:px-16">
        <div className="w-full max-w-[396px]">
          <Link className="mb-10 flex items-center justify-center gap-3 lg:hidden" href="/">
            <Image alt="" className="rounded-md" height={32} priority src="/brand/pageflow-logo.svg" width={32} />
            <span className="font-display text-2xl">PageFlow</span>
          </Link>

          <p className="eyebrow">{eyebrow}</p>
          <h2 className="mt-3 font-display text-[34px] leading-tight tracking-[-.02em]">{title}</h2>
          <p className="mt-1.5 text-[13.5px] leading-6 text-muted">{description}</p>
          <div className="mt-8">{children}</div>
        </div>
      </section>
    </main>
  );
}
