"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { localDate } from "@/lib/dates";
import { createClient } from "@/lib/supabase/server";

const DATE = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Choose a valid date.");
const goalFields = z.object({
  name: z.string().trim().min(1, "Name the goal.").max(120),
  targetBooks: z.coerce.number().int().min(1).max(10000),
  cadence: z.enum(["overall", "monthly"]),
  startsOn: DATE,
  endsOn: z.union([DATE, z.literal("")]),
}).superRefine((value, context) => {
  if (value.cadence === "overall" && !value.endsOn) {
    context.addIssue({ code: "custom", message: "Choose an end date for an overall goal.", path: ["endsOn"] });
  }
  if (value.endsOn && value.endsOn < value.startsOn) {
    context.addIssue({ code: "custom", message: "The end date must follow the start date.", path: ["endsOn"] });
  }
});

export type GoalActionState = { error?: string; success?: boolean };

function parseGoal(formData: FormData) {
  return goalFields.safeParse({
    name: formData.get("name"),
    targetBooks: formData.get("targetBooks"),
    cadence: formData.get("cadence"),
    startsOn: formData.get("startsOn"),
    endsOn: formData.get("endsOn") ?? "",
  });
}

function refreshGoals() {
  revalidatePath("/app");
  revalidatePath("/app/goals");
}

export async function createGoal(_: GoalActionState, formData: FormData): Promise<GoalActionState> {
  const parsed = parseGoal(formData);
  if (!parsed.success) return { error: parsed.error.issues[0]?.message ?? "Check the goal." };
  const supabase = await createClient();
  const { error } = await supabase.from("reading_goals").insert({
    name: parsed.data.name,
    target_books: parsed.data.targetBooks,
    cadence: parsed.data.cadence,
    starts_on: parsed.data.startsOn,
    ends_on: parsed.data.endsOn || null,
  });
  if (error) return { error: error.message };
  refreshGoals();
  return { success: true };
}

export async function updateGoal(_: GoalActionState, formData: FormData): Promise<GoalActionState> {
  const id = z.string().uuid().safeParse(formData.get("id"));
  const parsed = parseGoal(formData);
  if (!id.success || !parsed.success) return { error: parsed.success ? "That goal could not be found." : parsed.error.issues[0]?.message };
  const supabase = await createClient();
  const { error } = await supabase.from("reading_goals").update({
    name: parsed.data.name,
    target_books: parsed.data.targetBooks,
    cadence: parsed.data.cadence,
    starts_on: parsed.data.startsOn,
    ends_on: parsed.data.endsOn || null,
  }).eq("id", id.data);
  if (error) return { error: error.message };
  refreshGoals();
  return { success: true };
}

export async function setGoalArchived(formData: FormData) {
  const parsed = z.object({ id: z.string().uuid(), archived: z.enum(["true", "false"]) }).safeParse(Object.fromEntries(formData));
  if (!parsed.success) return;
  const supabase = await createClient();
  await supabase.from("reading_goals").update({ archived_at: parsed.data.archived === "true" ? new Date().toISOString() : null }).eq("id", parsed.data.id);
  refreshGoals();
}

export async function addBookToGoal(formData: FormData) {
  const parsed = z.object({ goalId: z.string().uuid(), bookId: z.string().uuid() }).safeParse(Object.fromEntries(formData));
  if (!parsed.success) return;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  const [{ data: book }, { data: goal }, { data: profile }] = await Promise.all([
    supabase.from("books").select("id,status,date_completed").eq("id", parsed.data.bookId).maybeSingle(),
    supabase.from("reading_goals").select("id").eq("id", parsed.data.goalId).is("archived_at", null).maybeSingle(),
    supabase.from("profiles").select("time_zone").eq("id", user.id).maybeSingle(),
  ]);
  if (!book || book.status !== "Completed" || !book.date_completed || !goal) return;
  const completedOn = localDate(profile?.time_zone || "UTC", new Date(book.date_completed));
  await supabase.from("reading_goal_books").upsert({ goal_id: goal.id, book_id: book.id, completed_on: completedOn }, { onConflict: "goal_id,book_id" });
  refreshGoals();
  revalidatePath(`/app/books/${book.id}`);
}

export async function removeBookFromGoal(formData: FormData) {
  const parsed = z.object({ goalId: z.string().uuid(), bookId: z.string().uuid() }).safeParse(Object.fromEntries(formData));
  if (!parsed.success) return;
  const supabase = await createClient();
  await supabase.from("reading_goal_books").delete().eq("goal_id", parsed.data.goalId).eq("book_id", parsed.data.bookId);
  refreshGoals();
  revalidatePath(`/app/books/${parsed.data.bookId}`);
}
