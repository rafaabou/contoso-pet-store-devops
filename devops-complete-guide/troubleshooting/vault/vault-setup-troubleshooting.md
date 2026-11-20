# Vault Setup Troubleshooting

> Vault home: install flow, seal lifecycle, KV layout, role-integration pattern.
> Master log: `../ansible/ansible-setup-troubleshooting.md` (ERRORs C-2, C-3,
> 26, 56–58). *Last Updated: 2026-09-10 — Vault serving TLS, unsealed, KV paths: cloudflare/sonarqube/argocd/forgejo/grafana/minio/alertmanager/sso/* (750MB trim holding; ERRORs 86/103 survived: reseal + key rotation).*

## 1. Current State (2026-09-09)

| Item | Value |
|---|---|
| Location | PC1 container `k3s-vault` (`10.195.94.200:8200`), UI `/ui` |
| TLS | Self-signed (`/etc/vault.d/vault.crt`, CN=host IP + SANs); clients use `VAULT_SKIP_VERIFY` / `validate_certs: no` on the private LAN |
| Init material | `/root/vault-init.json` mode 0600 (root token + 1 unseal key, threshold 1) |
| Storage | `file` backend `/opt/vault/data` (single node — Raft removed, C-2/W-19) |
| Engines | `kv-v2` at `kv/` |
| Secrets | `kv/cloudflare`, `kv/sonarqube`, `kv/argocd` (v6, olds destroyed), `kv/forgejo` (v1), `kv/alertmanager` (bot+chat), `kv/sso/*` (5 OAuth clients) |
| DNS | `vault.*` → `.200` direct + Gateway route (valid LE cert, TLS origination) |

## 2. How to Install (playbook order = dependency order)

```bash
ansible-playbook playbooks/site-vault.yml -i inventory/hosts.ini  # role: apt (HashiCorp key check-then-remove, ERROR 103) → TLS self-signed → config → systemd → auto-init/unseal from init file → KV-v2 enable → seal-race guards (ERROR 29/86)
```
- Version 2.1.0, single node, threshold 1 (one unseal key — homelab scale; Raft+KMS is Phase C production work).
- Verify: `vault status` → `Sealed false` → `vault kv list kv/` shows all engines above.
- Rollback: keep `/root/vault-init.json` (ONLY copy of root token + unseal key — losing it with a sealed Vault = full reinstall + reseeding). Service restart re-seals: follow every restart with the seal check.

## 3. Seal Lifecycle (the one concept that explains most Vault failures)

Vault **seals on every restart/reboot** (by design — keys leave memory). Sealed =
HTTP 503 on all privileged APIs; unseal needs the key from `/root/vault-init.json`.
Consequences enforced in automation:
- Playbooks must check seal state **fresh, immediately before** privileged calls —
  never trust an early check (a config-handler restart re-seals mid-run, ERROR 57).
- `vault status` exit codes: `0` unsealed, `2` sealed, anything else (e.g. `1`)
  is a *connection* error — retry, don't treat as state (ERROR 57 follow-up).

```bash
# Read-only diagnosis (inside container)
export VAULT_ADDR='https://127.0.0.1:8200' VAULT_SKIP_VERIFY=true
vault status                          # Sealed true/false
vault secrets list                    # 403 = sealed OR bad token; distinguish via status first
# Recovery (no re-run needed — mounts and data persist across seals)
vault operator unseal $(jq -r '.unseal_keys_b64[0]' /root/vault-init.json)
```

**Auto-unseal on boot (live since 2026-09-10, proven by 2 reboot tests):**
`vault-unseal.service` (oneshot, after `vault.service`) runs
`/usr/local/bin/vault-unseal.sh` (0700, root-only), which no-ops unless
sealed — then unseals from the init file. Same trust model as manual unseal
(keys stay on this disk); the unit only removes the human step. Verify any
time: `incus restart k3s-vault` → 60s → `Sealed false` with nobody typing.

## 3. Role-Integration Pattern (how cert-manager et al. read secrets)

1. `slurp /root/vault-init.json` from the vault host (`delegate_to`) → parse
   `root_token` + `unseal_keys_b64[0]` (`no_log: true` everywhere the value flows).
2. `GET /v1/sys/seal-status` → unseal via `PUT /v1/sys/unseal` if sealed.
3. Detect engine version first: `GET /v1/sys/mounts/<mount>` → `options.version`
   (ERROR 58 — v1 and v2 have different read paths AND response shapes).
4. Read: v2 → `/v1/<mount>/data/<name>`, value at `.data.data.<field>`;
   v1 → `/v1/<mount>/<name>`, value at `.data.<field>`.
5. Missing secret (404/empty) → `fail` with the exact seeding command, never a default.

## 4. Verification Commands

```bash
# API liveness + seal + mounts (needs root token for mounts/secrets)
export VAULT_ADDR='https://10.195.94.200:8200' VAULT_SKIP_VERIFY=true VAULT_TOKEN=$(ssh root@10.195.94.200 "jq -r .root_token /root/vault-init.json")
vault status | grep -E "Sealed|Initialized"
vault secrets list
vault kv get kv/cloudflare && vault kv get kv/sonarqube   # values masked = present
```

## 5. Seeding New Secrets (operator runbook)

```bash
vault login   # root token from /root/vault-init.json on the vault host
vault kv put kv/<name> <field>=<value>   # e.g. kv/argocd, kv/registry
```
Then reference `vault_<name>_path` + field in the consuming role following §3.
Rotate the same way (`kv put` overwrites → new version); re-run the consumer play.

## 6. Error Catalog (condensed)

| # | Symptom | Fix |
|---|---|---|
| C-2/C-3 | Vault installed but sealed, secrets unavailable | Auto-init (once, `creates` guard) + auto-unseal; keys in `/root/vault-init.json` |
| 26 | `mkdir /opt/vault/data: no such file` crash | `file:` task creates the data dir before service start |
| 56 | Consumer fails: secret missing | Seed once per §5; role fails fast with instructions |
| 57 | 503 sealed despite earlier "Unsealed" | `until: rc==0 or rc==2`; fresh re-check + conditional unseal right before privileged ops |
| 58 | 404 reading a secret that `kv get` shows | Branch on engine version (`options.version`); v1 vs v2 path + JSON shape |

## 7. First-Actions Runbook

1. `vault status` — sealed? unseal (§2). Not initialized? Something wiped storage — re-init (data lost; restore from backup).
2. 403 on reads — token wrong/expired? Re-login; root token never expires unless revoked.
3. 404 on reads — wrong path or wrong engine version (§3 step 3).
4. TLS errors from clients — cert regenerated? Clients pin nothing (skip-verify on LAN); check listener + port 8200.
