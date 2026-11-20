# Kiali Complete Guide

## Table of Contents

1. [What Is Kiali](#1-what-is-kiali)
2. [Why Use Kiali](#2-why-use-kiali)
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

## 1. What Is Kiali

Kiali is an observability console for Istio service mesh. It provides a visual representation of the mesh topology, metrics, health, and configuration.

### Key Characteristics

- **Service Mesh Visualization**: Topology maps and dependency graphs
- **Health Monitoring**: Real-time health status and alerts
- **Metrics Dashboard**: Traffic, latency, and error metrics
- **Configuration Management**: Istio configuration validation
- **Distributed Tracing**: Jaeger integration for request tracing

### How It Works

```
┌─────────────────────────────────────────────────┐
│                 Kiali Architecture               │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Kiali Server                       ││
│  │  - Web UI                                      ││
│  │  - REST API                                    ││
│  │  - Business logic                              ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Data Sources                        ││
│  │  - Kubernetes API                              ││
│  │  - Istio API                                   ││
│  │  - Prometheus                                  ││
│  │  - Jaeger                                      ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Visualization                       ││
│  │  - Topology graph                              ││
│  │  - Health dashboard                            ││
│  │  - Metrics charts                              ││
│  │  - Configuration views                         ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

---

## 2. Why Use Kiali

### Problems Kiali Solves

| Problem | Kiali Solution |
|---------|----------------|
| Complex mesh topology | Visual topology maps |
| Service health monitoring | Real-time health status |
| Traffic debugging | Traffic flow visualization |
| Configuration validation | Istio config validation |
| Performance monitoring | Metrics dashboard |

### Kiali vs Other Observability Tools

| Feature | Kiali | Jaeger | Prometheus | Grafana |
|---------|-------|--------|------------|---------|
| Topology visualization | Yes | No | No | No |
| Health monitoring | Yes | No | No | Limited |
| Metrics dashboard | Yes | No | Yes | Yes |
| Configuration validation | Yes | No | No | No |
| Distributed tracing | Yes | Yes | No | No |
| Istio integration | Yes | Limited | Limited | Limited |

### When to Use Kiali

- When visualizing Istio service mesh
- When monitoring service health
- When debugging traffic issues
- When validating Istio configuration
- When viewing metrics and traces

---

## 3. Architecture Overview

### Components

```
┌─────────────────────────────────────────────────┐
│                Kiali Architecture                │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Kiali Server                        ││
│  │  - Web UI (React)                              ││
│  │  - REST API (Go)                               ││
│  │  - Business logic                              ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Kubernetes Client                   ││
│  │  - Service discovery                           ││
│  │  - Pod information                             ││
│  │  - Configuration                               ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Istio Client                        ││
│  │  - VirtualService                              ││
│  │  - DestinationRule                             ││
│  │  - Gateway                                     ││
│  │  - ServiceEntry                                ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Prometheus Client                   ││
│  │  - Metrics queries                            ││
│  │  - Health calculations                        ││
│  │  - Traffic analysis                           ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Jaeger Client                       ││
│  │  - Trace queries                              ││
│  │  - Span analysis                              ││
│  │  - Performance debugging                      ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Data Flow

1. **Data Collection**: Kiali collects data from Kubernetes, Istio, and Prometheus
2. **Processing**: Business logic processes and analyzes data
3. **Visualization**: Web UI displays topology, health, and metrics
4. **User Interaction**: Users explore and debug the mesh

---

## 4. Installation

### Method 1: Kiali Operator

```bash
# Install Kiali Operator
kubectl apply -f https://raw.githubusercontent.com/kiali/kiali-operator/master/deploy/kiali/kiali_cr.yaml

# Install Kiali
kubectl apply -f https://raw.githubusercontent.com/kiali/kiali-operator/master/deploy/kiali/kiali_cr.yaml
```

### Method 2: Helm

```bash
# Add Helm repo
helm repo add kiali https://kiali.org/helm-charts
helm repo update

# Install Kiali
helm install kiali kiali/kiali \
  --namespace istio-system \
  --set auth.strategy="anonymous" \
  --set external_services.prometheus.url="http://prometheus.monitoring:9090" \
  --set external_services.tracing.url="http://jaeger.istio-system:16686"
```

### Method 3: Quick Start

```bash
# Install Kiali
kubectl apply -f https://raw.githubusercontent.com/kiali/kiali-operator/master/deploy/kiali/kiali_cr.yaml

# Verify installation
kubectl -n istio-system get pods -l app=kiali

# Access Kiali UI
kubectl -n istio-system port-forward svc/kiali 20001:20001
```

### Post-Installation Verification

```bash
# Check Kiali pod
kubectl -n istio-system get pods -l app=kiali

# Expected output:
# kiali-xxxxx    Running

# Check Kiali service
kubectl -n istio-system get svc kiali

# Access Kiali UI
# http://localhost:20001
```

### Ingress Configuration

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kiali-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - kiali.example.com
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali
  namespace: istio-system
spec:
  hosts:
  - kiali.example.com
  gateways:
  - kiali-gateway
  http:
  - route:
    - destination:
        host: kiali
        port:
          number: 20001
```

---

## 5. Configuration

### Kiali Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kiali
  namespace: istio-system
data:
  config.yaml: |
    server:
      port: 20001
      web_root: /
    auth:
      strategy: anonymous
    external_services:
      prometheus:
        url: http://prometheus.monitoring:9090
        custom_headers:
          X-Scope-OrgID: "istio-system"
      jaeger:
        url: http://jaeger.istio-system:16686
      grafana:
        url: http://grafana.monitoring:3000
      custom_metrics_dashboard:
        name: Istio Mesh Dashboard
        namespace: istio-system
    kubernetes_config:
      cluster_name: my-cluster
      qps: 100
      burst: 200
      cache_enabled: true
      cache_duration: 30s
      cache_token_bucket_capacity: 1000
      cache_token_refill_rate: 100
    api:
      namespaces:
        label_selector: kubernetes.io/metadata.name
      conf_map_name: kiali
      dry_run: false
      log_level: info
      metrics:
        enabled: true
        port: 9090
```

### Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kiali
  namespace: istio-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kiali
  template:
    metadata:
      labels:
        app: kiali
    spec:
      containers:
      - name: kiali
        image: quay.io/kiali/kiali:v1.75
        args:
        - -config
        - /kiali-configuration/config.yaml
        ports:
        - containerPort: 20001
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: ACTIVE_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: LOG_LEVEL
          value: info
        volumeMounts:
        - name: config
          mountPath: /kiali-configuration
      volumes:
      - name: config
        configMap:
          name: kiali
```

---

## 6. Core Concepts

### Topology Graph

Kiali provides a visual representation of the service mesh topology:

- **Nodes**: Services, workloads, and applications
- **Edges**: Traffic flow between nodes
- **Health**: Color-coded health status
- **Metrics**: Traffic, latency, and error rates

### Health Status

- **Healthy**: Green - Service is operating normally
- **Degraded**: Yellow - Service has some issues
- **Failure**: Red - Service is failing
- **Unknown**: Gray - Unable to determine health

### Metrics

- **Request Rate**: Requests per second
- **Response Time**: Latency percentiles
- **Error Rate**: Percentage of errors
- **Traffic Distribution**: Traffic split between versions

### Configuration Validation

- **VirtualService**: Validates routing rules
- **DestinationRule**: Validates traffic policies
- **Gateway**: Validates ingress configuration
- **ServiceEntry**: Validates external service configuration

---

## 7. Usage Guide

### Step-by-Step: View Topology

#### 1. Access Kiali UI

```bash
kubectl -n istio-system port-forward svc/kiali 20001:20001
# http://localhost:20001
```

#### 2. Navigate to Graph

- Click "Graph" in the left menu
- Select namespace from dropdown
- View topology graph

#### 3. Explore Topology

- **Zoom**: Mouse wheel
- **Pan**: Click and drag
- **Select**: Click on node
- **Details**: Double-click on node

#### 4. View Metrics

- Click on node to select
- Click "Metrics" tab
- View traffic, latency, and error metrics

### Step-by-Step: Check Health

#### 1. Navigate to Health

- Click "Health" in the left menu
- Select namespace from dropdown
- View health status

#### 2. Explore Health

- **Services**: Health of all services
- **Workloads**: Health of all workloads
- **Applications**: Health of all applications

#### 3. View Details

- Click on item to select
- View health details
- View metrics and logs

### Step-by-Step: Validate Configuration

#### 1. Navigate to Istio Config

- Click "Istio Config" in the left menu
- Select namespace from dropdown
- View configuration

#### 2. Check Validation

- View validation status
- Click on item to see details
- Fix configuration issues

#### 3. View Configuration

- View VirtualService
- View DestinationRule
- View Gateway
- View ServiceEntry

### Step-by-Step: View Traces

#### 1. Navigate to Traces

- Click "Distributed Tracing" in the left menu
- Select namespace from dropdown
- View traces

#### 2. Explore Traces

- Select trace from list
- View trace details
- View spans

#### 3. Analyze Performance

- View latency breakdown
- Identify bottlenecks
- Debug performance issues

---

## 8. Custom Configuration

### Custom Health Configuration

```yaml
# Custom health configuration
data:
  config.yaml: |
    health_config:
      rate:
        - namespace: default
          tolerance: 1.0
        - namespace: production
          tolerance: 0.5
      ratio:
        - namespace: default
          tolerance: 1.0
        - namespace: production
          tolerance: 0.5
```

### Custom Metrics Configuration

```yaml
# Custom metrics configuration
data:
  config.yaml: |
    metrics:
      enabled: true
      port: 9090
      path: /metrics
    custom_metrics:
      - name: my_custom_metric
        type: counter
        labels:
          - namespace
          - service
```

### Custom Dashboard Configuration

```yaml
# Custom dashboard configuration
data:
  config.yaml: |
    custom_metrics_dashboard:
      name: My Custom Dashboard
      namespace: istio-system
      interval: 30s
```

### Custom API Configuration

```yaml
# Custom API configuration
data:
  config.yaml: |
    api:
      namespaces:
        label_selector: kubernetes.io/metadata.name
      conf_map_name: kiali
      dry_run: false
      log_level: info
      metrics:
        enabled: true
        port: 9090
      cache:
        enabled: true
        duration: 30s
        token_bucket_capacity: 1000
        token_refill_rate: 100
```

---

## 9. Integration

### ArgoCD Integration

```yaml
# Application with Kiali
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kiali
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kiali/kiali-operator
    path: deploy/kiali
    targetRevision: master
  destination:
    server: https://kubernetes.default.svc
    namespace: istio-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Prometheus Integration

```yaml
# ServiceMonitor for Kiali
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kiali
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: kiali
  endpoints:
  - port: metrics
    interval: 30s
```

### Jaeger Integration

```yaml
# Kiali configuration for Jaeger
data:
  config.yaml: |
    external_services:
      jaeger:
        url: http://jaeger.istio-system:16686
        service: jaeger-query
        service_port: 16686
```

### Grafana Integration

```yaml
# Kiali configuration for Grafana
data:
  config.yaml: |
    external_services:
      grafana:
        url: http://grafana.monitoring:3000
        service: grafana
        service_port: 3000
```

---

## 10. Security

### RBAC Configuration

```yaml
# Role for Kiali
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kiali
  namespace: istio-system
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets", "pods", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.istio.io"]
  resources: ["virtualservices", "destinationrules", "gateways", "serviceentries"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["security.istio.io"]
  resources: ["peerauthentications", "authorizationpolicies", "requestauthentications"]
  verbs: ["get", "list", "watch"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kiali-network-policy
  namespace: istio-system
spec:
  podSelector:
    matchLabels:
      app: kiali
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-system
    ports:
    - protocol: TCP
      port: 20001
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 6443
```

### TLS Configuration

```yaml
# TLS for Kiali
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kiali
  namespace: istio-system
spec:
  template:
    spec:
      containers:
      - name: kiali
        args:
        - -config
        - /kiali-configuration/config.yaml
        env:
        - name: SERVER_CERT_FILE
          value: /kiali-cert/tls.crt
        - name: SERVER_KEY_FILE
          value: /kiali-cert/tls.key
        volumeMounts:
        - name: cert
          mountPath: /kiali-cert
      volumes:
      - name: cert
        secret:
          secretName: kiali-cert
```

---

## 11. Troubleshooting

### Issue 1: Kiali Not Starting

```bash
# Check Kiali pod
kubectl -n istio-system get pods -l app=kiali

# Check Kiali logs
kubectl -n istio-system logs -l app=kiali

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Restart Kiali
kubectl -n istio-system rollout restart deployment/kiali
```

### Issue 2: Kiali Cannot Connect to Prometheus

```bash
# Check Prometheus service
kubectl -n monitoring get svc prometheus

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Test Prometheus connection
kubectl -n istio-system exec -it kiali-xxxxx -- curl http://prometheus.monitoring:9090/api/v1/status/runtimeinfo

# Fix Kiali config
kubectl -n istio-system edit configmap kiali
```

### Issue 3: Kiali Cannot Connect to Jaeger

```bash
# Check Jaeger service
kubectl -n istio-system get svc jaeger

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Test Jaeger connection
kubectl -n istio-system exec -it kiali-xxxxx -- curl http://jaeger.istio-system:16686/api/services

# Fix Kiali config
kubectl -n istio-system edit configmap kiali
```

### Issue 4: Kiali UI Not Accessible

```bash
# Check Kiali service
kubectl -n istio-system get svc kiali

# Check Kiali pods
kubectl -n istio-system get pods -l app=kiali

# Port-forward Kiali
kubectl -n istio-system port-forward svc/kiali 20001:20001

# Access Kiali UI
# http://localhost:20001
```

### Issue 5: Kiali Shows No Data

```bash
# Check Istio installation
istioctl verify-install

# Check sidecar injection
kubectl get namespace -L istio-injection

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Restart Kiali
kubectl -n istio-system rollout restart deployment/kiali
```

### Issue 6: Kiali Topology Not Showing

```bash
# Check Kiali logs
kubectl -n istio-system logs -l app=kiali

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Check Istio metrics
curl http://localhost:9090/api/v1/query?query=istio_requests_total

# Restart Kiali
kubectl -n istio-system rollout restart deployment/kiali
```

### Issue 7: Kiali Health Not Working

```bash
# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Check health metrics
curl http://localhost:9090/api/v1/query?query=istio_requests_total

# Fix Kiali config
kubectl -n istio-system edit configmap kiali
```

### Issue 8: Kiali Metrics Not Showing

```bash
# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Check Istio metrics
curl http://localhost:9090/api/v1/query?query=istio_requests_total

# Fix Kiali config
kubectl -n istio-system edit configmap kiali
```

### Issue 9: Kiali Traces Not Showing

```bash
# Check Jaeger service
kubectl -n istio-system get svc jaeger

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Test Jaeger connection
kubectl -n istio-system exec -it kiali-xxxxx -- curl http://jaeger.istio-system:16686/api/services

# Fix Kiali config
kubectl -n istio-system edit configmap kiali
```

### Issue 10: Kiali Authentication Failed

```bash
# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Check authentication strategy
kubectl -n istio-system get configmap kiali -o jsonpath='{.data.config\.yaml}' | grep -A 5 auth

# Fix authentication
kubectl -n istio-system edit configmap kiali
```

### Issue 11: Kiali RBAC Denied

```bash
# Check Kiali service account
kubectl -n istio-system get sa kiali

# Check RBAC
kubectl get clusterrolebinding | grep kiali

# Fix RBAC
kubectl apply -f kiali-rbac.yaml
```

### Issue 12: Kiali Performance Issues

```bash
# Check Kiali pod resources
kubectl -n istio-system get pod kiali-xxxxx -o yaml | grep -A 10 resources

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Increase resources
kubectl -n istio-system edit deployment kiali
```

### Issue 13: Kiali Logs Not Showing

```bash
# Check Kiali logs
kubectl -n istio-system logs -l app=kiali

# Check log level
kubectl -n istio-system get configmap kiali -o jsonpath='{.data.config\.yaml}' | grep log_level

# Increase log level
kubectl -n istio-system edit configmap kiali
```

### Issue 14: Kiali Configuration Validation Not Working

```bash
# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Check Istio resources
kubectl get virtualservice,destinationrule,gateway,serviceentry -A

# Check validation status
kubectl -n istio-system exec -it kiali-xxxxx -- curl http://localhost:20001/api/istio/config
```

### Issue 15: Kiali UI Not Loading

```bash
# Check Kiali pod
kubectl -n istio-system get pods -l app=kiali

# Check Kiali logs
kubectl -n istio-system logs -l app=kiali

# Restart Kiali
kubectl -n istio-system rollout restart deployment/kiali

# Clear browser cache
# Hard refresh: Ctrl+Shift+R
```

### Issue 16: Kiali Cannot Connect to Kubernetes

```bash
# Check Kiali service account
kubectl -n istio-system get sa kiali

# Check RBAC
kubectl get clusterrolebinding | grep kiali

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Fix RBAC
kubectl apply -f kiali-rbac.yaml
```

---

## 12. Tips and Best Practices

### Tip 1: Use Anonymous Authentication for Development

```yaml
auth:
  strategy: anonymous
```

### Tip 2: Use OpenID Authentication for Production

```yaml
auth:
  strategy: openid
  openid:
    client_id: kiali
    issuer_url: https://auth.example.com
    scopes:
    - openid
    - profile
    - email
```

### Tip 3: Use Prometheus for Metrics

```yaml
external_services:
  prometheus:
    url: http://prometheus.monitoring:9090
```

### Tip 4: Use Jaeger for Tracing

```yaml
external_services:
  jaeger:
    url: http://jaeger.istio-system:16686
```

### Tip 5: Use Grafana for Dashboards

```yaml
external_services:
  grafana:
    url: http://grafana.monitoring:3000
```

### Tip 6: Use Custom Health Configuration

```yaml
health_config:
  rate:
    - namespace: default
      tolerance: 1.0
    - namespace: production
      tolerance: 0.5
```

### Tip 7: Use Custom Metrics Configuration

```yaml
metrics:
  enabled: true
  port: 9090
  path: /metrics
custom_metrics:
  - name: my_custom_metric
    type: counter
    labels:
      - namespace
      - service
```

### Tip 8: Use Custom Dashboard Configuration

```yaml
custom_metrics_dashboard:
  name: My Custom Dashboard
  namespace: istio-system
  interval: 30s
```

### Tip 9: Use Custom API Configuration

```yaml
api:
  namespaces:
    label_selector: kubernetes.io/metadata.name
  conf_map_name: kiali
  dry_run: false
  log_level: info
  metrics:
    enabled: true
    port: 9090
  cache:
    enabled: true
    duration: 30s
    token_bucket_capacity: 1000
    token_refill_rate: 100
```

### Tip 10: Use Monitoring and Alerts

```yaml
# PrometheusRule for Kiali
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kiali-alerts
  namespace: istio-system
spec:
  groups:
  - name: kiali
    rules:
    - alert: KialiDown
      expr: up{job="kiali"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Kiali is down"
        description: "Kiali has been down for more than 5 minutes"
```

### Tip 11: Use Backup and Restore

```bash
# Backup Kiali configuration
kubectl -n istio-system get configmap kiali -o yaml > kiali-backup.yaml

# Restore from backup
kubectl -n istio-system apply -f kiali-backup.yaml
```

### Tip 12: Use Sync Windows for Maintenance

```yaml
# Sync window for Kiali updates
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: istio-system
  namespace: argocd
spec:
  syncWindows:
  - kind: allow
    schedule: '0 2 * * *'
    duration: 4h
    applications:
    - '*'
```

### Tip 13: Use Rollback Strategy

```bash
# Rollback Kiali deployment
kubectl -n istio-system rollout undo deployment/kiali

# Rollback to specific revision
kubectl -n istio-system rollout undo deployment/kiali --to-revision=2
```

### Tip 14: Use Health Checks

```yaml
# Liveness probe
livenessProbe:
  httpGet:
    path: /kiali/healthz
    port: 20001
  initialDelaySeconds: 30
  periodSeconds: 10

# Readiness probe
readinessProbe:
  httpGet:
    path: /kiali/healthz
    port: 20001
  initialDelaySeconds: 5
  periodSeconds: 10
```

### Tip 15: Use Resource Quotas

```yaml
# Resource quota for Kiali
apiVersion: v1
kind: ResourceQuota
metadata:
  name: kiali-quota
  namespace: istio-system
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 2Gi
    limits.cpu: "2"
    limits.memory: 4Gi
```

### Tip 16: Use Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kiali-network-policy
  namespace: istio-system
spec:
  podSelector:
    matchLabels:
      app: kiali
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-system
    ports:
    - protocol: TCP
      port: 20001
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 6443
```

---

## 13. Command Reference

### Kiali Commands

```bash
# Check Kiali pod
kubectl -n istio-system get pods -l app=kiali

# Check Kiali logs
kubectl -n istio-system logs -l app=kiali

# Check Kiali config
kubectl -n istio-system get configmap kiali -o yaml

# Restart Kiali
kubectl -n istio-system rollout restart deployment/kiali

# Port-forward Kiali
kubectl -n istio-system port-forward svc/kiali 20001:20001
```

### Istio Commands

```bash
# Check Istio installation
istioctl verify-install

# Check proxy status
istioctl proxy-status

# Check proxy config
istioctl proxy-config listener my-app-pod

# Describe pod
istioctl x describe pod my-app-pod

# Analyze configuration
istioctl analyze
```

### Prometheus Commands

```bash
# Check Prometheus
kubectl -n monitoring get pods -l app=prometheus

# Port-forward Prometheus
kubectl -n monitoring port-forward svc/prometheus 9090:9090

# Query Prometheus
curl http://localhost:9090/api/v1/query?query=istio_requests_total
```

### Jaeger Commands

```bash
# Check Jaeger
kubectl -n istio-system get pods -l app=jaeger

# Port-forward Jaeger
kubectl -n istio-system port-forward svc/jaeger 16686:16686

# Query Jaeger
curl http://localhost:16686/api/services
```

---

## 14. CRD Reference

### Kiali (Operator CRD)

```yaml
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: istio-system
spec:
  auth:
    strategy: anonymous
  deployment:
    image_name: quay.io/kiali/kiali
    image_version: v1.75
    replicas: 1
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 1000m
        memory: 2Gi
  external_services:
    prometheus:
      url: http://prometheus.monitoring:9090
    jaeger:
      url: http://jaeger.istio-system:16686
    grafana:
      url: http://grafana.monitoring:3000
  server:
    port: 20001
    web_root: /
  kubernetes_config:
    cluster_name: my-cluster
    qps: 100
    burst: 200
    cache_enabled: true
    cache_duration: 30s
    cache_token_bucket_capacity: 1000
    cache_token_refill_rate: 100
```

### Kiali ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kiali
  namespace: istio-system
data:
  config.yaml: |
    server:
      port: 20001
      web_root: /
    auth:
      strategy: anonymous
    external_services:
      prometheus:
        url: http://prometheus.monitoring:9090
        custom_headers:
          X-Scope-OrgID: "istio-system"
      jaeger:
        url: http://jaeger.istio-system:16686
      grafana:
        url: http://grafana.monitoring:3000
      custom_metrics_dashboard:
        name: Istio Mesh Dashboard
        namespace: istio-system
    kubernetes_config:
      cluster_name: my-cluster
      qps: 100
      burst: 200
      cache_enabled: true
      cache_duration: 30s
      cache_token_bucket_capacity: 1000
      cache_token_refill_rate: 100
    api:
      namespaces:
        label_selector: kubernetes.io/metadata.name
      conf_map_name: kiali
      dry_run: false
      log_level: info
      metrics:
        enabled: true
        port: 9090
```

---

## 15. Real-World Examples

### Example 1: Production Kiali Deployment

```yaml
# Kiali for production
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: istio-system
spec:
  auth:
    strategy: openid
    openid:
      client_id: kiali
      issuer_url: https://auth.example.com
      scopes:
      - openid
      - profile
      - email
  deployment:
    image_name: quay.io/kiali/kiali
    image_version: v1.75
    replicas: 2
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: 1000m
        memory: 2Gi
  external_services:
    prometheus:
      url: http://prometheus.monitoring:9090
    jaeger:
      url: http://jaeger.istio-system:16686
    grafana:
      url: http://grafana.monitoring:3000
  server:
    port: 20001
    web_root: /
  kubernetes_config:
    cluster_name: production-cluster
    qps: 100
    burst: 200
    cache_enabled: true
    cache_duration: 30s
    cache_token_bucket_capacity: 1000
    cache_token_refill_rate: 100
```

### Example 2: Kiali with Custom Metrics

```yaml
# Kiali with custom metrics
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: istio-system
spec:
  auth:
    strategy: anonymous
  external_services:
    prometheus:
      url: http://prometheus.monitoring:9090
  custom_metrics:
    - name: my_custom_metric
      type: counter
      labels:
        - namespace
        - service
    - name: my_custom_histogram
      type: histogram
      labels:
        - namespace
        - service
      buckets:
        - 0.1
        - 0.5
        - 1.0
        - 5.0
        - 10.0
```

### Example 3: Kiali with Custom Dashboard

```yaml
# Kiali with custom dashboard
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  name: kiali
  namespace: istio-system
spec:
  auth:
    strategy: anonymous
  external_services:
    prometheus:
      url: http://prometheus.monitoring:9090
  custom_metrics_dashboard:
    name: My Custom Dashboard
    namespace: istio-system
    interval: 30s
    panels:
    - title: Request Rate
      type: graph
      queries:
      - expr: sum(rate(istio_requests_total[5m])) by (source_service)
        legend: "{{source_service}}"
    - title: Response Time
      type: graph
      queries:
      - expr: histogram_quantile(0.99, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (le))
        legend: "99th percentile"
```

### Example 4: Kiali with ArgoCD

```yaml
# Application with Kiali
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kiali
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/kiali/kiali-operator
    path: deploy/kiali
    targetRevision: master
  destination:
    server: https://kubernetes.default.svc
    namespace: istio-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 16. Further Reading

### Official Documentation

- [Kiali Documentation](https://kiali.io/documentation/)
- [Kiali GitHub](https://github.com/kiali/kiali)
- [Kiali Configuration](https://kiali.io/documentation/latest/configuration/)

### Tutorials and Guides

- [Getting Started with Kiali](https://kiali.io/documentation/latest/getting-started/)
- [Kiali Graph](https://kiali.io/documentation/latest/features/graph/)
- [Kiali Health](https://kiali.io/documentation/latest/features/health/)

### Community Resources

- [Kiali Slack](https://kiali.io/community/join-slack/)
- [Kiali Blog](https://kiali.io/blog/)
- [Kiali Examples](https://github.com/kiali/kiali/tree/master/samples)

### Books and Courses

- "Istio in Action" by Christian Posta
- "Learning Istio" by Christian Posta
- "Kiali in Action" by Kiali Community
