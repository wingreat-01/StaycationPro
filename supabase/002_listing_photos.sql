-- StaycationPro: photo storage for listings.
-- Run this once in the Supabase dashboard (SQL Editor) after schema.sql.

-- Public bucket: anyone with the link can view a photo, which is what
-- listing photos need. Max 5 MB, images only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'listing-photos',
  'listing-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Each user can only write inside their own folder: <user id>/<file>.
create policy "Upload own listing photos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Update own listing photos" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Delete own listing photos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
