-- A goal says how many finished volumes a reader means to complete. Overall
-- goals count across one date range; monthly goals repeat the target in each
-- calendar month while the goal is active.

create table public.reading_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  target_books integer not null check (target_books between 1 and 10000),
  cadence text not null default 'overall'
    check (cadence in ('overall', 'monthly')),
  starts_on date not null,
  ends_on date,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  constraint reading_goals_dates_in_order
    check (ends_on is null or ends_on >= starts_on),
  constraint reading_goals_overall_has_end
    check (cadence = 'monthly' or ends_on is not null)
);

-- Membership is explicit: a finished book can count toward more than one goal,
-- and removing it from a goal never changes the book itself.
create table public.reading_goal_books (
  goal_id uuid not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book_id uuid not null,
  completed_on date not null default ((now() at time zone 'utc')::date),
  added_at timestamptz not null default now(),
  primary key (goal_id, book_id),
  constraint reading_goal_books_goal_owner_fk
    foreign key (goal_id, user_id)
    references public.reading_goals(id, user_id)
    on delete cascade,
  constraint reading_goal_books_book_owner_fk
    foreign key (book_id, user_id)
    references public.books(id, user_id)
    on delete cascade
);

create trigger reading_goals_set_updated_at
before update on public.reading_goals
for each row execute function private.set_updated_at();

create index reading_goals_user_active_idx
  on public.reading_goals (user_id, starts_on, ends_on)
  where archived_at is null;
create index reading_goal_books_user_goal_idx
  on public.reading_goal_books (user_id, goal_id);
create index reading_goal_books_book_owner_idx
  on public.reading_goal_books (book_id, user_id);

alter table public.reading_goals enable row level security;
alter table public.reading_goal_books enable row level security;

revoke all on table public.reading_goals from public, anon, authenticated;
revoke all on table public.reading_goal_books from public, anon, authenticated;
grant select, insert, update, delete on table public.reading_goals to authenticated;
grant select, insert, update, delete on table public.reading_goal_books to authenticated;

create policy reading_goals_select_own on public.reading_goals
for select to authenticated using ((select auth.uid()) = user_id);
create policy reading_goals_insert_own on public.reading_goals
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy reading_goals_update_own on public.reading_goals
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy reading_goals_delete_own on public.reading_goals
for delete to authenticated using ((select auth.uid()) = user_id);

create policy reading_goal_books_select_own on public.reading_goal_books
for select to authenticated using ((select auth.uid()) = user_id);
create policy reading_goal_books_insert_own on public.reading_goal_books
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy reading_goal_books_update_own on public.reading_goal_books
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy reading_goal_books_delete_own on public.reading_goal_books
for delete to authenticated using ((select auth.uid()) = user_id);
