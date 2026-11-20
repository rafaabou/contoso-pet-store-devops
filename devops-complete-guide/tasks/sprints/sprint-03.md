# Sprint 03: Observability, Reliability & Production Hardening

## Sprint Info

| Field | Value |
|---|---|
| **Sprint** | Sprint 3 |
| **Duration** | 2026-10-02 → 2026-10-15 (10 working days) |
| **Team** | DevOps/DevSecOps |
| **Cluster** | k3s on 2 PCs via Incus + Tailscale |

## Cluster Topology (post-Sprint 2)

| Node | IP (Tailscale) | Role |
|---|---|---|
| k3s-master | 10.195.94.80 | Control Plane + etcd |
| k3s-worker-1 | 10.195.94.81 | Worker |
| k3s-worker-2 | 100.100.13.113 | Worker (via Tailscale) |
| vault | 10.195.94.200 | HashiCorp Vault (dedicated) |
| monitoring | 10.195.94.210 | Prometheus + Grafana (dedicated) |
| MetalLB Pool | 10.195.94.100-150 | Load Balancer |

## Sprint Goal

> Achieve full observability with SLOs, complete the service mesh, run chaos experiments, and harden production. By end of Sprint 3, the platform is production-ready with alerting, tracing, logging, and documented runbooks for every failure mode.

## Capacity

| Role | Headcount | Hours/Day | Total Hours |
|---|---|---|---|
| DevOps Engineer | 1 | 8 | 80 |
| Security Lead | 1 | 8 | 80 |
| SRE | 1 | 8 | 80 |
| **Total** | **3** | — | **240** |

Estimated task points: ~215h (leaves buffer for incident response and carry-over).

---

## Backlog

### Monitoring (25 tasks)

- [ ] TASK-151: Grafana dashboards — all services (ai, makeline, order, product, store-front, store-admin, virtual-customer, virtual-worker) (Priority: P1, Estimate: 6h, Category: monitoring)
- [ ] TASK-152: Prometheus alerts — CPU > 80%, memory > 85%, pod restart > 5, error rate > 1% (Priority: P1, Estimate: 4h, Category: monitoring)
- [ ] TASK-153: Alertmanager integration — Slack/PagerDuty routing (Priority: P1, Estimate: 3h, Category: monitoring)
- [ ] TASK-154: SLO burn rate alerts — 1%, 5%, 10% error budget burn (Priority: P1, Estimate: 4h, Category: monitoring)
- [ ] TASK-155: Custom metrics in ai-service — request duration histogram, model inference latency (Priority: P2, Estimate: 4h, Category: monitoring)
- [ ] TASK-156: Prometheus scrape configs — service monitor for all 8 services (Priority: P1, Estimate: 3h, Category: monitoring)
- [ ] TASK-157: kube-state-metrics alerts — deployment replica mismatch, PVC bound false (Priority: P1, Estimate: 3h, Category: monitoring)
- [ ] TASK-158: Latency monitoring — p50/p95/p99 per service (Priority: P1, Estimate: 3h, Category: monitoring)
- [ ] TASK-159: Error rate dashboard — 4xx/5xx per service over time (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-160: Log-based alerts — OOM, CrashLoop, image pull errors (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-161: Capacity planning dashboard — CPU/memory/disk forecasting (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-162: Uptime monitoring — external synthetic checks (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-163: DiskUsage alerts — /var/lib/kubelet > 80% (Priority: P1, Estimate: 1h, Category: monitoring)
- [ ] TASK-164: CPU/Memory alerts — node-level resource exhaustion (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-165: Deployment frequency dashboard — DORA metrics (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-166: DORA metrics — lead time, MTTR, change failure rate (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-167: Service dependency map — visualize service mesh topology (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-168: On-call rotation — PagerDuty schedule setup (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-169: Escalation policy — L1/L2/L3 escalation rules (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-170: MTTR dashboard — mean time to recovery tracking (Priority: P2, Estimate: 2h, Category: monitoring)
- [ ] TASK-171: Cost allocation — namespace-level cost breakdown (Priority: P3, Estimate: 3h, Category: monitoring)
- [ ] TASK-172: Prometheus retention — configure 30-day retention + Thanos (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-173: Grafana alerting — dashboard-based alerts for business metrics (Priority: P2, Estimate: 3h, Category: monitoring)
- [ ] TASK-174: Node monitoring — host-level metrics (disk, network, processes) (Priority: P1, Estimate: 2h, Category: monitoring)
- [ ] TASK-175: Cluster health dashboard — etcd, scheduler, controller-manager (Priority: P1, Estimate: 3h, Category: monitoring)

### Security (15 tasks)

- [ ] TASK-176: Falco tuning — reduce false positives from known workloads (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-177: Tetragon eBPF setup — deploy Cilium Tetragon for runtime visibility (Priority: P2, Estimate: 6h, Category: security)
- [ ] TASK-178: AppArmor profile updates — tighten based on production behavior (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-179: Seccomp profile updates — refine syscall allowlists (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-180: CIS benchmark remediation — fix remaining kube-bench findings (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-181: Security event alerting — Falco→Alertmanager→Slack pipeline (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-182: Container runtime security — gVisor/Kata evaluation (Priority: P3, Estimate: 6h, Category: security)
- [ ] TASK-183: Network segmentation review — verify inter-namespace isolation (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-184: Secrets access audit — who accessed what secret, when (Priority: P1, Estimate: 3h, Category: security)
- [ ] TASK-185: Compliance scanning — kube-bench + Trivy operator (Priority: P2, Estimate: 4h, Category: security)
- [ ] TASK-186: Vulnerability management process — triage workflow SLA (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-187: Security training materials — team security playbook (Priority: P3, Estimate: 4h, Category: security)
- [ ] TASK-188: Incident response drill — simulated breach exercise (Priority: P1, Estimate: 4h, Category: security)
- [ ] TASK-189: Penetration test planning — scope and methodology doc (Priority: P2, Estimate: 3h, Category: security)
- [ ] TASK-190: Security metrics dashboard — vuln count, MTTV, patch compliance (Priority: P2, Estimate: 3h, Category: security)

### Testing (15 tasks)

- [ ] TASK-191: Chaos engineering — Litmus experiments for pod/node failure (Priority: P1, Estimate: 6h, Category: testing)
- [ ] TASK-192: Load testing — full scale 1000 req/s sustained for 1h (Priority: P1, Estimate: 6h, Category: testing)
- [ ] TASK-193: Failover testing — master node failure simulation (Priority: P1, Estimate: 4h, Category: testing)
- [ ] TASK-194: Monitoring alert validation — fire all alerts, verify routing (Priority: P1, Estimate: 3h, Category: testing)
- [ ] TASK-195: Log query testing — verify Loki/ELK queries return data (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-196: Trace collection validation — Jaeger/Tempo traces for all services (Priority: P2, Estimate: 3h, Category: testing)
- [ ] TASK-197: E2E regression suite — automated checkout + order flow (Priority: P1, Estimate: 6h, Category: testing)
- [ ] TASK-198: API contract testing — Pact or Schemathesis for all APIs (Priority: P2, Estimate: 4h, Category: testing)
- [ ] TASK-199: Database failover test — primary failover + recovery (Priority: P1, Estimate: 3h, Category: testing)
- [ ] TASK-200: Cache invalidation test — Redis/Memcached eviction (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-201: Rate limiting test — verify throttling at 100 req/s (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-202: Circuit breaker test — downstream failure triggers breaker (Priority: P2, Estimate: 3h, Category: testing)
- [ ] TASK-203: Canary deployment test — verify canary traffic split (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-204: Blue-green switch test — traffic cutover validation (Priority: P2, Estimate: 2h, Category: testing)
- [ ] TASK-205: Rollback drill — deploy bad version, rollback, verify (Priority: P1, Estimate: 3h, Category: testing)

### Deployment (10 tasks)

- [ ] TASK-206: Istio service mesh — deploy Istio on all namespaces (Priority: P1, Estimate: 8h, Category: deployment)
- [ ] TASK-207: Kiali dashboards — service mesh observability (Priority: P2, Estimate: 3h, Category: deployment)
- [ ] TASK-208: Jaeger tracing setup — distributed tracing for all services (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-209: OpenTelemetry collector — deploy OTel collector for traces/metrics (Priority: P1, Estimate: 4h, Category: deployment)
- [ ] TASK-210: Fluentd/Loki logging — centralized log aggregation (Priority: P1, Estimate: 6h, Category: deployment)
- [ ] TASK-211: EFK stack — Elasticsearch + Fluentd + Kibana (Priority: P2, Estimate: 6h, Category: deployment)
- [ ] TASK-212: Service mesh mTLS — enforce mutual TLS across mesh (Priority: P1, Estimate: 3h, Category: deployment)
- [ ] TASK-213: Traffic management — canary, header-based routing (Priority: P2, Estimate: 4h, Category: deployment)
- [ ] TASK-214: Fault injection — Istio VirtualService fault injection (Priority: P2, Estimate: 3h, Category: deployment)
- [ ] TASK-215: Circuit breaker config — Istio outlier detection (Priority: P2, Estimate: 3h, Category: deployment)

### Infrastructure (10 tasks)

- [ ] TASK-216: Fluentd log aggregation — daemonset with parsers (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-217: Loki log storage — Grafana Loki for log queries (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-218: Promtail agent setup — ship logs from all nodes (Priority: P1, Estimate: 3h, Category: infrastructure)
- [ ] TASK-219: Log retention policies — 30-day hot, 90-day cold (Priority: P2, Estimate: 2h, Category: infrastructure)
- [ ] TASK-220: Vault dynamic credentials — auto-rotate DB passwords (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-221: Terraform workspace management — dev/staging/prod workspaces (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-222: Ansible idempotency verification — verify all roles idempotent (Priority: P2, Estimate: 3h, Category: infrastructure)
- [ ] TASK-223: etcd disaster recovery drill — restore from backup to new cluster (Priority: P1, Estimate: 4h, Category: infrastructure)
- [ ] TASK-224: Node autoscaling — Cluster API or manual scaling (Priority: P3, Estimate: 4h, Category: infrastructure)
- [ ] TASK-225: Storage class optimization — tune NFS mount options (Priority: P2, Estimate: 2h, Category: infrastructure)

### Documentation (5 tasks)

- [ ] TASK-226: Operations runbook — full ops procedures for all components (Priority: P1, Estimate: 6h, Category: documentation)
- [ ] TASK-227: Troubleshooting decision tree — flowchart for common failures (Priority: P2, Estimate: 4h, Category: documentation)
- [ ] TASK-228: Architecture decision records — document all ADRs (Priority: P2, Estimate: 4h, Category: documentation)
- [ ] TASK-229: Post-incident review template — PIR format and process (Priority: P1, Estimate: 2h, Category: documentation)
- [ ] TASK-230: Production readiness checklist — go/no-go criteria (Priority: P1, Estimate: 3h, Category: documentation)

### Autoscaling — KEDA + Karpenter (5 tasks, continuation from Sprint 2)

- [ ] TASK-245: Configure Karpenter disruption budgets — maxUnavailable, consolidation schedules (Priority: P2, Estimate: 1.5h, Category: autoscaling)
- [ ] TASK-247: Test Karpenter node consolidation — delete pods → underutilized node removed (Priority: P2, Estimate: 1.5h, Category: autoscaling)
- [ ] TASK-248: Integrate KEDA + Vault — TriggerAuthentication for RabbitMQ credentials (Priority: P2, Estimate: 2h, Category: autoscaling)
- [ ] TASK-249: Create Grafana dashboard for KEDA scaling events + Karpenter node metrics (Priority: P2, Estimate: 2h, Category: autoscaling)
- [ ] TASK-250: Document autoscaling strategy — decision tree (KEDA vs HPA vs Karpenter) (Priority: P3, Estimate: 2h, Category: autoscaling)

---

## Daily Breakdown

### Day 1 — Thu 2026-10-02: Observability Foundation

| Task | Category | Estimate |
|---|---|---|
| TASK-156: Prometheus scrape configs | monitoring | 3h |
| TASK-153: Alertmanager integration | monitoring | 3h |
| TASK-174: Node monitoring | monitoring | 2h |

**Focus**: All targets scraping, alerts routing to Slack.

### Day 2 — Fri 2026-10-03: Service Mesh

| Task | Category | Estimate |
|---|---|---|
| TASK-206: Istio service mesh | deployment | 8h |

**Focus**: Full day — Istio install, sidecar injection, basic routing.

### Day 3 — Mon 2026-10-06: Tracing & Logging

| Task | Category | Estimate |
|---|---|---|
| TASK-208: Jaeger tracing setup | deployment | 4h |
| TASK-209: OpenTelemetry collector | deployment | 4h |

**Focus**: Distributed tracing end-to-end across all services.

### Day 4 — Tue 2026-10-07: Centralized Logging

| Task | Category | Estimate |
|---|---|---|
| TASK-217: Loki log storage | infrastructure | 4h |
| TASK-216: Fluentd log aggregation | infrastructure | 4h |

**Focus**: All logs flowing into Loki, queryable from Grafana.

### Day 5 — Wed 2026-10-08: SLOs & Alerting

| Task | Category | Estimate |
|---|---|---|
| TASK-154: SLO burn rate alerts | monitoring | 4h |
| TASK-152: Prometheus alerts (all scenarios) | monitoring | 4h |

**Focus**: SLO-based alerting, comprehensive alert coverage.

### Day 6 — Thu 2026-10-09: Chaos & Reliability

| Task | Category | Estimate |
|---|---|---|
| TASK-191: Chaos engineering | testing | 6h |
| TASK-193: Failover testing | testing | 2h |

**Focus**: Chaos experiments — pod kill, node failure, network partition.

### Day 7 — Fri 2026-10-10: Load & Performance

| Task | Category | Estimate |
|---|---|---|
| TASK-192: Load testing (1000 req/s) | testing | 6h |
| TASK-201: Rate limiting test | testing | 2h |

**Focus**: Validate system under production-level load.

### Day 8 — Mon 2026-10-13: Security Hardening

| Task | Category | Estimate |
|---|---|---|
| TASK-176: Falco tuning | security | 4h |
| TASK-180: CIS benchmark remediation | security | 4h |

**Focus**: Reduce alert noise, fix remaining CIS findings.

### Day 9 — Tue 2026-10-14: E2E Validation

| Task | Category | Estimate |
|---|---|---|
| TASK-197: E2E regression suite | testing | 6h |
| TASK-188: Incident response drill | security | 2h |

**Focus**: Full regression + IR drill. Validate everything works.

### Day 10 — Wed 2026-10-15: Documentation & Production Readiness

| Task | Category | Estimate |
|---|---|---|
| TASK-226: Operations runbook | documentation | 6h |
| TASK-230: Production readiness checklist | documentation | 2h |

**Focus**: Finalize all documentation. Go/no-go decision.

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
     02/10 03/10 06/10 07/10 08/10 09/10 10/10 13/10 14/10 15/10
```

## Risks

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| Istio sidecar increases memory by 50MB/pod | Cluster OOM on workers | Medium | Monitor node memory, set Istio resource limits |
| Loki storage growth exceeds disk | Log queries fail | Medium | Retention policies, compaction, alert on disk |
| Chaos experiments cause cascading failures | Extended outage | Medium | Run in staging first, time-box experiments |
| Jaeger trace storage fills disk | Tracing stops | Medium | Short retention (7 days), sampling rate tuning |
| eBPF kernel requirements not met | Tetragon fails | High | Check kernel version first, fallback to Falco |
| Load test exceeds cluster capacity | Services crash | Medium | Gradual ramp-up, abort thresholds |
| Istio mTLS breaks non-mesh services | External traffic blocked | Medium | PERMISSIVE mode first, gradual STRICT |

## Retrospective Template

### What went well?
- 

### What could be improved?
- 

### Sprint 1-3 Overall Retrospective?
- 

### Velocity
| Metric | Value |
|---|---|
| Committed | 80 tasks |
| Completed | __ / 80 |
| Carry-over | __ tasks |
| Average estimate accuracy | __% |

### Sprint 1-3 Summary
| Sprint | Tasks Committed | Tasks Completed | Velocity |
|---|---|---|---|
| Sprint 1 | 70 | __ | __ |
| Sprint 2 | 80 | __ | __ |
| Sprint 3 | 80 | __ | __ |
| **Total** | **230** | __ | __ |

---

*Sprint 3 Planning — 2026-10-02*
