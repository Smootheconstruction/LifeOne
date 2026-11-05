-- NOVA World Connect private-beta moderation schema (review before applying).
-- This migration is NOT deployed by committing it to GitHub.
create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('harassment','bullying','scam','impersonation','hate','inappropriate_content','spam','other')),
  details text not null default '' check (char_length(details) <= 2000),
  status text not null default 'pending' check (status in ('pending','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  constraint cannot_report_self check (reporter_id <> reported_user_id)
);
create index if not exists user_reports_reporter_idx on public.user_reports(reporter_id,created_at desc);
create index if not exists user_reports_pending_idx on public.user_reports(status,created_at desc);
alter table public.user_reports enable row level security;
revoke all on public.user_reports from anon;
grant select, insert on public.user_reports to authenticated;
drop policy if exists "Submit own user reports" on public.user_reports;
create policy "Submit own user reports" on public.user_reports for insert to authenticated
with check (reporter_id = (select auth.uid()) and status = 'pending');
drop policy if exists "Read own submitted reports" on public.user_reports;
create policy "Read own submitted reports" on public.user_reports for select to authenticated
using (reporter_id = (select auth.uid()));

create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id,blocked_id),
  constraint cannot_block_self check (blocker_id <> blocked_id)
);
create index if not exists user_blocks_blocked_idx on public.user_blocks(blocked_id);
alter table public.user_blocks enable row level security;
revoke all on public.user_blocks from anon;
grant select, insert, delete on public.user_blocks to authenticated;
drop policy if exists "View own blocks" on public.user_blocks;
create policy "View own blocks" on public.user_blocks for select to authenticated
using (blocker_id = (select auth.uid()));
drop policy if exists "Block other users" on public.user_blocks;
create policy "Block other users" on public.user_blocks for insert to authenticated
with check (blocker_id = (select auth.uid()));
drop policy if exists "Unblock own blocks" on public.user_blocks;
create policy "Unblock own blocks" on public.user_blocks for delete to authenticated
using (blocker_id = (select auth.uid()));

-- IMPORTANT: Blocking must also be enforced in direct_messages INSERT
-- and friend_requests INSERT/UPDATE RLS before the block UI is enabled.
-- Moderators must be granted report access through a separately reviewed
-- server-verified authorization mechanism. No client-side admin bypass.
-- Do not expose message contents or reporter identities to reported users.
