-- Weekdays a follower plans to train (1 = Monday … 7 = Sunday). The Plan
-- calendar forecasts upcoming workouts on these days.
alter table public.plans
  add column training_days smallint[] not null default '{}'
  check (training_days <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]);
