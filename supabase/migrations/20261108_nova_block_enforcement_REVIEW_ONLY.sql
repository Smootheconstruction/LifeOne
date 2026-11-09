-- NOVA block enforcement staging draft — NOT APPLIED by GitHub.
-- Prerequisites (in order):
-- 1) 20261105_world_connect_moderation_draft.sql
-- 2) 20261108_nova_follows_leaders_REVIEW_ONLY.sql (including checked helper owner)
-- BEFORE executing, verify existing friend_requests/direct_messages schemas and policies.
-- Restrictive policies add a mandatory block condition on top of existing permissive policies.
-- Test on separate staging accounts before enabling any new UI.

alter table public.friend_requests enable row level security;
alter table public.direct_messages enable row level security;

drop policy if exists nova_friend_requests_no_block_read on public.friend_requests;
create policy nova_friend_requests_no_block_read on public.friend_requests
as restrictive for select to authenticated
using (not public.nova_follow_pair_blocked(sender_id,receiver_id));

drop policy if exists nova_friend_requests_no_block_insert on public.friend_requests;
create policy nova_friend_requests_no_block_insert on public.friend_requests
as restrictive for insert to authenticated
with check (not public.nova_follow_pair_blocked(sender_id,receiver_id));

drop policy if exists nova_friend_requests_no_block_update on public.friend_requests;
create policy nova_friend_requests_no_block_update on public.friend_requests
as restrictive for update to authenticated
using (not public.nova_follow_pair_blocked(sender_id,receiver_id))
with check (not public.nova_follow_pair_blocked(sender_id,receiver_id));

drop policy if exists nova_messages_no_block_read on public.direct_messages;
create policy nova_messages_no_block_read on public.direct_messages
as restrictive for select to authenticated
using (not public.nova_follow_pair_blocked(sender_id,recipient_id));

drop policy if exists nova_messages_no_block_insert on public.direct_messages;
create policy nova_messages_no_block_insert on public.direct_messages
as restrictive for insert to authenticated
with check (not public.nova_follow_pair_blocked(sender_id,recipient_id));

-- Existing friend/message ownership checks must remain in place.
-- Disallow user-provided sender identities in existing permissive INSERT policies.
-- Blocking may hide historic messages but does not delete underlying records.
-- Reconcile current message view, friendship state, and future reporting policy with moderators.
