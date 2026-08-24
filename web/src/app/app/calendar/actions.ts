"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const DATE = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Choose a day in the diary.");

const planSchema = z.object({
  bookId: z.string().uuid("Choose a volume to plan."),
  date: DATE,
  targetMinutes: z.coerce.number().int().min(5).max(1440).optional(),
  targetPages: z.coerce.number().int().min(1).max(100000).optional(),
  note: z.string().trim().max(500),
});

export type PlanActionState = { error?: string; success?: boolean };

export async function planReading(_: PlanActionState, formData: FormData): Promise<PlanActionState> {
  const parsed = planSchema.safeParse({
    bookId: formData.get("bookId"),
    date: formData.get("date"),
    targetMinutes: formData.get("targetMinutes") || undefined,
    targetPages: formData.get("targetPages") || undefined,
    note: formData.get("note") ?? "",
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message ?? "Check the sitting you are planning." };

  const supabase = await createClient();
  const { error } = await supabase.from("reading_plans").insert({
    book_id: parsed.data.bookId,
    planned_date: parsed.data.date,
    target_minutes: parsed.data.targetMinutes ?? null,
    target_pages: parsed.data.targetPages ?? null,
    note: parsed.data.note || null,
  });
  if (error) {
    return { error: error.code === "23505" ? "That volume already stands in the diary for this day." : error.message };
  }
  revalidatePath("/app");
  revalidatePath("/app/calendar");
  return { success: true };
}

export async function movePlan(formData: FormData) {
  const parsed = z.object({ id: z.string().uuid(), date: DATE }).safeParse({
    id: formData.get("id"), date: formData.get("date"),
  });
  if (!parsed.success) return;
  const supabase = await createClient();
  await supabase.from("reading_plans").update({ planned_date: parsed.data.date }).eq("id", parsed.data.id);
  revalidatePath("/app");
  revalidatePath("/app/calendar");
}

export async function removePlan(formData: FormData) {
  const id = z.string().uuid().safeParse(formData.get("id"));
  if (!id.success) return;
  const supabase = await createClient();
  await supabase.from("reading_plans").delete().eq("id", id.data);
  revalidatePath("/app");
  revalidatePath("/app/calendar");
}
