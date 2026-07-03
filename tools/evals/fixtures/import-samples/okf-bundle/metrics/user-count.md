---
type: Reference
title: User Count
description: Total number of unique users who triggered at least one event.
tags:
- metric
- audience
timestamp: '2026-05-28T22:51:41+00:00'
---

Total number of unique users who triggered at least one event in the selected date range.

```sql
COUNT(DISTINCT user_pseudo_id)
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
```

## Notes

- Uses `user_pseudo_id` (client-generated) not `user_id` (requires explicit setUserId call)
- Counts across all event types — not limited to active engagement events
- Cross-device users may be counted multiple times unless User-ID is configured
