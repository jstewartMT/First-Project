-- ============================================================================
-- MRBRO — Rules Engine: Stored Procedures
-- ============================================================================
-- Design: All business rules live here in explicit, auditable SQL.
-- No AI, no opaque logic. Every rule is a named, readable conditional.
-- ============================================================================

-- ============================================================================
-- PROCEDURE: Process an event and run rule evaluation
-- This is the main entry point called from Power Apps after event insertion.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_ProcessEvent
    @EventId    INT,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @MatterId       INT;
        DECLARE @EventTypeCode  VARCHAR(50);
        DECLARE @EventData      NVARCHAR(MAX);

        SELECT @MatterId = MatterId,
               @EventTypeCode = EventTypeCode,
               @EventData = EventData
        FROM dbo.Events
        WHERE EventId = @EventId;

        IF @MatterId IS NULL
        BEGIN
            RAISERROR('Event not found: %d', 16, 1, @EventId);
            RETURN;
        END

        -- Route to the appropriate rule handler
        IF @EventTypeCode = 'MATTER_CREATED'
            EXEC dbo.sp_Rule_MatterCreated @MatterId, @EventId, @UserId;

        ELSE IF @EventTypeCode = 'ENGAGEMENT_BASIS_UPDATED'
            EXEC dbo.sp_Rule_EngagementBasisUpdated @MatterId, @EventId, @EventData, @UserId;

        ELSE IF @EventTypeCode = 'OCG_RECEIVED'
            EXEC dbo.sp_Rule_OCGReceived @MatterId, @EventId, @EventData, @UserId;

        ELSE IF @EventTypeCode IN ('OCG_PROCESSED', 'OCG_PROCESSED_RESTRICTIONS')
            EXEC dbo.sp_Rule_OCGProcessed @MatterId, @EventId, @EventTypeCode, @EventData, @UserId;

        ELSE IF @EventTypeCode = 'NEW_TK_DETECTED'
            EXEC dbo.sp_Rule_NewTimekeeperDetected @MatterId, @EventId, @EventData, @UserId;

        ELSE IF @EventTypeCode = 'RATE_APPROVAL_UPDATED'
            EXEC dbo.sp_Rule_RateApprovalUpdated @MatterId, @EventId, @EventData, @UserId;

        ELSE IF @EventTypeCode = 'PREBILL_MILESTONE'
            EXEC dbo.sp_Rule_PrebillMilestone @MatterId, @EventId, @EventData, @UserId;

        -- Mark event as processed
        UPDATE dbo.Events
        SET IsProcessed = 1, ProcessedAt = SYSUTCDATETIME()
        WHERE EventId = @EventId;

        -- Always recalculate overall posture after any event
        EXEC dbo.sp_CalculateOverallPosture @MatterId, @UserId;

        -- Update matter timestamp
        UPDATE dbo.Matters
        SET UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @UserId
        WHERE MatterId = @MatterId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- RULE: Matter Created
-- Initialize all 5 readiness dimensions to Unknown/default state
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_MatterCreated
    @MatterId   INT,
    @EventId    INT,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize all dimensions if they don't already exist
    IF NOT EXISTS (SELECT 1 FROM dbo.ReadinessDimensions WHERE MatterId = @MatterId AND DimensionCode = 'COMMERCIAL')
        INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel, LastEvaluatedBy)
        VALUES (@MatterId, 'COMMERCIAL', 'AWAITING_DETERMINATION', 'Unknown', @UserId);

    IF NOT EXISTS (SELECT 1 FROM dbo.ReadinessDimensions WHERE MatterId = @MatterId AND DimensionCode = 'GUIDELINE')
        INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel, LastEvaluatedBy)
        VALUES (@MatterId, 'GUIDELINE', 'NO_OCG_KNOWN', 'Unknown', @UserId);

    IF NOT EXISTS (SELECT 1 FROM dbo.ReadinessDimensions WHERE MatterId = @MatterId AND DimensionCode = 'RATE')
        INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel, LastEvaluatedBy)
        VALUES (@MatterId, 'RATE', 'STANDARD_RATE', 'Green', @UserId);

    IF NOT EXISTS (SELECT 1 FROM dbo.ReadinessDimensions WHERE MatterId = @MatterId AND DimensionCode = 'STAFFING')
        INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel, LastEvaluatedBy)
        VALUES (@MatterId, 'STAFFING', 'NO_RISK_KNOWN', 'Green', @UserId);

    IF NOT EXISTS (SELECT 1 FROM dbo.ReadinessDimensions WHERE MatterId = @MatterId AND DimensionCode = 'EBILLING')
        INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel, LastEvaluatedBy)
        VALUES (@MatterId, 'EBILLING', 'NOT_APPLICABLE', 'Green', @UserId);

    -- Audit
    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Matter initialized', 'Matter', @MatterId,
            '{"dimensions":"all initialized to default"}',
            'All 5 readiness dimensions created with default statuses', @UserId);
END;
GO

-- ============================================================================
-- RULE: Engagement Basis Updated
-- If basis=existing_el or master_agreement → commercial green
-- If basis=new_el_required → commercial red
-- If basis=unclear → commercial amber + create exception
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_EngagementBasisUpdated
    @MatterId   INT,
    @EventId    INT,
    @EventData  NVARCHAR(MAX),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Basis VARCHAR(50) = JSON_VALUE(@EventData, '$.basis');
    DECLARE @NewStatus VARCHAR(50);
    DECLARE @NewRisk VARCHAR(10);
    DECLARE @OldStatus VARCHAR(50);

    SELECT @OldStatus = StatusCode
    FROM dbo.ReadinessDimensions
    WHERE MatterId = @MatterId AND DimensionCode = 'COMMERCIAL';

    -- Rule: existing EL covers matter → Green
    IF @Basis IN ('existing_el', 'existing_engagement_letter')
        SELECT @NewStatus = 'EXISTING_EL_COVERS', @NewRisk = 'Green';

    -- Rule: master agreement covers matter → Green
    ELSE IF @Basis IN ('master_agreement', 'master_agreement_covers')
        SELECT @NewStatus = 'MASTER_AGREEMENT_COVERS', @NewRisk = 'Green';

    -- Rule: new EL required → Red
    ELSE IF @Basis IN ('new_el_required', 'new_engagement_letter')
        SELECT @NewStatus = 'NEW_EL_REQUIRED', @NewRisk = 'Red';

    -- Rule: exception approved → Green
    ELSE IF @Basis = 'exception_approved'
        SELECT @NewStatus = 'EXCEPTION_APPROVED', @NewRisk = 'Green';

    -- Rule: unclear → Amber, create exception
    ELSE
        SELECT @NewStatus = 'BASIS_UNCLEAR', @NewRisk = 'Amber';

    -- Apply status change
    UPDATE dbo.ReadinessDimensions
    SET StatusCode = @NewStatus, RiskLevel = @NewRisk,
        LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId,
        UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND DimensionCode = 'COMMERCIAL';

    -- If commercial basis is unclear, create exception
    IF @NewRisk = 'Amber' AND @NewStatus = 'BASIS_UNCLEAR'
    BEGIN
        -- Only create if no open exception of this type exists
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId
                AND ExceptionTypeCode = 'COMMERCIAL_UNCLEAR'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, SourceEventId, CreatedBy)
            VALUES (@MatterId, 'COMMERCIAL_UNCLEAR', 'COMMERCIAL', 'Medium', 'FinanceOps',
                    'Commercial basis unclear — requires determination',
                    @EventId, @UserId);
        END
    END

    -- If new EL required, create exception
    IF @NewStatus = 'NEW_EL_REQUIRED'
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId
                AND ExceptionTypeCode = 'EL_REQUIRED_MISSING'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, SourceEventId, CreatedBy)
            VALUES (@MatterId, 'EL_REQUIRED_MISSING', 'COMMERCIAL', 'High', 'FinanceOps',
                    'New engagement letter required but not yet received',
                    @EventId, @UserId);
        END
    END

    -- Audit
    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Commercial readiness updated', 'Readiness', NULL,
            JSON_QUERY('{"status":"' + ISNULL(@OldStatus,'NULL') + '"}'),
            JSON_QUERY('{"status":"' + @NewStatus + '","risk":"' + @NewRisk + '"}'),
            'Engagement basis event processed: ' + ISNULL(@Basis, 'unknown'), @UserId);
END;
GO

-- ============================================================================
-- RULE: OCG Received
-- Mark guideline readiness as Amber (received, not processed)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_OCGReceived
    @MatterId   INT,
    @EventId    INT,
    @EventData  NVARCHAR(MAX),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus VARCHAR(50);
    SELECT @OldStatus = StatusCode FROM dbo.ReadinessDimensions
    WHERE MatterId = @MatterId AND DimensionCode = 'GUIDELINE';

    -- Rule: OCG received but not processed → Amber
    UPDATE dbo.ReadinessDimensions
    SET StatusCode = 'OCG_RECEIVED_NOT_PROCESSED', RiskLevel = 'Amber',
        LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId,
        UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND DimensionCode = 'GUIDELINE';

    -- Create processing exception
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Exceptions
        WHERE MatterId = @MatterId AND ExceptionTypeCode = 'OCG_NOT_PROCESSED'
            AND Status NOT IN ('Resolved','Closed','Overridden')
    )
    BEGIN
        INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, SourceEventId, CreatedBy)
        VALUES (@MatterId, 'OCG_NOT_PROCESSED', 'GUIDELINE', 'Medium', 'Billing',
                'OCG received — needs processing and review', @EventId, @UserId);
    END

    -- Record document signal
    IF NOT EXISTS (SELECT 1 FROM dbo.DocumentSignals WHERE MatterId = @MatterId AND DocumentType = 'OCG')
    BEGIN
        INSERT INTO dbo.DocumentSignals (MatterId, DocumentType, DocumentReference, SignalStatus, ReceivedDate, CreatedBy)
        VALUES (@MatterId, 'OCG', JSON_VALUE(@EventData, '$.docRef'), 'Received', CAST(SYSUTCDATETIME() AS DATE), @UserId);
    END
    ELSE
    BEGIN
        UPDATE dbo.DocumentSignals
        SET SignalStatus = 'Received', ReceivedDate = CAST(SYSUTCDATETIME() AS DATE), UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DocumentType = 'OCG';
    END

    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Guideline readiness updated', 'Readiness', NULL,
            '{"status":"' + ISNULL(@OldStatus,'NULL') + '"}',
            '{"status":"OCG_RECEIVED_NOT_PROCESSED","risk":"Amber"}',
            'OCG received — awaiting processing', @UserId);
END;
GO

-- ============================================================================
-- RULE: OCG Processed (with or without restrictions)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_OCGProcessed
    @MatterId       INT,
    @EventId        INT,
    @EventTypeCode  VARCHAR(50),
    @EventData      NVARCHAR(MAX),
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HasRestrictions BIT = CASE WHEN @EventTypeCode = 'OCG_PROCESSED_RESTRICTIONS' THEN 1 ELSE 0 END;

    IF @HasRestrictions = 0
    BEGIN
        -- Rule: OCG processed without material restrictions → Green
        UPDATE dbo.ReadinessDimensions
        SET StatusCode = 'OCG_PROCESSED', RiskLevel = 'Green',
            LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DimensionCode = 'GUIDELINE';
    END
    ELSE
    BEGIN
        -- Rule: OCG processed WITH material restrictions → Amber + exception
        UPDATE dbo.ReadinessDimensions
        SET StatusCode = 'OCG_MATERIAL_RESTRICTIONS', RiskLevel = 'Amber',
            LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DimensionCode = 'GUIDELINE';

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId AND ExceptionTypeCode = 'OCG_RESTRICTIONS'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, Detail, SourceEventId, CreatedBy)
            VALUES (@MatterId, 'OCG_RESTRICTIONS', 'GUIDELINE', 'High', 'Billing',
                    'OCG contains material restrictions requiring review',
                    @EventData, @EventId, @UserId);
        END
    END

    -- Resolve any pending OCG_NOT_PROCESSED exceptions
    UPDATE dbo.Exceptions
    SET Status = 'Resolved', ResolvedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND ExceptionTypeCode = 'OCG_NOT_PROCESSED'
        AND Status NOT IN ('Resolved','Closed','Overridden');

    -- Update document signal
    UPDATE dbo.DocumentSignals
    SET SignalStatus = 'Processed', ProcessedDate = CAST(SYSUTCDATETIME() AS DATE), UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND DocumentType = 'OCG';

    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'OCG processed', 'Readiness', NULL,
            '{"restrictions":' + CASE WHEN @HasRestrictions = 1 THEN 'true' ELSE 'false' END + '}',
            CASE WHEN @HasRestrictions = 1 THEN 'OCG processed with material restrictions' ELSE 'OCG processed — no material restrictions' END,
            @UserId);
END;
GO

-- ============================================================================
-- RULE: New Timekeeper Detected
-- Creates staffing exception if rate approval not confirmed
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_NewTimekeeperDetected
    @MatterId   INT,
    @EventId    INT,
    @EventData  NVARCHAR(MAX),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Rule: New timekeeper detected → staffing amber, create exception
    UPDATE dbo.ReadinessDimensions
    SET StatusCode = 'NEW_TK_DETECTED', RiskLevel = 'Amber',
        LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND DimensionCode = 'STAFFING'
        AND StatusCode NOT IN ('LATE_CYCLE_EXCEPTION', 'TK_RATE_NOT_APPROVED');
        -- Don't downgrade from a worse state

    -- Create staffing exception
    INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, Detail, SourceEventId, CreatedBy)
    VALUES (@MatterId, 'TK_NOT_APPROVED', 'STAFFING', 'Medium', 'Rates',
            'New timekeeper detected — approval and rate confirmation required',
            @EventData, @EventId, @UserId);

    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Staffing risk created', 'Readiness', NULL,
            @EventData, 'New timekeeper detected — rate approval pending', @UserId);
END;
GO

-- ============================================================================
-- RULE: Rate Approval Updated
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_RateApprovalUpdated
    @MatterId   INT,
    @EventId    INT,
    @EventData  NVARCHAR(MAX),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Status VARCHAR(50) = JSON_VALUE(@EventData, '$.status');

    IF @Status = 'approved'
    BEGIN
        -- Rule: rate approved → Green (if no other rate issues)
        UPDATE dbo.ReadinessDimensions
        SET StatusCode = 'STANDARD_RATE', RiskLevel = 'Green',
            LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DimensionCode = 'RATE';

        -- Resolve open rate exceptions
        UPDATE dbo.Exceptions
        SET Status = 'Resolved', ResolvedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND ExceptionTypeCode IN ('RATE_MISMATCH', 'TIME_BEFORE_RATE')
            AND Status NOT IN ('Resolved','Closed','Overridden');

        -- Also clear staffing rate issues
        UPDATE dbo.Exceptions
        SET Status = 'Resolved', ResolvedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND ExceptionTypeCode IN ('TK_NOT_APPROVED', 'TK_RATE_MISSING')
            AND Status NOT IN ('Resolved','Closed','Overridden');

        -- If no remaining staffing exceptions, clear staffing
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId AND DimensionCode = 'STAFFING'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            UPDATE dbo.ReadinessDimensions
            SET StatusCode = 'CLEARED', RiskLevel = 'Green',
                LastEvaluatedAt = SYSUTCDATETIME(), UpdatedAt = SYSUTCDATETIME()
            WHERE MatterId = @MatterId AND DimensionCode = 'STAFFING';
        END
    END
    ELSE IF @Status = 'mismatch'
    BEGIN
        -- Rule: rate mismatch → Red + exception
        UPDATE dbo.ReadinessDimensions
        SET StatusCode = 'RATE_MISMATCH', RiskLevel = 'Red',
            LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DimensionCode = 'RATE';

        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId AND ExceptionTypeCode = 'RATE_MISMATCH'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, OwnerRole, Summary, Detail, SourceEventId, CreatedBy)
            VALUES (@MatterId, 'RATE_MISMATCH', 'RATE', 'High', 'Rates',
                    'Rate mismatch detected — applied rates do not match agreed rates',
                    @EventData, @EventId, @UserId);
        END
    END
    ELSE IF @Status = 'pending'
    BEGIN
        UPDATE dbo.ReadinessDimensions
        SET StatusCode = 'CLIENT_APPROVAL_PENDING', RiskLevel = 'Amber',
            LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
        WHERE MatterId = @MatterId AND DimensionCode = 'RATE';
    END

    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Rate readiness updated', 'Readiness', NULL,
            @EventData, 'Rate approval status: ' + ISNULL(@Status, 'unknown'), @UserId);
END;
GO

-- ============================================================================
-- RULE: Prebill Milestone Reached
-- Escalate any unresolved exceptions; potentially block matter
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Rule_PrebillMilestone
    @MatterId   INT,
    @EventId    INT,
    @EventData  NVARCHAR(MAX),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OpenHighCritical INT;
    DECLARE @OpenAny INT;

    SELECT @OpenHighCritical = COUNT(*)
    FROM dbo.Exceptions
    WHERE MatterId = @MatterId
        AND Status NOT IN ('Resolved','Closed','Overridden')
        AND Severity IN ('High','Critical');

    SELECT @OpenAny = COUNT(*)
    FROM dbo.Exceptions
    WHERE MatterId = @MatterId
        AND Status NOT IN ('Resolved','Closed','Overridden');

    -- Rule: If unresolved staffing or rate exceptions remain at prebill → escalate severity
    UPDATE dbo.Exceptions
    SET Severity = CASE
            WHEN Severity = 'Medium' THEN 'High'
            WHEN Severity = 'High' THEN 'Critical'
            ELSE Severity
        END,
        Status = CASE
            WHEN Severity IN ('High','Critical') THEN 'Escalated'
            ELSE Status
        END,
        UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId
        AND DimensionCode IN ('STAFFING', 'RATE')
        AND Status NOT IN ('Resolved','Closed','Overridden')
        AND Severity <> 'Critical';  -- Don't escalate beyond critical

    -- Rule: If any high/critical exceptions at prebill → create prebill blocker exception
    IF @OpenHighCritical > 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Exceptions
            WHERE MatterId = @MatterId AND ExceptionTypeCode = 'PREBILL_BLOCKER'
                AND Status NOT IN ('Resolved','Closed','Overridden')
        )
        BEGIN
            INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, Status, OwnerRole, Summary, Detail, SourceEventId, CreatedBy)
            VALUES (@MatterId, 'PREBILL_BLOCKER', NULL, 'Critical', 'Escalated', 'FinanceOps',
                    'Prebill milestone reached with ' + CAST(@OpenHighCritical AS VARCHAR(5)) + ' unresolved high/critical exceptions',
                    '{"openHighCritical":' + CAST(@OpenHighCritical AS VARCHAR(5)) + ',"openTotal":' + CAST(@OpenAny AS VARCHAR(5)) + '}',
                    @EventId, @UserId);
        END
    END

    -- Update open exception count
    UPDATE dbo.Matters
    SET OpenExceptionCount = (
        SELECT COUNT(*) FROM dbo.Exceptions e
        WHERE e.MatterId = @MatterId AND e.Status NOT IN ('Resolved','Closed','Overridden')
    )
    WHERE MatterId = @MatterId;

    INSERT INTO dbo.AuditEntries (MatterId, EventId, Action, EntityType, EntityId, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @EventId, 'Prebill milestone processed', 'Matter', @MatterId,
            '{"openHighCritical":' + CAST(@OpenHighCritical AS VARCHAR(5)) + '}',
            'Prebill milestone reached — exceptions escalated as needed', @UserId);
END;
GO

-- ============================================================================
-- PROCEDURE: Calculate Overall Posture
-- Rolls up all readiness dimensions + exceptions into a single posture
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_CalculateOverallPosture
    @MatterId   INT,
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RedCount       INT = 0;
    DECLARE @AmberCount     INT = 0;
    DECLARE @UnknownCount   INT = 0;
    DECLARE @GreenCount     INT = 0;
    DECLARE @CriticalExc    INT = 0;
    DECLARE @HighExc        INT = 0;
    DECLARE @OpenExc        INT = 0;
    DECLARE @EscalatedExc   INT = 0;
    DECLARE @OldPosture     VARCHAR(40);
    DECLARE @NewPosture     VARCHAR(40);
    DECLARE @Rationale      NVARCHAR(MAX);

    SELECT @OldPosture = OverallPosture FROM dbo.Matters WHERE MatterId = @MatterId;

    -- Count risk levels across dimensions
    SELECT
        @RedCount     = SUM(CASE WHEN RiskLevel = 'Red'     THEN 1 ELSE 0 END),
        @AmberCount   = SUM(CASE WHEN RiskLevel = 'Amber'   THEN 1 ELSE 0 END),
        @UnknownCount = SUM(CASE WHEN RiskLevel = 'Unknown' THEN 1 ELSE 0 END),
        @GreenCount   = SUM(CASE WHEN RiskLevel = 'Green'   THEN 1 ELSE 0 END)
    FROM dbo.ReadinessDimensions
    WHERE MatterId = @MatterId;

    -- Count open exceptions by severity
    SELECT
        @CriticalExc  = SUM(CASE WHEN Severity = 'Critical' THEN 1 ELSE 0 END),
        @HighExc      = SUM(CASE WHEN Severity = 'High'     THEN 1 ELSE 0 END),
        @OpenExc      = COUNT(*),
        @EscalatedExc = SUM(CASE WHEN Status = 'Escalated'  THEN 1 ELSE 0 END)
    FROM dbo.Exceptions
    WHERE MatterId = @MatterId
        AND Status NOT IN ('Resolved','Closed','Overridden');

    -- Posture rollup rules (most severe wins):

    -- Rule 1: Any escalated or critical exception → ESCALATION_REQUIRED
    IF @EscalatedExc > 0 OR @CriticalExc > 0
    BEGIN
        SET @NewPosture = 'ESCALATION_REQUIRED';
        SET @Rationale = CAST(@EscalatedExc AS VARCHAR) + ' escalated, ' + CAST(@CriticalExc AS VARCHAR) + ' critical exceptions';
    END
    -- Rule 2: Any red dimension or high exception → RESTRICTED
    ELSE IF @RedCount > 0 OR @HighExc > 0
    BEGIN
        SET @NewPosture = 'RESTRICTED';
        SET @Rationale = CAST(@RedCount AS VARCHAR) + ' red dimensions, ' + CAST(@HighExc AS VARCHAR) + ' high-severity exceptions';
    END
    -- Rule 3: Open amber exceptions → READY_EXCEPTIONS
    ELSE IF @OpenExc > 0
    BEGIN
        SET @NewPosture = 'READY_EXCEPTIONS';
        SET @Rationale = CAST(@OpenExc AS VARCHAR) + ' open exceptions (non-blocking)';
    END
    -- Rule 4: Any unknown dimensions → READY_MONITORED
    ELSE IF @UnknownCount > 0
    BEGIN
        SET @NewPosture = 'READY_MONITORED';
        SET @Rationale = CAST(@UnknownCount AS VARCHAR) + ' dimensions with unknown status';
    END
    -- Rule 5: All green, no exceptions → READY
    ELSE
    BEGIN
        SET @NewPosture = 'READY';
        SET @Rationale = 'All dimensions green, no open exceptions';
    END

    -- Apply posture
    UPDATE dbo.Matters
    SET OverallPosture = @NewPosture,
        PostureRationale = @Rationale,
        OpenExceptionCount = @OpenExc,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedBy = @UserId
    WHERE MatterId = @MatterId;

    -- Audit posture change (only if changed)
    IF @OldPosture <> @NewPosture
    BEGIN
        INSERT INTO dbo.AuditEntries (MatterId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy)
        VALUES (@MatterId, 'Posture changed', 'Matter', @MatterId,
                '{"posture":"' + @OldPosture + '"}',
                '{"posture":"' + @NewPosture + '"}',
                @Rationale, @UserId);
    END
END;
GO

-- ============================================================================
-- PROCEDURE: Override an Exception
-- Allows authorized override with mandatory reason
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_OverrideException
    @ExceptionId    INT,
    @OverrideReason NVARCHAR(MAX),
    @UserId         INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @OverrideReason IS NULL OR LEN(TRIM(@OverrideReason)) = 0
    BEGIN
        RAISERROR('Override reason is required', 16, 1);
        RETURN;
    END

    DECLARE @MatterId INT;
    DECLARE @OldSeverity VARCHAR(10);
    DECLARE @OldStatus VARCHAR(30);

    SELECT @MatterId = MatterId, @OldSeverity = Severity, @OldStatus = Status
    FROM dbo.Exceptions WHERE ExceptionId = @ExceptionId;

    UPDATE dbo.Exceptions
    SET Status = 'Overridden',
        IsOverridden = 1,
        OverrideReason = @OverrideReason,
        OverriddenBy = @UserId,
        OverriddenAt = SYSUTCDATETIME(),
        UpdatedAt = SYSUTCDATETIME()
    WHERE ExceptionId = @ExceptionId;

    -- Audit
    INSERT INTO dbo.AuditEntries (MatterId, ExceptionId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, @ExceptionId, 'Exception overridden', 'Exception', @ExceptionId,
            '{"status":"' + @OldStatus + '","severity":"' + @OldSeverity + '"}',
            '{"status":"Overridden","overrideReason":"' + LEFT(@OverrideReason, 200) + '"}',
            @OverrideReason, @UserId);

    -- Recalculate posture
    EXEC dbo.sp_CalculateOverallPosture @MatterId, @UserId;
END;
GO

-- ============================================================================
-- PROCEDURE: Manually Update a Readiness Dimension
-- For cases where status changes outside the event flow
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_UpdateReadinessManual
    @MatterId       INT,
    @DimensionCode  VARCHAR(30),
    @NewStatusCode  VARCHAR(50),
    @Notes          NVARCHAR(MAX) = NULL,
    @UserId         INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus VARCHAR(50);
    DECLARE @OldRisk VARCHAR(10);
    DECLARE @NewRisk VARCHAR(10);

    SELECT @OldStatus = StatusCode, @OldRisk = RiskLevel
    FROM dbo.ReadinessDimensions
    WHERE MatterId = @MatterId AND DimensionCode = @DimensionCode;

    SELECT @NewRisk = RiskLevel
    FROM dbo.LookupReadinessStatus
    WHERE DimensionCode = @DimensionCode AND StatusCode = @NewStatusCode;

    UPDATE dbo.ReadinessDimensions
    SET StatusCode = @NewStatusCode, RiskLevel = @NewRisk, Notes = @Notes,
        LastEvaluatedAt = SYSUTCDATETIME(), LastEvaluatedBy = @UserId, UpdatedAt = SYSUTCDATETIME()
    WHERE MatterId = @MatterId AND DimensionCode = @DimensionCode;

    -- Log event
    INSERT INTO dbo.Events (MatterId, EventTypeCode, EventData, EventSource, IsProcessed, ProcessedAt, CreatedBy)
    VALUES (@MatterId, 'MANUAL_STATUS_UPDATE',
            '{"dimension":"' + @DimensionCode + '","oldStatus":"' + ISNULL(@OldStatus,'') + '","newStatus":"' + @NewStatusCode + '"}',
            'Manual', 1, SYSUTCDATETIME(), @UserId);

    -- Audit
    INSERT INTO dbo.AuditEntries (MatterId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy)
    VALUES (@MatterId, 'Manual readiness update', 'Readiness', NULL,
            '{"status":"' + ISNULL(@OldStatus,'') + '","risk":"' + ISNULL(@OldRisk,'') + '"}',
            '{"status":"' + @NewStatusCode + '","risk":"' + @NewRisk + '"}',
            ISNULL(@Notes, 'Manual update'), @UserId);

    EXEC dbo.sp_CalculateOverallPosture @MatterId, @UserId;
END;
GO
