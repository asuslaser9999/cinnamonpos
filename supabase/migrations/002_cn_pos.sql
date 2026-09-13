-- Cinnamon POS — master produk, transaksi kasir, pengeluaran, service charge.

create or replace function public.cn_is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.cn_profiles
    where id = auth.uid()
      and role = 'owner'
  );
$$;

alter table public.cn_store_app_settings
  add column if not exists service_charge_enabled boolean not null default false,
  add column if not exists service_charge_percent numeric(6, 2) not null default 0
    check (service_charge_percent >= 0 and service_charge_percent <= 100);

-- ─── Kategori produk ─────────────────────────────────────────────────────────

create table if not exists public.cn_product_categories (
  id         uuid        primary key default gen_random_uuid(),
  name       text        not null,
  sort_order integer     not null default 0,
  is_active  boolean     not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cn_product_categories_name_not_empty check (trim(name) <> '')
);

create unique index if not exists idx_cn_product_categories_name_lower
  on public.cn_product_categories (lower(name));

drop trigger if exists trg_cn_product_categories_updated_at
  on public.cn_product_categories;
create trigger trg_cn_product_categories_updated_at
  before update on public.cn_product_categories
  for each row execute function public.set_updated_at();

-- ─── Supplier ────────────────────────────────────────────────────────────────

create table if not exists public.cn_suppliers (
  id            uuid        primary key default gen_random_uuid(),
  supplier_name text        not null,
  phone         text,
  notes         text        not null default '',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint cn_suppliers_name_not_empty check (trim(supplier_name) <> '')
);

drop trigger if exists trg_cn_suppliers_updated_at on public.cn_suppliers;
create trigger trg_cn_suppliers_updated_at
  before update on public.cn_suppliers
  for each row execute function public.set_updated_at();

-- ─── Produk ──────────────────────────────────────────────────────────────────

create table if not exists public.cn_products (
  id            uuid           primary key default gen_random_uuid(),
  name          text           not null,
  type          text           not null
                               check (type in ('OWN_PRODUCTION', 'CONSIGNMENT')),
  category_id   uuid           not null references public.cn_product_categories(id),
  supplier_id   uuid           references public.cn_suppliers(id) on delete set null,
  cost_price    numeric(15, 2) not null default 0 check (cost_price >= 0),
  selling_price numeric(15, 2) not null default 0 check (selling_price >= 0),
  image_url     text,
  is_active     boolean        not null default true,
  created_at    timestamptz    not null default now(),
  updated_at    timestamptz    not null default now(),
  constraint cn_products_name_not_empty check (trim(name) <> ''),
  constraint cn_products_consignment_requires_supplier check (
    type <> 'CONSIGNMENT' or supplier_id is not null
  )
);

drop trigger if exists trg_cn_products_updated_at on public.cn_products;
create trigger trg_cn_products_updated_at
  before update on public.cn_products
  for each row execute function public.set_updated_at();

-- ─── Transaksi ───────────────────────────────────────────────────────────────

create table if not exists public.cn_sales (
  id                    uuid           primary key default gen_random_uuid(),
  sale_number           text           not null unique,
  sale_date             date           not null default current_date,
  sold_at               timestamptz    not null default now(),
  cashier_id            uuid           references public.cn_profiles(id) on delete set null,
  subtotal              numeric(15, 2) not null default 0 check (subtotal >= 0),
  service_charge_percent numeric(6, 2) not null default 0,
  service_charge_amount numeric(15, 2) not null default 0 check (service_charge_amount >= 0),
  total                 numeric(15, 2) not null default 0 check (total >= 0),
  status                text           not null default 'paid'
                                       check (status in ('paid', 'refunded')),
  notes                 text           not null default '',
  created_at            timestamptz    not null default now(),
  updated_at            timestamptz    not null default now()
);

create index if not exists idx_cn_sales_sale_date on public.cn_sales (sale_date);
create index if not exists idx_cn_sales_status on public.cn_sales (status);

drop trigger if exists trg_cn_sales_updated_at on public.cn_sales;
create trigger trg_cn_sales_updated_at
  before update on public.cn_sales
  for each row execute function public.set_updated_at();

create table if not exists public.cn_sale_items (
  id            uuid           primary key default gen_random_uuid(),
  sale_id       uuid           not null references public.cn_sales(id) on delete cascade,
  product_id    uuid           references public.cn_products(id) on delete set null,
  product_name  text           not null,
  product_type  text           not null
                               check (product_type in ('OWN_PRODUCTION', 'CONSIGNMENT')),
  category_name text           not null default '',
  qty           numeric(12, 2) not null check (qty > 0),
  unit_price    numeric(15, 2) not null default 0 check (unit_price >= 0),
  cost_price    numeric(15, 2) not null default 0 check (cost_price >= 0),
  line_total    numeric(15, 2) not null default 0 check (line_total >= 0),
  created_at    timestamptz    not null default now()
);

create index if not exists idx_cn_sale_items_sale_id on public.cn_sale_items (sale_id);

create table if not exists public.cn_sale_payments (
  id         uuid           primary key default gen_random_uuid(),
  sale_id    uuid           not null references public.cn_sales(id) on delete cascade,
  method     text           not null check (method in ('cash', 'edc')),
  amount     numeric(15, 2) not null check (amount > 0),
  created_at timestamptz    not null default now()
);

create index if not exists idx_cn_sale_payments_sale_id on public.cn_sale_payments (sale_id);

create table if not exists public.cn_sale_refunds (
  id          uuid           primary key default gen_random_uuid(),
  sale_id     uuid           not null references public.cn_sales(id) on delete cascade,
  cashier_id  uuid           references public.cn_profiles(id) on delete set null,
  amount      numeric(15, 2) not null check (amount >= 0),
  reason      text           not null default '',
  refunded_at timestamptz    not null default now()
);

-- ─── Pengeluaran ─────────────────────────────────────────────────────────────

create table if not exists public.cn_expenses (
  id           uuid           primary key default gen_random_uuid(),
  expense_date date           not null default current_date,
  description  text           not null,
  amount       numeric(15, 2) not null check (amount >= 0),
  created_by   uuid           references public.cn_profiles(id) on delete set null,
  created_at   timestamptz    not null default now(),
  updated_at   timestamptz    not null default now(),
  constraint cn_expenses_description_not_empty check (trim(description) <> '')
);

create index if not exists idx_cn_expenses_date on public.cn_expenses (expense_date);

drop trigger if exists trg_cn_expenses_updated_at on public.cn_expenses;
create trigger trg_cn_expenses_updated_at
  before update on public.cn_expenses
  for each row execute function public.set_updated_at();

-- ─── RLS ─────────────────────────────────────────────────────────────────────

alter table public.cn_product_categories enable row level security;
alter table public.cn_suppliers enable row level security;
alter table public.cn_products enable row level security;
alter table public.cn_sales enable row level security;
alter table public.cn_sale_items enable row level security;
alter table public.cn_sale_payments enable row level security;
alter table public.cn_sale_refunds enable row level security;
alter table public.cn_expenses enable row level security;

-- Categories
drop policy if exists "cn_categories_select" on public.cn_product_categories;
create policy "cn_categories_select" on public.cn_product_categories
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_categories_write" on public.cn_product_categories;
create policy "cn_categories_write" on public.cn_product_categories
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Suppliers
drop policy if exists "cn_suppliers_select" on public.cn_suppliers;
create policy "cn_suppliers_select" on public.cn_suppliers
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_suppliers_write" on public.cn_suppliers;
create policy "cn_suppliers_write" on public.cn_suppliers
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Products
drop policy if exists "cn_products_select" on public.cn_products;
create policy "cn_products_select" on public.cn_products
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_products_write" on public.cn_products;
create policy "cn_products_write" on public.cn_products
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- Sales
drop policy if exists "cn_sales_select" on public.cn_sales;
create policy "cn_sales_select" on public.cn_sales
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_sales_write" on public.cn_sales;
create policy "cn_sales_write" on public.cn_sales
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "cn_sale_items_select" on public.cn_sale_items;
create policy "cn_sale_items_select" on public.cn_sale_items
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_sale_items_write" on public.cn_sale_items;
create policy "cn_sale_items_write" on public.cn_sale_items
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "cn_sale_payments_select" on public.cn_sale_payments;
create policy "cn_sale_payments_select" on public.cn_sale_payments
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_sale_payments_write" on public.cn_sale_payments;
create policy "cn_sale_payments_write" on public.cn_sale_payments
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "cn_sale_refunds_select" on public.cn_sale_refunds;
create policy "cn_sale_refunds_select" on public.cn_sale_refunds
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_sale_refunds_write" on public.cn_sale_refunds;
create policy "cn_sale_refunds_write" on public.cn_sale_refunds
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

drop policy if exists "cn_expenses_select" on public.cn_expenses;
create policy "cn_expenses_select" on public.cn_expenses
  for select using (auth.role() = 'authenticated');
drop policy if exists "cn_expenses_write" on public.cn_expenses;
create policy "cn_expenses_write" on public.cn_expenses
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
