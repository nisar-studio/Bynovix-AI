-- =============================================================================
-- Bynovix AI — Governance Enforcement Functions
-- Generated: August 24, 2026
--
-- These functions enforce authoritative rules server-side.
-- They read from org_policies, not from frontend configuration.
-- =============================================================================

-- =============================================================================
-- 1. can_auto_execute()
-- Checks if an automated AI action is permitted based on org policies.
-- Enforces: AI confidence gate (90%), critical severity human approval
-- =============================================================================
CREATE OR REPLACE FUNCTION can_auto_execute(
  p_confidence numeric,
  p_severity text,
  p_org_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_policies record;
BEGIN
  SELECT * INTO v_policies FROM org_policies WHERE organization_id = p_org_id;

  IF NOT FOUND THEN
    -- No policies configured: deny by default (fail-closed)
    RETURN false;
  END IF;

  -- Check AI confidence gate (default: 90%)
  IF p_confidence < v_policies.ai_confidence_gate THEN
    RETURN false;
  END IF;

  -- Critical severity always requires human approval
  IF p_severity = 'critical' AND v_policies.critical_requires_human_approval THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$$;

-- =============================================================================
-- 2. check_failed_login()
-- Enforces failed-login threshold per organization.
-- Returns true if login is allowed, false if threshold exceeded.
-- =============================================================================
CREATE OR REPLACE FUNCTION check_failed_login(
  p_email text,
  p_org_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_threshold integer;
  v_recent_failures bigint;
BEGIN
  SELECT failed_login_threshold INTO v_threshold
  FROM org_policies WHERE organization_id = p_org_id;

  IF NOT FOUND THEN
    v_threshold := 5; -- Safe default
  END IF;

  -- Count failed login attempts in the last 15 minutes
  SELECT count(*) INTO v_recent_failures
  FROM audit_events
  WHERE organization_id = p_org_id
    AND event_type = 'login_failed'
    AND change_payload ->> 'email' = p_email
    AND created_at > now() - interval '15 minutes';

  RETURN v_recent_failures < v_threshold;
END;
$$;

-- =============================================================================
-- 3. validate_session()
-- Checks if the current session is within the timeout window.
-- Returns true if session is valid.
-- =============================================================================
CREATE OR REPLACE FUNCTION validate_session(
  p_org_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_timeout_minutes integer;
  v_last_active timestamptz;
BEGIN
  SELECT session_timeout_minutes INTO v_timeout_minutes
  FROM org_policies WHERE organization_id = p_org_id;

  IF NOT FOUND THEN
    v_timeout_minutes := 30; -- Safe default
  END IF;

  SELECT last_active_at INTO v_last_active
  FROM profiles WHERE id = auth.uid();

  IF v_last_active IS NULL THEN
    RETURN true; -- First activity
  END IF;

  RETURN v_last_active > now() - (v_timeout_minutes || ' minutes')::interval;
END;
$$;

-- =============================================================================
-- 4. enforce_mfa()
-- Checks if the current user has MFA enabled (when required by org policy).
-- Returns true if MFA is satisfied.
-- =============================================================================
CREATE OR REPLACE FUNCTION enforce_mfa(
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_org_id uuid;
  v_mfa_required boolean;
  v_user_mfa boolean;
BEGIN
  SELECT organization_id INTO v_org_id FROM profiles WHERE id = p_user_id;

  SELECT mfa_required INTO v_mfa_required
  FROM org_policies WHERE organization_id = v_org_id;

  IF NOT FOUND OR NOT v_mfa_required THEN
    RETURN true; -- MFA not required
  END IF;

  -- Check if user has MFA enabled via auth.users metadata
  -- (Supabase stores this in raw_user_meta_data or factors)
  SELECT (raw_user_meta_data ->> 'mfa_enabled')::boolean INTO v_user_mfa
  FROM auth.users WHERE id = p_user_id;

  RETURN COALESCE(v_user_mfa, false);
END;
$$;

-- =============================================================================
-- 5. log_audit_event()
-- Centralized audit logging function.
-- Only callable by service_role (application code) or SECURITY DEFINER functions.
-- =============================================================================
CREATE OR REPLACE FUNCTION log_audit_event(
  p_org_id uuid,
  p_user_id uuid,
  p_event_type text,
  p_module text,
  p_severity text,
  p_status text,
  p_change_payload jsonb DEFAULT '{}',
  p_context jsonb DEFAULT '{}'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  INSERT INTO audit_events (
    organization_id,
    user_id,
    event_type,
    module,
    severity,
    status,
    change_payload,
    context
  ) VALUES (
    p_org_id,
    p_user_id,
    p_event_type,
    p_module,
    p_severity,
    p_status,
    p_change_payload,
    p_context
  ) RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

-- =============================================================================
-- TRIGGER: Update updated_at on org_policies
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_org_policies_updated_at
  BEFORE UPDATE ON org_policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_source_connections_updated_at
  BEFORE UPDATE ON source_connections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
