# ArgoCD Troubleshooting

> GitOps delivery home. Master log: `../ansible/ansible-setup-troubleshooting.md`
> (ERRORs W-13, C-7, 78 + argocd role, SSO ERRORs 106/107). *Last Updated: 2026-09-10 — ArgoCD 7/7
> Running PC1-local (taint enforced), `argocd.*` → 307 via Gateway. In-cluster
> confirmed as production pattern. Open: initial login + password rotation.*

## 1. Current State (2026-09-09)

| Item | Value |
|---|---|
| Version | pinned `argocd_version` in group_vars (never `stable` manifest — W-13) |
| Install | plain manifests (`install.yaml` @ tag, `argocd` ns) — no Helm, no operator |
| Exposure | Istio Gateway + VirtualService (`argocd.<domain>`, wildcard TLS) — applied by the **istio** role, NOT an nginx Ingress (removed) |
| Credentials | initial admin password in `argocd-initial-admin-secret`; fetched via jsonpath, **never written to files** (C-7: old code saved `/tmp/argocd-credentials.txt`) |

## 2. How to Install (playbook order = dependency order)

```bash
ansible-playbook playbooks/site-argocd.yml -i inventory/hosts.ini   # role: ns → redis secret (once, random) → pinned manifests v2.12.5 → taint remote worker → recycle misplaced pods → rollout wait
ansible-playbook playbooks/site-networking.yml -i inventory/hosts.ini  # istio role publishes Gateway + argocd VS (port 80) + insecure+url params patch
```
- 7/7 pods pinned PC1-local (remote-worker taint + nodeSelector; cross-PC flannel can't carry them — ERROR 61).
- Verify: `kubectl -n argocd get pods` (7 Running, all on master/worker-1) → `https://argocd.<domain>/` 200 login HTML → UI login works.
- Rollback: `kubectl delete -f <install.yaml>` + delete ns (stateless — all state is git + `argocd-secret`).

## 3. First-Login Runbook (do this once, then close the loop)

```bash
kubectl -n argocd get pods                                   # server Running?
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
# Open https://argocd.<domain> → login admin/<above> → change password immediately
# Store the NEW value (example pattern from sonarqube):
#   vault kv put kv/argocd admin_password=<NEW>
# Delete the initial secret after first login:
kubectl -n argocd delete secret argocd-initial-admin-secret
```

## 3b. Rotate/Create Password WITH Vault (no plaintext anywhere)

```bash
# 1. One-time CLI (single binary, /tmp — ArgoCD alone mints valid bcrypt):
ssh root@10.195.94.80 "curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/download/v2.12.5/argocd-linux-amd64 && chmod +x /tmp/argocd"
# 2. Mint hash INTERACTIVELY on master (prompts securely — nothing in history, never in chat):
ssh root@10.195.94.80
HASH=$(/tmp/argocd account bcrypt)   # type chosen value at prompt, twice
# 3. Patch live secret + fresh mtime, restart server (still on master):
kubectl -n argocd patch secret argocd-secret -p "{\"stringData\":{\"admin.password\":\"$HASH\",\"admin.passwordMtime\":\"$(date -u +%FT%T%Z)\"}}"
kubectl -n argocd rollout restart deployment/argocd-server
# 4. Verify: log out → log in with the CHOSEN value (proves the hash, not hope)
# 5. Record (your terminal — type the same chosen value, never shown elsewhere):
vault kv put kv/argocd admin_password=THE_VERIFIED_VALUE   # via incus exec k3s-vault pattern
# 6. Burn superseded versions: vault kv destroy -versions=<olds> kv/argocd
```
Order is the whole method: mint → cluster → verify → record → burn. Reversing
record/verify manufactures split-brain (ERROR 83). Full automation (Vault as
source of truth) = External Secrets Operator, tracked separately.

## 3c. Verification Commands

```bash
kubectl -n argocd get pods,svc                               # server + repo-server + controller + redis
kubectl get virtualservice argocd -n argocd                  # Gateway binding intact?
curl -sk -o /dev/null -w "%{http_code}\n" --resolve argocd.<domain>:443:10.195.94.100 https://argocd.<domain>/  # 200/307 (503 = server down, ERROR 64 pattern)
argocd login argocd.<domain> --username admin --insecure     # CLI check (after tools: `argocd` CLI optional)
```

## 4. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| W-13 | ArgoCD version drifted between runs | Pin `argocd_version`; install manifest @ tag |
| C-7 | Admin password in plaintext file | Display-only credential task; save to Vault; delete initial secret post-login |
| 64-pattern | Gateway 503 on `argocd.*` | Backend (argocd-server) down or not yet installed — route is fine, app isn't |
| — | `argocd` ns missing when istio role applies VS | istio role pre-creates the namespace (ordering-proof) |

## 5. GitOps Wiring (when apps deploy — future)

- Repo credentials → Vault (`kv/argocd`), referenced by ApplicationSets — never in git.
- Rollouts canary analysis needs Istio traffic splitting (already meshed) + Prometheus metrics (already scraped).
- App namespaces get `istio-injection=enabled` labels at deploy time (sidecar mode); keep ArgoCD itself **out** of the mesh initially (fewer moving parts).
