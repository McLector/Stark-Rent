-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0001 — extensions, tables, indexes
-- Run order: 1st of 6. Files in backend/supabase/migrations/ run in name order.
-- Paste each file into Supabase Dashboard → SQL Editor → Run, in order.
--
-- NOTE: no native PG enums are used; constrained TEXT columns + CHECKs act as
-- enums (role, duration_type, status, sender_role). Kept as TEXT so the app can
-- evolve status values without enum migrations.
--
-- Column-name notes (code is truth):
--   • rental_messages.sender_role  — required by app/screens/Chat/RentalChat.tsx
--   • extension_requests.customer_note / admin_note — required by
--     CustomerRentalDetail.tsx + ExtensionRequests.tsx (app never writes `reason`)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Extensions ───────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ─── profiles: one row per auth user ──────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text not null,
  full_name   text not null,
  phone       text not null default '',
  role        text not null default 'customer' check (role in ('admin', 'customer')),
  avatar_url  text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ─── equipment: rental catalog ────────────────────────────────────────────────
create table if not exists public.equipment (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  category           text not null,            -- primary category (legacy) = categories[0]
  categories         text[] not null default '{}', -- multi-category
  description        text not null default '',
  daily_rate         numeric not null default 0 check (daily_rate >= 0),
  weekly_rate        numeric not null default 0 check (weekly_rate >= 0),
  monthly_rate       numeric not null default 0 check (monthly_rate >= 0),
  total_quantity     int not null default 1 check (total_quantity >= 0),
  available_quantity int not null default 1 check (available_quantity >= 0),
  condition          text not null default 'Good',
  image_url          text not null default '',
  specs              jsonb not null default '{}',
  is_active          boolean not null default true,
  needs_maintenance  boolean not null default false,
  maintenance_notes  text,
  total_rentals      int not null default 0,
  damaged_returns    int not null default 0,
  last_returned_at   timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- ─── rentals: full lifecycle pending → approved → active → returned ──────────
create table if not exists public.rentals (
  id            uuid primary key default gen_random_uuid(),
  customer_id   uuid not null references public.profiles (id) on delete cascade,
  equipment_id  uuid not null references public.equipment (id) on delete restrict,
  quantity      int not null default 1 check (quantity >= 1),
  start_date    date not null,
  end_date      date not null check (end_date > start_date),
  duration_type text not null default 'daily' check (duration_type in ('daily', 'weekly', 'monthly')),
  total_cost    numeric not null default 0 check (total_cost >= 0),
  status        text not null default 'pending'
                check (status in ('pending', 'approved', 'active', 'returned', 'rejected', 'cancelled')),
  notes         text,
  admin_notes   text,
  return_condition text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ─── rental_messages: per-rental chat (realtime enabled by client) ────────────
create table if not exists public.rental_messages (
  id         uuid primary key default gen_random_uuid(),
  rental_id  uuid not null references public.rentals (id) on delete cascade,
  sender_id  uuid not null references public.profiles (id) on delete cascade,
  sender_role text not null default 'customer' check (sender_role in ('admin', 'customer')),
  message    text not null,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

-- ─── extension_requests: customer asks for later end_date ────────────────────
create table if not exists public.extension_requests (
  id                 uuid primary key default gen_random_uuid(),
  rental_id          uuid not null references public.rentals (id) on delete cascade,
  customer_id        uuid not null references public.profiles (id) on delete cascade,
  requested_end_date date not null,
  reason             text, -- legacy/free-form reason (app writes customer_note)
  customer_note      text,
  admin_note         text,
  status             text not null default 'pending'
                     check (status in ('pending', 'approved', 'rejected')),
  created_at         timestamptz not null default now()
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────
create index if not exists idx_equipment_category    on public.equipment (category);
create index if not exists idx_equipment_is_active   on public.equipment (is_active);
create index if not exists idx_rentals_customer      on public.rentals (customer_id);
create index if not exists idx_rentals_equipment     on public.rentals (equipment_id);
create index if not exists idx_rentals_status        on public.rentals (status);
create index if not exists idx_rentals_dates         on public.rentals (equipment_id, start_date, end_date);
create index if not exists idx_messages_rental       on public.rental_messages (rental_id, created_at);
create index if not exists idx_extension_rental      on public.extension_requests (rental_id);
create index if not exists idx_extension_customer    on public.extension_requests (customer_id);
create index if not exists idx_profiles_role         on public.profiles (role);

-- ─── Reconciliation ─────────────────────────────────────────────────────────────
-- If this project ran EARLIER migrations, tables may already exist WITHOUT some
-- columns below. CREATE TABLE IF NOT EXISTS will not add them, so backfill every
-- column the app code reads/writes. Each statement is a no-op when the column
-- already exists. Safe to run on fresh and partially-migrated databases.
alter table public.profiles
  add column if not exists phone      text not null default '',
  add column if not exists avatar_url text,
  add column if not exists is_active  boolean not null default true;

alter table public.equipment
  add column if not exists category           text,
  add column if not exists categories         text[] not null default '{}',
  add column if not exists description        text not null default '',
  add column if not exists daily_rate         numeric not null default 0,
  add column if not exists weekly_rate        numeric not null default 0,
  add column if not exists monthly_rate       numeric not null default 0,
  add column if not exists total_quantity     int not null default 1,
  add column if not exists available_quantity int not null default 1,
  add column if not exists condition          text not null default 'Good',
  add column if not exists image_url          text not null default '',
  add column if not exists specs              jsonb not null default '{}',
  add column if not exists is_active          boolean not null default true,
  add column if not exists needs_maintenance  boolean not null default false,
  add column if not exists maintenance_notes  text,
  add column if not exists total_rentals      int not null default 0,
  add column if not exists damaged_returns    int not null default 0,
  add column if not exists last_returned_at   timestamptz,
  add column if not exists updated_at         timestamptz not null default now();

alter table public.rentals
  add column if not exists duration_type    text not null default 'daily',
  add column if not exists notes            text,
  add column if not exists admin_notes      text,
  add column if not exists return_condition text,
  add column if not exists updated_at       timestamptz not null default now();

alter table public.rental_messages
  add column if not exists sender_role text not null default 'customer',
  add column if not exists is_read     boolean not null default false;

alter table public.extension_requests
  add column if not exists requested_end_date date,
  add column if not exists reason             text,
  add column if not exists customer_note      text,
  add column if not exists admin_note         text,
  add column if not exists status             text not null default 'pending';
