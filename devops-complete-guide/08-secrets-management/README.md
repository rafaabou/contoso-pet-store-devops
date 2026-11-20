# 08 — Secrets Management

> Never hardcode credentials again — centralize, rotate, and audit every secret with zero trust.

This category covers tools for managing secrets (API keys, database passwords, TLS certificates) across your infrastructure. You'll learn to centralize secrets in HashiCorp Vault with dynamic credential generation, inject them into pods with Vault Agent, encrypt secrets in git with Sealed Secrets and SOPS, and eliminate all plaintext secrets from your codebase.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Vault** | Centralized secrets engine — KV store, dynamic database credentials, PKI, encryption-as-a-service, audit logging | [vault.md](vault.md) |
| **Vault Agent** | Sidecar injector — automatically fetches secrets from Vault and renders them as files or environment variables in K8s pods | [vault-agent.md](vault-agent.md) |
| **Vault Dynamic Secrets** | Ephemeral credentials — Vault generates short-lived database passwords, cloud tokens, and SSH keys on demand | [vault-dynamic-secrets.md](vault-dynamic-secrets.md) |
| **Sealed Secrets** | Git-safe encryption — encrypt K8s Secrets so they can be safely committed to git, decrypted only by the controller in-cluster | [sealed-secrets.md](sealed-secrets.md) |
| **SOPS** | File-level encryption — encrypt YAML, JSON, ENV files with AWS KMS, GCP KMS, Azure Key Vault, or age keys | [sops.md](sops.md) |

## What You'll Learn

- Deploy and unseal Vault in HA mode on Kubernetes
- Configure Vault KV and dynamic database secret engines
- Inject secrets into pods via Vault Agent sidecar annotations
- Seal and unseal K8s Secrets for safe git storage with Sealed Secrets
- Encrypt config files with SOPS for git-crypt-style workflows
- Implement secret rotation and audit logging

## Prerequisites

- Running k3s cluster (from Category 01)
- Understanding of Kubernetes Secrets and ConfigMaps
- TLS certificates or cloud KMS keys (for encryption)

## Difficulty

**Intermediate to Advanced** — Vault has a steep learning curve; Sealed Secrets and SOPS are easier entry points.

## Learning Path

```
SOPS (quick file encryption) → Sealed Secrets (git-safe K8s secrets)
→ Vault KV (static secrets) → Vault Agent (pod injection)
→ Vault Dynamic Secrets (ephemeral credentials)
```
