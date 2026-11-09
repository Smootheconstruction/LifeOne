-- REVIEW ONLY — do not run on production without authorization.
-- Based on owner-supplied November 2026 Supabase checks:
-- public.friend_requests(id, sender_id, receiver_id, status, created_at)
-- status only 'pending'/'accepted', six constraints, no custom triggers.
-- Existing "Recipient accepts requests" UPDATE RLS only checks recipient and status.
--
-- Purpose: ensure a recipient accepting a pending request cannot rewrite
-- its sender, receiver, ID, or creation time. Does not delete any records.
-- Test in a separate staging Supabase project with two invited accounts first.
--
-- WARNING: inspect any additional migrations/triggers introduced after the
-- owner's inspection before applying. This is not a substitute for RLS tests.
begin;

create or replace function public.nova_guard_friend_request_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $nova_guard$
begin
  if row(new.id,new.sender_id,new.receiver_id,new.created_at)
     is distinct from
     row(old.id,old.sender_id,old.receiver_id,old.created_at)
  then
    raise exception 'Friend request identity fields cannot be changed'
      using errcode = '23514';
  end if;

  if old.status is distinct from 'pending'
     or new.status is distinct from 'accepted'
  then
    raise exception 'Only pending friend requests can be accepted'
      using errcode = '23514';
  end if;

  return new;
end;
$nova_guard$;

revoke all on function public.nova_guard_friend_request_update()
  from public, anon, authenticated;

drop trigger if exists nova_friend_request_update_guard on public.friend_requests;
create trigger nova_friend_request_update_guard
before update on public.friend_requests
for each row
execute function public.nova_guard_friend_request_update();

commit;

-- Staging verification checklist (use two distinct auth sessions):
-- 1. Recipient can accept an existing pending request; sender cannot.
-- 2. Recipient cannot change sender_id/receiver_id/id/created_at on acceptance.
-- 3. Nobody can set an accepted request back to pending or rewrite it.
-- 4. Unrelated authenticated users cannot read or update the request.
-- 5. Existing accepted friendships and messaging still work.
-- 6. Deletion behavior remains controlled by existing RLS.
-- 7. Test the same two-user workflows after adding reciprocal block RLS.
-- Do not turn on public signup, follower features, or posts based only on
-- successful function creation. Review all grants and effective RLS separately.
