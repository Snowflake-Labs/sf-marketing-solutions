---
name: openrtb-analyst-agent
description: >
  Install or teardown the OpenRTB Analyst Agent solution.
  Creates programmatic advertising analytics with Dynamic Tables,
  Semantic View, and a Snowflake CoWork Agent.
  Usage: $sf-solutions:openrtb-analyst-agent | $sf-solutions:openrtb-analyst-agent teardown
tools:
  - snowflake_sql_execute
  - Bash
  - Read
  - Glob
  - Write
---

# OpenRTB Analyst Agent

Parse the action from `$ARGUMENTS`:
- If `$ARGUMENTS` is "install" or empty → run **Install** flow
- If `$ARGUMENTS` is "teardown" → run **Teardown** flow
- Otherwise → show usage help

## Overview

- **Industry:** Advertising & MarTech
- **Database:** SF_SOLUTIONS
- **Schema:** OPENRTB_ANALYTICS
- **Features:** Dynamic Tables, Cortex Agent, Cortex Analyst, Semantic View, Snowflake CoWork
- **Role Required:** ACCOUNTADMIN

## Install

1. Locate the sf-marketing-solutions repository:
   - Check `~/project/sf-sc/sf-marketing-solutions/`
   - Check current working directory
   - If not found: `git clone https://github.com/Snowflake-Labs/sf-marketing-solutions.git /tmp/sf-marketing-solutions`

2. Read `solutions/openrtb-analyst-agent/manifest.json`.

3. Present the installation plan:
   ```
   Solution: OpenRTB Analyst Agent v1.0.0
   Industry: Advertising & MarTech
   Database: SF_SOLUTIONS
   Schema:   OPENRTB_ANALYTICS
   Role:     ACCOUNTADMIN

   What will be created:
     - 2 base tables + 10 Dynamic Tables (~50K bid rows, ~20K auction rows)
     - Semantic View for Cortex Analyst (text-to-SQL)
     - Cortex Agent (OPENRTB_ANALYST) published to Snowflake CoWork

   Proceed with installation?
   ```

4. Wait for user confirmation.

5. Read and execute `solutions/openrtb-analyst-agent/scripts/setup.sql` as a single
   `snowflake_sql_execute` call. This creates the schema, base tables, 10 Dynamic
   Tables, and the stage.

6. Read and execute `solutions/openrtb-analyst-agent/scripts/data.sql` as a single
   `snowflake_sql_execute` call with `timeout_seconds: 600`.
   This inserts ~70K demo rows.

7. **Upload semantic model YAML (CRITICAL — agent won't work without this):**

   Step 7a — Locate the YAML file:
   - `solutions/openrtb-analyst-agent/scripts/semantic_model.yaml`

   Step 7b — Upload to stage via PUT:
   ```sql
   PUT file://<repo_path>/solutions/openrtb-analyst-agent/scripts/semantic_model.yaml
       @SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE
       AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
   ```
   Replace `<repo_path>` with the actual absolute path to the repository on disk.
   Use `USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;` in the same call.

   **If PUT fails**, read `solutions/openrtb-analyst-agent/scripts/semantic_model.yaml`,
   write its contents to `/tmp/openrtb_semantic_model.yaml` using the Write tool, then PUT:
   ```sql
   PUT file:///tmp/openrtb_semantic_model.yaml
       @SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE
       AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
   ```

   Step 7c — Verify the file is on stage:
   ```sql
   LIST @SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE;
   ```
   You MUST see `semantic_model.yaml`. If not, retry PUT before proceeding.

   Step 7d — Create the semantic view:
   ```sql
   USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
   CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
       'SF_SOLUTIONS.OPENRTB_ANALYTICS',
       SNOWFLAKE.CORTEX.READ_FILE('@SF_SOLUTIONS.OPENRTB_ANALYTICS.SEMANTIC_MODEL_STAGE/semantic_model.yaml')
   );
   GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYTICS
       TO ROLE PUBLIC;
   ```

   Step 7e — Verify semantic view was created:
   ```sql
   SHOW SEMANTIC VIEWS IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
   ```
   You MUST see `OPENRTB_ANALYTICS` in the output before proceeding.

8. Execute `solutions/openrtb-analyst-agent/scripts/agent.sql` as a SINGLE
   `snowflake_sql_execute` call. This creates the OPENRTB_ANALYST agent and
   publishes it to Snowflake CoWork.

   Verify agent was created:
   ```sql
   SHOW AGENTS IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
   ```
   You MUST see `OPENRTB_ANALYST` in the output.

9. Verify table data:
   ```sql
   SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
   FROM SF_SOLUTIONS.INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA = 'OPENRTB_ANALYTICS'
   ORDER BY TABLE_NAME;
   ```

10. **[MANDATORY — DO NOT SKIP]** Show the Agent URL. Execute this query:
    ```sql
    SELECT 'https://app.snowflake.com/'
        || LOWER(CURRENT_ORGANIZATION_NAME()) || '/' || LOWER(CURRENT_ACCOUNT_NAME())
        || '/#/agents/database/SF_SOLUTIONS/schema/OPENRTB_ANALYTICS/agent/OPENRTB_ANALYST/details'
        AS AGENT_URL;
    ```
    Display it to the user:
    ```
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Cortex Agent:
    <paste the full URL here>
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ```

11. Show final summary:
    ```
    Installation Complete: OpenRTB Analyst Agent v1.0.0

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Cortex Agent: <URL from step 10>
    CoWork:       https://ai.snowflake.com/<org>/<account>/#/ai
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Next Actions:
    1. Open the Cortex Agent URL above in Snowflake CoWork
    2. Try: "Who are the top advertisers by spend?"
    3. Try: "How does CTV performance compare to mobile?"
    4. Try: "Which SSP exchanges have the best clearing efficiency?"

    Teardown: $sf-solutions:openrtb-analyst-agent teardown
    ```

## Teardown

If `$ARGUMENTS` is "teardown":

1. Confirm with user: "This will drop the OPENRTB_ANALYTICS schema and the
   OPENRTB_ANALYST agent. Proceed?"
2. Read and execute `solutions/openrtb-analyst-agent/scripts/teardown.sql`.
3. Confirm: "OpenRTB Analyst Agent removed."

## Usage Help

```
Usage:
  $sf-solutions:openrtb-analyst-agent           — Install the solution
  $sf-solutions:openrtb-analyst-agent teardown   — Remove the solution
```
