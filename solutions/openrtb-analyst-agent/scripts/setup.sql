-- =============================================================================
-- Solution: OpenRTB Analyst Agent
-- Industry: Advertising & MarTech
-- Database: SF_SOLUTIONS
-- Schemas:  OPENRTB_ANALYTICS
-- =============================================================================
-- Programmatic advertising analytics with Cortex Agent.
-- Demonstrates: Dynamic Tables, Semantic Views, Snowflake Intelligence Agent.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Shared infrastructure (idempotent)
CREATE DATABASE IF NOT EXISTS SF_SOLUTIONS;
CREATE WAREHOUSE IF NOT EXISTS SF_SOLUTIONS_WH
WITH WAREHOUSE_SIZE = 'LARGE'
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE;

USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;

-- Schema creation
CREATE SCHEMA IF NOT EXISTS OPENRTB_ANALYTICS;
USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;

-- =============================================================================
-- Base Tables: Raw pre-aggregated hourly bid and auction data
-- =============================================================================

CREATE OR REPLACE TABLE OPENRTB_BIDS (
__TIME TIMESTAMP_NTZ NOT NULL,
ADOMAIN VARCHAR,
ADVERTISER_NAME VARCHAR,
CAMPAIGN_NAME VARCHAR,
APP_OR_SITE VARCHAR,
APP_SITE_DOMAIN VARCHAR,
APP_SITE_NAME VARCHAR,
PUB_NAME VARCHAR,
DEVICE_TYPE VARCHAR,
DEVICE_OS VARCHAR,
DEVICE_REGION VARCHAR,
PLATFORM_BROWSER VARCHAR,
AUCTION_TYPE VARCHAR,
BID_FLOOR_BUCKET VARCHAR,
PLACEMENT_TYPE VARCHAR,
CREATIVE_TYPE VARCHAR,
BID_CNT NUMBER DEFAULT 0,
IMP_CNT NUMBER DEFAULT 0,
CLICK_REG_CNT NUMBER DEFAULT 0,
MEDIA_SPEND_USD FLOAT DEFAULT 0,
BID_PRICE_USD FLOAT DEFAULT 0,
BID_FLOOR FLOAT DEFAULT 0,
HAS_BID_FLOOR_CNT NUMBER DEFAULT 0,
VIDEO_START_CNT NUMBER DEFAULT 0,
VIDEO_COMPLETE_CNT NUMBER DEFAULT 0,
SSP_EXCHANGE VARCHAR,
SUPPLY_PATH_TYPE VARCHAR,
INTERMEDIARY_COUNT NUMBER DEFAULT 1,
SUPPLY_COST_PCT FLOAT DEFAULT 0,
CLEARING_PRICE_USD FLOAT DEFAULT 0,
BOT_SCORE FLOAT,
SUSPICIOUS_FLAG NUMBER DEFAULT 0,
DATACENTER_FLAG NUMBER DEFAULT 0,
VIEWABLE_IMP_CNT NUMBER DEFAULT 0,
VIEWABILITY_RATE FLOAT DEFAULT 0
);

CREATE OR REPLACE TABLE OPENRTB_AUCTIONS (
__TIME TIMESTAMP_NTZ NOT NULL,
APP_SITE_NAME VARCHAR,
APP_SITE_DOMAIN VARCHAR,
PUB_NAME VARCHAR,
APP_SITE_CAT VARCHAR,
AD_SIZE VARCHAR,
DEVICE_REGION VARCHAR,
DEVICE_OS VARCHAR,
DEVICE_TYPE VARCHAR,
PLATFORM_BROWSER VARCHAR,
BID_FLOOR_BUCKET VARCHAR,
PLACEMENT_TYPE VARCHAR,
AUCTION_TYPE VARCHAR,
APP_OR_SITE VARCHAR,
AD_POSITION VARCHAR,
BID_REQUEST_CNT NUMBER DEFAULT 0,
BID_FLOOR FLOAT DEFAULT 0,
HAS_BID_FLOOR_CNT NUMBER DEFAULT 0
);

-- =============================================================================
-- Dynamic Tables: Hourly aggregation for dashboard and agent queries
-- =============================================================================

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_BIDS_HOURLY
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('hour', __TIME) AS HOUR_TS,
ADOMAIN,
ADVERTISER_NAME,
CAMPAIGN_NAME,
APP_OR_SITE,
APP_SITE_DOMAIN,
APP_SITE_NAME,
PUB_NAME,
DEVICE_TYPE,
DEVICE_OS,
DEVICE_REGION,
PLATFORM_BROWSER,
AUCTION_TYPE,
BID_FLOOR_BUCKET,
PLACEMENT_TYPE,
CREATIVE_TYPE,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(CLICK_REG_CNT) AS TOTAL_CLICKS,
SUM(MEDIA_SPEND_USD) AS TOTAL_SPEND_USD,
SUM(BID_PRICE_USD) AS TOTAL_BID_PRICE_USD,
SUM(BID_FLOOR) AS TOTAL_BID_FLOOR,
SUM(HAS_BID_FLOOR_CNT) AS TOTAL_HAS_FLOOR,
SUM(VIDEO_START_CNT) AS TOTAL_VIDEO_STARTS,
SUM(VIDEO_COMPLETE_CNT) AS TOTAL_VIDEO_COMPLETES,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT)
ELSE 0 END AS WIN_RATE,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(CLICK_REG_CNT)::FLOAT / SUM(IMP_CNT)
ELSE 0 END AS CTR,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(MEDIA_SPEND_USD) / 1000.0 / SUM(IMP_CNT)
ELSE 0 END AS ECPM,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(BID_PRICE_USD) / 1000.0 / SUM(BID_CNT)
ELSE 0 END AS AVG_BID_PRICE,
CASE WHEN SUM(HAS_BID_FLOOR_CNT) > 0
THEN SUM(BID_FLOOR) / SUM(HAS_BID_FLOOR_CNT)
ELSE 0 END AS AVG_BID_FLOOR,
CASE WHEN SUM(VIDEO_START_CNT) > 0
THEN SUM(VIDEO_COMPLETE_CNT)::FLOAT / SUM(VIDEO_START_CNT)
ELSE 0 END AS VIDEO_COMPLETION_RATE,
SUM(CLEARING_PRICE_USD) AS TOTAL_CLEARING_PRICE_USD,
AVG(SUPPLY_COST_PCT) AS AVG_SUPPLY_COST,
SUM(SUSPICIOUS_FLAG) AS SUSPICIOUS_COUNT,
AVG(BOT_SCORE) AS AVG_BOT_SCORE,
SUM(VIEWABLE_IMP_CNT) AS TOTAL_VIEWABLE_IMPRESSIONS,
AVG(VIEWABILITY_RATE) AS AVG_VIEWABILITY,
COUNT(*) AS ROW_COUNT
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_AUCTIONS_HOURLY
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('hour', __TIME) AS HOUR_TS,
APP_SITE_NAME,
APP_SITE_DOMAIN,
PUB_NAME,
APP_SITE_CAT,
AD_SIZE,
CASE WHEN DEVICE_REGION ILIKE '%/%'
THEN SPLIT_PART(DEVICE_REGION, '/', 2)
ELSE 'Unknown' END AS DEVICE_STATE,
CASE WHEN DEVICE_REGION ILIKE '%/%'
THEN SPLIT_PART(DEVICE_REGION, '/', 1)
ELSE 'Unknown' END AS DEVICE_COUNTRY,
DEVICE_OS,
DEVICE_TYPE,
PLATFORM_BROWSER,
BID_FLOOR_BUCKET,
PLACEMENT_TYPE,
AUCTION_TYPE,
APP_OR_SITE,
AD_POSITION,
SUM(BID_REQUEST_CNT) AS TOTAL_REQUESTS,
SUM(BID_FLOOR) AS TOTAL_BID_FLOOR,
SUM(HAS_BID_FLOOR_CNT) AS TOTAL_HAS_FLOOR,
CASE WHEN SUM(HAS_BID_FLOOR_CNT) > 0
THEN SUM(BID_FLOOR) / SUM(HAS_BID_FLOOR_CNT)
ELSE 0 END AS AVG_BID_FLOOR,
SUM(BID_REQUEST_CNT) / 86400.0 AS QPS_1D,
COUNT(*) AS ROW_COUNT
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_AUCTIONS
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_EXECUTIVE_DAILY
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('day', __TIME) AS DAY_TS,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(CLICK_REG_CNT) AS TOTAL_CLICKS,
SUM(MEDIA_SPEND_USD) / 1000.0 AS TOTAL_SPEND,
SUM(VIDEO_START_CNT) AS TOTAL_VIDEO_STARTS,
SUM(VIDEO_COMPLETE_CNT) AS TOTAL_VIDEO_COMPLETES,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT) ELSE 0 END AS WIN_RATE,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(CLICK_REG_CNT)::FLOAT / SUM(IMP_CNT) ELSE 0 END AS CTR,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(MEDIA_SPEND_USD) / 1000.0 / SUM(IMP_CNT) ELSE 0 END AS ECPM,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(BID_PRICE_USD) / 1000.0 / SUM(BID_CNT) ELSE 0 END AS AVG_BID_PRICE,
CASE WHEN SUM(HAS_BID_FLOOR_CNT) > 0
THEN SUM(BID_FLOOR) / SUM(HAS_BID_FLOOR_CNT) ELSE 0 END AS AVG_BID_FLOOR
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_ADVERTISER_PERFORMANCE
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('day', __TIME) AS DAY_TS,
ADVERTISER_NAME,
ADOMAIN,
SUM(MEDIA_SPEND_USD) / 1000.0 AS TOTAL_SPEND,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(CLICK_REG_CNT) AS TOTAL_CLICKS,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(CLICK_REG_CNT)::FLOAT / SUM(IMP_CNT) ELSE 0 END AS CTR,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(MEDIA_SPEND_USD) / 1000.0 / SUM(IMP_CNT) ELSE 0 END AS ECPM,
SUM(VIDEO_START_CNT) AS TOTAL_VIDEO_STARTS,
SUM(VIDEO_COMPLETE_CNT) AS TOTAL_VIDEO_COMPLETES
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1, 2, 3;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_SPEND_BY_DEVICE
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('hour', __TIME) AS HOUR_TS,
DEVICE_TYPE,
SUM(MEDIA_SPEND_USD) / 1000.0 AS TOTAL_SPEND,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1, 2;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_WINRATE_BY_FLOOR
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
BID_FLOOR_BUCKET,
AUCTION_TYPE,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT) ELSE 0 END AS WIN_RATE
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1, 2;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_SPO_ANALYSIS
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
SSP_EXCHANGE,
SUPPLY_PATH_TYPE,
PUB_NAME,
COUNT(*) AS TOTAL_ROWS,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(MEDIA_SPEND_USD) AS TOTAL_SPEND_USD,
SUM(CLEARING_PRICE_USD) AS TOTAL_CLEARING_PRICE_USD,
AVG(SUPPLY_COST_PCT) AS AVG_SUPPLY_COST_PCT,
AVG(INTERMEDIARY_COUNT) AS AVG_INTERMEDIARY_COUNT,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT) ELSE 0 END AS WIN_RATE,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(MEDIA_SPEND_USD) / SUM(IMP_CNT) ELSE 0 END AS ECPM,
CASE WHEN SUM(MEDIA_SPEND_USD) > 0
THEN SUM(CLEARING_PRICE_USD) / SUM(MEDIA_SPEND_USD)
ELSE 0 END AS CLEARING_EFFICIENCY
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
WHERE SSP_EXCHANGE IS NOT NULL
GROUP BY 1, 2, 3;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_FRAUD_INDICATORS
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('day', __TIME) AS DAY_TS,
DEVICE_TYPE,
PUB_NAME,
EXTRACT(HOUR FROM __TIME) AS HOUR_OF_DAY,
COUNT(*) AS TOTAL_ROWS,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(CLICK_REG_CNT) AS TOTAL_CLICKS,
SUM(SUSPICIOUS_FLAG) AS SUSPICIOUS_COUNT,
SUM(DATACENTER_FLAG) AS DATACENTER_COUNT,
AVG(BOT_SCORE) AS AVG_BOT_SCORE,
MAX(BOT_SCORE) AS MAX_BOT_SCORE,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(CLICK_REG_CNT)::FLOAT / SUM(IMP_CNT) ELSE 0 END AS CTR,
CASE WHEN COUNT(*) > 0
THEN SUM(SUSPICIOUS_FLAG)::FLOAT / COUNT(*) ELSE 0 END AS SUSPICIOUS_RATE
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
WHERE BOT_SCORE IS NOT NULL
GROUP BY 1, 2, 3, 4;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_BID_LANDSCAPE
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DEVICE_TYPE,
DEVICE_REGION,
PLACEMENT_TYPE,
COUNT(*) AS TOTAL_ROWS,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(MEDIA_SPEND_USD) / 1000.0 AS TOTAL_SPEND,
AVG(BID_PRICE_USD / NULLIF(BID_CNT, 0)) / 1000.0 AS AVG_BID_PRICE,
AVG(CLEARING_PRICE_USD / NULLIF(IMP_CNT, 0)) / 1000.0 AS AVG_CLEARING_PRICE,
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY
CASE WHEN IMP_CNT > 0
THEN CLEARING_PRICE_USD / IMP_CNT / 1000.0 END
) AS P25_CLEARING_PRICE,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY
CASE WHEN IMP_CNT > 0
THEN CLEARING_PRICE_USD / IMP_CNT / 1000.0 END
) AS MEDIAN_CLEARING_PRICE,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY
CASE WHEN IMP_CNT > 0
THEN CLEARING_PRICE_USD / IMP_CNT / 1000.0 END
) AS P75_CLEARING_PRICE,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT) ELSE 0 END AS WIN_RATE,
AVG(VIEWABILITY_RATE) AS AVG_VIEWABILITY
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
WHERE CLEARING_PRICE_USD > 0
GROUP BY 1, 2, 3;

CREATE OR REPLACE DYNAMIC TABLE OPENRTB_ADVERTISER_DAILY
TARGET_LAG = '1 hour'
WAREHOUSE = SF_SOLUTIONS_WH
REFRESH_MODE = FULL
INITIALIZE = ON_CREATE
AS
SELECT
DATE_TRUNC('day', __TIME) AS DAY_TS,
ADVERTISER_NAME,
SUM(BID_CNT) AS TOTAL_BIDS,
SUM(IMP_CNT) AS TOTAL_IMPRESSIONS,
SUM(CLICK_REG_CNT) AS TOTAL_CLICKS,
SUM(MEDIA_SPEND_USD) / 1000.0 AS TOTAL_SPEND,
CASE WHEN SUM(BID_CNT) > 0
THEN SUM(IMP_CNT)::FLOAT / SUM(BID_CNT) ELSE 0 END AS WIN_RATE,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(CLICK_REG_CNT)::FLOAT / SUM(IMP_CNT) ELSE 0 END AS CTR,
CASE WHEN SUM(IMP_CNT) > 0
THEN SUM(MEDIA_SPEND_USD) / SUM(IMP_CNT) ELSE 0 END AS ECPM,
SUM(SUSPICIOUS_FLAG) AS SUSPICIOUS_COUNT,
AVG(BOT_SCORE) AS AVG_BOT_SCORE,
SUM(VIEWABLE_IMP_CNT) AS VIEWABLE_IMPRESSIONS,
AVG(VIEWABILITY_RATE) AS AVG_VIEWABILITY
FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS
GROUP BY 1, 2;

-- =============================================================================
-- Semantic View: Cortex Analyst text-to-SQL interface
-- =============================================================================

CALL SYSTEM
$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SF_SOLUTIONS.OPENRTB_ANALYTICS',
    $$
name: openrtb_analytics
description: >
  Programmatic advertising analytics for OpenRTB 2.6 bid and auction data.
  Covers DSP bid performance, SSP auction supply, advertiser spend, device
  targeting, win rates, and bid floor analysis.

tables:
  - name: bids
    description: >
      Hourly aggregated DSP bid data with spend, impressions, clicks, video
      metrics, and derived rates (win rate, CTR, eCPM).
    base_table:
      database: SF_SOLUTIONS
      schema: OPENRTB_ANALYTICS
      table: OPENRTB_BIDS_HOURLY

    time_dimensions:
      - name: hour_ts
        synonyms: ["hour", "timestamp", "time", "date", "when", "period"]
        description: "Hour bucket for bid aggregation"
        expr: HOUR_TS
        data_type: TIMESTAMP_NTZ

    dimensions:
      - name: advertiser_domain
        synonyms: ["adomain", "domain", "ad domain"]
        description: "Advertiser top-level domain"
        expr: ADOMAIN
        data_type: VARCHAR
      - name: advertiser_name
        synonyms: ["advertiser", "brand", "company"]
        description: "Advertiser brand name"
        expr: ADVERTISER_NAME
        data_type: VARCHAR
        sample_values: ["Apex Consumer Brands", "Velocity Motors", "Summit Auto", "Starlight Media", "Horizon Studios"]
      - name: campaign_name
        synonyms: ["campaign", "campaign id"]
        description: "Campaign name from the DSP"
        expr: CAMPAIGN_NAME
        data_type: VARCHAR
      - name: app_or_site
        synonyms: ["traffic type", "environment", "channel"]
        description: "Whether inventory is App or Site (web)"
        expr: APP_OR_SITE
        data_type: VARCHAR
        is_enum: true
        sample_values: ["App", "Site"]
      - name: publisher_domain
        synonyms: ["site domain", "app domain", "publisher site"]
        description: "Publisher domain"
        expr: APP_SITE_DOMAIN
        data_type: VARCHAR
      - name: publisher_name
        synonyms: ["publisher", "pub", "site name", "app name"]
        description: "Publisher brand name"
        expr: APP_SITE_NAME
        data_type: VARCHAR
      - name: pub_name
        synonyms: ["publisher company"]
        description: "Publisher company name"
        expr: PUB_NAME
        data_type: VARCHAR
      - name: device_type
        synonyms: ["device", "device category"]
        description: "IAB device type classification"
        expr: DEVICE_TYPE
        data_type: VARCHAR
        is_enum: true
        sample_values: ["Mobile/Tablet", "Personal Computer", "Connected TV", "Phone", "Tablet"]
      - name: device_os
        synonyms: ["operating system", "os", "platform"]
        description: "Device operating system"
        expr: DEVICE_OS
        data_type: VARCHAR
        is_enum: true
        sample_values: ["iOS", "Android", "Windows", "macOS", "tvOS"]
      - name: device_region
        synonyms: ["region", "geo", "geography", "location", "state"]
        description: "Device geographic region (Country/State)"
        expr: DEVICE_REGION
        data_type: VARCHAR
      - name: browser
        synonyms: ["platform browser", "web browser"]
        description: "Browser used on the device"
        expr: PLATFORM_BROWSER
        data_type: VARCHAR
        is_enum: true
        sample_values: ["Chrome", "Safari", "Firefox", "Edge", "Samsung Internet"]
      - name: auction_type
        synonyms: ["auction", "pricing model"]
        description: "Auction pricing model"
        expr: AUCTION_TYPE
        data_type: VARCHAR
        is_enum: true
        sample_values: ["First Price", "Second Price"]
      - name: bid_floor_bucket
        synonyms: ["floor bucket", "bid floor range"]
        description: "Bid floor price bucket"
        expr: BID_FLOOR_BUCKET
        data_type: VARCHAR
      - name: placement_type
        synonyms: ["placement", "ad format"]
        description: "Ad placement format"
        expr: PLACEMENT_TYPE
        data_type: VARCHAR
        is_enum: true
        sample_values: ["Banner", "Native", "Video", "Interstitial"]
      - name: creative_type
        synonyms: ["creative", "ad type"]
        description: "Creative format type"
        expr: CREATIVE_TYPE
        data_type: VARCHAR
        is_enum: true
        sample_values: ["Display", "Video", "Rich Media"]

    facts:
      - name: total_bids
        synonyms: ["bids", "bid count"]
        description: "Total number of bids placed"
        expr: TOTAL_BIDS
        data_type: NUMBER
      - name: total_impressions
        synonyms: ["impressions", "imps", "wins"]
        description: "Total impressions won"
        expr: TOTAL_IMPRESSIONS
        data_type: NUMBER
      - name: total_clicks
        synonyms: ["clicks", "click count"]
        description: "Total registered clicks"
        expr: TOTAL_CLICKS
        data_type: NUMBER
      - name: total_spend_usd
        synonyms: ["spend", "media spend", "cost", "ad spend"]
        description: "Total media spend in USD"
        expr: TOTAL_SPEND_USD
        data_type: FLOAT
      - name: total_bid_price_usd
        synonyms: ["bid price total"]
        description: "Sum of all bid prices in USD"
        expr: TOTAL_BID_PRICE_USD
        data_type: FLOAT
      - name: total_bid_floor
        synonyms: ["floor total"]
        description: "Sum of bid floor values"
        expr: TOTAL_BID_FLOOR
        data_type: FLOAT
      - name: total_has_floor
        synonyms: ["floor count"]
        description: "Count of bids with a bid floor set"
        expr: TOTAL_HAS_FLOOR
        data_type: NUMBER
      - name: total_video_starts
        synonyms: ["video starts", "video views"]
        description: "Total video ad start events"
        expr: TOTAL_VIDEO_STARTS
        data_type: NUMBER
      - name: total_video_completes
        synonyms: ["video completes", "VCR numerator"]
        description: "Total video ad completions"
        expr: TOTAL_VIDEO_COMPLETES
        data_type: NUMBER
      - name: total_clearing_price_usd
        synonyms: ["clearing price", "settlement price"]
        description: "Sum of auction clearing prices"
        expr: TOTAL_CLEARING_PRICE_USD
        data_type: FLOAT
      - name: avg_supply_cost
        synonyms: ["supply cost", "take rate", "SSP fee"]
        description: "Average supply path cost percentage"
        expr: AVG_SUPPLY_COST
        data_type: FLOAT
      - name: suspicious_count
        synonyms: ["fraud count", "IVT count"]
        description: "Events flagged as suspicious"
        expr: SUSPICIOUS_COUNT
        data_type: NUMBER
      - name: avg_bot_score
        synonyms: ["bot score", "IVT score"]
        description: "Average bot probability score (0-1)"
        expr: AVG_BOT_SCORE
        data_type: FLOAT
      - name: total_viewable_impressions
        synonyms: ["viewable imps"]
        description: "Impressions meeting viewability threshold"
        expr: TOTAL_VIEWABLE_IMPRESSIONS
        data_type: NUMBER
      - name: avg_viewability
        synonyms: ["viewability rate", "in-view rate"]
        description: "Average viewability rate"
        expr: AVG_VIEWABILITY
        data_type: FLOAT

    metrics:
      - name: total_advertising_spend
        synonyms: ["total spend", "total cost", "total media spend"]
        description: "Total advertising spend in USD (CPM basis)"
        expr: SUM(TOTAL_SPEND_USD) / 1000.0
      - name: total_bid_count
        synonyms: ["total bids"]
        description: "Total number of bids"
        expr: SUM(TOTAL_BIDS)
      - name: total_impression_count
        synonyms: ["total impressions", "total wins"]
        description: "Total impressions won"
        expr: SUM(TOTAL_IMPRESSIONS)
      - name: total_click_count
        synonyms: ["total clicks"]
        description: "Total clicks registered"
        expr: SUM(TOTAL_CLICKS)
      - name: win_rate
        synonyms: ["win pct", "auction win rate"]
        description: "Impressions / bids"
        expr: CASE WHEN SUM(TOTAL_BIDS) > 0 THEN SUM(TOTAL_IMPRESSIONS)::FLOAT / SUM(TOTAL_BIDS) ELSE 0 END
      - name: click_through_rate
        synonyms: ["CTR", "click rate"]
        description: "Clicks / impressions"
        expr: CASE WHEN SUM(TOTAL_IMPRESSIONS) > 0 THEN SUM(TOTAL_CLICKS)::FLOAT / SUM(TOTAL_IMPRESSIONS) ELSE 0 END
      - name: effective_cpm
        synonyms: ["eCPM", "cost per mille", "CPM"]
        description: "Effective cost per 1000 impressions"
        expr: CASE WHEN SUM(TOTAL_IMPRESSIONS) > 0 THEN SUM(TOTAL_SPEND_USD) / SUM(TOTAL_IMPRESSIONS) ELSE 0 END
      - name: average_bid_price
        synonyms: ["avg bid", "mean bid price"]
        description: "Average bid price per bid in USD"
        expr: CASE WHEN SUM(TOTAL_BIDS) > 0 THEN SUM(TOTAL_BID_PRICE_USD) / 1000.0 / SUM(TOTAL_BIDS) ELSE 0 END
      - name: average_bid_floor
        synonyms: ["avg floor"]
        description: "Average bid floor"
        expr: CASE WHEN SUM(TOTAL_HAS_FLOOR) > 0 THEN SUM(TOTAL_BID_FLOOR) / SUM(TOTAL_HAS_FLOOR) ELSE 0 END
      - name: video_completion_rate
        synonyms: ["VCR"]
        description: "Video ads watched to completion"
        expr: CASE WHEN SUM(TOTAL_VIDEO_STARTS) > 0 THEN SUM(TOTAL_VIDEO_COMPLETES)::FLOAT / SUM(TOTAL_VIDEO_STARTS) ELSE 0 END
      - name: viewability_rate
        synonyms: ["viewability"]
        description: "MRC viewability threshold rate"
        expr: CASE WHEN SUM(TOTAL_IMPRESSIONS) > 0 THEN SUM(TOTAL_VIEWABLE_IMPRESSIONS)::FLOAT / SUM(TOTAL_IMPRESSIONS) ELSE 0 END
      - name: fraud_rate
        synonyms: ["IVT rate", "suspicious rate"]
        description: "Percentage of events flagged as suspicious"
        expr: CASE WHEN SUM(ROW_COUNT) > 0 THEN SUM(SUSPICIOUS_COUNT)::FLOAT / SUM(ROW_COUNT) ELSE 0 END
      - name: clearing_efficiency
        synonyms: ["clearing ratio"]
        description: "Clearing price / bid price ratio"
        expr: CASE WHEN SUM(TOTAL_SPEND_USD) > 0 THEN SUM(TOTAL_CLEARING_PRICE_USD) / SUM(TOTAL_SPEND_USD) ELSE 0 END

    filters:
      - name: last_7_days
        synonyms: ["this week", "recent"]
        description: "Last 7 days"
        expr: "HOUR_TS >= DATEADD('day', -7, CURRENT_TIMESTAMP())"
      - name: last_30_days
        synonyms: ["this month"]
        description: "Last 30 days"
        expr: "HOUR_TS >= DATEADD('day', -30, CURRENT_TIMESTAMP())"
      - name: mobile_only
        synonyms: ["mobile traffic"]
        description: "Mobile and tablet devices"
        expr: "DEVICE_TYPE IN ('Mobile/Tablet', 'Phone', 'Tablet')"
      - name: ctv_only
        synonyms: ["connected tv", "CTV", "OTT"]
        description: "Connected TV devices"
        expr: "DEVICE_TYPE = 'Connected TV'"
      - name: video_campaigns
        synonyms: ["video only"]
        description: "Video placements"
        expr: "PLACEMENT_TYPE = 'Video'"

  - name: auctions
    description: >
      Hourly aggregated SSP auction request data with request volume,
      bid floors, and QPS estimates.
    base_table:
      database: SF_SOLUTIONS
      schema: OPENRTB_ANALYTICS
      table: OPENRTB_AUCTIONS_HOURLY

    time_dimensions:
      - name: auction_hour
        synonyms: ["auction time", "request time"]
        description: "Hour bucket for auction requests"
        expr: HOUR_TS
        data_type: TIMESTAMP_NTZ

    dimensions:
      - name: auction_site_name
        synonyms: ["auction publisher", "auction site"]
        description: "Publisher site/app name"
        expr: APP_SITE_NAME
        data_type: VARCHAR
      - name: auction_pub_name
        synonyms: ["auction publisher name"]
        description: "Publisher company"
        expr: PUB_NAME
        data_type: VARCHAR
      - name: site_category
        synonyms: ["content category", "IAB category"]
        description: "IAB content category"
        expr: APP_SITE_CAT
        data_type: VARCHAR
      - name: ad_size
        synonyms: ["creative size", "banner size"]
        description: "Ad creative dimensions"
        expr: AD_SIZE
        data_type: VARCHAR
      - name: auction_device_state
        synonyms: ["state", "auction geo"]
        description: "US state of requesting device"
        expr: DEVICE_STATE
        data_type: VARCHAR
      - name: auction_device_type
        synonyms: ["auction device"]
        description: "Device type for auction requests"
        expr: DEVICE_TYPE
        data_type: VARCHAR
      - name: auction_device_os
        synonyms: ["auction os"]
        description: "OS for auction requests"
        expr: DEVICE_OS
        data_type: VARCHAR
      - name: auction_type_dim
        synonyms: ["auction pricing"]
        description: "Auction type"
        expr: AUCTION_TYPE
        data_type: VARCHAR

    facts:
      - name: total_requests
        synonyms: ["requests", "bid requests"]
        description: "Total bid requests received"
        expr: TOTAL_REQUESTS
        data_type: NUMBER
      - name: auction_bid_floor
        synonyms: ["auction floor"]
        description: "Sum of bid floor values"
        expr: TOTAL_BID_FLOOR
        data_type: FLOAT
      - name: auction_has_floor
        synonyms: ["auction floor count"]
        description: "Auctions with a bid floor"
        expr: TOTAL_HAS_FLOOR
        data_type: NUMBER

    metrics:
      - name: total_request_volume
        synonyms: ["total requests"]
        description: "Total bid requests"
        expr: SUM(TOTAL_REQUESTS)
      - name: auction_avg_bid_floor
        synonyms: ["avg auction floor"]
        description: "Average bid floor"
        expr: CASE WHEN SUM(TOTAL_HAS_FLOOR) > 0 THEN SUM(TOTAL_BID_FLOOR) / SUM(TOTAL_HAS_FLOOR) ELSE 0 END
      - name: queries_per_second
        synonyms: ["QPS"]
        description: "Estimated queries per second"
        expr: SUM(TOTAL_REQUESTS) / 86400.0

verified_queries:
  - name: top_advertisers_by_spend
    question: "Who are the top advertisers by spend?"
    use_as_onboarding_question: true
    sql: |
      SELECT advertiser_name, total_advertising_spend
      FROM openrtb_analytics
      GROUP BY advertiser_name
      ORDER BY total_advertising_spend DESC
      LIMIT 10

  - name: spend_by_device_type
    question: "How is spend distributed across device types?"
    use_as_onboarding_question: true
    sql: |
      SELECT device_type, total_advertising_spend, total_impression_count, win_rate
      FROM openrtb_analytics
      GROUP BY device_type
      ORDER BY total_advertising_spend DESC

  - name: daily_spend_trend
    question: "What is the daily spend trend over the last 7 days?"
    use_as_onboarding_question: true
    sql: |
      SELECT DATE_TRUNC('day', hour_ts) AS day, total_advertising_spend
      FROM openrtb_analytics
      WHERE hour_ts >= DATEADD('day', -7, CURRENT_TIMESTAMP())
      GROUP BY day
      ORDER BY day

  - name: ctv_performance
    question: "How is Connected TV performing compared to other devices?"
    sql: |
      SELECT device_type, total_advertising_spend, win_rate, effective_cpm, video_completion_rate
      FROM openrtb_analytics
      GROUP BY device_type
      ORDER BY total_advertising_spend DESC

  - name: supply_path_cost
    question: "What is the supply cost by device type?"
    use_as_onboarding_question: true
    sql: |
      SELECT device_type, avg_supply_cost_pct, total_advertising_spend, viewability_rate
      FROM openrtb_analytics
      GROUP BY device_type
      ORDER BY total_advertising_spend DESC
$$
);

GRANT SELECT ON SEMANTIC VIEW SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ANALYTICS
    TO ROLE PUBLIC;

-- =============================================================================
-- Cortex Agent: Snowflake Intelligence
-- =============================================================================

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

-- Output URLs
SELECT 'https://app.snowflake.com/' || LOWER(CURRENT_ORGANIZATION_NAME()) || '/'
    || LOWER(CURRENT_ACCOUNT_NAME())
    || '/#/agents/database/SF_SOLUTIONS/schema/OPENRTB_ANALYTICS/agent/OPENRTB_ANALYST/details'
    AS AGENT_URL;
