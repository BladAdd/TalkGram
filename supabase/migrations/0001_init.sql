-- ═══════════════════════════════════════════════════════════
-- TalkGram · схема базы данных (Supabase / PostgreSQL)
-- Запустите весь файл один раз: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ── 1. Профили пользователей (создаются автоматически при регистрации) ──
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text not null unique check (char_length(username) between 3 and 20),
  full_name  text,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- ── 2. Сообщения ──
create table if not exists public.messages (
  id           bigint generated always as identity primary key,
  sender_id    uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  content      text not null check (char_length(content) between 1 and 4000),
  created_at   timestamptz not null default now(),
  read_at      timestamptz
);
create index if not exists messages_sender_idx    on public.messages (sender_id, created_at desc);
create index if not exists messages_recipient_idx on public.messages (recipient_id, created_at desc);

-- ── 3. Автосоздание профиля при регистрации (по данным из signUp) ──
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'username', ''), 'user_' || left(new.id::text, 8)),
    new.raw_user_meta_data ->> 'full_name',
    null
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 4. RLS: пользователь видит только свои данные ──
alter table public.profiles enable row level security;
alter table public.messages  enable row level security;

-- профили читаемы всеми авторизованными (нужно для поиска собеседника)
create policy "profiles_select"      on public.profiles for select to authenticated using (true);
create policy "profiles_insert_own"  on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles_update_own"  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- сообщения: видит только отправитель и получатель
create policy "messages_select"      on public.messages for select to authenticated using (auth.uid() = sender_id or auth.uid() = recipient_id);
create policy "messages_insert"      on public.messages for insert to authenticated with check (auth.uid() = sender_id);
-- получатель отмечает прочитанным
create policy "messages_update_read" on public.messages for update to authenticated using (auth.uid() = recipient_id) with check (auth.uid() = recipient_id);
-- TODO: сузить update до колонки read_at (column-level policy), если понадобится редактирование сообщений

-- ── 5. Realtime: сообщения доставляются мгновенно (RLS применяется и здесь) ──
alter table public.messages replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;