import { TimerPageClient } from "./timer-page";
import { createClient } from "@/lib/supabase/server";

export default async function TimerPage({ searchParams }: { searchParams: Promise<{ book?: string }> }) {
  const [{ book: initialBookId }, supabase] = await Promise.all([searchParams, createClient()]);
  const [{ data: { user } }, { data: books }] = await Promise.all([
    supabase.auth.getUser(),
    supabase.from("books").select("id,title,author").neq("status", "Abandoned").order("updated_at", { ascending: false }),
  ]);
  return <TimerPageClient books={books ?? []} initialBookId={initialBookId} userId={user!.id} />;
}
