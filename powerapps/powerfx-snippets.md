# Power Fx Snippets Reference

Reusable formulas for the MRBRO Canvas App. Organized by concern.

## 1. Risk Level Color Function (reusable component)

```
// Use this in any control that shows risk level
// Parameter: riskLevel (Text)
Switch(
    riskLevel,
    "Green",   RGBA(76, 175, 80, 1),
    "Amber",   RGBA(255, 152, 0, 1),
    "Red",     RGBA(244, 67, 54, 1),
    "Unknown", RGBA(158, 158, 158, 1),
    RGBA(158, 158, 158, 1)
)
```

## 2. Posture Color Function

```
Switch(
    postureCode,
    "READY",                RGBA(46, 125, 50, 1),
    "READY_MONITORED",      RGBA(85, 139, 47, 1),
    "READY_EXCEPTIONS",     RGBA(249, 168, 37, 1),
    "RESTRICTED",           RGBA(230, 81, 0, 1),
    "ESCALATION_REQUIRED",  RGBA(183, 28, 28, 1),
    RGBA(117, 117, 117, 1)
)
```

## 3. Severity Badge

```
// For exception severity display
Switch(
    ThisItem.Severity,
    "Critical",  {Fill: RGBA(183, 28, 28, 1),  Text: "CRIT", TextColor: Color.White},
    "High",      {Fill: RGBA(230, 81, 0, 1),   Text: "HIGH", TextColor: Color.White},
    "Medium",    {Fill: RGBA(255, 152, 0, 1),   Text: "MED",  TextColor: Color.Black},
    "Low",       {Fill: RGBA(33, 150, 243, 1),  Text: "LOW",  TextColor: Color.White},
    {Fill: Color.Gray, Text: "???", TextColor: Color.White}
)
```

## 4. Role-Based Visibility

```
// Show edit controls only for authorized roles
varCanEdit

// Show admin controls only
varIsAdmin

// Show content relevant to user's team
varUserRole = "Billing" Or varUserRole = "Admin"

// Exception action buttons — role-based
// Resolve: only if owner role matches user role or Admin
btnResolve.Visible =
    varIsAdmin Or
    ThisItem.OwnerRole = varUserRole

// Override: Admin or FinanceOps only
btnOverride.Visible =
    varIsAdmin Or varUserRole = "FinanceOps"
```

## 5. Formatted Age Display

```
// Display exception age in human-readable format
If(
    ThisItem.AgeDays = 0, "Today",
    ThisItem.AgeDays = 1, "1 day",
    ThisItem.AgeDays < 7,  Text(ThisItem.AgeDays) & " days",
    ThisItem.AgeDays < 14, "1 week",
    ThisItem.AgeDays < 30, Text(RoundDown(ThisItem.AgeDays / 7, 0)) & " weeks",
    Text(RoundDown(ThisItem.AgeDays / 30, 0)) & " months"
)
```

## 6. Overdue Indicator

```
// Red text and icon for overdue exceptions
lblDueDate.Color =
    If(
        ThisItem.IsOverdue = 1,
        RGBA(183, 28, 28, 1),
        RGBA(33, 33, 33, 1)
    )

icnOverdue.Visible = ThisItem.IsOverdue = 1
```

## 7. Readiness Status Dropdown (context-sensitive)

```
// ddStatusUpdate.Items — filter statuses to only show valid options for the dimension
Filter(
    LookupReadinessStatus,
    DimensionCode = ThisItem.DimensionCode
)
```

## 8. Event Simulator — Dynamic Form Visibility

```
// Show/hide form sections based on selected event type
cntBasisFields.Visible =
    galEventTypes.Selected.EventTypeCode = "ENGAGEMENT_BASIS_UPDATED"

cntOCGFields.Visible =
    galEventTypes.Selected.EventTypeCode in ["OCG_RECEIVED", "OCG_PROCESSED_RESTRICTIONS"]

cntTimekeeperFields.Visible =
    galEventTypes.Selected.EventTypeCode = "NEW_TK_DETECTED"

cntRateFields.Visible =
    galEventTypes.Selected.EventTypeCode = "RATE_APPROVAL_UPDATED"

cntPrebillFields.Visible =
    galEventTypes.Selected.EventTypeCode = "PREBILL_MILESTONE"
```

## 9. Concurrent User Handling

```
// OnVisible — always refresh from server, never rely on stale cache
// This pattern applies to any screen that loads data:
ClearCollect(colScreenData, <SQLView>);

// After any write operation, immediately re-query:
Patch(...);
ClearCollect(colScreenData, <SQLView>);  // re-fetch from server
```

## 10. Error Handling Pattern

```
// Wrap SP calls with error handling
Set(varError, "");
IfError(
    'mrbro-sql'.ExecNonQuery("EXEC dbo.sp_ProcessEvent ..."),
    Set(varError, "Failed to process event. Please try again.");
    Notify(varError, NotificationType.Error),
    Notify("Event processed successfully", NotificationType.Success)
);
```

## 11. Loading Indicator Pattern

```
// Before data load
UpdateContext({locIsLoading: true});

// After data load
ClearCollect(colData, SQLView);
UpdateContext({locIsLoading: false});

// Spinner visibility
spinLoading.Visible = locIsLoading
galMainContent.Visible = Not(locIsLoading)
```

## 12. Stored Procedure Call Pattern (SQL Server Connector)

```
// Pattern for calling stored procedures through the SQL Server connector.
// The SQL Server connector's ExecNonQuery action runs arbitrary SQL.

// Simple call:
'mrbro-sql'.ExecNonQuery(
    "EXEC dbo.sp_ProcessEvent @EventId=" & varEventId & ", @UserId=" & varCurrentUser.UserId
)

// Call with string parameters (use double-tick escaping for single quotes):
'mrbro-sql'.ExecNonQuery(
    "EXEC dbo.sp_UpdateReadinessManual"
    & " @MatterId=" & varMatterId
    & ", @DimensionCode='" & varDimCode & "'"
    & ", @NewStatusCode='" & varStatusCode & "'"
    & ", @Notes='" & Substitute(txtNotes.Text, "'", "''") & "'"
    & ", @UserId=" & varCurrentUser.UserId
)
```
