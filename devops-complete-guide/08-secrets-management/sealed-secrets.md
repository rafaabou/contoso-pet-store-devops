# Sealed Secrets Complete Guide

## Table of Contents

1. [What Are Sealed Secrets](#what-are-sealed-secrets)
2. [Why Use Sealed Secrets — Real Breaches](#why-use-sealed-secrets--real-breaches)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Kubeseal CLI](#kubeseal-cli)
7. [Controller Configuration](#controller-configuration)
8. [Usage Guide — Step by Step](#usage-guide--step-by-step)
9. [Sealed Secret CRD](#sealed-secret-crd)
10. [Scope Modes](#scope-modes)
11. [Encryption & Decryption](#encryption--decryption)
12. [Key Management](#key-management)
13. [Integration with GitOps](#integration-with-gitops)
14. [Security Considerations](#security-considerations)
15. [Troubleshooting (20+ Issues)](#troubleshooting-20-issues)
16. [Tips & Best Practices (20+ Tips)](#tips--best-practices-20-tips)
17. [Command Reference](#command-reference)
18. [Configuration Reference](#configuration-reference)
19. [Real-World Examples — Our Cluster](#real-world-examples--our-cluster)
20. [Further Reading](#further-reading)

---

## What Are Sealed Secrets

Sealed Secrets is a Kubernetes controller and tool for one-way encrypted Secrets. It allows you to store encrypted Secret manifests in Git (or any version control), knowing that only the controller in your cluster can decrypt them.

### How It Works

1. **You encrypt** a Kubernetes Secret using `kubeseal` (client-side)
2. **You commit** the encrypted SealedSecret to Git
3. **The controller** in your cluster decrypts it using its private key
4. **A regular Secret** is created in your namespace
5. **Your pods** can mount/use the Secret normally

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│              │     │              │     │              │
│  Developer   │────▶│  Git Repo    │     │  K8s         │
│              │     │              │     │  Cluster     │
│  kubeseal    │     │  Stores      │     │              │
│  encrypts    │     │  encrypted   │     │  Controller  │
│              │     │  secrets     │     │  decrypts    │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
                                                ▼
                                         ┌──────────────┐
                                         │              │
                                         │  Regular     │
                                         │  K8s Secret  │
                                         │  created     │
                                         └──────────────┘
```

### Key Features

| Feature | Description |
|---------|-------------|
| **One-way encryption** | Can encrypt, cannot decrypt (client-side) |
| **Git-safe** | Encrypted secrets can be stored in Git |
| **Namespace isolation** | Secrets only decryptable in target namespace |
| **Cluster isolation** | Secrets only decryptable in target cluster |
| **Key rotation** | Automatic key rotation with backup |
| **No external dependencies** | Self-contained controller |

### What Sealed Secrets Is NOT

- **Not a replacement for Vault** — No dynamic secrets, no audit trail
- **Not a secrets manager** — Just encrypted Kubernetes Secrets
- **Not for all use cases** — Best for GitOps workflows
- **Not zero-trust** — Controller has full access to decrypt

---

## Why Use Sealed Secrets — Real Breaches

### The Problem Sealed Secrets Solve

Kubernetes Secrets are base64 encoded, not encrypted. Storing them in Git is insecure:

```yaml
# This is NOT secure (just base64)
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
data:
  password: cGFzc3dvcmQ=  # base64("password")
```

### Real-World Breaches

#### 1. GitOps Secret Exposure
- **Problem**: Teams store Secrets in Git for GitOps workflows
- **Impact**: Anyone with repo access sees all secrets
- **Sealed Secrets fix**: Secrets encrypted before Git commit

#### 2. Accidental Secret Commits
- **Problem**: Developer accidentally commits Secret YAML
- **Impact**: Secret exposed in Git history
- **Sealed Secrets fix**: Encrypted SealedSecret is safe to commit

#### 3. Cross-Team Secret Access
- **Problem**: Shared Git repo exposes secrets across teams
- **Impact**: Team A sees Team B's secrets
- **Sealed Secrets fix**: Namespace-scoped encryption

#### 4. CI/CD Pipeline Exposure
- **Problem**: CI/CD systems log Secret values
- **Impact**: Secrets in CI/CD logs
- **Sealed Secrets fix**: Encrypted secrets don't expose values

#### 5. Repository Backup Exposure
- **Problem**: Git repo backed up to insecure location
- **Impact**: Secrets in backups
- **Sealed Secrets fix**: Encrypted secrets in backups are safe

### Business Case

| Metric | Regular Secrets | Sealed Secrets |
|--------|----------------|----------------|
| **Git safety** | Unsafe | Safe |
| **Access control** | Repo-based | Namespace/Cluster-based |
| **Audit trail** | Limited | Git history |
| **Rollback** | Manual | Git revert |
| **Compliance** | Difficult | Built-in |

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Sealed Secrets Controller          │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Watcher │  │  Decrypt │  │  Secret  │     │   │
│  │  │  (CRD)   │  │  Engine  │  │  Creator │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Key     │  │  Key     │  │  Key     │     │   │
│  │  │  Store   │  │  Rotator │  │  Backup  │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              SealedSecret CRD                    │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Encrypted│  │  Scope   │  │  Metadata│     │   │
│  │  │  Data     │  │  Info    │  │          │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Regular Secret                      │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Decrypted│  │  Mounted │  │  Used by │     │   │
│  │  │  Data     │  │  by Pods │  │  Apps    │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Request Flow

```
1. Developer runs kubeseal
   │
   ▼
2. kubeseal fetches controller's public key
   │
   ▼
3. kubeseal encrypts Secret → SealedSecret
   │
   ▼
4. SealedSecret committed to Git
   │
   ▼
5. Controller watches for SealedSecrets
   │
   ▼
6. Controller decrypts using private key
   │
   ▼
7. Regular Secret created in namespace
   │
   ▼
8. Pods can mount/use Secret
```

### Key Management

```
┌─────────────────────────────────────────────────────────┐
│                    Key Management                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Key Prefix                          │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Current │  │  Previous│  │  Next    │     │   │
│  │  │  Key     │  │  Key     │  │  Key     │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Used for encryption: Current                   │   │
│  │  Used for decryption: All                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Key Rotation                        │   │
│  │                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │   │
│  │  │  Generate │  │  Update  │  │  Backup  │     │   │
│  │  │  New Key  │  │  Secrets │  │  Old Key │     │   │
│  │  └──────────┘  └──────────┘  └──────────┘     │   │
│  │                                                 │   │
│  │  Automatic rotation with configurable period    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Installation

### Method 1: Helm Chart (Recommended)

```bash
# Add Helm repo
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

# Install
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --set fullnameOverride=sealed-secrets-controller

# Install with custom settings
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --set fullnameOverride=sealed-secrets-controller \
  --set secretName=sealed-secrets-key \
  --set secretAnnotations."sealedsecrets\.bitnami\.com/managed=true"
```

### Method 2: kubectl Apply

```bash
# Download latest release
KUBE_SEALED_SECRETS_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r '.tag_name')

# Apply controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBE_SEALED_SECRETS_VERSION}/controller.yaml

# Apply CRD
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBE_SEALED_SECRETS_VERSION}/crd.yaml
```

### Method 3: kubeseal CLI

```bash
# Download kubeseal
KUBE_SEALED_SECRETS_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r '.tag_name')
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBE_SEALED_SECRETS_VERSION}/kubeseal-${KUBE_SEALED_SECRETS_VERSION}-linux-amd64.tar.gz

# Extract
tar -xzf kubeseal-${KUBE_SEALED_SECRETS_VERSION}-linux-amd64.tar.gz
sudo mv kubeseal-${KUBE_SEALED_SECRETS_VERSION}-linux-amd64 /usr/local/bin/kubeseal

# Verify
kubeseal --version
```

### Method 4: Kustomize

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
  - https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/crd.yaml

namespace: kube-system

patches:
  - target:
      kind: Deployment
      name: sealed-secrets-controller
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
```

### Method 5: K3s Specific

```bash
# On k3s-master
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: sealed-secrets
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: sealed-secrets
spec:
  chart:
    spec:
      chart: sealed-secrets
      version: "0.24.0"
      sourceRef:
        kind: HelmRepository
        name: bitnami-labs
  values:
    fullnameOverride: sealed-secrets-controller
    secretName: sealed-secrets-key
    secretAnnotations:
      "sealedsecrets.bitnami.com/managed": "true"
EOF
```

---

## Core Concepts

### SealedSecret CRD

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  encryptedData:
    db_password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
    api_key: AgCa4l3hFKsk2h8djk23hJHsdkf23hJH...
  template:
    metadata:
      name: myapp-secret
      namespace: production
      labels:
        app: myapp
    type: Opaque
```

### Scope Modes

#### Namespace Scope (Default)

```bash
# Encrypt for specific namespace
kubeseal --scope namespace --namespace production
```

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

#### Cluster-Wide Scope

```bash
# Encrypt for entire cluster
kubeseal --scope cluster
```

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

#### Strict Scope

```bash
# Encrypt for specific namespace AND name
kubeseal --scope strict --namespace production --name myapp-secret
```

### Encryption Algorithms

| Algorithm | Description |
|-----------|-------------|
| **RSA-OAEP** | RSA with OAEP padding (default) |
| **RSA-PKCS1v15** | RSA with PKCS1v15 padding |
| **AES-GCM** | AES in Galois/Counter Mode |
| **AES-CBC** | AES in Cipher Block Chaining |

### Key Types

| Key Type | Description |
|----------|-------------|
| **RSA** | RSA key pair (default) |
| **ECDSA** | Elliptic Curve Digital Signature Algorithm |
| **ED25519** | Edwards-curve Digital Signature Algorithm |

---

## Kubeseal CLI

### Basic Usage

```bash
# Encrypt a Secret
kubectl get secret myapp-secret -o yaml | kubeseal > sealed-secret.yaml

# Encrypt from file
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Encrypt from command line
echo -n "my-password" | kubeseal --raw --from-file=/dev/stdin --name myapp-secret --namespace production
```

### Command Line Options

```bash
# Format
kubeseal --format yaml          # YAML (default)
kubeseal --format json          # JSON

# Scope
kubeseal --scope namespace     # Namespace scope (default)
kubeseal --scope cluster       # Cluster-wide scope
kubeseal --scope strict        # Strict scope (namespace + name)

# Namespace
kubeseal --namespace production

# Name
kubeseal --name myapp-secret

# Secret Name
kubeseal --secret-name myapp-secret

# Controller Name
kubeseal --controller-name sealed-secrets-controller

# Controller Namespace
kubeseal --controller-namespace kube-system

# Re-encrypt
kubeseal --re-encrypt          # Re-encrypt with latest key

# Validate
kubeseal --validate            # Validate SealedSecret

# Print
kubeseal --print-renewal       # Print key renewal info
```

### Advanced Usage

```bash
# Encrypt with specific key
kubeseal --key /path/to/key.pem

# Encrypt from stdin
echo -n "password" | kubeseal --raw --from-file=/dev/stdin

# Encrypt from file
kubeseal --from-file=password.txt --name myapp-secret --namespace production

# Encrypt multiple values
kubectl create secret generic myapp-secret \
  --from-literal=db_password=abc123 \
  --from-literal=api_key=xyz789 \
  -o yaml | kubeseal > sealed-secret.yaml

# Encrypt with annotations
kubectl get secret myapp-secret -o yaml | \
  kubeseal --annotation "sealedsecrets.bitnami.com/managed=true" > sealed-secret.yaml

# Encrypt with labels
kubectl get secret myapp-secret -o yaml | \
  kubeseal --label "app=myapp" > sealed-secret.yaml
```

### Converting Existing Secrets

```bash
# Convert existing Secret to SealedSecret
kubectl get secret myapp-secret -o yaml | \
  kubeseal --format yaml > sealed-secret.yaml

# Convert SealedSecret back to Secret (requires controller access)
kubectl get sealedsecret myapp-secret -o yaml | \
  kubeseal --re-encrypt --format yaml > new-sealed-secret.yaml
```

---

## Controller Configuration

### Controller Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: sealed-secrets
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sealed-secrets
    spec:
      containers:
        - name: sealed-secrets
          image: bitnami/sealed-secrets:0.24.0
          args:
            - --key-prefix=sealed-secrets
            - --key-min-days=7
            - --key-rotate
            - --key-rotate-period=30d
          ports:
            - containerPort: 8080
              name: http
          volumeMounts:
            - name: keys
              mountPath: /tmp/sealed-secrets
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
      volumes:
        - name: keys
          persistentVolumeClaim:
            claimName: sealed-secrets-keys
```

### Controller Flags

```bash
# Key management
--key-prefix=<prefix>          # Key prefix (default: sealed-secrets)
--key-min-days=<days>          # Minimum days before key rotation
--key-rotate                   # Enable key rotation
--key-rotate-period=<period>   # Key rotation period

# Encryption
--key-name=<name>              # Specific key name
--key-type=<type>              # Key type (rsa, ecdsa, ed25519)

# Validation
--validate                     # Validate SealedSecrets
--strict-validation            # Strict validation mode

# Logging
--log-level=<level>            # Log level (debug, info, warn, error)
--log-format=<format>          # Log format (json, text)
```

### Controller Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  ports:
    - port: 8080
      targetPort: 8080
      name: http
  selector:
    app.kubernetes.io/name: sealed-secrets
```

### Controller RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sealed-secrets-controller
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["bitnami.com"]
    resources: ["sealedsecrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sealed-secrets-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sealed-secrets-controller
subjects:
  - kind: ServiceAccount
    name: sealed-secrets-controller
    namespace: kube-system
```

---

## Usage Guide — Step by Step

### Step 1: Install Controller

```bash
# Install via Helm
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --set fullnameOverride=sealed-secrets-controller

# Verify installation
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

### Step 2: Install kubeseal CLI

```bash
# Download kubeseal
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo mv kubeseal-0.24.0-linux-amd64 /usr/local/bin/kubeseal

# Verify
kubeseal --version
```

### Step 3: Create Secret

```bash
# Create Secret
kubectl create secret generic myapp-secret \
  --namespace production \
  --from-literal=db_password=abc123 \
  --from-literal=api_key=xyz789 \
  --dry-run=client -o yaml > secret.yaml
```

### Step 4: Encrypt Secret

```bash
# Encrypt to SealedSecret
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --namespace production > sealed-secret.yaml
```

### Step 5: Commit to Git

```bash
# Remove plain Secret
rm secret.yaml

# Commit SealedSecret
git add sealed-secret.yaml
git commit -m "Add encrypted myapp-secret"
git push
```

### Step 6: Apply SealedSecret

```bash
# Apply SealedSecret
kubectl apply -f sealed-secret.yaml

# Verify Secret created
kubectl get secret myapp-secret -n production
```

### Step 7: Use Secret

```yaml
# Pod using the Secret
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  namespace: production
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
```

### Step 8: Verify

```bash
# Check SealedSecret
kubectl get sealedsecret myapp-secret -n production

# Check Secret
kubectl get secret myapp-secret -n production

# Check Secret values
kubectl get secret myapp-secret -n production -o jsonpath='{.data.db_password}' | base64 -d
```

---

## Sealed Secret CRD

### Full CRD Spec

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
  labels:
    app: myapp
  annotations:
    sealedsecrets.bitnami.com/managed: "true"
spec:
  encryptedData:
    db_password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
    api_key: AgCa4l3hFKsk2h8djk23hJHsdkf23hJH...
  template:
    metadata:
      name: myapp-secret
      namespace: production
      labels:
        app: myapp
        env: production
      annotations:
        description: "Myapp database credentials"
    type: Opaque
```

### EncryptedData Field

```yaml
spec:
  encryptedData:
    # Key-value pairs (encrypted)
    db_password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
    api_key: AgCa4l3hFKsk2h8djk23hJHsdkf23hJH...
    
    # Or from file
    tls.crt: AgBBS3i4OJSWK+PiTySYZZA9rO43cGDEq...
    tls.key: AgBBS3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

### Template Field

```yaml
spec:
  template:
    metadata:
      name: myapp-secret
      namespace: production
      labels:
        app: myapp
      annotations:
        description: "Secret description"
    type: Opaque
```

### Status Field

```yaml
status:
  conditions:
    - type: Synced
      status: "True"
      lastTransitionTime: "2024-01-15T10:30:00Z"
  observedGeneration: 1
```

---

## Scope Modes

### Namespace Scope

```bash
# Encrypt for specific namespace
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --scope namespace --namespace production > sealed-secret.yaml
```

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

### Cluster-Wide Scope

```bash
# Encrypt for entire cluster
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --scope cluster > sealed-secret.yaml
```

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

### Strict Scope

```bash
# Encrypt for specific namespace AND name
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --scope strict --namespace production --name myapp-secret > sealed-secret.yaml
```

### Scope Comparison

| Scope | Namespace | Name | Use Case |
|-------|-----------|------|----------|
| **Namespace** | ✓ | ✗ | Most common |
| **Cluster** | ✗ | ✗ | Cross-namespace |
| **Strict** | ✓ | ✓ | Maximum security |

---

## Encryption & Decryption

### Encryption Process

```
1. kubeseal fetches controller's public key
   │
   ▼
2. Secret data is serialized
   │
   ▼
3. Serialized data is encrypted with public key
   │
   ▼
4. Encrypted data is base64 encoded
   │
   ▼
5. SealedSecret manifest is created
```

### Decryption Process

```
1. Controller watches for SealedSecrets
   │
   ▼
2. Controller decrypts using private key
   │
   ▼
3. Decrypted data is deserialized
   │
   ▼
4. Regular Secret is created
   │
   ▼
5. Pods can mount/use Secret
```

### Encryption Algorithms

```bash
# RSA-OAEP (default)
kubeseal --encryption-algorithm RSA-OAEP

# RSA-PKCS1v15
kubeseal --encryption-algorithm RSA-PKCS1v15

# AES-GCM
kubeseal --encryption-algorithm AES-GCM
```

### Key Exchange

```
┌──────────────┐     ┌──────────────┐
│              │     │              │
│  kubeseal    │     │  Controller  │
│              │     │              │
│  1. Fetch    │◀────│  Public Key  │
│     public   │     │  (exposed)   │
│     key      │     │              │
│              │     │              │
│  2. Encrypt  │     │              │
│     Secret   │     │              │
│              │     │              │
│  3. Return   │────▶│              │
│     Sealed   │     │  4. Decrypt  │
│     Secret   │     │     using    │
│              │     │     private  │
└──────────────┘     │     key      │
                     └──────────────┘
```

---

## Key Management

### Key Storage

```yaml
# Secret storing encryption keys
apiVersion: v1
kind: Secret
metadata:
  name: sealed-secrets-key
  namespace: kube-system
  annotations:
    sealedsecrets.bitnami.com/managed: "true"
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

### Key Rotation

```bash
# Check current keys
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# Force key rotation
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# Controller will generate new key
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets -w
```

### Key Backup

```bash
# Backup keys
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml

# Restore keys
kubectl apply -f sealed-secrets-key-backup.yaml
```

### Key Prefix

```bash
# Default prefix
--key-prefix=sealed-secrets

# Custom prefix
--key-prefix=my-sealed-secrets
```

---

## Integration with GitOps

### ArgoCD Integration

```yaml
# Application with SealedSecrets
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
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### FluxCD Integration

```yaml
# Kustomization with SealedSecrets
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
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: myapp
      namespace: production
```

### GitOps Workflow

```
1. Developer creates Secret
   │
   ▼
2. Developer encrypts with kubeseal
   │
   ▼
3. SealedSecret committed to Git
   │
   ▼
4. GitOps tool syncs to cluster
   │
   ▼
5. Controller decrypts SealedSecret
   │
   ▼
6. Regular Secret created
   │
   ▼
7. Pods use Secret
```

### Git Structure

```
myapp/
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── production/
│   │   ├── sealed-secret.yaml
│   │   ├── kustomization.yaml
│   │   └── patches/
│   └── staging/
│       ├── sealed-secret.yaml
│       ├── kustomization.yaml
│       └── patches/
└── src/
    └── ...
```

---

## Security Considerations

### Access Control

```yaml
# RBAC for SealedSecrets
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sealed-secrets-admin
rules:
  - apiGroups: ["bitnami.com"]
    resources: ["sealedsecrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sealed-secrets-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sealed-secrets-admin
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: sealed-secrets
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from: []
      ports:
        - port: 8080
  egress:
    - to: []
      ports:
        - port: 443
```

### Audit Logging

```yaml
# Enable audit logging
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sealed-secrets-controller
spec:
  template:
    spec:
      containers:
        - name: sealed-secrets
          args:
            - --log-level=info
            - --log-format=json
```

### Secret Zero

```bash
# Don't store controller private key in Git
# Use external secret management for controller key

# Example: Use Vault for controller key
kubectl create secret generic sealed-secrets-key \
  --namespace kube-system \
  --from-file=tls.crt=vault-crt.pem \
  --from-file=tls.key=vault-key.pem
```

---

## Troubleshooting (20+ Issues)

### Issue 1: Controller Not Running

**Symptom**: No SealedSecrets decrypted

```bash
# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check controller events
kubectl get events -n kube-system | grep sealed-secrets
```

### Issue 2: SealedSecret Not Decrypted

**Symptom**: SealedSecret exists but no Secret created

```bash
# Check SealedSecret status
kubectl get sealedsecret myapp-secret -n production -o yaml

# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check events
kubectl get events -n production | grep myapp-secret
```

### Issue 3: Wrong Namespace

**Symptom**: Secret created in wrong namespace

```bash
# Check SealedSecret namespace
kubectl get sealedsecret myapp-secret -n production -o yaml | grep namespace

# Re-encrypt for correct namespace
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --namespace production > sealed-secret.yaml
```

### Issue 4: Key Mismatch

**Symptom**: `no key found` error

```bash
# Check controller keys
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# Force key regeneration
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# Re-encrypt secrets
kubeseal --re-encrypt < old-sealed-secret.yaml > new-sealed-secret.yaml
```

### Issue 5: kubeseal Cannot Connect

**Symptom**: `connection refused` error

```bash
# Check controller service
kubectl get svc -n kube-system sealed-secrets-controller

# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Test connectivity
kubectl port-forward -n kube-system svc/sealed-secrets-controller 8080:8080
curl http://localhost:8080/v1/secret
```

### Issue 6: Secret Not Mounted

**Symptom**: Pod cannot access Secret

```bash
# Check Secret exists
kubectl get secret myapp-secret -n production

# Check Pod events
kubectl describe pod myapp-pod -n production

# Check Secret contents
kubectl get secret myapp-secret -n production -o json
```

### Issue 7: Invalid SealedSecret

**Symptom**: `invalid sealed secret` error

```bash
# Validate SealedSecret
kubectl get sealedsecret myapp-secret -n production -o yaml | kubeseal --validate

# Check YAML syntax
kubectl apply -f sealed-secret.yaml --dry-run=client
```

### Issue 8: Controller Crash Loop

**Symptom**: Controller pods restarting

```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets --previous

# Check resource usage
kubectl top pods -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check events
kubectl get events -n kube-system | grep sealed-secrets
```

### Issue 9: Key Rotation Failed

**Symptom**: Old secrets not decrypted after rotation

```bash
# Check key rotation status
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# Re-encrypt secrets with new key
kubeseal --re-encrypt < old-sealed-secret.yaml > new-sealed-secret.yaml
```

### Issue 10: Cluster-Wide Scope Not Working

**Symptom**: Secret only works in one namespace

```bash
# Check scope
kubectl get sealedsecret myapp-secret -n production -o yaml | grep scope

# Re-encrypt with cluster scope
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --scope cluster > sealed-secret.yaml
```

### Issue 11: Secret Data Lost

**Symptom**: Secret empty after decryption

```bash
# Check SealedSecret encryptedData
kubectl get sealedsecret myapp-secret -n production -o yaml | grep encryptedData

# Re-encrypt Secret
kubectl create secret generic myapp-secret \
  --namespace production \
  --from-literal=db_password=abc123 \
  --dry-run=client -o yaml | kubeseal > sealed-secret.yaml
```

### Issue 12: Controller Can't Create Secrets

**Symptom**: RBAC errors in controller logs

```bash
# Check controller RBAC
kubectl get clusterrole sealed-secrets-controller -o yaml

# Check controller service account
kubectl get sa -n kube-system sealed-secrets-controller

# Reapply RBAC
kubectl apply -f controller-rbac.yaml
```

### Issue 13: Secret Already Exists

**Symptom**: `secret already exists` error

```bash
# Delete existing Secret
kubectl delete secret myapp-secret -n production

# Apply SealedSecret
kubectl apply -f sealed-secret.yaml
```

### Issue 14: Controller Not Watching Namespace

**Symptom**: SealedSecret not decrypted in target namespace

```bash
# Check controller namespace
kubectl get deployment sealed-secrets-controller -n kube-system -o yaml | grep namespace

# Check SealedSecret namespace
kubectl get sealedsecret myapp-secret -n production -o yaml | grep namespace

# Re-encrypt for correct namespace
kubeseal --namespace production < secret.yaml > sealed-secret.yaml
```

### Issue 15: Key Backup Lost

**Symptom**: Cannot decrypt old secrets after key loss

```bash
# Check if key backup exists
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/key-name

# If lost, old secrets cannot be decrypted
# Re-encrypt all secrets with new key
```

### Issue 16: Secret Type Mismatch

**Symptom**: Secret type not preserved

```bash
# Check SealedSecret template
kubectl get sealedsecret myapp-secret -n production -o yaml | grep type

# Re-encrypt with correct type
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --format yaml > sealed-secret.yaml
```

### Issue 17: Secret Labels Lost

**Symptom**: Secret labels not preserved

```bash
# Check SealedSecret template
kubectl get sealedsecret myapp-secret -n production -o yaml | grep labels

# Re-encrypt with labels
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --label "app=myapp" > sealed-secret.yaml
```

### Issue 18: Secret Annotations Lost

**Symptom**: Secret annotations not preserved

```bash
# Check SealedSecret template
kubectl get sealedsecret myapp-secret -n production -o yaml | grep annotations

# Re-encrypt with annotations
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --annotation "description=my secret" > sealed-secret.yaml
```

### Issue 19: Controller Resource Limits

**Symptom**: Controller pods evicted

```bash
# Check resource usage
kubectl top pods -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Increase resource limits
kubectl patch deployment sealed-secrets-controller -n kube-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"sealed-secrets","resources":{"limits":{"memory":"512Mi","cpu":"500m"}}}]}}}}'
```

### Issue 20: Secret Not Rotated

**Symptom**: Old Secret still in use

```bash
# Check Secret version
kubectl get secret myapp-secret -n production -o jsonpath='{.metadata.resourceVersion}'

# Force Secret update
kubectl delete secret myapp-secret -n production
kubectl apply -f sealed-secret.yaml
```

### Issue 21: Controller HA Not Working

**Symptom**: Multiple controller instances conflict

```bash
# Check controller replicas
kubectl get deployment sealed-secrets-controller -n kube-system

# Check leader election
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets | grep leader

# Configure leader election
kubectl patch deployment sealed-secrets-controller -n kube-system \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"sealed-secrets","args":["--leader-elect"]}]}}}}'
```

### Issue 22: Secret Not Available During Deployment

**Symptom**: Pod starts before Secret created

```yaml
# Add init container or use wait
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      initContainers:
        - name: wait-for-secret
          image: busybox
          command: ['sh', '-c', 'until kubectl get secret myapp-secret -n production; do sleep 1; done']
      containers:
        - name: myapp
          image: myapp:latest
```

---

## Tips & Best Practices (20+ Tips)

### Tip 1: Use Namespace Scope

Always use namespace scope for better isolation:

```bash
kubeseal --scope namespace --namespace production
```

### Tip 2: Commit SealedSecrets to Git

SealedSecrets are safe to commit:

```bash
git add sealed-secret.yaml
git commit -m "Add encrypted myapp-secret"
git push
```

### Tip 3: Use kubeseal --re-encrypt

Re-encrypt secrets periodically:

```bash
kubeseal --re-encrypt < old-sealed-secret.yaml > new-sealed-secret.yaml
```

### Tip 4: Backup Controller Keys

Backup controller keys regularly:

```bash
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
```

### Tip 5: Use GitOps Workflow

Integrate with GitOps tools:

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
spec:
  source:
    path: k8s/production
```

### Tip 6: Validate SealedSecrets

Validate before applying:

```bash
kubectl get sealedsecret myapp-secret -n production -o yaml | kubeseal --validate
```

### Tip 7: Use kubeseal --print-renewal

Check key renewal status:

```bash
kubeseal --print-renewal
```

### Tip 8: Monitor Controller Health

Monitor controller health:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

### Tip 9: Use Multiple Controllers

Use multiple controller replicas for HA:

```bash
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --set controller.replicaCount=2
```

### Tip 10: Use Network Policies

Restrict controller network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sealed-secrets-controller
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: sealed-secrets
  policyTypes:
    - Ingress
    - Egress
```

### Tip 11: Use RBAC

Restrict SealedSecret access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sealed-secrets-viewer
rules:
  - apiGroups: ["bitnami.com"]
    resources: ["sealedsecrets"]
    verbs: ["get", "list", "watch"]
```

### Tip 12: Use Secret Zero Pattern

Store controller key externally:

```bash
# Use Vault for controller key
vault kv put secret/sealed-secrets-key \
  tls.crt=@tls.crt \
  tls.key=@tls.key
```

### Tip 13: Use kubeseal --raw

Generate raw encrypted values:

```bash
echo -n "password" | kubeseal --raw --from-file=/dev/stdin --name myapp-secret --namespace production
```

### Tip 14: Use kubeseal --from-file

Encrypt files:

```bash
kubeseal --from-file=tls.crt --name myapp-tls --namespace production
kubeseal --from-file=tls.key --name myapp-tls --namespace production
```

### Tip 15: Use kubeseal --format json

Output in JSON format:

```bash
kubectl get secret myapp-secret -n production -o yaml | kubeseal --format json > sealed-secret.json
```

### Tip 16: Use kubeseal --controller-name

Use custom controller name:

```bash
kubeseal --controller-name=my-sealed-secrets-controller
```

### Tip 17: Use kubeseal --controller-namespace

Use custom controller namespace:

```bash
kubeseal --controller-namespace=sealed-secrets
```

### Tip 18: Use kubeseal --secret-name

Specify secret name:

```bash
kubeseal --secret-name=myapp-secret
```

### Tip 19: Use kubeseal --annotation

Add annotations:

```bash
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --annotation "description=my secret" > sealed-secret.yaml
```

### Tip 20: Use kubeseal --label

Add labels:

```bash
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --label "app=myapp" > sealed-secret.yaml
```

### Tip 21: Use kubeseal --scope strict

Maximum security:

```bash
kubeseal --scope strict --namespace production --name myapp-secret
```

### Tip 22: Use kubeseal --encryption-algorithm

Use specific encryption algorithm:

```bash
kubeseal --encryption-algorithm RSA-OAEP
```

---

## Command Reference

### kubeseal Commands

```bash
kubeseal --format yaml                    # Output format
kubeseal --scope namespace                # Scope mode
kubeseal --scope cluster                  # Cluster-wide scope
kubeseal --scope strict                   # Strict scope
kubeseal --namespace production           # Target namespace
kubeseal --name myapp-secret              # Target name
kubeseal --secret-name myapp-secret       # Secret name
kubeseal --controller-name sealed-secrets-controller  # Controller name
kubeseal --controller-namespace kube-system  # Controller namespace
kubeseal --re-encrypt                     # Re-encrypt with latest key
kubeseal --validate                       # Validate SealedSecret
kubeseal --print-renewal                  # Print key renewal info
kubeseal --raw                            # Raw output
kubeseal --from-file=<path>               # Encrypt from file
kubeseal --annotation "key=value"         # Add annotation
kubeseal --label "key=value"              # Add label
kubeseal --encryption-algorithm RSA-OAEP  # Encryption algorithm
kubeseal --key <path>                     # Use specific key
```

### kubectl Commands

```bash
kubectl get sealedsecret <name> -n <namespace>  # Get SealedSecret
kubectl get sealedsecret <name> -n <namespace> -o yaml  # Get YAML
kubectl describe sealedsecret <name> -n <namespace>  # Describe
kubectl delete sealedsecret <name> -n <namespace>  # Delete
kubectl apply -f sealed-secret.yaml  # Apply
kubectl get secret <name> -n <namespace>  # Get Secret
kubectl get secret <name> -n <namespace> -o yaml  # Get Secret YAML
```

### Controller Commands

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets
kubectl get events -n kube-system | grep sealed-secrets
kubectl get svc -n kube-system sealed-secrets-controller
kubectl get sa -n kube-system sealed-secrets-controller
kubectl get clusterrole sealed-secrets-controller
kubectl get clusterrolebinding sealed-secrets-controller
```

---

## Configuration Reference

### Controller Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: sealed-secrets
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sealed-secrets
    spec:
      containers:
        - name: sealed-secrets
          image: bitnami/sealed-secrets:0.24.0
          args:
            - --key-prefix=sealed-secrets
            - --key-min-days=7
            - --key-rotate
            - --key-rotate-period=30d
            - --log-level=info
            - --log-format=json
          ports:
            - containerPort: 8080
              name: http
          volumeMounts:
            - name: keys
              mountPath: /tmp/sealed-secrets
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
      volumes:
        - name: keys
          persistentVolumeClaim:
            claimName: sealed-secrets-keys
```

### Helm Values

```yaml
# values.yaml
fullnameOverride: sealed-secrets-controller

# Controller
controller:
  replicaCount: 2
  image:
    registry: docker.io
    repository: bitnami/sealed-secrets
    tag: 0.24.0
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
  args:
    - --key-prefix=sealed-secrets
    - --key-min-days=7
    - --key-rotate
    - --key-rotate-period=30d

# Secret
secret:
  name: sealed-secrets-key
  annotations:
    sealedsecrets.bitnami.com/managed: "true"

# Service
service:
  type: ClusterIP
  port: 8080
```

### Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sealed-secrets-controller
  namespace: kube-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: sealed-secrets
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from: []
      ports:
        - port: 8080
  egress:
    - to: []
      ports:
        - port: 443
```

---

## Real-World Examples — Our Cluster

### Example 1: K3s Cluster with Sealed Secrets

```bash
# Install sealed-secrets on k3s
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: sealed-secrets
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: sealed-secrets
spec:
  chart:
    spec:
      chart: sealed-secrets
      version: "0.24.0"
      sourceRef:
        kind: HelmRepository
        name: bitnami-labs
  values:
    fullnameOverride: sealed-secrets-controller
    controller:
      replicaCount: 2
      args:
        - --key-prefix=sealed-secrets
        - --key-rotate
        - --key-rotate-period=30d
EOF
```

### Example 2: Application Secret

```bash
# Create Secret
kubectl create secret generic myapp-secret \
  --namespace production \
  --from-literal=db_password=abc123 \
  --from-literal=api_key=xyz789 \
  --dry-run=client -o yaml > secret.yaml

# Encrypt
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --namespace production > sealed-secret.yaml

# Clean up
rm secret.yaml

# Commit
git add sealed-secret.yaml
git commit -m "Add encrypted myapp-secret"
git push

# Apply
kubectl apply -f sealed-secret.yaml
```

### Example 3: TLS Secret

```bash
# Create TLS Secret
kubectl create secret tls myapp-tls \
  --namespace production \
  --cert=tls.crt \
  --key=tls.key \
  --dry-run=client -o yaml > secret.yaml

# Encrypt
kubectl get secret myapp-tls -n production -o yaml | \
  kubeseal --namespace production > sealed-secret.yaml

# Apply
kubectl apply -f sealed-secret.yaml
```

### Example 4: GitOps Workflow

```yaml
# ArgoCD Application with SealedSecrets
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
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Example 5: Multi-Environment

```bash
# Production
kubectl get secret myapp-secret -n production -o yaml | \
  kubeseal --namespace production > k8s/production/sealed-secret.yaml

# Staging
kubectl get secret myapp-secret -n staging -o yaml | \
  kubeseal --namespace staging > k8s/staging/sealed-secret.yaml

# Development
kubectl get secret myapp-secret -n development -o yaml | \
  kubeseal --namespace development > k8s/development/sealed-secret.yaml
```

---

## Further Reading

### Official Documentation
- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
- [kubeseal CLI Reference](https://github.com/bitnami-labs/sealed-secrets#kubeseal)
- [Controller Configuration](https://github.com/bitnami-labs/sealed-secrets#controller-flags)

### Tutorials
- [Getting Started with Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets#getting-started)
- [Sealed Secrets with ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/sealed-secrets/)
- [Sealed Secrets with FluxCD](https://fluxcd.io/flux/guides/sealed-secrets/)

### Community
- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [Sealed Secrets Issues](https://github.com/bitnami-labs/sealed-secrets/issues)

### Related Guides
- [HashiCorp Vault Complete Guide](vault.md)
- [Vault Agent Complete Guide](vault-agent.md)
- [Vault Dynamic Secrets](vault-dynamic-secrets.md)
- [SOPS (Mozilla)](sops.md)

---

*Last Updated: 2026*
*Version: 0.24.0*
*Author: OpenWolf DevOps Guide*
