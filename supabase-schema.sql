-- ============================================================
-- FieldSales NZ — Supabase Schema
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- Enable UUID extension (already on by default in Supabase)
create extension if not exists "uuid-ossp";

-- ============================================================
-- CUSTOMERS
-- ============================================================
create table if not exists customers (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  "group"     text not null default '',
  region      text not null default 'Auckland, New Zealand',
  status      text not null default 'ok'
                check (status in ('ok','risk','elsewhere','monitor','inactive')),
  address     text not null default '',
  phone       text not null default '',
  email       text not null default '',
  notes       text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ============================================================
-- CONTACTS  (linked to customers)
-- ============================================================
create table if not exists contacts (
  id           uuid primary key default uuid_generate_v4(),
  customer_id  uuid not null references customers(id) on delete cascade,
  name         text not null,
  role         text not null default '',
  phone        text not null default '',
  email        text not null default '',
  created_at   timestamptz not null default now()
);

-- ============================================================
-- CALLS  (sales call log)
-- ============================================================
create table if not exists calls (
  id           uuid primary key default uuid_generate_v4(),
  customer_id  uuid not null references customers(id) on delete cascade,
  call_date    date not null,
  notes        text not null default '',
  created_at   timestamptz not null default now()
);

-- ============================================================
-- CUSTOMER DOCUMENTS  (photos + files per customer profile)
-- ============================================================
create table if not exists customer_documents (
  id           uuid primary key default uuid_generate_v4(),
  customer_id  uuid not null references customers(id) on delete cascade,
  category     text not null default 'Other'
                 check (category in ('Planogram','Price List','Contract','Photo','Other')),
  file_name    text not null,
  file_type    text not null,   -- MIME type e.g. image/jpeg, application/pdf
  storage_path text not null,   -- path inside the Supabase Storage bucket
  size_bytes   integer,
  caption      text not null default '',
  created_at   timestamptz not null default now()
);

-- ============================================================
-- CALL ATTACHMENTS  (photos + docs attached to a specific call)
-- ============================================================
create table if not exists call_attachments (
  id           uuid primary key default uuid_generate_v4(),
  call_id      uuid not null references calls(id) on delete cascade,
  customer_id  uuid not null references customers(id) on delete cascade,
  file_name    text not null,
  file_type    text not null,
  storage_path text not null,
  size_bytes   integer,
  created_at   timestamptz not null default now()
);

-- ============================================================
-- AUTO-UPDATE updated_at on customers
-- ============================================================
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists customers_updated_at on customers;
create trigger customers_updated_at
  before update on customers
  for each row execute function update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- (keeps data private — each user only sees their own rows)
-- For a single-user / single-team app you can skip RLS and
-- just use the service_role key, but this is best practice.
-- ============================================================

alter table customers           enable row level security;
alter table contacts            enable row level security;
alter table calls               enable row level security;
alter table customer_documents  enable row level security;
alter table call_attachments    enable row level security;

-- Allow full access via the anon key (public app, no auth yet).
-- When you add Supabase Auth later, replace "true" with:
--   auth.uid() = owner_id   (after adding an owner_id column)

create policy "allow_all_customers"          on customers          for all using (true) with check (true);
create policy "allow_all_contacts"           on contacts           for all using (true) with check (true);
create policy "allow_all_calls"              on calls              for all using (true) with check (true);
create policy "allow_all_customer_documents" on customer_documents for all using (true) with check (true);
create policy "allow_all_call_attachments"   on call_attachments   for all using (true) with check (true);

-- ============================================================
-- STORAGE BUCKET
-- Run this AFTER creating the bucket in the Supabase dashboard
-- (Storage → New bucket → name: "fieldsales-media" → Public: ON)
-- ============================================================

-- Storage policy — allow upload/read for everyone (adjust when you add auth)
insert into storage.buckets (id, name, public)
values ('fieldsales-media', 'fieldsales-media', true)
on conflict (id) do nothing;

create policy "allow_upload" on storage.objects
  for insert with check (bucket_id = 'fieldsales-media');

create policy "allow_read" on storage.objects
  for select using (bucket_id = 'fieldsales-media');

create policy "allow_delete" on storage.objects
  for delete using (bucket_id = 'fieldsales-media');
