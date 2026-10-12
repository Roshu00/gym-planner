-- How an exercise is counted: weight and reps, reps alone (push-ups,
-- pull-ups) or seconds held (plank). Null means the app infers it from the
-- equipment (nothing to load counts reps).
alter table public.exercises
  add column if not exists measure text check (measure is null or measure in ('weight', 'reps', 'time'));
