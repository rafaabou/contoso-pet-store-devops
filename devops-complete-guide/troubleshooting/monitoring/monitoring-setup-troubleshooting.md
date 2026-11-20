# Monitoring & Observability Troubleshooting

> Covers Prometheus + Grafana + Alertmanager and the OTel stack (Collector,
> Jaeger, Loki) — all systemd services on the monitoring VM — plus the
> TASK-263 in-cluster edge (Alloy DaemonSet + kube-state-metrics, manifests in
> `infrastructure/observability-edge/`).
> Master log: `../ansible/ansible-setup-troubleshooting.md` (ERRORs 27, 65, 66,
> W-4/W-5 + role-fix era). *Last Updated: 2026-09-10 — center green; edge live (Alloy 3/3 + KSM, 56 series + log streams); blackbox 18-20 probes + 7/7 peer pings; Telegram paging proven (buzzed); 5 rules loaded.*

## 1. Current State (2026-09-09)

| Service | Port | URL (direct VM, bypasses cluster) | Notes |
|---|---|---|---|
| Prometheus | 9090 | `prometheus.*` | 30d retention, 15s scrape; scrapes K3s nodes + self |
| Grafana | 3000 | `grafana.*` | admin password in `group_vars` (lab) → Vault in production |
| Alertmanager | 9093 | `alertmanager.*` | receivers in role config |
| OTel Collector | 4317/4318/8888 | `otel.*` (8888 metrics) | otlphttp/loki exporters |
| Jaeger (all-in-one) | 16686 UI | `jaeger.*` | runs as `jaeger` user (not root), no `--memory.max-traces` on v1.x, built-in OTLP receiver DISABLED (`--collector.otlp.enabled=false` — else it fights the Collector for :4317, ERROR 79) |
| Loki | 3100 | `loki.*` | single-node, in-memory ring (accepted) |
| node-exporter | 9100 | every K3s node | `node-exporter` role; Prometheus target per node |

All six DNS names are direct A records to the monitoring VM (`.210`) — these
never touch Istio/Gateway by design (observability must survive ingress outages).

## 2. Scrape Topology (the part that breaks on moves)

```yaml
# roles/monitoring/templates/prometheus.yml.j2 (vars from group_vars)
- k3s_master_ip:9100, k3s_worker1_ip:9100   # 10.195.94.x — PC1-local ONLY
- k3s_worker2_ip:9100                        # Tailscale 100.x — cross-PC OK
- master:6443                                # K8s API probe (PC1-local)
```

**Constraint:** moving monitoring to PC2 requires retargeting every `10.195.94.x`
scrape to Tailscale IPs — which needs Tailscale inside worker-1 (missing) and
makes all metrics relay-dependent. Deferred deliberately; see master ERROR 73 discussion.

## 3. Verification Commands

```bash
curl -s http://10.195.94.210:9090/-/healthy                       # Prometheus ready
curl -s http://10.195.94.210:3000/login | head -1                  # Grafana login page
curl -s http://10.195.94.210:9093/-/healthy                       # Alertmanager
curl -s http://10.195.94.210:4318/ -o /dev/null -w "%{http_code}\n"  # OTel HTTP receiver
curl -s http://10.195.94.210:16686/ -o /dev/null -w "%{http_code}\n" # Jaeger UI
curl -s http://10.195.94.210:3100/ready                            # Loki ready
curl -s http://10.195.94.80:9100/metrics | head -2                 # node-exporter on master
systemctl is-active prometheus grafana-server alertmanager otelcol jaeger loki node_exporter
```

## 4. Install Flow

`site-monitoring.yml` (prometheus user/dirs → pinned binary → config → service;
Grafana via **dearmored** keyring + APT → config → service; Alertmanager same
shape) then `site-opentelemetry.yml` (otel user → collector + config →
`jaeger` user → all-in-one → loki user → config). Users are per-service system
accounts; configs templated from `group_vars` (no role-default duplication).

## 5. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| W-4/W-12 | node-exporter targets DOWN in Prometheus | `node-exporter` role + `site-node-exporter.yml` install it on all K3s nodes |
| 65 | Grafana repo `NO_PUBKEY` though key task passed | `apt.grafana.com/gpg.key` is ASCII-armored; `curl \| gpg --dearmor` to the `.gpg` keyring (vault-role pattern); delete older armored file first |
| W-5 | Jaeger runs as root | dedicated `jaeger` system user in role; service `User=/Group=jaeger` |
| 27 | `unknown flag --memory.max-traces` | v1.x flag — removed from the v1 all-in-one service template |
| 66 | `jaeger_grpc_port is undefined` | defaults-trim dropped a var the template uses — grep templates before trimming defaults; restored `14250` |
| — | HPA-style `no metrics` warnings (istiod HPA) | No metrics-server in cluster — harmless noise, not a failure |

## 6. First-Actions Runbook

1. `systemctl is-active` across the six units — which layer is down?
2. Target DOWN in Prometheus → `curl <ip>:9100/metrics` from the monitoring host (network vs exporter?).
3. Grafana 502/blank → Prometheus reachable from the VM? Datasource URL is localhost — check service, not network.
4. Jaeger empty traces → OTel exporter endpoints (`localhost:14250`) + collector logs.
5. apt failures on re-run → keyring state (`file /usr/share/keyrings/*` — ASCII vs binary, ERROR 65).

## 7. Edge Collectors (TASK-263 step 1 — in-cluster, DaemonSet everywhere)

- **Alloy** (`monitoring` ns, no sidecar): tails `/var/log/pods` (own node only — node-scoped discovery, ERROR 100) → PII scrub → Loki push; scrapes KSM + self + annotated pods → Prometheus remote-write (receiver flag, ERROR 99); OTLP 4317/4318 → VM collector. Endpoints = monitoring Tailscale IP (uniform from all nodes).
- **kube-state-metrics** (v2.13.0, 1 replica): cluster-state metrics. RBAC incl. `admissionregistration` read (reflector gap fixed).
- Proven live: 56 `kube_pod_info` series + pod log streams in Loki. Manifests: `infrastructure/observability-edge/`.

## 8. Blackbox Probes (TASK-263 step 2 — systemd on monitoring VM)

## 9. Alertmanager Telegram Paging (TASK-263 step 3 — Vault-sourced)

- Secrets: `kv/alertmanager` (`telegram_bot_token`, `telegram_chat_id`) fetched at deploy via delegate_to-vault pattern (cert-manager idiom), `no_log` throughout; facts render into `alertmanager.yml.j2`.
- Routing: all → `telegram`; critical repeats 1h, rest 4h; `send_resolved: true`.
- Proof is a live test alert to the phone (firing API below), not config inspection.
- Verify: `curl -s http://10.195.94.210:9093/api/v2/status | head -c 200` (config OK) + receive the test message.

- **blackbox_exporter** `:9115` (role `blackbox`, version var — 404 on download = bump it): modules `tls_page` (200/301/302/307 valid), `tls_s3` (403 valid), `http_page` (plain ports).
- **Scrape jobs** (in `prometheus.yml.j2`): `blackbox-tls` (10 Gateway names incl. apex), `blackbox-tls-special` (s3 + loki API), `blackbox-plain` (6 native URLs — mesh-independent view).
- **Rules** (`probe-rules.yml`, auto-loaded via `rules/*.yml`): DomainDown (probe 0 for 3m, critical), CertExpiringSoon (21d, warning), CertExpiringCritical (7d, critical). Firing visible in Prometheus/Grafana now; paging arrives step 3 (Telegram — Alertmanager `default` receiver still void).
- **KSM RBAC gap fixed:** `admissionregistration.k8s.io` read added (reflector noise gone after ClusterRole re-apply).
- Verify: Prometheus Targets page shows 3 blackbox jobs UP; `probe_success == 1` for all; `probe_ssl_earliest_cert_expiry` present on TLS targets.
- **Peer + node liveness (built after the 2026-09-10 silent outage):** `blackbox-icmp` pings all 7 tailnet peers from the monitoring VM (needs `CAP_NET_RAW` on the service); rules `TailscalePeerDown` + `NodeDown` (node-exporter `up`, any cause). URL probes alone never cover dead peers/hosts — this closes that exact gap.

- **Alloy** (`monitoring` ns, no sidecar): tails `/var/log/pods` → PII scrub (emails, bearer tokens) → Loki push; scrapes KSM + self + annotated pods → Prometheus remote-write; OTLP 4317/4318 pass-through → VM collector. Endpoints use the monitoring VM's **Tailscale IP** (placeholder `MONITORING_TS_IP` until Tailscale lands there) — reachable from every node incl. worker-2, no affinity hacks.
- **kube-state-metrics** (v2.13.0, 1 replica): cluster-state metrics; scraped by Alloy.
- Resource envelope: Alloy 128Mi/512Mi, KSM 64Mi/256Mi. Retention stays role default (`prometheus_retention: 30d`); disk pressure watched in step 5, not pre-trimmed.
- Verify after apply: `kubectl -n monitoring get pods -o wide` (alloy on 3/3 nodes) → Grafana Explore → Loki shows pod logs → Prometheus targets include KSM.
- Rollback: `kubectl delete -f infrastructure/observability-edge/` (center untouched).
