-- =============================================================================
-- Bynovix AI — Seed Data (Canonical Demo Entities)
-- Generated: August 24, 2026
--
-- ALL canonical values are preserved:
--   - 42.8M aggregate records
--   - $18.6M base forecast, 91% confidence
--   - $20.7M upside, $17.2M downside
--   - 90% AI confidence gate
--   - South Region pricing/revenue anomaly
--   - "Recover South Region Revenue" action
--   - "Suspicious Login Pattern" threat
--   - "Brute Force Protection" playbook
--
-- Entities are inserted in dependency order with explicit UUIDs
-- so lineage_edges can reference them reliably.
-- =============================================================================

-- =============================================================================
-- 1. ORGANIZATION
-- =============================================================================
INSERT INTO organizations (id, name, slug, industry) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Bynovix AI Enterprise', 'enterprise-org', 'Enterprise Software');

-- =============================================================================
-- 2. ORG_POLICIES (authoritative governance rules)
-- =============================================================================
INSERT INTO org_policies (
  organization_id,
  ai_confidence_gate,
  explainability_required,
  auto_response_rollback_enabled,
  mfa_required,
  session_timeout_minutes,
  failed_login_threshold,
  critical_requires_human_approval,
  audit_retention_days
) VALUES (
  'a0000000-0000-0000-0000-000000000001',  -- Bynovix AI Enterprise
  90,     -- AI confidence gate
  true,   -- Explainability required
  true,   -- Auto response rollback enabled
  true,   -- MFA required
  30,     -- Session timeout (minutes)
  5,      -- Failed login threshold
  true,   -- Critical requires human approval
  365     -- Audit retention (days)
);

-- =============================================================================
-- 3. PROFILES (users)
-- NOTE: These are demo profiles. In production, auth.users entries are
-- created via Supabase Auth signup. For demo seeding, we insert directly.
-- =============================================================================
INSERT INTO profiles (id, organization_id, email, full_name, role, team, status) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'sarah.lee@bynovix.com',    'Sarah Lee',  'admin',     'Executive',  'active'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'john.doe@bynovix.com',     'John Doe',   'manager',   'Revenue',    'active'),
  ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'mike.kim@bynovix.com',     'Mike Kim',   'restricted','Customers',  'active'),
  ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'anna.lin@bynovix.com',     'Anna Lin',   'manager',   'Sales',      'active'),
  ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'tom.ross@bynovix.com',     'Tom Ross',   'restricted','Operations', 'active');

-- =============================================================================
-- 4. SOURCE_CONNECTIONS (5 sources → 42.8M total records)
-- =============================================================================
INSERT INTO source_connections (id, organization_id, name, type, connection_method, status, records_count) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Salesforce CRM',    'CRM',            'OAuth',   'connected', 1280000),
  ('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Snowflake DW',      'Data Warehouse',  'JDBC',    'connected', 28600000),
  ('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'HubSpot',           'Marketing',       'API Key', 'syncing',   1420000),
  ('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'PostgreSQL Legacy', 'Database',        'JDBC',    'error',     8100000),
  ('c0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'Stripe Payments',   'Payments',        'API Key', 'connected', 3400000);
-- SUM: 1,280,000 + 28,600,000 + 1,420,000 + 8,100,000 + 3,400,000 = 42,800,000
-- Canonical aggregate: 42.8M records

-- =============================================================================
-- 5. SOURCE_FIELDS (from Salesforce CRM)
-- =============================================================================
INSERT INTO source_fields (id, source_id, organization_id, field_name, field_type) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'total_rev',  'numeric'),
  ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'cust_id',    'text'),
  ('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'loc_region', 'text'),
  ('d0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'product',    'text'),
  ('d0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'order_dt',   'date');

-- =============================================================================
-- 6. FIELD_MAPPINGS (Canonical v2.1)
-- =============================================================================
INSERT INTO field_mappings (id, organization_id, source_id, source_field_id, canonical_field_name, version, status) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'revenue',      'v2.1', 'valid'),
  ('e0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002', 'customer_id',  'v2.1', 'valid'),
  ('e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000003', 'region',       'v2.1', 'warning'),
  ('e0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000004', 'product',      'v2.1', 'unmapped'),
  ('e0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000005', 'date',         'v2.1', 'error');

-- =============================================================================
-- 7. DATA_QUALITY_METRICS
-- =============================================================================
INSERT INTO data_quality_metrics (id, organization_id, source_id, metric_name, metric_value) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'completeness', 94.2),
  ('f0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'freshness',    98.5),
  ('f0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'accuracy',     97.1);

-- =============================================================================
-- 8. ANALYTICAL_RESULTS
-- =============================================================================
INSERT INTO analytical_results (id, organization_id, title, type, period, metrics, anomalies_detected) VALUES
  ('10000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Revenue by Region Q3', 'revenue_analysis', 'Q3 2026',
   '{"total_revenue": 12400000, "growth_rate": 12.4, "regions": {"na": 5200000, "emea": 3800000, "apac": 2100000, "latam": 1300000}, "baseline_records": 42800000, "total_source_records": 42800000}',
   1);

-- =============================================================================
-- 9. FORECASTS (canonical: Base $18.6M, 91% confidence)
-- =============================================================================
INSERT INTO forecasts (id, organization_id, title, scenario, forecast_value, confidence, period, dimensions, drivers, risks, analytical_result_id) VALUES
  ('20000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Q3 Revenue Forecast', 'base',     18600000, 91, 'Q3 2026',
   '{"region": "all", "product_line": "all"}',
   '["Market demand surge in Enterprise Tier", "Seasonal uptick in marketing ROI"]',
   '["Competitor entry in APAC before Q4", "Churn rate stability below 2.1%"]',
   '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Q3 Revenue Forecast', 'upside',   20700000, 85, 'Q3 2026',
   '{"region": "all", "product_line": "all"}',
   '["Accelerated Enterprise adoption", "APAC expansion"]',
   '["Execution risk on new initiatives"]',
   '10000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Q3 Revenue Forecast', 'downside', 17200000, 78, 'Q3 2026',
   '{"region": "all", "product_line": "all"}',
   '["Conservative growth assumptions"]',
   '["Supply chain disruption in Asia-Pacific", "Increased CPCs from competitor campaign"]',
   '10000000-0000-0000-0000-000000000001');

-- =============================================================================
-- 10. INSIGHTS (canonical: South Region anomaly, cross-sell, churn)
-- =============================================================================
INSERT INTO insights (id, organization_id, title, type, severity, confidence, explanation, status, source_data, supporting_metrics, recommended_action_title, recommended_action_owner) VALUES
  ('30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Revenue Anomaly: South Region', 'anomaly', 'high', 94,
   'A sudden deceleration in revenue growth was detected in the South Region over the past 7 days. Expected revenue based on historical seasonal trends was $1.2M, but actual recognized revenue fell to $750k, creating an unexpected negative variance of $450k. The primary driver is a critical shortfall in top-of-funnel pipeline generation. The early depletion of the regional ad budget suggests increased CPCs, likely driven by a recent aggressive regional campaign by Competitor X.',
   'active',
   '{"source": "Salesforce CRM", "field_mapping": "South Region Data Hub", "region": "South"}',
   '{"expected_impact": -450000, "period": "7 days", "expected_revenue": 1200000, "actual_revenue": 750000}',
   'Increase ad spend in South Region ($50k)', 'Marketing'),
  ('30000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001',
   'Product B Cross-sell Opportunity', 'opportunity', 'medium', 88,
   'Cross-sell probability is highest in the Healthcare vertical for the next 30 days. Product B shows strong affinity with existing Healthcare customer base.',
   'active',
   '{"source": "Salesforce CRM", "vertical": "Healthcare"}',
   '{"expected_impact": 280000, "vertical": "Healthcare", "window": "30 days"}',
   'Launch Enterprise Cross-Sell Campaign', 'Sales'),
  ('30000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001',
   'Customer Churn Alert: Enterprise Tier', 'risk', 'high', 91,
   '12 Enterprise tier accounts showing warning signs of churn based on declining engagement metrics and support ticket patterns.',
   'active',
   '{"source": "Salesforce CRM", "tier": "Enterprise"}',
   '{"at_risk_accounts": 12, "tier": "Enterprise"}',
   'Initiate retention campaign for Enterprise tier', 'Marketing');

-- =============================================================================
-- 11. ACTIONS (canonical: "Recover South Region Revenue")
-- =============================================================================
INSERT INTO actions (id, organization_id, title, description, priority, owner, status, expected_impact, confidence, source_insight_id, source_type, due_date, checklist) VALUES
  ('40000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Recover South Region Revenue', 'Initiate targeted promotional campaign for Product B specifically in the South Region to counteract the supply chain disruption impact.',
   'critical', 'Marketing', 'in_progress', 450000, 94,
   '30000000-0000-0000-0000-000000000001', 'ai_insight', '2026-08-28',
   '[{"label": "Confirm regional data", "completed": true}, {"label": "Assign campaign owner", "completed": false}, {"label": "Approve budget", "completed": false}, {"label": "Launch intervention", "completed": false}, {"label": "Measure outcome", "completed": false}]'),
  ('40000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001',
   'Increase Product B Inventory', 'Reallocate stock to NA region to meet predicted demand surge from forecast analysis.',
   'high', 'Operations', 'todo', 620000, 96,
   NULL, 'forecast', '2026-09-02',
   '[]'),
  ('40000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001',
   'Launch Enterprise Cross-Sell Campaign', 'Execute cross-sell initiative targeting Healthcare vertical based on AI-detected opportunity.',
   'high', 'Sales', 'in_progress', 280000, 88,
   '30000000-0000-0000-0000-000000000002', 'ai_insight', '2026-09-05',
   '[]'),
  ('40000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001',
   'Review South Region Pricing Strategy', 'Analyze pricing elasticity in South Region and recommend adjustments.',
   'medium', 'Revenue Team', 'blocked', 190000, 81,
   NULL, 'ai_analyst', '2026-09-08',
   '[]');

-- =============================================================================
-- 12. REPORTS (5 canonical reports)
-- =============================================================================
INSERT INTO reports (id, organization_id, title, type, status, owner_id, impact) VALUES
  ('50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Executive Performance Q3',    'executive', 'generated', 'b0000000-0000-0000-0000-000000000001', 'High'),
  ('50000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Global Financial Rollup',     'financial', 'scheduled', 'b0000000-0000-0000-0000-000000000002', 'Medium'),
  ('50000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Enterprise Churn Analysis',   'customers', 'draft',      'b0000000-0000-0000-0000-000000000003', 'High'),
  ('50000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Q4 Sales Forecast',           'sales',     'generated', 'b0000000-0000-0000-0000-000000000004', 'Critical'),
  ('50000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'Supply Chain Efficiency',     'operations','generated', 'b0000000-0000-0000-0000-000000000005', 'Medium');

-- =============================================================================
-- 13. AUDIT_EVENTS (5 canonical events from security page)
-- =============================================================================
INSERT INTO audit_events (id, organization_id, user_id, event_type, module, severity, status, change_payload, context, created_at) VALUES
  ('60000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'permission_updated',   'Team',           'medium',   'successful', '{"before": "View Only", "after": "Manage Access"}', '{"ip": "192.168.1.1", "device": "Chrome", "location": "San Francisco, CA"}', now() - interval '42 minutes'),
  ('60000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'report_exported',      'Reports',        'low',      'successful', '{}', '{}', now() - interval '35 minutes'),
  ('60000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'login_failed',         'Security',       'critical', 'blocked',   '{"email": "mike.kim@bynovix.com", "attempt": 3}', '{"ip": "10.0.0.55", "device": "Firefox", "location": "New York, NY"}', now() - interval '12 minutes'),
  ('60000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000004', 'data_source_configured','Data Sources',  'high',    'successful', '{"source": "PostgreSQL Legacy"}', '{}', now() - interval '1 hour'),
  ('60000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000005', 'forecast_viewed',      'Forecasts',      'low',      'successful', '{}', '{}', now() - interval '1.5 hours');

-- =============================================================================
-- 14. THREATS (canonical: "Suspicious Login Pattern")
-- =============================================================================
INSERT INTO threats (id, organization_id, title, description, severity, status, source_audit_event_id, confidence, detected_at) VALUES
  ('70000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Suspicious Login Pattern', 'Multiple failed login attempts detected from the same IP range targeting administrative accounts. Pattern consistent with credential stuffing attack.',
   'critical', 'investigating',
   '60000000-0000-0000-0000-000000000003',
   87, now() - interval '10 minutes');

-- =============================================================================
-- 15. PLAYBOOKS (canonical: "Brute Force Protection")
-- =============================================================================
INSERT INTO playbooks (id, organization_id, name, description, trigger_event_type, auto_execute_threshold, requires_human_approval, is_active) VALUES
  ('80000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Brute Force Protection', 'Automated response to brute force and credential stuffing attack patterns. Blocks IP ranges and enforces MFA for targeted accounts.',
   'login_failed', 90, true, true);

-- =============================================================================
-- 16. PLAYBOOK_RULES
-- =============================================================================
INSERT INTO playbook_rules (playbook_id, organization_id, condition, action, priority) VALUES
  ('80000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   '{"field": "failed_attempts", "op": ">=", "value": 5}',
   '{"type": "block_ip", "notify": "admin", "enforce_mfa": true}',
   1);

-- =============================================================================
-- 17. SIMULATION_SCENARIOS
-- =============================================================================
INSERT INTO simulation_scenarios (id, organization_id, name, variables, projected_metrics, ai_analysis, created_by) VALUES
  ('90000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Scenario A: Product B Growth',
   '{"product_price_change_pct": -10, "marketing_spend_change_pct": 25, "customer_acquisition_rate_change_pct": 8, "discount_pct": 15}',
   '{"revenue": 14100000, "revenue_change_pct": 13.7, "profit": 3500000, "profit_change_pct": 9.4, "active_customers": 84200, "active_customers_change_pct": 18.1, "profit_margin_pct": 24.8, "profit_margin_change_pct": -1.2}',
   '{"impact_drivers": [{"factor": "Marketing Spend (+25%)", "impact_pct": 68}, {"factor": "Price Reduction (-10%)", "impact_pct": 32}], "risks": ["Competitor Response likely within Q2", "Assumes Market Saturation remains below 60%"]}',
   'b0000000-0000-0000-0000-000000000001');

-- =============================================================================
-- 18. MODULE_PERMISSIONS (per-user per-module)
-- =============================================================================
-- Sarah Lee (Admin): Full access to everything
INSERT INTO module_permissions (organization_id, user_id, module, permission) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'overview',    'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'analytics',   'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'ai_insights', 'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'ai_analyst',  'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'forecasts',   'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'what_if',     'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'actions',     'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'reports',     'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'data',        'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'team',        'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'settings',    'manage'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'security',    'manage');

-- John Doe (Manager): Edit access, no team/settings/security management
INSERT INTO module_permissions (organization_id, user_id, module, permission) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'overview',    'edit'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'analytics',   'edit'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'ai_insights', 'edit'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'forecasts',   'edit'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'actions',     'edit'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'reports',     'edit');

-- Mike Kim (Restricted): View only
INSERT INTO module_permissions (organization_id, user_id, module, permission) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'overview',    'view'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'analytics',   'view'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'ai_insights', 'view'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'forecasts',   'view'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'actions',     'view'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'reports',     'view');

-- =============================================================================
-- 19. LINEAGE_EDGES (full business + security chains)
-- =============================================================================

-- BUSINESS PIPELINE: Source → Field Mapping → Analytical Result → Forecast → Insight → Action → Report
INSERT INTO lineage_edges (organization_id, source_entity_type, source_entity_id, target_entity_type, target_entity_id, edge_type) VALUES
  -- Source → Field Mappings
  ('a0000000-0000-0000-0000-000000000001', 'source_connection', 'c0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000001', 'feeds_into'),
  ('a0000000-0000-0000-0000-000000000001', 'source_connection', 'c0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000002', 'feeds_into'),
  ('a0000000-0000-0000-0000-000000000001', 'source_connection', 'c0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000003', 'feeds_into'),
  -- Field Mappings → Analytical Result
  ('a0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000001', 'analytical_result', '10000000-0000-0000-0000-000000000001', 'feeds_into'),
  ('a0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000003', 'analytical_result', '10000000-0000-0000-0000-000000000001', 'feeds_into'),
  -- Analytical Result → Forecasts
  ('a0000000-0000-0000-0000-000000000001', 'analytical_result', '10000000-0000-0000-0000-000000000001', 'forecast', '20000000-0000-0000-0000-000000000001', 'feeds_into'),
  ('a0000000-0000-0000-0000-000000000001', 'analytical_result', '10000000-0000-0000-0000-000000000001', 'forecast', '20000000-0000-0000-0000-000000000002', 'feeds_into'),
  ('a0000000-0000-0000-0000-000000000001', 'analytical_result', '10000000-0000-0000-0000-000000000001', 'forecast', '20000000-0000-0000-0000-000000000003', 'feeds_into'),
  -- Forecasts → Insights
  ('a0000000-0000-0000-0000-000000000001', 'forecast', '20000000-0000-0000-0000-000000000001', 'insight', '30000000-0000-0000-0000-000000000001', 'derived_from'),
  -- Field Mappings → Insights
  ('a0000000-0000-0000-0000-000000000001', 'field_mapping', 'e0000000-0000-0000-0000-000000000003', 'insight', '30000000-0000-0000-0000-000000000001', 'derived_from'),
  -- Insights → Actions (FK: actions.source_insight_id)
  ('a0000000-0000-0000-0000-000000000001', 'insight', '30000000-0000-0000-0000-000000000001', 'action', '40000000-0000-0000-0000-000000000001', 'triggered_by'),
  ('a0000000-0000-0000-0000-000000000001', 'insight', '30000000-0000-0000-0000-000000000002', 'action', '40000000-0000-0000-0000-000000000003', 'triggered_by'),
  -- Insights → Reports
  ('a0000000-0000-0000-0000-000000000001', 'insight', '30000000-0000-0000-0000-000000000001', 'report', '50000000-0000-0000-0000-000000000001', 'produced_by'),
  -- Actions → Reports
  ('a0000000-0000-0000-0000-000000000001', 'action', '40000000-0000-0000-0000-000000000001', 'report', '50000000-0000-0000-0000-000000000001', 'produced_by');

-- SECURITY LOOP: Audit Event → Threat → Playbook → Approval → Security Action → Audit Entry
INSERT INTO lineage_edges (organization_id, source_entity_type, source_entity_id, target_entity_type, target_entity_id, edge_type) VALUES
  -- Audit Event → Threat
  ('a0000000-0000-0000-0000-000000000001', 'audit_event', '60000000-0000-0000-0000-000000000003', 'threat', '70000000-0000-0000-0000-000000000001', 'triggered_by');
