# Bynovix AI — Enterprise Intelligence Suite

> An enterprise intelligence platform that connects business data, analytics, forecasting, explainable AI, strategic actions, reporting, governance, and security response into one fully traceable system.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Supabase](https://img.shields.io/badge/supabase-postgresql-green.svg)
![Tailwind](https://img.shields.io/badge/tailwind-CSS-38bdf8.svg)
![Deployed](https://img.shields.io/badge/deployed-netlify-00c7b7.svg)
![Status](https://img.shields.io/badge/status-production-brightgreen.svg)

---

## Core Principles

```
DATA → INTELLIGENCE → DECISION → ACTION → PROOF
EVENT → DETECTION → GOVERNANCE → APPROVAL → RESPONSE → AUDIT
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND (SPA)                         │
│           Static HTML + JS + Tailwind CSS                   │
│         12 Modules · Hash-based Router · Auth               │
└────────────────────────┬────────────────────────────────────┘
                         │ Supabase Client SDK
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────┐  │
│  │ Postgres │  │   RLS    │  │    Edge Functions         │  │
│  │  22 tbl  │  │  Policies│  │  sync · insight · threat  │  │
│  └──────────┘  └──────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Intelligence Pipeline

```
Data Sources → Field Mapping → Analytics → Forecasts → AI Insights → Actions → Reports
```

### Security Pipeline

```
Audit Event → Threat Detection → Playbook → AI Confidence Gate → Human Approval → Security Action → Audit Entry
```

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | HTML + JavaScript + Tailwind CSS | Client application |
| Backend | Supabase (PostgreSQL) | Database, Auth, RLS |
| Serverless | Supabase Edge Functions (Deno/TypeScript) | API logic |
| AI | Groq API (qwen/qwen3.8-27b) | Insight generation |
| Hosting | Netlify (Free Tier) | Static deployment |
| Auth | Supabase Auth + Row Level Security | Authentication & authorization |

---

## Project Structure

```
bynovix-ai/
├── frontend/                    # Client Application
│   ├── index.html              # App shell, auth, router, Supabase client
│   └── pages/                  # 12 module pages
│       ├── overview.html       # Executive Overview — KPIs, alerts, forecasts
│       ├── analytics.html      # Analytics — charts, trends, segments
│       ├── ai-insights.html    # AI Insights — anomaly detection, priority feed
│       ├── ai-analyst.html     # AI Analyst — natural language queries
│       ├── forecasts.html      # Forecast Intelligence — projections, scenarios
│       ├── what-if.html        # What-If Simulator — scenario modeling
│       ├── actions.html        # Actions Execution — task management
│       ├── reports.html        # Comprehensive Reports — BI reports
│       ├── data.html           # Data Sources — connections, mapping, quality
│       ├── team.html           # Team & Permissions — RBAC management
│       ├── security.html       # Security & Audit Logs — threat monitoring
│       └── settings.html       # Organization Settings — governance control
│
├── backend/                     # Supabase Backend
│   ├── migrations/             # Database Schema (6 migration files)
│   │   ├── 001_extensions.sql  # UUID, pgcrypto extensions
│   │   ├── 002_tables.sql      # 22 tables with relationships
│   │   ├── 003_indexes.sql     # Performance indexes
│   │   ├── 004_rls.sql         # Row Level Security policies
│   │   ├── 005_functions.sql   # PostgreSQL functions & triggers
│   │   └── 006_seed.sql        # Canonical demo data
│   │
│   ├── functions/              # Edge Functions (TypeScript/Deno)
│   │   ├── sync-data-source/   # Sync data records + quality metrics
│   │   ├── generate-insight/   # AI insight generation + governance
│   │   └── respond-to-threat/  # Threat response + playbook matching
│   │
│   ├── tests/                  # Backend Tests
│   │   └── prod_smoke_test.js  # 171-test production verification suite
│   │
│   └── config.toml             # Supabase project configuration
│
├── docs/                        # Documentation
│   ├── PRD.md                  # Master Product Requirements Document
│   ├── ARCHITECTURE.md         # Database Architecture Proposal
│   └── MIGRATION_PLAN.md       # Migration Execution Plan
│
├── LICENSE                      # MIT License
├── README.md                    # This file
└── .gitignore
```

---

## Features

### 12 Enterprise Modules

| # | Module | Description |
|---|--------|-------------|
| 1 | **Executive Overview** | Real-time KPIs, alerts, forecasts, and trend indicators |
| 2 | **Analytics** | Interactive charts, segment analysis, revenue trends |
| 3 | **AI Insights** | Automated anomaly detection with confidence scoring |
| 4 | **AI Analyst** | Natural language query interface for business data |
| 5 | **Forecast Intelligence** | Revenue projections with scenario modeling |
| 6 | **What-If Simulator** | Base/Upside/Downside scenario comparisons |
| 7 | **Actions Execution** | Strategic action tracking with source lineage |
| 8 | **Comprehensive Reports** | Business intelligence report generation |
| 9 | **Data Sources** | Source connection management and field mapping |
| 10 | **Team & Permissions** | RBAC with Admin/Manager/Restricted roles |
| 11 | **Security & Audit Logs** | Threat monitoring and audit trail |
| 12 | **Organization Settings** | Governance control plane |

### Database Schema

22 tables organized across business and security domains:

- **Foundation:** `organizations`, `profiles`, `org_policies`
- **Data:** `source_connections`, `source_fields`, `field_mappings`, `data_quality_metrics`
- **Intelligence:** `analytical_results`, `forecasts`, `insights`, `actions`, `reports`
- **Security:** `audit_events`, `threats`, `playbooks`, `playbook_rules`, `security_actions`, `approvals`, `audit_entries`
- **Simulation:** `simulation_scenarios`
- **Governance:** `module_permissions`, `lineage_edges`

### Edge Functions

| Function | Purpose | Governance |
|----------|---------|------------|
| `sync-data-source` | Syncs source records, updates quality metrics | — |
| `generate-insight` | Creates AI insights with Groq integration + fallback | ✅ 90% confidence gate |
| `respond-to-threat` | Matches playbooks, creates threats, queues approvals | ✅ Human approval required |

---

## Security & Governance

- **Row Level Security (RLS):** Organization-scoped data isolation enforced at the database level
- **RBAC:** Admin / Manager / Restricted roles with module-level permissions
- **AI Governance:** 90% confidence gate enforced server-side
- **Human Approval:** Required for critical security actions
- **Explainability:** Required for all AI decisions
- **Audit Logging:** Every mutation logged with full context
- **Lineage Tracking:** Complete entity lineage via `lineage_edges` junction table

---

## Getting Started

### Prerequisites

- Node.js 18+ (for smoke tests)
- A [Supabase](https://supabase.com) project (or use the existing one)

### Run Locally

```bash
# Clone the repository
git clone https://github.com/your-username/bynovix-ai.git
cd bynovix-ai

# Start a local server
cd frontend
python -m http.server 8080
# or
npx http-server . -p 8080 -c-1

# Open http://localhost:8080
```

### Demo Credentials

| Email | Password | Role |
|-------|----------|------|
| sarah.lee@bynovix.com | BynovixAdmin@1 | Admin |
| john.doe@bynovix.com | BynovixManager@1 | Manager |
| mike.kim@bynovix.com | BynovixRestricted@1 | Restricted |
| anna.lin@bynovix.com | BynovixManager@1 | Manager |
| tom.ross@bynovix.com | BynovixRestricted@1 | Restricted |

### Run Smoke Tests

```bash
cd backend/tests
node prod_smoke_test.js
```

Requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` environment variables.

---

## Database Setup

The backend uses Supabase with 6 sequential migrations:

```bash
# Using Supabase CLI
cd backend
supabase db push

# Or apply manually via Supabase SQL Editor:
# 1. 001_extensions.sql
# 2. 002_tables.sql
# 3. 003_indexes.sql
# 4. 004_rls.sql
# 5. 005_functions.sql
# 6. 006_seed.sql
```

---

## Canonical Demo Data

| Metric | Value |
|--------|-------|
| Processed Records | 42.8M |
| Base Revenue Forecast | $18.6M |
| Forecast Confidence | 91% |
| Upside Scenario | $20.7M |
| Downside Scenario | $17.2M |
| AI Confidence Gate | 90% |
| Data Sources | 5 |
| AI Insights | 4 |
| Strategic Actions | 4 |
| Security Events | 5 |

---

## API Usage

### Generate AI Insight

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate-insight \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_id": "YOUR_ORG_ID",
    "analytical_result_id": "YOUR_RESULT_ID",
    "use_groq": true
  }'
```

### Sync Data Source

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-data-source \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"source_id": "YOUR_SOURCE_ID"}'
```

### Respond to Threat

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/respond-to-threat \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"audit_event_id": "YOUR_EVENT_ID"}'
```

---

## Production Deployment

**Live URL:** [https://bynovix-ai.netlify.app](https://bynovix-ai.netlify.app)

| Component | Status |
|-----------|--------|
| Frontend (Netlify) | ✅ Deployed |
| Database (Supabase) | ✅ Live |
| Edge Functions | ✅ Deployed (3/3) |
| AI Integration (Groq) | ✅ Active |
| RLS/RBAC | ✅ Enforced |
| Smoke Tests | ✅ 171/171 Passing |

---

## Roadmap

- [ ] ~~Phase 1-7: Frontend + Backend Foundation~~ ✅
- [ ] ~~Phase 8: Edge Functions~~ ✅
- [ ] ~~Phase 9: Groq AI Integration~~ ✅
- [ ] ~~Phase 11: Production QA~~ ✅
- [ ] ~~Production Deployment~~ ✅
- [ ] Phase 10: Salesforce / Enterprise Data Sources
- [ ] CI/CD Pipeline (GitHub Actions)
- [ ] Mobile Responsive Design
- [ ] Real-time Notifications (WebSocket)
- [ ] Advanced Report Export (PDF/Excel)

---

## Documentation

| Document | Description |
|----------|-------------|
| [PRD.md](docs/PRD.md) | Master Product Requirements Document |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Database Architecture Proposal |
| [MIGRATION_PLAN.md](docs/MIGRATION_PLAN.md) | Migration Execution Plan |

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Bynovix AI</strong> — Enterprise Intelligence Suite<br>
  <sub>Built with Supabase · Tailwind CSS · Groq AI</sub>
</p>
