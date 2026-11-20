# Istio Complete Guide

## Table of Contents

1. [What Is Istio](#1-what-is-istio)
2. [Why Use Istio](#2-why-use-istio)
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

## 1. What Is Istio

Istio is an open platform for connecting, managing, and securing microservices. It provides a service mesh that handles service-to-service communication, security, and observability.

### Key Characteristics

- **Traffic Management**: Load balancing, routing, and traffic shaping
- **Security**: mTLS, authentication, and authorization
- **Observability**: Metrics, logging, and distributed tracing
- **Policy Enforcement**: Rate limiting, retries, and circuit breaking
- **Platform Support**: Works on Kubernetes, VMs, and hybrid environments

### How It Works

```
┌─────────────────────────────────────────────────┐
│                   Istio Mesh                     │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Data Plane                         ││
│  │  - Envoy proxies (sidecars)                   ││
│  │  - Intercepts all traffic                     ││
│  │  - Enforces policies                          ││
│  │  - Collects metrics                           ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Control Plane                      ││
│  │  - istiod (pilot, citadel, galley)            ││
│  │  - Configures proxies                         ││
│  │  - Manages certificates                       ││
│  │  - Validates configurations                   ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Ingress Gateway                    ││
│  │  - Entry point to mesh                        ││
│  │  - TLS termination                            ││
│  │  - Traffic routing                            ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

---

## 2. Why Use Istio

### Problems Istio Solves

| Problem | Istio Solution |
|---------|----------------|
| Service-to-service communication | Service mesh with Envoy proxies |
| Security between services | mTLS encryption and authentication |
| Traffic management | Advanced routing and load balancing |
| Observability | Metrics, logs, and tracing |
| Policy enforcement | Rate limiting and circuit breaking |

### Istio vs Other Service Meshes

| Feature | Istio | Linkerd | Consul | Cilium |
|---------|-------|---------|--------|--------|
| Sidecar proxy | Yes | Yes | No | No |
| mTLS | Yes | Yes | Yes | Yes |
| Traffic management | Yes | Limited | Yes | Yes |
| Observability | Yes | Yes | Yes | Yes |
| Multi-cluster | Yes | Yes | Yes | Yes |
| VM support | Yes | No | Yes | No |
| Policy enforcement | Yes | Yes | Yes | Yes |

### When to Use Istio

- When you need service-to-service security
- When requiring advanced traffic management
- When implementing observability
- When enforcing policies
- When managing multi-cluster deployments

---

## 3. Architecture Overview

### Components

```
┌─────────────────────────────────────────────────┐
│                Istio Architecture                │
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Control Plane (istiod)              ││
│  │  - Pilot: Service discovery and traffic       ││
│  │    management                                 ││
│  │  - Citadel: Certificate management            ││
│  │  - Galley: Configuration validation           ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Data Plane (Envoy proxies)          ││
│  │  - Sidecar injection                          ││
│  │  - Traffic interception                        ││
│  │  - Policy enforcement                          ││
│  │  - Metrics collection                          ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Ingress Gateway                     ││
│  │  - TLS termination                             ││
│  │  - Traffic routing                             ││
│  │  - Load balancing                              ││
│  └──────────────────────────────────────────────┘│
│                                                   │
│  ┌──────────────────────────────────────────────┐│
│  │            Egress Gateway                      ││
│  │  - External service access                     ││
│  │  - Traffic monitoring                          ││
│  │  - Policy enforcement                          ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
```

### Data Flow

1. **Service Discovery**: Pilot discovers services and endpoints
2. **Configuration Distribution**: Pilot distributes configuration to proxies
3. **Traffic Interception**: Envoy proxies intercept all traffic
4. **Policy Enforcement**: Proxies enforce security and traffic policies
5. **Metrics Collection**: Proxies collect metrics and send to telemetry

---

## 4. Installation

### Method 1: istioctl

```bash
# Download istioctl
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio
istioctl install --set profile=demo -y

# Verify installation
istioctl verify-install
```

### Method 2: Helm

```bash
# Add Helm repo
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio base
helm install istio-base istio/base -n istio-system --create-namespace

# Install istiod
helm install istiod istio/istiod -n istio-system

# Install ingress gateway
helm install istio-ingressgateway istio/gateway -n istio-system
```

### Method 3: Quick Start

```bash
# Install with demo profile
istioctl install --set profile=demo -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled

# Deploy sample application
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Verify installation
kubectl get pods
```

### Post-Installation Verification

```bash
# Check Istio pods
kubectl -n istio-system get pods

# Expected output:
# istiod-xxxxx    Running
# istio-ingressgateway-xxxxx    Running

# Check Istio services
kubectl -n istio-system get svc

# Check sidecar injection
kubectl get namespace -L istio-injection
```

### Ingress Gateway Configuration

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
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
    - "*.example.com"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: my-tls-secret
    hosts:
    - "*.example.com"
```

---

## 5. Configuration

### Mesh Configuration

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-control-plane
  namespace: istio-system
spec:
  profile: default
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogEncoding: JSON
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 100.0
      holdApplicationUntilProxyStarts: true
    outboundTrafficPolicy:
      mode: ALLOW_ANY
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 500m
            memory: 2Gi
          limits:
            cpu: 1000m
            memory: 4Gi
        hpaSpec:
          minReplicas: 2
          maxReplicas: 5
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        hpaSpec:
          minReplicas: 2
          maxReplicas: 5
        service:
          type: LoadBalancer
          ports:
          - port: 80
            targetPort: 8080
            name: http
          - port: 443
            targetPort: 8443
            name: https
```

### Proxy Configuration

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
        connectTimeout: 30ms
      http:
        h2UpgradePolicy: DEFAULT
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
        maxRequestsPerConnection: 100
        maxRetries: 3
    loadBalancer:
      simple: LEAST_CONN
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

### Telemetry Configuration

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
  - providers:
    - name: envoy
  metrics:
  - providers:
    - name: prometheus
  tracing:
  - providers:
    - name: jaeger
    randomSamplingPercentage: 100
```

---

## 6. Core Concepts

### VirtualService

Defines routing rules for traffic:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
  - my-app
  http:
  - match:
    - headers:
        x-user-type:
          exact: "premium"
    route:
    - destination:
        host: my-app
        subset: v2
  - route:
    - destination:
        host: my-app
        subset: v1
      weight: 90
    - destination:
        host: my-app
        subset: v2
      weight: 10
```

### DestinationRule

Defines policies for traffic:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 3m
```

### Gateway

Defines load balancer for mesh traffic:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.example.com"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: my-tls-secret
    hosts:
    - "*.example.com"
```

### ServiceEntry

Defines external services:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-api
spec:
  hosts:
  - api.external.com
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: DNS
  location: MESH_EXTERNAL
```

---

## 7. Usage Guide

### Step-by-Step: Basic Traffic Management

#### 1. Enable Sidecar Injection

```bash
kubectl label namespace default istio-injection=enabled
```

#### 2. Deploy Application

```yaml
# deployment.yaml
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
        version: v1
    spec:
      containers:
      - name: my-app
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```

#### 3. Create VirtualService

```yaml
# virtualservice.yaml
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
        host: my-app
        subset: v1
      weight: 90
    - destination:
        host: my-app
        subset: v2
      weight: 10
```

#### 4. Create DestinationRule

```yaml
# destinationrule.yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

#### 5. Apply and Verify

```bash
kubectl apply -f deployment.yaml
kubectl apply -f virtualservice.yaml
kubectl apply -f destinationrule.yaml

# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check DestinationRule
kubectl get destinationrule my-app -o yaml

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Step-by-Step: Security (mTLS)

#### 1. Enable mTLS

```yaml
# peerauthentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

#### 2. Create AuthorizationPolicy

```yaml
# authorizationpolicy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-app
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/default/sa/my-app"
    to:
    - operation:
        methods: ["GET"]
```

#### 3. Apply and Verify

```bash
kubectl apply -f peerauthentication.yaml
kubectl apply -f authorizationpolicy.yaml

# Check mTLS status
istioctl x describe pod my-app-pod

# Check authorization
istioctl authn tls-check my-app-pod my-app.default.svc.cluster.local
```

---

## 8. Custom Configuration

### Custom Load Balancing

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    loadBalancer:
      consistentHash:
        httpHeaderName: x-user-id
```

### Custom Retry Policy

```yaml
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
        host: my-app
    retries:
      attempts: 3
      perTryTimeout: 2s
      retryOn: 5xx
```

### Custom Circuit Breaking

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

### Custom Fault Injection

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
  - my-app
  http:
  - fault:
      delay:
        percentage:
          value: 10
        fixedDelay: 5s
      abort:
        percentage:
          value: 5
        httpStatus: 500
    route:
    - destination:
        host: my-app
```

---

## 9. Integration

### ArgoCD Integration

```yaml
# Application with Istio
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

### Prometheus Integration

```yaml
# ServiceMonitor for Istio
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-mesh
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: pilot
  endpoints:
  - port: http-monitoring
    interval: 30s
```

### Jaeger Integration

```yaml
# Jaeger deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: istio-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:latest
        ports:
        - containerPort: 16686
        - containerPort: 14268
```

---

## 10. Security

### mTLS Configuration

```yaml
# Strict mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT

# Permissive mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: PERMISSIVE
```

### Authorization Policies

```yaml
# Allow all traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-all
  namespace: default
spec:
  {}
---
# Deny all traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  {}  # Empty spec means deny all
---
# Allow specific traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-app
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/default/sa/my-app"
    to:
    - operation:
        methods: ["GET"]
```

### JWT Authentication

```yaml
# RequestAuthentication
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  jwtRules:
  - issuer: "https://auth.example.com"
    jwksUri: "https://auth.example.com/.well-known/jwks.json"
```

### RBAC Configuration

```yaml
# AuthorizationPolicy with RBAC
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-app-rbac
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/default/sa/admin"
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
  - from:
    - source:
        principals:
        - "cluster.local/ns/default/sa/viewer"
    to:
    - operation:
        methods: ["GET"]
```

---

## 11. Troubleshooting

### Issue 1: Sidecar Injection Failed

```bash
# Check namespace label
kubectl get namespace default -o yaml | grep istio-injection

# Check sidecar injection pod
kubectl -n istio-system get pods -l app=istiod

# Check injection webhook
kubectl get mutatingwebhookconfigurations

# Restart pod to trigger injection
kubectl delete pod my-app-pod
```

### Issue 2: Traffic Not Routing

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check DestinationRule
kubectl get destinationrule my-app -o yaml

# Check Gateway
kubectl get gateway my-gateway -o yaml

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 3: mTLS Not Working

```bash
# Check PeerAuthentication
kubectl get peerauthentication -A

# Check mTLS status
istioctl x describe pod my-app-pod

# Check certificates
istioctl authn tls-check my-app-pod my-app.default.svc.cluster.local

# Check proxy config
istioctl proxy-config listener my-app-pod
```

### Issue 4: Authorization Denied

```bash
# Check AuthorizationPolicy
kubectl get authorizationpolicy -A

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Check authorization
istioctl authz check my-app-pod

# Check proxy config
istioctl proxy-config listener my-app-pod
```

### Issue 5: Proxy Not Starting

```bash
# Check proxy pod
kubectl get pods -l app=my-app

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Check proxy config
istioctl proxy-config listener my-app-pod

# Check proxy status
istioctl proxy-status
```

### Issue 6: Gateway Not Receiving Traffic

```bash
# Check Gateway
kubectl get gateway my-gateway -o yaml

# Check ingress gateway pods
kubectl -n istio-system get pods -l app=istio-ingressgateway

# Check ingress gateway service
kubectl -n istio-system get svc istio-ingressgateway

# Test traffic
curl http://my-app.example.com
```

### Issue 7: VirtualService Not Working

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check proxy config
istioctl proxy-config route my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 8: DestinationRule Not Working

```bash
# Check DestinationRule
kubectl get destinationrule my-app -o yaml

# Check subsets
istioctl proxy-config cluster my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 9: mTLS Conflict

```bash
# Check PeerAuthentication
kubectl get peerauthentication -A

# Check mTLS mode
istioctl x describe pod my-app-pod

# Check proxy config
istioctl proxy-config listener my-app-pod

# Fix mTLS mode
kubectl patch peerauthentication default -n istio-system --type merge -p '{"spec":{"mtls":{"mode":"STRICT"}}}'
```

### Issue 10: Authorization Policy Conflict

```bash
# Check AuthorizationPolicy
kubectl get authorizationpolicy -A

# Check proxy config
istioctl proxy-config listener my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Fix authorization policy
kubectl delete authorizationpolicy my-app
kubectl apply -f authorizationpolicy.yaml
```

### Issue 11: Proxy Configuration Error

```bash
# Check proxy config
istioctl proxy-config listener my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Check proxy status
istioctl proxy-status

# Restart proxy
kubectl delete pod my-app-pod
```

### Issue 12: Traffic Splitting Not Working

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check weights
istioctl proxy-config route my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 13: Circuit Breaking Not Working

```bash
# Check DestinationRule
kubectl get destinationrule my-app -o yaml

# Check circuit breaking
istioctl proxy-config cluster my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Test circuit breaking
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 14: Fault Injection Not Working

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check fault injection
istioctl proxy-config route my-app-pod

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Test fault injection
kubectl exec -it my-app-pod -- curl my-app
```

### Issue 15: Observability Not Working

```bash
# Check telemetry
kubectl get telemetry -A

# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Check metrics
kubectl port-forward -n istio-system svc/prometheus 9090:9090

# Check tracing
kubectl port-forward -n istio-system svc/jaeger 16686:16686
```

---

## 12. Tips and Best Practices

### Tip 1: Use Default Profile for Development

```bash
istioctl install --set profile=default -y
```

### Tip 2: Use Demo Profile for Testing

```bash
istioctl install --set profile=demo -y
```

### Tip 3: Use Production Profile for Production

```bash
istioctl install --set profile=production -y
```

### Tip 4: Enable Sidecar Injection for All Namespaces

```bash
kubectl label namespace default istio-injection=enabled
```

### Tip 5: Use VirtualService for Traffic Management

```yaml
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
        host: my-app
      weight: 90
    - destination:
        host: my-app
      weight: 10
```

### Tip 6: Use DestinationRule for Traffic Policies

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
```

### Tip 7: Use Gateway for External Traffic

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.example.com"
```

### Tip 8: Use PeerAuthentication for mTLS

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

### Tip 9: Use AuthorizationPolicy for Access Control

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-app
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/default/sa/my-app"
    to:
    - operation:
        methods: ["GET"]
```

### Tip 10: Use RequestAuthentication for JWT

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  jwtRules:
  - issuer: "https://auth.example.com"
    jwksUri: "https://auth.example.com/.well-known/jwks.json"
```

### Tip 11: Use Telemetry for Observability

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
  - providers:
    - name: envoy
  metrics:
  - providers:
    - name: prometheus
  tracing:
  - providers:
    - name: jaeger
    randomSamplingPercentage: 100
```

### Tip 12: Use ServiceEntry for External Services

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-api
spec:
  hosts:
  - api.external.com
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: DNS
  location: MESH_EXTERNAL
```

### Tip 13: Use DestinationRule for Circuit Breaking

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

### Tip 14: Use VirtualService for Fault Injection

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
  - my-app
  http:
  - fault:
      delay:
        percentage:
          value: 10
        fixedDelay: 5s
      abort:
        percentage:
          value: 5
        httpStatus: 500
    route:
    - destination:
        host: my-app
```

### Tip 15: Use Istioctl for Debugging

```bash
# Check proxy status
istioctl proxy-status

# Check proxy config
istioctl proxy-config listener my-app-pod

# Describe pod
istioctl x describe pod my-app-pod

# Analyze configuration
istioctl analyze
```

### Tip 16: Use Istioctl for Configuration

```bash
# Install Istio
istioctl install --set profile=default -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled

# Check installation
istioctl verify-install
```

---

## 13. Command Reference

### Installation Commands

```bash
# Install Istio
istioctl install --set profile=default -y

# Verify installation
istioctl verify-install

# Uninstall Istio
istioctl uninstall --purge -y

# Remove namespace
kubectl delete namespace istio-system
```

### Configuration Commands

```bash
# Check proxy status
istioctl proxy-status

# Check proxy config
istioctl proxy-config listener my-app-pod

# Describe pod
istioctl x describe pod my-app-pod

# Analyze configuration
istioctl analyze

# Check authorization
istioctl authz check my-app-pod

# Check mTLS
istioctl authn tls-check my-app-pod my-app.default.svc.cluster.local
```

### Debugging Commands

```bash
# Check proxy logs
kubectl logs my-app-pod -c istio-proxy

# Check proxy config
istioctl proxy-config listener my-app-pod

# Check proxy status
istioctl proxy-status

# Analyze configuration
istioctl analyze
```

### Traffic Commands

```bash
# Check VirtualService
kubectl get virtualservice my-app -o yaml

# Check DestinationRule
kubectl get destinationrule my-app -o yaml

# Check Gateway
kubectl get gateway my-gateway -o yaml

# Test traffic
kubectl exec -it my-app-pod -- curl my-app
```

### Security Commands

```bash
# Check PeerAuthentication
kubectl get peerauthentication -A

# Check AuthorizationPolicy
kubectl get authorizationpolicy -A

# Check RequestAuthentication
kubectl get requestauthentication -A

# Check mTLS
istioctl x describe pod my-app-pod
```

---

## 14. CRD Reference

### VirtualService

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: string
  namespace: string
spec:
  hosts:
  - string
  http:
  - match:
    - uri:
        prefix: string
      headers:
        x-user-type:
          exact: string
    route:
    - destination:
        host: string
        subset: string
        port:
          number: integer
      weight: integer
    retries:
      attempts: integer
      perTryTimeout: string
      retryOn: string
    fault:
      delay:
        percentage:
          value: float
        fixedDelay: string
      abort:
        percentage:
          value: float
        httpStatus: integer
  tcp:
  - match:
    - port: integer
    route:
    - destination:
        host: string
        subset: string
```

### DestinationRule

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: string
  namespace: string
spec:
  host: string
  subsets:
  - name: string
    labels:
      version: string
  trafficPolicy:
    loadBalancer:
      simple: string
      consistentHash:
        httpHeaderName: string
    connectionPool:
      tcp:
        maxConnections: integer
        connectTimeout: string
      http:
        h2UpgradePolicy: string
        http1MaxPendingRequests: integer
        http2MaxRequests: integer
        maxRequestsPerConnection: integer
        maxRetries: integer
    outlierDetection:
      consecutive5xxErrors: integer
      interval: string
      baseEjectionTime: string
      maxEjectionPercent: integer
```

### Gateway

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: string
  namespace: string
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: integer
      name: string
      protocol: string
    hosts:
    - string
    tls:
      mode: string
      credentialName: string
```

### ServiceEntry

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: string
  namespace: string
spec:
  hosts:
  - string
  ports:
  - number: integer
    name: string
    protocol: string
  resolution: string
  location: string
```

### PeerAuthentication

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: string
  namespace: string
spec:
  selector:
    matchLabels:
      app: string
  mtls:
    mode: string
  portLevelMtls:
    8080:
      mode: string
```

### AuthorizationPolicy

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: string
  namespace: string
spec:
  selector:
    matchLabels:
      app: string
  rules:
  - from:
    - source:
        principals:
        - string
        namespaces:
        - string
    to:
    - operation:
        methods:
        - string
        paths:
        - string
    when:
    - key: string
      values:
      - string
```

### RequestAuthentication

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: string
  namespace: string
spec:
  selector:
    matchLabels:
      app: string
  jwtRules:
  - issuer: string
    jwksUri: string
    jwks: string
    audiences:
    - string
    forwardOriginalToken: boolean
```

### Telemetry

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: string
  namespace: string
spec:
  accessLogging:
  - providers:
    - name: string
  metrics:
  - providers:
    - name: string
  tracing:
  - providers:
    - name: string
    randomSamplingPercentage: float
```

---

## 15. Real-World Examples

### Example 1: Production Traffic Management

```yaml
# VirtualService for production
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: production-app
  namespace: production
spec:
  hosts:
  - production-app.example.com
  gateways:
  - production-gateway
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: production-app
        subset: v1
      weight: 90
    - destination:
        host: production-app
        subset: v2
      weight: 10
    retries:
      attempts: 3
      perTryTimeout: 2s
      retryOn: 5xx
---
# DestinationRule for production
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: production-app
  namespace: production
spec:
  host: production-app
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 3m
```

### Example 2: Security Configuration

```yaml
# PeerAuthentication for production
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
---
# AuthorizationPolicy for production
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: production-app
  namespace: production
spec:
  selector:
    matchLabels:
      app: production-app
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/production/sa/production-app"
    to:
    - operation:
        methods: ["GET", "POST"]
```

### Example 3: Observability Configuration

```yaml
# Telemetry for production
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
  - providers:
    - name: envoy
  metrics:
  - providers:
    - name: prometheus
  tracing:
  - providers:
    - name: jaeger
    randomSamplingPercentage: 100
---
# ServiceMonitor for Istio
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-mesh
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: pilot
  endpoints:
  - port: http-monitoring
    interval: 30s
```

---

## 16. Further Reading

### Official Documentation

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio GitHub](https://github.com/istio/istio)
- [Istio Configuration](https://istio.io/latest/docs/reference/config/)

### Tutorials and Guides

- [Getting Started with Istio](https://istio.io/latest/docs/setup/getting-started/)
- [Traffic Management](https://istio.io/latest/docs/tasks/traffic-management/)
- [Security](https://istio.io/latest/docs/tasks/security/)

### Community Resources

- [Istio Slack](https://istio.io/latest/community/join-slack/)
- [Istio Blog](https://istio.io/latest/blog/)
- [Istio Examples](https://istio.io/latest/examples/)

### Books and Courses

- "Istio in Action" by Christian Posta
- "Learning Istio" by Christian Posta
- "Istio Up and Running" by Lee Calcote, Zack Butcher
