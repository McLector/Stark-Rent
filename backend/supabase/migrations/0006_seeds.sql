-- ═══════════════════════════════════════════════════════════════════════════════
-- StarkRent · migration 0006 — seed catalog (16 items, 2 per category)
-- Run order: 6th of 6. IDEMPOTENT: seeds only when the equipment table is empty;
-- re-running on a non-empty catalog skips with a NOTICE (no duplicates — the
-- table has no unique constraint on name, hence the empty-table guard).
-- Images: Unsplash URLs from src/constants/index.ts PLACEHOLDER_IMAGES.
-- Rates in Philippine pesos. weekly ≈ daily×6, monthly ≈ daily×22.
-- ═══════════════════════════════════════════════════════════════════════════════

DO $seed$
BEGIN
  IF (SELECT count(*) FROM public.equipment) > 0 THEN
    RAISE NOTICE '0006 seeds skipped: equipment table already has rows.';
    RETURN;
  END IF;

-- Excavation
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('CAT 320 Hydraulic Excavator', 'Excavation', '{Excavation}',
   '20-ton class hydraulic excavator for digging, trenching, and site prep.',
   12000, 72000, 264000, 3, 3, 'Good',
   'https://images.unsplash.com/photo-1580894908361-967195033215?w=400&q=80',
   '{"weight": "20,000 kg", "engine": "162 HP diesel", "bucket": "1.19 m³"}'),
  ('Kubota U27 Mini Excavator', 'Excavation', '{Excavation}',
   'Compact 2.7-ton mini excavator for tight urban and indoor sites.',
   4500, 27000, 99000, 4, 4, 'Excellent',
   'https://images.unsplash.com/photo-1580901368919-7738efb0f87e?w=400&q=80',
   '{"weight": "2,700 kg", "engine": "21 HP diesel", "width": "1.55 m"}');

-- Lifting
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Potain Tower Crane 8T', 'Lifting', '{Lifting}',
   '8-ton flat-top tower crane for high-rise material handling.',
   18000, 108000, 396000, 2, 2, 'Good',
   'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80',
   '{"capacity": "8,000 kg", "jib": "60 m", "height": "48 m"}'),
  ('Toyota 2.5T Diesel Forklift', 'Lifting', '{Lifting,Transport}',
   '2.5-ton diesel forklift for warehouse and yard loading.',
   3500, 21000, 77000, 5, 5, 'Good',
   'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400&q=80',
   '{"capacity": "2,500 kg", "lift_height": "4.5 m", "fuel": "diesel"}');

-- Compaction
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Bomag Plate Compactor 90kg', 'Compaction', '{Compaction}',
   '90kg vibratory plate compactor for soil, gravel, and pavers.',
   1200, 7200, 26400, 8, 8, 'Excellent',
   'https://images.unsplash.com/photo-1590856029826-c7a73142bbf1?w=400&q=80',
   '{"weight": "90 kg", "force": "15 kN", "plate": "500×350 mm"}'),
  ('Hamm Single-Drum Road Roller 12T', 'Compaction', '{Compaction}',
   '12-ton single-drum vibratory roller for road base compaction.',
   9500, 57000, 209000, 2, 2, 'Good',
   'https://images.unsplash.com/photo-1541625602330-2277a4c46182?w=400&q=80',
   '{"weight": "12,000 kg", "drum": "2.13 m", "engine": "134 HP"}');

-- Concrete
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Electric Concrete Mixer 400L', 'Concrete', '{Concrete}',
   '400L electric drum mixer for slabs, footings, and small pours.',
   1500, 9000, 33000, 6, 6, 'Good',
   'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80',
   '{"capacity": "400 L", "power": "1.5 kW", "voltage": "220 V"}'),
  ('Putzmeister Concrete Pump Truck', 'Concrete', '{Concrete,Transport}',
   'Truck-mounted boom pump for high-volume and high-rise pours.',
   15000, 90000, 330000, 1, 1, 'Fair',
   'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&q=80',
   '{"boom": "38 m", "output": "160 m³/h", "truck": "6×4 chassis"}');

-- Drilling
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Bosch Rotary Hammer Drill Set', 'Drilling', '{Drilling}',
   'SDS-max rotary hammer kit with bits for concrete and masonry.',
   800, 4800, 17600, 10, 10, 'Excellent',
   'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?w=400&q=80',
   '{"power": "1,500 W", "chuck": "SDS-max", "case": "included"}'),
  ('Atlas Copco Pneumatic Jackhammer', 'Drilling', '{Drilling,Excavation}',
   '90-lb pneumatic paving breaker for demolition and road work.',
   1800, 10800, 39600, 6, 6, 'Good',
   'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&q=80',
   '{"weight": "41 kg", "air": "90 PSI", "shank": "1-1/4 in"}');

-- Transport
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Isuzu 10-Wheeler Dump Truck', 'Transport', '{Transport}',
   '15m³ 10-wheeler dump truck for hauling aggregates and spoil.',
   8000, 48000, 176000, 4, 4, 'Good',
   'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=400&q=80',
   '{"capacity": "15 m³", "payload": "24 tons", "drive": "6×4"}'),
  ('Flatbed Trailer 40ft', 'Transport', '{Transport}',
   '40ft flatbed trailer for moving heavy equipment between sites.',
   5000, 30000, 110000, 3, 3, 'Fair',
   'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=400&q=80',
   '{"length": "40 ft", "payload": "30 tons", "axles": "3"}');

-- Power
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('Cummins 100kVA Diesel Generator', 'Power', '{Power}',
   '100kVA silent-type diesel genset for site-wide temporary power.',
   6500, 39000, 143000, 3, 3, 'Good',
   'https://images.unsplash.com/photo-1621905251189-08b45249ff78?w=400&q=80',
   '{"output": "100 kVA", "fuel_tank": "220 L", "noise": "72 dB"}'),
  ('Miller 400A Welding Machine', 'Power', '{Power}',
   '400A diesel engine-driven welder for structural steel work.',
   2200, 13200, 48400, 5, 5, 'Excellent',
   'https://images.unsplash.com/photo-1537462715879-360eeb61a0ad?w=400&q=80',
   '{"output": "400 A", "duty_cycle": "100%", "process": "SMAW/GTAW"}');

-- Safety
insert into public.equipment
  (name, category, categories, description, daily_rate, weekly_rate, monthly_rate,
   total_quantity, available_quantity, condition, image_url, specs)
values
  ('H-Frame Scaffolding Set (10 frames)', 'Safety', '{Safety}',
   '10-frame H-type scaffolding set with planks, ladders, and outriggers.',
   1000, 6000, 22000, 12, 12, 'Good',
   'https://images.unsplash.com/photo-1618090584176-7132b9911657?w=400&q=80',
   '{"frames": "10 pcs", "height": "1.7 m/frame", "load": "270 kg"}'),
  ('Fall-Arrest Harness Kit (10 sets)', 'Safety', '{Safety}',
   'Full-body harness kits with lanyards and helmets for work at height.',
   300, 1800, 6600, 20, 20, 'Excellent',
   'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=400&q=80',
   '{"sets": "10 pcs", "standard": "EN 361", "lanyard": "shock-absorbing"}');

  RAISE NOTICE '0006 seeds inserted: 16 equipment items.';
END
$seed$;

-- ─── First admin ──────────────────────────────────────────────────────────────
-- After registering through the app, promote yourself:
--   UPDATE public.profiles SET role = 'admin' WHERE email = 'you@example.com';
