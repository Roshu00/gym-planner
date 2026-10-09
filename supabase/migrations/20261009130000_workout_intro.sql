-- One sentence from the creator before a workout, shown on the Today screen.
alter table public.workouts
  add column intro text not null default '' check (length(intro) <= 200);
