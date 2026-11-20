# Notary Complete Guide

## Table of Contents

1. [What Is Notary](#1-what-is-notary)
2. [Why Use Notary](#2-why-use-notary)
3. [Real-World Breaches](#3-real-world-breaches)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Rules and Policies](#8-custom-rules-and-policies)
9. [Integration](#9-integration)
10. [Security Hardening](#10-security-hardening)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips and Best Practices](#12-tips-and-best-practices)
13. [Command Reference](#13-command-reference)
14. [Configuration Reference](#14-configuration-reference)
15. [Real-World Examples](#15-real-world-examples)
16. [Further Reading](#16-further-reading)

---

## 1. What Is Notary

Notary is a project that implements The Update Framework (TUF), a framework for securing software update systems. Notary provides a way to ensure that the content users are downloading is exactly what the publishers intended, and it has not been modified by any third parties. Notary v2 is the latest version, designed for cloud-native environments and container image signing.

### 1.1 Overview

Notary provides:

- **Content Trust**: Ensures that content is signed by trusted publishers
- **Tamper Protection**: Prevents unauthorized modification of signed content
- **Key Management**: Provides secure key generation and management
- **Delegation**: Supports delegation of signing authority to multiple parties
- **Timestamping**: Uses trusted timestampers to prevent replay attacks
- **Root Key Rotation**: Supports rotation of root signing keys

### 1.2 Architecture

Notary's architecture consists of:

- **Notary Server**: Stores and serves signed metadata
- **Notary Signer**: Signs metadata with server-managed keys
- **Notary Client**: Signs and verifies content locally
- **TUF Metadata**: Contains signed information about targets
- **Key Storage**: Secure storage for signing keys

### 1.3 Notary v1 vs v2

| Feature | Notary v1 | Notary v2 |
|---|---|---|
| Protocol | TUF | TUF + OCI |
| Storage | Database | OCI Registry |
| Key Management | Notary Server/Signer | Local or KMS |
| Container Support | Limited | Full OCI support |
| Delegation | Basic | Advanced |
| Timestamping | External | Built-in |

### 1.4 Comparison with Other Signing Tools

| Feature | Notary v2 | Cosign | Docker Content Trust |
|---|---|---|---|
| Open Source | Yes (Apache 2) | Yes (Apache 2) | Yes |
| Keyless Signing | No | Yes | No |
| Registry Storage | Yes (OCI) | Yes (OCI) | Yes |
| Transparent Logging | No | Yes (Rekor) | No |
| TUF Compliance | Yes | No | Yes |
| Delegation | Yes | Limited | No |
| Timestamping | Yes | No | Yes |

---

## 2. Why Use Notary

### 2.1 Content Trust

Notary ensures that users download exactly what publishers intended by:

- **Signing**: Publishers sign their content with private keys
- **Verification**: Users verify signatures with public keys
- **Tamper Detection**: Any modification is detected during verification

### 2.2 TUF Framework

Notary implements TUF, which provides:

- **Root Key Rotation**: Safely rotate root signing keys
- **Delegation**: Delegate signing authority to multiple parties
- **Timestamping**: Prevent replay attacks with trusted timestamps
- **Snapshotting**: Ensure consistency across metadata files

### 2.3 Supply Chain Security

Notary helps secure the software supply chain by:

- **Ensuring Integrity**: Verifying that content has not been modified
- **Providing Authenticity**: Confirming that content comes from trusted sources
- **Enabling Auditing**: Creating a record of all signing events
- **Supporting Compliance**: Meeting requirements for software signing

### 2.4 Cloud-Native Support

Notary v2 is designed for cloud-native environments:

- **OCI Registry Integration**: Stores signatures as OCI artifacts
- **Kubernetes Support**: Works with Kubernetes admission controllers
- **Docker Integration**: Works with Docker Content Trust
- **Harbor Support**: Integrates with Harbor container registry

### 2.5 Delegation and Multi-Party Signing

Notary supports delegation, which allows:

- **Multiple Signers**: Different teams can sign different parts of the software
- **Role-Based Access**: Different roles for different signing operations
- **Threshold Signing**: Require multiple signatures for high-value content

---

## 3. Real-World Breaches

### 3.1 Docker Hub Malware (2020)

**What happened**: Researchers found thousands of malicious Docker images on Docker Hub, including cryptominers and credential stealers.

**Notary prevention**: If Docker Hub had required Notary signatures:

- Malicious images would have failed signature verification
- Users could have verified that images come from trusted publishers
- The tampering would have been detected before distribution

### 3.2 SolarWinds Supply Chain Attack (2020)

**What happened**: Attackers compromised the SolarWinds Orion build system and injected a backdoor (SUNBURST) into software updates distributed to 18,000+ organizations.

**Notary prevention**: If SolarWinds had used Notary to sign their build artifacts:

- The compromised build would have failed signature verification
- The backdoor would have been detected before deployment
- The delegation system would have shown unauthorized signing events

### 3.3 Log4Shell (CVE-2021-44228)

**What happened**: A critical RCE vulnerability in Apache Log4j affected millions of Java applications worldwide.

**Notary prevention**: While Notary cannot prevent the vulnerability itself, it can:

- Ensure that only signed Log4j versions are deployed
- Track which versions are signed and by whom
- Provide an audit trail for incident response

### 3.4 Codecov Supply Chain Attack (2021)

**What happened**: Attackers modified the Codecov Bash Uploader script to exfiltrate environment variables, including CI/CD secrets, from over 29,000 repositories.

**Notary prevention**: If Codecov had used Notary to sign their build artifacts:

- The modified script would have failed signature verification
- The tampering would have been detected before distribution
- The delegation system would have shown unauthorized modifications

### 3.5 Dependency Confusion Attacks (2021)

**What happened**: Security researcher Alex Birsan demonstrated that by publishing packages with the same name as internal packages on public registries, attackers could trick package managers into downloading malicious code.

**Notary prevention**: Notary can:

- Sign internal packages to distinguish them from public ones
- Verify that packages come from trusted sources
- Track the origin of all signed artifacts

### 3.6 npm Supply Chain Attacks (2021)

**What happened**: Multiple npm packages were compromised, including ua-parser-js, coa, and rc, affecting millions of projects.

**Notary prevention**: Notary can:

- Sign npm packages to verify their origin
- Track package signing events
- Verify that packages come from trusted maintainers

---

## 4. Installation

### 4.1 Quick Install (Recommended)

```bash
# Install Notary v2 CLI
go install github.com/notaryproject/n2/cli/notary@latest

# Verify installation
notary version
```

### 4.2 Package Managers

```bash
# Ubuntu/Debian
sudo apt-get install notary

# Homebrew (macOS)
brew install notary

# Snap
sudo snap install notary
```

### 4.3 Docker

```bash
# Run Notary as a container
docker run --rm \
  -v $PWD:/workspace \
  -w /workspace \
  notaryproject/notary-server:latest serve
```

### 4.4 Binary Download

```bash
# Download the latest release
NOTARY_VERSION=$(curl -s https://api.github.com/repos/notaryproject/n2/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
curl -LO "https://github.com/notaryproject/n2/releases/download/${NOTARY_VERSION}/notary_${NOTARY_VERSION#v}_linux_amd64"
chmod +x "notary_${NOTARY_VERSION#v}_linux_amd64"
sudo mv "notary_${NOTARY_VERSION#v}_linux_amd64" /usr/local/bin/notary
```

### 4.5 Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notary-server
  namespace: notary-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notary-server
  template:
    metadata:
      labels:
        app: notary-server
    spec:
      containers:
      - name: notary-server
        image: notaryproject/notary-server:latest
        ports:
        - containerPort: 4443
        - containerPort: 4444
        volumeMounts:
        - name: notary-config
          mountPath: /etc/notary
      volumes:
      - name: notary-config
        configMap:
          name: notary-config
---
apiVersion: v1
kind: Service
metadata:
  name: notary-server
  namespace: notary-system
spec:
  selector:
    app: notary-server
  ports:
  - name: https
    port: 4443
    targetPort: 4443
  - name: health
    port: 4444
    targetPort: 4444
```

---

## 5. Configuration

### 5.1 Server Configuration

```yaml
# notary-server.yaml
server:
  addr: ":4443"
  tls_cert_file: "/etc/notary/server.crt"
  tls_key_file: "/etc/notary/server.key"

storage:
  backend: "mysql"
  db_hostname: "notary-db"
  db_port: "3306"
  db_username: "notary"
  db_password: "notary-password"
  db_name: "notaryserver"

auth:
  type: "token"
  options:
    issuer: "notary-server"
    realm: "https://notary.example.com/auth"
    rootcertbundle: "/etc/notary/root.crt"
```

### 5.2 Signer Configuration

```yaml
# notary-signer.yaml
server:
  addr: ":4444"
  tls_cert_file: "/etc/notary/signer.crt"
  tls_key_file: "/etc/notary/signer.key"

storage:
  backend: "mysql"
  db_hostname: "notary-db"
  db_port: "3306"
  db_username: "notary"
  db_password: "notary-password"
  db_name: "notarysigner"

key:
  backend: "file"
  file_path: "/etc/notary/keys"
```

### 5.3 Client Configuration

```bash
# Set environment variables
export NOTARY_SERVER_URL=https://notary.example.com
export NOTARY_AUTH_URL=https://notary.example.com/auth
export NOTARY_ROOT_CA_PATH=/etc/notary/root.crt

# Or use a config file
cat > ~/.notary/config.json <<EOF
{
  "server_url": "https://notary.example.com",
  "auth_url": "https://notary.example.com/auth",
  "root_ca_path": "/etc/notary/root.crt"
}
EOF
```

### 5.4 Environment Variables

```bash
# Set the Notary server URL
export NOTARY_SERVER_URL=https://notary.example.com

# Set the authentication URL
export NOTARY_AUTH_URL=https://notary.example.com/auth

# Set the root CA path
export NOTARY_ROOT_CA_PATH=/etc/notary/root.crt

# Set the TLS certificate
export NOTARY_TLS_CERT=/etc/notary/client.crt

# Set the TLS key
export NOTARY_TLS_KEY=/etc/notary/client.key
```

---

## 6. Core Concepts

### 6.1 TUF Metadata

Notary uses TUF metadata files:

- **root.json**: Contains root keys and defines top-level roles
- **targets.json**: Contains information about signed targets
- **snapshot.json**: Contains hashes of all metadata files
- **timestamp.json**: Contains a hash of the snapshot file and a trusted timestamp

### 6.2 Roles and Delegation

Notary supports multiple roles:

- **Root**: Manages root keys and defines top-level roles
- **Targets**: Signs target files (e.g., container images)
- **Snapshot**: Signs the snapshot metadata
- **Timestamp**: Signs the timestamp metadata
- **Delegations**: Custom roles for delegation

### 6.3 Key Management

Notary supports different key management backends:

- **File System**: Keys stored on the local file system
- **Database**: Keys stored in a database (for Notary Server)
- **Hardware Security Module (HSM)**: Keys stored in an HSM
- **Cloud KMS**: Keys stored in a cloud KMS (e.g., AWS KMS, GCP KMS)

### 6.4 Content Trust

Content trust ensures:

- **Integrity**: Content has not been modified
- **Authenticity**: Content comes from a trusted source
- **Freshness**: Content is not replayed from an earlier time
- **Consistency**: All metadata files are consistent with each other

### 6.5 Delegation

Notary supports delegation, which allows:

- **Multiple Signers**: Different teams can sign different targets
- **Role-Based Access**: Different roles for different signing operations
- **Threshold Signing**: Require multiple signatures for high-value targets

---

## 7. Usage Guide

### 7.1 Initializing a Repository

```bash
# Initialize a new Notary repository
notary init my-registry.com/my-image

# Initialize with a specific key
notary init --key /path/to/key my-registry.com/my-image

# Initialize with delegation
notary init --delegation targets/releases my-registry.com/my-image
```

### 7.2 Adding Targets

```bash
# Add a target (e.g., a container image)
notary add my-registry.com/my-image:latest /path/to/image.tar

# Add with metadata
notary add --metadata /path/to/metadata.json my-registry.com/my-image:latest /path/to/image.tar

# Add a delegation target
notary add --delegation targets/releases my-registry.com/my-image:latest /path/to/image.tar
```

### 7.3 Signing Targets

```bash
# Sign a target
notary sign my-registry.com/my-image:latest

# Sign with a specific key
notary sign --key /path/to/key my-registry.com/my-image:latest

# Sign with delegation
notary sign --delegation targets/releases my-registry.com/my-image:latest
```

### 7.4 Verifying Targets

```bash
# Verify a target
notary verify my-registry.com/my-image:latest

# Verify with a specific key
notary verify --key /path/to/key my-registry.com/my-image:latest

# Verify with delegation
notary verify --delegation targets/releases my-registry.com/my-image:latest

# Verify and show details
notary verify --verbose my-registry.com/my-image:latest
```

### 7.5 Listing Targets

```bash
# List all targets
notary list my-registry.com/my-image

# List with details
notary list --verbose my-registry.com/my-image

# List delegations
notary delegation list my-registry.com/my-image
```

### 7.6 Managing Keys

```bash
# Generate a new key pair
notary key generate

# Import a key
notary key import /path/to/key

# Export a key
notary key export /path/to/key

# List keys
notary key list

# Change key passphrase
notary key change-passphrase /path/to/key
```

### 7.7 Managing Delegations

```bash
# Add a delegation
notary delegation add --targets-role targets/releases --key /path/to/key my-registry.com/my-image

# Remove a delegation
notary delegation remove --targets-role targets/releases my-registry.com/my-image

# List delegations
notary delegation list my-registry.com/my-image
```

### 7.8 Publishing Metadata

```bash
# Publish metadata to the server
notary publish my-registry.com/my-image

# Publish with specific key
notary publish --key /path/to/key my-registry.com/my-image

# Publish delegation
notary publish --delegation targets/releases my-registry.com/my-image
```

---

## 8. Custom Rules and Policies

### 8.1 Docker Content Trust

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Push a signed image
docker push my-registry.com/my-image:latest

# Pull a verified image
docker pull my-registry.com/my-image:latest
```

### 8.2 Kyverno Policy for Notary

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-notary-signature
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: check-notary-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Image must be signed with Notary"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!*:latest"
```

### 8.3 OPA/Rego Policy for Notary

```rego
# notary-policy.rego
package main

default deny = false

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not image_signed(container.image)
    msg := sprintf("Image %s is not signed with Notary", [container.image])
}

image_signed(image) {
    # Verify signature using Notary
    output := exec.command("notary", "verify", image)
    count(output) > 0
}
```

### 8.4 Custom Delegation Policies

```bash
# Add a delegation with specific targets
notary delegation add --targets-role targets/releases \
  --path /releases/* \
  --key /path/to/key \
  my-registry.com/my-image

# Add a delegation with exclusion paths
notary delegation add --targets-role targets/releases \
  --path /releases/* \
  --exclusion /releases/experimental/* \
  --key /path/to/key \
  my-registry.com/my-image
```

---

## 9. Integration

### 9.1 GitHub Actions

```yaml
# .github/workflows/notary-sign.yml
name: Notary Sign
on:
  push:
    branches: [main]

jobs:
  sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push image
        run: docker push ghcr.io/${{ github.repository }}:${{ github.sha }}

      - name: Install Notary
        run: |
          go install github.com/notaryproject/n2/cli/notary@latest

      - name: Sign image
        run: |
          notary init ghcr.io/${{ github.repository }}:${{ github.sha }}
          notary add ghcr.io/${{ github.repository }}:${{ github.sha }}
          notary sign ghcr.io/${{ github.repository }}:${{ github.sha }}
          notary publish ghcr.io/${{ github.repository }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}
```

### 9.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
notary-sign:
  stage: security
  image: notaryproject/notary-server:latest
  script:
    - notary init $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - notary add $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - notary sign $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - notary publish $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  variables:
    NOTARY_SERVER_URL: $NOTARY_SERVER_URL
```

### 9.3 Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t my-app:${BUILD_NUMBER} .'
            }
        }
        stage('Sign') {
            steps {
                sh '''
                    notary init my-app:${BUILD_NUMBER}
                    notary add my-app:${BUILD_NUMBER}
                    notary sign my-app:${BUILD_NUMBER}
                    notary publish my-app:${BUILD_NUMBER}
                '''
            }
        }
        stage('Verify') {
            steps {
                sh 'notary verify my-app:${BUILD_NUMBER}'
            }
        }
    }
}
```

### 9.4 ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  annotations:
    notary.example.com/image-ref: my-app:latest
    notary.example.com/verify: "true"
```

### 9.5 k3s with Notary

```bash
# Deploy Notary server in k3s
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notary-server
  namespace: notary-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notary-server
  template:
    metadata:
      labels:
        app: notary-server
    spec:
      containers:
      - name: notary-server
        image: notaryproject/notary-server:latest
        ports:
        - containerPort: 4443
EOF
```

### 9.6 Harbor Integration

```bash
# Configure Harbor to use Notary
# Harbor UI -> Administration -> Interrogation Services -> Notary

# Or via Harbor API
curl -X PUT "https://harbor.example.com/api/v2.0/projects/myproject" \
  -H "Authorization: Basic $(echo -n admin:password | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "enable_content_trust": "true",
      "content_trust_notary_url": "https://notary.example.com"
    }
  }'
```

---

## 10. Security Hardening

### 10.1 Key Management Best Practices

```bash
# Use HSM for key management
notary key generate --type ecdsa --hardware

# Use cloud KMS
notary key generate --type ecdsa --kms aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# Rotate keys regularly
notary key generate --type ecdsa --new-root
```

### 10.2 Server Security

```yaml
server:
  addr: ":4443"
  tls_cert_file: "/etc/notary/server.crt"
  tls_key_file: "/etc/notary/server.key"

auth:
  type: "token"
  options:
    issuer: "notary-server"
    realm: "https://notary.example.com/auth"
    rootcertbundle: "/etc/notary/root.crt"
```

### 10.3 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: notary-network-policy
  namespace: notary-system
spec:
  podSelector:
    matchLabels:
      app: notary-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 4443
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 3306
```

### 10.4 RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: notary-signer
  namespace: notary-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: notary-signer
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: notary-signer
subjects:
- kind: ServiceAccount
  name: notary-signer
  namespace: notary-system
roleRef:
  kind: ClusterRole
  name: notary-signer
  apiGroup: rbac.authorization.k8s.io
```

### 10.5 Secret Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: notary-key
  namespace: notary-system
type: Opaque
data:
  key: <base64-encoded-private-key>
  cert: <base64-encoded-certificate>
```

---

## 11. Troubleshooting

### 11.1 Issue: Notary Server Not Found

**Symptom**: `connection refused` or `server not found`

**Fix**:
```bash
# Check server status
curl -k https://notary.example.com/v2/

# Check DNS resolution
nslookup notary.example.com

# Check firewall rules
sudo ufw status
```

### 11.2 Issue: Authentication Failed

**Symptom**: `unauthorized` or `authentication required`

**Fix**:
```bash
# Login to the registry
docker login my-registry.com

# Set environment variables
export NOTARY_SERVER_URL=https://notary.example.com
export NOTARY_AUTH_URL=https://notary.example.com/auth
```

### 11.3 Issue: Key Not Found

**Symptom**: `key not found` or `no key found`

**Fix**:
```bash
# Generate a new key pair
notary key generate

# Import a key
notary key import /path/to/key

# List keys
notary key list
```

### 11.4 Issue: Signature Verification Failed

**Symptom**: `verification failed` or `signature mismatch`

**Fix**:
```bash
# Verify with correct key
notary verify --key /path/to/key my-image:latest

# Check signature details
notary verify --verbose my-image:latest
```

### 11.5 Issue: Target Not Found

**Symptom**: `target not found` or `no targets`

**Fix**:
```bash
# Add a target
notary add my-image:latest /path/to/image.tar

# List targets
notary list my-image
```

### 11.6 Issue: Delegation Failed

**Symptom**: `delegation failed` or `permission denied`

**Fix**:
```bash
# Add a delegation
notary delegation add --targets-role targets/releases --key /path/to/key my-image

# List delegations
notary delegation list my-image
```

### 11.7 Issue: Publish Failed

**Symptom`: `publish failed` or `metadata error`

**Fix**:
```bash
# Publish with verbose output
notary publish --verbose my-image

# Check metadata
notary list --verbose my-image
```

### 11.8 Issue: Key Passphrase Required

**Symptom**: `passphrase required` or `key encrypted`

**Fix**:
```bash
# Enter passphrase when prompted
notary sign --key /path/to/key my-image:latest

# Or use environment variable
export NOTARY_PASSPHRASE=my-passphrase
notary sign --key /path/to/key my-image:latest
```

### 11.9 Issue: TUF Metadata Expired

**Symptom**: `metadata expired` or `timestamp expired`

**Fix**:
```bash
# Update timestamp metadata
notary timestamp my-image

# Verify freshness
notary verify --verbose my-image
```

### 11.10 Issue: Root Key Rotation Failed

**Symptom**: `root key rotation failed` or `key rotation error`

**Fix**:
```bash
# Generate new root key
notary key generate --new-root

# Rotate root key
notary key rotate my-image

# Verify rotation
notary verify --verbose my-image
```

### 11.11 Issue: Database Connection Failed

**Symptom`: `database connection failed` or `mysql error`

**Fix**:
```bash
# Check database status
mysql -h notary-db -u notary -p

# Check database configuration
cat /etc/notary/server.yaml
```

### 11.12 Issue: TLS Certificate Error

**Symptom`: `certificate error` or `tls handshake failure`

**Fix**:
```bash
# Check TLS certificate
openssl x509 -in /etc/notary/server.crt -text -noout

# Regenerate TLS certificate
openssl req -x509 -newkey rsa:4096 -keyout /etc/notary/server.key -out /etc/notary/server.crt -days 365
```

### 11.13 Issue: Notary Client Version Mismatch

**Symptom`: `version mismatch` or `protocol error`

**Fix**:
```bash
# Check client version
notary version

# Update client
go install github.com/notaryproject/n2/cli/notary@latest
```

### 11.14 Issue: Docker Content Trust Not Working

**Symptom`: `content trust not enabled` or `dct error`

**Fix**:
```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Push a signed image
docker push my-image:latest
```

### 11.15 Issue: Notary Server Performance Issues

**Symptom`: `slow response` or `timeout`

**Fix**:
```bash
# Check server resources
kubectl top pods -n notary-system

# Increase server replicas
kubectl scale deployment notary-server --replicas=3 -n notary-system

# Check database performance
mysql -h notary-db -u notary -p -e "SHOW PROCESSLIST;"
```

---

## 12. Tips and Best Practices

### 12.1 Use Hardware Security Modules (HSM)

Store root keys in an HSM for maximum security.

### 12.2 Rotate Keys Regularly

Rotate root and target keys regularly to limit the impact of key compromise.

### 12.3 Use Delegation for Multi-Party Signing

Use delegation to allow different teams to sign different parts of the software.

### 12.4 Enable Docker Content Trust

Enable Docker Content Trust to automatically verify signatures when pulling images.

### 12.5 Use Notary with Harbor

Integrate Notary with Harbor for a complete container security solution.

### 12.6 Monitor Notary Server

Monitor Notary server performance and security events.

### 12.7 Backup Keys Regularly

Backup all signing keys and metadata regularly.

### 12.8 Use TLS for All Connections

Use TLS for all connections to the Notary server.

### 12.9 Implement Access Control

Implement access control for the Notary server and signer.

### 12.10 Use Strong Passphrases

Use strong passphrases for all signing keys.

### 12.11 Audit Signing Events

Audit all signing events and metadata changes.

### 12.12 Test Signature Verification

Test signature verification in your CI/CD pipeline.

### 12.13 Use Consistent Tagging

Use consistent tagging for signed images to avoid confusion.

### 12.14 Document Signing Procedures

Document your organization's signing procedures and policies.

### 12.15 Train Your Team

Train your team on Notary usage and best practices.

---

## 13. Command Reference

### 13.1 Global Flags

| Flag | Description | Default |
|---|---|---|
| `--server` | Notary server URL | - |
| `--tls-ca-cert` | TLS CA certificate | - |
| `--tls-client-cert` | TLS client certificate | - |
| `--tls-client-key` | TLS client key | - |

### 13.2 Init Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Root key file | - |
| `--remote` | Remote server | - |
| `--delegation` | Delegation role | - |

### 13.3 Add Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Signing key file | - |
| `--metadata` | Metadata file | - |
| `--delegation` | Delegation role | - |

### 13.4 Sign Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Signing key file | - |
| `--delegation` | Delegation role | - |
| `--passphrase` | Key passphrase | - |

### 13.5 Verify Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Verification key file | - |
| `--delegation` | Delegation role | - |
| `--verbose` | Verbose output | false |

---

## 14. Configuration Reference

### 14.1 Server Configuration Example

```yaml
server:
  addr: ":4443"
  tls_cert_file: "/etc/notary/server.crt"
  tls_key_file: "/etc/notary/server.key"

storage:
  backend: "mysql"
  db_hostname: "notary-db"
  db_port: "3306"
  db_username: "notary"
  db_password: "notary-password"
  db_name: "notaryserver"

auth:
  type: "token"
  options:
    issuer: "notary-server"
    realm: "https://notary.example.com/auth"
    rootcertbundle: "/etc/notary/root.crt"
```

### 14.2 Signer Configuration Example

```yaml
server:
  addr: ":4444"
  tls_cert_file: "/etc/notary/signer.crt"
  tls_key_file: "/etc/notary/signer.key"

storage:
  backend: "mysql"
  db_hostname: "notary-db"
  db_port: "3306"
  db_username: "notary"
  db_password: "notary-password"
  db_name: "notarysigner"

key:
  backend: "file"
  file_path: "/etc/notary/keys"
```

### 14.3 Environment Variables Reference

| Variable | Description | Default |
|---|---|---|
| NOTARY_SERVER_URL | Notary server URL | - |
| NOTARY_AUTH_URL | Authentication URL | - |
| NOTARY_ROOT_CA_PATH | Root CA path | - |
| NOTARY_TLS_CERT | TLS client certificate | - |
| NOTARY_TLS_KEY | TLS client key | - |
| NOTARY_PASSPHRASE | Key passphrase | - |

---

## 15. Real-World Examples

### 15.1 Contoso Pet Store - Notary Integration

**Scenario**: Contoso Pet Store runs a microservices architecture on Kubernetes with 15 container images in production.

#### 15.1.1 CI/CD Pipeline Integration

```yaml
name: Pet Store Notary Sign
on:
  push:
    branches: [main]

jobs:
  sign:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - api-gateway
          - product-service
          - cart-service
          - order-service
          - user-service
          - payment-service
          - notification-service

    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }} ./services/${{ matrix.service }}

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push image
        run: docker push ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}

      - name: Install Notary
        run: |
          go install github.com/notaryproject/n2/cli/notary@latest

      - name: Initialize Notary repository
        run: |
          notary init ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}

      - name: Add target
        run: |
          notary add ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}

      - name: Sign target
        run: |
          notary sign ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}
          NOTARY_PASSPHRASE: ${{ secrets.NOTARY_PASSPHRASE }}

      - name: Publish metadata
        run: |
          notary publish ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}

      - name: Verify signature
        run: |
          notary verify ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
        env:
          NOTARY_SERVER_URL: ${{ secrets.NOTARY_SERVER_URL }}
```

#### 15.1.2 Kubernetes Security Policies

```yaml
# petstore-notary-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: petstore-notary-signature
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: check-notary-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    validate:
      message: "Image must be signed with Notary"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!*:latest"
```

---

## 16. Further Reading

### 16.1 Official Documentation

- [Notary Documentation](https://notaryproject.dev/docs/)
- [Notary GitHub Repository](https://github.com/notaryproject/n2)
- [TUF Specification](https://theupdateframework.github.io/spec/latest/)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/)

### 16.2 Blog Posts and Tutorials

- [Getting Started with Notary](https://notaryproject.dev/docs/quick_start/)
- [Notary vs Cosign: A Comparison](https://blog.notaryproject.dev/notary-vs-cosign)
- [TUF in Practice](https://blog.notaryproject.dev/tuf-in-practice/)

### 16.3 Community Resources

- [Notary Slack Channel](https://notaryproject.slack.com/)
- [Notary Discussions](https://github.com/notaryproject/n2/discussions)
- [Notary Issues](https://github.com/notaryproject/n2/issues)

### 16.4 Related Tools

- [Cosign](https://github.com/sigstore/cosign) - Image signing
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner
- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - Vulnerability scanner
- [Harbor](https://goharbor.io/) - Container registry

### 16.5 Standards and Specifications

- [TUF](https://theupdateframework.github.io/spec/latest/) - The Update Framework
- [OCI Artifacts](https://github.com/opencontainers/image-spec/blob/main/manifest.md) - OCI artifact specification
- [CycloneDX](https://cyclonedx.org/) - SBOM standard
- [SLSA](https://slsa.dev/) - Supply chain integrity framework

---

*Last updated: September 2026*
*Notary version: 2.0.0+*
