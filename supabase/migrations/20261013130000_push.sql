-- Push notifications. The app stores each phone's Firebase token; triggers
-- queue a notification when something happens in a team; the "push" Edge
-- Function sends the queue through Firebase (see docs/PUSH.md).
--
-- What is sent:
--   reply  the trainer answered your post                 → the post's author
--   cheer  your post reached 1, 5, 10, 25, 50, 100… Bravo  → the post's author
--   note   the trainer wrote today's message               → every team member
--   record someone in the team set a record               → the trainer

create table public.push_tokens (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  token text not null check (length(token) between 10 and 4096),
  platform text not null default 'ios' check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- Filled by triggers, emptied by the Edge Function. Clients never see it.
create table public.push_queue (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}',
  created_at timestamptz not null default now(),
  sent_at timestamptz
);
create index push_queue_unsent_idx on public.push_queue (created_at) where sent_at is null;

alter table public.push_tokens enable row level security;
alter table public.push_queue enable row level security;

create policy "users keep their own tokens" on public.push_tokens
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.push_tokens to authenticated;
revoke all on public.push_queue from anon, authenticated;

-- ── Triggers. Security definer: they read across users to address the
-- notification, and write only to the queue.

create or replace function public.push_on_reply() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  author uuid;
  trainer text;
begin
  select p.user_id into author from public.team_posts p where p.id = new.post_id;
  select c.name into trainer from public.creators c where c.id = new.creator_id;
  if author is not null then
    insert into public.push_queue (user_id, title, body, data)
    values (author, coalesce(trainer, 'Tvoj trener'), new.text,
            jsonb_build_object('type', 'reply', 'creator_id', new.creator_id, 'post_id', new.post_id));
  end if;
  return new;
end;
$$;

create or replace function public.push_on_cheer() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  post record;
  total integer;
begin
  select p.user_id, p.creator_id, p.workout_name into post from public.team_posts p where p.id = new.post_id;
  if post.user_id is null or post.user_id = new.user_id then
    return new;
  end if;
  select count(*) into total from public.team_cheers where post_id = new.post_id;
  if total in (1, 5, 10, 25, 50, 100, 250, 500, 1000) then
    insert into public.push_queue (user_id, title, body, data)
    values (post.user_id, 'Bravo za ' || post.workout_name,
            case when total = 1 then 'Neko iz tima ti je rekao Bravo.'
                 else total || ' ljudi iz tima ti je reklo Bravo.' end,
            jsonb_build_object('type', 'cheer', 'creator_id', post.creator_id, 'post_id', new.post_id));
  end if;
  return new;
end;
$$;

create or replace function public.push_on_note() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  trainer record;
begin
  select c.name, c.user_id into trainer from public.creators c where c.id = new.creator_id;
  insert into public.push_queue (user_id, title, body, data)
  select m.user_id, coalesce(trainer.name, 'Tvoj trener'), new.text,
         jsonb_build_object('type', 'note', 'creator_id', new.creator_id)
    from (
      select user_id from public.follows where creator_id = new.creator_id
      union
      select user_id from public.subscriptions where creator_id = new.creator_id
    ) m
   where m.user_id is distinct from trainer.user_id;
  return new;
end;
$$;

create or replace function public.push_on_record() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  owner uuid;
begin
  if jsonb_array_length(new.records) = 0 then
    return new;
  end if;
  select c.user_id into owner from public.creators c where c.id = new.creator_id;
  if owner is not null and owner <> new.user_id then
    insert into public.push_queue (user_id, title, body, data)
    values (owner, new.author_name || ' · novi rekord', new.records ->> 0,
            jsonb_build_object('type', 'record', 'creator_id', new.creator_id, 'post_id', new.id));
  end if;
  return new;
end;
$$;

revoke all on function public.push_on_reply() from public;
revoke all on function public.push_on_cheer() from public;
revoke all on function public.push_on_note() from public;
revoke all on function public.push_on_record() from public;

create trigger push_on_reply after insert on public.team_replies
  for each row execute function public.push_on_reply();
create trigger push_on_cheer after insert on public.team_cheers
  for each row execute function public.push_on_cheer();
create trigger push_on_note after insert on public.trainer_notes
  for each row execute function public.push_on_note();
create trigger push_on_record after insert on public.team_posts
  for each row execute function public.push_on_record();
