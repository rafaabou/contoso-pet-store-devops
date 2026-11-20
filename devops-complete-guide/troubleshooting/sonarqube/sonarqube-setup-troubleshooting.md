# SonarQube Setup Troubleshooting

> SonarQube home: install flow, version matrix, verification, Gateway exposure,
> migration record. Master log: `../ansible/ansible-setup-troubleshooting.md`
> (this file condenses the SonarQube-relevant ERRORs 67–72, 75 + migration 73–76).
> *Last Updated: 2026-09-10 — SonarQube live on PC2 (100.73.135.124:9000, also via Gateway `sonar.*`), matched pair 26.5.0.122743 + plugin 26.5.0. SSO: custom Forgejo plugin ACCEPTED + configured (ghost/timing/callback/URL lessons in ERRORs 96–112); provider landing + local admin both operator-confirmed — SSO closed.*

## 1. Current State (2026-09-09)

| Item | Value |
|---|---|
| Location | PC2 container `k3s-sonarqube` (migrated from PC1, ERROR 73) |
| Reachability | Tailscale `100.73.135.124:9000` (HTTP); `https://sonar.devops-devsecops.kdns.fr` via Istio Gateway (ERROR 76) |
| SonarQube | 26.5.0.122743 + Community Branch Plugin 26.5.0 (LOADED, verified in web.log) |
| Database | PostgreSQL 16, local to container (virgin at migration; old PC1 DB dropped) |
| Container | privileged, 2 CPU, 2560MB RAM (ERROR 67, 72) |
| Secrets | DB password `/root/sonarqube-db-password` (container); admin password in Vault `kv/sonarqube` |

## 2. Version Matrix (hard rule)

SonarQube and the Community Branch Plugin release **independently** — the plugin
lags SQ by months. Never derive one version from the other (ERROR 68).

| SonarQube | Plugin | Status |
|---|---|---|
| 26.5.0.122743 | 26.5.0 | ✅ VERIFIED LOADED (this cluster) |
| 26.9.0.129388 | 26.5.0 | ❌ no plugin lines in logs (rejected or ignored) |

Pins live in `ansible-opentofu/ansible/inventory/group_vars/all.yml`:
`sonarqube_version`, `sonarqube_plugin_version`. Verify candidates against
`https://api.github.com/repos/mc1arke/sonarqube-community-branch-plugin/releases`
(BOTH jar + webapp assets must exist under the tag) before pinning.

## 3. Install Flow (`playbooks/site-sonarqube.yml` + `roles/postgres-local/`)

1. PostgreSQL on container disk (`/srv/rds-data` path; plain dir on PC2, was an
   Incus device on PC1). DB password generated once → `/root/sonarqube-db-password`.
2. SonarQube zip → extract → install → `sonar.properties` (DB creds) →
   sysctl `vm.max_map_count` + file limits → plugin JAR + webapp →
   `chmod 755` scripts (ERROR 69) → systemd service → wait HTTP 200 →
   grep web.log for plugin evidence.
3. Idempotency gates check the **destination** (ERROR 75): extract/install run
   when download changed **or** `sonar.sh` missing; plugin copy/extract also
   re-fire on SonarQube reinstall.

## 4. Verification Commands

```bash
# Service + HTTP (inside container via incus, or ansible host via Tailscale IP)
incus exec k3s-sonarqube -- systemctl is-active sonarqube postgresql
curl -s -o /dev/null -w "HTTP:%{http_code}\n" http://100.73.135.124:9000
curl -s -u admin:<pass> http://100.73.135.124:9000/api/system/status  # {"status":"UP",...}

# Plugin loaded? (log says "Community Branch Plugin" with SPACES — hyphen
# grep matches nothing; playbook pattern already fixed)
incus exec k3s-sonarqube -- grep -h "Deploy Community Branch Plugin" /opt/sonarqube/logs/web.log

# Memory health (floor 2.5GB; thrashing = timeouts despite green playbook)
incus exec k3s-sonarqube -- free -m | head -2

# Via Gateway (TLS + SNI; SNI-less IP curl 000 is normal Envoy behavior)
curl -sk -o /dev/null -w "%{http_code}\n" --resolve sonar.devops-devsecops.kdns.fr:443:10.195.94.100 https://sonar.devops-devsecops.kdns.fr/
```

## 5. Gateway Exposure

`sonar.*` → gateway `.100` (NOT the backend Tailscale IP — TLS terminates only
at the Gateway, ERROR 76). Objects in `roles/istio/templates/gateway.yml.j2`:
`ServiceEntry sonarqube-ext` (endpoint = Tailscale IP, must be routable from
the gateway pod) + `VirtualService sonarqube` on `main-gateway` (wildcard cert).
No new DNS beyond pointing the name at `.100` (wildcard covers it).

## 6. Migration Record (PC1 → PC2, 2026-09-09)

Blue-green per ERROR 73: new PC2 container (privileged, 2560MB, Tailscale,
fresh virgin DB) → `site-sonarqube.yml` → HTTP 200 + plugin verified →
`sonar.*` DNS moved → PC1 `k3s-sonarqube` destroyed via tofu → host
`/srv/rds-data` orphan cleaned. PC1 files pruned (`main.tf` resource + vars +
outputs). DB migration was unnecessary (virgin); a stateful move would need
`pg_dump`/restore instead.

## 7. Error Catalog (condensed; full text in master guide)

| # | Symptom | Fix |
|---|---|---|
| 67 | `chown EPERM` on disk device / sysctl fails | `security.privileged=true` + `incus restart` (tofu apply alone doesn't restart); verify `uid_map` = `0 0 4294967295` |
| 68 | Plugin JAR 404 (`26.9.0` tag) | Pin `sonarqube_plugin_version` explicitly; verify tag on GitHub releases API first |
| 69 | service `203/EXEC`, empty logs | `chmod 755` starter scripts (playbook task permanent); 203 = check exec bit before app logs |
| 70 | Downgrade refuses DB; plugin files vanish on version switch | DROP+CREATE virgin DB; plugin gates also on `sq_download.changed` |
| 71 | Switch kept old code (download `ok`, skipped install) | Purge stale `/tmp` artifacts; verify on-disk versions (`unzip -l`, lib jars), not task colors |
| 72 | HTTP timeouts, 1885/1907MB used, 8s GC pauses | 2.5GB floor (`sonarqube_memory: 2560MB`); restart to apply limits; prove with fast HTTP 200 |
| 75 | `sonar.properties missing` on fresh box | Gates must stat destination (`sonar.sh`) OR'd with download-changed |
| 76 | Browser "Unable to connect" on `sonar.*:443` | Name must hit Gateway `.100` + ServiceEntry/VS must exist; check Authoritative DNS (`1.1.1.1`) vs stale local cache; `--resolve` splits DNS vs route faults |
| S-a | SSO: `issuer does not match` in web.log | Trailing `/` on Issuer URI setting (Nimbus byte-compares vs discovery doc) | Strip trailing slash; verify with fresh login attempt |
| S-b | SSO: startup abort ~60s in, wrapper cleanup mimics human stops | Duplicate plugin JARs, same key (1.0.0 + 1.0.1 + …) — server aborts on multiples | Exactly ONE version per plugin key; bump `<version>` every redeploy; confirm via Deploy line |
| S-c | SSO: callback goes to IdP host, not SonarQube | `sonar.core.serverBaseURL` holds the wrong host (cross-wired during fill) | Set base URL to the SONAR host, no trailing slash, Save + reload-proof |
| S-d | SSO: `Connection timed out` in init (browser reaches IdP fine) | Server-to-IdP calls cross the stretched-cluster blackhole (PC2→PC1 LAN unroutable without subnet routes) | Tailnet subnet route advertised + approved + accepted; prove with `curl` discovery URL FROM the SonarQube box first |

## 8. First-Actions Runbook (new symptom?)

1. `systemctl is-active sonarqube postgresql` — which layer is down?
2. `tail web.log / es.log` — startup vs runtime? (203/EXEC ⇒ §7-69, no app logs.)
3. `curl localhost:9000` from inside — local OK but remote fails ⇒ network/DNS/Gateway (see §5 + ERROR 76).
4. `free -m` — >90% used + slow HTTP ⇒ memory floor (§7-72).
5. Plugin missing features ⇒ `grep "Deploy Community Branch Plugin" web.log` (§4); version table (§2).
