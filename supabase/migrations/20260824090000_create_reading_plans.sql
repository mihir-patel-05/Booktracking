-- The diary: which volume the reader intends to open, and on which day.
-- A plan is an intention only; whether it was kept is read from the
-- attendance already recorded in public.reading_sessions.

create table public.reading_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  book_id uuid not null,
  planned_date date not null,
  target_minutes integer check (target_minutes is null or target_minutes between 5 and 1440),
  target_pages integer check (target_pages is null or target_pages between 1 and 100000),
  note text check (note is null or char_length(note) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  unique (user_id, planned_date, book_id),
  constraint reading_plans_book_owner_fk
    foreign key (book_id, user_id)
    references public.books(id, user_id)
    on delete cascade
);

create trigger reading_plans_set_updated_at
before update on public.reading_plans
for each row execute function private.set_updated_at();

create index reading_plans_user_date_idx on public.reading_plans (user_id, planned_date);
create index reading_plans_book_owner_idx on public.reading_plans (book_id, user_id);

alter table public.reading_plans enable row level security;

revoke all on table public.reading_plans from public, anon, authenticated;
grant select, insert, update, delete on table public.reading_plans to authenticated;

create policy reading_plans_select_own on public.reading_plans
for select to authenticated using ((select auth.uid()) = user_id);
create policy reading_plans_insert_own on public.reading_plans
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy reading_plans_update_own on public.reading_plans
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy reading_plans_delete_own on public.reading_plans
for delete to authenticated using ((select auth.uid()) = user_id);
