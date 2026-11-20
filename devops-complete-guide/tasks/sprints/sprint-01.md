# Sprint 01: Foundation & Incident Response

## Sprint Info

| Field | Value |
|---|---|
| **Sprint** | Sprint 1 |
| **Duration** | 2026-09-04 → 2026-09-17 (10 working days) |
| **Team** | DevOps/DevSecOps |
| **Cluster** | k3s on 2 PCs via Incus + Tailscale |

## Cluster Topology

| Node | IP (Tailscale) | Role |
|---|---|---|
| k3s-master | 10.195.94.80 | Control Plane + etcd |
| k3s-worker-1 | 10.195.94.81 | Worker |
| k3s-worker-2 | 100.100.13.113 | Worker (via Tailscale) |
| vault | 10.195.94.200 | HashiCorp Vault (dedicated) |
| monitoring | 10.195.94.210 | Prometheus + Grafana (dedicated) |
| MetalLB Pool | 10.195.94.100-150 | Load Balancer |

## Microservices

ai-service, makeline-service, order-service, product-service, store-front, store-admin, virtual-customer, virtual-worker

## Sprint Goal

> Get the k3s cluster production-ready and establish incident response basics. By end of Sprint 1, all 8 microservices deploy cleanly, monitoring catches failures, and the team has a documented incident response workflow.

## Capacity

| Role | Headcount | Hours/Day | Total Hours |
|---|---|---|---|
| DevOps Engineer | 1 | 8 | 80 |
| Security Lead | 1 | 6 | 60 |
| SRE | 1 | 8 | 80 |
| **Total** | **3** | — | **220** |

Estimated task points: ~200h (leaves buffer for meetings, incidents, context switching).

---

## Backlog

### Debugging (20 tasks)

- [ ] TASK-001: Pod CrashLooping — diagnose and resolve CrashLoopBackOff on all services (Priority: P1, Estimate: 4h, Category: debugging)
- [ ] TASK-002: OOM kills — identify memory limits causing kills, adjust resource requests (Priority: P1, Estimate: 3h, Category: debugging)
- [ ] TASK-003: DNS failures — CoreDNS resolution failures in cluster (Priority: P1, Estimate: 3h, Category: debugging)
- [ ] TASK-004: TLS expiry — expired certs on ingress, renew and set auto-renewal (Priority: P1, Estimate: 2h, Category: debugging)
- [ ] TASK-005: Disk alerts — /var/lib/kubelet filling up, clean images and logs (Priority: P1, Estimate: 2h, Category: debugging)
- [ ] TASK-006: Ingress 502/503 — fix nginx-ingress upstream connection errors (Priority: P1, Estimate: 4h, Category: debugging)
- [ ] TASK-007: PVC Pending — investigate and resolve stuck PersistentVolumeClaims (Priority: P2, Estimate: 3h, Category: debugging)
- [ ] TASK-008: NodeNotReady — diagnose k3s-worker-2 NotReady condition (Priority: P1, Estimate: 2h, Category: debugging)
- [ ] TASK-009: k3s kubelet crash — kubelet crash-loop on worker nodes (Priority: P1, Estimate: 4h, Category: debugging)
- [ ] TASK-010: Container image pull backoff — fix imagePullBackOff for private registry (Priority: P2, Estimate: 2h, Category: debugging)
- [ ] TASK-011: ConfigMap not mounting — volumes not appearing in pods (Priority: P2, Estimate: 2h, Category: debugging)
- [ ] TASK-012: Vault seal issues — Vault auto-unseal not working after reboot (Priority: P1, Estimate: 3h, Category: debugging)
- [ ] TASK-013: Prometheus targets down — scrape targets unreachable (Priority: P2, Estimate: 3h, Category: debugging)
- [ ] TASK-014: Grafana not loading — dashboard 502 errors (Priority: P2, Estimate: 2h, Category: debugging)
- [ ] TASK-015: ArgoCD sync failures — apps out of sync, sync loop (Priority: P2, Estimate: 3h, Category: debugging)
- [ ] TASK-016: Helm release failed — broken Helm releases stuck in pending (Priority: P2, Estimate: 2h, Category: debugging)
- [ ] TASK-017: Terraform state lock — stuck state lock after failed apply (Priority: P2, Estimate: 1h, Category: debugging)
- [ ] TASK-018: MetalLB not assigning IPs — load balancer IP pending (Priority: P2, Estimate: 3h, Category: debugging)
- [ ] TASK-019: cert-manager challenge failing — ACME challenges stuck in pending (Priority: P2, Estimate: 2h, Category: debugging)
- [ ] TASK-020: Flannel CNI errors — network plugin errors in kubelet log (Priority: P1, Estimate: 3h, Category: debugging)

### Infrastructure (15 tasks)

- [ ] TASK-021: Fix proc-sys-rw on Incus containers — /proc/sys remount issue (Priority: P1, Estimate: 2h, Category: infrastructure)
- [ ] TASK-022: Reconcile Terraform drift — detect and fix infrastructure drift (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-023: Update Ansible common role — sync with latest K8s versions (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-024: Add worker node — provision k3s-worker-2 via Incus (Priority: P2, Estimate: 4h, Category: infrastructure)
- [ ] TASK-025: Scale Incus resources — adjust CPU/memory for worker nodes (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-026: NFS storage class — create nfs-csi StorageClass (Priority: P1, Estimate: 3h, Category: infrastructure)
- [ ] TASK-027: etcd backup strategy — automated etcd snapshots (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-028: Tailscale ACLs — restrict cluster node communication (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-029: DNS records — configure Tailscale MagicDNS for services (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-030: Log rotation — configure journald and container log rotation (Priority: P2, Estimate: 1h, Category: infrastructure)
- [ ] TASK-031: Sysctl tuning — optimize kernel params for K8s workloads (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-032: K8s version update — update k3s to latest stable (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-033: Disk usage alerts — Prometheus alert for /var/lib/kubelet (Priority: P2, Estimate: 1h, Category: infrastructure)
- [ ] TASK-034: Monitoring setup — deploy Prometheus + Grafana stack (Priority: P1, Estimate: 6h, Category: infrastructure)
- [ ] TASK-035: Resource optimization — right-size pod requests/limits (Priority: P2, Estimate: 4h, Category: infrastructure)

### Security (10 tasks)

- [ ] TASK-036: Patch CVEs in base images — rebuild images with latest base (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-037: Rotate TLS certs — replace all expiring certificates (Priority: P1, Estimate: 2h, Category: security)
- [ ] TASK-038: Audit RBAC — review all ClusterRoleBindings and RoleBindings (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-039: Trivy scan baseline — scan all running images for vulnerabilities (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-040: OPA policies — deploy basic Gatekeeper policies (Priority: P2, Estimate: 6h, Category: security)
- [ ] TASK-041: Falco rules — deploy Falco with custom K8s rules (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-042: Network Policies — deny-all default, allow-by-label (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-043: Pod Security Standards — enforce restricted PSS on namespaces (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-044: Vault token rotation — implement token TTL and rotation (Priority: P2, Estimate: 2h, Category: security)
- [ ] TASK-045: Docker Hub access review — audit pull secrets and rate limits (Priority: P2, Estimate: 1h, Category: security)

### Deployment (10 tasks)

- [ ] TASK-046: Deploy order-service hotfix — push and verify hotfix (Priority: P1, Estimate: 2h, Category: deployment)
- [ ] TASK-047: Rollback procedure — document and test kubectl rollout undo (Priority: P1, Estimate: 3h, Category: deployment)
- [ ] TASK-048: ArgoCD app setup — configure ArgoCD for all 8 services (Priority: P1, Estimate: 6h, Category: deployment)
- [ ] TASK-049: Helm values update — update all charts with prod values (Priority: P2, Estimate: 4h, Category: deployment)
- [ ] TASK-050: Namespace strategy — create dev/staging/prod namespaces (Priority: P1, Estimate: 2h, Category: deployment)
- [ ] TASK-051: Prometheus stack — deploy kube-prometheus-stack via Helm (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-052: Grafana dashboards — import K8s cluster dashboard (Priority: P2, Estimate: 3h, Category: deployment)
- [ ] TASK-053: Vault Helm deploy — deploy Vault via Helm with HA config (Priority: P2, Estimate: 4h, Category: deployment)
- [ ] TASK-054: nginx-ingress setup — deploy and configure ingress controller (Priority: P1, Estimate: 3h, Category: deployment)
- [ ] TASK-055: cert-manager config — deploy cert-manager with Let's Encrypt (Priority: P1, Estimate: 3h, Category: deployment)

### Testing (5 tasks)

- [ ] TASK-056: Cluster connectivity tests — verify node-to-node communication (Priority: P1, Estimate: 2h, Category: testing)
- [ ] TASK-057: Service health checks — /healthz endpoints for all services (Priority: P1, Estimate: 2h, Category: testing)
- [ ] TASK-058: DNS resolution validation — internal and external DNS tests (Priority: P1, Estimate: 1h, Category: testing)
- [ ] TASK-059: Load balancer validation — MetalLB IP assignment and routing (Priority: P1, Estimate: 2h, Category: testing)
- [ ] TASK-060: Monitoring alert tests — fire test alerts, verify Alertmanager (Priority: P2, Estimate: 2h, Category: testing)

### Code Quality (5 tasks)

- [ ] TASK-061: Dockerfile hadolint fixes — lint all Dockerfiles, fix warnings (Priority: P2, Estimate: 3h, Category: code-quality)
- [ ] TASK-062: ESLint config — standardize ESLint across JS services (Priority: P3, Estimate: 2h, Category: code-quality)
- [ ] TASK-063: Pre-commit hooks — add hadolint, eslint, shellcheck hooks (Priority: P2, Estimate: 2h, Category: code-quality)
- [ ] TASK-064: PR template — create standard PR template for all repos (Priority: P3, Estimate: 1h, Category: code-quality)
- [ ] TASK-065: Code coverage setup — configure lcov/cobertura in CI (Priority: P3, Estimate: 2h, Category: code-quality)

### Documentation (5 tasks)

- [ ] TASK-066: Incident response runbook — step-by-step IR procedure (Priority: P1, Estimate: 4h, Category: documentation)
- [ ] TASK-067: Architecture ADR — document current cluster architecture (Priority: P2, Estimate: 3h, Category: documentation)
- [ ] TASK-068: Vault unseal docs — manual unseal procedure and key storage (Priority: P1, Estimate: 2h, Category: documentation)
- [ ] TASK-069: Troubleshooting guide — common issues and fixes (Priority: P2, Estimate: 3h, Category: documentation)
- [ ] TASK-070: Onboarding guide — new team member setup instructions (Priority: P3, Estimate: 2h, Category: documentation)

---

## Daily Breakdown

### Day 1 — Thu 2026-09-04: Cluster Stabilization

| Task | Category | Estimate |
|---|---|---|
| TASK-001: Pod CrashLooping | debugging | 4h |
| TASK-008: NodeNotReady | debugging | 2h |
| TASK-021: Fix proc-sys-rw | infrastructure | 2h |

**Focus**: Get all nodes Ready and pods running. Blocker for all other work.

### Day 2 — Fri 2026-09-05: Core Infrastructure

| Task | Category | Estimate |
|---|---|---|
| TASK-003: DNS failures | debugging | 3h |
| TASK-026: NFS storage class | infrastructure | 3h |
| TASK-054: nginx-ingress setup | deployment | 2h |

**Focus**: Networking stack — DNS, storage, ingress must work before services deploy.

### Day 3 — Mon 2026-09-08: Security & Certs

| Task | Category | Estimate |
|---|---|---|
| TASK-004: TLS expiry | debugging | 2h |
| TASK-037: Rotate TLS certs | security | 2h |
| TASK-055: cert-manager config | deployment | 3h |
| TASK-045: Docker Hub access review | security | 1h |

**Focus**: Get TLS working end-to-end with auto-renewal.

### Day 4 — Tue 2026-09-09: Monitoring Foundation

| Task | Category | Estimate |
|---|---|---|
| TASK-034: Monitoring setup | infrastructure | 6h |
| TASK-051: Prometheus stack | deployment | 2h |

**Focus**: Deploy full kube-prometheus-stack. Alerting baseline.

### Day 5 — Wed 2026-09-10: Security Baseline

| Task | Category | Estimate |
|---|---|---|
| TASK-039: Trivy scan baseline | security | 3h |
| TASK-042: Network Policies | security | 4h |
| TASK-036: Patch CVEs in base images | security | 1h |

**Focus**: Security scan all images, deploy deny-all NetworkPolicy.

### Day 6 — Thu 2026-09-11: GitOps & Deployment

| Task | Category | Estimate |
|---|---|---|
| TASK-048: ArgoCD app setup | deployment | 6h |
| TASK-050: Namespace strategy | deployment | 2h |

**Focus**: ArgoCD manages all 8 services. Namespace isolation.

### Day 7 — Fri 2026-09-12: Debugging Sprint

| Task | Category | Estimate |
|---|---|---|
| TASK-002: OOM kills | debugging | 3h |
| TASK-006: Ingress 502/503 | debugging | 4h |
| TASK-010: Image pull backoff | debugging | 1h |

**Focus**: Clear remaining CrashLoop/OOM/502 issues.

### Day 8 — Mon 2026-09-15: Vault & Secrets

| Task | Category | Estimate |
|---|---|---|
| TASK-012: Vault seal issues | debugging | 3h |
| TASK-053: Vault Helm deploy | deployment | 4h |
| TASK-068: Vault unseal docs | documentation | 1h |

**Focus**: Vault operational with unseal docs.

### Day 9 — Tue 2026-09-16: Reliability & Testing

| Task | Category | Estimate |
|---|---|---|
| TASK-027: etcd backup strategy | infrastructure | 4h |
| TASK-057: Service health checks | testing | 2h |
| TASK-059: Load balancer validation | testing | 2h |

**Focus**: Backups working, health checks passing, LB validated.

### Day 10 — Wed 2026-09-17: Documentation & Wrap-up

| Task | Category | Estimate |
|---|---|---|
| TASK-066: Incident response runbook | documentation | 4h |
| TASK-067: Architecture ADR | documentation | 2h |
| TASK-069: Troubleshooting guide | documentation | 2h |

**Focus**: Document everything. Retro prep. Sprint review.

---

## Burndown Chart

```
Hours Remaining
220 |
200 |████████████████████████████████████████████████████
180 |██████████████████████████████████████████████
160 |████████████████████████████████████████
140 |████████████████████████████████████
120 |████████████████████████████████
100 |████████████████████████████
 80 |████████████████████████
 60 |████████████████████
 40 |████████████████
 20 |████████████
  0 |████
    +----+----+----+----+----+----+----+----+----+----+
     D1   D2   D3   D4   D5   D6   D7   D8   D9  D10
     04/09 05/09 08/09 09/09 10/09 11/09 12/09 15/09 16/09 17/09
```

## Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| k3s Incus container loses /proc/sys rw | kubelet crash-loop | High | TASK-021 on Day 1, proc-sys-rw.service |
| MetalLB IP pool exhausted (50 IPs for 8 services) | Service unavailable | Low | Reserve IPs, plan pool expansion |
| Vault sealed after power loss | All secrets unavailable | Medium | Auto-unseal with cloud KMS or document manual unseal |
| Tailscale network partition | Cluster split-brain | Low | Monitoring on all nodes, alert on NotReady |
| etcd corruption without backups | Total cluster loss | High | TASK-027 automated snapshots + off-node storage |
| Docker Hub rate limiting | Deployment failures | Medium | Mirror to local registry, use pull secrets |

## Retrospective Template

### What went well?
- 

### What could be improved?
- 

### Action items for Sprint 2?
- 

### Velocity
| Metric | Value |
|---|---|
| Committed | 70 tasks |
| Completed | __ / 70 |
| Carry-over | __ tasks |
| Average estimate accuracy | __% |

---

*Sprint 1 Planning — 2026-09-04*
