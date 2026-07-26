# OpenRTB Analyst Agent

> **Note:** This solution uses entirely synthetic data. All advertiser and
> publisher names are fictional. DSP/SSP platform names (e.g., Google AdX,
> Magnite, PubMatic) are industry-standard exchange identifiers retained for
> realism — no real campaign data, user data, or proprietary information is
> included.

Programmatic advertising analytics powered by a Snowflake Intelligence Agent.
Ask natural language questions about bid performance, auction dynamics, and
campaign efficiency using OpenRTB 2.6 data.

## Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Snowflake Intelligence (Cortex Agent)                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  OPENRTB_ANALYST Agent                                         │  │
│  │    → Cortex Analyst (text-to-SQL via Semantic View)            │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Semantic View: OPENRTB_ANALYTICS                              │  │
│  │    → OPENRTB_BIDS_HOURLY (Dynamic Table)                      │  │
│  │    → OPENRTB_AUCTIONS_HOURLY (Dynamic Table)                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  10 Dynamic Tables (hourly aggregation)                        │  │
│  │    Executive Daily │ Advertiser Performance │ SPO Analysis      │  │
│  │    Spend by Device │ Win Rate by Floor │ Fraud Indicators      │  │
│  │    Bid Landscape │ Advertiser Daily (anomaly detection)        │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Raw Tables: OPENRTB_BIDS + OPENRTB_AUCTIONS                  │  │
│  │    50K+ synthetic bid rows │ 20K+ auction rows                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Key Features

- **Cortex Agent** — Natural language interface for programmatic ad analytics
- **Semantic View** — Rich metadata layer with dimensions, facts, metrics,
  filters, and verified queries for Cortex Analyst
- **Dynamic Tables** — 10 pre-aggregated views for dashboard-speed queries
- **OpenRTB 2.6 Schema** — Industry-standard bid request/response fields
- **Supply Path Optimization** — SSP exchange efficiency analysis
- **Fraud/IVT Detection** — Bot score and suspicious traffic indicators
- **Viewability Metrics** — MRC-compliant viewability tracking

## Snowflake Features Demonstrated

| Feature | Usage |
|---------|-------|
| Dynamic Tables | Hourly aggregation with `TARGET_LAG = '1 hour'` |
| Semantic View | Cortex Analyst text-to-SQL interface |
| Cortex Agent | Snowflake Intelligence natural language agent |
| GENERATOR() | Synthetic data generation (pure SQL) |

## Data Model

All data is **fully synthetic** — no real company data. Advertiser and publisher
names are fictional. DSP/SSP platform names (Google AdX, Magnite, PubMatic, etc.)
are industry-standard exchange identifiers retained for realism.

## Prerequisites

- Snowflake account with ACCOUNTADMIN access
- Snowflake Intelligence enabled (for the Agent)
- LARGE warehouse available

## Quick Start

Install via the solutions skill:

```text
$sf-solutions:openrtb-analyst-agent
```

After installation, ask the agent questions like:

- "Who are the top advertisers by spend?"
- "How does CTV performance compare to mobile?"
- "Which SSP exchanges have the best clearing efficiency?"
- "What is the fraud rate by publisher?"
