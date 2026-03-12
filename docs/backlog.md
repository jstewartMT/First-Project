# Product Backlog — MRBRO

## Priority Legend
- **P0:** MVP — must ship in first release
- **P1:** Fast-follow — ship within 2-4 weeks of MVP
- **P2:** Near-term — ship within 1-3 months
- **P3:** Future — roadmap item, not yet scheduled

---

## P0 — MVP

- [x] Architecture design and documentation
- [x] SQL schema DDL
- [x] Seed data for 10 realistic matters
- [x] Views for posture board, exception workbench, leadership dashboard
- [x] Rules engine stored procedures (7 event types)
- [x] Posture rollup logic
- [x] Exception lifecycle management (create, resolve, override)
- [x] Power Apps screen specifications (6 screens)
- [x] Power Fx implementation snippets
- [x] Event simulator design
- [x] Power Automate flow specs (5 flows)
- [x] Power BI reporting spec
- [x] Demo script and scenarios
- [ ] Power Apps canvas app build (requires Power Platform environment)
- [ ] Azure SQL provisioning and schema deployment
- [ ] Power Automate flow deployment
- [ ] Power BI report build and publish
- [ ] End-to-end smoke test with seed data
- [ ] Role assignment for 5 pilot users

## P1 — Fast Follow

- [ ] Teams notifications for high-severity exceptions (Flow 1)
- [ ] Daily exception digest (Flow 2)
- [ ] Exception auto-escalation timer (Flow 3)
- [ ] Audit trail export to SharePoint (Flow 5)
- [ ] Bulk status update (select multiple exceptions, resolve in batch)
- [ ] Matter search and quick-navigate from any screen
- [ ] Responsive layout for mobile (phone layout)
- [ ] User profile screen (view own role, notification preferences)
- [ ] Exception comments/notes thread
- [ ] Document signal management (upload/link engagement letters, OCGs)

## P2 — Near Term

- [ ] PMS integration (3E/Aderant) — auto-create matters and detect timekeepers
- [ ] Rate management system integration — auto-detect rate mismatches
- [ ] eBilling vendor integration — auto-track submission status
- [ ] Fabric Mirroring for Azure SQL → Lakehouse
- [ ] SCD Type 2 for posture history (trend tracking)
- [ ] Power BI: posture trend analysis over time
- [ ] Power BI: exception resolution time distribution
- [ ] Power BI: team workload and performance metrics
- [ ] Entra ID-based row-level security (replace soft RBAC)
- [ ] Override approval flow for Critical exceptions (Flow 4)
- [ ] Custom exception types (admin-configurable)
- [ ] Custom readiness dimensions (admin-configurable)
- [ ] Email notifications as fallback to Teams
- [ ] Exception SLA tracking (target resolution time by severity)

## P3 — Future

- [ ] AI-assisted OCG parsing and restriction extraction (feature-flagged)
- [ ] Predictive risk scoring (which matters are likely to need escalation?)
- [ ] Natural language search for audit trail
- [ ] Multi-entity/multi-jurisdiction matter grouping
- [ ] Client portal view (limited external visibility)
- [ ] Integration with conflict checking systems
- [ ] Integration with matter budgeting tools
- [ ] Copilot-powered exception triage suggestions
- [ ] Cross-firm benchmarking analytics (Gold layer in Fabric)
- [ ] Automated rate card comparison and approval workflow
- [ ] Webhook API for external system event ingestion
- [ ] Power Pages external portal for client-facing status
