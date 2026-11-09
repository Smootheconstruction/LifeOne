-- NOVA World Connect: EMPTY STAGING PROJECT ONLY — REVIEW BEFORE RUNNING.
-- Do not run on the existing production project. This creates blank tables and
-- secure policies matching the World Connect browser app's current field names.
-- Based on the owner's inspected production columns/policy expressions.
-- No customer profiles, user accounts, or messages are copied.
-- Auth accounts must be created separately via invitation after verifying
-- Supabase Auth settings. Do not enable public self-signup.
--
-- Intentionally NOT an auto-applied migration. Review and manually test.
begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'NOVA Explorer'
    check (char_length(btrim(display_name)) between 1 and 80),
  bio text not null default '' check (char_length(bio) <= 500)
);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select,insert,update on public.profiles to authenticated;
create policy "Create your profile" on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy "Edit your profile" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "Profiles visible to logged-in testers" on public.profiles
  for select to authenticated using (true);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  unique(sender_id,receiver_id),
  check(sender_id <> receiver_id)
);
create index friend_requests_receiver_idx on public.friend_requests(receiver_id,status);
alter table public.friend_requests enable row level security;
revoke all on public.friend_requests from anon, authenticated;
grant select,insert,update,delete on public.friend_requests to authenticated;
create policy "Requests visible to participants" on public.friend_requests
  for select to authenticated
  using(sender_id=(select auth.uid()) or receiver_id=(select auth.uid()));
create policy "Send pending requests" on public.friend_requests
  for insert to authenticated
  with check(sender_id=(select auth.uid()) and status='pending');
create policy "Recipient accepts requests" on public.friend_requests
  for update to authenticated
  using(receiver_id=(select auth.uid()) and status='pending')
  with check(receiver_id=(select auth.uid()) and status='accepted');
create policy "Participants remove requests" on public.friend_requests
  for delete to authenticated
  using(sender_id=(select auth.uid()) or receiver_id=(select auth.uid()));

create table public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  body text not null check(char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  check(sender_id <> recipient_id)
);
create index direct_messages_parties_idx on public.direct_messages(sender_id,recipient_id,created_at);
create index direct_messages_recipient_idx on public.direct_messages(recipient_id,created_at);
alter table public.direct_messages enable row level security;
revoke all on public.direct_messages from anon, authenticated;
grant select,insert on public.direct_messages to authenticated;
create policy "Read own messages" on public.direct_messages
  for select to authenticated
  using(sender_id=(select auth.uid()) or recipient_id=(select auth.uid()));
create policy "Send only to accepted friends" on public.direct_messages
  for insert to authenticated
  with check(sender_id=(select auth.uid()) and exists(
    select 1 from public.friend_requests f
    where f.status='accepted'
    and ((f.sender_id=sender_id and f.receiver_id=recipient_id)
      or (f.receiver_id=sender_id and f.sender_id=recipient_id))
  ));

commit;

-- NEXT, while still in empty staging:
-- 1. Apply the reviewed friend-request immutability guard (REVIEW_ONLY).
-- 2. Apply reviewed moderation + block RLS drafts in dependency order.
-- 3. Use 2 independent invited accounts to verify permissions/negative cases.
-- 4. Compare this STAGING approximation with full production schema before
--    considering any deployment to production.
--
-- Caveat: The original production direct_messages table definition was NOT
-- exported by the owner. This is a minimal compatible staging design, not a
-- verified byte-for-byte reproduction of their production database.
