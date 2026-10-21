-- =============================================================================
-- Solution: OpenRTB Analyst Agent — Agent and CoWork Setup
-- =============================================================================
-- Executed AFTER semantic_view creation confirms OPENRTB_ANALYTICS exists.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;

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
