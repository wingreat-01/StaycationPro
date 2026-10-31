-- StaycationPro: self-service account deletion.
-- Run this once in the Supabase dashboard (SQL Editor) after 002_listing_photos.sql.

-- Lets a signed-in user list their own photo folder, so the deletion page
-- can remove their photos through the Storage API before deleting the account.
create policy "List own listing photos" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'listing-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Deletes the signed-in user's account. Removing the auth user cascades to
-- their profile, listings and bookings (see schema.sql foreign keys).
-- Photos must be removed first via the Storage API, which the page does.
create function public.delete_my_account()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'You need to confirm your email before deleting your account.';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
