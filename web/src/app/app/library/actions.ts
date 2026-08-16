"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const bookSchema = z.object({
  title: z.string().trim().min(1).max(300),
  author: z.string().trim().min(1).max(200),
  totalPages: z.coerce.number().int().min(1).max(100000),
  coverUrl: z.string().url().max(2048).or(z.literal("")),
});

export type BookActionState = { error?: string; success?: boolean };

export async function createBook(_: BookActionState, formData: FormData): Promise<BookActionState> {
  const parsed = bookSchema.safeParse({
    title: formData.get("title"), author: formData.get("author"),
    totalPages: formData.get("totalPages"), coverUrl: formData.get("coverUrl") ?? "",
  });
  if (!parsed.success) return { error: parsed.error.issues[0]?.message ?? "Check the book details." };

  const supabase = await createClient();
  const { error } = await supabase.from("books").insert({
    title: parsed.data.title,
    author: parsed.data.author,
    total_pages: parsed.data.totalPages,
    cover_url: parsed.data.coverUrl || null,
  });
  if (error) return { error: error.message };
  revalidatePath("/app");
  revalidatePath("/app/library");
  return { success: true };
}

export async function deleteBook(formData: FormData) {
  const id = z.string().uuid().safeParse(formData.get("id"));
  if (!id.success) return;
  const supabase = await createClient();
  await supabase.from("books").delete().eq("id", id.data);
  revalidatePath("/app");
  revalidatePath("/app/library");
}
