-- =============================================================================
-- Bynovix AI — Performance Indexes
-- Generated: August 24, 2026
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Org-scoped indexes (one per table for RLS performance)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_org ON profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_source_connections_org ON source_connections(organization_id);
CREATE INDEX IF NOT EXISTS idx_source_fields_org ON source_fields(organization_id);
CREATE INDEX IF NOT EXISTS idx_source_fields_source ON source_fields(source_id);
CREATE INDEX IF NOT EXISTS idx_field_mappings_org ON field_mappings(organization_id);
CREATE INDEX IF NOT EXISTS idx_field_mappings_source ON field_mappings(source_id);
CREATE INDEX IF NOT EXISTS idx_data_quality_org ON data_quality_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_data_quality_source ON data_quality_metrics(source_id);
CREATE INDEX IF NOT EXISTS idx_analytical_results_org ON analytical_results(organization_id);
CREATE INDEX IF NOT EXISTS idx_forecasts_org ON forecasts(organization_id);
CREATE INDEX IF NOT EXISTS idx_forecasts_scenario ON forecasts(organization_id, scenario);
CREATE INDEX IF NOT EXISTS idx_forecasts_period ON forecasts(organization_id, period);
CREATE INDEX IF NOT EXISTS idx_insights_org ON insights(organization_id);
CREATE INDEX IF NOT EXISTS idx_insights_status ON insights(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_insights_severity ON insights(organization_id, severity);
CREATE INDEX IF NOT EXISTS idx_actions_org ON actions(organization_id);
CREATE INDEX IF NOT EXISTS idx_actions_status ON actions(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_actions_owner ON actions(organization_id, owner);
CREATE INDEX IF NOT EXISTS idx_actions_insight ON actions(source_insight_id);
CREATE INDEX IF NOT EXISTS idx_analytical_results_mapping ON analytical_results USING gin(source_mapping_ids);
CREATE INDEX IF NOT EXISTS idx_forecasts_mapping ON forecasts USING gin(source_mapping_ids);
CREATE INDEX IF NOT EXISTS idx_reports_org ON reports(organization_id);
CREATE INDEX IF NOT EXISTS idx_reports_insights ON reports USING gin(referenced_insight_ids);
CREATE INDEX IF NOT EXISTS idx_reports_actions ON reports USING gin(referenced_action_ids);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(organization_id, type);
CREATE INDEX IF NOT EXISTS idx_reports_owner ON reports(owner_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_org ON audit_events(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_timestamp ON audit_events(organization_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_user ON audit_events(user_id);
CREATE INDEX IF NOT EXISTS idx_threats_org ON threats(organization_id);
CREATE INDEX IF NOT EXISTS idx_threats_status ON threats(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_threats_source_event ON threats(source_audit_event_id);
CREATE INDEX IF NOT EXISTS idx_playbooks_org ON playbooks(organization_id);
CREATE INDEX IF NOT EXISTS idx_playbook_rules_org ON playbook_rules(organization_id);
CREATE INDEX IF NOT EXISTS idx_playbook_rules_playbook ON playbook_rules(playbook_id);
CREATE INDEX IF NOT EXISTS idx_approvals_org ON approvals(organization_id);
CREATE INDEX IF NOT EXISTS idx_security_actions_org ON security_actions(organization_id);
CREATE INDEX IF NOT EXISTS idx_security_actions_threat ON security_actions(threat_id);
CREATE INDEX IF NOT EXISTS idx_audit_entries_org ON audit_entries(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_entries_security_action ON audit_entries(security_action_id);
CREATE INDEX IF NOT EXISTS idx_simulation_scenarios_org ON simulation_scenarios(organization_id);
CREATE INDEX IF NOT EXISTS idx_module_permissions_org ON module_permissions(organization_id);
CREATE INDEX IF NOT EXISTS idx_module_permissions_user ON module_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_module_permissions_lookup ON module_permissions(organization_id, user_id, module);

-- ---------------------------------------------------------------------------
-- Lineage edge indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_lineage_org ON lineage_edges(organization_id);
CREATE INDEX IF NOT EXISTS idx_lineage_source ON lineage_edges(source_entity_type, source_entity_id);
CREATE INDEX IF NOT EXISTS idx_lineage_target ON lineage_edges(target_entity_type, target_entity_id);
CREATE INDEX IF NOT EXISTS idx_lineage_edge_type ON lineage_edges(organization_id, edge_type);
CREATE INDEX IF NOT EXISTS idx_lineage_source_org ON lineage_edges(organization_id, source_entity_type, source_entity_id);
CREATE INDEX IF NOT EXISTS idx_lineage_target_org ON lineage_edges(organization_id, target_entity_type, target_entity_id);
