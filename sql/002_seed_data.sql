-- ============================================================================
-- MRBRO — Seed Data
-- ============================================================================

-- ============================================================================
-- LOOKUP DATA
-- ============================================================================

INSERT INTO dbo.LookupRole (RoleCode, RoleLabel) VALUES
    ('Admin',       'Administrator'),
    ('FinanceOps',  'Finance Operations'),
    ('Billing',     'Billing Specialist'),
    ('Rates',       'Rates Analyst'),
    ('Viewer',      'Read-Only Viewer');

INSERT INTO dbo.LookupReadinessDimension (DimensionCode, DimensionName, SortOrder) VALUES
    ('COMMERCIAL',  'Commercial Readiness',     1),
    ('GUIDELINE',   'Guideline Readiness',      2),
    ('RATE',        'Rate Readiness',           3),
    ('STAFFING',    'Staffing Readiness',       4),
    ('EBILLING',    'eBilling Readiness',       5);

-- Commercial Readiness Statuses
INSERT INTO dbo.LookupReadinessStatus (DimensionCode, StatusCode, StatusLabel, RiskLevel, SortOrder) VALUES
    ('COMMERCIAL', 'NEW_EL_REQUIRED',          'New engagement letter required',            'Red',      1),
    ('COMMERCIAL', 'EXISTING_EL_COVERS',       'Existing engagement letter covers matter',  'Green',    2),
    ('COMMERCIAL', 'MASTER_AGREEMENT_COVERS',  'Master agreement covers matter',            'Green',    3),
    ('COMMERCIAL', 'BASIS_UNCLEAR',            'Commercial basis unclear',                  'Amber',    4),
    ('COMMERCIAL', 'EXCEPTION_APPROVED',       'Exception approved',                        'Green',    5),
    ('COMMERCIAL', 'AWAITING_DETERMINATION',   'Awaiting determination',                    'Unknown',  6);

-- Guideline Readiness Statuses
INSERT INTO dbo.LookupReadinessStatus (DimensionCode, StatusCode, StatusLabel, RiskLevel, SortOrder) VALUES
    ('GUIDELINE', 'NO_OCG_KNOWN',              'No OCG known',                              'Unknown',  1),
    ('GUIDELINE', 'OCG_EXPECTED_NOT_RECEIVED', 'OCG expected but not received',             'Amber',    2),
    ('GUIDELINE', 'OCG_RECEIVED_NOT_PROCESSED','OCG received, not processed',               'Amber',    3),
    ('GUIDELINE', 'OCG_PROCESSED',             'OCG processed',                             'Green',    4),
    ('GUIDELINE', 'OCG_MATERIAL_RESTRICTIONS', 'OCG processed with material restrictions',  'Amber',    5),
    ('GUIDELINE', 'OCG_UPDATED_POST_ACTIVATION','OCG updated after activation',             'Amber',    6);

-- Rate Readiness Statuses
INSERT INTO dbo.LookupReadinessStatus (DimensionCode, StatusCode, StatusLabel, RiskLevel, SortOrder) VALUES
    ('RATE', 'STANDARD_RATE',           'Standard rate assumption',         'Green',    1),
    ('RATE', 'SPECIAL_RATES_REQUIRED',  'Special rates required',          'Amber',    2),
    ('RATE', 'RATE_SETUP_IN_PROGRESS',  'Rate setup in progress',          'Amber',    3),
    ('RATE', 'CLIENT_APPROVAL_PENDING', 'Client-side approval pending',    'Amber',    4),
    ('RATE', 'RATE_MISMATCH',           'Rate mismatch detected',          'Red',      5),
    ('RATE', 'TIME_BEFORE_RATE',        'Time posted before rate approval','Red',      6);

-- Staffing Readiness Statuses
INSERT INTO dbo.LookupReadinessStatus (DimensionCode, StatusCode, StatusLabel, RiskLevel, SortOrder) VALUES
    ('STAFFING', 'NO_RISK_KNOWN',           'No active staffing risk known',    'Green',    1),
    ('STAFFING', 'NEW_TK_DETECTED',         'New timekeeper detected',          'Amber',    2),
    ('STAFFING', 'TK_APPROVAL_REQUIRED',    'Timekeeper approval required',     'Amber',    3),
    ('STAFFING', 'TK_RATE_NOT_APPROVED',    'Timekeeper rate not approved',     'Red',      4),
    ('STAFFING', 'LATE_CYCLE_EXCEPTION',    'Late-cycle staffing exception',    'Red',      5),
    ('STAFFING', 'CLEARED',                 'Cleared',                          'Green',    6);

-- eBilling Readiness Statuses
INSERT INTO dbo.LookupReadinessStatus (DimensionCode, StatusCode, StatusLabel, RiskLevel, SortOrder) VALUES
    ('EBILLING', 'NOT_APPLICABLE',          'Not applicable',                   'Green',    1),
    ('EBILLING', 'EBILLING_EXPECTED',       'eBilling expected',                'Amber',    2),
    ('EBILLING', 'SETUP_PENDING',           'eBilling setup pending',           'Amber',    3),
    ('EBILLING', 'CLIENT_APPROVAL_PENDING', 'Client approval pending',          'Amber',    4),
    ('EBILLING', 'SUBMISSION_RISK',         'Submission risk',                  'Red',      5),
    ('EBILLING', 'READY',                   'Ready',                            'Green',    6);

-- Posture Categories
INSERT INTO dbo.LookupPosture (PostureCode, PostureLabel, Severity, ColorHex) VALUES
    ('READY',                   'Ready',                            1, '#2E7D32'),
    ('READY_MONITORED',         'Ready with monitored unknowns',    2, '#558B2F'),
    ('READY_EXCEPTIONS',        'Ready with active exceptions',     3, '#F9A825'),
    ('RESTRICTED',              'Restricted',                       4, '#E65100'),
    ('ESCALATION_REQUIRED',     'Escalation required',              5, '#B71C1C');

-- Exception Types
INSERT INTO dbo.LookupExceptionType (ExceptionTypeCode, ExceptionTypeLabel, DefaultSeverity, DefaultOwnerRole) VALUES
    ('COMMERCIAL_UNCLEAR',      'Commercial basis unclear',                         'Medium',   'FinanceOps'),
    ('EL_REQUIRED_MISSING',     'Engagement letter required but not received',      'High',     'FinanceOps'),
    ('OCG_NOT_PROCESSED',       'OCG received but not yet processed',               'Medium',   'Billing'),
    ('OCG_RESTRICTIONS',        'OCG contains material restrictions',               'High',     'Billing'),
    ('RATE_MISMATCH',           'Rate mismatch detected',                           'High',     'Rates'),
    ('TK_NOT_APPROVED',         'Timekeeper not approved for matter',               'Medium',   'Rates'),
    ('TK_RATE_MISSING',         'Timekeeper rate not approved',                     'High',     'Rates'),
    ('LATE_CYCLE_STAFFING',     'Late-cycle staffing change',                       'High',     'FinanceOps'),
    ('EBILLING_SETUP_PENDING',  'eBilling setup pending',                           'Medium',   'Billing'),
    ('EBILLING_CLIENT_PENDING', 'eBilling client approval pending',                 'Medium',   'Billing'),
    ('PREBILL_BLOCKER',         'Unresolved exception at prebill milestone',        'Critical', 'FinanceOps'),
    ('TIME_BEFORE_RATE',        'Time posted before rate approval',                 'Critical', 'Rates');

-- Event Types
INSERT INTO dbo.LookupEventType (EventTypeCode, EventTypeLabel, SortOrder) VALUES
    ('MATTER_CREATED',              'Matter created',                           1),
    ('ENGAGEMENT_BASIS_UPDATED',    'Engagement basis updated',                 2),
    ('OCG_RECEIVED',                'Outside counsel guidelines received',      3),
    ('OCG_PROCESSED',               'OCG processed',                            4),
    ('OCG_PROCESSED_RESTRICTIONS',  'OCG processed with restrictions',          5),
    ('NEW_TK_DETECTED',             'New timekeeper detected',                  6),
    ('RATE_APPROVAL_UPDATED',       'Rate approval updated',                    7),
    ('PREBILL_MILESTONE',           'Prebill milestone reached',                8),
    ('EXCEPTION_CREATED',           'Exception created',                        9),
    ('EXCEPTION_RESOLVED',          'Exception resolved',                       10),
    ('EXCEPTION_OVERRIDDEN',        'Exception overridden',                     11),
    ('POSTURE_CHANGED',             'Overall posture changed',                  12),
    ('MANUAL_STATUS_UPDATE',        'Manual status update',                     13);

-- Exception Statuses
INSERT INTO dbo.LookupExceptionStatus (StatusCode, StatusLabel, IsTerminal) VALUES
    ('Open',            'Open',                     0),
    ('InProgress',      'In Progress',              0),
    ('PendingApproval', 'Pending Approval',         0),
    ('Escalated',       'Escalated',                0),
    ('Overridden',      'Overridden',               1),
    ('Resolved',        'Resolved',                 1),
    ('Closed',          'Closed (No Action)',        1);

-- Feature Flags
INSERT INTO dbo.FeatureFlags (FlagName, IsEnabled, Description) VALUES
    ('AI_OCG_EXTRACTION',       0, 'Use AI to extract key terms from OCG documents'),
    ('AI_RISK_SCORING',         0, 'Use AI-based risk scoring model'),
    ('AUTO_NOTIFY_TEAMS',       1, 'Send Teams notifications for high-severity exceptions'),
    ('AUTO_NOTIFY_EMAIL',       0, 'Send email notifications for exceptions'),
    ('EBILLING_INTEGRATION',    0, 'Enable direct eBilling vendor integration'),
    ('PMS_INTEGRATION',         0, 'Enable practice management system integration');

-- ============================================================================
-- USERS (demo)
-- ============================================================================

INSERT INTO dbo.Users (Email, DisplayName, RoleCode) VALUES
    ('admin@lawfirm.com',          'Sarah Chen',       'Admin'),
    ('m.rodriguez@lawfirm.com',    'Maria Rodriguez',  'FinanceOps'),
    ('j.patel@lawfirm.com',        'Jay Patel',        'FinanceOps'),
    ('l.thompson@lawfirm.com',     'Lisa Thompson',    'Billing'),
    ('d.kim@lawfirm.com',          'David Kim',        'Billing'),
    ('r.jones@lawfirm.com',        'Rachel Jones',     'Rates'),
    ('t.nguyen@lawfirm.com',       'Tom Nguyen',       'Rates'),
    ('cfo@lawfirm.com',            'James Wright',     'Viewer');

-- ============================================================================
-- MATTERS (10 realistic demo matters)
-- ============================================================================

INSERT INTO dbo.Matters (MatterNumber, MatterName, ClientName, ClientNumber, ResponsibleLawyer, PracticeGroup, Office, MatterOpenDate, OverallPosture) VALUES
    ('100001-001', 'Acme Corp v. Beta Industries — Patent Infringement',    'Acme Corporation',         'C-1001', 'Katherine Walsh',   'IP Litigation',        'New York',     '2026-01-15', 'READY'),
    ('100002-001', 'Global Bank Regulatory Inquiry',                        'Global Bank PLC',          'C-1002', 'Michael Torres',     'Financial Regulatory', 'Washington',   '2026-02-01', 'READY_MONITORED'),
    ('100003-001', 'TechStart Series B Financing',                          'TechStart Inc.',           'C-1003', 'Amanda Liu',         'Corporate/M&A',       'San Francisco','2026-02-10', 'READY_EXCEPTIONS'),
    ('100004-001', 'MegaCorp Antitrust Investigation',                      'MegaCorp Holdings',        'C-1004', 'Robert Singh',       'Antitrust',           'Chicago',      '2026-02-20', 'RESTRICTED'),
    ('100005-001', 'Clearwater Environmental Remediation',                  'Clearwater Energy LLC',    'C-1005', 'Jennifer Park',      'Environmental',       'Houston',      '2026-03-01', 'ESCALATION_REQUIRED'),
    ('100006-001', 'Pinnacle Healthcare Merger',                            'Pinnacle Health Systems',  'C-1006', 'David Chen',         'Corporate/M&A',       'New York',     '2026-03-03', 'READY_MONITORED'),
    ('100007-001', 'Sterling Real Estate Portfolio Acquisition',            'Sterling REIT',            'C-1007', 'Priya Sharma',       'Real Estate',         'Los Angeles',  '2026-03-05', 'RESTRICTED'),
    ('100008-001', 'NovaTech Employment Arbitration',                       'NovaTech Solutions',       'C-1008', 'James Martinez',     'Labor & Employment',  'Dallas',       '2026-03-07', 'READY'),
    ('100009-001', 'United Insurance Coverage Dispute',                     'United Insurance Group',   'C-1009', 'Helen Zhao',         'Insurance',           'Boston',       '2026-03-09', 'READY_EXCEPTIONS'),
    ('100010-001', 'Apex Pharma FDA Advisory',                              'Apex Pharmaceuticals',     'C-1010', 'Christopher Lee',    'Life Sciences',       'Washington',   '2026-03-11', 'READY_MONITORED');

-- ============================================================================
-- READINESS DIMENSIONS (for all 10 matters × 5 dimensions = 50 rows)
-- ============================================================================

-- Matter 1: Acme Corp — fully ready
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (1, 'COMMERCIAL', 'EXISTING_EL_COVERS',   'Green'),
    (1, 'GUIDELINE',  'OCG_PROCESSED',         'Green'),
    (1, 'RATE',       'STANDARD_RATE',          'Green'),
    (1, 'STAFFING',   'NO_RISK_KNOWN',          'Green'),
    (1, 'EBILLING',   'READY',                  'Green');

-- Matter 2: Global Bank — ready but OCG not yet known
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (2, 'COMMERCIAL', 'EXISTING_EL_COVERS',       'Green'),
    (2, 'GUIDELINE',  'NO_OCG_KNOWN',              'Unknown'),
    (2, 'RATE',       'STANDARD_RATE',              'Green'),
    (2, 'STAFFING',   'NO_RISK_KNOWN',              'Green'),
    (2, 'EBILLING',   'EBILLING_EXPECTED',           'Amber');

-- Matter 3: TechStart — rate setup in progress, exception open
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (3, 'COMMERCIAL', 'MASTER_AGREEMENT_COVERS',   'Green'),
    (3, 'GUIDELINE',  'OCG_PROCESSED',              'Green'),
    (3, 'RATE',       'RATE_SETUP_IN_PROGRESS',     'Amber'),
    (3, 'STAFFING',   'NO_RISK_KNOWN',              'Green'),
    (3, 'EBILLING',   'NOT_APPLICABLE',              'Green');

-- Matter 4: MegaCorp — commercial unclear, OCG with restrictions
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (4, 'COMMERCIAL', 'BASIS_UNCLEAR',              'Amber'),
    (4, 'GUIDELINE',  'OCG_MATERIAL_RESTRICTIONS',  'Amber'),
    (4, 'RATE',       'SPECIAL_RATES_REQUIRED',     'Amber'),
    (4, 'STAFFING',   'TK_APPROVAL_REQUIRED',       'Amber'),
    (4, 'EBILLING',   'SETUP_PENDING',               'Amber');

-- Matter 5: Clearwater — multiple reds, escalation required
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (5, 'COMMERCIAL', 'NEW_EL_REQUIRED',            'Red'),
    (5, 'GUIDELINE',  'OCG_EXPECTED_NOT_RECEIVED',  'Amber'),
    (5, 'RATE',       'RATE_MISMATCH',               'Red'),
    (5, 'STAFFING',   'LATE_CYCLE_EXCEPTION',        'Red'),
    (5, 'EBILLING',   'SUBMISSION_RISK',              'Red');

-- Matter 6: Pinnacle — mostly green, one unknown
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (6, 'COMMERCIAL', 'MASTER_AGREEMENT_COVERS',   'Green'),
    (6, 'GUIDELINE',  'NO_OCG_KNOWN',              'Unknown'),
    (6, 'RATE',       'STANDARD_RATE',              'Green'),
    (6, 'STAFFING',   'NO_RISK_KNOWN',              'Green'),
    (6, 'EBILLING',   'NOT_APPLICABLE',              'Green');

-- Matter 7: Sterling — EL needed, rates pending, ebilling pending
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (7, 'COMMERCIAL', 'NEW_EL_REQUIRED',            'Red'),
    (7, 'GUIDELINE',  'OCG_RECEIVED_NOT_PROCESSED', 'Amber'),
    (7, 'RATE',       'CLIENT_APPROVAL_PENDING',    'Amber'),
    (7, 'STAFFING',   'NEW_TK_DETECTED',            'Amber'),
    (7, 'EBILLING',   'CLIENT_APPROVAL_PENDING',     'Amber');

-- Matter 8: NovaTech — fully ready
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (8, 'COMMERCIAL', 'EXISTING_EL_COVERS',   'Green'),
    (8, 'GUIDELINE',  'OCG_PROCESSED',         'Green'),
    (8, 'RATE',       'STANDARD_RATE',          'Green'),
    (8, 'STAFFING',   'CLEARED',                'Green'),
    (8, 'EBILLING',   'NOT_APPLICABLE',          'Green');

-- Matter 9: United Insurance — ready with rate exception
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (9, 'COMMERCIAL', 'EXISTING_EL_COVERS',       'Green'),
    (9, 'GUIDELINE',  'OCG_PROCESSED',              'Green'),
    (9, 'RATE',       'TIME_BEFORE_RATE',            'Red'),
    (9, 'STAFFING',   'TK_RATE_NOT_APPROVED',       'Red'),
    (9, 'EBILLING',   'READY',                       'Green');

-- Matter 10: Apex Pharma — mostly ready, awaiting determination
INSERT INTO dbo.ReadinessDimensions (MatterId, DimensionCode, StatusCode, RiskLevel) VALUES
    (10, 'COMMERCIAL', 'AWAITING_DETERMINATION',    'Unknown'),
    (10, 'GUIDELINE',  'OCG_PROCESSED',              'Green'),
    (10, 'RATE',       'STANDARD_RATE',              'Green'),
    (10, 'STAFFING',   'NO_RISK_KNOWN',              'Green'),
    (10, 'EBILLING',   'EBILLING_EXPECTED',           'Amber');

-- ============================================================================
-- EXCEPTIONS
-- ============================================================================

INSERT INTO dbo.Exceptions (MatterId, ExceptionTypeCode, DimensionCode, Severity, Status, OwnerRole, Summary, DueDate) VALUES
    -- Matter 3: Rate exception
    (3, 'RATE_MISMATCH',       'RATE',      'Medium',   'Open',         'Rates',        'Special rates for Series B financing need to be set up; standard rates applied temporarily', '2026-03-20'),
    -- Matter 4: Multiple exceptions
    (4, 'COMMERCIAL_UNCLEAR',  'COMMERCIAL','Medium',   'InProgress',   'FinanceOps',   'Antitrust engagement structure unclear — may need separate EL per jurisdiction', '2026-03-15'),
    (4, 'OCG_RESTRICTIONS',    'GUIDELINE', 'High',     'Open',         'Billing',      'MegaCorp OCG restricts certain timekeeper levels; need to map staffing plan', '2026-03-18'),
    (4, 'TK_NOT_APPROVED',     'STAFFING',  'Medium',   'Open',         'Rates',        'Two associates not yet approved on MegaCorp panel', '2026-03-17'),
    -- Matter 5: Critical — escalation path
    (5, 'EL_REQUIRED_MISSING', 'COMMERCIAL','Critical', 'Escalated',    'FinanceOps',   'No engagement letter received; time already being billed', '2026-03-12'),
    (5, 'RATE_MISMATCH',       'RATE',      'High',     'Open',         'Rates',        'Rate card from 2024 applied; 2026 rates not agreed', NULL),
    (5, 'LATE_CYCLE_STAFFING', 'STAFFING',  'High',     'Open',         'FinanceOps',   'Two new partners added mid-cycle without client approval', '2026-03-14'),
    (5, 'PREBILL_BLOCKER',     'EBILLING',  'Critical', 'Escalated',    'FinanceOps',   'Prebill milestone reached with 4 unresolved exceptions', '2026-03-12'),
    -- Matter 7: New matter blockers
    (7, 'EL_REQUIRED_MISSING', 'COMMERCIAL','High',     'Open',         'FinanceOps',   'Sterling REIT requires new EL for portfolio acquisition', '2026-03-20'),
    (7, 'OCG_NOT_PROCESSED',   'GUIDELINE', 'Medium',   'Open',         'Billing',      'OCG received 3/5 — needs processing', '2026-03-16'),
    (7, 'TK_NOT_APPROVED',     'STAFFING',  'Medium',   'Open',         'Rates',        'New associate Priya Sharma detected on matter; rate approval pending', '2026-03-19'),
    -- Matter 9: Rate/staffing exceptions
    (9, 'TIME_BEFORE_RATE',    'RATE',      'Critical', 'Open',         'Rates',        'Partner billed 8hrs before rate approval finalized for United Insurance', '2026-03-13'),
    (9, 'TK_RATE_MISSING',     'STAFFING',  'High',     'Open',         'Rates',        'Associate rate not approved; 12hrs already posted', '2026-03-14'),
    -- Matter 10: Minor amber
    (10,'COMMERCIAL_UNCLEAR',  'COMMERCIAL','Low',      'Open',         'FinanceOps',   'Apex engagement basis not yet determined — prior work under master agreement', '2026-03-25');

-- Update open exception counts
UPDATE m SET OpenExceptionCount = (
    SELECT COUNT(*) FROM dbo.Exceptions e
    WHERE e.MatterId = m.MatterId
    AND e.Status NOT IN ('Resolved','Closed','Overridden')
)
FROM dbo.Matters m;

-- ============================================================================
-- EVENTS (sample history)
-- ============================================================================

INSERT INTO dbo.Events (MatterId, EventTypeCode, EventData, EventSource, IsProcessed, ProcessedAt, CreatedAt) VALUES
    -- Matter 1: clean lifecycle
    (1, 'MATTER_CREATED',              '{"source":"PMS"}',                                                     'Simulator', 1, '2026-01-15 09:00:00', '2026-01-15 09:00:00'),
    (1, 'ENGAGEMENT_BASIS_UPDATED',    '{"basis":"existing_el","elRef":"EL-2024-1001"}',                       'Simulator', 1, '2026-01-16 10:00:00', '2026-01-16 10:00:00'),
    (1, 'OCG_RECEIVED',                '{"client":"Acme Corporation","docRef":"OCG-ACME-2025"}',               'Simulator', 1, '2026-01-20 14:00:00', '2026-01-20 14:00:00'),
    (1, 'OCG_PROCESSED',               '{"restrictions":"none"}',                                              'Simulator', 1, '2026-01-22 11:00:00', '2026-01-22 11:00:00'),
    -- Matter 4: complex lifecycle
    (4, 'MATTER_CREATED',              '{"source":"PMS"}',                                                     'Simulator', 1, '2026-02-20 09:00:00', '2026-02-20 09:00:00'),
    (4, 'OCG_RECEIVED',                '{"client":"MegaCorp Holdings","docRef":"OCG-MEGA-2026"}',              'Simulator', 1, '2026-02-25 16:00:00', '2026-02-25 16:00:00'),
    (4, 'OCG_PROCESSED_RESTRICTIONS',  '{"restrictions":["no_first_year_associates","cap_on_paralegal_rate"]}','Simulator', 1, '2026-03-01 10:00:00', '2026-03-01 10:00:00'),
    (4, 'NEW_TK_DETECTED',            '{"timekeepers":["Associate A. Williams","Associate B. Garcia"]}',      'Simulator', 1, '2026-03-05 08:30:00', '2026-03-05 08:30:00'),
    -- Matter 5: escalation scenario
    (5, 'MATTER_CREATED',              '{"source":"PMS"}',                                                     'Simulator', 1, '2026-03-01 09:00:00', '2026-03-01 09:00:00'),
    (5, 'NEW_TK_DETECTED',            '{"timekeepers":["Partner J. Adams","Partner K. Brown"]}',              'Simulator', 1, '2026-03-07 14:00:00', '2026-03-07 14:00:00'),
    (5, 'RATE_APPROVAL_UPDATED',       '{"status":"mismatch","detail":"2024 rates applied, 2026 not agreed"}', 'Simulator', 1, '2026-03-08 10:00:00', '2026-03-08 10:00:00'),
    (5, 'PREBILL_MILESTONE',           '{"period":"2026-02","deadline":"2026-03-12"}',                         'Simulator', 1, '2026-03-10 09:00:00', '2026-03-10 09:00:00'),
    -- Matter 7: in-progress
    (7, 'MATTER_CREATED',              '{"source":"PMS"}',                                                     'Simulator', 1, '2026-03-05 09:00:00', '2026-03-05 09:00:00'),
    (7, 'OCG_RECEIVED',                '{"client":"Sterling REIT","docRef":"OCG-STER-2026"}',                  'Simulator', 1, '2026-03-05 16:00:00', '2026-03-05 16:00:00'),
    (7, 'NEW_TK_DETECTED',            '{"timekeepers":["Associate P. Sharma"]}',                              'Simulator', 1, '2026-03-08 11:00:00', '2026-03-08 11:00:00');

-- ============================================================================
-- AUDIT ENTRIES (sample)
-- ============================================================================

INSERT INTO dbo.AuditEntries (MatterId, Action, EntityType, EntityId, OldValue, NewValue, Rationale, PerformedBy, PerformedAt) VALUES
    (1, 'Posture changed',     'Matter',    1, '{"posture":"RESTRICTED"}',     '{"posture":"READY"}',              'All readiness dimensions green',                           1, '2026-01-22 11:30:00'),
    (4, 'Exception created',   'Exception', 2, NULL,                           '{"type":"COMMERCIAL_UNCLEAR"}',    'Antitrust engagement structure requires clarification',     2, '2026-02-22 09:00:00'),
    (4, 'Exception created',   'Exception', 3, NULL,                           '{"type":"OCG_RESTRICTIONS"}',      'OCG processed — material restrictions identified',          4, '2026-03-01 10:30:00'),
    (5, 'Severity escalated',  'Exception', 5, '{"severity":"High"}',          '{"severity":"Critical"}',          'Prebill milestone reached with unresolved commercial block',2, '2026-03-10 09:30:00'),
    (5, 'Posture changed',     'Matter',    5, '{"posture":"RESTRICTED"}',     '{"posture":"ESCALATION_REQUIRED"}','Multiple critical exceptions at prebill deadline',          2, '2026-03-10 09:35:00');

-- ============================================================================
-- DOCUMENT SIGNALS (sample)
-- ============================================================================

INSERT INTO dbo.DocumentSignals (MatterId, DocumentType, DocumentReference, SignalStatus, ReceivedDate, ProcessedDate) VALUES
    (1, 'EngagementLetter',    'EL-2024-1001',     'Processed',        '2024-06-15', '2024-06-16'),
    (1, 'OCG',                 'OCG-ACME-2025',    'Processed',        '2026-01-20', '2026-01-22'),
    (4, 'OCG',                 'OCG-MEGA-2026',    'Processed',        '2026-02-25', '2026-03-01'),
    (5, 'EngagementLetter',    NULL,               'Pending',          NULL,         NULL),
    (7, 'EngagementLetter',    NULL,               'Pending',          NULL,         NULL),
    (7, 'OCG',                 'OCG-STER-2026',    'Received',         '2026-03-05', NULL),
    (8, 'EngagementLetter',    'EL-2025-1008',     'Processed',        '2025-11-01', '2025-11-02'),
    (9, 'EngagementLetter',    'EL-2025-1009',     'Processed',        '2025-08-20', '2025-08-21'),
    (9, 'OCG',                 'OCG-UNIT-2025',    'Processed',        '2025-09-01', '2025-09-05');
