-- =============================================================================
-- Solution: SSP Impression Analytics
-- Industry: Advertising & MarTech
-- Database: SF_SOLUTIONS
-- Schemas:  SSP_IMPRESSION_ANALYTICS
-- =============================================================================
-- SSP impression analytics with identity resolution, campaign management,
-- and a Cortex Agent for natural language data exploration.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS SF_SOLUTIONS;
CREATE WAREHOUSE IF NOT EXISTS SF_SOLUTIONS_WH
    WITH WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;

CREATE SCHEMA IF NOT EXISTS SSP_IMPRESSION_ANALYTICS;
USE SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;

-- =============================================================================
-- Table 1: SSP Impression Log
-- Pre-aggregated SSP auction/impression data with DSP winners
-- =============================================================================

CREATE OR REPLACE TABLE SSP_IMPRESSION_LOG (
    IMPRESSION_LOG_ID VARCHAR(36) NOT NULL,
    CUSTOMER_ID VARCHAR(36),
    DEVICE_ID VARCHAR(36),
    AUCTION_ID VARCHAR(36),
    CAMPAIGN_ID VARCHAR(36),
    IMPRESSION_TIMESTAMP TIMESTAMP_NTZ,
    AD_FORMAT VARCHAR(50),
    AD_POSITION VARCHAR(50),
    AD_SIZE VARCHAR(20),
    INVENTORY_TYPE VARCHAR(50),
    WINNING_DSP VARCHAR(100),
    WINNING_BID_PRICE NUMBER(10, 4),
    FLOOR_PRICE NUMBER(10, 4),
    GROSS_REVENUE NUMBER(10, 4),
    NET_REVENUE NUMBER(10, 4),
    TECH_FEE NUMBER(10, 4),
    REVENUE_SHARE NUMBER(5, 4),
    VIEWABILITY_SCORE NUMBER(5, 4),
    BRAND_SAFETY_SCORE NUMBER(5, 4),
    COMPLETION_RATE NUMBER(5, 4),
    AUCTION_DURATION_MS NUMBER(38, 0),
    AUCTION_PARTICIPANTS NUMBER(38, 0),
    INTERACTION_TIME_SEC NUMBER(38, 0),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================================================
-- Table 2: SSP Campaign
-- Campaign configuration and targeting for the SSP platform
-- =============================================================================

CREATE OR REPLACE TABLE SSP_CAMPAIGN (
    CAMPAIGN_ID VARCHAR(36) NOT NULL,
    CAMPAIGN_NAME VARCHAR(255),
    CAMPAIGN_STATUS VARCHAR(20),
    CAMPAIGN_TYPE VARCHAR(50),
    DEAL_TYPE VARCHAR(50),
    INVENTORY_TYPE VARCHAR(50),
    FLOOR_PRICE NUMBER(10, 4),
    IMPRESSION_GOAL NUMBER(38, 0),
    REVENUE_GOAL NUMBER(15, 2),
    FILL_RATE_TARGET NUMBER(5, 4),
    VIEWABILITY_THRESHOLD NUMBER(5, 4),
    COMPLETION_RATE_THRESHOLD NUMBER(5, 4),
    FRAUD_PROTECTION_LEVEL VARCHAR(20),
    CAMPAIGN_START_DATE DATE,
    CAMPAIGN_END_DATE DATE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================================================
-- Table 3: Customer Profile (simplified with IDR scores)
-- Unified profile combining identity resolution provider data
-- =============================================================================

CREATE OR REPLACE TABLE CUSTOMER_PROFILE (
    CUSTOMER_ID VARCHAR(36) NOT NULL,
    FIRST_NAME VARCHAR(255),
    LAST_NAME VARCHAR(255),
    EMAIL VARCHAR(255),
    GENDER VARCHAR(50),
    AGE NUMBER(38, 0),
    CITY VARCHAR(255),
    STATE VARCHAR(50),
    ZIP_CODE VARCHAR(20),
    COUNTRY_CODE VARCHAR(2),
    CUSTOMER_SEGMENT VARCHAR(200),
    SIGNUP_DATE DATE,
    -- IDR Provider A scores
    IDR_A_ID VARCHAR(64),
    IDR_A_DIGITAL_ENGAGEMENT_SCORE FLOAT,
    IDR_A_PURCHASE_PROPENSITY FLOAT,
    IDR_A_BRAND_LOYALTY_SCORE FLOAT,
    IDR_A_IDENTITY_LINKAGE_SCORE FLOAT,
    IDR_A_HOUSEHOLD_LINKAGE_SCORE FLOAT,
    -- IDR Provider B scores
    IDR_B_ID VARCHAR(64),
    IDR_B_BRAND_AFFINITY_SCORE FLOAT,
    IDR_B_CROSS_DEVICE_LINKAGE_SCORE FLOAT,
    IDR_B_DIGITAL_ENGAGEMENT_SCORE FLOAT,
    -- SSP engagement metrics
    TOTAL_IMPRESSIONS NUMBER(18, 0),
    TOTAL_CLICKS NUMBER(38, 0),
    TOTAL_CONVERSIONS NUMBER(38, 0),
    TOTAL_SPEND_REACHED NUMBER(15, 2),
    LIFETIME_VALUE FLOAT,
    LAST_IMPRESSION_DATE TIMESTAMP_NTZ
);

-- =============================================================================
-- Stage for semantic model YAML
-- =============================================================================

CREATE STAGE IF NOT EXISTS SEMANTIC_MODEL_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for Cortex Analyst semantic model YAML';

-- =============================================================================
-- Cortex Agent
-- =============================================================================

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

-- Publish to Snowflake CoWork
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE PUBLIC;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE PUBLIC;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_ANALYST;

-- Output URLs
SELECT 'https://app.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME())
    || '/#/agents/database/SF_SOLUTIONS/schema/SSP_IMPRESSION_ANALYTICS/agent/SSP_ANALYST/details'
    AS AGENT_URL;
