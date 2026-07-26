-- =============================================================================
-- Solution: SSP Impression Analytics — Demo Data Generation
-- Industry: Advertising & MarTech
-- =============================================================================
-- All names are synthetic. DSP platform names (The Trade Desk, Amazon DSP) retained.
-- IDR providers anonymized as "IDR Provider A" / "IDR Provider B".
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;
USE SCHEMA SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS;

-- =============================================================================
-- SSP_CAMPAIGN: 50 synthetic campaigns
-- =============================================================================

INSERT INTO SSP_CAMPAIGN
SELECT
    UUID_STRING() AS CAMPAIGN_ID,
    'Campaign_' || SEQ4()::VARCHAR || '_' ||
        CASE UNIFORM(1, 5, RANDOM())
            WHEN 1 THEN 'Awareness'
            WHEN 2 THEN 'Performance'
            WHEN 3 THEN 'Branding'
            WHEN 4 THEN 'Retargeting'
            ELSE 'Prospecting'
        END AS CAMPAIGN_NAME,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'Active'
        WHEN 2 THEN 'Active'
        WHEN 3 THEN 'Active'
        ELSE 'Paused'
    END AS CAMPAIGN_STATUS,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'Programmatic Guaranteed'
        WHEN 2 THEN 'Private Marketplace'
        WHEN 3 THEN 'Open Auction'
        ELSE 'Preferred Deal'
    END AS CAMPAIGN_TYPE,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'Fixed Price'
        WHEN 2 THEN 'Floor Price'
        ELSE 'Dynamic Floor'
    END AS DEAL_TYPE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'CTV'
        WHEN 2 THEN 'Display'
        WHEN 3 THEN 'Video'
        ELSE 'Mobile'
    END AS INVENTORY_TYPE,
    UNIFORM(200, 5000, RANDOM()) / 100.0 AS FLOOR_PRICE,
    UNIFORM(100000, 5000000, RANDOM()) AS IMPRESSION_GOAL,
    UNIFORM(10000, 500000, RANDOM())::NUMBER(15, 2) AS REVENUE_GOAL,
    UNIFORM(60, 95, RANDOM()) / 100.0 AS FILL_RATE_TARGET,
    UNIFORM(50, 90, RANDOM()) / 100.0 AS VIEWABILITY_THRESHOLD,
    UNIFORM(40, 85, RANDOM()) / 100.0 AS COMPLETION_RATE_THRESHOLD,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'Standard'
        WHEN 2 THEN 'Enhanced'
        ELSE 'Maximum'
    END AS FRAUD_PROTECTION_LEVEL,
    DATEADD('day', -UNIFORM(30, 120, RANDOM()), CURRENT_DATE()) AS CAMPAIGN_START_DATE,
    DATEADD('day', UNIFORM(30, 90, RANDOM()), CURRENT_DATE()) AS CAMPAIGN_END_DATE,
    CURRENT_TIMESTAMP() AS CREATED_AT
FROM TABLE(GENERATOR(ROWCOUNT => 50));

-- =============================================================================
-- CUSTOMER_PROFILE: 5000 synthetic customers with IDR scores
-- =============================================================================

INSERT INTO CUSTOMER_PROFILE
SELECT
    UUID_STRING() AS CUSTOMER_ID,
    CASE UNIFORM(1, 20, RANDOM())
        WHEN 1 THEN 'James' WHEN 2 THEN 'Mary' WHEN 3 THEN 'Robert'
        WHEN 4 THEN 'Patricia' WHEN 5 THEN 'John' WHEN 6 THEN 'Jennifer'
        WHEN 7 THEN 'Michael' WHEN 8 THEN 'Linda' WHEN 9 THEN 'David'
        WHEN 10 THEN 'Elizabeth' WHEN 11 THEN 'William' WHEN 12 THEN 'Barbara'
        WHEN 13 THEN 'Richard' WHEN 14 THEN 'Susan' WHEN 15 THEN 'Joseph'
        WHEN 16 THEN 'Jessica' WHEN 17 THEN 'Thomas' WHEN 18 THEN 'Sarah'
        WHEN 19 THEN 'Daniel' ELSE 'Karen'
    END AS FIRST_NAME,
    CASE UNIFORM(1, 15, RANDOM())
        WHEN 1 THEN 'Smith' WHEN 2 THEN 'Johnson' WHEN 3 THEN 'Williams'
        WHEN 4 THEN 'Brown' WHEN 5 THEN 'Jones' WHEN 6 THEN 'Garcia'
        WHEN 7 THEN 'Miller' WHEN 8 THEN 'Davis' WHEN 9 THEN 'Rodriguez'
        WHEN 10 THEN 'Martinez' WHEN 11 THEN 'Wilson' WHEN 12 THEN 'Anderson'
        WHEN 13 THEN 'Taylor' WHEN 14 THEN 'Thomas' ELSE 'Moore'
    END AS LAST_NAME,
    UUID_STRING() || '@example.com' AS EMAIL,
    CASE WHEN UNIFORM(1, 2, RANDOM()) = 1 THEN 'Male' ELSE 'Female' END AS GENDER,
    UNIFORM(18, 75, RANDOM()) AS AGE,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'New York' WHEN 2 THEN 'Los Angeles' WHEN 3 THEN 'Chicago'
        WHEN 4 THEN 'Houston' WHEN 5 THEN 'Phoenix' WHEN 6 THEN 'Philadelphia'
        WHEN 7 THEN 'San Antonio' WHEN 8 THEN 'San Diego' WHEN 9 THEN 'Dallas'
        ELSE 'Austin'
    END AS CITY,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'NY' WHEN 2 THEN 'CA' WHEN 3 THEN 'IL'
        WHEN 4 THEN 'TX' WHEN 5 THEN 'AZ' WHEN 6 THEN 'PA'
        WHEN 7 THEN 'FL' WHEN 8 THEN 'OH' WHEN 9 THEN 'GA'
        ELSE 'WA'
    END AS STATE,
    LPAD(UNIFORM(10000, 99999, RANDOM())::VARCHAR, 5, '0') AS ZIP_CODE,
    'US' AS COUNTRY_CODE,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'High Value CTV Viewer'
        WHEN 2 THEN 'Mobile-First Shopper'
        WHEN 3 THEN 'Premium Content Consumer'
        WHEN 4 THEN 'Cross-Device Active'
        WHEN 5 THEN 'Sports & Entertainment'
        ELSE 'General Audience'
    END AS CUSTOMER_SEGMENT,
    DATEADD('day', -UNIFORM(30, 730, RANDOM()), CURRENT_DATE()) AS SIGNUP_DATE,
    -- IDR Provider A (deterministic identity)
    'IDRA_' || UUID_STRING() AS IDR_A_ID,
    UNIFORM(10, 100, RANDOM()) / 100.0 AS IDR_A_DIGITAL_ENGAGEMENT_SCORE,
    UNIFORM(10, 100, RANDOM()) / 100.0 AS IDR_A_PURCHASE_PROPENSITY,
    UNIFORM(10, 100, RANDOM()) / 100.0 AS IDR_A_BRAND_LOYALTY_SCORE,
    UNIFORM(50, 100, RANDOM()) / 100.0 AS IDR_A_IDENTITY_LINKAGE_SCORE,
    UNIFORM(40, 100, RANDOM()) / 100.0 AS IDR_A_HOUSEHOLD_LINKAGE_SCORE,
    -- IDR Provider B (probabilistic identity)
    'IDRB_' || UUID_STRING() AS IDR_B_ID,
    UNIFORM(10, 100, RANDOM()) / 100.0 AS IDR_B_BRAND_AFFINITY_SCORE,
    UNIFORM(30, 100, RANDOM()) / 100.0 AS IDR_B_CROSS_DEVICE_LINKAGE_SCORE,
    UNIFORM(10, 100, RANDOM()) / 100.0 AS IDR_B_DIGITAL_ENGAGEMENT_SCORE,
    -- SSP engagement
    UNIFORM(10, 5000, RANDOM()) AS TOTAL_IMPRESSIONS,
    UNIFORM(0, 200, RANDOM()) AS TOTAL_CLICKS,
    UNIFORM(0, 30, RANDOM()) AS TOTAL_CONVERSIONS,
    UNIFORM(100, 50000, RANDOM())::NUMBER(15, 2) AS TOTAL_SPEND_REACHED,
    UNIFORM(50, 5000, RANDOM()) / 10.0 AS LIFETIME_VALUE,
    DATEADD('day', -UNIFORM(0, 60, RANDOM()), CURRENT_TIMESTAMP()) AS LAST_IMPRESSION_DATE
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- =============================================================================
-- SSP_IMPRESSION_LOG: 30000 synthetic impressions linked to campaigns/customers
-- =============================================================================

INSERT INTO SSP_IMPRESSION_LOG
WITH CAMPAIGNS AS (
    SELECT CAMPAIGN_ID, ROW_NUMBER() OVER (ORDER BY CAMPAIGN_ID) AS RN
    FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_CAMPAIGN
),

CUSTOMERS AS (
    SELECT CUSTOMER_ID, ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS RN
    FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.CUSTOMER_PROFILE
)

SELECT
    UUID_STRING() AS IMPRESSION_LOG_ID,
    CUST.CUSTOMER_ID,
    UUID_STRING() AS DEVICE_ID,
    UUID_STRING() AS AUCTION_ID,
    CAMP.CAMPAIGN_ID,
    DATEADD('minute', -UNIFORM(0, 43200, RANDOM()), CURRENT_TIMESTAMP()) AS IMPRESSION_TIMESTAMP,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'Display Banner'
        WHEN 2 THEN 'Video Pre-roll'
        WHEN 3 THEN 'Video Mid-roll'
        WHEN 4 THEN 'Native'
        ELSE 'CTV Full-screen'
    END AS AD_FORMAT,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'Above Fold'
        WHEN 2 THEN 'Below Fold'
        WHEN 3 THEN 'In-Stream'
        ELSE 'Full Screen'
    END AS AD_POSITION,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN '300x250'
        WHEN 2 THEN '728x90'
        WHEN 3 THEN '1920x1080'
        WHEN 4 THEN '320x50'
        ELSE '640x480'
    END AS AD_SIZE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'CTV'
        WHEN 2 THEN 'Display'
        WHEN 3 THEN 'Video'
        ELSE 'Mobile'
    END AS INVENTORY_TYPE,
    CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN 'The Trade Desk'
        WHEN 2 THEN 'Amazon DSP'
        WHEN 3 THEN 'Google DV360'
        WHEN 4 THEN 'Xandr'
        ELSE 'MediaMath'
    END AS WINNING_DSP,
    UNIFORM(100, 8000, RANDOM()) / 100.0 AS WINNING_BID_PRICE,
    UNIFORM(50, 3000, RANDOM()) / 100.0 AS FLOOR_PRICE,
    UNIFORM(100, 7000, RANDOM()) / 100.0 AS GROSS_REVENUE,
    UNIFORM(80, 5500, RANDOM()) / 100.0 AS NET_REVENUE,
    UNIFORM(5, 500, RANDOM()) / 100.0 AS TECH_FEE,
    UNIFORM(10, 30, RANDOM()) / 100.0 AS REVENUE_SHARE,
    UNIFORM(40, 100, RANDOM()) / 100.0 AS VIEWABILITY_SCORE,
    UNIFORM(70, 100, RANDOM()) / 100.0 AS BRAND_SAFETY_SCORE,
    UNIFORM(30, 100, RANDOM()) / 100.0 AS COMPLETION_RATE,
    UNIFORM(20, 500, RANDOM()) AS AUCTION_DURATION_MS,
    UNIFORM(2, 15, RANDOM()) AS AUCTION_PARTICIPANTS,
    UNIFORM(0, 120, RANDOM()) AS INTERACTION_TIME_SEC,
    CURRENT_TIMESTAMP() AS CREATED_AT
FROM TABLE(GENERATOR(ROWCOUNT => 30000))
JOIN CAMPAIGNS CAMP ON MOD(SEQ4(), 50) + 1 = CAMP.RN
JOIN CUSTOMERS CUST ON MOD(SEQ4(), 5000) + 1 = CUST.RN;
