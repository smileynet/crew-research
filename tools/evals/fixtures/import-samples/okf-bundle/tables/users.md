---
type: BigQuery Table
title: Users
description: Information about users registered on Stack Overflow, including profile information, activity metrics, and network-wide identifiers.
tags:
- Stack Overflow
- users
- profiles
- community
timestamp: '2026-05-28T23:32:24+00:00'
---

# Overview

The `users` table stores profiles of registered users on the Stack Overflow platform. Each row represents a unique user, identified by their `id`.

## Schema

- `id` (INTEGER) — Unique identifier for the user
- `display_name` (STRING) — The publicly visible name of the user
- `about_me` (STRING) — User-provided free-form text. Nullable.
- `age` (INTEGER) — User-provided age. Nullable.
- `account_id` (INTEGER) — Stack Exchange Network profile ID. Nullable.
- `creation_date` (TIMESTAMP) — When the account was created
- `last_access_date` (TIMESTAMP) — Last page load; updated every 30 minutes at most
- `location` (STRING) — User-provided geographical location. Nullable.
- `reputation` (INTEGER) — The user's reputation score
- `up_votes` (INTEGER) — Total upvotes cast by this user
- `down_votes` (INTEGER) — Total downvotes cast by this user
- `views` (INTEGER) — Number of times this user's profile has been viewed

## Common Queries

### Top users by reputation
```sql
SELECT display_name, reputation, up_votes, down_votes
FROM `bigquery-public-data.stackoverflow.users`
ORDER BY reputation DESC
LIMIT 20
```

### User activity distribution
```sql
SELECT
  CASE
    WHEN reputation < 100 THEN 'newcomer'
    WHEN reputation < 1000 THEN 'active'
    WHEN reputation < 10000 THEN 'established'
    ELSE 'veteran'
  END as tier,
  COUNT(*) as user_count
FROM `bigquery-public-data.stackoverflow.users`
GROUP BY tier
```
