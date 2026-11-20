# cert-manager Complete Guide

## Table of Contents

1. [What Is cert-manager?](#1-what-is-cert-manager)
2. [Why Use cert-manager?](#2-why-use-cert-manager)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Advanced Features](#7-advanced-features)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting](#10-troubleshooting)
11. [Tips & Best Practices](#11-tips--best-practices)
12. [Commands Reference](#12-commands-reference)
13. [CRD Reference](#13-crd-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

## 1. What Is cert-manager?

cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates from various issuing sources. It ensures certificates are valid and up to date, and attempts to renew certificates at an appropriate time before expiry.

### The Problem cert-manager Solves

Managing TLS certificates manually is:

- **Error-prone**: Easy to forget renewal dates
- **Time-consuming**: Manual CSR generation, validation, installation
- **Security risk**: Expired certificates cause downtime
- **Inconsistent**: Different teams use different processes
- **Not scalable**: Impossible to manage hundreds of certificates manually

cert-manager automates this entire lifecycle:

```
┌─────────────────────────────────────────────────────────────┐
│                    cert-manager Flow                         │
│                                                              │
│  1. Create Certificate CR                                    │
│     │                                                        │
│     ▼                                                        │
│  2. cert-manager creates CertificateRequest                 │
│     │                                                        │
│     ▼                                                        │
│  3. cert-manager creates Order (for ACME)                    │
│     │                                                        │
│     ▼                                                        │
│  4. cert-manager solves challenges (HTTP-01, DNS-01)         │
│     │                                                        │
│     ▼                                                        │
│  5. Certificate Authority issues certificate                 │
│     │                                                        │
│     ▼                                                        │
│  6. cert-manager stores certificate in Secret                │
│     │                                                        │
│     ▼                                                        │
│  7. cert-manager auto-renews before expiry                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              cert-manager Controller                  │   │
│  │  - Watches Certificate/Issuer/ClusterIssuer           │   │
│  │  - Creates CertificateRequest/Order/Challenge         │   │
│  │  - Manages certificate lifecycle                      │   │
│  │  - Handles auto-renewal                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Certificate Issuers                      │   │
│  │  - ACME (Let's Encrypt)                              │   │
│  │  - Venafi                                            │   │
│  │  - HashiCorp Vault                                    │   │
│  │  - SelfSigned                                         │   │
│  │  - CA                                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Kubernetes Secrets                       │   │
│  │  - tls.crt (certificate)                             │   │
│  │  - tls.key (private key)                             │   │
│  │  - ca.crt (CA certificate)                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                              │                               │
│                              ▼                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Ingress/Services                         │   │
│  │  - nginx-ingress uses TLS secrets                    │   │
│  │  - Services reference certificates                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **cert-manager** | Main controller managing certificate lifecycle |
| **cainjector** | Injects CA certificates into webhooks |
| **webhook** | Validates cert-manager resources |
| **Issuer** | Defines how certificates are issued |
| **Certificate** | Defines desired certificate state |
| **CertificateRequest** | Request to issue a certificate |
| **Order** | ACME order for certificate issuance |
| **Challenge** | ACME challenge for domain validation |

### Supported Issuers

| Issuer | Use Case | Complexity |
|--------|----------|------------|
| **ACME (Let's Encrypt)** | Public trusted certificates | Medium |
| **SelfSigned** | Testing, development | Low |
| **CA** | Internal PKI, private CA | Low |
| **Vault** | Enterprise PKI, HashiCorp Vault | High |
| **Venafi** | Enterprise certificate management | High |
| **External** | Custom issuers | High |

---

## 2. Why Use cert-manager?

### Use Cases

**1. Automated TLS for Ingress**
Automatically provision and renew TLS certificates for all Ingress resources.

**2. Internal PKI**
Create a private CA and issue certificates for internal services.

**3. Let's Encrypt Integration**
Automatically obtain and renew free trusted certificates from Let's Encrypt.

**4. Multi-Cluster Certificate Management**
Manage certificates across multiple clusters with centralized issuers.

**5. Compliance**
Maintain audit trails of certificate issuance and renewal.

**6. Secret Management**
Store certificates as Kubernetes Secrets for easy consumption.

### Pros

| Advantage | Details |
|-----------|---------|
| **Automated Lifecycle** | Handles issuance, renewal, and revocation |
| **Multiple Issuers** | Supports Let's Encrypt, Vault, Venafi, etc. |
| **Kubernetes Native** | Uses CRDs, integrates with existing workflows |
| **Auto-Renewal** | Renews certificates before expiry automatically |
| **Free Certificates** | Let's Encrypt integration provides free trusted certs |
| **Audit Trail** | Tracks all certificate operations |
| **Scalable** | Manages thousands of certificates easily |
| **Well Maintained** | Active CNCF project with regular releases |

### Cons

| Limitation | Details |
|------------|---------|
| **Complexity** | Many CRDs to understand and manage |
| **Issuer Setup** | Initial issuer configuration can be tricky |
| **Rate Limits** | Let's Encrypt has rate limits (50 certs/week) |
| **Challenge Requirements** | HTTP-01 needs port 80, DNS-01 needs DNS access |
| **Debugging** | Certificate issues can be hard to diagnose |
| **Resource Usage** | Controller consumes CPU and memory |
| **Webhook Dependency** | Requires webhook for validation (can be HA issue) |

### Alternatives Comparison

| Tool | Features | Complexity | Free Certs |
|------|----------|------------|------------|
| **cert-manager** | Very High | Medium | Yes (Let's Encrypt) |
| **kube-cert-manager** | Medium | Low | Yes |
| **external-dns** | DNS only | Low | No |
| **Vault PKI** | Enterprise | High | No |

**Recommendation**: cert-manager for most Kubernetes deployments. Use Vault for enterprise PKI needs.

---

## 3. Installation

### Prerequisites

1. **Kubernetes cluster running** (k3s, kubeadm, etc.)
2. **kubectl configured** to talk to your cluster
3. **Helm 3.x installed** (recommended)
4. **Internet access** (for Let's Encrypt)
5. **Port 80 accessible** (for HTTP-01 challenges)

### Method 1: Helm (Recommended)

```bash
# Add the Jetstack repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Check available versions
helm search repo jetstack/cert-manager --versions

# Install cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.1 \
  --set crds.enabled=true \
  --set crds.keep=true \
  --set replicaCount=1 \
  --set webhook.replicaCount=1 \
  --set cainjector.replicaCount=1

# Wait for pods to be ready
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=300s

# Verify installation
kubectl get pods -n cert-manager
```

### Method 2: kubectl apply (Official Manifest)

```bash
# Install cert-manager with CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.yaml

# Verify installation
kubectl get pods -n cert-manager
```

### Method 3: Kustomize

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: cert-manager

resources:
  - https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.yaml

patches:
  - target:
      kind: Deployment
      name: cert-manager
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
  - target:
      kind: Deployment
      name: cert-manager-webhook
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
  - target:
      kind: Deployment
      name: cert-manager-cainjector
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
```

### Method 4: k3s Integration

For k3s clusters, add to your installation script:

```bash
# After k3s installation
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set crds.keep=true

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=300s

# Verify installation
kubectl get pods -n cert-manager
kubectl get crds | grep cert-manager
```

### Verify Installation

```bash
# Check all cert-manager pods are running
kubectl get pods -n cert-manager -o wide
# NAME                                       READY   STATUS    RESTARTS   AGE
# cert-manager-xxx                           1/1     Running   0          5m
# cert-manager-cainjector-xxx                1/1     Running   0          5m
# cert-manager-webhook-xxx                   1/1     Running   0          5m

# Check CRDs are installed
kubectl get crds | grep cert-manager
# NAME                                    CREATED AT
# certificaterequests.cert-manager.io     2024-01-01T00:00:00Z
# certificates.cert-manager.io            2024-01-01T00:00:00Z
# challenges.acme.cert-manager.io         2024-01-01T00:00:00Z
# clusterissuers.cert-manager.io          2024-01-01T00:00:00Z
# issuers.cert-manager.io                 2024-01-01T00:00:00Z
# orders.acme.cert-manager.io             2024-01-01T00:00:00Z

# Check webhooks
kubectl get validatingwebhookconfigurations | grep cert-manager
kubectl get mutatingwebhookconfigurations | grep cert-manager

# Test with a self-signed issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  commonName: test.example.com
  dnsNames:
    - test.example.com
EOF

# Check certificate status
kubectl describe certificate test-cert
kubectl get certificate test-cert
# NAME         READY   SECRET          AGE
# test-cert    True    test-cert-tls   30s
```

---

## 4. Configuration

### ClusterIssuer Configuration

#### SelfSigned Issuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

#### CA Issuer

```yaml
# First, create a CA certificate
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: my-ca
  secretName: my-ca-secret
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
---
# Then use the CA to issue certificates
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: my-ca-issuer
spec:
  ca:
    secretName: my-ca-secret
```

#### ACME Issuer (Let's Encrypt)

```yaml
# Staging (for testing)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Production
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

#### ACME with DNS-01 Challenge

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-dns-key
    solvers:
      # Cloudflare
      - dns01:
          cloudflare:
            email: admin@example.com
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: api-token
        selector:
          dnsZones:
            - "example.com"
      
      # Route53
      - dns01:
          route53:
            region: us-east-1
            accessKeyIDSecretRef:
              name: route53-credentials
              key: access-key-id
            secretAccessKeySecretRef:
              name: route53-credentials
              key: secret-access-key
      
      # Google Cloud DNS
      - dns01:
          cloudDNS:
            project: my-project
            serviceAccountSecretRef:
              name: clouddns-service-account
              key: key.json
```

#### Vault Issuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    path: pki/sign/my-role
    server: https://vault.example.com
    auth:
      kubernetes:
        role: my-role
        mountPath: /v1/auth/kubernetes
        secretRef:
          name: vault-sa-token
          key: token
```

#### Venafi Issuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: venafi-issuer
spec:
  venafi:
    zone: "Default"
    tpp:
      url: https://tpp.example.com
      credentialsSecretRef:
        name: venafi-credentials
        key: access-token
```

### Namespace-Scoped Issuers

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: my-issuer
  namespace: production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Certificate Configuration

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-cert
  namespace: default
spec:
  # Secret to store the certificate
  secretName: my-cert-tls
  
  # Issuer to use
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  
  # Certificate details
  commonName: app.example.com
  dnsNames:
    - app.example.com
    - www.app.example.com
    - api.app.example.com
  ipAddresses:
    - 192.168.1.100
  
  # Duration and renewal
  duration: 2160h  # 90 days
  renewBefore: 720h  # 30 days before expiry
  
  # Private key settings
  privateKey:
    algorithm: RSA
    size: 2048
    rotationPolicy: Always
  
  # Additional options
  isCA: false
  usages:
    - server auth
    - digital signature
    - key encipherment
```

### ACME Challenge Configuration

#### HTTP-01 Challenge

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-http
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
      - http01:
          ingress:
            class: nginx
            podTemplate:
              spec:
                nodeSelector:
                  kubernetes.io/os: linux
```

#### DNS-01 Challenge

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
      - dns01:
          cloudflare:
            email: admin@example.com
            apiTokenSecretRef:
              name: cloudflare-token
              key: token
        selector:
          dnsZones:
            - "example.com"
          dnsNames:
            - "*.example.com"
            - "example.com"
```

### Webhook Configuration

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: webhook-issuer
spec:
  webhook:
    url: https://webhook.example.com
    caBundle: <base64-encoded-ca>
```

---

## 5. Core Concepts

### Certificate Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                 Certificate Lifecycle                        │
│                                                              │
│  1. Create Certificate CR                                    │
│     │                                                        │
│     ▼                                                        │
│  2. cert-manager creates CertificateRequest                 │
│     │                                                        │
│     ▼                                                        │
│  3. CertificateRequest creates Order (ACME)                  │
│     │                                                        │
│     ▼                                                        │
│  4. Order creates Challenges                                 │
│     │                                                        │
│     ▼                                                        │
│  5. Challenges are solved (HTTP-01/DNS-01)                   │
│     │                                                        │
│     ▼                                                        │
│  6. Certificate is issued                                    │
│     │                                                        │
│     ▼                                                        │
│  7. Certificate is stored in Secret                          │
│     │                                                        │
│     ▼                                                        │
│  8. Auto-renewal before expiry                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Issuer vs ClusterIssuer

| Feature | Issuer | ClusterIssuer |
|---------|--------|---------------|
| **Scope** | Namespace | Cluster-wide |
| **Use Case** | Team/project specific | Organization-wide |
| **RBAC** | Namespace-scoped | Cluster-scoped |
| **Example** | `Issuer` in `production` namespace | `ClusterIssuer` in `cert-manager` namespace |

### Challenge Types

| Type | Requirements | Use Case |
|------|--------------|----------|
| **HTTP-01** | Port 80 accessible | Simple setups |
| **DNS-01** | DNS API access | Wildcards, internal |
| **TLS-ALPN-01** | Port 443 accessible | Advanced setups |

### Certificate States

| State | Description |
|-------|-------------|
| **Ready** | Certificate is valid and stored in Secret |
| **Pending** | Certificate is being issued |
| **Failed** | Certificate issuance failed |
| **Unknown** | Certificate status unknown |

### Secret Structure

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-cert-tls
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
  ca.crt: <base64-encoded-ca-certificate>  # Optional
```

---

## 6. Usage Guide

### Step 1: Install cert-manager

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

### Step 2: Create a ClusterIssuer

```yaml
# letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

```bash
kubectl apply -f letsencrypt-issuer.yaml
kubectl describe clusterissuer letsencrypt-prod
```

### Step 3: Create a Certificate

```yaml
# my-cert.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-cert
  namespace: default
spec:
  secretName: my-app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: app.example.com
  dnsNames:
    - app.example.com
    - www.app.example.com
  duration: 2160h
  renewBefore: 720h
  privateKey:
    algorithm: RSA
    size: 2048
```

```bash
kubectl apply -f my-cert.yaml
kubectl describe certificate my-app-cert
```

### Step 4: Create an Ingress Using the Certificate

```yaml
# my-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
        - www.app.example.com
      secretName: my-app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

```bash
kubectl apply -f my-ingress.yaml
```

### Step 5: Verify Certificate Issuance

```bash
# Check certificate status
kubectl get certificate
# NAME           READY   SECRET          AGE
# my-app-cert    True    my-app-tls     5m

# Check certificate details
kubectl describe certificate my-app-cert

# Check certificate request
kubectl get certificaterequest

# Check order
kubectl get order

# Check challenges
kubectl get challenge

# Verify the TLS secret
kubectl get secret my-app-tls -o yaml

# Verify the certificate
kubectl get secret my-app-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### Step 6: Test HTTPS Access

```bash
# Add to /etc/hosts for local testing
echo "192.168.1.200 app.example.com www.app.example.com" | sudo tee -a /etc/hosts

# Test HTTPS
curl -v https://app.example.com

# Verify certificate
curl -vI https://app.example.com 2>&1 | grep -E "subject|issuer|expire"
```

### Step 7: Monitor Certificate Renewal

```bash
# Check certificate expiry
kubectl get certificate -o wide

# Check renewal events
kubectl get events --field-selector reason=Renewing

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f | grep -i renew
```

### Step 8: Manual Renewal

```bash
# Force certificate renewal
kubectl cert-manager renew my-app-cert

# Or delete the secret to trigger re-issuance
kubectl delete secret my-app-tls
```

### Step 9: Multiple Certificates

```yaml
# Multiple certificates for different services
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-cert
  namespace: production
spec:
  secretName: api-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: api.example.com
  dnsNames:
    - api.example.com
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: web-cert
  namespace: production
spec:
  secretName: web-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: www.example.com
  dnsNames:
    - www.example.com
    - example.com
```

### Step 10: Wildcard Certificates

```yaml
# Wildcard certificate (requires DNS-01 challenge)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
  namespace: default
spec:
  secretName: wildcard-tls
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  commonName: "*.example.com"
  dnsNames:
    - "*.example.com"
    - example.com
```

---

## 7. Advanced Features

### Multiple Issuers

```yaml
# Production issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Staging issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Internal CA issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca
spec:
  ca:
    secretName: internal-ca-secret
```

### Certificate Templates

```yaml
# Base certificate template
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: base-cert-template
  namespace: cert-manager
spec:
  isCA: false
  duration: 8760h  # 1 year
  renewBefore: 720h  # 30 days
  privateKey:
    algorithm: RSA
    size: 2048
    rotationPolicy: Always
  usages:
    - server auth
    - digital signature
    - key encipherment
```

### Certificate for Service Mesh

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mesh-cert
  namespace: istio-system
spec:
  secretName: mesh-cert-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  commonName: "*.istio-system.svc.cluster.local"
  dnsNames:
    - "*.istio-system.svc.cluster.local"
    - "istio-system.svc.cluster.local"
  usages:
    - server auth
    - client auth
```

### Auto-Discovery with Ingress Annotations

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auto-discovery
  annotations:
    # Auto-create certificate
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # Or use a specific issuer
    cert-manager.io/issuer: my-issuer
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app
                port:
                  number: 80
```

### Certificate with IP Addresses

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ip-cert
spec:
  secretName: ip-cert-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  commonName: my-server.local
  dnsNames:
    - my-server.local
  ipAddresses:
    - 192.168.1.100
    - 10.0.0.50
```

### Certificate with Custom Key Usage

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: custom-usage-cert
spec:
  secretName: custom-usage-tls
  issuerRef:
    name: internal-ca
    kind: ClusterIssuer
  commonName: my-app.local
  usages:
    - server auth
    - client auth
    - digital signature
    - key encipherment
    - code signing
    - email protection
    - timeStamping
```

### Certificate with Duration and Renewal

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: custom-duration-cert
spec:
  secretName: custom-duration-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: app.example.com
  # Certificate valid for 1 year
  duration: 8760h
  # Renew 60 days before expiry
  renewBefore: 1440h
  # Or renew at a specific time
  # renewBefore: "2024-06-01T00:00:00Z"
```

### Certificate with Private Key Rotation

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: rotation-cert
spec:
  secretName: rotation-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: app.example.com
  privateKey:
    algorithm: ECDSA
    size: 256
    # Rotate private key on each renewal
    rotationPolicy: Always
    # Or keep the same key
    # rotationPolicy: Never
```

---

## 8. Integration

### Integration with nginx-ingress

cert-manager automatically provisions TLS for nginx-ingress:

```bash
# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# Create Ingress with automatic TLS
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
EOF
```

### Integration with MetalLB

MetalLB provides the external IP, cert-manager provides TLS:

```bash
# MetalLB provides external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
# NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# ingress-nginx-controller   LoadBalancer   10.43.0.50     192.168.1.200    80:30080/TCP,443:30443/TCP

# cert-manager provisions TLS
kubectl get certificate
# NAME           READY   SECRET          AGE
# my-app-cert    True    my-app-tls     5m

# Verify
curl -v https://app.example.com
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
# * Server certificate:
# *  subject: CN=app.example.com
# *  issuer: C=US; O=Let's Encrypt; CN=R11
```

### Integration with k3s

```bash
# k3s includes Traefik by default
# Option 1: Use Traefik with cert-manager
# Option 2: Replace Traefik with nginx-ingress

# For nginx-ingress on k3s
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Create issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

### Integration with Prometheus

```yaml
# ServiceMonitor for cert-manager metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cert-manager
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: cert-manager
  namespaceSelector:
    matchNames:
      - cert-manager
  endpoints:
    - port: metrics
      interval: 30s
---
# PrometheusRule for certificate expiry alerts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cert-manager-alerts
  namespace: monitoring
spec:
  groups:
    - name: cert-manager
      rules:
        - alert: CertificateExpiringSoon
          expr: |
            certmanager_certificate_expiration_timestamp_seconds - time() < 86400 * 7
          for: 1h
          labels:
            severity: warning
          annotations:
            summary: "Certificate expiring soon"
            description: "Certificate {{ $labels.name }} expires in less than 7 days"
        
        - alert: CertificateExpired
          expr: |
            certmanager_certificate_expiration_timestamp_seconds < time()
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Certificate has expired"
            description: "Certificate {{ $labels.name }} has expired"
```

---

## 9. Security

### RBAC Configuration

```yaml
# Allow specific namespaces to create certificates
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cert-manager-certificates
  namespace: production
rules:
  - apiGroups: ["cert-manager.io"]
    resources: ["certificates", "certificaterequests"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cert-manager-certificates
  namespace: production
subjects:
  - kind: ServiceAccount
    name: cert-manager
    namespace: cert-manager
roleRef:
  kind: Role
  name: cert-manager-certificates
  apiGroup: rbac.authorization.k8s.io
```

### Secret Encryption

```yaml
# Encrypt secrets at rest
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-secret>
      - identity: {}
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-cert-manager
  namespace: cert-manager
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: cert-manager
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow webhook connections
    - ports:
        - port: 10250
          protocol: TCP
  egress:
    # Allow ACME challenges
    - ports:
        - port: 80
          protocol: TCP
        - port: 443
          protocol: TCP
    # Allow DNS
    - ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
```

### Certificate Security

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: secure-cert
spec:
  secretName: secure-cert-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: secure.example.com
  # Use strong key algorithm
  privateKey:
    algorithm: ECDSA
    size: 256
    rotationPolicy: Always
  # Set appropriate duration
  duration: 2160h  # 90 days
  renewBefore: 720h  # 30 days
  # Define key usages
  usages:
    - server auth
    - digital signature
    - key encipherment
```

### Audit Logging

```yaml
# Enable audit logging for cert-manager
apiVersion: v1
kind: ConfigMap
metadata:
  name: cert-manager
  namespace: cert-manager
data:
  log-level: "2"
  log-format: "json"
```

---

## 10. Troubleshooting

### Issue 1: Certificate Stuck in Pending

**Symptoms:**
```bash
kubectl get certificate
# NAME           READY   SECRET          AGE
# my-cert        False   my-cert-tls     5m
```

**Diagnosis:**
```bash
# Check certificate request
kubectl get certificaterequest
kubectl describe certificaterequest <name>

# Check order
kubectl get order
kubectl describe order <name>

# Check challenge
kubectl get challenge
kubectl describe challenge <name>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager | grep -i <certificate-name>
```

**Solutions:**
1. Ensure issuer is ready: `kubectl describe clusterissuer letsencrypt-prod`
2. Check challenge solver is working
3. Verify DNS records are correct (for DNS-01)
4. Ensure port 80 is accessible (for HTTP-01)

### Issue 2: Challenge Fails

**Symptoms:**
```bash
kubectl get challenge
# NAME                                       STATE     AGE
# my-challenge-xxx                           Failed    5m
```

**Diagnosis:**
```bash
kubectl describe challenge <name>
kubectl logs -n cert-manager deployment/cert-manager | grep -i challenge
```

**Solutions:**
1. For HTTP-01: Ensure port 80 is accessible from the internet
2. For DNS-01: Verify DNS API credentials are correct
3. Check firewall rules
4. Verify Ingress is configured correctly

### Issue 3: Certificate Not Renewing

**Symptoms:**
- Certificate expires without renewal
- No renewal events in logs

**Diagnosis:**
```bash
# Check certificate expiry
kubectl get certificate -o yaml | grep -A5 "notAfter"

# Check renewal settings
kubectl describe certificate <name>

# Check cert-manager logs for renewal
kubectl logs -n cert-manager deployment/cert-manager | grep -i renew
```

**Solutions:**
1. Verify `renewBefore` is set correctly
2. Check cert-manager controller is running
3. Ensure issuer is still valid
4. Check for events: `kubectl get events --field-selector reason=Renewing`

### Issue 4: Secret Not Created

**Symptoms:**
- Certificate shows Ready=True
- Secret doesn't exist

**Diagnosis:**
```bash
kubectl get secret <secret-name>
kubectl describe certificate <name>
```

**Solutions:**
1. Check RBAC permissions
2. Verify secret name is correct
3. Check cert-manager logs for errors
4. Ensure namespace exists

### Issue 5: Wrong Certificate Issued

**Symptoms:**
- Certificate has wrong domain
- Certificate issued by wrong issuer

**Diagnosis:**
```bash
kubectl get certificate <name> -o yaml
kubectl describe certificaterequest <name>
```

**Solutions:**
1. Verify `issuerRef` is correct
2. Check `dnsNames` and `commonName`
3. Delete and recreate certificate if needed

### Issue 6: Let's Encrypt Rate Limited

**Symptoms:**
- Certificate requests fail with rate limit errors
- Too many certificates issued

**Diagnosis:**
```bash
kubectl describe order <name>
kubectl logs -n cert-manager deployment/cert-manager | grep -i rate
```

**Solutions:**
1. Use staging issuer for testing
2. Wait for rate limit to reset (1 week)
3. Reduce certificate requests
4. Use DNS-01 challenge (no rate limit per domain)

### Issue 7: Webhook Errors

**Symptoms:**
```bash
kubectl get validatingwebhookconfigurations
# Error: connection refused
```

**Diagnosis:**
```bash
kubectl get pods -n cert-manager -l app=webhook
kubectl logs -n cert-manager deployment/cert-manager-webhook
```

**Solutions:**
1. Ensure webhook pod is running
2. Check webhook service is accessible
3. Verify CA bundle is correct
4. Restart webhook pod

### Issue 8: CA Injector Not Working

**Symptoms:**
- Webhook CA not injected
- Validation errors

**Diagnosis:**
```bash
kubectl get pods -n cert-manager -l app=cainjector
kubectl logs -n cert-manager deployment/cert-manager-cainjector
```

**Solutions:**
1. Ensure cainjector pod is running
2. Check RBAC permissions
3. Verify Certificate resources exist
4. Restart cainjector pod

### Issue 9: Certificate Shows Unknown State

**Symptoms:**
```bash
kubectl get certificate
# NAME           READY   SECRET          AGE
# my-cert        Unknown my-cert-tls     5m
```

**Diagnosis:**
```bash
kubectl describe certificate <name>
kubectl get events --field-selector involvedObject.name=<name>
```

**Solutions:**
1. Check issuer is ready
2. Verify certificate request exists
3. Check cert-manager logs
4. Ensure no conflicts with existing secrets

### Issue 10: DNS-01 Challenge Timeout

**Symptoms:**
- DNS-01 challenge never completes
- Challenge stays in Pending state

**Diagnosis:**
```bash
kubectl describe challenge <name>
# Check DNS propagation
dig TXT _acme-challenge.example.com
```

**Solutions:**
1. Verify DNS API credentials
2. Check DNS record propagation time
3. Increase timeout settings
4. Verify DNS provider is supported

### Issue 11: HTTP-01 Challenge Fails Behind Proxy

**Symptoms:**
- HTTP-01 challenge fails
- Challenge solver pod can't reach ACME server

**Diagnosis:**
```bash
kubectl describe challenge <name>
kubectl logs -n cert-manager <challenge-pod-name>
```

**Solutions:**
1. Ensure port 80 is accessible
2. Check proxy configuration
3. Use DNS-01 challenge instead
4. Configure proper forwarding headers

### Issue 12: Certificate Secret Contains Wrong Data

**Symptoms:**
- Secret exists but has wrong certificate
- Certificate doesn't match domain

**Diagnosis:**
```bash
kubectl get secret <secret-name> -o yaml
kubectl get secret <secret-name> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

**Solutions:**
1. Delete secret and let cert-manager recreate
2. Verify certificate spec is correct
3. Check for conflicting certificates

### Issue 13: cert-manager Pod CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n cert-manager
# NAME                                       READY   STATUS             RESTARTS
# cert-manager-xxx                           0/1     CrashLoopBackOff   5
```

**Diagnosis:**
```bash
kubectl logs -n cert-manager pod/cert-manager-xxx --previous
```

**Solutions:**
1. Check RBAC permissions
2. Verify webhook is accessible
3. Check resource limits
4. Review cert-manager logs

### Issue 14: Webhook Certificate Expired

**Symptoms:**
- API server can't validate cert-manager resources
- Webhook connection errors

**Diagnosis:**
```bash
kubectl get secret -n cert-manager cert-manager-webhook-ca
kubectl describe validatingwebhookconfiguration cert-manager-webhook
```

**Solutions:**
1. Restart cert-manager pods
2. Delete webhook CA secret to regenerate
3. Check cainjector is running

### Issue 15: Certificate Not Matching Ingress

**Symptoms:**
- Ingress shows TLS but certificate is wrong
- Browser shows certificate warning

**Diagnosis:**
```bash
kubectl describe ingress <name>
kubectl get certificate <name> -o yaml
```

**Solutions:**
1. Verify `tls.secretName` matches certificate `secretName`
2. Check certificate `dnsNames` include all hosts
3. Ensure Ingress class is correct
4. Restart ingress controller after certificate changes

---

## 11. Tips & Best Practices

### Tip 1: Use Staging for Testing

Always test with Let's Encrypt staging first:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Tip 2: Set Appropriate Duration

```yaml
# Short duration for production
duration: 2160h  # 90 days
renewBefore: 720h  # 30 days

# Longer duration for internal certificates
duration: 8760h  # 1 year
renewBefore: 720h  # 30 days
```

### Tip 3: Use DNS-01 for Wildcards

```yaml
# Wildcards require DNS-01 challenge
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
spec:
  secretName: wildcard-tls
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  commonName: "*.example.com"
  dnsNames:
    - "*.example.com"
    - example.com
```

### Tip 4: Monitor Certificate Expiry

```bash
# Check certificate expiry
kubectl get certificate -o custom-columns=\
'NAME:.metadata.name,READY:.status.conditions[0].status,EXPIRY:.status.notAfter,SECRET:.spec.secretName'

# Set up alerts for expiring certificates
```

### Tip 5: Use Private Key Rotation

```yaml
privateKey:
  algorithm: ECDSA
  size: 256
  rotationPolicy: Always  # Rotate on each renewal
```

### Tip 6: Keep Issuers Separate

```yaml
# Production issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Staging issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Tip 7: Use Ingress Annotations

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
  cert-manager.io/issuer: my-issuer
```

### Tip 8: Backup Certificates

```bash
# Backup certificate secrets
kubectl get secret my-cert-tls -o yaml > backup.yaml

# Backup all certificates
for cert in $(kubectl get certificates -o name); do
  kubectl get $cert -o yaml > backup.yaml
done
```

### Tip 9: Test Certificate Renewal

```bash
# Force certificate renewal
kubectl cert-manager renew my-cert

# Check renewal status
kubectl get certificate my-cert -w
```

### Tip 10: Use ClusterIssuer for Multi-Tenancy

```yaml
# ClusterIssuer for organization-wide use
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Tip 11: Monitor cert-manager Metrics

```yaml
# Enable metrics
helm install cert-manager jetstack/cert-manager \
  --set prometheus.enabled=true \
  --set prometheus.servicemonitor.enabled=true
```

### Tip 12: Use External Secrets

```yaml
# Store issuer credentials in external secrets
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: cloudflare-credentials
  namespace: cert-manager
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: cloudflare-api-token
  data:
    - secretKey: api-token
      remoteRef:
        key: secret/data/cloudflare
        property: api-token
```

### Tip 13: Use Certificate Templates

```yaml
# Base template for all certificates
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: base-template
  namespace: cert-manager
spec:
  duration: 2160h
  renewBefore: 720h
  privateKey:
    algorithm: ECDSA
    size: 256
    rotationPolicy: Always
  usages:
    - server auth
    - digital signature
    - key encipherment
```

### Tip 14: Clean Up Old Certificates

```bash
# Delete expired certificates
kubectl get certificates -o json | jq -r '
  .items[] | 
  select(.status.conditions[0].status == "False") | 
  .metadata.name' | xargs kubectl delete certificate
```

### Tip 15: Use Multiple Solvers

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: multi-solver
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: multi-solver-key
    solvers:
      # HTTP-01 for most domains
      - http01:
          ingress:
            class: nginx
      # DNS-01 for wildcard domains
      - dns01:
          cloudflare:
            email: admin@example.com
            apiTokenSecretRef:
              name: cloudflare-token
              key: token
        selector:
          dnsZones:
            - "*.example.com"
```

---

## 12. Commands Reference

### Installation Commands

```bash
# Install via Helm
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true

# Uninstall
helm uninstall cert-manager -n cert-manager
```

### Certificate Management

```bash
# List all certificates
kubectl get certificates -A

# Describe a certificate
kubectl describe certificate my-cert

# Create a certificate
kubectl apply -f certificate.yaml

# Delete a certificate
kubectl delete certificate my-cert

# Force certificate renewal
kubectl cert-manager renew my-cert

# Check certificate status
kubectl get certificate my-cert -o yaml
```

### Issuer Management

```bash
# List all issuers
kubectl get issuers -A

# List all cluster issuers
kubectl get clusterissuers

# Describe a cluster issuer
kubectl describe clusterissuer letsencrypt-prod

# Check issuer status
kubectl get clusterissuer letsencrypt-prod -o yaml
```

### CertificateRequest Management

```bash
# List certificate requests
kubectl get certificaterequest -A

# Describe a certificate request
kubectl describe certificaterequest <name>

# Delete a certificate request
kubectl delete certificaterequest <name>
```

### Order Management

```bash
# List ACME orders
kubectl get order -A

# Describe an order
kubectl describe order <name>

# Delete an order
kubectl delete order <name>
```

### Challenge Management

```bash
# List ACME challenges
kubectl get challenge -A

# Describe a challenge
kubectl describe challenge <name>

# Delete a challenge
kubectl delete challenge <name>
```

### Secret Management

```bash
# List TLS secrets
kubectl get secret -A --field-selector type=kubernetes.io/tls

# Describe a TLS secret
kubectl describe secret my-cert-tls

# View certificate in secret
kubectl get secret my-cert-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# View private key
kubectl get secret my-cert-tls -o jsonpath='{.data.tls\.key}' | base64 -d
```

### Debugging Commands

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Check webhook logs
kubectl logs -n cert-manager deployment/cert-manager-webhook -f

# Check cainjector logs
kubectl logs -n cert-manager deployment/cert-manager-cainjector -f

# Check cert-manager events
kubectl get events -n cert-manager

# Check certificate events
kubectl get events --field-selector involvedObject.name=<certificate-name>
```

### Webhook Commands

```bash
# Test webhook
kubectl get validatingwebhookconfigurations | grep cert-manager
kubectl get mutatingwebhookconfigurations | grep cert-manager

# Check webhook service
kubectl get svc -n cert-manager cert-manager-webhook

# Test webhook endpoint
kubectl port-forward -n cert-manager svc/cert-manager-webhook 10250:443
curl -k https://localhost:10250/healthz
```

### Metrics Commands

```bash
# Check cert-manager metrics
kubectl port-forward -n cert-manager svc/cert-manager 9402:9402
curl http://localhost:9402/metrics

# Check certificate expiration metric
curl http://localhost:9402/metrics | grep certmanager_certificate_expiration
```

---

## 13. CRD Reference

### Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: string              # Required: Certificate name
  namespace: string         # Required: Namespace
spec:
  secretName: string        # Required: Secret to store certificate
  issuerRef:                # Required: Issuer reference
    name: string            # Required: Issuer name
    kind: string            # Required: Issuer or ClusterIssuer
    group: string           # Optional: cert-manager.io
  commonName: string        # Optional: Common Name
  dnsNames:                 # Optional: DNS names
    - string
  ipAddresses:              # Optional: IP addresses
    - string
  duration: string          # Optional: Certificate duration (e.g., 2160h)
  renewBefore: string       # Optional: Renewal period (e.g., 720h)
  isCA: bool                # Optional: Is CA certificate
  privateKey:               # Optional: Private key settings
    algorithm: string       # Optional: RSA, ECDSA, Ed25519
    size: int               # Optional: Key size
    rotationPolicy: string  # Optional: Always or Never
  usages:                   # Optional: Key usages
    - string
  secretTemplate:           # Optional: Secret template
    labels:
      key: string
    annotations:
      key: string
  keystores:                # Optional: Additional keystores
    jks:
      create: bool
      passwordSecretRef:
        name: string
        key: string
    pkcs12:
      create: bool
      passwordSecretRef:
        name: string
        key: string
```

### Issuer

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: string              # Required: Issuer name
  namespace: string         # Required: Namespace
spec:
  acme:                     # Optional: ACME issuer
    server: string          # Required: ACME server URL
    email: string           # Required: Email for ACME
    privateKeySecretRef:    # Required: Secret for private key
      name: string
    solvers:                # Required: Challenge solvers
      - http01:
          ingress:
            class: string
      - dns01:
          cloudflare:
            email: string
            apiTokenSecretRef:
              name: string
              key: string
  ca:                       # Optional: CA issuer
    secretName: string      # Required: CA secret
  selfSigned: {}            # Optional: Self-signed issuer
  vault:                    # Optional: Vault issuer
    path: string
    server: string
    auth:
      kubernetes:
        role: string
        mountPath: string
        secretRef:
          name: string
          key: string
  venafi:                   # Optional: Venafi issuer
    zone: string
    tpp:
      url: string
      credentialsSecretRef:
        name: string
        key: string
  webhook:                  # Optional: Webhook issuer
    url: string
    caBundle: string
```

### ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: string              # Required: Issuer name (cluster-scoped)
spec:
  # Same spec as Issuer
  acme: ...
  ca: ...
  selfSigned: ...
  vault: ...
  venafi: ...
  webhook: ...
```

### CertificateRequest

```yaml
apiVersion: cert-manager.io/v1
kind: CertificateRequest
metadata:
  name: string              # Required: Request name
  namespace: string         # Required: Namespace
spec:
  csr: string               # Required: PEM-encoded CSR
  issuerRef:                # Required: Issuer reference
    name: string
    kind: string
    group: string
  duration: string          # Optional: Certificate duration
  isCA: bool                # Optional: Is CA certificate
  usages:                   # Optional: Key usages
    - string
```

### Order (ACME)

```yaml
apiVersion: acme.cert-manager.io/v1
kind: Order
metadata:
  name: string              # Required: Order name
  namespace: string         # Required: Namespace
spec:
  request: string           # Required: CertificateRequest name
  issuerRef:                # Required: Issuer reference
    name: string
    kind: string
    group: string
  commonName: string        # Optional: Common Name
  dnsNames:                 # Optional: DNS names
    - string
  ipAddresses:              # Optional: IP addresses
    - string
```

### Challenge (ACME)

```yaml
apiVersion: acme.cert-manager.io/v1
kind: Challenge
metadata:
  name: string              # Required: Challenge name
  namespace: string         # Required: Namespace
spec:
  challengeType: string     # Required: http-01, dns-01, tls-alpn-01
  dnsName: string           # Required: DNS name to validate
  issuerRef:                # Required: Issuer reference
    name: string
    kind: string
    group: string
  solver:                   # Required: Challenge solver
    http01:
      ingress:
        class: string
    dns01:
      cloudflare:
        email: string
        apiTokenSecretRef:
          name: string
          key: string
  token: string             # Required: ACME token
  key: string               # Required: ACME key
```

---

## 14. Real-World Examples

### Example 1: Simple Web Application

```yaml
# ClusterIssuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: web-app-cert
  namespace: default
spec:
  secretName: web-app-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: app.example.com
  dnsNames:
    - app.example.com
    - www.app.example.com
---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
        - www.app.example.com
      secretName: web-app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app
                port:
                  number: 80
```

### Example 2: Internal PKI

```yaml
# Self-signed CA
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
# CA Certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: internal-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: internal-ca
  secretName: internal-ca-secret
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
---
# CA Issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca-issuer
spec:
  ca:
    secretName: internal-ca-secret
---
# Internal certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: internal-service
  namespace: production
spec:
  secretName: internal-service-tls
  issuerRef:
    name: internal-ca-issuer
    kind: ClusterIssuer
  commonName: internal-service.production.svc.cluster.local
  dnsNames:
    - internal-service.production.svc.cluster.local
    - internal-service
```

### Example 3: Wildcard Certificate

```yaml
# DNS-01 issuer for wildcard
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-dns-key
    solvers:
      - dns01:
          cloudflare:
            email: admin@example.com
            apiTokenSecretRef:
              name: cloudflare-token
              key: token
        selector:
          dnsZones:
            - "example.com"
---
# Wildcard certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
  namespace: default
spec:
  secretName: wildcard-tls
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  commonName: "*.example.com"
  dnsNames:
    - "*.example.com"
    - example.com
  duration: 2160h
  renewBefore: 720h
  privateKey:
    algorithm: ECDSA
    size: 256
    rotationPolicy: Always
```

### Example 4: Multi-Tenant Setup

```yaml
# Team A issuer
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: team-a-issuer
  namespace: team-a
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: team-a@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
      - http01:
          ingress:
            class: nginx
---
# Team A certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: team-a-app
  namespace: team-a
spec:
  secretName: team-a-app-tls
  issuerRef:
    name: team-a-issuer
    kind: Issuer
  commonName: team-a.example.com
  dnsNames:
    - team-a.example.com
    - api.team-a.example.com
---
# Team B issuer
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: team-b-issuer
  namespace: team-b
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: team-b@example.com
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### Example 5: Certificate with JKS Keystore

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: java-app-cert
  namespace: production
spec:
  secretName: java-app-tls
  issuerRef:
    name: internal-ca-issuer
    kind: ClusterIssuer
  commonName: java-app.internal
  dnsNames:
    - java-app.internal
  keystores:
    jks:
      create: true
      passwordSecretRef:
        name: jks-password
        key: password
---
apiVersion: v1
kind: Secret
metadata:
  name: jks-password
  namespace: production
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 of "password123"
```

---

## 15. Further Reading

### Official Documentation
- [cert-manager Website](https://cert-manager.io/)
- [cert-manager GitHub](https://github.com/cert-manager/cert-manager)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Certificate Resources](https://cert-manager.io/docs/usage/certificate/)
- [Issuer Resources](https://cert-manager.io/docs/configuration/)

### Tutorials
- [Installing cert-manager](https://cert-manager.io/docs/installation/)
- [ACME Issuer](https://cert-manager.io/docs/configuration/acme/)
- [CA Issuer](https://cert-manager.io/docs/configuration/ca/)
- [SelfSigned Issuer](https://cert-manager.io/docs/configuration/selfsigned/)

### Related Tools
- [nginx-ingress](./nginx-ingress.md)
- [MetalLB](./metallb.md)
- [Let's Encrypt](https://letsencrypt.org/)
- [HashiCorp Vault](https://www.vaultproject.io/)

### Community
- [cert-manager Slack](https://slack.k8s.io/channels/cert-manager)
- [Kubernetes Slack](https://slack.k8s.io/)

---

*Last Updated: 2026-09-03*
*Version: 1.0*
*Part of the DevOps Complete Guide Series*
