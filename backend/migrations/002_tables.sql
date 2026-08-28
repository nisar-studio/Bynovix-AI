-- =============================================================================
-- Bynovix AI — Schema Migration (21 tables)
-- Generated: August 24, 2026
-- Safe to run: uses CREATE TABLE IF NOT EXISTS
-- =============================================================================

-- =============================================================================
-- 1. ORGANIZATIONS (multi-tenant root)
-- =============================================================================
CREATE TABLE IF NOT EXISTS organizations (
  id          uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name        text NOT NULL,
  slug        text UNIQUE NOT NULL,
  industry    text,
  logo_url    text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 2. ORG_POLICIES (authoritative governance/security settings)
-- =============================================================================
CREATE TABLE IF NOT EXISTS org_policies (
  id                              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id                 uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

  -- AI Governance
  ai_confidence_gate              numeric NOT NULL DEFAULT 90,
  explainability_required         boolean NOT NULL DEFAULT true,
  auto_response_rollback_enabled  boolean NOT NULL DEFAULT true,

  -- Security
  mfa_required                    boolean NOT NULL DEFAULT true,
  session_timeout_minutes         integer NOT NULL DEFAULT 30,
  failed_login_threshold          integer NOT NULL DEFAULT 5,
  critical_requires_human_approval boolean NOT NULL DEFAULT true,

  -- Audit
  audit_retention_days            integer NOT NULL DEFAULT 365,

  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  UNIQUE(organization_id)
);

-- =============================================================================
-- 3. PROFILES (extends Supabase auth.users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email           text,
  full_name       text,
  avatar_url      text,
  role            text NOT NULL DEFAULT 'restricted' CHECK (role IN ('admin', 'manager', 'restricted')),
  team            text,
  status          text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending', 'disabled')),
  last_active_at  timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 4. SOURCE_CONNECTIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS source_connections (
  id                uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id   uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name              text NOT NULL,
  type              text NOT NULL, -- CRM, Data Warehouse, Marketing, Database, Payments
  connection_method text NOT NULL, -- OAuth, JDBC, API Key
  status            text NOT NULL DEFAULT 'disconnected' CHECK (status IN ('connected', 'syncing', 'error', 'disconnected')),
  records_count     bigint NOT NULL DEFAULT 0,
  last_sync_at      timestamptz,
  config            jsonb DEFAULT '{}',
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 5. SOURCE_FIELDS
-- =============================================================================
CREATE TABLE IF NOT EXISTS source_fields (
  id              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  source_id       uuid NOT NULL REFERENCES source_connections(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  field_name      text NOT NULL,
  field_type      text NOT NULL, -- numeric, text, date, etc.
  sample_values   jsonb,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 6. FIELD_MAPPINGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS field_mappings (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  source_id           uuid NOT NULL REFERENCES source_connections(id) ON DELETE CASCADE,
  source_field_id     uuid NOT NULL REFERENCES source_fields(id) ON DELETE CASCADE,
  canonical_field_name text NOT NULL,
  version             text NOT NULL DEFAULT 'v1.0',
  status              text NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'warning', 'error', 'unmapped')),
  validation_message  text,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 7. DATA_QUALITY_METRICS
-- =============================================================================
CREATE TABLE IF NOT EXISTS data_quality_metrics (
  id              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  source_id       uuid NOT NULL REFERENCES source_connections(id) ON DELETE CASCADE,
  metric_name     text NOT NULL, -- completeness, freshness, accuracy
  metric_value    numeric NOT NULL CHECK (metric_value >= 0 AND metric_value <= 100),
  measured_at     timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 8. ANALYTICAL_RESULTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS analytical_results (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title               text NOT NULL,
  type                text NOT NULL, -- revenue_analysis, retention, anomaly_detection
  period              text NOT NULL, -- Q3 2026, Last 12 Months
  metrics             jsonb NOT NULL DEFAULT '{}',
  anomalies_detected  integer NOT NULL DEFAULT 0,
  source_mapping_ids  uuid[] NOT NULL DEFAULT '{}',  -- FK → field_mappings.id (lineage)
  computed_at         timestamptz NOT NULL DEFAULT now(),
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 9. FORECASTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS forecasts (
  id                      uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id         uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title                   text NOT NULL,
  scenario                text NOT NULL CHECK (scenario IN ('base', 'upside', 'downside')),
  forecast_value          numeric NOT NULL,
  confidence              numeric NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  period                  text NOT NULL,
  dimensions              jsonb NOT NULL DEFAULT '{}',
  drivers                 jsonb NOT NULL DEFAULT '[]',
  risks                   jsonb NOT NULL DEFAULT '[]',
  source_mapping_ids      uuid[] NOT NULL DEFAULT '{}',  -- FK → field_mappings.id (lineage)
  analytical_result_id    uuid REFERENCES analytical_results(id) ON DELETE SET NULL,
  created_at              timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 10. INSIGHTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS insights (
  id                          uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id             uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title                       text NOT NULL,
  type                        text NOT NULL, -- anomaly, opportunity, risk, revenue, customer, product
  severity                    text NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  confidence                  numeric NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  explanation                 text,
  status                      text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'dismissed')),
  source_data                 jsonb NOT NULL DEFAULT '{}',
  supporting_metrics          jsonb NOT NULL DEFAULT '{}',
  recommended_action_title    text,
  recommended_action_owner    text,
  created_at                  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 11. ACTIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS actions (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title               text NOT NULL,
  description         text,
  priority            text NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  owner               text NOT NULL,
  status              text NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'blocked', 'completed', 'cancelled')),
  expected_impact     numeric,
  confidence          numeric CHECK (confidence >= 0 AND confidence <= 100),
  source_insight_id   uuid REFERENCES insights(id) ON DELETE SET NULL,
  source_type         text NOT NULL, -- ai_insight, forecast, ai_analyst
  due_date            date,
  checklist           jsonb NOT NULL DEFAULT '[]',
  execution_started_at timestamptz,
  completed_at        timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 12. REPORTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS reports (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title               text NOT NULL,
  type                text NOT NULL, -- executive, financial, sales, customers, operations
  status              text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'generated')),
  owner_id            uuid REFERENCES profiles(id) ON DELETE SET NULL,
  impact              text, -- High, Medium, Critical
  content             jsonb NOT NULL DEFAULT '{}',
  referenced_insight_ids  uuid[] NOT NULL DEFAULT '{}',  -- FK → insights.id (lineage)
  referenced_action_ids   uuid[] NOT NULL DEFAULT '{}',  -- FK → actions.id (lineage)
  last_generated_at   timestamptz,
  shared_with         jsonb NOT NULL DEFAULT '[]',
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 13. AUDIT_EVENTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_events (
  id              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id         uuid REFERENCES profiles(id) ON DELETE SET NULL,
  event_type      text NOT NULL,
  module          text NOT NULL,
  severity        text NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  status          text NOT NULL CHECK (status IN ('successful', 'blocked', 'failed')),
  change_payload  jsonb,
  context         jsonb,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 14. THREATS
-- =============================================================================
CREATE TABLE IF NOT EXISTS threats (
  id                      uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id         uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title                   text NOT NULL,
  description             text,
  severity                text NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  status                  text NOT NULL DEFAULT 'detected' CHECK (status IN ('detected', 'investigating', 'contained', 'resolved')),
  source_audit_event_id   uuid REFERENCES audit_events(id) ON DELETE SET NULL,
  confidence              numeric CHECK (confidence >= 0 AND confidence <= 100),
  detected_at             timestamptz NOT NULL DEFAULT now(),
  resolved_at             timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 15. PLAYBOOKS
-- =============================================================================
CREATE TABLE IF NOT EXISTS playbooks (
  id                          uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id             uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name                        text NOT NULL,
  description                 text,
  trigger_event_type          text NOT NULL,
  auto_execute_threshold      numeric NOT NULL DEFAULT 90,
  requires_human_approval     boolean NOT NULL DEFAULT true,
  is_active                   boolean NOT NULL DEFAULT true,
  created_at                  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 16. PLAYBOOK_RULES
-- =============================================================================
CREATE TABLE IF NOT EXISTS playbook_rules (
  id              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  playbook_id     uuid NOT NULL REFERENCES playbooks(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  condition       jsonb NOT NULL,
  action          jsonb NOT NULL,
  priority        integer NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 17. APPROVALS
-- =============================================================================
CREATE TABLE IF NOT EXISTS approvals (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  security_action_id  uuid, -- FK added after security_actions is created
  approver_id         uuid REFERENCES profiles(id) ON DELETE SET NULL,
  decision            text NOT NULL DEFAULT 'pending' CHECK (decision IN ('pending', 'approved', 'denied')),
  reason              text,
  decided_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 18. SECURITY_ACTIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS security_actions (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  threat_id           uuid REFERENCES threats(id) ON DELETE SET NULL,
  playbook_id         uuid REFERENCES playbooks(id) ON DELETE SET NULL,
  approval_id         uuid REFERENCES approvals(id) ON DELETE SET NULL,
  action_type         text NOT NULL, -- block_ip, disable_account, enforce_mfa
  status              text NOT NULL DEFAULT 'pending_approval' CHECK (status IN ('pending_approval', 'approved', 'executed', 'denied')),
  executed_at         timestamptz,
  executed_by         uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- Add FK from approvals to security_actions (circular reference resolved)
-- Wrapped in DO block to be re-runnable
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_approvals_security_action'
  ) THEN
    ALTER TABLE approvals
      ADD CONSTRAINT fk_approvals_security_action
      FOREIGN KEY (security_action_id) REFERENCES security_actions(id) ON DELETE SET NULL;
  END IF;
END
$$;

-- =============================================================================
-- 19. AUDIT_ENTRIES
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_entries (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  security_action_id  uuid REFERENCES security_actions(id) ON DELETE SET NULL,
  event_type          text NOT NULL,
  details             jsonb NOT NULL DEFAULT '{}',
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 20. SIMULATION_SCENARIOS
-- =============================================================================
CREATE TABLE IF NOT EXISTS simulation_scenarios (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name                text NOT NULL,
  variables           jsonb NOT NULL DEFAULT '{}',
  projected_metrics   jsonb NOT NULL DEFAULT '{}',
  ai_analysis         jsonb NOT NULL DEFAULT '{}',
  created_by          uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 21. MODULE_PERMISSIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS module_permissions (
  id              uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  module          text NOT NULL,
  permission      text NOT NULL CHECK (permission IN ('view', 'edit', 'manage', 'no_access')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, user_id, module)
);

-- =============================================================================
-- 22. LINEAGE_EDGES (junction table for all lineage relationships)
-- =============================================================================
CREATE TABLE IF NOT EXISTS lineage_edges (
  id                  uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  organization_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

  source_entity_type  text NOT NULL,
  source_entity_id    uuid NOT NULL,
  target_entity_type  text NOT NULL,
  target_entity_id    uuid NOT NULL,

  edge_type           text NOT NULL, -- feeds_into, derived_from, triggered_by, produced_by
  metadata            jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),

  UNIQUE(organization_id, source_entity_type, source_entity_id, target_entity_type, target_entity_id, edge_type)
);
