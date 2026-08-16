import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
export async function GET() {
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const tables = ["profiles", "books", "reading_sessions", "session_notes", "quotes", "streak_freezes", "user_stats"] as const;
  const entries = await Promise.all(tables.map(async (table) => [table, (await supabase.from(table).select("*")).data ?? []] as const));
  const response = NextResponse.json({ exported_at: new Date().toISOString(), account: { id: user.id, email: user.email }, data: Object.fromEntries(entries) });
  response.headers.set("Content-Disposition", `attachment; filename="pageflow-export-${new Date().toISOString().slice(0, 10)}.json"`);
  response.headers.set("Cache-Control", "private, no-cache, no-store, must-revalidate"); return response;
}
