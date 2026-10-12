-- Pictures may also be ones bundled in the app (assets/trainers), written as
-- `asset:assets/trainers/<trainer>/<file>`: the photos of the trainers who
-- joined before launch. Everything else stays an https link.

alter table public.creators drop constraint if exists creators_photo_url_check;
alter table public.creators add constraint creators_photo_url_check check (
  photo_url is null or (
    (photo_url ~ '^https://' or photo_url ~ '^asset:assets/trainers/[a-z0-9_/.-]+$') and length(photo_url) <= 1000
  )
);

alter table public.exercises drop constraint if exists exercises_image_url_check;
alter table public.exercises add constraint exercises_image_url_check check (
  image_url is null or (
    (image_url ~ '^https://' or image_url ~ '^asset:assets/trainers/[a-z0-9_/.-]+$') and length(image_url) <= 1000
  )
);

alter table public.workouts drop constraint if exists workouts_image_url_check;
alter table public.workouts add constraint workouts_image_url_check check (
  image_url is null or (
    (image_url ~ '^https://' or image_url ~ '^asset:assets/trainers/[a-z0-9_/.-]+$') and length(image_url) <= 1000
  )
);

alter table public.programs drop constraint if exists programs_image_url_check;
alter table public.programs add constraint programs_image_url_check check (
  image_url is null or (
    (image_url ~ '^https://' or image_url ~ '^asset:assets/trainers/[a-z0-9_/.-]+$') and length(image_url) <= 1000
  )
);
