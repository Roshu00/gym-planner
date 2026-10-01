-- The follower's own changes to single calendar days: rest instead of a
-- workout, a different workout, a shorter or edited exercise list. Keyed by
-- date (YYYY-MM-DD); the plan only suggests.
alter table public.plans
  add column days jsonb not null default '{}'
  check (jsonb_typeof(days) = 'object');
