-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0004 — Storage bucket equipment-images
-- Run order: 4th of 6 (independent of 0001–0003, keep order for readability).
-- Matches src/utils/imageUpload.ts: upload to `equipment/<file>`, public URL
-- via getPublicUrl for catalog images. Public read, authenticated write.
-- ═══════════════════════════════════════════════════════════════════════════════

insert into storage.buckets (id, name, public)
values ('equipment-images', 'equipment-images', true)
on conflict (id) do update set public = true;

-- Public read (catalog images via getPublicUrl).
drop policy if exists "equipment-images_public_read" on storage.objects;
create policy "equipment-images_public_read" on storage.objects
  for select to public
  using (bucket_id = 'equipment-images');

-- Logged-in users can upload (app uploads to `equipment/<file>`).
drop policy if exists "equipment-images_auth_write" on storage.objects;
create policy "equipment-images_auth_write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'equipment-images');

drop policy if exists "equipment-images_auth_update" on storage.objects;
create policy "equipment-images_auth_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'equipment-images')
  with check (bucket_id = 'equipment-images');

drop policy if exists "equipment-images_auth_delete" on storage.objects;
create policy "equipment-images_auth_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'equipment-images');
