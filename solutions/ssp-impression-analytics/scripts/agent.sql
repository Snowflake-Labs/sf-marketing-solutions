-- =============================================================================
-- Solution: SSP Impression Analytics — Agent and CoWork Setup
-- =============================================================================
-- Executed AFTER semantic_view.sql creates the SSP_ANALYTICS semantic view.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;

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

SELECT 'https://app.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME())
    || '/#/agents/database/SF_SOLUTIONS/schema/SSP_IMPRESSION_ANALYTICS/agent/SSP_ANALYST/details'
    AS AGENT_URL;
