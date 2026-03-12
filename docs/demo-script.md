# MRBRO Demo Script

**Duration:** 20-25 minutes
**Audience:** Finance Ops leadership, IT stakeholders, Practice Group Leaders
**Presenter:** Solution architect / Finance Ops project lead

---

## Demo Setup

Before the demo, ensure:
- [ ] Azure SQL database is provisioned and seed data loaded (run `001_schema.sql`, `002_seed_data.sql`, `003_views.sql`, `004_rules_engine.sql`)
- [ ] Power Apps canvas app is connected and published
- [ ] Demo user accounts configured with different roles
- [ ] Browser tabs pre-loaded: Power Apps, Power BI dashboard

---

## Scene 1: The Problem (2 min)

**Talking points:**
> "Today, matter readiness is tracked in spreadsheets, emails, and tribal knowledge. When a matter opens, nobody has a single view of whether we have an engagement letter, whether outside counsel guidelines have been processed, whether rates are approved, or whether eBilling is set up. Problems surface at prebill — the most expensive time to discover them."

> "MRBRO changes this. It creates a single operational control layer that tracks readiness across five dimensions, from matter intake through billing."

---

## Scene 2: Posture Board (4 min)

**Open:** Posture Board screen

**Walk through:**
1. Show the portfolio view — 10 matters with color-coded readiness dots
2. Point out Matter 100001 (Acme Corp) — all green, fully ready
3. Point out Matter 100005 (Clearwater Energy) — mostly red, escalation required
4. Filter by posture: show only "Restricted" and "Escalation Required" matters
5. Filter by office: show only New York matters
6. Show the summary chips at the top — "At a glance, 3 of our 10 matters need attention"

**Key message:**
> "This replaces the 'Where are we on this matter?' question. Every matter's readiness is visible at all times."

---

## Scene 3: Matter Detail — Clean Matter (3 min)

**Tap:** Matter 100001 (Acme Corp)

**Walk through:**
1. Show the posture banner — "Ready" in green
2. Walk through each readiness dimension — all green
3. Show "No open exceptions"
4. Show event history — matter created → engagement basis confirmed → OCG received → OCG processed
5. Show audit trail — every status change logged with timestamp and user

**Key message:**
> "This is what good looks like. Full traceability from intake to ready."

---

## Scene 4: Matter Detail — Problem Matter (4 min)

**Navigate back, then tap:** Matter 100005 (Clearwater Energy)

**Walk through:**
1. Show the posture banner — "Escalation Required" in red
2. Walk through readiness dimensions — Commercial: Red, Rate: Red, Staffing: Red, eBilling: Red
3. Show 4 open exceptions with severities
4. Highlight the prebill blocker exception — "Prebill milestone reached with 4 unresolved high/critical exceptions"
5. Show the event timeline — matter created → late timekeepers detected → rate mismatch found → prebill milestone hit → auto-escalation
6. Point out the audit trail — severity was auto-escalated from High to Critical when prebill milestone was reached

**Key message:**
> "The system didn't just flag the problem — it tracked the entire history and auto-escalated when the prebill deadline arrived. This matter needs leadership attention."

---

## Scene 5: Exception Workbench (3 min)

**Navigate to:** Exception Workbench

**Walk through:**
1. Show the full exception queue — 14 open exceptions across all matters
2. Filter by severity: show only Critical — 3 items need immediate attention
3. Filter by role: show only "Rates" — what does the Rates team need to work on?
4. Toggle "Overdue" — show overdue exceptions highlighted
5. Tap an exception to show detail panel
6. Demo the "Resolve" action on a non-critical exception
7. Demo the "Override" action — show that an override reason is mandatory

**Key message:**
> "Every exception has an owner, a severity, and a due date. Nothing falls through the cracks."

---

## Scene 6: Event Simulator — Live Demo (5 min)

**Navigate to:** Event Simulator

**Scenario: Walk a new matter through its lifecycle**

1. **Fire event: "Matter Created"** for Matter 100006 (Pinnacle Healthcare)
   - Show result: all dimensions initialized, posture = "Ready with monitored unknowns" (because commercial and guideline start as Unknown)

2. **Fire event: "Engagement Basis Updated"** — select "Master agreement covers matter"
   - Show result: Commercial dimension goes Green, posture may improve

3. **Fire event: "OCG Received"**
   - Show result: Guideline dimension goes Amber (received but not processed), exception created

4. **Fire event: "New Timekeeper Detected"**
   - Show result: Staffing dimension goes Amber, new exception created
   - Navigate to posture board to see the updated matter

5. **Fire event: "OCG Processed with Restrictions"**
   - Show result: Guideline dimension stays Amber but with restrictions, new exception created for OCG restrictions

**Key message:**
> "This is how the system works in production — events flow in from integrations, and readiness is continuously re-evaluated. For the MVP, we simulate these events manually, but the rules engine is the same."

---

## Scene 7: Leadership Dashboard (2 min)

**Open:** Power BI dashboard (or Canvas App dashboard screen)

**Walk through:**
1. KPI cards — total matters, at-risk matters, critical exceptions
2. Donut chart — matters by posture
3. Bar chart — exceptions by aging bucket (highlight the 15+ day items)
4. Top blockers — rate mismatches are the #1 blocker category
5. Override count — 0 overrides (clean governance so far)

**Key message:**
> "Leadership gets a single pane of glass. No more asking 'How many matters are we worried about?' The answer is always current."

---

## Scene 8: Rules and Auditability (2 min)

**Talking points:**
> "Every business rule is explicit and editable. There's no AI magic here — the rules are written in SQL stored procedures that we control. For example:"

Show rules:
- "If commercial basis is unclear, create an exception owned by Finance Ops"
- "If OCG has material restrictions, create an exception owned by Billing"
- "If unresolved exceptions remain at prebill milestone, auto-escalate severity"

> "Every decision is logged. We can tell you exactly why a matter's posture changed, who changed it, and when. Overrides require a reason and are permanently recorded."

---

## Scene 9: Roadmap (2 min)

1. **Next:** Connect to practice management system for automatic matter creation events
2. **Next:** Connect to time entry system for automatic timekeeper detection
3. **Next:** eBilling vendor integration for submission status
4. **Future:** Fabric analytics layer for trend analysis and predictive risk scoring
5. **Future:** AI-assisted OCG parsing (feature-flagged, only when DLP-approved)

---

## Demo Scenarios (Pre-Seeded Data)

| # | Scenario | Matters | What It Shows |
|---|---|---|---|
| 1 | Clean lifecycle | 100001 (Acme) | Happy path — all green, fully audited |
| 2 | Monitored unknowns | 100002 (Global Bank), 100006 (Pinnacle), 100010 (Apex) | Unknown OCG status is tracked, not ignored |
| 3 | Active exceptions | 100003 (TechStart), 100009 (United Insurance) | Rate/staffing exceptions managed through workbench |
| 4 | Restricted matter | 100004 (MegaCorp), 100007 (Sterling) | Multiple amber/red dimensions, multiple exceptions |
| 5 | Full escalation | 100005 (Clearwater) | Critical exceptions, prebill blocker, escalation path |

## Sample User Stories for Backlog

| ID | Story | Priority |
|---|---|---|
| US-001 | As a Finance Ops analyst, I want to see all matters and their readiness status so I can prioritize my work | P0 - MVP |
| US-002 | As a Billing specialist, I want to see only exceptions assigned to my role so I can focus on my queue | P0 - MVP |
| US-003 | As a Rates analyst, I want to be notified when a new timekeeper is detected so I can set up rates proactively | P0 - MVP |
| US-004 | As a Finance Ops manager, I want to override an exception with a mandatory reason so we can proceed while maintaining audit trail | P0 - MVP |
| US-005 | As a leadership stakeholder, I want to see a dashboard of matter readiness and exception health so I can make resource decisions | P0 - MVP |
| US-006 | As a Finance Ops analyst, I want the system to auto-escalate exceptions at prebill milestone so nothing is missed | P0 - MVP |
| US-007 | As an Admin, I want to configure feature flags so I can enable/disable notification channels | P1 |
| US-008 | As a Finance Ops analyst, I want to receive a daily digest of open exceptions in Teams | P1 |
| US-009 | As a Billing specialist, I want OCG restriction details captured so I can set up billing rules | P1 |
| US-010 | As a leadership stakeholder, I want to see posture trends over time so I can track improvement | P2 |
