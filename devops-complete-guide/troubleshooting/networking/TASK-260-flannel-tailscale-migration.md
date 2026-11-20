# TASK-260: Flannel onto `tailscale0` (cross-PC pod networking) — Runbook

> Status: DONE 2026-09-13 — window 2026-09-12→13; worker-1 Tailnet .108, 3/3 restarted with flag, VTEPs all-Tailnet (master .206.35, worker-1 .126.108, worker-2 .113), 5b flights 3/3 0% loss both ways (10.42.0.105 ↔ 10.42.2.30); guards intact, pigeons cleaned.
> Board: `TASKS.md` P2 Infrastructure, blocked since 2026-09-09. Related: bug-030, ERROR 61.

## 0. The idea (12-year-old version)

Pods on different PCs talk through underground tunnels (flannel VXLAN). Each
node shouts its tunnel address so others can find it. Right now worker-2
shouts its **hallway address** (a bridge IP nobody outside PC2 can reach), so
packets walk into a wall. This op makes every node shout its **Tailnet
address** (`tailscale0`), which everyone can reach. Same tunnels, correct
addresses.

## 1. What this changes (and does NOT)

- CHANGES: the VXLAN underlay interface on 3 k3s nodes (one config line each + restart).
- DOES NOT CHANGE: node IPs, pod CIDRs, Service/ClusterIP, DNS, Gateway/certs,
  Vault, MetalLB, or the istiod/gateway nodeSelector pins (pins stay until a
  later, separate decision — NOT this window).

## 2. Preconditions (all green before touching k3s)

- [ ] P0 — `tailscale0` exists on ALL THREE k3s nodes:
  `k3s-master` (has Tailscale, IP `100.119.206.35`), `k3s-worker-1` (**NO
  Tailscale yet — install + `tailscale up` first, operator terminal,
  interactive login**), `k3s-worker-2` (Tailscale-only already).
  Verify per node: `ip addr show tailscale0` returns an interface (no restart needed for this step).
- [ ] P1 — No conflicting flag: `systemctl cat k3s | grep -c flannel-iface` on
  master and `systemctl cat k3s-agent | grep -c flannel-iface` on workers must
  print `0` (neither role sets it today; if non-zero → STOP, report, plan changes).
- [ ] P2 — Window declared (~30–45 min). Expect: brief API blips during the
  server restart; cross-node pod traffic broken MID-migration (mixed old/new
  tunnel addresses — normal, judge only after all 3 restarted). Pods keep
  running; nothing is deleted.
- [ ] P3 — Break-glass ready: SSH to all 3 nodes works; every command below is
  given one step at a time (standing rule).

## 3. Steps (operator runs, one at a time, report back each)

**Step 1 — worker-1 joins the Tailnet** (k3s untouched):
install Tailscale on `k3s-worker-1` (10.195.94.81), `tailscale up` (browser
login), then `tailscale status` shows all nodes and `ip addr show tailscale0`
is present. Report the tailscale0 IP.

**Step 2 — write the one-line config on all 3 nodes** (no restarts yet):
- master `/etc/rancher/k3s/config.yaml`: append `flannel-iface: tailscale0`
  (file already exists — holds the `tls-san` block; ADD the line, don't replace).
- workers `/etc/rancher/k3s/config.yaml`: CREATE with the single line
  `flannel-iface: tailscale0` (agents have no config file today).
- Assert: `cat /etc/rancher/k3s/config.yaml` shows the line on each node.

**Step 3 — restart in order, waiting between each:**
1. master: `systemctl restart k3s` → wait `k3s kubectl get nodes` shows master Ready + API answers.
2. worker-1: `systemctl restart k3s-agent` → master reports it Ready.
3. worker-2: `systemctl restart k3s-agent` → master reports it Ready.
Report `get nodes` after each.

**Step 4 — behavioral proof (the only verdict that counts):**
1. All 3 nodes `Ready`.
2. `ip link show flannel.1` exists on each node.
3. Cross-node ping: temp busybox pod pinned to master + temp busybox pod pinned
   to worker-2, ping pod-IP both directions → both succeed. Delete temp pods after.
4. Cross-PC service check: from the worker-2 pod, `curl` a ClusterIP service
   backed by a master pod → 200.
Report all four. Pins stay — this window proves the underlay, unpinning is later.

## 4. Rollback (any step red — < 10 min)

1. Delete the `flannel-iface` line (or the created file on workers).
2. Restart the changed nodes in the same order as §3.
3. Verify nodes Ready + master-local traffic fine.
Mid-migration breakage is EXPECTED (mixed addresses) — rollback only if the
post-restart §4 proof fails. No data loss path exists in this op (config line only).

## 5. Close-out (assistant side, after green §4)

- Move TASK-260 TODO → DONE in `TASKS.md` + `tasks/categories/infrastructure.md`.
- Daily log: result + VTEP evidence.
- Leave ERROR 61 history intact; append pointer to this file.
