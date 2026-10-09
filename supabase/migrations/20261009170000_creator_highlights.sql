-- Highlights on a creator's profile, like Instagram: titled sets of photos
-- and short videos, public to everyone. Kept on the creator row as
-- [{"id", "title", "items": [{"url", "video"}]}]; only the owner can update
-- the row (existing creators policies).
alter table public.creators
  add column if not exists highlights jsonb not null default '[]'::jsonb;

-- The media bucket now also takes photos for highlights.
-- Skipped where Supabase Storage is not installed (tool/test_db.sh).
do $$
begin
  if not exists (select 1 from pg_namespace where nspname = 'storage') then
    return;
  end if;

  update storage.buckets
     set allowed_mime_types = array['video/mp4', 'video/quicktime', 'image/jpeg', 'image/png', 'image/heic']
   where id = 'exercise-media';
end
$$;
