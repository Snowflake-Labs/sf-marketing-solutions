# Post-Install: OpenRTB Analyst Agent

## Phase 1: Quick Exploration

Try these queries with the agent at the URL shown after install:

- "Who are the top advertisers by spend?"
- "How is spend distributed across device types?"
- "What is the daily spend trend over the last 7 days?"
- "What is the supply cost by device type?"

Or run SQL directly:

```sql
SELECT * FROM SF_SOLUTIONS.OPENRTB_ANALYTICS.OPENRTB_EXECUTIVE_DAILY
ORDER BY DAY_TS DESC LIMIT 7;
```

## Phase 2: Explore Dynamic Tables

Check the 10 pre-aggregated views:

```sql
SHOW DYNAMIC TABLES IN SCHEMA SF_SOLUTIONS.OPENRTB_ANALYTICS;
```

Key tables for analysis:

| Dynamic Table | Use Case |
|---------------|----------|
| OPENRTB_BIDS_HOURLY | Core bid analytics |
| OPENRTB_SPO_ANALYSIS | Supply path optimization |
| OPENRTB_FRAUD_INDICATORS | IVT/bot detection |
| OPENRTB_BID_LANDSCAPE | Clearing price distribution |
| OPENRTB_ADVERTISER_DAILY | Anomaly detection |

## Phase 3: Connect Real Data

Replace the synthetic data with your own OpenRTB bid logs:

1. Truncate the base tables
2. Load your data into `OPENRTB_BIDS` and `OPENRTB_AUCTIONS`
3. Dynamic Tables will auto-refresh within 1 hour

Key columns to map from your data:

- `__TIME` — Event timestamp (hourly granularity)
- `ADVERTISER_NAME` / `ADOMAIN` — Advertiser identity
- `PUB_NAME` / `APP_SITE_DOMAIN` — Publisher identity
- `BID_CNT` / `IMP_CNT` / `CLICK_REG_CNT` — Volume metrics
- `MEDIA_SPEND_USD` / `BID_PRICE_USD` — Financial metrics

## Phase 4: Production Deployment

For production use:

1. **Adjust TARGET_LAG** — Set to `'5 minutes'` for near-real-time
2. **Add streaming source** — Connect Snowpipe Streaming for live bid data
3. **Customize the agent** — Edit instructions for your team's terminology
4. **Add alerts** — Create tasks that monitor anomalies in OPENRTB_ADVERTISER_DAILY
