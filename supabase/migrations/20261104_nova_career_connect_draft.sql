-- LifeOne NOVA Career Connect: SECURITY-FIRST SCHEMA DRAFT
-- NOT executed. Review and test on a staging Supabase project before applying.
-- Only admin/service-role operations may verify employers or publish jobs.
-- Do not place a service_role key in client code.

create extension if not exists pgcrypto;

create table if not exists public.nova_employers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  company_name text not null check (char_length(company_name) between 2 and 120),
  website text,
  location text,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.nova_jobs (
  id uuid primary key default gen_random_uuid(),
  employer_id uuid not null references public.nova_employers(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 120),
  location text not null check (char_length(location) between 2 and 120),
  arrangement text not null check (arrangement in ('full-time','part-time','contract','temporary')),
  pay_range text check (char_length(pay_range) <= 120),
  description text not null check (char_length(description) between 20 and 5000),
  status text not null default 'draft' check (status in ('draft','pending_review','published','closed','rejected')),
  created_at timestamptz not null default now(),
  published_at timestamptz
);

create table if not exists public.nova_job_applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.nova_jobs(id) on delete cascade,
  applicant_id uuid not null references auth.users(id) on delete cascade,
  message text check (char_length(message) <= 2000),
  created_at timestamptz not null default now(),
  unique (job_id, applicant_id)
);

create index if not exists nova_jobs_public_idx on public.nova_jobs(status, published_at desc);
create index if not exists nova_jobs_employer_idx on public.nova_jobs(employer_id);
create index if not exists nova_applications_applicant_idx on public.nova_job_applications(applicant_id);
create index if not exists nova_applications_job_idx on public.nova_job_applications(job_id);

alter table public.nova_employers enable row level security;
alter table public.nova_jobs enable row level security;
alter table public.nova_job_applications enable row level security;

-- Anyone can see only verified employers, but the owner can inspect their own record.
create policy nova_employers_read on public.nova_employers for select to authenticated
using (verified = true or owner_id = (select auth.uid()));

-- Unverified accounts cannot self-promote. Clients cannot UPDATE verified status.
create policy nova_employers_create on public.nova_employers for insert to authenticated
with check (owner_id = (select auth.uid()) and verified = false);
-- No client UPDATE/DELETE policy for employers; admins use trusted service role.

-- Publicly visible jobs require both published status and a verified employer.
create policy nova_jobs_read on public.nova_jobs for select to anon, authenticated
using (
  (status = 'published' and exists (
    select 1 from public.nova_employers e
    where e.id = employer_id and e.verified = true
  ))
  or (auth.role() = 'authenticated' and exists (
    select 1 from public.nova_employers e
    where e.id = employer_id and e.owner_id = (select auth.uid())
  ))
);

-- Verified employers can create DRAFTS only, never self-publish.
create policy nova_jobs_create on public.nova_jobs for insert to authenticated
with check (
  status = 'draft' and published_at is null
  and exists (select 1 from public.nova_employers e
    where e.id = employer_id and e.owner_id = (select auth.uid()) and e.verified = true)
);
-- No client UPDATE/DELETE policy for jobs. Admin workflows publish/close/update.
-- Implement employer changes as pending-review requests in a later migration.

-- Workers can apply only to published jobs from verified employers.
create policy nova_applications_create on public.nova_job_applications for insert to authenticated
with check (
 applicant_id = (select auth.uid())
 and exists (
   select 1 from public.nova_jobs j
   join public.nova_employers e on e.id = j.employer_id
   where j.id = job_id and j.status = 'published' and e.verified = true
 )
);

-- Applications are private to the applicant and the verified job owner.
create policy nova_applications_read on public.nova_job_applications for select to authenticated
using (
 applicant_id = (select auth.uid()) or exists (
  select 1 from public.nova_jobs j
  join public.nova_employers e on e.id = j.employer_id
  where j.id = job_id and e.owner_id = (select auth.uid()) and e.verified = true
 )
);
-- No client UPDATE/DELETE policies for applications in this draft.

-- Permission prerequisites: run this in staging, confirm grants and schema exposure.
-- Crucial QA: anonymous reads only published jobs, nonowners cannot read private
-- applications or draft vacancies, unverified employers cannot publish or insert
-- jobs, applicants cannot apply twice, and employer verification is admin-only.
