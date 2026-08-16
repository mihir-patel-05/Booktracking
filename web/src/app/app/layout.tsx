import { redirect } from "next/navigation";
import { AppShell } from "@/components/app/app-shell";
import { hasSupabaseConfig } from "@/lib/supabase/env";
import { createClient } from "@/lib/supabase/server";

export default async function ProtectedLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  if (!hasSupabaseConfig()) redirect("/login?error=configuration");

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase.from("profiles").select("display_name").eq("id", user.id).maybeSingle();
  const displayName = profile?.display_name || String(user.user_metadata.display_name ?? user.user_metadata.full_name ?? "");
  return <AppShell displayName={displayName}>{children}</AppShell>;
}
