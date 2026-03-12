# Architecture: Matter Readiness and Billing Risk Orchestrator

## Architecture Decision Summary

**Decision:** Power Apps Canvas App + Azure SQL Database + Power Automate + Microsoft Fabric/Power BI

**Why this stack over alternatives:**

| Alternative | Why Not |
|---|---|
| Model-driven app | Too rigid for the multi-dimensional posture UX; canvas gives pixel-level control for the posture board |
| SharePoint lists as data store | Cannot handle relational integrity, complex views, or the audit trail volume at scale |
| Dataverse | Correct long-term, but adds licensing cost and DLP surface area for MVP; Azure SQL is more portable and schema-controllable |
| Custom web app (React/.NET) | Overkill for MVP; Power Apps gets us to demo faster with less infra |
| Logic Apps instead of Power Automate | Power Automate stays in the maker ecosystem; Logic Apps adds Azure subscription management overhead |

**Key architectural constraints:**
- No AI connectors assumed available (feature-flagged if present)
- Conservative DLP profile: SQL Server connector, Office 365 Outlook, Microsoft Teams, SharePoint (standard connectors only)
- No custom connectors in MVP; all integration via Azure SQL
- Event-driven logic lives in SQL + Power Automate, not in opaque AI flows

## Component Diagram

```mermaid
graph TB
    subgraph "User Layer"
        PA[Power Apps Canvas App]
        PBI[Power BI Dashboard]
    end

    subgraph "Process Layer"
        PAF[Power Automate Flows]
        RE[Rules Engine<br/>SQL Stored Procedures]
    end

    subgraph "Data Layer"
        ASQL[(Azure SQL Database)]
        FAB[Microsoft Fabric<br/>Lakehouse / Semantic Model]
    end

    subgraph "Identity"
        ENTRA[Microsoft Entra ID]
    end

    PA -->|SQL Server Connector<br/>CRUD operations| ASQL
    PA -->|Trigger flows via<br/>HTTP or button| PAF
    PAF -->|Execute SQL| ASQL
    PAF -->|Send notifications| TEAMS[Microsoft Teams]
    PAF -->|Send email| OUTLOOK[Outlook]
    ASQL -->|Mirroring or<br/>Pipeline| FAB
    FAB -->|Semantic Model| PBI
    ENTRA -->|RBAC / SSO| PA
    ENTRA -->|Row-level security| PBI
    RE -->|Lives inside| ASQL

    style PA fill:#4B0082,color:#fff
    style ASQL fill:#0078D4,color:#fff
    style PAF fill:#0066FF,color:#fff
    style FAB fill:#E87400,color:#fff
    style PBI fill:#F2C811,color:#000
    style ENTRA fill:#00A4EF,color:#fff
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "Event Sources (MVP: Manual Simulator)"
        ES1[Matter Created]
        ES2[Engagement Updated]
        ES3[OCG Received]
        ES4[Timekeeper Detected]
        ES5[Rate Updated]
        ES6[Prebill Milestone]
    end

    subgraph "Event Processing"
        EI[Event Ingestion<br/>Power Apps Form → SQL INSERT]
        RE[Rules Engine<br/>sp_EvaluateMatterReadiness]
        EX[Exception Generator<br/>sp_CreateException]
        PR[Posture Rollup<br/>sp_CalculateOverallPosture]
    end

    subgraph "State"
        MT[(Matters)]
        RD[(ReadinessDimensions)]
        EXC[(Exceptions)]
        EVT[(Events)]
        AUD[(AuditEntries)]
    end

    subgraph "Outputs"
        PB[Posture Board]
        MW[Exception Workbench]
        LD[Leadership Dashboard]
        NT[Notifications]
    end

    ES1 & ES2 & ES3 & ES4 & ES5 & ES6 --> EI
    EI --> EVT
    EI --> RE
    RE --> RD
    RE --> EX
    EX --> EXC
    RE --> PR
    PR --> MT
    RE --> AUD

    MT & RD --> PB
    EXC --> MW
    MT & EXC --> LD
    EXC --> NT
```

## Event Processing Sequence

```mermaid
sequenceDiagram
    participant U as User / Simulator
    participant PA as Power Apps
    participant SQL as Azure SQL
    participant RE as Rules Engine (SP)
    participant PAF as Power Automate
    participant T as Teams

    U->>PA: Trigger event (e.g., OCG Received)
    PA->>SQL: INSERT INTO Events
    PA->>SQL: EXEC sp_ProcessEvent @EventId
    SQL->>RE: Evaluate rules for event type
    RE->>SQL: UPDATE ReadinessDimensions
    RE->>SQL: INSERT INTO Exceptions (if triggered)
    RE->>SQL: INSERT INTO AuditEntries
    RE->>SQL: EXEC sp_CalculateOverallPosture
    RE-->>PA: Return updated posture
    PA->>PAF: Trigger notification flow (if severity >= High)
    PAF->>T: Post adaptive card to channel
    PA->>U: Refresh posture board
```

## Assumptions

1. **Azure SQL is provisioned** and accessible via the Power Platform SQL Server connector (standard connector, no premium required for on-prem gateway scenarios — but Azure SQL direct connection is standard-tier in most tenants)
2. **Power Apps per-user or per-app licensing** is available for the Finance Ops team (~20-50 users)
3. **DLP policies** allow: SQL Server connector, Office 365 Outlook, Microsoft Teams, SharePoint
4. **No custom connectors** in MVP — all complex logic pushed to SQL stored procedures
5. **Microsoft Fabric** is available for the analytics layer; if not, Power BI can connect directly to Azure SQL views
6. **Entra ID** groups exist or can be created for: `MRBRO-Admin`, `MRBRO-FinanceOps`, `MRBRO-Billing`, `MRBRO-Rates`, `MRBRO-Viewer`

## Constraints

- No real-time integration with practice management system (3E, Aderant, etc.) in MVP — event simulator replaces this
- No document parsing or OCG extraction — manual status updates only
- No AI/Copilot features unless explicitly feature-flagged
- Power Apps Canvas has a delegation limit of 2,000 rows by default (configurable to 100K in non-delegation scenarios); views and stored procedures handle server-side filtering
- All business rules are explicit, auditable, and editable in SQL — no black-box logic

## Security Architecture

```mermaid
graph TB
    subgraph "Entra ID"
        AG1[MRBRO-Admin]
        AG2[MRBRO-FinanceOps]
        AG3[MRBRO-Billing]
        AG4[MRBRO-Rates]
        AG5[MRBRO-Viewer]
    end

    subgraph "Power Apps"
        SHARE[App Sharing via Entra Groups]
        ROLE[AppRole lookup table in SQL]
    end

    subgraph "Azure SQL"
        RLS[Row-Level Security<br/>Future Enhancement]
        SPROC[Stored Procedures<br/>enforce role checks via @UserRole param]
    end

    subgraph "Power BI"
        PRLS[Power BI RLS<br/>via Entra group mapping]
    end

    AG1 & AG2 & AG3 & AG4 & AG5 --> SHARE
    SHARE --> ROLE
    ROLE --> SPROC
    AG1 & AG2 & AG3 & AG4 & AG5 --> PRLS
```

**MVP approach:** The `Users` table stores role assignments. Power Apps reads the current user's email, looks up their role, and conditionally shows/hides screens and controls. This is "soft RBAC" — sufficient for internal demo, upgradeable to Entra-backed RLS later.
