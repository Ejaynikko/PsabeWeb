-- PSABE full schema, built from scratch. Safe to re-run. Run in the "Philmech PSABE" project (ref ijliyzkslhntnrsriqbc).

-- 1. Tables --------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  region text,
  chapter text,
  membership_type text not null default 'member',
  role text not null default 'member' check (role in ('member','admin')),
  status text not null default 'pending' check (status in ('pending','active','inactive')),
  prc_license_no text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text,
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  registration_url text,
  program_url text,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  certificate_url text,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);
create index if not exists event_registrations_user_id_idx on public.event_registrations (user_id);

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  image_url text,
  is_published boolean not null default true,
  published_at timestamptz default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.officers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  position text not null,
  region text,
  term text,
  photo_url text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.news enable row level security;
alter table public.officers enable row level security;

-- 2. Functions + triggers --------------------------------------------------------
-- New sign-up -> profile row (status 'pending' until an admin approves).
create or replace function public.create_profile_for_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), new.email)
  on conflict (id) do nothing;
  return new;
end $$;

create or replace function public.update_profile_timestamp() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- is_admin is security definer so policies on profiles don't recurse.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = (select auth.uid()) and role = 'admin');
$$;

-- Members can edit their profile but never their own role/status.
-- auth.uid() is null in the SQL editor / service role, so those can still change anything.
create or replace function public.guard_profile_admin_fields() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if (new.role is distinct from old.role or new.status is distinct from old.status)
     and (select auth.uid()) is not null and not public.is_admin() then
    raise exception 'Only admins can change role or status';
  end if;
  return new;
end $$;

-- leftovers from the first version of this script
drop trigger if exists on_auth_user_created_profile_email on auth.users;
drop function if exists public.set_profile_email();

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users for each row execute function public.create_profile_for_new_user();

drop trigger if exists profiles_update_timestamp on public.profiles;
create trigger profiles_update_timestamp
  before update on public.profiles for each row execute function public.update_profile_timestamp();

drop trigger if exists profiles_guard_admin_fields on public.profiles;
create trigger profiles_guard_admin_fields
  before update on public.profiles for each row execute function public.guard_profile_admin_fields();

-- Trigger functions are never called directly; is_admin is only for signed-in users' policies.
revoke execute on function public.create_profile_for_new_user() from public, anon, authenticated;
revoke execute on function public.update_profile_timestamp() from public, anon, authenticated;
revoke execute on function public.guard_profile_admin_fields() from public, anon, authenticated;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- 3. Policies ---------------------------------------------------------------------
drop policy if exists "Members read own profile" on public.profiles;
drop policy if exists "Members update own profile" on public.profiles;
drop policy if exists "Admins read all profiles" on public.profiles;
drop policy if exists "Admins update all profiles" on public.profiles;
create policy "Members read own profile" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "Members update own profile" on public.profiles
  for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "Admins read all profiles" on public.profiles
  for select to authenticated using (public.is_admin());
create policy "Admins update all profiles" on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads published events" on public.events;
drop policy if exists "Admins read all events" on public.events;
drop policy if exists "Admins insert events" on public.events;
drop policy if exists "Admins update events" on public.events;
drop policy if exists "Admins delete events" on public.events;
create policy "Anyone reads published events" on public.events for select using (is_published);
create policy "Admins read all events" on public.events for select to authenticated using (public.is_admin());
create policy "Admins insert events" on public.events for insert to authenticated with check (public.is_admin());
create policy "Admins update events" on public.events
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins delete events" on public.events for delete to authenticated using (public.is_admin());

drop policy if exists "Members read own registrations" on public.event_registrations;
drop policy if exists "Active members register for published events" on public.event_registrations;
drop policy if exists "Admins manage registrations" on public.event_registrations;
create policy "Members read own registrations" on public.event_registrations
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Active members register for published events" on public.event_registrations
  for insert to authenticated with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.events e where e.id = event_id and e.is_published)
    and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
  );
create policy "Admins manage registrations" on public.event_registrations
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads published news" on public.news;
drop policy if exists "Admins read all news" on public.news;
drop policy if exists "Admins write news" on public.news;
create policy "Anyone reads published news" on public.news for select using (is_published);
create policy "Admins read all news" on public.news for select to authenticated using (public.is_admin());
create policy "Admins write news" on public.news
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads officers" on public.officers;
drop policy if exists "Admins write officers" on public.officers;
create policy "Anyone reads officers" on public.officers for select using (true);
create policy "Admins write officers" on public.officers
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4. Public attendee counts per region (aggregates only, no personal data) -------
create or replace view public.event_region_counts as
select r.event_id, coalesce(nullif(p.region, ''), 'Unspecified') as region, count(*)::int as attendees
from public.event_registrations r
join public.profiles p on p.id = r.user_id
join public.events e on e.id = r.event_id and e.is_published
group by r.event_id, coalesce(nullif(p.region, ''), 'Unspecified');
grant select on public.event_region_counts to anon, authenticated;

-- 5. Profiles for accounts that already exist, then the first admin ---------------
insert into public.profiles (id, full_name, email)
select id, coalesce(raw_user_meta_data->>'full_name', ''), email from auth.users
on conflict (id) do nothing;

update public.profiles set role = 'admin', status = 'active' where lower(email) = lower('Admin.PSABE@gmail.com');
