-- SilverHands Family Guide - one-click/idempotent installation
-- Run this in Supabase SQL Editor if the Family Guide tables/functions are missing.
-- Safe to run after 003/004 as well.

alter table public.opportunities
  add column if not exists owner_id uuid references auth.users(id) on delete cascade;

create table if not exists public.guide_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  guide_id uuid references auth.users(id) on delete set null,
  guide_name text,
  relationship text default 'Family member',
  invite_code text not null unique,
  status text not null default 'pending'
    check (status in ('pending','active','revoked','expired')),
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists guide_links_owner_idx on public.guide_links(owner_id);
create index if not exists guide_links_guide_idx on public.guide_links(guide_id);
create index if not exists opportunities_owner_idx on public.opportunities(owner_id);

alter table public.guide_links enable row level security;

drop policy if exists "owner manages guide links" on public.guide_links;
create policy "owner manages guide links"
on public.guide_links for all to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "guide reads own links" on public.guide_links;
create policy "guide reads own links"
on public.guide_links for select to authenticated
using (auth.uid() = guide_id);

create or replace function public.create_guide_code(
  p_relationship text default 'Family member'
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_code text;
begin
  if v_user_id is null then
    raise exception 'You must be signed in to create a guide code';
  end if;

  update public.guide_links
  set status = 'expired', updated_at = now()
  where owner_id = v_user_id and status = 'pending';

  loop
    v_code := (floor(random() * 900000) + 100000)::text;
    exit when not exists (
      select 1 from public.guide_links where invite_code = v_code
    );
  end loop;

  insert into public.guide_links (
    owner_id, relationship, invite_code, status, expires_at
  ) values (
    v_user_id,
    coalesce(nullif(trim(p_relationship), ''), 'Family member'),
    v_code,
    'pending',
    now() + interval '30 minutes'
  );

  return v_code;
end;
$$;

revoke all on function public.create_guide_code(text) from public;
grant execute on function public.create_guide_code(text) to authenticated;

create or replace function public.accept_guide_code(
  p_code text,
  p_guide_name text,
  p_relationship text default 'Family member'
)
returns public.guide_links
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.guide_links;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to connect as a Family Guide';
  end if;

  update public.guide_links
  set guide_id = auth.uid(),
      guide_name = nullif(trim(p_guide_name), ''),
      relationship = coalesce(nullif(trim(p_relationship), ''), relationship, 'Family member'),
      status = 'active',
      updated_at = now()
  where invite_code = trim(p_code)
    and status = 'pending'
    and expires_at > now()
  returning * into result;

  if result.id is null then
    raise exception 'Invalid or expired guide code';
  end if;

  return result;
end;
$$;

revoke all on function public.accept_guide_code(text,text,text) from public;
grant execute on function public.accept_guide_code(text,text,text) to authenticated;

create or replace function public.revoke_guide_link(p_link_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.guide_links
  set status = 'revoked', updated_at = now()
  where id = p_link_id and owner_id = auth.uid();
  return found;
end;
$$;

revoke all on function public.revoke_guide_link(uuid) from public;
grant execute on function public.revoke_guide_link(uuid) to authenticated;

-- Profile access: owner + active guide can read; existing owner-only write policy remains.
drop policy if exists "profiles guide read" on public.profiles;
create policy "profiles guide read"
on public.profiles for select to authenticated
using (
  auth.uid() = id
  or exists (
    select 1 from public.guide_links gl
    where gl.owner_id = profiles.id
      and gl.guide_id = auth.uid()
      and gl.status = 'active'
  )
);

-- Opportunities: owner writes; linked guide may read the owner's opportunities.
drop policy if exists "opportunities owner write" on public.opportunities;
create policy "opportunities owner write"
on public.opportunities for all to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "opportunities guide readable" on public.opportunities;
create policy "opportunities guide readable"
on public.opportunities for select to authenticated
using (
  is_active = true
  or exists (
    select 1 from public.guide_links gl
    where gl.owner_id = opportunities.owner_id
      and gl.guide_id = auth.uid()
      and gl.status = 'active'
  )
);

-- Matches: linked guide may read the member's matches.
drop policy if exists "matches guide readable" on public.matches;
create policy "matches guide readable"
on public.matches for select to authenticated
using (
  auth.uid() = user_id
  or exists (
    select 1 from public.guide_links gl
    where gl.owner_id = matches.user_id
      and gl.guide_id = auth.uid()
      and gl.status = 'active'
  )
);

create table if not exists public.guide_activity (
  id bigint generated by default as identity primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  guide_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  details text,
  created_at timestamptz not null default now()
);

alter table public.guide_activity enable row level security;

drop policy if exists "guide activity linked read" on public.guide_activity;
create policy "guide activity linked read"
on public.guide_activity for select to authenticated
using (auth.uid() = guide_id or auth.uid() = owner_id);

drop policy if exists "guide activity guide insert" on public.guide_activity;
create policy "guide activity guide insert"
on public.guide_activity for insert to authenticated
with check (
  auth.uid() = guide_id
  and exists (
    select 1 from public.guide_links gl
    where gl.owner_id = guide_activity.owner_id
      and gl.guide_id = auth.uid()
      and gl.status = 'active'
  )
);

-- Prevent a user from creating guide codes for another account through the client.
revoke all on public.guide_links from anon;
grant select, insert, update on public.guide_links to authenticated;
