-- Content for the new design: gallery, resources, announcements, plus news category and event image.
-- Additive and safe to re-run. Run in the "Philmech PSABE" project AFTER 000_psabe_full_schema.sql.

alter table public.news   add column if not exists category text not null default 'News';
alter table public.events add column if not exists image_url text;

create table if not exists public.gallery_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text not null,
  sort_order int not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text not null default 'downloads' check (category in ('publications','references','downloads')),
  file_url text not null,
  sort_order int not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.gallery_items enable row level security;
alter table public.resources enable row level security;
alter table public.announcements enable row level security;

-- Guests read published rows only; admins read and write everything.
drop policy if exists "Anyone reads published gallery" on public.gallery_items;
drop policy if exists "Admins read all gallery" on public.gallery_items;
drop policy if exists "Admins write gallery" on public.gallery_items;
create policy "Anyone reads published gallery" on public.gallery_items for select using (is_published);
create policy "Admins read all gallery" on public.gallery_items for select to authenticated using (public.is_admin());
create policy "Admins write gallery" on public.gallery_items
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads published resources" on public.resources;
drop policy if exists "Admins read all resources" on public.resources;
drop policy if exists "Admins write resources" on public.resources;
create policy "Anyone reads published resources" on public.resources for select using (is_published);
create policy "Admins read all resources" on public.resources for select to authenticated using (public.is_admin());
create policy "Admins write resources" on public.resources
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads active announcements" on public.announcements;
drop policy if exists "Admins read all announcements" on public.announcements;
drop policy if exists "Admins write announcements" on public.announcements;
create policy "Anyone reads active announcements" on public.announcements for select using (is_active);
create policy "Admins read all announcements" on public.announcements for select to authenticated using (public.is_admin());
create policy "Admins write announcements" on public.announcements
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Guests only ever read; remove the write privileges Supabase grants by default (RLS already blocks them).
revoke insert, update, delete, truncate, references, trigger
  on public.gallery_items, public.resources, public.announcements from anon;
