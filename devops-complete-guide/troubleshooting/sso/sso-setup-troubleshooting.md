# SSO (Forgejo as IdP) — Setup & Troubleshooting

> Living document. Every client/config change lands here.
> Decision (locked): Forgejo is the Identity Provider (zero new services);
> Authelia stays fallback. No Keycloak/Authentik (heavier than some apps).

## Current State (2026-09-10)

| Item | Value |
|---|---|
| IdP | Forgejo `https://forgejo.<domain>` (issuer URL — never IP, OIDC discovery breaks otherwise) |
| Clients | 5 OAuth apps: grafana, argocd, sonarqube, minio, vault |
| Secrets | Vault `kv/sso/<name>` (`client_id`, `client_secret`) — never chat/files |
| Break-glass | Local logins stay ON everywhere (admin/sysadmin/token); quarterly drill: IdP down → local entry per app |
| Phase | Grafana first (wired, pending apply) → ArgoCD → SonarQube+MinIO → Vault OIDC last |

## Flow (per app, same every time)

1. Client exists in Forgejo + pair in `kv/sso/<name>` (Phase 1 pattern).
2. Role fetches pair at deploy (delegate_to-vault, `no_log`) → renders provider block.
3. Apply → logout → provider button appears → login test → local login re-test.
4. Rollback = one config flag off (documented per app below).

## App Status

| App | Status | Rollback flag |
|---|---|---|
| Grafana | ✅ PROVEN (SSO lands as Viewer + local admin verified) | `enabled = false` |
| ArgoCD | ✅ PROVEN (SSO login succeeded end to end per dex+server logs; empty-URL root cause fixed by ERROR 107) | remove `dex.config` key from argocd-cm + restart dex |
| SonarQube | ✅ PROVEN (operator-verified end-to-end login + local admin; ghost/timing/callback/URL saga in ERRORs 96–113 closed) | remove JAR + restart |
| MinIO | ✅ PROVEN (root rotated, SSO lands with consoleAdmin via per-user policies named by username) | remove OIDC Environment lines + restart |
| Vault | ✅ PROVEN (operator signed in via OIDC Role `default`, approve → in); blank Role field → "Invalid role" (UI sends empty string this version doesn't resolve — type `default` explicitly) | `vault auth disable oidc` |

## Verify Commands

```bash
# Login button present + working per app (browser); local admin still works (break-glass proof)
# Vault copy check (metadata only, never values):
vault kv list kv/sso/   # expect 5 names
```

## Error Catalog

| # | Symptom | Cause | Fix |
|---|---|---|---|
| S-1 | `redirect_uri_mismatch` at login | URI in Forgejo client ≠ app callback (one char off kills it) | Copy exact URIs from this guide (table in Phase 1 plan); never type them |
| S-2 | `invalid_client` | Wrong pair in Vault (UUID pasted as secret, stale client, typo) | Delete + recreate client, rewrite pair, re-apply; test immediately (tokens die with entries) |
| S-3 | Login loops back unauthenticated | `root_url`/callback base wrong (e.g. apex domain, http scheme) | Provider block must carry the public HTTPS name (Grafana `root_url`!) |
| S-4 | IdP down = nobody logs in | Expected (federation dependency) | Break-glass local accounts (drilled quarterly); Vault token path never federated away |
| S-5 | Provider button 401s / "not authorized" with `issuerUri is not configured` in web.log | Section viewed but never filled+Saved (empty fields = unconfigured provider; init throws before any IdP contact) | Fill all 5 fields + Save (unsaved settings silently do nothing); stack trace names the exact missing key — read it, don't guess |
