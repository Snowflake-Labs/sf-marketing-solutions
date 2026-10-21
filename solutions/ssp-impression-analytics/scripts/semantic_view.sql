-- =============================================================================
-- Solution: SSP Impression Analytics — Semantic View Creation
-- =============================================================================
-- This script is executed AFTER semantic_model.yaml has been PUT to the stage
-- by the SKILL.md installer (Step 5).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;
USE SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS',
    SNOWFLAKE.CORTEX.READ_FILE('@SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SEMANTIC_MODEL_STAGE/semantic_model.yaml')
);

GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYTICS
    TO ROLE PUBLIC;
