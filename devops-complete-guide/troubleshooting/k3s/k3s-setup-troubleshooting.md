# K3s Cluster Troubleshooting

> K3s home: LXC prerequisites, install modes, cross-PC join, kubeconfig, pod networking.
> Master log: `../ansible/ansible-setup-troubleshooting.md` (ERRORs 47–48, 50, 61–62, 77,
> W-3/W-9/W-18 + k3s role-fix era). *Last Updated: 2026-09-10 — 3/3 nodes Ready; observability edge live (Alloy DaemonSet 3/3 + KSM).*

## 1. Current State (2026-09-09)

| Node | IP | Role | Notes |
|---|---|---|---|
| k3s-master | 10.195.94.80 (+ Tailscale 100.119.206.35) | control-plane | v1.36.4+k3s1, privileged, etcd embedded |
| k3s-worker-1 | 10.195.94.81 | worker | v1.36.4+k3s1, privileged, PC1-local |
| k3s-worker-2 | 100.100.13.113 (Tailscale) | worker | v1.36.4+k3s1, privileged, PC2, joins via master Tailscale URL |

All nodes: `overlay` + `br_netfilter` via host (`linux.kernel_modules`), `/dev/kmsg`
symlink + `/proc/sys` remount (`lxc-prerequisites` role), node-exporter :9100,
kubectl kubeconfig present (`/etc/rancher/k3s/k3s.yaml` + `/root/.kube/config`).

## 2. LXC Rules (why K3s-in-LXC needs special handling)

1. **No `/lib/modules` inside** — containers share the host kernel. Never
   `modprobe` in-container; verify via `/sys/module/<name>` (ERROR 47). Modules
   load from the host via Incus `linux.kernel_modules` at container start.
2. **`/proc/sys` is read-only** — kubelet writes `kernel/panic`; remount rw via
   `proc-sys-rw.service` ordered `Before=k3s.service` (ERROR 11-era).
3. **No `/dev/kmsg`** — symlink to `/dev/console` via `dev-kmsg.service`.
4. Both fixes live once in the shared `lxc-prerequisites` role (not copy-pasted).

## 3. Install Modes (the etcd trap)

- Server: bare install (no URL) → `k3s.service`.
- Agent: **env vars** `K3S_URL` + `K3S_TOKEN` → `k3s-agent.service`.
- Never CLI flags `--server/--token` (unreliable agent detection → server boot
  → `failed to bootstrap cluster data: etcd disabled`, ERROR 48).
- Strip `modprobe ExecStartPre` lines from installed units (fail in LXC).
- Agent token: fetched from master (`/var/lib/rancher/k3s/server/node-token`);
  delete `/tmp/k3s-node-token` off-controller after all joins (C-8).

## 4. Cross-PC Join (worker-2 pattern)

- Master needs in-container Tailscale (`tailscale up` + browser auth once).
- Worker uses `k3s_server_url=https://<master-tailscale-ip>:6443` (host var in
  `hosts.ini`); same override pattern reused for NFS (`nfs_server_override`, ERROR 53).
- kubeconfig server URL rewritten per worker (ERROR 77).
- API serving cert must list the Tailscale IP: `/etc/rancher/k3s/config.yaml`
  `tls-san: [<master-tailscale-ip>]` (role-managed; restart regenerates serving
  certs only). Verified 2026-09-09: worker-2 kubectl 3/3 post-restart.
- **Known limitation:** flannel binds `eth0` → cross-PC pod traffic blackholed
  (VTEPs unroutable, ERROR 61). Infra stays PC1-pinned; durable fix queued:
  `--flannel-iface=tailscale0` cluster-wide + Tailscale in worker-1.

## 5. Verification Commands

```bash
kubectl get nodes -o wide                          # 3/3 Ready, correct IPs/versions
kubectl -n kube-system get pods                    # coredns/traefik/kanal healthy
# Per node (via incus exec or ssh):
cat /proc/sys/kernel/panic >/dev/null && echo PROC_SYS_RW
ls /dev/kmsg && echo KMSG_OK
ls /sys/module/br_netfilter /sys/module/overlay   # host-loaded modules visible
systemctl is-active k3s k3s-agent                  # whichever applies
# Worker kubeconfig sanity:
kubectl --kubeconfig=/dev/null get nodes 2>&1 | head -1   # must NOT be used; real:
kubectl get nodes | head -3                        # works from any node (ERROR 77 fix)
```

## 6. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| 11-era | kubelet `Failed to start ContainerManager`, master crash-loops | `proc-sys-rw.service` remount (fstab bind line alone doesn't apply) |
| 47 | `modprobe: FATAL ... not found` in container | Check `/sys/module/`, never modprobe; host loads via `linux.kernel_modules` |
| 48 | agent boots as server (`etcd disabled`) | `K3S_URL`+`K3S_TOKEN` env (not CLI flags); uninstall broken install first; drop modprobe pre-steps |
| 50 | cross-PC agent `CA certs: context deadline exceeded` | master Tailscale + per-worker `k3s_server_url` |
| 61 | pods Unready cross-PC; ClusterIP loss; kubelet 502s | flannel VTEP blackhole — pin infra to PC1 now; `flannel-iface` migration later |
| 62 | Pending `Insufficient memory` at low usage % | size against **allocatable** (k3s reserves ~2GB/4GB node) |
| 77 | `localhost:8080 refused` on workers | distribute admin kubeconfig with rewritten server URL |
| W-3 | master/workers version skew | no fallback defaults — single `{{ k3s_version }}` everywhere |

## 7. First-Actions Runbook (node NotReady?)

1. `kubectl describe node` — pressure conditions? allocatable vs requests?
2. On the node: `systemctl status k3s*` + `journalctl -u k3s(-agent) --no-pager | tail`.
3. LXC trio: `/dev/kmsg`, `/proc/sys` rw, `/sys/module/{br_netfilter,overlay}`.
4. Cross-PC only: Tailscale up both ends? VTEP reachability (`bridge fdb`, ClusterIP ping)?
5. Join issues: token fresh? (tokens rotate on server re-install) → re-fetch; server URL reachable from worker?
