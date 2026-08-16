"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const schema = z.object({ id: z.string().uuid().optional(), bookId: z.string().uuid(), text: z.string().trim().min(1).max(10000) });
export async function saveQuote(formData: FormData) {
  const input = Object.fromEntries(formData); if (!input.id) delete input.id;
  const parsed = schema.safeParse(input); if (!parsed.success) return;
  const supabase = await createClient();
  if (parsed.data.id) await supabase.from("quotes").update({ book_id: parsed.data.bookId, text: parsed.data.text }).eq("id", parsed.data.id);
  else await supabase.from("quotes").insert({ book_id: parsed.data.bookId, text: parsed.data.text });
  revalidatePath("/app/quotes");
}
export async function deleteQuote(formData: FormData) {
  const id = z.string().uuid().safeParse(formData.get("id")); if (!id.success) return;
  const supabase = await createClient(); await supabase.from("quotes").delete().eq("id", id.data); revalidatePath("/app/quotes");
}
