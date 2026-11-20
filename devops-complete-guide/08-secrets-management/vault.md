# HashiCorp Vault Complete Guide

## Table of Contents

1. [What Is Vault](#what-is-vault)
2. [Why Use Vault — Real Breaches](#why-use-vault--real-breaches)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Secret Engines](#secret-engines)
7. [Authentication Methods](#authentication-methods)
8. [Policies](#policies)
9. [Usage Guide — Step by Step](#usage-guide--step-by-step)
10. [High Availability](#high-availability)
11. [Encryption as a Service](#encryption-as-a-service)
12. [Secrets Leasing & Renewal](#secrets-leasing--renewal)
13. [Audit Backend](#audit-backend)
14. [Seal/Unseal Operations](#sealunseal-operations)
15. [Vault on Kubernetes](#vault-on-kubernetes)
16. [Integration with DevOps Tools](#integration-with-devops-tools)
17. [Security Hardening](#security-hardening)
18. [Troubleshooting (20+ Issues)](#troubleshooting-20-issues)
19. [Tips & Best Practices (20+ Tips)](#tips--best-practices-20-tips)
20. [Command Reference](#command-reference)
21. [Configuration Reference](#configuration-reference)
22. [Real-World Examples — Our Cluster](#real-world-examples--our-cluster)
23. [Further Reading](#further-reading)

---

## What Is Vault

HashiCorp Vault is a tool for securely accessing secrets. It provides a unified interface to any secret, with tight access control, detailed audit logging, and dynamic secret generation. Vault is identity-aware and provides fine-grained access control for secrets, encryption-as-a-service, and identity-based credentials.

### Core Value Proposition

Vault solves the fundamental problem of secrets management: how do you distribute, rotate, and audit access to sensitive credentials across heterogeneous infrastructure? Instead of hardcoding passwords in config files, storing API keys in environment variables, or sharing certificates via email, Vault provides a single source of truth with:

- **Centralized secret storage** — One place for all secrets across all environments
- **Dynamic secrets** — Generate credentials on-demand with automatic expiration
- **Encryption as a Service** — Encrypt/decrypt data without managing keys
- **Identity-based access** — Authenticate via multiple methods, authorize with fine-grained policies
- **Full audit trail** — Every secret access is logged with caller identity
- **Secure storage** — Secrets encrypted at rest with configurable backends (Consul, Raft, PostgreSQL, etc.)

### What Vault Is NOT

- Vault is not a password manager for end users
- Vault is not a substitute for proper key management (though it can do KMS)
- Vault is not a replacement for TLS/certificate management (though it has PKI)
- Vault is not a zero-trust network solution (though it integrates with them)

### Key Features at a Glance

| Feature | Description |
|---------|-------------|
| **Secret Engines** | KV, Database, PKI, AWS, Azure, GCP, Transit, SSH, and more |
| **Auth Methods** | AppRole, Kubernetes, LDAP, OIDC/JWT, Userpass, TLS Certs, GitHub |
| **Storage Backends** | Integrated Raft, Consul, PostgreSQL, MySQL, file |
| **Audit Devices** | File, Syslog, Socket |
| **HA** | Active-standby with Raft or Consul, auto-failover |
| **Namespaces** | Enterprise multi-tenancy |
| **Sentinel** | Policy as code (Enterprise) |

---

## Why Use Vault — Real Breaches

### The Problem Secrets Management Solves

Secrets scattered across infrastructure create massive attack surfaces. When a single compromised credential can lead to full environment compromise, you need centralized control.

### Real-World Breaches Caused by Poor Secrets Management

#### 1. Uber (2016)
- **What happened**: Attackers found AWS access keys hardcoded in a GitHub repository belonging to an Uber engineer
- **Impact**: 57 million user records stolen (names, emails, phone numbers), $148M settlement
- **Vault would have helped**: Dynamic AWS credentials with automatic rotation and short TTLs would have limited exposure window. Audit logging would have detected unauthorized access.

#### 2. Samsung (2019)
- **What happened**: Source code and credentials stored in publicly accessible GitLab repositories
- **Impact**: 6 TB of internal data exposed, including Samsung's Bixby source code
- **Vault would have helped**: Centralized secret storage prevents engineers from embedding credentials in code repos. Policy enforcement prevents secrets from being committed.

#### 3. Capital One (2019)
- **What happened**: Misconfigured WAF role allowed SSRF to access EC2 metadata credentials
- **Impact**: 100 million customer records exposed, $190M settlement
- **Vault would have helped**: Dynamic AWS credentials with strict IAM policies and short TTLs. No long-lived IAM keys to steal from instance metadata.

#### 4. Microsoft (2021)
- **What happened**: Azure misconfiguration allowed access to storage accounts containing 2.4 TB of customer data
- **Impact**: 65,000+ customer records exposed
- **Vault would have helped**: Centralized Azure credential management with automatic rotation and access logging.

#### 5. CircleCI (2023)
- **What happened**: Stolen OAuth tokens from a CircleCI engineer's laptop led to supply chain attack affecting customers
- **Impact**: Hundreds of downstream organizations compromised, including 1Password, Twilio, and Sphere
- **Vault would have helped**: Centralized token management with rotation policies, audit trails for all token usage, and automatic revocation.

#### 6. Twitch (2021)
- **What happened**: Server misconfiguration exposed source code and "internal tools" including hardcoded credentials
- **Impact**: 123 GB of data including creator payout information leaked
- **Vault would have helped**: Secrets not stored alongside code, centralized access control.

#### 7. Codecov (2021)
- **What happened**: Attackers modified Codecov's Docker image to exfiltrate CI/CD environment variables
- **Impact**: Thousands of customers' secrets (tokens, keys, credentials) stolen
- **Vault would have helped**: Secrets injected at runtime from Vault rather than stored as environment variables. Short-lived tokens that expire automatically.

#### 8. Colonial Pipeline (2021)
- **What happened**: Compromised VPN credentials (likely reused from a data breach) led to ransomware
- **Impact**: $4.4M ransom, fuel shortages across US East Coast
- **Vault would have helped**: Centralized credential management, MFA enforcement, automatic credential rotation, audit logging of VPN access.

### The Business Case

| Metric | Without Vault | With Vault |
|--------|--------------|------------|
| Secret sprawl | 100s of locations | 1 central store |
| Rotation cycle | Manual, months | Automatic, hours/days |
| Audit visibility | None | Complete trail |
| Blast radius | Full environment | Limited by TTL/policy |
| Compliance effort | Months of remediation | Continuous compliance |
| Incident response | Days to identify exposure | Minutes to revoke |

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Clients                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ App A    │  │ App B    │  │ CI/CD    │  │ Human   │ │
│  │(AppRole) │  │(K8s Auth)│  │(JWT/OIDC)│  │(LDAP)   │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │              │              │              │      │
└───────┼──────────────┼──────────────┼──────────────┼──────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────┐
│                   Vault Server                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Authentication Layer                │   │
│  │  AppRole │ K8s │ LDAP │ OIDC │ Userpass │ TLS  │   │
│  └────────────────────┬────────────────────────────┘   │
│                       │                                 │
│  ┌────────────────────▼────────────────────────────┐   │
│  │              Authorization (Policies)           │   │
│  │          HCL-based fine-grained access           │   │
│  └────────────────────┬────────────────────────────┘   │
│                       │                                 │
│  ┌────────────────────▼────────────────────────────┐   │
│  │              Secret Engines                      │   │
│  │  KV │ Database │ PKI │ Transit │ AWS │ SSH │ ...│   │
│  └────────────────────┬────────────────────────────┘   │
│                       │                                 │
│  ┌────────────────────▼────────────────────────────┐   │
│  │              Audit Backend                       │   │
│  │          File │ Syslog │ Socket                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Storage Backend                             │
│         Integrated Raft │ Consul │ PostgreSQL            │
└─────────────────────────────────────────────────────────┘
```

### Request Flow

1. **Client authenticates** via configured auth method (e.g., AppRole, Kubernetes)
2. **Vault validates credentials** and returns a client token
3. **Client makes request** with token (e.g., `vault read secret/data/myapp`)
4. **Vault checks policy** attached to token's identity
5. **Vault queries secret engine** for the requested secret
6. **Secret returned** to client (and logged in audit log)
7. **Token expires** or is revoked, requiring re-authentication

### Component Interaction

```
Client → Vault API (HTTPS :8200) → Auth Method → Policy Engine → Secret Engine → Storage Backend
                                    ↓
                              Audit Device (every API call logged)
```

---

## Installation

### Method 1: Binary Download (Recommended for Production)

```bash
# Detect architecture
ARCH=$(uname -m)
case $ARCH in
  x86_64) VAULT_ARCH="amd64" ;;
  aarch64) VAULT_ARCH="arm64" ;;
  armv7l) VAULT_ARCH="arm" ;;
  *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

# Download latest stable version
VAULT_VERSION="1.15.4"
wget -qO /tmp/vault.zip \
  "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip"

# Verify checksum
wget -qO /tmp/vault_SHA256SUMS \
  "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS"
grep "vault_${VAULT_VERSION}_linux_${VAULT_ARCH}.zip" /tmp/vault_SHA256SUMS | \
  sha256sum -c -

# Install
unzip -o /tmp/vault.zip -d /usr/local/bin/
vault --version
```

### Method 2: Package Manager

```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault

# RHEL/CentOS
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install vault
```

### Method 3: Docker

```bash
# Pull image
docker pull hashicorp/vault:1.15.4

# Run in dev mode
docker run -d --name vault-dev -p 8200:8200 \
  -e VAULT_DEV_ROOT_TOKEN_ID=myroot \
  hashicorp/vault:1.15.4 server -dev

# Run in production mode
docker run -d --name vault \
  -p 8200:8200 \
  -v /opt/vault/config:/vault/config \
  -v /opt/vault/data:/vault/data \
  -v /opt/vault/logs:/vault/logs \
  -e VAULT_API_ADDR=https://vault.example.com:8200 \
  --cap-add IPC_LOCK \
  hashicorp/vault:1.15.4 server -config=/vault/config/vault.hcl
```

### Method 4: Kubernetes (Helm)

```bash
# Add HashiCorp Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set server.ha.raft.replicas=3

# Initialize and unseal
kubectl -n vault exec -it vault-0 -- vault operator init
kubectl -n vault exec -it vault-0 -- vault operator unseal <key1>
kubectl -n vault exec -it vault-1 -- vault operator unseal <key2>
kubectl -n vault exec -it vault-2 -- vault operator unseal <key3>
```

### Method 5: Linux Service (systemd)

```bash
# Create vault user
sudo useradd --system --home /etc/vault --shell /bin/false vault

# Create directories
sudo mkdir -p /etc/vault /opt/vault/data /var/log/vault
sudo chown -R vault:vault /etc/vault /opt/vault /var/log/vault

# Create systemd service
sudo tee /etc/systemd/system/vault.service << 'EOF'
[Unit]
Description=Vault Secret Management Tool
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.hcl

[Service]
User=vault
Group=vault
Type=simple
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
CapabilityBoundingSet=CAP_IPC_LOCK
AmbientCapabilities=CAP_IPC_LOCK
NoNewPrivileges=yes
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=+no_new_privs

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault
```

---

## Core Concepts

### Vault Tokens

Tokens are the core authentication mechanism. Every Vault interaction requires a valid token.

**Token Properties:**
- **Accessor**: Used for token management (lookup, renew, revoke) without knowing the token itself
- **Policies**: List of policies attached to the token (determines what the token can access)
- **TTL**: Time-to-live; token expires after this duration unless renewed
- **Max TTL**: Maximum lifetime regardless of renewals
- **Orphan**: If true, token is not revoked when parent token is revoked
- **Period**: If set, token can be renewed indefinitely as long as renewed within this period

**Token Hierarchy:**
```
Root Token (exists temporarily)
    └── Master Token (created from root)
        ├── Service Token A (for App A)
        ├── Service Token B (for App B)
        └── Batch Token C (for CI/CD)
```

### Policies

Policies are HCL documents that define what paths a token can access. They are additive — a token with multiple policies gets the union of all permissions.

**Policy Structure:**
```hcl
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "secret/data/myapp/config" {
  capabilities = ["read"]
  # Deny delete
}

path "sys/policies/*" {
  capabilities = ["create", "read", "update", "list"]
}
```

**Capabilities:**
- `create` — Create a new entry
- `read` — Read an existing entry
- `update` — Modify an existing entry
- `delete` — Delete an entry
- `list` — List entries (does not reveal values)
- `sudo` — Required for privileged operations
- `deny` — Explicitly deny access (overrides other capabilities)

### Secret Engines

Secret engines are plugins that manage secrets. Each engine has its own lifecycle and API.

**KV Engine (Key-Value):**
```bash
# Enable KV v2
vault secrets enable -path=secret kv-v2

# Write a secret
vault kv put secret/myapp/config username=admin password=s3cret

# Read a secret
vault kv get secret/myapp/config

# Read specific field
vault kv get -field=password secret/myapp/config
```

**Database Engine:**
```bash
# Enable database engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@db.example.com:5432/myapp" \
  allowed_roles="readonly" \
  username="vault_admin" \
  password="admin_password"

# Create a role
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h"

# Get dynamic credentials
vault read database/creds/readonly
# Returns: username=v-appuser-abc123 password=xYz789 TTL=3600
```

### Leases

Every secret returned by Vault has an associated lease. The lease defines:
- **TTL**: How long the secret is valid
- **Max TTL**: Maximum lifetime (even with renewal)
- **Renewable**: Whether the lease can be extended
- **Request ID**: Unique identifier for this lease

```
Secret Request → Vault generates secret → Returns secret + lease
                                              │
                                    Lease ID: abc123
                                    TTL: 3600s
                                    Renewable: true
                                              │
                                    ┌─────────┴─────────┐
                                    │                   │
                              Before TTL          After TTL
                              (renewable)         (expired)
                                    │                   │
                              Extend TTL          Secret revoked
                              (if renewable)      (automatic cleanup)
```

### Namespaces (Enterprise)

Namespaces create isolated Vault environments within a single Vault cluster. Each namespace has its own:
- Auth methods
- Secret engines
- Policies
- Tokens

```
Root Namespace
├── Team-A Namespace
│   ├── auth/ldap/team-a
│   ├── secret/team-a/
│   └── policy/team-a-*
├── Team-B Namespace
│   ├── auth/k8s/team-b
│   ├── secret/team-b/
│   └── policy/team-b-*
└── Platform Namespace
    ├── auth/approle/platform
    ├── pki/
    └── policy/platform-*
```

---

## Secret Engines

### KV v2 (Key-Value Version 2)

The most commonly used engine. Stores arbitrary key-value secrets with versioning.

```bash
# Enable
vault secrets enable -path=secret kv-v2

# Write
vault kv put secret/myapp/config \
  db_password="s3cret" \
  api_key="ak_12345"

# Read (returns version info)
vault kv get secret/myapp/config
# === Data ===
# Key    Value
# ---    -----
# api_key    ak_12345
# db_password    s3cret
#
# --- Metadata ---
# Created Time    2024-01-15T10:30:00Z
# Deletion Time    n/a
# Destroyed    false
# Version    1

# Read specific field
vault kv get -field=db_password secret/myapp/config

# Read previous version
vault kv get -version=1 secret/myapp/config

# Delete (soft delete)
vault kv delete secret/myapp/config

# Destroy (hard delete, unrecoverable)
vault kv destroy -version=1 secret/myapp/config

# List secrets
vault kv list secret/myapp/

# Get metadata
vault kv metadata get secret/myapp/config

# Undelete
vault kv undelete -versions=1 secret/myapp/config

# Rollback
vault kv rollback -version=1 secret/myapp/config
```

### Database Secrets Engine

Generates dynamic database credentials with automatic expiration.

```bash
# Enable
vault secrets enable database

# PostgreSQL
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  allowed_roles="readonly,readwrite" \
  username="vault" \
  password="initial_password"

# MySQL
vault write database/config/mysql \
  plugin_name=mysql-database-plugin \
  connection_url="{{username}}:{{password}}@tcp(db.example.com:3306)/mydb" \
  allowed_roles="readonly" \
  username="vault" \
  password="initial_password"

# MongoDB
vault write database/config/mongodb \
  plugin_name=mongodb-database-plugin \
  connection_url="mongodb://{{username}}:{{password}}@db.example.com:27017/mydb" \
  allowed_roles="readonly" \
  username="vault" \
  password="initial_password"

# Create roles
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  "

# Get credentials
vault read database/creds/readonly
# username=v-appuser-xyz789 password=aBc123xyz TTL=3600

# Revoke specific lease
vault lease revoke database/creds/readonly/<lease-id>
```

### PKI Secrets Engine

Creates a full Certificate Authority and issues certificates.

```bash
# Enable
vault secrets enable pki

# Tune max lease TTL (CA must be longer)
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write pki/root/generate/internal \
  common_name="Example CA" \
  ttl=87600h

# Configure URLs
vault write pki/config/urls \
  issuing_certificates="https://vault.example.com/v1/pki/ca" \
  crl_distribution_points="https://vault.example.com/v1/pki/crl"

# Create role for internal servers
vault write pki/roles/internal-server \
  allowed_domains="example.com,internal.example.com" \
  allow_subdomains=true \
  max_ttl=720h \
  key_bits=2048 \
  key_usage="DigitalSignature,KeyEncipherment" \
  ext_key_usage="ServerAuth"

# Issue certificate
vault write pki/issue/internal-server \
  common_name="web.internal.example.com" \
  ttl=72h

# Response includes:
# - certificate (PEM)
# - issuing_ca
# - private_key (PEM)
# - serial_number
```

### Transit Secrets Engine

Encryption as a Service — encrypt/decrypt data without managing keys.

```bash
# Enable
vault secrets enable transit

# Create encryption key
vault write transit/keys/myapp type=aes256-gcm96

# Encrypt data (base64 encoded)
vault write transit/encrypt/myapp \
  plaintext=$(echo -n "sensitive data" | base64)
# ciphertext="vault:v1:abc123..."

# Decrypt data
vault write transit/decrypt/myapp \
  ciphertext="vault:v1:abc123..."
# plaintext (base64) → "sensitive data"

# Rotate key (old versions still decrypt)
vault write -f transit/keys/myapp/rotate

# Check key versions
vault read transit/keys/myapp
# keys: 1=1705312200, 2=1705398600 (version 2 is current)

# Decrypt with specific version
vault write transit/decrypt/myapp \
  ciphertext="vault:v1:abc123..."
```

### AWS Secrets Engine

Generates dynamic AWS IAM credentials.

```bash
# Enable
vault secrets enable aws

# Configure root credentials
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-east-1

# Create role
vault write aws/roles/myapp \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": ["arn:aws:s3:::myapp-bucket/*"]
    }
  ]
}
EOF

# Get credentials
vault read aws/creds/myapp
# access_key=AKIA...  secret_key=...  ttl=3600
```

### SSH Secrets Engine

Provides secure SSH access to hosts via Vault.

```bash
# Enable
vault secrets enable -path=ssh ssh

# Create OTP role
vault write ssh/roles/otp-role \
  key_type=otp \
  default_user=ubuntu \
  allowed_users="ubuntu,admin" \
  ttl=300

# Generate OTP credential
vault write ssh/creds/otp-role \
  ip=10.0.0.5
# otp: abc123def456...

# User runs: vault-ssh-helper -mode=otp -ip=10.0.0.5 -user=ubuntu
```

---

## Authentication Methods

### AppRole

Designed for machines/workloads. Provides role_id + secret_id pairs.

```bash
# Enable
vault auth enable approle

# Create role
vault write auth/approle/role/myapp \
  token_policies="myapp-policy" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=10m \
  secret_id_num_uses=40

# Get role_id
vault read auth/approle/role/myapp/role_id
# role_id=abc123...

# Generate secret_id
vault write -f auth/approle/role/myapp/secret-id
# secret_id=xyz789...

# Login
vault write auth/approle/login \
  role_id=abc123 \
  secret_id=xyz789
# token=s.xxxx...
```

### Kubernetes

For workloads running in Kubernetes.

```bash
# Enable
vault auth enable kubernetes

# Configure (from inside cluster)
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  tokenReviewerJwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=production \
  policies=myapp-policy \
  ttl=1h

# From pod (uses service account token)
vault write auth/kubernetes/login \
  role=myapp \
  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

### OIDC/JWT

For web applications and API access.

```bash
# Enable
vault auth enable oidc

# Configure with your identity provider
vault write auth/oidc/config \
  oidc_discovery_url="https://accounts.google.com" \
  oidc_client_id="my-client-id" \
  oidc_client_secret="my-client-secret" \
  default_role="oidc-default"

# Create role
vault write auth/oidc/role/oidc-default \
  bound_audiences="my-client-id" \
  allowed_redirect_uris="https://vault.example.com/ui/vault/auth/oidc/oidc/callback" \
  user_claim="sub" \
  policies="default"
```

### LDAP

For enterprise environments with Active Directory.

```bash
# Enable
vault auth enable ldap

# Configure
vault write auth/ldap/config \
  url="ldaps://ldap.example.com" \
  userdn="ou=Users,dc=example,dc=com" \
  groupdn="ou=Groups,dc=example,dc=com" \
  userattr="uid" \
  groupattr="memberOf" \
  upn="user@example.com" \
  certificate=@ca.crt

# Create group policy mapping
vault write auth/ldap/groups/vault-admins \
  policies="admin-policy"

# Login
vault login -method=ldap username=admin password=ldap_password
```

### TLS Certificate

For machine-to-machine authentication.

```bash
# Enable
vault auth enable cert

# Create trusted certificate
vault write auth/cert/certs/webapp \
  display_name="Web Application" \
  policies="webapp-policy" \
  certificate=@webapp.crt

# Login (client uses mTLS)
vault login -method=cert \
  -ca-cert=ca.crt \
  -client-cert=client.crt \
  -client-key=client.key
```

### Userpass

Simple username/password authentication (dev/test only).

```bash
# Enable
vault auth enable userpass

# Create user
vault write auth/userpass/users/admin \
  password=changeme \
  policies="admin-policy" \
  token_ttl=1h

# Login
vault login -method=userpass username=admin password=changeme
```

---

## Policies

### Policy Basics

Policies are HCL (HashiCorp Configuration Language) documents that control access to Vault paths.

```hcl
# Read-only access to a specific path
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}

# Full access to a path
path "secret/data/myapp/config" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Deny access
path "secret/data/admin/*" {
  capabilities = ["deny"]
}

# Required for sudo operations
path "sys/auth/*" {
  capabilities = ["sudo", "create", "read", "update", "delete", "list"]
}
```

### Advanced Policy Features

```hcl
# Parameter constraints
path "secret/data/{{identity.entity.aliases.auth_oidc_*.metadata.role}}/*" {
  capabilities = ["read", "list"]
}

# Request data constraints
path "secret/data/myapp/config" {
  capabilities = ["create", "read", "update"]
  # Only allow if request body contains specific field
  required_parameters = ["db_password"]
  allowed_parameters = {
    "db_password" = ["*"]
    "api_key" = ["*"]
  }
  denied_parameters = {
    "admin_password" = []
  }
}

# Minimum data version
path "secret/data/myapp/config" {
  capabilities = ["read"]
  min_wrapping_ttl = "1h"
  max_wrapping_ttl = "24h"
}

# Glob patterns
path "secret/data/{{identity.entity.aliases.auth_*.metadata.team}}/*" {
  capabilities = ["read", "list"]
}

# Wrapping support
path "sys/wrapping/wrap" {
  capabilities = ["create", "update"]
}

# Lease management
path "sys/leases/revoke" {
  capabilities = ["create", "update"]
}

# Identity entities
path "identity/entity/id/*" {
  capabilities = ["read"]
}
```

### Policy Templates

```hcl
# Template: per-tenant access
path "secret/data/{{identity.entity.metadata.tenant}}/*" {
  capabilities = ["read", "list"]
}

# Template: per-namespace (Enterprise)
path "sys/mounts/{{identity.entity.metadata.namespace}}/*" {
  capabilities = ["read"]
}

# Template: environment-based
path "secret/data/{{identity.entity.metadata.environment}}/*" {
  capabilities = ["read"]
}
```

### Common Policy Patterns

```hcl
# Pattern 1: CI/CD pipeline
path "secret/data/ci/*" {
  capabilities = ["read"]
}
path "secret/data/{{identity.entity.metadata.pipeline}}/*" {
  capabilities = ["read"]
}

# Pattern 2: Application with specific roles
path "secret/data/app/readonly/*" {
  capabilities = ["read", "list"]
}
path "secret/data/app/readwrite/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/data/app/admin/*" {
  capabilities = ["deny"]
}

# Pattern 3: Dynamic secrets approval
path "database/creds/readonly" {
  capabilities = ["read"]
}
path "database/creds/readwrite" {
  capabilities = ["read"]
  # Requires approval (Enterprise feature)
  required_parameters = ["ttl"]
  allowed_parameters = {
    "ttl" = ["3600", "7200"]
  }
}
```

---

## Usage Guide — Step by Step

### Step 1: Initialize Vault

```bash
# Initialize with 5 unseal keys, 3 threshold
vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > /tmp/vault-init.json

# Parse init output
cat /tmp/vault-init.json | jq -r '.unseal_keys_b64[]'
cat /tmp/vault-init.json | jq -r '.root_token'
```

**⚠️ CRITICAL**: Store unseal keys and root token securely. If you lose them, your Vault is permanently sealed.

### Step 2: Unseal Vault

```bash
# Unseal with 3 of 5 keys (threshold)
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>

# Verify status
vault status
# Key             Value
# ---             -----
# Seal Type       shamir
# Initialized     true
# Sealed          false
# Total Shares    5
# Threshold       3
# Version         1.15.4
# Cluster Name    vault-cluster-abc123
# Cluster ID      def456...
# HA Enabled      true
```

### Step 3: Configure Auth Methods

```bash
# Enable AppRole
vault auth enable approle

# Enable Kubernetes (if applicable)
vault auth enable kubernetes

# Enable OIDC (if applicable)
vault auth enable oidc
```

### Step 4: Create Policies

```bash
# Write policy from file
vault policy write myapp-policy /path/to/myapp-policy.hcl

# Or inline
vault policy write myapp-policy - << 'EOF'
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
path "secret/data/myapp/config" {
  capabilities = ["read"]
  required_parameters = []
}
EOF
```

### Step 5: Enable Secret Engines

```bash
# KV store
vault secrets enable -path=secret kv-v2

# Database
vault secrets enable database

# PKI
vault secrets enable pki

# Transit
vault secrets enable transit
```

### Step 6: Configure Secret Engines

```bash
# KV: Write initial secrets
vault kv put secret/myapp/config \
  db_password="initial_password" \
  api_key="initial_key"

# Database: Configure connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://vault:password@localhost:5432/mydb" \
  allowed_roles="readonly" \
  username="vault" \
  password="password"

# PKI: Generate root CA
vault write pki/root/generate/internal \
  common_name="My CA" \
  ttl=87600h
```

### Step 7: Create AppRole for Applications

```bash
# Create role
vault write auth/approle/role/myapp \
  token_policies="myapp-policy" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role_id
vault read auth/approle/role/myapp/role_id

# Generate secret_id
vault write -f auth/approle/role/myapp/secret-id

# Test login
vault write auth/approle/login \
  role_id=<role_id> \
  secret_id=<secret_id>
```

### Step 8: Enable Audit Logging

```bash
# File audit device
vault audit enable file file_path=/var/log/vault/audit.log

# Syslog audit device
vault audit enable syslog tag=vault facility=auth

# Socket audit device
vault audit enable socket address=127.0.0.1:9000 tcp_max_parallel_requests=128
```

### Step 9: Test Everything

```bash
# Test KV read
vault kv put secret/test/hello world=goodbye
vault kv get secret/test/hello

# Test database credentials
vault read database/creds/readonly

# Test PKI certificate
vault write pki/issue/internal-server common_name=test.example.com

# Check audit log
tail -f /var/log/vault/audit.log | jq .
```

---

## High Availability

### Active-Standby with Integrated Raft

```hcl
# vault.hcl (for each node)
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"  # Unique per node

  retry_join {
    leader_api_addr = "https://vault-1.example.com:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-2.example.com:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-3.example.com:8200"
  }
}

cluster_addr = "https://vault-1.example.com:8201"  # For cluster gossip

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/vault.crt"
  tls_key_file  = "/opt/vault/tls/vault.key"
}

api_addr     = "https://vault-1.example.com:8200"
```

```bash
# Join cluster (on non-leader nodes)
vault operator raft join https://vault-1.example.com:8200

# Check cluster status
vault operator raft list-peers

# Raft snapshot (backup)
vault operator raft snapshot save /opt/vault/backup/raft-$(date +%Y%m%d).snap

# Restore raft snapshot
vault operator raft snapshot restore /opt/vault/backup/raft-20240115.snap
```

### Active-Standby with Consul

```hcl
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  token   = "consul-acl-token"
}

cluster_addr = "https://vault-1.example.com:8201"
api_addr     = "https://vault-1.example.com:8200"
```

### Performance Replication (Enterprise)

```bash
# Primary cluster
vault write -f sys/replication/performance/primary/enable

# Secondary cluster
vault write -f sys/replication/performance/secondary/enable \
  primary_api_addr="https://vault-primary.example.com:8200" \
  token="secondary-token"

# Promote secondary to primary (disaster recovery)
vault write -f sys/replication/performance/secondary/promote
```

---

## Encryption as a Service

### Transit Engine Deep Dive

```bash
# Create key with specific type
vault write transit/keys/myapp \
  type=aes256-gcm96 \
  deletion_allowed=false \
  exportable=false \
  allow_plaintext_backup=false \
  auto_rotate_period=720h

# Supported key types:
# - aes128-gcm96
# - aes256-gcm96
# - chacha20-poly1305
# - ed25519
# - ecdsa-p256
# - ecdsa-p384
# - ecdsa-p521
# - rsa-2048
# - rsa-4096

# Encrypt
ENCRYPTED=$(vault write -format=json transit/encrypt/myapp \
  plaintext=$(echo -n "sensitive data" | base64) \
  key_version=1 | jq -r '.data.ciphertext')

# Decrypt
vault write -format=json transit/decrypt/myapp \
  ciphertext="$ENCRYPTED" | jq -r '.data.plaintext' | base64 -d

# Sign data
vault write -format=json transit/sign/myapp \
  input=$(echo -n "data to sign" | base64) \
  hash_algorithm=sha256 | jq -r '.data.signature'

# Verify signature
vault write -format=json transit/verify/myapp \
  input=$(echo -n "data to sign" | base64) \
  signature="vault:v1:abc123..." | jq -r '.data.valid'
```

### Wrapping Secrets

```bash
# Wrap a secret with TTL
WRAPPED=$(vault write -format=json -wrap-ttl=5m \
  secret/data/myapp/config)

# Unwrap (within TTL)
vault unwrap "$WRAPPED"
```

---

## Secrets Leasing & Renewal

### Understanding Leases

```bash
# Every secret has a lease
vault read database/creds/readonly
# Key                Value
# ---                -----
# lease_id           database/creds/readonly/abc123
# lease_duration     3600
# lease_renewable    true
# username           v-appuser-xyz
# password           xYz789...
```

### Renewing Leases

```bash
# Renew a lease
vault lease renew database/creds/readonly/abc123

# Renew with extended TTL
vault lease renew -increment=3600 database/creds/readonly/abc123

# Revoke a specific lease
vault lease revoke database/creds/readonly/abc123

# Revoke all leases for a prefix
vault lease revoke -prefix database/creds/

# Revoke all leases for a token
vault token revoke <token-id>
```

### Lease Management

```bash
# List all leases
vault list sys/leases/lookup

# Lookup specific lease
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123

# Renew lease
vault write sys/leases/renew lease_id=database/creds/readonly/abc123

# Revoke lease
vault write sys/leases/revoke lease_id=database/creds/readonly/abc123
```

---

## Audit Backend

### File Audit Device

```bash
# Enable file audit
vault audit enable file file_path=/var/log/vault/audit.log

# With log rotation
vault audit enable file file_path=/var/log/vault/audit.log \
  log_raw=false \
  hmac_accessor=true \
  mode=0600 \
  description="File audit device"
```

### Syslog Audit Device

```bash
# Enable syslog
vault audit enable syslog tag=vault facility=auth

# With specific options
vault audit enable syslog \
  tag=vault \
  facility=auth \
  log_raw=false \
  hmac_accessor=true \
  tls=false
```

### Socket Audit Device

```bash
# Enable socket (TCP)
vault audit enable socket address=127.0.0.1:9000 tcp_max_parallel_requests=128

# Enable socket (Unix)
vault audit enable socket address=/var/run/vault-audit.sock
```

### Audit Log Format

```json
{
  "type": "request",
  "time": "2024-01-15T10:30:00.123456Z",
  "auth": {
    "token_type": "service",
    "accessor": "hmac-sha256:abc123",
    "policies": ["myapp-policy"],
    "metadata": {},
    "entity_id": "hmac-sha256:def456"
  },
  "request": {
    "id": "req-abc123",
    "operation": "read",
    "path": "secret/data/myapp/config",
    "remote_address": "10.0.0.5",
    "wrap_ttl": 0,
    "headers": {}
  },
  "error": ""
}

{
  "type": "response",
  "time": "2024-01-15T10:30:00.234567Z",
  "auth": {
    "token_type": "service",
    "accessor": "hmac-sha256:abc123",
    "policies": ["myapp-policy"],
    "metadata": {},
    "entity_id": "hmac-sha256:def456"
  },
  "request": {
    "id": "req-abc123",
    "operation": "read",
    "path": "secret/data/myapp/config",
    "remote_address": "10.0.0.5",
    "wrap_ttl": 0,
    "headers": {}
  },
  "response": {
    "data": {
      "data": {
        "api_key": "hmac-sha256:xyz789",
        "db_password": "hmac-sha256:abc123"
      },
      "metadata": {
        "created_time": "2024-01-15T10:00:00Z",
        "deletion_time": "",
        "destroyed": false,
        "version": 1
      }
    },
    "wrap_info": null,
    "warnings": null,
    "auth": null
  }
}
```

---

## Seal/Unseal Operations

### Understanding Seal Types

**Shamir Sealing** (default):
- Uses Shamir's Secret Sharing algorithm
- Splits master key into N shares
- Requires M shares (threshold) to unseal
- Default: 5 shares, 3 threshold

**Auto-unseal** (Cloud KMS):
- Uses cloud provider KMS to unseal automatically
- Vault server starts sealed, KMS decrypts master key
- Supports: AWS KMS, Azure Key Vault, Google Cloud KMS, OCI KMS, Transit (another Vault)

```hcl
# Auto-unseal with AWS KMS
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "abc123-def456"
  access_key = "AKIA..."  # Or use instance profile
  secret_key = "secret..." # Or use instance profile
}
```

### Unseal Operations

```bash
# Check seal status
vault status

# Unseal with keys
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>

# If using auto-unseal, Vault unseals automatically

# Seal Vault (for maintenance)
vault operator seal
# Or via API
curl -X PUT https://vault.example.com:8200/v1/sys/seal -d '{"type": "shamir"}'

# Seal status
curl -s https://vault.example.com:8200/v1/sys/seal-status | jq .
```

### Key Management

```bash
# Get current key information
vault operator key-status

# Rotate unseal keys (without re-sealing)
vault operator rekey \
  -key-shares=5 \
  -key-threshold=3 \
  -target=shares

# Backup keys
vault operator rekey -backup=/opt/vault/backup/rekey-$(date +%Y%m%d)

# Initialize rekey
vault operator rekey -init \
  -key-shares=5 \
  -key-threshold=3

# Provide new key shares
vault operator rekey -nonce=<nonce> <new_key_share_1>
vault operator rekey -nonce=<nonce> <new_key_share_2>
vault operator rekey -nonce=<nonce> <new_key_share_3>

# Cancel rekey
vault operator rekey -cancel -nonce=<nonce>
```

---

## Vault on Kubernetes

### Kubernetes Auth Method

```bash
# Enable
vault auth enable kubernetes

# Configure (from inside cluster)
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  disable_local_ca_jwt=true

# Create role for application
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=production \
  policies=myapp-policy \
  ttl=1h \
  max_ttl=24h

# Create role for CI/CD
vault write auth/kubernetes/role/cicd \
  bound_service_account_names=ci-runner \
  bound_service_account_namespaces=ci \
  policies=cicd-policy \
  ttl=15m \
  max_ttl=1h
```

### Vault Secrets Operator (VSO)

```bash
# Install VSO via Helm
helm install vault hashicorp/vault-secrets-operator \
  --namespace vault-secrets-operator-system \
  --create-namespace

# Create VaultStaticSecret CR
kubectl apply -f - << 'EOF'
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: myapp-config
  namespace: production
spec:
  mount: secret
  path: myapp/config
  destination:
    name: myapp-config
    create: true
  vaultAuthRef: vault-auth
EOF

# Create VaultDynamicSecret CR
kubectl apply -f - << 'EOF'
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultDynamicSecret
metadata:
  name: myapp-db-creds
  namespace: production
spec:
  mount: database
  path: creds/readonly
  destination:
    name: myapp-db-creds
    create: true
  renewalPercent: 67
  vaultAuthRef: vault-auth
EOF
```

### Sidecar Injector

```yaml
# Deployment annotation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "myapp"
    vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp/config"
    vault.hashicorp.com/agent-inject-template-config: |
      {{- with secret "secret/data/myapp/config" -}}
      {
        "db_password": "{{ .Data.data.db_password }}",
        "api_key": "{{ .Data.data.api_key }}"
      }
      {{- end }}
spec:
  template:
    spec:
      serviceAccountName: myapp
      containers:
        - name: myapp
          image: myapp:latest
          volumeMounts:
            - name: vault-secrets
              mountPath: /vault/secrets
              readOnly: true
      volumes:
        - name: vault-secrets
          emptyDir:
            medium: Memory
```

---

## Integration with DevOps Tools

### Terraform

```hcl
# Provider
provider "vault" {
  address = "https://vault.example.com:8200"
  token   = var.vault_token  # Or use AppRole/K8s auth
}

# Read secret
data "vault_generic_secret" "db" {
  path = "secret/data/myapp/database"
}

# Use in resource
resource "aws_db_instance" "main" {
  # ...
  password = data.vault_generic_secret.db.data["db_password"]
}

# Database credentials
data "vault_database_credentials" "db" {
  backend = "database"
  role    = "readonly"
}
```

### Ansible

```yaml
# Lookup plugin
- name: Get secret from Vault
  debug:
    msg: "{{ lookup('hashi_vault', 'secret=secret/data/myapp/config:db_password') }}"

# With custom auth
- name: Get secret
  debug:
    msg: "{{ lookup('hashi_vault',
      'secret=secret/data/myapp/config:db_password auth_method=approle role_id=xxx secret_id=yyy') }}"
```

### Terraform Enterprise/Cloud

```hcl
# Run triggers vault secret fetch
resource "tfe_variable" "db_password" {
  key          = "DB_PASSWORD"
  value        = "vault:secret/data/myapp/database#db_password"
  category     = "env"
  workspace_id = tfe_workspace.main.id
  description  = "Database password from Vault"
  sensitive    = true
}
```

### GitHub Actions

```yaml
- name: Import Secrets
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.example.com:8200
    method: jwt
    role: ci
    jwtGithubAudience: "https://vault.example.com"
    secrets: |
      secret/data/myapp/config db_password | DB_PASSWORD ;
      secret/data/myapp/config api_key | API_KEY ;
```

### CI/CD (Generic)

```bash
#!/bin/bash
# CI/CD script using Vault

# Login via AppRole
VAULT_TOKEN=$(vault write -format=json auth/approle/login \
  role_id="$VAULT_ROLE_ID" \
  secret_id="$VAULT_SECRET_ID" | jq -r '.auth.client_token')

# Export for child processes
export VAULT_TOKEN

# Read secrets
export DB_PASSWORD=$(vault kv get -field=db_password secret/myapp/config)
export API_KEY=$(vault kv get -field=api_key secret/myapp/config)

# Run deployment
./deploy.sh

# Revoke token when done
vault token revoke "$VAULT_TOKEN"
```

---

## Security Hardening

### TLS Configuration

```hcl
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/vault.crt"
  tls_key_file  = "/opt/vault/tls/vault.key"
  tls_min_version = "tls12"
  tls_cipher_suites = [
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
  ]
  tls_prefer_server_cipher_suites = "true"
}
```

### Network Security

```bash
# Firewall rules
sudo ufw allow from 10.0.0.0/24 to any port 8200
sudo ufw allow from 10.0.0.0/24 to any port 8201  # Cluster
sudo ufw deny 8200
sudo ufw deny 8201

# Consul ACLs
consul acl policy create -name vault-server \
  -rules='node "vault-*" { policy = "write" }'

# Kubernetes NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-allow
  namespace: vault
spec:
  podSelector:
    matchLabels:
      app: vault
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: production
      ports:
        - port: 8200
```

### Token Security

```hcl
# Policy for token management
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Restrict token creation
path "auth/token/create" {
  capabilities = ["create"]
  required_parameters = ["policies"]
  max_wrapping_ttl = "30m"
}

# Restrict token revocation
path "auth/token/revoke" {
  capabilities = ["create", "update"]
  # Only allow revoking own tokens
  required_parameters = ["token_accessor"]
}
```

### Audit Security

```bash
# Enable audit with HMAC (default, recommended)
vault audit enable file file_path=/var/log/vault/audit.log

# Raw logging (DANGEROUS - only for debugging)
vault audit enable -path=raw file file_path=/tmp/vault-raw.log log_raw=true

# HMAC accessor (hide token values but keep accessor for correlation)
vault audit enable file file_path=/var/log/vault/audit.log hmac_accessor=true
```

### Response Wrapping

```bash
# Wrap response (hides secret from intermediate systems)
WRAPPED=$(vault write -format=json -wrap-ttl=5m secret/data/myapp/config)
echo "$WRAPPED" | jq .wrap_info
# {
#   "accessor": "v1/wrapping/wrapping-accessor",
#   "token": "v1.wrapping.token...",
#   "ttl": 300,
#   "creation_time": "2024-01-15T10:30:00Z",
#   "wrapped_accessor": "hmac-sha256:abc123"
# }

# Unwrap (must be done within TTL)
vault unwrap v1.wrapping.token...

# Via API
curl -X PUT https://vault.example.com:8200/v1/sys/wrapping/unwrap \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -d '{"token": "v1.wrapping.token..."}'
```

---

## Troubleshooting (20+ Issues)

### Issue 1: Vault is Sealed

**Symptom**: All API requests return `Vault is sealed`

```bash
# Check seal status
vault status | grep Sealed

# Unseal
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### Issue 2: Token Expired

**Symptom**: `permission denied` or `permission denied` errors

```bash
# Check token info
vault token lookup

# Renew token
vault token renew

# Login again for fresh token
vault login -method=approle role_id=<id> secret_id=<id>
```

### Issue 3: Permission Denied

**Symptom**: `permission denied` when accessing a path

```bash
# Check token policies
vault token lookup -format=json | jq '.data.policies'

# Check effective policy
vault policy read <policy-name>

# Test policy against path
vault policy read <policy-name> | grep -A5 "<path>"
```

### Issue 4: Connection Refused

**Symptom**: `dial tcp 127.0.0.1:8200: connect: connection refused`

```bash
# Check if Vault is running
systemctl status vault

# Check Vault process
ps aux | grep vault

# Check logs
journalctl -u vault -f

# Check port
ss -tlnp | grep 8200
```

### Issue 5: TLS Certificate Errors

**Symptom**: `x509: certificate signed by unknown authority`

```bash
# Set CA certificate
export VAULT_CACERT=/path/to/ca.crt

# Or skip verification (DANGEROUS - dev only)
export VAULT_SKIP_VERIFY=true

# Verify certificate
openssl s_client -connect vault.example.com:8200 -CAfile ca.crt
```

### Issue 6: Storage Backend Unavailable

**Symptom**: `storage backend temporarily unavailable`

```bash
# Check Consul health
consul members

# Check Raft status
vault operator raft list-peers

# Check storage backend logs
journalctl -u consul -f
```

### Issue 7: Unseal Key Lost

**Symptom**: Cannot unseal Vault

```bash
# If you have more keys than threshold, use remaining keys
# If not, restore from backup
vault operator raft snapshot restore /path/to/backup.snap

# Or reinitialize (CAUTION: all secrets lost)
vault operator init
```

### Issue 8: Audit Log Full

**Symptom**: `no space left on device`

```bash
# Check disk space
df -h /var/log/vault

# Rotate logs
logrotate /etc/logrotate.d/vault

# Or truncate (after backup)
> /var/log/vault/audit.log
```

### Issue 9: High Latency

**Symptom**: Slow API responses

```bash
# Check storage backend performance
vault status -format=json | jq '.request_time'

# Check cluster status
vault operator raft list-peers

# Enable performance standby (Enterprise)
```

### Issue 10: Token Leaked

**Symptom**: Suspected token compromise

```bash
# Revoke specific token
vault token revoke <token-id>

# Revoke all tokens for a policy
vault token revoke -accessor <accessor>

# Revoke all tokens (CAUTION: emergency only)
vault token revoke -self

# Force re-authentication of all clients
vault policy write no-access - << 'EOF'
path "*" { capabilities = ["deny"] }
EOF
```

### Issue 11: Secret Engine Misconfigured

**Symptom**: `connection refused` or `authentication failed` for database engine

```bash
# Check database config
vault read database/config/postgresql

# Rotate root credentials
vault write -f database/rotate-role/readonly

# Verify connection
vault read database/creds/readonly
```

### Issue 12: KV v2 Version Mismatch

**Symptom**: `key not found` when reading KV v2

```bash
# Check if using v1 vs v2
vault secrets list -format=json | jq '."secret/"'

# If v1, use different path
vault read secret/myapp/config  # v1
vault kv get secret/data/myapp/config  # v2
```

### Issue 13: Policy Syntax Error

**Symptom**: `Error writing policy: invalid character`

```bash
# Validate policy
vault policy write myapp-policy /path/to/policy.hcl

# Check HCL syntax
vault fmt /path/to/policy.hcl
```

### Issue 14: Lease Renewal Failed

**Symptom**: `lease not renewable`

```bash
# Check lease status
vault read sys/leases/lookup lease_id=<lease-id>

# Check if renewable
vault lease renew <lease-id>

# If not renewable, revoke and re-request
vault lease revoke <lease-id>
vault read database/creds/readonly
```

### Issue 15: HA Leader Election Issues

**Symptom**: `Vault is in standby mode`

```bash
# Check cluster status
vault operator raft list-peers

# Force re-election (CAUTION)
vault operator step-down

# Check network connectivity between nodes
curl -k https://vault-2.example.com:8200/v1/sys/health
```

### Issue 16: Kubernetes Auth Failing

**Symptom**: `permission denied` from Kubernetes pods

```bash
# Check service account
kubectl get sa myapp -o yaml

# Verify JWT
kubectl exec -it myapp-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | \
  vault write auth/kubernetes/login role=myapp jwt=-

# Check Kubernetes auth config
vault read auth/kubernetes/config
```

### Issue 17: Root Token Lost

**Symptom**: No root token for emergency access

```bash
# If you have unseal keys, generate new root
vault operator generate-root

# Provide unseal keys
vault operator generate-root -nonce=<nonce> <key1>
vault operator generate-root -nonce=<nonce> <key2>
vault operator generate-root -nonce=<nonce> <key3>

# New root token printed
```

### Issue 18: Database Credential Rotation Failed

**Symptom**: `error rotating credentials`

```bash
# Check database role
vault read database/roles/readonly

# Manually rotate
vault write -f database/rotate-role/readonly

# Verify new credentials work
vault read database/creds/readonly
```

### Issue 19: PKI Certificate Expired

**Symptom**: `certificate has expired` errors

```bash
# Check certificate
vault read pki/cert/<serial-number>

# Revoke and issue new
vault write pki/revoke serial_number=<serial-number>
vault write pki/issue/internal-server common_name=web.example.com

# Check CA certificate expiry
vault read pki/cert/ca
```

### Issue 20: Audit Log Tampering Detection

**Symptom**: Audit log hash mismatch

```bash
# Verify audit log integrity
# Each log entry contains "previous_hash" field

# Check for gaps
cat /var/log/vault/audit.log | jq '.previous_hash' | sort | uniq -c

# If tampering detected:
# 1. Seal Vault immediately
vault operator seal
# 2. Investigate
# 3. Restore from secure backup
# 4. Re-enable audit logging
```

### Issue 21: Auto-Unseal KMS Unavailable

**Symptom**: Vault stays sealed, cannot reach KMS

```bash
# Check KMS connectivity
aws kms describe-key --key-id <key-id>

# Check Vault logs for KMS errors
journalctl -u vault | grep -i "seal"

# Emergency: manual unseal with Shamir keys (if configured)
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### Issue 22: Response Wrapping Timeout

**Symptom**: `wrapping token is expired or not valid`

```bash
# Check wrap TTL
vault unwrap -format=json <wrapped-token>

# If expired, re-wrap with longer TTL
vault write -format=json -wrap-ttl=15m secret/data/myapp/config
```

---

## Tips & Best Practices (20+ Tips)

### Tip 1: Always Use HTTPS

Never expose Vault over plaintext HTTP in production. Use TLS for all communications.

### Tip 2: Enable Audit Logging

Every API call should be logged. Use at least one audit device (file + syslog recommended).

### Tip 3: Use Short-Lived Tokens

Prefer tokens with short TTLs (1 hour) that are renewed automatically, rather than long-lived tokens.

### Tip 4: Implement Least Privilege

Grant only the minimum permissions needed. Use fine-grained policies instead of broad access.

### Tip 5: Use Dynamic Secrets

Prefer database credentials, AWS keys, etc. that are generated on-demand with automatic expiration.

### Tip 6: Rotate Secrets Regularly

Use Vault's built-in rotation capabilities or implement rotation in your applications.

### Tip 7: Use Response Wrapping

When passing secrets through intermediate systems, use response wrapping to limit exposure.

### Tip 8: Implement Separate Environments

Use different Vault namespaces or clusters for dev/staging/production.

### Tip 9: Backup Regularly

```bash
# Raft snapshot
vault operator raft snapshot save /backup/vault-$(date +%Y%m%d).snap

# Schedule daily backups
0 2 * * * vault operator raft snapshot save /backup/vault-$(date +\%Y\%m\%d).snap
```

### Tip 10: Monitor Vault Health

```bash
# Health check
curl -s https://vault.example.com:8200/v1/sys/health | jq .

# Prometheus metrics
vault metrics | grep vault_core_active
```

### Tip 11: Use Namespaces for Multi-Tenancy (Enterprise)

Isolate teams/projects within a single Vault cluster.

### Tip 12: Implement Secret Rotation for Applications

Applications should handle secret rotation gracefully:

```python
import vault

def get_secret(path, field):
    """Get secret with automatic refresh"""
    client = vault.Client()
    secret = client.secrets.kv.v2.read_secret_version(path=path)
    return secret.data['data'][field]
```

### Tip 13: Use Transit for Encryption as a Service

Instead of managing encryption keys, use Vault's Transit engine.

### Tip 14: Implement Zero-Trust Network Access

Combine Vault with identity-aware proxies for zero-trust access.

### Tip 15: Use Sentinel Policies (Enterprise)

Implement approval workflows for sensitive operations.

### Tip 16: Regular Security Audits

```bash
# Review all policies
vault policy list | xargs -I {} vault policy read {}

# Review all tokens
vault token lookup -accessor <accessor>

# Review audit logs for anomalies
grep "permission denied" /var/log/vault/audit.log | jq .request.path | sort | uniq -c | sort -rn
```

### Tip 17: Test Policies Before Deployment

```bash
# Dry-run policy
vault policy write test-policy /path/to/policy.hcl
vault token create -policy=test-policy -format=json | jq -r '.auth.client_token' > /tmp/test-token
VAULT_TOKEN=$(cat /tmp/test-token) vault read secret/test/hello
```

### Tip 18: Use Kubernetes Auth for Workloads

Never store Vault tokens in Kubernetes Secrets. Use the Kubernetes auth method with service accounts.

### Tip 19: Implement Secret Injection

Use Vault Agent or CSI provider to inject secrets into pods rather than application-level fetching.

### Tip 20: Monitor for Secret Sprawl

Regularly audit where secrets are stored:

```bash
# Find secrets outside Vault
grep -r "password" /etc/ --include="*.conf" --include="*.yml" 2>/dev/null
```

### Tip 21: Use Seal Wrap for Critical Secrets

Enable seal wrap for the most sensitive secret engines.

### Tip 22: Implement Break-Glass Procedures

Have documented procedures for emergency access when normal authentication fails.

---

## Command Reference

### Server Operations

```bash
vault server -config=/path/to/config.hcl  # Start server
vault status                                # Check status
vault operator init                         # Initialize
vault operator unseal <key>                 # Unseal
vault operator seal                         # Seal
vault operator key-status                   # Key status
vault operator rekey                        # Rekey
```

### Secret Operations

```bash
vault secrets enable <engine>               # Enable engine
vault secrets disable <path>                # Disable engine
vault secrets list                          # List engines
vault secrets move <old> <new>              # Move engine
vault secrets tune -max-lease-ttl=720h <path>  # Tune engine
```

### KV Operations

```bash
vault kv put <path> key=value              # Write
vault kv get <path>                        # Read
vault kv get -field=<field> <path>         # Read field
vault kv get -version=<n> <path>           # Read version
vault kv delete <path>                     # Delete
vault kv destroy -version=<n> <path>       # Destroy
vault kv list <path>                       # List
vault kv rollback -version=<n> <path>      # Rollback
```

### Auth Operations

```bash
vault auth enable <method>                 # Enable
vault auth disable <path>                  # Disable
vault auth list                            # List
vault login -method=<method>               # Login
vault token lookup                         # Token info
vault token renew                          # Renew token
vault token revoke <token>                 # Revoke token
```

### Policy Operations

```bash
vault policy write <name> <file>           # Write policy
vault policy read <name>                   # Read policy
vault policy delete <name>                 # Delete policy
vault policy list                          # List policies
```

### Lease Operations

```bash
vault lease renew <lease-id>               # Renew
vault lease revoke <lease-id>              # Revoke
vault lease revoke -prefix <prefix>        # Revoke prefix
```

### Audit Operations

```bash
vault audit enable <device> [options]      # Enable
vault audit disable <path>                 # Disable
vault audit list                           # List
```

### Operator Operations

```bash
vault operator init                        # Initialize
vault operator unseal                      # Unseal
vault operator seal                        # Seal
vault operator step-down                   # Step down (HA)
vault operator generate-root               # Generate root token
```

### Raft Operations

```bash
vault operator raft list-peers             # List peers
vault operator raft join <address>         # Join cluster
vault operator raft snapshot save <path>   # Backup
vault operator raft snapshot restore <path>  # Restore
```

---

## Configuration Reference

### Full Server Configuration

```hcl
# vault.hcl

# Storage backend
storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
  
  retry_join {
    leader_api_addr = "https://vault-1.example.com:8200"
  }
}

# Cluster configuration
cluster_addr = "https://vault-1.example.com:8201"
api_addr     = "https://vault-1.example.com:8200"

# Listener
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/vault.crt"
  tls_key_file  = "/opt/vault/tls/vault.key"
  
  # Advanced TLS
  tls_min_version    = "tls12"
  tls_cipher_suites  = [
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
  ]
  tls_prefer_server_cipher_suites = true
  
  # Telemetry
  telemetry {
    unauthenticated_metrics_access = false
  }
  
  # PROXY Protocol (if behind load balancer)
  proxy_protocol_behavior = "use_if_not_set"
}

# Seal configuration
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "abc123-def456"
}

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}

# Logging
log_level  = "info"
log_format = "json"

# UI
ui = true
```

### Environment Variables

```bash
# Server
VAULT_ADDR="https://vault.example.com:8200"
VAULT_TOKEN="s.xxxx"
VAULT_CACERT="/path/to/ca.crt"
VAULT_CLIENT_CERT="/path/to/client.crt"
VAULT_CLIENT_KEY="/path/to/client.key"
VAULT_SKIP_VERIFY=false
VAULT_NAMESPACE="admin"  # Enterprise only

# Auto-unseal
VAULT_AWSKMS_SEAL_KEY_ID="abc123"
AWS_ACCESS_KEY_ID="AKIA..."
AWS_SECRET_ACCESS_KEY="secret..."

# Storage
VAULT_RAFT_NODE_ID="vault-1"
```

---

## Real-World Examples — Our Cluster

### Example 1: K3s Cluster with Vault

```bash
# Install Vault on k3s-master
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: vault
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: vault
  namespace: vault
spec:
  chart:
    spec:
      chart: vault
      version: "0.25.0"
      sourceRef:
        kind: HelmRepository
        name: hashicorp
  values:
    server:
      ha:
        enabled: true
        replicas: 3
        raft:
          enabled: true
      auditStorage:
        enabled: true
      dataStorage:
        enabled: true
        size: 10Gi
EOF

# Initialize Vault
kubectl -n vault exec -it vault-0 -- vault operator init

# Unseal
kubectl -n vault exec -it vault-0 -- vault operator unseal <key1>
kubectl -n vault exec -it vault-1 -- vault operator unseal <key2>
kubectl -n vault exec -it vault-2 -- vault operator unseal <key3>
```

### Example 2: Application Secret Injection

```yaml
# Deployment with Vault Agent
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/myapp/database"
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/myapp/database" -}}
          DB_HOST={{ .Data.data.host }}
          DB_USER={{ .Data.data.username }}
          DB_PASS={{ .Data.data.password }}
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
        - name: myapp
          image: myapp:latest
          command: ["sh", "-c", "source /vault/secrets/db && ./start.sh"]
```

### Example 3: Database Credential Management

```bash
# Configure PostgreSQL
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres.prod.svc:5432/myapp" \
  allowed_roles="myapp-readonly,myapp-readwrite" \
  username="vault_admin" \
  password="initial_password" \
  max_open_connections=10 \
  max_idle_connections=5 \
  max_connection_lifetime="30s"

# Create read-only role
vault write database/roles/myapp-readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  "

# Create read-write role
vault write database/roles/myapp-readwrite \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  "

# Application gets credentials
vault read database/creds/myapp-readonly
# Returns: username=v-appuser-xyz password=abc123 TTL=3600
```

### Example 4: PKI for Internal Services

```bash
# Enable PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write pki/root/generate/internal \
  common_name="Internal CA" \
  key_bits=4096 \
  ttl=87600h

# Configure URLs
vault write pki/config/urls \
  issuing_certificates="https://vault.internal/v1/pki/ca" \
  crl_distribution_points="https://vault.internal/v1/pki/crl"

# Create role for servers
vault write pki/roles/internal-server \
  allowed_domains="internal,svc.cluster.local" \
  allow_subdomains=true \
  max_ttl=720h \
  key_bits=2048

# Issue certificate for web service
vault write -format=json pki/issue/internal-server \
  common_name="web.internal" \
  ttl=72h | jq -r '.data.certificate' > web.crt
vault write -format=json pki/issue/internal-server \
  common_name="web.internal" \
  ttl=72h | jq -r '.data.private_key' > web.key
```

### Example 5: Transit for Application Encryption

```bash
# Enable Transit
vault secrets enable transit

# Create key for application
vault write transit/keys/myapp type=aes256-gcm96

# Application encrypts sensitive data
vault write -format=json transit/encrypt/myapp \
  plaintext=$(echo -n "SSN:123-45-6789" | base64) | \
  jq -r '.data.ciphertext'
# vault:v1:abc123def456...

# Application decrypts when needed
vault write -format=json transit/decrypt/myapp \
  ciphertext="vault:v1:abc123def456..." | \
  jq -r '.data.plaintext' | base64 -d
# SSN:123-45-6789
```

---

## Further Reading

### Official Documentation
- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault API Reference](https://developer.hashicorp.com/vault/api-docs)
- [Vault Tutorials](https://developer.hashicorp.com/vault/tutorials)
- [Vault GitHub](https://github.com/hashicorp/vault)

### Books
- *HashiCorp Vault in Action* by Yos Riady (Manning)
- *Vault: Up and Running* by Yos Riady

### Blogs & Articles
- [Vault Best Practices](https://developer.hashicorp.com/vault/docs/concepts/security)
- [Vault Architecture Reference](https://developer.hashicorp.com/vault/docs/concepts/architecture)
- [Vault Hardening Checklist](https://developer.hashicorp.com/vault/docs/concepts/hardening)

### Community
- [Vault Discuss Forum](https://discuss.hashicorp.com/c/vault/29)
- [Vault GitHub Issues](https://github.com/hashicorp/vault/issues)
- [HashiCorp User Group](https://www.hashicorp.com/community)

### Videos
- [Vault Deep Dive (HashiConf)](https://www.youtube.com/watch?v=6f-jl6YjqkQ)
- [Vault on Kubernetes (KubeCon)](https://www.youtube.com/watch?v=0FGVjRlJlYk)
- [Vault Security Model](https://www.youtube.com/watch?v=kPVawc5KBxM)

### Related Tools
- [Vault Agent](vault-agent.md) — Sidecar for secret injection
- [Sealed Secrets](sealed-secrets.md) — Kubernetes-native solution
- [SOPS](sops.md) — Mozilla's file encryption tool
- [Vault Dynamic Secrets](vault-dynamic-secrets.md) — Dynamic credential management

---

*Last Updated: 2026*
*Version: 1.15.4*
*Author: OpenWolf DevOps Guide*
