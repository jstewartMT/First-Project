# Microsoft Fabric Semantic Model Specification

## Architecture Decision

**MVP:** Power BI connects directly to Azure SQL views. No Fabric pipeline needed yet.

**Future state:** Azure SQL → Fabric Mirroring (or Pipeline) → Lakehouse → Semantic Model → Power BI.

This is the right sequencing because:
1. The MVP has <50 matters and <500 exceptions — direct SQL is fine
2. Fabric Mirroring for Azure SQL is the lowest-friction ingestion path
3. The semantic model layer becomes valuable when we add cross-source analytics (PMS data, time entry data, eBilling vendor data)

## MVP: Direct SQL Connection

Power BI connects to Azure SQL using **Import** mode (scheduled refresh, 4x daily) or **DirectQuery** (real-time, slight latency).

**Recommendation for MVP:** Import mode with 4-hour refresh. Leadership dashboards don't need sub-second latency, and Import gives better calculated measure performance.

### Source Views for Power BI

| Power BI Table | SQL Source | Refresh |
|---|---|---|
| PostureBoard | `vw_MatterPostureBoard` | 4-hour |
| ExceptionWorkbench | `vw_ExceptionWorkbench` | 4-hour |
| PostureSummary | `vw_DashboardPostureSummary` | 4-hour |
| ExceptionsByType | `vw_DashboardExceptionsByType` | 4-hour |
| ExceptionsByAge | `vw_DashboardExceptionsByAge` | 4-hour |
| TopBlockers | `vw_DashboardTopBlockers` | 4-hour |
| OverriddenMatters | `vw_DashboardOverriddenMatters` | 4-hour |
| AuditTrail | `vw_MatterAuditTrail` | Daily |
| LookupPosture | `dbo.LookupPosture` | Weekly |

### Relationships (Star Schema)

```
                    ┌─────────────────┐
                    │ LookupPosture   │
                    │ PostureCode (PK)│
                    └────────┬────────┘
                             │ 1
                             │
                    ┌────────┴────────┐
           ┌───────┤  PostureBoard    ├───────┐
           │       │  (Fact table)    │       │
           │       └────────┬────────┘       │
           │                │                │
    ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐
    │ ExcByType   │  │ ExcByAge    │  │ TopBlockers │
    │ (Fact)      │  │ (Fact)      │  │ (Fact)      │
    └─────────────┘  └─────────────┘  └─────────────┘
```

### DAX Measures

```dax
// Measure: Total Open Exceptions
Total Open Exceptions =
CALCULATE(
    COUNTROWS(ExceptionWorkbench),
    NOT(ExceptionWorkbench[StatusCode] IN {"Resolved", "Closed", "Overridden"})
)

// Measure: Critical Exception Count
Critical Exceptions =
CALCULATE(
    COUNTROWS(ExceptionWorkbench),
    ExceptionWorkbench[Severity] = "Critical",
    NOT(ExceptionWorkbench[StatusCode] IN {"Resolved", "Closed", "Overridden"})
)

// Measure: Average Exception Age (Days)
Avg Exception Age =
CALCULATE(
    AVERAGE(ExceptionWorkbench[AgeDays]),
    NOT(ExceptionWorkbench[StatusCode] IN {"Resolved", "Closed", "Overridden"})
)

// Measure: Matters at Risk (Restricted + Escalation)
Matters at Risk =
CALCULATE(
    COUNTROWS(PostureBoard),
    PostureBoard[PostureCode] IN {"RESTRICTED", "ESCALATION_REQUIRED"}
)

// Measure: Overdue Exception %
Overdue Exception Pct =
DIVIDE(
    CALCULATE(
        COUNTROWS(ExceptionWorkbench),
        ExceptionWorkbench[IsOverdue] = 1
    ),
    [Total Open Exceptions],
    0
)

// Measure: Exception Resolution Rate (Last 30 Days)
Resolution Rate 30d =
VAR _resolved = CALCULATE(
    COUNTROWS(ExceptionWorkbench),
    ExceptionWorkbench[StatusCode] IN {"Resolved", "Closed"},
    ExceptionWorkbench[ResolvedAt] >= TODAY() - 30
)
VAR _created = CALCULATE(
    COUNTROWS(ExceptionWorkbench),
    ExceptionWorkbench[CreatedAt] >= TODAY() - 30
)
RETURN DIVIDE(_resolved, _created, 0)
```

---

## Future State: Fabric Lakehouse

### Medallion Architecture (when ready)

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   BRONZE     │    │   SILVER     │    │    GOLD      │
│              │    │              │    │              │
│ Raw SQL      │───→│ Cleaned +    │───→│ Aggregated   │
│ mirror data  │    │ Conformed    │    │ Semantic     │
│              │    │ + SCD Type 2 │    │ Model        │
│ - Matters    │    │ for posture  │    │              │
│ - Exceptions │    │ history      │    │ - KPIs       │
│ - Events     │    │              │    │ - Trends     │
│ - Audit      │    │ + Derived    │    │ - Forecasts  │
│              │    │ metrics      │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
       ↑
  Fabric Mirroring
  (Azure SQL → Lakehouse)
```

### When to Move to Fabric

| Signal | Action |
|---|---|
| >200 active matters | Consider Import → Fabric pipeline for performance |
| Need trend analysis over time | Implement SCD Type 2 in Silver layer for posture history |
| PMS integration goes live | Fabric pipeline to join PMS data with MRBRO data |
| Time entry data needed | Fabric pipeline from time/billing system |
| Cross-firm analytics requested | Gold layer with firm-wide KPIs |

### Fabric Tables (Future)

**Silver layer additions:**
- `dim_Matter` — SCD Type 2 (tracks posture changes over time)
- `dim_Date` — standard date dimension
- `fact_PostureSnapshot` — daily posture snapshots for trending
- `fact_ExceptionLifecycle` — exception create → resolve duration metrics
- `fact_EventProcessing` — event volume and processing latency

**Gold layer:**
- `kpi_MatterReadiness` — pre-aggregated readiness scores
- `kpi_ExceptionHealth` — resolution rates, aging trends
- `kpi_TeamPerformance` — exception handling by team/role
