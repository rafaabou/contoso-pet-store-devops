# Helm Charts Complete Guide — Creating & Publishing

## Table of Contents

1. [What Is Helm](#what-is-helm)
2. [Why Use Helm](#why-use-helm)
3. [Installation](#installation)
4. [Core Concepts](#core-concepts)
5. [Chart Structure](#chart-structure)
6. [Usage Guide (Step-by-Step)](#usage-guide)
7. [Custom Configuration](#custom-configuration)
8. [Chart Repository](#chart-repository)
9. [Integration](#integration)
10. [Security](#security)
11. [Troubleshooting](#troubleshooting)
12. [Tips & Best Practices](#tips--best-practices)
13. [Command Reference](#command-reference)
14. [Configuration Reference](#configuration-reference)
15. [Real-World Examples](#real-world-examples)
16. [Further Reading](#further-reading)

---

## What Is Helm

Helm is the package manager for Kubernetes. It is the de facto standard for deploying and managing applications on Kubernetes clusters. Helm simplifies the deployment, upgrade, rollback, and management of Kubernetes applications by packaging them into reusable, configurable units called "charts."

A Helm chart is a collection of files that describe a related set of Kubernetes resources. A chart contains a `Chart.yaml` file (metadata), a `values.yaml` file (default configuration), and template files that generate Kubernetes manifests from configuration values. Charts can depend on other charts, be shared via repositories, and be versioned for safe upgrades and rollbacks.

Helm charts can be:
- **Application charts**: Deploy a single application (e.g., nginx, PostgreSQL)
- **Library charts**: Provide reusable templates and functions
- **Umbrella charts**: Deploy multiple related applications as a single release

Helm works by:
1. Taking a chart and configuration values
2. Rendering the templates with those values
3. Producing Kubernetes manifests
4. Applying those manifests to the cluster

Helm maintains a release history, allowing instant rollbacks to previous versions. It also supports atomic installs (rollback on failure), dry-run rendering, and template debugging.

---

## Why Use Helm

**Simplified Deployment**: Deploy complex applications with a single command instead of managing multiple YAML files. Helm charts encapsulate all Kubernetes resources (Deployments, Services, ConfigMaps, Secrets, Ingresses, etc.) into a single package.

**Configuration Management**: Override default values for different environments (dev, staging, production) using values files or command-line flags. The same chart can be deployed to multiple environments with different configurations.

**Version Control and Rollbacks**: Helm tracks release history, enabling instant rollbacks to any previous version. This is critical for production deployments where quick recovery from bad releases is essential.

**Reusable Templates**: Charts can be shared across teams and organizations. The Helm Hub and Artifact Hub host thousands of pre-built charts for common software (databases, monitoring tools, message queues, etc.).

**Dependency Management**: Charts can declare dependencies on other charts. An umbrella chart can deploy an entire application stack (database, cache, application server) as a single unit.

**Dry-Run and Debugging**: Preview the manifests that Helm would apply without actually deploying them. Debug template rendering issues before they affect your cluster.

**Release Management**: Track which version of an application is deployed, when it was deployed, and what configuration was used. This provides audit trails for compliance and operations.

**Backward Compatibility**: Helm charts support values file inheritance, allowing you to extend and override base configurations without duplicating template code.

---

## Installation

### macOS

```bash
# Using Homebrew
brew install helm

# Verify installation
helm version
# version.BuildInfo{Version:"v3.14.0", ...}
```

### Linux

```bash
# Download the latest release
HELM_VERSION=3.14.0
curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar xz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Or using the install script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### Windows

```bash
# Using Chocolatey
choco install kubernetes-helm

# Using Scoop
scoop install helm

# Or download from GitHub releases
```

### Verify Installation

```bash
# Check version
helm version

# Add official chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repository index
helm repo update

# Search for charts
helm search repo nginx
```

### Configure Shell Completion

```bash
# Bash
helm completion bash > /etc/bash_completion.d/helm

# Zsh
helm completion zsh > "${fpath[1]}/_helm"

# Fish
helm completion fish > ~/.config/fish/completions/helm.fish
```

### Install with Go

```bash
# Install from source
go install github.com/helm/helm/v3@latest

# Or use krew plugin manager
kubectl krew install helm
```

---

## Core Concepts

### Charts

A chart is a package of pre-configured Kubernetes resources. Charts are organized in directories with a specific structure:

```
mychart/
  Chart.yaml          # Chart metadata
  Chart.lock          # Dependency lock file
  values.yaml         # Default configuration values
  charts/             # Dependencies
  templates/          # Template files
  templates/NOTES.txt # Post-install notes
  .helmignore         # Files to ignore
```

### Releases

A release is a running instance of a chart. You can install the same chart multiple times in the same cluster with different release names and configurations:

```bash
# Install the same chart twice with different names
helm install my-nginx bitnami/nginx
helm install another-nginx bitnami/nginx --set replicaCount=3
```

### Repositories

Repositories are collections of charts that can be shared and distributed:

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Search for charts
helm search repo bitnami/nginx

# Install a chart
helm install my-nginx bitnami/nginx
```

### Values

Values are configuration parameters that are passed to charts. Charts define default values in `values.yaml`, and users can override them:

```bash
# Use default values
helm install my-nginx bitnami/nginx

# Override values
helm install my-nginx bitnami/nginx --set replicaCount=3

# Use a custom values file
helm install my-nginx bitnami/nginx -f my-values.yaml
```

### Templates

Templates are Go template files that generate Kubernetes manifests. They use the `{{ }}` syntax to inject values:

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### Hooks

Helm hooks are Kubernetes resources that run at specific points in the release lifecycle:

- `pre-install`: Runs before the release is installed
- `post-install`: Runs after the release is installed
- `pre-upgrade`: Runs before the release is upgraded
- `post-upgrade`: Runs after the release is upgraded
- `pre-delete`: Runs before the release is deleted
- `post-delete`: Runs after the release is deleted
- `pre-rollback`: Runs before the release is rolled back
- `post-rollback`: Runs after the release is rolled back

### Tests

Helm tests are jobs that run when `helm test` is invoked. They verify that the release is working correctly:

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-connection"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "mychart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

---

## Chart Structure

### Chart.yaml

```yaml
apiVersion: v2
name: mychart
description: A Helm chart for my application
type: application          # application or library
version: 0.1.0            # Chart version (SemVer)
appVersion: "1.0.0"       # Application version
keywords:
  - web
  - nginx
home: https://github.com/myorg/mychart
sources:
  - https://github.com/myorg/mychart
maintainers:
  - name: John Doe
    email: john@example.com
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

### values.yaml

```yaml
# Default values for mychart
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: nginx
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

postgresql:
  enabled: false
  auth:
    postgresPassword: ""
    database: mydb
```

### templates/

```
templates/
  _helpers.tpl          # Template helpers
  deployment.yaml       # Deployment manifest
  service.yaml          # Service manifest
  ingress.yaml          # Ingress manifest
  configmap.yaml        # ConfigMap manifest
  secret.yaml           # Secret manifest
  hpa.yaml              # HorizontalPodAutoscaler
  serviceaccount.yaml   # ServiceAccount
  NOTES.txt             # Post-install notes
  tests/
    test-connection.yaml  # Test job
```

### _helpers.tpl

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "mychart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### .helmignore

```
# Patterns to ignore when building packages.
.git
.gitignore
.DS_Store
*.swp
*.bak
*.tmp
*.orig
*~
.project
.idea/
*.tmproj
.vscode/
```

---

## Usage Guide

### Step 1: Create a New Chart

```bash
# Create a new chart
helm create mychart

# Examine the structure
ls mychart/
# Chart.yaml  Chart.lock  charts/  templates/  values.yaml
```

### Step 2: Understand the Default Chart

```bash
# View the default Chart.yaml
cat mychart/Chart.yaml

# View the default values.yaml
cat mychart/values.yaml

# View the default templates
cat mychart/templates/deployment.yaml
```

### Step 3: Customize the Chart

```yaml
# mychart/Chart.yaml
apiVersion: v2
name: mywebapp
description: A Helm chart for my web application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

```yaml
# mychart/values.yaml
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25"

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Step 4: Template the Manifests

```yaml
# mychart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mywebapp.fullname" . }}
  labels:
    {{- include "mywebapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "mywebapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mywebapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

### Step 5: Lint and Validate

```bash
# Lint the chart
helm lint mychart/

# Template and inspect rendered manifests
helm template my-release mychart/

# Dry run (validate against cluster)
helm install my-release mychart/ --dry-run --debug
```

### Step 6: Install the Chart

```bash
# Install with default values
helm install my-release mychart/

# Install with custom values
helm install my-release mychart/ -f custom-values.yaml

# Install with set values
helm install my-release mychart/ --set replicaCount=5

# Install to a specific namespace
helm install my-release mychart/ --namespace mynamespace --create-namespace

# Install with wait (wait for resources to be ready)
helm install my-release mychart/ --wait --timeout 5m

# Install atomically (rollback on failure)
helm install my-release mychart/ --atomic
```

### Step 7: Upgrade the Release

```bash
# Upgrade with new values
helm upgrade my-release mychart/ -f new-values.yaml

# Upgrade and install if not exists
helm upgrade --install my-release mychart/

# Upgrade with specific values
helm upgrade my-release mychart/ --set replicaCount=10

# Upgrade atomically
helm upgrade my-release mychart/ --atomic
```

### Step 8: Rollback

```bash
# List release history
helm history my-release

# Rollback to revision 1
helm rollback my-release 1

# Rollback with wait
helm rollback my-release 1 --wait
```

### Step 9: Uninstall

```bash
# Uninstall the release
helm uninstall my-release

# Uninstall and keep history
helm uninstall my-release --keep-history

# Uninstall from specific namespace
helm uninstall my-release --namespace mynamespace
```

### Step 10: Package and Publish

```bash
# Package the chart
helm package mychart/

# Push to a chart repository
cm-push mychart-0.1.0.tgz https://charts.example.com/

# Or using OCI
helm push mychart-0.1.0.tgz oci://registry.example.com/charts
```

### Step 11: Add Dependencies

```bash
# Add a dependency
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update mychart/

# Or add to Chart.yaml and run
helm dependency update mychart/
```

### Step 12: Run Tests

```bash
# Run Helm tests
helm test my-release

# Run tests with specific timeout
helm test my-release --timeout 5m
```

### Step 13: Debug Templates

```bash
# Render templates with specific values
helm template my-release mychart/ -f values.yaml

# Render and show all values
helm template my-release mychart/ --show-only templates/deployment.yaml

# Debug template rendering
helm template my-release mychart/ --debug
```

### Step 14: Export Values

```bash
# Get all values for a release
helm get values my-release

# Get all values including defaults
helm get values my-release --all

# Get specific values
helm get values my-release --output json
```

### Step 15: Plugin Management

```bash
# List installed plugins
helm plugin list

# Install a plugin
helm plugin install https://github.com/chartmuseum/helm-push

# Uninstall a plugin
helm plugin uninstall push

# Update plugins
helm plugin update push
```

---

## Custom Configuration

### Values File Inheritance

```yaml
# base-values.yaml (base configuration)
replicaCount: 2
image:
  repository: nginx
  tag: "1.25"

# production-values.yaml (extends base)
# Use -f with multiple files
replicaCount: 5
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

```bash
# Use multiple values files
helm install my-release mychart/ -f base-values.yaml -f production-values.yaml
```

### Conditional Resources

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mychart.fullname" . }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "mychart.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

### Template Functions

```yaml
# Common template functions
{{ .Values.name }}                    # Access values
{{ .Chart.Name }}                     # Access chart metadata
{{ .Release.Name }}                   # Access release info
{{ include "mychart.fullname" . }}    # Call template function
{{ toYaml .Values.resources | nindent 12 }}  # Convert to YAML
{{ .Values.ingress.enabled | default false }}  # Default value
{{ if .Values.ingress.enabled }}...{{ end }}  # Conditional
{{- range .Values.ingress.hosts }}...{{- end }}  # Loop
{{ required "A valid port is required" .Values.service.port }}  # Required
{{ quote .Values.image.tag }}         # Quote value
{{ semverCompare ">= 1.14.0" .Capabilities.KubeVersion.Version }}  # Version compare
```

### Hooks for Lifecycle Management

```yaml
# templates/migrations.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-migrations
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
        - name: migrations
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["./migrate.sh"]
      restartPolicy: Never
  backoffLimit: 1
```

### Tests for Validation

```yaml
# templates/tests/test-api.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-api"
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-weight": "1"
spec:
  containers:
    - name: curl
      image: curlimages/curl
      command: ['curl']
      args:
        - '-f'
        - 'http://{{ include "mychart.fullname" . }}:{{ .Values.service.port }}/health'
  restartPolicy: Never
```

### Named Templates

```yaml
# templates/_helpers.tpl
{{- define "mychart.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  {{- toYaml . | nindent 2 }}
{{- end }}
```

```yaml
# templates/deployment.yaml
{{ include "mychart.deployment" .Values.deploymentSpec }}
```

---

## Chart Repository

### Chart Museum

```bash
# Install ChartMuseum
docker run -d -p 8080:8080 \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  -v $(pwd)/charts:/charts \
  chartmuseum/chartmuseum:latest

# Add as Helm repo
helm repo add local http://localhost:8080

# Push chart
cm-push mychart-0.1.0.tgz http://localhost:8080
```

### OCI Registry

```bash
# Login to OCI registry
helm registry login registry.example.com \
  --username myuser \
  --password mypassword

# Package and push chart
helm package mychart/
helm push mychart-0.1.0.tgz oci://registry.example.com/charts

# Pull chart from OCI registry
helm pull oci://registry.example.com/charts/mychart --version 0.1.0

# Install from OCI registry
helm install my-release oci://registry.example.com/charts/mychart --version 0.1.0
```

### GitHub Pages

```bash
# Package chart
helm package mychart/

# Create gh-pages branch
git checkout --orphan gh-pages
git reset --hard
cp mychart-*.tgz .
helm repo index .
git add .
git commit -m "Add chart"
git push origin gh-pages

# Add as repo
helm repo add mycharts https://myorg.github.io/myrepo
```

### Chart Repository Structure

```
myrepo/
  index.yaml           # Repository index
  mychart-0.1.0.tgz   # Chart package
  mychart-0.2.0.tgz   # Chart package
  ...
```

### Publishing Workflow

```bash
# 1. Package the chart
helm package mychart/

# 2. Sign the chart (optional but recommended)
helm sign mychart-0.1.0.tgz

# 3. Push to repository
cm-push mychart-0.1.0.tgz https://charts.example.com/

# 4. Update repository index
helm repo update

# 5. Verify
helm search repo mychart
```

---

## Integration

### Helm + GitHub Actions

```yaml
# .github/workflows/helm.yml
name: Helm Chart

on:
  push:
    paths:
      - 'charts/**'

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint chart
        run: helm lint charts/mychart
      
      - name: Template chart
        run: helm template my-release charts/mychart
      
      - name: Install chart
        run: |
          helm install my-release charts/mychart \
            --namespace test \
            --create-namespace \
            --wait --timeout 5m
      
      - name: Test chart
        run: helm test my-release --namespace test
      
      - name: Uninstall chart
        if: always()
        run: helm uninstall my-release --namespace test

  publish:
    needs: lint-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Package chart
        run: helm package charts/mychart
      
      - name: Push to OCI registry
        run: |
          echo "${{ secrets.REGISTRY_PASSWORD }}" | helm registry login registry.example.com \
            --username ${{ secrets.REGISTRY_USERNAME }} \
            --password-stdin
          helm push mychart-*.tgz oci://registry.example.com/charts
```

### Helm + ArgoCD

```yaml
# argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.example.com
    chart: mychart
    targetRevision: 0.1.0
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Helm + Flux

```yaml
# helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  chart:
    spec:
      chart: mychart
      version: "0.1.x"
      sourceRef:
        kind: HelmRepository
        name: myrepo
        namespace: flux-system
  values:
    replicaCount: 3
    image:
      tag: "1.25"
```

### Helm + CI/CD Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - publish

helm-lint:
  stage: lint
  image: alpine/helm:3.14.0
  script:
    - helm lint charts/mychart

helm-test:
  stage: test
  image: alpine/helm:3.14.0
  script:
    - helm template my-release charts/mychart

helm-publish:
  stage: publish
  image: alpine/helm:3.14.0
  script:
    - helm package charts/mychart
    - helm push mychart-*.tgz oci://$CI_REGISTRY/charts
  only:
    - main
```

### Helm + Kustomize

```bash
# Use Helm with Kustomize
kustomize build . | helm template my-release charts/mychart -f - 
```

### Helm + Kubernetes Operators

```yaml
# Deploy an operator with Helm
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: prometheus-operator
spec:
  chart:
    spec:
      chart: kube-prometheus-stack
      version: "55.x"
      sourceRef:
        kind: HelmRepository
        name: prometheus-community
  values:
    grafana:
      enabled: true
    prometheus:
      enabled: true
```

---

## Security

### Secrets Management

```yaml
# templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
type: Opaque
data:
  {{- range $key, $value := .Values.secrets }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
```

```yaml
# values.yaml
secrets:
  db-password: changeme
  api-key: abc123
```

```bash
# Pass secrets via values file
helm install my-release mychart/ -f secrets.yaml

# Or via command line
helm install my-release mychart/ \
  --set secrets.db-password=changeme \
  --set secrets.api-key=abc123
```

### RBAC Configuration

```yaml
# templates/serviceaccount.yaml
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "mychart.serviceAccountName" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

# templates/role.yaml
{{- if .Values.rbac.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
rules:
  {{- toYaml .Values.rbac.rules | nindent 2 }}
{{- end }}
```

### Network Policies

```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              {{- include "mychart.selectorLabels" . | nindent 14 }}
  egress:
    - to:
        - podSelector:
            matchLabels:
              {{- include "mychart.selectorLabels" . | nindent 14 }}
{{- end }}
```

### Pod Security

```yaml
# templates/deployment.yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
```

### Chart Signing

```bash
# Generate GPG key
gpg --gen-key

# Sign chart
helm sign mychart-0.1.0.tgz

# Verify chart
helm verify mychart-0.1.0.tgz.prov

# Install only signed charts
helm install my-release mychart/ --verify
```

### Values Encryption

```bash
# Use SOPS for encrypted values
sops -e values-secret.yaml > values-secret.enc.yaml

# Decrypt during install
sops -d values-secret.enc.yaml | helm install my-release mychart/ -f -
```

---

## Troubleshooting

### Issue 1: Template Rendering Error

**Symptom**: `template: mychart/templates/deployment.yaml:10: function "include" not defined`

**Solution**: Ensure the template function is defined in `_helpers.tpl` and the syntax is correct:
```yaml
{{ include "mychart.fullname" . }}
# Not
{{ include "mychart.fullname" }}
```

### Issue 2: Values Not Being Applied

**Symptom**: Changes to values.yaml not reflected in rendered manifests

**Solution**: Verify the values path and syntax:
```bash
helm template my-release mychart/ --show-only templates/deployment.yaml
# Check if values are being applied
```

### Issue 3: Dependency Not Found

**Symptom**: `Error: chart "postgresql" not found`

**Solution**: Update dependencies:
```bash
helm dependency update mychart/
# Or add the repository first
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### Issue 4: Release Stuck in Pending

**Symptom**: Release status shows `pending-upgrade` or `pending-install`

**Solution**: Force the release status:
```bash
helm status my-release
helm get values my-release
# If needed, force upgrade
helm upgrade --force my-release mychart/
```

### Issue 5: RBAC Permissions Error

**Symptom**: `forbidden: User "system:serviceaccount:default:default" cannot ...`

**Solution**: Create a ServiceAccount with appropriate RBAC:
```yaml
# templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "mychart.serviceAccountName" . }}

# templates/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "mychart.fullname" . }}
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
```

### Issue 6: Chart Version Conflict

**Symptom**: `Error: cannot reuse a name that is still in use`

**Solution**: Use a different release name or uninstall the previous release:
```bash
helm list --all-namespaces
helm uninstall old-release
helm install new-release mychart/
```

### Issue 7: Missing Required Values

**Symptom**: `Error: required key missing`

**Solution**: Provide the required values:
```yaml
# In values.yaml
{{ required "A valid database password is required" .Values.database.password }}
```

### Issue 8: Conditional Resource Not Rendering

**Symptom**: Ingress not created despite being enabled

**Solution**: Check the condition syntax:
```yaml
{{- if .Values.ingress.enabled }}
# Ensure proper indentation and syntax
{{- end }}
```

### Issue 9: Hook Execution Fails

**Symptom**: Pre-install hook job fails

**Solution**: Check hook annotations and job configuration:
```yaml
annotations:
  "helm.sh/hook": pre-install
  "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

### Issue 10: Chart Test Fails

**Symptom**: `helm test` reports failure

**Solution**: Check test pod logs and configuration:
```bash
kubectl logs my-release-test-connection
helm test my-release --logs
```

### Issue 11: Namespace Not Created

**Symptom**: `Error: namespace "mynamespace" not found`

**Solution**: Use `--create-namespace` flag:
```bash
helm install my-release mychart/ --namespace mynamespace --create-namespace
```

### Issue 12: Release History Not Available

**Symptom**: `Error: no history found`

**Solution**: Ensure history is not deleted:
```bash
# Don't use --keep-history=false
helm uninstall my-release --keep-history
```

### Issue 13: Chart Dependencies Outdated

**Symptom**: `Error: chart dependencies have changed`

**Solution**: Update dependencies:
```bash
helm dependency update mychart/
# Review Chart.lock
cat mychart/Chart.lock
```

### Issue 14: Template Variables Not Available

**Symptom**: `undefined variable` error

**Solution**: Check the context and scope:
```yaml
{{- $name := .Values.name -}}
{{- printf "%s" $name -}}
```

### Issue 15: Image Pull Error

**Symptom**: `ImagePullBackOff` or `ErrImagePull`

**Solution**: Verify image name, tag, and pull policy:
```yaml
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
# Or use imagePullSecrets
imagePullSecrets:
  - name: my-registry-secret
```

### Issue 16: Service Port Mismatch

**Symptom**: Service cannot connect to pods

**Solution**: Ensure service port matches container port:
```yaml
# In deployment
ports:
  - name: http
    containerPort: 8080

# In service
ports:
  - port: 80
    targetPort: 8080
```

### Issue 17: ConfigMap Update Not Triggering Rollout

**Symptom**: Pods not restarted when ConfigMap changes

**Solution**: Use checksum annotation:
```yaml
spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

### Issue 18: Helm Cannot Connect to Cluster

**Symptom**: `Error: Kubernetes cluster unreachable`

**Solution**: Check kubeconfig:
```bash
kubectl cluster-info
helm ls --all-namespaces
# Or specify kubeconfig
helm install my-release mychart/ --kubeconfig ~/.kube/config
```

---

## Tips & Best Practices

### 1. Use Semantic Versioning

```yaml
# Chart.yaml
version: 0.1.0  # Chart version (SemVer)
appVersion: "1.0.0"  # Application version
```

### 2. Follow Chart Naming Conventions

```bash
# Use lowercase and hyphens
helm create my-web-app

# Not
helm create MyWebApp
helm create my_web_app
```

### 3. Use Templates for Reusability

```yaml
# templates/_helpers.tpl
{{- define "mychart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```

### 4. Set Default Values

```yaml
# values.yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
```

### 5. Use Required Values

```yaml
# templates/deployment.yaml
image:
  repository: {{ required "A valid image repository is required" .Values.image.repository }}
```

### 6. Lint Before Deploying

```bash
helm lint mychart/
helm template my-release mychart/
```

### 7. Use Dry-Run for Validation

```bash
helm install my-release mychart/ --dry-run --debug
```

### 8. Implement Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: http
readinessProbe:
  httpGet:
    path: /ready
    port: http
```

### 9. Use Hooks for Migrations

```yaml
annotations:
  "helm.sh/hook": pre-upgrade
  "helm.sh/hook-weight": "0"
  "helm.sh/hook-delete-policy": hook-succeeded
```

### 10. Implement Tests

```yaml
# templates/tests/test-connection.yaml
annotations:
  "helm.sh/hook": test
```

### 11. Use Chart Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

### 12. Keep Charts Small

Split large charts into smaller, focused charts. Use umbrella charts for complex deployments.

### 13. Document Your Charts

```yaml
# Chart.yaml
description: A Helm chart for deploying nginx
home: https://github.com/myorg/mychart
sources:
  - https://github.com/myorg/mychart
```

### 14. Use Helm for Configuration Management

```bash
# Store environment-specific values in files
helm install my-release mychart/ -f values-production.yaml
```

### 15. Implement Rollback Strategy

```bash
# Keep release history
helm uninstall my-release --keep-history

# Rollback to specific revision
helm rollback my-release 3
```

### 16. Use Chart Testing

```bash
# Install chart-testing
brew install chart-testing

# Lint and test charts
ct lint mychart/
ct install mychart/
```

### 17. Publish Charts Properly

```bash
# Package and sign
helm package mychart/
helm sign mychart-0.1.0.tgz

# Push to repository
cm-push mychart-0.1.0.tgz https://charts.example.com/
```

### 18. Use OCI for Chart Storage

```bash
# Use OCI registries for chart storage
helm push mychart-0.1.0.tgz oci://ghcr.io/myorg/charts
```

---

## Command Reference

### Chart Management

```bash
# Create a new chart
helm create mychart

# Lint a chart
helm lint mychart/

# Package a chart
helm package mychart/

# Inspect chart
helm show chart mychart/
helm show values mychart/
helm show readme mychart/
helm show all mychart/
```

### Release Management

```bash
# Install a release
helm install my-release mychart/

# Upgrade a release
helm upgrade my-release mychart/

# Rollback a release
helm rollback my-release 1

# Uninstall a release
helm uninstall my-release

# List releases
helm list
helm list --all-namespaces

# Get release status
helm status my-release

# Get release values
helm get values my-release

# Get release history
helm history my-release
```

### Repository Management

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# List repositories
helm repo list

# Update repository
helm repo update

# Remove a repository
helm repo remove bitnami

# Search repositories
helm search repo bitnami/nginx
helm search hub nginx
```

### Dependency Management

```bash
# Update dependencies
helm dependency update mychart/

# Build dependencies
helm dependency build mychart/

# List dependencies
helm dependency list mychart/
```

### Testing

```bash
# Run tests
helm test my-release

# Run tests with logs
helm test my-release --logs

# Run tests with specific timeout
helm test my-release --timeout 5m
```

### Debugging

```bash
# Template and inspect
helm template my-release mychart/

# Dry run
helm install my-release mychart/ --dry-run --debug

# Get release info
helm get manifest my-release
helm get hooks my-release
helm get all my-release
```

### Plugin Management

```bash
# List plugins
helm plugin list

# Install a plugin
helm plugin install https://github.com/chartmuseum/helm-push

# Uninstall a plugin
helm plugin uninstall push

# Update plugins
helm plugin update push
```

---

## Configuration Reference

### values.yaml Structure

```yaml
# Global values
global:
  imageRegistry: ""
  imagePullSecrets: []

# Chart values
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext: {}

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources: {}

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}
```

### Template Functions Reference

```yaml
# Access values
{{ .Values.key }}
{{ .Values.key.subkey }}

# Access chart metadata
{{ .Chart.Name }}
{{ .Chart.Version }}
{{ .Chart.AppVersion }}

# Access release info
{{ .Release.Name }}
{{ .Release.Namespace }}
{{ .Release.Service }}

# Include template
{{ include "name" . }}

# To YAML
{{ toYaml .Values.resources | nindent 12 }}

# Default value
{{ .Values.key | default "default" }}

# Required value
{{ required "Message" .Values.key }}

# Quote
{{ quote .Values.key }}

# Quote list
{{ toYaml .Values.list | quote }}

# Range
{{- range .Values.list }}
- {{ . }}
{{- end }}

# If
{{- if .Values.enabled }}
# do something
{{- end }}

# If/else
{{- if .Values.enabled }}
# do something
{{- else }}
# do something else
{{- end }}

# Semver compare
{{ semverCompare ">= 1.14.0" .Capabilities.KubeVersion.Version }}
```

### Chart.yaml Reference

```yaml
apiVersion: v2
name: mychart
description: A Helm chart
type: application  # application or library
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - web
  - nginx
home: https://example.com
sources:
  - https://github.com/myorg/mychart
maintainers:
  - name: John Doe
    email: john@example.com
  - name: Jane Doe
    email: jane@example.com
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
    tags:
      - database
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
annotations:
  artifacthub.io/category: integration-delivery
  artifacthub.io/license: MIT
```

---

## Real-World Examples

### Example 1: NGINX Deployment

```yaml
# values.yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### Example 2: PostgreSQL with Dependencies

```yaml
# Chart.yaml
apiVersion: v2
name: myapp
version: 0.1.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled

# values.yaml
postgresql:
  enabled: true
  auth:
    postgresPassword: changeme
    database: mydb
  primary:
    persistence:
      size: 10Gi
```

### Example 3: Complete Application Stack

```yaml
# Chart.yaml
apiVersion: v2
name: fullstack-app
version: 0.1.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
  - name: redis
    version: "17.x.x"
    repository: "https://charts.bitnami.com/bitnami"

# values.yaml
app:
  replicaCount: 3
  image:
    repository: myorg/myapp
    tag: "latest"

postgresql:
  enabled: true
  auth:
    postgresPassword: ${DB_PASSWORD}
    database: mydb

redis:
  enabled: true
  auth:
    enabled: false
```

### Example 4: Multi-Environment Values

```yaml
# values.yaml (base)
replicaCount: 2
image:
  repository: myorg/myapp
  tag: "latest"

# values-dev.yaml
replicaCount: 1
resources:
  limits:
    cpu: 200m
    memory: 256Mi

# values-prod.yaml
replicaCount: 5
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
ingress:
  enabled: true
```

```bash
# Deploy to different environments
helm install myapp-dev charts/myapp -f values-dev.yaml
helm install myapp-prod charts/myapp -f values-prod.yaml
```

### Example 5: Custom Chart with Hooks

```yaml
# templates/migrations.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-migrate
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["./migrate.sh"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "mychart.fullname" . }}
                  key: database-url
      restartPolicy: Never
  backoffLimit: 3
```

### Example 6: Helm with ArgoCD

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.example.com
    chart: mychart
    targetRevision: 0.1.0
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

---

## Further Reading

### Official Documentation
- [Helm Documentation](https://helm.sh/docs/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Plugins](https://helm.sh/docs/topics/plugins/)

### Tools
- [ChartMuseum](https://chartmuseum.com/) — Chart repository server
- [ct (chart-testing)](https://github.com/helm/chart-testing) — Chart testing tool
- [Helmfile](https://github.com/helmfile/helmfile) — Declarative spec for deploying Helm charts
- [ChartPress](https://github.com/chartmuseum/chartpress) — Helm chart packaging tool

### Community
- [Helm Slack](https://helm.sh/slack)
- [Helm GitHub](https://github.com/helm/helm)
- [Artifact Hub](https://artifacthub.io/)
- [Helm Hub](https://hub.helm.sh/)

### Books and Tutorials
- "Helm: Up and Running" by Matt Butcher, Matt Farina, and Josh Dolitsky
- "Kubernetes Packaging with Helm" by Scott Rigby
- [Helm Quickstart Guide](https://helm.sh/docs/intro/quickstart/)
- [Helm Workshop](https://github.com/helm/helm-workshop)
