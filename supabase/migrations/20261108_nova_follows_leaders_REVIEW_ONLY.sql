-- NOVA Followers & Leaders private-beta staging migration.
-- REVIEW ONLY: committing this file DOES NOT execute it.
-- Prerequisite: apply/test 20261105_world_connect_moderation_draft.sql first,
-- including public.user_blocks and its protected RLS policies.
-- Do not activate follows until full RLS and two-user block/unblock tests pass.
-- No public signup, leader awarding, paid subscriptions, or access to private data.
-- Run manually on a staging Supabase instance AFTER reviewing the prerequisite.
-- Verify the SECURITY DEFINER owner has the required RLS bypass and is trusted.

-- Helper must be owned by a role with BYPASSRLS (e.g., postgres in SQL Editor)
-- and reviewed prior to deployment. Returns true for any request where the caller
-- is not one of the two parties, preventing arbitrary relationship probes.
create or replace function public.nova_follow_pair_blocked(a uuid,b uuid)
returns boolean language sql stable security definer set search_path = ''
as $
  select (select auth.uid()) is null
    or (select auth.uid()) not in (a,b)
    or exists (
      select 1 from public.user_blocks x
      where (x.blocker_id=a and x.blocked_id=b)
         or (x.blocker_id=b and x.blocked_id=a)
    );
$;
revoke all on function public.nova_follow_pair_blocked(uuid,uuid) from public,anon;
grant execute on function public.nova_follow_pair_blocked(uuid,uuid) to authenticated;

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
using ((select auth.uid()) in (follower_id, followee_id) and not public.nova_follow_pair_blocked(follower_id,followee_id));

drop policy if exists "nova_follows_create_self" on public.nova_follows;
create policy "nova_follows_create_self" on public.nova_follows for insert to authenticated
with check (
 follower_id = (select auth.uid())
 and follower_id <> followee_id
 and exists(select 1 from public.profiles p where p.id = followee_id)
 and not public.nova_follow_pair_blocked(follower_id,followee_id)
);

drop policy if exists "nova_follows_delete_self" on public.nova_follows;
create policy "nova_follows_delete_self" on public.nova_follows for delete to authenticated
using (follower_id = (select auth.uid()));

-- Block checks use the SECURITY DEFINER helper; test both directions and RLS ownership.

create table if not exists public.nova_leader_awards (
 user_id uuid primary key references auth.users(id) on delete cascade,
 awarded_at timestamptz not null default now(),
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
