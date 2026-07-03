---
type: Reference
title: Average Transactions Per Purchaser
description: The average number of transactions made by purchasers.
tags:
- metric
- ecommerce
timestamp: '2026-05-28T22:51:41+00:00'
---

The average number of transactions made by purchasers.

```sql
COUNT(*) / COUNT(DISTINCT user_pseudo_id)
-- for events where event_name IN ('in_app_purchase', 'purchase')
```

## Calculation Details

This metric only considers users who have completed at least one purchase event. Non-purchasers are excluded from both numerator and denominator.

## Usage

Use this metric to understand purchase frequency. A high value indicates repeat purchasing behavior. Compare across user segments (device type, acquisition channel) to identify high-value cohorts.
