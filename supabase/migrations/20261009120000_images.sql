-- Pictures: a creator's portrait, a cover for workouts and programs, and a
-- picture of each exercise. Null means the app shows initials, a pop color
-- or the muscle group instead. Only https links.

alter table public.creators
  add column photo_url text check (photo_url is null or (photo_url ~ '^https://' and length(photo_url) <= 1000));

alter table public.exercises
  add column image_url text check (image_url is null or (image_url ~ '^https://' and length(image_url) <= 1000));

alter table public.workouts
  add column image_url text check (image_url is null or (image_url ~ '^https://' and length(image_url) <= 1000));

alter table public.programs
  add column image_url text check (image_url is null or (image_url ~ '^https://' and length(image_url) <= 1000));
