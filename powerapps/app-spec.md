# Power Apps Canvas App Specification

**App Name:** MRBRO — Matter Readiness & Billing Risk Orchestrator
**Type:** Canvas App (tablet-optimized, responsive)
**Data Source:** Azure SQL via SQL Server connector (standard)
**Auth:** Entra ID SSO (inherits from Power Platform environment)

## Data Binding Approach

All data access uses the **SQL Server connector** pointing to Azure SQL.

**Connection setup:**
- Server: `mrbro-sql.database.windows.net`
- Database: `MRBRO`
- Authentication: Azure AD Integrated

**Tables exposed to Power Apps:**
| Power Apps Name | SQL Source | Type |
|---|---|---|
| PostureBoard | `vw_MatterPostureBoard` | View (read) |
| ExceptionWorkbench | `vw_ExceptionWorkbench` | View (read) |
| Matters | `dbo.Matters` | Table (CRUD) |
| ReadinessDimensions | `dbo.ReadinessDimensions` | Table (read) |
| Exceptions | `dbo.Exceptions` | Table (CRUD) |
| Events | `dbo.Events` | Table (write) |
| AuditTrail | `vw_MatterAuditTrail` | View (read) |
| EventHistory | `vw_MatterEventHistory` | View (read) |
| LookupReadinessStatus | `dbo.LookupReadinessStatus` | Table (read) |
| LookupEventType | `dbo.LookupEventType` | Table (read) |
| LookupExceptionType | `dbo.LookupExceptionType` | Table (read) |
| LookupPosture | `dbo.LookupPosture` | Table (read) |
| Users | `dbo.Users` | Table (read) |
| DashPosture | `vw_DashboardPostureSummary` | View (read) |
| DashExcByType | `vw_DashboardExceptionsByType` | View (read) |
| DashExcByAge | `vw_DashboardExceptionsByAge` | View (read) |

**Delegation strategy:** All filtering/sorting done server-side via views and stored procedures. Canvas app displays results; does not rely on client-side delegation for critical operations.

## Navigation Structure

```
┌─────────────────────────────────────────────┐
│  Header Bar (persistent)                     │
│  [Logo] MRBRO    [Posture Board] [Exceptions]│
│  [Simulator] [Dashboard]     [User ▼] [⚙]  │
├─────────────────────────────────────────────┤
│  Screen Content Area                         │
└─────────────────────────────────────────────┘
```

**Navigation:** Top navigation bar using a `Component` shared across all screens. `Navigate()` calls with slide transitions.

## App-Level Variables

```
// OnStart
Set(varCurrentUser,
    LookUp(Users, Email = User().Email)
);
Set(varUserRole,
    If(IsBlank(varCurrentUser), "Viewer", varCurrentUser.RoleCode)
);
Set(varIsAdmin, varUserRole = "Admin");
Set(varCanEdit, varUserRole in ["Admin", "FinanceOps", "Billing", "Rates"]);
```

## Color Theme

```
Set(colReady,        ColorValue("#2E7D32"));
Set(colMonitored,    ColorValue("#558B2F"));
Set(colExceptions,   ColorValue("#F9A825"));
Set(colRestricted,   ColorValue("#E65100"));
Set(colEscalation,   ColorValue("#B71C1C"));
Set(colRiskGreen,    ColorValue("#4CAF50"));
Set(colRiskAmber,    ColorValue("#FF9800"));
Set(colRiskRed,      ColorValue("#F44336"));
Set(colRiskUnknown,  ColorValue("#9E9E9E"));
Set(colBgPrimary,    ColorValue("#FAFAFA"));
Set(colBgCard,       ColorValue("#FFFFFF"));
Set(colTextPrimary,  ColorValue("#212121"));
Set(colTextSecondary,ColorValue("#757575"));
```
