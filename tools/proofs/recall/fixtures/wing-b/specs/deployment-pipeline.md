---
type: specification
title: "Deployment Pipeline Spec"
---

# Deployment Pipeline

## Overview

The deployment pipeline uses gamma_protocol for service communication and delta_framework for validation. Each deployment goes through three stages: build, canary, and promote.

## Stages

### Build
Compile artifacts and run unit tests.

### Canary
Deploy to 5% of traffic, monitor error rates for 30 minutes.

### Promote
If canary passes, roll out to remaining traffic.
