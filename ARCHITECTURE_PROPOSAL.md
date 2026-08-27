# Bynovix AI — Supabase Architecture Proposal

> **Status:** DRAFT — Awaiting Review  
> **Date:** August 24, 2026  
> **Scope:** Database schema, entity relationships, RLS policy, and mock data mapping  
> **Not in scope:** UI changes, Groq integration, frontend refactoring

---

## 1. Design Principles

1. **Every downstream entity retains lineage.** An Action traces back to an Insight; an Insight traces back to source data and analytical results; a Report references Insights and Actions.
2. **Organization-isolated.** Every table carries `organization_id`. No cross-org data leakage is possible.
3. **Enforced server-side.** Governance rules (90% confidence gate, MFA, session timeout, failed-login threshold) are enforced via Supabase RLS and database functions, not just frontend hiding.
4. **No isolated CRUD.** Pages are views into shared enterprise entities. The same `action` row appears in the Actions page, in an AI Insight's recommended actions, and in a Report's referenced actions.
5. **Canonical demo data preserved.** The existing mock values ($18.6M base forecast, 91% confidence, 42.8M records, South Region anomaly, etc.) seed the initial data.

---

## 2. Organization & Auth Layer

### 2.1 `organizations`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `name` | `text NOT NULL` | e.g. "Bynovix AI Enterprise" |
| `slug` | `text UNIQUE` | URL slug: `bynovix.ai/app/enterprise-org` |
| `industry` | `text` | "Enterprise Software" |
| `logo_url` | `text` | |
| `default_timezone` | `text` | "PST" |
| `default_currency` | `text` | "USD" |
| `settings` | `jsonb` | MFA required, session timeout, failed-login threshold |
| `created_at` | `timestamptz` | |

**Settings JSONB schema:**
```json
{
  "mfa_required": true,
  "session_timeout_minutes": 30,
  "failed_login_threshold": 5,
  "ai_confidence_gate": 90
}
```

### 2.2 `profiles` (extends Supabase `auth.users`)
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | FK → `auth.users.id` |
| `organization_id` | `uuid FK → organizations.id` | |
| `email` | `text` | |
| `full_name` | `text` | "Sarah Lee" |
| `avatar_url` | `text` | |
| `role` | `text CHECK (IN ('admin','manager','restricted'))` | |
| `team` | `text` | "Executive", "Revenue", "Marketing", etc. |
| `status` | `text CHECK (IN ('active','pending','disabled'))` | |
| `last_active_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

**Mock data mapping:**
| Mock User | Role | Team | Status |
|-----------|------|------|--------|
| Sarah Lee | admin | Executive | active |
| John Doe | manager | Revenue | active |
| Mike Kim | restricted | Customers | active |
| Anna Lin | manager | Sales | active |
| Tom Ross | restricted | Operations | active |

---

## 3. Data Foundation

### 3.1 `source_connections`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `name` | `text` | "Salesforce CRM", "Snowflake DW" |
| `type` | `text` | "CRM", "Data Warehouse", "Marketing", "Database", "Payments" |
| `connection_method` | `text` | "OAuth", "JDBC", "API Key" |
| `status` | `text CHECK (IN ('connected','syncing','error','disconnected'))` | |
| `records_count` | `bigint` | |
| `last_sync_at` | `timestamptz` | |
| `config` | `jsonb` | Encrypted connection details |
| `created_at` | `timestamptz` | |

**Mock data mapping:**
| Source | Type | Method | Records | Status |
|--------|------|--------|---------|--------|
| Salesforce CRM | CRM | OAuth | 1,200,000 | connected |
| Snowflake DW | Data Warehouse | JDBC | 25,400,000 | connected |
| HubSpot | Marketing | API Key | 480,000 | syncing |
| PostgreSQL Legacy | Database | JDBC | 8,100,000 | error |
| Stripe Payments | Payments | API Key | 3,400,000 | connected |

**Total: 42.8M records** (canonical) ← stored as the sum of `records_count` across all sources

### 3.2 `source_fields`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `source_id` | `uuid FK → source_connections.id` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `field_name` | `text` | "total_rev", "cust_id", "loc_region" |
| `field_type` | `text` | "numeric", "text", "date", etc. |
| `sample_values` | `jsonb` | |

### 3.3 `field_mappings`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `source_id` | `uuid FK → source_connections.id` | |
| `source_field_id` | `uuid FK → source_fields.id` | |
| `canonical_field_name` | `text` | "revenue", "customer_id", "region", "product", "date" |
| `version` | `text` | "v2.1" |
| `status` | `text CHECK (IN ('valid','warning','error','unmapped'))` | |
| `validation_message` | `text` | |
| `created_at` | `timestamptz` | |

**Canonical fields (always present):**
- `revenue` (canonical.revenue_gross)
- `customer_id` (canonical.customer_count)
- `region`
- `product`
- `date`

### 3.4 `data_quality_metrics`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `source_id` | `uuid FK → source_connections.id` | |
| `metric_name` | `text` | "completeness", "freshness", "accuracy" |
| `metric_value` | `numeric` | 0-100 |
| `measured_at` | `timestamptz` | |

---

## 4. Intelligence Pipeline

### 4.1 `analytical_results`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Revenue by Region Q3", "Customer Retention Analysis" |
| `type` | `text` | "revenue_analysis", "retention", "anomaly_detection" |
| `period` | `text` | "Q3 2026", "Last 12 Months" |
| `metrics` | `jsonb` | { "total_revenue": 4200000, "growth_rate": 12.4, ... } |
| `anomalies_detected` | `integer` | |
| `source_mapping_ids` | `uuid[]` | FK → field_mappings.id (lineage) |
| `computed_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

### 4.2 `forecasts`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Q3 Revenue Forecast" |
| `scenario` | `text CHECK (IN ('base','upside','downside'))` | |
| `forecast_value` | `numeric` | |
| `confidence` | `numeric` | 0-100 |
| `period` | `text` | "Q3 2026" |
| `dimensions` | `jsonb` | { "region": "all", "product_line": "all" } |
| `drivers` | `jsonb` | ["Market demand surge", "Seasonal uptick"] |
| `risks` | `jsonb` | ["Competitor entry APAC", "Churn rate stability"] |
| `source_mapping_ids` | `uuid[]` | FK → field_mappings.id |
| `analytical_result_id` | `uuid FK → analytical_results.id` | |
| `created_at` | `timestamptz` | |

**Canonical forecast scenarios (seed data):**
| Scenario | Value | Confidence |
|----------|-------|------------|
| **Base** | **$18.6M** | **91%** |
| Upside | $20.7M | — |
| Downside | $17.2M | — |

### 4.3 `insights`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Revenue Anomaly: South Region" |
| `type` | `text` | "anomaly", "opportunity", "risk", "revenue", "customer", "product" |
| `severity` | `text CHECK (IN ('critical','high','medium','low'))` | |
| `confidence` | `numeric` | 0-100 |
| `explanation` | `text` | "A sudden deceleration in revenue growth..." |
| `status` | `text CHECK (IN ('active','acknowledged','resolved','dismissed'))` | |
| `source_data` | `jsonb` | { "source": "Salesforce CRM", "mapping": "South Region Data Hub" } |
| `lineage` | `jsonb` | { analytical_result_id, forecast_id, source_mapping_ids[] } |
| `supporting_metrics` | `jsonb` | { "expected_impact": -450000, "period": "7 days" } |
| `recommended_action_title` | `text` | "Increase ad spend in South Region ($50k)" |
| `recommended_action_owner` | `text` | "Marketing" |
| `created_at` | `timestamptz` | |

**Lineage object:**
```json
{
  "source": { "name": "Salesforce CRM", "field_mapping": "South Region Data Hub" },
  "analytical_result_id": "uuid-or-null",
  "forecast_id": "uuid-or-null",
  "canonical_fields_used": ["revenue", "region"]
}
```

**Mock data mapping:**
| Mock Insight | Type | Severity | Confidence | Impact |
|-------------|------|----------|------------|--------|
| Revenue Anomaly: South Region | anomaly | high | 94% | -$450k |
| Product B Cross-sell Opportunity | opportunity | medium | 88% | +$280k |
| Customer Churn Alert: Enterprise Tier | risk | high | 91% | -12 accounts |

### 4.4 `actions`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Recover South Region Revenue" |
| `description` | `text` | |
| `priority` | `text CHECK (IN ('critical','high','medium','low'))` | |
| `owner` | `text` | "Marketing", "Operations", "Sales" |
| `status` | `text CHECK (IN ('todo','in_progress','blocked','completed','cancelled'))` | |
| `expected_impact` | `numeric` | Dollar amount |
| `confidence` | `numeric` | 0-100 |
| `source_insight_id` | `uuid FK → insights.id` | Lineage: where this action came from |
| `source_type` | `text` | "ai_insight", "forecast", "ai_analyst" |
| `due_date` | `date` | |
| `checklist` | `jsonb` | [{ "label": "...", "completed": true }, ...] |
| `execution_started_at` | `timestamptz` | |
| `completed_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

**Mock data mapping:**
| Mock Action | Source | Priority | Status | Impact | Confidence |
|------------|--------|----------|--------|--------|------------|
| Recover South Region Revenue | AI Insights | critical | in_progress | $450k | 94% |
| Increase Product B Inventory | Forecast | high | todo | $620k | 96% |
| Launch Enterprise Cross-Sell | AI Insights | high | in_progress | $280k | 88% |
| Review South Region Pricing | AI Analyst | medium | blocked | $190k | 81% |

### 4.5 `reports`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Executive Performance Q3" |
| `type` | `text` | "executive", "financial", "sales", "customers", "operations" |
| `status` | `text CHECK (IN ('draft','scheduled','generated'))` | |
| `owner_id` | `uuid FK → profiles.id` | |
| `impact` | `text` | "High", "Medium", "Critical" |
| `content` | `jsonb` | Report body / structured data |
| `referenced_insight_ids` | `uuid[]` | FK → insights.id |
| `referenced_action_ids` | `uuid[]` | FK → actions.id |
| `last_generated_at` | `timestamptz` | |
| `shared_with` | `jsonb` | [{ "group": "Board Members" }] |
| `created_at` | `timestamptz` | |

**Mock data mapping:**
| Mock Report | Type | Owner | Status | Impact |
|------------|------|-------|--------|--------|
| Executive Performance Q3 | executive | Sarah Lee | generated | High |
| Global Financial Rollup | financial | John Doe | scheduled | Medium |
| Enterprise Churn Analysis | customers | Mike Kim | draft | High |
| Q4 Sales Forecast | sales | Anna Lin | generated | Critical |
| Supply Chain Efficiency | operations | Tom Ross | generated | Medium |

---

## 5. Security System

### 5.1 `audit_events`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `user_id` | `uuid FK → profiles.id` | |
| `event_type` | `text` | "permission_updated", "login_failed", "report_exported", etc. |
| `module` | `text` | "Team", "Security", "Reports", "Data Sources", "Forecasts" |
| `severity` | `text CHECK (IN ('critical','high','medium','low'))` | |
| `status` | `text CHECK (IN ('successful','blocked','failed'))` | |
| `change_payload` | `jsonb` | { "before": "View Only", "after": "Manage Access" } |
| `context` | `jsonb` | { "ip": "192.168.1.1", "device": "Chrome", "location": "San Francisco, CA" } |
| `created_at` | `timestamptz` | |

**Mock data mapping:**
| Timestamp | User | Event | Module | Severity | Status |
|-----------|------|-------|--------|----------|--------|
| 10:42 AM | Sarah Lee | Permission updated | Team | Medium | Successful |
| 10:35 AM | John Doe | Report exported | Reports | Low | Successful |
| 10:12 AM | Mike Kim | Failed login attempt | Security | Critical | Blocked |
| 09:55 AM | Anna Lin | Data source configured | Data Sources | High | Successful |
| 09:30 AM | Tom Ross | Forecast viewed | Forecasts | Low | Successful |

### 5.2 `threats`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `title` | `text` | "Suspicious Login Pattern" |
| `description` | `text` | |
| `severity` | `text CHECK (IN ('critical','high','medium','low'))` | |
| `status` | `text CHECK (IN ('detected','investigating','contained','resolved'))` | |
| `source_audit_event_id` | `uuid FK → audit_events.id` | Lineage |
| `confidence` | `numeric` | 0-100 |
| `detected_at` | `timestamptz` | |
| `resolved_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

### 5.3 `playbooks`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `name` | `text` | "Brute Force Protection" |
| `description` | `text` | |
| `trigger_event_type` | `text` | "login_failed" |
| `auto_execute_threshold` | `numeric` | 90 (confidence gate) |
| `requires_human_approval` | `boolean` | true for critical |
| `is_active` | `boolean` | |
| `created_at` | `timestamptz` | |

### 5.4 `playbook_rules`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `playbook_id` | `uuid FK → playbooks.id` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `condition` | `jsonb` | { "field": "failed_attempts", "op": ">=", "value": 5 } |
| `action` | `jsonb` | { "type": "block_ip", "notify": "admin" } |
| `priority` | `integer` | Execution order |

### 5.5 `security_actions`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `threat_id` | `uuid FK → threats.id` | Lineage |
| `playbook_id` | `uuid FK → playbooks.id` | Lineage |
| `approval_id` | `uuid FK → approvals.id` | Lineage |
| `action_type` | `text` | "block_ip", "disable_account", "enforce_mfa" |
| `status` | `text CHECK (IN ('pending_approval','approved','executed','denied'))` | |
| `executed_at` | `timestamptz` | |
| `executed_by` | `uuid FK → profiles.id` | |
| `created_at` | `timestamptz` | |

### 5.6 `approvals`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `security_action_id` | `uuid FK → security_actions.id` | |
| `approver_id` | `uuid FK → profiles.id` | |
| `decision` | `text CHECK (IN ('pending','approved','denied'))` | |
| `reason` | `text` | |
| `decided_at` | `timestamptz` | |
| `created_at` | `timestamptz` | |

### 5.7 `audit_entries`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `security_action_id` | `uuid FK → security_actions.id` | Lineage |
| `event_type` | `text` | "security_action_executed" |
| `details` | `jsonb` | Full audit record |
| `created_at` | `timestamptz` | |

---

## 6. What-If Simulator

### 6.1 `simulation_scenarios`
| Column | Type | Notes |
|--------|------|-------|
| `id` | `uuid PK` | |
| `organization_id` | `uuid FK → organizations.id` | |
| `name` | `text` | "Scenario A: Product B Growth" |
| `variables` | `jsonb` | See below |
| `projected_metrics` | `jsonb` | See below |
| `ai_analysis` | `jsonb` | { "impact_drivers": [...], "risks": [...] } |
| `created_by` | `uuid FK → profiles.id` | |
| `created_at` | `timestamptz` | |

**Variables JSONB:**
```json
{
  "product_price_change_pct": -10,
  "marketing_spend_change_pct": 25,
  "customer_acquisition_rate_change_pct": 8,
  "discount_pct": 15
}
```

**Projected metrics JSONB:**
```json
{
  "revenue": 14100000,
  "revenue_change_pct": 13.7,
  "profit": 3500000,
  "profit_change_pct": 9.4,
  "active_customers": 84200,
  "active_customers_change_pct": 18.1,
  "profit_margin_pct": 24.8,
  "profit_margin_change_pct": -1.2
}
```

---

## 7. Permission System (RLS Strategy)

### 7.1 Roles

| Role | Capabilities |
|------|-------------|
| **Admin** | Full access to all modules, manage members, configure settings, approve security actions |
| **Manager** | View + Edit all modules, cannot manage members or security policies |
| **Restricted** | View-only access, cannot export, cannot create actions |

### 7.2 Module Permissions Table

Each user can have per-module permission overrides:

```sql
CREATE TABLE module_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id),
  user_id uuid REFERENCES profiles(id),
  module text NOT NULL, -- 'overview', 'analytics', 'ai_insights', etc.
  permission text CHECK (IN ('view','edit','manage','no_access')),
  UNIQUE(organization_id, user_id, module)
);
```

### 7.3 RLS Strategy

**Core pattern:** Every table with `organization_id` gets an RLS policy that checks `auth.uid()` → `profiles.organization_id` matches the row's `organization_id`.

```sql
-- Example: insights table
ALTER TABLE insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON insights
  FOR ALL
  USING (
    organization_id = (
      SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
  );
```

**Additional policies:**

| Table | Extra Policy |
|-------|-------------|
| `profiles` | Users can only see their own org's profiles |
| `source_connections` | Admin/Manager can edit; Restricted can only view |
| `actions` | Restricted users cannot INSERT/UPDATE |
| `security_actions` | Only Admin can approve |
| `approvals` | Only Admin can decide |
| `audit_events` | Read-only for all; only system writes |
| `module_permissions` | Only Admin can modify |

### 7.4 Server-Side Governance Enforcement

**AI Confidence Gate (90%):**
```sql
-- Function to check if an automated action is allowed
CREATE OR REPLACE FUNCTION can_auto_execute(
  p_confidence numeric,
  p_severity text,
  p_org_id uuid
) RETURNS boolean AS $$
DECLARE
  v_threshold numeric;
  v_settings jsonb;
BEGIN
  SELECT settings INTO v_settings FROM organizations WHERE id = p_org_id;
  v_threshold := (v_settings->>'ai_confidence_gate')::numeric;
  
  -- Must meet confidence threshold
  IF p_confidence < v_threshold THEN
    RETURN false;
  END IF;
  
  -- Critical severity always requires human approval
  IF p_severity = 'critical' THEN
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;
```

**Session timeout & failed login enforcement** handled via Supabase Auth hooks and Edge Functions.

---

## 8. Lineage Graph

```
source_connections
  └── source_fields
        └── field_mappings
              ├── analytical_results (via source_mapping_ids)
              │     ├── forecasts (via analytical_result_id + source_mapping_ids)
              │     └── insights (via lineage.analytical_result_id)
              │           ├── actions (via source_insight_id)
              │           │     └── reports (via referenced_action_ids)
              │           └── reports (via referenced_insight_ids)
              └── insights (via lineage.source_mapping_ids)

audit_events
  └── threats (via source_audit_event_id)
        └── security_actions (via threat_id)
              ├── approvals (via security_action_id)
              └── audit_entries (via security_action_id)

simulation_scenarios (standalone, references field_mappings indirectly)
```

---

## 9. Table Count Summary

| Category | Tables | Count |
|----------|--------|-------|
| Organization & Auth | `organizations`, `profiles` | 2 |
| Data Foundation | `source_connections`, `source_fields`, `field_mappings`, `data_quality_metrics` | 4 |
| Intelligence Pipeline | `analytical_results`, `forecasts`, `insights`, `actions`, `reports` | 5 |
| Security System | `audit_events`, `threats`, `playbooks`, `playbook_rules`, `security_actions`, `approvals`, `audit_entries` | 7 |
| What-If Simulator | `simulation_scenarios` | 1 |
| Permissions | `module_permissions` | 1 |
| **Total** | | **20** |

---

## 10. ER Diagram (Text)

```
organizations ──── profiles
       │               │
       ├── source_connections ──── source_fields ──── field_mappings
       │                                            │
       │                                    data_quality_metrics
       │                                            │
       ├── analytical_results ──────────────────────┤
       │       │                                    │
       │       └── forecasts ◄──────────────────────┘
       │               │
       ├── insights ◄──┘ (lineage JSONB)
       │       │
       │       └── actions
       │               │
       ├── reports ◄────┘ (referenced_insight_ids, referenced_action_ids)
       │
       ├── audit_events
       │       │
       │       └── threats
       │               │
       │               ├── security_actions ──── approvals
       │               │         │
       │               │         └── audit_entries
       │               │
       │               └── playbooks ──── playbook_rules
       │
       ├── simulation_scenarios
       │
       └── module_permissions
```

---

## 11. Seed Data — Canonical Demo Entities

These values MUST be preserved in the initial seed:

| Entity | Field | Canonical Value |
|--------|-------|----------------|
| Source Connection (aggregate) | total records | **42.8M** |
| Forecast (base) | forecast_value | **$18.6M** |
| Forecast (base) | confidence | **91%** |
| Forecast (upside) | forecast_value | **$20.7M** |
| Forecast (downside) | forecast_value | **$17.2M** |
| Governance Rule | ai_confidence_gate | **90%** |
| Insight | title | **"Revenue Anomaly: South Region"** |
| Action | title | **"Recover South Region Revenue"** |
| Threat | title | **"Suspicious Login Pattern"** |
| Playbook | name | **"Brute Force Protection"** |
| Organization Settings | session_timeout | **30 minutes** |
| Organization Settings | failed_login_threshold | **5 attempts** |
| Organization Settings | mfa_required | **true** |

---

## 12. What This Proposal Does NOT Cover

- ❌ UI changes to any page
- ❌ Groq / LLM integration
- ❌ Edge Functions for data sync
- ❌ Real-time subscriptions
- ❌ File storage (avatars, exports)
- ❌ API route design (future REST/GraphQL)
- ❌ Migration scripts (to be designed after approval)

---

**Awaiting your review. Once approved, I will produce the migration SQL and seed script.**
