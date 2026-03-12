-- ============================================================================
-- MRBRO — Views for Posture Board, Exception Workbench, Leadership Dashboard
-- ============================================================================

-- ============================================================================
-- VIEW: Matter Posture Board
-- Used by: Power Apps "Posture Board" screen, Power BI
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_MatterPostureBoard AS
SELECT
    m.MatterId,
    m.MatterNumber,
    m.MatterName,
    m.ClientName,
    m.ResponsibleLawyer,
    m.PracticeGroup,
    m.Office,
    m.MatterOpenDate,

    -- Individual readiness dimensions (pivoted)
    rd_com.StatusCode       AS CommercialStatusCode,
    rs_com.StatusLabel      AS CommercialStatus,
    rd_com.RiskLevel        AS CommercialRisk,

    rd_gui.StatusCode       AS GuidelineStatusCode,
    rs_gui.StatusLabel      AS GuidelineStatus,
    rd_gui.RiskLevel        AS GuidelineRisk,

    rd_rat.StatusCode       AS RateStatusCode,
    rs_rat.StatusLabel      AS RateStatus,
    rd_rat.RiskLevel        AS RateRisk,

    rd_sta.StatusCode       AS StaffingStatusCode,
    rs_sta.StatusLabel      AS StaffingStatus,
    rd_sta.RiskLevel        AS StaffingRisk,

    rd_ebi.StatusCode       AS EBillingStatusCode,
    rs_ebi.StatusLabel      AS EBillingStatus,
    rd_ebi.RiskLevel        AS EBillingRisk,

    -- Overall posture
    m.OverallPosture        AS PostureCode,
    p.PostureLabel,
    p.Severity              AS PostureSeverity,
    p.ColorHex              AS PostureColor,
    m.PostureRationale,

    -- Exception summary
    m.OpenExceptionCount,

    -- Timestamps
    m.UpdatedAt             AS LastUpdated

FROM dbo.Matters m
    INNER JOIN dbo.LookupPosture p ON p.PostureCode = m.OverallPosture
    LEFT JOIN dbo.ReadinessDimensions rd_com ON rd_com.MatterId = m.MatterId AND rd_com.DimensionCode = 'COMMERCIAL'
    LEFT JOIN dbo.LookupReadinessStatus rs_com ON rs_com.DimensionCode = rd_com.DimensionCode AND rs_com.StatusCode = rd_com.StatusCode
    LEFT JOIN dbo.ReadinessDimensions rd_gui ON rd_gui.MatterId = m.MatterId AND rd_gui.DimensionCode = 'GUIDELINE'
    LEFT JOIN dbo.LookupReadinessStatus rs_gui ON rs_gui.DimensionCode = rd_gui.DimensionCode AND rs_gui.StatusCode = rd_gui.StatusCode
    LEFT JOIN dbo.ReadinessDimensions rd_rat ON rd_rat.MatterId = m.MatterId AND rd_rat.DimensionCode = 'RATE'
    LEFT JOIN dbo.LookupReadinessStatus rs_rat ON rs_rat.DimensionCode = rd_rat.DimensionCode AND rs_rat.StatusCode = rd_rat.StatusCode
    LEFT JOIN dbo.ReadinessDimensions rd_sta ON rd_sta.MatterId = m.MatterId AND rd_sta.DimensionCode = 'STAFFING'
    LEFT JOIN dbo.LookupReadinessStatus rs_sta ON rs_sta.DimensionCode = rd_sta.DimensionCode AND rs_sta.StatusCode = rd_sta.StatusCode
    LEFT JOIN dbo.ReadinessDimensions rd_ebi ON rd_ebi.MatterId = m.MatterId AND rd_ebi.DimensionCode = 'EBILLING'
    LEFT JOIN dbo.LookupReadinessStatus rs_ebi ON rs_ebi.DimensionCode = rd_ebi.DimensionCode AND rs_ebi.StatusCode = rd_ebi.StatusCode
WHERE m.IsActive = 1;
GO

-- ============================================================================
-- VIEW: Exception Workbench
-- Used by: Power Apps "Exception Workbench" screen
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_ExceptionWorkbench AS
SELECT
    e.ExceptionId,
    e.MatterId,
    m.MatterNumber,
    m.MatterName,
    m.ClientName,
    et.ExceptionTypeLabel   AS ExceptionType,
    e.ExceptionTypeCode,
    ld.DimensionName,
    e.Severity,
    CASE e.Severity
        WHEN 'Critical'  THEN 1
        WHEN 'High'      THEN 2
        WHEN 'Medium'    THEN 3
        WHEN 'Low'       THEN 4
    END                     AS SeveritySort,
    es.StatusLabel          AS ExceptionStatus,
    e.Status                AS StatusCode,
    e.OwnerRole,
    lr.RoleLabel            AS OwnerRoleLabel,
    e.OwnerUserId,
    u.DisplayName           AS OwnerName,
    e.Summary,
    e.Detail,
    e.DueDate,
    e.IsOverridden,
    e.OverrideReason,
    e.CreatedAt,
    e.UpdatedAt,
    e.ResolvedAt,
    -- Aging
    DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) AS AgeDays,
    CASE
        WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 3  THEN '0-3 days'
        WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 7  THEN '4-7 days'
        WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 14 THEN '8-14 days'
        ELSE '15+ days'
    END                     AS AgingBucket,
    -- Is overdue?
    CASE WHEN e.DueDate IS NOT NULL AND e.DueDate < CAST(SYSUTCDATETIME() AS DATE)
         AND e.Status NOT IN ('Resolved','Closed','Overridden')
         THEN 1 ELSE 0
    END                     AS IsOverdue
FROM dbo.Exceptions e
    INNER JOIN dbo.Matters m ON m.MatterId = e.MatterId
    INNER JOIN dbo.LookupExceptionType et ON et.ExceptionTypeCode = e.ExceptionTypeCode
    INNER JOIN dbo.LookupExceptionStatus es ON es.StatusCode = e.Status
    LEFT JOIN dbo.LookupReadinessDimension ld ON ld.DimensionCode = e.DimensionCode
    LEFT JOIN dbo.LookupRole lr ON lr.RoleCode = e.OwnerRole
    LEFT JOIN dbo.Users u ON u.UserId = e.OwnerUserId;
GO

-- ============================================================================
-- VIEW: Leadership Dashboard — Matters by Posture
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_DashboardPostureSummary AS
SELECT
    p.PostureCode,
    p.PostureLabel,
    p.Severity,
    p.ColorHex,
    COUNT(m.MatterId) AS MatterCount
FROM dbo.LookupPosture p
    LEFT JOIN dbo.Matters m ON m.OverallPosture = p.PostureCode AND m.IsActive = 1
GROUP BY p.PostureCode, p.PostureLabel, p.Severity, p.ColorHex;
GO

-- ============================================================================
-- VIEW: Leadership Dashboard — Exceptions by Type
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_DashboardExceptionsByType AS
SELECT
    et.ExceptionTypeCode,
    et.ExceptionTypeLabel,
    e.Severity,
    COUNT(*)            AS ExceptionCount
FROM dbo.Exceptions e
    INNER JOIN dbo.LookupExceptionType et ON et.ExceptionTypeCode = e.ExceptionTypeCode
WHERE e.Status NOT IN ('Resolved','Closed')
GROUP BY et.ExceptionTypeCode, et.ExceptionTypeLabel, e.Severity;
GO

-- ============================================================================
-- VIEW: Leadership Dashboard — Exceptions by Aging Bucket
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_DashboardExceptionsByAge AS
SELECT
    AgingBucket,
    Severity,
    COUNT(*) AS ExceptionCount
FROM (
    SELECT
        e.Severity,
        CASE
            WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 3  THEN '0-3 days'
            WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 7  THEN '4-7 days'
            WHEN DATEDIFF(DAY, e.CreatedAt, SYSUTCDATETIME()) <= 14 THEN '8-14 days'
            ELSE '15+ days'
        END AS AgingBucket
    FROM dbo.Exceptions e
    WHERE e.Status NOT IN ('Resolved','Closed')
) sub
GROUP BY AgingBucket, Severity;
GO

-- ============================================================================
-- VIEW: Leadership Dashboard — Top Blocker Categories
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_DashboardTopBlockers AS
SELECT TOP 10
    et.ExceptionTypeLabel   AS BlockerCategory,
    COUNT(*)                AS OccurrenceCount,
    COUNT(DISTINCT e.MatterId) AS AffectedMatters
FROM dbo.Exceptions e
    INNER JOIN dbo.LookupExceptionType et ON et.ExceptionTypeCode = e.ExceptionTypeCode
WHERE e.Status NOT IN ('Resolved','Closed')
    AND e.Severity IN ('High','Critical')
GROUP BY et.ExceptionTypeLabel
ORDER BY OccurrenceCount DESC;
GO

-- ============================================================================
-- VIEW: Leadership Dashboard — Overridden Matters
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_DashboardOverriddenMatters AS
SELECT
    COUNT(DISTINCT e.MatterId) AS OverriddenMatterCount
FROM dbo.Exceptions e
WHERE e.IsOverridden = 1
    AND e.Status = 'Overridden';
GO

-- ============================================================================
-- VIEW: Matter Event History (for detail screen audit trail)
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_MatterEventHistory AS
SELECT
    evt.EventId,
    evt.MatterId,
    m.MatterNumber,
    et.EventTypeLabel,
    evt.EventTypeCode,
    evt.EventData,
    evt.EventSource,
    evt.CreatedAt   AS EventTimestamp,
    u.DisplayName   AS TriggeredBy
FROM dbo.Events evt
    INNER JOIN dbo.Matters m ON m.MatterId = evt.MatterId
    INNER JOIN dbo.LookupEventType et ON et.EventTypeCode = evt.EventTypeCode
    LEFT JOIN dbo.Users u ON u.UserId = evt.CreatedBy;
GO

-- ============================================================================
-- VIEW: Matter Audit Trail (for detail screen)
-- ============================================================================

CREATE OR ALTER VIEW dbo.vw_MatterAuditTrail AS
SELECT
    a.AuditId,
    a.MatterId,
    m.MatterNumber,
    a.Action,
    a.EntityType,
    a.EntityId,
    a.OldValue,
    a.NewValue,
    a.Rationale,
    a.PerformedAt,
    u.DisplayName AS PerformedByName
FROM dbo.AuditEntries a
    INNER JOIN dbo.Matters m ON m.MatterId = a.MatterId
    LEFT JOIN dbo.Users u ON u.UserId = a.PerformedBy;
GO
