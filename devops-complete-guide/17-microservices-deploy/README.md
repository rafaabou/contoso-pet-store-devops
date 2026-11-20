# 17 — Microservices Deployment

> The capstone: deploy the complete Contoso Pet Store — 8 microservices, polyglot stack, from zero to production.

This category ties everything together. You'll deploy the Contoso Pet Store, a realistic microservices application with 8 services written in Python, Go, Node.js, Rust, and Vue.js. Every tool from the previous 16 categories is applied here: cluster setup, CI/CD pipelines, security scanning, GitOps delivery, monitoring, logging, tracing, and runtime security — all working together on a real application.

## Architecture

The Contoso Pet Store consists of:

| Service | Language | Purpose |
|---------|----------|---------|
| **API Gateway** | Go | Entry point, routing, rate limiting |
| **Product Service** | Python/FastAPI | Product catalog, search, inventory |
| **Order Service** | Node.js/Express | Order management, checkout flow |
| **Payment Service** | Rust/Actix | Payment processing, PCI compliance |
| **User Service** | Python/FastAPI | Authentication, user profiles |
| **Cart Service** | Go | Shopping cart, session management |
| **Notification Service** | Node.js | Email/SMS notifications, event handling |
| **Frontend** | Vue.js | Web UI, responsive design |

## What You'll Learn

- Deploy 8 microservices to a k3s cluster with proper resource management
- Implement inter-service communication (REST, gRPC, event-driven)
- Apply the full DevSecOps pipeline to a real application:
  - Code scanning (SonarQube, Semgrep) → Dependency scanning (Snyk, OSV)
  - Container scanning (Trivy, Grype) → Image signing (Cosign)
  - IaC scanning (Checkov, tfsec) → Policy enforcement (Gatekeeper)
  - Runtime security (Falco, AppArmor) → Compliance (kube-bench)
- Set up GitOps delivery with ArgoCD for all 8 services
- Implement observability across all services (Prometheus, Grafana, Loki, Jaeger)
- Perform chaos testing to verify resilience

## Prerequisites

- Complete understanding of Categories 01-16
- Running k3s cluster with all infrastructure in place
- All security tools deployed and configured
- Container registry with access to push/pull images

## Difficulty

**Expert** — This is the capstone project. It requires mastery of every category in this guide working together.

## Learning Path

```
1. Deploy services to k3s (Helm charts or Kustomize)
2. Set up CI/CD pipeline (GitHub Actions + security scanning)
3. Configure ArgoCD for GitOps delivery
4. Enable monitoring (Prometheus + Grafana + Alertmanager)
5. Add logging (Loki or EFK stack)
6. Implement tracing (OpenTelemetry + Jaeger)
7. Deploy runtime security (Falco + AppArmor)
8. Run compliance checks (kube-bench)
9. Perform chaos testing (Litmus Chaos)
10. Conduct post-mortem and optimize
```
