-- The first workout of a program is a free preview: anyone can read it and
-- its exercises, so a follower can try a subscribers-only program once
-- before paying. The rest of the program stays for subscribers.

-- True when [p_workout] opens some program.
create or replace function public.is_preview_workout(p_workout text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.programs p where p.workout_ids[1] = p_workout);
$$;

-- True when [p_exercise] is in a workout that opens some program.
create or replace function public.is_preview_exercise(p_exercise text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
      from public.programs p
      join public.workouts w on w.id = p.workout_ids[1]
     where w.exercises @> jsonb_build_array(jsonb_build_object('exerciseId', p_exercise))
  );
$$;

revoke all on function public.is_preview_workout(text) from public;
revoke all on function public.is_preview_exercise(text) from public;
grant execute on function public.is_preview_workout(text) to anon, authenticated;
grant execute on function public.is_preview_exercise(text) to anon, authenticated;

drop policy if exists "exercises by audience" on public.exercises;
create policy "exercises by audience" on public.exercises
  for select to anon, authenticated
  using (
    audience = 'public'
    or public.can_view_subscriber_content(creator_id)
    or public.is_preview_exercise(id)
  );

drop policy if exists "workouts by audience" on public.workouts;
create policy "workouts by audience" on public.workouts
  for select to anon, authenticated
  using (
    audience = 'public'
    or public.can_view_subscriber_content(creator_id)
    or public.is_preview_workout(id)
  );
