import { createClient } from "https://esm.sh/@supabase/supabase-js@2.112.3";
const headers = { "Content-Type": "application/json", "Cache-Control": "no-store" };
Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers });
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, ""); if (!token) return new Response(JSON.stringify({ error: "Authentication required" }), { status: 401, headers });
  const url = Deno.env.get("SUPABASE_URL")!; const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!; const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const verifier = createClient(url, anonKey, { global: { headers: { Authorization: `Bearer ${token}` } }, auth: { persistSession: false } }); const { data: { user }, error } = await verifier.auth.getUser(token);
  if (error || !user) return new Response(JSON.stringify({ error: "Invalid session" }), { status: 401, headers });
  const admin = createClient(url, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } }); await admin.auth.admin.signOut(token, "global"); const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) return new Response(JSON.stringify({ error: "Account deletion failed" }), { status: 500, headers });
  return new Response(JSON.stringify({ deleted: true }), { status: 200, headers });
});
