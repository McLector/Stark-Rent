-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0005 — RPC clear_maintenance_flag
-- Run order: 5th of 6 (needs 0001 equipment table + 0002 is_admin()).
-- Called by app/screens/Admin/Equipment/EquipmentManage.tsx after servicing
-- equipment flagged needs_maintenance (e.g. after a Damaged return).
-- ═══════════════════════════════════════════════════════════════════════════════

create or replace function public.clear_maintenance_flag(equipment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Only admins can clear maintenance flags.';
  end if;

  update public.equipment
  set needs_maintenance = false,
      maintenance_notes = null,
      updated_at = now()
  where id = equipment_id;
end;
$$;
