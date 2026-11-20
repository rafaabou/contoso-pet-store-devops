# ArgoCD Complete Guide

## Table of Contents

1. [What Is ArgoCD](#1-what-is-argocd)
2. [Why Use ArgoCD](#2-why-use-argocd)
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

## 1. What Is ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of applications to Kubernetes clusters by syncing the desired state declared in a Git repository to the live state running in a cluster.

### Key Characteristics

- **Declarative**: Configuration is stored in Git as the single source of truth
- **Automated**: Continuous synchronization between Git and the cluster
- **Auditable**: Every change is tracked via Git commits
- **Secure**: No cluster credentials stored in Git
- **Scalable**: Supports multi-cluster deployments

### How It Works

```
Git Repository (source of truth)
        │
        ▼
   ArgoCD Server
        │
        ├── Detects changes via webhooks or polling
        ├── Compares desired state (Git) vs live state (cluster)
        ├── Determines sync actions
        └── Applies changes to Kubernetes
        │
        ▼
   Kubernetes Cluster (live state)
```

### Core Principles

1. **Single Source of Truth**: All application definitions live in Git
2. **Declarative Configuration**: Kubernetes manifests define the desired state
3. **Pull-based Deployment**: ArgoCD pulls from Git rather than pushing to clusters
4. **Immutable References**: Git commits provide immutable references to known-good states

---

## 2. Why Use ArgoCD

### Problems ArgoCD Solves

| Problem | ArgoCD Solution |
|---------|-----------------|
| Manual deployments | Automated Git-synced deployments |
| Configuration drift | Continuous reconciliation |
| Multi-cluster chaos | Centralized multi-cluster management |
| Secrets in Git | Vault/sealed-secrets integration |
| Rollback difficulty | Git-based instant rollback |
| Audit trails | Git commit history |

### ArgoCD vs Other CD Tools

| Feature | ArgoCD | Flux | Spinnaker | Jenkins X |
|---------|--------|------|-----------|-----------|
| Kubernetes-native | Yes | Yes | No | Yes |
| GitOps | Yes | Yes | No | Yes |
| Multi-cluster | Yes | Yes | Yes | Limited |
| UI Dashboard | Yes | No | Yes | Yes |
| CLI | Yes | Yes | Yes | Yes |
| RBAC | Yes | Yes | Yes | Limited |
| Webhook support | Yes | Yes | Yes | Yes |

### When to Use ArgoCD

- When you need GitOps-based continuous delivery
- When managing multiple Kubernetes clusters
- When requiring audit trails and compliance
- When needing easy rollbacks
- When deploying Helm charts, Kustomize, or raw manifests
- When integrating with CI pipelines

---

## 3. Architecture Overview

### Components

```
┌─────────────────────────────────────────────────┐
│                   ArgoCD Server                   │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │   API    │  │  Server  │  │    Repo      │   │
│  │  Server  │  │ (gRPC)   │  │   Server     │   │
│  └──────────┘  └──────────┘  └──────────────┘   │
│                                                   │
│  ┌──────────────────────────────────────────┐    │
│  │            Application Controller         │    │
│  │  - Watch for changes                      │    │
│  │  - Compare desired vs live state          │    │
│  │  - Sync applications                      │    │
│  └──────────────────────────────────────────┘    │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │   Redis  │  │  Dex     │  │   Notification│   │
│  │  Cache   │  │  SSO     │  │   Controller  │   │
│  └──────────┘  └──────────┘  └──────────────┘   │
└─────────────────────────────────────────────────┘
```

### Data Flow

1. **Repository Server**: Clones Git repos, generates Kubernetes manifests
2. **Application Controller**: Monitors repos and clusters, detects drift
3. **API Server**: Provides gRPC/REST interface for CLI and UI
4. **Redis**: Caches repository data for performance
5. **Dex**: Handles SSO authentication

### Deployment Models

- **All-in-One**: Single namespace deployment
- **Multi-Tenant**: Namespace per team
- **Ha**: High-availability with replicas

---

## 4. Installation

### Method 1: Kustomize (Recommended)

```bash
# Install ArgoCD namespace
kubectl create namespace argocd

# Install with HA (production)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml

# Install without HA (development)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Method 2: Helm

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=LoadBalancer \
  --set server.service.loadBalancerIP=<YOUR_IP>
```

### Method 3: Quick Start

```bash
# Download argocd CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Install (minimal)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl -n argocd get pods -w

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward UI
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Login
argocd login localhost:8080
```

### Post-Installation Verification

```bash
# Check all pods are running
kubectl -n argocd get pods

# Expected output:
# argocd-application-controller-xxxxx    Running
# argocd-dex-server-xxxxx                Running
# argocd-redis-xxxxx                     Running
# argocd-repo-server-xxxxx               Running
# argocd-server-xxxxx                    Running

# Check services
kubectl -n argocd get svc

# Get version
argocd version --server localhost:8080
```

### Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
  - host: argocd.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
  tls:
  - hosts:
    - argocd.example.com
    secretName: argocd-tls
```

---

## 5. Configuration

### Server Configuration

```yaml
# argocd-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  # URL where users are redirected when accessing ArgoCD
  url: https://argocd.example.com
  
  # Status badge enabled
  statusbadge.enabled: "true"
  
  # Resource exclusions
  resource.exclusions: |
    - apiGroups:
      - cilium.io
      kinds:
      - CiliumIdentity
      clusters:
      - "*"
  
  # Timeout for repository operations
  timeout.reconciliation: 180s
  
  # Resource tracking method
  application.resourceTrackingMethod: annotation
  
  # Admin account
  admin.enabled: "true"
```

### RBAC Configuration

```yaml
# argocd-rbac-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    # Policies
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    p, role:admin, logs, *, *, allow
    p, role:admin, exec, *, */*, allow
    
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, */*, allow
    p, role:developer, applications, action/*, */*, allow
    p, role:developer, logs, get, */*, allow
    
    p, role:view, applications, get, */*, allow
    p, role:view, clusters, get, *, allow
    p, role:view, repositories, get, *, allow
    p, role:view, logs, get, */*, allow
    
    # Groups
    g, admins, role:admin
    g, developers, role:developer
    g, viewers, role:view
```

### SSO Configuration (Dex)

```yaml
# argocd-cm ConfigMap - Dex SSO
data:
  url: https://argocd.example.com
  
  # OIDC Provider
  dex.config: |
    connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: <github-client-id>
        clientSecret: <github-client-secret>
        redirectURI: https://argocd.example.com/api/dex/callback
        orgs:
        - name: my-org
```

### TLS Configuration

```yaml
# argocd-tls-certs-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-tls-certs-cm
  namespace: argocd
data:
  example.com: |
    -----BEGIN CERTIFICATE-----
    <certificate>
    -----END CERTIFICATE-----
  example.com.key: |
    -----BEGIN RSA PRIVATE KEY-----
    <private-key>
    -----END RSA PRIVATE KEY-----
```

### Repository Configuration

```yaml
# argocd-repositories ConfigMap or Secret
apiVersion: v1
kind: Secret
metadata:
  name: argocd-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository-creds
stringData:
  url: https://github.com/my-org
  username: git
  password: <personal-access-token>
  type: git
```

---

## 6. Core Concepts

### Application

An Application represents a deployment of an application to a Kubernetes cluster.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Project

Projects provide organizational boundaries for Applications.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My Project
  sourceRepos:
  - 'https://github.com/my-org/*'
  destinations:
  - namespace: my-app
    server: https://kubernetes.default.svc
  - namespace: my-app-staging
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceBlacklist:
  - group: ''
    kind: ResourceQuota
  - group: ''
    kind: LimitRange
```

### Repository

Repositories are Git repositories that contain application manifests.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/my-org/my-app.git
  username: git
  password: <token>
  insecure: "false"
  enableLfs: "false"
```

### Sync

Synchronization is the process of applying the desired state (from Git) to the cluster.

**Sync Statuses**:
- **Synced**: Cluster matches Git
- **OutOfSync**: Cluster differs from Git
- **Unknown**: Unable to determine

**Sync Waves**: Applications can be ordered using annotations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Health

Health checks determine if the application is running correctly.

**Health Statuses**:
- **Healthy**: Running as expected
- **Progressing**: In transition
- **Degraded**: Not running as expected
- **Missing**: Resource not found
- **Unknown**: Unable to determine

---

## 7. Usage Guide

### Step-by-Step: Deploy an Application

#### 1. Create a Git Repository

```bash
mkdir my-app-deployment
cd my-app-deployment

# Create deployment.yaml
cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
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
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

# Create service.yaml
cat > service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Create kustomization.yaml
cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF

# Commit and push
git init
git add .
git commit -m "Initial deployment manifests"
git remote add origin https://github.com/my-org/my-app.git
git push -u origin main
```

#### 2. Create ArgoCD Application

```bash
# Using CLI
argocd app create my-app \
  --repo https://github.com/my-org/my-app.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-app \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --create-namespace
```

#### 3. Sync the Application

```bash
# Trigger sync
argocd app sync my-app

# Watch sync status
argocd app get my-app --watch

# Check status
argocd app wait my-app --health
```

#### 4. Verify Deployment

```bash
# Check application status
argocd app get my-app

# Check Kubernetes resources
kubectl -n my-app get pods,svc

# View application logs
argocd app logs my-app
```

### Step-by-Step: Multi-Cluster Setup

#### 1. Register Remote Cluster

```bash
# Add cluster credentials
argocd cluster add my-remote-cluster --service-account argocd

# Or using kubeconfig
argocd cluster add my-remote-cluster-context --kubeconfig /path/to/kubeconfig

# List registered clusters
argocd cluster list
```

#### 2. Create Multi-Cluster Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-multi
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s
  destinations:
  - server: https://kubernetes.default.svc
    namespace: my-app
  - server: https://remote-cluster.example.com
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step-by-Step: Helm Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-helm-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 15.0.0
    helm:
      releaseName: my-nginx
      valueFiles:
      - values.yaml
      values: |
        replicaCount: 3
        service:
          type: LoadBalancer
  destination:
    server: https://kubernetes.default.svc
    namespace: nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step-by-Step: Kustomize Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-kustomize-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: overlays/production
    kustomize:
      images:
      - my-app=nginx:1.21
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step-by-Step: Rollback

```bash
# List sync history
argocd app history my-app

# Rollback to specific revision
argocd app rollback my-app 3

# Rollback to specific commit
argocd app rollback my-app abc123

# Or simply revert Git commit and let auto-sync handle it
git revert HEAD
git push
```

---

## 8. Custom Configuration

### Custom Resource Health Checks

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
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

### Custom Sync Hooks

```yaml
# Pre-sync hook
apiVersion: batch/v1
kind: Job
metadata:
  name: pre-sync-job
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: pre-sync
        image: busybox
        command: ['sh', '-c', 'echo Running pre-sync hook']
      restartPolicy: Never
  backoffLimit: 0
```

### Sync Phase Options

- **PreSync**: Runs before sync
- **Sync**: Main sync phase
- **PostSync**: Runs after sync
- **SyncFail**: Runs on sync failure
- **Skip**: Skips the resource

### Notification Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
    signingSecret: $slack-signing-secret
  
  template.app-sync-succeeded: |
    message: |
      Application {{.app.metadata.name}} sync succeeded.
      Revision: {{.app.status.sync.revision}}
      Environment: {{index .app.metadata.labels "environment"}}
  
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-sync-succeeded]
  
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]
```

### Resource Tracking Configuration

```yaml
# argocd-cm ConfigMap
data:
  # Annotation-based tracking (recommended)
  application.resourceTrackingMethod: annotation
  
  # Label-based tracking
  # application.resourceTrackingMethod: label
  
  # annotation+label hybrid
  # application.resourceTrackingMethod: annotation-and-label
```

### ApplicationSet (Application Generator)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-appset
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: dev
        url: https://dev.example.com
        cluster: https://kubernetes.default.svc
      - env: staging
        url: https://staging.example.com
        cluster: https://staging-cluster.example.com
      - env: prod
        url: https://prod.example.com
        cluster: https://prod-cluster.example.com
  template:
    metadata:
      name: 'my-app-{{env}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/my-org/my-app.git
        targetRevision: main
        path: k8s/overlays/{{env}}
      destination:
        server: '{{cluster}}'
        namespace: my-app
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

## 9. Integration

### CI/CD Pipeline Integration

```yaml
# GitHub Actions workflow
name: Deploy to ArgoCD
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Update manifest image tag
      run: |
        cd k8s
        kustomize edit set image my-app=${{ github.sha }}
    
    - name: Commit and push
      run: |
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git add .
        git commit -m "Update image tag to ${{ github.sha }}"
        git push
```

### Vault Integration

```yaml
# vault-csi-provider ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-csi-provider
  namespace: argocd
data:
  vault-secrets-provider.yaml: |
    apiVersion: secrets-store.csi.x-k8s.io/v1
    kind: SecretProviderClass
    metadata:
      name: vault-secrets
    spec:
      provider: vault
      parameters:
        roleName: argocd
        vaultAddress: https://vault.example.com
        secrets: |
          - objectName: db-password
            secretPath: secret/data/my-app
            secretKey: password
```

### Prometheus/Grafana Monitoring

```yaml
# ServiceMonitor for ArgoCD
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-application-controller
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Slack/Teams Notifications

```bash
# Install argocd-notifications
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/notifications.yaml

# Configure Slack
kubectl -n argocd patch configmap argocd-notifications-cm --type merge -p '
data:
  service.slack: |
    token: $slack-token
    signingSecret: $slack-signing-secret
  template.app-sync: |
    message: |
      Application {{.app.metadata.name}} sync status: {{.app.status.sync.status}}
      Health: {{.app.status.health.status}}
  trigger.on-sync: |
    - when: app.status.operationState.phase in ['Succeeded', 'Failed']
      send: [app-sync]
'
```

---

## 10. Security

### RBAC Best Practices

```yaml
# least-privilege RBAC policy
policy.csv: |
  # Viewer: read-only
  p, role:viewer, applications, get, */*, allow
  p, role:viewer, clusters, get, *, allow
  p, role:viewer, repositories, get, *, allow
  
  # Developer: manage specific apps
  p, role:developer, applications, get, my-project/*, allow
  p, role:developer, applications, sync, my-project/*, allow
  p, role:developer, applications, action/*, my-project/*, allow
  
  # Admin: full access
  p, role:admin, applications, *, */*, allow
  p, role:admin, clusters, *, *, allow
  p, role:admin, repositories, *, *, allow
  p, role:admin, logs, *, */*, allow
  p, role:admin, exec, *, */*, allow
```

### Service Account Security

```yaml
# argocd-server ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-server
  namespace: argocd
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-server-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: argocd-server
  namespace: argocd
```

### TLS/mTLS

```yaml
# Enable TLS on ArgoCD server
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  namespace: argocd
spec:
  template:
    spec:
      containers:
      - name: argocd-server
        args:
        - argocd-server
        - --insecure  # Remove for TLS
        - --tlscertpath /tls/tls.crt
        - --tlskeypath /tls/tls.key
        volumeMounts:
        - name: tls-certs
          mountPath: /tls
      volumes:
      - name: tls-certs
        secret:
          secretName: argocd-server-tls
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 8443
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 6443
```

### Secrets Management

```yaml
# Sealed Secrets integration
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
  namespace: argocd
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
  template:
    metadata:
      name: my-secret
      namespace: argocd
```

---

## 11. Troubleshooting

### Issue 1: Application Stuck in "Progressing"

```bash
# Check application status
argocd app get my-app

# Check application logs
argocd app logs my-app

# Force refresh
argocd app get my-app --refresh

# Check resource status
kubectl -n my-app get pods,deployments
```

### Issue 2: Sync Failed - "ComparisonError"

```bash
# Check application events
kubectl -n argocd get events --field-selector involvedObject.name=my-app

# Check repository access
argocd repo list
argocd repo get https://github.com/my-org/my-app.git

# Test repository connection
argocd repo get https://github.com/my-org/my-app.git --upstream
```

### Issue 3: Application Shows "OutOfSync" but Not Syncing

```bash
# Check sync policy
argocd app get my-app -o json | jq '.spec.syncPolicy'

# Force sync
argocd app sync my-app --force

# Check for resource conflicts
kubectl -n my-app describe deployment my-app
```

### Issue 4: "Permission Denied" Error

```bash
# Check RBAC
argocd account list
argocd admin rbac can my-user sync applications my-project/my-app

# Check project restrictions
argocd app get my-app -o json | jq '.spec.project'

# Check cluster credentials
argocd cluster list
```

### Issue 5: Application Health Check Failing

```bash
# Check health status
argocd app get my-app -o json | jq '.status.health'

# Check resource status
kubectl -n my-app get pods -o wide

# Check deployment rollout
kubectl -n my-app rollout status deployment/my-app
```

### Issue 6: "Repository Not Found" Error

```bash
# Verify repository exists
argocd repo list

# Test repository access
argocd repo get https://github.com/my-org/my-app.git --upstream

# Re-add repository
argocd repo rm https://github.com/my-org/my-app.git
argocd repo add https://github.com/my-org/my-app.git --username git --password <token>
```

### Issue 7: "Application Controller Not Ready"

```bash
# Check controller pod
kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-application-controller

# Check controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller

# Restart controller
kubectl -n argocd rollout restart deployment/argocd-application-controller
```

### Issue 8: "Connection Refused" to Kubernetes API

```bash
# Check API server
kubectl cluster-info

# Check service account
kubectl -n argocd get sa argocd-server -o yaml

# Verify cluster access
argocd cluster get my-cluster
```

### Issue 9: Sync Takes Too Long

```bash
# Check sync timeout
argocd app get my-app -o json | jq '.spec.syncPolicy.syncOptions'

# Optimize sync
argocd app sync my-app --async

# Check resource limits
kubectl -n argocd describe pod -l app.kubernetes.io/name=argocd-application-controller
```

### Issue 10: "Namespace Not Found" Error

```bash
# Create namespace
kubectl create namespace my-app

# Check destination
argocd app get my-app -o json | jq '.spec.destination'

# Enable auto-create namespace
argocd app set my-app --sync-option CreateNamespace=true
```

### Issue 11: "Helm Template Error"

```bash
# Test Helm template locally
helm template my-app . --values values.yaml

# Check Helm values
argocd app get my-app -o json | jq '.spec.source.helm.values'

# Validate Helm chart
helm lint .
```

### Issue 12: "Kustomize Build Error"

```bash
# Test Kustomize build locally
kustomize build .

# Check kustomization.yaml
cat kustomization.yaml

# Validate resources
kubectl apply --dry-run=client -f .
```

### Issue 13: "Application Controller CrashLoopBackOff"

```bash
# Check controller logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller --tail=100

# Check resource usage
kubectl -n argocd top pods

# Check for memory issues
kubectl -n argocd describe pod -l app.kubernetes.io/name=argocd-application-controller
```

### Issue 14: "Notification Controller Not Working"

```bash
# Check notification pods
kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-notifications-controller

# Check notification logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-notifications-controller

# Test notification
argocd app set my-app --notification-event on-sync-succeeded
```

### Issue 15: "SSO Login Failed"

```bash
# Check Dex configuration
kubectl -n argocd get configmap argocd-cm -o yaml

# Check Dex logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-dex-server

# Test SSO
curl -k https://argocd.example.com/api/dex/.well-known/openid-configuration
```

### Issue 16: "Application Status Not Updating"

```bash
# Force refresh
argocd app get my-app --refresh

# Check controller status
kubectl -n argocd get deployment argocd-application-controller

# Check for stale state
kubectl -n argocd get configmap argocd-cache -o yaml
```

### Issue 17: "Resource Conflict" During Sync

```bash
# Check resource ownership
kubectl -n my-app get deployment my-app -o yaml | jq '.metadata.annotations'

# Clear resource tracking
kubectl -n my-app annotate deployment my-app argocd.argoproj.io/managed-by-

# Force sync
argocd app sync my-app --force --prune
```

---

## 12. Tips and Best Practices

### Tip 1: Use ApplicationSets for Multi-Environment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-appset
spec:
  generators:
  - git:
      repoURL: https://github.com/my-org/my-app.git
      revision: main
      directories:
      - path: overlays/*
  template:
    metadata:
      name: 'my-app-{{path.basename}}'
    spec:
      source:
        path: '{{path}}'
      destination:
        namespace: 'my-app-{{path.basename}}'
```

### Tip 2: Implement Progressive Sync with Waves

```yaml
# Wave -1: Pre-requisites
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"

# Wave 0: Main application
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"

# Wave 1: Post-sync tasks
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Tip 3: Use Sync Hooks for Complex Deployments

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: my-app:latest
        command: ['python', 'manage.py', 'migrate']
      restartPolicy: Never
```

### Tip 4: Implement Proper Health Checks

```yaml
# Custom health check for CRD
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

### Tip 5: Use Progressive Delivery with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 5m}
      - setWeight: 60
      - pause: {duration: 5m}
      - setWeight: 80
      - pause: {duration: 5m}
```

### Tip 6: Implement Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: argocd-quota
  namespace: argocd
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

### Tip 7: Use Monitoring and Alerts

```yaml
# PrometheusRule for ArgoCD
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argocd-alerts
  namespace: argocd
spec:
  groups:
  - name: argocd
    rules:
    - alert: ArgoCDAppOutOfSync
      expr: argocd_app_info{sync_status="OutOfSync"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "ArgoCD application is out of sync"
        description: "Application {{ $labels.name }} is out of sync for more than 5 minutes"
```

### Tip 8: Backup and Restore

```bash
# Backup ArgoCD state
argocd admin export > argocd-backup.yaml

# Restore from backup
argocd admin import < argocd-backup.yaml
```

### Tip 9: Use Sync Windows for Maintenance

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
spec:
  syncWindows:
  - kind: allow
    schedule: '0 2 * * *'
    duration: 4h
    applications:
    - '*'
  - kind: deny
    schedule: '0 0 * * *'
    duration: 2h
    applications:
    - '*'
```

### Tip 10: Implement GitOps Workflow

```bash
# 1. Developer commits to Git
git add .
git commit -m "Update application"
git push

# 2. CI pipeline builds and tests
# 3. CI updates deployment manifests
# 4. ArgoCD syncs to cluster
argocd app sync my-app
```

### Tip 11: Use Diff for Change Detection

```bash
# Show diff between Git and cluster
argocd app diff my-app

# Show diff with specific revision
argocd app diff my-app --revision abc123
```

### Tip 12: Implement Pruning Strategy

```yaml
# Automatic pruning
spec:
  syncPolicy:
    automated:
      prune: true

# Manual pruning
argocd app sync my-app --prune

# Prune specific resources
argocd app sync my-app --prune --resource deployment:my-app
```

### Tip 13: Use Resource Tracking Methods

```yaml
# Annotation-based tracking (recommended)
data:
  application.resourceTrackingMethod: annotation

# Label-based tracking
data:
  application.resourceTrackingMethod: label
```

### Tip 14: Implement Application Dependencies

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  annotations:
    argocd.argoproj.io/manifest-generate-paths: /k8s
spec:
  sources:
  - repoURL: https://github.com/my-org/my-app.git
    path: k8s
  - repoURL: https://github.com/my-org/my-config.git
    path: config
    targetRevision: main
```

### Tip 15: Use Sync Waves for Ordering

```yaml
# Database migration (Wave -1)
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
---
# Application deployment (Wave 0)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    argocd.argoproj.io/sync-wave: "0"
---
# Post-sync task (Wave 1)
apiVersion: batch/v1
kind: Job
metadata:
  name: post-deploy
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

### Tip 16: Implement Rollback Strategy

```bash
# Automatic rollback on failure
argocd app set my-app --sync-option AutomatedPrune=true

# Manual rollback
argocd app rollback my-app 3

# Rollback to specific commit
argocd app rollback my-app abc123
```

### Tip 17: Use Health Checks for Custom Resources

```yaml
data:
  resource.customizations.health.argoproj.io_Rollout: |
    hs = {}
    hs.status = "Progressing"
    hs.message = ""
    if obj.status ~= nil then
      if obj.status.conditions ~= nil then
        for _, condition in ipairs(obj.status.conditions) do
          if condition.type == "Ready" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = condition.message or ""
            return hs
          end
        end
      end
    end
    return hs
```

---

## 13. Command Reference

### Application Commands

```bash
# List applications
argocd app list

# Get application details
argocd app get <app-name>

# Create application
argocd app create <app-name> \
  --repo <repo-url> \
  --path <path> \
  --dest-server <server-url> \
  --dest-namespace <namespace>

# Delete application
argocd app delete <app-name>

# Sync application
argocd app sync <app-name>

# Rollback application
argocd app rollback <app-name> <revision>

# Set application parameters
argocd app set <app-name> --parameter key=value

# Wait for application
argocd app wait <app-name> --health

# Get application logs
argocd app logs <app-name>

# Show diff
argocd app diff <app-name>

# Force refresh
argocd app get <app-name> --refresh
```

### Repository Commands

```bash
# List repositories
argocd repo list

# Add repository
argocd repo add <url> --username <user> --password <pass>

# Remove repository
argocd repo rm <url>

# Test repository connection
argocd repo get <url> --upstream

# Refresh repository
argocd repo get <url> --refresh
```

### Cluster Commands

```bash
# List clusters
argocd cluster list

# Add cluster
argocd cluster add <context-name>

# Remove cluster
argocd cluster rm <server-url>

# Get cluster credentials
argocd cluster get <server-url>
```

### Account Commands

```bash
# List accounts
argocd account list

# Get account details
argocd account get

# Update password
argocd account update-password

# Generate token
argocd account generate-token

# List tokens
argocd account list-tokens

# Delete token
argocd account delete-token <token-id>
```

### Project Commands

```bash
# List projects
argocd proj list

# Create project
argocd proj create <project-name> --src <repo-url>

# Delete project
argocd proj delete <project-name>

# Add source
argocd proj add-source <project-name> <repo-url>

# Add destination
argocd proj add-destination <project-name> <namespace> <server>
```

### Admin Commands

```bash
# Import/Export
argocd admin export > backup.yaml
argocd admin import < backup.yaml

# Settings
argocd admin settings

# RBAC
argocd admin rbac can <user> <action> <resource> <object>

# Cluster
argocd admin cluster rotate-address
argocd admin cluster kubeconfig
```

### Completion

```bash
# Generate completion script
argocd completion bash > /etc/bash_completion.d/argocd

# Load completion
source <(argocd completion bash)
```

---

## 14. CRD Reference

### Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: string
  namespace: string
  labels: map[string]string
  annotations: map[string]string
spec:
  project: string
  source:
    repoURL: string
    targetRevision: string
    path: string
    chart: string
    helm:
      releaseName: string
      valueFiles: [string]
      values: string
    kustomize:
      images: [string]
    directory:
      recurse: boolean
      jsonnet: object
    plugin:
      name: string
      env: map[string]string
  destination:
    server: string
    namespace: string
    name: string
  syncPolicy:
    automated:
      prune: boolean
      selfHeal: boolean
      allowEmpty: boolean
    syncOptions:
    - string
    retry:
      limit: integer
      backoff:
        duration: string
        factor: integer
        maxDuration: string
    managedNamespaceMetadata:
      annotations: map[string]string
      labels: map[string]string
  ignoreDifferences:
  - group: string
    kind: string
    jsonPointers: [string]
    jqPathExpressions: [string]
    name: string
    namespace: string
  sources:
  - repoURL: string
    path: string
    targetRevision: string
  revisionHistoryLimit: integer
  info:
  - name: string
    value: string
```

### AppProject

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: string
  namespace: string
spec:
  description: string
  sourceRepos:
  - string
  destinations:
  - namespace: string
    server: string
    name: string
  clusterResourceWhitelist:
  - group: string
    kind: string
  namespaceResourceWhitelist:
  - group: string
    kind: string
  namespaceResourceBlacklist:
  - group: string
    kind: string
  roles:
  - name: string
    description: string
    policies:
    - string
    groups:
    - string
  syncWindows:
  - kind: string
    schedule: string
    duration: string
    applications:
    - string
    namespaces:
    - string
    clusters:
    - string
    manualSync: boolean
  signatureKeys:
  - keyID: string
```

### ApplicationSet

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: string
  namespace: string
spec:
  generators:
  - list:
      elements:
      - string: string
    git:
      repoURL: string
      revision: string
      directories:
      - path: string
      files:
      - path: string
    clusters:
      selector:
        matchLabels: map[string]string
    matrix:
      generators:
      - list: object
      - git: object
    merge:
      mergeKeys: [string]
      generators:
      - list: object
      - git: object
    pullRequest:
      github:
        owner: string
        repo: string
      pollPeriod: string
    plugin:
      configMapRef:
        name: string
      input: map[string]string
  template:
    metadata:
      name: string
      namespace: string
      labels: map[string]string
      annotations: map[string]string
    spec:
      project: string
      source:
        repoURL: string
        targetRevision: string
        path: string
      destination:
        server: string
        namespace: string
      syncPolicy: object
  strategy:
    type: string
    rollingSync:
      steps:
      - matchExpressions:
        - key: string
          operator: string
          values: [string]
        maxUpdate: string
  syncPolicy:
    preserveResourcesOnDeletion: boolean
  templateMeta:
    annotations: map[string]string
    labels: map[string]string
```

---

## 15. Real-World Examples

### Example 1: Production Application Deployment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: production-app
  namespace: argocd
  labels:
    environment: production
    team: platform
spec:
  project: production
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s/overlays/production
    kustomize:
      images:
      - my-app=registry.example.com/my-app:v1.2.3
  destination:
    server: https://kubernetes.example.com
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

### Example 2: Multi-Tenant Setup

```yaml
# ApplicationSet for tenant isolation
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: tenant-apps
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/my-org/tenant-configs.git
      revision: main
      directories:
      - path: tenants/*
  template:
    metadata:
      name: 'tenant-{{path.basename}}'
      labels:
        tenant: '{{path.basename}}'
    spec:
      project: 'tenant-{{path.basename}}'
      source:
        path: 'tenants/{{path.basename}}'
      destination:
        server: https://kubernetes.example.com
        namespace: 'tenant-{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### Example 3: ArgoCD with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app-rollout
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.example.com
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-app
  strategy:
    canary:
      canaryService: my-app-canary
      stableService: my-app-stable
      trafficRouting:
        nginx:
          stableIngress: my-app-ingress
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: my-app-canary.production.svc.cluster.local
      steps:
      - setWeight: 10
      - pause: {duration: 5m}
      - setWeight: 30
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 70
      - pause: {duration: 5m}
```

### Example 4: Vault Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vault-secrets
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/my-app.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.example.com
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-secrets
  namespace: production
spec:
  provider: vault
  parameters:
    roleName: my-app
    vaultAddress: https://vault.example.com
    secrets: |
      - objectName: db-password
        secretPath: secret/data/my-app
        secretKey: password
      - objectName: api-key
        secretPath: secret/data/my-app
        secretKey: api-key
```

### Example 5: GitOps with PR Automation

```yaml
# GitHub Actions workflow for ArgoCD
name: ArgoCD Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Update kustomize image
      run: |
        cd k8s/overlays/production
        kustomize edit set image my-app=registry.example.com/my-app:${{ github.sha }}
    
    - name: Commit changes
      run: |
        git config user.name "github-actions"
        git config user.email "actions@github.com"
        git add .
        git commit -m "Update image to ${{ github.sha }}"
        git push
```

---

## 16. Further Reading

### Official Documentation

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [ArgoCD CLI Reference](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [ArgoCD API Reference](https://argo-cd.readthedocs.io/en/stable/operator-manual/)

### Tutorials and Guides

- [Getting Started with ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [ArgoCD Tutorial for Beginners](https://www.youtube.com/watch?v=MeU5_k9ssrs)
- [GitOps with ArgoCD](https://www.gitops.tech/argocd/)

### Community Resources

- [ArgoCD GitHub](https://github.com/argoproj/argo-cd)
- [ArgoCD Slack](https://argoproj.github.io/community/join-slack)
- [ArgoCD Blog](https://blog.argoproj.io/)

### Books and Courses

- "GitOps and Kubernetes" by Billy Yuen, Alexander Matyushentsev, Todd Ekenstam, Jesse Suen
- "ArgoCD in Action" by Mickaël Hello (Mickaël Cara)
- Linux Foundation Training: GitOps with ArgoCD

### Tools and Integrations

- [Argo CD CLI](https://github.com/argoproj/argo-cd/tree/master/cmd/argocd)
- [Argo CD Image Updater](https://github.com/argoproj/argo-image-updater)
- [Argo CD Notifications](https://github.com/argoproj/notifications-engine)
- [Argo CD Autopilot](https://github.com/argoproj-labs/argocd-autopilot)
