# Vault Dynamic Secrets Complete Guide

## Table of Contents

1. [What Are Dynamic Secrets](#what-are-dynamic-secrets)
2. [Why Use Dynamic Secrets — Real Breaches](#why-use-dynamic-secrets--real-breaches)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Database Secrets Engine](#database-secrets-engine)
7. [Cloud Secrets Engines](#cloud-secrets-engines)
8. [PKI Secrets Engine](#pki-secrets-engine)
9. [SSH Secrets Engine](#ssh-secrets-engine)
10. [Transit Secrets Engine](#transit-secrets-engine)
11. [Lease Management](#lease-management)
12. [Usage Guide — Step by Step](#usage-guide--step-by-step)
13. [Custom Roles](#custom-roles)
14. [Credential Rotation](#credential-rotation)
15. [Integration with Applications](#integration-with-applications)
16. [Security Considerations](#security-considerations)
17. [Troubleshooting (20+ Issues)](#troubleshooting-20-issues)
18. [Tips & Best Practices (20+ Tips)](#tips--best-practices-20-tips)
19. [Command Reference](#command-reference)
20. [Configuration Reference](#configuration-reference)
21. [Real-World Examples — Our Cluster](#real-world-examples--our-cluster)
22. [Further Reading](#further-reading)

---

## What Are Dynamic Secrets

Dynamic secrets are secrets generated on-demand by Vault with a short lease duration. Unlike static secrets (which are stored in Vault and returned as-is), dynamic secrets are:

1. **Generated uniquely** for each request (no shared credentials)
2. **Short-lived** with automatic expiration
3. **Auditable** with full lease tracking
4. **Rotatable** with automatic cleanup

### Static vs Dynamic Secrets

```
Static Secrets:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Vault      │────▶│  App A      │     │  App B      │
│  stores     │     │  gets       │     │  gets       │
│  password   │     │  password   │     │  password   │
└─────────────┘     └─────────────┘     └─────────────┘
                         │                   │
                         ▼                   ▼
                    Same password       Same password
                    (shared)            (shared)

Dynamic Secrets:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Vault      │────▶│  App A      │     │  App B      │
│  generates  │     │  gets user1 │     │  gets user2 │
│  on-demand  │     │  pass123    │     │  pass456    │
└─────────────┘     └─────────────┘     └─────────────┘
                         │                   │
                         ▼                   ▼
                    Unique credential   Unique credential
                    TTL: 1h             TTL: 1h
                    (auto-expires)      (auto-expires)
```

### Core Benefits

| Benefit | Static Secrets | Dynamic Secrets |
|---------|---------------|-----------------|
| **Credential uniqueness** | Shared across apps | Unique per request |
| **Automatic expiration** | Manual rotation | Automatic TTL |
| **Audit trail** | Limited | Full lease tracking |
| **Blast radius** | Full environment | Single workload |
| **Compliance** | Hard to prove | Built-in expiration |
| **Cleanup** | Manual | Automatic |

### When to Use Dynamic Secrets

**Use dynamic secrets for:**
- Database credentials (PostgreSQL, MySQL, MongoDB, etc.)
- Cloud IAM credentials (AWS, Azure, GCP)
- SSH access to servers
- TLS certificates (PKI)
- Any credential that benefits from automatic rotation

**Use static secrets for:**
- API keys that can't be rotated automatically
- Third-party service credentials
- Encryption keys (though Transit engine is better)
- Configuration values that don't change

---

## Why Use Dynamic Secrets — Real Breaches

### The Problem Dynamic Secrets Solve

Static credentials that live forever create massive attack surfaces:
- Compromised credential → permanent access
- Shared credentials → no accountability
- No rotation → stale credentials accumulate
- Hard to audit → who accessed what?

### Real-World Breaches Dynamic Secrets Would Prevent

#### 1. Capital One (2019)
- **Breach**: Compromised WAF role → SSRF → EC2 metadata credentials
- **Root cause**: Long-lived IAM credentials in instance metadata
- **Dynamic secrets fix**: Short-lived dynamic AWS credentials with automatic expiration

#### 2. Uber (2016)
- **Breach**: Hardcoded AWS keys in GitHub repository
- **Root cause**: Static credentials stored in code
- **Dynamic secrets fix**: No static credentials to leak; dynamic credentials expire automatically

#### 3. Codecov (2021)
- **Breach**: CI/CD environment variables exfiltrated
- **Root cause**: Static secrets in environment variables
- **Dynamic secrets fix**: Secrets injected at runtime, expire after CI/CD pipeline

#### 4. CircleCI (2023)
- **Breach**: Stolen OAuth tokens led to supply chain attack
- **Root cause**: Long-lived tokens not rotated
- **Dynamic secrets fix**: Short-lived tokens with automatic rotation

#### 5. Twitch (2021)
- **Breach**: Hardcoded credentials in source code
- **Root cause**: Static secrets in codebase
- **Dynamic secrets fix**: No credentials in code; dynamic injection at runtime

### The Business Case for Dynamic Secrets

| Metric | Static Secrets | Dynamic Secrets |
|--------|---------------|-----------------|
| Credential lifetime | Months/Years | Hours/Days |
| Rotation effort | Manual, complex | Automatic |
| Compromise impact | Full environment | Single workload |
| Audit capability | Limited | Complete |
| Compliance | Difficult | Built-in |

---

## Architecture Overview

### Dynamic Secrets Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │
│  Application │────▶│    Vault     │────▶│  Target      │
│              │     │              │     │  System      │
│  requests    │     │  generates   │     │              │
│  credentials │     │  credentials │     │  creates     │
│              │     │  on-demand   │     │  user        │
└──────────────┘     └──────────────┘     └──────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
  Gets unique          Lease created         User created
  credentials          TTL: 1h               with permissions
  (user1/pass123)      Auto-expires          (SELECT only)
```

### Lease Lifecycle

```
1. Request credentials
   │
   ▼
2. Vault generates unique credentials
   │
   ▼
3. Credentials returned + lease created
   │
   │   Lease ID: database/creds/readonly/abc123
   │   TTL: 3600s
   │   Renewable: true
   │
   ▼
4. Application uses credentials
   │
   ├──▶ Before TTL: Can renew lease
   │
   ▼
5. Lease expires (or revoked)
   │
   ▼
6. Vault revokes credentials from target system
   │
   ▼
7. Credentials no longer work
```

### Supported Engines

| Engine | Type | Credential Lifetime |
|--------|------|---------------------|
| **Database** | PostgreSQL, MySQL, MongoDB, etc. | Configurable (default: 1h) |
| **AWS** | IAM Users, AssumeRole | Configurable (default: 1h) |
| **Azure** | Service Principals | Configurable (default: 1h) |
| **GCP** | Service Accounts | Configurable (default: 1h) |
| **PKI** | X.509 Certificates | Configurable (default: 72h) |
| **SSH** | OTP, CA-signed | Configurable (default: 5m) |
| **Transit** | Encryption keys | N/A (encryption service) |

---

## Installation

### Enable Secret Engines

```bash
# Database engine
vault secrets enable database

# AWS engine
vault secrets enable aws

# Azure engine
vault secrets enable azure

# GCP engine
vault secrets enable gcp

# PKI engine
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

# SSH engine
vault secrets enable ssh

# Transit engine
vault secrets enable transit
```

### Configure Root Credentials

```bash
# PostgreSQL
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  allowed_roles="readonly,readwrite" \
  username="vault_admin" \
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

# AWS
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-east-1

# Azure
vault write azure/config \
  subscription_id="abc123" \
  tenant_id="def456" \
  client_id="ghi789" \
  client_secret="jkl012"

# GCP
vault write gcp/config \
  credentials=@/path/to/service-account.json
```

---

## Core Concepts

### Roles

Roles define how credentials are generated:

```bash
# Database role
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "

# AWS role
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
```

### Leases

Every dynamic secret has a lease:

```bash
# Get credentials
vault read database/creds/readonly
# Key                Value
# ---                -----
# lease_id           database/creds/readonly/abc123
# lease_duration     3600
# lease_renewable    true
# username           v-appuser-xyz
# password           xYz789...
```

**Lease Properties:**
- **lease_id**: Unique identifier
- **lease_duration**: TTL in seconds
- **lease_renewable**: Can be renewed
- **lease_max_duration**: Maximum lifetime

### Rotation

Credentials can be rotated automatically:

```bash
# Rotate root credentials
vault write -f database/rotate-role/readonly

# Rotate specific credential
vault write database/rotate-role/readonly \
  name=v-appuser-xyz
```

---

## Database Secrets Engine

### Supported Databases

| Database | Plugin Name |
|----------|-------------|
| PostgreSQL | postgresql-database-plugin |
| MySQL | mysql-database-plugin |
| MariaDB | mysql-rds-database-plugin |
| MongoDB | mongodb-database-plugin |
| MongoDB Atlas | mongodbatlas-database-plugin |
| Cassandra | cassandra-database-plugin |
| CouchDB | couchdb-database-plugin |
| InfluxDB | influxdb-database-plugin |
| Redis | redis-database-plugin |
| Redshift | redshift-database-plugin |
| Snowflake | snowflake-database-plugin |

### PostgreSQL Configuration

```bash
# Enable engine
vault secrets enable database

# Configure connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres.example.com:5432/myapp" \
  allowed_roles="readonly,readwrite,admin" \
  username="vault_admin" \
  password="initial_password" \
  max_open_connections=10 \
  max_idle_connections=5 \
  max_connection_lifetime="30s"

# Create read-only role
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "

# Create read-write role
vault write database/roles/readwrite \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "

# Create admin role
vault write database/roles/admin \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT ALL PRIVILEGES ON DATABASE myapp TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON DATABASE myapp FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "
```

### MySQL Configuration

```bash
# Configure connection
vault write database/config/mysql \
  plugin_name=mysql-database-plugin \
  connection_url="{{username}}:{{password}}@tcp(mysql.example.com:3306)/myapp" \
  allowed_roles="readonly" \
  username="vault" \
  password="initial_password" \
  max_open_connections=10 \
  max_idle_connections=5 \
  max_connection_lifetime="30s"

# Create role
vault write database/roles/readonly \
  db_name=mysql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
    GRANT SELECT ON myapp.* TO '{{name}}'@'%';
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON myapp.* FROM '{{name}}'@'%';
    DROP USER IF EXISTS '{{name}}'@'%';
  "
```

### MongoDB Configuration

```bash
# Configure connection
vault write database/config/mongodb \
  plugin_name=mongodb-database-plugin \
  connection_url="mongodb://{{username}}:{{password}}@mongo.example.com:27017/admin" \
  allowed_roles="readonly" \
  username="vault" \
  password="initial_password"

# Create role
vault write database/roles/readonly \
  db_name=mongodb \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements='
    db = db.getSiblingDB("myapp");
    db.createUser({
      user: "{{name}}",
      pwd: "{{password}}",
      roles: [{ role: "read", db: "myapp" }]
    });
  ' \
  revocation_statements='
    db = db.getSiblingDB("myapp");
    db.dropUser("{{name}}");
  '
```

### Dynamic Credentials

```bash
# Get credentials
vault read database/creds/readonly
# Key                Value
# ---                -----
# lease_id           database/creds/readonly/abc123
# lease_duration     3600
# lease_renewable    true
# username           v-appuser-xyz
# password           xYz789...

# Use credentials in application
PGPASSWORD=xYz789... psql -h postgres.example.com -U v-appuser-xyz -d myapp
```

### Root Credential Rotation

```bash
# Rotate root credentials
vault write -f database/config/postgresql/rotate-root

# Verify rotation
vault read database/config/postgresql
# rotation_statements: [...]
# connection_url: postgresql://{{username}}:{{password}}@...
```

### Static Roles

For credentials that exist already (not generated by Vault):

```bash
# Create static role
vault write database/static-roles/existing-user \
  db_name=postgresql \
  username="existing_user" \
  rotation_period="86400" \
  rotation_statements="
    ALTER USER \"{{name}}\" PASSWORD '{{password}}';
  "

# Get credentials
vault read database/static-creds/existing-user
# Key                Value
# ---                -----
# password           new_password
# ttl                43200
```

---

## Cloud Secrets Engines

### AWS Secrets Engine

```bash
# Enable
vault secrets enable aws

# Configure root credentials
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-east-1

# Create IAM user role
vault write aws/roles/myapp \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myapp-bucket",
        "arn:aws:s3:::myapp-bucket/*"
      ]
    }
  ]
}
EOF

# Create assumed role
vault write aws/roles/cross-account \
  credential_type=assumed_role \
  role_arn=arn:aws:iam::123456789012:role/CrossAccountRole \
  default_sts_ttl=3600 \
  max_sts_ttl=43200

# Get credentials
vault read aws/creds/myapp
# Key                Value
# ---                -----
# lease_id           aws/creds/myapp/abc123
# lease_duration     3600
# lease_renewable    true
# access_key         AKIA...
# secret_key         ...
# security_token     ... (for assumed roles)

# Use credentials
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
aws s3 ls myapp-bucket
```

### Azure Secrets Engine

```bash
# Enable
vault secrets enable azure

# Configure
vault write azure/config \
  subscription_id="abc123" \
  tenant_id="def456" \
  client_id="ghi789" \
  client_secret="jkl012"

# Create role
vault write azure/roles/myapp \
  azure_roles=-<<EOF
[
  {
    "role_name": "Contributor",
    "scope": "/subscriptions/abc123/resourceGroups/myapp"
  }
]
EOF

# Get credentials
vault read azure/creds/myapp
# Key                Value
# ---                -----
# lease_id           azure/creds/myapp/abc123
# lease_duration     3600
# lease_renewable    true
# client_id          new_client_id
# client_secret      new_client_secret
# subscription_id    abc123
# tenant_id          def456
```

### GCP Secrets Engine

```bash
# Enable
vault secrets enable gcp

# Configure
vault write gcp/config \
  credentials=@/path/to/service-account.json

# Create role
vault write gcp/roles/myapp \
  type=iam \
  project_id=my-project \
  policies="roles/storage.objectViewer"

# Get credentials
vault read gcp/creds/myapp
# Key                Value
# ---                -----
# lease_id           gcp/creds/myapp/abc123
# lease_duration     3600
# lease_renewable    true
# token              ya29...
# expires_at         2024-01-15T11:30:00Z
```

---

## PKI Secrets Engine

### Internal CA

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
  issuing_certificates="https://vault.example.com/v1/pki/ca" \
  crl_distribution_points="https://vault.example.com/v1/pki/crl"

# Create role
vault write pki/roles/internal-server \
  allowed_domains="internal,svc.cluster.local" \
  allow_subdomains=true \
  max_ttl=720h \
  key_bits=2048 \
  key_usage="DigitalSignature,KeyEncipherment" \
  ext_key_usage="ServerAuth"

# Issue certificate
vault write pki/issue/internal-server \
  common_name="web.internal" \
  ttl=72h
# Key                Value
# ---                -----
# certificate        -----BEGIN CERTIFICATE-----
# expiration         1705651200
# issuing_ca         -----BEGIN CERTIFICATE-----
# private_key        -----BEGIN RSA PRIVATE KEY-----
# serial_number      abc:123:def
```

### Intermediate CA

```bash
# Enable intermediate PKI
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

# Generate intermediate CSR
vault write -format=json pki_int/intermediate/generate/internal \
  common_name="Intermediate CA" \
  key_bits=4096 | jq -r '.data.csr' > intermediate.csr

# Sign intermediate CA with root
vault write -format=json pki/root/sign-intermediate \
  csr=@intermediate.csr \
  format=pem_bundle \
  ttl=43800h | jq -r '.data.certificate' > intermediate.crt

# Set signed certificate
vault write pki_int/intermediate/set-signed \
  certificate=@intermediate.crt

# Create role
vault write pki_int/roles/internal-server \
  allowed_domains="internal,svc.cluster.local" \
  allow_subdomains=true \
  max_ttl=720h

# Issue certificate
vault write pki_int/issue/internal-server \
  common_name="web.internal" \
  ttl=72h
```

### ACME (Let's Encrypt Integration)

```bash
# Configure ACME
vault write pki/config/acme \
  directory_url="https://acme-v02.api.letsencrypt.org/directory" \
  email="admin@example.com"

# Create ACME role
vault write pki/roles/acme \
  allowed_domains="example.com" \
  allow_subdomains=true \
  max_ttl=720h

# Get ACME account
vault write pki/acme/account \
  role=acme

# Request certificate
vault write pki/acme/certificate \
  role=acme \
  common_name="web.example.com"
```

---

## SSH Secrets Engine

### OTP (One-Time Password)

```bash
# Enable SSH engine
vault secrets enable ssh

# Create OTP role
vault write ssh/roles/otp-role \
  key_type=otp \
  default_user=ubuntu \
  allowed_users="ubuntu,admin" \
  ttl=300

# Generate OTP
vault write ssh/creds/otp-role \
  ip=10.0.0.5
# Key                Value
# ---                -----
# lease_id           ssh/creds/otp-role/abc123
# lease_duration     300
# lease_renewable    false
# otp                abc123def456...

# User connects
ssh -o ProxyCommand="vault-ssh-helper -mode=otp -ip=10.0.0.5 -user=ubuntu" \
  ubuntu@10.0.0.5
```

### CA-Signed Certificates

```bash
# Generate CA key
vault write -format=json ssh/config/ca \
  private_key_type=ed25519 | jq -r '.data.private_key' > /etc/ssh/vault_ca
vault write -format=json ssh/config/ca \
  public_key_type=ed25519 | jq -r '.data.public_key' > /etc/ssh/vault_ca.pub

# Install CA public key on hosts
sudo tee -a /etc/ssh/trusted-user-ca-keys.pub < /etc/ssh/vault_ca.pub

# Configure SSHD
sudo tee -a /etc/ssh/sshd_config << 'EOF'
TrustedUserCAKeys /etc/ssh/vault_ca.pub
EOF
sudo systemctl restart sshd

# Create role
vault write ssh/roles/ca-role \
  key_type=ca \
  default_user=ubuntu \
  allowed_users="ubuntu,admin" \
  allowed_domains="example.com,internal" \
  max_ttl=3600

# Generate certificate
vault write -format=json ssh/sign/ca-role \
  public_key=@/home/user/.ssh/id_ed25519.pub \
  valid_principals=ubuntu \
  ttl=3600 | jq -r '.data.signed_key' > /home/user/.ssh/id_ed25519-cert.pub

# Connect with certificate
ssh -i /home/user/.ssh/id_ed25519 ubuntu@10.0.0.5
```

### Dynamic Host Keys

```bash
# Create role for dynamic keys
vault write ssh/roles/dynamic-role \
  key_type=dynamic \
  default_user=ubuntu \
  allowed_users="ubuntu,admin" \
  ttl=300

# Get dynamic key
vault read ssh/creds/dynamic-role \
  ip=10.0.0.5
# Key                Value
# ---                -----
# lease_id           ssh/creds/dynamic-role/abc123
# lease_duration     300
# lease_renewable    false
# username           ubuntu
# ssh_password       abc123...

# Connect with password
sshpass -p "abc123..." ssh ubuntu@10.0.0.5
```

---

## Transit Secrets Engine

### Encryption as a Service

```bash
# Enable transit engine
vault secrets enable transit

# Create encryption key
vault write transit/keys/myapp \
  type=aes256-gcm96 \
  deletion_allowed=false \
  exportable=false \
  auto_rotate_period=720h

# Encrypt data
vault write -format=json transit/encrypt/myapp \
  plaintext=$(echo -n "sensitive data" | base64) | \
  jq -r '.data.ciphertext'
# vault:v1:abc123...

# Decrypt data
vault write -format=json transit/decrypt/myapp \
  ciphertext="vault:v1:abc123..." | \
  jq -r '.data.plaintext' | base64 -d
# sensitive data
```

### Key Types

| Key Type | Use Case |
|----------|----------|
| `aes128-gcm96` | Symmetric encryption (128-bit) |
| `aes256-gcm96` | Symmetric encryption (256-bit) |
| `chacha20-poly1305` | Symmetric encryption |
| `ed25519` | Digital signatures |
| `ecdsa-p256` | Asymmetric encryption |
| `ecdsa-p384` | Asymmetric encryption |
| `ecdsa-p521` | Asymmetric encryption |
| `rsa-2048` | Asymmetric encryption |
| `rsa-4096` | Asymmetric encryption |

### Signing and Verification

```bash
# Create signing key
vault write transit/keys/signing-key type=ed25519

# Sign data
vault write -format=json transit/sign/signing-key \
  input=$(echo -n "data to sign" | base64) | \
  jq -r '.data.signature'
# vault:v1:abc123...

# Verify signature
vault write -format=json transit/verify/signing-key \
  input=$(echo -n "data to sign" | base64) \
  signature="vault:v1:abc123..." | \
  jq -r '.data.valid'
# true
```

### Key Rotation

```bash
# Rotate key
vault write transit/keys/myapp/rotate

# Check key versions
vault read transit/keys/myapp
# Key                Value
# ---                -----
# type               aes256-gcm96
# keys               map[1:1705312200 2:1705398600]
# latest_version     2
# min_decryption_version  1
# min_encryption_version  2

# Decrypt with specific version
vault write transit/decrypt/myapp \
  ciphertext="vault:v1:abc123..."
```

---

## Lease Management

### Renewing Leases

```bash
# Renew a lease
vault lease renew database/creds/readonly/abc123

# Renew with extended TTL
vault lease renew -increment=3600 database/creds/readonly/abc123

# Renew until max TTL
vault lease renew -increment=3600 -force=true database/creds/readonly/abc123
```

### Revoking Leases

```bash
# Revoke specific lease
vault lease revoke database/creds/readonly/abc123

# Revoke all leases for a prefix
vault lease revoke -prefix database/creds/

# Revoke all leases for a token
vault token revoke <token-id>
```

### Listing Leases

```bash
# List leases by prefix
vault list sys/leases/lookup

# Lookup specific lease
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123
# Key                Value
# ---                -----
# id                 database/creds/readonly/abc123
# ttl                3600
# type               service
# expire_time        2024-01-15T11:30:00Z
# last_renewal       2024-01-15T10:30:00Z
# renewable          true
```

### Lease Properties

| Property | Description |
|----------|-------------|
| **id** | Unique lease identifier |
| **ttl** | Time remaining until expiry |
| **type** | Service or batch |
| **expire_time** | Absolute expiry time |
| **last_renewal** | Last renewal time |
| **renewable** | Can be renewed |
| **max_ttl** | Maximum lifetime |

---

## Usage Guide — Step by Step

### Step 1: Enable Engine

```bash
vault secrets enable database
```

### Step 2: Configure Connection

```bash
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  allowed_roles="readonly" \
  username="vault" \
  password="password"
```

### Step 3: Create Role

```bash
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  "
```

### Step 4: Get Credentials

```bash
vault read database/creds/readonly
# Returns: username, password, lease_id, ttl
```

### Step 5: Use Credentials

```bash
PGPASSWORD=password psql -h localhost -U username -d mydb
```

### Step 6: Monitor Leases

```bash
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123
```

### Step 7: Rotate Credentials

```bash
vault write -f database/rotate-role/readonly
```

### Step 8: Revoke Credentials

```bash
vault lease revoke database/creds/readonly/abc123
```

---

## Custom Roles

### Custom Creation Statements

```bash
# PostgreSQL with specific permissions
vault write database/roles/custom \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT CONNECT ON DATABASE myapp TO \"{{name}}\";
    GRANT USAGE ON SCHEMA public TO \"{{name}}\";
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM \"{{name}}\";
    REVOKE USAGE ON SCHEMA public FROM \"{{name}}\";
    REVOKE CONNECT ON DATABASE myapp FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "
```

### Custom AWS Policies

```bash
# S3 access only
vault write aws/roles/s3-only \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myapp-bucket",
        "arn:aws:s3:::myapp-bucket/*"
      ]
    }
  ]
}
EOF

# Cross-account access
vault write aws/roles/cross-account \
  credential_type=assumed_role \
  role_arn=arn:aws:iam::123456789012:role/CrossAccountRole \
  default_sts_ttl=3600 \
  max_sts_ttl=43200 \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::123456789012:role/CrossAccountRole"
    }
  ]
}
EOF
```

---

## Credential Rotation

### Automatic Rotation

```bash
# Rotate root credentials
vault write -f database/config/postgresql/rotate-root

# Rotate specific credential
vault write database/rotate-role/readonly \
  name=v-appuser-xyz
```

### Manual Rotation

```bash
# Revoke old credentials
vault lease revoke database/creds/readonly/abc123

# Get new credentials
vault read database/creds/readonly
```

### Rotation Policies

```bash
# Set rotation policy
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  rotation_period="3600" \
  rotation_statements="
    ALTER USER \"{{name}}\" PASSWORD '{{password}}';
  "
```

---

## Integration with Applications

### Python

```python
import hvac
import os

class VaultSecretsManager:
    def __init__(self):
        self.client = hvac.Client(url='https://vault.example.com:8200')
        
        # Authenticate with AppRole
        self.client.auth.approle.login(
            role_id=os.environ['VAULT_ROLE_ID'],
            secret_id=os.environ['VAULT_SECRET_ID']
        )
    
    def get_database_credentials(self, role):
        """Get dynamic database credentials"""
        response = self.client.read(f'database/creds/{role}')
        return {
            'username': response['data']['username'],
            'password': response['data']['password'],
            'lease_id': response['lease_id'],
            'lease_duration': response['lease_duration']
        }
    
    def get_aws_credentials(self, role):
        """Get dynamic AWS credentials"""
        response = self.client.read(f'aws/creds/{role}')
        return {
            'access_key': response['data']['access_key'],
            'secret_key': response['data']['secret_key'],
            'security_token': response['data'].get('security_token'),
            'lease_id': response['lease_id'],
            'lease_duration': response['lease_duration']
        }

# Usage
vault = VaultSecretsManager()
db_creds = vault.get_database_credentials('readonly')
aws_creds = vault.get_aws_credentials('myapp')
```

### Go

```go
package main

import (
    "fmt"
    "os"
    
    vault "github.com/hashicorp/vault/api"
)

func main() {
    // Create Vault client
    config := vault.DefaultConfig()
    config.Address = "https://vault.example.com:8200"
    
    client, err := vault.NewClient(config)
    if err != nil {
        panic(err)
    }
    
    // Authenticate with AppRole
    secret, err := client.Logical().Write("auth/approle/login", map[string]interface{}{
        "role_id":     os.Getenv("VAULT_ROLE_ID"),
        "secret_id":   os.Getenv("VAULT_SECRET_ID"),
    })
    if err != nil {
        panic(err)
    }
    client.SetToken(secret.Auth.ClientToken)
    
    // Get database credentials
    secret, err = client.Logical().Read("database/creds/readonly")
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Username: %s\n", secret.Data["username"])
    fmt.Printf("Password: %s\n", secret.Data["password"])
}
```

### Node.js

```javascript
const vault = require('node-vault')();

async function getSecrets() {
    // Authenticate with AppRole
    await vault.approle.login({
        role_id: process.env.VAULT_ROLE_ID,
        secret_id: process.env.VAULT_SECRET_ID
    });
    
    // Get database credentials
    const dbSecret = await vault.read('database/creds/readonly');
    console.log('Username:', dbSecret.data.username);
    console.log('Password:', dbSecret.data.password);
    
    // Get AWS credentials
    const awsSecret = await vault.read('aws/creds/myapp');
    console.log('Access Key:', awsSecret.data.access_key);
    console.log('Secret Key:', awsSecret.data.secret_key);
}

getSecrets();
```

---

## Security Considerations

### Least Privilege

```bash
# Create minimal role
vault write database/roles/minimal \
  db_name=postgresql \
  default_ttl="300" \
  max_ttl="3600" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON specific_table TO \"{{name}}\";
  "
```

### Short TTLs

```bash
# Use short default TTL
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="300" \
  max_ttl="3600"
```

### Audit Logging

```bash
# Enable audit logging
vault audit enable file file_path=/var/log/vault/audit.log

# Monitor credential access
tail -f /var/log/vault/audit.log | jq 'select(.request.path | startswith("database/creds/"))'
```

### Secret Rotation

```bash
# Rotate root credentials regularly
vault write -f database/config/postgresql/rotate-root

# Set up automatic rotation
vault write database/roles/readonly \
  rotation_period="86400"
```

### Response Wrapping

```bash
# Wrap credentials
vault write -wrap-ttl=5m -format=json database/creds/readonly

# Unwrap at destination
vault unwrap <wrapped-token>
```

---

## Troubleshooting (20+ Issues)

### Issue 1: Connection Refused

**Symptom**: `connection refused` when accessing database

```bash
# Check database connectivity
vault read database/config/postgresql

# Verify connection URL
vault write database/config/postgresql \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  --format=json

# Test connection manually
psql -h localhost -U vault -d mydb
```

### Issue 2: Permission Denied

**Symptom**: `permission denied` when creating credentials

```bash
# Check database user permissions
psql -U vault -d mydb -c "\du"

# Verify vault user has CREATE ROLE permission
psql -U postgres -d mydb -c "SELECT has_role_privilege('vault', 'mydb', 'CREATE ROLE');"

# Grant necessary permissions
psql -U postgres -d mydb -c "GRANT CREATE ROLE TO vault;"
```

### Issue 3: Role Already Exists

**Symptom**: `role already exists` error

```bash
# Check existing roles
psql -U postgres -d mydb -c "\du"

# Clean up stale roles
psql -U postgres -d mydb -c "DROP ROLE IF EXISTS \"v-appuser-xyz\";"

# Or use IF EXISTS in creation statements
vault write database/roles/readonly \
  creation_statements="
    DO $$ BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{{name}}') THEN
        CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
      END IF;
    END $$;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  "
```

### Issue 4: Lease Not Renewable

**Symptom**: `lease not renewable` error

```bash
# Check lease status
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123

# Check max TTL
vault read database/roles/readonly

# If max TTL reached, revoke and re-request
vault lease revoke database/creds/readonly/abc123
vault read database/creds/readonly
```

### Issue 5: Credentials Expired

**Symptom**: `connection authentication failed` error

```bash
# Check credential TTL
vault read database/creds/readonly

# If expired, get new credentials
vault read database/creds/readonly

# Check lease status
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123
```

### Issue 6: Database Connection Timeout

**Symptom**: `connection timeout` error

```bash
# Check database connectivity
psql -h localhost -U vault -d mydb -c "SELECT 1;"

# Check network connectivity
telnet localhost 5432

# Check database status
systemctl status postgresql
```

### Issue 7: Invalid Plugin

**Symptom**: `unknown plugin` error

```bash
# Check available plugins
vault read sys/plugins/database

# Verify plugin name
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin
```

### Issue 8: Connection Pool Exhausted

**Symptom**: `too many connections` error

```bash
# Check connection pool settings
vault read database/config/postgresql

# Reduce max connections
vault write database/config/postgresql \
  max_open_connections=5

# Check database connections
psql -U postgres -d mydb -c "SELECT count(*) FROM pg_stat_activity;"
```

### Issue 9: AWS Credentials Invalid

**Symptom**: `InvalidClientTokenId` error

```bash
# Check AWS credentials
vault read aws/config/root

# Rotate root credentials
vault write -f aws/config/root/rotate-root

# Verify IAM user permissions
aws iam list-attached-user-policies --user-name vault
```

### Issue 10: PKI Certificate Expired

**Symptom**: `certificate has expired` error

```bash
# Check certificate expiry
vault read pki/cert/<serial-number>

# Revoke and issue new
vault write pki/revoke serial_number=<serial-number>
vault write pki/issue/internal-server common_name=web.internal

# Check CA expiry
vault read pki/cert/ca
```

### Issue 11: SSH OTP Failed

**Symptom**: `OTP validation failed` error

```bash
# Check OTP role
vault read ssh/roles/otp-role

# Verify SSHD configuration
sudo cat /etc/ssh/sshd_config | grep vault

# Check vault-ssh-helper
vault-ssh-helper -verify-only -ip=10.0.0.5
```

### Issue 12: Transit Key Rotation Failed

**Symptom**: `key rotation failed` error

```bash
# Check key status
vault read transit/keys/myapp

# Verify key permissions
vault read sys/policies/myapp-policy

# Rotate manually
vault write transit/keys/myapp/rotate
```

### Issue 13: Dynamic Secrets Engine Not Enabled

**Symptom**: `no secrets engine at path` error

```bash
# Check enabled engines
vault secrets list

# Enable if missing
vault secrets enable database
```

### Issue 14: Connection URL Template Error

**Symptom**: `template parsing error` in logs

```bash
# Verify connection URL template
vault read database/config/postgresql

# Test with simple template
vault write database/config/postgresql \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb"
```

### Issue 15: Revocation Failed

**Symptom**: `revocation failed` error

```bash
# Check revocation statements
vault read database/roles/readonly

# Test revocation manually
vault lease revoke database/creds/readonly/abc123

# Check database for orphaned roles
psql -U postgres -d mydb -c "\du" | grep v-appuser
```

### Issue 16: AWS Assumed Role Failed

**Symptom**: `AccessDenied` when assuming role

```bash
# Check role ARN
vault read aws/roles/cross-account

# Verify trust policy
aws iam get-role --role-name CrossAccountRole

# Check Vault AWS permissions
aws iam list-attached-user-policies --user-name vault
```

### Issue 17: MongoDB Connection Failed

**Symptom**: `authentication failed` on MongoDB

```bash
# Check MongoDB user
mongo -u vault -p password --authenticationDatabase admin

# Verify user permissions
mongo -u admin -p password --authenticationDatabase admin \
  --eval "db.getUsers()"

# Grant necessary permissions
mongo -u admin -p password --authenticationDatabase admin \
  --eval "db.createUser({user:'vault', pwd:'password', roles:[{role:'userAdminAnyDatabase', db:'admin'}]})"
```

### Issue 18: Certificate Signing Failed

**Symptom**: `certificate signing failed` error

```bash
# Check CA certificate
vault read pki/cert/ca

# Verify key type
vault read pki/roles/internal-server

# Check TTL
vault write pki/issue/internal-server \
  common_name=web.internal \
  ttl=72h
```

### Issue 19: Connection Pool Timeout

**Symptom**: `pool timeout` error

```bash
# Check pool settings
vault read database/config/postgresql

# Increase pool size
vault write database/config/postgresql \
  max_open_connections=20

# Check database load
psql -U postgres -d mydb -c "SELECT count(*) FROM pg_stat_activity;"
```

### Issue 20: Secret Not Rotated

**Symptom**: Old secret still in use

```bash
# Check secret version
vault read database/creds/readonly

# Force rotation
vault lease revoke database/creds/readonly/abc123
vault read database/creds/readonly

# Check rotation policy
vault read database/roles/readonly
```

### Issue 21: Azure Service Principal Creation Failed

**Symptom**: `service principal creation failed` error

```bash
# Check Azure credentials
vault read azure/config

# Verify Azure AD permissions
az ad app list --display-name vault

# Check subscription permissions
az role assignment list --assignee <vault-client-id>
```

### Issue 22: GCP Service Account Creation Failed

**Symptom**: `service account creation failed` error

```bash
# Check GCP credentials
vault read gcp/config

# Verify IAM permissions
gcloud projects get-iam-policy my-project

# Check service account permissions
gcloud iam service-accounts list
```

---

## Tips & Best Practices (20+ Tips)

### Tip 1: Use Short TTLs

Set short default TTLs for dynamic credentials:

```bash
vault write database/roles/readonly \
  default_ttl="300" \
  max_ttl="3600"
```

### Tip 2: Rotate Root Credentials

Rotate root credentials regularly:

```bash
vault write -f database/config/postgresql/rotate-root
```

### Tip 3: Use Revocation Statements

Always define revocation statements:

```bash
vault write database/roles/readonly \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "
```

### Tip 4: Monitor Lease Expiry

Monitor lease expiry to prevent credential exhaustion:

```bash
# Check lease TTL
vault read sys/leases/lookup lease_id=database/creds/readonly/abc123

# Set up monitoring
```

### Tip 5: Use Response Wrapping

Wrap credentials when passing through intermediate systems:

```bash
vault write -wrap-ttl=5m database/creds/readonly
```

### Tip 6: Implement Least Privilege

Grant minimal permissions:

```bash
vault write database/roles/readonly \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON specific_table TO \"{{name}}\";
  "
```

### Tip 7: Use Static Roles for Existing Credentials

For credentials that already exist:

```bash
vault write database/static-roles/existing-user \
  db_name=postgresql \
  username="existing_user" \
  rotation_period="86400"
```

### Tip 8: Monitor Connection Pools

Monitor connection pool usage:

```bash
# Check pool settings
vault read database/config/postgresql

# Monitor database connections
psql -U postgres -d mydb -c "SELECT count(*) FROM pg_stat_activity;"
```

### Tip 9: Use Audit Logging

Enable audit logging for compliance:

```bash
vault audit enable file file_path=/var/log/vault/audit.log
```

### Tip 10: Test Revocation

Test revocation statements before deployment:

```bash
# Create test role
vault write database/roles/test \
  db_name=postgresql \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
  " \
  revocation_statements="
    DROP ROLE IF EXISTS \"{{name}}\";
  "

# Test
vault read database/creds/test
vault lease revoke <lease-id>
```

### Tip 11: Use Connection URL Templates

Use templates for connection URLs:

```bash
vault write database/config/postgresql \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb"
```

### Tip 12: Implement Secret Rotation

Implement automatic rotation:

```bash
vault write database/roles/readonly \
  rotation_period="86400" \
  rotation_statements="
    ALTER USER \"{{name}}\" PASSWORD '{{password}}';
  "
```

### Tip 13: Use Cloud IAM Roles

For AWS, use assumed roles instead of IAM users:

```bash
vault write aws/roles/myapp \
  credential_type=assumed_role \
  role_arn=arn:aws:iam::123456789012:role/myapp
```

### Tip 14: Monitor Lease Count

Monitor lease count to prevent exhaustion:

```bash
vault list sys/leases/lookup
```

### Tip 15: Use Batch Tokens

For high-volume credential requests:

```bash
vault token create -policy=readonly -type=batch -ttl=1h
```

### Tip 16: Implement Circuit Breakers

Implement circuit breakers in applications:

```python
try:
    creds = vault.get_database_credentials('readonly')
except Exception as e:
    # Fallback to cached credentials
    creds = get_cached_credentials()
```

### Tip 17: Use Health Checks

Use Vault health checks:

```bash
curl -s https://vault.example.com:8200/v1/sys/health
```

### Tip 18: Monitor Audit Logs

Monitor audit logs for anomalies:

```bash
tail -f /var/log/vault/audit.log | jq 'select(.request.path | startswith("database/creds/"))'
```

### Tip 19: Use Namespaces

Use namespaces for multi-tenancy:

```bash
vault namespace create team-a
vault secrets enable -namespace=team-a database
```

### Tip 20: Document Credential Usage

Document credential usage:

```bash
echo "Database credentials:" > /vault/docs/README.md
echo "Role: readonly" >> /vault/docs/README.md
echo "TTL: 1h" >> /vault/docs/README.md
```

---

## Command Reference

### Engine Operations

```bash
vault secrets enable <engine>                    # Enable engine
vault secrets disable <path>                     # Disable engine
vault secrets list                               # List engines
vault secrets tune -max-lease-ttl=720h <path>   # Tune engine
```

### Database Operations

```bash
vault write database/config/<name> ...           # Configure connection
vault write database/roles/<name> ...            # Create role
vault read database/creds/<name>                 # Get credentials
vault read database/config/<name>                # Read config
vault write -f database/rotate-root              # Rotate root
```

### AWS Operations

```bash
vault write aws/config/root ...                  # Configure root
vault write aws/roles/<name> ...                 # Create role
vault read aws/creds/<name>                      # Get credentials
vault write -f aws/config/root/rotate-root       # Rotate root
```

### PKI Operations

```bash
vault write pki/root/generate/internal ...       # Generate CA
vault write pki/issue/<role> ...                 # Issue certificate
vault write pki/revoke serial_number=<serial>    # Revoke certificate
vault read pki/cert/ca                           # Read CA cert
```

### SSH Operations

```bash
vault write ssh/roles/<name> ...                 # Create role
vault write ssh/creds/<name> ...                 # Get credentials
vault write ssh/sign/<role> ...                  # Sign key
```

### Transit Operations

```bash
vault write transit/keys/<name> ...              # Create key
vault write transit/encrypt/<name> ...           # Encrypt
vault write transit/decrypt/<name> ...           # Decrypt
vault write transit/keys/<name>/rotate           # Rotate key
```

### Lease Operations

```bash
vault lease renew <lease-id>                     # Renew lease
vault lease revoke <lease-id>                    # Revoke lease
vault lease revoke -prefix <prefix>              # Revoke prefix
vault read sys/leases/lookup lease_id=<id>       # Lookup lease
```

---

## Configuration Reference

### Database Configuration

```bash
vault write database/config/<name> \
  plugin_name=<plugin> \
  connection_url="<url>" \
  allowed_roles="<roles>" \
  username="<username>" \
  password="<password>" \
  max_open_connections=<n> \
  max_idle_connections=<n> \
  max_connection_lifetime="<duration>"
```

### Role Configuration

```bash
vault write database/roles/<name> \
  db_name=<db-name> \
  default_ttl="<ttl>" \
  max_ttl="<ttl>" \
  creation_statements="<sql>" \
  revocation_statements="<sql>" \
  rotation_period="<seconds>" \
  rotation_statements="<sql>"
```

### AWS Configuration

```bash
vault write aws/config/root \
  access_key=<key> \
  secret_key=<secret> \
  region=<region>

vault write aws/roles/<name> \
  credential_type=<iam_user|assumed_role> \
  role_arn=<arn> \
  default_sts_ttl=<seconds> \
  max_sts_ttl=<seconds> \
  policy_document=<json>
```

### PKI Configuration

```bash
vault write pki/root/generate/internal \
  common_name=<name> \
  key_bits=<bits> \
  ttl=<duration>

vault write pki/config/urls \
  issuing_certificates=<url> \
  crl_distribution_points=<url>
```

---

## Real-World Examples — Our Cluster

### Example 1: PostgreSQL Dynamic Credentials

```bash
# Enable database engine
vault secrets enable database

# Configure PostgreSQL
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres.prod.svc:5432/myapp" \
  allowed_roles="readonly,readwrite" \
  username="vault" \
  password="initial_password"

# Create read-only role
vault write database/roles/readonly \
  db_name=postgresql \
  default_ttl="1h" \
  max_ttl="24h" \
  creation_statements="
    CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";
  " \
  revocation_statements="
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"{{name}}\";
    DROP ROLE IF EXISTS \"{{name}}\";
  "

# Get credentials
vault read database/creds/readonly
# Returns: username=v-appuser-xyz, password=abc123, TTL=3600
```

### Example 2: AWS Dynamic Credentials

```bash
# Enable AWS engine
vault secrets enable aws

# Configure root
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-east-1

# Create S3 role
vault write aws/roles/s3-access \
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
vault read aws/creds/s3-access
# Returns: access_key, secret_key, TTL=3600
```

### Example 3: PKI for Internal Services

```bash
# Enable PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write pki/root/generate/internal \
  common_name="Internal CA" \
  key_bits=4096 \
  ttl=87600h

# Create role
vault write pki/roles/internal-server \
  allowed_domains="internal,svc.cluster.local" \
  allow_subdomains=true \
  max_ttl=720h

# Issue certificate
vault write pki/issue/internal-server \
  common_name="web.internal" \
  ttl=72h
```

### Example 4: SSH CA Authentication

```bash
# Enable SSH engine
vault secrets enable ssh

# Generate CA key
vault write -format=json ssh/config/ca \
  private_key_type=ed25519 | jq -r '.data.private_key' > /etc/ssh/vault_ca

# Create role
vault write ssh/roles/ca-role \
  key_type=ca \
  default_user=ubuntu \
  allowed_users="ubuntu,admin" \
  max_ttl=3600

# Sign key
vault write -format=json ssh/sign/ca-role \
  public_key=@/home/user/.ssh/id_ed25519.pub \
  valid_principals=ubuntu \
  ttl=3600 | jq -r '.data.signed_key' > /home/user/.ssh/id_ed25519-cert.pub
```

---

## Further Reading

### Official Documentation
- [Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases)
- [AWS Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/aws)
- [Azure Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/azure)
- [GCP Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/gcp)
- [PKI Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/pki)
- [SSH Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/ssh)
- [Transit Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/transit)

### Tutorials
- [Database Secrets Engine](https://developer.hashicorp.com/vault/tutorials/db-credentials)
- [AWS Secrets Engine](https://developer.hashicorp.com/vault/tutorials/aws)
- [PKI Secrets Engine](https://developer.hashicorp.com/vault/tutorials/pki)

### Community
- [Vault Discuss Forum](https://discuss.hashicorp.com/c/vault/29)
- [Vault GitHub Issues](https://github.com/hashicorp/vault/issues)

### Related Guides
- [HashiCorp Vault Complete Guide](vault.md)
- [Vault Agent Complete Guide](vault-agent.md)
- [Sealed Secrets](sealed-secrets.md)
- [SOPS (Mozilla)](sops.md)

---

*Last Updated: 2026*
*Version: 1.15.4*
*Author: OpenWolf DevOps Guide*
