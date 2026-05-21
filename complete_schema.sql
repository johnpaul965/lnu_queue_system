-- ============================================================
-- LNU REGISTRAR DOCUMENT REQUEST AND SCHEDULING SYSTEM
-- Online Registrar Document Request and Scheduling System
-- Run this ONE file in Supabase SQL Editor
-- ============================================================

-- Drop everything first
drop view if exists v_requests_overview cascade;
drop table if exists notifications cascade;
drop table if exists queue cascade;
drop table if exists qr_tokens cascade;
drop table if exists requests cascade;
drop table if exists students cascade;
drop table if exists document_types cascade;

-- ============================================================
-- 1. DOCUMENT TYPES
-- ============================================================
create table document_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  base_fee numeric(10,2) not null default 0,
  requirements text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz default now()
);

insert into document_types (name, base_fee, requirements) values
  ('Transcript of Records', 150.00, array['VPSD Clearance', 'Dean''s Approval', 'Proof of Payment / Receipt']),
  ('Certificate of Enrollment', 50.00, array['Valid School ID', 'Proof of Payment / Receipt']),
  ('Certificate of Graduation', 100.00, array['Clearance from all offices', 'Proof of Payment / Receipt']),
  ('Good Moral Certificate', 50.00, array['Valid School ID', 'Proof of Payment / Receipt']),
  ('Diploma (Replacement)', 500.00, array['Affidavit of Loss', 'Police Report', 'Clearance', 'Proof of Payment / Receipt']),
  ('Authentication of Documents', 75.00, array['Original Document for authentication', 'Valid School ID', 'Proof of Payment / Receipt']),
  ('Transfer Credentials', 200.00, array['Clearance from all offices', 'Letter of Intent', 'Proof of Payment / Receipt']);

-- ============================================================
-- 2. ADMINS (System Registrars)
-- ============================================================
drop table if exists admins cascade;
create table admins (
  id uuid primary key default gen_random_uuid(),
  auth_id uuid references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  created_at timestamptz default now()
);
alter table admins enable row level security;
create policy "Authenticated can read admins" on admins
  for select using (auth.role() = 'authenticated');
create policy "Authenticated can insert admins" on admins
  for insert with check (auth.role() = 'authenticated');
create policy "Authenticated can delete admins" on admins
  for delete using (auth.role() = 'authenticated');

-- ============================================================
-- 3. STUDENTS
-- ============================================================
create table students (
  id uuid primary key default gen_random_uuid(),
  auth_id uuid references auth.users(id) on delete cascade,
  full_name text not null,
  student_id text not null unique check (student_id ~ '^\d{7}$'),
  email text not null,
  created_at timestamptz default now()
);

-- ============================================================
-- 3. REQUESTS
-- Status flow:
--   SUBMITTED → UNDER_REVIEW → FOR_PAYMENT → PAYMENT_VERIFIED
--   → PROCESSING → FOR_CLAIMING → COMPLETED
--   OR → INCOMPLETE (needs resubmission)
--   OR → REJECTED
-- ============================================================
create table requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  document_type_id uuid references document_types(id),
  copies integer not null default 1,
  purpose text,
  base_fee numeric(10,2) not null default 0,
  assessed_fee numeric(10,2),
  status text not null default 'SUBMITTED',
  requirement_urls text[] default '{}',
  rejection_reason text,
  payment_note text,
  claim_date timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  payment_verified_at timestamptz,
  payment_verified_by uuid references auth.users(id),
  claim_scheduled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- 4. NOTIFICATIONS
-- ============================================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references students(id) on delete cascade,
  request_id uuid references requests(id) on delete cascade,
  title text not null,
  body text,
  type text,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- 5. REQUESTS OVERVIEW VIEW
-- ============================================================
create view v_requests_overview as
select
  r.id as request_id,
  r.status,
  r.copies,
  r.base_fee,
  r.assessed_fee,
  r.claim_date,
  r.created_at,
  r.updated_at,
  r.requirement_urls,
  r.rejection_reason,
  r.payment_note,
  s.id as student_id,
  s.full_name,
  s.student_id as student_number,
  s.email,
  dt.name as document_type,
  dt.id as document_type_id
from requests r
join students s on s.id = r.student_id
join document_types dt on dt.id = r.document_type_id
order by r.created_at desc;

-- ============================================================
-- 6. ENABLE ROW LEVEL SECURITY
-- ============================================================
alter table students enable row level security;
alter table requests enable row level security;
alter table notifications enable row level security;
alter table document_types enable row level security;

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

-- Document types: anyone can read
create policy "Anyone can read document types" on document_types
  for select using (true);

-- Students
create policy "Read students" on students
  for select using (auth.role() = 'authenticated');

create policy "Insert own profile" on students
  for insert with check (auth.uid() = auth_id);

-- Requests
create policy "Read requests" on requests
  for select using (auth.role() = 'authenticated');

create policy "Insert own request" on requests
  for insert with check (
    student_id in (select id from students where auth_id = auth.uid())
  );

create policy "Update requests" on requests
  for update using (auth.role() = 'authenticated');

-- Notifications
create policy "Read own notifications" on notifications
  for select using (
    student_id in (select id from students where auth_id = auth.uid())
    or auth.role() = 'authenticated'
  );

create policy "Insert notifications" on notifications
  for insert with check (auth.role() = 'authenticated');

create policy "Update notifications" on notifications
  for update using (auth.role() = 'authenticated');

-- ============================================================
-- 8. REQUIREMENTS STORAGE BUCKET
-- ============================================================
insert into storage.buckets (id, name, public)
values ('requirements', 'requirements', true)
on conflict (id) do nothing;

create policy "Upload requirements" on storage.objects
  for insert with check (
    bucket_id = 'requirements' and auth.role() = 'authenticated'
  );

create policy "View requirements" on storage.objects
  for select using (bucket_id = 'requirements');
