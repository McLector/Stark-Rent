-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0007 — drop stale pre-restart policies
-- Run order: 7th of 6+1. One-off cleanup: removes policies left by migrations
-- that ran BEFORE this set (different names, so 0003's DROP IF EXISTS could not
-- match them). Permissive policies combine with OR, so these stale rows could
-- only ever OVER-grant access beyond the 0003/0004 model. Dropping them leaves
-- exactly the 19 intended policies (15 table + 4 storage). Safe to re-run.
-- ═══════════════════════════════════════════════════════════════════════════════

-- equipment (keeps: equipment_select_auth, equipment_write_admin)
drop policy if exists "equipment_admin_write" on public.equipment;
drop policy if exists "equipment_read" on public.equipment;

-- extension_requests (keeps: extensions_select_own_or_admin, extensions_insert_own, extensions_update_own_or_admin)
drop policy if exists "ext_req_admin" on public.extension_requests;
drop policy if exists "ext_req_customer" on public.extension_requests;

-- storage.objects (keeps: equipment-images_public_read, equipment-images_auth_write/update/delete)
drop policy if exists "Admin delete equipment images" on storage.objects;
drop policy if exists "Admin update equipment images" on storage.objects;
drop policy if exists "Admin upload equipment images" on storage.objects;
drop policy if exists "Public read equipment images" on storage.objects;

-- profiles (keeps: profiles_insert_own, profiles_select_auth, profiles_update_own_or_admin)
drop policy if exists "profiles_insert_policy" on public.profiles;
drop policy if exists "profiles_select_policy" on public.profiles;
drop policy if exists "profiles_update_policy" on public.profiles;

-- rental_messages (keeps: messages_select/insert/update_participant)
drop policy if exists "messages_admin" on public.rental_messages;
drop policy if exists "messages_customer" on public.rental_messages;

-- rentals (keeps: rentals_select/insert/update/delete_own_or_admin)
drop policy if exists "rentals_admin" on public.rentals;
drop policy if exists "rentals_own" on public.rentals;
drop policy if exists "rentals_own_cancel" on public.rentals;
drop policy if exists "rentals_own_insert" on public.rentals;

-- Verify: expect exactly 19 rows afterward.
-- SELECT count(*) FROM pg_policies WHERE schemaname IN ('public','storage');
