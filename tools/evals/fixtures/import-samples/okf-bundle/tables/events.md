---
type: BigQuery Table
title: Events table (Google Analytics BigQuery Export)
description: Contains Google Analytics event export data from the ga4_obfuscated_sample_ecommerce dataset.
tags:
- events
- Google Analytics
- BigQuery
- ecommerce
timestamp: '2026-05-28T22:53:05+00:00'
---

# Overview

The `events_` table is a sharded BigQuery table containing Google Analytics event export data. Each row represents a single event triggered by a user interaction or system action.

## Key Fields

### Event identification
- `event_date` (STRING) — Date of the event (YYYYMMDD format)
- `event_timestamp` (INTEGER) — Microsecond timestamp of the event
- `event_name` (STRING) — Name of the event (e.g., page_view, purchase, add_to_cart)
- `event_params` (RECORD, REPEATED) — Key-value pairs of event parameters

### User identification
- `user_pseudo_id` (STRING) — Pseudonymous identifier for the user
- `user_id` (STRING) — User ID set via setUserId API (nullable)
- `user_first_touch_timestamp` (INTEGER) — Timestamp of first user interaction

### Device and geo
- `device.category` (STRING) — desktop, mobile, tablet
- `device.mobile_brand_name` (STRING) — Device manufacturer
- `geo.country` (STRING) — Country based on IP
- `geo.city` (STRING) — City based on IP

## Common Queries

### Event count by type
```sql
SELECT event_name, COUNT(*) as event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_name
ORDER BY event_count DESC
LIMIT 10
```

### Purchase funnel
```sql
SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END) as viewers,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END) as adders,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END) as purchasers
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
```
