-- NOVA shared publishing, comments, and reactions: staging-only schema draft.
-- This is NOT applied by committing to GitHub. Public publishing is OFF.
-- Prerequisites: reviewed moderation + reciprocal block functions and real authenticated profiles.
-- All new posts enter moderation as "pending"; no client can self-publish.
-- "public" means discoverable by authenticated, invited beta members after approval.
-- Anonymous access is denied. Public-at-large requires a separate future review.
create extension if not exists pgcrypto;

create table if not exists public.nova_posts (
 id uuid primary key default gen_random_uuid(),
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null default '' check (char_length(body) <= 750),
 visibility text not null default 'only_me' check (visibility in ('public','followers','only_me')),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 media_path text check (media_path is null or char_length(media_path) between 1 and 500),
 media_kind text check (media_kind is null or media_kind in ('image','video')),
 created_at timestamptz not null default now(),
 constraint nova_posts_content_required check (char_length(btrim(body))>0 or media_path is not null),
 constraint nova_posts_media_pair check ((media_path is null) = (media_kind is null))
);
create index if not exists nova_posts_author_time on public.nova_posts(author_id,created_at desc);
create index if not exists nova_posts_approved_time on public.nova_posts(status,created_at desc);

alter table public.nova_posts enable row level security;
revoke all on public.nova_posts from anon, authenticated;
grant select,insert,delete on public.nova_posts to authenticated;
drop policy if exists nova_posts_read on public.nova_posts;
create policy nova_posts_read on public.nova_posts for select to authenticated using (
 author_id=(select auth.uid())
 or (status='approved'
 and not public.nova_follow_pair_blocked((select auth.uid()),author_id)
 and (visibility='public' or (visibility='followers' and exists (
   select 1 from public.nova_follows f
   where f.follower_id=(select auth.uid()) and f.followee_id=author_id
 ))))
);
drop policy if exists nova_posts_insert on public.nova_posts;
create policy nova_posts_insert on public.nova_posts for insert to authenticated with check (
 author_id=(select auth.uid()) and status='pending'
 and media_path is null and media_kind is null
 -- Media upload requires a separately configured private bucket and validated
 -- ownership/size/type rules. Until then, only text posts can be staged.
);
drop policy if exists nova_posts_delete_own on public.nova_posts;
create policy nova_posts_delete_own on public.nova_posts for delete to authenticated using (
 author_id=(select auth.uid())
);
-- NO client UPDATE policy: moderation approvals and any edits require trusted workflows.

create table if not exists public.nova_post_comments (
 id uuid primary key default gen_random_uuid(),
 post_id uuid not null references public.nova_posts(id) on delete cascade,
 author_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(btrim(body)) between 1 and 1000),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create index if not exists nova_post_comments_post_time on public.nova_post_comments(post_id,created_at desc);
alter table public.nova_post_comments enable row level security;
revoke all on public.nova_post_comments from anon,authenticated;
grant select,insert,delete on public.nova_post_comments to authenticated;
drop policy if exists nova_comments_read on public.nova_post_comments;
create policy nova_comments_read on public.nova_post_comments for select to authenticated using (
 author_id=(select auth.uid()) or (
 status='approved'
 and exists(select 1 from public.nova_posts p where p.id=post_id and (
   p.author_id=(select auth.uid()) or p.status='approved'
 ))
 and not public.nova_follow_pair_blocked((select auth.uid()),author_id)
 )
);
drop policy if exists nova_comments_insert on public.nova_post_comments;
create policy nova_comments_insert on public.nova_post_comments for insert to authenticated with check (
 author_id=(select auth.uid()) and status='pending'
 and exists(select 1 from public.nova_posts p where p.id=post_id and p.status='approved'
 and not public.nova_follow_pair_blocked((select auth.uid()),p.author_id))
);
drop policy if exists nova_comments_delete_own on public.nova_post_comments;
create policy nova_comments_delete_own on public.nova_post_comments for delete to authenticated using (
 author_id=(select auth.uid())
);

create table if not exists public.nova_post_likes (
 post_id uuid not null references public.nova_posts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key (post_id,user_id)
);
alter table public.nova_post_likes enable row level security;
revoke all on public.nova_post_likes from anon,authenticated;
grant select,insert,delete on public.nova_post_likes to authenticated;
drop policy if exists nova_likes_read on public.nova_post_likes;
create policy nova_likes_read on public.nova_post_likes for select to authenticated using (
 user_id=(select auth.uid()) or exists (
 select 1 from public.nova_posts p where p.id=post_id
 and p.author_id=(select auth.uid()) and not public.nova_follow_pair_blocked(p.author_id,user_id)
 ));
drop policy if exists nova_likes_insert on public.nova_post_likes;
create policy nova_likes_insert on public.nova_post_likes for insert to authenticated with check (
 user_id=(select auth.uid()) and exists (
 select 1 from public.nova_posts p where p.id=post_id and p.status='approved'
 and not public.nova_follow_pair_blocked((select auth.uid()),p.author_id))
);
drop policy if exists nova_likes_delete_self on public.nova_post_likes;
create policy nova_likes_delete_self on public.nova_post_likes for delete to authenticated using(user_id=(select auth.uid()));

-- Media is intentionally blocked. Configure private Supabase Storage buckets with
-- signed access, server-side file validation, malware/CSAM handling, size limits,
-- content moderation and deletion before enabling photo/video uploading.
-- No payment/billing access is introduced.
