# Forgejo CI — Setup & Troubleshooting (TASK-262)

> Living document. Every config/role/playbook/IP change lands here.
> Every new error gets an ERROR entry below.

## Current State (2026-09-10, CI live — runners registered + idle, server + domain 200)

| Item | Value |
|---|---|
| Server VM | `k3s-forgejo-ci` RUNNING, bridge `10.195.95.221`, Tailscale `100.88.159.38`, openssh installed |
| Runner VM | `k3s-runner-1` RUNNING, bridge `10.195.95.222`, Tailscale `100.113.54.77`, openssh installed |
| Next | architecture-first per operator 2026-09-10 (NO app deploy yet — code not in git, pilot PARKED by operator, pick any day); remaining order: generic correlation plumbing → hardening (SonarQube SSO trial + Vault OIDC DONE, plugin v1.0.3 released; `sysadmin` rotated, `kv/forgejo` v1 live, runners registered + idle ×2 UI-confirmed) |
| Then | Forgejo login → rotate admin → `kv/forgejo` → `forgejo_ext_ip` already Tailscale → networking re-run → runners register → pilot |

## Previous State (scaffolding, superseded)

| Item | Value |
|---|---|
| Server VM | `k3s-forgejo-ci`, PC2, 2 CPU / 4GB / 30GB, privileged, bridge `10.195.95.221` → Tailscale after boot |
| Runner VM | `k3s-runner-1`, PC2, 2 CPU / 3GB / 20GB, unprivileged, bridge `10.195.95.222` → Tailscale after boot |
| Forgejo | 16.0.3 binary, SQLite, systemd, `:3000` |
| Runners | host labels (`ci-light` on server VM cap 1, `ci-heavy` on runner VM cap 2), Buildah builds |
| URL | `https://forgejo.devops-devsecops.kdns.fr` (Gateway ServiceEntry/VS, zero DNS work) |
| Secrets | admin user `sysadmin`, pw `/root/.forgejo-admin` → rotate → `kv/forgejo`; runner tokens server-minted (`/root/.forgejo-runner-token-<label>` on server, fetched machine-to-machine, `no_log`) — UI copy path retired (ERROR 97) |
| Measured headroom | PC2 11Gi / ~8.6Gi avail; PC1 14Gi / ~3.6Gi avail, 1.1GB swap in use (watch item) |

## Install Flow

1. Vault trim 750MB (PC1, live apply) → verify seal status.
2. `tofu apply` PC2 (2 new instances) → SSH keys → Tailscale inside → record 100.x IPs in inventory.
3. `site-forgejo.yml`: server → runners (token from UI) → login → rotate admin → `kv/forgejo`.
4. `forgejo_ext_ip` already `100.88.159.38` (done) → re-run `site-networking.yml` after install → verify 200.
5. Pilot: mirror 1 service, `.forgejo/` workflow (lint→test→Trivy→Buildah→push→manifest→ArgoCD), green run.

## Verify Commands

```bash
curl -sk -o /dev/null -w "%{http_code}\n" https://forgejo.devops-devsecops.kdns.fr/
incus exec k3s-forgejo-ci -- systemctl status forgejo.service
incus exec k3s-runner-1 -- systemctl status forgejo-runner.service
buildah --version   # on runner hosts
```

## User Lifecycle (admin-only — self-registration disabled by design)

- **Create:** `sysadmin` → Site Administration → User accounts → Create User
  Account (lowercase immutable username, real email, temporary password,
  require-change ON).
- **Hand over** by voice/secure channel only (URL + username + temp password)
  — never chat, logs, or files. Forced change at first login expires the
  temp value by construction.
- **Joiner/leaver:** disable/delete in the same panel on departure; audit
  quarterly. This account doubles as the SSO identity for Grafana/ArgoCD/
  SonarQube/MinIO/Vault — one disable removes all five doors.

## Decisions (locked, with reasons)

- **SQLite over Postgres:** zero setup, docs-ok at our scale; migration path kept, not built.
- **Host labels over Podman:** nothing lighter exists; single trusted user + disposable IaC VMs contain the risk; Podman stays a 15-min upgrade path.
- **Buildah over nerdctl/Docker:** zero daemons, Dockerfiles unchanged; nerdctl-minimal reserved for k3s-node debugging.
- **Both VMs on PC2:** PC1 at 3.6Gi avail + 1.1GB swap in use + apps incoming; no new PC1 containers.
- **No runner in Vault VM:** root token material lives there — secrets plane never shares a host with compute.

## Error Catalog

*(empty — first ERROR goes here when met)*
