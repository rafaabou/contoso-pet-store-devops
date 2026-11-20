# ANSIBLE USER GUIDE — Live Infrastructure Playbooks

Companion to `README.md` (setup story) and `OPENTOFU-GUIDE.md` (provisioning tutorial).
This file is the day-to-day operator manual: what runs where, in what order,
with which secrets, and how failures are diagnosed. All facts verified against
the live tree — not aspirational.

> **Operating rule (standing):** the assistant never executes. Every command
> below is run by the operator, one step at a time, with output reported back.
> File edits belong to the assistant; shell/tofu/ansible/incus belong to you.

---

## 1. Layout (actual, 20 roles + 15 playbooks)

```
ansible/
├── ansible.cfg              # roles_path=roles, fact_caching, SSH multiplexing
├── site.yml                 # master: 15 imports, cluster → security (order matters)
├── setup-ssh-keys.sh        # one-time key distribution (all 8 hosts, Tailscale-aware)
├── inventory/
│   ├── hosts.ini            # 8 hosts: PC1 bridge IPs + PC2 Tailscale IPs, SSH keys ONLY
│   └── group_vars/
│       ├── all.yml          # versions, domain, IPs, Vault names, OIDC pins
│       ├── forgejo_server.yml  # ci-light label + capacity 1
│       └── ci_runners.yml      # ci-heavy label + capacity 2
├── playbooks/               # one concern each; site.yml imports in dependency order
└── roles/                   # 20 roles (config owns the how, playbooks own the when)
```

## 2. Inventory — Read This Before Touching Anything

- **PC1 hosts use bridge IPs** (`10.195.94.x` — same LAN as the operator).
- **PC2 hosts use Tailscale IPs** (`100.x` — PC2 bridge is invisible cross-PC).
- **SSH keys only.** Password auth was retired (see ERROR 28); `setup-ssh-keys.sh`
  distributes keys. Fresh Ubuntu images need `openssh-server` installed +
  direct key push first (root password is locked — `ssh-copy-id` can never
  succeed there; ERROR 87). PC2's controller user has no keypair: `scp` PC1's
  public key over first (ERROR 88).
- **Prompt discipline:** `antix@antix` = PC1, `antix@home` = PC2. Wrong prompt
  → `ssh` first, never apply (ERROR 85 family).

## 3. Playbook Catalog (site.yml order — dependencies flow downward)

| # | Playbook | Does | Key roles |
|---|---|---|---|
| 1 | site-cluster.yml | K3s server + agents join (K3S_URL/K3S_TOKEN env, never flags) | k3s-master, k3s-worker |
| 2 | site-nfs-server.yml | NFS exports on master (restricted, root_squash) | nfs-server |
| 3 | site-nfs-client.yml | NFS mounts on workers ONLY (unprivileged VMs get disk devices) | nfs-client |
| 4 | site-node-exporter.yml | Node metrics on K3s nodes | node-exporter |
| 5 | site-tools.yml | kubectl/helm/k9s toolchain on nodes | tools |
| 6 | site-vault.yml | Vault: TLS + auto-init/unseal + KV-v2 + OIDC method/role | vault |
| 7 | site-networking.yml | MetalLB (PC1-pinned speakers) + Istio + cert-manager DNS-01 + all Gateway routes | metallb, istio, cert-manager |
| 8 | site-monitoring.yml | Prometheus/Grafana/Alertmanager (+ blackbox role) + Grafana SSO | monitoring, blackbox |
| 9 | site-opentelemetry.yml | OTel Collector + Jaeger (OTLP disabled) + Loki | opentelemetry |
| 10 | site-minio.yml | MinIO S3 (Vault creds + OIDC, health-gated on :9000) | minio |
| 11 | site-sonarqube.yml | PostgreSQL (data-dir move) + SonarQube + branch plugin (+ OIDC plugin) | postgres-local, sonarqube |
| 12 | site-argocd.yml | ArgoCD pinned PC1-local (+ Dex OIDC connector) | argocd |
| 13 | site-apps.yml | Application namespace (idempotent create) | — |
| 14 | site-forgejo.yml | Forgejo server + host-label runners (server-minted tokens) | forgejo, forgejo-runner |
| 15 | site-security.yml | RBAC + NetworkPolicies lockdown | — |

Run one: `ansible-playbook playbooks/<name>.yml -i inventory/hosts.ini 2>&1 | tee /tmp/ansible-<name>.log`
Run all: `ansible-playbook site.yml -i inventory/hosts.ini` (expect `failed=0` on all hosts — the convergence proof).

## 4. Vault Patterns (used identically by 6 roles — learn once)

```yaml
# 1. Read init file FROM the vault host (roles run elsewhere):
- slurp: {src: /root/vault-init.json}
  register: x_vault_init_b64
  delegate_to: "{{ groups['vault_server'][0] }}"
# 2. Parse token silently:
- set_fact: {x_vault_token: "{{ (x_vault_init_b64.content | b64decode | from_json).root_token }}"}
  no_log: true
# 3. Read KV (v2 path!) with the token, never logged:
- uri: {url: "{{ vault_addr }}/v1/kv/data/<name>", headers: {X-Vault-Token: "{{ x_vault_token }}"}}
  register: x_kv
  no_log: true
# 4. Facts feed templates; values NEVER appear in logs, chat, or files.
```

KV paths in use: `cloudflare` (cert-manager), `sonarqube`, `argocd`, `forgejo` (admin only — runner tokens are machine-to-machine), `grafana`, `minio` (root pair), `alertmanager` (Telegram pair), `sso/*` (5 OAuth client pairs).

Seal discipline: seal state is in-memory — every Incus apply on the Vault host
is followed by a seal check; re-run `site-vault.yml` to auto-unseal (ERROR 86).

## 5. Idempotency Idioms (why re-runs are clean)

- **Namespaces:** `create --dry-run=client -o yaml | kubectl apply -f -` with
  `changed_when: 'created' in stdout` (never bare create — ERROR 81).
- **Absence-tolerant checks:** `failed_when: false` + rc-branches (never
  `ignore_errors` for flow control — it still prints ERROR blocks; ERROR 84).
- **Sealed-is-a-state:** Vault rc 0/2 both proceed; only other codes fail (ERROR 86).
- **First-run-only artifacts:** `creates:` guards, version-gated downloads,
  once-secrets (redis, admin passwords). Re-runs print `ok`, not work.
- **Render like Ansible does:** local Jinja tests must use `trim_blocks=True`
  (ERROR 101 follow-on); Prometheus `{{ }}` goes in `{% raw %}` mid-line only.

## 6. Gateway Exposure Pattern (copy for every new UI)

ServiceEntry (external IP, STATIC) + VirtualService (hostname → ServiceEntry),
both in `istio-ingress`. TLS backends (Vault :8200) add a DestinationRule
(SIMPLE + insecureSkipVerify on the LAN hop). HTTP backends route straight.
Wildcard DNS covers every future name — zero DNS work per service.
Template: `roles/istio/templates/gateway.yml.j2` (15 docs, all vars in group_vars).

## 7. SSO Wiring (Forgejo-as-IdP, per app)

Grafana (generic OAuth) → ArgoCD (Dex connector, merge-patch + dual restart
rule) → SonarQube (custom OIDC plugin `~/sonarqube-auth-forgejo/`) + MinIO
(env vars, per-user policies) → Vault OIDC last (token auth stays forever).
Break-glass local logins stay ON everywhere, drilled quarterly. Full matrix:
`devops-complete-guide/troubleshooting/sso/`.

## 8. Logs, Verification, Troubleshooting

- Every run: `tee /tmp/ansible-<play>.log`; diagnose from the log, never memory.
- Verify per layer: playbook recap (`failed=0`) → route codes (`curl`,
  200/302/307 healthy, 403-anon healthy) → UI eyeball → Vault metadata
  (versions only, never values).
- **112 ERRORs** with fixes live in
  `devops-complete-guide/troubleshooting/ansible/ansible-setup-troubleshooting.md`
  + 13 component homes (state, flow, verify, error catalog each).
- Task system: `devops-complete-guide/TASKS.md` board + `tasks/daily/` logs.
