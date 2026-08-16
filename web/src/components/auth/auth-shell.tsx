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
    <main className="safe-page mx-auto grid w-full max-w-[1100px] items-center gap-10 py-6 lg:min-h-screen lg:grid-cols-2 lg:py-12">
      <section className="hidden lg:block">
        <Link className="inline-flex min-h-11 items-center gap-3" href="/">
          <Image src="/brand/pageflow-logo.svg" alt="" width={44} height={44} />
          <span className="font-display text-2xl">PageFlow</span>
        </Link>
        <p className="mt-16 text-xs font-bold uppercase tracking-[0.22em] text-accent-light">Read with intention</p>
        <h1 className="font-display mt-5 max-w-md text-6xl leading-[0.98]">Every chapter leaves something behind.</h1>
        <p className="mt-6 max-w-lg text-lg leading-8 text-secondary">
          Keep the ideas, feelings, and passages that make a book worth remembering.
        </p>
      </section>

      <section className="mx-auto w-full max-w-[460px]">
        <Link className="mb-10 flex min-h-11 items-center justify-center gap-3 lg:hidden" href="/">
          <Image src="/brand/pageflow-logo.svg" alt="" width={42} height={42} priority />
          <span className="font-display text-2xl">PageFlow</span>
        </Link>
        <div className="glass-card rounded-[2rem] p-5 sm:p-8">
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-accent-light">{eyebrow}</p>
          <h2 className="font-display mt-3 text-4xl leading-tight">{title}</h2>
          <p className="mt-3 text-sm leading-6 text-secondary">{description}</p>
          <div className="mt-7">{children}</div>
        </div>
      </section>
    </main>
  );
}
