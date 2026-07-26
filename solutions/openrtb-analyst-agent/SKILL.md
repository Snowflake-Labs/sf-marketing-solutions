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
This creates: schema, base tables, 10 dynamic tables, semantic model stage, and agent.

### Step 4: Execute data.sql

Run `scripts/data.sql` with `timeout_seconds: 600` (data generation may take
a few minutes due to GENERATOR + JOINs).

### Step 5: Upload Semantic Model and Create Semantic View

Upload the YAML file to the stage, then create the semantic view:

```sql
USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
PUT file://semantic_model.yaml @SEMANTIC_MODEL_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

Then call:

```sql
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SF_SOLUTIONS.OPENRTB_ANALYTICS',
    SNOWFLAKE.CORTEX.READ_FILE('@SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE/semantic_model.yaml')
);
GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYTICS TO ROLE PUBLIC;
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
