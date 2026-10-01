-- How the app addresses the follower in Serbian (Pojavio / Pojavila si se).
alter table public.profiles
  add column gender text not null default 'unspecified'
  check (gender in ('female', 'male', 'unspecified'));
