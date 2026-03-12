# Notification Patterns

## Notification Matrix

| Event | Severity Threshold | Channel | Recipient | Timing |
|---|---|---|---|---|
| Exception created | High, Critical | Teams + Email | Owner role team | Real-time |
| Exception created | Medium, Low | Teams only | Owner role team | Batched (daily digest) |
| Exception escalated | Any → Critical | Teams + Email | FinOps manager | Real-time |
| Exception overdue | Any | Teams | Owner role team | Every 4 hours |
| Posture → Escalation Required | N/A | Teams + Email | FinOps manager + responsible lawyer | Real-time |
| Override requested (Critical) | Critical | Approval flow | FinOps manager | Real-time |
| Daily digest | N/A | Teams + Email | FinOps team | Daily 8 AM |

## Teams Channel Structure

| Channel | Purpose | Members |
|---|---|---|
| Finance Ops — Exceptions | Real-time exception alerts | All FinOps, Billing, Rates |
| Finance Ops — Daily Digest | Daily summary | All FinOps + leadership |
| Finance Ops — Escalations | Critical/escalation alerts | FinOps managers + leadership |

## Adaptive Card Template — Exception Alert

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "Container",
      "style": "attention",
      "items": [
        {
          "type": "TextBlock",
          "text": "${severity} Exception — ${exceptionType}",
          "weight": "bolder",
          "size": "medium",
          "color": "attention"
        }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        {"title": "Matter", "value": "${matterNumber} — ${matterName}"},
        {"title": "Client", "value": "${clientName}"},
        {"title": "Summary", "value": "${summary}"},
        {"title": "Owner", "value": "${ownerRole}"},
        {"title": "Due", "value": "${dueDate}"},
        {"title": "Current Posture", "value": "${postureLabel}"}
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.OpenUrl",
      "title": "Open Matter in MRBRO",
      "url": "${appUrl}?MatterId=${matterId}"
    }
  ]
}
```

## Email Template — Escalation Alert

**Subject:** `[MRBRO] ESCALATION: ${matterNumber} — ${clientName}`

**Body:**

```html
<h2 style="color: #B71C1C;">Escalation Required</h2>
<table style="border-collapse: collapse; width: 100%;">
  <tr><td style="padding: 8px; font-weight: bold;">Matter:</td>
      <td style="padding: 8px;">${matterNumber} — ${matterName}</td></tr>
  <tr><td style="padding: 8px; font-weight: bold;">Client:</td>
      <td style="padding: 8px;">${clientName}</td></tr>
  <tr><td style="padding: 8px; font-weight: bold;">Responsible Lawyer:</td>
      <td style="padding: 8px;">${responsibleLawyer}</td></tr>
  <tr><td style="padding: 8px; font-weight: bold;">Posture:</td>
      <td style="padding: 8px; color: #B71C1C;">Escalation Required</td></tr>
  <tr><td style="padding: 8px; font-weight: bold;">Open Exceptions:</td>
      <td style="padding: 8px;">${openExceptionCount}</td></tr>
  <tr><td style="padding: 8px; font-weight: bold;">Critical Exceptions:</td>
      <td style="padding: 8px;">${criticalCount}</td></tr>
</table>
<p><a href="${appUrl}?MatterId=${matterId}">Open in MRBRO →</a></p>
```

## Fallback Hierarchy

If a notification channel is unavailable:

1. **Teams** → fall back to **Email**
2. **Email** → fall back to **SharePoint list item** (create an alert record)
3. **SharePoint** → fall back to **SQL audit entry** (always available)

The flows should check feature flags before sending:
```
// Pseudo-logic in each notification flow
IF FeatureFlag('AUTO_NOTIFY_TEAMS') = true → Send Teams
ELSE IF FeatureFlag('AUTO_NOTIFY_EMAIL') = true → Send Email
ELSE → Log to AuditEntries with Action = 'Notification suppressed (all channels disabled)'
```
