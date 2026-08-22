"use client";

import { ArrowLeft, ArrowRight, Check } from "lucide-react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { roman } from "@/lib/format";
import { createClient } from "@/lib/supabase/client";

const moods = ["Reflective", "Cozy", "Dark", "Intense", "Fun", "Adventurous", "Emotional", "Mind-bending"];
const prompt = "What thought, image, or feeling stayed with you?";
const stages = ["Mood & reflection", "A note", "A line to keep"];

type Session = { bookId: string; startedAt: string; durationSeconds: number };
type Draft = { session: Session; stage: number; moodTags: string[]; reflection: string; noteTitle: string; noteContent: string; noteTags: string; chapter: string; quote: string };

function freshDraft(session: Session): Draft {
  return { session, stage: 1, moodTags: [], reflection: "", noteTitle: "", noteContent: "", noteTags: "", chapter: "", quote: "" };
}

export function JournalFlow({ session, userId, onDiscard }: { session: Session; userId: string; onDiscard: () => void }) {
  const router = useRouter();
  const storageKey = `pageflow:journal-draft:${userId}`;
  const [draft, setDraft] = useState(() => freshDraft(session));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const [xp, setXp] = useState<number>();

  useEffect(() => {
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved) as Draft;
        if (parsed.session.bookId === session.bookId && parsed.session.startedAt === session.startedAt) setDraft(parsed);
      }
    } catch { localStorage.removeItem(storageKey); }
  }, [session.bookId, session.startedAt, storageKey]);

  useEffect(() => { if (xp === undefined) localStorage.setItem(storageKey, JSON.stringify(draft)); }, [draft, storageKey, xp]);

  function update(patch: Partial<Draft>) { setDraft((current) => ({ ...current, ...patch })); }
  function toggleMood(mood: string) { update({ moodTags: draft.moodTags.includes(mood) ? draft.moodTags.filter((item) => item !== mood) : [...draft.moodTags, mood] }); }

  async function finalize() {
    setSaving(true);
    setError(undefined);
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
    const tags = draft.noteTags.split(",").map((tag) => tag.trim()).filter(Boolean).slice(0, 30);
    const noteTitle = draft.noteTitle.trim() || (draft.noteContent.trim() ? "Reading note" : null);
    const { data, error: rpcError } = await createClient().rpc("finalize_reading_session", {
      p_book_id: draft.session.bookId,
      p_duration_seconds: draft.session.durationSeconds,
      p_started_at: draft.session.startedAt,
      p_time_zone: timeZone,
      p_mood_tags: draft.moodTags,
      p_reflection_prompt: draft.reflection.trim() ? prompt : undefined,
      p_reflection_text: draft.reflection.trim() || undefined,
      p_note_title: noteTitle ?? undefined,
      p_note_content: draft.noteContent.trim() || undefined,
      p_note_tags: tags,
      p_chapter_reference: draft.chapter.trim() || undefined,
      p_quote_text: draft.quote.trim() || undefined,
    });
    if (rpcError) setError(rpcError.message);
    else {
      localStorage.removeItem(storageKey);
      setXp(Number(data?.[0]?.xp_earned ?? 5));
      router.refresh();
    }
    setSaving(false);
  }

  const sittingMinutes = Math.round(session.durationSeconds / 60);

  if (xp !== undefined) {
    return (
      <div className="mx-auto max-w-[840px] border-y border-line py-14 text-center">
        <p className="eyebrow tracking-[.24em]">The sitting is entered</p>
        <p className="mt-4 font-display text-[44px] leading-tight tracking-[-.02em]">The book is closed.</p>
        <p className="tnum mt-3 text-sm text-muted">This sitting earned <span className="text-gold-text">{xp} XP</span>.</p>
        <button className="btn btn-primary mt-7" onClick={onDiscard} type="button">Done</button>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-[840px]">
      <div className="flex items-end justify-between gap-6 border-b border-line pb-6">
        <div>
          <p className="eyebrow tracking-[.22em]">Sitting recorded · {sittingMinutes} minutes</p>
          <h2 className="mt-3.5 font-display text-[32px] leading-tight tracking-[-.02em] sm:text-[44px]">Before you close the book.</h2>
        </div>
        <div className="shrink-0 text-right">
          <p className="text-[9.5px] uppercase tracking-[.16em] text-muted">Stage</p>
          <p className="tnum font-display text-[26px]">{roman(draft.stage)} / III</p>
        </div>
      </div>

      <div aria-hidden="true" className="mt-3.5 grid grid-cols-3 gap-2">
        {[1, 2, 3].map((stage) => <span className={`h-0.5 ${stage <= draft.stage ? "bg-gold" : "bg-line"}`} key={stage} />)}
      </div>
      <div className="mt-2 grid grid-cols-3 gap-2 text-[10px] uppercase tracking-[.14em] text-faint">
        {stages.map((label, index) => <span className={index + 1 === draft.stage ? "text-gold-text" : undefined} key={label}>{label}</span>)}
      </div>

      {draft.stage === 1 ? (
        <>
          <section className="mt-10">
            <h3 className="font-display text-[25px]">How did this reading feel?</h3>
            <p className="mb-4 mt-1 text-[13px] text-muted">Choose as many as are true. These become the pattern on your Record.</p>
            <div className="flex flex-wrap gap-2.5">
              {moods.map((mood) => {
                const on = draft.moodTags.includes(mood);
                return (
                  <button aria-pressed={on} className={`btn ${on ? "btn-primary bg-[var(--gold-tint)]" : "btn-secondary"}`} key={mood} onClick={() => toggleMood(mood)} type="button">{mood}</button>
                );
              })}
            </div>
          </section>
          <section className="mt-10 border-t border-line pt-8">
            <h3 className="font-display text-[25px]">{prompt}</h3>
            <p className="mb-4 mt-1 text-[13px] text-muted">Two sentences is plenty. Nobody else reads this.</p>
            <Reflection label={prompt} onChange={(value) => update({ reflection: value })} value={draft.reflection} />
          </section>
        </>
      ) : null}

      {draft.stage === 2 ? (
        <section className="mt-10">
          <h3 className="font-display text-[25px]">Anything worth writing in the margin?</h3>
          <p className="mb-5 mt-1 text-[13px] text-muted">Leave it all blank to pass this stage by.</p>
          <div className="grid gap-5">
            <Field label="Title of the note" onChange={(value) => update({ noteTitle: value })} value={draft.noteTitle} />
            <TextArea label="The note" onChange={(value) => update({ noteContent: value })} value={draft.noteContent} />
            <div className="grid gap-5 sm:grid-cols-2">
              <Field label="Chapter or page" onChange={(value) => update({ chapter: value })} value={draft.chapter} />
              <Field label="Tags, comma separated" onChange={(value) => update({ noteTags: value })} value={draft.noteTags} />
            </div>
          </div>
        </section>
      ) : null}

      {draft.stage === 3 ? (
        <section className="mt-10">
          <h3 className="font-display text-[25px]">Any line you want copied out?</h3>
          <p className="mb-5 mt-1 text-[13px] text-muted">One line worth returning to. This stage is optional.</p>
          <Reflection label="A line to keep" onChange={(value) => update({ quote: value })} value={draft.quote} />
        </section>
      ) : null}

      {error ? <p className="mt-6 border border-[var(--danger)] px-4 py-3 text-sm text-[var(--danger)]" role="alert">{error}</p> : null}

      <div className="mt-10 flex flex-wrap items-center justify-between gap-4 border-t border-line pt-6">
        {draft.stage > 1 ? (
          <button className="btn btn-secondary" onClick={() => update({ stage: draft.stage - 1 })} type="button"><ArrowLeft size={15} strokeWidth={1.5} />Back</button>
        ) : (
          <button className="btn btn-secondary" onClick={() => { localStorage.removeItem(storageKey); onDiscard(); }} type="button">Discard this sitting</button>
        )}
        <div className="flex items-center gap-4">
          <span className="text-xs text-faint">Draft kept as you go</span>
          {draft.stage < 3 ? (
            <button className="btn btn-primary" onClick={() => update({ stage: draft.stage + 1 })} type="button">
              Next — {stages[draft.stage]}<ArrowRight size={15} strokeWidth={1.5} />
            </button>
          ) : (
            <button className="btn btn-primary" disabled={saving} onClick={finalize} type="button">
              {saving ? "Entering…" : <><Check size={15} strokeWidth={1.5} />Enter the sitting</>}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function Field({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <input className="input" onChange={(event) => onChange(event.target.value)} value={value} />
    </label>
  );
}

function TextArea({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <textarea className="input" maxLength={10000} onChange={(event) => onChange(event.target.value)} value={value} />
    </label>
  );
}

/** The long answers are set on a plate, in the display face, as the design has them. */
function Reflection({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <div className="plate plate-filled px-6 py-5">
      <textarea
        aria-label={label}
        className="w-full resize-y border-0 bg-transparent p-0 font-display text-[22px] leading-[1.5] outline-none"
        maxLength={10000}
        onChange={(event) => onChange(event.target.value)}
        rows={4}
        value={value}
      />
      <p className="tnum mt-3.5 text-right text-[11px] text-faint">{value.length} characters</p>
    </div>
  );
}
