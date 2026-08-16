import { Download } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { PasswordRecoveryForm } from "@/components/auth/password-recovery-form";
import { DeleteAccount } from "@/components/settings/delete-account";
import { createClient } from "@/lib/supabase/server";
import { updateProfile } from "./actions";
export default async function SettingsPage() {
  const supabase = await createClient(); const { data: { user } } = await supabase.auth.getUser(); const { data: profile } = await supabase.from("profiles").select("display_name,time_zone").eq("id", user!.id).maybeSingle();
  return <><PageHeading eyebrow="Your account" title="Settings" description={user?.email} /><div className="grid gap-6 xl:grid-cols-2"><SettingsCard title="Profile"><form action={updateProfile} className="space-y-4"><Field defaultValue={profile?.display_name ?? ""} label="Display name" name="displayName" /><Field defaultValue={profile?.time_zone ?? "UTC"} label="IANA time zone" name="timeZone" required /><button className="primary-button w-full">Save profile</button></form></SettingsCard><SettingsCard title="Change password"><PasswordRecoveryForm mode="reset" /></SettingsCard><SettingsCard title="Export your data"><p className="mb-4 text-sm leading-6 text-secondary">Download a portable JSON copy of all PageFlow data connected to your account.</p><a className="secondary-button w-full" download href="/api/export"><Download size={18} />Download JSON export</a></SettingsCard><SettingsCard danger title="Delete account"><DeleteAccount /></SettingsCard></div></>;
}
function SettingsCard({ title, children, danger }: { title: string; children: React.ReactNode; danger?: boolean }) { return <section className={`glass-card rounded-2xl p-5 ${danger ? "border-danger/30" : ""}`}><h2 className={`mb-4 font-display text-2xl ${danger ? "text-red-100" : ""}`}>{title}</h2>{children}</section>; }
function Field({ label, ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) { return <label><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">{label}</span><input className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4" {...props} /></label>; }
