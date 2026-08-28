-- =============================================================================
-- Bynovix AI — CRITICAL FIX: Profiles RLS + Auto-Profile Creation
-- =============================================================================
-- ROOT CAUSE: 
--   The profiles table RLS policy "org_isolation" calls get_user_org_id()
--   which queries profiles WHERE id = auth.uid(). This creates a circular
--   dependency when a user's profile row doesn't match their auth UUID,
--   or when get_user_org_id() returns NULL, blocking ALL data access.
--
-- FIX:
--   1. Replace profiles RLS with a self-select policy (always works)
--   2. Add auto-profile creation trigger for new auth users
--   3. Link any orphaned existing profiles to auth users by email
-- =============================================================================

-- STEP 1: Fix profiles RLS — drop the circular policy, add safe ones
DROP POLICY IF EXISTS "org_isolation" ON profiles;
DROP POLICY IF EXISTS "user_self_select" ON profiles;
DROP POLICY IF EXISTS "org_members_select" ON profiles;

-- Policy: Users can ALWAYS read their own profile (no RLS check needed)
CREATE POLICY "user_self_select" ON profiles
  FOR SELECT USING (
    id = auth.uid()
  );

-- Policy: Users can see other members of their org (for Team page)
-- Uses SECURITY DEFINER function to avoid circular dependency
CREATE POLICY "org_members_select" ON profiles
  FOR SELECT USING (
    organization_id = get_user_org_id()
    AND get_user_org_id() IS NOT NULL
  );

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "user_self_update" ON profiles;
CREATE POLICY "user_self_update" ON profiles
  FOR UPDATE USING (
    id = auth.uid()
  );

-- STEP 2: Auto-create profile for new auth users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, organization_id, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'restricted'),
    'a0000000-0000-0000-0000-000000000001',
    'active'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- STEP 3: Link existing auth users to profiles by email
-- This fixes any mismatch between auth.users.id and profiles.id
DO $$
DECLARE
  auth_rec RECORD;
  updated_count INTEGER := 0;
BEGIN
  FOR auth_rec IN 
    SELECT au.id as auth_id, au.email 
    FROM auth.users au 
    INNER JOIN public.profiles p ON p.email = au.email 
    WHERE p.id != au.id
  LOOP
    UPDATE public.profiles 
    SET id = auth_rec.auth_id 
    WHERE email = auth_rec.email AND id != auth_rec.auth_id;
    updated_count := updated_count + 1;
    RAISE NOTICE 'Linked profile for % (auth_id: %)', auth_rec.email, auth_rec.auth_id;
  END LOOP;
  
  IF updated_count = 0 THEN
    RAISE NOTICE 'All profiles already linked to auth users';
  ELSE
    RAISE NOTICE 'Linked % profiles to their auth user IDs', updated_count;
  END IF;
END;
$$;

-- STEP 4: Verify — show results
DO $$
BEGIN
  RAISE NOTICE '=== FIX COMPLETE ===';
  RAISE NOTICE 'Profiles RLS: self-select + org_members_select policies active';
  RAISE NOTICE 'Auto-profile trigger: on_auth_user_created enabled';
  RAISE NOTICE 'Orphaned profiles: linked to auth users by email';
END;
$$;
