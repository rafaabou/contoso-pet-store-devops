# Kustomize Complete Guide

## Table of Contents

1. [What Is Kustomize](#what-is-kustomize)
2. [Why Use Kustomize](#why-use-kustomize)
3. [Installation](#installation)
4. [Core Concepts](#core-concepts)
5. [Configuration](#configuration)
6. [Usage Guide (Step-by-Step)](#usage-guide)
7. [Custom Configuration](#custom-configuration)
8. [Integration](#integration)
9. [Security](#security)
10. [Troubleshooting](#troubleshooting)
11. [Tips & Best Practices](#tips--best-practices)
12. [Command Reference](#command-reference)
13. [Configuration Reference](#configuration-reference)
14. [Real-World Examples](#real-world-examples)
15. [Further Reading](#further-reading)

---

## What Is Kustomize

Kustomize is a template-free configuration management tool for Kubernetes. Created by Google and now part of the Kubernetes project (built into `kubectl` since version 1.14), Kustomize allows you to customize Kubernetes resource definitions without writing templates or duplicating YAML files.

Unlike Helm, which uses Go templates to generate manifests, Kustomize works by applying overlays to existing YAML files. You maintain a base set of Kubernetes manifests and then create environment-specific overlays that modify, patch, or add to the base. Kustomize merges these layers to produce the final manifests.

The core philosophy of Kustomize is:
- **No templates**: Work with raw YAML files, maintaining full syntax highlighting and validation
- **Base and overlays**: A base directory contains the common manifests, and overlay directories contain environment-specific customizations
- **Strategic merge patches**: Modify specific fields in existing resources without rewriting the entire file
- **Generators**: Create ConfigMaps, Secrets, and other resources from files or literals
- **Reproducibility**: The same base produces the same manifests every time, with customizations applied deterministically

Kustomize is particularly useful for:
- Managing multiple environments (dev, staging, production) from a common base
- Customizing third-party applications without forking their charts
- Applying patches to resources without modifying the original files
- Generating ConfigMaps and Secrets from files or literals

Kustomize is built into `kubectl` and can also be used standalone. It integrates with ArgoCD, Flux, and other GitOps tools.

---

## Why Use Kustomize

**No Template Language**: Unlike Helm, Kustomize works directly with YAML. You don't need to learn a template language, and your manifests remain valid Kubernetes YAML that can be validated, linted, and syntax-highlighted.

**Built into kubectl**: Kustomize is available as `kubectl kustomize` or `kubectl apply -k` without installing anything additional.

**Environment Overlays**: Maintain a single base configuration and create overlays for different environments. Each overlay inherits the base and applies only the differences.

**Strategic Merge Patches**: Modify specific fields in Kubernetes resources without rewriting the entire file. Patches are surgical and easy to understand.

**Generator Functions**: Create ConfigMaps and Secrets from files, literals, or environment variables without manually creating YAML.

**Reproducible Builds**: The same base plus the same overlay always produces the same manifests. There are no variables or conditionals that could cause unexpected behavior.

**GitOps Friendly**: Kustomize works perfectly with GitOps workflows. Each environment has its own directory with its own `kustomization.yaml`, making it easy to track changes and manage deployments.

**No State Management**: Unlike Helm, Kustomize doesn't maintain release state. This simplifies operations and avoids state-related issues.

**Composable**: Kustomize supports building from remote URLs, allowing you to compose configurations from multiple sources.

---

## Installation

### kubectl (Built-in)

```bash
# Kustomize is built into kubectl
kubectl version --client
# Version 1.14+ includes Kustomize

# Use kustomize directly
kubectl kustomize .

# Or apply with kustomize
kubectl apply -k .
```

### Standalone Kustomize

```bash
# macOS
brew install kustomize

# Linux (amd64)
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Verify installation
kustomize version
# v5.3.0
```

### kustomize via krew

```bash
# Install krew plugin manager
kubectl krew install kustomize

# Use kustomize
kubectl kustomize .
```

### Verify Installation

```bash
# Check kustomize version
kustomize version

# Or via kubectl
kubectl kustomize --help

# Create a test kustomization
mkdir test && cd test
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
EOF

# Build
kustomize build .
```

### Shell Completion

```bash
# Bash
kustomize completion bash > /etc/bash_completion.d/kustomize

# Zsh
kustomize completion zsh > "${fpath[1]}/_kustomize"

# Fish
kustomize completion fish > ~/.config/fish/completions/kustomize.fish
```

---

## Core Concepts

### Kustomization.yaml

The `kustomization.yaml` file is the heart of Kustomize. It defines the resources, patches, generators, and other configuration for a directory:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

patchesStrategicMerge:
  - patches/replica-patch.yaml

patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5

configMapGenerator:
  - name: my-config
    literals:
      - KEY=value
      - ANOTHER_KEY=another-value

secretGenerator:
  - name: my-secret
    literals:
      - DB_PASSWORD=supersecret
    type: Opaque

commonLabels:
  app: myapp
  env: production

namespace: production
```

### Base and Overlays

The base directory contains the common Kubernetes manifests. Overlay directories contain environment-specific customizations that build upon the base:

```
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   │       └── replica-patch.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   │       └── replica-patch.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── patches/
│           └── replica-patch.yaml
```

### Strategic Merge Patches

Strategic merge patches modify specific fields in existing resources. The patch file contains only the fields you want to change:

```yaml
# patches/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
```

### JSON 6902 Patches

JSON 6902 patches use JSON Pointer syntax for more precise modifications:

```yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5
      - op: add
        path: /metadata/labels/environment
        value: production
```

### Generators

Generators create resources from files, literals, or environment variables:

```yaml
# Create ConfigMap from file
configMapGenerator:
  - name: nginx-config
    files:
      - nginx.conf

# Create Secret from file
secretGenerator:
  - name: tls-secret
    files:
      - tls.crt
      - tls.key
    type: kubernetes.io/tls
```

### Common Labels and Annotations

Kustomize automatically adds labels and annotations to all resources:

```yaml
commonLabels:
  app: myapp
  team: platform

commonAnnotations:
  description: "My application"
  owner: "platform-team"
```

### Strategic Merge Patch Behavior

Kustomize uses strategic merge patch by default for Kubernetes resources. This means:
- Maps are merged by key
- Lists are merged by specified merge keys
- Scalars are replaced
- Null values remove the field

---

## Configuration

### Basic Kustomization

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
```

### Environment-Specific Overlays

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml
  - patches/resource-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - ENV=production
      - LOG_LEVEL=info
```

### Remote Resources

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - https://github.com/kubernetes-sigs/kustomize/examples/helloWorld?ref=v1.0.6
  - deployment.yaml
  - service.yaml
```

### Components

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

components:
  - https://github.com/kubernetes-sigs/kustomize/examples/helloWorld?ref=v1.0.6
```

### Build Options

```bash
# Build with output to file
kustomize build . -o output.yaml

# Build with enable-alpha-plugins
kustomize build . --enable-alpha-plugins

# Build with enable-exec
kustomize build . --enable-exec

# Build with load-restrictor
kustomize build . --load-restrictor LoadRestrictionsNone
```

---

## Usage Guide

### Step 1: Create a Base Directory

```bash
mkdir -p base
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: myapp
EOF
```

### Step 2: Create Base Resources

```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
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
          image: nginx:1.25
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: app-config
```

```yaml
# base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

```yaml
# base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_NAME: myapp
  APP_PORT: "80"
```

### Step 3: Build the Base

```bash
# Build and inspect base manifests
kustomize build base/

# Or using kubectl
kubectl kustomize base/
```

### Step 4: Create an Overlay Directory

```bash
mkdir -p overlays/production
cat > overlays/production/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml
  - patches/resource-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - ENV=production
      - LOG_LEVEL=info

secretGenerator:
  - name: app-secrets
    literals:
      - DB_PASSWORD=supersecret
    type: Opaque
EOF
```

### Step 5: Create Patches

```yaml
# overlays/production/patches/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
```

```yaml
# overlays/production/patches/resource-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: myapp
          resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 250m
              memory: 256Mi
```

### Step 6: Build the Overlay

```bash
# Build and inspect overlay manifests
kustomize build overlays/production/

# Apply to cluster
kubectl apply -k overlays/production/
```

### Step 7: Add More Overlays

```bash
# Create dev overlay
mkdir -p overlays/dev
cat > overlays/dev/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - ENV=development
      - LOG_LEVEL=debug
EOF
```

### Step 8: Use Generators

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml

configMapGenerator:
  - name: nginx-config
    files:
      - nginx.conf
    options:
      disableNameSuffixHash: true

secretGenerator:
  - name: tls-secret
    files:
      - tls.crt
      - tls.key
    type: kubernetes.io/tls
```

### Step 9: Apply JSON 6902 Patches

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 10
      - op: add
        path: /spec/template/spec/containers/0/env/-
        name: ENV
        value: production
```

### Step 10: Use Components

```bash
# Create a component
mkdir components/monitoring
cat > components/monitoring/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - deployment.yaml
  - service.yaml
EOF
```

```yaml
# components/monitoring/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:latest
          ports:
            - containerPort: 9090
```

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

components:
  - ../../components/monitoring
```

### Step 11: Remote Resources

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - https://github.com/kubernetes-sigs/kustomize/examples/helloWorld?ref=v1.0.6
  - deployment.yaml
  - service.yaml
```

### Step 12: Apply to Cluster

```bash
# Dry run
kubectl apply -k overlays/production/ --dry-run=client

# Apply
kubectl apply -k overlays/production/

# Diff
kubectl diff -k overlays/production/

# Delete
kubectl delete -k overlays/production/
```

### Step 13: Validate Manifests

```bash
# Build and validate
kustomize build overlays/production/ | kubectl apply --dry-run=client -f -

# Use kubeconform
kustomize build overlays/production/ | kubeconform

# Use kubeval
kustomize build overlays/production/ | kubeval
```

### Step 14: Manage Resources

```bash
# List all resources
kubectl get all -k overlays/production/

# Describe resources
kubectl describe -k overlays/production/

# Get specific resource
kubectl get deployment myapp -k overlays/production/
```

### Step 15: Debug Templates

```bash
# Render and inspect
kustomize build overlays/production/ -o output.yaml

# Diff between environments
diff <(kustomize build overlays/dev/) <(kustomize build overlays/production/)

# Validate YAML
kustomize build overlays/production/ | python -c "import sys, yaml; yaml.safe_load(sys.stdin)"
```

---

## Custom Configuration

### Custom Patches

```yaml
# patches/ingress-patch.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

### Custom Generators

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

configMapGenerator:
  - name: app-config
    literals:
      - KEY1=value1
      - KEY2=value2
    files:
      - config.properties
    options:
      disableNameSuffixHash: true
      annotations:
        my-annotation: value
      labels:
        my-label: value

secretGenerator:
  - name: app-secret
    literals:
      - DB_PASSWORD=secret
    type: Opaque
    options:
      disableNameSuffixHash: true
```

### Custom Replicators

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

replicas:
  - name: myapp
    count: 5
```

### Custom Namespace

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
  - deployment.yaml
  - service.yaml
```

### Custom Name Prefix/Suffix

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namePrefix: prod-
nameSuffix: -v1

resources:
  - deployment.yaml
  - service.yaml
```

### Custom Images

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

images:
  - name: nginx
    newName: myregistry/nginx
    newTag: "1.25"

resources:
  - deployment.yaml
```

---

## Integration

### Kustomize + kubectl

```bash
# Apply with kustomize
kubectl apply -k overlays/production/

# Build and pipe
kustomize build overlays/production/ | kubectl apply -f -

# Diff
kubectl diff -k overlays/production/
```

### Kustomize + ArgoCD

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/k8s-configs
    targetRevision: main
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Kustomize + Flux

```yaml
# Kustomization (Flux)
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  path: overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: myapp
```

### Kustomize + Helm

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: nginx
    repo: https://charts.bitnami.com/bitnami
    version: "17.x.x"
    releaseName: my-nginx
    namespace: production
    valuesInline:
      replicaCount: 3
      service:
        type: ClusterIP
```

### Kustomize + GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy with Kustomize

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and validate
        run: |
          kustomize build overlays/production | kubeconform
      
      - name: Deploy
        run: |
          kubectl apply -k overlays/production/
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG }}
```

### Kustomize + Terraform

```hcl
# main.tf
resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}

resource "null_resource" "kustomize_apply" {
  provisioner "local-exec" {
    command = "kubectl apply -k overlays/production/"
  }

  depends_on = [kubernetes_namespace.production]
}
```

### Kustomize + Helmfile

```yaml
# helmfile.yaml
repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  - name: my-nginx
    chart: bitnami/nginx
    values:
      - replicaCount: 3
    hooks:
      - events: ["postsync"]
        command: kubectl
        args: ["apply", "-k", "overlays/production/"]
```

### Kustomize + CI/CD Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - deploy

kustomize-validate:
  stage: validate
  image: alpine/k8s:1.28.0
  script:
    - kustomize build overlays/production | kubeconform

kustomize-deploy:
  stage: deploy
  image: alpine/k8s:1.28.0
  script:
    - kubectl apply -k overlays/production/
  only:
    - main
```

---

## Security

### Secret Management

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

secretGenerator:
  - name: app-secret
    literals:
      - DB_PASSWORD=changeme
    type: Opaque
    options:
      disableNameSuffixHash: true

  - name: tls-secret
    files:
      - tls.crt
      - tls.key
    type: kubernetes.io/tls
```

### External Secrets

```yaml
# Use SOPS for encrypted secrets
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - secret.yaml

# Apply SOPS before kustomize
# sops -d secret.enc.yaml | kubectl apply -f -
```

### RBAC

```yaml
# templates/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ .Release.Name }}-role
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
```

### Network Policies

```yaml
# templates/networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: myapp
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: myapp
```

### Pod Security

```yaml
# patches/security-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: myapp
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
```

### Resource Quotas

```yaml
# templates/resourcequota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: myapp-quota
  namespace: production
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
```

### Limit Ranges

```yaml
# templates/limitrange.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: myapp-limitrange
  namespace: production
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
```

---

## Troubleshooting

### Issue 1: Kustomization.yaml Not Found

**Symptom**: `Error: accumulo: load or build: couldn't find kustomization.yaml`

**Solution**: Ensure `kustomization.yaml` exists in the current directory:
```bash
ls -la kustomization.yaml
# Create if missing
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: []
EOF
```

### Issue 2: Resource Already Exists

**Symptom**: `Error: resource already exists`

**Solution**: Use strategic merge patch instead of creating a new resource:
```yaml
# Instead of creating a new Deployment
# patches/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
```

### Issue 3: Namespace Mismatch

**Symptom**: Resources applied to wrong namespace

**Solution**: Ensure namespace is set in kustomization.yaml:
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
```

### Issue 4: Patches Not Applied

**Symptom**: Changes not reflected in built manifests

**Solution**: Verify patch file path and syntax:
```bash
# Build and inspect
kustomize build overlays/production/

# Check patches
ls -la overlays/production/patches/
```

### Issue 5: Generator Not Working

**Symptom**: ConfigMap or Secret not created

**Solution**: Check generator syntax and file paths:
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
configMapGenerator:
  - name: my-config
    files:
      - config.properties
```

### Issue 6: Remote Resource Not Found

**Symptom**: `Error: trouble processing: ...`

**Solution**: Verify the remote URL and reference:
```yaml
resources:
  - https://github.com/org/repo/path?ref=main
```

### Issue 7: Circular Dependencies

**Symptom**: `Error: cycle detected`

**Solution**: Check for circular references between kustomization files:
```bash
# List all resources
kustomize build . | grep -E "^(apiVersion|kind|name)"
```

### Issue 8: Invalid YAML

**Symptom**: `Error: yaml: unmarshal errors`

**Solution**: Validate YAML syntax:
```bash
kustomize build . > /dev/null
# Or
yaml lint kustomization.yaml
```

### Issue 9: Missing Required Fields

**Symptom**: `Error: missing required field`

**Solution**: Ensure all required fields are present:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

### Issue 10: Label Selector Mismatch

**Symptom**: Service not finding pods

**Solution**: Ensure labels match between Deployment and Service:
```yaml
# In Deployment
metadata:
  labels:
    app: myapp
spec:
  selector:
    matchLabels:
      app: myapp

# In Service
spec:
  selector:
    app: myapp
```

### Issue 11: Image Pull Error

**Symptom**: `ImagePullBackOff` or `ErrImagePull`

**Solution**: Verify image name and tag:
```yaml
# kustomization.yaml
images:
  - name: nginx
    newName: myregistry/nginx
    newTag: "1.25"
```

### Issue 12: Port Conflict

**Symptom**: Service port already in use

**Solution**: Check service ports and ensure no conflicts:
```yaml
# Service
spec:
  ports:
    - port: 80
      targetPort: 8080
```

### Issue 13: ConfigMap Update Not Triggering Rollout

**Symptom**: Pods not restarted when ConfigMap changes

**Solution**: Use `configMapGenerator` with `disableNameSuffixHash: false`:
```yaml
configMapGenerator:
  - name: my-config
    literals:
      - KEY=value
    options:
      disableNameSuffixHash: false  # Default, generates hash suffix
```

### Issue 14: Secret Not Encoded

**Symptom**: Secret data not properly encoded

**Solution**: Use `secretGenerator` instead of manually creating secrets:
```yaml
secretGenerator:
  - name: my-secret
    literals:
      - DB_PASSWORD=secret
    type: Opaque
```

### Issue 15: Kustomize Version Mismatch

**Symptom**: `Error: unknown apiVersion`

**Solution**: Update kustomize or use a compatible apiVersion:
```yaml
# Use v1beta1 for older versions
apiVersion: kustomize.config.k8s.io/v1beta1

# Use v1 for newer versions
apiVersion: kustomize.config.k8s.io/v1
```

### Issue 16: Build Output Too Large

**Symptom**: `Error: manifest too large`

**Solution**: Split resources into separate files or use kustomize build with output:
```bash
kustomize build . -o output.yaml
```

### Issue 17: Helm Chart Not Found

**Symptom**: `Error: chart not found`

**Solution**: Verify the chart repository and version:
```yaml
helmCharts:
  - name: nginx
    repo: https://charts.bitnami.com/bitnami
    version: "17.x.x"
```

### Issue 18: Component Not Loading

**Symptom**: `Error: component not found`

**Solution**: Verify component path and structure:
```yaml
components:
  - ../../components/monitoring
```

### Issue 19: Remote Reference Not Found

**Symptom**: `Error: remote resource not found`

**Solution**: Verify the remote reference and branch/tag:
```yaml
resources:
  - https://github.com/org/repo/path?ref=v1.0.0
```

### Issue 20: Build Fails Silently

**Symptom**: No output from kustomize build

**Solution**: Add verbose output:
```bash
kustomize build . --stack-trace
```

---

## Tips & Best Practices

### 1. Use Base and Overlays

```
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   └── production/
│       ├── kustomization.yaml
│       └── patches/
```

### 2. Use Strategic Merge Patches

```yaml
# patches/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
```

### 3. Use Generators for ConfigMaps and Secrets

```yaml
configMapGenerator:
  - name: my-config
    files:
      - config.properties

secretGenerator:
  - name: my-secret
    literals:
      - DB_PASSWORD=secret
```

### 4. Use Components for Reusable Features

```yaml
# components/monitoring/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - deployment.yaml
  - service.yaml
```

### 5. Use Name Prefix/Suffix

```yaml
namePrefix: prod-
nameSuffix: -v1
```

### 6. Use Common Labels

```yaml
commonLabels:
  app: myapp
  team: platform
```

### 7. Use Namespace

```yaml
namespace: production
```

### 8. Use Images

```yaml
images:
  - name: nginx
    newName: myregistry/nginx
    newTag: "1.25"
```

### 9. Use Replicas

```yaml
replicas:
  - name: myapp
    count: 5
```

### 10. Use Remote Resources

```yaml
resources:
  - https://github.com/org/repo/path?ref=main
```

### 11. Use JSON 6902 Patches

```yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5
```

### 12. Validate Before Applying

```bash
kustomize build . | kubeconform
kubectl apply -k . --dry-run=client
```

### 13. Use GitOps

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    path: overlays/production
```

### 14. Use Helm with Kustomize

```yaml
helmCharts:
  - name: nginx
    repo: https://charts.bitnami.com/bitnami
    version: "17.x.x"
```

### 15. Use Components for Feature Toggles

```yaml
# overlays/production/kustomization.yaml
components:
  - ../../components/monitoring
  - ../../components/logging
```

### 16. Keep Patches Small

```yaml
# Good: only patch what you need
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5

# Bad: patch entire deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 5
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
          image: nginx
```

### 17. Use DisableNameSuffixHash

```yaml
configMapGenerator:
  - name: my-config
    options:
      disableNameSuffixHash: true
```

### 18. Use Diff to Compare

```bash
diff <(kustomize build overlays/dev/) <(kustomize build overlays/production/)
```

### 19. Use Output for Debugging

```bash
kustomize build . -o output.yaml
```

### 20. Use Labels for Organization

```yaml
commonLabels:
  app: myapp
  env: production
  team: platform
```

---

## Command Reference

### Basic Commands

```bash
# Build kustomization
kustomize build .

# Build with output
kustomize build . -o output.yaml

# Build with kubectl
kubectl kustomize .

# Apply kustomization
kubectl apply -k .

# Diff kustomization
kubectl diff -k .
```

### Resource Management

```bash
# List resources
kubectl get all -k .

# Describe resources
kubectl describe -k .

# Delete resources
kubectl delete -k .
```

### Build Options

```bash
# Enable alpha plugins
kustomize build . --enable-alpha-plugins

# Enable exec
kustomize build . --enable-exec

# Load restrictions
kustomize build . --load-restrictor LoadRestrictionsNone

# Stack trace
kustomize build . --stack-trace
```

### Version and Help

```bash
# Show version
kustomize version

# Show help
kustomize --help

# Show build help
kustomize build --help
```

### Common Patterns

```bash
# Build and pipe to kubectl
kustomize build . | kubectl apply -f -

# Build and validate
kustomize build . | kubeconform

# Build and diff
diff <(kubectl kustomize base/) <(kubectl kustomize overlays/production/)

# Build with dry run
kubectl apply -k overlays/production/ --dry-run=client
```

### Debugging

```bash
# Verbose output
kustomize build . --stack-trace

# Debug build
kustomize build . -o output.yaml

# Check resources
kustomize build . | grep -E "^(apiVersion|kind|name)"
```

---

## Configuration Reference

### kustomization.yaml Fields

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Resources
resources:
  - deployment.yaml
  - service.yaml
  - https://github.com/org/repo/path?ref=main

# Patches
patchesStrategicMerge:
  - patches/replica-patch.yaml

patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5

# Generators
configMapGenerator:
  - name: my-config
    literals:
      - KEY=value
    files:
      - config.properties
    options:
      disableNameSuffixHash: true

secretGenerator:
  - name: my-secret
    literals:
      - DB_PASSWORD=secret
    type: Opaque

# Common labels and annotations
commonLabels:
  app: myapp

commonAnnotations:
  description: "My application"

# Namespace
namespace: production

# Name prefix/suffix
namePrefix: prod-
nameSuffix: -v1

# Images
images:
  - name: nginx
    newName: myregistry/nginx
    newTag: "1.25"

# Replicas
replicas:
  - name: myapp
    count: 5

# Components
components:
  - ../../components/monitoring

# Helm charts
helmCharts:
  - name: nginx
    repo: https://charts.bitnami.com/bitnami
    version: "17.x.x"
    releaseName: my-nginx
    namespace: production
    valuesInline:
      replicaCount: 3
```

### Patch Types

```yaml
# Strategic Merge Patch
patchesStrategicMerge:
  - patches/patch.yaml

# JSON 6902 Patch
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5

# Patch with name
patches:
  - path: patches/patch.yaml
    target:
      group: apps
      version: v1
      kind: Deployment
      name: myapp
```

### Generator Options

```yaml
configMapGenerator:
  - name: my-config
    literals:
      - KEY=value
    options:
      disableNameSuffixHash: true
      labels:
        my-label: value
      annotations:
        my-annotation: value

secretGenerator:
  - name: my-secret
    literals:
      - DB_PASSWORD=secret
    options:
      disableNameSuffixHash: true
```

### Component Structure

```yaml
# Component kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - deployment.yaml
  - service.yaml

patchesStrategicMerge:
  - patches/patch.yaml

configMapGenerator:
  - name: my-config
    literals:
      - KEY=value
```

---

## Real-World Examples

### Example 1: NGINX Deployment

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: nginx
```

```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
```

### Example 2: Multi-Environment

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml
  - patches/resource-patch.yaml

namespace: production
```

### Example 3: Complete Application Stack

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - secret.yaml
  - ingress.yaml
  - hpa.yaml
  - pdb.yaml

commonLabels:
  app: myapp
  team: platform
```

### Example 4: Helm + Kustomize

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: nginx
    repo: https://charts.bitnami.com/bitnami
    version: "17.x.x"
    releaseName: my-nginx
    namespace: production
    valuesInline:
      replicaCount: 3
      service:
        type: ClusterIP
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: myapp.example.com
            paths:
              - path: /
                pathType: Prefix
```

### Example 5: Components

```yaml
# components/monitoring/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - deployment.yaml
  - service.yaml
  - servicemonitor.yaml

configMapGenerator:
  - name: prometheus-config
    files:
      - prometheus.yml
```

### Example 6: GitOps with ArgoCD

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - patches/replica-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - ENV=production
      - LOG_LEVEL=info
```

### Example 7: GitHub Actions with Kustomize

```yaml
# .github/workflows/deploy.yml
name: Deploy with Kustomize

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and validate
        run: |
          kustomize build overlays/production | kubeconform
      
      - name: Deploy
        run: |
          kubectl apply -k overlays/production/
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG }}
```

### Example 8: Flux with Kustomize

```yaml
# kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  path: overlays/production
  prune: true
  sourceRef:
    kind: GitRepository
    name: myapp
```

---

## Further Reading

### Official Documentation
- [Kustomize Documentation](https://kubectl.docs.kustomize.io/)
- [Kustomize GitHub](https://github.com/kubernetes-sigs/kustomize)
- [kubectl Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-projects/kustomize/)
- [Kustomize API Reference](https://github.com/kubernetes-sigs/kustomize/tree/master/api)

### Related Tools
- [Helm](https://helm.sh/) — Package manager for Kubernetes
- [ArgoCD](https://argoproj.github.io/cd/) — GitOps continuous delivery
- [Flux](https://fluxcd.io/) — GitOps toolkit for Kubernetes
- [Kubeconform](https://github.com/yannh/kubeconform) — Kubernetes manifest validator
- [Kubeval](https://github.com/instrumenta/kubeval) — Kubernetes configuration validation

### Community
- [Kustomize Slack](https://kubernetes.slack.com/messages/kustomize)
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [Kustomize GitHub Discussions](https://github.com/kubernetes-sigs/kustomize/discussions)

### Learning Resources
- [Kustomize Tutorial](https://kubernetes.io/docs/tasks/manage-kubernetes-projects/kustomize/)
- [Kustomize Examples](https://github.com/kubernetes-sigs/kustomize/tree/master/examples)
- [Kustomize Best Practices](https://kubectl.docs.kustomize.io/guides/best_practices/)
- [Kustomize vs Helm](https://www.weave.works/technologies/gitops/kustomize-vs-helm/)
