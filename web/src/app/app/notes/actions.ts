"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({
  id: z.string().uuid().optional(), bookId: z.string().uuid(),
  title: z.string().trim().min(1).max(200), content: z.string().max(50000),
  tags: z.string().max(500), chapter: z.string().trim().max(200),
});

export async function saveNote(formData: FormData) {
  const input = Object.fromEntries(formData);
  if (!input.id) delete input.id;
  const parsed = schema.safeParse(input);
  if (!parsed.success) return;
  const note = { book_id: parsed.data.bookId, title: parsed.data.title, content: parsed.data.content, tags: parsed.data.tags.split(",").map((tag) => tag.trim()).filter(Boolean).slice(0, 30), chapter_reference: parsed.data.chapter || null };
  const supabase = await createClient();
  if (parsed.data.id) await supabase.from("session_notes").update(note).eq("id", parsed.data.id);
  else await supabase.from("session_notes").insert(note);
  revalidatePath("/app/notes");
}

export async function deleteNote(formData: FormData) {
  const id = z.string().uuid().safeParse(formData.get("id"));
  if (!id.success) return;
  const supabase = await createClient();
  await supabase.from("session_notes").delete().eq("id", id.data);
  revalidatePath("/app/notes");
}
