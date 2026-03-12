# Screen-by-Screen Functional Specification

## Screen 1: Posture Board (`scrPostureBoard`)

**Purpose:** Portfolio-level view of all matters with their readiness posture.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ HEADER: [Filters ▼] [Search 🔍___________]  Showing 10 of 47       │
├──────────────────────────────────────────────────────────────────────┤
│ ┌─ Filter Bar ─────────────────────────────────────────────────────┐ │
│ │ Posture: [All ▼]  Office: [All ▼]  PG: [All ▼]  Risk: [All ▼] │ │
│ └──────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│ POSTURE SUMMARY CHIPS                                                │
│ [● Ready: 2] [● Monitored: 3] [● Exceptions: 2]                    │
│ [● Restricted: 2] [● Escalation: 1]                                 │
├───────┬────────┬──────┬───────┬───────┬───────┬───────┬─────┬──────┤
│Matter │Client  │Lawyer│Comm.  │Guide. │Rate   │Staff. │eBill│Post. │
├───────┼────────┼──────┼───────┼───────┼───────┼───────┼─────┼──────┤
│100001 │Acme    │Walsh │ 🟢   │ 🟢   │ 🟢   │ 🟢   │ 🟢 │READY │
│100002 │Global  │Torres│ 🟢   │ ⚪   │ 🟢   │ 🟢   │ 🟡 │MONIT │
│100004 │MegaCorp│Singh │ 🟡   │ 🟡   │ 🟡   │ 🟡   │ 🟡 │RESTR │
│100005 │Clearwtr│Park  │ 🔴   │ 🟡   │ 🔴   │ 🔴   │ 🔴 │ESCAL │
│ ...   │        │      │       │       │       │       │     │      │
└───────┴────────┴──────┴───────┴───────┴───────┴───────┴─────┴──────┘
│ Tap any row → Navigate to Matter Detail                              │
```

### Key Controls

| Control | Type | Name | Purpose |
|---|---|---|---|
| Search | TextInput | `txtSearch` | Filter by matter number, name, client |
| Posture Filter | Dropdown | `ddPostureFilter` | Filter by overall posture |
| Office Filter | Dropdown | `ddOfficeFilter` | Filter by office |
| Risk Filter | Dropdown | `ddRiskFilter` | Filter by any risk level present |
| Summary Chips | Gallery (horizontal) | `galPostureSummary` | Count of matters per posture |
| Main Grid | Gallery (vertical) | `galPostureBoard` | The matter listing |
| Risk Indicator | Circle/Icon | `icnRisk_[Dim]` | Colored dot per dimension |

### Power Fx — Data Source

```
// galPostureBoard.Items
SortByColumns(
    Filter(
        PostureBoard,
        // Search filter
        Or(
            IsBlank(txtSearch.Text),
            txtSearch.Text in MatterNumber,
            txtSearch.Text in MatterName,
            txtSearch.Text in ClientName,
            txtSearch.Text in ResponsibleLawyer
        ),
        // Posture filter
        Or(
            ddPostureFilter.Selected.Value = "All",
            PostureCode = ddPostureFilter.Selected.Value
        ),
        // Office filter
        Or(
            ddOfficeFilter.Selected.Value = "All",
            Office = ddOfficeFilter.Selected.Value
        )
    ),
    "PostureSeverity", SortOrder.Descending,
    "LastUpdated", SortOrder.Descending
)
```

### Power Fx — Risk Dot Color

```
// icnCommercialRisk.Fill
Switch(
    ThisItem.CommercialRisk,
    "Green",   colRiskGreen,
    "Amber",   colRiskAmber,
    "Red",     colRiskRed,
    "Unknown", colRiskUnknown,
    colRiskUnknown
)
```

### Power Fx — Posture Badge Color

```
// lblPosture.Fill
Switch(
    ThisItem.PostureCode,
    "READY",                colReady,
    "READY_MONITORED",      colMonitored,
    "READY_EXCEPTIONS",     colExceptions,
    "RESTRICTED",           colRestricted,
    "ESCALATION_REQUIRED",  colEscalation,
    Color.Gray
)
```

### Power Fx — Summary Chips

```
// galPostureSummary.Items
AddColumns(
    GroupBy(PostureBoard, "PostureCode", "PostureLabel", "PostureColor", "Grouped"),
    "Count", CountRows(Grouped)
)
```

### Power Fx — Row Selection / Navigation

```
// galPostureBoard.OnSelect
Set(varSelectedMatterId, ThisItem.MatterId);
Navigate(scrMatterDetail, ScreenTransition.None)
```

---

## Screen 2: Matter Detail (`scrMatterDetail`)

**Purpose:** Deep view of a single matter — readiness dimensions, exceptions, events, audit trail.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ [← Back]  Matter 100004-001: MegaCorp Antitrust Investigation       │
│ Client: MegaCorp Holdings | Lawyer: Robert Singh | Opened: 2026-02-20│
├──────────────────────────────────────────────────────────────────────┤
│ OVERALL POSTURE: [████ RESTRICTED ████]                              │
│ Rationale: 1 red dimensions, 2 high-severity exceptions             │
├──────────────────────────────────────────────────────────────────────┤
│ READINESS DIMENSIONS                                                 │
│ ┌─────────────┬───────────────────────────┬──────┬────────────────┐ │
│ │ Dimension    │ Status                    │ Risk │ [Update ▼]     │ │
│ ├─────────────┼───────────────────────────┼──────┼────────────────┤ │
│ │ Commercial   │ Commercial basis unclear  │ 🟡  │ [Change]       │ │
│ │ Guideline    │ OCG w/ restrictions       │ 🟡  │ [Change]       │ │
│ │ Rate         │ Special rates required    │ 🟡  │ [Change]       │ │
│ │ Staffing     │ TK approval required      │ 🟡  │ [Change]       │ │
│ │ eBilling     │ Setup pending             │ 🟡  │ [Change]       │ │
│ └─────────────┴───────────────────────────┴──────┴────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│ OPEN EXCEPTIONS (3)                                                  │
│ ┌──────┬──────────────────────────┬────────┬────────┬────────────┐  │
│ │ Sev. │ Summary                  │ Owner  │ Status │ Actions    │  │
│ ├──────┼──────────────────────────┼────────┼────────┼────────────┤  │
│ │ Med  │ Commercial basis unclear │ FinOps │ InProg │ [View]     │  │
│ │ High │ OCG material restrictions│ Billing│ Open   │ [Override] │  │
│ │ Med  │ TK not approved          │ Rates  │ Open   │ [View]     │  │
│ └──────┴──────────────────────────┴────────┴────────┴────────────┘  │
├──────────────────────────────────────────────────────────────────────┤
│ TABS: [Event History] [Audit Trail] [Documents]                      │
│ ┌──────────┬──────────────────────────────┬──────────────────────┐  │
│ │ Date     │ Action                        │ By                  │  │
│ │ 03/05    │ New timekeeper detected       │ System              │  │
│ │ 03/01    │ OCG processed w/ restrictions │ Lisa Thompson       │  │
│ │ 02/25    │ OCG received                  │ System              │  │
│ │ 02/20    │ Matter created                │ System              │  │
│ └──────────┴──────────────────────────────┴──────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Controls

| Control | Type | Name | Purpose |
|---|---|---|---|
| Back Button | Icon | `icnBack` | Return to posture board |
| Matter Header | Labels | `lblMatterNumber`, `lblClientName`, etc. | Matter summary |
| Posture Banner | Rectangle + Label | `recPostureBanner`, `lblPosture` | Colored posture display |
| Readiness Gallery | Gallery | `galReadinessDimensions` | 5-row readiness grid |
| Status Dropdown | Dropdown | `ddStatusUpdate` | Change readiness status |
| Exception Gallery | Gallery | `galMatterExceptions` | Open exceptions list |
| Tab Buttons | Buttons | `btnTabEvents`, `btnTabAudit`, `btnTabDocs` | Toggle bottom section |
| Event History | Gallery | `galEventHistory` | Chronological events |
| Audit Trail | Gallery | `galAuditTrail` | All audit entries |
| Override Button | Button | `btnOverride` | Override an exception |

### Power Fx — Load Matter Data

```
// scrMatterDetail.OnVisible
Set(varMatterDetail,
    LookUp(PostureBoard, MatterId = varSelectedMatterId)
);
ClearCollect(colReadiness,
    Filter(ReadinessDimensions, MatterId = varSelectedMatterId)
);
ClearCollect(colExceptions,
    SortByColumns(
        Filter(ExceptionWorkbench,
            MatterId = varSelectedMatterId,
            StatusCode <> "Resolved",
            StatusCode <> "Closed"
        ),
        "SeveritySort", SortOrder.Ascending
    )
);
ClearCollect(colEvents,
    SortByColumns(
        Filter(EventHistory, MatterId = varSelectedMatterId),
        "EventTimestamp", SortOrder.Descending
    )
);
ClearCollect(colAudit,
    SortByColumns(
        Filter(AuditTrail, MatterId = varSelectedMatterId),
        "PerformedAt", SortOrder.Descending
    )
);
```

### Power Fx — Update Readiness Status

```
// btnUpdateStatus.OnSelect (inside galReadinessDimensions)
// Calls stored procedure via SQL Server connector
'mrbro-sql'.ExecNonQuery(
    "EXEC dbo.sp_UpdateReadinessManual @MatterId=" & varSelectedMatterId
    & ", @DimensionCode='" & ThisItem.DimensionCode & "'"
    & ", @NewStatusCode='" & ddStatusUpdate.Selected.StatusCode & "'"
    & ", @Notes='" & txtStatusNotes.Text & "'"
    & ", @UserId=" & varCurrentUser.UserId
);
// Refresh data
ClearCollect(colReadiness,
    Filter(ReadinessDimensions, MatterId = varSelectedMatterId)
);
Set(varMatterDetail,
    LookUp(PostureBoard, MatterId = varSelectedMatterId)
);
Notify("Readiness updated", NotificationType.Success);
```

### Power Fx — Override Exception

```
// btnOverride.OnSelect
If(
    IsBlank(txtOverrideReason.Text),
    Notify("Override reason is required", NotificationType.Error),
    // Call override stored procedure
    'mrbro-sql'.ExecNonQuery(
        "EXEC dbo.sp_OverrideException @ExceptionId="
        & galMatterExceptions.Selected.ExceptionId
        & ", @OverrideReason='" & txtOverrideReason.Text & "'"
        & ", @UserId=" & varCurrentUser.UserId
    );
    // Refresh
    ClearCollect(colExceptions,
        Filter(ExceptionWorkbench, MatterId = varSelectedMatterId,
            StatusCode <> "Resolved", StatusCode <> "Closed")
    );
    Set(varMatterDetail,
        LookUp(PostureBoard, MatterId = varSelectedMatterId)
    );
    Reset(txtOverrideReason);
    Notify("Exception overridden — logged to audit trail", NotificationType.Success)
)
```

---

## Screen 3: Exception Workbench (`scrExceptionWorkbench`)

**Purpose:** Queue view for operations teams to manage exceptions across all matters.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ EXCEPTION WORKBENCH                                                  │
│ [My Role ▼: All] [Severity ▼: All] [Status ▼: Open] [Overdue: ☐]  │
├──────────────────────────────────────────────────────────────────────┤
│ SUMMARY: 14 open | 3 Critical | 5 High | 4 Medium | 2 Low          │
├───────┬──────────────────┬────────┬──────────┬───────┬──────┬──────┤
│ Sev.  │ Exception         │ Matter │ Owner    │Status │ Age  │ Due  │
├───────┼──────────────────┼────────┼──────────┼───────┼──────┼──────┤
│🔴 Crit│ Prebill blocker   │100005  │ FinOps   │Escal. │ 2d   │ 3/12 │
│🔴 Crit│ EL missing        │100005  │ FinOps   │Escal. │ 11d  │ 3/12 │
│🔴 Crit│ Time before rate  │100009  │ Rates    │Open   │ 3d   │ 3/13 │
│🟠 High│ OCG restrictions  │100004  │ Billing  │Open   │ 11d  │ 3/18 │
│🟠 High│ Rate mismatch     │100005  │ Rates    │Open   │ 4d   │  —   │
│ ...   │                   │        │          │       │      │      │
└───────┴──────────────────┴────────┴──────────┴───────┴──────┴──────┘
│ Tap row → Expand detail panel                                        │
│ [Assign to Me] [Resolve] [Override] [Escalate]                       │
```

### Key Controls

| Control | Type | Name | Purpose |
|---|---|---|---|
| Role Filter | Dropdown | `ddRoleFilter` | Filter by owner role (defaults to user's role) |
| Severity Filter | Dropdown | `ddSevFilter` | Filter by severity |
| Status Filter | Dropdown | `ddStatusFilter` | Filter by exception status |
| Overdue Toggle | Toggle | `togOverdue` | Show only overdue exceptions |
| Summary Labels | Labels | `lblTotalOpen`, `lblCriticalCount`, etc. | Summary counts |
| Exception Grid | Gallery | `galExceptions` | Main exception listing |
| Detail Panel | Container | `cntExceptionDetail` | Expanded exception info |
| Action Buttons | Buttons | `btnResolve`, `btnOverride`, `btnEscalate`, `btnAssign` | Actions |

### Power Fx — Filtered Exception List

```
// galExceptions.Items
SortByColumns(
    Filter(
        ExceptionWorkbench,
        // Role filter
        Or(
            ddRoleFilter.Selected.Value = "All",
            OwnerRole = ddRoleFilter.Selected.Value
        ),
        // Severity filter
        Or(
            ddSevFilter.Selected.Value = "All",
            Severity = ddSevFilter.Selected.Value
        ),
        // Status filter
        Or(
            ddStatusFilter.Selected.Value = "All",
            StatusCode = ddStatusFilter.Selected.Value
        ),
        // Overdue toggle
        Or(
            Not(togOverdue.Value),
            IsOverdue = 1
        )
    ),
    "SeveritySort", SortOrder.Ascending,
    "AgeDays", SortOrder.Descending
)
```

### Power Fx — Severity Icon Color

```
// icnSeverity.Fill
Switch(
    ThisItem.Severity,
    "Critical",  colRiskRed,
    "High",      ColorValue("#E65100"),
    "Medium",    colRiskAmber,
    "Low",       ColorValue("#2196F3"),
    Color.Gray
)
```

---

## Screen 4: Event Simulator (`scrEventSimulator`)

**Purpose:** Manual event injection for demo/testing when integrations are unavailable.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ EVENT SIMULATOR                                                      │
│ ⚠ This screen simulates events that will normally come from         │
│   integrations. Use it for testing and demo purposes.                │
├──────────────────────────────────────────────────────────────────────┤
│ Step 1: Select Matter                                                │
│ [Matter Dropdown ▼: 100004-001 MegaCorp Antitrust Investigation]    │
│                                                                      │
│ Step 2: Select Event Type                                            │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ [● Matter Created          ] [● OCG Received                  ] │ │
│ │ [● Engagement Basis Updated] [● OCG Processed w/ Restrictions ] │ │
│ │ [● New Timekeeper Detected ] [● Rate Approval Updated         ] │ │
│ │ [● Prebill Milestone       ]                                    │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ Step 3: Event Details (dynamic form based on event type)             │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ [Dynamic fields based on event type selection]                   │ │
│ │ e.g., for "Engagement Basis Updated":                           │ │
│ │   Basis: [Existing EL ▼]                                       │ │
│ │   EL Reference: [EL-2024-____]                                 │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ [🚀 Fire Event]                                                     │
│                                                                      │
│ RESULT: ✅ Event processed. Posture changed: RESTRICTED → READY     │
├──────────────────────────────────────────────────────────────────────┤
│ RECENT SIMULATED EVENTS                                              │
│ ┌──────────┬──────────────────────────┬──────────┬────────────────┐ │
│ │ Time     │ Event                    │ Matter   │ Result         │ │
│ │ 10:32    │ OCG Processed            │ 100004   │ Posture → RESTR│ │
│ │ 10:28    │ New TK Detected          │ 100004   │ Exception +1   │ │
│ └──────────┴──────────────────────────┴──────────┴────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Controls

| Control | Type | Name | Purpose |
|---|---|---|---|
| Matter Picker | Dropdown | `ddSimMatter` | Select target matter |
| Event Type | Gallery (wrap) | `galEventTypes` | Select event type |
| Dynamic Form | Container | `cntEventForm` | Context-dependent input fields |
| Fire Button | Button | `btnFireEvent` | Submit event |
| Result Label | Label | `lblSimResult` | Show processing result |
| Recent Events | Gallery | `galRecentSim` | Last 10 simulated events |

### Power Fx — Fire Event

```
// btnFireEvent.OnSelect

// Step 1: Build event JSON payload based on event type
Set(varEventPayload,
    Switch(
        galEventTypes.Selected.EventTypeCode,
        "ENGAGEMENT_BASIS_UPDATED",
            "{""basis"":""" & ddBasis.Selected.Value & """}",
        "OCG_RECEIVED",
            "{""client"":""" & varSimMatter.ClientName & """,""docRef"":""" & txtDocRef.Text & """}",
        "OCG_PROCESSED_RESTRICTIONS",
            "{""restrictions"":[""" & txtRestrictions.Text & """]}",
        "NEW_TK_DETECTED",
            "{""timekeepers"":[""" & txtTimekeepers.Text & """]}",
        "RATE_APPROVAL_UPDATED",
            "{""status"":""" & ddRateStatus.Selected.Value & """}",
        "PREBILL_MILESTONE",
            "{""period"":""" & txtPeriod.Text & """,""deadline"":""" & Text(dpDeadline.SelectedDate, "yyyy-mm-dd") & """}",
        "{}"
    )
);

// Step 2: Insert event
Patch(Events,
    Defaults(Events),
    {
        MatterId: ddSimMatter.Selected.MatterId,
        EventTypeCode: galEventTypes.Selected.EventTypeCode,
        EventData: varEventPayload,
        EventSource: "Simulator",
        IsProcessed: false,
        CreatedBy: varCurrentUser.UserId
    }
);

// Step 3: Get the new event ID and process it
Set(varNewEventId,
    LookUp(
        Events,
        MatterId = ddSimMatter.Selected.MatterId,
        EventId
    ).EventId
);

// Step 4: Process event via stored procedure
'mrbro-sql'.ExecNonQuery(
    "EXEC dbo.sp_ProcessEvent @EventId=" & varNewEventId
    & ", @UserId=" & varCurrentUser.UserId
);

// Step 5: Refresh and show result
Set(varMatterDetail,
    LookUp(PostureBoard, MatterId = ddSimMatter.Selected.MatterId)
);
Set(varSimResult,
    "✅ Event processed. Posture: " & varMatterDetail.PostureLabel
    & " | Open exceptions: " & varMatterDetail.OpenExceptionCount
);
Notify(varSimResult, NotificationType.Success);
```

---

## Screen 5: Leadership Dashboard (`scrDashboard`)

**Purpose:** Summary view for leadership — posture distribution, exception health, blockers.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ LEADERSHIP DASHBOARD                        As of: 2026-03-12 10:45 │
├──────────────────────────────────────────────────────────────────────┤
│ MATTERS BY POSTURE          │ ACTIVE EXCEPTIONS BY TYPE              │
│ ┌─────────────────────────┐ │ ┌────────────────────────────────────┐ │
│ │ ██████ Ready        2   │ │ │ ████ Rate Mismatch           3    │ │
│ │ █████ Monitored     3   │ │ │ ███ EL Required Missing      2    │ │
│ │ ████ Exceptions     2   │ │ │ ███ TK Not Approved          2    │ │
│ │ ███ Restricted      2   │ │ │ ██ OCG Restrictions          1    │ │
│ │ ██ Escalation       1   │ │ │ ██ Commercial Unclear        2    │ │
│ └─────────────────────────┘ │ └────────────────────────────────────┘ │
├──────────────────────────────┼──────────────────────────────────────┤
│ EXCEPTIONS BY AGE            │ TOP BLOCKERS                         │
│ ┌─────────────────────────┐ │ ┌────────────────────────────────────┐ │
│ │ 0-3 days    ████ 5     │ │ │ 1. Rate mismatch (3 matters)      │ │
│ │ 4-7 days    ███ 4      │ │ │ 2. Missing engagement letter (2)  │ │
│ │ 8-14 days   ██ 3       │ │ │ 3. TK not approved (2 matters)    │ │
│ │ 15+ days    █ 2        │ │ │ 4. OCG restrictions (1 matter)    │ │
│ └─────────────────────────┘ │ └────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│ OVERRIDDEN MATTERS: 0                                                │
│ [View Posture Board →]  [View Exception Workbench →]                │
└──────────────────────────────────────────────────────────────────────┘
```

### Power Fx — Dashboard Data

```
// scrDashboard.OnVisible
ClearCollect(colDashPosture,    DashPosture);
ClearCollect(colDashExcByType,  DashExcByType);
ClearCollect(colDashExcByAge,   DashExcByAge);
```

### Implementation Note

Power Apps Canvas charts are limited. For the MVP dashboard within Power Apps, use:
- **Horizontal bar charts** via the built-in `BarChart` control (limited but functional)
- **Colored rectangles with dynamic width** as a more reliable alternative to chart controls
- For the "Top Blockers" section, a simple gallery with ranked items

The **real leadership dashboard** should live in Power BI (see `/fabric/reporting-spec.md`). The Power Apps version is a lightweight summary for users who don't leave the app.

---

## Screen 6: Settings / Admin (`scrAdmin`)

**Purpose:** Admin-only screen for managing users, feature flags, and role assignments.

### Visibility Rule

```
// scrAdmin.Visible
varIsAdmin
```

### Capabilities

- View/edit user role assignments
- Toggle feature flags
- View system health (exception counts, event processing queue)
- Export audit trail (via Power Automate trigger)
