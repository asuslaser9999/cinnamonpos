-- Cinnamon POS — tabel prefix cn_ di database yang sama dengan Ultimate POS.
-- Tidak mengubah tabel profiles / store_app_settings yang sudah ada.

create extension if not exists "pgcrypto";

-- ─── cn_profiles ─────────────────────────────────────────────────────────────

create table if not exists public.cn_profiles (
  id           uuid        primary key references auth.users(id) on delete cascade,
  email        text,
  role         text        not null default 'cashier'
                           check (role in ('owner', 'cashier')),
  display_name text        not null default '',
  username     text,
  is_active    boolean     not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.cn_profiles is
  'Profil pengguna Cinnamon POS (terpisah dari public.profiles).';

create unique index if not exists idx_cn_profiles_username_lower
  on public.cn_profiles (lower(username))
  where username is not null;

drop trigger if exists trg_cn_profiles_updated_at on public.cn_profiles;
create trigger trg_cn_profiles_updated_at
  before update on public.cn_profiles
  for each row execute function public.set_updated_at();

-- Seed dari akun Ultimate POS yang sudah ada agar login yang sama langsung jalan.
insert into public.cn_profiles (
  id, email, role, display_name, username, is_active, created_at, updated_at
)
select
  p.id,
  p.email,
  p.role,
  coalesce(
    nullif(p.display_name, ''),
    nullif(p.username, ''),
    split_part(coalesce(p.email, ''), '@', 1),
    ''
  ),
  p.username,
  coalesce(p.is_active, true),
  p.created_at,
  p.updated_at
from public.profiles p
on conflict (id) do nothing;

create or replace function public.cn_is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.cn_profiles
    where id = auth.uid()
      and role = 'owner'
  );
$$;

alter table public.cn_profiles enable row level security;

drop policy if exists "cn_profiles_select_own_or_owner" on public.cn_profiles;
create policy "cn_profiles_select_own_or_owner"
  on public.cn_profiles for select
  using (id = auth.uid() or public.cn_is_owner());

drop policy if exists "cn_profiles_update_owner" on public.cn_profiles;
create policy "cn_profiles_update_owner"
  on public.cn_profiles for update
  using (public.cn_is_owner())
  with check (public.cn_is_owner());

drop policy if exists "cn_profiles_insert_owner" on public.cn_profiles;
create policy "cn_profiles_insert_owner"
  on public.cn_profiles for insert
  with check (public.cn_is_owner());

-- ─── cn_store_app_settings ───────────────────────────────────────────────────

create table if not exists public.cn_store_app_settings (
  id text primary key default 'default'
    check (id = 'default'),
  cashier_access_mode text not null default 'time_restricted'
    check (cashier_access_mode in ('full', 'time_restricted', 'blocked')),
  cashier_access_start text not null default '05:30',
  cashier_access_end text not null default '16:30',
  cashier_can_manage_own_products boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.cn_profiles(id) on delete set null
);

comment on table public.cn_store_app_settings is
  'Pengaturan akses kasir Cinnamon POS — terpisah dari store_app_settings.';

insert into public.cn_store_app_settings (id)
values ('default')
on conflict (id) do nothing;

alter table public.cn_store_app_settings enable row level security;

drop policy if exists "cn_store_app_settings_select_authenticated"
  on public.cn_store_app_settings;
create policy "cn_store_app_settings_select_authenticated"
  on public.cn_store_app_settings for select
  using (auth.role() = 'authenticated');

drop policy if exists "cn_store_app_settings_update_owner"
  on public.cn_store_app_settings;
create policy "cn_store_app_settings_update_owner"
  on public.cn_store_app_settings for update
  using (public.cn_is_owner())
  with check (public.cn_is_owner());

drop policy if exists "cn_store_app_settings_insert_owner"
  on public.cn_store_app_settings;
create policy "cn_store_app_settings_insert_owner"
  on public.cn_store_app_settings for insert
  with check (public.cn_is_owner());

drop trigger if exists trg_cn_store_app_settings_updated_at
  on public.cn_store_app_settings;
create trigger trg_cn_store_app_settings_updated_at
  before update on public.cn_store_app_settings
  for each row execute function public.set_updated_at();

-- ─── Trigger user baru → cn_profiles ─────────────────────────────────────────

create or replace function public.cn_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_display_name text;
  v_role text;
begin
  v_username := lower(trim(coalesce(new.raw_user_meta_data->>'username', '')));
  if v_username = '' and new.email is not null then
    v_username := lower(split_part(new.email, '@', 1));
  end if;

  v_display_name := coalesce(new.raw_user_meta_data->>'display_name', v_username, '');
  v_role := coalesce(new.raw_user_meta_data->>'role', 'cashier');

  insert into public.cn_profiles (id, email, role, display_name, username, is_active)
  values (
    new.id,
    new.email,
    v_role,
    v_display_name,
    nullif(v_username, ''),
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_cn on auth.users;
create trigger on_auth_user_created_cn
  after insert on auth.users
  for each row execute function public.cn_handle_new_user();

-- ─── RPC resolve email dari cn_profiles ──────────────────────────────────────

create or replace function public.cn_resolve_login_email(p_username text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with input as (
    select lower(trim(p_username)) as val
  )
  select coalesce(
    (
      select p.email
      from public.cn_profiles p, input
      where lower(p.username) = input.val
      limit 1
    ),
    (
      select p.email
      from public.cn_profiles p, input
      where lower(p.email) = input.val
      limit 1
    ),
    (
      select p.email
      from public.cn_profiles p, input
      where lower(split_part(p.email, '@', 1)) = input.val
      limit 1
    ),
    (select input.val || '@mulyasari.pos' from input)
  );
$$;

revoke all on function public.cn_resolve_login_email(text) from public;
grant execute on function public.cn_resolve_login_email(text) to anon, authenticated;
