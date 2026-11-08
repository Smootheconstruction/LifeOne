-- NOVA Followers & Leaders private-beta staging migration.
-- REVIEW ONLY: committing this file DOES NOT execute it.
-- Prerequisite: apply/test 20261105_world_connect_moderation_draft.sql first,
-- including public.user_blocks and its protected RLS policies.
-- Do not activate follows until full RLS and two-user block/unblock tests pass.
-- No public signup, leader awarding, paid subscriptions, or access to private data.

create table if not exists public.nova_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followee_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint nova_no_self_follow check (follower_id <> followee_id)
);
create index if not exists nova_follows_target_idx on public.nova_follows (followee_id,created_at desc);
alter table public.nova_follows enable row level security;
revoke all on public.nova_follows from anon;
revoke all on public.nova_follows from authenticated;
grant select, insert, delete on public.nova_follows to authenticated;

drop policy if exists "nova_follows_read_own" on public.nova_follows;
create policy "nova_follows_read_own" on public.nova_follows for select to authenticated
using ((select auth.uid()) in (follower_id, followee_id) and not exists (
 select 1 from public.user_blocks b
 where (b.blocker_id = follower_id and b.blocked_id = followee_id)
    or (b.blocker_id = followee_id and b.blocked_id = follower_id)
));

drop policy if exists "nova_follows_create_self" on public.nova_follows;
create policy "nova_follows_create_self" on public.nova_follows for insert to authenticated
with check (
 follower_id = (select auth.uid())
 and follower_id <> followee_id
 and exists(select 1 from public.profiles p where p.id = followee_id)
 and not exists (
  select 1 from public.user_blocks b where
  (b.blocker_id = follower_id and b.blocked_id = followee_id)
  or (b.blocker_id = followee_id and b.blocked_id = follower_id)
 )
);

drop policy if exists "nova_follows_delete_self" on public.nova_follows;
create policy "nova_follows_delete_self" on public.nova_follows for delete to authenticated
using (follower_id = (select auth.uid()));

-- SECURITY NOTE: user_blocks only allows selecting your own outbound blocks by default.
-- PostgreSQL RLS would hide a block by the *other* person. So the policies above
-- ALONE are insufficient for reciprocal block enforcement. Apply a reviewed,
-- SECURITY DEFINER boolean helper with fixed search_path and no information-leaking
-- response, then replace the "not exists" checks with that function.
-- This migration is intentionally a SECURITY REVIEW DRAFT. DO NOT DEPLOY as-is.

create table if not exists public.nova_leader_awards (
 user_id uuid primary key references auth.users(id) on delete cascade,
 awarded_at timestamptz not null default now(),
 review_note text not null default '' check (char_length(review_note) <= 600),
 review_reference text,
 revoked_at timestamptz
);
alter table public.nova_leader_awards enable row level security;
revoke all on public.nova_leader_awards from anon;
revoke all on public.nova_leader_awards from authenticated;
grant select on public.nova_leader_awards to authenticated;
drop policy if exists "nova_leaders_awarded_only" on public.nova_leader_awards;
create policy "nova_leaders_awarded_only" on public.nova_leader_awards
 for select to authenticated using (revoked_at is null);
-- ONLY trusted server-side admins may insert/revoke leader awards.
-- Never grant INSERT/UPDATE/DELETE to authenticated browser users.
-- No payment/billing schema is included.
