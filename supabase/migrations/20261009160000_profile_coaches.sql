-- Chose "Da pravim programe za druge" at sign-up: the app shows the Studio tab.
alter table public.profiles
  add column coaches boolean not null default false;
