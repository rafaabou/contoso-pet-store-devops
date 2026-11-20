# 10 — Service Mesh

> Add security, observability, and traffic management to every service — without changing a line of application code.

This category covers service mesh technology for managing service-to-service communication in your Kubernetes cluster. Istio provides the data plane (sidecar proxies) and control plane for mTLS, traffic routing, and telemetry. Kiali gives you a visual dashboard to understand, monitor, and troubleshoot your mesh.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Istio** | Service mesh control plane — mTLS encryption, traffic management (canary, mirroring, retries), telemetry collection, security policies | [istio.md](istio.md) |
| **Kiali** | Service mesh observability — real-time topology graph, health metrics, configuration validation, traffic animation | [kiali.md](kiali.md) |

## What You'll Learn

- Install Istio on k3s with Istioctl or Helm
- Enable automatic sidecar injection for namespaces
- Configure mTLS encryption between all services (zero-trust networking)
- Implement traffic routing: canary, A/B, fault injection, retries, timeouts
- Use Kiali to visualize service topology and health
- Apply Istio authorization policies for service-to-service access control

## Prerequisites

- Running k3s cluster with deployed microservices (from Categories 01, 17)
- Understanding of Kubernetes networking (Services, Pods, DNS)
- Sufficient cluster resources (Istio sidecars add memory overhead per pod)

## Difficulty

**Advanced** — Istio has a large surface area; mTLS and basic traffic rules are approachable, but multi-cluster and advanced policies require deep expertise.

## Learning Path

```
Istio installation → Sidecar injection → mTLS (zero-trust)
→ Traffic management (canary, retries) → Kiali (observability)
→ Authorization policies → Advanced (multi-cluster, Wasm)
```
