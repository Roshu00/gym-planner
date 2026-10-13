-- The team: everyone who follows or subscribes to a creator. Members post a
-- finished workout to the team ("Pokaži timu"), cheer each other ("Bravo"),
-- and the creator replies to posts and writes a word for the day.
--
-- Who sees what: a team's posts, cheers and replies are visible to its
-- members and its creator; a creator's daily notes are public (they are
-- the shop window too). Members write only their own posts and cheers; only
-- the creator writes replies and notes.

-- True when the current user follows or subscribes to [p_creator], or owns it.
create or replace function public.in_team(p_creator text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.follows f where f.creator_id = p_creator and f.user_id = (select auth.uid())
  ) or exists (
    select 1 from public.subscriptions s where s.creator_id = p_creator and s.user_id = (select auth.uid())
  ) or public.owns_creator(p_creator);
$$;

create table public.team_posts (
  id text primary key default gen_random_uuid()::text,
  creator_id text not null references public.creators (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  author_name text not null check (length(btrim(author_name)) between 1 and 80),
  workout_name text not null check (length(workout_name) <= 120),
  -- Short labels of the records set in that workout: ["Hip thrust 45 kg"].
  records jsonb not null default '[]' check (jsonb_typeof(records) = 'array'),
  streak_weeks integer not null default 0 check (streak_weeks >= 0),
  created_at timestamptz not null default now()
);
create index team_posts_creator_idx on public.team_posts (creator_id, created_at desc);

create table public.team_cheers (
  post_id text not null references public.team_posts (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.team_replies (
  post_id text primary key references public.team_posts (id) on delete cascade,
  creator_id text not null references public.creators (id) on delete cascade,
  text text not null check (length(btrim(text)) between 1 and 500),
  created_at timestamptz not null default now()
);

create table public.trainer_notes (
  id text primary key default gen_random_uuid()::text,
  creator_id text not null references public.creators (id) on delete cascade,
  text text not null check (length(btrim(text)) between 1 and 500),
  created_at timestamptz not null default now()
);
create index trainer_notes_creator_idx on public.trainer_notes (creator_id, created_at desc);

-- Members and who trained today, without exposing who they are.
create or replace function public.team_size(p_creator text) returns integer
language sql stable security definer set search_path = '' as $$
  select count(*)::integer from (
    select user_id from public.follows where creator_id = p_creator
    union
    select user_id from public.subscriptions where creator_id = p_creator
  ) members;
$$;

create or replace function public.team_active_today(p_creator text) returns integer
language sql stable security definer set search_path = '' as $$
  select count(distinct user_id)::integer from public.team_posts
   where creator_id = p_creator and created_at >= date_trunc('day', now());
$$;

revoke all on function public.in_team(text) from public;
revoke all on function public.team_size(text) from public;
revoke all on function public.team_active_today(text) from public;
grant execute on function public.in_team(text) to authenticated;
grant execute on function public.team_size(text) to anon, authenticated;
grant execute on function public.team_active_today(text) to anon, authenticated;

alter table public.team_posts enable row level security;
alter table public.team_cheers enable row level security;
alter table public.team_replies enable row level security;
alter table public.trainer_notes enable row level security;

create policy "team sees its posts" on public.team_posts
  for select to authenticated using (public.in_team(creator_id));
create policy "members post their own workouts" on public.team_posts
  for insert to authenticated with check (user_id = (select auth.uid()) and public.in_team(creator_id));
create policy "members remove their own posts" on public.team_posts
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "team sees cheers" on public.team_cheers
  for select to authenticated using (
    exists (select 1 from public.team_posts p where p.id = post_id and public.in_team(p.creator_id))
  );
create policy "members cheer as themselves" on public.team_cheers
  for insert to authenticated with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.team_posts p where p.id = post_id and public.in_team(p.creator_id))
  );
create policy "members take back their cheer" on public.team_cheers
  for delete to authenticated using (user_id = (select auth.uid()));

create policy "team sees replies" on public.team_replies
  for select to authenticated using (public.in_team(creator_id));
create policy "creators reply in their team" on public.team_replies
  for all to authenticated
  using (public.owns_creator(creator_id))
  with check (
    public.owns_creator(creator_id)
    and exists (select 1 from public.team_posts p where p.id = post_id and p.creator_id = team_replies.creator_id)
  );

create policy "notes are public" on public.trainer_notes
  for select to anon, authenticated using (true);
create policy "creators write their notes" on public.trainer_notes
  for all to authenticated using (public.owns_creator(creator_id)) with check (public.owns_creator(creator_id));

grant select on public.trainer_notes to anon;
grant select, insert, update, delete on public.team_posts, public.team_cheers, public.team_replies, public.trainer_notes
  to authenticated;
