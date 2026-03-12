# Power BI Reporting Specification

## Report: MRBRO Leadership Dashboard

**Audience:** Finance leadership, COO, CFO, Practice Group Leaders
**Refresh:** Every 4 hours (Import mode)
**RLS:** Row-level security by office/practice group via Entra ID group mapping

---

## Page 1: Executive Summary

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ MRBRO — Matter Readiness Overview              Last refresh: [time] │
├───────────┬───────────┬───────────┬───────────┬─────────────────────┤
│           │           │           │           │                     │
│  [KPI]    │  [KPI]    │  [KPI]    │  [KPI]    │  [KPI]             │
│  Total    │  At Risk  │  Critical │  Overdue  │  Overridden        │
│  Matters  │  Matters  │  Exc.     │  Exc. %   │  Matters           │
│  47       │  3        │  4        │  28%      │  0                 │
│           │           │           │           │                     │
├───────────┴───────────┴───────────┴───────────┴─────────────────────┤
│                                                                      │
│  ┌──────────────────────────┐  ┌──────────────────────────────────┐ │
│  │ MATTERS BY POSTURE       │  │ EXCEPTIONS BY SEVERITY           │ │
│  │ (Donut chart)            │  │ (Stacked bar chart)              │ │
│  │                          │  │                                  │ │
│  │  Ready ████ 2            │  │ Critical ██████ 4                │ │
│  │  Monitored ████ 3       │  │ High     █████ 5                 │ │
│  │  Exceptions ███ 2       │  │ Medium   ████ 4                  │ │
│  │  Restricted ██ 2        │  │ Low      █ 1                     │ │
│  │  Escalation █ 1         │  │                                  │ │
│  └──────────────────────────┘  └──────────────────────────────────┘ │
│                                                                      │
│  ┌──────────────────────────┐  ┌──────────────────────────────────┐ │
│  │ EXCEPTIONS BY AGE        │  │ TOP BLOCKER CATEGORIES           │ │
│  │ (Clustered bar)          │  │ (Horizontal bar)                 │ │
│  │                          │  │                                  │ │
│  │ 0-3 days   ████ 5       │  │ Rate mismatch        ████ 3     │ │
│  │ 4-7 days   ███ 4        │  │ Missing EL           ███ 2      │ │
│  │ 8-14 days  ██ 3         │  │ TK not approved      ███ 2      │ │
│  │ 15+ days   █ 2          │  │ OCG restrictions     ██ 1       │ │
│  └──────────────────────────┘  └──────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

### Visuals

| Visual | Type | Source | Measures |
|---|---|---|---|
| Total Matters | Card | PostureBoard | COUNTROWS |
| At Risk Matters | Card | PostureBoard | [Matters at Risk] |
| Critical Exceptions | Card | ExceptionWorkbench | [Critical Exceptions] |
| Overdue % | Card | ExceptionWorkbench | [Overdue Exception Pct] |
| Overridden Matters | Card | OverriddenMatters | OverriddenMatterCount |
| Posture Donut | Donut chart | PostureSummary | MatterCount by PostureLabel |
| Exceptions by Severity | Stacked bar | ExceptionsByType | ExceptionCount by Severity |
| Exceptions by Age | Clustered bar | ExceptionsByAge | ExceptionCount by AgingBucket |
| Top Blockers | Horizontal bar | TopBlockers | OccurrenceCount by BlockerCategory |

### Color Coding

Use the posture hex values from `LookupPosture` as chart colors:
- Ready: `#2E7D32`
- Monitored: `#558B2F`
- Exceptions: `#F9A825`
- Restricted: `#E65100`
- Escalation: `#B71C1C`

---

## Page 2: Matter Posture Detail

### Layout

Matrix visual showing all matters with conditional formatting.

| Visual | Type | Source |
|---|---|---|
| Posture Matrix | Matrix | PostureBoard |

**Rows:** MatterNumber, ClientName, ResponsibleLawyer
**Values:** CommercialRisk, GuidelineRisk, RateRisk, StaffingRisk, EBillingRisk, PostureLabel, OpenExceptionCount

**Conditional formatting:**
- Risk columns: background color based on Green/Amber/Red/Unknown values
- PostureLabel: background color from ColorHex
- OpenExceptionCount: data bars

**Slicers:**
- Office (dropdown)
- Practice Group (dropdown)
- Posture (checkboxes)
- Responsible Lawyer (searchable dropdown)

---

## Page 3: Exception Deep Dive

### Layout

| Visual | Type | Source |
|---|---|---|
| Exception Table | Table | ExceptionWorkbench |
| Aging Trend | Line chart | ExceptionsByAge (future: daily snapshots) |
| Severity Breakdown | Treemap | ExceptionWorkbench grouped by Type × Severity |
| Owner Workload | Bar chart | ExceptionWorkbench grouped by OwnerRoleLabel |

**Slicers:**
- Severity (checkboxes)
- Status (checkboxes)
- Owner Role (dropdown)
- Date range (relative date slicer: last 7/14/30/90 days)

---

## Page 4: Audit & Compliance

### Layout

| Visual | Type | Source |
|---|---|---|
| Audit Timeline | Table (sorted by date) | AuditTrail |
| Override Log | Filtered table | ExceptionWorkbench where IsOverridden = 1 |
| Event Volume | Bar chart by date | AuditTrail grouped by date |

**Purpose:** Compliance and governance teams need to see all decisions, overrides, and status changes.

---

## Row-Level Security (RLS)

### Roles

| RLS Role | Filter | Effect |
|---|---|---|
| All Matters | None | Leadership sees everything |
| By Office | `PostureBoard[Office] = USERPRINCIPALNAME()` mapped via security table | Users see only their office's matters |
| By Practice Group | `PostureBoard[PracticeGroup] = ...` | PG leaders see their group only |

### Implementation

```dax
// RLS role: OfficeFilter
[Office] = LOOKUPVALUE(
    SecurityMapping[Office],
    SecurityMapping[UserEmail],
    USERPRINCIPALNAME()
)
```

MVP shortcut: Deploy with the "All Matters" role for now; add RLS roles when office-level filtering is requested.

---

## Deployment

1. Publish to a **Premium Per User** or **Fabric F-capacity** workspace: `MRBRO - Finance Ops`
2. Set up scheduled refresh (4-hour cadence)
3. Configure gateway if Azure SQL requires on-prem gateway (usually not needed for Azure SQL + Entra auth)
4. Share with Entra security groups: `MRBRO-Viewer`, `MRBRO-FinanceOps`, `MRBRO-Admin`
