"use client";

import { ArrowLeft, ArrowRight, Check, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const moods = ["Cozy", "Intense", "Reflective", "Fun", "Dark", "Adventurous", "Emotional", "Mind-bending"];
const prompt = "What thought, image, or feeling stayed with you?";
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
      p_reflection_prompt: draft.reflection.trim() ? prompt : null,
      p_reflection_text: draft.reflection.trim() || null,
      p_note_title: noteTitle,
      p_note_content: draft.noteContent.trim() || null,
      p_note_tags: tags,
      p_chapter_reference: draft.chapter.trim() || null,
      p_quote_text: draft.quote.trim() || null,
    });
    if (rpcError) setError(rpcError.message);
    else {
      localStorage.removeItem(storageKey);
      setXp(Number(data?.[0]?.xp_earned ?? 5));
      router.refresh();
    }
    setSaving(false);
  }

  if (xp !== undefined) return <div className="glass-card mx-auto max-w-2xl rounded-3xl p-8 text-center"><Sparkles className="mx-auto text-accent-light" size={40} /><p className="mt-4 font-display text-3xl">Session saved.</p><p className="mt-2 text-secondary">Your reflection earned <strong className="text-white">{xp} XP</strong>.</p><button className="primary-button mt-6" onClick={onDiscard}>Done</button></div>;

  return <div className="glass-card mx-auto max-w-2xl rounded-3xl p-5 sm:p-8">
    <div className="mb-6 flex items-center justify-between"><div><p className="text-xs font-bold uppercase tracking-[.16em] text-accent-light">Reading journal</p><h2 className="font-display text-2xl">Capture the moment.</h2></div><span className="text-sm text-muted">{draft.stage} / 3</span></div>
    <div aria-hidden="true" className="mb-7 grid grid-cols-3 gap-2">{[1, 2, 3].map((stage) => <span className={`h-1.5 rounded-full ${stage <= draft.stage ? "bg-accent-light" : "bg-white/10"}`} key={stage} />)}</div>
    {draft.stage === 1 ? <section className="space-y-6"><div><h3 className="font-semibold">How did this reading feel?</h3><div className="mt-3 flex flex-wrap gap-2">{moods.map((mood) => <button aria-pressed={draft.moodTags.includes(mood)} className={`min-h-11 rounded-full border px-4 text-sm ${draft.moodTags.includes(mood) ? "border-accent bg-accent/20 text-accent-light" : "border-[var(--border)] text-secondary"}`} key={mood} onClick={() => toggleMood(mood)} type="button">{mood}</button>)}</div></div><TextArea label={prompt} onChange={(value) => update({ reflection: value })} value={draft.reflection} /></section> : null}
    {draft.stage === 2 ? <section className="space-y-4"><p className="text-sm text-secondary">Save a note, or leave everything blank to skip this stage.</p><Field label="Note title" onChange={(value) => update({ noteTitle: value })} value={draft.noteTitle} /><TextArea label="Note" onChange={(value) => update({ noteContent: value })} value={draft.noteContent} /><div className="grid gap-4 sm:grid-cols-2"><Field label="Chapter or page" onChange={(value) => update({ chapter: value })} value={draft.chapter} /><Field label="Tags (comma separated)" onChange={(value) => update({ noteTags: value })} value={draft.noteTags} /></div></section> : null}
    {draft.stage === 3 ? <section className="space-y-4"><p className="text-sm text-secondary">Keep one line worth returning to. This stage is optional.</p><TextArea label="Quote" onChange={(value) => update({ quote: value })} value={draft.quote} /></section> : null}
    {error ? <p className="mt-5 rounded-xl border border-danger/30 bg-danger/10 p-3 text-sm text-red-200" role="alert">{error}</p> : null}
    <div className="mt-7 flex gap-3">{draft.stage > 1 ? <button className="secondary-button flex-1" onClick={() => update({ stage: draft.stage - 1 })}><ArrowLeft size={18} />Back</button> : <button className="secondary-button flex-1" onClick={() => { localStorage.removeItem(storageKey); onDiscard(); }}>Discard</button>}{draft.stage < 3 ? <button className="primary-button flex-1" onClick={() => update({ stage: draft.stage + 1 })}>Next<ArrowRight size={18} /></button> : <button className="primary-button flex-1" disabled={saving} onClick={finalize}>{saving ? "Saving…" : <><Check size={18} />Save session</>}</button>}</div>
  </div>;
}

function Field({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) { return <label className="block"><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">{label}</span><input className="min-h-12 w-full rounded-xl border border-[var(--border)] bg-black/20 px-4" onChange={(event) => onChange(event.target.value)} value={value} /></label>; }
function TextArea({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) { return <label className="block"><span className="mb-2 block text-xs uppercase tracking-[.12em] text-muted">{label}</span><textarea className="min-h-28 w-full resize-y rounded-xl border border-[var(--border)] bg-black/20 p-4" maxLength={10000} onChange={(event) => onChange(event.target.value)} value={value} /></label>; }
