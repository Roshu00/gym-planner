-- Creators' videos of exercises live in the public "exercise-media" bucket.
-- Anyone with the link can watch (the app shows them to followers); only the
-- owner can add, replace or remove files, and only in their own folder,
-- named after their user id. Up to 50 MB, mp4 or mov.
--
-- Skipped where Supabase Storage is not installed (tool/test_db.sh).
do $$
begin
  if not exists (select 1 from pg_namespace where nspname = 'storage') then
    return;
  end if;

  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('exercise-media', 'exercise-media', true, 52428800, array['video/mp4', 'video/quicktime'])
  on conflict (id) do update
    set public = excluded.public,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

  execute $p$
    create policy "Creators add media to their own folder" on storage.objects
      for insert to authenticated
      with check (bucket_id = 'exercise-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
  $p$;
  execute $p$
    create policy "Creators replace their own media" on storage.objects
      for update to authenticated
      using (bucket_id = 'exercise-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
  $p$;
  execute $p$
    create policy "Creators remove their own media" on storage.objects
      for delete to authenticated
      using (bucket_id = 'exercise-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
  $p$;
end
$$;
