-- OPTIONAL sample content copied from the friend's design, so the home page is not empty while you build.
-- Every row is a placeholder: edit or delete it in the admin pages. Each block only runs if its table is empty.
-- Run after 002_content_tables.sql.

insert into public.announcements (text, sort_order)
select t.text, t.n from (values
  ('Welcome to the official PSABE website!', 1),
  ('Membership applications and renewals will be available online.', 2),
  ('Watch this page for upcoming PSABE events and announcements.', 3)
) as t(text, n)
where not exists (select 1 from public.announcements);

insert into public.news (title, body, image_url, category, is_published)
select * from (values
  ('PSABE Website Development', 'A new digital platform is being developed to improve member services, communication, and organizational management.', 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800', 'Announcement', true),
  ('Advancing Agricultural Engineering', 'Discover opportunities for professional development, collaboration, and technical knowledge sharing.', 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800', 'Professional Development', true),
  ('Building Stronger Professional Networks', 'Connecting agricultural and biosystems engineering professionals throughout the country.', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800', 'Community', true)
) as t(title, body, image_url, category, is_published)
where not exists (select 1 from public.news);

insert into public.events (title, summary, location, starts_at, image_url, is_published)
select * from (values
  ('PSABE National Convention', 'A professional gathering for knowledge exchange, innovation, and networking.', 'To Be Announced', now() + interval '60 days', 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800', true),
  ('Technical Seminar and Training', 'Technical learning and professional development for agricultural engineers.', 'To Be Announced', now() + interval '90 days', 'https://images.unsplash.com/photo-1559223607-a43c990c692c?w=800', true),
  ('Professional Networking', 'An opportunity to connect with fellow members and industry professionals.', 'To Be Announced', now() + interval '120 days', 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=800', true)
) as t(title, summary, location, starts_at, image_url, is_published)
where not exists (select 1 from public.events);

insert into public.officers (full_name, position, sort_order)
select * from (values
  ('Officer Name', 'National President', 1),
  ('Officer Name', 'National Vice President', 2),
  ('Officer Name', 'National Secretary', 3),
  ('Officer Name', 'National Treasurer', 4)
) as t(full_name, position, sort_order)
where not exists (select 1 from public.officers);

insert into public.gallery_items (title, image_url, sort_order)
select * from (values
  ('Professional Gathering', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800', 1),
  ('Technical Conference', 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800', 2),
  ('Agricultural Innovation', 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800', 3),
  ('Professional Training', 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800', 4)
) as t(title, image_url, sort_order)
where not exists (select 1 from public.gallery_items);
