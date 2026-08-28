# Bynovix AI — Final Migration Plan

> **Version:** 2.0 (Post-Review)  
> **Date:** August 24, 2026  
> **Status:** READY FOR EXECUTION  
> **Changes from v1:** lineage_edges junction table replaces JSONB lineage; org_policies table replaces inline settings JSONB; 21 total tables

---

## Migration Order

| Step | File | Description | Tables/Objects |
|------|------|-------------|----------------|
| 1 | `001_extensions.sql` | Enable required PostgreSQL extensions | `pgcrypto`, `uuid-ossp` |
| 2 | `002_tables.sql` | Create all 21 tables in dependency order | 21 tables |
| 3 | `003_indexes.sql` | Performance indexes | ~35 indexes |
| 4 | `004_rls.sql` | Row Level Security policies | ~40 policies |
| 5 | `005_functions.sql` | Governance enforcement functions | 5 functions |
| 6 | `006_seed.sql` | Canonical demo data | ~150 rows |

**No destructive operations.** All tables are created fresh via `CREATE TABLE IF NOT EXISTS`.

---

## Complete Table List (21 Tables)

### Organization & Auth (3 tables)

| # | Table | PK | Org-scoped | Description |
|---|-------|----|-----------|-------------|
| 1 | `organizations` | `id uuid` | — | Multi-tenant root |
| 2 | `org_policies` | `id uuid` | `organization_id FK` | **NEW:** Authoritative governance/security rules per org |
| 3 | `profiles` | `id uuid FK → auth.users` | `organization_id FK` | User identity + role |

### Data Foundation (4 tables)

| # | Table | PK | Org-scoped | FK Targets |
|---|-------|----|-----------|------------|
| 4 | `source_connections` | `id uuid` | `organization_id FK` | — |
| 5 | `source_fields` | `id uuid` | `organization_id FK` | `source_connections.id` |
| 6 | `field_mappings` | `id uuid` | `organization_id FK` | `source_connections.id`, `source_fields.id` |
| 7 | `data_quality_metrics` | `id uuid` | `organization_id FK` | `source_connections.id` |

### Intelligence Pipeline (5 tables)

| # | Table | PK | Org-scoped | FK Targets |
|---|-------|----|-----------|------------|
| 8 | `analytical_results` | `id uuid` | `organization_id FK` | — |
| 9 | `forecasts` | `id uuid` | `organization_id FK` | `analytical_results.id` |
| 10 | `insights` | `id uuid` | `organization_id FK` | — |
| 11 | `actions` | `id uuid` | `organization_id FK` | `insights.id` |
| 12 | `reports` | `id uuid` | `organization_id FK` | `profiles.id` (owner) |

### Security System (7 tables)

| # | Table | PK | Org-scoped | FK Targets |
|---|-------|----|-----------|------------|
| 13 | `audit_events` | `id uuid` | `organization_id FK` | `profiles.id` |
| 14 | `threats` | `id uuid` | `organization_id FK` | `audit_events.id` |
| 15 | `playbooks` | `id uuid` | `organization_id FK` | — |
| 16 | `playbook_rules` | `id uuid` | `organization_id FK` | `playbooks.id` |
| 17 | `security_actions` | `id uuid` | `organization_id FK` | `threats.id`, `playbooks.id`, `approvals.id` |
| 18 | `approvals` | `id uuid` | `organization_id FK` | `security_actions.id`, `profiles.id` (approver) |
| 19 | `audit_entries` | `id uuid` | `organization_id FK` | `security_actions.id` |

### What-If Simulator (1 table)

| # | Table | PK | Org-scoped | FK Targets |
|---|-------|----|-----------|------------|
| 20 | `simulation_scenarios` | `id uuid` | `organization_id FK` | `profiles.id` (creator) |

### Cross-Cutting (2 tables)

| # | Table | PK | Org-scoped | FK Targets |
|---|-------|----|-----------|------------|
| 21 | `module_permissions` | `id uuid` | `organization_id FK` | `profiles.id` |
| — | `lineage_edges` | `id uuid` | `organization_id FK` | Polymorphic source/target |

---

## `org_policies` Schema (Authoritative Governance)

```sql
CREATE TABLE org_policies (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
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
  
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(organization_id)
);
```

**Enforcement:** The `can_auto_execute()` function reads from this table, not from `organizations.settings` JSONB. This is the single source of truth for governance rules.

---

## `lineage_edges` Schema (Junction Table)

```sql
CREATE TABLE lineage_edges (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  source_entity_type  text NOT NULL,  -- 'source_connection', 'field_mapping', 'analytical_result', etc.
  source_entity_id    uuid NOT NULL,
  target_entity_type  text NOT NULL,  -- 'analytical_result', 'forecast', 'insight', 'action', etc.
  target_entity_id    uuid NOT NULL,
  
  edge_type           text NOT NULL,  -- 'feeds_into', 'derived_from', 'triggered_by', 'produced_by'
  metadata            jsonb,
  
  created_at          timestamptz NOT NULL DEFAULT now(),
  
  UNIQUE(organization_id, source_entity_type, source_entity_id, target_entity_type, target_entity_id, edge_type)
);
```

**Indexes:**
- `(source_entity_type, source_entity_id)` — "what does this entity feed into?"
- `(target_entity_type, target_entity_id)` — "what produced this entity?"
- `(organization_id, edge_type)` — filtered queries

**Supported lineage chains:**

| Chain | Edges |
|-------|-------|
| Business Pipeline | `source_connection → field_mapping → analytical_result → forecast → insight → action → report` |
| Security Loop | `audit_event → threat → playbook → approval → security_action → audit_entry` |
| Report Traceability | `insight → report`, `action → report` |

---

## Foreign Key Chain Verification

### Business Chain
```
source_connections (1) ──→ (N) source_fields
source_fields (1) ──→ (N) field_mappings
field_mappings (N) ◄── (via lineage_edges) ──→ (N) analytical_results
analytical_results (1) ──→ (N) forecasts
insights ◄── (via lineage_edges) ──→ field_mappings
insights ◄── (via lineage_edges) ──→ analytical_results
insights ◄── (via lineage_edges) ──→ forecasts
insights (1) ──→ (N) actions           ← FK actions.source_insight_id
reports ◄── (via lineage_edges) ──→ insights
reports ◄── (via lineage_edges) ──→ actions
```

### Security Chain
```
audit_events (1) ──→ (N) threats            ← FK threats.source_audit_event_id
playbooks (1) ──→ (N) playbook_rules       ← FK playbook_rules.playbook_id
threats + playbooks ──→ security_actions    ← FK security_actions.threat_id + playbook_id
security_actions (1) ──→ (N) approvals      ← FK approvals.security_action_id
security_actions (1) ──→ (N) audit_entries   ← FK audit_entries.security_action_id
```

---

## RLS Policy Summary

| Pattern | Tables | Rule |
|---------|--------|------|
| Org Isolation | ALL 21 tables | `organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())` |
| Role: Restricted | `actions`, `source_connections`, `field_mappings` | `role != 'restricted'` for INSERT/UPDATE/DELETE |
| Role: Admin Only | `org_policies`, `module_permissions`, `approvals` | `role = 'admin'` for INSERT/UPDATE |
| Read-Only Audit | `audit_events`, `audit_entries` | SELECT only; INSERT via service_role only |
| User Self | `profiles` | Users can UPDATE their own row |

---

## Governance Functions (5 functions)

| Function | Purpose | Called By |
|----------|---------|-----------|
| `can_auto_execute(confidence, severity, org_id)` | Checks confidence gate + critical approval | Edge Functions, DB triggers |
| `check_failed_login(email, org_id)` | Enforces failed-login threshold | Auth hook |
| `validate_session(org_id)` | Checks session timeout | Middleware |
| `enforce_mfa(user_id)` | Checks MFA status | Auth hook |
| `log_audit_event(org_id, user_id, event_type, module, severity, status, payload)` | Centralized audit logging | Application code |

---

## Index Summary (~35 indexes)

| Table | Index | Purpose |
|-------|-------|---------|
| All tables | `idx_{table}_org_id` | RLS performance |
| `lineage_edges` | `idx_lineage_source` | Source lookups |
| `lineage_edges` | `idx_lineage_target` | Target lookups |
| `lineage_edges` | `idx_lineage_org_type` | Filtered queries |
| `insights` | `idx_insights_status` | Active insights filter |
| `insights` | `idx_insights_severity` | Priority filtering |
| `actions` | `idx_actions_status` | Workflow filtering |
| `actions` | `idx_actions_owner` | Assignment filtering |
| `forecasts` | `idx_forecasts_scenario` | Scenario filtering |
| `forecasts` | `idx_forecasts_period` | Period filtering |
| `audit_events` | `idx_audit_events_timestamp` | Time-based queries |
| `audit_events` | `idx_audit_events_user` | User activity |
| `threats` | `idx_threats_status` | Active threat filter |
| `module_permissions` | `idx_modperm_user_module` | Permission lookup |
| `source_connections` | `idx_source_status` | Health monitoring |

---

## Canonical Seed Data (Connected Entities)

All entities below are connected via `lineage_edges`:

1. **Organization:** "Bynovix AI Enterprise"
2. **Org Policies:** ai_confidence_gate=90, mfa_required=true, session_timeout=30, failed_login_threshold=5
3. **5 Users:** Sarah Lee (admin), John Doe (manager), Mike Kim (restricted), Anna Lin (manager), Tom Ross (restricted)
4. **5 Source Connections:** Salesforce CRM, Snowflake DW, HubSpot, PostgreSQL Legacy, Stripe Payments → sum = 42.8M records
5. **5 Field Mappings:** revenue, customer_id, region, product, date (Canonical v2.1)
6. **1 Analytical Result:** Revenue by Region Q3
7. **3 Forecasts:** Base $18.6M (91% conf), Upside $20.7M, Downside $17.2M
8. **3 Insights:** Revenue Anomaly South Region (94% conf), Cross-sell Opportunity (88%), Churn Alert (91%)
9. **4 Actions:** Recover South Region Revenue, Increase Product B Inventory, Launch Enterprise Cross-Sell, Review South Region Pricing
10. **5 Reports:** Executive Performance Q3, Global Financial Rollup, Enterprise Churn Analysis, Q4 Sales Forecast, Supply Chain Efficiency
11. **5 Audit Events:** Permission updated, Report exported, Failed login, Data source configured, Forecast viewed
12. **1 Threat:** Suspicious Login Pattern
13. **1 Playbook:** Brute Force Protection (with rules)
14. **1 Security Action:** (connected to threat + playbook)
15. **1 Approval:** (connected to security action)
16. **1 Audit Entry:** (result of security action)
17. **1 Simulation Scenario:** Product B Growth
18. **~24 Module Permissions:** Per-user per-module access
19. **~15 Lineage Edges:** Full business + security chains

---

## Execution Checklist

Before running migrations:

- [ ] Supabase project created
- [ ] `supabase` CLI installed
- [ ] `supabase link --project-ref <ref>` connected
- [ ] No existing tables with these names
- [ ] Backup of any existing data

After running migrations:

- [ ] All 21 tables created
- [ ] RLS enabled on all tables
- [ ] Seed data inserted
- [ ] Lineage edges verified (SELECT queries)
- [ ] Governance functions callable (SELECT can_auto_execute(...))
- [ ] Edge Function stubs deployed

---

**Plan complete. Awaiting confirmation to execute.**
