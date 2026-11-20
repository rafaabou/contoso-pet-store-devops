# Argo Rollouts Complete Guide

## Table of Contents

1. [What Is Argo Rollouts](#1-what-is-argo-rollouts)
2. [Why Use Argo Rollouts](#2-why-use-argo-rollouts)
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

## 1. What Is Argo Rollouts

Argo Rollouts is a Kubernetes controller and set of CRDs for progressive delivery. It provides advanced deployment strategies like canary and blue-green deployments, with automated analysis and rollback capabilities.

### Key Characteristics

- **Progressive Delivery**: Canary and blue-green deployments
- **Automated Analysis**: Traffic shaping and health checks
- **Automated Rollback**: Rollback on analysis failure
- **Integration**: Works with service meshes, ingress controllers, and load balancers
- **Kubernetes-native**: Uses CRDs and controllers

### How It Works

```
┌─────────────────────────────────────────────────┐
│                Argo Rollouts Controller           │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Rollout Controller                 ││
│  │  - Watches Rollout CRD                        ││
│  │  - Manages ReplicaSets                        ││
│  │  - Handles traffic splitting                  ││
│  │  - Executes analysis runs                     ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Traffic Management                 ││
│  │  - Istio VirtualService                       ││
│  │  - Nginx Ingress                              ││
│  │  - AWS ALB                                    ││
│  │  - SMI TrafficSplit                           ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Analysis Engine                    ││
│  │  - Prometheus metrics                         ││
│  │  - Datadog queries                           ││
│  │  - Kayenta (Canary analysis)                  ││
│  │  - Custom webhooks                            ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Deployment Strategies

1. **Canary**: Gradually shift traffic to new version
2. **Blue-Green**: Deploy new version alongside old, then switch
3. **Rolling**: Standard Kubernetes rolling update
4. **Step-based**: Custom steps with pauses and analysis

---

## 2. Why Use Argo Rollouts

### Problems Argo Rollouts Solves

| Problem | Argo Rollouts Solution |
|---------|------------------------|
| Risky deployments | Canary deployments with traffic splitting |
| Difficult rollbacks | Automated rollback on failure |
| No deployment verification | Automated analysis with metrics |
| Manual deployment approval | Integration with ArgoCD |
| Traffic management | Service mesh integration |

### Argo Rollouts vs Other Tools

| Feature | Argo Rollouts | Flagger | Istio | Spinnaker |
|---------|---------------|---------|-------|-----------|
| Canaries | Yes | Yes | Yes | Yes |
| Blue-Green | Yes | Yes | Yes | Yes |
| Analysis | Yes | Yes | Yes | Limited |
| CRD-based | Yes | Yes | No | No |
| Service Mesh | Yes | Yes | Yes | Yes |
| Manual Approval | Yes | Yes | Yes | Yes |
| ArgoCD Integration | Yes | No | No | Limited |

### When to Use Argo Rollouts

- When you need progressive delivery strategies
- When requiring automated rollback on failure
- When integrating with ArgoCD for GitOps
- When managing traffic splitting
- When implementing deployment analysis
- When needing manual approval gates

---

## 3. Architecture Overview

### Components

```
┌─────────────────────────────────────────────────┐
│                Argo Rollouts                     │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │        Rollout Controller                     ││
│  │  - Watches Rollout resources                  ││
│  │  - Manages ReplicaSets                        ││
│  │  - Handles traffic shaping                    ││
│  │  - Executes analysis runs                     ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │        Analysis Controller                    ││
│  │  - Monitors AnalysisRun resources             ││
│  │  - Executes metrics queries                   ││
│  │  - Reports analysis results                   ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │        Traffic Router                         ││
│  │  - Istio VirtualService                       ││
│  │  - Nginx Ingress                              ││
│  │  - AWS ALB                                    ││
│  │  - SMI TrafficSplit                           ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Data Flow

1. **User creates Rollout CRD**: Defines deployment strategy
2. **Controller watches**: Detects new Rollout
3. **Creates ReplicaSets**: Stable and canary ReplicaSets
4. **Manages traffic**: Splits traffic between versions
5. **Runs analysis**: Monitors metrics during deployment
6. **Promotes or rolls back**: Based on analysis results

---

## 4. Installation

### Method 1: Kustomize

```bash
# Install CRDs
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/config/crd/install.yaml

# Install controller
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/config/install.yaml
```

### Method 2: Helm

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install
helm install argo-rollouts argo/argo-rollouts \
  --namespace argo-rollouts \
  --create-namespace \
  --set dashboard.enabled=true
```

### Method 3: Download CLI

```bash
# Linux
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/argo-rollouts-linux-amd64
chmod +x argo-rollouts-linux-amd64
sudo mv argo-rollouts-linux-amd64 /usr/local/bin/argo-rollouts

# macOS
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/argo-rollouts-darwin-amd64
chmod +x argo-rollouts-darwin-amd64
sudo mv argo-rollouts-darwin-amd64 /usr/local/bin/argo-rollouts
```

### Post-Installation Verification

```bash
# Check controller pod
kubectl -n argo-rollouts get pods

# Expected output:
# argo-rollouts-xxxxx    Running

# Check CRDs
kubectl get crd | grep argo

# Expected output:
# analysisruns.argoproj.io
# analysistemplates.argoproj.io
# rollouts.argoproj.io
```

### Dashboard Installation

```bash
# Port-forward dashboard
kubectl -n argo-rollouts port-forward svc/argo-rollouts-dashboard 3100:3100

# Access dashboard
# http://localhost:3100
```

---

## 5. Configuration

### Controller Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argo-rollouts
  namespace: argo-rollouts
spec:
  template:
    spec:
      containers:
      - name: argo-rollouts
        image: quay.io/argoproj/argo-rollouts:latest
        args:
        - --analytics-enabled=false
        - --dashboard-enabled=true
        - --leader-elect=true
        - --log-level=info
        - --log-format=json
        env:
        - name: ARGO_ROLLOUTS_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

### Traffic Management Configuration

#### Istio Configuration

```yaml
# VirtualService for Istio
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
  - my-app
  http:
  - route:
    - destination:
        host: my-app-stable
      weight: 100
    - destination:
        host: my-app-canary
      weight: 0
```

#### Nginx Configuration

```yaml
# Ingress for Nginx
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "0"
spec:
  rules:
  - host: my-app.example.com
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

### Analysis Configuration

```yaml
# Prometheus metrics
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config
  namespace: argo-rollouts
data:
  metricProviders: |
    - name: prometheus
      address: http://prometheus.monitoring:9090
      interval: 60s
```

---

## 6. Core Concepts

### Rollout

A Rollout is a custom resource that defines a deployment strategy.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-app
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
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
      canaryService: my-app-canary
      stableService: my-app-stable
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
```

### AnalysisTemplate

AnalysisTemplate defines metrics queries and success criteria.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 60s
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.*"}[5m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

### AnalysisRun

AnalysisRun is created by the Rollout controller during deployment.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
metadata:
  name: my-app-analysis-123
spec:
  analysisTemplate:
    name: success-rate
  args:
  - name: service-name
    value: my-app-canary
  metrics:
  - name: success-rate
    interval: 60s
    count: 5
    successCondition: result[0] >= 0.95
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.*"}[5m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

### Blue-Green Strategy

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-app
  strategy:
    blueGreen:
      activeService: my-app-active
      previewService: my-app-preview
      autoPromotionEnabled: true
      autoPromotionSeconds: 60
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
```

---

## 7. Usage Guide

### Step-by-Step: Canary Deployment

#### 1. Create AnalysisTemplate

```yaml
# analysis-template.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 60s
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.*"}[5m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

#### 2. Create Rollout

```yaml
# rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-app
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
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
      canaryService: my-app-canary
      stableService: my-app-stable
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
```

#### 3. Create Services

```yaml
# services.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-stable
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-canary
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```

#### 4. Deploy and Monitor

```bash
# Apply manifests
kubectl apply -f analysis-template.yaml
kubectl apply -f services.yaml
kubectl apply -f rollout.yaml

# Watch rollout progress
kubectl argo rollouts get rollout my-app --watch

# Check rollout status
kubectl argo rollouts status my-app
```

#### 5. Promote or Rollback

```bash
# Promote to next step
kubectl argo rollouts promote my-app

# Rollback to previous version
kubectl argo rollouts undo my-app

# Skip to specific step
kubectl argo rollouts goto-step 3 --name my-app
```

### Step-by-Step: Blue-Green Deployment

#### 1. Create Rollout

```yaml
# rollout-bluegreen.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-app
  strategy:
    blueGreen:
      activeService: my-app-active
      previewService: my-app-preview
      autoPromotionEnabled: false
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
```

#### 2. Create Services

```yaml
# services-bluegreen.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-active
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-preview
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```

#### 3. Deploy and Monitor

```bash
# Apply manifests
kubectl apply -f rollout-bluegreen.yaml
kubectl apply -f services-bluegreen.yaml

# Watch rollout progress
kubectl argo rollouts get rollout my-app --watch

# Promote when ready
kubectl argo rollouts promote my-app
```

---

## 8. Custom Configuration

### Custom Analysis Metrics

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: custom-metrics
spec:
  args:
  - name: service-name
  metrics:
  - name: latency
    interval: 60s
    count: 5
    successCondition: result[0] <= 100
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket{service="{{args.service-name}}"}[5m])) by (le)
          ) * 1000
  - name: error-rate
    interval: 60s
    count: 5
    successCondition: result[0] <= 0.05
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"5.*"}[5m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

### Webhook Analysis

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: webhook-analysis
spec:
  metrics:
  - name: smoke-test
    interval: 60s
    count: 1
    provider:
      webhook:
        method: GET
        url: https://smoke-tests.example.com/run
        headers:
        - key: Authorization
          value: Bearer {{token}}
```

### Kayenta Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: kayenta-analysis
spec:
  args:
  - name: canary-hash
  metrics:
  - name: kayenta
    provider:
      kayenta:
        address: https://kayenta.example.com
        canaryConfig:
          name: my-app-canary
          spotCheck:
            metricsAccount: my-metrics-account
            objectStoresAccount: my-object-store
          canaryConfig:
            metricsAccount: my-metrics-account
            objectStoresAccount: my-object-store
            judgementBucketName: my-judgement
            templateId: my-template
            baselineCluster: my-baseline
            baselineClusterLocation: my-location
            canaryCluster: my-canary
            canaryClusterLocation: my-location
          scoreThresholds:
            pass: 95
            marginal: 75
```

### Traffic Router Plugins

```yaml
# Custom traffic router
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config
  namespace: argo-rollouts
data:
  trafficRouters: |
    - name: my-custom-router
      experimental: true
      serviceName: my-custom-router
      template: |
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: my-custom-router-{{rollout}}
        data:
          config.yaml: |
            trafficRouting:
              serviceName: {{stableService}}
              canaryServiceName: {{canaryService}}
              trafficSplit:
                - weight: {{weight}}
```

---

## 9. Integration

### ArgoCD Integration

```yaml
# Application with Rollout
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
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

### Istio Integration

```yaml
# VirtualService for Argo Rollouts
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
  - my-app
  http:
  - route:
    - destination:
        host: my-app-stable
      weight: 100
    - destination:
        host: my-app-canary
      weight: 0
```

### Nginx Ingress Integration

```yaml
# Ingress for Argo Rollouts
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "0"
spec:
  rules:
  - host: my-app.example.com
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

### AWS ALB Integration

```yaml
# Ingress for AWS ALB
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/actions.canary: |
      {
        "Type": "forward",
        "ForwardConfig": {
          "TargetGroups": [
            {
              "ServiceName": "my-app-stable",
              "ServicePort": "80"
            },
            {
              "ServiceName": "my-app-canary",
              "ServicePort": "80",
              "Weight": 0
            }
          ]
        }
      }
spec:
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: canary
            port:
              number: 80
```

### Prometheus Integration

```yaml
# PrometheusRule for Argo Rollouts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argo-rollouts-alerts
  namespace: argo-rollouts
spec:
  groups:
  - name: argo-rollouts
    rules:
    - alert: RolloutAnalysisFailed
      expr: argo_rollouts_analysis_status{phase="Failed"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Argo Rollouts analysis failed"
        description: "Analysis {{ $labels.name }} has failed"
```

---

## 10. Security

### RBAC Configuration

```yaml
# Role for Argo Rollouts
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argo-rollouts
  namespace: argo-rollouts
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["replicasets"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["argoproj.io"]
  resources: ["rollouts", "rollouts/status", "rollouts/finalizers"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["argoproj.io"]
  resources: ["analysisruns", "analysisruns/finalizers"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["argoproj.io"]
  resources: ["analysistemplates"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["networking.istio.io"]
  resources: ["virtualservices"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argo-rollouts-network-policy
  namespace: argo-rollouts
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: argocd
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 9090
    - protocol: TCP
      port: 443
```

### TLS Configuration

```yaml
# TLS for Argo Rollouts Dashboard
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argo-rollouts-dashboard
  namespace: argo-rollouts
spec:
  template:
    spec:
      containers:
      - name: argo-rollouts-dashboard
        args:
        - --secure-port=8443
        - --tls-cert=/tls/tls.crt
        - --tls-key=/tls/tls.key
        volumeMounts:
        - name: tls-certs
          mountPath: /tls
      volumes:
      - name: tls-certs
        secret:
          secretName: argo-rollouts-dashboard-tls
```

---

## 11. Troubleshooting

### Issue 1: Rollout Stuck in "Progressing"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check rollout controller logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts --tail=100

# Force promote
kubectl argo rollouts promote my-app
```

### Issue 2: Analysis Run Failed

```bash
# Check analysis run
kubectl get analysisrun

# Check analysis run events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app-analysis-123

# Check analysis run logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts --tail=100

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

### Issue 3: Traffic Not Shifting

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check Istio proxy
istioctl proxy-status

# Check Istio configuration
istioctl analyze

# Check rollout steps
kubectl argo rollouts get rollout my-app
```

### Issue 4: Canary Service Not Receiving Traffic

```bash
# Check canary service
kubectl get svc my-app-canary

# Check canary pods
kubectl get pods -l app=my-app -o wide

# Check endpoints
kubectl get endpoints my-app-canary

# Check rollout status
kubectl argo rollouts get rollout my-app
```

### Issue 5: Blue-Green Service Not Switching

```bash
# Check blue-green services
kubectl get svc my-app-active my-app-preview

# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Promote manually
kubectl argo rollouts promote my-app
```

### Issue 6: Rollout Controller Not Starting

```bash
# Check controller pod
kubectl -n argo-rollouts get pods -l app.kubernetes.io/name=argo-rollouts

# Check controller logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts

# Check controller events
kubectl -n argo-rollouts get events

# Restart controller
kubectl -n argo-rollouts rollout restart deployment/argo-rollouts
```

### Issue 7: CRD Not Installed

```bash
# Check CRDs
kubectl get crd | grep argo

# Install CRDs
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/config/crd/install.yaml

# Verify CRDs
kubectl get crd rollouts.argoproj.io
```

### Issue 8: Analysis Template Not Found

```bash
# Check analysis templates
kubectl get analysistemplate

# Check analysis template in namespace
kubectl -n argo-rollouts get analysistemplate

# Create analysis template
kubectl apply -f analysis-template.yaml
```

### Issue 9: Rollout Stuck in "Degraded"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check pods
kubectl get pods -l app=my-app

# Check replica set
kubectl get rs -l app=my-app
```

### Issue 10: Traffic Router Not Working

```bash
# Check traffic router configuration
kubectl -n argo-rollouts get configmap argo-rollouts-config -o yaml

# Check traffic router pods
kubectl -n argo-rollouts get pods

# Check traffic router logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts

# Check traffic router events
kubectl -n argo-rollouts get events
```

### Issue 11: Rollout Stuck in "Waiting"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check rollout controller logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts

# Force promote
kubectl argo rollouts promote my-app
```

### Issue 12: Rollout Stuck in "Paused"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Resume rollout
kubectl argo rollouts resume my-app

# Force promote
kubectl argo rollouts promote my-app
```

### Issue 13: Rollout Stuck in "Error"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check rollout controller logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts

# Check for resource conflicts
kubectl -n argo-rollouts get events --type Warning
```

### Issue 14: Rollout Stuck in "Scaling"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check replica set
kubectl get rs -l app=my-app

# Check pods
kubectl get pods -l app=my-app
```

### Issue 15: Rollout Stuck in "WaitingForApproval"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Approve rollout
kubectl argo rollouts approve my-app

# Force promote
kubectl argo rollouts promote my-app
```

### Issue 16: Rollout Stuck in "Running"

```bash
# Check rollout status
kubectl argo rollouts get rollout my-app

# Check rollout events
kubectl -n argo-rollouts get events --field-selector involvedObject.name=my-app

# Check rollout controller logs
kubectl -n argo-rollouts logs -l app.kubernetes.io/name=argo-rollouts

# Abort rollout
kubectl argo rollouts abort my-app
```

---

## 12. Tips and Best Practices

### Tip 1: Use Canary for Low-Risk Deployments

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 2m}
      - setWeight: 20
      - pause: {duration: 2m}
      - setWeight: 30
      - pause: {duration: 2m}
      - setWeight: 40
      - pause: {duration: 2m}
      - setWeight: 50
      - pause: {duration: 2m}
      - setWeight: 60
      - pause: {duration: 2m}
      - setWeight: 70
      - pause: {duration: 2m}
      - setWeight: 80
      - pause: {duration: 2m}
      - setWeight: 90
      - pause: {duration: 2m}
```

### Tip 2: Use Blue-Green for High-Risk Deployments

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: my-app-active
      previewService: my-app-preview
      autoPromotionEnabled: false
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
```

### Tip 3: Implement Analysis Templates

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 60s
    count: 5
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status=~"2.*"}[5m])) /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

### Tip 4: Use Analysis Runs for Verification

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
```

### Tip 5: Implement Traffic Shaping

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      canaryService: my-app-canary
      stableService: my-app-stable
      trafficRouting:
        istio:
          virtualServices:
          - name: my-app
            routes:
            - primary
```

### Tip 6: Use Manual Approval for Production

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      analysis:
        templates:
        - templateName: success-rate
```

### Tip 7: Implement Automated Rollback

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: my-app-canary
```

### Tip 8: Use Pre/Post Analysis

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: my-app-active
      previewService: my-app-preview
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
```

### Tip 9: Implement Custom Metrics

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: custom-metrics
spec:
  args:
  - name: service-name
  metrics:
  - name: latency
    interval: 60s
    count: 5
    successCondition: result[0] <= 100
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring:9090
        query: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket{service="{{args.service-name}}"}[5m])) by (le)
          ) * 1000
```

### Tip 10: Use Webhook Analysis

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: webhook-analysis
spec:
  metrics:
  - name: smoke-test
    interval: 60s
    count: 1
    provider:
      webhook:
        method: GET
        url: https://smoke-tests.example.com/run
        headers:
        - key: Authorization
          value: Bearer {{token}}
```

### Tip 11: Implement Traffic Router Plugins

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config
  namespace: argo-rollouts
data:
  trafficRouters: |
    - name: my-custom-router
      experimental: true
      serviceName: my-custom-router
      template: |
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: my-custom-router-{{rollout}}
        data:
          config.yaml: |
            trafficRouting:
              serviceName: {{stableService}}
              canaryServiceName: {{canaryService}}
              trafficSplit:
                - weight: {{weight}}
```

### Tip 12: Use ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
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

### Tip 13: Implement Progressive Delivery

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 2m}
      - setWeight: 20
      - pause: {duration: 2m}
      - setWeight: 30
      - pause: {duration: 2m}
      - setWeight: 40
      - pause: {duration: 2m}
      - setWeight: 50
      - pause: {duration: 2m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
```

### Tip 14: Use Monitoring and Alerts

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argo-rollouts-alerts
  namespace: argo-rollouts
spec:
  groups:
  - name: argo-rollouts
    rules:
    - alert: RolloutAnalysisFailed
      expr: argo_rollouts_analysis_status{phase="Failed"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Argo Rollouts analysis failed"
        description: "Analysis {{ $labels.name }} has failed"
```

### Tip 15: Implement Backup and Restore

```bash
# Backup rollout configuration
kubectl get rollout my-app -o yaml > rollout-backup.yaml

# Restore from backup
kubectl apply -f rollout-backup.yaml
```

### Tip 16: Use Sync Windows for Maintenance

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: my-app-canary
      trafficRouting:
        istio:
          virtualServices:
          - name: my-app
            routes:
            - primary
```

---

## 13. Command Reference

### Rollout Commands

```bash
# Get rollout status
kubectl argo rollouts get rollout <rollout-name>

# Get rollout status with watch
kubectl argo rollouts get rollout <rollout-name> --watch

# Promote rollout
kubectl argo rollouts promote <rollout-name>

# Rollback rollout
kubectl argo rollouts undo <rollout-name>

# Abort rollout
kubectl argo rollouts abort <rollout-name>

# Resume rollout
kubectl argo rollouts resume <rollout-name>

# Restart rollout
kubectl argo rollouts restart <rollout-name>

# Retry rollout
kubectl argo rollouts retry <rollout-name>

# Set rollout weight
kubectl argo rollouts set weight <rollout-name> <weight>

# Set rollout image
kubectl argo rollouts set image <rollout-name> <container>=<image>

# Get rollout history
kubectl argo rollouts history <rollout-name>

# Get rollout status
kubectl argo rollouts status <rollout-name>

# Wait for rollout
kubectl argo rollouts wait <rollout-name>

# Get rollout events
kubectl argo rollouts events <rollout-name>

# Get rollout metrics
kubectl argo rollouts metrics <rollout-name>

# Get rollout traffic
kubectl argo rollouts traffic <rollout-name>

# Get rollout analysis
kubectl argo rollouts analysis <rollout-name>
```

### Analysis Commands

```bash
# Get analysis runs
kubectl argo rollouts get analysisrun

# Get analysis run status
kubectl argo rollouts get analysisrun <analysisrun-name>

# Get analysis run events
kubectl argo rollouts events analysisrun <analysisrun-name>

# Get analysis run logs
kubectl argo rollouts logs analysisrun <analysisrun-name>
```

### Dashboard Commands

```bash
# Start dashboard
kubectl -n argo-rollouts port-forward svc/argo-rollouts-dashboard 3100:3100

# Access dashboard
# http://localhost:3100
```

---

## 14. CRD Reference

### Rollout

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: string
  namespace: string
  labels: map[string]string
  annotations: map[string]string
spec:
  replicas: integer
  selector:
    matchLabels: map[string]string
    matchExpressions: [object]
  strategy:
    canary:
      canaryService: string
      stableService: string
      trafficRouting:
        istio:
          virtualServices:
          - name: string
            routes: [string]
        nginx:
          stableIngress: string
          additionalIngressAnnotations: map[string]string
        albs:
          ingress: string
          servicePort: integer
        smi:
          trafficSplitName: string
          rootsService: string
          trafficSplitService: string
        contour:
          virtualHost: string
          tls: object
        traefik:
          weightedTraefikServices: object
        appMesh:
          virtualNode: object
        plugins:
          name: object
      steps:
      - setWeight: integer
      - pause: {duration: string}
      - setHeaderRoute: object
      - setMirrorRoute: object
      - analysis: object
      - experiment: object
    blueGreen:
      activeService: string
      previewService: string
      autoPromotionEnabled: boolean
      autoPromotionSeconds: integer
      prePromotionAnalysis: object
      postPromotionAnalysis: object
      scaleDownDelaySeconds: integer
      previewReplicaCount: integer
    rolling:
      maxSurge: string
      maxUnavailable: string
      maxSurgeValue: integer
      maxUnavailableValue: integer
  template:
    metadata:
      labels: map[string]string
      annotations: map[string]string
    spec:
      containers:
      - name: string
        image: string
        ports:
        - containerPort: integer
        resources:
          requests:
            memory: string
            cpu: string
          limits:
            memory: string
            cpu: string
  revisionHistoryLimit: integer
  analysis: object
```

### AnalysisTemplate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: string
  namespace: string
  labels: map[string]string
  annotations: map[string]string
spec:
  args:
  - name: string
    value: string
    valueFrom:
      secretKeyRef:
        name: string
        key: string
  metrics:
  - name: string
    interval: string
    count: integer
    successCondition: string
    failureCondition: string
    failureLimit: integer
    incompleteWindowIgnore: boolean
    provider:
      prometheus:
        address: string
        query: string
        headers: [object]
      datadog:
        address: string
        query: string
        apiKey: object
        appKey: object
      job:
        spec: object
        backoffLimit: integer
      webhook:
        method: string
        url: string
        headers: [object]
        body: string
        insecureSkipVerify: boolean
        timeoutSeconds: integer
      skywalking:
        address: string
        query: string
      graphite:
        address: string
        query: string
      cloudWatch:
        metricDataQueries: [object]
        region: string
      wavefront:
        address: string
        query: string
      newRelic:
        query: string
        profileSecretRef: object
        outputCapacity: integer
      kayak:
        url: string
        insecureSkipVerify: boolean
      blockDiag:
        block: object
  measurementRetention:
  - metricName: string
    limit: integer
  args:
  - name: string
    value: string
```

### AnalysisRun

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
metadata:
  name: string
  namespace: string
  labels: map[string]string
  annotations: map[string]string
spec:
  analysisTemplate:
    name: string
    templateName: string
    clusterScope: boolean
  args:
  - name: string
    value: string
    valueFrom:
      fieldRef:
        fieldPath: string
      secretKeyRef:
        name: string
        key: string
  metrics:
  - name: string
    interval: string
    count: integer
    successCondition: string
    failureCondition: string
    failureLimit: integer
    provider: object
  measurementRetention:
  - metricName: string
    limit: integer
  analyticsRunMeasurementTTL: string
  dryRun: boolean
  args:
  - name: string
    value: string
status:
  phase: string
  message: string
  metricRefs: [object]
  measurements: [object]
  runSummary: object
  conditions: [object]
 Ars:
  - metricName: string
    phase: string
    count: integer
    message: string
    measurements: [object]
```

---

## 15. Real-World Examples

### Example 1: Production Canary Deployment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: production-app
  namespace: production
  labels:
    environment: production
spec:
  replicas: 10
  selector:
    matchLabels:
      app: production-app
  strategy:
    canary:
      canaryService: production-app-canary
      stableService: production-app-stable
      trafficRouting:
        istio:
          virtualServices:
          - name: production-app
            routes:
            - primary
      steps:
      - setWeight: 5
      - pause: {duration: 5m}
      - setWeight: 10
      - pause: {duration: 5m}
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 30
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 70
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: production-app-canary
  template:
    metadata:
      labels:
        app: production-app
    spec:
      containers:
      - name: production-app
        image: registry.example.com/production-app:v1.2.3
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

### Example 2: Blue-Green Deployment with Analysis

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: critical-app
  namespace: production
  labels:
    environment: production
    criticality: high
spec:
  replicas: 5
  selector:
    matchLabels:
      app: critical-app
  strategy:
    blueGreen:
      activeService: critical-app-active
      previewService: critical-app-preview
      autoPromotionEnabled: false
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        - templateName: latency-check
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        - templateName: latency-check
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: critical-app
        image: registry.example.com/critical-app:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1"
```

### Example 3: Multi-Cluster Deployment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: multi-cluster-app
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: multi-cluster-app
  strategy:
    canary:
      canaryService: multi-cluster-app-canary
      stableService: multi-cluster-app-stable
      trafficRouting:
        istio:
          virtualServices:
          - name: multi-cluster-app
            routes:
            - primary
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 5m}
      - setWeight: 60
      - pause: {duration: 5m}
      - setWeight: 80
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
  template:
    metadata:
      labels:
        app: multi-cluster-app
    spec:
      containers:
      - name: multi-cluster-app
        image: registry.example.com/multi-cluster-app:v1.0.0
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

### Example 4: GitOps with ArgoCD

```yaml
# Application with Rollout
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitops-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/my-org/gitops-app.git
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
# Rollout
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: gitops-app
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: gitops-app
  strategy:
    canary:
      canaryService: gitops-app-canary
      stableService: gitops-app-stable
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      analysis:
        templates:
        - templateName: success-rate
  template:
    metadata:
      labels:
        app: gitops-app
    spec:
      containers:
      - name: gitops-app
        image: registry.example.com/gitops-app:latest
        ports:
        - containerPort: 8080
```

---

## 16. Further Reading

### Official Documentation

- [Argo Rollouts Documentation](https://argo-rollouts.readthedocs.io/en/stable/)
- [Argo Rollouts GitHub](https://github.com/argoproj/argo-rollouts)
- [Argo Rollouts CRD Reference](https://argo-rollouts.readthedocs.io/en/stable/features/specification/)

### Tutorials and Guides

- [Getting Started with Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/getting-started/)
- [Canary Deployments with Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)
- [Blue-Green Deployments with Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/features/blue-green/)

### Community Resources

- [Argo Rollouts Slack](https://argoproj.github.io/community/join-slack)
- [Argo Rollouts Blog](https://blog.argoproj.io/)
- [Argo Rollouts Examples](https://github.com/argoproj/argo-rollouts/tree/master/examples)

### Books and Courses

- "GitOps and Kubernetes" by Billy Yuen, Alexander Matyushentsev, Todd Ekenstam, Jesse Suen
- "Progressive Delivery" by Oscar Renalias
- "Kubernetes Deployment Strategies" by Christian Posta

### Tools and Integrations

- [Argo Rollouts CLI](https://github.com/argoproj/argo-rollouts/blob/master/cmd/kubectl-argo-rollouts/)
- [Argo Rollouts Dashboard](https://github.com/argoproj/argo-rollouts/tree/master/server)
- [Argo Rollouts Notifications](https://github.com/argoproj/notifications-engine)
