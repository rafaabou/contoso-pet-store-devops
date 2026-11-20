# Debugging Tasks

Real-world DevOps debugging incidents and sessions.

## Cluster Infrastructure

- [ ] TASK-001: k3s-master kubelet NotReady after reboot
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `k3s` `kubelet` `node`
  - **Services:** [k3s-master (10.195.94.100)]
  - **Symptoms:** kubectl get nodes shows master NotReady; pods evicted after 5m
  - **Investigation steps:** ssh k3s-master; systemctl status kubelet; journalctl -u kubelet --since "10 min ago" -f; cat /var/lib/rancher/k3s/agent/etc/containerd/config.toml; crictl ps
  - **Expected fix:** Check /proc/sys rw (proc-sys-rw.service), restart kubelet, verify containerd runtime is healthy, rejoin if certificate rotated

- [ ] TASK-002: k3s-worker-1 node NotReady — container runtime unhealthy
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `k3s` `containerd` `runtime`
  - **Services:** [k3s-worker-1 (10.195.94.101)]
  - **Symptoms:** Node status NotReady for 8+ min; kubelet reports "container runtime not ready"
  - **Investigation steps:** ssh k3s-worker-1; crictl info 2>&1; journalctl -u containerd -n 50; df -h /var/lib/containerd; ls -la /run/containerd/containerd.sock
  - **Expected fix:** Restart containerd, clear corrupt snapshot, check disk space on /var/lib/containerd, restart kubelet

- [ ] TASK-003: k3s-worker-2 networking broken — pods cannot reach master API
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `k3s` `network` `flannel`
  - **Services:** [k3s-worker-2 (10.195.94.102), flannel, kube-apiserver]
  - **Symptoms:** Worker-2 pods get Pending; kubectl describe node shows network plugin not ready; flannel pod CrashLoopBackOff
  - **Investigation steps:** ssh k3s-worker-2; ip addr show flannel.1; ip link show; iptables -L -n -v | head -30; journalctl -u flannel -n 50
  - **Expected fix:** Reinstall flannel CNI, verify VXLAN backend, check iptables rules not cleared by ufw restart, re-apply flannel secret

- [ ] TASK-004: K3s containerd image pull backoff — registry unreachable
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `containerd` `registry` `image-pull`
  - **Services:** [containerd on k3s-worker-1]
  - **Symptoms:** Pod events show "Back-off pulling image"; crictl pull fails with "dial tcp: connection refused"
  - **Investigation steps:** ssh k3s-worker-1; crictl pull <image> 2>&1; cat /etc/containerd/config.toml | grep -A5 registry; curl -v https://registry.example.com/v2/
  - **Expected fix:** Check registry DNS, verify TLS cert on registry, restart containerd, configure mirror if needed

- [ ] TASK-005: Disk full on k3s-master — /var/lib/rancher space exhaustion
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `disk` `cleanup` `k3s`
  - **Services:** [k3s-master]
  - **Symptoms:** Disk usage 97%+ on /var/lib/rancher; kubelet failing to create containers; OOM kills in dmesg
  - **Investigation steps:** df -h /var/lib/rancher; du -sh /var/lib/rancher/k3s/* | sort -rh; du -sh /var/lib/rancher/k3s/agent/containerd/io.containerd.snapshotter.v1.overlayfs/* | sort -rh | head -10
  - **Expected fix:** Prune unused images (crictl rmi --prune), delete old logs, move audit logs to worker, set up log rotation

- [ ] TASK-006: Container image pull — ImagePullBackOff for private registry
  - **Priority:** P1 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `image-pull` `registry` `secrets`
  - **Services:** [deployment, registry, imagepullsecret]
  - **Symptoms:** Pod stuck in Init:0/1; event shows "pull access denied, repository does not exist or may require authorization"
  - **Investigation steps:** kubectl get secret -A | grep registry; kubectl describe secret <secret-name>; kubectl get pod <pod> -o jsonpath='{.spec.imagePullSecrets}'; crictl pull --creds user:pass <image>
  - **Expected fix:** Recreate imagePullSecret, verify registry credentials, check registry namespace/image path

- [ ] TASK-007: Pod OOMKilled on deployment — container memory limit too low
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `oom` `memory` `limits`
  - **Services:** [deployment, resource-quota]
  - **Symptoms:** Pod restarts every 30s; lastState shows OOMKilled with exit code 137
  - **Investigation steps:** kubectl describe pod <pod> | grep -A5 "Last State"; kubectl top pod <pod>; kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].resources}'; dmesg | grep -i oom
  - **Expected fix:** Increase memory limits, profile application memory usage, check for memory leak, set proper requests/limits

- [ ] TASK-008: Liveness probe failing — pod restarting every 30s
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `probes` `health` `liveness`
  - **Services:** [deployment, liveness-probe]
  - **Symptoms:** Pod shows restart count incrementing; liveness probe returns 500; event shows "Liveness probe failed"
  - **Investigation steps:** kubectl describe pod <pod> | grep -A10 "Liveness"; kubectl logs <pod> --previous | tail -20; kubectl exec -it <pod> -- curl -s localhost:<port>/healthz; kubectl get deploy <deploy> -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
  - **Expected fix:** Increase initialDelaySeconds, check application startup time, verify endpoint path, fix app startup issue

- [ ] TASK-009: Readiness probe never passes — service endpoint empty
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `probes` `readiness` `service`
  - **Services:** [deployment, service]
  - **Symptoms:** kubectl get endpoints shows empty; service has no backing pods; pod shows "NotReady"
  - **Investigation steps:** kubectl describe pod <pod> | grep -A10 "Readiness"; kubectl exec -it <pod> -- curl -s localhost:<port>/ready; kubectl logs <pod> | grep -i "ready\|listen"
  - **Expected fix:** Fix readiness endpoint, ensure app binds to 0.0.0.0 (not localhost), adjust probe timeout

## Application Debugging

- [ ] TASK-010: Ingress returning 502 Bad Gateway — upstream connection refused
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `ingress` `nginx` `upstream`
  - **Services:** [ingress-nginx, backend-service]
  - **Symptoms:** curl returns 502; ingress logs show "upstream connection refused"; backend pods Running but not listening
  - **Investigation steps:** kubectl logs -n ingress-nginx <ingress-pod> | grep 502; kubectl exec -it <ingress-pod> -- curl -v backend-svc:8080; kubectl get pods -l app=backend; kubectl logs <backend-pod> | grep -i listen
  - **Expected fix:** Fix backend port, check service selector matches pod labels, verify backend binds to correct interface

- [ ] TASK-011: Service latency spike — p99 >5s after deployment
  - **Priority:** P0 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `latency` `performance` `database`
  - **Services:** [api-service, postgresql, redis-cache]
  - **Symptoms:** Prometheus shows p99 latency jumped from 200ms to 5.2s after v2.3.0 deploy; error rate <1%
  - **Investigation steps:** kubectl top pod api-service; kubectl logs api-service | grep -i "slow query\|timeout"; kubectl exec -it postgresql -- psql -c "SELECT * FROM pg_stat_activity WHERE wait_event IS NOT NULL"; kubectl logs api-service | grep -i redis
  - **Expected fix:** Rollback to v2.2.x, investigate N+1 query in new code, check connection pool exhaustion, tune PostgreSQL shared_buffers

- [ ] TASK-012: DNS resolution failing inside pods — CoreDNS returning SERVFAIL
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `dns` `coredns` `networking`
  - **Services:** [coredns, kube-dns, node-local-dns]
  - **Symptoms:** Pods cannot resolve kubernetes.default; nslookup from pod returns SERVFAIL; CoreDNS logs show "plugin/forward: no healthy upstream"
  - **Investigation steps:** kubectl exec -it <pod> -- nslookup kubernetes.default; kubectl logs -n kube-system coredns-xxx | tail -50; kubectl get configmap coredns -n kube-system -o yaml; kubectl exec -n kube-system coredns-xxx -- cat /etc/resolv.conf
  - **Expected fix:** Check CoreDNS upstream config, verify /etc/resolv.conf on node, restart CoreDNS, check if CoreDNS pods are on nodes with working DNS

- [ ] TASK-013: TLS certificate expiry — cert-manager not renewing
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `tls` `cert-manager` `letsencrypt`
  - **Services:** [cert-manager, certificate, ingress]
  - **Symptoms:** Browser shows "certificate expires in 2 days"; cert-manager Certificate resource shows Ready=False
  - **Investigation steps:** kubectl get certificate -A; kubectl describe certificate <cert>; kubectl describe order <order>; kubectl logs -n cert-manager <pod> | grep -i "challenge\|renew"
  - **Expected fix:** Check cert-manager issuer status, verify ACME account, manually trigger renewal, check DNS challenge solver

- [ ] TASK-014: PVC stuck in Pending — no PV available
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `pvc` `storage` `local-path`
  - **Services:** [pvc, local-path-provisioner]
  - **Symptoms:** Pod stuck in Pending; kubectl describe pvc shows "waiting for a volume to be created"; no PV created
  - **Investigation steps:** kubectl describe pvc <pvc>; kubectl get storageclass; kubectl get pv; kubectl describe sc local-path; ls -la /opt/local-path-provisioner/
  - **Expected fix:** Verify StorageClass exists, check provisioner pod is running, ensure node has disk space, bind PV if manually created

- [ ] TASK-015: ConfigMap not mounting — pod starts but config missing
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `configmap` `mount` `volume`
  - **Services:** [configmap, deployment]
  - **Symptoms:** Pod starts normally but application reports missing config; /config inside pod is empty
  - **Investigation steps:** kubectl exec -it <pod> -- ls -la /config; kubectl get configmap <cm> -o yaml; kubectl describe pod <pod> | grep -A5 "Volumes\|Mounts"; kubectl describe pod <pod> | grep -i "Warning"
  - **Expected fix:** Check configmap name matches volume name, verify mountPath, check items key mapping, ensure configmap exists in same namespace

- [ ] TASK-016: Secret not available in pod — application crashes on startup
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `secret` `env` `missing`
  - **Services:** [secret, deployment]
  - **Symptoms:** Pod CrashLoopBackOff; logs show "DATABASE_PASSWORD not set" or similar; secret exists but not injected
  - **Investigation steps:** kubectl get secret <secret> -o yaml | grep keys; kubectl describe pod <pod> | grep -A10 "Environment"; kubectl exec -it <pod> -- env | grep DATABASE
  - **Expected fix:** Check secretKeyRef key name matches actual secret key, verify secret exists in pod namespace, check for RBAC denying access

- [ ] TASK-017: HPA not scaling — target CPU never reached
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `hpa` `autoscaling` `metrics`
  - **Services:** [hpa, metrics-server, deployment]
  - **Symptoms:** HPA shows metrics as "unknown" or target never reached; pods remain at replicas=2 despite load
  - **Investigation steps:** kubectl get hpa -A; kubectl describe hpa <hpa>; kubectl top pod; kubectl logs -n kube-system metrics-server-xxx | grep -i error; kubectl get apiservice v1beta1.metrics.k8s.io
  - **Expected fix:** Verify metrics-server is running, check resource requests are set on pods, fix HPA metric target, ensure metrics API is registered

- [ ] TASK-018: CronJob stuck — last job never completed
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `cronjob` `stuck` `ttl`
  - **Services:** [cronjob, job]
  - **Symptoms:** kubectl get jobs shows job with ActiveDeadlineSeconds exceeded; no new jobs created
  - **Investigation steps:** kubectl get jobs --sort-by=.status.completionTime; kubectl describe job <job>; kubectl logs <job-pod> | tail -30; kubectl get cronjob <cronjob> -o jsonpath='{.spec.successfulJobsHistoryLimit}'
  - **Expected fix:** Delete stuck job, add activeDeadlineSeconds and backoffLimit, set ttlSecondsAfterFinished, check job logic for hangs

- [ ] TASK-019: DaemonSet pods not scheduling on new node
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `daemonset` `scheduling` `node`
  - **Services:** [daemonset, kube-scheduler]
  - **Symptoms:** New node added but no DaemonSet pod; kubectl get pods -l app=flannel shows 2 pods for 3 nodes
  - **Investigation steps:** kubectl get nodes; kubectl describe daemonset <ds>; kubectl get events --field-selector reason=FailedScheduling; kubectl describe node <new-node> | grep -A5 Taints
  - **Expected fix:** Check node taints and DaemonSet tolerations, verify node is Ready, check nodeSelector/affinity rules

- [ ] TASK-020: RBAC Forbidden — service account cannot list pods
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `rbac` `serviceaccount` `permissions`
  - **Services:** [rbac, serviceaccount, clusterrolebinding]
  - **Symptoms:** Application logs show "forbidden: User \"system:serviceaccount:default:my-sa\" cannot list resource pods"
  - **Investigation steps:** kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa; kubectl get clusterrolebinding -o yaml | grep -A5 my-sa; kubectl describe sa my-sa; kubectl get rolebinding -A | grep my-sa
  - **Expected fix:** Create proper ClusterRole/RoleBinding, bind to correct service account, check namespace scope

## Network & Ingress

- [ ] TASK-021: MetalLB not assigning external IPs — IPAddressPool empty
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `metallb` `loadbalancer` `ip`
  - **Services:** [metallb, speaker, controller]
  - **Symptoms:** LoadBalancer service stuck in Pending; kubectl get svc shows ExternalIPs as "<pending>"; metallb logs show "no IP addresses available"
  - **Investigation steps:** kubectl get ipaddresspool -A; kubectl describe ipaddresspool; kubectl logs -n metallb-system speaker-xxx | grep -i "announce\|assign"; kubectl logs -n metallb-system controller-xxx | tail -20
  - **Expected fix:** Verify IPAddressPool CIDR matches network, check L2Advertisement or BGP config, ensure speaker DaemonSet is on all nodes, restart controller

- [ ] TASK-022: Ingress 503 Service Unavailable — all backends down
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `ingress` `503` `backend`
  - **Services:** [ingress-nginx, backend-service]
  - **Symptoms:** curl returns 503; ingress-nginx logs show "no upstream endpoints"; kubectl get endpoints shows 0 endpoints
  - **Investigation steps:** kubectl get endpoints <svc>; kubectl get pods -l app=backend; kubectl describe endpoints <svc>; kubectl logs -n ingress-nginx <pod> | grep upstream
  - **Expected fix:** Check service selector matches pod labels, ensure pods are Ready, check pod readiness gates

- [ ] TASK-023: Flannel pod CrashLoopBackOff — VXLAN setup failed
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `flannel` `vxlan` `cni`
  - **Services:** [flannel, kube-flannel-cfg]
  - **Symptoms:** flannel pod restarts every 10s; logs show "Failed to set up: failed to set up external tunnel endpoint"
  - **Investigation steps:** kubectl logs -n kube-system <flannel-pod> | tail -30; kubectl get configmap kube-flannel-cfg -o yaml; ip link show flannel.1; lsmod | grep vxlan
  - **Expected fix:** Check VXLAN module loaded on host, verify flannel CIDR matches pod CIDR, restart flannel, check MTU settings

- [ ] TASK-024: CoreDNS resolution slow — 2s+ latency for kubernetes.default
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `coredns` `dns` `latency`
  - **Services:** [coredns, node-local-dns]
  - **Symptoms:** kubectl exec nslookup takes 2-3s; application health checks timing out; CoreDNS CPU 100%
  - **Investigation steps:** kubectl exec -it <pod> -- time nslookup kubernetes.default; kubectl top pod -n kube-system coredns; kubectl logs coredns-xxx | grep -i "plugin/forward\|errors"
  - **Expected fix:** Scale CoreDNS replicas, check upstream forward targets, enable node-local-dns, verify resolv.conf on nodes

- [ ] TASK-025: kubectl exec connection refused — API server unreachable from pod
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `exec` `api` `networking`
  - **Services:** [kube-apiserver, kubelet]
  - **Symptoms:** kubectl exec fails with "connection refused"; pods can reach each other but not API server
  - **Investigation steps:** kubectl exec -it <pod> -- curl -sk https://kubernetes.default:443; kubectl logs -n kube-system kube-apiserver-xxx | grep -i "listen\|bind"; ss -tlnp | grep 6443
  - **Expected fix:** Check apiserver is listening on 6443, verify kubelet certificate, check firewall rules on port 6443

- [ ] TASK-026: Network policy blocking legitimate traffic between pods
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `networkpolicy` `ingress` `egress`
  - **Services:** [networkpolicy, calico, flannel]
  - **Symptoms:** Pod A cannot reach Pod B despite both being Running; logs show connection timeout
  - **Investigation steps:** kubectl get networkpolicy -A; kubectl describe networkpolicy <np>; kubectl exec -it <pod-a> -- curl -v <pod-b-ip>:8080; iptables -L -n -v | grep -i "policy\|drop"
  - **Expected fix:** Review NetworkPolicy rules, check ingress/egress definitions, verify pod selectors match, check CNI plugin supports NetworkPolicy

- [ ] TASK-027: NodePort service not reachable externally
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `nodeport` `firewall` `external`
  - **Services:** [nodeport-service, ufw, firewall]
  - **Symptoms:** curl from outside cluster times out; kubectl get svc shows NodePort assigned; internal curl works fine
  - **Investigation steps:** ssh worker node; ss -tlnp | grep <nodeport>; sudo ufw status | grep <nodeport>; curl localhost:<nodeport>
  - **Expected fix:** Open nodeport in ufw/firewall, check node's external IP, verify kube-proxy rules, check cloud security groups if applicable

## Storage & Stateful

- [ ] TASK-028: Longhorn volume stuck in Attaching — iSCSI netlink failure
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 4h | **Tags:** `longhorn` `iscsi` `netlink` `lxc`
  - **Services:** [longhorn, iscsid, lxc-containers]
  - **Symptoms:** PVC shows Bound but pod stuck Pending; Longhorn UI shows volume "attaching"; iscsid logs "sendmsg: ECONNREFUSED"
  - **Investigation steps:** kubectl get pv <pv> -o yaml | grep -A10 longhorn; ssh k3s-worker-1; systemctl status iscsid; strace -e sendmsg iscsiadm -m session; ls /sys/class/net/
  - **Expected fix:** Known LXC issue — iscsi netlink socket doesn't cross netns. Use nfs-csi or local-path instead of Longhorn. If Longhorn required, enable kernel modules iscsi_tcp,libiscsi,scsi_transport_iscsi on host and set linux.kernel_modules in Incus config.

- [ ] TASK-029: NFS CSI mount failure — permission denied on NFS server
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `nfs` `csi` `permission`
  - **Services:** [nfs-csi, nfs-server]
  - **Symptoms:** Pod stuck in ContainerCreating; events show "mount.nfs: permission denied"; PVC Bound but mount fails
  - **Investigation steps:** kubectl describe pod <pod> | grep -A10 Events; ssh NFS server; cat /etc/exports; showmount -e nfs-server; kubectl get csinodes -o yaml | grep -A5 nfs
  - **Expected fix:** Verify NFS exports allow worker node IPs, check no_root_squash setting, ensure NFS CSI credentials correct, restart node if stale mounts

- [ ] TASK-030: Local-path-provisioner orphaned volumes — disk filling up
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `local-path` `cleanup` `disk`
  - **Services:** [local-path-provisioner]
  - **Symptoms:** /opt/local-path-provisioner growing; old PVC directories exist after PVC deletion; disk usage increasing
  - **Investigation steps:** ls -la /opt/local-path-provisioner/pvc-*; kubectl get pvc -A | wc -l; du -sh /opt/local-path-provisioner/*; kubectl logs local-path-provisioner-xxx | grep -i "cleanup\|delete"
  - **Expected fix:** Manually remove orphaned directories, check provisioner cleanup job, enable reclaim policy, configure storage limits

- [ ] TASK-031: etcd backup failing — snapshot corrupted
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `etcd` `backup` `k3s`
  - **Services:** [k3s, etcd]
  - **Symptoms:** etcd snapshot cron job fails; error "snapshot file is corrupted"; no recent backup found
  - **Investigation steps:** k3s etcd-snapshot save --dir /var/lib/rancher/k3s/server/db/snapshots 2>&1; ls -la /var/lib/rancher/k3s/server/db/snapshots/; etcdctl snapshot status latest.db 2>&1
  - **Expected fix:** Check disk space, delete corrupted snapshots, verify etcd health, schedule regular backups to off-node location

- [ ] TASK-032: ConfigMap with invalid YAML — pod refuses to start
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 30min | **Tags:** `configmap` `yaml` `syntax`
  - **Services:** [configmap]
  - **Symptoms:** kubectl apply fails with "error: error parsing stdin: yaml: line X: mapping values not allowed here"; configmap creation fails
  - **Investigation steps:** kubectl get configmap <cm> -o yaml; kubectl create configmap <cm> --from-file=config.yaml -o yaml --dry-run=client | kubectl apply -f -; yamllint config.yaml
  - **Expected fix:** Fix YAML indentation, escape special characters, validate with yamllint before applying

## Monitoring & Observability

- [ ] TASK-033: Prometheus targets down — node-exporter unreachable
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `prometheus` `targets` `scrape`
  - **Services:** [prometheus, node-exporter]
  - **Symptoms:** Prometheus UI shows node-exporter targets as DOWN; last scrape error "context deadline exceeded"
  - **Investigation steps:** kubectl get endpoints node-exporter -n monitoring; kubectl logs prometheus-xxx | grep -i "down\|error"; curl -s http://<node-ip>:9100/metrics | head
  - **Expected fix:** Check node-exporter pod is running, verify port 9100 is accessible, check firewall rules, restart node-exporter

- [ ] TASK-034: Grafana dashboard not loading — plugin initialization failed
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `grafana` `plugins` `dashboard`
  - **Services:** [grafana]
  - **Symptoms:** Grafana UI shows "Dashboard not found"; logs show plugin loading error; datasource health check failing
  - **Investigation steps:** kubectl logs grafana-xxx | grep -i "plugin\|error"; kubectl exec -it grafana-xxx -- grafana-cli plugins ls; curl -s http://grafana:3000/api/health
  - **Expected fix:** Reinstall failing plugin, check datasource URL, verify grafana.db permissions, restart Grafana

- [ ] TASK-035: Alertmanager not sending notifications — webhook URL unreachable
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `alertmanager` `notifications` `webhook`
  - **Services:** [alertmanager, alertmanager-config]
  - **Symptoms:** Alerts firing in Prometheus but no notifications received; Alertmanager logs show "sending failed"
  - **Investigation steps:** kubectl logs alertmanager-xxx | grep -i "send\|error\|webhook"; kubectl exec -it alertmanager-xxx -- amtool config show; kubectl exec -it alertmanager-xxx -- curl -v <webhook-url>
  - **Expected fix:** Check webhook URL accessibility, verify TLS cert, check retry configuration, validate alert routing

- [ ] TASK-036: Metrics-server returning stale data — node metrics 5min old
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `metrics-server` `stale` `kubelet`
  - **Services:** [metrics-server, kubelet]
  - **Symptoms:** kubectl top node shows old data; HPA not scaling; metrics-server logs show "unable to scrape"
  - **Investigation steps:** kubectl top node; kubectl logs metrics-server-xxx | grep -i "scrape\|error"; curl -sk https://<node>:10250/metrics/resource | head -20
  - **Expected fix:** Restart metrics-server, check kubelet read-only port 10250, verify kubelet certificate

## Deployment & Release

- [ ] TASK-037: Deployment stuck at RollingUpdate — new pod CrashLoopBackOff
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `deployment` `rolling-update` `stuck`
  - **Services:** [deployment, replicaset]
  - **Symptoms:** kubectl rollout status shows stuck at 75%; old pods still running; new pod restarting
  - **Investigation steps:** kubectl rollout status deployment/<deploy>; kubectl get rs; kubectl logs <new-pod> --previous | tail -30; kubectl describe pod <new-pod>
  - **Expected fix:** Check new image tag, review app logs for config issue, rollback with kubectl rollout undo, fix forward

- [ ] TASK-038: Helm release failed — chart upgrade rolled back
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `helm` `release` `upgrade`
  - **Services:** [helm, release]
  - **Symptoms:** helm history shows last release "FAILED"; helm upgrade times out; resources not updated
  - **Investigation steps:** helm history <release> -n <ns>; helm get notes <release> -n <ns>; kubectl get events --sort-by='.lastTimestamp' | head -20; helm test <release> -n <ns>
  - **Expected fix:** Check values override syntax, review pre-upgrade hooks, check resource quotas, rollback to last successful release

- [ ] TASK-039: ArgoCD sync failure — application stuck in OutOfSync
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 2h | **Tags:** `argocd` `sync` `gitops`
  - **Services:** [argocd, application]
  - **Symptoms:** ArgoCD UI shows OutOfSync; sync fails with "unable to apply manifests"; application state not matching git
  - **Investigation steps:** argocd app get <app>; argocd app sync <app> --dry-run 2>&1; kubectl logs -n argocd argocd-application-controller-xxx | grep -i "error\|sync"
  - **Expected fix:** Check manifest syntax, verify ArgoCD repo access, review RBAC for ArgoCD, check resource conflicts

- [ ] TASK-040: Terraform apply stuck — state lock timeout
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `terraform` `state` `lock`
  - **Services:** [terraform, state-backend]
  - **Symptoms:** terraform apply hangs at "Acquiring state lock"; another apply might be running; state file locked
  - **Investigation steps:** terraform state list; terraform force-unlock <lock-id>; ps aux | grep terraform; ls -la .terraform.lock.hcl
  - **Expected fix:** Force-unlock state, check for stuck CI jobs, ensure only one terraform runs at a time, use remote state with proper locking

## Container Runtime

- [ ] TASK-041: Container in CrashLoopBackOff — application exits immediately
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `container` `crash` `exit`
  - **Services:** [deployment]
  - **Symptoms:** Pod restarts every 5s; lastState shows exit code 1; logs show application error
  - **Investigation steps:** kubectl logs <pod> --previous | tail -50; kubectl describe pod <pod> | grep -A5 "State"; kubectl exec -it <pod> -- cat /app/app.log
  - **Expected fix:** Fix application crash, check environment variables, verify mounted volumes, check init container logs

- [ ] TASK-042: Container cannot write to volume — read-only filesystem
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `volume` `permission` `readonly`
  - **Services:** [deployment, pvc]
  - **Symptoms:** Application logs show "Read-only file system"; container exits with permission error
  - **Investigation steps:** kubectl describe pod <pod> | grep -A5 "Mounts"; kubectl exec -it <pod> -- touch /data/test; kubectl get pvc <pvc> -o jsonpath='{.spec.accessModes}'
  - **Expected fix:** Set readOnlyRootFilesystem=false in securityContext, check PVC access modes, verify mount permissions

- [ ] TASK-043: Pod stuck in Terminating — finalizer blocking deletion
  - **Priority:** P1 | **Sprint:** 2 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `pod` `finalizer` `stuck`
  - **Services:** [deployment, finalizer]
  - **Symptoms:** Pod stuck in Terminating for 10+ minutes; kubectl delete times out; finalizers listed in metadata
  - **Investigation steps:** kubectl get pod <pod> -o json | jq '.metadata.finalizers'; kubectl patch pod <pod> -p '{"metadata":{"finalizers":null}}'; kubectl describe pod <pod>
  - **Expected fix:** Remove finalizer if stuck, check operator managing the resource, verify graceful shutdown timeout

- [ ] TASK-044: Image build failing in CI — layer cache corrupted
  - **Priority:** P2 | **Sprint:** 3 | **Status:** backlog
  - **Estimate:** 1h | **Tags:** `docker` `build` `cache`
  - **Services:** [ci-runner, docker, registry]
  - **Symptoms:** CI pipeline fails at "docker build"; error "failed to solve: failed to compute cache key"; build takes 10x longer without cache
  - **Investigation steps:** docker build --no-cache . 2>&1; docker system df; docker builder prune -f; cat Dockerfile | grep COPY
  - **Expected fix:** Clear builder cache, fix Dockerfile layer ordering, use multi-stage build, configure cache mounts

- [ ] TASK-045: k3s service crash loop — kube-proxy iptables "Table does not exist"
  - **Priority:** P0 | **Sprint:** 1 | **Status:** backlog
  - **Estimate:** 3h | **Tags:** `k3s` `kube-proxy` `iptables` `kernel`
  - **Services:** [k3s, kube-proxy, lxc-containers]
  - **Symptoms:** k3s.service restarts every 10s; logs show "kube-proxy exited" and "Table does not exist"; all pods evicted
  - **Investigation steps:** journalctl -u k3s -n 50 --no-pager; ssh k3s-master; systemctl status k3s; modprobe ip_tables 2>&1; lsmod | grep ip_tables
  - **Expected fix:** Ensure kernel modules loaded on host (ip_tables, ip6_tables, iptable_nat, iptable_filter, nf_tables, br_netfilter), set linux.kernel_modules in Incus config, restart container. See bug-008 for details.
