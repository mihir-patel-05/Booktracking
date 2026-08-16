create table public.streak_freezes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  missed_date date not null,
  month_start date not null,
  created_at timestamptz not null default now(),
  unique (user_id, missed_date),
  check (month_start = date_trunc('month', missed_date)::date)
);

create table public.user_stats (
  user_id uuid primary key references auth.users(id) on delete cascade,
  total_xp integer not null default 0 check (total_xp >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  longest_streak integer not null default 0 check (longest_streak >= 0),
  last_session_date date,
  total_sessions integer not null default 0 check (total_sessions >= 0),
  total_seconds bigint not null default 0 check (total_seconds >= 0),
  updated_at timestamptz not null default now()
);

create index streak_freezes_user_month_idx on public.streak_freezes (user_id, month_start);

alter table public.streak_freezes enable row level security;
alter table public.user_stats enable row level security;

revoke all on table public.streak_freezes from public, anon, authenticated;
revoke all on table public.user_stats from public, anon, authenticated;
grant select on table public.streak_freezes to authenticated;
grant select on table public.user_stats to authenticated;

create policy streak_freezes_select_own on public.streak_freezes
for select to authenticated using ((select auth.uid()) = user_id);
create policy user_stats_select_own on public.user_stats
for select to authenticated using ((select auth.uid()) = user_id);

create or replace function private.refresh_user_stats(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_date date;
  v_previous_date date;
  v_missed_date date;
  v_gap integer;
  v_month_freezes integer;
  v_current_streak integer := 0;
  v_longest_streak integer := 0;
  v_total_xp integer := 0;
  v_total_sessions integer := 0;
  v_total_seconds bigint := 0;
  v_last_session_date date;
begin
  delete from public.streak_freezes where user_id = p_user_id;

  for v_date in
    select distinct session_local_date
    from public.reading_sessions
    where user_id = p_user_id
    order by session_local_date
  loop
    if v_previous_date is null then
      v_current_streak := 1;
    else
      v_gap := v_date - v_previous_date;
      if v_gap = 1 then
        v_current_streak := v_current_streak + 1;
      elsif v_gap = 2 then
        v_missed_date := v_previous_date + 1;
        select count(*)::integer into v_month_freezes
        from public.streak_freezes
        where user_id = p_user_id
          and month_start = date_trunc('month', v_missed_date)::date;

        if v_month_freezes < 2 then
          insert into public.streak_freezes (user_id, missed_date, month_start)
          values (p_user_id, v_missed_date, date_trunc('month', v_missed_date)::date)
          on conflict (user_id, missed_date) do nothing;
          v_current_streak := v_current_streak + 2;
        else
          v_current_streak := 1;
        end if;
      else
        v_current_streak := 1;
      end if;
    end if;

    v_longest_streak := greatest(v_longest_streak, v_current_streak);
    v_previous_date := v_date;
  end loop;

  select
    coalesce(sum(xp_earned), 0)::integer,
    count(*)::integer,
    coalesce(sum(duration_seconds), 0)::bigint,
    max(session_local_date)
  into v_total_xp, v_total_sessions, v_total_seconds, v_last_session_date
  from public.reading_sessions
  where user_id = p_user_id;

  insert into public.user_stats (
    user_id,
    total_xp,
    current_streak,
    longest_streak,
    last_session_date,
    total_sessions,
    total_seconds,
    updated_at
  )
  values (
    p_user_id,
    v_total_xp,
    v_current_streak,
    v_longest_streak,
    v_last_session_date,
    v_total_sessions,
    v_total_seconds,
    now()
  )
  on conflict (user_id) do update set
    total_xp = excluded.total_xp,
    current_streak = excluded.current_streak,
    longest_streak = excluded.longest_streak,
    last_session_date = excluded.last_session_date,
    total_sessions = excluded.total_sessions,
    total_seconds = excluded.total_seconds,
    updated_at = excluded.updated_at;
end;
$$;

create or replace function private.set_session_xp()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_has_note boolean := false;
  v_has_quote boolean := false;
begin
  if tg_op = 'UPDATE' then
    select exists (
      select 1 from public.session_notes
      where session_id = new.id and user_id = new.user_id
    ) into v_has_note;
    select exists (
      select 1 from public.quotes
      where session_id = new.id and user_id = new.user_id
    ) into v_has_quote;
  end if;

  new.xp_earned := least(
    25,
    5
    + case when cardinality(new.mood_tags) > 0 then 5 else 0 end
    + case when nullif(btrim(new.reflection_text), '') is not null then 5 else 0 end
    + case when v_has_note then 5 else 0 end
    + case when v_has_quote then 5 else 0 end
  );
  return new;
end;
$$;

create or replace function private.refresh_session_xp(p_session_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  update public.reading_sessions
  set updated_at = now()
  where id = p_session_id and user_id = p_user_id;
end;
$$;

create or replace function private.after_session_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  perform private.refresh_user_stats(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

create or replace function private.after_session_child_change()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
begin
  if tg_op in ('DELETE', 'UPDATE') and old.session_id is not null then
    perform private.refresh_session_xp(old.session_id, old.user_id);
    perform private.refresh_user_stats(old.user_id);
  end if;

  if tg_op in ('INSERT', 'UPDATE') and new.session_id is not null then
    if tg_op <> 'UPDATE' or new.session_id is distinct from old.session_id then
      perform private.refresh_session_xp(new.session_id, new.user_id);
      perform private.refresh_user_stats(new.user_id);
    end if;
  end if;

  return coalesce(new, old);
end;
$$;

revoke all on function private.refresh_user_stats(uuid) from public, anon, authenticated;
revoke all on function private.set_session_xp() from public, anon, authenticated;
revoke all on function private.refresh_session_xp(uuid, uuid) from public, anon, authenticated;
revoke all on function private.after_session_change() from public, anon, authenticated;
revoke all on function private.after_session_child_change() from public, anon, authenticated;

create trigger reading_sessions_set_xp
before insert or update on public.reading_sessions
for each row execute function private.set_session_xp();

create trigger reading_sessions_refresh_stats
after insert or update or delete on public.reading_sessions
for each row execute function private.after_session_change();

create trigger session_notes_refresh_xp
after insert or update or delete on public.session_notes
for each row execute function private.after_session_child_change();

create trigger quotes_refresh_xp
after insert or update or delete on public.quotes
for each row execute function private.after_session_child_change();

create or replace function public.finalize_reading_session(
  p_book_id uuid,
  p_duration_seconds integer,
  p_started_at timestamptz default now(),
  p_time_zone text default 'UTC',
  p_mood_tags text[] default '{}',
  p_reflection_prompt text default null,
  p_reflection_text text default null,
  p_note_title text default null,
  p_note_content text default null,
  p_note_tags text[] default '{}',
  p_chapter_reference text default null,
  p_quote_text text default null
)
returns table (session_id uuid, xp_earned integer)
language plpgsql
security invoker
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = p_time_zone) then
    raise exception 'Invalid time zone' using errcode = '22023';
  end if;

  perform 1 from public.books where id = p_book_id and user_id = v_user_id;
  if not found then
    raise exception 'Book not found' using errcode = 'P0002';
  end if;

  insert into public.reading_sessions (
    user_id,
    book_id,
    started_at,
    ended_at,
    duration_seconds,
    session_local_date,
    time_zone,
    mood_tags,
    reflection_prompt,
    reflection_text
  ) values (
    v_user_id,
    p_book_id,
    p_started_at,
    p_started_at + make_interval(secs => p_duration_seconds),
    p_duration_seconds,
    (p_started_at at time zone p_time_zone)::date,
    p_time_zone,
    coalesce(p_mood_tags, '{}'),
    nullif(btrim(p_reflection_prompt), ''),
    nullif(btrim(p_reflection_text), '')
  ) returning id into v_session_id;

  if nullif(btrim(p_note_title), '') is not null then
    insert into public.session_notes (
      user_id, book_id, session_id, title, content, tags, chapter_reference
    ) values (
      v_user_id,
      p_book_id,
      v_session_id,
      btrim(p_note_title),
      coalesce(p_note_content, ''),
      coalesce(p_note_tags, '{}'),
      nullif(btrim(p_chapter_reference), '')
    );
  end if;

  if nullif(btrim(p_quote_text), '') is not null then
    insert into public.quotes (user_id, book_id, session_id, text)
    values (v_user_id, p_book_id, v_session_id, btrim(p_quote_text));
  end if;

  return query
  select reading_sessions.id, reading_sessions.xp_earned
  from public.reading_sessions
  where reading_sessions.id = v_session_id;
end;
$$;

revoke all on function public.finalize_reading_session(
  uuid, integer, timestamptz, text, text[], text, text, text, text, text[], text, text
) from public, anon;
grant execute on function public.finalize_reading_session(
  uuid, integer, timestamptz, text, text[], text, text, text, text, text[], text, text
) to authenticated;
