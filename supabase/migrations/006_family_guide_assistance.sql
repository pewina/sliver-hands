-- SilverHands Family Guide assistance layer.
-- Run AFTER 005_family_guide_install.sql (or after the Family Guide migrations
-- already installed in your project).

create table if not exists public.guide_help_requests (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  guide_id uuid not null references auth.users(id) on delete cascade,
  request_type text not null check (request_type in ('opportunity','content','message','safety','order')),
  title text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists guide_help_requests_owner_idx on public.guide_help_requests(owner_id, created_at desc);
create index if not exists guide_help_requests_guide_idx on public.guide_help_requests(guide_id, created_at desc);

alter table public.guide_help_requests enable row level security;

drop policy if exists "guide reads own help requests" on public.guide_help_requests;
create policy "guide reads own help requests"
on public.guide_help_requests for select to authenticated
using (auth.uid() = guide_id);

drop policy if exists "owner reads own help requests" on public.guide_help_requests;
create policy "owner reads own help requests"
on public.guide_help_requests for select to authenticated
using (auth.uid() = owner_id);

-- Guides create requests only for their currently linked member.
drop policy if exists "guide creates linked help requests" on public.guide_help_requests;
create policy "guide creates linked help requests"
on public.guide_help_requests for insert to authenticated
with check (
  auth.uid() = guide_id
  and exists (
    select 1 from public.guide_links gl
    where gl.owner_id = guide_help_requests.owner_id
      and gl.guide_id = auth.uid()
      and gl.status = 'active'
  )
);

-- Only the member can approve/reject. Guides cannot mutate the request state.
drop policy if exists "owner responds to help requests" on public.guide_help_requests;
create policy "owner responds to help requests"
on public.guide_help_requests for update to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create or replace function public.create_guide_help_request(
  p_request_type text,
  p_title text,
  p_message text,
  p_payload jsonb default '{}'::jsonb
)
returns public.guide_help_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_guide uuid := auth.uid();
  v_owner uuid;
  v_result public.guide_help_requests;
begin
  if v_guide is null then
    raise exception 'You must be signed in';
  end if;

  select gl.owner_id into v_owner
  from public.guide_links gl
  where gl.guide_id = v_guide and gl.status = 'active'
  order by gl.updated_at desc
  limit 1;

  if v_owner is null then
    raise exception 'No active family member is connected to this guide';
  end if;

  insert into public.guide_help_requests (
    owner_id, guide_id, request_type, title, message, payload
  ) values (
    v_owner, v_guide,
    coalesce(nullif(trim(p_request_type), ''), 'message'),
    coalesce(nullif(trim(p_title), ''), 'Help requested'),
    coalesce(nullif(trim(p_message), ''), 'Your Family Guide has requested your review.'),
    coalesce(p_payload, '{}'::jsonb)
  ) returning * into v_result;

  insert into public.guide_activity(owner_id, guide_id, action, details)
  values (v_owner, v_guide, 'approval_requested', p_title);

  return v_result;
end;
$$;

revoke all on function public.create_guide_help_request(text,text,text,jsonb) from public;
grant execute on function public.create_guide_help_request(text,text,text,jsonb) to authenticated;

create or replace function public.respond_to_guide_help_request(
  p_request_id uuid,
  p_status text
)
returns public.guide_help_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result public.guide_help_requests;
begin
  if p_status not in ('approved','rejected') then
    raise exception 'Invalid response status';
  end if;

  update public.guide_help_requests
  set status = p_status,
      responded_at = now(),
      updated_at = now()
  where id = p_request_id
    and owner_id = auth.uid()
    and status = 'pending'
  returning * into v_result;

  if v_result.id is null then
    raise exception 'Request not found or already handled';
  end if;

  insert into public.guide_activity(owner_id, guide_id, action, details)
  values (v_result.owner_id, v_result.guide_id, 'approval_' || p_status, v_result.title);

  return v_result;
end;
$$;

revoke all on function public.respond_to_guide_help_request(uuid,text) from public;
grant execute on function public.respond_to_guide_help_request(uuid,text) to authenticated;

create or replace function public.cancel_guide_help_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.guide_help_requests
  set status = 'cancelled', updated_at = now()
  where id = p_request_id
    and guide_id = auth.uid()
    and status = 'pending';
  return found;
end;
$$;

revoke all on function public.cancel_guide_help_request(uuid) from public;
grant execute on function public.cancel_guide_help_request(uuid) to authenticated;
