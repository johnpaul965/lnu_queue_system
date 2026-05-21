-- ============================================================
-- RUN THIS IN YOUR SUPABASE SQL EDITOR
-- Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- ============================================================

-- Create admins table (stores registrar accounts)
CREATE TABLE IF NOT EXISTS admins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all registrars
CREATE POLICY IF NOT EXISTS "Authenticated can read admins" ON admins
  FOR SELECT USING (auth.role() = 'authenticated');

-- Allow authenticated users to insert new registrars
CREATE POLICY IF NOT EXISTS "Authenticated can insert admins" ON admins
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to delete registrars
CREATE POLICY IF NOT EXISTS "Authenticated can delete admins" ON admins
  FOR DELETE USING (auth.role() = 'authenticated');

-- Update the existing admin account role to 'admin' (System Administrator)
-- Replace the ID below with your actual admin user's auth ID if different
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'),
  '{role}',
  '"admin"'
)
WHERE email = 'admin@lnu.edu.ph';

-- Update the existing registrar account role to 'staff'
-- (If you have an existing registrar using role='admin', update them to 'staff')
-- UPDATE auth.users
-- SET raw_user_meta_data = jsonb_set(
--   COALESCE(raw_user_meta_data, '{}'),
--   '{role}',
--   '"staff"'
-- )
-- WHERE email = 'registrar@lnu.edu.ph';
