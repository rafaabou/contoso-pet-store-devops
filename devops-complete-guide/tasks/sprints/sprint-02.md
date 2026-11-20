# Sprint 02: Security Hardening & CI/CD

## Sprint Info

| Field | Value |
|---|---|
| **Sprint** | Sprint 2 |
| **Duration** | 2026-09-18 → 2026-10-01 (10 working days) |
| **Team** | DevOps/DevSecOps |
| **Cluster** | k3s on 2 PCs via Incus + Tailscale |

## Cluster Topology (post-Sprint 1)

| Node | IP (Tailscale) | Role |
|---|---|---|
| k3s-master | 10.195.94.80 | Control Plane + etcd |
| k3s-worker-1 | 10.195.94.81 | Worker |
| k3s-worker-2 | 100.100.13.113 | Worker (via Tailscale) |
| vault | 10.195.94.200 | HashiCorp Vault (dedicated) |
| monitoring | 10.195.94.210 | Prometheus + Grafana (dedicated) |
| MetalLB Pool | 10.195.94.100-150 | Load Balancer |

## Sprint Goal

> Establish full CI/CD pipeline with security scanning at every stage. By end of Sprint 2, every commit goes through lint → scan → build → test → deploy, with signed images, sealed secrets, and policy enforcement.

## Capacity

| Role | Headcount | Hours/Day | Total Hours |
|---|---|---|---|
| DevOps Engineer | 1 | 8 | 80 |
| Security Lead | 1 | 8 | 80 |
| SRE | 1 | 8 | 80 |
| **Total** | **3** | — | **240** |

Estimated task points: ~210h (leaves buffer for Sprint 1 carry-over and incidents).

---

## Backlog

### Security (25 tasks)

- [ ] TASK-071: Trivy deep scan — scan all images with severity threshold CRITICAL (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-072: Cosign signing — sign all container images with Sigstore Cosign (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-073: Vault dynamic secrets — configure database/SSH secret engines (Priority: P1, Estimate: 6h, Category: security)
- [ ] TASK-074: OPA Gatekeeper tuning — refine constraints, reduce false positives (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-075: Falco custom rules — service-specific detection rules (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-076: Sealed Secrets — deploy Bitnami Sealed Secrets controller (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-077: RBAC review — least-privilege audit for all service accounts (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-078: Network Policy hardening — inter-service allow rules per service (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-079: AppArmor profiles — custom profiles for all services (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-080: Seccomp profiles — baseline + custom seccomp for workloads (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-081: Image pull secrets — rotate and distribute registry credentials (Priority: P1, Estimate: 2h, Category: security)
- [ ] TASK-082: Encryption at rest — enable etcd encryption (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-083: Audit logging — enable K8s audit policy with webhook (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-084: WAF rules — deploy ModSecurity/Coraza for ingress (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-085: mTLS setup — enable service mesh mutual TLS (Priority: P2, Estimate: 6h, Category: security)
- [ ] TASK-086: kube-bench remediation — fix all CIS benchmark failures (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-087: Vault auto-unseal — configure transit auto-unseal (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-088: IAM least privilege — review Tailscale + cloud IAM policies (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-089: Security scanning in CI — Trivy + Snyk in pipeline (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-090: Helm chart scanning — trivy config scan on Helm values (Priority: P2, Estimate: 2h, Category: security)
- [ ] TASK-091: Dependabot alerts — enable for all repos (Priority: P2, Estimate: 1h, Category: security)
- [ ] TASK-092: Incident response testing — tabletop exercise (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-093: DR testing — restore etcd snapshot to new cluster (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-094: Backup encryption — encrypt etcd snapshots at rest (Priority: P2, Estimate: 2h, Category: security)
- [ ] TASK-095: Vault token rotation — implement automatic token revocation (Priority: P2, Estimate: 2h, Category: security)

### Deployment (15 tasks)

- [ ] TASK-096: ArgoCD GitOps pipeline — full GitOps flow for all services (Priority: P1, Estimate: 6h, Category: deployment)
- [ ] TASK-097: Argo Rollouts blue-green — deploy order-service blue-green (Priority: P1, Estimate: 6h, Category: deployment)
- [ ] TASK-098: ArgoCD Image Updater — auto-update image tags in Git (Priority: P2, Estimate: 4h, Category: deployment)
- [ ] TASK-099: CI/CD for ai-service — build, scan, test, deploy pipeline (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-100: CI/CD for product-service — build, scan, test, deploy pipeline (Priority: P1, Estimate: 3h, Category: deployment)
- [ ] TASK-101: CI/CD for makeline-service — build, scan, test, deploy pipeline (Priority: P1, Estimate: 3h, Category: deployment)
- [ ] TASK-102: Staging environment — separate namespace with prod mirror (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-103: Database migration pipeline — versioned migration runner (Priority: P2, Estimate: 4h, Category: deployment)
- [ ] TASK-104: Secret rotation pipeline — automated secret refresh (Priority: P2, Estimate: 3h, Category: deployment)
- [ ] TASK-105: Deployment checklist runbook — pre/post deploy steps (Priority: P1, Estimate: 2h, Category: deployment)
- [ ] TASK-106: ArgoCD notifications — Slack/webhook on sync events (Priority: P2, Estimate: 2h, Category: deployment)
- [ ] TASK-107: Rollouts analysis — automated canary analysis (Priority: P2, Estimate: 3h, Category: deployment)
- [ ] TASK-108: Multi-env promotion — dev → staging → prod pipeline (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-109: Helm chart versioning — semver + changelog automation (Priority: P2, Estimate: 2h, Category: deployment)
- [ ] TASK-110: Release tagging — git tags on successful deploy (Priority: P3, Estimate: 1h, Category: deployment)

### Testing (15 tasks)

- [ ] TASK-111: Security scan integration — block deploy on CRITICAL vulns (Priority: P1, Estimate: 3h, Category: testing)
- [ ] TASK-112: Policy validation tests — test OPA constraints in CI (Priority: P1, Estimate: 3h, Category: testing)
- [ ] TASK-113: Secrets rotation tests — verify Vault secret refresh (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-114: CI/CD pipeline tests — end-to-end pipeline dry-run (Priority: P1, Estimate: 3h, Category: testing)
- [ ] TASK-115: E2E checkout flow — full purchase flow automated test (Priority: P1, Estimate: 6h, Category: testing)
- [ ] TASK-116: Load testing — k6 script for 1000 req/s (Priority: P1, Estimate: 6h, Category: testing)
- [ ] TASK-117: Chaos experiment — kill random pods, verify recovery (Priority: P2, Estimate: 4h, Category: testing)
- [ ] TASK-118: Vault failover test — seal/unseal during traffic (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-119: RBAC restriction test — verify denied access paths (Priority: P1, Estimate: 2h, Category: testing)
- [ ] TASK-120: TLS renewal test — force cert renewal, verify zero downtime (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-121: ArgoCD broken manifest test — deploy bad YAML, verify ArgoCD blocks (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-122: Rollback procedure test — trigger rollback, verify service recovery (Priority: P1, Estimate: 2h, Category: testing)
- [ ] TASK-123: Disaster recovery test — full cluster restore from backup (Priority: P1, Estimate: 4h, Category: testing)
- [ ] TASK-124: Pod Security test — test PSS enforcement (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-125: DNS load test — CoreDNS throughput under load (Priority: P3, Estimate: 2h, Category: testing)

### Code Quality (10 tasks)

- [ ] TASK-126: SonarQube setup — deploy SonarQube in cluster (Priority: P1, Estimate: 6h, Category: code-quality)
- [ ] TASK-127: Quality gates — block merge on coverage < 80% (Priority: P2, Estimate: 2h, Category: code-quality)
- [ ] TASK-128: Semgrep custom rules — service-specific security rules (Priority: P2, Estimate: 4h, Category: code-quality)
- [ ] TASK-129: SBOM generation — cyclonedx-bom in CI pipeline (Priority: P1, Estimate: 3h, Category: code-quality)
- [ ] TASK-130: OWASP dependency check — dependency-check in pipeline (Priority: P2, Estimate: 3h, Category: code-quality)
- [ ] TASK-131: Code review automation — auto-assign reviewers, label (Priority: P3, Estimate: 2h, Category: code-quality)
- [ ] TASK-132: PR review checklist — security + ops checklist in template (Priority: P2, Estimate: 1h, Category: code-quality)
- [ ] TASK-133: Linter rules for all languages — Go, Python, JS, YAML (Priority: P2, Estimate: 3h, Category: code-quality)
- [ ] TASK-134: Test coverage reporting — codecov integration (Priority: P2, Estimate: 2h, Category: code-quality)
- [ ] TASK-135: Security scan reporting — consolidated vuln report dashboard (Priority: P2, Estimate: 2h, Category: code-quality)

### Infrastructure (10 tasks)

- [ ] TASK-136: Terraform module refactor — extract reusable modules (Priority: P2, Estimate: 6h, Category: infrastructure)
- [ ] TASK-137: Ansible role updates — sync with K3s 1.30+ (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-138: Vault agent injection — sidecar for all services (Priority: P2, Estimate: 4h, Category: infrastructure)
- [ ] TASK-139: NFS migration — migrate PVs from local to NFS (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-140: etcd backup automation — CronJob with off-node storage (Priority: P1, Estimate: 3h, Category: infrastructure)
- [ ] TASK-141: Container image GC — configure imageGCThresholds (Priority: P2, Estimate: 1h, Category: infrastructure)
- [ ] TASK-142: Cost monitoring — Kubecost or resource tracking (Priority: P3, Estimate: 3h, Category: infrastructure)
- [ ] TASK-143: Resource quota enforcement — LimitRange + ResourceQuota per namespace (Priority: P1, Estimate: 3h, Category: infrastructure)
- [ ] TASK-144: Network policy audit — verify all inter-service traffic allowed (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-145: TLS cert auto-renewal — cert-manager automatic renewal test (Priority: P1, Estimate: 2h, Category: infrastructure)

### Documentation (5 tasks)

- [ ] TASK-146: Deployment runbook — full deploy procedure per service (Priority: P1, Estimate: 4h, Category: documentation)
- [ ] TASK-147: Security architecture doc — threat model + controls (Priority: P2, Estimate: 4h, Category: documentation)
- [ ] TASK-148: Network topology doc — diagram of all services + policies (Priority: P2, Estimate: 3h, Category: documentation)
- [ ] TASK-149: Backup/restore guide — step-by-step disaster recovery (Priority: P1, Estimate: 3h, Category: documentation)
- [ ] TASK-150: Capacity planning doc — resource forecasting (Priority: P3, Estimate: 2h, Category: documentation)

### Autoscaling — KEDA + Karpenter (15 tasks)

- [ ] TASK-231: Deploy KEDA operator via Helm chart (Priority: P1, Estimate: 1h, Category: autoscaling)
- [ ] TASK-232: Create KEDA ScaledObject for order-service — RabbitMQ queue depth trigger, min 2, max 10 (Priority: P1, Estimate: 2h, Category: autoscaling)
- [ ] TASK-233: Create KEDA ScaledObject for virtual-customer — cron trigger, scale to zero (Priority: P1, Estimate: 1.5h, Category: autoscaling)
- [ ] TASK-234: Create KEDA ScaledObject for ai-service — CPU/memory triggers, min 2 (Priority: P2, Estimate: 1h, Category: autoscaling)
- [ ] TASK-235: Create KEDA ScaledObject for product-service — CPU/memory triggers, min 2 (Priority: P2, Estimate: 1h, Category: autoscaling)
- [ ] TASK-236: Create KEDA ScaledObject for makeline-service — CPU/memory triggers, min 2 (Priority: P2, Estimate: 1h, Category: autoscaling)
- [ ] TASK-237: Create KEDA ScaledObject for store-front — CPU/memory triggers, min 2 (Priority: P2, Estimate: 1h, Category: autoscaling)
- [ ] TASK-238: Create KEDA ScaledObject for store-admin — CPU/memory triggers, min 2 (Priority: P2, Estimate: 1h, Category: autoscaling)
- [ ] TASK-239: Configure KEDA scale-to-zero for virtual-customer — cooldownPeriod 300s (Priority: P1, Estimate: 1h, Category: autoscaling)
- [ ] TASK-240: Configure KEDA scale-to-zero for virtual-worker — RabbitMQ trigger, min 0 (Priority: P1, Estimate: 1h, Category: autoscaling)
- [ ] TASK-241: Test KEDA autoscaling — enqueue 50 messages → order-service scales to 5 pods (Priority: P1, Estimate: 2h, Category: autoscaling)
- [ ] TASK-242: Test KEDA scale-to-zero — idle virtual-customer → pods → zero after 5 min (Priority: P2, Estimate: 1.5h, Category: autoscaling)
- [ ] TASK-243: Deploy Karpenter operator via Helm chart (Priority: P1, Estimate: 1.5h, Category: autoscaling)
- [ ] TASK-244: Create Karpenter NodePool with instance type requirements (Priority: P1, Estimate: 2h, Category: autoscaling)
- [ ] TASK-246: Test Karpenter node provisioning — create 20 pending pods → new node appears (Priority: P1, Estimate: 2h, Category: autoscaling)

---

## Daily Breakdown

### Day 1 — Thu 2026-09-18: CI Pipeline Foundation

| Task | Category | Estimate |
|---|---|---|
| TASK-089: Security scanning in CI | security | 4h |
| TASK-099: CI/CD for ai-service | deployment | 4h |

**Focus**: First service through full pipeline with security gates.

### Day 2 — Fri 2026-09-19: Pipeline Rollout

| Task | Category | Estimate |
|---|---|---|
| TASK-100: CI/CD for product-service | deployment | 3h |
| TASK-101: CI/CD for makeline-service | deployment | 3h |
| TASK-114: CI/CD pipeline tests | testing | 2h |

**Focus**: All core services in CI/CD. Validate pipeline end-to-end.

### Day 3 — Mon 2026-09-22: Secrets & Signing

| Task | Category | Estimate |
|---|---|---|
| TASK-072: Cosign signing | security | 4h |
| TASK-076: Sealed Secrets | security | 4h |

**Focus**: Supply chain security — signed images, sealed secrets in Git.

### Day 4 — Tue 2026-09-23: Vault Hardening

| Task | Category | Estimate |
|---|---|---|
| TASK-073: Vault dynamic secrets | security | 6h |
| TASK-087: Vault auto-unseal | security | 2h |

**Focus**: Vault production-ready with dynamic secrets and auto-unseal.

### Day 5 — Wed 2026-09-24: Policy Enforcement

| Task | Category | Estimate |
|---|---|---|
| TASK-074: OPA Gatekeeper tuning | security | 4h |
| TASK-079: AppArmor profiles | security | 4h |

**Focus**: Policy-as-code enforcement. Block non-compliant workloads.

### Day 6 — Thu 2026-09-25: GitOps & Blue-Green

| Task | Category | Estimate |
|---|---|---|
| TASK-096: ArgoCD GitOps pipeline | deployment | 6h |
| TASK-097: Argo Rollouts blue-green | deployment | 2h |

**Focus**: Full GitOps with blue-green deployment capability.

### Day 7 — Fri 2026-09-26: Testing Sprint

| Task | Category | Estimate |
|---|---|---|
| TASK-115: E2E checkout flow | testing | 6h |
| TASK-116: Load testing (1000 req/s) | testing | 2h |

**Focus**: Validate the entire system works under load.

### Day 8 — Mon 2026-09-29: Security Hardening

| Task | Category | Estimate |
|---|---|---|
| TASK-078: Network Policy hardening | security | 4h |
| TASK-082: Encryption at rest | security | 3h |
| TASK-086: kube-bench remediation | security | 1h |

**Focus**: Lock down networking, encryption, CIS compliance.

### Day 9 — Tue 2026-09-30: DR & Reliability

| Task | Category | Estimate |
|---|---|---|
| TASK-093: DR testing | security | 4h |
| TASK-117: Chaos experiment | testing | 4h |

**Focus**: Validate disaster recovery and chaos resilience.

### Day 10 — Wed 2026-10-01: Documentation & Wrap-up

| Task | Category | Estimate |
|---|---|---|
| TASK-146: Deployment runbook | documentation | 4h |
| TASK-147: Security architecture doc | documentation | 4h |

**Focus**: Document the new security posture and deployment flow.

---

## Burndown Chart

```
Hours Remaining
240 |
220 |████████████████████████████████████████████████████████████
200 |████████████████████████████████████████████████████████
180 |████████████████████████████████████████████████████
160 |████████████████████████████████████████████████
140 |████████████████████████████████████████████
120 |████████████████████████████████████████
100 |████████████████████████████████
 80 |████████████████████████████
 60 |████████████████████████
 40 |████████████████████
 20 |████████████████
  0 |████
    +----+----+----+----+----+----+----+----+----+----+
     D1   D2   D3   D4   D5   D6   D7   D8   D9  D10
     18/09 19/09 22/09 23/09 24/09 25/09 26/09 29/09 30/09 01/10
```

## Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Cosign key management compromise | Supply chain attack | Low | Use keyless signing with OIDC identity |
| Sealed Secrets controller crash | Secrets unavailable | Medium | Backup encryption keys, document manual decrypt |
| Vault auto-unseal transit failure | All services fail to start | Medium | Keep manual unseal keys as fallback |
| OPA Gatekeeper blocks all deployments | Deployment halt | Medium | Dry-run mode first, staged enforcement |
| Blue-green doubles resource usage | Cluster capacity exhaustion | Medium | Scale down old version quickly, set rollout timeouts |
| SonarQube memory pressure | Cluster OOM | Medium | Set resource limits, schedule on dedicated node |

## Retrospective Template

### What went well?
- 

### What could be improved?
- 

### Action items for Sprint 3?
- 

### Velocity
| Metric | Value |
|---|---|
| Committed | 80 tasks |
| Completed | __ / 80 |
| Carry-over | __ tasks |
| Average estimate accuracy | __% |

---

*Sprint 2 Planning — 2026-09-18*
