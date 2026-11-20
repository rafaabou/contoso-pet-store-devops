# kube-state-metrics Complete Guide

## Table of Contents

1. [What Is kube-state-metrics](#1-what-is-kube-state-metrics)
2. [Why Use kube-state-metrics](#2-why-use-kube-state-metrics)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Metrics Reference](#7-metrics-reference)
8. [Usage Guide (Step-by-Step)](#8-usage-guide-step-by-step)
9. [Custom Resource Metrics](#9-custom-resource-metrics)
10. [Native Histograms](#10-native-histograms)
11. [Helm Deployment](#11-helm-deployment)
12. [Integrations](#12-integrations)
13. [Security](#13-security)
14. [Performance Tuning](#14-performance-tuning)
15. [Troubleshooting](#15-troubleshooting)
16. [Tips and Best Practices](#16-tips-and-best-practices)
17. [Command Reference](#17-command-reference)
18. [Configuration Reference](#18-configuration-reference)
19. [Real-World Examples](#19-real-world-examples)
20. [Further Reading](#20-further-reading)

---

## 1. What Is kube-state-metrics

kube-state-metrics (KSM) is a simple service that listens to the Kubernetes API server and generates metrics about the state of Kubernetes objects (deployments, pods, nodes, namespaces, etc.). It does not manage or monitor the cluster itself — it only generates metrics about the objects' state.

### Key Features

- **Object state metrics**: Generates metrics for all Kubernetes objects
- **No sampling**: Reports exact state, not averages
- **Lightweight**: Minimal resource usage
- **Real-time updates**: Metrics reflect current cluster state
- **Custom resource support**: Extensible to Custom Resource Definitions (CRDs)
- **Native histograms**: Support for Kubernetes native histogram metrics
- **Label metrics**: Metrics include relevant labels for filtering and grouping

### Metric Types

KSM generates three types of metrics:

1. **Current state**: Gauges showing current values (e.g., pod count, deployment replicas)
2. **Info**: Metadata about objects (e.g., pod labels, container images)
3. **Event**: Counters for Kubernetes events (optional, disabled by default)

### Metric Naming Convention

```
kube_<resource>_<metric>
```

Examples:
- `kube_deployment_status_replicas_available`
- `kube_pod_status_phase`
- `kube_node_status_condition`

---

## 2. Why Use kube-state-metrics

### vs. Metrics Server

| Feature | kube-state-metrics | Metrics Server |
|---------|-------------------|----------------|
| Purpose | Object state metrics | Resource usage metrics |
| Data source | Kubernetes API | cAdvisor/kubelet |
| Metrics type | State (ready, available) | Usage (CPU, memory) |
| Latency | Real-time | Near real-time |
| Resource usage | Low | Medium |

### When to Use kube-state-metrics

- Monitor deployment status (available vs. desired replicas)
- Track pod lifecycle (pending, running, failed, succeeded)
- Monitor node health and conditions
- Track resource quota usage
- Monitor persistent volume claims
- Track DaemonSet, StatefulSet, Job, CronJob status
- Monitor Custom Resources

### Advantages

- **Simple**: No complex configuration required
- **Reliable**: Directly reads from Kubernetes API
- **Complete**: Covers all core Kubernetes resources
- **Extensible**: Custom metrics for CRDs
- **Lightweight**: Minimal resource footprint

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────┐
│              Kubernetes API Server           │
│  ┌───────────────────────────────────────┐  │
│  │  Objects: Pods, Deployments, Nodes,   │  │
│  │  Services, ConfigMaps, Secrets, etc.  │  │
│  └───────────────────┬───────────────────┘  │
└──────────────────────┼──────────────────────┘
                       │ watch/list
              ┌────────┴────────┐
              │ kube-state-metrics│
              │                 │
              │ ┌─────────────┐ │
              │ │  Metrics    │ │
              │ │  Generator  │ │
              │ └─────────────┘ │
              │ ┌─────────────┐ │
              │ │  /metrics   │ │
              │ │  endpoint   │ │
              │ │  (:8080)    │ │
              │ └─────────────┘ │
              └────────┬────────┘
                       │ scrape
                 ┌─────┴─────┐
                 │ Prometheus │
                 └───────────┘
```

### Components

1. **Kubernetes Client**: Connects to the API server
2. **Object Store**: Watches and caches Kubernetes objects
3. **Metrics Generator**: Converts object state to Prometheus metrics
4. **HTTP Server**: Serves `/metrics` endpoint on port 8080

### Data Flow

1. KSM connects to Kubernetes API server
2. Watches for object changes (create, update, delete)
3. Maintains an in-memory store of object states
4. On each scrape, generates metrics from the store
5. Returns metrics in Prometheus exposition format

### High Availability

KSM can run in two modes:
- **Single instance**: Sufficient for most clusters
- **Two replicas**: For HA (recommended for production)

With two replicas, both serve metrics but one may be slightly behind. Prometheus scrapes both and uses `honor_labels: true` to avoid duplicates.

---

## 4. Installation

### Kubernetes (Manifests)

```yaml
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: monitoring

---
# Cluster Role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
  - apiGroups: [""]
    resources: ['nodes', 'pods', 'services', 'resourcequotas', 'replicationcontrollers', 'limitranges', 'persistentvolumeclaims', 'namespaces', 'configmaps']
    verbs: ['list', 'watch']
  - apiGroups: ['extensions', 'apps']
    resources: ['daemonsets', 'deployments', 'replicasets', 'statefulsets']
    verbs: ['list', 'watch']
  - apiGroups: ['batch']
    resources: ['jobs', 'cronjobs']
    verbs: ['list', 'watch']
  - apiGroups: ['autoscaling']
    resources: ['horizontalpodautoscalers']
    verbs: ['list', 'watch']
  - apiGroups: ['policy']
    resources: ['poddisruptionbudgets']
    verbs: ['list', 'watch']
  - apiGroups: ['storage.k8s.io']
    resources: ['storageclasses', 'volumeattachments']
    verbs: ['list', 'watch']
  - apiGroups: ['certificates.k8s.io']
    resources: ['certificatesigningrequests']
    verbs: ['list', 'watch']

---
# Cluster Role Binding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
  - kind: ServiceAccount
    name: kube-state-metrics
    namespace: monitoring

---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    app: kube-state-metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-state-metrics
  template:
    metadata:
      labels:
        app: kube-state-metrics
    spec:
      serviceAccountName: kube-state-metrics
      containers:
        - name: kube-state-metrics
          image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.12.0
          args:
            - '--port=8080'
            - '--telemetry-port=8081'
          ports:
            - containerPort: 8080
              name: metrics
            - containerPort: 8081
              name: telemetry
          resources:
            limits:
              memory: 256Mi
              cpu: 200m
            requests:
              memory: 128Mi
              cpu: 100m
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            timeoutSeconds: 5

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    app: kube-state-metrics
spec:
  clusterIP: None
  ports:
    - port: 8080
      targetPort: 8080
      name: metrics
    - port: 8081
      targetPort: 8081
      name: telemetry
  selector:
    app: kube-state-metrics
```

### Install with kubectl

```bash
kubectl apply -f kube-state-metrics.yaml
```

### Verify Installation

```bash
# Check pods
kubectl get pods -n monitoring -l app=kube-state-metrics

# Check service
kubectl get svc -n monitoring kube-state-metrics

# Test metrics
kubectl port-forward -n monitoring svc/kube-state-metrics 8080:8080
curl http://localhost:8080/metrics | head -20
```

---

## 5. Configuration

### Command-Line Flags

```bash
kube-state-metrics \
  --port=8080 \
  --telemetry-port=8081 \
  --metric-labels-allowlist=pods=[app,version],deployments=[app] \
  --metric-annotations-allowlist=pods=[app] \
  --namespaces="default,kube-system" \
  --resources=pods,deployments,nodes \
  --metric-optimizer-level=1 \
  --enable-gzip-encoding \
  --log-file=/var/log/kube-state-metrics.log \
  --log-level=info \
  --help
```

### Configuration File

```yaml
# /etc/kube-state-metrics/config.yaml
port: 8080
telemetry-port: 8081

# Resource filtering
resources:
  - pods
  - deployments
  - nodes
  - services
  - configmaps
  - secrets
  - namespaces
  - persistentvolumeclaims
  - jobs
  - cronjobs
  - daemonsets
  - statefulsets
  - horizontalpodautoscalers
  - poddisruptionbudgets

# Namespace filtering
namespaces:
  - default
  - kube-system
  - monitoring

# Label allowlist
metric-labels-allowlist:
  - pods=[app,version,env]
  - deployments=[app,version]
  - nodes=[kubernetes.io/os,kubernetes.io/arch]

# Annotation allowlist
metric-annotations-allowlist:
  - pods=[app]
```

### Helm Values

```yaml
# helm values.yaml
image:
  repository: registry.k8s.io/kube-state-metrics/kube-state-metrics
  tag: v2.12.0

replicas: 2

resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m

# Metric generation
metricLabelsAllowlist:
  - pods=[app,version,env]
  - deployments=[app,version]

metricAnnotationsAllowlist:
  - pods=[app]

# Namespace filtering
namespaces: ""

# Resource filtering
resources:
  - pods
  - deployments
  - nodes
  - services
  - configmaps
  - secrets
  - namespaces
  - persistentvolumeclaims
  - jobs
  - cronjobs
  - daemonsets
  - statefulsets
  - horizontalpodautoscalers
  - poddisruptionbudgets

# Telemetry
telemetryPort: 8081
```

---

## 6. Core Concepts

### Object Store

KSM maintains an in-memory store of Kubernetes objects. When an object is created, updated, or deleted, the store is updated, and metrics are regenerated on the next scrape.

### Metric Generation

KSM generates metrics by inspecting each object's status and spec:

```
Object (Deployment) → Status (Replicas, Conditions) → Metrics
```

### Labels

KSM adds relevant labels to metrics:

```
kube_deployment_status_replicas_available{namespace="default",deployment="nginx"} 3
```

### Resource Filtering

You can restrict which resources KSM monitors:

```bash
--resources=pods,deployments,nodes
```

### Namespace Filtering

You can restrict which namespaces KSM monitors:

```bash
--namespaces="default,kube-system"
```

### Metric Labels Allowlist

By default, KSM only includes standard labels. To include custom labels:

```bash
--metric-labels-allowlist=pods=[app,version],deployments=[app]
```

---

## 7. Metrics Reference

### Pod Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_pod_info` | Info | Pod information |
| `kube_pod_status_phase` | Gauge | Pod phase (Running, Pending, etc.) |
| `kube_pod_status_ready` | Gauge | Pod ready condition |
| `kube_pod_status_scheduled` | Gauge | Pod scheduled condition |
| `kube_pod_container_status_ready` | Gauge | Container ready state |
| `kube_pod_container_status_restarts_total` | Counter | Container restart count |
| `kube_pod_container_resource_requests` | Gauge | Resource requests |
| `kube_pod_container_resource_limits` | Gauge | Resource limits |
| `kube_pod_created` | Gauge | Pod creation timestamp |
| `kube_pod_owner` | Info | Pod owner reference |

### Deployment Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_deployment_status_replicas` | Gauge | Total replicas |
| `kube_deployment_status_replicas_available` | Gauge | Available replicas |
| `kube_deployment_status_replicas_unavailable` | Gauge | Unavailable replicas |
| `kube_deployment_status_replicas_updated` | Gauge | Updated replicas |
| `kube_deployment_spec_replicas` | Gauge | Desired replicas |
| `kube_deployment_spec_strategy_rolling_update_max_surge` | Gauge | Rolling update max surge |
| `kube_deployment_spec_strategy_rolling_update_max_unavailable` | Gauge | Rolling update max unavailable |
| `kube_deployment_created` | Gauge | Deployment creation timestamp |

### Node Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_node_info` | Info | Node information |
| `kube_node_status_condition` | Gauge | Node conditions |
| `kube_node_status_capacity` | Gauge | Node resource capacity |
| `kube_node_status_allocatable` | Gauge | Node allocatable resources |
| `kube_node_created` | Gauge | Node creation timestamp |
| `kube_node_spec_taint` | Info | Node taints |

### Service Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_service_info` | Info | Service information |
| `kube_service_spec_type` | Gauge | Service type |
| `kube_service_created` | Gauge | Service creation timestamp |
| `kube_service_labels` | Info | Service labels |

### Namespace Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_namespace_status_phase` | Gauge | Namespace phase |
| `kube_namespace_labels` | Info | Namespace labels |
| `kube_namespace_created` | Gauge | Namespace creation timestamp |

### DaemonSet Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_daemonset_status_desired_number_scheduled` | Gauge | Desired number scheduled |
| `kube_daemonset_status_number_ready` | Gauge | Number ready |
| `kube_daemonset_status_number_available` | Gauge | Number available |
| `kube_daemonset_status_number_unavailable` | Gauge | Number unavailable |
| `kube_daemonset_status_updated_number_scheduled` | Gauge | Updated number scheduled |

### StatefulSet Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_statefulset_status_replicas` | Gauge | Total replicas |
| `kube_statefulset_status_replicas_ready` | Gauge | Ready replicas |
| `kube_statefulset_status_replicas_updated` | Gauge | Updated replicas |
| `kube_statefulset_spec_replicas` | Gauge | Desired replicas |

### Job Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_job_status_active` | Gauge | Active pods |
| `kube_job_status_succeeded` | Gauge | Succeeded pods |
| `kube_job_status_failed` | Gauge | Failed pods |
| `kube_job_spec_completions` | Gauge | Desired completions |
| `kube_job_spec_parallelism` | Gauge | Desired parallelism |
| `kube_job_complete` | Gauge | Job completion status |

### CronJob Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_cronjob_status_active` | Gauge | Active jobs |
| `kube_cronjob_status_last_schedule_time` | Gauge | Last schedule time |
| `kube_cronjob_spec_suspend` | Gauge | Suspended status |
| `kube_cronjob_next_schedule_time` | Gauge | Next schedule time |

### PVC Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_persistentvolumeclaim_info` | Info | PVC information |
| `kube_persistentvolumeclaim_status_phase` | Gauge | PVC phase |
| `kube_persistentvolumeclaim_resource_requests_storage_bytes` | Gauge | Requested storage |
| `kube_persistentvolumeclaim_labels` | Info | PVC labels |

### HPA Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_hpa_spec_max_replicas` | Gauge | Maximum replicas |
| `kube_hpa_spec_min_replicas` | Gauge | Minimum replicas |
| `kube_hpa_status_current_replicas` | Gauge | Current replicas |
| `kube_hpa_status_desired_replicas` | Gauge | Desired replicas |
| `kube_hpa_status_condition` | Gauge | HPA conditions |

### PDB Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_poddisruptionbudget_status_current_healthy` | Gauge | Current healthy pods |
| `kube_poddisruptionbudget_status_desired_healthy` | Gauge | Desired healthy pods |
| `kube_poddisruptionbudget_status_pod_disruptions_allowed` | Gauge | Disruptions allowed |
| `kube_poddisruptionbudget_spec_min_available` | Gauge | Min available |
| `kube_poddisruptionbudget_spec_max_unavailable` | Gauge | Max unavailable |

### Resource Quota Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_resourcequota` | Gauge | Resource quota status |
| `kube_resourcequota_created` | Gauge | Quota creation timestamp |

### Limit Range Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `kube_limitrange` | Gauge | Limit range info |
| `kube_limitrange_created` | Gauge | Limit range creation timestamp |

---

## 8. Usage Guide (Step-by-Step)

### Step 1: Create Namespace

```bash
kubectl create namespace monitoring
```

### Step 2: Create Service Account and RBAC

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
  - apiGroups: [""]
    resources: ['nodes', 'pods', 'services', 'resourcequotas', 'replicationcontrollers', 'limitranges', 'persistentvolumeclaims', 'namespaces', 'configmaps']
    verbs: ['list', 'watch']
  - apiGroups: ['extensions', 'apps']
    resources: ['daemonsets', 'deployments', 'replicasets', 'statefulsets']
    verbs: ['list', 'watch']
  - apiGroups: ['batch']
    resources: ['jobs', 'cronjobs']
    verbs: ['list', 'watch']
  - apiGroups: ['autoscaling']
    resources: ['horizontalpodautoscalers']
    verbs: ['list', 'watch']
  - apiGroups: ['policy']
    resources: ['poddisruptionbudgets']
    verbs: ['list', 'watch']
  - apiGroups: ['storage.k8s.io']
    resources: ['storageclasses', 'volumeattachments']
    verbs: ['list', 'watch']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
  - kind: ServiceAccount
    name: kube-state-metrics
    namespace: monitoring
EOF
```

### Step 3: Deploy kube-state-metrics

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-state-metrics
  template:
    metadata:
      labels:
        app: kube-state-metrics
    spec:
      serviceAccountName: kube-state-metrics
      containers:
        - name: kube-state-metrics
          image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.12.0
          args:
            - '--port=8080'
            - '--telemetry-port=8081'
          ports:
            - containerPort: 8080
              name: metrics
            - containerPort: 8081
              name: telemetry
          resources:
            limits:
              memory: 256Mi
              cpu: 200m
            requests:
              memory: 128Mi
              cpu: 100m
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            timeoutSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
spec:
  clusterIP: None
  ports:
    - port: 8080
      targetPort: 8080
      name: metrics
    - port: 8081
      targetPort: 8081
      name: telemetry
  selector:
    app: kube-state-metrics
EOF
```

### Step 4: Verify Deployment

```bash
kubectl get pods -n monitoring -l app=kube-state-metrics
kubectl port-forward -n monitoring svc/kube-state-metrics 8080:8080
curl http://localhost:8080/metrics | head -20
```

### Step 5: Configure Prometheus to Scrape

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']
```

### Step 6: Test Queries

```promql
# Deployment availability
kube_deployment_status_replicas_available

# Pod phases
kube_pod_status_phase

# Node conditions
kube_node_status_condition

# PVC status
kube_persistentvolumeclaim_status_phase
```

### Step 7: Create Alert Rules

```yaml
groups:
  - name: kubernetes
    rules:
      - alert: DeploymentReplicasMismatch
        expr: kube_deployment_status_replicas_available != kube_deployment_spec_replicas
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Deployment {{ $labels.deployment }} replica mismatch"

      - alert: PodNotReady
        expr: kube_pod_status_ready{condition="true"} == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} not ready"

      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.node }} not ready"
```

---

## 9. Custom Resource Metrics

### Defining Custom Metrics

```go
// pkg/custom/collector.go
package custom

import (
    "github.com/prometheus/client_golang/prometheus"
    "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
    "k8s.io/kube-state-metrics/pkg/metric"
)

type CustomCollector struct {
}

func (c *CustomCollector) Describe(store *metricstore.MetricStore) {
    store.AddDescendants(
        &prometheus.Desc{
            Name: "myapp_status_ready",
            Help: "MyApp ready status",
            ConstLabels: prometheus.Labels{
                "namespace": "default",
                "name": "myapp",
            },
        },
    )
}

func (c *CustomCollector) Collect(store *metricstore.MetricStore, u *unstructured.Unstructured) {
    name := u.GetName()
    namespace := u.GetNamespace()
    
    ready, _, _ := unstructured.NestedBool(u.Object, "status", "ready")
    
    store.Add(&prometheus.Desc{
        Name: "myapp_status_ready",
        Help: "MyApp ready status",
        ConstLabels: prometheus.Labels{
            "namespace": namespace,
            "name": name,
        },
    }, prometheus.GaugeValue, boolToFloat64(ready))
}
```

### CRD Metrics Example

```yaml
# Custom Resource Definition
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myapps.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
  scope: Namespaced
  names:
    plural: myapps
    singular: myapp
    kind: MyApp

# Custom Resource
apiVersion: example.com/v1
kind: MyApp
metadata:
  name: my-app
  namespace: default
spec:
  replicas: 3
status:
  ready: true
  currentVersion: "1.0.0"
```

### Enabling Custom Metrics

```bash
kube-state-metrics \
  --custom-resource-state-enabled=true \
  --custom-resource-state-config=/etc/kube-state-metrics/custom-resource-state.yaml
```

---

## 10. Native Histograms

### What Are Native Histograms

Native histograms are a Prometheus feature that stores histogram data more efficiently. KSM supports generating native histogram metrics for certain resources.

### Enabling Native Histograms

```bash
kube-state-metrics \
  --metric-object-counts=true \
  --native-histograms=true
```

### Metrics Affected

Native histograms can be enabled for:
- `kube_pod_container_resource_requests`
- `kube_pod_container_resource_limits`
- `kube_node_status_capacity`
- `kube_node_status_allocatable`

---

## 11. Helm Deployment

### Install via Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring \
  --create-namespace \
  --set replicas=2 \
  --set resources.limits.memory=256Mi \
  --set resources.limits.cpu=200m \
  --set resources.requests.memory=128Mi \
  --set resources.requests.cpu=100m
```

### Custom Helm Values

```yaml
# values.yaml
replicaCount: 2

image:
  repository: registry.k8s.io/kube-state-metrics/kube-state-metrics
  tag: v2.12.0

resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m

# Metric generation
metricLabelsAllowlist:
  - pods=[app,version,env]
  - deployments=[app,version]
  - nodes=[kubernetes.io/os,kubernetes.io/arch]

metricAnnotationsAllowlist:
  - pods=[app]

# Namespace filtering
namespaces: ""

# Resource filtering
resources:
  - pods
  - deployments
  - nodes
  - services
  - configmaps
  - secrets
  - namespaces
  - persistentvolumeclaims
  - jobs
  - cronjobs
  - daemonsets
  - statefulsets
  - horizontalpodautoscalers
  - poddisruptionbudgets

# Telemetry
telemetryPort: 8081
```

### Upgrade Helm Release

```bash
helm upgrade kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring \
  --reuse-values \
  --set replicas=2
```

---

## 12. Integrations

### Prometheus

```yaml
scrape_configs:
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']
    scrape_interval: 30s
```

### Prometheus Operator (ServiceMonitor)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: kube-state-metrics
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

### Grafana

```yaml
# Import community dashboard
# Dashboard ID: 315 (kube-state-metrics full)
# Dashboard ID: 13770 (kube-state-metrics for k8s)
```

### Alertmanager

```yaml
# Alert rules using KSM metrics
groups:
  - name: kubernetes
    rules:
      - alert: DeploymentReplicasMismatch
        expr: kube_deployment_status_replicas_available != kube_deployment_spec_replicas
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Deployment {{ $labels.deployment }} replica mismatch"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} crash looping"

      - alert: PersistentVolumeClaimPending
        expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "PVC {{ $labels.persistentvolumeclaim }} pending"
```

---

## 13. Security

### RBAC Configuration

```yaml
# Minimum required permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
  - apiGroups: [""]
    resources: ['nodes', 'pods', 'services', 'resourcequotas', 'replicationcontrollers', 'limitranges', 'persistentvolumeclaims', 'namespaces', 'configmaps']
    verbs: ['list', 'watch']
  - apiGroups: ['extensions', 'apps']
    resources: ['daemonsets', 'deployments', 'replicasets', 'statefulsets']
    verbs: ['list', 'watch']
  - apiGroups: ['batch']
    resources: ['jobs', 'cronjobs']
    verbs: ['list', 'watch']
  - apiGroups: ['autoscaling']
    resources: ['horizontalpodautoscalers']
    verbs: ['list', 'watch']
  - apiGroups: ['policy']
    resources: ['poddisruptionbudgets']
    verbs: ['list', 'watch']
  - apiGroups: ['storage.k8s.io']
    resources: ['storageclasses', 'volumeattachments']
    verbs: ['list', 'watch']
```

### Network Security

```yaml
# Network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kube-state-metrics
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: kube-state-metrics
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to: []
      ports:
        - protocol: TCP
          port: 443  # Kubernetes API
```

### Security Context

```yaml
containers:
  - name: kube-state-metrics
    securityContext:
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 65534
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
```

### TLS

```bash
# Enable TLS for metrics endpoint
kube-state-metrics \
  --tls-cert-file=/etc/tls/tls.crt \
  --tls-private-key-file=/etc/tls/tls.key
```

---

## 14. Performance Tuning

### Reduce Resource Usage

```bash
# Only monitor needed resources
kube-state-metrics --resources=pods,deployments,nodes

# Only monitor specific namespaces
kube-state-metrics --namespaces="default,production"
```

### Increase Scrape Interval

```yaml
scrape_configs:
  - job_name: 'kube-state-metrics'
    scrape_interval: 30s  # Default is 15s
```

### Use Metric Relabeling to Drop Metrics

```yaml
scrape_configs:
  - job_name: 'kube-state-metrics'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'kube_pod_container_resource_requests_memory_bytes'
        action: drop
```

### Resource Limits

```yaml
resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m
```

### High Availability

```yaml
# Deploy two replicas
replicas: 2

# Prometheus configuration
scrape_configs:
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets:
          - kube-state-metrics-0.monitoring:8080
          - kube-state-metrics-1.monitoring:8080
    honor_labels: true
```

---

## 15. Troubleshooting

### Issue 1: KSM Pod Not Starting

**Symptoms**: Pod in CrashLoopBackOff

**Diagnosis**:
```bash
kubectl logs -n monitoring kube-state-metrics-xxx
kubectl describe pod -n monitoring kube-state-metrics-xxx
```

**Resolution**: Check RBAC permissions, verify image exists, check resource limits, ensure API server is reachable.

### Issue 2: No Metrics Appearing

**Symptoms**: `curl http://localhost:8080/metrics` returns empty

**Diagnosis**:
```bash
kubectl port-forward -n monitoring svc/kube-state-metrics 8080:8080
curl http://localhost:8080/metrics
```

**Resolution**: Check KSM logs, verify RBAC permissions, ensure API server is accessible, check resource filtering.

### Issue 3: Missing Specific Metrics

**Symptoms**: Expected metrics not in `/metrics`

**Diagnosis**:
```bash
curl http://localhost:8080/metrics | grep kube_pod
```

**Resolution**: Check if resource is enabled, verify namespace filtering, check if object exists in the cluster.

### Issue 4: High Memory Usage

**Symptoms**: KSM consuming excessive RAM

**Diagnosis**:
```bash
kubectl top pod -n monitoring kube-state-metrics-xxx
curl http://localhost:8080/metrics | grep process_resident_memory_bytes
```

**Resolution**: Reduce resource filtering, limit namespaces, increase memory limits.

### Issue 5: Prometheus Cannot Scrape

**Symptoms**: Target shows DOWN in Prometheus

**Diagnosis**:
```bash
curl http://kube-state-metrics.monitoring:8080/metrics
# Check from Prometheus pod
kubectl exec -it prometheus-xxx -- curl http://kube-state-metrics.monitoring:8080/metrics
```

**Resolution**: Check network policies, verify service DNS, ensure port is correct, check RBAC.

### Issue 6: Metrics Have Labels Blocked

**Symptoms**: Custom labels not appearing in metrics

**Diagnosis**:
```bash
curl http://localhost:8080/metrics | grep 'app='
```

**Resolution**: Add labels to `--metric-labels-allowlist`, verify label names are correct.

### Issue 7: KSM High CPU Usage

**Symptoms**: KSM consuming excessive CPU

**Diagnosis**:
```bash
kubectl top pod -n monitoring kube-state-metrics-xxx
```

**Resolution**: Reduce resource filtering, limit namespaces, check for API server latency.

### Issue 8: RBAC Errors

**Symptoms**: Logs show "forbidden" errors

**Diagnosis**:
```bash
kubectl logs -n monitoring kube-state-metrics-xxx | grep forbidden
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:kube-state-metrics
```

**Resolution**: Add missing resources to ClusterRole, verify service account is correct.

### Issue 9: Duplicate Metrics

**Symptoms**: Prometheus shows duplicate time series

**Diagnosis**:
```bash
curl http://kube-state-metrics-0:8080/metrics | grep kube_pod
curl http://kube-state-metrics-1:8080/metrics | grep kube_pod
```

**Resolution**: Set `honor_labels: true` in Prometheus scrape config.

### Issue 10: Slow Metric Generation

**Symptoms**: Scrape duration exceeding timeout

**Diagnosis**:
```bash
curl http://localhost:8080/metrics | grep scrape_duration_seconds
```

**Resolution**: Reduce number of resources, limit namespaces, increase scrape timeout.

### Issue 11: Missing Custom Resource Metrics

**Symptoms**: CRD metrics not appearing

**Diagnosis**:
```bash
curl http://localhost:8080/metrics | grep myapp
```

**Resolution**: Verify custom resource state is enabled, check CRD definition, verify RBAC.

### Issue 12: KSM Pod Evicted

**Symptoms**: Pod evicted due to OOMKilled

**Diagnosis**:
```bash
kubectl describe pod -n monitoring kube-state-metrics-xxx | grep -A5 "Last State"
```

**Resolution**: Increase memory limits, reduce resource filtering.

### Issue 13: Metrics Not Reflecting Current State

**Symptoms**: Metrics show stale data

**Diagnosis**:
```bash
# Check last scrape time
curl http://localhost:8080/metrics | grep process_start_time_seconds
```

 **Resolution**: Verify API server connectivity, check for watch errors in logs.

### Issue 14: Namespace Filtering Not Working

**Symptoms**: Metrics from excluded namespaces appearing

**Diagnosis**:
```bash
curl http://localhost:8080/metrics | grep namespace
```

**Resolution**: Verify `--namespaces` flag, check for typos, ensure exact namespace names.

### Issue 15: Telemetry Port Not Accessible

**Symptoms**: Cannot access port 8081

**Diagnosis**:
```bash
kubectl port-forward -n monitoring svc/kube-state-metrics 8081:8081
curl http://localhost:8081/metrics
```

**Resolution**: Check service exposes telemetry port, verify firewall rules.

---

## 16. Tips and Best Practices

### 1. Deploy Two Replicas for HA

```yaml
replicas: 2
```

### 2. Use Resource Filtering

Only monitor resources you need:
```bash
--resources=pods,deployments,nodes
```

### 3. Limit Namespaces

Only monitor namespaces you care about:
```bash
--namespaces="default,production"
```

### 4. Use Metric Labels Allowlist

Include only labels you need for dashboards and alerts:
```bash
--metric-labels-allowlist=pods=[app,version],deployments=[app]
```

### 5. Set Resource Limits

Always set memory and CPU limits to prevent resource exhaustion.

### 6. Use Recording Rules for Expensive Queries

Precompute frequently used aggregations in Prometheus.

### 7. Monitor KSM Itself

Track `process_*` metrics and telemetry metrics.

### 8. Use Consistent Labeling

Standardize labels across all Kubernetes objects.

### 9. Use Prometheus Operator ServiceMonitor

Automates Prometheus configuration for KSM.

### 10. Use Native Histograms for Resource Metrics

More efficient storage for resource request/limit metrics.

### 11. Use Custom Resource State for CRDs

Extend KSM to monitor your custom resources.

### 12. Use Grafana Dashboards

Import community dashboards for quick visualization.

### 13. Use Alert Rules for Common Issues

Alert on deployment mismatches, pod crashes, and node issues.

### 14. Keep KSM Updated

Regularly update to the latest version for bug fixes and new features.

### 15. Use Pod Disruption Budgets

Ensure KSM remains available during cluster maintenance.

### 16. Document Custom Metrics

Document any custom resource metrics you add.

---

## 17. Command Reference

### kube-state-metrics

```bash
kube-state-metrics \
  --port=8080 \
  --telemetry-port=8081 \
  --metric-labels-allowlist=pods=[app,version],deployments=[app] \
  --metric-annotations-allowlist=pods=[app] \
  --namespaces="default,kube-system" \
  --resources=pods,deployments,nodes \
  --metric-optimizer-level=1 \
  --enable-gzip-encoding \
  --tls-cert-file=/etc/tls/tls.crt \
  --tls-private-key-file=/etc/tls/tls.key \
  --custom-resource-state-enabled=true \
  --custom-resource-state-config=/etc/kube-state-metrics/custom-resource-state.yaml \
  --log-level=info \
  --help
```

### Useful Commands

```bash
# Check version
kube-state-metrics --version

# Test metrics endpoint
curl http://localhost:8080/metrics

# Check health
curl http://localhost:8080/healthz

# Check telemetry
curl http://localhost:8081/metrics

# Count metrics
curl http://localhost:8080/metrics | grep -v '^#' | grep -v '^$' | wc -l
```

### Common Queries

```promql
# Deployment availability
kube_deployment_status_replicas_available

# Pod phases
kube_pod_status_phase

# Node conditions
kube_node_status_condition

# PVC status
kube_persistentvolumeclaim_status_phase

# Job completion
kube_job_status_succeeded

# CronJob schedule
kube_cronjob_next_schedule_time

# HPA scaling
kube_hpa_status_current_replicas

# Resource quotas
kube_resourcequota
```

---

## 18. Configuration Reference

### Command-Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--port` | `8080` | Metrics port |
| `--telemetry-port` | `8081` | Telemetry port |
| `--metric-labels-allowlist` | | Labels to include |
| `--metric-annotations-allowlist` | | Annotations to include |
| `--namespaces` | | Namespace filter |
| `--resources` | | Resource filter |
| `--metric-optimizer-level` | `1` | Metric optimization |
| `--enable-gzip-encoding` | `false` | Enable gzip |
| `--tls-cert-file` | | TLS certificate |
| `--tls-private-key-file` | | TLS private key |
| `--custom-resource-state-enabled` | `false` | Enable CRD metrics |
| `--custom-resource-state-config` | | CRD config file |
| `--log-level` | `info` | Log level |

### Helm Values

| Value | Default | Description |
|-------|---------|-------------|
| `replicaCount` | `1` | Number of replicas |
| `image.repository` | `registry.k8s.io/kube-state-metrics/kube-state-metrics` | Image repository |
| `image.tag` | `v2.12.0` | Image tag |
| `resources.limits.memory` | `256Mi` | Memory limit |
| `resources.limits.cpu` | `200m` | CPU limit |
| `resources.requests.memory` | `128Mi` | Memory request |
| `resources.requests.cpu` | `100m` | CPU request |
| `metricLabelsAllowlist` | `[]` | Labels to include |
| `metricAnnotationsAllowlist` | `[]` | Annotations to include |
| `namespaces` | `""` | Namespace filter |
| `resources` | `[]` | Resource filter |

### RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
rules:
  - apiGroups: [""]
    resources: ['nodes', 'pods', 'services', 'resourcequotas', 'replicationcontrollers', 'limitranges', 'persistentvolumeclaims', 'namespaces', 'configmaps']
    verbs: ['list', 'watch']
  - apiGroups: ['extensions', 'apps']
    resources: ['daemonsets', 'deployments', 'replicasets', 'statefulsets']
    verbs: ['list', 'watch']
  - apiGroups: ['batch']
    resources: ['jobs', 'cronjobs']
    verbs: ['list', 'watch']
  - apiGroups: ['autoscaling']
    resources: ['horizontalpodautoscalers']
    verbs: ['list', 'watch']
  - apiGroups: ['policy']
    resources: ['poddisruptionbudgets']
    verbs: ['list', 'watch']
  - apiGroups: ['storage.k8s.io']
    resources: ['storageclasses', 'volumeattachments']
    verbs: ['list', 'watch']
```

---

## 19. Real-World Examples

### Example 1: Complete KSM Deployment with Helm

```bash
helm install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring \
  --create-namespace \
  --set replicaCount=2 \
  --set resources.limits.memory=256Mi \
  --set resources.limits.cpu=200m \
  --set resources.requests.memory=128Mi \
  --set resources.requests.cpu=100m \
  --set metricLabelsAllowlist[0]="pods=[app,version,env]" \
  --set metricLabelsAllowlist[1]="deployments=[app,version]" \
  --set metricAnnotationsAllowlist[0]="pods=[app]"
```

### Example 2: Alert Rules for Kubernetes

```yaml
# /etc/prometheus/rules/kubernetes.rules.yml
groups:
  - name: kubernetes
    rules:
      - alert: DeploymentReplicasMismatch
        expr: kube_deployment_status_replicas_available != kube_deployment_spec_replicas
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Deployment {{ $labels.deployment }} replica mismatch"
          description: "Deployment {{ $labels.deployment }} has {{ $value }} available replicas but {{ $labels.deployment_spec_replicas }} desired"

      - alert: PodNotReady
        expr: kube_pod_status_ready{condition="true"} == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} not ready"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} crash looping"

      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.node }} not ready"

      - alert: PersistentVolumeClaimPending
        expr: kube_persistentvolumeclaim_status_phase{phase="Pending"} == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "PVC {{ $labels.persistentvolumeclaim }} pending"

      - alert: JobFailed
        expr: kube_job_status_failed > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Job {{ $labels.job }} failed"
```

### Example 3: Recording Rules

```yaml
# /etc/prometheus/rules/kube_recording.yml
groups:
  - name: kube_recording
    interval: 30s
    rules:
      - record: namespace:pod_count:sum
        expr: count by (namespace) (kube_pod_info)

      - record: namespace:deployment_replicas:sum
        expr: sum by (namespace) (kube_deployment_status_replicas)

      - record: namespace:deployment_available_replicas:sum
        expr: sum by (namespace) (kube_deployment_status_replicas_available)

      - record: namespace:pvc_count:sum
        expr: count by (namespace) (kube_persistentvolumeclaim_info)

      - record: node:pods_running:sum
        expr: count by (node) (kube_pod_info{phase="Running"})
```

### Example 4: Grafana Dashboard Variables

```json
{
  "templating": {
    "list": [
      {
        "name": "namespace",
        "type": "query",
        "query": "label_values(kube_pod_info, namespace)",
        "refresh": 2,
        "sort": 1,
        "includeAll": true,
        "allValue": ".*"
      },
      {
        "name": "deployment",
        "type": "query",
        "query": "label_values(kube_deployment_status_replicas{namespace=~\"$namespace\"}, deployment)",
        "refresh": 2,
        "sort": 1,
        "includeAll": true,
        "allValue": ".*"
      },
      {
        "name": "node",
        "type": "query",
        "query": "label_values(kube_pod_info{namespace=~\"$namespace\"}, node)",
        "refresh": 2,
        "sort": 1,
        "includeAll": true,
        "allValue": ".*"
      }
    ]
  }
}
```

### Example 5: Custom Resource State Configuration

```yaml
# /etc/kube-state-metrics/custom-resource-state.yaml
kind: CustomResourceStateMetrics
resources:
  - groupVersionKind:
      group: "example.com"
      version: "v1"
      kind: "MyApp"
    metrics:
      - name: "ready"
        help: "MyApp ready status"
        each:
          type: Gauge
          gauge:
            path: ["status", "ready"]
            labels:
              - key: "name"
                path: ["metadata", "name"]
              - key: "namespace"
                path: ["metadata", "namespace"]
      - name: "replicas"
        help: "MyApp replica count"
        each:
          type: Gauge
          gauge:
            path: ["spec", "replicas"]
            labels:
              - key: "name"
                path: ["metadata", "name"]
              - key: "namespace"
                path: ["metadata", "namespace"]
```

---

## 20. Further Reading

### Official Documentation

- [kube-state-metrics GitHub](https://github.com/kubernetes/kube-state-metrics)
- [kube-state-metrics Documentation](https://github.com/kubernetes/kube-state-metrics#readme)
- [kube-state-metrics Releases](https://github.com/kubernetes/kube-state-metrics/releases)
- [Prometheus Kubernetes Monitoring](https://prometheus.io/docs/guides/container-monitoring/)

### Community Resources

- [kube-state-metrics Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)
- [Grafana kube-state-metrics Dashboards](https://grafana.com/grafana/dashboards/?search=kube-state-metrics)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [Kubernetes Monitoring Guide](https://awesome-kubernetes.com/monitoring)

### Books

- *Kubernetes in Action* by Marko Lukša
- *Prometheus: Up & Running* by Brian Brazil
- *Site Reliability Engineering* by Google
- *Monitoring Kubernetes* by James Turnbull

### Related Tools

- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) - Resource usage metrics
- [Prometheus](https://prometheus.io/) - Metrics collection and storage
- [Grafana](https://grafana.com/) - Dashboard visualization
- [cAdvisor](https://github.com/google/cadvisor) - Container metrics
- [Node Exporter](https://github.com/prometheus/node_exporter) - Node-level metrics
- [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) - Node agent
