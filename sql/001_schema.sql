-- ============================================================================
-- Matter Readiness and Billing Risk Orchestrator (MRBRO)
-- Schema DDL — Azure SQL Database
-- ============================================================================

-- ============================================================================
-- LOOKUP TABLES
-- ============================================================================

CREATE TABLE dbo.LookupReadinessDimension (
    DimensionCode       VARCHAR(30)     NOT NULL PRIMARY KEY,
    DimensionName       NVARCHAR(100)   NOT NULL,
    SortOrder           INT             NOT NULL DEFAULT 0
);

CREATE TABLE dbo.LookupReadinessStatus (
    StatusId            INT             IDENTITY(1,1) PRIMARY KEY,
    DimensionCode       VARCHAR(30)     NOT NULL
        REFERENCES dbo.LookupReadinessDimension(DimensionCode),
    StatusCode          VARCHAR(50)     NOT NULL,
    StatusLabel         NVARCHAR(200)   NOT NULL,
    RiskLevel           VARCHAR(10)     NOT NULL  -- Green, Amber, Red, Unknown
        CHECK (RiskLevel IN ('Green','Amber','Red','Unknown')),
    SortOrder           INT             NOT NULL DEFAULT 0,
    CONSTRAINT UQ_DimStatus UNIQUE (DimensionCode, StatusCode)
);

CREATE TABLE dbo.LookupPosture (
    PostureCode         VARCHAR(40)     NOT NULL PRIMARY KEY,
    PostureLabel        NVARCHAR(100)   NOT NULL,
    Severity            INT             NOT NULL, -- 1=Ready … 5=Escalation Required
    ColorHex            CHAR(7)         NOT NULL  -- for UI
);

CREATE TABLE dbo.LookupExceptionType (
    ExceptionTypeCode   VARCHAR(50)     NOT NULL PRIMARY KEY,
    ExceptionTypeLabel  NVARCHAR(200)   NOT NULL,
    DefaultSeverity     VARCHAR(10)     NOT NULL
        CHECK (DefaultSeverity IN ('Low','Medium','High','Critical')),
    DefaultOwnerRole    VARCHAR(30)     NULL
);

CREATE TABLE dbo.LookupEventType (
    EventTypeCode       VARCHAR(50)     NOT NULL PRIMARY KEY,
    EventTypeLabel      NVARCHAR(200)   NOT NULL,
    SortOrder           INT             NOT NULL DEFAULT 0
);

CREATE TABLE dbo.LookupRole (
    RoleCode            VARCHAR(30)     NOT NULL PRIMARY KEY,
    RoleLabel           NVARCHAR(100)   NOT NULL
);

CREATE TABLE dbo.LookupExceptionStatus (
    StatusCode          VARCHAR(30)     NOT NULL PRIMARY KEY,
    StatusLabel         NVARCHAR(100)   NOT NULL,
    IsTerminal          BIT             NOT NULL DEFAULT 0
);

-- ============================================================================
-- CORE TABLES
-- ============================================================================

CREATE TABLE dbo.Users (
    UserId              INT             IDENTITY(1,1) PRIMARY KEY,
    Email               NVARCHAR(256)   NOT NULL UNIQUE,
    DisplayName         NVARCHAR(200)   NOT NULL,
    RoleCode            VARCHAR(30)     NOT NULL
        REFERENCES dbo.LookupRole(RoleCode),
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Matters (
    MatterId            INT             IDENTITY(1,1) PRIMARY KEY,
    MatterNumber        NVARCHAR(50)    NOT NULL UNIQUE,
    MatterName          NVARCHAR(500)   NOT NULL,
    ClientName          NVARCHAR(300)   NOT NULL,
    ClientNumber        NVARCHAR(50)    NULL,
    ResponsibleLawyer   NVARCHAR(200)   NOT NULL,
    PracticeGroup       NVARCHAR(100)   NULL,
    Office              NVARCHAR(100)   NULL,
    MatterOpenDate      DATE            NOT NULL,
    OverallPosture      VARCHAR(40)     NOT NULL DEFAULT 'Restricted'
        REFERENCES dbo.LookupPosture(PostureCode),
    PostureRationale    NVARCHAR(MAX)   NULL,
    OpenExceptionCount  INT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy           INT             NULL REFERENCES dbo.Users(UserId),
    UpdatedBy           INT             NULL REFERENCES dbo.Users(UserId)
);

CREATE INDEX IX_Matters_Posture ON dbo.Matters(OverallPosture);
CREATE INDEX IX_Matters_Client  ON dbo.Matters(ClientName);

CREATE TABLE dbo.ReadinessDimensions (
    ReadinessId         INT             IDENTITY(1,1) PRIMARY KEY,
    MatterId            INT             NOT NULL
        REFERENCES dbo.Matters(MatterId),
    DimensionCode       VARCHAR(30)     NOT NULL
        REFERENCES dbo.LookupReadinessDimension(DimensionCode),
    StatusCode          VARCHAR(50)     NOT NULL,
    RiskLevel           VARCHAR(10)     NOT NULL
        CHECK (RiskLevel IN ('Green','Amber','Red','Unknown')),
    Notes               NVARCHAR(MAX)   NULL,
    LastEvaluatedAt     DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    LastEvaluatedBy     INT             NULL REFERENCES dbo.Users(UserId),
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_MatterDimension UNIQUE (MatterId, DimensionCode),
    CONSTRAINT FK_ReadinessStatus FOREIGN KEY (DimensionCode, StatusCode)
        REFERENCES dbo.LookupReadinessStatus(DimensionCode, StatusCode)
);

CREATE INDEX IX_Readiness_Matter ON dbo.ReadinessDimensions(MatterId);
CREATE INDEX IX_Readiness_Risk   ON dbo.ReadinessDimensions(RiskLevel);

CREATE TABLE dbo.Exceptions (
    ExceptionId         INT             IDENTITY(1,1) PRIMARY KEY,
    MatterId            INT             NOT NULL
        REFERENCES dbo.Matters(MatterId),
    ExceptionTypeCode   VARCHAR(50)     NOT NULL
        REFERENCES dbo.LookupExceptionType(ExceptionTypeCode),
    DimensionCode       VARCHAR(30)     NULL
        REFERENCES dbo.LookupReadinessDimension(DimensionCode),
    Severity            VARCHAR(10)     NOT NULL
        CHECK (Severity IN ('Low','Medium','High','Critical')),
    Status              VARCHAR(30)     NOT NULL DEFAULT 'Open'
        REFERENCES dbo.LookupExceptionStatus(StatusCode),
    OwnerRole           VARCHAR(30)     NULL
        REFERENCES dbo.LookupRole(RoleCode),
    OwnerUserId         INT             NULL
        REFERENCES dbo.Users(UserId),
    Summary             NVARCHAR(500)   NOT NULL,
    Detail              NVARCHAR(MAX)   NULL,
    DueDate             DATE            NULL,
    IsOverridden        BIT             NOT NULL DEFAULT 0,
    OverrideReason      NVARCHAR(MAX)   NULL,
    OverriddenBy        INT             NULL REFERENCES dbo.Users(UserId),
    OverriddenAt        DATETIME2(3)    NULL,
    SourceEventId       INT             NULL,  -- FK added after Events table
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    ResolvedAt          DATETIME2(3)    NULL,
    CreatedBy           INT             NULL REFERENCES dbo.Users(UserId)
);

CREATE INDEX IX_Exceptions_Matter   ON dbo.Exceptions(MatterId);
CREATE INDEX IX_Exceptions_Status   ON dbo.Exceptions(Status);
CREATE INDEX IX_Exceptions_Severity ON dbo.Exceptions(Severity);
CREATE INDEX IX_Exceptions_Owner    ON dbo.Exceptions(OwnerRole, OwnerUserId);
CREATE INDEX IX_Exceptions_Due      ON dbo.Exceptions(DueDate) WHERE Status NOT IN ('Resolved','Closed');

CREATE TABLE dbo.Events (
    EventId             INT             IDENTITY(1,1) PRIMARY KEY,
    MatterId            INT             NOT NULL
        REFERENCES dbo.Matters(MatterId),
    EventTypeCode       VARCHAR(50)     NOT NULL
        REFERENCES dbo.LookupEventType(EventTypeCode),
    EventData           NVARCHAR(MAX)   NULL,  -- JSON payload for flexible event attributes
    EventSource         VARCHAR(30)     NOT NULL DEFAULT 'Manual'
        CHECK (EventSource IN ('Manual','Simulator','Integration','System')),
    IsProcessed         BIT             NOT NULL DEFAULT 0,
    ProcessedAt         DATETIME2(3)    NULL,
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy           INT             NULL REFERENCES dbo.Users(UserId)
);

CREATE INDEX IX_Events_Matter    ON dbo.Events(MatterId);
CREATE INDEX IX_Events_Type      ON dbo.Events(EventTypeCode);
CREATE INDEX IX_Events_Processed ON dbo.Events(IsProcessed) WHERE IsProcessed = 0;

-- Now add the FK from Exceptions to Events
ALTER TABLE dbo.Exceptions
    ADD CONSTRAINT FK_Exceptions_SourceEvent
    FOREIGN KEY (SourceEventId) REFERENCES dbo.Events(EventId);

CREATE TABLE dbo.AuditEntries (
    AuditId             INT             IDENTITY(1,1) PRIMARY KEY,
    MatterId            INT             NULL
        REFERENCES dbo.Matters(MatterId),
    ExceptionId         INT             NULL
        REFERENCES dbo.Exceptions(ExceptionId),
    EventId             INT             NULL
        REFERENCES dbo.Events(EventId),
    Action              NVARCHAR(100)   NOT NULL,
    EntityType          VARCHAR(50)     NOT NULL,  -- Matter, Readiness, Exception, Event
    EntityId            INT             NULL,
    OldValue            NVARCHAR(MAX)   NULL,  -- JSON
    NewValue            NVARCHAR(MAX)   NULL,  -- JSON
    Rationale           NVARCHAR(MAX)   NULL,
    PerformedBy         INT             NULL REFERENCES dbo.Users(UserId),
    PerformedAt         DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_Audit_Matter    ON dbo.AuditEntries(MatterId);
CREATE INDEX IX_Audit_Exception ON dbo.AuditEntries(ExceptionId);
CREATE INDEX IX_Audit_Time      ON dbo.AuditEntries(PerformedAt);

CREATE TABLE dbo.DocumentSignals (
    SignalId            INT             IDENTITY(1,1) PRIMARY KEY,
    MatterId            INT             NOT NULL
        REFERENCES dbo.Matters(MatterId),
    DocumentType        VARCHAR(50)     NOT NULL,  -- EngagementLetter, OCG, MasterAgreement, RateCard
    DocumentReference   NVARCHAR(500)   NULL,
    SignalStatus        VARCHAR(30)     NOT NULL,  -- Received, Pending, Processed, NotApplicable
    Notes               NVARCHAR(MAX)   NULL,
    ReceivedDate        DATE            NULL,
    ProcessedDate       DATE            NULL,
    CreatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy           INT             NULL REFERENCES dbo.Users(UserId)
);

CREATE INDEX IX_DocSignals_Matter ON dbo.DocumentSignals(MatterId);

-- ============================================================================
-- FEATURE FLAGS (for AI / optional features)
-- ============================================================================

CREATE TABLE dbo.FeatureFlags (
    FlagName            VARCHAR(100)    NOT NULL PRIMARY KEY,
    IsEnabled           BIT             NOT NULL DEFAULT 0,
    Description         NVARCHAR(500)   NULL,
    UpdatedAt           DATETIME2(3)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedBy           INT             NULL REFERENCES dbo.Users(UserId)
);
