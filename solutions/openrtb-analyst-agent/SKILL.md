---
name: openrtb-analyst-agent
description: >
  Install or teardown the OpenRTB Analyst Agent solution.
  Creates programmatic advertising analytics with Dynamic Tables,
  Semantic View, and a Snowflake CoWork Agent.
tools:
  - Read
  - Glob
  - Bash
  - Edit
  - Write
  - snowflake_sql_execute
---

# OpenRTB Analyst Agent

## Usage

```text
$sf-solutions:openrtb-analyst-agent           # Install
$sf-solutions:openrtb-analyst-agent teardown   # Remove
```

## Install Flow

### Parse Arguments

If `$ARGUMENTS` contains "teardown" or "uninstall", jump to Teardown Flow.

### Step 1: Present Plan

```text
Solution:   OpenRTB Analyst Agent
Database:   SF_SOLUTIONS
Schema:     OPENRTB_ANALYTICS
Objects:    2 base tables, 10 dynamic tables, 1 semantic view, 1 agent
Data:       ~50K synthetic bid rows + ~20K auction rows
Features:   Dynamic Tables, Semantic View, Cortex Agent
```

Ask user to confirm before proceeding.

### Step 2: Locate Solution Files

Find the solution directory containing `manifest.json` with
`"name": "openrtb-analyst-agent"`. Read `scripts/setup.sql` and
`scripts/data.sql`.

### Step 3: Execute setup.sql

Run the full `scripts/setup.sql` as a single `snowflake_sql_execute` call.
This creates: schema, base tables, 10 dynamic tables, and semantic model stage.

### Step 4: Execute data.sql + Upload Semantic Model (PARALLEL)

These two steps are independent — execute them in parallel using subagents:

```text
Subagent A: "Insert demo data"
  - Run scripts/data.sql with timeout_seconds: 600
  - This populates OPENRTB_BIDS (50K rows) and OPENRTB_AUCTIONS (20K rows)

Subagent B: "Upload semantic model and create semantic view"
  - USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
  - PUT file://semantic_model.yaml @SEMANTIC_MODEL_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
  - CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
        'SF_SOLUTIONS.OPENRTB_ANALYTICS',
        SNOWFLAKE.CORTEX.READ_FILE('@SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE/semantic_model.yaml')
    );
  - GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYTICS TO ROLE PUBLIC;
```

Wait for both subagents to complete before proceeding.

**Why parallel:** data.sql inserts into base tables; semantic view reads from
dynamic tables (which are empty until base tables have data AND refresh).
However, the semantic view *creation* does not require data — it only needs the
dynamic table DDL to exist (already created in Step 3). So both can run safely
in parallel.

### Step 5: Create Agent (AFTER Semantic View confirmed)

First verify the semantic view was created successfully:

```sql
SHOW SEMANTIC VIEWS IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
```

If `OPENRTB_ANALYTICS` appears, proceed. If not, re-run Step 4B before continuing.

Then create the agent and publish to CoWork:

```sql
CREATE OR REPLACE AGENT SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYST
COMMENT = 'Programmatic advertising analytics agent for OpenRTB bid and auction data'
PROFILE = '{"display_name":"OpenRTB Analyst"}'
FROM SPECIFICATION
$$
models:
  orchestration: "auto"

instructions:
  response: |
    You are an expert programmatic advertising analyst with deep knowledge of
    OpenRTB 2.6, DSP/SSP mechanics, and ad tech metrics. You help users
    understand their bid performance, auction dynamics, and campaign efficiency.

    When answering questions:
    - Always provide specific numbers and percentages
    - Compare metrics across dimensions when relevant
    - Flag anomalies or notable patterns
    - Suggest optimization actions when data reveals opportunities
    - Use industry terminology correctly (eCPM, CTR, win rate, bid floor, etc.)

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "query_openrtb_data"

tool_resources:
  query_openrtb_data:
    semantic_view: "SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYTICS"
    execution_environment:
      type: "warehouse"
      warehouse: "SF_SOLUTIONS_WH"
$$;

GRANT USAGE ON AGENT SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYST
    TO ROLE PUBLIC;

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYST;
```

### Step 6: Verify

```sql
SELECT COUNT(*) AS bid_rows FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS;
SELECT COUNT(*) AS auction_rows FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_AUCTIONS;
SHOW DYNAMIC TABLES IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
SHOW AGENTS IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
```

### Step 7: Show Results

Display:

1. Agent URL:

```sql
SELECT 'https://app.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME())
    || '/#/agents/database/SF_SOLUTIONS/schema/OPENRTB_ANALYTICS/agent/OPENRTB_ANALYST/details'
    AS AGENT_URL;
```

2. Summary table with object counts
3. Read and display NEXT_ACTIONS.md

## Teardown Flow

Run `scripts/teardown.sql`:

```sql
USE ROLE ACCOUNTADMIN;
DROP SCHEMA IF EXISTS SF_SOLUTIONS.OPENRTB_ANALYTICS CASCADE;
```

Confirm schema was dropped.
