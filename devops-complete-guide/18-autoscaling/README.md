# 18 — Autoscaling — Pod & Node Autoscaling

Automatic scaling of pods and nodes based on workload demand, ensuring the store application maintains performance during traffic spikes and reduces cost during idle periods.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **KEDA** | Event-driven pod autoscaling (RabbitMQ queue depth, cron schedules, external metrics) with scale-to-zero support | [keda.md](keda.md) |
| **Karpenter** | Dynamic node provisioning and consolidation — provisions right-sized nodes on demand, removes underutilized nodes | [karpenter.md](karpenter.md) |
| **HPA** | Horizontal Pod Autoscaler — scales pod replicas based on CPU/memory utilization (built into Kubernetes) | [hpa.md](hpa.md) |
| **VPA** | Vertical Pod Autoscaler — adjusts CPU/memory resource requests per pod based on historical usage | [vpa.md](vpa.md) |
| **Cluster Autoscaler** | Traditional cluster autoscaler — adjusts node count based on unschedulable pods (older alternative to Karpenter) | [cluster-autoscaler.md](cluster-autoscaler.md) |

## Prerequisites

- Running Kubernetes cluster (k3s on k3s-master 10.195.94.80, k3s-worker-1 10.195.94.81, k3s-worker-2 10.195.94.82)
- Helm 3.x installed
- kubectl configured with cluster access
- Prometheus + Grafana deployed for metrics (category 17)
- Vault deployed for secrets management (category 12)
- RabbitMQ operational with queues configured

## Learning Path

1. **Start here** — Understand HPA basics and current static replica counts
2. **KEDA** — Deploy operator, create ScaledObjects for queue-driven services (order-service, virtual-worker), configure scale-to-zero
3. **Karpenter** — Deploy operator, define NodePool with instance type constraints, test provisioning and consolidation
4. **Integration** — Connect KEDA scaling events to Karpenter node provisioning, store trigger credentials in Vault
5. **Observability** — Build Grafana dashboards for scaling events and node lifecycle metrics
6. **Strategy** — Document decision framework for when to use each tool

## Difficulty

**Intermediate** — Requires familiarity with Kubernetes Deployments, Helm, and basic metrics concepts.
