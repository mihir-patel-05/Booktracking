"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
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
  const { id, currentPage, totalPages } = parsed.data;
  const status = currentPage === totalPages ? "Completed" : parsed.data.status;
  const supabase = await createClient();
  const { error } = await supabase.from("books").update({
    current_page: currentPage,
    status,
    date_completed: status === "Completed" ? new Date().toISOString() : null,
  }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/app");
  revalidatePath("/app/library");
  revalidatePath(`/app/books/${id}`);
  return { success: true };
}
