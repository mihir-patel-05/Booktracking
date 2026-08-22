import Image from "next/image";
import Link from "next/link";

const promises = [
  ["I", "Keep", "Every volume entered in a register — searched from Google Books, or set down by hand."],
  ["II", "Sit", "A timer that runs to a deadline, so a closed lid or a refresh never costs you the sitting."],
  ["III", "Return", "The lines and marginalia worth keeping, and a streak counted in your own time zone."],
];

export default function LandingPage() {
  return (
    <main className="mx-auto flex w-full max-w-[var(--content-width)] flex-col px-6 lg:px-11">
      <header className="flex min-h-16 items-center justify-between border-b border-line">
        <Link aria-label="PageFlow home" className="flex items-center gap-3" href="/">
          <Image alt="" className="rounded-md" height={30} priority src="/brand/pageflow-logo.svg" width={30} />
          <span className="font-display text-[27px] leading-none">PageFlow</span>
        </Link>
        <Link className="btn btn-secondary" href="/login">Sign in</Link>
      </header>

      <section className="grid flex-1 items-end gap-12 py-16 lg:grid-cols-[1.05fr_.95fr] lg:py-24">
        <div>
          <p className="eyebrow tracking-[.24em]">Est. 2026 · a reading register</p>
          <h1 className="mt-6 font-display text-[clamp(2.75rem,8vw,4.5rem)] leading-[1.04] tracking-[-.02em]">
            Keep the account<br />of what you read.
          </h1>
          <div className="my-8 h-px w-14 bg-gold" />
          <p className="max-w-[46ch] text-[15px] leading-[1.85] text-secondary [hyphens:auto] [text-align:justify]">
            A timer that survives a closed laptop, a commonplace book for the lines worth keeping, and a
            streak counted in your own time zone. No feed, no recommendations, nobody else’s shelf.
          </p>
          <div className="mt-9 flex flex-wrap gap-4">
            <Link className="btn btn-primary" href="/signup">Open an account</Link>
            <a className="btn btn-secondary" href="#how-it-works">See how it keeps</a>
          </div>
        </div>

        {/* A specimen page from the register itself. */}
        <div className="plate plate-filled px-7 py-7">
          <p className="eyebrow eyebrow-muted">Currently reading</p>
          <p className="mt-3 font-display text-[26px] leading-tight">The Rings of Saturn</p>
          <p className="mt-0.5 text-[12.5px] italic text-muted">W. G. Sebald</p>
          <div className="mt-5 h-[3px] bg-line-soft"><div className="h-[3px] w-[71%] bg-gold" /></div>
          <p className="tnum mt-2 text-[11px] text-faint">208 / 296 pp.</p>
          <p className="mt-5 text-[13px] leading-[1.8] text-secondary [hyphens:auto] [text-align:justify]">
            The catch is described in the register of accountancy — tonnage, barrels, lamp oil — and the
            effect is not clinical but elegiac.
          </p>
          <div className="mt-6 flex items-center justify-between border-t border-line-soft pt-4">
            <span className="text-[9.5px] uppercase tracking-[.18em] text-muted">Sitting no. 214</span>
            <span className="tnum font-display text-xl">25:00</span>
          </div>
        </div>
      </section>

      <section className="grid gap-10 border-t border-line py-14 sm:grid-cols-3" id="how-it-works">
        {promises.map(([numeral, title, copy]) => (
          <article key={title}>
            <p className="font-display text-[22px] text-gold">{numeral}</p>
            <h2 className="mt-3 font-display text-[26px]">{title}</h2>
            <p className="mt-2 text-sm leading-7 text-muted">{copy}</p>
          </article>
        ))}
      </section>
    </main>
  );
}
