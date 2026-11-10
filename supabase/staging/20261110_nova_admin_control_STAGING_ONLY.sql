-- NOVA ADMIN CONTROL CENTER — STAGING / REVIEW ONLY
-- NOT applied by a GitHub commit. Do not run in production without approval.
-- Administrator assignment must be performed by trusted project operators using
-- protected administrative access, never via browser/client API.
begin;
create table if not exists public.nova_staff_roles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null check(role in ('owner','admin','moderator','support')),
 active boolean not null default true,
 assigned_at timestamptz not null default now()
);
alter table public.nova_staff_roles enable row level security;
revoke all on public.nova_staff_roles from public, anon, authenticated;
-- No client policy: even an authenticated account cannot read or self-promote.

create or replace function public.nova_admin_overview()
returns jsonb language plpgsql stable security definer
set search_path = ''
as $fn$
declare
 viewer uuid := (select auth.uid());
 is_admin boolean := false;
 counts jsonb := '{}'::jsonb;
 n bigint;
begin
 if viewer is null then
  raise exception 'unauthorized' using errcode='42501';
 end if;
 select exists(
  select 1 from public.nova_staff_roles r
  where r.user_id=viewer and r.active=true and r.role in ('owner','admin')
 ) into is_admin;
 if not is_admin then
  raise exception 'unauthorized' using errcode='42501';
 end if;
 -- Tables may not be deployed yet; null means not available, never zero.
 if to_regclass('public.profiles') is not null then
  execute 'select count(*) from public.profiles' into n;
  counts := counts || jsonb_build_object('profiles',n);
 end if;
 if to_regclass('public.nova_access_requests') is not null then
  execute 'select count(*) from public.nova_access_requests where status = $1'
  into n using 'pending';
  counts := counts || jsonb_build_object('access_requests',n);
 end if;
 if to_regclass('public.user_reports') is not null then
  execute 'select count(*) from public.user_reports where status = $1'
  into n using 'pending';
  counts := counts || jsonb_build_object('reports',n);
 end if;
 if to_regclass('public.nova_posts') is not null then
  execute 'select count(*) from public.nova_posts where status = $1'
  into n using 'pending';
  counts := counts || jsonb_build_object('pending_posts',n);
 end if;
 return jsonb_build_object('authorized',true,'counts',counts);
end
$fn$;
revoke all on function public.nova_admin_overview() from public, anon;
grant execute on function public.nova_admin_overview() to authenticated;
commit;
-- SECURITY CHECKLIST BEFORE ANY EXECUTION:
-- 1. Review SECURITY DEFINER owner, role, RLS bypass behavior, and search_path.
-- 2. Ensure only trusted operators can assign/update/revoke nova_staff_roles.
-- 3. Require MFA for admin identities and protected admin deployment access.
-- 4. Perform tests as anon, ordinary member, revoked staff, moderator, admin.
-- 5. Add audited role assignments and dedicated server-side moderation actions.
-- 6. No direct message contents should be included in overview functions.
-- 7. Never insert a user ID or assign owner permission from this migration.
