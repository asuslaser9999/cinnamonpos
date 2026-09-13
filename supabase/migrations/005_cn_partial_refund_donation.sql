-- Cinnamon POS — refund sebagian + donasi pembulatan tunai.

alter table public.cn_store_app_settings
  add column if not exists cash_donation_rounding_enabled boolean not null default false;

alter table public.cn_sales
  add column if not exists donation_amount numeric(15, 2) not null default 0
    check (donation_amount >= 0);

alter table public.cn_sale_items
  add column if not exists qty_refunded numeric(12, 2) not null default 0;

do $$
begin
  alter table public.cn_sale_items
    add constraint cn_sale_items_qty_refunded_range
    check (qty_refunded >= 0 and qty_refunded <= qty);
exception
  when duplicate_object then null;
end $$;

alter table public.cn_sales drop constraint if exists cn_sales_status_check;
alter table public.cn_sales
  add constraint cn_sales_status_check
  check (status in ('paid', 'partial_refund', 'refunded'));

alter table public.cn_sale_refunds
  add column if not exists items_amount numeric(15, 2) not null default 0
    check (items_amount >= 0);

alter table public.cn_sale_refunds
  add column if not exists service_amount numeric(15, 2) not null default 0
    check (service_amount >= 0);

alter table public.cn_sale_refunds
  add column if not exists donation_amount numeric(15, 2) not null default 0
    check (donation_amount >= 0);

create table if not exists public.cn_sale_refund_items (
  id           uuid           primary key default gen_random_uuid(),
  refund_id    uuid           not null references public.cn_sale_refunds(id) on delete cascade,
  sale_item_id uuid           references public.cn_sale_items(id) on delete set null,
  product_name text           not null,
  qty          numeric(12, 2) not null check (qty > 0),
  unit_price   numeric(15, 2) not null default 0 check (unit_price >= 0),
  line_total   numeric(15, 2) not null default 0 check (line_total >= 0),
  created_at   timestamptz    not null default now()
);

create index if not exists idx_cn_sale_refund_items_refund_id
  on public.cn_sale_refund_items (refund_id);

alter table public.cn_sale_refund_items enable row level security;

drop policy if exists "cn_sale_refund_items_select" on public.cn_sale_refund_items;
create policy "cn_sale_refund_items_select"
  on public.cn_sale_refund_items
  for select
  using (auth.role() = 'authenticated');

drop policy if exists "cn_sale_refund_items_write" on public.cn_sale_refund_items;
create policy "cn_sale_refund_items_write"
  on public.cn_sale_refund_items
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
