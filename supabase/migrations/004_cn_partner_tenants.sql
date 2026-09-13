-- Cinnamon POS — penjualan via tenan lain (piutang / tagihan).

create table if not exists public.cn_partner_tenants (
  id         uuid        primary key default gen_random_uuid(),
  name       text        not null,
  notes      text        not null default '',
  is_active  boolean     not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cn_partner_tenants_name_not_empty check (trim(name) <> '')
);

create unique index if not exists idx_cn_partner_tenants_name_lower
  on public.cn_partner_tenants (lower(name));

drop trigger if exists trg_cn_partner_tenants_updated_at
  on public.cn_partner_tenants;
create trigger trg_cn_partner_tenants_updated_at
  before update on public.cn_partner_tenants
  for each row execute function public.set_updated_at();

alter table public.cn_sales
  add column if not exists channel text not null default 'own_cashier';

alter table public.cn_sales
  add column if not exists partner_tenant_id uuid
    references public.cn_partner_tenants(id) on delete set null;

alter table public.cn_sales
  add column if not exists partner_tenant_name text not null default '';

do $$
begin
  alter table public.cn_sales
    add constraint cn_sales_channel_check
    check (channel in ('own_cashier', 'via_tenant'));
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.cn_sales
    add constraint cn_sales_via_tenant_partner
    check (channel <> 'via_tenant' or partner_tenant_id is not null);
exception
  when duplicate_object then null;
end $$;

create index if not exists idx_cn_sales_channel on public.cn_sales (channel);
create index if not exists idx_cn_sales_partner_tenant
  on public.cn_sales (partner_tenant_id);

alter table public.cn_sale_payments
  drop constraint if exists cn_sale_payments_method_check;

alter table public.cn_sale_payments
  add constraint cn_sale_payments_method_check
  check (method in ('cash', 'edc', 'receivable'));

alter table public.cn_partner_tenants enable row level security;

drop policy if exists "cn_partner_tenants_select" on public.cn_partner_tenants;
create policy "cn_partner_tenants_select"
  on public.cn_partner_tenants
  for select
  using (auth.role() = 'authenticated');

drop policy if exists "cn_partner_tenants_write" on public.cn_partner_tenants;
create policy "cn_partner_tenants_write"
  on public.cn_partner_tenants
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');
