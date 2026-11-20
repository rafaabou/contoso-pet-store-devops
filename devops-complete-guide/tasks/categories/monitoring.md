# Monitoring Tasks

## Task List

- [ ] TASK-166: Create Grafana dashboard for order-service
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `grafana` `dashboard` `order-service`
  - **Services:** order-service, Grafana
  - **Steps:** Design panel layout (request rate, error rate, p50/p95/p99 latency, saturation), write Prometheus queries, import as JSON dashboard, configure variables for namespace/pod, share with team via Grafana folder permissions

- [ ] TASK-167: Set up Prometheus alert for PodCrashLooping
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `prometheus` `alerting` `kubernetes`
  - **Services:** Prometheus, kube-state-metrics
  - **Steps:** Write PromQL rule `kube_pod_container_status_restarts_total > 5 within 1h`, add to alerting rules file, validate with promtool, deploy via Helm values, verify alert fires on test pod restart loop

- [ ] TASK-168: Configure Alertmanager Slack and PagerDuty integration
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `alertmanager` `slack` `pagerduty` `notification`
  - **Services:** Alertmanager, Slack workspace, PagerDuty
  - **Steps:** Create Slack webhook, obtain PagerDuty service key, write alertmanager.yml receivers and route tree, configure severity-based routing (P0→PagerDuty+Slack, P1→Slack, P2→Slack-thread), test with amtool, add inhibition rules for nested alerts

- [ ] TASK-169: Tune alert thresholds to reduce noise
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `alerting` `noise-reduction` `sre`
  - **Services:** Prometheus, Alertmanager
  - **Steps:** Audit last 30 days of fired alerts, identify top 10 noisy alerts, add `for` duration clauses (minimum 5m), add severity labels, implement inhibit_rules for cause→effect chains, add group_wait/group_interval tuning, document tuning rationale in runbook

- [ ] TASK-170: Set up SLO burn rate alerts
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `slo` `burn-rate` `reliability`
  - **Services:** Prometheus, Alertmanager, order-service, store-front
  - **Steps:** Define SLIs (availability=success ratio, latency= RequestsUnderTarget), set SLO targets (99.9% avail, 99% under 500ms), write multi-window burn rate alerts (1h/5m for P0, 6h/30m for P1), create Prometheus recording rules, validate with historical data, wire into Alertmanager with SLO-specific receiver

- [ ] TASK-171: Create dashboard for cluster health
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `grafana` `cluster` `kubernetes`
  - **Services:** Grafana, Prometheus, kube-state-metrics, node-exporter
  - **Steps:** Build dashboard with panels: CPU/Memory/Disk per node, pod count by namespace, API server request rate and latency, etcd leader changes, scheduler predicate failures, controller manager work queue depth. Use template variables for cluster selection. Import k8s pre-built dashboard as base

- [ ] TASK-172: Add custom metrics to ai-service
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `prometheus` `custom-metrics` `ai-service`
  - **Services:** ai-service, Prometheus
  - **Steps:** Instrument inference latency histogram, model load time gauge, prediction confidence distribution, queue depth gauge. Use prometheus_client library, expose /metrics endpoint, write ServiceMonitor CRD for Prometheus auto-discovery, document metric names in service README

- [ ] TASK-173: Configure Prometheus scrape configs for all services
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `prometheus` `scrape` `service-discovery`
  - **Services:** Prometheus, all microservices
  - **Steps:** Create ServiceMonitor CRDs per namespace, configure relabeling for app label, set scrape_interval=15s and scrape_timeout=10s, enable metrics endpoint probes, verify targets in Prometheus UI (Status→Targets), remove any static_configs in favor of CRD discovery

- [ ] TASK-174: Set up kube-state-metrics alerts for deployment and node issues
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `kube-state-metrics` `alerting` `kubernetes`
  - **Services:** kube-state-metrics, Prometheus
  - **Steps:** Add alerts for: DeploymentReplicasMismatch, NodeNotReady, PersistentVolumeUsageHigh, JobFailed, CronJobSuspended, DaemonSetMisscheduled. Write PromQL rules, group by namespace and alertname, add annotations with runbook URLs, deploy and test each with synthetic conditions

- [ ] TASK-175: Create latency monitoring for store-front
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `latency` `store-front` `monitoring`
  - **Services:** store-front, Prometheus, Grafana
  - **Steps:** Add histogram metrics for page load time, API call duration, asset load time. Configure client-side RUM via OpenTelemetry JS SDK. Build Grafana dashboard with percentile panels, heatmaps, and slow-query drill-down. Set up alerts for p95 latency exceeding 2s SLA

- [ ] TASK-176: Set up error rate dashboard
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `error-rate` `grafana` `dashboard`
  - **Services:** Grafana, Prometheus
  - **Steps:** Write PromQL for HTTP 5xx ratio per service, GRPC error ratio, exception count by type. Build dashboard with: overall error rate trend, per-service breakdown, top error messages from structured logs, error rate by version/canary. Add threshold annotations for SLO breaches

- [ ] TASK-177: Configure log-based alerts in Loki
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `loki` `alerting` `logs`
  - **Services:** Loki, Grafana, Prometheus
  - **Steps:** Write LogQL metric queries for error patterns (|~ "error|panic|fatal"), create recording rules in Loki for log-based metrics, configure Grafana alerting rules with LogQL, set up notification channels, test with injected error logs, tune threshold to reduce false positives

- [ ] TASK-178: Create capacity planning dashboard
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `capacity` `planning` `grafana`
  - **Services:** Grafana, Prometheus, node-exporter
  - **Steps:** Build dashboard with: CPU/Memory/Disk utilization trends (30-day), growth rate projections, pod resource requests vs actual usage, PVC growth rate, network bandwidth. Add forecast panels using Prometheus predict_linear, set up email report on weekly schedule, document capacity thresholds and action triggers

- [ ] TASK-179: Set up uptime monitoring for external endpoints
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `uptime` `blackbox-exporter` `external`
  - **Services:** Blackbox Exporter, Prometheus, Alertmanager
  - **Steps:** Deploy blackbox-exporter with HTTP/TCP/ICMP probes, configure probe targets (store-front, payment-gateway, auth-service external URLs), write Prometheus scrape configs with blackbox relabeling, set up alerts for probe failures (for 3m), dashboard with probe status and SSL certificate expiry tracking

- [ ] TASK-180: Configure DiskUsage alert at 80%
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `disk` `alerting` `node-exporter`
  - **Services:** Prometheus, node-exporter, Alertmanager
  - **Steps:** Write PromQL `(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 20` with `for: 10m`, exclude ephemeral and overlay filesystems via relabeling, add severity labels (disk<80%=warning, disk<90%=critical), wire into Alertmanager, add runbook annotation with remediation steps

- [ ] TASK-181: Add CPU and Memory pressure alerts
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `cpu` `memory` `pressure` `alerting`
  - **Services:** Prometheus, node-exporter, kube-state-metrics
  - **Steps:** Write alerts for: CPUUsageHigh (>85% for 15m), MemoryUsageHigh (>90% for 5m), KubeletMemoryPressure, KubeletDiskPressure, node condition alerts. Add context annotations (which pods consuming most), create per-tier thresholds (prod vs staging), test with resource stress tools

- [ ] TASK-182: Create deployment frequency dashboard
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `dora` `deployment` `dashboard`
  - **Services:** Grafana, Prometheus, ArgoCD
  - **Steps:** Query ArgoCD sync history API or k8s deployment annotations for timestamps, build Grafana dashboard showing: deploys per day/week, per service breakdown, success/failure ratio, lead time (commit→deploy), deploy duration. Add trend lines and comparison to previous period

- [ ] TASK-183: Set up DORA metrics tracking
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 6h | **Tags:** `dora` `metrics` `engineering-effectiveness`
  - **Services:** Grafana, Prometheus, Git, ArgoCD, PagerDuty
  - **Steps:** Implement 4 DORA metrics: deployment frequency (from ArgoCD), lead time for changes (git commit to deploy), change failure rate (failed deploys/total), MTTR (incident open to resolve from PagerDuty). Build composite dashboard with historical trends, export as team quarterly report, set up automated weekly Slack summary

- [ ] TASK-184: Configure service dependency map
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `service-map` `tracing` `dependency`
  - **Services:** Jaeger, Prometheus, all microservices
  - **Steps:** Instrument OpenTelemetry spans in all services, configure collector to extract service graph metrics, enable Prometheus remote write for service graph, build Grafana service map dashboard using tempo/trace data, validate accuracy against known architecture diagram, document in ADR

- [ ] TASK-185: Create on-call rotation schedule
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `on-call` `pagerduty` `schedule`
  - **Services:** PagerDuty, team
  - **Steps:** Define rotation policy (1-week shifts, secondary fallback), add all SRE/DevOps team members, configure escalation policies (primary→secondary→manager after 15m), set up timezone-aware schedules, create override procedure for PTO, test with synthetic incident, document in team wiki

- [ ] TASK-186: Set up incident escalation policy
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `escalation` `incident` `pagerduty`
  - **Services:** PagerDuty, Slack, Alertmanager
  - **Steps:** Define 3 escalation levels (L1: on-call, L2: team lead, L3: engineering manager), configure PagerDuty escalation policy with timeouts (5m/10m/15m), add Slack #incidents channel integration, create incident severity matrix (SEV1→immediate, SEV2→30m, SEV3→next business day), write escalation runbook, test with game day

- [ ] TASK-187: Create MTTR dashboard
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `mttr` `incident` `dashboard`
  - **Services:** Grafana, PagerDuty
  - **Steps:** Calculate MTTR from PagerDuty incident timestamps (created→resolved), build dashboard with: MTTR trend by month, per-service MTTR, MTTR by severity, time-to-acknowledge, time-to-resolve breakdown. Add DORA change failure rate correlation panel, set up monthly SLA review trigger

- [ ] TASK-188: Set up cost allocation tags for cloud resources
  - **Priority:** P3 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `cost` `finops` `allocation`
  - **Services:** cloud provider, Kubernetes
  - **Steps:** Define label standard (team, environment, service, cost-center), implement label enforcement via OPA/Gatekeeper, add cost allocation labels to all Deployments/StatefulSets/PVCs, build Grafana cost dashboard using cloud billing API, set up monthly cost report by team, document tagging policy

- [ ] TASK-189: Configure Prometheus retention policy
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `prometheus` `retention` `storage`
  - **Services:** Prometheus, Thanos/S3
  - **Steps:** Set storage.tsdb.retention.time=30d for local, configure Thanos sidecar for long-term S3 storage, create recording rules for 1h/1d aggregations to reduce cardinality, verify disk usage projections, document retention tiers (hot=7d, warm=30d, cold=90d in S3)

- [ ] TASK-190: Set up Grafana alerting escalation via Contact Points
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `grafana` `alerting` `escalation`
  - **Services:** Grafana, Slack, PagerDuty
  - **Steps:** Create Grafana Contact Points (Slack for warnings, PagerDuty for critical), configure Notification Policies with label-based routing, set up silence and mute window procedures, add nested policies for team-specific channels, test escalation chain end-to-end, document procedure in runbook
