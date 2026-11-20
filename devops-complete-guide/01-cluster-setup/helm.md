# Helm — Complete Guide

---

## Table of Contents

1. [What Is Helm?](#1-what-is-helm)
2. [Concepts](#2-concepts)
3. [Installation](#3-installation)
4. [Helm Repository Management](#4-helm-repository-management)
5. [Installing Charts](#5-installing-charts)
6. [Creating Charts](#6-creating-charts)
7. [Template Engine](#7-template-engine)
8. [Values](#8-values)
9. [Chart Dependencies](#9-chart-dependencies)
10. [Hooks](#10-hooks)
11. [Testing](#11-testing)
12. [Packaging & Publishing](#12-packaging--publishing)
13. [Security](#13-security)
14. [Advanced](#14-advanced)
15. [Command Reference](#15-command-reference)
16. [Template Functions Reference](#16-template-functions-reference)
17. [Troubleshooting](#17-troubleshooting)
18. [Tips & Best Practices](#18-tips--best-practices)
19. [Real-World Example](#19-real-world-example)
20. [Further Reading](#20-further-reading)

---

## 1. What Is Helm?

### The Analogy

Helm is to Kubernetes what `apt` is to Debian, `yum` is to RHEL, or `brew` is to macOS. It is a **package manager** for Kubernetes. Instead of installing software on your laptop, you install applications (called "charts") into your Kubernetes cluster.

Think about deploying a complex application like WordPress on Kubernetes. You would need to write YAML manifests for:

- A **Deployment** for the PHP application
- A **Deployment** for the MySQL database
- A **Service** to expose the PHP app
- A **Service** to expose MySQL internally
- A **Secret** for database credentials
- A **ConfigMap** for WordPress configuration
- A **PersistentVolumeClaim** for MySQL data storage
- A **PersistentVolumeClaim** for WordPress uploads
- A **Ingress** for external access
- Maybe a **HorizontalPodAutoscaler**
- Maybe a **NetworkPolicy**

That is easily 10-20 YAML files, each with multiple fields that must be correct. If you change one value (say, the MySQL root password), you have to edit the Secret, then the Deployment, then ensure they roll out in the right order. Multiply this across every environment (dev, staging, production), and you have a maintenance nightmare.

Helm solves this by packaging all those manifests into a single reusable unit called a **chart**. One command installs everything. One value file customizes it for production. Another value file customizes it for staging.

### Why Helm Exists

Before Helm, Kubernetes operators faced several problems:

1. **Repetition**: Writing the same manifests for every deployment, every environment.
2. **No templating**: Pure YAML has no variables, no conditionals, no loops.
3. **No versioning**: No way to track which version of your app config is deployed.
4. **No rollbacks**: If an upgrade broke something, you had to manually revert files.
5. **No sharing**: There was no standard way to share Kubernetes configurations between teams.

Helm addresses all of these. It provides:

- **Templating**: Dynamic YAML generation with Go templates.
- **Values**: Separate configuration from manifests.
- **Packaging**: Bundle templates and defaults into a versioned archive.
- **Repositories**: Store and share charts publicly or privately.
- **Release management**: Install, upgrade, rollback, and delete in one command.
- **History**: Every change is tracked in a release history.

### Helm Version History

- **Helm 2** (legacy): Tiller-based architecture, required a server component in the cluster. Deprecated.
- **Helm 3** (current): Client-only architecture. Tiller removed. Uses Kubernetes RBAC directly. All modern guides target Helm 3.

This guide covers **Helm 3** exclusively.

### Helm's Role in the Ecosystem

Helm sits in the Kubernetes ecosystem alongside:

- **Kustomize**: An alternative to Helm for configuration management (overlay-based, not templating-based).
- **ArgoCD / Flux**: GitOps tools that can deploy Helm charts via Git.
- **Operators**: Custom controllers that manage complex apps. Helm charts often deploy operators.
- **OCI registries**: Modern Helm charts can be stored as OCI artifacts in container registries (Harbor, Docker Hub, ghcr.io).

---

## 2. Concepts

### Charts

A **chart** is a package of pre-configured Kubernetes resources. It is the equivalent of a `.deb` or `.rpm` package. A chart contains:

- `Chart.yaml`: Metadata (name, version, description, maintainers).
- `values.yaml`: Default configuration values.
- `templates/`: Directory of Go template files that generate Kubernetes manifests.
- `charts/`: Directory containing dependency charts (subcharts).
- `crds/`: Custom Resource Definitions that the chart needs.
- `README.md`: Documentation.
- `LICENSE`: License file.
- `tests/`: Test resources for `helm test`.

Charts are distributed as compressed tarballs (`.tgz` files) or stored as OCI artifacts in container registries.

### Releases

A **release** is a specific deployment of a chart with a specific name and set of values. When you run:

```bash
helm install my-release bitnami/nginx -f values.yaml
```

You create a release named `my-release`. That release tracks:

- Which chart was installed and at what version.
- What values were used.
- The state of all Kubernetes resources it created.
- The full history of changes (upgrades, rollbacks).

You can install the same chart multiple times with different release names:

```bash
helm install staging-nginx bitnami/nginx -f staging-values.yaml
helm install production-nginx bitnami/nginx -f production-values.yaml
```

Each is a separate release with independent lifecycle.

### Repositories

A **repository** is a collection of charts that can be shared and accessed by URL. The official Helm repository is at `https://charts.helm.sh/stable`. Major vendors maintain their own:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
```

Charts within a repository are indexed by a generated `index.yaml` file.

### Values

**Values** are the configuration inputs to a chart. Every chart has a `values.yaml` that defines defaults. Users override these defaults:

```bash
# Using a file
helm install my-release my-chart -f custom-values.yaml

# Using --set
helm install my-release my-chart --set replicaCount=3 --set service.type=LoadBalancer

# Using both (file first, --set overrides)
helm install my-release my-chart -f custom-values.yaml --set replicaCount=5
```

Values are deeply merged. A custom values file only needs to contain the keys you want to change.

### Templates

**Templates** are Go template files that generate Kubernetes YAML. They live in the `templates/` directory and use values to produce the final manifests. Templates enable:

- Dynamic resource naming
- Conditional resource creation
- Loops over lists
- Helper functions
- Environment-specific configuration

### Hooks

**Hooks** are special resources that execute at specific points in the release lifecycle (before install, after upgrade, etc.). Common uses:

- Database migrations before an upgrade
- Schema validation after install
- Cleanup after delete
- Notification to an external system

### Revisions

Every change to a release creates a new **revision**. Revisions are numbered sequentially. You can inspect any revision and roll back to it:

```bash
helm history my-release
helm rollback my-release 3    # Roll back to revision 3
```

---

## 3. Installation

### Method 1: Binary Download (Recommended)

Download the latest Helm binary from the official releases page:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

This script detects your OS and architecture, downloads the correct binary, and installs it to `/usr/local/bin/helm`.

### Method 2: Manual Download

For specific versions or air-gapped environments:

```bash
# Linux amd64
wget https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz
tar -zxvf helm-v3.16.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm
```

### Method 3: macOS

```bash
brew install helm
```

### Method 4: Windows

```powershell
choco install kubernetes-helm
```

Or download from [GitHub releases](https://github.com/helm/helm/releases).

### Method 5: Snap

```bash
sudo snap install helm --classic
```

### Method 6: Package Manager (Debian/Ubuntu)

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### Verification

```bash
helm version
# version.BuildInfo{Version:"v3.16.3", GitCommit:"...", GitCommitState:"clean", GoVersion:"go1.22.8"}
```

```bash
helm help
```

### Shell Completion

```bash
# Bash
helm completion bash > /etc/bash_completion.d/helm
source <(helm completion bash)

# Zsh
helm completion zsh > "${fpath[1]}/_helm"

# Fish
helm completion fish > ~/.config/fish/completions/helm.fish
```

---

## 4. Helm Repository Management

### Adding Repositories

```bash
# Official stable charts
helm repo add stable https://charts.helm.sh/stable

# Bitnami (most popular)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Prometheus monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts

# Ingress-NGINX
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Custom internal repository
helm repo add my-company https://charts.my-company.internal
```

### Listing Repositories

```bash
helm repo list
# NAME                 URL
# stable               https://charts.helm.sh/stable
# bitnami              https://charts.bitnami.com/bitnami
# prometheus-community  https://prometheus-community.github.io/helm-charts
```

### Updating Repositories

Always update before searching or installing:

```bash
helm repo update
# Hang tight while we grab the latest from your chart repositories...
# ...Successfully got an update from the "bitnami" chart repository
# ...Successfully got an update from the "stable" chart repository
# Update Complete. ✨Happy Helming!✨
```

### Searching for Charts

```bash
# Search by keyword
helm search repo nginx
# NAME                            CHART VERSION  APP VERSION  DESCRIPTION
# bitnami/nginx                   18.3.14        1.27.2       NGINX Open Source is a web server that can be a...
# stable/nginx-ingress            1.41.3         0.35.0       DEPRECATED: This chart is superseded, see https...

# Search for a specific version
helm search repo prometheus --versions
# NAME                            CHART VERSION  APP VERSION  DESCRIPTION
# prometheus-community/prometheus 25.27.0        2.53.0       Prometheus is a monitoring system and time serie...
# prometheus-community/prometheus 25.26.0        2.53.0       Prometheus is a monitoring system and time serie...

# Search across all configured repos
helm search hub prometheus
```

### Removing Repositories

```bash
helm repo remove stable
# "stable" has been removed from your repositories

helm repo remove stable bitnami
# Removing multiple repos at once
```

### Inspecting a Chart in a Repository

```bash
# Show chart info without installing
helm show chart bitnami/nginx
helm show values bitnami/nginx        # Show default values
helm show readme bitnami/nginx        # Show README
helm show all bitnami/nginx           # Show everything
```

---

## 5. Installing Charts

### Basic Installation

```bash
# Install with release name "my-nginx"
helm install my-nginx bitnami/nginx

# Output:
# NAME: my-nginx
# LAST DEPLOYED: Mon Jan 13 10:30:00 2025
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
```

### Installation with Custom Values

```bash
# Using a values file
helm install my-nginx bitnami/nginx -f values-production.yaml

# Using --set flags
helm install my-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=LoadBalancer \
  --set service.port=8080

# Combining both
helm install my-nginx bitnami/nginx \
  -f values.yaml \
  --set replicaCount=5
```

### Installation in a Specific Namespace

```bash
# Install in existing namespace
helm install my-nginx bitnami/nginx --namespace production

# Create namespace and install
helm install my-nginx bitnami/nginx --namespace production --create-namespace
```

### Installing a Specific Version

```bash
# Install a specific chart version
helm install my-nginx bitnami/nginx --version 18.3.14

# Install a specific app version
helm install my-nginx bitnami/nginx --app-version 1.27.2
```

### Installing from a Local Chart

```bash
# From a directory
helm install my-release ./my-chart

# From a packaged chart (.tgz)
helm install my-release ./my-chart-0.1.0.tgz

# From a URL
helm install my-release https://charts.example.com/my-chart-0.1.0.tgz
```

### Dry Run and Debug

```bash
# Simulate an install (no resources created)
helm install my-nginx bitnami/nginx --dry-run

# Show rendered templates
helm install my-nginx bitnami/nginx --dry-run --debug

# Output to stdout without installing
helm install my-nginx bitnami/nginx --dry-run --debug -o yaml
```

### Installation with Wait and Timeout

```bash
# Wait for all resources to be ready
helm install my-nginx bitnami/nginx --wait

# Wait with custom timeout
helm install my-nginx bitnami/nginx --wait --timeout 5m

# Atomic install: rollback on failure
helm install my-nginx bitnami/nginx --atomic --timeout 5m
```

### Installing with Create/Update Behavior

```bash
# Install only if not already installed
helm install my-nginx bitnami/nginx --install

# Upgrade if release exists, install if not
helm upgrade --install my-nginx bitnami/nginx -f values.yaml
```

### Releasing to a Specific Kube Context

```bash
# Install on a specific cluster
helm install my-nginx bitnami/nginx --kube-context staging-cluster

# Install with specific kubeconfig
helm install my-nginx bitnami/nginx --kubeconfig ~/.kube/staging.conf
```

### Upgrading Releases

```bash
# Upgrade to a new chart version
helm upgrade my-nginx bitnami/nginx --version 18.3.15

# Upgrade with new values
helm upgrade my-nginx bitnami/nginx -f values-production.yaml

# Upgrade with --set
helm upgrade my-nginx bitnami/nginx --set replicaCount=5

# Wait for upgrade to complete
helm upgrade my-nginx bitnami/nginx --wait --timeout 5m

# Atomic upgrade (auto-rollback on failure)
helm upgrade my-nginx bitnami/nginx --atomic

# Force upgrade (delete and recreate resources)
helm upgrade my-nginx bitnami/nginx --force

# Reset values to chart defaults on upgrade
helm upgrade my-nginx bitnami/nginx --reset-values

# Reuse values from previous release
helm upgrade my-nginx bitnami/nginx --reuse-values
```

### Rollbacks

```bash
# View release history
helm history my-nginx
# REVISION  UPDATED                   STATUS    CHART           APP VERSION  DESCRIPTION
# 1         Mon Jan 13 10:30:00 2025  deployed  nginx-18.3.14   1.27.2       Install complete
# 2         Mon Jan 13 11:00:00 2025  deployed  nginx-18.3.15   1.27.3       Upgrade complete
# 3         Mon Jan 13 11:30:00 2025  superseded nginx-18.3.15  1.27.3       Upgrade to 5 replicas

# Rollback to specific revision
helm rollback my-nginx 1

# Rollback to previous revision
helm rollback my-nginx --cleanup-on-fail

# Rollback with custom values
helm rollback my-nginx 1 -f values-rollback.yaml

# Rollback and wait
helm rollback my-nginx 1 --wait --timeout 5m
```

### Uninstalling Releases

```bash
# Uninstall a release
helm uninstall my-nginx

# Uninstall and wait for resources to be deleted
helm uninstall my-nginx --wait

# Uninstall with timeout
helm uninstall my-nginx --timeout 5m

# Uninstall but keep the release record
helm uninstall my-nginx --keep-history

# Uninstall from a specific namespace
helm uninstall my-nginx --namespace production
```

### Viewing Release Status

```bash
# Status of a release
helm status my-nginx
# NAME: my-nginx
# LAST DEPLOYED: Mon Jan 13 10:30:00 2025
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1

# Status as JSON
helm status my-nginx -o json

# List all releases
helm list

# List all releases across all namespaces
helm list --all-namespaces

# List only deployed releases
helm list --deployed

# List failed releases
helm list --failed

# Filter by name
helm list --filter my-nginx
```

---

## 6. Creating Charts

### Scaffolding a New Chart

```bash
helm create my-chart
```

This creates the following structure:

```
my-chart/
├── Chart.yaml          # Chart metadata
├── Chart.lock          # Lock file for dependencies
├── values.yaml         # Default values
├── charts/             # Dependency charts (subcharts)
├── templates/          # Template files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── serviceaccount.yaml
│   ├── _helpers.tpl    # Template helpers
│   ├── NOTES.txt       # Post-install notes
│   └── tests/
│       └── test-connection.yaml
├── .helmignore         # Files to exclude from packaging
└── README.md           # Chart documentation
```

### Chart.yaml — Complete Reference

```yaml
# Required fields
apiVersion: v2               # Chart API version (v2 for Helm 3)
name: my-chart                # Chart name
version: 0.1.0                # Semantic version (required)

# Optional fields
description: A description of what this chart does
type: application             # "application" (default) or "library"
keywords:
  - web
  - nginx
  - microservice
home: https://github.com/myorg/my-chart
sources:
  - https://github.com/myorg/my-chart
maintainers:
  - name: Your Name
    email: you@example.com
    url: https://example.com
icon: https://example.com/icon.png
appVersion: "1.0.0"           # Version of the application
deprecated: false             # Mark chart as deprecated
kubeVersion: ">=1.25.0-0"    # Kubernetes version constraint
dependencies:                 # Subchart dependencies
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    tags:
      - cache
```

### values.yaml — Complete Reference

```yaml
# Replica count
replicaCount: 1

# Image configuration
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""   # Defaults to appVersion

# Image pull secrets
imagePullSecrets: []

# Override the release name
nameOverride: ""
fullnameOverride: ""

# Service account
serviceAccount:
  create: true
  automount: true
  annotations: {}
  name: ""

# Pod annotations and labels
podAnnotations: {}
podLabels: {}

# Pod security context
podSecurityContext: {}
  # fsGroup: 1000

# Container security context
securityContext: {}
  # capabilities:
  #   drop:
  #     - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 80
  protocol: TCP

# Ingress configuration
ingress:
  enabled: false
  className: ""
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls: []

# Resource limits and requests
resources: {}
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

# Autoscaling
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  # targetMemoryUtilizationPercentage: 80

# Node selector
nodeSelector: {}

# Tolerations
tolerations: []

# Affinity
affinity: {}

# Probes
livenessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10

# Environment variables
env: []
  # - name: DATABASE_URL
  #   valueFrom:
  #     secretKeyRef:
  #       name: db-secret
  #       key: url

# ConfigMaps
configMap:
  enabled: false
  data: {}
    # app.conf: |
    #   [server]
    #   port=8080

# Persistent volumes
persistence:
  enabled: false
  # storageClass: ""
  accessModes:
    - ReadWriteOnce
  size: 1Gi

# Pod disruption budget
podDisruptionBudget:
  enabled: false
  minAvailable: 1
```

### templates/_helpers.tpl

This file defines reusable template snippets:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "my-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "my-chart.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "my-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-chart.labels" -}}
helm.sh/chart: {{ include "my-chart.chart" . }}
{{ include "my-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "my-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "my-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

### templates/NOTES.txt

Display after installation:

```
Thank you for installing {{ .Chart.Name }}.

Your release is named {{ .Release.Name }}.

To get the application URL:
{{- if .Values.ingress.enabled }}
{{- range $host := .Values.ingress.hosts }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}
{{- end }}
{{- else if contains "NodePort" .Values.service.type }}
  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "my-chart.fullname" . }})
  export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
{{- else if contains "LoadBalancer" .Values.service.type }}
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
  kubectl get --namespace {{ .Release.Namespace }} svc {{ include "my-chart.fullname" . }} -w
{{- end }}
```

### .helmignore

```
# Patterns to ignore when building packages.
.DS_Store
.git/
.gitignore
.bzr/
.bzrignore
.hg/
.hgignore
.svn/
*.swp
*.bak
*.tmp
*.orig
*~
.project
.idea/
*.tmproj
.vscode/
README.md
```

---

## 7. Template Engine

Helm uses Go's `text/template` engine with additional functions. Templates produce YAML manifests.

### Basic Syntax

```yaml
# Variable interpolation
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  # Access values
  {{ .Values.config.key }}

  # Access nested values
  {{ .Values.database.host }}
```

### Conditionals

```yaml
# Simple if/else
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-chart.fullname" . }}
{{- end }}

# If/else if/else
{{- if eq .Values.service.type "LoadBalancer" }}
  type: LoadBalancer
{{- else if eq .Values.service.type "NodePort" }}
  type: NodePort
{{- else }}
  type: ClusterIP
{{- end }}

# Boolean checks (empty string is falsy)
{{- if .Values.persistence.enabled }}
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: {{ include "my-chart.fullname" . }}
{{- end }}

# Negation
{{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
{{- end }}

# Logical operators
{{- if and .Values.ingress.enabled .Values.ingress.tls }}
  tls:
    - hosts:
        - {{ .Values.ingress.host | quote }}
{{- end }}

{{- if or .Values.config.debug .Values.config.verbose }}
  logLevel: debug
{{- end }}
```

### Ranges (Loops)

```yaml
# Iterate over a list
{{- range .Values.ingress.hosts }}
  - host: {{ .host | quote }}
    http:
      paths:
      {{- range .paths }}
        - path: {{ .path }}
          pathType: {{ .pathType }}
      {{- end }}
{{- end }}

# Iterate over a map
{{- range $key, $value := .Values.env }}
  - name: {{ $key }}
    value: {{ $value | quote }}
{{- end }}

# Range with index
{{- range $index, $element := .Values.servers }}
  - name: server-{{ $index }}
    image: {{ $element.image }}
    port: {{ $element.port }}
{{- end }}

# Loop with an empty check
{{- with .Values.config }}
data:
  {{- toYaml . | nindent 2 }}
{{- end }}
```

### Variables

```yaml
{{/* Define a variable */}}
{{- $releaseName := .Release.Name -}}
{{- $fullName := printf "%s-%s" $releaseName "config" -}}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $fullName }}

# Using "with" to change scope
{{- with .Values.resources }}
resources:
  limits:
    cpu: {{ .limits.cpu }}
    memory: {{ .limits.memory }}
  requests:
    cpu: {{ .requests.cpu }}
    memory: {{ .requests.memory }}
{{- end }}
```

### Pipelines

```yaml
# Pipe output to a function
{{ .Values.name | upper }}
{{ .Values.name | lower }}
{{ .Values.name | title }}
{{ .Values.name | quote }}
{{ .Values.name | indent 4 }}
{{ .Values.name | nindent 2 }}
{{ .Values.name | default "fallback" }}
{{ .Values.name | trunc 63 }}
{{ .Values.name | trim }}
{{ .Values.name | replace "-" "_" }}
{{ .Values.name | regexReplaceAll "[^a-z]" "" }}

# Chaining pipelines
{{ .Values.name | default "nginx" | upper | trunc 20 }}

# toYaml and fromYaml
{{ toYaml .Values.resources | nindent 2 }}

# Yaml overwriting
{{ $defaults := dict "replicas" 1 "image" "nginx" }}
{{ $custom := .Values.custom }}
{{ mergeOverwrite $defaults $custom | toYaml | nindent 2 }}
```

### Helper Functions (define)

```yaml
# In _helpers.tpl
{{- define "mychart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

# In a template file
metadata:
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

### Quote and Quote Functions

```yaml
# Simple quoting
value: {{ .Values.name | quote }}

# Double quoting (for YAML safety)
value: "{{ .Values.name }}"

# quote-list: quotes each element
{{ .Values.hosts | toJson }}
```

### JSON/YAML Encoding

```yaml
# toYaml: convert to YAML
{{ toYaml .Values.config | nindent 2 }}

# fromYaml: parse YAML string
{{ fromYaml .Values.configString }}

# toJson: convert to JSON
{{ .Values.config | toJson }}

# fromJson: parse JSON string
{{ fromJson .Values.configJson }}

# toJsonPretty: indented JSON
{{ .Values.config | toJsonPretty }}
```

### Built-in Objects

```yaml
{{ .Release.Name }}        # Release name
{{ .Release.Namespace }}   # Namespace
{{ .Release.Service }}     # Always "Helm"
{{ .Release.Revision }}    # Revision number
{{ .Chart.Name }}          # Chart name from Chart.yaml
{{ .Chart.Version }}       # Chart version
{{ .Chart.AppVersion }}    # Application version
{{ .Capabilities.KubeVersion }}  # Kubernetes version
{{ .Values }}              # Values object
{{ .Template.Name }}       # Current template name
{{ .Template.BasePath }}   # Base path of templates
```

---

## 8. Values

### Value Precedence

Helm values are merged in a specific order (last wins):

1. **Chart's `values.yaml`**: Base defaults.
2. **Parent chart's `values.yaml`**: If chart is a dependency.
3. **`-f` files**: Custom values files, applied in order (later files override earlier).
4. **`--set` flags**: Direct overrides on the command line.
5. **`--set-string` flags**: Forces string type.
6. **`--set-file` flags**: Sets value from file contents.
7. **`--set-json` flags**: Sets value from JSON string.

```bash
# Example: three -f files, each overriding the previous
helm install my-release ./my-chart \
  -f values-default.yaml \
  -f values-production.yaml \
  -f values-us-east.yaml

# --set overrides everything
helm install my-release ./my-chart \
  -f values-production.yaml \
  --set replicaCount=10
```

### Using `-f` Files

```bash
# Install with a custom values file
helm install my-release ./my-chart -f my-values.yaml

# Multiple values files
helm install my-release ./my-chart -f base.yaml -f overlay.yaml
```

### Using `--set`

```bash
# Simple key=value
helm install my-release ./my-chart --set replicaCount=3

# Nested keys
helm install my-release ./my-chart --set service.type=LoadBalancer

# Multiple values
helm install my-release ./my-chart \
  --set replicaCount=3 \
  --set service.type=LoadBalancer \
  --set service.port=8080

# Array indices
helm install my-release ./my-chart \
  --set 'ingress.hosts[0].host=example.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix'

# Maps
helm install my-release ./my-chart \
  --set 'env.DATABASE_URL=postgres://db:5432/app' \
  --set 'env.REDIS_URL=redis://cache:6379'

# Escaping dots in keys
helm install my-release ./my-chart \
  --set 'config."my\.key"=value'
```

### `--set-string` vs `--set`

```bash
# --set converts types (int, bool, float)
helm install my-release ./my-chart --set port=8080     # port is integer

# --set-string always uses string type
helm install my-release ./my-chart --set-string port=8080  # port is string "8080"
```

### `--set-file`

Sets a value to the contents of a file:

```bash
# Read file content into a value
helm install my-release ./my-chart \
  --set-file config.app\.conf=./config/app.conf \
  --set-file config.nginx\.conf=./config/nginx.conf
```

In templates:

```yaml
data:
  app.conf: {{ .Values.config."app.conf" | quote }}
```

### `--set-json`

```bash
helm install my-release ./my-chart \
  --set-json 'servers=[{"name":"s1","port":8080},{"name":"s2","port":8081}]'
```

### Values Files for Different Environments

```
my-chart/
├── values.yaml             # Base defaults
├── values-dev.yaml         # Dev overrides
├── values-staging.yaml     # Staging overrides
├── values-production.yaml  # Production overrides
└── values-secrets.yaml     # Secret overrides (gitignored)
```

```bash
# Dev
helm install dev-app ./my-chart -f values-dev.yaml

# Staging
helm install staging-app ./my-chart -f values-staging.yaml

# Production
helm install prod-app ./my-chart -f values-production.yaml -f values-secrets.yaml
```

### Using Helmfile for Environment Management

Helmfile allows declaring multiple releases in a single file:

```yaml
# helmfile.yaml
repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  - name: nginx
    chart: bitnami/nginx
    values:
      - values/nginx.yaml
      - values/nginx-{{ .Environment.Name }}.yaml
    set:
      - name: replicaCount
        value: 3
```

```bash
# Deploy to dev
helmfile -e dev apply

# Deploy to production
helmfile -e production apply
```

---

## 9. Chart Dependencies

### Defining Dependencies

#### Modern Approach (Chart.yaml)

```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 0.1.0

dependencies:
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled

  - name: postgresql
    version: "13.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled

  - name: grafana
    version: "7.x.x"
    repository: "https://grafana.github.io/helm-charts"
    alias: monitoring-grafana
    tags:
      - monitoring
```

#### Dependency Fields

| Field | Description |
|-------|-------------|
| `name` | Chart name in the repository |
| `version` | Semver range or exact version |
| `repository` | Repository URL |
| `condition` | Values path that enables/disables the dependency |
| `tags` | List of tags that enable the dependency |
| `alias` | Local name for the subchart |
| `import-values` | Import values from the subchart |
| `exported-values` | Export values from this chart |
| `enabled` | Enable/disable (default: true) |

### Resolving Dependencies

```bash
# Download dependencies into charts/ directory
helm dependency update

# Output:
# Hang tight while we grab the latest from your chart repositories...
# ...Successfully got an update from the "bitnami" chart repository
# Update Complete. ✨Happy Helming!✨
# Saving 2 charts
# Downloading redis from repo https://charts.bitnami.com/bitnami
# Downloading postgresql from repo https://charts.bitnami.com/bitnami
# Deleting outdated charts
```

This creates a `Chart.lock` file and downloads charts into `charts/`.

### Chart.lock

```
# Chart.lock
dependencies:
  - name: redis
    repository: https://charts.bitnami.com/bitnami
    version: 18.6.1
  - name: postgresql
    repository: https://charts.bitnami.com/bitnami
    version: 13.2.24
digest: sha256:abc123...
generated: "2024-01-13T10:30:00Z"
```

### Dependency Conditions

```yaml
# values.yaml
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false

postgresql:
  enabled: false
  auth:
    postgresPassword: changeme
```

```bash
# Install with Redis only
helm install my-app ./my-chart \
  --set redis.enabled=true \
  --set postgresql.enabled=false

# Install with PostgreSQL only
helm install my-app ./my-chart \
  --set redis.enabled=false \
  --set postgresql.enabled=true
```

### Accessing Subchart Values

```yaml
# templates/configmap.yaml
data:
  # Access subchart values via alias
  {{- if .Values.redis.enabled }}
  redis-host: {{ .Values.redis.host | default "redis-master" }}
  redis-port: {{ .Values.redis.port | default "6379" | toString }}
  {{- end }}

  # If alias is set, use the alias
  {{- if .Values.monitoring-grafana.enabled }}
  grafana-url: {{ .Values.monitoring-grafana.grafana.service.type }}
  {{- end }}
```

### Importing Values from Subcharts

```yaml
# Chart.yaml
dependencies:
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    import-values:
      - redis     # Import redis's values as top-level keys
```

### Legacy Approach (requirements.yaml)

```yaml
# requirements.yaml (deprecated, use Chart.yaml dependencies)
dependencies:
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

### OCI Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: my-internal-chart
    version: "1.2.3"
    repository: "oci://registry.example.com/charts"
```

---

## 10. Hooks

### Hook Types

| Hook | When it runs |
|------|-------------|
| `pre-install` | Before install, after templates are rendered |
| `post-install` | After all resources are created |
| `pre-upgrade` | Before upgrade, after templates are rendered |
| `post-upgrade` | After all resources are updated |
| `pre-delete` | Before delete |
| `post-delete` | After all resources are deleted |
| `pre-rollback` | Before rollback |
| `post-rollback` | After rollback |
| `test` | During `helm test` |

### Creating a Hook

```yaml
# templates/migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-chart.fullname" . }}-db-migration
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["./migrate.sh"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "my-chart.fullname" . }}-db
                  key: url
```

### Hook Annotations

| Annotation | Description |
|-----------|-------------|
| `helm.sh/hook` | Hook type(s), comma-separated |
| `helm.sh/hook-weight` | Integer weight (lower runs first, negative runs before positive) |
| `helm.sh/hook-delete-policy` | When to delete hook resources |

### Hook Delete Policies

| Policy | When resource is deleted |
|--------|------------------------|
| `before-hook-creation` | Before a new hook is created (deletes previous run) |
| `hook-succeeded` | After hook succeeds |
| `hook-failed` | After hook fails |

### Hook Weights

```yaml
# Step 1: Run first (weight -10)
metadata:
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-10"

# Step 2: Run second (weight -5)
metadata:
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"

# Step 3: Run last (weight 0)
metadata:
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "0"
```

### Multiple Hook Types

```yaml
annotations:
  # Runs on install, upgrade, and delete
  "helm.sh/hook": pre-install,pre-upgrade,pre-delete
```

### Hook with Resource Policy

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-chart.fullname" . }}-cleanup
  annotations:
    "helm.sh/hook": post-delete
    "helm.sh/hook-delete-policy": hook-succeeded,before-hook-creation
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: cleanup
          image: bitnami/kubectl:latest
          command:
            - /bin/sh
            - -c
            - kubectl delete pvc --all -n {{ .Release.Namespace }}
```

---

## 11. Testing

### Creating Tests

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-chart.fullname" . }}-test-connection"
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-chart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

### Running Tests

```bash
# Run all tests for a release
helm test my-release

# Run tests and wait for completion
helm test my-release --wait

# Run tests with timeout
helm test my-release --timeout 5m

# Run tests with logs
helm test my-release --logs

# Run specific test
helm test my-release --filter name=release-name-test-connection
```

### Advanced Test Example

```yaml
# templates/tests/test-api.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-chart.fullname" . }}-test-api"
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  containers:
    - name: curl
      image: curlimages/curl:latest
      command:
        - /bin/sh
        - -c
        - |
          echo "Testing API health..."
          curl -sf http://{{ include "my-chart.fullname" . }}:{{ .Values.service.port }}/health
          echo ""
          echo "Testing API metrics..."
          curl -sf http://{{ include "my-chart.fullname" . }}:{{ .Values.service.port }}/metrics | grep -q "up"
          echo "All tests passed!"
  restartPolicy: Never
```

### Test with Job (for database migration tests)

```yaml
# templates/tests/test-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "my-chart.fullname" . }}-test-migration"
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: test
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["./test-migration.sh"]
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "my-chart.fullname" . }}-db
                  key: url
```

---

## 12. Packaging & Publishing

### Packaging a Chart

```bash
# Package a chart directory into a .tgz archive
helm package my-chart
# Successfully packaged chart and saved it to: my-chart-0.1.0.tgz

# Package with destination
helm package my-chart -d ./dist/

# Package multiple charts
helm package chart-a chart-b -d ./dist/
```

### Linting Charts

```bash
# Lint a chart
helm lint my-chart
# [INFO] Chart.yaml: chart type is application
# [INFO] values.yaml: file does not exist
# 1 chart(s) linted, 0 chart(s) failed

# Lint with strict mode
helm lint my-chart --strict

# Lint multiple charts
helm lint chart-a chart-b
```

### Rendering Templates

```bash
# Render templates to stdout
helm template my-release my-chart

# Render with custom values
helm template my-release my-chart -f values.yaml

# Render and save to file
helm template my-release my-chart -f values.yaml > rendered.yaml

# Render specific templates
helm template my-release my-chart --show-only templates/deployment.yaml

# Render and validate against Kubernetes
helm template my-release my-chart | kubectl apply --dry-run=client -f -
```

### Publishing to a Helm Repository

#### Static Repository (GitHub Pages)

```bash
# 1. Package the chart
helm package my-chart -d docs/

# 2. Create/update index
helm repo index docs/ --url https://myorg.github.io/charts

# 3. Push to GitHub Pages
git add docs/
git commit -m "Add chart"
git push

# 4. Add the repo
helm repo add my-charts https://myorg.github.io/charts
```

#### ChartMuseum

```bash
# Start ChartMuseum
docker run -d -p 8080:8080 \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  -v /data/charts:/charts \
  chartmuseum/chartmuseum:latest

# Add as Helm repo
helm repo add chartmuseum http://localhost:8080

# Push chart
curl --data-binary "@my-chart-0.1.0.tgz" http://localhost:8080/api/charts
```

#### Harbor OCI Registry

```bash
# Login to OCI registry
helm registry login registry.example.com -u admin -p password

# Push chart as OCI artifact
helm push my-chart-0.1.0.tgz oci://registry.example.com/charts

# Install from OCI registry
helm install my-release oci://registry.example.com/charts/my-chart --version 0.1.0
```

#### OCI with Specific Namespace

```bash
# Push to a specific project/namespace
helm push my-chart-0.1.0.tgz oci://registry.example.com/project-name

# Install from specific project
helm install my-release oci://registry.example.com/project-name/my-chart --version 0.1.0
```

### Exporting Templates for GitOps

```bash
# Render and save (for ArgoCD/Flux)
helm template my-release my-chart -f production-values.yaml > k8s/manifests.yaml

# With Kustomize (for Flux)
helm template my-release my-chart -f values.yaml > base/manifests.yaml
```

---

## 13. Security

### RBAC for Helm

Helm uses the user's kubeconfig credentials. Ensure the user has proper RBAC:

```yaml
# helm-admin-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: helm-admin
rules:
  - apiGroups: ["", "apps", "batch", "extensions", "networking.k8s.io"]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings"]
    verbs: ["*"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: helm-admin
subjects:
  - kind: User
    name: helm-user
    apiGroup: rbac.authorization.k8s.io
```

### Chart Provenance

Helm supports GPG signing for chart packages:

```bash
# Import a GPG key
gpg --import my-key.gpg

# Package with provenance
helm package my-chart --sign --key my-key-id

# This creates:
# my-chart-0.1.0.tgz
# my-chart-0.1.0.tgz.prov

# Verify a chart
helm verify my-chart-0.1.0.tgz
```

### Provenance File Contents

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

apiVersion: v2
name: my-chart
version: 0.1.0
...
files:
- my-chart/templates/deployment.yaml: sha256:abc123...
- my-chart/values.yaml: sha256:def456...
digest: sha256:789abc...
-----BEGIN PGP SIGNATURE-----

iQEzBAEBCAAdFiEE...
-----END PGP SIGNATURE-----
```

### Secret Management

```yaml
# templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-chart.fullname" . }}
type: Opaque
data:
  # Base64 encoded (use a vault solution for production)
  password: {{ .Values.secrets.password | b64enc | quote }}
```

**Better approach**: Use external secret managers:

- **Sealed Secrets**: Encrypt secrets for Git storage
- **External Secrets Operator**: Fetch from AWS/GCP/Azure Vault
- **SOPS**: Encrypt values files

### Security Scanning

```bash
# Scan chart templates for security issues
helm lint my-chart --strict

# Use kube-linter
kube-linter lint my-chart/templates/

# Use checkov for Helm
checkov -d my-chart/templates/

# Scan with Trivy
trivy config my-chart/templates/
```

### Pod Security Standards

```yaml
# values.yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

---

## 14. Advanced

### Helm Plugins

```bash
# List installed plugins
helm plugin list

# Install a plugin
helm plugin install https://github.com/chartmuseum/helm-push
# Adds "helm cm-push" command

helm plugin install https://github.com/jkroepke/helm-secrets
# Adds "helm secrets" command

helm plugin install https://github.com/databus23/helm-diff
# Adds "helm diff" command

helm plugin install https://github.com/quintush/helm-unittest
# Adds "helm unittest" command

# Remove a plugin
helm plugin remove secrets

# Update plugins
helm plugin update secrets
```

### helm-diff

Shows what would change before upgrading:

```bash
# Preview upgrade changes
helm diff upgrade my-release ./my-chart -f values.yaml

# Show only changed resources
helm diff upgrade my-release ./my-chart -f values.yaml --suppress-secrets
```

### helm-secrets

Manage secrets with SOPS:

```bash
# Install secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Encrypt a values file
helm secrets enc values-secrets.yaml

# Install with encrypted secrets
helm secrets upgrade --install my-release ./my-chart -f values.yaml -f secrets://values-secrets.yaml
```

### helmfile

Declarative Helm release management:

```yaml
# helmfile.yaml
environments:
  dev:
    values:
      - values/dev.yaml
  staging:
    values:
      - values/staging.yaml
  production:
    values:
      - values/production.yaml

repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  - name: nginx
    chart: bitnami/nginx
    values:
      - values/nginx.yaml
    set:
      - name: replicaCount
        value: 3

  - name: redis
    chart: bitnami/redis
    values:
      - values/redis.yaml

  - name: postgresql
    chart: bitnami/postgresql
    values:
      - values/postgresql.yaml
```

```bash
# Diff what will change
helmfile diff

# Apply all releases
helmfile apply

# Sync all releases
helmfile sync

# Destroy all releases
helmfile destroy
```

### Environment Overlays

```
my-chart/
├── values.yaml              # Base
├── values/
│   ├── dev.yaml             # Dev overlay
│   ├── staging.yaml         # Staging overlay
│   ├── production.yaml      # Production overlay
│   ├── production-secrets.yaml  # Secrets (gitignored)
│   └── region/
│       ├── us-east.yaml     # Region-specific
│       └── eu-west.yaml
```

### OCI Registry Integration

```bash
# Login
helm registry login ghcr.io -u myuser -p $GITHUB_TOKEN

# Push to GHCR
helm push my-chart-0.1.0.tgz oci://ghcr.io/myorg/charts

# Install from OCI
helm install my-release oci://ghcr.io/myorg/charts/my-chart --version 0.1.0

# Add OCI as repo (Helm 3.8+)
helm repo add my-charts oci://ghcr.io/myorg/charts
```

### Post-Rendering

Transform rendered templates before applying:

```bash
# Using kustomize as post-renderer
helm install my-release ./my-chart \
  --post-renderer kustomize \
  --post-renderer-args "build=."

# Custom post-renderer
helm install my-release ./my-chart \
  --post-renderer ./my-post-renderer.sh
```

### Helm as a Library

Library charts provide templates without deploying resources:

```yaml
# Chart.yaml
apiVersion: v2
name: my-library
type: library     # Key difference
version: 0.1.0
```

```yaml
# templates/_helpers.tpl
{{- define "myapp.ingress.annotations" -}}
{{- if .Values.ingress.tls }}
  cert-manager.io/cluster-issuer: {{ .Values.ingress.certIssuer | default "letsencrypt" }}
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
{{- end }}
nginx.ingress.kubernetes.io/proxy-body-size: "50m"
{{- end }}
```

---

## 15. Command Reference

### Global Flags

```
--add-dir-header           Add the file directory to the header of log messages
--alsologtostderr          Log to standard error as well as files
--debug                    Enable verbose output
--kube-apiserver           The address and the port of the Kubernetes API server
--kube-as-group            Group to impersonate for the operation
--kube-as-user             Username to impersonate for the operation
--kube-ca-file             Path to a CA certificate file
--kube-context             Name of the kubeconfig context to use
--kube-insecure-skip-tls-verify   If true, the server's certificate will not be checked
--kube-tls-server-name     Used to set the server name for TLS validation
--kubeconfig               Path to the kubeconfig file
--log-dir                  If non-empty, write log files in this directory
--log-file                 If non-empty, use this log file
--log-file-max-size        Defines the maximum size of log files
--logtostderr              Log to standard error instead of files
--namespace, -n            Namespace scope for this request
--registry-config          Path to the registry config file
--repository-cache         Path to the repository cache directory
--repository-config        Path to the repository config file
```

### helm install

```
helm install [NAME] [CHART] [flags]

Flags:
  --atomic                  Install fails and rolls back on timeout
  --ca-file                 Path to CA certificate for the chart repo
  --cert-file               Path to client certificate for the chart repo
  --create-namespace        Create the namespace if it does not exist
  --dependency-update       Update dependencies before installing
  --description             Add a description
  --devel                   Use development versions (equivalent to version >0.0.0-0)
  --disable-openapi-validation   Skip validation against OpenAPI schema
  --dry-run                 Simulate an install
  --enable-plugins          Enable plugins (experimental)
  --force                   Force resource replacements
  --generate-name           Generate the release name
  --key-file                Path to client key for the chart repo
  --keyring                 Path to the keyring for verifying chart signatures
  --kube-context            Kubeconfig context
  --kube-namespace          Kubernetes namespace
  --name-template           Override the release name template
  --no-hooks                Disable pre/post install hooks
  --password                Chart repository password
  --post-renderer           The path to an executable to be used for post rendering
  --post-renderer-args      Args for post-renderer
  --priority                Set release priority
  --render-subchart-notes   Render subchart notes
  --replace                 Reuse the given name, only if that name is a deleted release
  --repo                    Chart repository URL
  --reset-values            Reset values to chart defaults
  --reuse-values           Merge with existing values
  --set                     Set values on the command line
  --set-file                Set values from files
  --set-json                Set values from JSON
  --set-string              Set string values
  --show-only               Only show rendered templates
  --skip-crds               Skip CRD installation
  --sort                    Sort release resources
  --sub-notes               Render subchart notes
  --timeout                 Time to wait (e.g., 5m, 1h)
  --username                Chart repository username
  --validate                Validate against Kubernetes API
  --values, -f              Values files
  --verify                  Verify the chart before installing
  --version                 Chart version
  --wait                    Wait for all resources
```

### helm upgrade

```
helm upgrade [RELEASE] [CHART] [flags]

Flags:
  (Most install flags apply)
  --cleanup-on-fail         Allow upgrade to clean up on failure
  --history-max             Max number of release versions
  --install                 Install if release does not exist
  --keep-history            Keep upgrade records
  --reset-values            Reset values to chart defaults
  --reuse-values           Merge with existing values
  --skip-crds               Skip CRD installation during upgrade
```

### helm rollback

```
helm rollback [RELEASE] [REVISION] [flags]

Flags:
  --cleanup-on-fail         Allow rollback to clean up on failure
  --dry-run                 Simulate a rollback
  --force                   Force resource replacements
  --history-max             Max number of release versions
  --no-hooks                Disable pre/post rollback hooks
  --reuse-values           Merge with existing values
  --timeout                 Time to wait
  --wait                    Wait for all resources
```

### helm uninstall

```
helm uninstall [RELEASE] [flags]

Flags:
  --dry-run                 Simulate an uninstall
  --keep-history            Keep release records
  --no-hooks                Disable pre/post delete hooks
  --timeout                 Time to wait
  --wait                    Wait for all resources to be deleted
```

### helm list

```
helm list [flags]

Flags:
  -a, --all                 Show all releases
  --all-namespaces          Show across all namespaces
  -d, --date                Sort by date
  -f, --filter              Filter by name/regex
  -m, --max                 Maximum number of releases
  --offset                  Start from a specific release
  -o, --output              Output format (json, yaml, table, wide)
  -r, --reverse             Reverse sort order
  -l, --short               Output short (quiet) listing
  --deployed                List deployed releases
  --failed                  List failed releases
  --pending                  List pending releases
  --uninstalled             List uninstalled releases
  --superseded              List superseded releases
```

### helm search

```
helm search repo [keyword] [flags]

Flags:
  -l, --lax                 Fuzzy matching
  -r, --regexp              Use regex
  -v, --versions            Show all versions
  -o, --output              Output format

helm search hub [keyword] [flags]

Flags:
  -l, --lax                 Fuzzy matching
  -r, --regexp              Use regex
  -o, --output              Output format
```

### helm repo

```
helm repo add [NAME] [URL] [flags]
  --force-update            Replace existing repo
  --no-update               Don't update repository

helm repo index [DIR] [flags]
  --merge                   Merge with existing index
  --url                     URL of the chart repository

helm repo list [flags]
  -o, --output              Output format

helm repo remove [NAME]...

helm repo update [flags]
  --fail-on-error           Fail if any repo fails
  [REPO...]                 Specific repos to update
```

### helm show

```
helm show all [CHART] [flags]
helm show chart [CHART] [flags]
helm show crds [CHART] [flags]
helm show values [CHART] [flags]
helm show readme [CHART] [flags]

Flags:
  --ca-file                 CA file for HTTPS
  --cert-file               Client cert file
  --key-file                Client key file
  --password                Repo password
  --username                Repo username
  --repo                    Chart repo URL
  --version                 Chart version
```

### helm package

```
helm package [CHART] [flags]

Flags:
  -d, --destination          Destination directory
  --app-version              Override app version
  --dependency-update        Update dependencies
  --key                      Key for signing
  --keyring                  Keyring for verification
  --sign                     Sign the chart
  --version                  Override version
```

### helm push

```
helm push [CHART_PACKAGE] [remote] [flags]

Flags:
  --ca-file                 CA file
  --cert-file               Client cert file
  --insecure                Skip TLS verification
  --key-file                Client key file
  --non-interactive         Disable interactive prompts
  --password                Repo password
  --plain-http              Use plain HTTP
  --username                Repo username
```

### helm template

```
helm template [NAME] [CHART] [flags]

Flags:
  --api-versions            Kubernetes API versions
  --include-crds            Include CRDs
  --kube-version            Kubernetes version
  --name-template           Release name template
  --namespace, -n           Namespace
  --no-hooks                Disable hooks
  --notes                   Show notes
  --output, -o              Output format
  --release-name            Add release name
  --set                     Set values
  --show-only               Show specific templates
  --validate                Validate against API
  --values, -f              Values files
  --version                 Chart version
```

### helm lint

```
helm lint [CHART] [flags]

Flags:
  --strict                  Strict mode
  --with-subcharts          Also lint dependency charts
  --values, -f              Values files
```

### helm dependency

```
helm dependency build [CHART] [flags]
helm dependency update [CHART] [flags]
helm dependency list [CHART] [flags]
```

### helm create

```
helm create [NAME] [flags]
```

### helm test

```
helm test [RELEASE] [flags]

Flags:
  --filter                  Filter by test name
  --logs                    Dump logs on completion
  --timeout                 Time to wait
  --watch                   Watch until completion
  --reuse-values           Merge with existing values
```

### helm plugin

```
helm plugin install [URL] [flags]
helm plugin list
helm plugin remove [PLUGIN]
helm plugin update [PLUGIN]
```

### helm env

```bash
# Show Helm environment info
helm env
# HELM_HOME="/home/user/.config/helm"
# HELM_REGISTRY_USERNAME=""
# HELM_REGISTRY_PASSWORD=""
# HELM_REPOSITORY_CACHE="/home/user/.cache/helm/repository"
# HELM_REPOSITORY_CONFIG="/home/user/.config/helm/repositories.yaml"
# HELM_NAMESPACE="default"
```

---

## 16. Template Functions Reference

### String Functions

| Function | Description | Example |
|----------|-------------|---------|
| `upper` | Convert to uppercase | `"hello" \| upper` → `"HELLO"` |
| `lower` | Convert to lowercase | `"HELLO" \| lower` → `"hello"` |
| `title` | Capitalize first letter of each word | `"hello world" \| title` → `"Hello World"` |
| `trim` | Remove whitespace | `" hello " \| trim` → `"hello"` |
| `trimAll` | Remove all whitespace | `" hello " \| trimAll` → `"hello"` |
| `trimPrefix` | Remove prefix | `"hello" \| trimPrefix "he"` → `"llo"` |
| `trimSuffix` | Remove suffix | `"hello" \| trimSuffix "lo"` → `"hel"` |
| `replace` | Replace substring | `"hello" \| replace "l" "r"` → `"herro"` |
| `quote` | Add quotes | `"hello" \| quote` → `"\"hello\""` |
| `squote` | Add single quotes | `"hello" \| squote` → `"'hello'"` |
| `cat` | Concatenate with space | `"hello" \| cat "world"` → `"hello world"` |
| `indent` | Indent by N spaces | `"hello" \| indent 4` → `"    hello"` |
| `nindent` | Newline + indent | `"hello" \| nindent 2` → `"\n  hello"` |
| `wrap` | Wrap at N columns | `"hello" \| wrap 3` → `"hel\nlo"` |
| `wrapWith` | Wrap with custom newline | `"hello" \| wrapWith 3 "\|"` → `"hel\|lo"` |
| `trunc` | Truncate string | `"hello" \| trunc 3` → `"hel"` |
| `nospace` | Remove all spaces | `"h e l l o" \| nospace` → `"hello"` |
| `camelcase` | CamelCase | `"hello-world" \| camelcase` → `"helloWorld"` |
| `snakecase` | snake_case | `"helloWorld" \| snakecase` → `"hello_world"` |
| `kebabcase` | kebab-case | `"helloWorld" \| kebabcase` → `"hello-world"` |
| `contains` | Check substring | `"hello" \| contains "ell"` → `true` |
| `hasPrefix` | Check prefix | `"hello" \| hasPrefix "hel"` → `true` |
| `hasSuffix` | Check suffix | `"hello" \| hasSuffix "llo"` → `true` |
| `quoteList` | Quote each item | `list "a" "b" \| quoteList` → `"a" "b"` |
| `plural` | Pluralize | `2 \| plural "item" "items"` → `"items"` |

### Math Functions

| Function | Description | Example |
|----------|-------------|---------|
| `add` | Addition | `2 \| add 3` → `5` |
| `add1` | Increment by 1 | `5 \| add1` → `6` |
| `sub` | Subtraction | `5 \| sub 3` → `2` |
| `mul` | Multiplication | `3 \| mul 4` → `12` |
| `div` | Division | `10 \| div 2` → `5` |
| `mod` | Modulus | `10 \| mod 3` → `1` |
| `max` | Maximum | `list 3 1 2 \| max` → `3` |
| `min` | Minimum | `list 3 1 2 \| min` → `1` |
| `ceil` | Round up | `3.1 \| ceil` → `4` |
| `floor` | Round down | `3.9 \| floor` → `3` |
| `round` | Round to decimal | `3.567 \| round 2` → `3.57` |

### List Functions

| Function | Description | Example |
|----------|-------------|---------|
| `list` | Create a list | `list 1 2 3` → `[1 2 3]` |
| `first` | First element | `list 1 2 3 \| first` → `1` |
| `last` | Last element | `list 1 2 3 \| last` → `3` |
| `rest` | All but first | `list 1 2 3 \| rest` → `[2 3]` |
| `initial` | All but last | `list 1 2 3 \| initial` → `[1 2]` |
| `reverse` | Reverse list | `list 1 2 3 \| reverse` → `[3 2 1]` |
| `sortAlpha` | Sort alphabetically | `list c b a \| sortAlpha` → `[a b c]` |
| `append` | Add to end | `list 1 2 \| append 3` → `[1 2 3]` |
| `prepend` | Add to start | `list 2 3 \| prepend 1` → `[1 2 3]` |
| `concat` | Merge lists | `concat (list 1 2) (list 3 4)` → `[1 2 3 4]` |
| `uniq` | Remove duplicates | `list 1 2 2 3 \| uniq` → `[1 2 3]` |
| `without` | Remove elements | `list 1 2 3 \| without 2` → `[1 3]` |
| `has` | Check membership | `list 1 2 3 \| has 2` → `true` |
| `index` | Get element by index | `list a b c \| index 1` → `"b"` |
| `slice` | Sublist | `list a b c d \| slice 1 3` → `[b c]` |
| `compact` | Remove nil values | `list "" "a" "" "b" \| compact` → `["a" "b"]` |
| `flatten` | Flatten nested lists | `list (list 1 2) (list 3 4) \| flatten` → `[1 2 3 4]` |
| `range` | Generate range | `range 0 5` → `[0 1 2 3 4]` |

### Dict Functions

| Function | Description | Example |
|----------|-------------|---------|
| `dict` | Create a dict | `dict "key" "value"` → `{key: value}` |
| `get` | Get value | `dict "a" 1 \| get "a"` → `1` |
| `set` | Set value | `dict \| set "a" 1` → `{a: 1}` |
| `hasKey` | Check key exists | `dict "a" 1 \| hasKey "a"` → `true` |
| `keys` | Get all keys | `dict "a" 1 "b" 2 \| keys` → `[a b]` |
| `values` | Get all values | `dict "a" 1 "b" 2 \| values` → `[1 2]` |
| `pick` | Pick specific keys | `dict "a" 1 "b" 2 \| pick "a"` → `{a: 1}` |
| `omit` | Omit specific keys | `dict "a" 1 "b" 2 \| omit "a"` → `{b: 2}` |
| `merge` | Merge dicts | `merge (dict "a" 1) (dict "b" 2)` → `{a: 1, b: 2}` |
| `mergeOverwrite` | Merge with overwrite | `mergeOverwrite (dict "a" 1) (dict "a" 2)` → `{a: 2}` |

### Encoding Functions

| Function | Description | Example |
|----------|-------------|---------|
| `b64enc` | Base64 encode | `"hello" \| b64enc` → `"aGVsbG8="` |
| `b64dec` | Base64 decode | `"aGVsbG8=" \| b64dec` → `"hello"` |
| `b32enc` | Base32 encode | `"hello" \| b32enc` → `"NBSWY3DP"` |
| `b32dec` | Base32 decode | `"NBSWY3DP" \| b32dec` → `"hello"` |
| `toJson` | Convert to JSON | `dict "a" 1 \| toJson` → `{"a":1}` |
| `fromJson` | Parse JSON | `fromJson "{\"a\":1}"` → `{a: 1}` |
| `toYaml` | Convert to YAML | `dict "a" 1 \| toYaml` → `"a: 1\n"` |
| `fromYaml` | Parse YAML | `fromYaml "a: 1"` → `{a: 1}` |
| `toJsonPretty` | Pretty JSON | `dict "a" 1 \| toJsonPretty` → `"{\n  \"a\": 1\n}"` |

### Type Checking Functions

| Function | Description | Example |
|----------|-------------|---------|
| `kindOf` | Get type | `"hello" \| kindOf` → `"string"` |
| `kindIs` | Check type | `"hello" \| kindIs "string"` → `true` |
| `typeOf` | Get detailed type | `"hello" \| typeOf` → `"string"` |
| `typeIs` | Check detailed type | `"hello" \| typeIs "string"` → `true` |
| `empty` | Check if empty | `"" \| empty` → `true` |

### Date Functions

| Function | Description | Example |
|----------|-------------|---------|
| `now` | Current time | `now` → current time object |
| `date` | Format date | `now \| date "2006-01-02"` → `"2025-01-13"` |
| `dateModify` | Add time | `now \| dateModify "+24h"` → +24h |
| `ago` | Time since | `now \| ago` → `"12h34m56s"` |
| `duration` | Format duration | `123456789 \| duration` → `"123456.789s"` |

### Path and URL Functions

| Function | Description | Example |
|----------|-------------|---------|
| `base` | Base name | `"/a/b/c.txt" \| base` → `"c.txt"` |
| `dir` | Directory | `"/a/b/c.txt" \| dir` → `"/a/b"` |
| `ext` | Extension | `"/a/b/c.txt" \| ext` → `".txt"` |
| `clean` | Clean path | `"/a//b/../c" \| clean` → `"/a/c"` |
| `isAbs` | Absolute check | `"/a/b" \| isAbs` → `true` |
| `urlParse` | Parse URL | `"https://example.com" \| urlParse` → URL object |

### Crypto Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sha256sum` | SHA-256 hash | `"hello" \| sha256sum` → hash |
| `sha1sum` | SHA-1 hash | `"hello" \| sha1sum` → hash |
| `genPrivateKey` | Generate private key | `genPrivateKey "rsa"` → PEM key |
| `genCA` | Generate CA cert | `genCA "My CA" 365` → cert+key |
| `genSelfSignedCert` | Generate cert | `genSelfSignedCert ...` → cert+key |
| `derivePassword` | Derive password | `derivePassword 1 ...` → password |

### Semver Functions

| Function | Description | Example |
|----------|-------------|---------|
| `semver` | Parse semver | `"1.2.3" \| semver` → semver object |
| `semverCompare` | Compare versions | `semverCompare ">=1.2.0" "1.2.3"` → `true` |
| `semverDiff` | Version diff type | `semverDiff "1.2.3" "1.3.0"` → `"minor"` |
| `major` | Major version | `"1.2.3" \| major` → `1` |
| `minor` | Minor version | `"1.2.3" \| minor` → `2` |
| `patch` | Patch version | `"1.2.3" \| patch` → `3` |

### Miscellaneous Functions

| Function | Description | Example |
|----------|-------------|---------|
| `default` | Default value | `"" \| default "fallback"` → `"fallback"` |
| `empty` | Check empty | `"" \| empty` → `true` |
| `not` | Negate | `true \| not` → `false` |
| `fail` | Fail with message | `fail "something went wrong"` → error |
| `ternary` | Conditional value | `true \| ternary "yes" "no"` → `"yes"` |
| `env` | Get env var | `env "HOME"` → `/root` |
| `expandenv` | Expand env vars | `"Hello $HOME" \| expandenv` → `"Hello /root"` |
| `dir` | Directory of path | `"/a/b/c.txt" \| dir` → `"/a/b"` |
| `base` | Base of path | `"/a/b/c.txt" \| base` → `"c.txt"` |
| `clean` | Clean path | `"/a//b/../c" \| clean` → `"/a/c"` |
| `toString` | Convert to string | `123 \| toString` → `"123"` |
| `toDecimal` | Convert to decimal | `"1.5" \| toDecimal` → `1.5` |
| `toInt` | Convert to int | `"123" \| toInt` → `123` |
| `toComplex` | Convert to complex | `"1+2i" \| toComplex` → complex |
| `indent` | Indent lines | `"hello\nworld" \| indent 4` → indented |
| `nindent` | Newline indent | `"hello" \| nindent 2` → `"\n  hello"` |
| `randomBytes` | Random bytes | `randomBytes 32` → random bytes |
| `nospace` | Remove spaces | `"h e l l o" \| nospace` → `"hello"` |
| `wrap` | Wrap at columns | `"hello world" \| wrap 5` → wrapped |

---

## 17. Troubleshooting

### 1. `Error: Kubernetes cluster unreachable`

**Symptom**: Cannot connect to the cluster.

```bash
Error: Kubernetes cluster unreachable: Get "http://localhost:8080/version": dial tcp 127.0.0.1:8080: connect: connection refused
```

**Fix**:
```bash
# Check current context
kubectl config current-context

# Set the correct context
kubectl config use-context my-cluster

# Verify kubeconfig
cat ~/.kube/config | head -20
```

### 2. `Error: release already exists`

**Symptom**: Attempting to install a release that already exists.

```bash
Error: release "my-release" already exists
```

**Fix**:
```bash
# Check existing releases
helm list

# Use upgrade instead
helm upgrade my-release ./my-chart

# Or uninstall and reinstall
helm uninstall my-release
helm install my-release ./my-chart
```

### 3. `Error: chart not found`

**Symptom**: Chart is not in any configured repository.

```bash
Error: chart "my-chart" not found
```

**Fix**:
```bash
# Update repos
helm repo update

# Search for the chart
helm search repo nginx

# Add the correct repo
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### 4. `Error: CRDs are not installed`

**Symptom**: Custom Resources fail because CRDs are missing.

**Fix**:
```bash
# Check if CRDs exist
kubectl get crd | grep myresource

# Install CRDs first
kubectl apply -f crds/
# Then install the chart
helm install my-release ./my-chart
```

### 5. `Error: timed out waiting for resources`

**Symptom**: Helm install/upgrade times out waiting for pods.

```bash
Error: timed out waiting for the condition
```

**Fix**:
```bash
# Check pod status
kubectl get pods -n my-namespace

# Check events
kubectl describe pod my-pod -n my-namespace

# Check logs
kubectl logs my-pod -n my-namespace

# Increase timeout
helm upgrade my-release ./my-chart --timeout 10m --wait

# Or skip waiting
helm upgrade my-release ./my-chart --no-wait
```

### 6. `Error: semantic versioning issue`

**Symptom**: Chart version conflicts with Kubernetes constraints.

```bash
Error: chart requires kubeVersion: >=1.25.0-0 which is incompatible with Kubernetes vX.Y.Z
```

**Fix**:
```bash
# Check your Kubernetes version
kubectl version --short

# Use a compatible chart version
helm search repo my-chart --versions

# Override kubeVersion check (dangerous)
helm install my-release ./my-chart --skip-crds
```

### 7. `Error: rendered templates contain Kubernetes API errors`

**Symptom**: Template validation fails.

```bash
Error: rendered manifests contain a resource that already exists
```

**Fix**:
```bash
# Use --force to replace
helm upgrade my-release ./my-chart --force

# Or uninstall and reinstall
helm uninstall my-release
helm install my-release ./my-chart
```

### 8. `Error: cannot re-use a name that is still in use`

**Symptom**: Release name conflict.

**Fix**:
```bash
# List all releases
helm list --all

# Uninstall the old release
helm uninstall my-release

# Wait for resources to be deleted
kubectl get all -l app.kubernetes.io/instance=my-release

# Install fresh
helm install my-release ./my-chart
```

### 9. `Error: secret not found`

**Symptom**: Template references a secret that doesn't exist.

```bash
Error: Secret "my-secret" not found
```

**Fix**:
```bash
# Check if the secret exists
kubectl get secret my-secret -n my-namespace

# Create the secret manually
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=secret

# Or use helm to install the chart that creates it
helm install my-release ./my-chart
```

### 10. `Error: role/rolebinding not found`

**Symptom**: ServiceAccount lacks permissions.

**Fix**:
```bash
# Check the service account
kubectl get sa my-sa -n my-namespace

# Check role bindings
kubectl get rolebinding -n my-namespace

# Create RBAC
kubectl apply -f rbac.yaml
```

### 11. `Error: numeric value too large`

**Symptom**: Template produces invalid YAML due to unquoted numbers.

**Fix**:
```yaml
# Before (broken)
port: {{ .Values.service.port }}

# After (correct)
port: {{ .Values.service.port | int }}
# or
port: {{ .Values.service.port | int64 }}
```

### 12. `Error: template rendering fails with nil pointer`

**Symptom**: Accessing a value that doesn't exist.

```yaml
# This fails if .Values.ingress is nil
{{ .Values.ingress.host }}

# Fix: use "with" or check existence
{{- with .Values.ingress }}
host: {{ .host }}
{{- end }}

# Or with if
{{- if .Values.ingress }}
host: {{ .Values.ingress.host }}
{{- end }}
```

### 13. `Error: circular dependency in chart`

**Symptom**: Chart dependencies reference each other.

**Fix**:
```bash
# Remove the circular reference
# Check Chart.yaml dependencies
helm dependency build

# Or restructure dependencies
```

### 14. `Error: cannot find a Ready certificate`

**Symptom**: TLS/HTTPS issues with chart repository.

**Fix**:
```bash
# Add repo without TLS verification (insecure)
helm repo add my-repo https://charts.internal.example.com --insecure-skip-tls-verify

# Or add the CA certificate
helm repo add my-repo https://charts.internal.example.com --ca-file ca.crt
```

### 15. `Error: release name exceeds Kubernetes limit`

**Symptom**: Release name is too long.

```bash
Error: release name "my-very-long-release-name-for-production-environment" exceeds Kubernetes 53 character limit
```

**Fix**:
```bash
# Use a shorter release name
helm install prod ./my-chart

# Or use --name-template to generate shorter names
helm install . --name-template "{{ .Release.Name }}-{{ .Chart.Name }}"
```

### 16. Debugging Failed Installs

```bash
# Check release status
helm status my-release

# Get detailed info
helm get all my-release

# Get manifest
helm get manifest my-release

# Get values used
helm get values my-release

# Get all values including defaults
helm get values my-release --all

# Get hooks
helm get hooks my-release

# Get notes
helm get notes my-release
```

### 17. Debugging Template Rendering

```bash
# Dry run to see what would be applied
helm template my-release ./my-chart --debug

# Render specific templates
helm template my-release ./my-chart --show-only templates/deployment.yaml

# Render with specific values
helm template my-release ./my-chart -f values.yaml --debug

# Check template syntax
helm lint ./my-chart
```

### 18. Debugging Resource Creation

```bash
# Check if resources were created
kubectl get all -l app.kubernetes.io/instance=my-release

# Check events
kubectl get events -n my-namespace --sort-by='.lastTimestamp'

# Describe problematic resource
kubectl describe pod my-pod -n my-namespace

# Check logs
kubectl logs my-pod -n my-namespace
kubectl logs my-pod -n my-namespace --previous  # Previous container logs
```

---

## 18. Tips & Best Practices

### 1. Always Use `--atomic` for Production Upgrades

```bash
helm upgrade my-release ./my-chart \
  --atomic \
  --timeout 5m \
  --wait
```

This automatically rolls back if the upgrade fails or times out.

### 2. Use `helm diff` Before Upgrading

```bash
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade my-release ./my-chart -f values.yaml
```

Preview what will change before making any modifications.

### 3. Use Chart Dependencies Instead of Multiple Releases

Instead of deploying Redis, PostgreSQL, and your app as separate releases, bundle them:

```yaml
# Chart.yaml
dependencies:
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
  - name: postgresql
    version: "13.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

### 4. Use Semantic Versioning for Your Charts

```yaml
# Chart.yaml
version: 1.2.3  # Follow semver
```

### 5. Keep `values.yaml` Documented

```yaml
# Number of replicas to deploy
replicaCount: 1

# Docker image configuration
image:
  repository: nginx
  # Image pull policy (Always, IfNotPresent, Never)
  pullPolicy: IfNotPresent
  # Image tag (defaults to appVersion)
  tag: ""
```

### 6. Use Labels Consistently

```yaml
# Common labels for all resources
{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

### 7. Use Separate Files for Environments

```
values.yaml            # Base defaults
values-dev.yaml        # Dev overrides
values-staging.yaml    # Staging overrides
values-production.yaml # Production overrides
```

### 8. Never Store Secrets in `values.yaml`

```bash
# Use --set for secrets
helm install my-release ./my-chart \
  --set secrets.dbPassword=$(kubectl get secret db -o jsonpath='{.data.password}' | base64 -d)

# Or use external secret management
helm install my-release ./my-chart -f secrets://values-secrets.yaml
```

### 9. Use `helm lint` Before Every Release

```bash
helm lint ./my-chart --strict
helm lint ./my-chart -f values.yaml
```

### 10. Use `helm template` to Debug

```bash
helm template my-release ./my-chart -f values.yaml > rendered.yaml
# Inspect the output
cat rendered.yaml | grep -A 5 "kind: Deployment"
```

### 11. Use `_helpers.tpl` for Reusable Templates

Keep your templates DRY by defining reusable snippets in `_helpers.tpl`.

### 12. Version Your Charts with Git Tags

```bash
git tag -a v1.2.3 -m "Release 1.2.3"
git push --tags
```

### 13. Use `helm package` for Distribution

```bash
helm package my-chart -d ./dist/
helm repo index ./dist/ --url https://charts.example.com
```

### 14. Use `helm list` to Monitor Deployments

```bash
# Watch all releases
helm list --all-namespaces --output wide

# Filter by status
helm list --deployed
helm list --failed
helm list --pending
```

### 15. Use `--create-namespace` for New Namespaces

```bash
helm install my-release ./my-chart --namespace new-ns --create-namespace
```

### 16. Use `helm history` for Audit Trails

```bash
helm history my-release --max 10
```

### 17. Use OCI Registries for Private Charts

```bash
helm push my-chart-0.1.0.tgz oci://registry.example.com/charts
helm install my-release oci://registry.example.com/charts/my-chart --version 0.1.0
```

### 18. Use `helmfile` for Multi-Release Management

```yaml
# helmfile.yaml
releases:
  - name: app
    chart: ./my-chart
    values:
      - values/app.yaml
  - name: nginx
    chart: bitnami/nginx
    values:
      - values/nginx.yaml
```

### 19. Test Your Charts

```bash
# Install test dependencies
helm plugin install https://github.com/quintush/helm-unittest

# Run unit tests
helm unittest ./my-chart

# Run integration tests
helm test my-release
```

### 20. Document Your Charts

Include a comprehensive `README.md` with:

- Chart description
- Prerequisites
- Installation instructions
- Configuration reference
- Examples
- Troubleshooting

---

## 19. Real-World Example

### Creating a Chart for a Microservices Application

Let's create a chart for a typical microservices application with:

- An API Gateway (Nginx)
- A Backend Service (Node.js)
- A Database (PostgreSQL)
- A Cache (Redis)

#### Directory Structure

```
microservices-app/
├── Chart.yaml
├── values.yaml
├── values/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── production.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   ├── api-gateway/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   └── hpa.yaml
│   ├── postgresql/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   └── redis/
│       ├── deployment.yaml
│       └── service.yaml
├── charts/
├── README.md
└── LICENSE
```

#### Chart.yaml

```yaml
apiVersion: v2
name: microservices-app
description: A complete microservices application with API Gateway, Backend, Database, and Cache
type: application
version: 1.0.0
appVersion: "2.0.0"
keywords:
  - microservices
  - api-gateway
  - backend
  - database
  - cache
maintainers:
  - name: DevOps Team
    email: devops@example.com
dependencies:
  - name: redis
    version: "18.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

#### values.yaml

```yaml
# Global settings
global:
  imageRegistry: ""
  imagePullSecrets: []

# API Gateway
apiGateway:
  enabled: true
  replicaCount: 2
  image:
    repository: nginx
    tag: "1.25"
    pullPolicy: IfNotPresent
  service:
    type: LoadBalancer
    port: 80
    httpsPort: 443
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80

# Backend Service
backend:
  enabled: true
  replicaCount: 3
  image:
    repository: myregistry/backend
    tag: "latest"
    pullPolicy: Always
  service:
    type: ClusterIP
    port: 3000
  config:
    NODE_ENV: production
    LOG_LEVEL: info
    DATABASE_URL: "postgresql://postgres:secret@postgresql:5432/app"
    REDIS_URL: "redis://redis:6379"
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20
    targetCPUUtilizationPercentage: 75

# PostgreSQL
postgresql:
  enabled: true
  replicaCount: 1
  image:
    repository: postgres
    tag: "16"
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 5432
  auth:
    postgresPassword: changeme
    database: app
  persistence:
    enabled: true
    size: 10Gi
    storageClass: ""
  resources:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi

# Redis
redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: false
  persistence:
    enabled: true
    size: 2Gi

# Monitoring
monitoring:
  enabled: false
  serviceMonitor:
    enabled: false
    interval: 30s
```

#### templates/_helpers.tpl

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "microservices-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "microservices-app.fullname" -}}
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
{{- define "microservices-app.labels" -}}
helm.sh/chart: {{ include "microservices-app.chart" . }}
{{ include "microservices-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "microservices-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservices-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
API Gateway labels
*/}}
{{- define "microservices-app.apiGateway.labels" -}}
{{ include "microservices-app.labels" . }}
app.kubernetes.io/component: api-gateway
{{- end }}

{{/*
Backend labels
*/}}
{{- define "microservices-app.backend.labels" -}}
{{ include "microservices-app.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "microservices-app.postgresql.labels" -}}
{{ include "microservices-app.labels" . }}
app.kubernetes.io/component: database
{{- end }}
```

#### templates/api-gateway/deployment.yaml

```yaml
{{- if .Values.apiGateway.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservices-app.fullname" . }}-api-gateway
  labels:
    {{- include "microservices-app.apiGateway.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.apiGateway.replicaCount }}
  selector:
    matchLabels:
      {{- include "microservices-app.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: api-gateway
  template:
    metadata:
      labels:
        {{- include "microservices-app.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: api-gateway
    spec:
      containers:
        - name: nginx
          image: "{{ .Values.apiGateway.image.repository }}:{{ .Values.apiGateway.image.tag }}"
          imagePullPolicy: {{ .Values.apiGateway.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            {{- toYaml .Values.apiGateway.resources | nindent 12 }}
{{- end }}
```

#### templates/api-gateway/service.yaml

```yaml
{{- if .Values.apiGateway.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "microservices-app.fullname" . }}-api-gateway
  labels:
    {{- include "microservices-app.apiGateway.labels" . | nindent 4 }}
spec:
  type: {{ .Values.apiGateway.service.type }}
  ports:
    - port: {{ .Values.apiGateway.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "microservices-app.selectorLabels" . | nindent 4 }}
    app.kubernetes.io/component: api-gateway
{{- end }}
```

#### templates/backend/deployment.yaml

```yaml
{{- if .Values.backend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservices-app.fullname" . }}-backend
  labels:
    {{- include "microservices-app.backend.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.backend.replicaCount }}
  selector:
    matchLabels:
      {{- include "microservices-app.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: backend
  template:
    metadata:
      labels:
        {{- include "microservices-app.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: backend
    spec:
      containers:
        - name: backend
          image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
          imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.backend.service.port }}
              protocol: TCP
          env:
            {{- range $key, $value := .Values.backend.config }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            {{- toYaml .Values.backend.resources | nindent 12 }}
{{- end }}
```

#### templates/backend/configmap.yaml

```yaml
{{- if .Values.backend.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "microservices-app.fullname" . }}-backend-config
  labels:
    {{- include "microservices-app.backend.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.backend.config }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
```

#### templates/backend/secret.yaml

```yaml
{{- if .Values.backend.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "microservices-app.fullname" . }}-backend-secret
  labels:
    {{- include "microservices-app.backend.labels" . | nindent 4 }}
type: Opaque
data:
  DATABASE_URL: {{ .Values.backend.config.DATABASE_URL | b64enc | quote }}
  REDIS_URL: {{ .Values.backend.config.REDIS_URL | b64enc | quote }}
{{- end }}
```

#### templates/postgresql/deployment.yaml

```yaml
{{- if .Values.postgresql.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservices-app.fullname" . }}-postgresql
  labels:
    {{- include "microservices-app.postgresql.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.postgresql.replicaCount }}
  selector:
    matchLabels:
      {{- include "microservices-app.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: database
  template:
    metadata:
      labels:
        {{- include "microservices-app.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: database
    spec:
      containers:
        - name: postgresql
          image: "{{ .Values.postgresql.image.repository }}:{{ .Values.postgresql.image.tag }}"
          imagePullPolicy: {{ .Values.postgresql.image.pullPolicy }}
          ports:
            - name: postgres
              containerPort: 5432
              protocol: TCP
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "microservices-app.fullname" . }}-postgresql
                  key: postgres-password
            - name: POSTGRES_DB
              value: {{ .Values.postgresql.auth.database | quote }}
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          resources:
            {{- toYaml .Values.postgresql.resources | nindent 12 }}
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ include "microservices-app.fullname" . }}-postgresql
{{- end }}
```

#### templates/postgresql/pvc.yaml

```yaml
{{- if and .Values.postgresql.enabled .Values.postgresql.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "microservices-app.fullname" . }}-postgresql
  labels:
    {{- include "microservices-app.postgresql.labels" . | nindent 4 }}
spec:
  accessModes:
    - ReadWriteOnce
  {{- if .Values.postgresql.persistence.storageClass }}
  storageClassName: {{ .Values.postgresql.persistence.storageClass }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.postgresql.persistence.size }}
{{- end }}
```

#### templates/redis/deployment.yaml

```yaml
{{- if .Values.redis.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservices-app.fullname" . }}-redis
  labels:
    {{- include "microservices-app.labels" . | nindent 4 }}
    app.kubernetes.io/component: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "microservices-app.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: cache
  template:
    metadata:
      labels:
        {{- include "microservices-app.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: cache
    spec:
      containers:
        - name: redis
          image: redis:7
          ports:
            - name: redis
              containerPort: 6379
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 50m
              memory: 64Mi
{{- end }}
```

#### Installing the Chart

```bash
# Dev environment
helm install dev-app ./microservices-app \
  -f values/dev.yaml \
  --namespace dev --create-namespace

# Staging environment
helm install staging-app ./microservices-app \
  -f values/staging.yaml \
  --namespace staging --create-namespace

# Production environment
helm install prod-app ./microservices-app \
  -f values/production.yaml \
  --namespace production --create-namespace \
  --atomic --timeout 10m --wait
```

#### Upgrading the Chart

```bash
# Upgrade production
helm upgrade prod-app ./microservices-app \
  -f values/production.yaml \
  --namespace production \
  --atomic --timeout 10m --wait

# Upgrade specific component
helm upgrade prod-app ./microservices-app \
  -f values/production.yaml \
  --set backend.replicaCount=5 \
  --namespace production
```

#### Monitoring the Release

```bash
# Check status
helm status prod-app -n production

# Get all resources
kubectl get all -l app.kubernetes.io/instance=prod-app -n production

# Check logs
kubectl logs -l app.kubernetes.io/component=backend -n production --tail=100
```

---

## 20. Further Reading

### Official Documentation

- **Helm Documentation**: [https://helm.sh/docs/](https://helm.sh/docs/)
- **Helm Best Practices**: [https://helm.sh/docs/chart_best_practices/](https://helm.sh/docs/chart_best_practices/)
- **Helm Template Guide**: [https://helm.sh/docs/chart_template_guide/](https://helm.sh/docs/chart_template_guide/)
- **Helm Chart Development Tips**: [https://helm.sh/docs/howto/charts_tips_and_tricks/](https://helm.sh/docs/howto/charts_tips_and_tricks/)
- **Helm Plugins List**: [https://helm.sh/docs/topics/plugins/](https://helm.sh/docs/topics/plugins/)
- **Helm 3 Migration Guide**: [https://helm.sh/docs/topics/v2_v3_migration/](https://helm.sh/docs/topics/v2_v3_migration/)

### GitHub Repositories

- **Helm Main Repository**: [https://github.com/helm/helm](https://github.com/helm/helm)
- **Bitnami Charts**: [https://github.com/bitnami/charts](https://github.com/bitnami/charts)
- **Prometheus Helm Charts**: [https://github.com/prometheus-community/helm-charts](https://github.com/prometheus-community/helm-charts)
- **Grafana Helm Charts**: [https://github.com/grafana/helm-charts](https://github.com/grafana/helm-charts)
- **Helmfile**: [https://github.com/helmfile/helmfile](https://github.com/helmfile/helmfile)

### Tools and Plugins

- **helm-diff**: [https://github.com/databus23/helm-diff](https://github.com/databus23/helm-diff) - Preview changes before upgrading
- **helm-secrets**: [https://github.com/jkroepke/helm-secrets](https://github.com/jkroepke/helm-secrets) - Manage secrets with SOPS
- **helmfile**: [https://github.com/helmfile/helmfile](https://github.com/helmfile/helmfile) - Declarative Helm release management
- **helm-unittest**: [https://github.com/quintush/helm-unittest](https://github.com/quintush/helm-unittest) - Unit testing for Helm charts
- **chart-testing**: [https://github.com/helm/chart-testing](https://github.com/helm/chart-testing) - Lint and test charts
- **ct (chart-testing)**: [https://github.com/helm/chart-testing](https://github.com/helm/chart-testing) - CI/CD tool for chart testing

### OCI Registries

- **Harbor**: [https://goharbor.io/](https://goharbor.io/) - Open-source registry with Helm support
- **Docker Hub**: [https://hub.docker.com/](https://hub.docker.com/) - Supports Helm OCI
- **GitHub Container Registry**: [https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### Books and Tutorials

- **Helm: Up & Running** (O'Reilly) - Comprehensive Helm guide
- **Kubernetes Patterns** (O'Reilly) - Includes Helm best practices
- **Cloud Native DevOps with Kubernetes** - Helm chapters
- **Learn Helm** (Packt) - Beginner-friendly Helm tutorial

### Community Resources

- **Helm Slack**: [https://helm.sh/community/](https://helm.sh/community/) - Official Helm Slack channel
- **Kubernetes Slack**: #helm channel
- **CNCF Helm Working Group**: [https://github.com/cncf/helm](https://github.com/cncf/helm)
- **Stack Overflow**: [https://stackoverflow.com/questions/tagged/helm](https://stackoverflow.com/questions/tagged/helm)

### Example Charts to Study

- **Bitnami Charts**: Excellent examples of production-ready charts
- **Prometheus Stack**: Complex chart with many dependencies
- **Elastic Stack**: Multi-component chart with extensive configuration
- **Ingress NGINX**: Simple but well-structured chart

### Cheat Sheet

```bash
# Install
helm install RELEASE_NAME CHART -f values.yaml -n namespace --create-namespace

# Upgrade
helm upgrade RELEASE_NAME CHART -f values.yaml -n namespace --atomic

# Rollback
helm rollback RELEASE_NAME REVISION -n namespace

# List
helm list -n namespace --output wide

# Status
helm status RELEASE_NAME -n namespace

# Uninstall
helm uninstall RELEASE_NAME -n namespace

# Search
helm search repo KEYWORD --versions

# Repo management
helm repo add NAME URL
helm repo update
helm repo list

# Package
helm package CHART -d dist/

# Template
helm template RELEASE_NAME CHART -f values.yaml > rendered.yaml

# Lint
helm lint CHART --strict

# Diff
helm diff upgrade RELEASE_NAME CHART -f values.yaml
```

---

## Quick Reference: Helm Cheat Sheet

### Installation Commands

| Command | Description |
|---------|-------------|
| `helm install NAME CHART` | Install a chart |
| `helm upgrade NAME CHART` | Upgrade a release |
| `helm rollback NAME REVISION` | Rollback to a revision |
| `helm uninstall NAME` | Remove a release |
| `helm list` | List releases |
| `helm status NAME` | Show release status |
| `helm history NAME` | Show release history |
| `helm search repo KEYWORD` | Search repos |
| `helm repo add NAME URL` | Add a repo |
| `helm repo update` | Update repos |
| `helm package CHART` | Package a chart |
| `helm lint CHART` | Lint a chart |
| `helm template NAME CHART` | Render templates |
| `helm test NAME` | Run tests |
| `helm plugin install URL` | Install a plugin |

### Common Flags

| Flag | Description |
|------|-------------|
| `-f, --values` | Values file |
| `--set` | Set values |
| `--namespace, -n` | Namespace |
| `--atomic` | Rollback on failure |
| `--wait` | Wait for resources |
| `--timeout` | Timeout duration |
| `--dry-run` | Simulate |
| `--debug` | Debug output |
| `--create-namespace` | Create namespace |
| `--force` | Force replace |
| `--reuse-values` | Merge values |
| `--reset-values` | Reset to defaults |

### Values Priority

1. Chart `values.yaml`
2. Parent chart `values.yaml`
3. `-f` files (in order)
4. `--set` flags

### Template Objects

| Object | Description |
|--------|-------------|
| `.Release` | Release info (name, namespace, revision) |
| `.Chart` | Chart info (name, version, appVersion) |
| `.Values` | Values from `values.yaml` and overrides |
| `.Capabilities` | Kubernetes capabilities |
| `.Template` | Current template info |

---

**This guide covers Helm 3.16+ with Kubernetes 1.25+. Always refer to the official documentation for the latest information.**

**Last updated: 2025**
