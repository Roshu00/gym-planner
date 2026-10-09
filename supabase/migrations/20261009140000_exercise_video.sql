-- A short clip of how an exercise is done, looped without sound in the app.
alter table public.exercises
  add column video_url text check (video_url is null or (video_url ~ '^https://' and length(video_url) <= 1000));
