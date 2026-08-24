"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { BarChart3, CalendarDays, Home, Library, Menu, Quote, StickyNote, Timer, X } from "lucide-react";
import { useState, type ReactNode } from "react";

const nav = [
  { href: "/app", label: "Today", icon: Home },
  { href: "/app/library", label: "Library", icon: Library },
  { href: "/app/calendar", label: "Calendar", icon: CalendarDays },
  { href: "/app/timer", label: "Timer", icon: Timer },
  { href: "/app/notes", label: "Notes", icon: StickyNote },
  { href: "/app/quotes", label: "Quotes", icon: Quote },
  { href: "/app/stats", label: "Statistics", icon: BarChart3 },
];

/* The bottom bar carries five; the commonplace book and the margins keep to the menu. */
const mobile = nav.filter((item) => item.href !== "/app/quotes" && item.href !== "/app/notes");

function isCurrent(pathname: string, href: string) {
  return href === "/app" ? pathname === href : pathname.startsWith(href);
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean).slice(0, 2);
  return parts.map((part) => part[0]!.toLocaleUpperCase()).join("") || "PF";
}

export function AppShell({ children, displayName }: { children: ReactNode; displayName: string }) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const today = new Intl.DateTimeFormat("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" }).format(new Date());

  return (
    <div className="min-h-svh lg:grid lg:grid-cols-[var(--rail-width)_minmax(0,1fr)]">
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-[var(--rail-width)] flex-col border-r border-line bg-rail py-[30px] lg:flex">
        <div className="px-[26px] pb-[26px]">
          <Link className="flex items-center gap-3" href="/app">
            <Image alt="" className="rounded-md" height="30" src="/brand/pageflow-logo.svg" width="30" />
            <span className="font-display text-[27px] leading-none tracking-[.01em]">PageFlow</span>
          </Link>
          <div className="mt-[11px] mb-[9px] h-px w-[26px] bg-gold" />
          <p className="text-[9.5px] uppercase tracking-[.22em] text-muted">A reading register</p>
        </div>

        <nav aria-label="Main navigation" className="flex flex-col">
          {nav.map(({ href, label, icon: Icon }) => {
            const active = isCurrent(pathname, href);
            return (
              <Link
                aria-current={active ? "page" : undefined}
                className={`flex items-center gap-[11px] px-[26px] py-[10px] text-sm ${
                  active
                    ? "bg-[var(--gold-tint)] text-gold-text shadow-[inset_2px_0_0_var(--gold)]"
                    : "text-secondary hover:text-foreground"
                }`}
                href={href}
                key={href}
              >
                <Icon size={16} strokeWidth={1.5} />
                {label}
              </Link>
            );
          })}
        </nav>

        <div className="mt-auto flex flex-col gap-3 border-t border-line px-[26px] pt-[18px]">
          <Link className={`text-[13px] ${isCurrent(pathname, "/app/settings") ? "text-gold-text" : "text-muted hover:text-foreground"}`} href="/app/settings">Settings</Link>
          <form action="/auth/signout" method="post">
            <button className="text-[13px] text-muted hover:text-foreground" type="submit">Sign out</button>
          </form>
        </div>
      </aside>

      <div className="min-w-0 lg:col-start-2">
        <header className="sticky top-0 z-20 flex min-h-16 items-center justify-between border-b border-line bg-background px-[max(1rem,env(safe-area-inset-left))] pt-[env(safe-area-inset-top)] lg:px-11">
          <Link className="flex min-h-11 items-center gap-2 lg:hidden" href="/app">
            <Image alt="" className="rounded" height="26" src="/brand/pageflow-logo.svg" width="26" />
            <span className="font-display text-xl">PageFlow</span>
          </Link>
          <p className="tnum hidden text-[9.5px] uppercase tracking-[.2em] text-muted lg:block">{today}</p>
          <button aria-expanded={menuOpen} aria-label="Open account menu" className="flex size-11 items-center justify-center border border-line lg:hidden" onClick={() => setMenuOpen(!menuOpen)} type="button">
            {menuOpen ? <X size={20} strokeWidth={1.5} /> : <Menu size={20} strokeWidth={1.5} />}
          </button>
          <div className="hidden items-center gap-[18px] lg:flex">
            <span className="text-[13px] text-muted">{displayName || "reader"}</span>
            <Link aria-label="Settings" className="grid size-[30px] place-items-center rounded-full border border-[var(--border-strong)] font-display text-sm" href="/app/settings">
              {initials(displayName)}
            </Link>
          </div>
        </header>

        {menuOpen ? (
          <div className="fixed inset-x-4 top-[calc(4rem+env(safe-area-inset-top))] z-30 border border-line bg-panel p-2 shadow-[var(--shadow-lg)] lg:hidden">
            <Link className="flex min-h-12 items-center gap-3 px-3 text-sm" href="/app/notes" onClick={() => setMenuOpen(false)}><StickyNote size={18} strokeWidth={1.5} />Notes</Link>
            <Link className="flex min-h-12 items-center gap-3 px-3 text-sm" href="/app/quotes" onClick={() => setMenuOpen(false)}><Quote size={18} strokeWidth={1.5} />Quotes</Link>
            <Link className="flex min-h-12 items-center gap-3 px-3 text-sm" href="/app/settings" onClick={() => setMenuOpen(false)}>Settings</Link>
            <form action="/auth/signout" method="post"><button className="flex min-h-12 w-full items-center gap-3 px-3 text-left text-sm text-muted" type="submit">Sign out</button></form>
          </div>
        ) : null}

        <main className="mx-auto w-full max-w-[var(--content-width)] px-4 pb-[calc(var(--mobile-nav-height)+env(safe-area-inset-bottom)+1.5rem)] pt-8 sm:px-6 lg:px-11 lg:pb-12 lg:pt-10">{children}</main>
      </div>

      <nav aria-label="Mobile navigation" className="fixed inset-x-0 bottom-0 z-20 grid grid-cols-5 border-t border-line bg-rail px-[max(.35rem,env(safe-area-inset-left))] pb-[env(safe-area-inset-bottom)] lg:hidden">
        {mobile.map(({ href, label, icon: Icon }) => {
          const active = isCurrent(pathname, href);
          return (
            <Link
              aria-current={active ? "page" : undefined}
              className={`flex min-h-[var(--mobile-nav-height)] flex-col items-center justify-center gap-1.5 text-[10px] uppercase tracking-[.12em] ${active ? "text-gold-text" : "text-muted"}`}
              href={href}
              key={href}
            >
              <Icon size={19} strokeWidth={active ? 1.9 : 1.5} />
              {label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
