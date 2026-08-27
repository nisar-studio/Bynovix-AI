# Bynovix AI — Enterprise Intelligence Suite

## Overview

Bynovix AI is an enterprise intelligence platform that connects business data, analytics, forecasting, explainable AI, strategic actions, reporting, governance, and security response into one traceable system.

**Core principle:** DATA → INTELLIGENCE → DECISION → ACTION → PROOF  
**Security principle:** EVENT → DETECTION → GOVERNANCE → APPROVAL → RESPONSE → AUDIT

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Static HTML + JavaScript + Tailwind CSS (CDN) |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Serverless | Supabase Edge Functions (Deno/TypeScript) |
| AI | Groq API (planned, not yet integrated) |
| Routing | Hash-based SPA (`#overview`, `#analytics`, etc.) |

## Project Structure

```
Bynovix AI/
├── index.html                    # App shell, auth, router, DB helpers
├── pages/                        # 12 module pages
│   ├── overview.html             # Executive Overview
│   ├── analytics.html            # Analytics
│   ├── ai-insights.html          # AI Insights
│   ├── ai-analyst.html           # AI Analyst
│   ├── forecasts.html            # Forecast Intelligence
│   ├── what-if.html              # What-If Simulator
│   ├── actions.html              # Actions Execution
│   ├── reports.html              # Comprehensive Reports
│   ├── data.html                 # Data Sources & Mapping
│   ├── team.html                 # Team & Permissions
│   ├── security.html             # Security & Audit Logs
│   └── settings.html             # Organization Settings
├── supabase/
│   ├── migrations/               # Database schema
│   │   ├── 001_extensions.sql    # UUID, pgcrypto extensions
│   │   ├── 002_tables.sql        # 22 tables
│   │   ├── 003_indexes.sql       # Performance indexes
│   │   ├── 004_rls.sql           # Row Level Security policies
│   │   ├── 005_functions.sql     # PostgreSQL functions/triggers
│   │   └── 006_seed.sql          # Canonical demo data
│   ├── functions/                # Edge Functions
│   │   ├── sync-data-source/     # Sync data source records + quality
│   │   ├── generate-insight/     # Generate AI insights with governance
│   │   └── respond-to-threat/    # Threat response with playbook matching
│   ├── prod_smoke_test.js        # 171-test production verification suite
│   └── config.toml               # Supabase project config
├── BYNOVIX_MASTER_PRD.md         # Authoritative product specification
├── ARCHITECTURE_PROPOSAL.md      # Database architecture proposal
├── FINAL_MIGRATION_PLAN.md       # Migration execution plan
├── .gitignore
└── README.md
```

## Database Schema

22 tables organized into business and security domains:

**Foundation:** `organizations`, `profiles`, `org_policies`  
**Data:** `source_connections`, `source_fields`, `field_mappings`, `data_quality_metrics`  
**Intelligence:** `analytical_results`, `forecasts`, `insights`, `actions`, `reports`  
**Security:** `audit_events`, `threats`, `playbooks`, `playbook_rules`, `security_actions`, `approvals`, `audit_entries`  
**Simulation:** `simulation_scenarios`  
**Governance:** `module_permissions`, `lineage_edges`

## Authentication & Users

| Email | Password | Role | Org |
|-------|----------|------|-----|
| sarah.lee@bynovix.com | BynovixAdmin@1 | Admin | Bynovix AI |
| john.doe@bynovix.com | BynovixAdmin@1 | Manager | Bynovix AI |
| mike.jones@bynovix.com | BynovixAdmin@1 | Restricted | Bynovix AI |
| alice.smith@bynovix.com | BynovixAdmin@1 | Admin | Acme Corp |
| bob.wilson@bynovix.com | BynovixAdmin@1 | Manager | Acme Corp |

**RLS enforced:** Users can only access data within their organization. Cross-org access blocked server-side.

## Edge Functions

| Function | Purpose | Governance |
|----------|---------|------------|
| `sync-data-source` | Syncs source records, updates quality metrics, logs audit | N/A |
| `generate-insight` | Creates AI insights, enforces confidence gate (90%), explainability | ✅ Server-side |
| `respond-to-threat` | Matches playbooks, creates threats, queues critical actions for approval | ✅ Server-side |

**Invoke via:**
```bash
curl -X POST https://ddsjxafkhxijypgsbvcu.supabase.co/functions/v1/sync-data-source \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"source_id": "UUID_HERE"}'
```

## Canonical Demo Data

- **42.8M** processed records across 5 data sources
- **$18.6M** base revenue forecast (91% confidence)
- **Upside:** $20.7M / **Downside:** $17.2M
- **3 AI Insights** (South Region Anomaly, Churn Alert, Cross-sell)
- **4 Actions** with cross-module lineage
- **5 Audit Events** including Brute Force Protection threat
- **2 Organizations** with isolated data (Bynovix AI, Acme Corp)

## Production URL

**https://bynovix-ai.netlify.app**

| Property | Value |
|----------|-------|
| Platform | Netlify (Free Tier) |
| Hosting URL | https://bynovix-ai.netlify.app |
| Admin Panel | https://app.netlify.com/projects/bynovix-ai |

## Running Locally

```bash
# Start a local server (from project root)
python -m http.server 8080
# or
npx http-server . -p 8080 -c-1

# Open http://localhost:8080
# Login with: sarah.lee@bynovix.com / BynovixAdmin@1
```

## Running Smoke Tests

```bash
cd supabase
node prod_smoke_test.js
```

Requires Node.js. Tests 171 assertions covering schema, auth, RLS, RBAC, governance, canonical data, Edge Functions, and frontend configuration.

## Supabase Project

| Property | Value |
|----------|-------|
| Project Ref | `ddsjxafkhxijypgsbvcu` |
| URL | `https://ddsjxafkhxijypgsbvcu.supabase.co` |
| Dashboard | `https://supabase.com/dashboard/project/ddsjxafkhxijypgsbvcu` |

## Remaining Work (Not Started)

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 9 | Groq AI integration | Paused |
| Phase 10 | Salesforce / enterprise data sources | Paused |
| Phase 11 | Production QA | ✅ Complete |
| Production | CI/CD, monitoring, error tracking | Not started |

## Authoritative Documents

- [BYNOVIX_MASTER_PRD.md](./BYNOVIX_MASTER_PRD.md) — Product requirements and technical specification
- [ARCHITECTURE_PROPOSAL.md](./ARCHITECTURE_PROPOSAL.md) — Database architecture proposal
- [FINAL_MIGRATION_PLAN.md](./FINAL_MIGRATION_PLAN.md) — Migration execution plan

---

*Built with Bynovix AI Enterprise Intelligence Suite*
