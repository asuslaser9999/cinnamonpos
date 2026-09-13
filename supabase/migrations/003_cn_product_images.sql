-- Cinnamon POS — gambar produk + bucket storage.

alter table public.cn_products
  add column if not exists image_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'cn_product_images',
  'cn_product_images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

drop policy if exists "cn_product_images_select" on storage.objects;
create policy "cn_product_images_select"
  on storage.objects
  for select
  using (bucket_id = 'cn_product_images');

drop policy if exists "cn_product_images_insert" on storage.objects;
create policy "cn_product_images_insert"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'cn_product_images');

drop policy if exists "cn_product_images_update" on storage.objects;
create policy "cn_product_images_update"
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'cn_product_images')
  with check (bucket_id = 'cn_product_images');

drop policy if exists "cn_product_images_delete" on storage.objects;
create policy "cn_product_images_delete"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'cn_product_images');
