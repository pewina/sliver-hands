-- SilverHands Family Guide: reliable member-side code generation.
-- Run AFTER 003_family_guide.sql.
-- This function creates the invite on behalf of the signed-in member while
-- keeping owner_id bound to auth.uid(). The Flutter client never supplies it.

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

  -- A new code invalidates older unused invitations for this member.
  update public.guide_links
  set status = 'expired', updated_at = now()
  where owner_id = v_user_id
    and status = 'pending';

  loop
    v_code := (floor(random() * 900000) + 100000)::text;
    exit when not exists (
      select 1 from public.guide_links where invite_code = v_code
    );
  end loop;

  insert into public.guide_links (
    owner_id,
    relationship,
    invite_code,
    status,
    expires_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    coalesce(nullif(trim(p_relationship), ''), 'Family member'),
    v_code,
    'pending',
    now() + interval '30 minutes',
    now(),
    now()
  );

  return v_code;
end;
$$;

revoke all on function public.create_guide_code(text) from public;
grant execute on function public.create_guide_code(text) to authenticated;
