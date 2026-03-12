# MRBRO Build & Deployment Guide

## Prerequisites

| Component | Requirement | Notes |
|---|---|---|
| Azure SQL Database | Standard S2 or higher | ~$75/mo for dev/test |
| Power Platform environment | With SQL Server connector enabled | Check DLP policies first |
| Power Apps license | Per-user or per-app | Canvas app |
| Power Automate license | Included with Power Apps per-user or standalone | For scheduled flows |
| Power BI Pro or Premium Per User | For dashboard | $10-20/user/mo |
| Microsoft Fabric | Optional for MVP | Required for Phase 2+ analytics |
| Entra ID | Security groups for RBAC | Create groups listed below |

## Step 1: Azure SQL Database Setup

### 1.1 Create Database

```bash
# Azure CLI
az sql server create \
  --name mrbro-sql \
  --resource-group rg-mrbro \
  --location eastus \
  --admin-user mrbro-admin \
  --admin-password <strong-password>

az sql db create \
  --resource-group rg-mrbro \
  --server mrbro-sql \
  --name MRBRO \
  --service-objective S2

# Enable Entra auth
az sql server ad-admin create \
  --resource-group rg-mrbro \
  --server-name mrbro-sql \
  --display-name "MRBRO Admin" \
  --object-id <entra-group-object-id>
```

### 1.2 Configure Firewall

```bash
# Allow Azure services
az sql server firewall-rule create \
  --resource-group rg-mrbro \
  --server mrbro-sql \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 1.3 Deploy Schema and Seed Data

Run the SQL scripts in order:

```bash
# Using sqlcmd
sqlcmd -S mrbro-sql.database.windows.net -d MRBRO -G -U admin@lawfirm.com \
  -i sql/001_schema.sql

sqlcmd -S mrbro-sql.database.windows.net -d MRBRO -G -U admin@lawfirm.com \
  -i sql/002_seed_data.sql

sqlcmd -S mrbro-sql.database.windows.net -d MRBRO -G -U admin@lawfirm.com \
  -i sql/003_views.sql

sqlcmd -S mrbro-sql.database.windows.net -d MRBRO -G -U admin@lawfirm.com \
  -i sql/004_rules_engine.sql
```

Or use Azure Data Studio / SSMS to run each script manually.

### 1.4 Verify Deployment

```sql
-- Check tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Check views
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS;

-- Check seed data
SELECT COUNT(*) AS MatterCount FROM dbo.Matters;              -- Should be 10
SELECT COUNT(*) AS ExceptionCount FROM dbo.Exceptions;        -- Should be 14
SELECT COUNT(*) AS EventCount FROM dbo.Events;                -- Should be 15

-- Test posture board view
SELECT * FROM dbo.vw_MatterPostureBoard;

-- Test rules engine
DECLARE @EventId INT;
INSERT INTO dbo.Events (MatterId, EventTypeCode, EventData, EventSource, CreatedBy)
VALUES (6, 'ENGAGEMENT_BASIS_UPDATED', '{"basis":"master_agreement"}', 'Manual', 1);
SET @EventId = SCOPE_IDENTITY();
EXEC dbo.sp_ProcessEvent @EventId, 1;
SELECT OverallPosture, PostureRationale FROM dbo.Matters WHERE MatterId = 6;
```

## Step 2: Entra ID Security Groups

Create the following groups in Entra ID:

| Group Name | Purpose |
|---|---|
| `MRBRO-Admin` | Full access, feature flags, user management |
| `MRBRO-FinanceOps` | Exception management, posture updates, event simulation |
| `MRBRO-Billing` | Guideline and eBilling exception management |
| `MRBRO-Rates` | Rate and staffing exception management |
| `MRBRO-Viewer` | Read-only access to posture board and dashboard |

## Step 3: Power Apps Canvas App

### 3.1 Create the App

1. Go to `make.powerapps.com`
2. Create → Canvas app → Tablet layout
3. Name: `MRBRO`

### 3.2 Add Data Source

1. Data → Add data → SQL Server
2. Server: `mrbro-sql.database.windows.net`
3. Database: `MRBRO`
4. Authentication: Azure AD
5. Select all tables and views listed in `powerapps/app-spec.md`

### 3.3 Build Screens

Follow the specifications in:
- `powerapps/app-spec.md` — app-level config, variables, theme
- `powerapps/screens.md` — screen-by-screen layout and controls
- `powerapps/powerfx-snippets.md` — reusable formulas

Build order:
1. Navigation component (shared header)
2. Posture Board screen (`scrPostureBoard`)
3. Matter Detail screen (`scrMatterDetail`)
4. Exception Workbench screen (`scrExceptionWorkbench`)
5. Event Simulator screen (`scrEventSimulator`)
6. Leadership Dashboard screen (`scrDashboard`)
7. Admin screen (`scrAdmin`)

### 3.4 Publish and Share

1. Save → Publish
2. Share with Entra security groups
3. Test with each role to verify visibility rules

## Step 4: Power Automate Flows

### 4.1 Check DLP Policies First

Before building flows, verify these connectors are allowed in your environment:
- SQL Server (standard)
- Office 365 Outlook (standard)
- Microsoft Teams (standard)
- Approvals (standard)
- SharePoint (standard)

### 4.2 Build Flows

Follow specs in `powerautomate/flow-specs.md`. Build in order:
1. Flow 1: Notify on High-Severity Exception
2. Flow 2: Daily Exception Digest
3. Flow 3: Exception Escalation Timer
4. Flow 5: Audit Trail Export

Flow 4 (Override Approval) is optional for MVP.

### 4.3 Configure Feature Flags

```sql
-- Enable Teams notifications
UPDATE dbo.FeatureFlags SET IsEnabled = 1 WHERE FlagName = 'AUTO_NOTIFY_TEAMS';

-- Enable email notifications (optional)
UPDATE dbo.FeatureFlags SET IsEnabled = 1 WHERE FlagName = 'AUTO_NOTIFY_EMAIL';
```

## Step 5: Power BI Dashboard

### 5.1 Create Report

1. Open Power BI Desktop
2. Get Data → Azure SQL Database
3. Server: `mrbro-sql.database.windows.net`
4. Database: `MRBRO`
5. Import the views listed in `fabric/reporting-spec.md`
6. Build the 4 report pages per spec

### 5.2 Publish

1. Publish to workspace: `MRBRO - Finance Ops`
2. Configure scheduled refresh (every 4 hours)
3. Share with Entra security groups

## Step 6: Smoke Test

Run through the demo script (`docs/demo-script.md`) end-to-end:
- [ ] Posture Board loads with 10 matters
- [ ] Color-coded readiness dots display correctly
- [ ] Filtering works (posture, office)
- [ ] Matter Detail shows all dimensions, exceptions, events, audit
- [ ] Exception Workbench shows 14 open exceptions
- [ ] Event Simulator can fire all 7 event types
- [ ] Events trigger correct readiness changes
- [ ] Exceptions are created by rules engine
- [ ] Posture recalculates after events
- [ ] Override requires a reason and logs to audit
- [ ] Leadership dashboard displays summary charts
- [ ] Power BI report loads with correct data

## Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| SQL connector fails in Power Apps | Firewall not allowing Power Platform IPs | Add Power Platform outbound IPs to SQL firewall |
| "Delegation warning" in Power Apps | Client-side filtering on large dataset | Ensure filtering happens via view, not in gallery formula |
| Stored procedure doesn't return results | Missing SET NOCOUNT ON | Already included in all SPs |
| Power Automate flow fails on SQL | Connection auth expired | Re-authenticate the SQL connection in the flow |
| Posture doesn't update after event | sp_ProcessEvent not called | Ensure event insert is followed by SP execution |
