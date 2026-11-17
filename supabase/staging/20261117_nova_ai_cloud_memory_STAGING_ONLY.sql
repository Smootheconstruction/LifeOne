-- NOVA AI Cloud Memory private beta: apply ONLY to NOVA-WorldConnect-Test.
create table public.nova_ai_conversations (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 1 and 120),
 turns jsonb not null default '[]'::jsonb
   check (jsonb_typeof(turns) = 'array' and jsonb_array_length(turns) <= 100 and pg_column_size(turns) <= 150000),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index nova_ai_conversations_owner_updated
 on public.nova_ai_conversations(user_id, updated_at desc);
alter table public.nova_ai_conversations enable row level security;
revoke all on public.nova_ai_conversations from anon;
revoke all on public.nova_ai_conversations from authenticated;
grant select, insert, update, delete on public.nova_ai_conversations to authenticated;
create policy "nova_ai_select_own" on public.nova_ai_conversations
 for select to authenticated using (user_id = (select auth.uid()));
create policy "nova_ai_insert_own" on public.nova_ai_conversations
 for insert to authenticated with check (user_id = (select auth.uid()));
create policy "nova_ai_update_own" on public.nova_ai_conversations
 for update to authenticated using (user_id = (select auth.uid()))
 with check (user_id = (select auth.uid()));
create policy "nova_ai_delete_own" on public.nova_ai_conversations
 for delete to authenticated using (user_id = (select auth.uid()));
