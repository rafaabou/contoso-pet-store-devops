# Argo Image Updater Complete Guide

## Table of Contents

1. [What Is Argo Image Updater](#1-what-is-argo-image-updater)
2. [Why Use Argo Image Updater](#2-why-use-argo-image-updater)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Configuration](#8-custom-configuration)
9. [Integration](#9-integration)
10. [Security](#10-security)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips and Best Practices](#12-tips-and-best-practices)
13. [Command Reference](#13-command-reference)
14. [CRD Reference](#14-crd-reference)
15. [Real-World Examples](#15-real-world-examples)
16. [Further Reading](#16-further-reading)

---

## 1. What Is Argo Image Updater

Argo Image Updater is a Kubernetes controller that automatically updates container images in Kubernetes deployments when new versions are available in a container registry. It monitors container registries for new image tags and updates the deployment manifests accordingly.

### Key Characteristics

- **Automated Image Updates**: Detects new image versions automatically
- **Registry Support**: Supports Docker Hub, GitHub Container Registry, Quay, and more
- **Annotation-based**: Uses annotations to control update behavior
- **GitOps Integration**: Works with ArgoCD for Git-based deployments
- **Webhook Support**: Receives webhooks from registries for real-time updates

### How It Works

```
┌─────────────────────────────────────────────────┐
│           Argo Image Updater                     │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Image Update Controller               ││
│  │  - Watches Kubernetes deployments             ││
│  │  - Checks registries for new tags             ││
│  │  - Updates deployment manifests               ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Registry Client                       ││
│  │  - Docker Hub                                 ││
│  │  - GitHub Container Registry                  ││
│  │  - Quay.io                                    ││
│  │  - Private registries                         ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Update Strategy                       ││
│  │  - Semver                                     ││
│  │  - Alphabetical                               ││
│  │  - Literal                                    ││
│  │  - Digest                                     ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

---

## 2. Why Use Argo Image Updater

### Problems Argo Image Updater Solves

| Problem | Argo Image Updater Solution |
|---------|----------------------------|
| Manual image updates | Automated detection and update |
| Image version drift | Continuous monitoring and sync |
| Security vulnerabilities | Quick patch deployment |
| Complex update scripts | Declarative configuration |
| Registry authentication | Built-in credential management |

### When to Use Argo Image Updater

- When you need automated image updates
- When using GitOps workflows
- When managing multiple deployments
- When requiring quick security patches
- When using container registries with webhooks

---

## 3. Architecture Overview

### Components

```
┌─────────────────────────────────────────────────┐
│           Argo Image Updater                     │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Controller Manager                    ││
│  │  - Main reconciliation loop                   ││
│  │  - Webhook server                             ││
│  │  - Registry client manager                    ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Update Strategy                       ││
│  │  - Semver (semantic versioning)               ││
│  │  - Alphabetical (sort by name)                ││
│  │  - Literal (exact match)                      ││
│  │  - Digest (image digest)                      ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │         Registry Clients                      ││
│  │  - Docker Hub                                 ││
│  │  - GitHub Container Registry                  ││
│  │  - Quay.io                                    ││
│  │  - AWS ECR                                    ││
│  │  - Google GCR                                 ││
│  │  - Azure ACR                                  ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Data Flow

1. **Watch Deployments**: Controller watches for annotated deployments
2. **Check Registries**: Periodically checks registries for new tags
3. **Compare Versions**: Compares current vs available versions
4. **Update Manifest**: Updates deployment manifest with new image
5. **Git Commit**: Commits changes to Git repository (optional)
6. **ArgoCD Sync**: ArgoCD detects changes and syncs to cluster

---

## 4. Installation

### Method 1: Kustomize

```bash
# Install Argo Image Updater
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argo-image-updater/stable/manifests/install.yaml
```

### Method 2: Helm

```bash
# Add Helm repo
helm repo add argo-image-updater https://argoproj-labs.github.io/argo-image-updater
helm repo update

# Install
helm install argo-image-updater argo-image-updater/argo-image-updater \
  --namespace argocd \
  --set config.registries[0].name=dockerhub \
  --set config.registries[0].api_url=https://registry-1.docker.io \
  --set config.registries[0].credentials.secret=argocd-image-updater-dockerhub \
  --set config.registries[0].credentials.namespace=argocd
```

### Method 3: Download Binary

```bash
# Download binary
curl -LO https://github.com/argoproj-labs/argo-image-updater/releases/latest/download/argo-image-updater-linux-amd64
chmod +x argo-image-updater-linux-amd64
sudo mv argo-image-updater-linux-amd64 /usr/local/bin/argo-image-updater
```

### Post-Installation Verification

```bash
# Check controller pod
kubectl -n argocd get pods

# Expected output:
# argo-image-updater-xxxxx    Running

# Check controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater
```

---

## 5. Configuration

### Controller Configuration

```yaml
# ConfigMap for Argo Image Updater
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: dockerhub
      api_url: https://registry-1.docker.io
      ping: false
      credentials: pullsecret:argocd/argocd-image-updater-dockerhub
      default: true
    - name: github
      api_url: https://ghcr.io
      ping: false
      credentials: pullsecret:argocd/argocd-image-updater-github
    - name: quay
      api_url: https://quay.io
      ping: false
      credentials: pullsecret:argocd/argocd-image-updater-quay
  application-specs: |
    apps:
    - image-list: "*"
      updateStrategy: semver
      pullSecret: pullsecret:argocd/argocd-image-updater-dockerhub
```

### Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argo-image-updater
  namespace: argocd
spec:
  template:
    spec:
      containers:
      - name: argo-image-updater
        image: quay.io/argoproj-labs/argo-image-updater:latest
        args:
        - --once
        - --interval=2m
        - --argocd-namespace=argocd
        - --kube-config=/etc/kubernetes/config
        env:
        - name: ARGOCD_IMAGE_UPDATER_LOGLEVEL
          value: "info"
        volumeMounts:
        - name: config
          mountPath: /app/config
      volumes:
      - name: config
        configMap:
          name: argo-image-updater-config
```

---

## 6. Core Concepts

### Annotations

Argo Image Updater uses annotations to control update behavior:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    # Enable image updates
    argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
    
    # Update strategy
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
    
    # Pull secret
    argocd-image-updater.argoproj.io/my-app.pull-secret: pullsecret:argocd/my-pull-secret
    
    # Allow tags
    argocd-image-updater.argoproj.io/my-app.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
    
    # Ignore tags
    argocd-image-updater.argoproj.io/my-app.ignore-tags: latest,stable
    
    # Platform
    argocd-image-updater.argoproj.io/my-app.platforms: linux/amd64,linux/arm64
```

### Update Strategies

1. **Semver**: Semantic versioning (v1.0.0, v1.2.3)
2. **Alphabetical**: Sort by name (latest, stable)
3. **Literal**: Exact match (v1.0.0)
4. **Digest**: Image digest (sha256:abc123)

### Image List

```yaml
# Single image
argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"

# Multiple images
argocd-image-updater.argoproj.io/image-list: |
  my-app=registry.example.com/my-app
  my-api=registry.example.com/my-api
  my-worker=registry.example.com/my-worker
```

---

## 7. Usage Guide

### Step-by-Step: Basic Image Update

#### 1. Create Deployment with Annotations

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: registry.example.com/my-app:v1.0.0
        ports:
        - containerPort: 8080
```

#### 2. Apply Deployment

```bash
kubectl apply -f deployment.yaml
```

#### 3. Verify Image Update

```bash
# Check deployment
kubectl get deployment my-app -o yaml

# Check image updater logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater

# Check updated image
kubectl get deployment my-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Step-by-Step: Multiple Image Updates

#### 1. Create Deployment with Multiple Images

```yaml
# deployment-multi.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    argocd-image-updater.argoproj.io/image-list: |
      my-app=registry.example.com/my-app
      my-api=registry.example.com/my-api
      my-worker=registry.example.com/my-worker
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
    argocd-image-updater.argoproj.io/my-api.update-strategy: semver
    argocd-image-updater.argoproj.io/my-worker.update-strategy: semver
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: registry.example.com/my-app:v1.0.0
        ports:
        - containerPort: 8080
      - name: my-api
        image: registry.example.com/my-api:v1.0.0
        ports:
        - containerPort: 8081
      - name: my-worker
        image: registry.example.com/my-worker:v1.0.0
        ports:
        - containerPort: 8082
```

#### 2. Apply Deployment

```bash
kubectl apply -f deployment-multi.yaml
```

#### 3. Verify Updates

```bash
# Check all containers
kubectl get deployment my-app -o jsonpath='{.spec.template.spec.containers[*].image}'

# Check image updater logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater
```

### Step-by-Step: Webhook Configuration

#### 1. Configure Webhook

```yaml
# webhook-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-webhook
  namespace: argocd
data:
  webhook.host: "0.0.0.0"
  webhook.port: "8080"
  webhook.secret: "my-webhook-secret"
```

#### 2. Create Webhook Service

```yaml
# webhook-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: argo-image-updater-webhook
  namespace: argocd
spec:
  selector:
    app.kubernetes.io/name: argo-image-updater
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

#### 3. Create Ingress

```yaml
# webhook-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argo-image-updater-webhook
  namespace: argocd
spec:
  rules:
  - host: argo-image-updater.example.com
    http:
      paths:
      - path: /webhook
        pathType: Prefix
        backend:
          service:
            name: argo-image-updater-webhook
            port:
              number: 8080
  tls:
  - hosts:
    - argo-image-updater.example.com
    secretName: argo-image-updater-webhook-tls
```

#### 4. Configure Registry Webhook

```yaml
# Docker Hub webhook
apiVersion: v1
kind: Secret
metadata:
  name: argocd-image-updater-dockerhub-webhook
  namespace: argocd
type: Opaque
data:
  webhook-secret: <base64-encoded-secret>
```

---

## 8. Custom Configuration

### Custom Update Strategies

```yaml
# Custom semver strategy
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: custom-registry
      api_url: https://custom-registry.example.com
      ping: false
      credentials: pullsecret:argocd/custom-registry-secret
      default: false
  application-specs: |
    apps:
    - image-list: "*"
      updateStrategy: semver
      pullSecret: pullsecret:argocd/custom-registry-secret
      registries:
      - name: custom-registry
```

### Custom Webhook Configuration

```yaml
# Webhook with custom handlers
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-config
  namespace: argocd
data:
  webhook.host: "0.0.0.0"
  webhook.port: "8080"
  webhook.secret: "my-webhook-secret"
  webhook.handlers: |
    - name: dockerhub
      url: /webhook/dockerhub
      secret: dockerhub-webhook-secret
    - name: github
      url: /webhook/github
      secret: github-webhook-secret
```

### Custom Platform Configuration

```yaml
# Multi-platform support
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
    argocd-image-updater.argoproj.io/my-app.platforms: linux/amd64,linux/arm64
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    spec:
      containers:
      - name: my-app
        image: registry.example.com/my-app:v1.0.0
```

---

## 9. Integration

### ArgoCD Integration

```yaml
# Application with image updater
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### GitHub Actions Integration

```yaml
# GitHub Actions workflow
name: Build and Push
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: registry.example.com/my-app:${{ github.sha }}
```

### GitLab CI Integration

```yaml
# .gitlab-ci.yml
build:
  stage: build
  script:
  - docker build -t registry.example.com/my-app:$CI_COMMIT_SHA .
  - docker push registry.example.com/my-app:$CI_COMMIT_SHA
  - |
    # Update deployment manifest
    kubectl set image deployment/my-app \
      my-app=registry.example.com/my-app:$CI_COMMIT_SHA
```

---

## 10. Security

### Pull Secrets

```yaml
# Create pull secret
kubectl create secret docker-registry argocd-image-updater-dockerhub \
  --docker-server=https://registry-1.docker.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  -n argocd
```

### RBAC Configuration

```yaml
# Role for Argo Image Updater
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argo-image-updater
  namespace: argocd
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argo-image-updater-network-policy
  namespace: argocd
spec:
  podSelector: {}
  policyTypes:
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

---

## 11. Troubleshooting

### Issue 1: Image Not Updating

```bash
# Check deployment annotations
kubectl get deployment my-app -o yaml | grep -A 10 annotations

# Check image updater logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater

# Check registry access
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater list --image-registry https://registry-1.docker.io

# Force update
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater update my-app
```

### Issue 2: Registry Authentication Failed

```bash
# Check pull secret
kubectl -n argocd get secret argocd-image-updater-dockerhub -o yaml

# Test registry access
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater list --image-registry https://registry-1.docker.io \
  --credentials argocd/argocd-image-updater-dockerhub

# Update secret
kubectl -n argocd delete secret argocd-image-updater-dockerhub
kubectl -n argocd create secret docker-registry argocd-image-updater-dockerhub \
  --docker-server=https://registry-1.docker.io \
  --docker-username=myuser \
  --docker-password=mypassword
```

### Issue 3: Webhook Not Working

```bash
# Check webhook configuration
kubectl -n argocd get configmap argo-image-updater-config -o yaml

# Check webhook logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater | grep webhook

# Test webhook endpoint
kubectl -n argocd port-forward svc/argo-image-updater-webhook 8080:8080
curl -X POST http://localhost:8080/webhook
```

### Issue 4: Update Strategy Not Working

```bash
# Check annotations
kubectl get deployment my-app -o yaml | grep argocd-image-updater

# Check update strategy
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater get --image-registry https://registry-1.docker.io

# Check available tags
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater list --image-registry https://registry-1.docker.io
```

### Issue 5: Controller Not Starting

```bash
# Check controller pod
kubectl -n argocd get pods -l app.kubernetes.io/name=argo-image-updater

# Check controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater

# Check controller events
kubectl -n argocd get events --field-selector involvedObject.name=argo-image-updater

# Restart controller
kubectl -n argocd rollout restart deployment/argo-image-updater
```

### Issue 6: Image Pull Error

```bash
# Check deployment
kubectl get deployment my-app -o yaml

# Check image
kubectl get deployment my-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check pull secret
kubectl get secret argocd-image-updater-dockerhub -o yaml

# Test image pull
kubectl run test-pod --image=registry.example.com/my-app:v1.0.0 --dry-run=client -o yaml
```

### Issue 7: Multiple Image Updates

```bash
# Check all images
kubectl get deployment my-app -o jsonpath='{.spec.template.spec.containers[*].image}'

# Check image updater logs
kubectl -n argocd logs -l app.kubernetes.io/name=argo-image-updater

# Update specific image
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater update my-app --image registry.example.com/my-api
```

### Issue 8: Platform Mismatch

```bash
# Check platform
kubectl get deployment my-app -o yaml | grep argocd-image-updater

# Check available platforms
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater list --image-registry https://registry-1.docker.io \
  --platform linux/amd64

# Update platform
kubectl annotate deployment my-app \
  argocd-image-updater.argoproj.io/my-app.platforms=linux/amd64,linux/arm64
```

### Issue 9: Digest Update

```bash
# Check digest
kubectl get deployment my-app -o yaml | grep argocd-image-updater

# Check current digest
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater get --image-registry https://registry-1.docker.io

# Update to specific digest
kubectl annotate deployment my-app \
  argocd-image-updater.argoproj.io/my-app.digest=sha256:abc123
```

### Issue 10: ConfigMap Not Found

```bash
# Check configmap
kubectl -n argocd get configmap argo-image-updater-config

# Create configmap
kubectl -n argocd create configmap argo-image-updater-config \
  --from-file=registries.conf

# Restart controller
kubectl -n argocd rollout restart deployment/argo-image-updater
```

### Issue 11: Namespace Not Found

```bash
# Check namespace
kubectl get namespace argocd

# Create namespace
kubectl create namespace argocd

# Install Argo Image Updater
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argo-image-updater/stable/manifests/install.yaml
```

### Issue 12: CRD Not Installed

```bash
# Check CRDs
kubectl get crd | grep image

# Install CRDs
kubectl apply -f https://raw.githubusercontent.com/argoproj-labs/argo-image-updater/stable/config/crd/install.yaml

# Verify CRDs
kubectl get crd applications.argoproj.io
```

### Issue 13: Image Not Found

```bash
# Check image
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater list --image-registry https://registry-1.docker.io

# Check image name
kubectl get deployment my-app -o yaml | grep image

# Update image name
kubectl annotate deployment my-app \
  argocd-image-updater.argoproj.io/image-list="my-app=registry.example.com/my-app"
```

### Issue 14: Update Interval Not Working

```bash
# Check update interval
kubectl -n argocd get deployment argo-image-updater -o yaml | grep interval

# Update interval
kubectl -n argocd set env deployment/argo-image-updater \
  ARGOCD_IMAGE_UPDATER_INTERVAL=2m

# Restart controller
kubectl -n argocd rollout restart deployment/argo-image-updater
```

### Issue 15: Log Level Not Working

```bash
# Check log level
kubectl -n argocd get deployment argo-image-updater -o yaml | grep loglevel

# Update log level
kubectl -n argocd set env deployment/argo-image-updater \
  ARGOCD_IMAGE_UPDATER_LOGLEVEL=debug

# Restart controller
kubectl -n argocd rollout restart deployment/argo-image-updater
```

---

## 12. Tips and Best Practices

### Tip 1: Use Semver Strategy for Versioned Releases

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.update-strategy: semver
  argocd-image-updater.argoproj.io/my-app.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
```

### Tip 2: Use Alphabetical Strategy for Latest Tags

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.update-strategy: alphabetical
  argocd-image-updater.argoproj.io/my-app.sort-options: asc
```

### Tip 3: Use Literal Strategy for Fixed Versions

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.update-strategy: literal
  argocd-image-updater.argoproj.io/my-app.force-tag: v1.0.0
```

### Tip 4: Use Digest Strategy for Immutable Releases

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.update-strategy: digest
  argocd-image-updater.argoproj.io/my-app.force-tag: sha256:abc123
```

### Tip 5: Use Multiple Image Updates

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: |
    my-app=registry.example.com/my-app
    my-api=registry.example.com/my-api
    my-worker=registry.example.com/my-worker
```

### Tip 6: Use Platform-Specific Updates

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.platforms: linux/amd64,linux/arm64
```

### Tip 7: Use Pull Secrets for Private Registries

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.pull-secret: pullsecret:argocd/my-pull-secret
```

### Tip 8: Use Tag Filtering

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
  argocd-image-updater.argoproj.io/my-app.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
  argocd-image-updater.argoproj.io/my-app.ignore-tags: latest,stable
```

### Tip 9: Use Webhook for Real-Time Updates

```yaml
# Webhook configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-webhook
  namespace: argocd
data:
  webhook.host: "0.0.0.0"
  webhook.port: "8080"
  webhook.secret: "my-webhook-secret"
```

### Tip 10: Use GitOps Workflow

```yaml
# Application with image updater
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: "my-app=registry.example.com/my-app"
    argocd-image-updater.argoproj.io/my-app.update-strategy: semver
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Tip 11: Use Monitoring and Alerts

```yaml
# PrometheusRule for Argo Image Updater
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argo-image-updater-alerts
  namespace: argocd
spec:
  groups:
  - name: argo-image-updater
    rules:
    - alert: ImageUpdateFailed
      expr: argo_image_updater_update_failed_total > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Argo Image Updater update failed"
        description: "Image update has failed for more than 5 minutes"
```

### Tip 12: Use Backup and Restore

```bash
# Backup configuration
kubectl -n argocd get configmap argo-image-updater-config -o yaml > backup.yaml

# Restore from backup
kubectl -n argocd apply -f backup.yaml
```

### Tip 13: Use Sync Windows for Maintenance

```yaml
# Sync window for image updates
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  syncWindows:
  - kind: allow
    schedule: '0 2 * * *'
    duration: 4h
    applications:
    - '*'
```

### Tip 14: Use Rollback Strategy

```yaml
# Rollback to previous version
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater rollback my-app

# Rollback to specific version
kubectl -n argocd exec -it argo-image-updater-xxxxx -- \
  argo-image-updater rollback my-app --tag v1.0.0
```

### Tip 15: Use Health Checks

```yaml
# Custom health check
data:
  resource.customizations.health.argoproj.io_Application: |
    hs = {}
    hs.status = "Progressing"
    hs.message = ""
    if obj.status ~= nil then
      if obj.status.health ~= nil then
        hs.status = obj.status.health.status
        if obj.status.health.message ~= nil then
          hs.message = obj.status.health.message
        end
      end
    end
    return hs
```

### Tip 16: Use Resource Tracking

```yaml
# Annotation-based tracking
data:
  application.resourceTrackingMethod: annotation

# Label-based tracking
data:
  application.resourceTrackingMethod: label
```

---

## 13. Command Reference

### Image Commands

```bash
# List images
argo-image-updater list --image-registry https://registry-1.docker.io

# Get image info
argo-image-updater get --image-registry https://registry-1.docker.io

# Update image
argo-image-updater update my-app

# Rollback image
argo-image-updater rollback my-app

# Check image tags
argo-image-updater list --image-registry https://registry-1.docker.io --tag-regexp "^v[0-9]+\.[0-9]+\.[0-9]+$"
```

### Registry Commands

```bash
# List registries
argo-image-updater registries list

# Add registry
argo-image-updater registries add --name my-registry \
  --api-url https://registry.example.com \
  --credentials argocd/my-secret

# Remove registry
argo-image-updater registries remove my-registry

# Test registry connection
argo-image-updater registries test my-registry
```

### Config Commands

```bash
# Get configuration
argo-image-updater config get

# Update configuration
argo-image-updater config set --key my-key --value my-value

# Delete configuration
argo-image-updater config delete --key my-key
```

### Webhook Commands

```bash
# Start webhook server
argo-image-updater webhook start

# Test webhook endpoint
curl -X POST http://localhost:8080/webhook
```

---

## 14. CRD Reference

### Application (Extended)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: string
  namespace: string
  labels: map[string]string
  annotations:
    argocd-image-updater.argoproj.io/image-list: string
    argocd-image-updater.argoproj.io/<image>.update-strategy: string
    argocd-image-updater.argoproj.io/<image>.pull-secret: string
    argocd-image-updater.argoproj.io/<image>.allow-tags: string
    argocd-image-updater.argoproj.io/<image>.ignore-tags: string
    argocd-image-updater.argoproj.io/<image>.platforms: string
    argocd-image-updater.argoproj.io/<image>.force-tag: string
    argocd-image-updater.argoproj.io/<image>.digest: string
spec:
  project: string
  source:
    repoURL: string
    targetRevision: string
    path: string
  destination:
    server: string
    namespace: string
  syncPolicy:
    automated:
      prune: boolean
      selfHeal: boolean
```

### ImageUpdaterConfig (Internal)

```yaml
# Internal configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: string
      api_url: string
      ping: boolean
      credentials: string
      default: boolean
  application-specs: |
    apps:
    - image-list: string
      updateStrategy: string
      pullSecret: string
      registries: [object]
  webhook.host: string
  webhook.port: string
  webhook.secret: string
```

---

## 15. Real-World Examples

### Example 1: Production Application Update

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
  namespace: production
  annotations:
    argocd-image-updater.argoproj.io/image-list: "production-app=registry.example.com/production-app"
    argocd-image-updater.argoproj.io/production-app.update-strategy: semver
    argocd-image-updater.argoproj.io/production-app.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
    argocd-image-updater.argoproj.io/production-app.pull-secret: pullsecret:argocd/production-pull-secret
spec:
  replicas: 5
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      containers:
      - name: production-app
        image: registry.example.com/production-app:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Example 2: Multi-Image Update

```yaml
# deployment-multi.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microservices-app
  namespace: production
  annotations:
    argocd-image-updater.argoproj.io/image-list: |
      frontend=registry.example.com/frontend
      api=registry.example.com/api
      worker=registry.example.com/worker
    argocd-image-updater.argoproj.io/frontend.update-strategy: semver
    argocd-image-updater.argoproj.io/api.update-strategy: semver
    argocd-image-updater.argoproj.io/worker.update-strategy: semver
    argocd-image-updater.argoproj.io/frontend.pull-secret: pullsecret:argocd/frontend-pull-secret
    argocd-image-updater.argoproj.io/api.pull-secret: pullsecret:argocd/api-pull-secret
    argocd-image-updater.argoproj.io/worker.pull-secret: pullsecret:argocd/worker-pull-secret
spec:
  replicas: 3
  selector:
    matchLabels:
      app: microservices-app
  template:
    metadata:
      labels:
        app: microservices-app
    spec:
      containers:
      - name: frontend
        image: registry.example.com/frontend:v1.0.0
        ports:
        - containerPort: 8080
      - name: api
        image: registry.example.com/api:v1.0.0
        ports:
        - containerPort: 8081
      - name: worker
        image: registry.example.com/worker:v1.0.0
        ports:
        - containerPort: 8082
```

### Example 3: Multi-Platform Update

```yaml
# deployment-platform.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-platform-app
  namespace: production
  annotations:
    argocd-image-updater.argoproj.io/image-list: "multi-platform-app=registry.example.com/multi-platform-app"
    argocd-image-updater.argoproj.io/multi-platform-app.update-strategy: semver
    argocd-image-updater.argoproj.io/multi-platform-app.platforms: linux/amd64,linux/arm64
spec:
  replicas: 3
  selector:
    matchLabels:
      app: multi-platform-app
  template:
    metadata:
      labels:
        app: multi-platform-app
    spec:
      containers:
      - name: multi-platform-app
        image: registry.example.com/multi-platform-app:v1.0.0
        ports:
        - containerPort: 8080
```

### Example 4: GitOps with ArgoCD

```yaml
# Application with image updater
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: "gitops-app=registry.example.com/gitops-app"
    argocd-image-updater.argoproj.io/gitops-app.update-strategy: semver
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/gitops-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 16. Further Reading

### Official Documentation

- [Argo Image Updater Documentation](https://argocd-image-updater.readthedocs.io/en/stable/)
- [Argo Image Updater GitHub](https://github.com/argoproj-labs/argo-image-updater)
- [Argo Image Updater Configuration](https://argocd-image-updater.readthedocs.io/en/stable/configuration/)

### Tutorials and Guides

- [Getting Started with Argo Image Updater](https://argocd-image-updater.readthedocs.io/en/stable/getting-started/)
- [Image Update Strategies](https://argocd-image-updater.readthedocs.io/en/stable/configuration/image-updates/)
- [Webhook Configuration](https://argocd-image-updater.readthedocs.io/en/stable/configuration/webhooks/)

### Community Resources

- [Argo Image Updater Slack](https://argoproj.github.io/community/join-slack)
- [Argo Image Updater Blog](https://blog.argoproj.io/)
- [Argo Image Updater Examples](https://github.com/argoproj-labs/argo-image-updater/tree/master/docs)
