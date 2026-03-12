# CLAUDE.md

This file provides guidance for AI assistants working in this repository.

## Repository Overview

**Name:** MRBRO — Matter Readiness and Billing Risk Orchestrator
**Owner:** jstewartMT
**Status:** MVP design complete, pending Power Platform build

An operational control layer for law firm Finance Operations teams. Tracks matter readiness across five billing-risk dimensions, manages exceptions, and maintains audit trails.

## Project Structure

```
First-Project/
├── CLAUDE.md              # AI assistant guidance (this file)
├── README.md              # Project overview and quick start
├── docs/
│   ├── architecture.md    # Architecture with Mermaid diagrams
│   ├── build-guide.md     # Deployment instructions
│   ├── demo-script.md     # Demo walkthrough
│   └── backlog.md         # Prioritized product backlog
├── sql/
│   ├── 001_schema.sql     # DDL — all tables, indexes, constraints
│   ├── 002_seed_data.sql  # Seed data — 10 matters, lookups, users
│   ├── 003_views.sql      # Views — posture board, workbench, dashboard
│   └── 004_rules_engine.sql # Stored procedures — rules, posture rollup
├── powerapps/
│   ├── app-spec.md        # Canvas app config, data binding, theme
│   ├── screens.md         # Screen-by-screen functional spec
│   └── powerfx-snippets.md # Reusable Power Fx formulas
├── powerautomate/
│   ├── flow-specs.md      # Flow definitions (5 flows)
│   └── notification-patterns.md # Notification matrix and templates
├── fabric/
│   ├── semantic-model-spec.md # Power BI semantic model + DAX
│   ├── reporting-spec.md  # Power BI report spec (4 pages)
│   └── integration-roadmap.md # Fabric migration path
└── src/
    └── rules-engine/
        └── posture-rules.json # Business rules reference (human-readable)
```

## Tech Stack

- **Front end:** Power Apps Canvas App
- **Database:** Azure SQL Database
- **Workflows:** Power Automate (standard connectors only)
- **Analytics:** Power BI (direct SQL connection for MVP, Fabric for future)
- **Identity:** Microsoft Entra ID

## Development Workflow

### Branching

- The default branch should be used for stable, reviewed code.
- Feature branches should use descriptive names.

### Key Conventions

- SQL is the source of truth for business rules (stored procedures in `004_rules_engine.sql`)
- All rule changes must be reflected in both SQL and `posture-rules.json`
- No AI dependencies without feature flags (default OFF)
- Only standard Power Platform connectors — no premium/custom connectors in MVP
- Every state change must produce an audit trail entry

### Commits

- Write clear, descriptive commit messages.
- Keep commits focused on a single logical change.

### Pull Requests

- Provide a summary of changes and a test plan.
- Link related issues when applicable.

## Build & Test

- Deploy SQL scripts in order: 001 → 002 → 003 → 004
- Verify with: `SELECT * FROM dbo.vw_MatterPostureBoard` (should return 10 rows)
- Test rules engine: insert events and run `sp_ProcessEvent`
- See `docs/build-guide.md` for full deployment instructions

## Conventions

- Keep the repository clean — use a `.gitignore` appropriate for the project's language/framework.
- Prefer editing existing files over creating new ones to avoid file bloat.
- Do not commit secrets, credentials, or `.env` files.

## AI Assistant Guidelines

- Read existing code before suggesting modifications.
- Keep changes minimal and focused on what was requested.
- Do not add unnecessary abstractions, comments, or refactors beyond the task at hand.
- When modifying SQL, ensure audit trail entries are always created.
- When modifying rules, update both the stored procedure and `posture-rules.json`.
- When unsure about project conventions, check recent commits and existing code patterns.
