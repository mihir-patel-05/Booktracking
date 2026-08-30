begin;
create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values
  ('11111111-1111-4111-8111-111111111111', 'reader-one@example.test', '{}', '{}'),
  ('22222222-2222-4222-8222-222222222222', 'reader-two@example.test', '{}', '{}');

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

select lives_ok(
  $$insert into public.profiles (id, display_name, time_zone) values ('11111111-1111-4111-8111-111111111111', 'Reader One', 'America/Detroit')$$,
  'an authenticated user can create their profile'
);
select lives_ok(
  $$insert into public.books (id, title, author, total_pages) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Test Book', 'Test Author', 300)$$,
  'an authenticated user can create a book'
);
select is((select count(*) from public.books), 1::bigint, 'the owner can read their book');
select is(
  (select xp_earned from public.finalize_reading_session(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 1500, '2026-08-16T14:00:00Z', 'America/Detroit',
    array['Reflective'], 'Prompt', 'Reflection', 'Note', 'Content', array['test'], 'Chapter 1', 'A quote'
  )),
  25,
  'the atomic finalizer calculates XP on the server'
);
select is((select total_xp from public.user_stats), 25, 'cached statistics reflect finalized XP');
select lives_ok(
  $$insert into public.reading_plans (book_id, planned_date, target_minutes) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-08-20', 30)$$,
  'an authenticated user can plan a volume for a day'
);
select throws_ok(
  $$insert into public.reading_plans (book_id, planned_date) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-08-20')$$,
  '23505',
  'duplicate key value violates unique constraint "reading_plans_user_id_planned_date_book_id_key"',
  'the same volume is entered in the diary once a day'
);
select throws_ok(
  $$update public.books set user_id = '22222222-2222-4222-8222-222222222222' where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'$$,
  '42501',
  'new row violates row-level security policy for table "books"',
  'ownership cannot be reassigned'
);
select lives_ok(
  $$insert into public.reading_goals (id, name, target_books, cadence, starts_on, ends_on) values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'Twenty in 2026', 20, 'overall', '2026-01-01', '2026-12-31')$$,
  'an authenticated user can set a reading goal'
);
select lives_ok(
  $$insert into public.reading_goal_books (goal_id, book_id, completed_on) values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-08-20')$$,
  'the owner can enter their volume against their goal'
);
select is(
  (select count(*) from public.reading_goal_books where completed_on between '2026-01-01' and '2026-12-31'),
  1::bigint,
  'goal progress is measurable by the local completion date'
);
select throws_ok(
  $$insert into public.reading_goal_books (goal_id, book_id, completed_on) values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-08-21')$$,
  '23505',
  'duplicate key value violates unique constraint "reading_goal_books_pkey"',
  'a volume counts against the same goal only once'
);

select set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
select is((select count(*) from public.books), 0::bigint, 'another user cannot read the owner book');
select is((select count(*) from public.reading_goals), 0::bigint, 'another user cannot read the owner goals');
select throws_ok(
  $$insert into public.session_notes (book_id, title) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Cross-user note')$$,
  '23503',
  'insert or update on table "session_notes" violates foreign key constraint "session_notes_book_owner_fk"',
  'records cannot link across owners'
);
select throws_ok(
  $$insert into public.reading_plans (book_id, planned_date) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-08-21')$$,
  '23503',
  'insert or update on table "reading_plans" violates foreign key constraint "reading_plans_book_owner_fk"',
  'a plan cannot be laid against a volume owned by another reader'
);
insert into public.books (id, title, author, total_pages)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Second Reader Book', 'Another Author', 240);
select throws_ok(
  $$insert into public.reading_goal_books (goal_id, book_id, completed_on) values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '2026-08-21')$$,
  '23503',
  'insert or update on table "reading_goal_books" violates foreign key constraint "reading_goal_books_goal_owner_fk"',
  'a volume cannot be entered against another reader goal'
);

select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select lives_ok(
  $$delete from public.reading_goals where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'$$,
  'the owner can permanently delete their goal'
);
select is(
  (select count(*) from public.reading_goal_books where goal_id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'),
  0::bigint,
  'deleting a goal removes its goal membership rows'
);

set local role anon;
select throws_ok($$select count(*) from public.books$$, '42501', 'permission denied for table books', 'anonymous table reads are revoked');
select throws_ok($$select count(*) from public.reading_goals$$, '42501', 'permission denied for table reading_goals', 'anonymous goal reads are revoked');
select throws_ok(
  $$select * from public.finalize_reading_session('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 60)$$,
  '42501',
  'permission denied for function finalize_reading_session',
  'anonymous RPC execution is revoked'
);

select * from finish();
rollback;
