# BYNOVIX AI — MASTER PRD + TECHNICAL ARCHITECTURE SPECIFICATION

> **Version:** 1.0  
> **Date:** August 24, 2026  
> **Status:** AUTHORITATIVE — Source of Truth  
> **Cross-references:** `ARCHITECTURE_PROPOSAL.md`, `FINAL_MIGRATION_PLAN.md`

---

## TABLE OF CONTENTS

1. [Product](#1-product)
2. [Current Frontend Technology — LOCKED](#2-current-frontend-technology--locked)
3. [Current Application Modules](#3-current-application-modules)
4. [Core Business Workflow](#4-core-business-workflow)
5. [Security Workflow](#5-security-workflow)
6. [Canonical Product Data](#6-canonical-product-data)
7. [Backend Technology — LOCKED](#7-backend-technology--locked)
8. [Database Architecture](#8-database-architecture)
9. [Lineage](#9-lineage)
10. [Organization Isolation](#10-organization-isolation)
11. [RBAC](#11-rbac)
12. [Governance](#12-governance)
13. [AI Requirements](#13-ai-requirements)
14. [What-If Simulator](#14-what-if-simulator)
15. [Reporting](#15-reporting)
16. [Actions](#16-actions)
17. [Data Sources](#17-data-sources)
18. [Security](#18-security)
19. [Organization Settings](#19-organization-settings)
20. [Current Edge Functions](#20-current-edge-functions)
21. [Development Order](#21-development-order)
22. [Non-Negotiable Constraints](#22-non-negotiable-constraints)
23. [Acceptance Criteria](#23-acceptance-criteria)
24. [Implementation Status](#24-implementation-status)
25. [Cross-Reference Index](#25-cross-reference-index)

---

## 1. PRODUCT

**Product name:**  
Bynovix AI — Enterprise Intelligence Suite

**Purpose:**  
An enterprise intelligence platform that connects business data, analytics, forecasting, explainable AI, strategic actions, reporting, governance, and security response into one traceable system.

**Core product principle:**

```
DATA → INTELLIGENCE → DECISION → ACTION → PROOF
```

**Security principle:**

```
EVENT → DETECTION → GOVERNANCE → APPROVAL → RESPONSE → AUDIT
```

---

## 2. CURRENT FRONTEND TECHNOLOGY — LOCKED

The frontend is currently:

- Static HTML
- JavaScript
- Tailwind CSS via CDN
- Google Fonts (Geist, Inter, JetBrains Mono)
- Google Material Symbols
- Hash-based SPA routing
- Shared application shell (sidebar + topbar)
- Stitch-generated UI exports consolidated into one SPA

**Main entry:** `index.html`

### LOCKED — Do NOT change unless explicitly requested

- Do NOT migrate to React, Vue, Next.js, Angular, or another frontend framework
- Do NOT redesign the existing Bynovix UI
- Do NOT replace the frontend framework

### Approved Visual System

| Property | Value |
|----------|-------|
| Background | `#0C0C0E` |
| Operational surfaces | `#1A1A1C` |
| Primary accent | indigo |
| AI accent | indigo-to-violet |
| Typography | premium enterprise / Geist-style hierarchy |
| Logo | Approved geometric B |
| Prohibited | cyan/blue visual drift, white logo containers, light-theme regression |

---

## 3. CURRENT APPLICATION MODULES

There are **12 canonical modules**:

| # | Module | Route | Backend Entities |
|---|--------|-------|------------------|
| 1 | Executive Overview | `#overview` | KPIs, forecasts, insights, actions, reports |
| 2 | Analytics | `#analytics` | analytical_results, field_mappings, data_quality_metrics |
| 3 | AI Insights | `#ai-insights` | insights, lineage_edges |
| 4 | AI Analyst | `#ai-analyst` | insights, analytical_results, forecasts |
| 5 | Forecast Intelligence | `#forecasts` | forecasts, analytical_results, lineage_edges |
| 6 | What-If Simulator | `#what-if` | simulation_scenarios, forecasts |
| 7 | Actions Execution | `#actions` | actions, insights |
| 8 | Comprehensive Reports | `#reports` | reports, insights, actions |
| 9 | Data Sources & Mapping | `#data` | source_connections, source_fields, field_mappings, data_quality_metrics |
| 10 | Team & Permissions | `#team` | profiles, module_permissions |
| 11 | Security & Audit Logs | `#security` | audit_events, threats, playbooks, security_actions, approvals, audit_entries |
| 12 | Organization Settings | `#settings` | organizations, org_policies |

### CRITICAL

These modules are **views into shared backend entities**.

They are **NOT** independent applications.

---

## 4. CORE BUSINESS WORKFLOW

The primary intelligence pipeline:

```
Data Sources
    ↓
Field Mapping / Validation
    ↓
Analytics
    ↓
Forecasts
    ↓
AI Insights
    ↓
Actions
    ↓
Reports
```

Every downstream result retains appropriate lineage.

### Canonical Example

```
Salesforce CRM
    ↓
Revenue / Region mapping
    ↓
Analytics
    ↓
South Region revenue anomaly
    ↓
Forecast risk
    ↓
AI Insight
    ↓
Recover South Region Revenue
    ↓
Executive Report
```

---

## 5. SECURITY WORKFLOW

```
Security Audit Event
    ↓
Threat Detection
    ↓
Playbook
    ↓
AI Confidence Gate
    ↓
Human Approval when required
    ↓
Security Action
    ↓
Audit Entry
```

### Canonical Example

```
Suspicious Login Pattern
    ↓
Brute Force Protection
    ↓
90% AI Confidence Gate
    ↓
Human Approval when required
    ↓
Block Suspicious IP
    ↓
Audit Entry
```

---

## 6. CANONICAL PRODUCT DATA

These canonical demonstration values MUST be preserved across connected modules:

| Category | Entity | Canonical Value |
|----------|--------|-----------------|
| Records | Total processed | **42.8M** (aggregate sum, not actual rows) |
| Forecast | Base Revenue | **$18.6M** |
| Forecast | Confidence | **91%** |
| Forecast | Upside | **$20.7M** |
| Forecast | Downside | **$17.2M** |
| Governance | AI Confidence Gate | **90%** |
| Security | Session Timeout | **30 minutes** |
| Security | Failed Login Threshold | **5 attempts** |
| Business | Canonical anomaly | South Region revenue/pricing pressure |
| Business | Canonical action | Recover South Region Revenue |
| Security | Canonical event | Suspicious Login Pattern |
| Security | Canonical playbook | Brute Force Protection |

These values remain consistent across connected modules unless intentionally changed through real data.

---

## 7. BACKEND TECHNOLOGY — LOCKED

| Layer | Technology |
|-------|-----------|
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| Authorization | PostgreSQL Row Level Security |
| Server-side logic | PostgreSQL functions/triggers |
| Serverless/API | Supabase Edge Functions |
| Edge Function language | TypeScript |
| AI provider | Groq API (planned, NOT connected yet) |
| External integrations | Planned, NOT connected yet |

### LOCKED — Do NOT change unless explicitly requested

- Do NOT connect Groq until the Supabase foundation and frontend data integration are validated
- Do NOT connect Salesforce or external enterprise data sources until data mapping architecture is validated

---

## 8. DATABASE ARCHITECTURE

**22 tables** across 6 domain areas:

### 8.1 Organization & Auth (3 tables)

| Table | PK | Org-scoped | Description |
|-------|----|-----------|-------------|
| `organizations` | `id uuid` | — | Multi-tenant root |
| `org_policies` | `id uuid` | `organization_id FK` | Authoritative governance/security rules per org |
| `profiles` | `id uuid FK → auth.users` | `organization_id FK` | User identity + role |

### 8.2 Data Foundation (4 tables)

| Table | PK | Org-scoped | FK Targets |
|-------|----|-----------|------------|
| `source_connections` | `id uuid` | `organization_id FK` | — |
| `source_fields` | `id uuid` | `organization_id FK` | `source_connections.id` |
| `field_mappings` | `id uuid` | `organization_id FK` | `source_connections.id`, `source_fields.id` |
| `data_quality_metrics` | `id uuid` | `organization_id FK` | `source_connections.id` |

### 8.3 Intelligence Pipeline (5 tables)

| Table | PK | Org-scoped | FK Targets |
|-------|----|-----------|------------|
| `analytical_results` | `id uuid` | `organization_id FK` | — |
| `forecasts` | `id uuid` | `organization_id FK` | `analytical_results.id` |
| `insights` | `id uuid` | `organization_id FK` | — |
| `actions` | `id uuid` | `organization_id FK` | `insights.id` (via `source_insight_id`) |
| `reports` | `id uuid` | `organization_id FK` | `profiles.id` (owner) |

### 8.4 Security System (7 tables)

| Table | PK | Org-scoped | FK Targets |
|-------|----|-----------|------------|
| `audit_events` | `id uuid` | `organization_id FK` | `profiles.id` |
| `threats` | `id uuid` | `organization_id FK` | `audit_events.id` |
| `playbooks` | `id uuid` | `organization_id FK` | — |
| `playbook_rules` | `id uuid` | `organization_id FK` | `playbooks.id` |
| `security_actions` | `id uuid` | `organization_id FK` | `threats.id`, `playbooks.id`, `approvals.id` |
| `approvals` | `id uuid` | `organization_id FK` | `security_actions.id`, `profiles.id` (approver) |
| `audit_entries` | `id uuid` | `organization_id FK` | `security_actions.id` |

### 8.5 What-If Simulator (1 table)

| Table | PK | Org-scoped | FK Targets |
|-------|----|-----------|------------|
| `simulation_scenarios` | `id uuid` | `organization_id FK` | `profiles.id` (creator) |

### 8.6 Cross-Cutting (2 tables)

| Table | PK | Org-scoped | FK Targets |
|-------|----|-----------|------------|
| `module_permissions` | `id uuid` | `organization_id FK` | `profiles.id` |
| `lineage_edges` | `id uuid` | `organization_id FK` | Polymorphic source/target |

### Design Rules

- Do not create disconnected page-specific tables
- Shared entities must be reused across modules
- Every business/security table has `organization_id`
- RLS prevents cross-organization access

---

## 9. LINEAGE

Use `lineage_edges` as the persistent lineage graph.

### Business Lineage

```
Source
→ Mapping
→ Analytics
→ Forecast
→ Insight
→ Action
→ Report
```

### Security Lineage

```
Audit Event
→ Threat
→ Playbook
→ Approval
→ Security Action
→ Audit Entry
```

### Lineage Must Answer

| Question | Lineage Path |
|----------|-------------|
| Where did this number come from? | Report → Action/Insight → Forecast → Analytics → Mapping → Source |
| Why did the AI produce this insight? | Insight → Analytics + Forecast + Source Mapping |
| What action resulted from the insight? | Insight → Action |
| What report contains the outcome? | Action/Insight → Report |
| Which security event caused this response? | Security Action → Threat → Audit Event |
| Which policy governed the response? | Playbook → org_policies |

### lineage_edges Schema

```sql
CREATE TABLE lineage_edges (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  source_entity_type  text NOT NULL,
  source_entity_id    uuid NOT NULL,
  target_entity_type  text NOT NULL,
  target_entity_id    uuid NOT NULL,
  edge_type           text NOT NULL,  -- 'feeds_into', 'derived_from', 'triggered_by', 'produced_by'
  metadata            jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id, source_entity_type, source_entity_id, target_entity_type, target_entity_id, edge_type)
);
```

---

## 10. ORGANIZATION ISOLATION

The system is organization-scoped.

- Business/security records must be isolated by `organization_id` where appropriate
- RLS must prevent cross-organization access
- Never rely solely on frontend filtering for security

### RLS Pattern

Every table with `organization_id` gets an RLS policy:

```sql
CREATE POLICY "org_isolation" ON {table}
  FOR ALL
  USING (
    organization_id = (
      SELECT organization_id FROM profiles WHERE id = auth.uid()
    )
  );
```

---

## 11. RBAC

### Canonical Roles

| Role | Capabilities |
|------|-------------|
| **Admin** | Full access to all modules, manage members, configure settings, approve security actions |
| **Manager** | View + Edit all modules, cannot manage members or security policies |
| **Restricted** | View-only access, cannot export, cannot create actions |

### Module-Level Permissions

```sql
CREATE TABLE module_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id),
  user_id uuid REFERENCES profiles(id),
  module text NOT NULL,
  permission text CHECK (IN ('view','edit','manage','no_access')),
  UNIQUE(organization_id, user_id, module)
);
```

### Enforcement

- Permissions must be enforced server-side via RLS
- Frontend visibility is not sufficient security
- Module-level permission overrides are supported

---

## 12. GOVERNANCE

Authoritative organization policies are stored in `org_policies`:

```sql
CREATE TABLE org_policies (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  ai_confidence_gate              numeric NOT NULL DEFAULT 90,
  explainability_required         boolean NOT NULL DEFAULT true,
  auto_response_rollback_enabled  boolean NOT NULL DEFAULT true,
  mfa_required                    boolean NOT NULL DEFAULT true,
  session_timeout_minutes         integer NOT NULL DEFAULT 30,
  failed_login_threshold          integer NOT NULL DEFAULT 5,
  critical_requires_human_approval boolean NOT NULL DEFAULT true,
  audit_retention_days            integer NOT NULL DEFAULT 365,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id)
);
```

### Governance Rules

| Rule | Value | Enforcement |
|------|-------|-------------|
| AI Confidence Gate | **90%** | `can_auto_execute()` reads from `org_policies` |
| Critical security actions | **Human approval required** | `can_auto_execute()` returns false for severity='critical' |
| MFA | **Required** | `enforce_mfa()` checks auth.users metadata |
| Session Timeout | **30 minutes** | `validate_session()` checks `last_active_at` |
| Failed Login Threshold | **5 attempts** | `check_failed_login()` counts recent failures |
| Explainability | **Required** | Checked in `generate-insight` Edge Function |
| Automatic Rollback | **Enabled** | Checked in `respond-to-threat` Edge Function |

These policies must exist **server-side** and not merely as frontend labels.

---

## 13. AI REQUIREMENTS

- AI must be **explainable**
- AI outputs must retain:
  - Confidence
  - Explanation
  - Supporting evidence
  - Source lineage
  - Relevant analytical/forecast context
  - Originating organization
  - Timestamp
  - Status
- Automated actions must respect governance policies
- AI must **never bypass** server-side governance
- Groq will eventually provide inference
- Do **NOT** connect Groq until the Supabase foundation and frontend data integration are validated

---

## 14. WHAT-IF SIMULATOR

### Supported Scenarios

- Base Case
- Upside
- Downside

### Current UI Limitation

- Maximum **3 concurrent scenario comparisons**

### Scenario Schema

```sql
CREATE TABLE simulation_scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  name text NOT NULL,
  variables jsonb NOT NULL,
  projected_metrics jsonb NOT NULL,
  ai_analysis jsonb,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
```

Scenario calculations must eventually connect to real forecast/business data rather than remain isolated mock UI state.

---

## 15. REPORTING

Reports must be **traceable**.

A report may reference:
- Insights
- Actions
- Forecasts
- Analytics
- Supporting metrics

The user must be able to understand the source of important reported findings.

### Report Schema (key fields)

```sql
referenced_insight_ids  uuid[]    -- FK → insights.id
referenced_action_ids   uuid[]    -- FK → actions.id
content                 jsonb     -- Report body / structured data
```

---

## 16. ACTIONS

Actions contain operational information:

| Field | Type | Notes |
|-------|------|-------|
| title | text | |
| description | text | |
| owner | text | "Marketing", "Operations", "Sales" |
| priority | text | critical, high, medium, low |
| due_date | date | |
| status | text | todo, in_progress, blocked, completed, cancelled |
| notes | text | |
| expected_impact | numeric | Dollar amount |
| source_insight_id | uuid FK → insights.id | Lineage |
| source_type | text | ai_insight, forecast, ai_analyst |
| confidence | numeric | 0-100 |
| checklist | jsonb | [{ "label": "...", "completed": true }] |
| execution_started_at | timestamptz | |
| completed_at | timestamptz | |

Actions must preserve source traceability.

---

## 17. DATA SOURCES

Data Sources supports:
- Source connections
- Source health
- Source fields
- Canonical mappings
- Validation
- Conflicts
- Needs Review states
- Data quality
- Mapping versions
- Rollback
- Downstream impact

### Important

**42.8M records** is an aggregate demonstration metric (sum of `records_count` across all sources).

Do **NOT** seed 42.8M individual records.

### Source Connections (canonical)

| Source | Type | Method | Records | Status |
|--------|------|--------|---------|--------|
| Salesforce CRM | CRM | OAuth | 1,200,000 | connected |
| Snowflake DW | Data Warehouse | JDBC | 25,400,000 | connected |
| HubSpot | Marketing | API Key | 480,000 | syncing |
| PostgreSQL Legacy | Database | JDBC | 8,100,000 | error |
| Stripe Payments | Payments | API Key | 3,400,000 | connected |
| **Total** | | | **42,580,000** | |

---

## 18. SECURITY

Security & Audit Logs provide:
- Audit events
- Threat investigation
- Security event details
- Traceability
- Security posture

### Automated Threat Response / Playbooks must support:

- Trigger conditions
- AI confidence gate
- Human approval
- Dry run
- Rollback
- Execution context
- Auditability

### Security Entity Chain

```
audit_events → threats → playbooks → playbook_rules
                                ↓
                          security_actions → approvals
                                ↓
                           audit_entries
```

---

## 19. ORGANIZATION SETTINGS

Organization Settings is the **governance control plane**.

It governs:
- Organization profile
- Regional preferences
- Security policies
- AI governance
- MFA
- Session timeout
- Failed-login threshold
- AI confidence threshold
- Human approval
- Explainability
- Rollback policy
- Integrations
- Subscription/usage where applicable

### Controlled by `org_policies` table (server-side)

See [Section 12: Governance](#12-governance).

---

## 20. CURRENT EDGE FUNCTIONS

| Function | Purpose | Status |
|----------|---------|--------|
| `sync-data-source` | Data synchronization pipeline | Stub only |
| `generate-insight` | AI insight generation (Groq integration point) | Stub only |
| `respond-to-threat` | Automated threat response | Stub only |

These are **integration points only**. Do not connect external services yet.

---

## 21. DEVELOPMENT ORDER

Implementation **must** follow this order:

| Phase | Description | Status |
|-------|-------------|--------|
| **PHASE 1** | Validate Supabase migrations | ⏳ Pending |
| **PHASE 2** | Create/connect Supabase project | ⏳ Pending |
| **PHASE 3** | Apply schema, indexes, RLS, functions and seed data | ⏳ Pending |
| **PHASE 4** | Verify authentication and organization isolation | ⏳ Pending |
| **PHASE 5** | Connect frontend to Supabase | ⏳ Pending |
| **PHASE 6** | Replace mock data with real database queries | ⏳ Pending |
| **PHASE 7** | Implement persistent cross-module workflows | ⏳ Pending |
| **PHASE 8** | Deploy/test Edge Functions | ⏳ Pending |
| **PHASE 9** | Connect Groq | ⏳ Pending |
| **PHASE 10** | Connect Salesforce and other enterprise data sources | ⏳ Pending |
| **PHASE 11** | Production QA | ⏳ Pending |

**Do not skip ahead.**

---

## 22. NON-NEGOTIABLE CONSTRAINTS

Do **NOT**:

- [ ] Redesign the UI
- [ ] Change the Bynovix visual identity
- [ ] Replace the frontend framework
- [ ] Create disconnected CRUD pages
- [ ] Bypass RLS
- [ ] Enforce security only in JavaScript
- [ ] Invent new modules
- [ ] Invent arbitrary business metrics
- [ ] Connect Groq before the database foundation is validated
- [ ] Connect Salesforce before data mapping architecture is validated

---

## 23. ACCEPTANCE CRITERIA

The platform is considered functionally correct only when:

| # | Criterion | Category |
|---|-----------|----------|
| 1 | All 12 modules load | Frontend |
| 2 | Authentication works | Auth |
| 3 | Organization isolation works | Security |
| 4 | RBAC works | Security |
| 5 | Data Sources → Analytics → Forecast → Insight lineage works | Business Pipeline |
| 6 | Insight → Action → Report lineage works | Business Pipeline |
| 7 | Audit Event → Threat → Playbook → Approval → Security Action → Audit Entry lineage works | Security Pipeline |
| 8 | 90% confidence governance is enforced server-side | Governance |
| 9 | Critical actions require human approval | Governance |
| 10 | Audit history is persistent | Security |
| 11 | Existing canonical demonstration data remains consistent | Data Integrity |
| 12 | Existing Bynovix visual design remains unchanged | UI |
| 13 | Frontend uses real Supabase data instead of hardcoded mock data where implemented | Integration |
| 14 | No cross-organization data leakage is possible through frontend or API access | Security |

---

## 24. IMPLEMENTATION STATUS

| Artifact | Status | Location |
|----------|--------|----------|
| Stitch ZIP extracted | ✅ Complete | `stitch_extracted/` |
| 12-page SPA consolidated | ✅ Complete | `index.html`, `pages/` |
| Frontend running | ✅ Complete | `http://localhost:8080` |
| Architecture proposal | ✅ Complete | `ARCHITECTURE_PROPOSAL.md` |
| Final migration plan | ✅ Complete | `FINAL_MIGRATION_PLAN.md` |
| Migration SQL | ✅ Complete | `supabase/migrations/001-006` |
| RLS policies | ✅ Complete | `supabase/migrations/004_rls.sql` |
| Governance functions | ✅ Complete | `supabase/migrations/005_functions.sql` |
| Seed data | ✅ Complete | `supabase/migrations/006_seed.sql` |
| Edge Function stubs | ✅ Complete | `supabase/functions/` |
| Master PRD | ✅ Complete | `BYNOVIX_MASTER_PRD.md` |
| Supabase project created | ⏳ Pending | — |
| Migrations applied | ⏳ Pending | — |
| Frontend connected to Supabase | ⏳ Pending | — |
| Groq connected | ⏳ Pending | — |

---

## 25. CROSS-REFERENCE INDEX

| Document | Purpose | Relationship to this PRD |
|----------|---------|------------------------|
| `ARCHITECTURE_PROPOSAL.md` | Detailed entity schemas, mock data mapping, RLS strategy | Predecessor — approved and incorporated |
| `FINAL_MIGRATION_PLAN.md` | Migration file inventory, execution checklist | Implementation guide — derived from this PRD |
| `supabase/migrations/001_extensions.sql` | PostgreSQL extensions | Phase 3 implementation |
| `supabase/migrations/002_tables.sql` | 21 table definitions | Phase 3 implementation |
| `supabase/migrations/003_indexes.sql` | Performance indexes | Phase 3 implementation |
| `supabase/migrations/004_rls.sql` | Row Level Security policies | Phase 3 implementation |
| `supabase/migrations/005_functions.sql` | Governance enforcement functions | Phase 3 implementation |
| `supabase/migrations/006_seed.sql` | Canonical demo data | Phase 3 implementation |
| `supabase/functions/sync-data-source/index.ts` | Data sync stub | Phase 8 implementation |
| `supabase/functions/generate-insight/index.ts` | AI insight stub | Phase 8 implementation |
| `supabase/functions/respond-to-threat/index.ts` | Threat response stub | Phase 8 implementation |
| `index.html` | Frontend SPA shell | Phase 5-6 integration |
| `pages/*.html` | Module page content | Phase 5-6 integration |

---

## GOVERNANCE RULE

Before implementing anything that conflicts with this document, **stop and request clarification**.

This document is the **authoritative product + technical specification** for Bynovix AI.

---

*Generated: August 24, 2026*  
*Authoritative Version: 1.0*
