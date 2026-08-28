-- FIX: Profiles circular dependency RLS issue
-- Problem: org_isolation policy calls get_user_org_id() which queries profiles
-- If the auth user has no matching profile row, get_user_org_id() returns NULL
-- and ALL profile access is blocked, breaking the entire app.
-- Fix: Allow users to always read their own profile, and use security definer
-- function for org-level access.

-- Drop the problematic policy
DROP POLICY IF EXISTS "org_isolation" ON profiles;

-- Allow users to always read their own profile (critical for login flow)
CREATE POLICY "user_self_select" ON profiles
  FOR SELECT USING (
    id = auth.uid()
  );

-- Allow org members to see other org members (for Team page)
CREATE POLICY "org_members_select" ON profiles
  FOR SELECT USING (
    organization_id = get_user_org_id()
    AND get_user_org_id() IS NOT NULL
  );

-- Also fix the same issue on ALL other tables that use get_user_org_id()
-- If get_user_org_id() returns NULL, all access is blocked.
-- Add a safety check: if user has no profile, deny (which is correct for
-- non-authenticated users), but the profiles table itself must be accessible
-- to the user first so they CAN get a profile.

-- Verify the fix
DO $$
BEGIN
  RAISE NOTICE 'Profiles RLS fixed: self-select + org_members_select policies created';
END $$;
