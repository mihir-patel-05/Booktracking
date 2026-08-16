"use client";

import Script from "next/script";
import { useEffect, useId, useRef } from "react";

declare global {
  interface Window {
    turnstile?: {
      render: (container: HTMLElement, options: Record<string, unknown>) => string;
      remove: (widgetId: string) => void;
    };
  }
}

type TurnstileProps = {
  onToken: (token: string | undefined) => void;
};

export function Turnstile({ onToken }: TurnstileProps) {
  const siteKey = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY;
  const containerRef = useRef<HTMLDivElement>(null);
  const widgetRef = useRef<string | null>(null);
  const reactId = useId();

  useEffect(() => {
    if (!siteKey) {
      onToken(undefined);
    }
  }, [onToken, siteKey]);

  function renderWidget() {
    if (!siteKey || !containerRef.current || !window.turnstile || widgetRef.current) return;
    widgetRef.current = window.turnstile.render(containerRef.current, {
      sitekey: siteKey,
      theme: "dark",
      size: "flexible",
      callback: (token: string) => onToken(token),
      "expired-callback": () => onToken(undefined),
      "error-callback": () => onToken(undefined),
    });
  }

  useEffect(() => {
    renderWidget();
    return () => {
      if (widgetRef.current && window.turnstile) {
        window.turnstile.remove(widgetRef.current);
      }
    };
  });

  if (!siteKey) return null;

  return (
    <>
      <Script
        id={`turnstile-${reactId}`}
        src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
        strategy="afterInteractive"
        onLoad={renderWidget}
      />
      <div ref={containerRef} className="min-h-[65px]" aria-label="Bot verification" />
    </>
  );
}
