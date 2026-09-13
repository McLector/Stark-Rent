-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0003 — Row Level Security policies
-- Run order: 3rd of 6 (needs 0001 tables + 0002 is_admin()).
-- Model: customers CRUD their OWN rows; admins full access via is_admin().
-- Equipment catalog: authenticated users read active items; admins see all.
-- ═══════════════════════════════════════════════════════════════════════════════

alter table public.profiles           enable row level security;
alter table public.equipment          enable row level security;
alter table public.rentals            enable row level security;
alter table public.rental_messages    enable row level security;
alter table public.extension_requests enable row level security;

-- ─── profiles ─────────────────────────────────────────────────────────────────
-- Signup: authenticated user inserts their own row (id = auth.uid()).
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check (id = auth.uid());

-- Everyone logged in can read profiles (needed for chat names, customer lists).
-- Narrow later if needed.
drop policy if exists "profiles_select_auth" on public.profiles;
create policy "profiles_select_auth" on public.profiles
  for select to authenticated
  using (true);

-- Users update their own row; admins update any row (role change, deactivate).
drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- ─── equipment ────────────────────────────────────────────────────────────────
-- Any logged-in user reads active catalog items; admins see everything
-- (app also filters is_active client-side).
drop policy if exists "equipment_select_auth" on public.equipment;
create policy "equipment_select_auth" on public.equipment
  for select to authenticated
  using (is_active = true or public.is_admin());

-- Admins have full write access.
drop policy if exists "equipment_write_admin" on public.equipment;
create policy "equipment_write_admin" on public.equipment
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ─── rentals ──────────────────────────────────────────────────────────────────
-- Customers read/insert their own rentals.
drop policy if exists "rentals_select_own_or_admin" on public.rentals;
create policy "rentals_select_own_or_admin" on public.rentals
  for select to authenticated
  using (customer_id = auth.uid() or public.is_admin());

drop policy if exists "rentals_insert_own" on public.rentals;
create policy "rentals_insert_own" on public.rentals
  for insert to authenticated
  with check (customer_id = auth.uid() or public.is_admin());

-- Customers update/cancel their own; admins update any.
drop policy if exists "rentals_update_own_or_admin" on public.rentals;
create policy "rentals_update_own_or_admin" on public.rentals
  for update to authenticated
  using (customer_id = auth.uid() or public.is_admin())
  with check (customer_id = auth.uid() or public.is_admin());

drop policy if exists "rentals_delete_own_or_admin" on public.rentals;
create policy "rentals_delete_own_or_admin" on public.rentals
  for delete to authenticated
  using (customer_id = auth.uid() or public.is_admin());

-- ─── rental_messages ──────────────────────────────────────────────────────────
-- Participant = rental owner or admin.
drop policy if exists "messages_select_participant" on public.rental_messages;
create policy "messages_select_participant" on public.rental_messages
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.rentals r
      where r.id = rental_id and r.customer_id = auth.uid()
    )
  );

drop policy if exists "messages_insert_participant" on public.rental_messages;
create policy "messages_insert_participant" on public.rental_messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and (
      public.is_admin()
      or exists (
        select 1 from public.rentals r
        where r.id = rental_id and r.customer_id = auth.uid()
      )
    )
  );

drop policy if exists "messages_update_participant" on public.rental_messages;
create policy "messages_update_participant" on public.rental_messages
  for update to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.rentals r
      where r.id = rental_id and r.customer_id = auth.uid()
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.rentals r
      where r.id = rental_id and r.customer_id = auth.uid()
    )
  );

-- ─── extension_requests ───────────────────────────────────────────────────────
drop policy if exists "extensions_select_own_or_admin" on public.extension_requests;
create policy "extensions_select_own_or_admin" on public.extension_requests
  for select to authenticated
  using (customer_id = auth.uid() or public.is_admin());

drop policy if exists "extensions_insert_own" on public.extension_requests;
create policy "extensions_insert_own" on public.extension_requests
  for insert to authenticated
  with check (customer_id = auth.uid() or public.is_admin());

drop policy if exists "extensions_update_own_or_admin" on public.extension_requests;
create policy "extensions_update_own_or_admin" on public.extension_requests
  for update to authenticated
  using (customer_id = auth.uid() or public.is_admin())
  with check (customer_id = auth.uid() or public.is_admin());
