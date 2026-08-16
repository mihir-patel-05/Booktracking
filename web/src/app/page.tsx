import Image from "next/image";
import Link from "next/link";

const features = [
  ["Track", "Build your library and see every page of progress."],
  ["Reflect", "Turn each reading session into notes worth keeping."],
  ["Grow", "Make consistency visible with streaks, XP, and insights."],
];

export default function LandingPage() {
  return (
    <main className="safe-page mx-auto flex w-full max-w-[1180px] flex-col">
      <header className="flex min-h-14 items-center justify-between">
        <Link className="flex min-h-11 items-center gap-3" href="/" aria-label="PageFlow home">
          <Image src="/brand/pageflow-logo.svg" alt="" width={36} height={36} priority />
          <span className="font-display text-xl font-semibold">PageFlow</span>
        </Link>
        <Link className="secondary-button !min-h-11 !rounded-full !px-4 !py-2 text-sm" href="/login">
          Sign in
        </Link>
      </header>

      <section className="grid flex-1 items-center gap-12 py-14 lg:grid-cols-[1.05fr_0.95fr] lg:py-20">
        <div className="max-w-2xl">
          <p className="mb-5 text-xs font-bold uppercase tracking-[0.22em] text-accent-light">
            Your reading life, remembered
          </p>
          <h1 className="font-display text-[clamp(3.2rem,14vw,6.5rem)] font-semibold leading-[0.91] tracking-[-0.045em]">
            Read.<br />Reflect.<br />
            <span className="bg-gradient-to-r from-[#a78bfa] to-[#f0abfc] bg-clip-text text-transparent">
              Grow.
            </span>
          </h1>
          <p className="mt-7 max-w-xl text-base leading-7 text-secondary sm:text-lg">
            PageFlow turns reading sessions into a personal knowledge library—complete with focused timers,
            thoughtful prompts, saved quotes, and momentum you can see.
          </p>
          <div className="mt-8 grid gap-3 sm:flex">
            <Link className="primary-button px-7" href="/signup">
              Start your reading flow <span aria-hidden>→</span>
            </Link>
            <a className="secondary-button px-7" href="#how-it-works">See how it works</a>
          </div>
        </div>

        <div className="relative mx-auto w-full max-w-[430px] lg:mr-0">
          <div className="absolute -inset-10 rounded-full bg-accent/20 blur-3xl" aria-hidden />
          <div className="glass-card relative overflow-hidden rounded-[2rem] p-5 sm:p-6">
            <div className="mb-6 flex items-center justify-between">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.14em] text-muted">Today&apos;s flow</p>
                <h2 className="font-display mt-1 text-2xl">Keep the story moving.</h2>
              </div>
              <span className="rounded-full border border-warning/30 bg-warning/10 px-3 py-2 text-sm text-warning">
                🔥 12 days
              </span>
            </div>
            <div className="rounded-3xl border border-white/5 bg-black/20 p-4">
              <div className="flex gap-4">
                <div className="h-28 w-20 shrink-0 rounded-xl bg-gradient-to-br from-[#3730a3] to-[#a855f7] shadow-xl" />
                <div className="min-w-0 flex-1 py-1">
                  <p className="truncate font-semibold">The Midnight Library</p>
                  <p className="mt-1 text-sm text-secondary">Matt Haig</p>
                  <div className="mt-5 h-1.5 overflow-hidden rounded-full bg-white/10">
                    <div className="h-full w-[63%] rounded-full bg-gradient-to-r from-accent to-[#c084fc]" />
                  </div>
                  <p className="mt-2 text-xs text-muted">189 of 300 pages</p>
                </div>
              </div>
              <div className="mt-5 flex items-center justify-between rounded-2xl bg-surface-light/70 px-4 py-3">
                <span className="text-sm text-secondary">Ready for another chapter?</span>
                <span className="font-display text-xl text-accent-light">25:00</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="how-it-works" className="grid gap-3 pb-10 sm:grid-cols-3">
        {features.map(([title, copy], index) => (
          <article className="glass-card rounded-2xl p-5" key={title}>
            <span className="text-xs font-bold text-accent-light">0{index + 1}</span>
            <h2 className="font-display mt-5 text-2xl">{title}</h2>
            <p className="mt-2 text-sm leading-6 text-secondary">{copy}</p>
          </article>
        ))}
      </section>
    </main>
  );
}
