-- RLS and constraint tests. Run by tool/test_db.sh after the stub, the
-- migrations and the seed. Any failed check raises and stops the run.
\set ON_ERROR_STOP on

insert into auth.users (id, email, is_anonymous) values
  ('00000000-0000-0000-0000-00000000000a', 'ana@primer.rs', false),
  ('00000000-0000-0000-0000-00000000000b', 'boban@primer.rs', false),
  ('00000000-0000-0000-0000-00000000000c', null, true);

create or replace function pg_temp.act_as(who text) returns void language plpgsql as $$
begin
  if who = 'anon' then
    perform set_config('role', 'anon', false);
    perform set_config('request.jwt.claims', '', false);
  else
    perform set_config('role', 'authenticated', false);
    perform set_config('request.jwt.claims', json_build_object(
      'sub', case who when 'ana' then '00000000-0000-0000-0000-00000000000a'
                      when 'boban' then '00000000-0000-0000-0000-00000000000b'
                      else '00000000-0000-0000-0000-00000000000c' end,
      'is_anonymous', who = 'guest')::text, false);
  end if;
end;
$$;

create or replace function pg_temp.check(ok boolean, what text) returns void language plpgsql as $$
begin
  if not ok then raise exception 'FAILED: %', what; end if;
  raise notice 'ok: %', what;
end;
$$;

-- Runs [stmt] and returns the SQLSTATE it failed with, or null when it succeeded.
create or replace function pg_temp.fails(stmt text) returns text language plpgsql as $$
begin
  execute stmt;
  return null;
exception when others then
  return sqlstate;
end;
$$;

-- ── Anonymous visitor: the shop window only.
select pg_temp.act_as('anon');
select pg_temp.check((select count(*) from public.creators) = 3, 'anon sees creators');
select pg_temp.check((select count(*) from public.programs) = 5, 'anon sees all program pages, locked ones too');
select pg_temp.check(not exists (select 1 from public.exercises where audience = 'subscribers'), 'anon does not see subscriber exercises');
select pg_temp.check(not exists (select 1 from public.workouts where audience = 'subscribers'), 'anon does not see subscriber workouts');
select pg_temp.check(exists (select 1 from public.workouts where id = 'w_m_push'), 'anon sees public workouts');
select pg_temp.check(pg_temp.fails('select * from public.profiles') = '42501', 'anon cannot read profiles');
select pg_temp.check(pg_temp.fails($$insert into public.creators (name, handle) values ('X', 'xxx')$$) = '42501', 'anon cannot create creators');

-- ── Ana becomes a creator and publishes.
select pg_temp.act_as('ana');
insert into public.creators (id, user_id, name, handle) values ('c_ana', '00000000-0000-0000-0000-00000000000a', 'Ana', 'ana.trener');
insert into public.exercises (id, creator_id, name, muscle, equipment, audience) values
  ('a_pub', 'c_ana', 'Sklek', 'chest', '{bodyweight}', 'public'),
  ('a_sub', 'c_ana', 'Tajna vežba', 'core', '{band}', 'subscribers');
insert into public.workouts (id, creator_id, name, exercises, audience) values
  ('a_w', 'c_ana', 'Jutro', '[{"exerciseId":"a_sub","sets":3}]', 'subscribers');
insert into public.programs (id, creator_id, name, workout_ids, audience) values
  ('a_p', 'c_ana', 'Moj program', '{a_w}', 'subscribers');
select pg_temp.check((select count(*) from public.exercises where creator_id = 'c_ana') = 2, 'owner sees own subscriber content');
select pg_temp.check(
  pg_temp.fails($$insert into public.exercises (creator_id, name, muscle) values ('c_marko', 'Tuđa', 'chest')$$) = '42501',
  'cannot write into another creator''s library');
select pg_temp.check(
  pg_temp.fails($$insert into public.creators (user_id, name, handle) values ('00000000-0000-0000-0000-00000000000b', 'Lažni', 'lazni')$$) = '42501',
  'cannot create a creator for someone else');
update public.creators set name = 'Marko 2' where id = 'c_marko';
select pg_temp.check((select name from public.creators where id = 'c_marko') = 'Marko Petrović', 'cannot edit demo creators');

-- ── Boban follows, then subscribes.
select pg_temp.act_as('boban');
select pg_temp.check(not exists (select 1 from public.exercises where id = 'a_sub'), 'non-subscriber does not see subscriber exercise');
select pg_temp.check(exists (select 1 from public.exercises where id = 'a_pub'), 'non-subscriber sees public exercise');
select pg_temp.check(exists (select 1 from public.programs where id = 'a_p'), 'locked program page is visible');
insert into public.follows (user_id, creator_id) values ('00000000-0000-0000-0000-00000000000b', 'c_ana');
insert into public.subscriptions (user_id, creator_id) values ('00000000-0000-0000-0000-00000000000b', 'c_ana');
select pg_temp.check(exists (select 1 from public.exercises where id = 'a_sub'), 'subscriber sees subscriber exercise');
select pg_temp.check(exists (select 1 from public.workouts where id = 'a_w'), 'subscriber sees subscriber workout');
select pg_temp.check(
  pg_temp.fails($$insert into public.subscriptions (user_id, creator_id) values ('00000000-0000-0000-0000-00000000000a', 'c_marko')$$) = '42501',
  'cannot subscribe someone else');
select pg_temp.check(
  pg_temp.fails($$update public.exercises set note = 'hack' where id = 'a_pub'$$) is null
    and (select note from public.exercises where id = 'a_pub') = '',
  'subscriber cannot edit the creator''s content');

insert into public.profiles (user_id, name, goal, experience, place, days_per_week, equipment)
  values ('00000000-0000-0000-0000-00000000000b', 'Boban', 'strength', 'beginner', 'home', 3, '{dumbbell,band}');
insert into public.plans (id, user_id, program_id, creator_id, name, workout_ids, weeks, days_per_week, started_at)
  values ('plan_b', '00000000-0000-0000-0000-00000000000b', 'a_p', 'c_ana', 'Moj program', '{a_w}', 8, 3, now());
insert into public.sessions (id, user_id, workout_id, workout_name, creator_id, creator_name, started_at)
  values ('s1', '00000000-0000-0000-0000-00000000000b', 'a_w', 'Jutro', 'c_ana', 'Ana', now());
select pg_temp.check(
  pg_temp.fails($$insert into public.sessions (id, user_id, workout_id, workout_name, creator_id, creator_name, started_at)
    values ('s2', '00000000-0000-0000-0000-00000000000b', 'a_w', 'Jutro', 'c_ana', 'Ana', now())$$) = '23505',
  'only one running session per user');
update public.sessions set finished_at = now() + interval '1 hour' where id = 's1';
insert into public.sessions (id, user_id, workout_id, workout_name, creator_id, creator_name, started_at)
  values ('s2', '00000000-0000-0000-0000-00000000000b', 'a_w', 'Jutro', 'c_ana', 'Ana', now());
select pg_temp.check((select count(*) from public.sessions) = 2, 'a new session after finishing one');
select pg_temp.check(
  pg_temp.fails($$insert into public.plans (id, user_id, program_id, creator_id, name, weeks, days_per_week, started_at)
    values ('plan_b2', '00000000-0000-0000-0000-00000000000b', 'a_p', 'c_ana', 'X', 8, 3, now())$$) = '23505',
  'one plan per user');

-- ── The exact upserts the app sends (PostgREST: insert … on conflict).
insert into public.subscriptions (user_id, creator_id) values ('00000000-0000-0000-0000-00000000000b', 'c_ana')
  on conflict do nothing;
select pg_temp.check((select count(*) from public.subscriptions) = 1, 'repeated subscribe is a no-op');
insert into public.follows (user_id, creator_id) values ('00000000-0000-0000-0000-00000000000b', 'c_ana')
  on conflict do nothing;
insert into public.plans (id, user_id, program_id, creator_id, name, workout_ids, weeks, days_per_week, started_at)
  values ('plan_new', '00000000-0000-0000-0000-00000000000b', 'p_m_start', 'c_marko', 'Početak', '{w_m_full_a}', 6, 3, now())
  on conflict (user_id) do update set id = excluded.id, program_id = excluded.program_id, name = excluded.name;
select pg_temp.check((select id from public.plans) = 'plan_new', 'starting a new program replaces the plan');
insert into public.sessions (id, user_id, workout_id, workout_name, creator_id, creator_name, started_at, exercises)
  values ('s2', '00000000-0000-0000-0000-00000000000b', 'a_w', 'Jutro', 'c_ana', 'Ana', now(), '[{"name":"x"}]')
  on conflict (id) do update set exercises = excluded.exercises;
select pg_temp.check((select exercises from public.sessions where id = 's2') = '[{"name":"x"}]', 'session upsert updates');
insert into public.profiles (user_id, name, goal, experience, place, days_per_week)
  values ('00000000-0000-0000-0000-00000000000b', 'Boban B.', 'strength', 'beginner', 'home', 4)
  on conflict (user_id) do update set name = excluded.name, days_per_week = excluded.days_per_week;
select pg_temp.check((select days_per_week from public.profiles) = 4, 'profile upsert updates');

-- ── Ana cannot see Boban's data; Boban cancels.
select pg_temp.act_as('ana');
select pg_temp.check((select count(*) from public.sessions) = 0, 'sessions are private');
select pg_temp.check((select count(*) from public.profiles) = 0, 'profiles are private');
select pg_temp.check((select count(*) from public.subscriptions) = 0, 'subscriptions are private');
select pg_temp.act_as('boban');
delete from public.subscriptions where creator_id = 'c_ana';
select pg_temp.check(not exists (select 1 from public.exercises where id = 'a_sub'), 'cancelling locks subscriber content again');
select pg_temp.check((select count(*) from public.sessions) = 2, 'history stays after cancelling');

-- ── Guests (anonymous sign-in) train but cannot publish.
select pg_temp.act_as('guest');
insert into public.profiles (user_id, name, goal, experience, place, days_per_week)
  values ('00000000-0000-0000-0000-00000000000c', 'Gost', 'general', 'beginner', 'gym', 3);
select pg_temp.check(
  pg_temp.fails($$insert into public.creators (user_id, name, handle) values ('00000000-0000-0000-0000-00000000000c', 'Gost', 'gost.trener')$$) = '42501',
  'guests cannot create a creator profile');

-- ── Constraints.
select pg_temp.act_as('boban');
select pg_temp.check(
  pg_temp.fails($$insert into public.creators (user_id, name, handle) values ('00000000-0000-0000-0000-00000000000b', 'Boban', 'ANA.trener')$$) is not null,
  'handles are unique and lowercase');
select pg_temp.check(
  pg_temp.fails($$insert into public.creators (user_id, name, handle) values ('00000000-0000-0000-0000-00000000000b', 'Boban', 'marko.lifts')$$) = '23505',
  'handles are unique');
select pg_temp.check(
  pg_temp.fails($$update public.profiles set equipment = '{jetpack}'$$) = '23514',
  'equipment must be known');
select pg_temp.check(
  pg_temp.fails($$update public.profiles set days_per_week = 9$$) = '23514',
  'days per week between 1 and 7');

-- ── Deleting the account removes the user's data.
reset role;
delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';
select pg_temp.check(not exists (select 1 from public.creators where id = 'c_ana'), 'account deletion removes the creator');
select pg_temp.check(not exists (select 1 from public.exercises where creator_id = 'c_ana'), 'and their content');
select pg_temp.check((select count(*) from public.sessions where creator_id = 'c_ana') = 2, 'followers keep their history');

\echo 'ALL RLS TESTS PASSED'
