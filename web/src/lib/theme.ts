/** The light a reader chooses to read by. "system" follows the device. */
export const THEMES = ["system", "paper", "night"] as const;
export type Theme = (typeof THEMES)[number];

export const THEME_COOKIE = "pageflow-theme";

export function isTheme(value: unknown): value is Theme {
  return typeof value === "string" && (THEMES as readonly string[]).includes(value);
}

/**
 * The attribute stamped on <html>. "system" stamps nothing, so the
 * prefers-color-scheme rules in globals.css decide.
 */
export function themeAttribute(theme: Theme) {
  return theme === "system" ? undefined : theme;
}
