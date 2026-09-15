-- Cinnamon POS — rekap stok harian (awal, sisa). Qty terjual dihitung dari penjualan.

create table if not exists public.cn_daily_stock (
  id           uuid           primary key default gen_random_uuid(),
  stock_date   date           not null default current_date,
  product_id   uuid           not null references public.cn_products(id) on delete cascade,
  opening_qty  numeric(12, 2) not null default 0 check (opening_qty >= 0),
  closing_qty  numeric(12, 2) check (closing_qty is null or closing_qty >= 0),
  notes        text           not null default '',
  updated_by   uuid           references public.cn_profiles(id) on delete set null,
  created_at   timestamptz    not null default now(),
  updated_at   timestamptz    not null default now(),
  constraint cn_daily_stock_date_product unique (stock_date, product_id)
);

create index if not exists idx_cn_daily_stock_date
  on public.cn_daily_stock (stock_date);

drop trigger if exists trg_cn_daily_stock_updated_at on public.cn_daily_stock;
create trigger trg_cn_daily_stock_updated_at
  before update on public.cn_daily_stock
  for each row execute function public.set_updated_at();

alter table public.cn_daily_stock enable row level security;

drop policy if exists "cn_daily_stock_select" on public.cn_daily_stock;
create policy "cn_daily_stock_select"
  on public.cn_daily_stock
  for select
  using (auth.role() = 'authenticated');

drop policy if exists "cn_daily_stock_write" on public.cn_daily_stock;
create policy "cn_daily_stock_write"
  on public.cn_daily_stock
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
