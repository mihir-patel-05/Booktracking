create table public.reading_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book_id uuid not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds integer not null check (duration_seconds between 1 and 64800),
  session_local_date date not null,
  time_zone text not null check (char_length(time_zone) between 1 and 64),
  mood_tags text[] not null default '{}'
    check (
      mood_tags <@ array['Cozy', 'Intense', 'Reflective', 'Fun', 'Dark', 'Adventurous', 'Emotional', 'Mind-bending']::text[]
      and cardinality(mood_tags) <= 8
    ),
  reflection_prompt text check (reflection_prompt is null or char_length(reflection_prompt) <= 500),
  reflection_text text check (reflection_text is null or char_length(reflection_text) <= 10000),
  xp_earned integer not null default 0 check (xp_earned between 0 and 25),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  constraint reading_sessions_book_owner_fk
    foreign key (book_id, user_id)
    references public.books(id, user_id)
    on delete cascade
);

create table public.session_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book_id uuid not null,
  session_id uuid,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  content text not null default '' check (char_length(content) <= 50000),
  tags text[] not null default '{}' check (cardinality(tags) <= 30),
  chapter_reference text check (chapter_reference is null or char_length(chapter_reference) <= 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint session_notes_book_owner_fk
    foreign key (book_id, user_id)
    references public.books(id, user_id)
    on delete cascade,
  constraint session_notes_session_owner_fk
    foreign key (session_id, user_id)
    references public.reading_sessions(id, user_id)
    on delete set null (session_id)
);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book_id uuid not null,
  session_id uuid,
  text text not null check (char_length(btrim(text)) between 1 and 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quotes_book_owner_fk
    foreign key (book_id, user_id)
    references public.books(id, user_id)
    on delete cascade,
  constraint quotes_session_owner_fk
    foreign key (session_id, user_id)
    references public.reading_sessions(id, user_id)
    on delete set null (session_id)
);

create trigger reading_sessions_set_updated_at
before update on public.reading_sessions
for each row execute function private.set_updated_at();

create trigger session_notes_set_updated_at
before update on public.session_notes
for each row execute function private.set_updated_at();

create trigger quotes_set_updated_at
before update on public.quotes
for each row execute function private.set_updated_at();

create index reading_sessions_user_started_idx on public.reading_sessions (user_id, started_at desc);
create index reading_sessions_user_local_date_idx on public.reading_sessions (user_id, session_local_date desc);
create index reading_sessions_book_idx on public.reading_sessions (book_id, started_at desc);
create index reading_sessions_mood_tags_idx on public.reading_sessions using gin (mood_tags);
create index session_notes_user_created_idx on public.session_notes (user_id, created_at desc);
create index session_notes_book_idx on public.session_notes (book_id, created_at desc);
create index session_notes_session_idx on public.session_notes (session_id) where session_id is not null;
create index session_notes_tags_idx on public.session_notes using gin (tags);
create index quotes_user_created_idx on public.quotes (user_id, created_at desc);
create index quotes_book_idx on public.quotes (book_id, created_at desc);
create index quotes_session_idx on public.quotes (session_id) where session_id is not null;

alter table public.reading_sessions enable row level security;
alter table public.session_notes enable row level security;
alter table public.quotes enable row level security;

revoke all on table public.reading_sessions from public, anon, authenticated;
revoke all on table public.session_notes from public, anon, authenticated;
revoke all on table public.quotes from public, anon, authenticated;

grant select, insert, update, delete on table public.reading_sessions to authenticated;
grant select, insert, update, delete on table public.session_notes to authenticated;
grant select, insert, update, delete on table public.quotes to authenticated;

create policy reading_sessions_select_own on public.reading_sessions
for select to authenticated using ((select auth.uid()) = user_id);
create policy reading_sessions_insert_own on public.reading_sessions
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy reading_sessions_update_own on public.reading_sessions
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy reading_sessions_delete_own on public.reading_sessions
for delete to authenticated using ((select auth.uid()) = user_id);

create policy session_notes_select_own on public.session_notes
for select to authenticated using ((select auth.uid()) = user_id);
create policy session_notes_insert_own on public.session_notes
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy session_notes_update_own on public.session_notes
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy session_notes_delete_own on public.session_notes
for delete to authenticated using ((select auth.uid()) = user_id);

create policy quotes_select_own on public.quotes
for select to authenticated using ((select auth.uid()) = user_id);
create policy quotes_insert_own on public.quotes
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy quotes_update_own on public.quotes
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy quotes_delete_own on public.quotes
for delete to authenticated using ((select auth.uid()) = user_id);
