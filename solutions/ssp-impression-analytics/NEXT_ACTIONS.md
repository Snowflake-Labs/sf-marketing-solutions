# Post-Install: SSP Impression Analytics

## Phase 1: Quick Exploration

Try these queries with the agent at the URL shown after install:

- "Which DSPs generate the most revenue?"
- "How is revenue distributed across inventory types?"
- "What is the viewability rate by ad format?"
- "Which customer segments have the highest lifetime value?"

Or run SQL directly:

```sql
SELECT WINNING_DSP, COUNT(*) AS IMPRESSIONS,
    SUM(GROSS_REVENUE)::FLOAT AS TOTAL_REVENUE,
    AVG(VIEWABILITY_SCORE)::FLOAT AS AVG_VIEWABILITY
FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_IMPRESSION_LOG
GROUP BY WINNING_DSP
ORDER BY TOTAL_REVENUE DESC;
```

## Phase 2: Campaign Health

Check active campaigns and their performance:

```sql
SELECT c.CAMPAIGN_NAME, c.CAMPAIGN_TYPE, c.CAMPAIGN_STATUS,
    COUNT(i.IMPRESSION_LOG_ID) AS DELIVERED,
    c.IMPRESSION_GOAL,
    ROUND(COUNT(i.IMPRESSION_LOG_ID) * 100.0 / NULLIF(c.IMPRESSION_GOAL, 0), 1) AS FILL_PCT
FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_CAMPAIGN c
LEFT JOIN SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.SSP_IMPRESSION_LOG i
    ON c.CAMPAIGN_ID = i.CAMPAIGN_ID
GROUP BY 1, 2, 3, 5
ORDER BY FILL_PCT DESC
LIMIT 10;
```

## Phase 3: Audience Quality (IDR Scores)

Explore high-value audiences using identity resolution scores:

```sql
SELECT CUSTOMER_SEGMENT,
    COUNT(*) AS CUSTOMERS,
    AVG(IDR_A_DIGITAL_ENGAGEMENT_SCORE)::FLOAT AS AVG_ENGAGEMENT,
    AVG(IDR_B_BRAND_AFFINITY_SCORE)::FLOAT AS AVG_AFFINITY,
    AVG(LIFETIME_VALUE)::FLOAT AS AVG_LTV
FROM SF_SOLUTIONS.SSP_IMPRESSION_ANALYTICS.CUSTOMER_PROFILE
GROUP BY CUSTOMER_SEGMENT
ORDER BY AVG_LTV DESC;
```

## Phase 4: Connect Real Data

Replace synthetic data with your own SSP logs:

1. Truncate the 3 base tables
2. Load your impression log, campaigns, and customer profiles
3. Re-upload `semantic_model.yaml` if you change column names

Key mappings:

- `WINNING_DSP` — The DSP that won each auction
- `GROSS_REVENUE` / `NET_REVENUE` — Financial metrics per impression
- `VIEWABILITY_SCORE` / `BRAND_SAFETY_SCORE` — Quality metrics (0-1 scale)
- `IDR_A_*` / `IDR_B_*` — Scores from your identity resolution partners
