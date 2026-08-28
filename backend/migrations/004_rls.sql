-- =============================================================================
-- Bynovix AI — Row Level Security Policies
-- Generated: August 24, 2026
-- 
-- Strategy:
--   1. Every table gets org isolation: user can only see rows matching their org
--   2. Role-based write restrictions for sensitive tables
--   3. Audit tables are read-only for users (INSERT via service_role only)
-- =============================================================================

-- =============================================================================
-- HELPER FUNCTION: Get current user's organization_id
-- =============================================================================
CREATE OR REPLACE FUNCTION get_user_org_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT organization_id FROM profiles WHERE id = auth.uid();
$$;

-- HELPER FUNCTION: Get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- =============================================================================
-- 1. ORGANIZATIONS
-- =============================================================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON organizations
  FOR SELECT USING (
    id = get_user_org_id()
  );

CREATE POLICY "org_admin_update" ON organizations
  FOR UPDATE USING (
    id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 2. ORG_POLICIES
-- =============================================================================
ALTER TABLE org_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON org_policies
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "admin_only_write" ON org_policies
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

CREATE POLICY "admin_only_update" ON org_policies
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 3. PROFILES
-- =============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON profiles
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "user_self_update" ON profiles
  FOR UPDATE USING (
    id = auth.uid()
  );

CREATE POLICY "admin_insert" ON profiles
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

CREATE POLICY "admin_manage" ON profiles
  FOR DELETE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin' AND id != auth.uid()
  );

-- =============================================================================
-- 4. SOURCE_CONNECTIONS
-- =============================================================================
ALTER TABLE source_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON source_connections
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "manager_plus_insert" ON source_connections
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "manager_plus_update" ON source_connections
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "admin_delete" ON source_connections
  FOR DELETE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 5. SOURCE_FIELDS
-- =============================================================================
ALTER TABLE source_fields ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON source_fields
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 6. FIELD_MAPPINGS
-- =============================================================================
ALTER TABLE field_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON field_mappings
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "manager_plus_write" ON field_mappings
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "manager_plus_update" ON field_mappings
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

-- =============================================================================
-- 7. DATA_QUALITY_METRICS
-- =============================================================================
ALTER TABLE data_quality_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON data_quality_metrics
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 8. ANALYTICAL_RESULTS
-- =============================================================================
ALTER TABLE analytical_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON analytical_results
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 9. FORECASTS
-- =============================================================================
ALTER TABLE forecasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON forecasts
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 10. INSIGHTS
-- =============================================================================
ALTER TABLE insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation_select" ON insights
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "manager_plus_insert" ON insights
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "manager_plus_update" ON insights
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "admin_delete" ON insights
  FOR DELETE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 11. ACTIONS
-- =============================================================================
ALTER TABLE actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON actions
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "restricted_read_only" ON actions
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() != 'restricted'
  );

CREATE POLICY "restricted_no_update" ON actions
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() != 'restricted'
  );

-- =============================================================================
-- 12. REPORTS
-- =============================================================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation_select" ON reports
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "manager_plus_insert" ON reports
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "manager_plus_update" ON reports
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() IN ('admin', 'manager')
  );

CREATE POLICY "admin_delete" ON reports
  FOR DELETE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 13. AUDIT_EVENTS (read-only for users)
-- =============================================================================
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation_select" ON audit_events
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

-- No INSERT/UPDATE/DELETE policies — only service_role can write

-- =============================================================================
-- 14. THREATS
-- =============================================================================
ALTER TABLE threats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON threats
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 15. PLAYBOOKS
-- =============================================================================
ALTER TABLE playbooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON playbooks
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "admin_only_write" ON playbooks
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

CREATE POLICY "admin_only_update" ON playbooks
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 16. PLAYBOOK_RULES
-- =============================================================================
ALTER TABLE playbook_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON playbook_rules
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "admin_only_write" ON playbook_rules
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 17. APPROVALS
-- =============================================================================
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON approvals
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "admin_only_decision" ON approvals
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 18. SECURITY_ACTIONS
-- =============================================================================
ALTER TABLE security_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON security_actions
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 19. AUDIT_ENTRIES (read-only for users)
-- =============================================================================
ALTER TABLE audit_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation_select" ON audit_entries
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

-- No INSERT/UPDATE/DELETE policies — only service_role can write

-- =============================================================================
-- 20. SIMULATION_SCENARIOS
-- =============================================================================
ALTER TABLE simulation_scenarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON simulation_scenarios
  FOR ALL USING (
    organization_id = get_user_org_id()
  );

-- =============================================================================
-- 21. MODULE_PERMISSIONS
-- =============================================================================
ALTER TABLE module_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON module_permissions
  FOR SELECT USING (
    organization_id = get_user_org_id()
  );

CREATE POLICY "admin_only_write" ON module_permissions
  FOR INSERT WITH CHECK (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

CREATE POLICY "admin_only_update" ON module_permissions
  FOR UPDATE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

CREATE POLICY "admin_only_delete" ON module_permissions
  FOR DELETE USING (
    organization_id = get_user_org_id() AND get_user_role() = 'admin'
  );

-- =============================================================================
-- 22. LINEAGE_EDGES
-- =============================================================================
ALTER TABLE lineage_edges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON lineage_edges
  FOR ALL USING (
    organization_id = get_user_org_id()
  );
