# Infrastructure Tasks

> Cluster: k3s-master (10.195.94.80), k3s-worker-1 (10.195.94.81), k3s-worker-2 (10.195.94.82)

- [ ] TASK-136: Fix k3s kubelet crash loop (proc-sys-rw service)
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `k3s` `kubelet` `lxc` `crash-loop`
  - **Services:** [k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** On all 3 nodes: create `/etc/systemd/system/proc-sys-rw.service` with `mount -o remount,rw /proc/sys`, set `DefaultDependencies=no`, `Before=k3s.service k3s-agent.service`, `After=local-fs.target`, enable and start, restart k3s service, verify nodes go to `Ready` state
  - **Rollback:** `systemctl disable --now proc-sys-rw.service` on each node, remove unit file

- [ ] TASK-137: Reconcile Terraform state drift on Incus containers
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `terraform` `state` `incus` `drift`
  - **Services:** [incus, k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** Run `terraform plan -out=drift.tfplan` in `infra/terraform/`, compare output against expected state, identify manually changed resources (e.g. resource limits, kernel modules), run `terraform apply drift.tfplan` to reconcile, verify all instances match `main.tf` definition
  - **Rollback:** `terraform apply` with previous known-good state file, or `terraform state rm` + re-import

- [ ] TASK-138: Update Ansible playbook for common role
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `ansible` `playbook` `automation`
  - **Services:** [all nodes]
  - **Steps:** Add new tasks to `roles/common/tasks/main.yml`: sysctl tuning for k3s, ntp configuration, log rotation for `/var/log/k3s/`, ssh hardening (disable root, key-only), test with `ansible-playbook --check`, apply to staging first, then production
  - **Rollback:** `ansible-playbook` with reverted role, or `git checkout roles/common/tasks/main.yml`

- [ ] TASK-139: Add k3s worker node to cluster
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `k3s` `worker` `scale-out`
  - **Services:** [k3s-new-worker]
  - **Steps:** Provision Incus container with Terraform (CPU 4, RAM 8GB, disk 50GB), install k3s-agent using token from master, set `--node-label worker=new-worker`, verify node joins cluster with `kubectl get nodes`, apply workloads, check pod scheduling
  - **Rollback:** `kubectl delete node new-worker`, remove container via Incus

- [ ] TASK-140: Scale Incus container resources (CPU, RAM, disk)
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `incus` `scaling` `resources`
  - **Services:** [k3s-worker-1, k3s-worker-2]
  - **Steps:** Run `incus config set k3s-worker-1 limits.cpu 8` and `limits.memory 16GB`, expand disk with `incus storage volume resize default k3s-worker-1 100GB`, verify with `incus info`, restart kubelet, confirm no workload disruption
  - **Rollback:** Revert to previous values via `incus config set`

- [ ] TASK-141: Set up NFS storage class for k3s
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `nfs` `storage` `storageclass`
  - **Services:** [nfs-server, k3s-cluster]
  - **Steps:** Install NFS server on dedicated host, install nfs-subdir-external-provisioner via Helm, set `nfs.server=10.195.94.100`, `nfs.path=/srv/k8s`, create StorageClass `nfs-client` as default, verify PVC provisioning and dynamic directory creation
  - **Rollback:** `kubectl delete storageclass nfs-client`, uninstall helm release

- [ ] TASK-142: Configure backup strategy for etcd snapshots
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `etcd` `backup` `disaster-recovery`
  - **Services:** [k3s-master]
  - **Steps:** Create cron job running `k3s etcd-snapshot save --name etcd-backup-$(date +%s)` every 6 hours, configure s3 upload to external bucket via `rclone`, store last 7 days of snapshots, create `restore-etcd.sh` script for recovery, document restore procedure
  - **Rollback:** Remove cron job, delete s3 backup bucket

- [ ] TASK-143: Update Tailscale ACLs for new services
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `tailscale` `acl` `networking`
  - **Services:** [tailscale, k3s-cluster]
  - **Steps:** Edit Tailscale ACL policy file in admin console, add new service tags: `tag:store-ai`, `tag:store-monitoring`, grant access rules for `ai-service` nodes to MongoDB and Redis, update Grafana access for on-call team, test connectivity with `tailscale ping`
  - **Rollback:** Revert ACL policy to previous version in Tailscale admin

- [ ] TASK-144: Add new DNS records for services
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `dns` `records` `networking`
  - **Services:** [dns, ingress-nginx]
  - **Steps:** Add A records in internal DNS: `grafana.store.internal → 10.195.94.90`, `argocd.store.internal → 10.195.94.90`, `vault.store.internal → 10.195.94.90`, update ingress resources to match, verify with `dig` and `nslookup` from worker nodes
  - **Rollback:** Remove DNS records, revert ingress hostnames

- [ ] TASK-145: Set up log rotation on nodes
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `logging` `rotation` `syslog`
  - **Services:** [k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** Create `/etc/logrotate.d/k3s` config with daily rotation, 7-day retention, compress, missingok, create `/etc/logrotate.d/containerd` for container logs, test with `logrotate -d`, apply Ansible role, verify disk usage stabilizes
  - **Rollback:** Remove logrotate config files, `logrotate -f /etc/logrotate.conf`

- [ ] TASK-146: Configure sysctl tuning for k3s
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `sysctl` `tuning` `kernel`
  - **Services:** [k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** Create `/etc/sysctl.d/90-k3s.conf` with: `net.bridge.bridge-nf-call-iptables=1`, `net.bridge.bridge-nf-call-ip6tables=1`, `fs.inotify.max_user_watches=1048576`, `vm.max_map_count=262144`, `net.core.somaxconn=65535`, apply with `sysctl --system`, verify with `sysctl net.bridge.bridge-nf-call-iptables`
  - **Rollback:** Delete `/etc/sysctl.d/90-k3s.conf`, `sysctl --system`

- [ ] TASK-147: Update Kubernetes versions on all nodes
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `kubernetes` `upgrade` `version`
  - **Services:** [k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** Check latest k3s release, update `install-k3s.sh` script version variable, drain worker nodes with `kubectl drain --ignore-daemonsets`, upgrade master first (`curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.XX.X+k3s1 sh`), upgrade workers, uncordon, verify with `kubectl get nodes -o wide`
  - **Rollback:** Reinstall previous k3s version on each node, restore etcd snapshot

- [ ] TASK-148: Set up monitoring for node resources
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `monitoring` `node-exporter` `resources`
  - **Services:** [prometheus-node-exporter, prometheus]
  - **Steps:** Verify node-exporter DaemonSet running on all nodes (`kubectl get ds -n monitoring`), confirm scrape config includes all worker IPs, add custom collectors (conntrack, Entropy, NTP), create alert rules for high CPU/memory (>85%), verify metrics in Prometheus targets page
  - **Rollback:** Remove custom collectors, revert scrape config

- [ ] TASK-149: Configure disk usage alerts
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `alerting` `disk` `monitoring`
  - **Services:** [prometheus, alertmanager]
  - **Steps:** Create PrometheusRule `disk-usage-alerts.yaml`: alert `DiskSpaceLow` when `node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15` (85% full), add `DiskSpaceCritical` at 95%, route to `slack-critical` receiver, test with `promtool test rules`
  - **Rollback:** `kubectl delete prometheusrule disk-usage-alerts -n monitoring`

- [ ] TASK-150: Update Incus profiles for GPU passthrough
  - **Priority:** P3 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `incus` `gpu` `passthrough`
  - **Services:** [incus, ai-service]
  - **Steps:** Identify GPU PCI address on host with `lspci`, create Incus profile `gpu` with `devices.gpupci=pci/0000:01:00.0`, attach profile to ai-service container, install NVIDIA driver in container, verify with `nvidia-smi`, test AI inference workload
  - **Rollback:** `incus profile remove gpu <container>`, remove profile

- [ ] TASK-151: Set up automated etcd backups
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `etcd` `backup` `cron`
  - **Services:** [k3s-master]
  - **Steps:** Create systemd timer `etcd-backup.timer` running every 6 hours, service runs `k3s etcd-snapshot save --name auto-$(date +%Y%m%d-%H%M)`, configure `rclone` to sync to S3 bucket, add retention policy (keep 7 days), verify backup files exist, test restore procedure
  - **Rollback:** `systemctl disable --now etcd-backup.timer`, remove timer unit files

- [ ] TASK-152: Create Ansible role for security hardening
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `ansible` `security` `hardening`
  - **Services:** [all nodes]
  - **Steps:** Create `roles/security-hardening/tasks/main.yml`: disable password auth (ssh only), set `PermitRootLogin no`, configure UFW (allow 6443/k3s, 22/ssh, 80,443/ingress), enable unattended-upgrades, set kernel module blacklisting (blacklist dccp sctp rds), configure auditd rules, test with `ansible-playbook --check`
  - **Rollback:** Revert playbook, `ufw disable` on affected nodes

- [ ] TASK-153: Update Terraform provider versions
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `terraform` `providers` `versioning`
  - **Services:** [terraform]
  - **Steps:** Run `terraform init -upgrade` in `infra/terraform/`, update provider versions in `required_providers` block (incus, kubernetes, helm), run `terraform plan` to check for breaking changes, review changelog, apply to staging first, then production
  - **Rollback:** `git checkout providers.tf`, `terraform init -upgrade` to previous version

- [ ] TASK-154: Migrate from local-path to NFS storage
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `storage` `migration` `nfs`
  - **Services:** [k3s-cluster, nfs-server]
  - **Steps:** Export existing PVs from local-path, backup PVC data via `kubectl cp`, delete PVCs with `kubectl delete pvc --cascade=orphan`, remove local-path StorageClass, set `nfs-client` as default, recreate PVCs referencing NFS, verify data integrity, update Helm values
  - **Rollback:** Restore data from backup, re-enable local-path StorageClass

- [ ] TASK-155: Configure network policies for namespace isolation
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `network-policy` `isolation` `security`
  - **Services:** [store-prod, store-staging, store-dev]
  - **Steps:** Create default deny-all policy in `store-prod`, allow ingress only from `ingress-nginx` namespace, allow egress to `kube-dns` (port 53), create per-service policies: order-service can reach postgres and rabbitmq, makeline-service can reach rabbitmq, apply and verify with `kubectl describe networkpolicy`
  - **Rollback:** `kubectl delete networkpolicy -n store-prod`, traffic flows unrestricted

- [ ] TASK-156: Set up Prometheus service discovery
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `prometheus` `sd` `discovery`
  - **Services:** [prometheus, kubernetes]
  - **Steps:** Configure `kubernetes_sd_configs` in Prometheus scrape config with `role: pod` and `role: node`, add `relabel_configs` to match pods with label `prometheus.io/scrape=true`, set port and path labels, add scraping for custom exporters (mongodb-exporter, rabbitmq-exporter), verify targets in Prometheus UI
  - **Rollback:** Remove `kubernetes_sd_configs` entries, restart Prometheus

- [ ] TASK-157: Update MetalLB address pool
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `metallb` `networking` `pool`
  - **Services:** [metallb-system]
  - **Steps:** Edit IPAddressPool resource to expand range from `10.195.94.90-10.195.94.95` to `10.195.94.90-10.195.94.100`, update L2Advertisement if needed, verify with `kubectl get ipaddresspool -A`, check new Services receive IPs from expanded pool
  - **Rollback:** Edit IPAddressPool to original range

- [ ] TASK-158: Configure HPA metrics server
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `hpa` `metrics-server` `autoscaling`
  - **Services:** [metrics-server, k3s-cluster]
  - **Steps:** Verify metrics-server installed (k3s includes it by default), check with `kubectl top nodes` and `kubectl top pods -A`, configure HPA on order-service (min 2, max 10, target CPU 70%), add memory-based scaling for ai-service, test with load generator
  - **Rollback:** Remove HPA resources, `kubectl delete hpa -n store-*`

- [ ] TASK-159: Set up Vertical Pod Autoscaler
  - **Priority:** P3 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `vpa` `autoscaling` `resources`
  - **Services:** [vpa, order-service, product-service]
  - **Steps:** Install VPA via Helm (`fairwinds/vpa`), create VPA resource for order-service with `updatePolicy: {minReplicas: 2, updateMode: "Off"}` (recommendation only), monitor recommendations for 1 week, adjust resource requests based on VPA output, enable `Auto` mode after tuning
  - **Rollback:** `kubectl delete vpa order-service-vpa`, uninstall VPA helm release

- [ ] TASK-160: Review and optimize resource requests/limits
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `resources` `optimization` `cost`
  - **Services:** [all services]
  - **Steps:** Collect 2 weeks of metrics (`kubectl top pods` historical), identify over-provisioned pods (>50% average CPU), reduce requests to actual usage + 20% headroom, increase limits 2x requests, check for OOMKill events, update Helm values, apply to staging first, verify no performance degradation
  - **Rollback:** Restore previous resource values from git history

- [ ] TASK-161: Update Helm chart dependencies
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `helm` `dependencies` `versioning`
  - **Services:** [all helm charts]
  - **Steps:** Run `helm dependency update` in each chart directory, update `Chart.yaml` dependency versions for mongodb, rabbitmq, prometheus, check for breaking changes in changelogs, test with `helm template`, apply to staging, verify all pods healthy
  - **Rollback:** Revert `Chart.yaml` to previous dependency versions, `helm dependency update`

- [ ] TASK-162: Set up stale container cleanup cronjob
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `cleanup` `cronjob` `resources`
  - **Services:** [k3s-cluster]
  - **Steps:** Create CronJob `cleanup-stale` running daily at 3am, use `crictl rmi --prune` to remove unused images, add script to delete pods in `Error`/`CrashLoopBackOff` state for >24h, log cleanup actions, verify with `kubectl get cronjob -n kube-system`
  - **Rollback:** `kubectl delete cronjob cleanup-stale -n kube-system`

- [ ] TASK-163: Configure container image garbage collection
  - **Priority:** P2 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `containerd` `garbage-collection` `disk`
  - **Services:** [k3s-master, k3s-worker-1, k3s-worker-2]
  - **Steps:** Configure containerd GC in `/var/lib/rancher/k3s/agent/etc/containerd/config.toml`: set `maxConcurrentDownloads=5`, `imageGCHighThresholdPercent=80`, `imageGCLowThresholdPercent=70`, apply to all nodes, verify with `crictl images` and `df -h /var/lib/containerd`
  - **Rollback:** Revert config.toml, restart containerd service

- [ ] TASK-164: Update TLS certificates for internal services
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Services:** [cert-manager, vault, ingress-nginx]
  - **Tags:** `tls` `certificates` `security`
  - **Steps:** Verify cert-manager issuers are functioning, check certificate expiry with `kubectl get certificates -A`, renew certificates expiring within 30 days, update Let's Encrypt ACME account key if needed, test TLS handshake with `openssl s_client`, update ingress TLS secrets
  - **Rollback:** Restore previous certificate secrets from backup

- [ ] TASK-165: Set up infrastructure cost monitoring
  - **Priority:** P3 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 5h | **Tags:** `cost` `monitoring` `reporting`
  - **Services:** [kube-cost, prometheus, grafana]
  - **Steps:** Install OpenCost via Helm (`opencost/opencost`), configure Prometheus remote write for cost data, create Grafana dashboard showing cost per namespace, cost per deployment, cost trends, add alerts for budget thresholds, generate weekly cost report via cronjob
  - **Rollback:** `helm uninstall opencost -n opencost`, remove Grafana dashboards

- [x] TASK-251: K3s 3-node cluster operational (PC1x2 + PC2 via Tailscale)
  - **Priority:** P0 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 8h | **Services:** [k3s, incus, tailscale]
  - **Steps:** LXC prerequisites role; K3S_URL agent installs; per-worker server URLs; kubeconfig distribution; API tls-san for Tailscale IP
  - **Tags:** `k3s` `lxc` `tailscale` `kubeconfig`
  - **Result:** 3/3 Ready v1.36.4+k3s1, kubectl from every node

- [x] TASK-252: Istio ingress migration + DNS-01 wildcard TLS
  - **Priority:** P0 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 6h | **Services:** [istio, metallb, cert-manager, cloudflare]
  - **Steps:** Removed nginx-ingress; Istio 1.30.4 sidecar/PERMISSIVE; Cloudflare token in Vault kv/cloudflare; wildcard cert; gateway pinned .100; routes for argocd/minio/sonar
  - **Tags:** `istio` `tls` `dns01` `gateway`
  - **Result:** Networking play failed=0; sonar-via-gateway 200

- [x] TASK-253: Vault TLS + auto-init/unseal + KV engine + secrets seeded
  - **Priority:** P0 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 4h | **Services:** [vault]
  - **Steps:** Self-signed TLS; file backend; init keys /root/vault-init.json; kv-v2 at kv/; seeded kv/cloudflare + kv/sonarqube
  - **Tags:** `vault` `secrets` `tls`
  - **Result:** Unsealed, serving https://10.195.94.200:8200

- [x] TASK-254: Monitoring + observability stack deployed (PC1 VM)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 4h | **Services:** [prometheus, grafana, alertmanager, otelcol, jaeger, loki, node-exporter]
  - **Steps:** Pinned binaries; dearmored Grafana keyring; jaeger non-root user; node-exporter on all K3s nodes
  - **Tags:** `monitoring` `observability`
  - **Result:** All units active; scrape targets green

- [x] TASK-255: SonarQube migrated PC1 to PC2 + Gateway exposure
  - **Priority:** P1 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 5h | **Services:** [sonarqube, postgresql, istio]
  - **Steps:** Blue-green PC2 container (privileged, 2560MB, Tailscale); matched pair SQ 26.5.0.122743 + plugin 26.5.0; ServiceEntry/VirtualService; PC1 instance destroyed; host data cleaned
  - **Tags:** `sonarqube` `migration` `postgres`
  - **Result:** HTTP 200 + plugin loaded; 934MB headroom

- [x] TASK-256: Worker kubeconfig distribution + API TLS SANs
  - **Priority:** P1 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 2h | **Services:** [k3s]
  - **Steps:** Slurp master k3s.yaml; rewrite server per worker; tls-san config + k3s restart for cert regen
  - **Tags:** `k3s` `kubeconfig` `tls`
  - **Result:** kubectl works from all 3 nodes; workloads healthy post-restart

- [x] TASK-257: sonar.* DNS cutover + Firefox verify + admin password rotation
  - **Priority:** P1 | **Sprint:** 2 | **Status:** done 2026-09-09
  - **Estimate:** 30min | **Services:** [cloudflare-dns, sonarqube, vault]
  - **Steps:** sonar A record to 10.195.94.100; Firefox https check (restart browser post-flip); change admin password in UI; confirm new-value login; value already in kv/sonarqube
  - **Tags:** `dns` `sonarqube` `security`

- [x] TASK-258: ArgoCD login verified + admin password stored in Vault kv/argocd
  - **Priority:** P0 | **Sprint:** 2 | **Status:** todo (next)
  - **Estimate:** 1h | **Services:** [argocd, istio, vault]
  - **Steps:** Run site-argocd.yml; get initial password; login via Gateway URL; change password; kv put kv/argocd; delete initial secret
  - **Tags:** `argocd` `gitops` `security`

- [x] TASK-259: Full site.yml convergence proof (failed=0 all 6 hosts, 2026-09-09)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** todo
  - **Estimate:** 1h | **Services:** [all]
  - **Steps:** Run site.yml end-to-end; every idempotent skip verified; record recap
  - **Tags:** `ansible` `convergence`

- [~] TASK-262: Forgejo CI/CD on PC2 (k3s-forgejo-ci + k3s-runner-1, binary 16.0.3, SQLite, host-label runners, Buildah, pilot 1 service)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** in progress (server live + domain 200; runners registered + idle ×2 UI-confirmed; `sysadmin` rotated + `kv/forgejo` v1; awaiting pilot pick + pilot green)
  - **Estimate:** 6h | **Services:** [forgejo, forgejo-runner, buildah, istio, vault, pc2-tofu]
  - **Steps:** Vault trim 750MB → tofu apply PC2 (2 VMs) → Tailscale+SSH → forgejo role → Gateway exposure → runners register → Buildah pilot 1 service → docs → convergence proof
  - **Tags:** `forgejo` `ci` `buildah` `pc2`

- [~] TASK-263: Production monitoring (Alloy edge + probes + Telegram alerts + correlation + hardening)
  - **Priority:** P1 | **Sprint:** 2 | **Status:** in progress (steps 1–3 PROVEN live: edge metrics+logs, 18-20 probes + 7/7 peer pings, Telegram buzzed end-to-end; remaining: step 4 correlation (needs pilot) + step 5 hardening)
  - **Estimate:** 5h | **Services:** [alloy, kube-state-metrics, prometheus, loki, jaeger, alertmanager, vault]
  - **Steps:** edge → probes (blackbox 13 domains + certs) → rules + 7 alerts + Telegram test → correlation → hardening + close-out
  - **Tags:** `monitoring` `alloy` `alerts` `telegram` `slo`

- [x] TASK-260: Cross-PC pod networking (flannel-iface=tailscale0 migration — DONE 2026-09-13, 5b 0% loss both ways)
  - **Priority:** P2 | **Sprint:** 3 | **Status:** blocked (needs maintenance window + worker-1 Tailscale first)
  - **Estimate:** 3h | **Services:** [k3s, flannel, tailscale]
  - **Steps:** Tailscale in worker-1; set flannel-iface on all nodes; restart k3s master-first; verify VTEPs + ClusterIP from worker-2; unpin infra if desired
  - **Tags:** `k3s` `flannel` `tailscale`
