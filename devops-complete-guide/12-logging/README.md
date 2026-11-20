# 12 — Logging

> Centralize every log line from every pod — search, filter, and debug across your entire cluster from one place.

This category covers the ELK stack (Elasticsearch, Fluentd, Kibana) for full-text log search, and Grafana Loki for lightweight, label-based log aggregation. The ELK stack gives you powerful full-text search and analytics; Loki integrates natively with Grafana for a unified metrics + logs experience at a fraction of the resource cost.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Elasticsearch** | Distributed search and analytics engine — full-text indexing, structured queries, aggregation pipelines, index lifecycle management | [elasticsearch.md](elasticsearch.md) |
| **Fluentd** | Log collector and processor — 500+ plugins, filter chains, buffer management, multi-output routing | [fluentd.md](fluentd.md) |
| **Kibana** | Elasticsearch visualization — discover logs, create dashboards, visualize fields, set up index patterns | [kibana.md](kibana.md) |
| **Loki** | Grafana-native log aggregation — label-indexed, not full-text. Cheap to run, queries with LogQL, integrates with Grafana dashboards | [loki.md](loki.md) |

## What You'll Learn

- Deploy Elasticsearch + Fluentd + Kibana (EFK stack) on Kubernetes
- Configure Fluentd as a DaemonSet to collect all container logs
- Query logs with Elasticsearch DSL and Kibana Discover
- Build Kibana dashboards for log-based alerting and analysis
- Deploy Loki with Promtail for label-based log aggregation
- Write LogQL queries and correlate logs with Prometheus metrics in Grafana
- Compare EFK vs. Loki (cost, features, resource usage)

## Prerequisites

- Running k3s cluster (from Category 01)
- Sufficient disk and memory (Elasticsearch is resource-hungry)
- Understanding of Kubernetes pod logging (stdout/stderr)

## Difficulty

**Intermediate** — EFK deployment is well-documented; Elasticsearch tuning and LogQL query optimization require experience.

## Learning Path

```
Loki + Promtail (quick start, low overhead)
→ Grafana + Loki integration (unified dashboards)
→ EFK stack (Elasticsearch + Fluentd + Kibana)
→ Advanced: Elasticsearch tuning, ILM, LogQL optimizations
```
