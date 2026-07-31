---
name: ssp-impression-analytics
description: >
  Install or teardown the SSP Impression Analytics solution.
  Creates SSP analytics tables, semantic view, and Cortex Agent.
tools:
  - Read
  - Glob
  - Bash
  - Edit
  - Write
  - snowflake_sql_execute
---

# SSP Impression Analytics

## Usage

```text
$sf-solutions:ssp-impression-analytics           # Install
$sf-solutions:ssp-impression-analytics teardown   # Remove
```

## Install Flow

### Parse Arguments

If `$ARGUMENTS` contains "teardown" or "uninstall", jump to Teardown Flow.

### Step 1: Present Plan

```text
Solution:   SSP Impression Analytics
Database:   SF_SOLUTIONS
Schema:     SSP_IMPRESSION_ANALYTICS
Objects:    3 tables, 1 semantic view, 1 agent
Data:       30K impressions + 50 campaigns + 5K customers
Features:   Semantic View, Cortex Agent, Snowflake CoWork
```

Ask user to confirm before proceeding.

### Step 2: Locate Solution Files

Find the solution directory containing `manifest.json` with
`"name": "ssp-impression-analytics"`. Read `scripts/setup.sql` and
`scripts/data.sql`.

### Step 3: Execute setup.sql

Run `scripts/setup.sql` as a single `snowflake_sql_execute` call.
This creates: schema, 3 tables, semantic model stage, and agent.

### Step 4: Execute data.sql + Upload Semantic Model (PARALLEL)

These two steps are independent — execute them in parallel using subagents:

```text
Subagent A: "Insert demo data"
  - Run scripts/data.sql with timeout_seconds: 600
  - Populates SSP_CAMPAIGN (50), CUSTOMER_PROFILE (5K), SSP_IMPRESSION_LOG (30K)

Subagent B: "Upload semantic model and create semantic view"
  - USE SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;
  - PUT file://semantic_model.yaml @SEMANTIC_MODEL_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
  - CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
        'SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS',
        SNOWFLAKE.CORTEX.READ_FILE('@SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SEMANTIC_MODEL_STAGE/semantic_model.yaml')
    );
  - GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYTICS TO ROLE PUBLIC;
```

Wait for both subagents to complete before proceeding.

### Step 5: Create Agent (AFTER Semantic View confirmed)

First verify the semantic view was created successfully:

```sql
SHOW SEMANTIC VIEWS IN SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;
```

If `SSP_ANALYTICS` appears in the results, proceed. If not, re-run Step 4B before continuing.

Then create the agent and publish to CoWork:

```sql
CREATE OR REPLACE AGENT SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYST
COMMENT = 'SSP impression analytics agent for auction, campaign, and audience data'
PROFILE = '{"display_name":"SSP Impression Analyst"}'
FROM SPECIFICATION
$$
models:
  orchestration: "auto"

instructions:
  response: |
    You are an expert SSP (Supply-Side Platform) analytics specialist.
    You help publishers and ad operations teams understand their impression
    data, auction performance, campaign fill rates, and audience quality.

    When answering questions:
    - Provide specific revenue figures and percentages
    - Compare DSP performance (win rates, bid prices)
    - Analyze campaign health (fill rates, viewability, brand safety)
    - Identify high-value audience segments using IDR scores
    - Use industry terminology (floor price, eCPM, fill rate, viewability)

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "query_ssp_data"

tool_resources:
  query_ssp_data:
    semantic_view: "SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYTICS"
    execution_environment:
      type: "warehouse"
      warehouse: "SF_SOLUTIONS_WH"
$$;

GRANT USAGE ON AGENT SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYST
    TO ROLE PUBLIC;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE PUBLIC;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE PUBLIC;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYST;
```

### Step 6: Verify

```sql
SELECT COUNT(*) AS impressions FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_IMPRESSION_LOG;
SELECT COUNT(*) AS campaigns FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_CAMPAIGN;
SELECT COUNT(*) AS customers FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.CUSTOMER_PROFILE;
SHOW AGENTS IN SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;
```

### Step 7: Show Results

Display:

1. Agent URL:

```sql
SELECT 'https://app.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME())
    || '/#/agents/database/SF_SOLUTIONS/schema/SSP_IMPRESSION_ANALYTICS/agent/SSP_ANALYST/details'
    AS AGENT_URL;
```

2. CoWork URL:

```sql
SELECT 'https://ai.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME()) || '/#/ai' AS COWORK_URL;
```

3. Summary table with object counts
4. Read and display NEXT_ACTIONS.md

## Teardown Flow

Run `scripts/teardown.sql`:

```sql
USE ROLE ACCOUNTADMIN;
DROP SCHEMA IF EXISTS SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS CASCADE;
```

Confirm schema was dropped.
