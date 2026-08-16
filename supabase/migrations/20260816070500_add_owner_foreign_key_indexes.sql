create index reading_sessions_book_owner_idx
on public.reading_sessions (book_id, user_id);

create index session_notes_book_owner_idx
on public.session_notes (book_id, user_id);

create index session_notes_session_owner_idx
on public.session_notes (session_id, user_id)
where session_id is not null;

create index quotes_book_owner_idx
on public.quotes (book_id, user_id);

create index quotes_session_owner_idx
on public.quotes (session_id, user_id)
where session_id is not null;
