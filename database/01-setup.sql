-- 01-setup.sql : Site Issue Tracker - Phase 1
-- Paste this WHOLE block into the Supabase SQL Editor and press "Run" once.
-- It creates one table called "issues", turns on security rules,
-- and adds a few MADE-UP sample rows so the dashboard is not empty.

create table if not exists public.issues (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  title        text not null,
  category     text not null default 'Other'
               check (category in ('Safety','Equipment','Electrical','Environment','Road / Haulage','Water / Housing','Other')),
  location     text not null,
  urgency      text not null default 'Medium'
               check (urgency in ('Low','Medium','High')),
  status       text not null default 'Open'
               check (status in ('Open','In progress','Resolved')),
  description  text,
  reported_by  text,   -- a role or team only, e.g. "Shift B supervisor". No real names.
  action_note  text    -- what was done / decided
);

-- Keep updated_at correct whenever a row is changed
create or replace function public.issues_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists issues_updated_at on public.issues;
create trigger issues_updated_at
  before update on public.issues
  for each row execute function public.issues_set_updated_at();

-- Security: anyone with the link may read, add and update. Nobody may delete.
alter table public.issues enable row level security;

drop policy if exists "issues_select" on public.issues;
drop policy if exists "issues_insert" on public.issues;
drop policy if exists "issues_update" on public.issues;

create policy "issues_select" on public.issues
  for select to anon, authenticated using (true);
create policy "issues_insert" on public.issues
  for insert to anon, authenticated with check (true);
create policy "issues_update" on public.issues
  for update to anon, authenticated using (true) with check (true);

grant select, insert, update on public.issues to anon, authenticated;

-- MADE-UP sample data (only added if the table is empty)
insert into public.issues (created_at, title, category, location, urgency, status, description, reported_by, action_note)
select * from (values
  (now() - interval '20 days', 'Loose rock on bench edge',        'Safety',          'Pit A - North Bench', 'High',   'Resolved',    'Overhanging rock seen near bench edge after blasting.', 'Shift A supervisor', 'Area barricaded and scaled.'),
  (now() - interval '15 days', 'Dumper brake warning light',      'Equipment',       'Workshop',            'Medium', 'Resolved',    'Warning light stays on after start-up.',               'Workshop team',      'Brake sensor replaced.'),
  (now() - interval '12 days', 'Dust level high on haul road',    'Environment',     'Pit B - Haul Road',   'Medium', 'In progress', 'Water sprinkling not enough in afternoon shift.',      'Shift B supervisor', 'Extra sprinkler round planned.'),
  (now() - interval '9 days',  'Street light not working',        'Electrical',      'Colony / Township',   'Low',    'Open',        'Two street lights near the market are off.',          'Resident welfare',   null),
  (now() - interval '6 days',  'Conveyor belt misalignment',      'Equipment',       'Coal Handling Plant', 'High',   'In progress', 'Belt drifting to one side, spillage seen.',           'CHP operator',       'Maintenance crew informed.'),
  (now() - interval '4 days',  'Pothole on haul road bend',       'Road / Haulage',  'Pit B - Haul Road',   'High',   'Open',        'Deep pothole on the sharp bend, dumpers slowing down.', 'Shift C supervisor', null),
  (now() - interval '2 days',  'Water leakage in quarters',       'Water / Housing', 'Colony / Township',   'Low',    'Open',        'Pipe leaking near block C.',                           'Resident welfare',   null),
  (now() - interval '1 day',   'Weighbridge display flickering',  'Electrical',      'Weighbridge',         'Medium', 'Open',        'Display flickers and sometimes shows zero.',           'Weighbridge clerk',  null)
) as v(created_at, title, category, location, urgency, status, description, reported_by, action_note)
where not exists (select 1 from public.issues);
