"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { BarChart3, BookOpen, Home, Library, LogOut, Menu, Settings, StickyNote, Timer, X } from "lucide-react";
import { useState, type ReactNode } from "react";

const primary = [
  { href: "/app", label: "Home", icon: Home },
  { href: "/app/library", label: "Library", icon: Library },
  { href: "/app/timer", label: "Timer", icon: Timer },
  { href: "/app/notes", label: "Notes", icon: StickyNote },
  { href: "/app/stats", label: "Stats", icon: BarChart3 },
];

const desktop = [...primary, { href: "/app/quotes", label: "Quotes", icon: BookOpen }];

function isCurrent(pathname: string, href: string) {
  return href === "/app" ? pathname === href : pathname.startsWith(href);
}

export function AppShell({ children, displayName }: { children: ReactNode; displayName: string }) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="min-h-svh lg:grid lg:grid-cols-[248px_minmax(0,1fr)]">
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-[248px] border-r border-[var(--border)] bg-[#11111c]/95 px-4 py-6 backdrop-blur-xl lg:flex lg:flex-col">
        <Link className="mb-9 flex min-h-11 items-center gap-3 px-2" href="/app">
          <Image alt="" height="34" src="/brand/pageflow-logo.svg" width="34" />
          <span className="font-display text-xl">PageFlow</span>
        </Link>
        <nav aria-label="Main navigation" className="space-y-1">
          {desktop.map((item) => <NavItem active={isCurrent(pathname, item.href)} key={item.href} {...item} />)}
        </nav>
        <div className="mt-auto border-t border-[var(--border)] pt-4">
          <NavItem active={isCurrent(pathname, "/app/settings")} href="/app/settings" icon={Settings} label="Settings" />
          <form action="/auth/signout" method="post">
            <button className="mt-1 flex min-h-11 w-full items-center gap-3 rounded-xl px-3 text-sm text-secondary hover:bg-white/5 hover:text-white" type="submit">
              <LogOut size={19} /> Sign out
            </button>
          </form>
        </div>
      </aside>

      <div className="min-w-0 lg:col-start-2">
        <header className="sticky top-0 z-20 flex min-h-16 items-center justify-between border-b border-[var(--border)] bg-background/90 px-[max(1rem,env(safe-area-inset-left))] pt-[env(safe-area-inset-top)] backdrop-blur-xl lg:px-8">
          <Link className="flex min-h-11 items-center gap-2 lg:hidden" href="/app">
            <Image alt="" height="30" src="/brand/pageflow-logo.svg" width="30" />
            <span className="font-display text-lg">PageFlow</span>
          </Link>
          <p className="hidden text-sm text-secondary lg:block">Welcome back, <span className="text-white">{displayName || "reader"}</span>.</p>
          <button aria-expanded={menuOpen} aria-label="Open account menu" className="flex size-11 items-center justify-center rounded-xl border border-[var(--border)] lg:hidden" onClick={() => setMenuOpen(!menuOpen)} type="button">
            {menuOpen ? <X size={21} /> : <Menu size={21} />}
          </button>
          <Link className="hidden min-h-11 items-center rounded-xl px-3 text-sm text-secondary hover:text-white lg:flex" href="/app/settings"><Settings className="mr-2" size={18} />Account</Link>
        </header>

        {menuOpen ? (
          <div className="fixed inset-x-4 top-[calc(4rem+env(safe-area-inset-top))] z-30 rounded-2xl border border-[var(--border)] bg-surface p-3 shadow-2xl lg:hidden">
            <Link className="flex min-h-12 items-center gap-3 rounded-xl px-3" href="/app/quotes" onClick={() => setMenuOpen(false)}><BookOpen size={20} />Quotes</Link>
            <Link className="flex min-h-12 items-center gap-3 rounded-xl px-3" href="/app/settings" onClick={() => setMenuOpen(false)}><Settings size={20} />Settings</Link>
            <form action="/auth/signout" method="post"><button className="flex min-h-12 w-full items-center gap-3 rounded-xl px-3 text-red-200" type="submit"><LogOut size={20} />Sign out</button></form>
          </div>
        ) : null}

        <main className="mx-auto w-full max-w-[1180px] px-4 pb-[calc(var(--mobile-nav-height)+env(safe-area-inset-bottom)+1.5rem)] pt-6 sm:px-6 lg:px-8 lg:pb-12 lg:pt-9">{children}</main>
      </div>

      <nav aria-label="Mobile navigation" className="fixed inset-x-0 bottom-0 z-20 grid grid-cols-5 border-t border-[var(--border)] bg-[#11111c]/96 px-[max(.35rem,env(safe-area-inset-left))] pb-[env(safe-area-inset-bottom)] backdrop-blur-xl lg:hidden">
        {primary.map(({ href, label, icon: Icon }) => {
          const active = isCurrent(pathname, href);
          return <Link aria-current={active ? "page" : undefined} className={`flex min-h-[var(--mobile-nav-height)] flex-col items-center justify-center gap-1 text-[11px] ${active ? "text-accent-light" : "text-muted"}`} href={href} key={href}><Icon size={21} strokeWidth={active ? 2.4 : 1.8} />{label}</Link>;
        })}
      </nav>
    </div>
  );
}

function NavItem({ href, label, icon: Icon, active }: { href: string; label: string; icon: typeof Home; active: boolean }) {
  return <Link aria-current={active ? "page" : undefined} className={`flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm ${active ? "bg-accent/15 font-semibold text-accent-light" : "text-secondary hover:bg-white/5 hover:text-white"}`} href={href}><Icon size={19} />{label}</Link>;
}
