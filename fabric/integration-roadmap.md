# Fabric Integration Roadmap

## Phase Progression

### Phase 0: MVP (Current)
- Power BI → Azure SQL (direct connection, Import mode)
- No Fabric infrastructure required
- 4-hour scheduled refresh
- Works with Power BI Pro licensing (no Fabric capacity needed)

### Phase 1: Fabric Mirroring (Post-MVP, ~Month 2-3)
- Enable Azure SQL Database Mirroring in Fabric
- Data automatically syncs to Fabric Lakehouse (near real-time)
- Power BI switches from direct SQL to Fabric Lakehouse as source
- Benefit: decouples analytics workload from transactional database

### Phase 2: Silver Layer (Month 3-4)
- Add Fabric Notebook or Dataflow Gen2 to create Silver tables
- Implement SCD Type 2 for `dim_Matter` (track posture history)
- Create `fact_PostureSnapshot` (daily snapshots for trending)
- Create `fact_ExceptionLifecycle` (duration from create → resolve)
- Add date dimension

### Phase 3: External Data Integration (Month 4-6)
- PMS integration: matter master, timekeeper data, time entries
- eBilling vendor data: submission status, rejection reasons
- Rate management system: approved rates, rate cards
- All ingested via Fabric Pipelines → Bronze → Silver

### Phase 4: Gold Layer + Advanced Analytics (Month 6+)
- Pre-aggregated KPI tables for fast dashboard loading
- Predictive models: which matters are likely to need escalation?
- Trend analysis: exception resolution time trending, seasonal patterns
- Cross-firm benchmarking (if multi-office data available)

## Integration Connector Strategy

| Source System | Connector Method | Fabric Component |
|---|---|---|
| Azure SQL (MRBRO) | Fabric Mirroring | Lakehouse (Bronze) |
| 3E / Aderant (PMS) | Fabric Pipeline + REST/ODBC | Lakehouse (Bronze) |
| eBilling vendor (e.g., Legal Tracker) | Fabric Pipeline + SFTP/API | Lakehouse (Bronze) |
| Rate management | Fabric Pipeline + SQL/File | Lakehouse (Bronze) |
| SharePoint (documents) | Fabric Shortcut or Pipeline | Lakehouse (Bronze) |

## Fabric Workspace Layout

```
Workspace: MRBRO - Analytics
├── Lakehouse: MRBRO_Lakehouse
│   ├── Tables (Bronze - mirrored)
│   │   ├── Matters
│   │   ├── ReadinessDimensions
│   │   ├── Exceptions
│   │   ├── Events
│   │   └── AuditEntries
│   ├── Tables (Silver - transformed)
│   │   ├── dim_Matter (SCD2)
│   │   ├── dim_Date
│   │   ├── fact_PostureSnapshot
│   │   └── fact_ExceptionLifecycle
│   └── Tables (Gold - aggregated)
│       ├── kpi_MatterReadiness
│       └── kpi_ExceptionHealth
├── Semantic Model: MRBRO_Model
├── Report: MRBRO Leadership Dashboard
├── Notebook: MRBRO_Silver_Transform
└── Pipeline: MRBRO_Daily_Refresh
```
