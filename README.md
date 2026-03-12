# MRBRO — Matter Readiness and Billing Risk Orchestrator

An operational control layer for law firm Finance Operations teams. Tracks matter readiness across five dimensions, manages billing risk through event-driven exception handling, and maintains a full audit trail of every decision and override.

## What This Is

MRBRO is **not** a chatbot or a passive dashboard. It is an active system that:

1. **Creates a readiness posture** for every matter at intake
2. **Tracks what is known, unknown, conditional, or unresolved** across five dimensions
3. **Re-evaluates billing risk** when events happen (new timekeeper, OCG received, rate mismatch, etc.)
4. **Routes exceptions** to the correct operational owner (Finance Ops, Billing, Rates)
5. **Auto-escalates** when deadlines are missed or prebill milestones are reached
6. **Logs everything** — every status change, every override, every decision is auditable

## Architecture

**Stack:** Power Apps Canvas App + Azure SQL Database + Power Automate + Microsoft Fabric/Power BI

```
Power Apps ──→ Azure SQL ──→ Power Automate ──→ Teams/Email
    ↑              ↑              │
    │              │              │
    └──────────────┘              │
    (SQL Server connector)        │
                                  │
Power BI ←── Fabric ←── Azure SQL ←┘
```

All business rules live in SQL stored procedures. No AI dependencies. No premium connectors required for core functionality.

## Readiness Dimensions

| Dimension | What It Tracks |
|---|---|
| **Commercial** | Engagement letter status — existing EL, master agreement, new EL needed, or unclear |
| **Guideline** | Outside counsel guidelines — received, processed, restrictions identified |
| **Rate** | Rate approval — standard rates, special rates, mismatches, client approval |
| **Staffing** | Timekeeper status — new timekeepers detected, approval and rate confirmation |
| **eBilling** | Electronic billing setup — vendor setup, client approval, submission readiness |

Each dimension rolls up to an **overall posture**: Ready, Ready with Monitored Unknowns, Ready with Active Exceptions, Restricted, or Escalation Required.

## Repo Structure

```
├── docs/
│   ├── architecture.md          # Architecture decision record with Mermaid diagrams
│   ├── build-guide.md           # Step-by-step deployment instructions
│   ├── demo-script.md           # 25-minute demo walkthrough
│   └── backlog.md               # Prioritized product backlog
├── sql/
│   ├── 001_schema.sql           # Full DDL — tables, indexes, constraints
│   ├── 002_seed_data.sql        # 10 realistic matters with exceptions and events
│   ├── 003_views.sql            # Views for posture board, workbench, dashboard
│   └── 004_rules_engine.sql     # Stored procedures — event processing, posture rollup
├── powerapps/
│   ├── app-spec.md              # App config, data binding, theme, variables
│   ├── screens.md               # 6 screens — layout, controls, behavior
│   └── powerfx-snippets.md      # Reusable Power Fx formulas
├── powerautomate/
│   ├── flow-specs.md            # 5 flow definitions with DLP-safe connector strategy
│   └── notification-patterns.md # Notification matrix, Teams adaptive cards, email templates
├── fabric/
│   ├── semantic-model-spec.md   # Power BI semantic model, DAX measures
│   ├── reporting-spec.md        # 4-page Power BI report specification
│   └── integration-roadmap.md   # Fabric Lakehouse migration path
└── src/
    └── rules-engine/
        └── posture-rules.json   # Human-readable business rules reference
```

## Quick Start

1. **Provision Azure SQL** — See `docs/build-guide.md` for Azure CLI commands
2. **Run SQL scripts** in order: `001_schema.sql` → `002_seed_data.sql` → `003_views.sql` → `004_rules_engine.sql`
3. **Verify** — `SELECT * FROM dbo.vw_MatterPostureBoard` should return 10 matters
4. **Build Power Apps** — Follow `powerapps/app-spec.md` and `powerapps/screens.md`
5. **Deploy Power Automate flows** — Follow `powerautomate/flow-specs.md`
6. **Build Power BI report** — Follow `fabric/reporting-spec.md`

## Key Design Decisions

- **Rules in SQL, not AI:** Every business rule is an explicit conditional in a stored procedure. Auditable, editable, testable.
- **Unknown is valid:** "No OCG known" doesn't block a matter — it's tracked as a monitored unknown.
- **Exceptions are first-class:** Not just flags — they have owners, severity, due dates, lifecycle states, and override audit trails.
- **Feature flags for AI:** AI capabilities (OCG parsing, risk scoring) are feature-flagged and default to OFF.
- **DLP-safe by design:** Only standard Power Platform connectors. No HTTP, no custom connectors, no AI Builder in MVP.

## Roles

| Role | Access |
|---|---|
| Admin | Full access, user management, feature flags |
| Finance Ops | Exception management, posture updates, event simulation |
| Billing | Guideline and eBilling exceptions |
| Rates | Rate and staffing exceptions |
| Viewer | Read-only posture board and dashboard |

## License

Internal use only. Proprietary to the firm.
