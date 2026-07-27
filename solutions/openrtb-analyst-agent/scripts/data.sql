-- =============================================================================
-- Solution: OpenRTB Analyst Agent — Demo Data Generation
-- Industry: Advertising & MarTech
-- =============================================================================
-- Generates ~50,000 rows of synthetic OpenRTB bid data and ~20,000 auction rows.
-- All advertiser and publisher names are fictional; DSP/SSP platform names are real.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SF_SOLUTIONS;
USE WAREHOUSE SF_SOLUTIONS_WH;
USE SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;

-- =============================================================================
-- OPENRTB_BIDS: Synthetic pre-aggregated hourly bid data
-- =============================================================================

INSERT INTO OPENRTB_BIDS
WITH ADVERTISERS AS (
SELECT COLUMN1 AS IDX,
COLUMN2 AS ADV_NAME,
COLUMN3 AS ADOMAIN,
COLUMN4 AS VERTICAL
FROM VALUES
(1, 'Apex Consumer Brands', 'apexconsumer.example.com', 'CPG'),
(2, 'GlobalHome Corp', 'globalhome.example.com', 'CPG'),
(3, 'Harvest Foods', 'harvestfoods.example.com', 'CPG'),
(4, 'PureGrain Co', 'puregrain.example.com', 'CPG'),
(5, 'SnackWorks International', 'snackworks.example.com', 'CPG'),
(6, 'FreshSmile Labs', 'freshsmile.example.com', 'CPG'),
(7, 'BrightClean Inc', 'brightclean.example.com', 'CPG'),
(8, 'EverPure Solutions', 'everpure.example.com', 'CPG'),
(9, 'Summit Auto Group', 'summitauto.example.com', 'Automotive'),
(10, 'Velocity Motors', 'velocitymotors.example.com', 'Automotive'),
(11, 'Prestige Auto', 'prestigeauto.example.com', 'Automotive'),
(12, 'DriveForward', 'driveforward.example.com', 'Automotive'),
(13, 'Atlas Automotive', 'atlasauto.example.com', 'Automotive'),
(14, 'EuroWheels AG', 'eurowheels.example.com', 'Automotive'),
(15, 'MedVita Pharma', 'medvita.example.com', 'Pharma'),
(16, 'DermaCare Labs', 'dermacare.example.com', 'Pharma'),
(17, 'BioGenix Health', 'biogenix.example.com', 'Pharma'),
(18, 'WellPoint Sciences', 'wellpoint.example.com', 'Pharma'),
(19, 'NordicHome', 'nordichome.example.com', 'Retail'),
(20, 'CasaStyle', 'casastyle.example.com', 'Retail'),
(21, 'ShopSphere', 'shopsphere.example.com', 'Retail'),
(22, 'QuickCart', 'quickcart.example.com', 'Retail'),
(23, 'PrimeLend Financial', 'primelend.example.com', 'Financial'),
(24, 'SafeGuard Insurance', 'safeguard.example.com', 'Insurance'),
(25, 'TrustShield Coverage', 'trustshield.example.com', 'Insurance'),
(26, 'LuxeBeauty Co', 'luxebeauty.example.com', 'Beauty'),
(27, 'GlowCraft', 'glowcraft.example.com', 'Beauty'),
(28, 'RadiantSkin Labs', 'radiantskin.example.com', 'Beauty'),
(29, 'Starlight Media', 'starlightmedia.example.com', 'Entertainment'),
(30, 'Horizon Studios', 'horizonstudios.example.com', 'Entertainment'),
(31, 'Nexus Entertainment', 'nexusent.example.com', 'Entertainment'),
(32, 'Voyager Hotels', 'voyagerhotels.example.com', 'Travel'),
(33, 'TripWise', 'tripwise.example.com', 'Travel'),
(34, 'ConnectOne Wireless', 'connectone.example.com', 'Telecom'),
(35, 'NovaTech Electronics', 'novatech.example.com', 'Electronics')
),

PUBLISHERS AS (
SELECT COLUMN1 AS IDX, COLUMN2 AS PUB_NAME, COLUMN3 AS PUB_DOMAIN,
COLUMN4 AS APP_NAME, COLUMN5 AS IS_APP
FROM VALUES
(1, 'StreamBox', 'streambox.example.com', 'StreamBox Channel', TRUE),
(2, 'CloudScreen', 'cloudscreen.example.com', 'CloudScreen', TRUE),
(3, 'FreeView TV', 'freeview.example.com', 'FreeView', TRUE),
(4, 'OrbitTV', 'orbittv.example.com', 'OrbitTV', TRUE),
(5, 'FeatherStream', 'featherstream.example.com', 'FeatherStream', TRUE),
(6, 'PixelPlus TV', 'pixelplus.example.com', 'PixelPlus TV', TRUE),
(7, 'ClearVision+', 'clearvision.example.com', 'ClearVision+', TRUE),
(8, 'PrimeView+', 'primeview.example.com', 'PrimeView+', TRUE),
(9, 'LiveScore TV', 'livescoretv.example.com', 'LiveScore TV', TRUE),
(10, 'Metro Daily News', 'metrodaily.example.com', NULL, FALSE),
(11, 'Capital Journal', 'capitaljournal.example.com', NULL, FALSE),
(12, 'GlobalReport', 'globalreport.example.com', NULL, FALSE),
(13, 'SportStream', 'sportstream.example.com', NULL, FALSE),
(14, 'MarketPulse', 'marketpulse.example.com', NULL, FALSE),
(15, 'National Tribune', 'nationaltribune.example.com', NULL, FALSE),
(16, 'InfoChannel', 'infochannel.example.com', NULL, FALSE),
(17, 'DailyWire Plus', 'dailywireplus.example.com', NULL, FALSE),
(18, 'WorldNews Wire', 'worldnewswire.example.com', NULL, FALSE),
(19, 'TrendBuzz', 'trendbuzz.example.com', NULL, FALSE),
(20, 'SoundWave', 'soundwave.example.com', 'SoundWave', TRUE),
(21, 'MelodyFM', 'melodyfm.example.com', 'MelodyFM', TRUE),
(22, 'TuneIn Live', 'tuneinlive.example.com', 'TuneIn Live', TRUE),
(23, 'ThreadBoard', 'threadboard.example.com', 'ThreadBoard', TRUE),
(24, 'GameStream', 'gamestream.example.com', 'GameStream', TRUE),
(25, 'WeatherNow', 'weathernow.example.com', 'WeatherNow', TRUE)
),

SSP_EXCHANGES AS (
SELECT COLUMN1 AS IDX, COLUMN2 AS EXCHANGE_NAME, COLUMN3 AS TAKE_RATE
FROM VALUES
(1, 'Google AdX', 0.15),
(2, 'Magnite', 0.12),
(3, 'PubMatic', 0.14),
(4, 'Index Exchange', 0.11),
(5, 'OpenX', 0.16),
(6, 'Xandr', 0.13),
(7, 'TripleLift', 0.14),
(8, 'Sovrn', 0.18),
(9, 'Sharethrough', 0.15),
(10, '33Across', 0.19)
),

GENERATED AS (
SELECT
SEQ4() AS ROW_ID,
DATEADD('minute',
-1 * UNIFORM(0, 43200, RANDOM()),
CURRENT_TIMESTAMP()
) AS TS,
UNIFORM(1, 35, RANDOM()) AS ADV_IDX,
UNIFORM(1, 25, RANDOM()) AS PUB_IDX,
UNIFORM(1, 10, RANDOM()) AS SSP_IDX
FROM TABLE(GENERATOR(ROWCOUNT => 50000))
)

SELECT
DATE_TRUNC('hour', G.TS) AS __TIME,
A.ADOMAIN,
A.ADV_NAME AS ADVERTISER_NAME,
A.ADV_NAME || '_Campaign_' || UNIFORM(1, 6, RANDOM())::VARCHAR AS CAMPAIGN_NAME,
CASE WHEN P.IS_APP THEN 'App' ELSE 'Site' END AS APP_OR_SITE,
P.PUB_DOMAIN AS APP_SITE_DOMAIN,
COALESCE(P.APP_NAME, P.PUB_NAME) AS APP_SITE_NAME,
P.PUB_NAME,
CASE UNIFORM(1, 9, RANDOM())
WHEN 1 THEN 'Mobile/Tablet'
WHEN 2 THEN 'Personal Computer'
WHEN 3 THEN 'Connected TV'
WHEN 4 THEN 'Phone'
WHEN 5 THEN 'Set Top Box[NR1]'
WHEN 6 THEN 'Tablet'
WHEN 7 THEN 'Games Console'
WHEN 8 THEN 'Connected Device'
ELSE 'Mobile/Tablet'
END AS DEVICE_TYPE,
CASE UNIFORM(1, 7, RANDOM())
WHEN 1 THEN 'iOS'
WHEN 2 THEN 'Android'
WHEN 3 THEN 'Windows'
WHEN 4 THEN 'macOS'
WHEN 5 THEN 'tvOS'
WHEN 6 THEN 'Fire OS'
ELSE 'Linux'
END AS DEVICE_OS,
'US/' || CASE UNIFORM(1, 15, RANDOM())
WHEN 1 THEN 'CA' WHEN 2 THEN 'NY' WHEN 3 THEN 'TX'
WHEN 4 THEN 'FL' WHEN 5 THEN 'IL' WHEN 6 THEN 'PA'
WHEN 7 THEN 'OH' WHEN 8 THEN 'GA' WHEN 9 THEN 'NC'
WHEN 10 THEN 'MI' WHEN 11 THEN 'WA' WHEN 12 THEN 'AZ'
WHEN 13 THEN 'MA' WHEN 14 THEN 'CO' ELSE 'VA'
END AS DEVICE_REGION,
CASE UNIFORM(1, 6, RANDOM())
WHEN 1 THEN 'Chrome'
WHEN 2 THEN 'Safari'
WHEN 3 THEN 'Edge'
WHEN 4 THEN 'Firefox'
WHEN 5 THEN 'Samsung Internet'
ELSE 'In-App'
END AS PLATFORM_BROWSER,
CASE WHEN UNIFORM(1, 100, RANDOM()) <= 72 THEN 'First Price'
ELSE 'Second Price' END AS AUCTION_TYPE,
'$' || (UNIFORM(0, 20, RANDOM()) * 0.5)::VARCHAR(10)
|| '-$' || ((UNIFORM(0, 20, RANDOM()) * 0.5) + 0.5)::VARCHAR(10)
AS BID_FLOOR_BUCKET,
CASE UNIFORM(1, 4, RANDOM())
WHEN 1 THEN 'Banner'
WHEN 2 THEN 'Video'
WHEN 3 THEN 'Native'
ELSE 'Audio'
END AS PLACEMENT_TYPE,
CASE UNIFORM(1, 4, RANDOM())
WHEN 1 THEN 'Display'
WHEN 2 THEN 'Video'
WHEN 3 THEN 'Native'
ELSE 'Rich Media'
END AS CREATIVE_TYPE,
UNIFORM(50, 500, RANDOM()) AS BID_CNT,
UNIFORM(10, 200, RANDOM()) AS IMP_CNT,
UNIFORM(0, 15, RANDOM()) AS CLICK_REG_CNT,
UNIFORM(100, 50000, RANDOM())::FLOAT AS MEDIA_SPEND_USD,
UNIFORM(200, 80000, RANDOM())::FLOAT AS BID_PRICE_USD,
UNIFORM(50, 2000, RANDOM()) / 100.0 AS BID_FLOOR,
UNIFORM(30, 400, RANDOM()) AS HAS_BID_FLOOR_CNT,
CASE WHEN UNIFORM(1, 4, RANDOM()) = 2
THEN UNIFORM(5, 100, RANDOM()) ELSE 0 END AS VIDEO_START_CNT,
CASE WHEN UNIFORM(1, 4, RANDOM()) = 2
THEN UNIFORM(2, 70, RANDOM()) ELSE 0 END AS VIDEO_COMPLETE_CNT,
S.EXCHANGE_NAME AS SSP_EXCHANGE,
CASE UNIFORM(1, 4, RANDOM())
WHEN 1 THEN 'Direct'
WHEN 2 THEN 'Reseller'
WHEN 3 THEN 'Header Bidding'
ELSE 'SDK'
END AS SUPPLY_PATH_TYPE,
UNIFORM(1, 4, RANDOM()) AS INTERMEDIARY_COUNT,
S.TAKE_RATE + UNIFORM(-5, 5, RANDOM()) / 100.0 AS SUPPLY_COST_PCT,
UNIFORM(50, 40000, RANDOM())::FLOAT AS CLEARING_PRICE_USD,
UNIFORM(0, 100, RANDOM()) / 100.0 AS BOT_SCORE,
CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5 THEN 1 ELSE 0 END AS SUSPICIOUS_FLAG,
CASE WHEN UNIFORM(1, 100, RANDOM()) <= 3 THEN 1 ELSE 0 END AS DATACENTER_FLAG,
UNIFORM(5, 180, RANDOM()) AS VIEWABLE_IMP_CNT,
UNIFORM(40, 95, RANDOM()) / 100.0 AS VIEWABILITY_RATE
FROM GENERATED G
JOIN ADVERTISERS A ON G.ADV_IDX = A.IDX
JOIN PUBLISHERS P ON G.PUB_IDX = P.IDX
JOIN SSP_EXCHANGES S ON G.SSP_IDX = S.IDX;

-- =============================================================================
-- OPENRTB_AUCTIONS: Synthetic pre-aggregated hourly auction request data
-- =============================================================================

INSERT INTO OPENRTB_AUCTIONS
WITH PUBLISHERS AS (
SELECT COLUMN1 AS IDX, COLUMN2 AS PUB_NAME, COLUMN3 AS PUB_DOMAIN,
COLUMN4 AS APP_NAME, COLUMN5 AS IS_APP
FROM VALUES
(1, 'StreamBox', 'streambox.example.com', 'StreamBox Channel', TRUE),
(2, 'CloudScreen', 'cloudscreen.example.com', 'CloudScreen', TRUE),
(3, 'FreeView TV', 'freeview.example.com', 'FreeView', TRUE),
(4, 'OrbitTV', 'orbittv.example.com', 'OrbitTV', TRUE),
(5, 'FeatherStream', 'featherstream.example.com', 'FeatherStream', TRUE),
(6, 'PixelPlus TV', 'pixelplus.example.com', 'PixelPlus TV', TRUE),
(7, 'ClearVision+', 'clearvision.example.com', 'ClearVision+', TRUE),
(8, 'PrimeView+', 'primeview.example.com', 'PrimeView+', TRUE),
(9, 'LiveScore TV', 'livescoretv.example.com', 'LiveScore TV', TRUE),
(10, 'Metro Daily News', 'metrodaily.example.com', NULL, FALSE),
(11, 'Capital Journal', 'capitaljournal.example.com', NULL, FALSE),
(12, 'GlobalReport', 'globalreport.example.com', NULL, FALSE),
(13, 'SportStream', 'sportstream.example.com', NULL, FALSE),
(14, 'MarketPulse', 'marketpulse.example.com', NULL, FALSE),
(15, 'National Tribune', 'nationaltribune.example.com', NULL, FALSE),
(16, 'InfoChannel', 'infochannel.example.com', NULL, FALSE),
(17, 'DailyWire Plus', 'dailywireplus.example.com', NULL, FALSE),
(18, 'WorldNews Wire', 'worldnewswire.example.com', NULL, FALSE),
(19, 'TrendBuzz', 'trendbuzz.example.com', NULL, FALSE),
(20, 'SoundWave', 'soundwave.example.com', 'SoundWave', TRUE),
(21, 'MelodyFM', 'melodyfm.example.com', 'MelodyFM', TRUE),
(22, 'TuneIn Live', 'tuneinlive.example.com', 'TuneIn Live', TRUE),
(23, 'ThreadBoard', 'threadboard.example.com', 'ThreadBoard', TRUE),
(24, 'GameStream', 'gamestream.example.com', 'GameStream', TRUE),
(25, 'WeatherNow', 'weathernow.example.com', 'WeatherNow', TRUE)
),

GENERATED AS (
SELECT
SEQ4() AS ROW_ID,
DATEADD('minute',
-1 * UNIFORM(0, 43200, RANDOM()),
CURRENT_TIMESTAMP()
) AS TS,
UNIFORM(1, 25, RANDOM()) AS PUB_IDX
FROM TABLE(GENERATOR(ROWCOUNT => 20000))
)

SELECT
DATE_TRUNC('hour', G.TS) AS __TIME,
COALESCE(P.APP_NAME, P.PUB_NAME) AS APP_SITE_NAME,
P.PUB_DOMAIN AS APP_SITE_DOMAIN,
P.PUB_NAME,
'IAB' || UNIFORM(1, 20, RANDOM())::VARCHAR AS APP_SITE_CAT,
CASE UNIFORM(1, 6, RANDOM())
WHEN 1 THEN '300x250'
WHEN 2 THEN '728x90'
WHEN 3 THEN '320x50'
WHEN 4 THEN '970x250'
WHEN 5 THEN '1920x1080'
ELSE '640x480'
END AS AD_SIZE,
'US/' || CASE UNIFORM(1, 15, RANDOM())
WHEN 1 THEN 'CA' WHEN 2 THEN 'NY' WHEN 3 THEN 'TX'
WHEN 4 THEN 'FL' WHEN 5 THEN 'IL' WHEN 6 THEN 'PA'
WHEN 7 THEN 'OH' WHEN 8 THEN 'GA' WHEN 9 THEN 'NC'
WHEN 10 THEN 'MI' WHEN 11 THEN 'WA' WHEN 12 THEN 'AZ'
WHEN 13 THEN 'MA' WHEN 14 THEN 'CO' ELSE 'VA'
END AS DEVICE_REGION,
CASE UNIFORM(1, 7, RANDOM())
WHEN 1 THEN 'iOS'
WHEN 2 THEN 'Android'
WHEN 3 THEN 'Windows'
WHEN 4 THEN 'macOS'
WHEN 5 THEN 'tvOS'
WHEN 6 THEN 'Fire OS'
ELSE 'Linux'
END AS DEVICE_OS,
CASE UNIFORM(1, 5, RANDOM())
WHEN 1 THEN 'Mobile/Tablet'
WHEN 2 THEN 'Personal Computer'
WHEN 3 THEN 'Connected TV'
WHEN 4 THEN 'Phone'
ELSE 'Tablet'
END AS DEVICE_TYPE,
CASE UNIFORM(1, 5, RANDOM())
WHEN 1 THEN 'Chrome'
WHEN 2 THEN 'Safari'
WHEN 3 THEN 'Edge'
WHEN 4 THEN 'Firefox'
ELSE 'In-App'
END AS PLATFORM_BROWSER,
'$' || (UNIFORM(0, 10, RANDOM()) * 0.5)::VARCHAR(10)
|| '-$' || ((UNIFORM(0, 10, RANDOM()) * 0.5) + 0.5)::VARCHAR(10)
AS BID_FLOOR_BUCKET,
CASE UNIFORM(1, 4, RANDOM())
WHEN 1 THEN 'Banner'
WHEN 2 THEN 'Video'
WHEN 3 THEN 'Native'
ELSE 'Audio'
END AS PLACEMENT_TYPE,
CASE WHEN UNIFORM(1, 100, RANDOM()) <= 72 THEN 'First Price'
ELSE 'Second Price' END AS AUCTION_TYPE,
CASE WHEN P.IS_APP THEN 'App' ELSE 'Site' END AS APP_OR_SITE,
CASE UNIFORM(1, 4, RANDOM())
WHEN 1 THEN 'Above Fold'
WHEN 2 THEN 'Below Fold'
WHEN 3 THEN 'Full Screen'
ELSE 'Header'
END AS AD_POSITION,
UNIFORM(100, 5000, RANDOM()) AS BID_REQUEST_CNT,
UNIFORM(50, 2000, RANDOM()) / 100.0 AS BID_FLOOR,
UNIFORM(50, 4000, RANDOM()) AS HAS_BID_FLOOR_CNT
FROM GENERATED G
JOIN PUBLISHERS P ON G.PUB_IDX = P.IDX;

-- =============================================================================
-- Manually refresh Dynamic Tables so data is available immediately after install.
-- Without this, TARGET_LAG = '1 day' means up to 24-hour delay before Agent
-- queries return any results.
-- =============================================================================

ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BIDS_HOURLY REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_AUCTIONS_HOURLY REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_EXECUTIVE_DAILY REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ADVERTISER_PERFORMANCE REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_SPEND_BY_DEVICE REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_WINRATE_BY_FLOOR REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_SPO_ANALYSIS REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_FRAUD_INDICATORS REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_BID_LANDSCAPE REFRESH;
ALTER DYNAMIC TABLE SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_ADVERTISER_DAILY REFRESH;
