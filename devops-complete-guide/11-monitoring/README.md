# 11 — Monitoring & Metrics

> You can't fix what you can't see — collect, visualize, and alert on every metric in your cluster.

This category covers the full monitoring stack: Prometheus collects metrics, Grafana visualizes them, Alertmanager routes alerts to Slack/PagerDuty, and Node Exporter + kube-state-metrics expose infrastructure and Kubernetes metrics. For cloud-native observability without managing your own stack, Datadog offers an all-in-one SaaS alternative.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Prometheus** | Time-series metrics database — pull-based collection, PromQL queries, service discovery, long-term storage with Thanos | [prometheus.md](prometheus.md) |
| **Grafana** | Metrics visualization — dashboards, panels, annotations, data source federation, alerting | [grafana.md](grafana.md) |
| **Alertmanager** | Alert routing and deduplication — silence, group, and route Prometheus alerts to Slack, email, PagerDuty, webhooks | [alertmanager.md](alertmanager.md) |
| **Datadog** | All-in-one observability SaaS — metrics, logs, traces, APM, security monitoring in one platform | [datadog.md](datadog.md) |
| **Node Exporter** | Host metrics — CPU, memory, disk, network, filesystem stats from every node in the cluster | [node-exporter.md](node-exporter.md) |
| **kube-state-metrics** | Kubernetes object metrics — deployment replicas, pod status, PVC claims, node conditions, and 200+ K8s metrics | [kube-state-metrics.md](kube-state-metrics.md) |

## What You'll Learn

- Deploy the full Prometheus stack (Prometheus + Grafana + Alertmanager) with Helm
- Write PromQL queries for CPU, memory, network, and application metrics
- Build Grafana dashboards for cluster health, application performance, and SLAs
- Configure Alertmanager routes for critical, warning, and info-level alerts
- Use Node Exporter and kube-state-metrics for infrastructure visibility
- Compare self-hosted vs. Datadog SaaS tradeoffs

## Prerequisites

- Running k3s cluster (from Category 01)
- Helm configured (from Category 01)
- Understanding of basic metrics (CPU %, memory usage, request latency)

## Difficulty

**Beginner to Intermediate** — Prometheus + Grafana Helm chart is easy to deploy; PromQL and dashboard design require practice.

## Learning Path

```
Prometheus + Grafana (Helm install) → Node Exporter + kube-state-metrics
→ Basic PromQL → Grafana dashboards → Alertmanager (alerting)
→ Advanced PromQL → Datadog comparison (optional)
```
