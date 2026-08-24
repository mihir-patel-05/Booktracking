"use server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import { isTheme, THEME_COOKIE } from "@/lib/theme";
const schema = z.object({ displayName: z.string().trim().max(80), timeZone: z.string().min(1).max(64) });
export async function updateProfile(formData: FormData) {
  const parsed = schema.safeParse(Object.fromEntries(formData)); if (!parsed.success) return;
  try { new Intl.DateTimeFormat("en", { timeZone: parsed.data.timeZone }).format(); } catch { return; }
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) return;
  await supabase.from("profiles").upsert({ id: user.id, display_name: parsed.data.displayName, time_zone: parsed.data.timeZone });
  revalidatePath("/app", "layout");
}

/** Keep the reader's chosen light in a cookie, so the server can set it
    on <html> before the first paint and no page flashes the wrong way. */
export async function setTheme(formData: FormData) {
  const theme = formData.get("theme");
  if (!isTheme(theme)) return;
  const store = await cookies();
  store.set(THEME_COOKIE, theme, {
    path: "/",
    maxAge: 60 * 60 * 24 * 365,
    sameSite: "lax",
  });
  revalidatePath("/", "layout");
}
