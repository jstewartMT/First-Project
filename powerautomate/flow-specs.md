# Power Automate Flow Specifications

## Connector Strategy

**Conservative DLP-safe approach:** Only standard connectors are used in the core flows.

| Connector | Tier | Usage | DLP Safe? |
|---|---|---|---|
| SQL Server | Standard | Read/write Azure SQL | Yes |
| Office 365 Outlook | Standard | Email notifications | Yes |
| Microsoft Teams | Standard | Channel/chat notifications | Yes |
| Approvals | Standard | Exception overrides | Yes |
| SharePoint | Standard | Audit log export | Yes (optional) |

**Not used in MVP (available as feature-flagged enhancements):**
| Connector | Tier | Why Excluded |
|---|---|---|
| AI Builder | Premium | DLP restricted in many tenants |
| HTTP | Premium/Blocked | Often blocked by DLP |
| Custom Connectors | Premium | Not needed for MVP |
| Dataverse | Premium | Using Azure SQL instead |

---

## Flow 1: Notify on High-Severity Exception

**Trigger:** Automated — SQL Server "When an item is modified"
**Alternative trigger:** Power Apps button → Run flow
**Purpose:** Send Teams notification when a high/critical exception is created or escalated.

### Flow Definition

```
Trigger: When an item is created (SQL Server)
  Table: dbo.Exceptions
  Condition: Severity IN ('High', 'Critical')

→ Action: Get matter details
  SQL: SELECT * FROM dbo.vw_MatterPostureBoard WHERE MatterId = @{triggerBody()?['MatterId']}

→ Condition: Is feature flag enabled?
  SQL: SELECT IsEnabled FROM dbo.FeatureFlags WHERE FlagName = 'AUTO_NOTIFY_TEAMS'

  → Yes branch:
    → Action: Post adaptive card to Teams channel
      Channel: "Finance Ops — Exceptions"
      Card body:
        {
          "type": "AdaptiveCard",
          "body": [
            {
              "type": "TextBlock",
              "text": "⚠ New @{triggerBody()?['Severity']} Exception",
              "weight": "bolder",
              "size": "medium"
            },
            {
              "type": "FactSet",
              "facts": [
                {"title": "Matter", "value": "@{body('GetMatter')?['MatterNumber']} — @{body('GetMatter')?['MatterName']}"},
                {"title": "Client", "value": "@{body('GetMatter')?['ClientName']}"},
                {"title": "Exception", "value": "@{triggerBody()?['Summary']}"},
                {"title": "Severity", "value": "@{triggerBody()?['Severity']}"},
                {"title": "Owner Role", "value": "@{triggerBody()?['OwnerRole']}"}
              ]
            }
          ],
          "actions": [
            {
              "type": "Action.OpenUrl",
              "title": "Open in MRBRO",
              "url": "https://apps.powerapps.com/play/<app-id>?MatterId=@{triggerBody()?['MatterId']}"
            }
          ],
          "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
          "version": "1.4"
        }

  → No branch: (do nothing — feature flag disabled)

→ Action: Log notification event
  SQL: INSERT INTO dbo.AuditEntries (MatterId, ExceptionId, Action, EntityType, Rationale)
       VALUES (@MatterId, @ExceptionId, 'Notification sent', 'Exception', 'Teams notification for high-severity exception')
```

### Fallback if Teams connector is restricted

Replace with Office 365 Outlook → Send an email:
- To: role-based distribution list (e.g., `finops-exceptions@lawfirm.com`)
- Subject: `[MRBRO] @{Severity} Exception: @{Summary}`
- Body: HTML table with matter details

---

## Flow 2: Daily Exception Digest

**Trigger:** Recurrence — Daily at 8:00 AM
**Purpose:** Send a daily summary of open exceptions to the Finance Ops team.

### Flow Definition

```
Trigger: Recurrence
  Frequency: Day
  At: 08:00

→ Action: Get open exception counts
  SQL: SELECT Severity, COUNT(*) AS Cnt
       FROM dbo.Exceptions
       WHERE Status NOT IN ('Resolved','Closed','Overridden')
       GROUP BY Severity

→ Action: Get overdue exceptions
  SQL: SELECT TOP 10 e.Summary, m.MatterNumber, e.Severity, e.DueDate
       FROM dbo.Exceptions e
       JOIN dbo.Matters m ON m.MatterId = e.MatterId
       WHERE e.Status NOT IN ('Resolved','Closed','Overridden')
         AND e.DueDate < CAST(GETUTCDATE() AS DATE)
       ORDER BY e.Severity, e.DueDate

→ Action: Get escalation-required matters
  SQL: SELECT MatterNumber, MatterName, ClientName, OpenExceptionCount
       FROM dbo.Matters
       WHERE OverallPosture = 'ESCALATION_REQUIRED' AND IsActive = 1

→ Condition: Any overdue or escalation matters?

  → Yes:
    → Action: Post to Teams channel
      Channel: "Finance Ops — Daily Digest"
      Message type: Adaptive Card with:
        - Exception count by severity
        - Overdue exception list
        - Escalation-required matters
        - Link to MRBRO app

    → (Optional) Action: Send email digest
      To: finops-team@lawfirm.com
      Subject: "[MRBRO] Daily Exception Digest — @{utcNow('yyyy-MM-dd')}"

  → No: (skip — no digest needed if all clear)
```

---

## Flow 3: Exception Escalation Timer

**Trigger:** Recurrence — Every 4 hours
**Purpose:** Auto-escalate exceptions that have exceeded their due date.

### Flow Definition

```
Trigger: Recurrence
  Frequency: Hour
  Interval: 4

→ Action: Find overdue non-escalated exceptions
  SQL: SELECT ExceptionId, MatterId, Severity, Summary
       FROM dbo.Exceptions
       WHERE Status NOT IN ('Resolved','Closed','Overridden','Escalated')
         AND DueDate IS NOT NULL
         AND DueDate < CAST(GETUTCDATE() AS DATE)

→ Apply to each (overdue exception):

  → Action: Escalate severity
    SQL: UPDATE dbo.Exceptions
         SET Severity = CASE
               WHEN Severity = 'Low' THEN 'Medium'
               WHEN Severity = 'Medium' THEN 'High'
               WHEN Severity = 'High' THEN 'Critical'
               ELSE Severity
             END,
             Status = CASE WHEN Severity IN ('High','Critical') THEN 'Escalated' ELSE Status END,
             UpdatedAt = SYSUTCDATETIME()
         WHERE ExceptionId = @{items('Apply_to_each')?['ExceptionId']}

  → Action: Log audit entry
    SQL: INSERT INTO dbo.AuditEntries (MatterId, ExceptionId, Action, EntityType, EntityId, Rationale)
         VALUES (@MatterId, @ExceptionId, 'Auto-escalated (overdue)', 'Exception', @ExceptionId,
                 'Exception past due date — severity auto-escalated')

  → Action: Recalculate posture
    SQL: EXEC dbo.sp_CalculateOverallPosture @MatterId = @{items('Apply_to_each')?['MatterId']}
```

---

## Flow 4: Exception Override Approval (Optional)

**Trigger:** Power Apps button (manual trigger from Override button)
**Purpose:** Require approval for overrides on Critical exceptions.

### Flow Definition

```
Trigger: Power Apps (V2) — manual trigger
  Inputs:
    - ExceptionId (number)
    - OverrideReason (text)
    - RequestedBy (text — email)

→ Action: Get exception details
  SQL: SELECT * FROM dbo.vw_ExceptionWorkbench WHERE ExceptionId = @ExceptionId

→ Condition: Is severity Critical?

  → Yes:
    → Action: Start and wait for an approval
      Type: Approve/Reject — First to respond
      Title: "Override Critical Exception: @{Summary}"
      Assigned to: Finance Ops manager email
      Details: "Requested by: @{RequestedBy}\nMatter: @{MatterNumber}\nReason: @{OverrideReason}"

    → Condition: Approved?
      → Yes:
        → SQL: EXEC dbo.sp_OverrideException @ExceptionId, @OverrideReason, @UserId
        → Respond to Power Apps: {"approved": true}
      → No:
        → SQL: INSERT INTO AuditEntries (... Action='Override rejected' ...)
        → Respond to Power Apps: {"approved": false, "reason": "Rejected by approver"}

  → No (non-critical):
    → SQL: EXEC dbo.sp_OverrideException @ExceptionId, @OverrideReason, @UserId
    → Respond to Power Apps: {"approved": true}
```

---

## Flow 5: Audit Trail Export (Scheduled)

**Trigger:** Recurrence — Weekly (Sunday 2:00 AM)
**Purpose:** Export audit trail to SharePoint for long-term retention.

```
Trigger: Recurrence — Weekly

→ Action: Get audit entries from past week
  SQL: SELECT * FROM dbo.vw_MatterAuditTrail
       WHERE PerformedAt >= DATEADD(DAY, -7, SYSUTCDATETIME())
       ORDER BY PerformedAt

→ Action: Create CSV content
  Use Select action to format rows → Join with newlines

→ Action: Create file (SharePoint)
  Site: Finance Ops site
  Folder: /Shared Documents/MRBRO/AuditExports
  File name: MRBRO-Audit-@{utcNow('yyyy-MM-dd')}.csv
  Content: @{body('Create_CSV')}
```

---

## DLP Safety Notes

1. **All SQL calls use parameterized patterns** — no dynamic SQL construction in Power Automate expressions. The SQL is built as static templates with expression placeholders.

2. **No HTTP connector required** — all data access goes through the SQL Server connector directly. No external APIs called.

3. **Teams and Outlook connectors are interchangeable** — if one is blocked, the other can substitute. Both are standard tier.

4. **Approvals connector** is standard tier and generally DLP-safe, but mark Flow 4 as optional if the Approvals connector is restricted.

5. **Feature flags control behavior** — even if a flow is deployed, the feature flag check ensures notifications only fire when the admin enables them. This provides a kill switch without redeploying flows.

6. **No AI Builder, no Copilot actions, no custom connectors** in any of these flows. Everything runs on standard, universally-available connectors.
