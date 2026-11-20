# SOPS (Mozilla) Complete Guide

## Table of Contents

1. [What Is SOPS](#what-is-sops)
2. [Why Use SOPS — Real Breaches](#why-use-sops--real-breaches)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Configuration Reference](#configuration-reference)
7. [Key Management](#key-management)
8. [Encryption Formats](#encryption-formats)
9. [Usage Guide — Step by Step](#usage-guide--step-by-step)
10. [PGP/GPG Integration](#pgpgpg-integration)
11. [KMS Integration](#kms-integration)
12. [Azure Key Vault Integration](#azure-key-vault-integration)
13. [GCP KMS Integration](#gcp-kms-integration)
14. [age Integration](#age-integration)
15. [Kubernetes Integration](#kubernetes-integration)
16. [GitOps Integration](#gitops-integration)
17. [Security Considerations](#security-considerations)
18. [Troubleshooting (20+ Issues)](#troubleshooting-20-issues)
19. [Tips & Best Practices (20+ Tips)](#tips--best-practices-20-tips)
20. [Command Reference](#command-reference)
21. [Configuration Reference (Full)](#configuration-reference-full)
22. [Real-World Examples — Our Cluster](#real-world-examples--our-cluster)
23. [Further Reading](#further-reading)

---

## What Is SOPS

SOPS (Secrets OPerationS) is an open-source tool originally developed by Mozilla for securely managing encrypted files. It supports YAML, JSON, ENV, INI, and binary file formats, and can encrypt values while leaving keys/structure readable.

### How It Works

1. **You define encryption keys** (PGP, AWS KMS, Azure Key Vault, GCP KMS, age)
2. **SOPS encrypts values** in structured files (YAML, JSON, etc.)
3. **Keys/structure remain readable** for git diffs and code review
4. **Encrypted files can be committed** to Git safely
5. **SOPS decrypts** using the configured keys at runtime

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │
│  Developer   │────▶│  SOPS        │────▶│  Git Repo    │
│              │     │              │     │              │
│  Encrypts    │     │  Encrypts    │     │  Stores      │
│  secrets     │     │  values      │     │  encrypted   │
│              │     │              │     │  files       │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
                                                ▼
                                         ┌──────────────┐
                                         │              │
                                         │  Application │
                                         │              │
                                         │  Decrypts    │
                                         │  at runtime  │
                                         └──────────────┘
```

### Key Features

| Feature | Description |
|---------|-------------|
| **Multi-format** | YAML, JSON, ENV, INI, binary |
| **Partial encryption** | Encrypt values, leave keys readable |
| **Multiple key types** | PGP, AWS KMS, Azure Key Vault, GCP KMS, age |
| **Key rotation** | Re-encrypt with new keys |
| **Git-friendly** | Encrypted files work with git diff |
| **No server** | Client-side encryption/decryption |

### What SOPS Is NOT

- **Not a secrets manager** — Just encrypted files
- **Not a key management service** — Uses external KMS
- **Not a secrets injection tool** — Files must be decrypted before use
- **Not for dynamic secrets** — Static file encryption only

---

## Why Use SOPS — Real Breaches

### The Problem SOPS Solves

Secrets in configuration files are a major security risk:
- Plain text secrets in Git repos
- Secrets in CI/CD pipelines
- Secrets in backup files
- Secrets in configuration management

### Real-World Breaches

#### 1. GitHub Repository Exposure
- **Breach**: Hardcoded AWS keys in public GitHub repo
- **Impact**: $150K cloud bill in 2 days
- **SOPS fix**: Encrypted secrets in Git, safe to commit

#### 2. Docker Compose Secret Leaks
- **Breach**: docker-compose.yml with plain text secrets committed
- **Impact**: Full database access
- **SOPS fix**: Encrypted docker-compose.sops.yaml

#### 3. Ansible Vault Compromise
- **Breach**: Weak Ansible Vault password cracked
- **Impact**: Production credentials exposed
- **SOPS fix**: Multiple key encryption, key rotation

#### 4. Terraform State Exposure
- **Breach**: Terraform state with secrets stored in S3
- **Impact**: All infrastructure secrets exposed
- **SOPS fix**: Encrypted tfvars files

#### 5. Helm Values Leakage
- **Breach**: Helm values.yaml with database passwords in Git
- **Impact**: Database credentials exposed
- **SOPS fix**: Encrypted values.sops.yaml

### Business Case

| Metric | Plain Text Secrets | SOPS Encrypted |
|--------|-------------------|----------------|
| **Git safety** | Unsafe | Safe |
| **Diff readability** | N/A | Keys visible |
| **Key management** | Manual | KMS-managed |
| **Rotation** | Manual | Automated |
| **Compliance** | Difficult | Built-in |

---

## Architecture Overview

### SOPS Components

```
┌─────────────────────────────────────────────────────────┐
│                    SOPS Architecture                     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Key Management                      │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  PGP     │  │  AWS KMS │  │  Azure   │     │   │
│  │  │  Keys    │  │          │  │  Key     │     │   │
│  │  └──────────┘  └──────────┘  │  Vault   │     │   │
│  │                              └──────────┘     │   │
│  │  ┌──────────┐  ┌──────────┐                   │   │
│  │  │  GCP KMS │  │  age     │                   │   │
│  │  │          │  │  Keys    │                   │   │
│  │  └──────────┘  └──────────┘                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Encryption Engine                   │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  YAML    │  │  JSON    │  │  ENV     │     │   │
│  │  │  Parser  │  │  Parser  │  │  Parser  │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  INI     │  │  Binary  │  │  Custom  │     │   │
│  │  │  Parser  │  │  Handler │  │  Format  │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              File Handler                        │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Read    │  │  Write   │  │  Diff     │     │   │
│  │  │  Files   │  │  Files   │  │  Support  │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Encryption Flow

```
1. SOPS reads file
   │
   ▼
2. SOPS parses structure (YAML/JSON/etc.)
   │
   ▼
3. SOPS identifies values to encrypt
   │
   ▼
4. SOPS encrypts values using configured keys
   │
   ▼
5. SOPS writes encrypted file with metadata
   │
   ▼
6. Metadata includes key info for decryption
```

### Decryption Flow

```
1. SOPS reads encrypted file
   │
   ▼
2. SOPS reads metadata (key info)
   │
   ▼
3. SOPS decrypts data key using configured KMS
   │
   ▼
4. SOPS decrypts values using data key
   │
   ▼
5. SOPS outputs decrypted file
```

---

## Installation

### Method 1: Binary Download (Recommended)

```bash
# Download latest version
SOPS_VERSION="3.8.1"
wget -qO /tmp/sops \
  "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"

# Install
sudo install /tmp/sops /usr/local/bin/sops

# Verify
sops --version
# sops 3.8.1
```

### Method 2: Package Manager

```bash
# Ubuntu/Debian
sudo apt-get install -y sops

# macOS (Homebrew)
brew install sops

# Fedora/RHEL
sudo dnf install -y sops

# Arch Linux
sudo pacman -S sops
```

### Method 3: Snap

```bash
sudo snap install sops --classic
```

### Method 4: Docker

```bash
# Pull image
docker pull mozilla/sops:v3.8.1

# Run
docker run -it --rm \
  -v $(pwd):/work \
  -w /work \
  mozilla/sops:v3.8.1 \
  sops --encrypt secrets.yaml > secrets.enc.yaml
```

### Method 5: Go Install

```bash
go install github.com/getsops/sops/v3/cmd/sops@latest
```

---

## Core Concepts

### Encryption Types

#### 1. PGP (Pretty Good Privacy)

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    pgp: FINGERPRINT1,FINGERPRINT2
```

#### 2. AWS KMS

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
```

#### 3. Azure Key Vault

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    azure_keyvault: "https://myvault.vault.azure.net/keys/mykey/abc123"
```

#### 4. GCP KMS

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    gcp_kms: "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
```

#### 5. age

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    age: age1qyxyz...
```

### Encrypted File Structure

```yaml
# Encrypted YAML file
db_password: ENC[AES256_GCM,data:abc123...,type:str]
api_key: ENC[AES256_GCM,data:def456...,type:str]
sops:
    kms:
        - arn: arn:aws:kms:us-east-1:123456789012:key/abc123
          created_at: "2024-01-15T10:30:00Z"
          enc: abc123...
    pgp:
        - created_at: "2024-01-15T10:30:00Z"
          enc: abc123...
    lastmodified: "2024-01-15T10:30:00Z"
    version: 3.8.1
```

### Data Key

SOPS uses a **data key** for encryption:
1. SOPS generates a random data key
2. Data key encrypts the file values
3. Data key is encrypted with configured KMS
4. Encrypted data key stored in file metadata
5. To decrypt, KMS decrypts the data key
6. Data key decrypts the file values

---

## Configuration Reference

### .sops.yaml

```yaml
# Global configuration
creation_rules:
  # Rule 1: YAML files
  - path_regex: \.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
    pgp: "FINGERPRINT1,FINGERPRINT2"

  # Rule 2: JSON files
  - path_regex: \.json$
    kms: "arn:aws:kms:us-east-1:123456789012:key/def456"

  # Rule 3: ENV files
  - path_regex: \.env$
    kms: "arn:aws:kms:us-east-1:123456789012:key/ghi789"

  # Rule 4: Environment-specific
  - path_regex: production/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/prod-key"

  # Rule 5: Team-specific
  - path_regex: team-a/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/team-a-key"
```

### Configuration Options

```yaml
creation_rules:
  - path_regex: <regex>
    # Encryption keys
    pgp: "<fingerprint1>,<fingerprint2>"
    kms: "<arn1>,<arn2>"
    azure_keyvault: "<url1>,<url2>"
    gcp_kms: "<resource1>,<resource2>"
    age: "<pubkey1>,<pubkey2>"

    # File format
    # (auto-detected from extension)

    # Unencrypted suffix
    unencrypted_suffix: "_unencrypted"

    # Encrypted suffix
    encrypted_suffix: "_encrypted"

    # Regex to exclude
    exclude: "<regex>"

    # Shred options
    shred: true
    shred_iterations: 10
```

---

## Key Management

### PGP/GPG Keys

```bash
# Generate key
gpg --gen-key

# List keys
gpg --list-keys

# Export public key
gpg --export --armor FINGERPRINT > public.key

# Export private key
gpg --export-secret-keys --armor FINGERPRINT > private.key

# Import key
gpg --import public.key
gpg --import private.key

# Trust key
gpg --edit-key FINGERPRINT trust
```

### AWS KMS

```bash
# Create key
aws kms create-key --description "SOPS encryption key"

# Create alias
aws kms create-alias \
  --alias-name alias/sops \
  --target-key-id <key-id>

# Get key ARN
aws kms describe-key --key-id <key-id>

# Grant access
aws kms create-grant \
  --key-id <key-id> \
  --grantee-principal <principal-arn> \
  --operations Encrypt Decrypt GenerateDataKey
```

### Azure Key Vault

```bash
# Create vault
az keyvault create --name myvault --resource-group mygroup

# Create key
az keyvault key create \
  --vault-name myvault \
  --name sops-key \
  --kty RSA-HSM \
  --size 2048

# Get key URI
az keyvault key show \
  --vault-name myvault \
  --name sops-key \
  --query key.kid
```

### GCP KMS

```bash
# Create key ring
gcloud kms keyrings create my-ring --location global

# Create key
gcloud kms keys create my-key \
  --keyring my-ring \
  --location global \
  --purpose encryption

# Get key resource name
gcloud kms keys describe my-key \
  --keyring my-ring \
  --location global
```

### age Keys

```bash
# Generate key pair
age-keygen -o key.txt

# Output:
# Public key: age1qyxyz...

# Convert to SSH key (optional)
ssh-to-age < ~/.ssh/id_ed25519.pub
```

---

## Encryption Formats

### YAML

```yaml
# Before encryption
db_password: mypassword
api_key: abc123
config:
  host: localhost
  port: 5432

# After encryption
db_password: ENC[AES256_GCM,data:abc123...,type:str]
api_key: ENC[AES256_GCM,data:def456...,type:str]
config:
  host: ENC[AES256_GCM,data:ghi789...,type:str]
  port: ENC[AES256_GCM,data:jkl012...,type:int]
```

### JSON

```json
// Before encryption
{
  "db_password": "mypassword",
  "api_key": "abc123"
}

// After encryption
{
  "db_password": "ENC[AES256_GCM,data:abc123...,type:str]",
  "api_key": "ENC[AES256_GCM,data:def456...,type:str]"
}
```

### ENV

```bash
# Before encryption
DB_PASSWORD=mypassword
API_KEY=abc123

# After encryption
DB_PASSWORD=ENC[AES256_GCM,data:abc123...,type:str]
API_KEY=ENC[AES256_GCM,data:def456...,type:str]
```

### INI

```ini
# Before encryption
[database]
password = mypassword

[api]
key = abc123

# After encryption
[database]
password = ENC[AES256_GCM,data:abc123...,type:str]

[api]
key = ENC[AES256_GCM,data:def456...,type:str]
```

### Binary

```bash
# Encrypt binary file
sops --encrypt --binary secret.bin > secret.enc.bin

# Decrypt binary file
sops --decrypt --binary secret.enc.bin > secret.bin
```

---

## Usage Guide — Step by Step

### Step 1: Install SOPS

```bash
# Download and install
wget -qO /tmp/sops \
  "https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64"
sudo install /tmp/sops /usr/local/bin/sops

# Verify
sops --version
```

### Step 2: Generate Keys

```bash
# PGP
gpg --gen-key

# Or age
age-keygen -o key.txt
# Public key: age1qyxyz...

# Or use AWS KMS
aws kms create-key --description "SOPS key"
```

### Step 3: Configure .sops.yaml

```yaml
# .sops.yaml in repo root
creation_rules:
  - path_regex: \.yaml$
    pgp: "FINGERPRINT"
    # or
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
    # or
    age: "age1qyxyz..."
```

### Step 4: Create Secret File

```yaml
# secrets.yaml
db_password: mypassword
api_key: abc123
redis_password: redispass
```

### Step 5: Encrypt File

```bash
# Encrypt
sops --encrypt secrets.yaml > secrets.enc.yaml

# Or in-place
sops --encrypt --in-place secrets.yaml
```

### Step 6: Verify Encryption

```bash
# View encrypted file
cat secrets.enc.yaml
# db_password: ENC[AES256_GCM,data:abc123...,type:str]
# api_key: ENC[AES256_GCM,data:def456...,type:str]
# sops:
#     pgp:
#         - created_at: "2024-01-15T10:30:00Z"
#           enc: abc123...
#     lastmodified: "2024-01-15T10:30:00Z"
#     version: 3.8.1
```

### Step 7: Commit to Git

```bash
git add secrets.enc.yaml
git commit -m "Add encrypted secrets"
git push
```

### Step 8: Decrypt at Runtime

```bash
# Decrypt
sops --decrypt secrets.enc.yaml > secrets.yaml

# Or pipe
sops --decrypt secrets.enc.yaml | kubectl apply -f -

# Or in-place
sops --decrypt --in-place secrets.enc.yaml
```

---

## PGP/GPG Integration

### Setup

```bash
# Generate key
gpg --gen-key

# List keys
gpg --list-keys
# pub   rsa4096 2024-01-15 [SC]
#       ABCD1234EFGH5678IJKL9012MNOP3456QRST7890
# uid           [ultimate] Your Name <you@example.com>
# sub   rsa4096 2024-01-15 [E]

# Export fingerprint
gpg --list-keys --keyid-format long you@example.com
# pub   rsa4096/ABCD1234EFGH5678 2024-01-15 [SC]
#       ABCD1234EFGH5678IJKL9012MNOP3456QRST7890
# uid                 [ultimate] Your Name <you@example.com>
# sub   rsa4096/IJKL9012MNOP3456 2024-01-15 [E]
```

### Configuration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    pgp: "ABCD1234EFGH5678IJKL9012MNOP3456QRST7890"
```

### Multi-Key Setup

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    pgp: "KEY1,KEY2,KEY3"
```

### Key Rotation

```bash
# Re-encrypt with new key
sops --rotate --pgp "NEW_KEY" secrets.enc.yaml

# Or update .sops.yaml and re-encrypt
sops --update-parent-config secrets.enc.yaml
```

---

## KMS Integration

### AWS KMS

```bash
# Create key
aws kms create-key --description "SOPS encryption key"

# Create alias
aws kms create-alias \
  --alias-name alias/sops \
  --target-key-id <key-id>

# Get key ARN
aws kms describe-key --key-id alias/sops
```

### Configuration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"

  - path_regex: production/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/prod-key"

  - path_regex: staging/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/staging-key"
```

### Multi-Region KMS

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/key1,arn:aws:kms:eu-west-1:123456789012:key/key2"
```

### KMS with IAM

```bash
# Create IAM policy
aws iam create-policy \
  --policy-name sops-kms \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": "arn:aws:kms:us-east-1:123456789012:key/*"
      }
    ]
  }'

# Attach to role/user
aws iam attach-role-policy \
  --role-name my-role \
  --policy-arn arn:aws:iam::123456789012:policy/sops-kms
```

---

## Azure Key Vault Integration

### Setup

```bash
# Create vault
az keyvault create \
  --name myvault \
  --resource-group mygroup \
  --location eastus

# Create key
az keyvault key create \
  --vault-name myvault \
  --name sops-key \
  --kty RSA-HSM \
  --size 2048

# Get key URI
az keyvault key show \
  --vault-name myvault \
  --name sops-key \
  --query key.kid
# Output: https://myvault.vault.azure.net/keys/sops-key/abc123
```

### Configuration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    azure_keyvault: "https://myvault.vault.azure.net/keys/sops-key/abc123"
```

### Multi-Key Setup

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    azure_keyvault: "https://vault1.vault.azure.net/keys/key1/abc123,https://vault2.vault.azure.net/keys/key2/def456"
```

### Managed Identity

```bash
# Enable managed identity
az vm identity assign --name myvm --resource-group mygroup

# Grant key vault access
az keyvault set-policy \
  --name myvault \
  --object-id <identity-principal-id> \
  --secret-permissions get list \
  --key-permissions encrypt decrypt get list
```

---

## GCP KMS Integration

### Setup

```bash
# Create key ring
gcloud kms keyrings create my-ring --location global

# Create key
gcloud kms keys create my-key \
  --keyring my-ring \
  --location global \
  --purpose encryption

# Get key resource name
gcloud kms keys describe my-key \
  --keyring my-ring \
  --location global
# Output: projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key
```

### Configuration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    gcp_kms: "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
```

### Service Account

```bash
# Create service account
gcloud iam service-accounts create sops \
  --display-name "SOPS encryption"

# Grant KMS role
gcloud kms keys add-iam-policy-binding my-key \
  --keyring my-ring \
  --location global \
  --member serviceAccount:sops@my-project.iam.gserviceaccount.com \
  --roles roles/cloudkms.cryptoKeyEncrypterDecrypter
```

---

## age Integration

### Setup

```bash
# Install age
# macOS
brew install age

# Linux
wget https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz
tar -xzf age-v1.1.1-linux-amd64.tar.gz
sudo mv age/age age/keygen /usr/local/bin/

# Generate key pair
age-keygen -o key.txt
# Public key: age1qyxyz...

# Or convert SSH key
ssh-to-age < ~/.ssh/id_ed25519.pub
# age1qyxyz...
```

### Configuration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    age: "age1qyxyz..."
```

### Multi-Key Setup

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    age: "age1qyxyz...,age1abc123..."
```

### age with SSH

```bash
# Convert SSH key to age
ssh-to-age < ~/.ssh/id_ed25519.pub > ~/.sops/age/keys.txt

# Use in .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    age: "age1qyxyz..."
```

---

## Kubernetes Integration

### Secret Encryption

```bash
# Encrypt Kubernetes Secret
kubectl get secret myapp-secret -n production -o yaml | \
  sops --encrypt --kms-arn arn:aws:kms:us-east-1:123456789012:key/abc123 \
  > sealed-secret.yaml
```

### Sealed Secrets Alternative

```yaml
# Instead of Sealed Secrets, use SOPS
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  namespace: production
type: Opaque
data:
  db_password: ENC[AES256_GCM,data:abc123...,type:str]
  api_key: ENC[AES256_GCM,data:def456...,type:str]
```

### Helm Integration

```bash
# Encrypt Helm values
sops --encrypt values.yaml > values.enc.yaml

# Deploy with decrypted values
sops --decrypt values.enc.yaml | helm install myapp ./chart -f -
```

### Kustomize Integration

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

secretGenerator:
  - name: myapp-secret
    namespace: production
    type: Opaque
    literals:
      - db_password=ENC[AES256_GCM,data:abc123...,type:str]
```

---

## GitOps Integration

### ArgoCD Integration

```yaml
# Application with SOPS
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myapp.git
    targetRevision: HEAD
    path: k8s/production
    # ArgoCD will decrypt SOPS-encrypted files
    plugin:
      name: sops
  destination:
    server: https://kubernetes.default.svc
    namespace: production
```

### FluxCD Integration

```yaml
# Kustomization with SOPS
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  path: ./k8s/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: myapp
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

### GitOps Workflow

```
1. Developer creates secret file
   │
   ▼
2. Developer encrypts with SOPS
   │
   ▼
3. Encrypted file committed to Git
   │
   ▼
4. GitOps tool syncs to cluster
   │
   ▼
5. GitOps tool decrypts with SOPS
   │
   ▼
6. Decrypted Secret applied to cluster
```

---

## Security Considerations

### Key Security

```bash
# Never commit private keys
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore

# Use KMS for key management
# Rotate keys regularly
sops --rotate secrets.enc.yaml
```

### Access Control

```bash
# AWS IAM policies
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/*"
    }
  ]
}
```

### Audit Logging

```bash
# Enable AWS CloudTrail
aws cloudtrail create-trail \
  --name sops-audit \
  --s3-bucket-name my-audit-bucket

# Enable logging
aws cloudtrail start-logging --name sops-audit
```

### Secret Zero

```bash
# Store SOPS keys externally
# Use Vault for key management
vault kv put secret/sops-keys \
  pgp-private=@private.key \
  kms-arn=arn:aws:kms:us-east-1:123456789012:key/abc123
```

---

## Troubleshooting (20+ Issues)

### Issue 1: SOPS Not Found

**Symptom**: `sops: command not found`

```bash
# Check installation
which sops

# Reinstall
wget -qO /tmp/sops \
  "https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64"
sudo install /tmp/sops /usr/local/bin/sops
```

### Issue 2: No Encryption Key Found

**Symptom**: `no encryption key found`

```bash
# Check .sops.yaml
cat .sops.yaml

# Verify key exists
gpg --list-keys
aws kms list-keys
```

### Issue 3: GPG Key Not Trusted

**Symptom**: `gpg: decryption failed: No secret key`

```bash
# Check key trust
gpg --list-keys --keyid-format long

# Import key
gpg --import private.key

# Trust key
gpg --edit-key FINGERPRINT trust
```

### Issue 4: KMS Access Denied

**Symptom**: `AccessDeniedException`

```bash
# Check IAM permissions
aws iam list-attached-user-policies --user-name <user>

# Test KMS access
aws kms encrypt --key-id <key-id> --plaintext "test"
```

### Issue 5: Azure Key Vault Access Denied

**Symptom**: `AuthorizationFailed`

```bash
# Check access policy
az keyvault show --name myvault --query properties.accessPolicies

# Grant access
az keyvault set-policy \
  --name myvault \
  --object-id <principal-id> \
  --key-permissions encrypt decrypt get list
```

### Issue 6: GCP KMS Access Denied

**Symptom**: `PermissionDenied`

```bash
# Check IAM bindings
gcloud kms keys get-iam-policy my-key \
  --keyring my-ring \
  --location global

# Grant access
gcloud kms keys add-iam-policy-binding my-key \
  --keyring my-ring \
  --location global \
  --member serviceAccount:<sa-email> \
  --roles roles/cloudkms.cryptoKeyEncrypterDecrypter
```

### Issue 7: age Key Not Found

**Symptom`: `age: no such identity`

```bash
# Check age key
cat key.txt

# Verify public key
age-keygen -o key.txt
# Output: age1qyxyz...

# Update .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    age: "age1qyxyz..."
```

### Issue 8: File Format Not Recognized

**Symptom`: `error loading file: unsupported file format`

```bash
# Check file extension
ls -la secrets.yaml

# Specify format
sops --encrypt --input-type yaml secrets.yaml

# Or use --output-type
sops --encrypt --output-type json secrets.yaml
```

### Issue 9: Encrypted Values Not Decrypting

**Symptom`: `error decrypting data: invalid key`

```bash
# Check key matches
cat secrets.enc.yaml | grep sops

# Re-encrypt with correct key
sops --encrypt --pgp "CORRECT_FINGERPRINT" secrets.yaml
```

### Issue 10: Git Diff Not Working

**Symptom`: git diff shows encrypted gibberish

```bash
# This is expected behavior
# SOPS encrypts values but leaves keys readable
# You can still see which keys changed

# For full diff, decrypt first
git diff --no-index <(sops --decrypt secrets.enc.yaml) secrets.yaml
```

### Issue 11: File Corruption

**Symptom`: `error loading file: malformed`

```bash
# Check file encoding
file secrets.enc.yaml

# Verify SOPS header
head -20 secrets.enc.yaml

# Re-encrypt
sops --encrypt secrets.yaml > secrets.enc.yaml.new
```

### Issue 12: Key Rotation Failed

**Symptom`: `error rotating key`

```bash
# Check current keys
cat secrets.enc.yaml | grep sops

# Rotate manually
sops --rotate --pgp "NEW_KEY" secrets.enc.yaml

# Or update .sops.yaml
sops --update-parent-config secrets.enc.yaml
```

### Issue 13: Multiple SOPS Versions

**Symptom`: `incompatible SOPS version`

```bash
# Check version
sops --version

# Update to latest
wget -qO /tmp/sops \
  "https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64"
sudo install /tmp/sops /usr/local/bin/sops
```

### Issue 14: ENV File Not Encrypting

**Symptom`: `error encrypting env file`

```bash
# Check file format
file secrets.env

# Specify input type
sops --encrypt --input-type env secrets.env

# Or rename to .env
mv secrets.env .env
sops --encrypt .env
```

### Issue 15: JSON File Not Encrypting

**Symptom`: `error encrypting json file`

```bash
# Check JSON syntax
python -m json.tool secrets.json

# Specify input type
sops --encrypt --input-type json secrets.json
```

### Issue 16: Binary File Not Encrypting

**Symptom`: `error encrypting binary file`

```bash
# Specify binary mode
sops --encrypt --binary secret.bin > secret.enc.bin

# Or use --input-type
sops --encrypt --input-type binary secret.bin
```

### Issue 17: Large File Performance

**Symptom`: SOPS slow on large files

```bash
# Use streaming encryption
sops --encrypt --stream large-file.yaml

# Or split file
split -l 1000 large-file.yaml large-file-part-
```

### Issue 18: CI/CD Pipeline Fails

**Symptom`: `error decrypting in CI/CD`

```bash
# Ensure keys available in CI/CD
export SOPS_AGE_KEY_FILE=/path/to/key.txt

# Or use KMS
export AWS_ACCESS_KEY_ID=<access-key>
export AWS_SECRET_ACCESS_KEY=<secret-key>
```

### Issue 19: Docker Build Fails

**Symptom`: `error decrypting in Dockerfile`

```bash
# Copy keys to build context
COPY keys.txt /root/.sops/age/keys.txt

# Decrypt before build
sops --decrypt secrets.enc.yaml > secrets.yaml
docker build --build-arg SECRETS=secrets.yaml .
```

### Issue 20: Kubernetes Secret Not Created

**Symptom`: `error creating secret from SOPS`

```bash
# Decrypt first
sops --decrypt secrets.enc.yaml > secrets.yaml

# Apply
kubectl apply -f secrets.yaml
```

### Issue 21: Helm Values Not Decrypting

**Symptom`: `error decrypting Helm values`

```bash
# Decrypt values file
sops --decrypt values.enc.yaml > values.yaml

# Install with decrypted values
helm install myapp ./chart -f values.yaml
```

### Issue 22: Terraform Values Not Decrypting

**Symptom`: `error decrypting tfvars`

```bash
# Decrypt tfvars
sops --decrypt secrets.enc.tfvars > secrets.tfvars

# Use in Terraform
terraform apply -var-file=secrets.tfvars
```

---

## Tips & Best Practices (20+ Tips)

### Tip 1: Use Multiple Key Types

Combine PGP and KMS for redundancy:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    pgp: "FINGERPRINT"
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
```

### Tip 2: Rotate Keys Regularly

```bash
# Rotate PGP key
sops --rotate --pgp "NEW_FINGERPRINT" secrets.enc.yaml

# Rotate KMS key
sops --rotate --kms "arn:aws:kms:us-east-1:123456789012:key/new-key" secrets.enc.yaml
```

### Tip 3: Use .sops.yaml in Repo Root

Place `.sops.yaml` in repository root for consistent configuration.

### Tip 4: Use Git Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Auto-encrypt .yaml files
for file in $(git diff --cached --name-only | grep '\.yaml$'); do
  if [[ ! -f "$file.enc.yaml" ]]; then
    sops --encrypt "$file" > "$file.enc.yaml"
    git add "$file.enc.yaml"
  fi
done
```

### Tip 5: Use Environment-Specific Rules

```yaml
# .sops.yaml
creation_rules:
  - path_regex: production/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/prod-key"

  - path_regex: staging/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/staging-key"
```

### Tip 6: Use Encrypted File Extension

```bash
# Use .enc.yaml extension
sops --encrypt secrets.yaml > secrets.enc.yaml

# Clear in .gitignore
git add -f secrets.enc.yaml
```

### Tip 7: Use KMS for Production

Use AWS KMS, Azure Key Vault, or GCP KMS for production:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: production/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/prod-key"
```

### Tip 8: Use age for Development

age is simpler for development:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: development/.*\.yaml$
    age: "age1qyxyz..."
```

### Tip 9: Use kubeseal Alternative

Use SOPS instead of Sealed Secrets for simpler workflow:

```bash
# Instead of kubeseal
kubectl get secret myapp-secret -o yaml | sops --encrypt > sealed-secret.yaml
```

### Tip 10: Use SOPS for Helm Values

```bash
# Encrypt Helm values
sops --encrypt values.yaml > values.enc.yaml

# Deploy
sops --decrypt values.enc.yaml | helm install myapp ./chart -f -
```

### Tip 11: Use SOPS for Terraform Variables

```bash
# Encrypt tfvars
sops --encrypt secrets.tfvars > secrets.enc.tfvars

# Use in Terraform
terraform apply -var-file=<(sops --decrypt secrets.enc.tfvars)
```

### Tip 12: Use SOPS for Ansible

```bash
# Encrypt Ansible vars
sops --encrypt vars/secrets.yaml > vars/secrets.enc.yaml

# Decrypt at runtime
sops --decrypt vars/secrets.enc.yaml | ansible-playbook -e @- playbook.yml
```

### Tip 13: Use SOPS for Docker Compose

```bash
# Encrypt docker-compose secrets
sops --encrypt docker-compose.yaml > docker-compose.enc.yaml

# Decrypt and run
sops --decrypt docker-compose.enc.yaml | docker-compose -f - up
```

### Tip 14: Use SOPS for Kubernetes Secrets

```bash
# Encrypt Kubernetes Secret
kubectl get secret myapp-secret -o yaml | sops --encrypt > sealed-secret.yaml

# Decrypt and apply
sops --decrypt sealed-secret.yaml | kubectl apply -f -
```

### Tip 15: Use SOPS for CI/CD

```bash
# In CI/CD pipeline
sops --decrypt secrets.enc.yaml > secrets.yaml

# Use secrets
export DB_PASSWORD=$(yq -r '.db_password' secrets.yaml)
```

### Tip 16: Use SOPS for Local Development

```bash
# Local development
sops --decrypt secrets.enc.yaml > secrets.yaml

# Load into environment
export $(grep -v '^#' secrets.yaml | xargs)
```

### Tip 17: Use SOPS for Backup

```bash
# Encrypt backup
tar -czf backup.tar.gz /path/to/data
sops --encrypt backup.tar.gz > backup.enc.tar.gz

# Decrypt backup
sops --decrypt backup.enc.tar.gz | tar -xzf -
```

### Tip 18: Use SOPS for Migration

```bash
# Migrate from Ansible Vault
ansible-vault decrypt secrets.yaml
sops --encrypt secrets.yaml > secrets.enc.yaml
```

### Tip 19: Use SOPS for Compliance

```bash
# Audit encrypted files
find . -name "*.enc.yaml" -exec sops --decrypt {} \; | jq .

# Check key usage
cat secrets.enc.yaml | grep sops
```

### Tip 20: Use SOPS for Team Collaboration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.yaml$
    pgp: "KEY1,KEY2,KEY3"
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
```

### Tip 21: Use SOPS for Disaster Recovery

```bash
# Backup keys
gpg --export-secret-keys > private-keys.asc
aws kms create-alias --alias-name alias/sops-backup --target-key-id <new-key-id>

# Re-encrypt with backup key
sops --rotate --kms "arn:aws:kms:us-east-1:123456789012:key/backup-key" secrets.enc.yaml
```

### Tip 22: Use SOPS for Multi-Cloud

```yaml
# .sops.yaml
creation_rules:
  - path_regex: aws/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"

  - path_regex: azure/.*\.yaml$
    azure_keyvault: "https://myvault.vault.azure.net/keys/mykey/abc123"

  - path_regex: gcp/.*\.yaml$
    gcp_kms: "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
```

---

## Command Reference

### Encryption

```bash
sops --encrypt <file>                    # Encrypt file
sops --encrypt --in-place <file>         # Encrypt in place
sops --encrypt --output <file> <input>   # Encrypt to output
sops --encrypt --binary <file>           # Encrypt as binary
```

### Decryption

```bash
sops --decrypt <file>                    # Decrypt file
sops --decrypt --in-place <file>         # Decrypt in place
sops --decrypt --output <file> <input>   # Decrypt to output
sops --decrypt --binary <file>           # Decrypt as binary
```

### Key Management

```bash
sops --rotate <file>                     # Rotate keys
sops --rotate --pgp "KEY" <file>         # Rotate to PGP key
sops --rotate --kms "ARN" <file>         # Rotate to KMS key
sops --update-parent-config <file>       # Update parent config
```

### File Operations

```bash
sops --extract '["key"]' <file>          # Extract value
sops --set '["key"]' "value" <file>      # Set value
sops --dump <file>                       # Dump encrypted file
sops --dump --input-type json <file>     # Dump as JSON
```

### Configuration

```bash
sops --config <path>                     # Use specific config
sops --kms <arn>                         # Use specific KMS
sops --pgp <fingerprint>                 # Use specific PGP key
sops --age <pubkey>                      # Use specific age key
sops --azure-keyvault <url>              # Use specific Azure Key Vault
sops --gcp-kms <resource>                # Use specific GCP KMS
```

### Input/Output

```bash
sops --input-type <type>                 # Input type (yaml, json, env, ini, binary)
sops --output-type <type>                # Output type (yaml, json, env, ini, binary)
sops --output <file>                     # Output file
```

### Other

```bash
sops --version                           # Version
sops --help                              # Help
sops --verify <file>                     # Verify file
sops --find <file>                       # Find encrypted values
```

---

## Configuration Reference (Full)

### .sops.yaml Complete

```yaml
# Global configuration
creation_rules:
  # Rule 1: YAML files with PGP
  - path_regex: \.yaml$
    pgp: "FINGERPRINT1,FINGERPRINT2"
    kms: "arn:aws:kms:us-east-1:123456789012:key/abc123"
    azure_keyvault: "https://myvault.vault.azure.net/keys/mykey/abc123"
    gcp_kms: "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key"
    age: "age1qyxyz..."
    unencrypted_suffix: "_unencrypted"
    encrypted_suffix: "_encrypted"
    exclude: "template/.*"

  # Rule 2: JSON files
  - path_regex: \.json$
    kms: "arn:aws:kms:us-east-1:123456789012:key/def456"

  # Rule 3: ENV files
  - path_regex: \.env$
    kms: "arn:aws:kms:us-east-1:123456789012:key/ghi789"

  # Rule 4: Environment-specific
  - path_regex: production/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/prod-key"

  # Rule 5: Team-specific
  - path_regex: team-a/.*\.yaml$
    kms: "arn:aws:kms:us-east-1:123456789012:key/team-a-key"

# Shred configuration
shred: true
shred_iterations: 10
```

### Environment Variables

```bash
# SOPS configuration
SOPS_AGE_KEY_FILE=/path/to/key.txt
SOPS_KMS_ARN=arn:aws:kms:us-east-1:123456789012:key/abc123
SOPS_PGP_FP=FINGERPRINT1,FINGERPRINT2
SOPS_AZURE_KEYVAULT_URL=https://myvault.vault.azure.net
SOPS_GCP_KMS_RESOURCE=projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key

# AWS configuration
AWS_ACCESS_KEY_ID=<access-key>
AWS_SECRET_ACCESS_KEY=<secret-key>
AWS_DEFAULT_REGION=us-east-1

# Azure configuration
AZURE_CLIENT_ID=<client-id>
AZURE_CLIENT_SECRET=<client-secret>
AZURE_TENANT_ID=<tenant-id>

# GCP configuration
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

---

## Real-World Examples — Our Cluster

### Example 1: K3s Cluster with SOPS

```bash
# Install SOPS
wget -qO /tmp/sops \
  "https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64"
sudo install /tmp/sops /usr/local/bin/sops

# Generate age key
age-keygen -o /root/.sops/age/keys.txt
# Public key: age1qyxyz...

# Create .sops.yaml
cat > .sops.yaml << 'EOF'
creation_rules:
  - path_regex: \.yaml$
    age: "age1qyxyz..."
EOF

# Create secret
cat > secrets.yaml << 'EOF'
db_password: mypassword
api_key: abc123
redis_password: redispass
EOF

# Encrypt
sops --encrypt secrets.yaml > secrets.enc.yaml

# Verify
cat secrets.enc.yaml
# db_password: ENC[AES256_GCM,data:abc123...,type:str]
# api_key: ENC[AES256_GCM,data:def456...,type:str]
# sops:
#     age:
#         - created_at: "2024-01-15T10:30:00Z"
#           enc: abc123...
#     lastmodified: "2024-01-15T10:30:00Z"
#     version: 3.8.1

# Commit
git add secrets.enc.yaml .sops.yaml
git commit -m "Add encrypted secrets"
git push

# Decrypt at runtime
sops --decrypt secrets.enc.yaml > secrets.yaml
```

### Example 2: Application Deployment

```yaml
# deployment.yaml
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
    spec:
      containers:
        - name: myapp
          image: myapp:latest
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: myapp-secret
                  key: db_password
            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: myapp-secret
                  key: api_key
---
# secret.yaml (encrypted)
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  namespace: production
type: Opaque
data:
  db_password: ENC[AES256_GCM,data:abc123...,type:str]
  api_key: ENC[AES256_GCM,data:def456...,type:str]
sops:
    age:
        - created_at: "2024-01-15T10:30:00Z"
          enc: abc123...
    lastmodified: "2024-01-15T10:30:00Z"
    version: 3.8.1
```

### Example 3: Helm Values

```bash
# Encrypt Helm values
sops --encrypt values.yaml > values.enc.yaml

# Deploy with decrypted values
sops --decrypt values.enc.yaml | helm install myapp ./chart -f -
```

### Example 4: Terraform Variables

```bash
# Encrypt tfvars
sops --encrypt secrets.tfvars > secrets.enc.tfvars

# Use in Terraform
terraform apply -var-file=<(sops --decrypt secrets.enc.tfvars)
```

### Example 5: GitOps with FluxCD

```yaml
# kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  path: ./k8s/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: myapp
  decryption:
    provider: sops
    secretRef:
      name: sops-age
---
# sops-age secret
apiVersion: v1
kind: Secret
metadata:
  name: sops-age
  namespace: flux-system
type: Opaque
data:
  age.agekey: <base64-encoded-age-key>
```

---

## Further Reading

### Official Documentation
- [SOPS Documentation](https://github.com/getsops/sops)
- [SOPS CLI Reference](https://github.com/getsops/sops/blob/main/README.rst)
- [SOPS Configuration](https://github.com/getsops/sops/blob/main/README.rst#configuration)

### Tutorials
- [Getting Started with SOPS](https://github.com/getsops/sops/blob/main/README.rst#getting-started)
- [SOPS with AWS KMS](https://github.com/getsops/sops/blob/main/README.rst#aws-kms)
- [SOPS with Azure Key Vault](https://github.com/getsops/sops/blob/main/README.rst#azure-key-vault)
- [SOPS with GCP KMS](https://github.com/getsops/sops/blob/main/README.rst#gcp-kms)
- [SOPS with age](https://github.com/getsops/sops/blob/main/README.rst#age)

### Community
- [SOPS GitHub](https://github.com/getsops/sops)
- [SOPS Issues](https://github.com/getsops/sops/issues)

### Related Guides
- [HashiCorp Vault Complete Guide](vault.md)
- [Vault Agent Complete Guide](vault-agent.md)
- [Vault Dynamic Secrets](vault-dynamic-secrets.md)
- [Sealed Secrets](sealed-secrets.md)

---

*Last Updated: 2026*
*Version: 3.8.1*
*Author: OpenWolf DevOps Guide*
