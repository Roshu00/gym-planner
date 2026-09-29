-- Chalkline: initial schema.
--
-- Catalog (creators, programs) is readable by everyone: it is the shop window.
-- Exercises and workouts marked 'subscribers' are readable only by subscribers
-- and by the creator who owns them. Everything a follower owns (profile, plan,
-- sessions, follows, subscriptions) is readable and writable only by them.
--
-- Sessions snapshot names and prescriptions and have no foreign keys to
-- creator content, so history stays exact when a creator edits or deletes.

create extension if not exists pgcrypto;

-- ───────────────────────── Helpers

create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ───────────────────────── Catalog

create table public.creators (
  id text primary key default gen_random_uuid()::text,
  -- Null for demo creators seeded without an account.
  user_id uuid unique references auth.users (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  handle text not null check (handle ~ '^[a-z0-9._]{3,30}$'),
  tagline text not null default '' check (length(tagline) <= 120),
  bio text not null default '' check (length(bio) <= 2000),
  -- Audience on social platforms, shown on the profile.
  followers integer not null default 0 check (followers >= 0),
  price_monthly numeric(6, 2) not null default 4.99 check (price_monthly >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index creators_handle_key on public.creators (lower(handle));

create table public.exercises (
  id text primary key default gen_random_uuid()::text,
  creator_id text not null references public.creators (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  muscle text not null check (
    muscle in ('chest', 'back', 'shoulders', 'biceps', 'triceps', 'quads', 'hamstrings', 'glutes', 'calves', 'core')
  ),
  equipment text[] not null default '{bodyweight}' check (
    equipment <@ array['barbell', 'dumbbell', 'bench', 'machine', 'cable', 'kettlebell', 'pullupBar', 'band', 'bodyweight']
  ),
  note text not null default '' check (length(note) <= 1000),
  audience text not null default 'public' check (audience in ('public', 'subscribers')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index exercises_creator_idx on public.exercises (creator_id);

create table public.workouts (
  id text primary key default gen_random_uuid()::text,
  creator_id text not null references public.creators (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  -- Ordered prescriptions: [{exerciseId, sets, repsMin, repsMax, rir, restSeconds}].
  exercises jsonb not null default '[]' check (jsonb_typeof(exercises) = 'array'),
  finish_message text not null default '' check (length(finish_message) <= 300),
  audience text not null default 'public' check (audience in ('public', 'subscribers')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index workouts_creator_idx on public.workouts (creator_id);

create table public.programs (
  id text primary key default gen_random_uuid()::text,
  creator_id text not null references public.creators (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  description text not null default '' check (length(description) <= 2000),
  -- Rotation order; the plan is not tied to dates.
  workout_ids text[] not null default '{}',
  weeks integer not null default 8 check (weeks between 1 and 52),
  days_per_week integer not null default 3 check (days_per_week between 1 and 7),
  level text not null default 'beginner' check (level in ('beginner', 'intermediate', 'advanced')),
  goal text not null default 'general' check (goal in ('strength', 'muscle', 'conditioning', 'general')),
  place text not null default 'gym' check (place in ('gym', 'home')),
  audience text not null default 'public' check (audience in ('public', 'subscribers')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index programs_creator_idx on public.programs (creator_id);

-- ───────────────────────── Follower data

create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 80),
  goal text not null check (goal in ('strength', 'muscle', 'conditioning', 'general')),
  experience text not null check (experience in ('beginner', 'intermediate', 'advanced')),
  place text not null check (place in ('gym', 'home')),
  days_per_week integer not null check (days_per_week between 1 and 7),
  equipment text[] not null default '{}' check (
    equipment <@ array['barbell', 'dumbbell', 'bench', 'machine', 'cable', 'kettlebell', 'pullupBar', 'band', 'bodyweight']
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.follows (
  user_id uuid not null references auth.users (id) on delete cascade,
  creator_id text not null references public.creators (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, creator_id)
);

-- TEMPORARY: until payments exist, a user inserts their own subscription.
-- With payments, drop the insert policy below and write rows from the payment
-- webhook with the service role.
create table public.subscriptions (
  user_id uuid not null references auth.users (id) on delete cascade,
  creator_id text not null references public.creators (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, creator_id)
);

-- The follower's copy of a program. One per user.
create table public.plans (
  id text primary key,
  user_id uuid not null unique references auth.users (id) on delete cascade,
  program_id text not null,
  creator_id text not null,
  name text not null,
  workout_ids text[] not null default '{}',
  weeks integer not null check (weeks between 1 and 52),
  days_per_week integer not null check (days_per_week between 1 and 7),
  started_at timestamptz not null,
  -- Original exercise id → replacement exercise id.
  swaps jsonb not null default '{}' check (jsonb_typeof(swaps) = 'object'),
  next_index integer not null default 0 check (next_index >= 0),
  completed integer not null default 0 check (completed >= 0),
  updated_at timestamptz not null default now()
);

-- A workout session. finished_at is null while it is running.
create table public.sessions (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_id text,
  workout_id text not null,
  workout_name text not null,
  creator_id text not null,
  creator_name text not null,
  started_at timestamptz not null,
  finished_at timestamptz check (finished_at is null or finished_at >= started_at),
  finish_message text not null default '',
  -- Snapshot: [{exerciseId, name, muscle, target, sets: [{kg, reps, rir, done, isPr}], ...}].
  exercises jsonb not null default '[]' check (jsonb_typeof(exercises) = 'array'),
  updated_at timestamptz not null default now()
);
create index sessions_user_idx on public.sessions (user_id, started_at desc);
create unique index sessions_one_active_per_user on public.sessions (user_id) where finished_at is null;

-- ───────────────────────── Triggers

create trigger creators_updated_at before update on public.creators for each row execute function public.set_updated_at();
create trigger exercises_updated_at before update on public.exercises for each row execute function public.set_updated_at();
create trigger workouts_updated_at before update on public.workouts for each row execute function public.set_updated_at();
create trigger programs_updated_at before update on public.programs for each row execute function public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger plans_updated_at before update on public.plans for each row execute function public.set_updated_at();
create trigger sessions_updated_at before update on public.sessions for each row execute function public.set_updated_at();

-- ───────────────────────── Access helpers

-- True when the current user owns [p_creator].
create or replace function public.owns_creator(p_creator text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.creators c where c.id = p_creator and c.user_id = (select auth.uid())
  );
$$;

-- True when the current user may see [p_creator]'s subscriber content.
create or replace function public.can_view_subscriber_content(p_creator text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.subscriptions s where s.creator_id = p_creator and s.user_id = (select auth.uid())
  ) or public.owns_creator(p_creator);
$$;

-- Creating a creator profile needs a real (non-anonymous) account.
create or replace function public.is_permanent_user() returns boolean
language sql stable as $$
  select (select auth.uid()) is not null
     and coalesce(((select auth.jwt()) ->> 'is_anonymous')::boolean, false) = false;
$$;

revoke all on function public.owns_creator(text) from public;
revoke all on function public.can_view_subscriber_content(text) from public;
grant execute on function public.owns_creator(text) to anon, authenticated;
grant execute on function public.can_view_subscriber_content(text) to anon, authenticated;
grant execute on function public.is_permanent_user() to anon, authenticated;

-- ───────────────────────── Row Level Security

alter table public.creators enable row level security;
alter table public.exercises enable row level security;
alter table public.workouts enable row level security;
alter table public.programs enable row level security;
alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.subscriptions enable row level security;
alter table public.plans enable row level security;
alter table public.sessions enable row level security;

-- Creators
create policy "creators are public" on public.creators
  for select to anon, authenticated using (true);
create policy "users create their own creator profile" on public.creators
  for insert to authenticated with check (user_id = (select auth.uid()) and public.is_permanent_user());
create policy "creators edit their own profile" on public.creators
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "creators delete their own profile" on public.creators
  for delete to authenticated using (user_id = (select auth.uid()));

-- Programs: metadata is public, like a product page.
create policy "programs are public" on public.programs
  for select to anon, authenticated using (true);
create policy "creators write their programs" on public.programs
  for all to authenticated using (public.owns_creator(creator_id)) with check (public.owns_creator(creator_id));

-- Exercises and workouts: public ones for all, the rest for subscribers.
create policy "exercises by audience" on public.exercises
  for select to anon, authenticated
  using (audience = 'public' or public.can_view_subscriber_content(creator_id));
create policy "creators write their exercises" on public.exercises
  for all to authenticated using (public.owns_creator(creator_id)) with check (public.owns_creator(creator_id));

create policy "workouts by audience" on public.workouts
  for select to anon, authenticated
  using (audience = 'public' or public.can_view_subscriber_content(creator_id));
create policy "creators write their workouts" on public.workouts
  for all to authenticated using (public.owns_creator(creator_id)) with check (public.owns_creator(creator_id));

-- Follower data: owner only.
create policy "own profile" on public.profiles
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own follows" on public.follows
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own subscriptions: read" on public.subscriptions
  for select to authenticated using (user_id = (select auth.uid()));
create policy "own subscriptions: subscribe (temporary, until payments)" on public.subscriptions
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "own subscriptions: cancel" on public.subscriptions
  for delete to authenticated using (user_id = (select auth.uid()));
create policy "own plan" on public.plans
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own sessions" on public.sessions
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- ───────────────────────── Grants (explicit, RLS still applies)

grant usage on schema public to anon, authenticated;
grant select on public.creators, public.programs, public.exercises, public.workouts to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
