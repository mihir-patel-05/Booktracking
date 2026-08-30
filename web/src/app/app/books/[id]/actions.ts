"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { localDate } from "@/lib/dates";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({
  id: z.string().uuid(),
  currentPage: z.coerce.number().int().min(0),
  totalPages: z.coerce.number().int().min(1).max(100000),
  status: z.enum(["Want to Read", "Currently Reading", "Completed", "Abandoned"]),
}).refine((value) => value.currentPage <= value.totalPages, { message: "Current page cannot exceed total pages." });

export type ProgressState = { error?: string; success?: boolean };

export async function updateProgress(_: ProgressState, formData: FormData): Promise<ProgressState> {
  const parsed = schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.issues[0]?.message ?? "Check the reading progress." };
  const parsedGoalIds = z.array(z.string().uuid()).max(50).safeParse(formData.getAll("goalIds"));
  if (!parsedGoalIds.success) return { error: "One of those goals could not be found." };
  const { id, currentPage, totalPages } = parsed.data;
  const status = currentPage === totalPages ? "Completed" : parsed.data.status;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Sign in again to record progress." };
  const [{ data: book }, { data: profile }, { data: currentGoals }] = await Promise.all([
    supabase.from("books").select("id,status,date_completed").eq("id", id).maybeSingle(),
    supabase.from("profiles").select("time_zone").eq("id", user.id).maybeSingle(),
    supabase.from("reading_goal_books").select("goal_id").eq("book_id", id),
  ]);
  if (!book) return { error: "That volume could not be found." };

  if (status === "Completed" && parsedGoalIds.data.length) {
    const { data: goals, error: goalError } = await supabase.from("reading_goals").select("id").in("id", parsedGoalIds.data).is("archived_at", null);
    if (goalError || goals?.length !== new Set(parsedGoalIds.data).size) return { error: "One of those goals is no longer active." };
  }

  const completedAt = status === "Completed" ? (book.date_completed ?? new Date().toISOString()) : null;
  const { error } = await supabase.from("books").update({
    current_page: currentPage,
    status,
    date_completed: completedAt,
  }).eq("id", id);
  if (error) return { error: error.message };

  if (status === "Completed") {
    if (parsedGoalIds.data.length) {
      const completedOn = localDate(profile?.time_zone || "UTC", new Date(completedAt!));
      const { error: addError } = await supabase.from("reading_goal_books").upsert(
        parsedGoalIds.data.map((goalId) => ({ goal_id: goalId, book_id: id, completed_on: completedOn })),
        { onConflict: "goal_id,book_id" },
      );
      if (addError) return { error: addError.message };
    }
    const selected = new Set(parsedGoalIds.data);
    const removed = (currentGoals ?? []).map((entry) => entry.goal_id).filter((goalId) => !selected.has(goalId));
    if (removed.length) {
      const { error: removeError } = await supabase.from("reading_goal_books").delete().eq("book_id", id).in("goal_id", removed);
      if (removeError) return { error: removeError.message };
    }
  }
  revalidatePath("/app");
  revalidatePath("/app/goals");
  revalidatePath("/app/library");
  revalidatePath(`/app/books/${id}`);
  return { success: true };
}
