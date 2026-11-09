-- NOVA World Connect staged access requests — STAGING ONLY.
-- This DOES NOT create login accounts, enable public Auth signup, or send emails.
-- Apply to NOVA-WorldConnect-Test only, following review. Not production.
-- Applicants can submit a request but cannot read anyone's email or application.
-- Project administrators review in Supabase Table Editor and invite approved
-- users manually under Authentication > Users > Add user > Send invitation.
-- This is a basic beta queue. Add server-side rate limiting/CAPTCHA before broad exposure.
begin;
create table if not exists public.nova_access_requests (
 id uuid primary key default gen_random_uuid(),
 display_name text not null check (char_length(btrim(display_name)) between 2 and 70),
 email text not null check (char_length(btrim(email)) between 5 and 254 and email ~* '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$'),
 reason text not null default '' check (char_length(reason) <= 300),
 status text not null default 'pending' check (status in ('pending','approved','declined')),
 created_at timestamptz not null default now()
);
create index if not exists nova_access_requests_time on public.nova_access_requests(created_at desc);
alter table public.nova_access_requests enable row level security;
revoke all on public.nova_access_requests from public, anon, authenticated;
grant insert (display_name,email,reason) on public.nova_access_requests to anon;
drop policy if exists nova_access_request_submit on public.nova_access_requests;
create policy nova_access_request_submit on public.nova_access_requests
 for insert to anon with check (
   status='pending'
   and char_length(btrim(display_name)) between 2 and 70
   and char_length(btrim(email)) between 5 and 254
   and char_length(reason) <= 300
 );
-- Deliberately no SELECT, UPDATE or DELETE policies for anon or authenticated.
-- Supabase dashboard administrators can review through privileged dashboard SQL/Table Editor.
commit;
-- After approval in the admin dashboard, invite the user in Authentication > Users.
-- Inviting is MANUAL and does not happen automatically when a row is approved.
-- Do not publish the queue, expose a secret key, or enable open self-signup.
