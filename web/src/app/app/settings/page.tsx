import { cookies } from "next/headers";
import { Download } from "lucide-react";
import { PageHeading } from "@/components/app/page-heading";
import { PasswordRecoveryForm } from "@/components/auth/password-recovery-form";
import { DeleteAccount } from "@/components/settings/delete-account";
import { ThemePicker } from "@/components/settings/theme-picker";
import { isTheme, THEME_COOKIE } from "@/lib/theme";
import { createClient } from "@/lib/supabase/server";
import { updateProfile } from "./actions";

export default async function SettingsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const { data: profile } = await supabase.from("profiles").select("display_name,time_zone").eq("id", user!.id).maybeSingle();

  const chosen = (await cookies()).get(THEME_COOKIE)?.value;
  const theme = isTheme(chosen) ? chosen : "system";

  return (
    <>
      <PageHeading description={user?.email} eyebrow="Your account" title="Settings" />

      <section>
        <h2 className="font-display text-[30px]">The light you read by</h2>
        <p className="mb-7 mt-1.5 max-w-[56ch] text-sm text-muted">
          Paper for the daytime; Night for the small hours, when a bright page is the enemy of a long sitting.
        </p>
        <ThemePicker current={theme} />
        <p className="mt-4 text-xs leading-6 text-faint">The choice is kept on this device.</p>
      </section>

      <div className="mt-12 grid gap-12 border-t border-line pt-10 xl:grid-cols-2 xl:gap-14">
        <Panel title="Profile">
          <form action={updateProfile} className="grid gap-5">
            <Field defaultValue={profile?.display_name ?? ""} label="Name" name="displayName" />
            <Field defaultValue={profile?.time_zone ?? "UTC"} label="IANA time zone" name="timeZone" required />
            <button className="btn btn-primary btn-block" type="submit">Save profile</button>
          </form>
        </Panel>

        <Panel title="Change password">
          <PasswordRecoveryForm mode="reset" />
        </Panel>

        <Panel note="A portable JSON copy of everything connected to your account." title="Export your data">
          <a className="btn btn-secondary btn-block" download href="/api/export">
            <Download size={15} strokeWidth={1.5} />Download JSON export
          </a>
        </Panel>

        <Panel title="Delete account">
          <DeleteAccount />
        </Panel>
      </div>
    </>
  );
}

function Panel({ title, note, children }: { title: string; note?: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="font-display text-[26px]">{title}</h2>
      {note ? <p className="mt-1 text-[12.5px] text-muted">{note}</p> : null}
      <div className="mt-5">{children}</div>
    </section>
  );
}

function Field({ label, ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <input className="input" {...props} />
    </label>
  );
}
