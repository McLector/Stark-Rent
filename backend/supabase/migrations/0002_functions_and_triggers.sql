-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0002 — helper functions + triggers
-- Run order: 2nd of 6 (after 0001 tables exist).
--   • is_admin() — role check reused by every RLS policy (0003) and the RPC (0005)
--   • touch_updated_at() — keeps updated_at fresh on equipment + rentals
--   • sync_equipment_availability() — the SINGLE writer of available_quantity.
--     Reserved (booked) statuses: approved, active.
--     pending / rejected / cancelled / returned hold NO units.
--     App code never touches available_quantity itself (status updates only),
--     so trigger + app cannot double-count.
-- ═══════════════════════════════════════════════════════════════════════════════

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Keep updated_at fresh.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_equipment_touch on public.equipment;
create trigger trg_equipment_touch
  before update on public.equipment
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_rentals_touch on public.rentals;
create trigger trg_rentals_touch
  before update on public.rentals
  for each row execute function public.touch_updated_at();

-- Auto-maintain equipment.available_quantity from rental status.
create or replace function public.sync_equipment_availability()
returns trigger
language plpgsql
as $$
declare
  old_reserved boolean := false;
  new_reserved boolean := false;
  old_qty int := 0;
  new_qty int := 0;
  target_equipment uuid;
  available_now int;
begin
  if tg_op = 'INSERT' then
    if new.status in ('approved', 'active') then
      select available_quantity into available_now
      from public.equipment where id = new.equipment_id;
      if available_now is null then
        raise exception 'Equipment not found.';
      end if;
      if available_now < new.quantity then
        raise exception 'Insufficient quantity available. Only % unit(s) left.', available_now;
      end if;
      update public.equipment
      set available_quantity = available_quantity - new.quantity
      where id = new.equipment_id;
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.status in ('approved', 'active') then
      update public.equipment
      set available_quantity = least(total_quantity, available_quantity + old.quantity)
      where id = old.equipment_id;
    end if;
    return old;
  end if;

  -- UPDATE
  old_reserved := old.status in ('approved', 'active');
  new_reserved := new.status in ('approved', 'active');
  old_qty := case when old_reserved then old.quantity else 0 end;
  new_qty := case when new_reserved then new.quantity else 0 end;

  if new.equipment_id = old.equipment_id then
    if new_qty <> old_qty then
      if new_qty > old_qty then
        select available_quantity into available_now
        from public.equipment where id = new.equipment_id;
        if available_now < (new_qty - old_qty) then
          raise exception 'Insufficient quantity available. Only % unit(s) left.', available_now;
        end if;
      end if;
      update public.equipment
      set available_quantity = greatest(0, least(total_quantity, available_quantity - (new_qty - old_qty)))
      where id = new.equipment_id;
    end if;
  else
    -- Equipment swapped (app never does this, but stay correct):
    -- release old hold, take new hold.
    if old_reserved then
      update public.equipment
      set available_quantity = least(total_quantity, available_quantity + old.quantity)
      where id = old.equipment_id;
    end if;
    if new_reserved then
      select available_quantity into available_now
      from public.equipment where id = new.equipment_id;
      if available_now < new.quantity then
        raise exception 'Insufficient quantity available. Only % unit(s) left.', available_now;
      end if;
      update public.equipment
      set available_quantity = available_quantity - new.quantity
      where id = new.equipment_id;
    end if;
  end if;

  -- Return stats: count returns, flag damage for service.
  if new.status = 'returned' and old.status <> 'returned' then
    target_equipment := new.equipment_id;
    update public.equipment
    set total_rentals = total_rentals + 1,
        last_returned_at = now(),
        damaged_returns = damaged_returns
          + case when new.return_condition in ('Damaged', 'Lost') then 1 else 0 end,
        needs_maintenance = needs_maintenance
          or (new.return_condition in ('Damaged', 'Lost')),
        maintenance_notes = case
          when new.return_condition in ('Damaged', 'Lost')
            then coalesce(maintenance_notes || ' | ', '') || 'Flagged on return (' || new.return_condition || ')'
          else maintenance_notes
        end
    where id = target_equipment;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_rentals_availability on public.rentals;
create trigger trg_rentals_availability
  after insert or update or delete on public.rentals
  for each row execute function public.sync_equipment_availability();
