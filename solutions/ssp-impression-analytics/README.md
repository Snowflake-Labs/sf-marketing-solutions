# SSP Impression Analytics

> **Note:** This solution uses entirely synthetic data. All customer names,
> emails, and addresses are fictional. DSP platform names (The Trade Desk,
> Amazon DSP, Google DV360) are industry-standard identifiers retained for
> realism. Identity resolution providers are anonymized as "IDR Provider A"
> and "IDR Provider B".

SSP (Supply-Side Platform) impression analytics with identity resolution
and a Cortex Agent for natural language data exploration.

## Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│  Snowflake CoWork (Cortex Agent)                                     │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  SSP_ANALYST Agent                                             │  │
│  │    → Cortex Analyst (text-to-SQL via Semantic View)            │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Semantic View: SSP_ANALYTICS                                  │  │
│  │    3 tables: impressions, campaigns, customers                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  SSP_IMPRESSION_LOG    │  SSP_CAMPAIGN    │  CUSTOMER_PROFILE  │  │
│  │  30K impressions       │  50 campaigns    │  5K customers      │  │
│  │  + auction metrics     │  + deal config   │  + IDR scores      │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Key Features

- **Cortex Agent** — Ask natural language questions about SSP performance
- **Impression Analytics** — Revenue, viewability, brand safety, DSP win rates
- **Campaign Management** — Deal types, fill rates, floor prices
- **Identity Resolution** — Dual-provider IDR scores for audience quality
- **Audience Segmentation** — Customer LTV and engagement by segment

## Snowflake Features Demonstrated

| Feature | Usage |
|---------|-------|
| Semantic View | Cortex Analyst text-to-SQL over 3 tables |
| Cortex Agent | CoWork-published natural language agent |
| GENERATOR() | Synthetic data generation (pure SQL) |

## Data Model

| Table | Rows | Description |
|-------|------|-------------|
| SSP_IMPRESSION_LOG | 30,000 | Individual auction impressions |
| SSP_CAMPAIGN | 50 | Campaign configurations |
| CUSTOMER_PROFILE | 5,000 | Unified profiles with IDR scores |

## Prerequisites

- Snowflake account with ACCOUNTADMIN access
- Snowflake CoWork enabled (for the Agent)

## Quick Start

```text
$sf-solutions:ssp-impression-analytics
```

After installation, ask the agent:

- "Which DSPs generate the most revenue?"
- "What is the viewability rate by ad format?"
- "Which customer segments have the highest lifetime value?"
- "How is revenue distributed across inventory types?"
