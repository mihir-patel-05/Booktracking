create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.set_updated_at() from public, anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 80),
  avatar_url text check (avatar_url is null or char_length(avatar_url) <= 2048),
  time_zone text not null default 'UTC' check (char_length(time_zone) between 1 and 64),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 300),
  author text not null check (char_length(btrim(author)) between 1 and 200),
  cover_url text check (cover_url is null or char_length(cover_url) <= 2048),
  total_pages integer not null check (total_pages between 1 and 100000),
  current_page integer not null default 0 check (current_page >= 0 and current_page <= total_pages),
  status text not null default 'Want to Read'
    check (status in ('Want to Read', 'Currently Reading', 'Completed', 'Abandoned')),
  date_added timestamptz not null default now(),
  date_completed timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger books_set_updated_at
before update on public.books
for each row execute function private.set_updated_at();

create index books_user_status_idx on public.books (user_id, status);
create index books_user_date_added_idx on public.books (user_id, date_added desc);

alter table public.profiles enable row level security;
alter table public.books enable row level security;

revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.books from public, anon, authenticated;

grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.books to authenticated;

create policy profiles_select_own
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy profiles_insert_own
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

create policy profiles_update_own
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy profiles_delete_own
on public.profiles for delete
to authenticated
using ((select auth.uid()) = id);

create policy books_select_own
on public.books for select
to authenticated
using ((select auth.uid()) = user_id);

create policy books_insert_own
on public.books for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy books_update_own
on public.books for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy books_delete_own
on public.books for delete
to authenticated
using ((select auth.uid()) = user_id);
