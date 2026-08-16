"use server";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
const schema = z.object({ displayName: z.string().trim().max(80), timeZone: z.string().min(1).max(64) });
export async function updateProfile(formData: FormData) {
  const parsed = schema.safeParse(Object.fromEntries(formData)); if (!parsed.success) return;
  try { new Intl.DateTimeFormat("en", { timeZone: parsed.data.timeZone }).format(); } catch { return; }
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); if (!user) return;
  await supabase.from("profiles").upsert({ id: user.id, display_name: parsed.data.displayName, time_zone: parsed.data.timeZone });
  revalidatePath("/app", "layout");
}
