# Networking Troubleshooting (MetalLB + Istio + cert-manager)

> Ingress and TLS home: MetalLB pool, Istio mesh, DNS-01 issuance, Gateway catalog.
> Master log: `../ansible/ansible-setup-troubleshooting.md` (ERRORs 54–55, 59–64, 76).
> *Last Updated: 2026-09-13 — MetalLB pool live, wildcard cert Ready, Istio 1.30.4; 11 Gateway routes (5 original + forgejo + 5 monitoring UIs + vault TLS origination); OTel excluded (no UI). TASK-260 DONE: flannel→tailscale0 on 3/3 nodes, 5b 0% loss both ways*
> sidecar/PERMISSIVE, gateway `.100`, Gateway+VS for argocd/minio/sonar/forgejo.* + monitoring UIs (grafana:3000/prometheus:9090/alertmanager:9093/jaeger:16686/loki:3100 via mon-ext) + vault.* (TLS origination via DestinationRule SIMPLE+insecureSkipVerify). OTel excluded (no UI). Unknown *.domain hosts → Envoy 404 (Gateway holds the wildcard cert, so TLS succeeds before routing fails).

## 1. Current State (2026-09-09)

| Layer | Value |
|---|---|
| MetalLB pool | `10.195.94.100-150` (L2 mode; speakers on master + worker-1; worker-2 speaker CrashLoops — cross-PC L2 can't work, harmless) |
| Istio | 1.30.4 upstream Helm, sidecar mode, mesh-wide PERMISSIVE (`PeerAuthentication default/istio-system`) |
| Control plane | istiod + ingress gateway pinned to `k3s-master` (`nodeSelector`, stretched-cluster rule) |
| Gateway service | `istio-ingress/istio-ingressgateway`, `loadBalancerIP: 10.195.94.100` (asserted in-role) |
| TLS | cert-manager DNS-01/Cloudflare → wildcard `*.devops-devsecops.kdns.fr` cert (`wildcard-tls` secret, `istio-ingress` ns) |
| Cloudflare token | Vault `kv/cloudflare` → K8s secret `cloudflare-api-token-secret` (never in git) |
| Gateway catalog | `main-gateway` (wildcard TLS) + VS: `argocd`, `minio-console`/`minio-api` (ServiceEntry), `sonarqube` (ServiceEntry) |

## 2. Traffic Model (read this before debugging any URL)

```
browser --(SNI host, TLS wildcard)--> .100 gateway --(HTTP LAN)--> backend
```
- Routing key = **SNI hostname**, not path/IP. SNI-less curl to the bare IP
  returns `000` (Envoy drops it) — normal, not a fault (ERROR 76).
- Gateway terminates TLS; mesh→backend hops are plain HTTP on the private LAN.
- Off-cluster backends (MinIO on master, SonarQube on PC2) attach via
  `ServiceEntry` (MESH_EXTERNAL/STATIC, endpoint = IP reachable **from the
  gateway pod**: Tailscale, never PC2-bridge).
- In-cluster backends (ArgoCD server) route by `<svc>.<ns>.svc.cluster.local`.

## 3. Verification Commands

```bash
kubectl -n istio-ingress get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'  # .100?
kubectl get gateway -A; kubectl get virtualservice -A          # catalog present?
kubectl -n istio-ingress get certificate wildcard-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'  # True?
kubectl -n istio-system get pods; kubectl -n istio-ingress get pods   # Running on master?
# End-to-end WITH SNI (bypasses DNS cache):
curl -sk -o /dev/null -w "%{http_code}\n" --resolve <host>:443:10.195.94.100 https://<host>/
```

## 4. Install Flow (`site-networking.yml`: metallb → cert-manager → istio)

1. MetalLB manifest + `IPAddressPool` + L2Advertisement (idempotent guards).
2. cert-manager manifest → Vault unseal-check → token fetch (KV version-aware,
   ERROR 58) → Cloudflare secret → DNS-01 ClusterIssuer → wildcard Certificate
   (300s Ready wait; ACME + DNS propagation need minutes).
3. Istio: repo → `base` → `istiod` (default profile, 512Mi/250m requests for
   small nodes, ERRORs 60/62) → per-release presence guards → nodeSelector pins
   (ERROR 61) → gateway chart (pinned `.100`, asserted) → Gateway + VS template
   → PERMISSIVE policy. Waits use `rollout status`, never pod selectors (ERROR 63).

## 5. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| 54 | nginx helm pre-install timeout, partial release | Removed nginx entirely → Istio; `helm uninstall` + ns delete leftovers |
| 55 | HTTP-01 challenges never complete (private IPs) | DNS-01/Cloudflare; token in Vault; wildcard cert |
| 59 | chart version not in index though released | Pin latest *published* chart (`helm search repo --versions`); announcements outpace charts |
| 60 | `unknown profile k3s`; half-install never converges | Drop profile flag (default); per-release presence guards on install AND wait |
| 61 | Infra pods Unready on cross-PC worker | nodeSelector-pin to PC1 master; durable fix = `--flannel-iface=tailscale0` DONE 2026-09-13 (runbook `TASK-260-flannel-tailscale-migration.md`; 3/3 restarted, VTEPs all-Tailnet, 5b 3/3 0% loss both ways) |
| 62 | Pod Pending `Insufficient memory` at "7% usage" | Check **allocatable** (k3s reserves ~2GB/4GB node); lower requests (istiod 512Mi) |
| 63 | `kubectl wait` selector poisoned by dying RS pods | `rollout status deployment/<name>` after any patch/upgrade |
| 76 | HTTPS name "Unable to connect" though DNS resolves | Name must hit Gateway `.100` (TLS lives there), not backend IP; SNI-less `000` is normal |

## 6. First-Actions Runbook (URL broken?)

1. `--resolve` test (§3) — 200 ⇒ cluster fine, fault is DNS/cache (check `1.1.1.1` vs system resolver).
2. `000` with SNI ⇒ gateway/speaker down: pods? LB IP still `.100`? MetalLB speakers?
3. `503` ⇒ route matched, backend missing/down (ERROR 64 pattern): endpoints exist? app installed?
4. Cert not Ready ⇒ `describe certificate/challenge`: Cloudflare token valid? DNS propagation? Vault unsealed?
5. New hostname ⇒ Gateway covers `*.domain` already; only a VirtualService (+ServiceEntry if external) is needed — never new DNS, never new certs.
