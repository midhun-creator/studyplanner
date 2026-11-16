-- ============================================================
-- StudyPlanner — reference schema + Row Level Security
-- Run in: Supabase Dashboard → SQL Editor.
-- Columns are inferred from app.js. Review against your project
-- before running on existing data.
--
-- IMPORTANT
--  1. Admin rights live in app_metadata, which users cannot edit.
--     After running this script, grant admin (replace the email):
--
--       update auth.users
--       set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"isAdmin": true}'
--       where email = 'admin@example.com';
--
--     The user must sign out and back in for the new claim to apply.
--  2. The UI check in app.js is cosmetic. THESE POLICIES are the
--     real access control.
-- ============================================================

create or replace function public.is_admin()
returns boolean
language sql stable
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'isAdmin')::boolean, false);
$$;

-- ---------- Tables ----------

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text, reg text, phone text, adm text, act text
);

create table if not exists public.tasks (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  text text not null, done boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.reminders (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, date date not null, recurring text default 'none'
);

create table if not exists public.notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, content text, link text, tags text,
  created_at timestamptz not null default now()
);

create table if not exists public.sem_notes (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  sem int not null, subject text not null, content text
);

create table if not exists public.flashcards (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  front text not null, back text not null, subject text
);

create table if not exists public.progress (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  sem int not null, marks numeric not null
);

create table if not exists public.study_time (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null, subject text not null, minutes int not null default 0
);

create table if not exists public.streak_log (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  primary key (user_id, date)
);

create table if not exists public.attendance_records (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null, date date not null, present boolean not null,
  unique (user_id, subject, date)
);

create table if not exists public.admin_timetable (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  day text, time text, subject text, date date
);

create table if not exists public.admin_pdfs (
  id bigint generated always as identity primary key,
  sem int not null, subject text not null,
  name text, url text, storage_path text, size bigint,
  created_at timestamptz not null default now()
);

create table if not exists public.study_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null, exam_date date not null,
  difficulty text not null default 'medium',
  status text not null default 'pending' check (status in ('pending', 'responded')),
  response_text text,
  created_at timestamptz not null default now()
);

-- ---------- Enable RLS everywhere ----------

alter table public.profiles           enable row level security;
alter table public.tasks              enable row level security;
alter table public.reminders          enable row level security;
alter table public.notes              enable row level security;
alter table public.sem_notes          enable row level security;
alter table public.flashcards         enable row level security;
alter table public.progress           enable row level security;
alter table public.study_time         enable row level security;
alter table public.streak_log         enable row level security;
alter table public.attendance_records enable row level security;
alter table public.admin_timetable    enable row level security;
alter table public.admin_pdfs         enable row level security;
alter table public.study_requests     enable row level security;

-- ---------- Owner-only tables ----------
-- Students manage their own rows. Admin gets read-only access
-- where the admin dashboard needs it.

do $$
declare t text;
begin
  foreach t in array array[
    'profiles','tasks','reminders','notes','sem_notes','flashcards',
    'progress','study_time','streak_log','admin_timetable'
  ] loop
    execute format('drop policy if exists "owner all" on public.%I', t);
    execute format(
      'create policy "owner all" on public.%I for all to authenticated
         using (user_id = auth.uid()) with check (user_id = auth.uid())', t);
    execute format('drop policy if exists "admin read" on public.%I', t);
    execute format(
      'create policy "admin read" on public.%I for select to authenticated
         using (public.is_admin())', t);
  end loop;
end $$;

-- ---------- Attendance: students read own, admin full control ----------

drop policy if exists "student read own" on public.attendance_records;
create policy "student read own" on public.attendance_records
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "admin all" on public.attendance_records;
create policy "admin all" on public.attendance_records
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- Admin PDFs: everyone signed-in reads, admin writes ----------

drop policy if exists "read pdfs" on public.admin_pdfs;
create policy "read pdfs" on public.admin_pdfs
  for select to authenticated using (true);

drop policy if exists "admin write pdfs" on public.admin_pdfs;
create policy "admin write pdfs" on public.admin_pdfs
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- Study requests ----------
-- Students create/read/delete their own. Only admin may answer
-- (update), so students cannot forge `response_text`.

drop policy if exists "student insert" on public.study_requests;
create policy "student insert" on public.study_requests
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending' and response_text is null);

drop policy if exists "student read own" on public.study_requests;
create policy "student read own" on public.study_requests
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "student delete own" on public.study_requests;
create policy "student delete own" on public.study_requests
  for delete to authenticated using (user_id = auth.uid());

drop policy if exists "admin all" on public.study_requests;
create policy "admin all" on public.study_requests
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------- Storage bucket "pdfs" ----------

insert into storage.buckets (id, name, public)
values ('pdfs', 'pdfs', true)
on conflict (id) do nothing;

drop policy if exists "pdfs public read" on storage.objects;
create policy "pdfs public read" on storage.objects
  for select using (bucket_id = 'pdfs');

drop policy if exists "pdfs admin insert" on storage.objects;
create policy "pdfs admin insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'pdfs' and public.is_admin());

drop policy if exists "pdfs admin delete" on storage.objects;
create policy "pdfs admin delete" on storage.objects
  for delete to authenticated using (bucket_id = 'pdfs' and public.is_admin());
