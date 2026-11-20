# Cosign Complete Guide (Image Signing)

## Table of Contents

1. [What Is Cosign](#1-what-is-cosign)
2. [Why Use Cosign](#2-why-use-cosign)
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

## 1. What Is Cosign

Cosign is a container signing, verification, and storage tool developed by Sigstore. It is designed to sign and verify container images, ensuring the integrity and authenticity of software artifacts in cloud-native environments. Cosign is a key component of the Sigstore project, which aims to make software signing easy and accessible.

### 1.1 Overview

Cosign provides:

- **Image Signing**: Sign container images with cryptographic signatures
- **Image Verification**: Verify that images have not been tampered with
- **Keyless Signing**: Sign images using OIDC identity (no keys needed)
- **Key Management**: Generate and manage signing keys
- **Signature Storage**: Store signatures in container registries or transparent logs
- **SBOM Signing**: Sign Software Bill of Materials
- **Artifact Signing**: Sign any file or blob

### 1.2 Architecture

Cosign's architecture includes:

- **Key Management**: Generates and manages signing keys (RSA, ECDSA, ED25519)
- **Signing Engine**: Creates digital signatures for container images and artifacts
- **Verification Engine**: Verifies signatures against public keys or OIDC identities
- **Fulcio Integration**: Uses Fulcio for keyless signing with short-lived certificates
- **Rekor Integration**: Uses Rekor for transparent logging of signing events
- **OCI Registry**: Stores signatures as OCI artifacts in container registries

### 1.3 Supported Operations

| Operation | Description |
|---|---|
| sign | Sign a container image or artifact |
| verify | Verify a signature against an image |
| attach | Attach signatures, SBOMs, or attestations to images |
| detach | Detach signatures from images |
| download | Download signatures from a registry |
| upload | Upload signatures to a registry |
| generate-key-pair | Generate a new signing key pair |
| blob sign | Sign any file or blob |
| blob verify | Verify a blob signature |

### 1.4 Comparison with Other Signing Tools

| Feature | Cosign | Notary v2 | Docker Content Trust | Sigstore |
|---|---|---|---|---|
| Open Source | Yes (Apache 2) | Yes | Yes | Yes |
| Keyless Signing | Yes | No | No | Yes |
| Registry Storage | Yes | Yes | Yes | Yes |
| Transparent Logging | Yes (Rekor) | No | No | Yes |
| SBOM Signing | Yes | Limited | No | Yes |
| Kubernetes Integration | Yes | Limited | No | Yes |
| OIDC Support | Yes | No | No | Yes |
| Simplicity | High | Medium | Low | High |

---

## 2. Why Use Cosign

### 2.1 Supply Chain Security

Cosign is critical for supply chain security because it:

- **Ensures Integrity**: Verifies that images have not been tampered with since they were signed
- **Provides Authenticity**: Confirms that images come from a trusted source
- **Enables Auditing**: Creates a transparent log of all signing events
- **Supports Compliance**: Meets requirements for software signing in regulated industries

### 2.2 Keyless Signing

Cosign supports keyless signing using OIDC identity, which means:

- No need to manage long-lived signing keys
- Uses short-lived certificates from Fulcio
- Identity is tied to your OIDC provider (GitHub, Google, etc.)
- Signing events are logged in Rekor transparent log

### 2.3 Registry-Native Storage

Cosign stores signatures as OCI artifacts in the same container registry as the images, which means:

- No additional infrastructure needed
- Signatures travel with the images
- Works with any OCI-compliant registry
- Signatures are stored alongside the image manifests

### 2.4 Kubernetes Integration

Cosign integrates natively with Kubernetes:

- **Kyverno**: Policy-as-code enforcement for image signatures
- **OPA/Gatekeeper**: Custom policies for signature verification
- **Admission Controllers**: Block unsigned images from running
- **Cosign Policy**: Define signing policies for your organization

### 2.5 SBOM and Attestation Support

Cosign can sign and verify:

- Container images
- Software Bill of Materials (SBOMs)
- Vulnerability scan results
- Build provenance attestations
- Custom attestations

---

## 3. Real-World Breaches

### 3.1 SolarWinds Supply Chain Attack (2020)

**What happened**: Attackers compromised the SolarWinds Orion build system and injected a backdoor (SUNBURST) into software updates distributed to 18,000+ organizations.

**Cosign prevention**: If SolarWinds had used Cosign to sign their build artifacts:

- The compromised build would have failed signature verification
- The backdoor would have been detected before deployment
- The transparent log would have shown when the signing key was compromised

**Detection with Cosign**:
```bash
cosign verify --key cosign.pub solarwinds-orion:latest
```

### 3.2 Codecov Supply Chain Attack (2021)

**What happened**: Attackers modified the Codecov Bash Uploader script to exfiltrate environment variables, including CI/CD secrets, from over 29,000 repositories.

**Cosign prevention**: If Codecov had used Cosign to sign their build artifacts:

- The modified script would have failed signature verification
- The tampering would have been detected before distribution
- The transparent log would have shown the unauthorized signing event

### 3.3 Log4Shell (CVE-2021-44228)

**What happened**: A critical RCE vulnerability in Apache Log4j affected millions of Java applications worldwide.

**Cosign prevention**: While Cosign cannot prevent the vulnerability itself, it can:

- Ensure that only signed Log4j versions are deployed
- Track which versions are signed and by whom
- Provide an audit trail for incident response

### 3.4 Dependency Confusion Attacks (2021)

**What happened**: Security researcher Alex Birsan demonstrated that by publishing packages with the same name as internal packages on public registries, attackers could trick package managers into downloading malicious code.

**Cosign prevention**: Cosign can:

- Sign internal packages to distinguish them from public ones
- Verify that packages come from trusted sources
- Track the origin of all signed artifacts

### 3.5 Docker Hub Malware (2020)

**What happened**: Researchers found thousands of malicious Docker images on Docker Hub, including cryptominers and credential stealers.

**Cosign prevention**: Cosign can:

- Sign official images to distinguish them from malicious ones
- Verify that images come from trusted publishers
- Block unsigned images from running in Kubernetes

### 3.6 npm Supply Chain Attacks (2021)

**What happened**: Multiple npm packages were compromised, including ua-parser-js, coa, and rc, affecting millions of projects.

**Cosign prevention**: Cosign can:

- Sign npm packages to verify their origin
- Track package signing events in transparent logs
- Verify that packages come from trusted maintainers

---

## 4. Installation

### 4.1 Quick Install (Recommended)

```bash
# Install via the official install script
curl -sSfL https://raw.githubusercontent.com/sigstore/cosign/main/install.sh | sh -s -- -b /usr/local/bin

# Verify installation
cosign version
```

### 4.2 Package Managers

```bash
# Ubuntu/Debian (via Sigstore repository)
curl -sSfL https://raw.githubusercontent.com/sigstore/cosign/main/install.sh | sudo -E bash
sudo apt-get install cosign

# Homebrew (macOS)
brew install cosign

# Snap
sudo snap install cosign

# AUR (Arch Linux)
yay -S cosign
```

### 4.3 Docker

```bash
# Run Cosign as a container
docker run --rm \
  -v $PWD:/workspace \
  -w /workspace \
  gcr.io/projectsigstore/cosign:latest sign --key cosign.key my-image:latest
```

### 4.4 Binary Download

```bash
# Download the latest release
COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
curl -LO "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign_${COSIGN_VERSION#v}_linux_amd64"
chmod +x "cosign_${COSIGN_VERSION#v}_linux_amd64"
sudo mv "cosign_${COSIGN_VERSION#v}_linux_amd64" /usr/local/bin/cosign
```

### 4.5 Kubernetes Deployment

```bash
# Deploy Cosign as a Kubernetes Job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: cosign-sign
spec:
  template:
    spec:
      containers:
      - name: cosign
        image: gcr.io/projectsigstore/cosign:latest
        args:
        - sign
        - --key
        - /etc/cosign/cosign.key
        - my-image:latest
        volumeMounts:
        - name: cosign-key
          mountPath: /etc/cosign
          readOnly: true
      restartPolicy: Never
      volumes:
      - name: cosign-key
        secret:
          secretName: cosign-key
  backoffLimit: 1
EOF
```

---

## 5. Configuration

### 5.1 Key Management

```bash
# Generate a new key pair
cosign generate-key-pair

# Generate with a specific algorithm
cosign generate-key-pair --algorithm ecdsa
cosign generate-key-pair --algorithm ed25519
cosign generate-key-pair --algorithm rsa

# Generate with a password
cosign generate-key-pair --kms-hashicorp-vault transit cosign-key
```

### 5.2 Environment Variables

```bash
# Set the key path
export COSIGN_KEY=/path/to/cosign.key

# Set the password
export COSIGN_PASSWORD=my-password

# Set the OIDC issuer
export COSIGN_OIDC_ISSUER=https://token.actions.githubusercontent.com

# Set the OIDC client ID
export COSIGN_OIDC_CLIENT_ID=sigstore

# Set the Rekor URL
export COSIGN_REKOR_URL=https://rekor.sigstore.dev

# Set the Fulcio URL
export COSIGN_FULCIO_URL=https://fulcio.sigstore.dev
```

### 5.3 Configuration File

Cosign can be configured via a YAML file:

```yaml
# cosign.yaml
key: /path/to/cosign.key
password: my-password
oidc-issuer: https://token.actions.githubusercontent.com
oidc-client-id: sigstore
rekor-url: https://rekor.sigstore.dev
fulcio-url: https://fulcio.sigstore.dev
```

---

## 6. Core Concepts

### 6.1 Key-Based Signing

Key-based signing uses a private key to sign images and a public key to verify them:

```bash
# Sign with a key
cosign sign --key cosign.key my-image:latest

# Verify with a key
cosign verify --key cosign.pub my-image:latest
```

### 6.2 Keyless Signing

Keyless signing uses OIDC identity to sign images without managing keys:

```bash
# Sign keylessly (uses OIDC token from environment)
cosign sign my-image:latest

# Verify keyless signing
cosign verify \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  my-image:latest
```

### 6.3 Signature Storage

Cosign stores signatures as OCI artifacts in the container registry:

- **Image Signature**: Stored as a manifest in the registry
- **SBOM**: Stored as an OCI artifact attached to the image
- **Attestation**: Stored as an OCI artifact attached to the image

### 6.4 Transparency Log

Cosign uses Rekor for transparent logging of signing events:

- **Immutable**: Once logged, entries cannot be modified
- **Auditable**: Anyone can verify the log
- **Verifiable**: Entries can be verified against the log

### 6.5 Fulcio Certificates

Cosign uses Fulcio for short-lived certificates:

- **Short-lived**: Certificates expire after a short period
- **OIDC-based**: Identity is tied to OIDC providers
- **No key management**: No long-lived keys to manage

### 6.6 SBOM and Attestation

Cosign can sign and attach SBOMs and attestations:

```bash
# Attach an SBOM
cosign attach sbom --sbom sbom.json my-image:latest

# Attach an attestation
cosign attest --key cosign.key --predicate predicate.json my-image:latest

# Verify attestation
cosign verify-attestation --key cosign.pub my-image:latest
```

---

## 7. Usage Guide

### 7.1 Signing Container Images

```bash
# Generate a key pair
cosign generate-key-pair

# Sign an image with a key
cosign sign --key cosign.key my-image:latest

# Sign an image keylessly
cosign sign my-image:latest

# Sign with a specific tag
cosign sign --key cosign.key -a version=1.0.0 my-image:latest

# Sign and upload to a specific registry
cosign sign --key cosign.key registry.example.com/my-image:latest
```

### 7.2 Verifying Container Images

```bash
# Verify with a key
cosign verify --key cosign.pub my-image:latest

# Verify keyless signing
cosign verify \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  my-image:latest

# Verify with annotations
cosign verify --key cosign.pub -a version=1.0.0 my-image:latest

# Verify and output JSON
cosign verify --key cosign.pub --output json my-image:latest
```

### 7.3 Signing SBOMs

```bash
# Generate an SBOM
syft nginx:latest -o cyclonedx-json=sbom.json

# Attach the SBOM to the image
cosign attach sbom --sbom sbom.json nginx:latest

# Verify the SBOM
cosign verify --key cosign.pub nginx:latest
```

### 7.4 Signing Attestations

```bash
# Create a predicate file
cat > predicate.json <<EOF
{
  "claimType": "https://example.com/vuln-scan",
  "claimValue": {
    "scanner": "grype",
    "result": "passed"
  }
}
EOF

# Sign the attestation
cosign attest --key cosign.key --predicate predicate.json my-image:latest

# Verify the attestation
cosign verify-attestation --key cosign.pub my-image:latest
```

### 7.5 Signing Blobs

```bash
# Sign a file
cosign blob sign --key cosign.key my-file.txt

# Verify a blob signature
cosign blob verify --key cosign.pub my-file.txt
```

### 7.6 Managing Keys

```bash
# Generate a new key pair
cosign generate-key-pair

# Generate with a specific algorithm
cosign generate-key-pair --algorithm ecdsa

# Generate with a KMS
cosign generate-key-pair --kms gcpkms://projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key

# List keys in a KMS
cosign kms list --kms gcpkms://projects/my-project/locations/global/keyRings/my-ring
```

### 7.7 Working with Transparency Log

```bash
# Upload to transparency log
cosign sign --key cosign.key --upload-to rekor my-image:latest

# Search transparency log
cosign search --rekor https://rekor.sigstore.dev my-image:latest

# Verify against transparency log
cosign verify --key cosign.pub --rekor https://rekor.sigstore.dev my-image:latest
```

---

## 8. Custom Rules and Policies

### 8.1 Kyverno Policy for Image Signing

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-signature
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: check-image-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Image must be signed with Cosign"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!*:latest"
    verifyImages:
    - imageReferences:
      - "my-registry/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----
```

### 8.2 OPA/Rego Policy for Image Signing

```rego
# cosign-policy.rego
package main

default deny = false

# Deny if image is not signed
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "my-registry/")
    msg := sprintf("Image %s is not from trusted registry", [container.image])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    startswith(container.image, "my-registry/")
    not image_signed(container.image)
    msg := sprintf("Image %s is not signed", [container.image])
}

image_signed(image) {
    # Verify signature using Cosign
    output := exec.command("cosign", "verify", "--key", "/etc/cosign/cosign.pub", image)
    count(output) > 0
}
```

### 8.3 Custom Annotation Policies

```bash
# Sign with required annotations
cosign sign --key cosign.key \
  -a team=backend \
  -a environment=production \
  -a compliance=soc2 \
  my-image:latest

# Verify with annotation requirements
cosign verify --key cosign.pub \
  -a team=backend \
  -a environment=production \
  my-image:latest
```

### 8.4 Certificate Identity Policies

```bash
# Verify with specific certificate identity
cosign verify \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  my-image:latest

# Verify with wildcard identity
cosign verify \
  --certificate-identity-regexp=.*@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  my-image:latest
```

---

## 9. Integration

### 9.1 GitHub Actions

```yaml
# .github/workflows/cosign-sign.yml
name: Cosign Sign
on:
  push:
    branches: [main]

jobs:
  sign:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      packages: write

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

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      - name: Sign image with keyless signing
        uses: sigstore/cosign-sign@v2
        with:
          registry-username: ${{ github.actor }}
          container: ghcr.io/${{ github.repository }}:${{ github.sha }}
          upload-to-rekor: true

      - name: Verify signature
        run: |
          cosign verify \
            --certificate-identity=${{ github.actor }}@users.noreply.github.com \
            --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
            ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### 9.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
cosign-sign:
  stage: security
  image: gcr.io/projectsigstore/cosign:latest
  script:
    - cosign sign --key $COSIGN_KEY $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  variables:
    COSIGN_KEY: $COSIGN_PRIVATE_KEY
    COSIGN_PASSWORD: $COSIGN_PASSWORD
  only:
    - main

cosign-verify:
  stage: security
  image: gcr.io/projectsigstore/cosign:latest
  script:
    - cosign verify --key $COSIGN_PUB $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  variables:
    COSIGN_PUB: $COSIGN_PUBLIC_KEY
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
                withCredentials([file(credentialsId: 'cosign-key', variable: 'COSIGN_KEY')]) {
                    sh '''
                        cosign sign --key $COSIGN_KEY my-app:${BUILD_NUMBER}
                    '''
                }
            }
        }
        stage('Verify') {
            steps {
                withCredentials([file(credentialsId: 'cosign-pub', variable: 'COSIGN_PUB')]) {
                    sh '''
                        cosign verify --key $COSIGN_PUB my-app:${BUILD_NUMBER}
                    '''
                }
            }
        }
    }
}
```

### 9.4 ArgoCD Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  annotations:
    cosign.sigstore.dev/image-ref: my-app:latest
    cosign.sigstore.dev/key: /etc/cosign/cosign.pub
    cosign.sigstore.dev/verify: "true"
```

### 9.5 k3s with Cosign

```bash
# Install Kyverno for policy enforcement
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# Apply Cosign policy
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-cosign-signature
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-cosign-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "my-registry/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----
EOF
```

### 9.6 Harbor Integration

```bash
# Configure Harbor to require Cosign signatures
# Harbor UI -> Projects -> Configuration -> Deployment Security

# Or via Harbor API
curl -X PUT "https://harbor.example.com/api/v2.0/projects/myproject" \
  -H "Authorization: Basic $(echo -n admin:password | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "enable_content_trust": "true"
    }
  }'
```

---

## 10. Security Hardening

### 10.1 Key Management Best Practices

```bash
# Use KMS for key management
cosign generate-key-pair --kms gcpkms://projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key

# Use hardware security module (HSM)
cosign generate-key-pair --kms pkcs11:token=my-token;object=my-key

# Rotate keys regularly
cosign generate-key-pair --kms gcpkms://projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key-new
```

### 10.2 Keyless Signing Best Practices

```bash
# Use keyless signing in CI/CD
cosign sign my-image:latest

# Verify with specific identity
cosign verify \
  --certificate-identity=ci-cd-pipeline@example.com \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  my-image:latest
```

### 10.3 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cosign-network-policy
  namespace: cosign-system
spec:
  podSelector:
    matchLabels:
      app: cosign
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

### 10.4 RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cosign-signer
  namespace: cosign-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cosign-signer
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["kyverno.io"]
  resources: ["clusterpolicies", "policies"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cosign-signer
subjects:
- kind: ServiceAccount
  name: cosign-signer
  namespace: cosign-system
roleRef:
  kind: ClusterRole
  name: cosign-signer
  apiGroup: rbac.authorization.k8s.io
```

### 10.5 Secret Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cosign-key
  namespace: cosign-system
type: Opaque
data:
  cosign.key: <base64-encoded-private-key>
  cosign.pub: <base64-encoded-public-key>
```

---

## 11. Troubleshooting

### 11.1 Issue: Key Not Found

**Symptom**: `no key found` or `key not found`

**Fix**:
```bash
cosign generate-key-pair
cosign sign --key cosign.key my-image:latest
```

### 11.2 Issue: Password Required

**Symptom**: `password required`

**Fix**:
```bash
cosign sign --key cosign.key my-image:latest
# Enter password when prompted

# Or use environment variable
export COSIGN_PASSWORD=my-password
cosign sign --key cosign.key my-image:latest
```

### 11.3 Issue: Registry Authentication Failed

**Symptom**: `unauthorized` or `authentication required`

**Fix**:
```bash
docker login registry.example.com
cosign sign --key cosign.key registry.example.com/my-image:latest
```

### 11.4 Issue: Signature Already Exists

**Symptom**: `signature already exists`

**Fix**:
```bash
# Force re-sign
cosign sign --key cosign.key --force my-image:latest
```

### 11.5 Issue: Verification Failed

**Symptom**: `verification failed` or `signature mismatch`

**Fix**:
```bash
# Verify with correct key
cosign verify --key cosign.pub my-image:latest

# Check signature details
cosign verify --key cosign.pub --output json my-image:latest
```

### 11.6 Issue: Transparency Log Not Available

**Symptom**: `rekor not available` or `transparency log error`

**Fix**:
```bash
# Use different Rekor instance
cosign sign --key cosign.key --rekor https://rekor.sigstore.dev my-image:latest

# Or skip transparency log
cosign sign --key cosign.key --tlog-upload=false my-image:latest
```

### 11.7 Issue: Fulcio Certificate Expired

**Symptom**: `certificate expired` or `fulcio error`

**Fix**:
```bash
# Get new OIDC token
cosign sign my-image:latest

# Verify with new certificate
cosign verify \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://accounts.google.com \
  my-image:latest
```

### 11.8 Issue: Image Not Found

**Symptom**: `image not found` or `manifest unknown`

**Fix**:
```bash
# Check image exists
docker pull my-image:latest

# Sign with correct tag
cosign sign --key cosign.key my-image:latest
```

### 11.9 Issue: Permission Denied

**Symptom**: `permission denied` or `access denied`

**Fix**:
```bash
# Check registry permissions
docker login registry.example.com

# Check key permissions
chmod 600 cosign.key
```

### 11.10 Issue: Network Timeout

**Symptom**: `timeout` or `connection refused`

**Fix**:
```bash
# Increase timeout
cosign sign --key cosign.key --timeout 30m my-image:latest

# Use different registry mirror
cosign sign --key cosign.key registry-mirror.example.com/my-image:latest
```

### 11.11 Issue: Invalid Key Format

**Symptom**: `invalid key format` or `key parse error`

**Fix**:
```bash
# Regenerate key pair
cosign generate-key-pair

# Use correct key format
cosign sign --key cosign.key my-image:latest
```

### 11.12 Issue: SBOM Attach Failed

**Symptom**: `sbom attach failed` or `sbom error`

**Fix**:
```bash
# Check SBOM file exists
ls -la sbom.json

# Attach with correct format
cosign attach sbom --sbom sbom.json my-image:latest
```

### 11.13 Issue: Attestation Verify Failed

**Symptom**: `attestation verify failed` or `attestation error`

**Fix**:
```bash
# Verify with correct predicate type
cosign verify-attestation --key cosign.pub --type vuln my-image:latest

# Check attestation details
cosign verify-attestation --key cosign.pub --output json my-image:latest
```

### 11.14 Issue: Key Rotation Required

**Symptom**: `key rotation required` or `key compromised`

**Fix**:
```bash
# Generate new key pair
cosign generate-key-pair --kms gcpkms://projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key-new

# Re-sign images with new key
cosign sign --key cosign.key my-image:latest

# Update policies with new public key
```

### 11.15 Issue: Multiple Signatures

**Symptom**: `multiple signatures found` or `ambiguous signature`

**Fix**:
```bash
# List all signatures
cosign verify --key cosign.pub --output json my-image:latest

# Verify specific signature
cosign verify --key cosign.pub --certificate-identity=user@example.com my-image:latest
```

---

## 12. Tips and Best Practices

### 12.1 Use Keyless Signing in CI/CD

Keyless signing is ideal for CI/CD pipelines because it eliminates the need to manage long-lived keys.

### 12.2 Use KMS for Key Management

Store signing keys in a KMS (e.g., GCP KMS, AWS KMS, Azure Key Vault) for better security.

### 12.3 Sign Every Build

Sign every build artifact to ensure traceability and integrity.

### 12.4 Verify Before Deployment

Always verify signatures before deploying images to production.

### 12.5 Use Annotations for Metadata

Use annotations to add metadata to signatures (e.g., team, environment, compliance).

### 12.6 Use Transparency Log

Use Rekor transparency log for auditability and non-repudiation.

### 12.7 Rotate Keys Regularly

Rotate signing keys regularly to limit the impact of key compromise.

### 12.8 Use Short-Lived Certificates

Use Fulcio short-lived certificates for keyless signing.

### 12.9 Integrate with Policy Engines

Use Kyverno or OPA/Gatekeeper to enforce signature verification.

### 12.10 Store Signatures in Registry

Store signatures in the same container registry as the images for simplicity.

### 12.11 Use SBOM Signing

Sign SBOMs to ensure the integrity of software composition data.

### 12.12 Use Attestation for Build Provenance

Use Cosign attestations to create build provenance records.

### 12.13 Monitor Signing Events

Monitor Rekor transparency log for unauthorized signing events.

### 12.14 Use Multiple Signatures

Use multiple signatures from different signers for higher assurance.

### 12.15 Document Signing Policies

Document your organization's signing policies and procedures.

---

## 13. Command Reference

### 13.1 Global Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Private key file | - |
| `--password` | Private key password | - |
| `--output` | Output format | - |
| `--timeout` | Operation timeout | 3m0s |
| `--force` | Force overwrite | false |

### 13.2 Sign Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Private key file | - |
| `--password` | Private key password | - |
| `--annotations` | Annotations to add | - |
| `--tlog-upload` | Upload to transparency log | true |
| `--rekor-url` | Rekor URL | https://rekor.sigstore.dev |
| `--fulcio-url` | Fulcio URL | https://fulcio.sigstore.dev |
| `--oidc-issuer` | OIDC issuer URL | - |
| `--oidc-client-id` | OIDC client ID | sigstore |

### 13.3 Verify Flags

| Flag | Description | Default |
|---|---|---|
| `--key` | Public key file | - |
| `--certificate-identity` | Certificate identity | - |
| `--certificate-oidc-issuer` | Certificate OIDC issuer | - |
| `--output` | Output format | - |
| `--rekor-url` | Rekor URL | https://rekor.sigstore.dev |

### 13.4 Attach Flags

| Flag | Description | Default |
|---|---|---|
| `--sbom` | SBOM file | - |
| `--predicate` | Predicate file | - |
| `--type` | Attestation type | - |

---

## 14. Configuration Reference

### 14.1 Full Configuration Example

```yaml
# cosign.yaml
key: /path/to/cosign.key
password: my-password
oidc-issuer: https://token.actions.githubusercontent.com
oidc-client-id: sigstore
rekor-url: https://rekor.sigstore.dev
fulcio-url: https://fulcio.sigstore.dev
timeout: 3m0s
```

### 14.2 Environment Variables Reference

| Variable | Description | Default |
|---|---|---|
| COSIGN_KEY | Private key file | - |
| COSIGN_PASSWORD | Private key password | - |
| COSIGN_OIDC_ISSUER | OIDC issuer URL | - |
| COSIGN_OIDC_CLIENT_ID | OIDC client ID | sigstore |
| COSIGN_REKOR_URL | Rekor URL | https://rekor.sigstore.dev |
| COSIGN_FULCIO_URL | Fulcio URL | https://fulcio.sigstore.dev |
| COSIGN_TIMEOUT | Operation timeout | 3m0s |

---

## 15. Real-World Examples

### 15.1 Contoso Pet Store - Image Signing

**Scenario**: Contoso Pet Store runs a microservices architecture on Kubernetes with 15 container images in production.

#### 15.1.1 CI/CD Pipeline Integration

```yaml
name: Pet Store Image Signing
on:
  push:
    branches: [main]

jobs:
  sign:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      packages: write

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

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      - name: Sign image with keyless signing
        uses: sigstore/cosign-sign@v2
        with:
          registry-username: ${{ github.actor }}
          container: ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
          upload-to-rekor: true
          annotations: |
            team=${{ matrix.service }}
            environment=production
            compliance=soc2

      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
          format: cyclonedx
          output-file: sbom-${{ matrix.service }}.cdx.json

      - name: Attach SBOM
        run: |
          cosign attach sbom \
            --sbom sbom-${{ matrix.service }}.cdx.json \
            ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}

      - name: Verify signature
        run: |
          cosign verify \
            --certificate-identity=${{ github.actor }}@users.noreply.github.com \
            --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
            ghcr.io/petstore/${{ matrix.service }}:${{ github.sha }}
```

#### 15.1.2 Kubernetes Security Policies

```yaml
# petstore-cosign-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: petstore-cosign-signature
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: check-cosign-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    verifyImages:
    - imageReferences:
      - "ghcr.io/petstore/*"
      attestors:
      - entries:
        - keyless:
            url: https://fulcio.sigstore.dev
            identities:
            - issuer: https://token.actions.githubusercontent.com
              subjectRegExp: ".*@users.noreply.github.com"
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----
```

#### 15.1.3 Incident Response Workflow

```bash
#!/bin/bash
# petstore-incident-response.sh

IMAGE="$1"

echo "Verifying signature for $IMAGE..."

# Verify signature
if cosign verify \
  --certificate-identity-regexp=".*@users.noreply.github.com" \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  "$IMAGE"; then
    echo "Signature verified successfully"

    # Download and verify SBOM
    echo "Downloading SBOM..."
    cosign download sbom "$IMAGE" > sbom.json

    # Scan SBOM for vulnerabilities
    echo "Scanning SBOM for vulnerabilities..."
    grype sbom:sbom.json --fail-on high
else
    echo "Signature verification failed!"
    exit 1
fi
```

---

## 16. Further Reading

### 16.1 Official Documentation

- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Cosign GitHub Repository](https://github.com/sigstore/cosign)
- [Sigstore Documentation](https://docs.sigstore.dev/)
- [Fulcio Documentation](https://docs.sigstore.dev/fulcio/overview/)
- [Rekor Documentation](https://docs.sigstore.dev/rekor/overview/)

### 16.2 Blog Posts and Tutorials

- [Getting Started with Cosign](https://docs.sigstore.dev/cosign/quick_start/)
- [Cosign vs Notary: A Comparison](https://blog.sigstore.dev/cosign-vs-notary)
- [Keyless Signing with Cosign](https://docs.sigstore.dev/cosign/key_management/keyless_signing)

### 16.3 Community Resources

- [Sigstore Slack Channel](https://sigstore.slack.com/)
- [Sigstore Discussions](https://github.com/sigstore/cosign/discussions)
- [Sigstore Issues](https://github.com/sigstore/cosign/issues)

### 16.4 Related Tools

- [Notary](https://github.com/notaryproject/notary) - Container signing
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner
- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - Vulnerability scanner
- [Kyverno](https://kyverno.io/) - Policy engine

### 16.5 Standards and Specifications

- [OCI Artifacts](https://github.com/opencontainers/image-spec/blob/main/manifest.md) - OCI artifact specification
- [CycloneDX](https://cyclonedx.org/) - SBOM standard
- [SLSA](https://slsa.dev/) - Supply chain integrity framework
- [in-toto](https://in-toto.io/) - Supply chain integrity framework

---

*Last updated: September 2026*
*Cosign version: 2.4.0+*
