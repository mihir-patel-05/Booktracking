import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

function safeDestination(value: string | null) {
  return value?.startsWith("/") && !value.startsWith("//") ? value : "/app";
}

export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const destination = safeDestination(url.searchParams.get("next"));

  if (!code) return NextResponse.redirect(new URL("/login?error=missing_code", url.origin));

  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return NextResponse.redirect(new URL("/login?error=callback_failed", url.origin));

  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const metadata = user.user_metadata;
    await supabase.from("profiles").upsert({
      id: user.id,
      display_name: String(metadata.display_name ?? metadata.full_name ?? metadata.name ?? "").slice(0, 80),
      avatar_url: typeof metadata.avatar_url === "string" ? metadata.avatar_url.slice(0, 2048) : null,
      time_zone: typeof metadata.time_zone === "string" ? metadata.time_zone.slice(0, 64) : "UTC",
    }, { onConflict: "id", ignoreDuplicates: true });
  }

  const response = NextResponse.redirect(new URL(destination, url.origin));
  response.headers.set("Cache-Control", "private, no-cache, no-store, must-revalidate, max-age=0");
  return response;
}
