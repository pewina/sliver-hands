-- SilverHands live prototype extensions.
-- Run this AFTER 001_silverhands.sql in the Supabase SQL Editor.

alter table public.profiles add column if not exists headline text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists transcript text;
alter table public.profiles add column if not exists aadhaar_verified boolean default false;
alter table public.profiles add column if not exists aadhaar_last4 text;

create table if not exists public.collaboration_partners (
  id uuid primary key default gen_random_uuid(),
  display_name text not null unique,
  skills text[] default '{}',
  location text,
  capacity_units integer default 0,
  reliability_score integer default 0,
  active boolean default true,
  created_at timestamptz default now()
);

alter table public.collaboration_partners enable row level security;
drop policy if exists "collaboration partners readable" on public.collaboration_partners;
create policy "collaboration partners readable"
on public.collaboration_partners
for select to authenticated
using (active = true);

insert into public.collaboration_partners
(display_name, skills, location, capacity_units, reliability_score)
values
('Lakshmi', array['Cooking','Traditional Food'], 'Chennai, Tamil Nadu', 30, 97),
('Meena', array['Pickle Making','Cooking'], 'Chennai, Tamil Nadu', 30, 95),
('Shanthi', array['Packaging','Handicrafts'], 'Chennai, Tamil Nadu', 30, 93),
('Revathi', array['Cooking','Sweets Making'], 'Chennai, Tamil Nadu', 30, 96)
on conflict (display_name) do update set
  skills = excluded.skills,
  location = excluded.location,
  capacity_units = excluded.capacity_units,
  reliability_score = excluded.reliability_score,
  active = true;
