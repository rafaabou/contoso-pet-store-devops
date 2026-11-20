# Contoso Pet Store — Complete Deployment Guide

**Version 2.0 | Target Platform: k3s Cluster | Last Updated: September 2026**

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Building Container Images](#3-building-container-images)
4. [Helm Chart](#4-helm-chart)
5. [Deployment Steps](#5-deployment-steps)
6. [Networking](#6-networking)
7. [Storage](#7-storage)
8. [Secrets Management](#8-secrets-management)
9. [Security Hardening](#9-security-hardening)
10. [Monitoring](#10-monitoring)
11. [Logging](#11-logging)
12. [Tracing](#12-tracing)
13. [CI/CD Pipeline](#13-cicd-pipeline)
14. [Scaling](#14-scaling)
15. [Troubleshooting](#15-troubleshooting)
16. [Tips & Best Practices](#16-tips--best-practices)
17. [Full YAML Examples](#17-full-yaml-examples)

---

## 1. Architecture Overview

### 1.1 Application Summary

The Contoso Pet Store is a cloud-native reference application built with polyglot microservices. Each service is implemented in a different language and framework to demonstrate cross-service communication patterns in a realistic e-commerce scenario.

### 1.2 The 8 Microservices

| Service | Language | Framework | Port | Description |
|---------|----------|-----------|------|-------------|
| `ai-service` | Python 3.11 | FastAPI | 8080 | AI-powered product recommendations, pet health Q&A, image analysis |
| `makeline-service` | Go 1.21 | Gin | 8081 | Order fulfillment pipeline, batch processing, inventory updates |
| `order-service` | Node.js 20 | Fastify | 8082 | Order lifecycle management, cart operations, payment orchestration |
| `product-service` | Rust 1.75 | Actix-Web | 8083 | Product catalog CRUD, search, pricing, stock levels |
| `store-front` | Vue.js 3 | Vite/Nginx | 80 | Customer-facing SPA, product browsing, checkout |
| `store-admin` | Vue.js 3 | Vite/Nginx | 80 | Admin dashboard, order management, analytics |
| `virtual-customer` | Rust | Tokio | 8084 | Load generator: simulates customer browsing and purchasing |
| `virtual-worker` | Rust | Tokio | 8085 | Load generator: simulates back-office order processing |

### 1.3 Service Dependency Map

```
                         ┌─────────────────────────────────┐
                         │         INGRESS CONTROLLER       │
                         │       (NGINX Ingress / 443)      │
                         └───────┬───────────────┬──────────┘
                                 │               │
                    ┌────────────▼──┐   ┌────────▼─────────┐
                    │  store-front  │   │   store-admin    │
                    │   (Vue.js)    │   │    (Vue.js)      │
                    └──────┬────────┘   └────────┬─────────┘
                           │                     │
            ┌──────────────┼─────────────────────┼──────────────┐
            │              │         REST / gRPC  │              │
            ▼              ▼                      ▼              ▼
    ┌──────────────┐ ┌──────────────┐  ┌──────────────┐ ┌────────────┐
    │ order-service│ │product-service│ │ ai-service   │ │makeline-svc│
    │  (Fastify)   │ │  (Actix)     │  │  (FastAPI)   │ │   (Gin)    │
    └──────┬───────┘ └──────┬───────┘  └──────────────┘ └─────┬──────┘
           │                │                                  │
           │     ┌──────────┴──────────┐                     │
           │     │    PostgreSQL 16    │                     │
           │     │   (petstore-db)     │◄────────────────────┘
           │     └─────────────────────┘
           │
    ┌──────┴───────────────────────────┐
    │         Redis 7 (cache)          │
    └──────────────────────────────────┘

    ┌──────────────┐   ┌──────────────┐
    │virtual-customer│  │virtual-worker │
    │  (Rust/Tokio) │  │  (Rust/Tokio) │
    │  → order-svc  │  │  → makeline   │
    └──────────────┘   └──────────────┘
```

### 1.4 Communication Patterns

**Synchronous (REST/HTTP):**
- `store-front` → `product-service` (product listing, search)
- `store-front` → `order-service` (create order, check status)
- `store-admin` → `order-service` (manage orders)
- `store-admin` → `product-service` (manage products)
- `order-service` → `ai-service` (recommendations)
- `virtual-customer` → `order-service` (simulated orders)
- `virtual-worker` → `makeline-service` (simulated processing)

**Asynchronous (Redis pub/sub / message queue):**
- `order-service` → `makeline-service` (new order events via Redis streams)
- `makeline-service` → `order-service` (order status updates)
- `ai-service` → `product-service` (recommendation cache invalidation)

### 1.5 Data Flow

```
Customer Request Flow:
─────────────────────
Browser → Ingress(443) → store-front → product-service → PostgreSQL
                        store-front → order-service → Redis (queue)
                                                    → PostgreSQL (orders)
                                                    → ai-service (recommendations)

Fulfillment Flow:
─────────────────
Redis Stream ← order-service (publish "new_order")
              → makeline-service (subscribe, process batch)
              → PostgreSQL (update order status)
              → order-service (callback: status update)
```

---

## 2. Prerequisites

### 2.1 Cluster Requirements

Your k3s cluster must be running with the following components:

```bash
# Verify cluster is operational
kubectl cluster-info
kubectl get nodes -o wide

# Expected output: at least 1 master + 2 workers, all Ready
```

**Required components and their expected versions:**

| Component | Version | Purpose |
|-----------|---------|---------|
| k3s | ≥1.28 | Kubernetes distribution |
| MetalLB | ≥0.13 | LoadBalancer IP allocation |
| cert-manager | ≥1.13 | TLS certificate management |
| NGINX Ingress | ≥1.9 | Ingress controller |
| Helm | ≥3.13 | Package management |
| kubectl | ≥1.28 | CLI for Kubernetes |
| ArgoCD | ≥2.9 | GitOps continuous deployment |
| Prometheus + Grafana | — | Monitoring stack |
| Vault | ≥1.15 | Secrets management |
| Loki + Promtail | — | Log aggregation |

### 2.2 Quick Validation Script

```bash
#!/bin/bash
set -e

echo "=== Contoso Pet Store — Prerequisites Check ==="

# 1. Cluster nodes
echo "[1/8] Checking cluster nodes..."
kubectl get nodes --no-headers 2>/dev/null | grep -q "Ready" && echo "  ✓ Nodes Ready" || { echo "  ✗ No nodes Ready"; exit 1; }

# 2. MetalLB
echo "[2/8] Checking MetalLB..."
kubectl get pods -n metallb-system -l app.kubernetes.io/name=metallb --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ MetalLB Running" || echo "  ✗ MetalLB not found"

# 3. cert-manager
echo "[3/8] Checking cert-manager..."
kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ cert-manager Running" || echo "  ✗ cert-manager not found"

# 4. NGINX Ingress
echo "[4/8] Checking NGINX Ingress..."
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ NGINX Ingress Running" || echo "  ✗ NGINX Ingress not found"

# 5. Helm
echo "[5/8] Checking Helm..."
helm version --short 2>/dev/null && echo "  ✓ Helm installed" || echo "  ✗ Helm not found"

# 6. ArgoCD
echo "[6/8] Checking ArgoCD..."
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ ArgoCD Running" || echo "  ✗ ArgoCD not found"

# 7. Prometheus
echo "[7/8] Checking Prometheus..."
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ Prometheus Running" || echo "  ✗ Prometheus not found"

# 8. Vault
echo "[8/8] Checking Vault..."
kubectl get pods -n vault -l app.kubernetes.io/name=vault --no-headers 2>/dev/null | grep -q "Running" && echo "  ✓ Vault Running" || echo "  ✗ Vault not found"

echo ""
echo "=== Prerequisites check complete ==="
```

### 2.3 Required Tools on Your Workstation

```bash
# Core
kubectl version --client          # ≥1.28
helm version                      # ≥3.13
argocd version                    # ≥2.9
vault --version                   # ≥1.15

# Optional but recommended
k9s                               # Cluster UI
stern                             # Multi-pod log tailing
kubectx / kubens                  # Context/namespace switching
```

---

## 3. Building Container Images

### 3.1 Docker Registry Setup

If you don't have an external registry, use the built-in k3s registry:

```bash
# Create registry namespace and deployment
kubectl create namespace registry

cat <<'EOF' | kubectl apply -n registry -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: data
              mountPath: /var/lib/registry
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: registry-data
---
apiVersion: v1
kind: Service
metadata:
  name: registry
spec:
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: registry-config
data:
  config.yml: |
    version: 0.1
    log:
      fields:
        service: registry
    storage:
      cache:
        blobdescriptor: inmemory
    http:
      addr: :5000
      headers:
        X-Content-Type-Options: [nosniff]
        Access-Control-Allow-Origin: ['*']
        Access-Control-Allow-Methods: ['HEAD', 'GET', 'OPTIONS', 'DELETE']
        Access-Control-Allow-Headers: ['Authorization', 'Accept', 'Cache-Control']
EOF

kubectl rollout status deployment/registry -n registry
```

**Configure nodes to trust the local registry:**

```bash
# On each node, add to /etc/rancher/k3s/registries.yaml
cat <<'EOF' > /etc/rancher/k3s/registries.yaml
mirrors:
  "registry.contoso.local":
    endpoint:
      - "http://registry.registry.svc.cluster.local:5000"
EOF

# Restart k3s on each node
systemctl restart k3s
```

### 3.2 Multi-Stage Dockerfiles

Every service uses a multi-stage build for minimal image size and no build tools in production.

#### ai-service (Python/FastAPI)

```dockerfile
# ai-service/Dockerfile
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY . .

FROM python:3.11-slim AS runtime

RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY --from=builder /install /usr/local
COPY --from=builder /app /app

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "4"]
```

#### makeline-service (Go/Gin)

```dockerfile
# makeline-service/Dockerfile
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -ldflags="-s -w" -o /makeline-service .

FROM gcr.io/distroless/static-debian12 AS runtime

COPY --from=builder /makeline-service /makeline-service

EXPOSE 8081
ENTRYPOINT ["/makeline-service"]
```

#### order-service (Node.js/Fastify)

```dockerfile
# order-service/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

FROM node:20-alpine AS runtime

RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app .

USER appuser

EXPOSE 8082
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:8082/health || exit 1

CMD ["node", "server.js"]
```

#### product-service (Rust/Actix)

```dockerfile
# product-service/Dockerfile
FROM rust:1.75-slim AS builder

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
# Create dummy main.rs to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release 2>/dev/null || true
RUN rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=builder /app/target/release/product-service /product-service

USER appuser
EXPOSE 8083
CMD ["/product-service"]
```

#### store-front (Vue.js/Nginx)

```dockerfile
# store-front/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:1.25-alpine AS runtime

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### store-admin (Vue.js/Nginx)

```dockerfile
# store-admin/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:1.25-alpine AS runtime

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### virtual-customer (Rust)

```dockerfile
# virtual-customer/Dockerfile
FROM rust:1.75-slim AS builder

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release 2>/dev/null || true
RUN rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=builder /app/target/release/virtual-customer /virtual-customer

USER appuser
ENTRYPOINT ["/virtual-customer"]
```

#### virtual-worker (Rust)

```dockerfile
# virtual-worker/Dockerfile
FROM rust:1.75-slim AS builder

RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release 2>/dev/null || true
RUN rm -rf src

COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y libssl3 ca-certificates && rm -rf /var/lib/apt/lists/*
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=builder /app/target/release/virtual-worker /virtual-worker

USER appuser
ENTRYPOINT ["/virtual-worker"]
```

### 3.3 Build and Push All Images

```bash
#!/bin/bash
# build-all.sh
set -euo pipefail

REGISTRY="registry.contoso.local:5000"
TAG="${1:-latest}"
SERVICES="ai-service makeline-service order-service product-service store-front store-admin virtual-customer virtual-worker"

echo "=== Building all services with tag: ${TAG} ==="

for svc in ${SERVICES}; do
  echo ""
  echo "--- Building ${svc} ---"
  
  # Enable BuildKit for faster, more secure builds
  DOCKER_BUILDKIT=1 docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from "${REGISTRY}/${svc}:${TAG}" \
    -t "${REGISTRY}/${svc}:${TAG}" \
    -t "${REGISTRY}/${svc}:latest" \
    -f "${svc}/Dockerfile" \
    "${svc}/"
  
  echo "Pushing ${svc}:${TAG}..."
  docker push "${REGISTRY}/${svc}:${TAG}"
  docker push "${REGISTRY}/${svc}:latest"
  
  echo "✓ ${svc} built and pushed"
done

echo ""
echo "=== All images built and pushed to ${REGISTRY} ==="
```

### 3.4 Image Scanning with Trivy

```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan all images
for svc in ai-service makeline-service order-service product-service store-front store-admin virtual-customer virtual-worker; do
  echo "--- Scanning ${svc} ---"
  trivy image --severity HIGH,CRITICAL "${REGISTRY}/${svc}:${TAG}"
done
```

---

## 4. Helm Chart

### 4.1 Chart Structure

```
contoso-petstore/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgresql/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── redis/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── ai-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── networkpolicy.yaml
│   ├── makeline-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── networkpolicy.yaml
│   ├── order-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── networkpolicy.yaml
│   ├── product-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── networkpolicy.yaml
│   ├── store-front/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── store-admin/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── virtual-customer/
│   │   └── deployment.yaml
│   ├── virtual-worker/
│   │   └── deployment.yaml
│   ├── networkpolicy.yaml
│   ├── servicemonitor.yaml
│   ├── poddisruptionbudget.yaml
│   └── serviceaccount.yaml
├── charts/
└── tests/
    └── test-connection.yaml
```

### 4.2 Chart.yaml

```yaml
# contoso-petstore/Chart.yaml
apiVersion: v2
name: contoso-petstore
description: Contoso Pet Store — polyglot microservices reference application
type: application
version: 1.0.0
appVersion: "2.0.0"
keywords:
  - microservices
  - e-commerce
  - polyglot
  - reference-architecture
maintainers:
  - name: Platform Team
    email: platform@contoso.com
dependencies:
  - name: postgresql
    version: "13.2.24"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  - name: redis
    version: "18.6.1"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

### 4.3 values.yaml

```yaml
# contoso-petstore/values.yaml
global:
  imageRegistry: "registry.contoso.local:5000"
  imagePullPolicy: IfNotPresent

namespace:
  create: true
  name: petstore

# ────────────────────────────────
# Infrastructure Dependencies
# ────────────────────────────────
postgresql:
  enabled: true
  auth:
    postgresPassword: ""  # Set via --set or sealed secret
    username: petstore
    password: ""  # Set via --set or sealed secret
    database: petstore
  primary:
    persistence:
      size: 10Gi
      storageClass: nfs-client
    resources:
      requests:
        cpu: 250m
        memory: 512Mi
      limits:
        cpu: "1"
        memory: 1Gi

redis:
  enabled: true
  architecture: standalone
  auth:
    enabled: true
    password: ""  # Set via --set or sealed secret
  master:
    persistence:
      size: 5Gi
      storageClass: nfs-client
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi

# ────────────────────────────────
# Application Services
# ────────────────────────────────
aiService:
  enabled: true
  replicaCount: 2
  image:
    repository: ai-service
    tag: "latest"
  ports:
    http: 8080
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: "1"
      memory: 1Gi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

makelineService:
  enabled: true
  replicaCount: 2
  image:
    repository: makeline-service
    tag: "latest"
  ports:
    http: 8081
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

orderService:
  enabled: true
  replicaCount: 2
  image:
    repository: order-service
    tag: "latest"
  ports:
    http: 8082
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: "1"
      memory: 512Mi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

productService:
  enabled: true
  replicaCount: 2
  image:
    repository: product-service
    tag: "latest"
  ports:
    http: 8083
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

storeFront:
  enabled: true
  replicaCount: 2
  image:
    repository: store-front
    tag: "latest"
  ports:
    http: 80
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

storeAdmin:
  enabled: true
  replicaCount: 1
  image:
    repository: store-admin
    tag: "latest"
  ports:
    http: 80
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

virtualCustomer:
  enabled: false  # Disabled by default — load generator
  replicaCount: 1
  image:
    repository: virtual-customer
    tag: "latest"
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi

virtualWorker:
  enabled: false  # Disabled by default — load generator
  replicaCount: 1
  image:
    repository: virtual-worker
    tag: "latest"
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi

# ────────────────────────────────
# Ingress
# ────────────────────────────────
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: petstore.contoso.local
      paths:
        - path: /
          pathType: Prefix
          service: store-front
          port: 80
    - host: admin.petstore.contoso.local
      paths:
        - path: /
          pathType: Prefix
          service: store-admin
          port: 80
  tls:
    - secretName: petstore-tls
      hosts:
        - petstore.contoso.local
        - admin.petstore.contoso.local

# ────────────────────────────────
# Security
# ────────────────────────────────
serviceAccount:
  create: true
  name: petstore-sa
  annotations: {}

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL

# ────────────────────────────────
# Monitoring
# ────────────────────────────────
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s

# ────────────────────────────────
# Networking
# ────────────────────────────────
networkPolicy:
  enabled: true
```

### 4.4 Template: Deployment (Generic)

```yaml
# templates/ai-service/deployment.yaml
{{- if .Values.aiService.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-ai-service
  namespace: {{ .Values.namespace.name }}
  labels:
    app.kubernetes.io/name: ai-service
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/version: {{ .Values.aiService.image.tag }}
    app.kubernetes.io/component: backend
spec:
  replicas: {{ .Values.aiService.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: ai-service
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ai-service
        app.kubernetes.io/instance: {{ .Release.Name }}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "{{ .Values.aiService.ports.http }}"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: ai-service
          image: "{{ .Values.global.imageRegistry }}/{{ .Values.aiService.image.repository }}:{{ .Values.aiService.image.tag }}"
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.aiService.ports.http }}
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-db-credentials
                  key: url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: {{ .Release.Name }}-redis-credentials
                  key: url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://{{ .Release.Name }}-otel-collector:4317"
            - name: SERVICE_NAME
              value: "ai-service"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30
          resources:
            {{- toYaml .Values.aiService.resources | nindent 12 }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
```

### 4.5 Template: Service

```yaml
# templates/ai-service/service.yaml
{{- if .Values.aiService.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-ai-service
  namespace: {{ .Values.namespace.name }}
  labels:
    app.kubernetes.io/name: ai-service
    app.kubernetes.io/instance: {{ .Release.Name }}
  annotations:
    {{- if .Values.metrics.serviceMonitor.enabled }}
    prometheus.io/scrape: "true"
    prometheus.io/port: "{{ .Values.aiService.ports.http }}"
    prometheus.io/path: "/metrics"
    {{- end }}
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: ai-service
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - name: http
      port: {{ .Values.aiService.ports.http }}
      targetPort: http
      protocol: TCP
{{- end }}
```

### 4.6 Template: Ingress

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
  namespace: {{ .Values.namespace.name }}
  labels:
    app.kubernetes.io/name: {{ .Release.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
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
                name: {{ .service }}
                port:
                  number: {{ .port }}
          {{- end }}
    {{- end }}
{{- end }}
```

### 4.7 Template: HPA

```yaml
# templates/ai-service/hpa.yaml
{{- if and .Values.aiService.enabled .Values.aiService.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Release.Name }}-ai-service
  namespace: {{ .Values.namespace.name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Release.Name }}-ai-service
  minReplicas: {{ .Values.aiService.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.aiService.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.aiService.autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
{{- end }}
```

### 4.8 Template: NetworkPolicy

```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Release.Name }}-default-deny
  namespace: {{ .Values.namespace.name }}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Release.Name }}-allow-dns
  namespace: {{ .Values.namespace.name }}
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to: []
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Release.Name }}-order-service
  namespace: {{ .Values.namespace.name }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: order-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: store-front
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: store-admin
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: virtual-customer
      ports:
        - port: 8082
          protocol: TCP
  egress:
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: postgresql
      ports:
        - port: 5432
          protocol: TCP
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: redis
      ports:
        - port: 6379
          protocol: TCP
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ai-service
      ports:
        - port: 8080
          protocol: TCP
{{- end }}
```

### 4.9 Template: ConfigMap

```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
  namespace: {{ .Values.namespace.name }}
data:
  # AI Service
  AI_SERVICE_MODEL: "gpt-4-turbo"
  AI_SERVICE_MAX_TOKENS: "2048"
  AI_SERVICE_TEMPERATURE: "0.7"

  # Order Service
  ORDER_SERVICE_MAX_RETRY: "3"
  ORDER_SERVICE_TIMEOUT_MS: "5000"
  ORDER_SERVICE_BATCH_SIZE: "50"

  # Product Service
  PRODUCT_SERVICE_CACHE_TTL: "300"
  PRODUCT_SERVICE_MAX_RESULTS: "100"

  # Makeline Service
  MAKELINE_BATCH_SIZE: "10"
  MAKELINE_POLL_INTERVAL_MS: "1000"

  # Common
  LOG_LEVEL: "info"
  OTEL_SERVICE_NAME: "contoso-petstore"
  OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=production"
```

---

## 5. Deployment Steps

### 5.1 Create Namespace and Secrets

```bash
# Create namespace
kubectl create namespace petstore

# Create database credentials (replace with your values)
kubectl create secret generic petstore-db-credentials \
  --namespace petstore \
  --from-literal=url="postgresql://petstore:$(openssl rand -hex 16)@petstore-postgresql:5432/petstore" \
  --from-literal=username="petstore" \
  --from-literal=password="$(openssl rand -hex 16)"

# Create Redis credentials
kubectl create secret generic petstore-redis-credentials \
  --namespace petstore \
  --from-literal=url="redis://:$(openssl rand -hex 16)@petstore-redis-master:6379" \
  --from-literal=password="$(openssl rand -hex 16)"
```

### 5.2 Deploy via Helm

```bash
# From the chart directory
cd contoso-petstore/

# Install/upgrade the chart
helm upgrade --install petstore . \
  --namespace petstore \
  --values values.yaml \
  --set postgresql.auth.postgresPassword="$(openssl rand -hex 16)" \
  --set postgresql.auth.password="$(openssl rand -hex 16)" \
  --set redis.auth.password="$(openssl rand -hex 16)" \
  --wait \
  --timeout 10m

# Verify all pods are running
kubectl get pods -n petstore -w
```

### 5.3 Verify Deployment

```bash
# Check all deployments
kubectl get deployments -n petstore

# Expected output:
# NAME                        READY   UP-TO-DATE   AVAILABLE
# petstore-ai-service         2/2     2            2
# petstore-makeline-service   2/2     2            2
# petstore-order-service      2/2     2            2
# petstore-product-service    2/2     2            2
# petstore-store-front        2/2     2            2
# petstore-store-admin        1/1     1            1

# Check services
kubectl get svc -n petstore

# Check ingress
kubectl get ingress -n petstore

# Check certificates
kubectl get certificate -n petstore
```

### 5.4 Smoke Tests

```bash
# Port-forward and test each service
kubectl port-forward -n petstore svc/petstore-store-front 8080:80 &
sleep 2

# Test product listing
curl -s http://localhost:8080/api/products | head -c 200

# Test order creation
curl -s -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"items":[{"productId":"pet-001","quantity":1}]}'

# Test AI recommendations
curl -s http://localhost:8080/api/recommendations/user-001

# Test admin dashboard
curl -s http://localhost:8080/admin/ | head -c 100

# Cleanup
kill %1
```

---

## 6. Networking

### 6.1 Service Discovery

All services discover each other via Kubernetes DNS:

```
# From within the cluster:
petstore-ai-service.petstore.svc.cluster.local:8080
petstore-makeline-service.petstore.svc.cluster.local:8081
petstore-order-service.petstore.svc.cluster.local:8082
petstore-product-service.petstore.svc.cluster.local:8083
petstore-store-front.petstore.svc.cluster.local:80
petstore-store-admin.petstore.svc.cluster.local:80
petstore-postgresql.petstore.svc.cluster.local:5432
petstore-redis-master.petstore.svc.cluster.local:6379
```

Services can also use short names within the same namespace:
```
petstore-ai-service:8080
petstore-order-service:8082
```

### 6.2 Ingress Configuration

```yaml
# After deployment, verify the ingress
kubectl describe ingress petstore-ingress -n petstore

# The ingress controller routes:
# petstore.contoso.local → store-front
# admin.petstore.contoso.local → store-admin

# Add to /etc/hosts (or configure DNS)
echo "$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}') petstore.contoso.local admin.petstore.contoso.local" | sudo tee -a /etc/hosts
```

### 6.3 TLS with cert-manager

```yaml
# ClusterIssuer for Let's Encrypt
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@contoso.com
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

### 6.4 Internal Service Mesh (Optional)

For mTLS between services, consider adding Linkerd or Istio:

```bash
# Linkerd (lightweight)
curl -sL https://run.linkerd.io/install | sh
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# Inject sidecar proxies
kubectl get deploy -n petstore -o yaml | linkerd inject - | kubectl apply -f -
```

---

## 7. Storage

### 7.1 StorageClasses

```yaml
# NFS StorageClass (recommended for k3s)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: nfs-subdir-external-provisioner
parameters:
  server: 10.0.0.100
  path: /exports/k3s-volumes
  archiveOnDelete: "true"
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: Immediate
---
# Local-path StorageClass (k3s default, single-node only)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

### 7.2 PersistentVolumeClaims

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: petstore-postgresql-data
  namespace: petstore
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-client
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: petstore-redis-data
  namespace: petstore
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-client
  resources:
    requests:
      storage: 5Gi
```

### 7.3 Database Deployment

The PostgreSQL and Redis deployments are managed by the Helm chart dependencies (Bitnami subcharts). They are automatically deployed when `postgresql.enabled: true` and `redis.enabled: true`.

For production, consider:
- Using an external managed database (AWS RDS, Azure PostgreSQL)
- Setting up read replicas
- Configuring automated backups with `pg_dump` CronJobs
- Using PgBouncer for connection pooling

---

## 8. Secrets Management

### 8.1 Vault Integration

```bash
# Install Vault via Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set server.dev.enabled=true

# Initialize Vault (unseal after init)
kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1
kubectl exec -n vault vault-0 -- vault operator unseal <unseal-key>
```

### 8.2 Store Secrets in Vault

```bash
# Create secrets path
kubectl exec -n vault vault-0 -- vault secrets enable -path=petstore kv-v2

# Store database credentials
kubectl exec -n vault vault-0 -- vault kv put petstore/db-username value="petstore"
kubectl exec -n vault vault-0 -- vault kv put petstore/db-password value="s3cr3t-p@ss"
kubectl exec -n vault vault-0 -- vault kv put petstore/redis-password value="r3d1s-p@ss"
```

### 8.3 Sealed Secrets

```bash
# Install Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create a SealedSecret
cat <<'EOF' | kubectl apply -f -
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: petstore-db-credentials
  namespace: petstore
spec:
  encryptedData:
    url: AgB3c3...encrypted...==
    username: AgB3c3...encrypted...==
    password: AgB3c3...encrypted...==
EOF

# Seal a new secret
echo -n "s3cr3t" | kubeseal --raw --from-file=/dev/stdin \
  --controller-namespace=kube-system \
  --controller-name=sealed-secrets
```

### 8.4 ConfigMaps for Non-Sensitive Config

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: petstore-app-config
  namespace: petstore
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  CACHE_TTL: "300"
```

---

## 9. Security Hardening

### 9.1 Pod Security Standards

Enforce the `restricted` profile at namespace level:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: petstore
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

This requires all pods to:
- Run as non-root (`runAsNonRoot: true`)
- Drop all capabilities (`drop: ALL`)
- Use read-only root filesystem
- Not allow privilege escalation

### 9.2 RBAC

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: petstore-sa
  namespace: petstore
automountServiceAccountToken: false  # Only mount when needed
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: petstore-role
  namespace: petstore
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: petstore-rolebinding
  namespace: petstore
subjects:
  - kind: ServiceAccount
    name: petstore-sa
    namespace: petstore
roleRef:
  kind: Role
  name: petstore-role
  apiGroup: rbac.authorization.k8s.io
```

### 9.3 Network Policies

The Helm chart deploys default-deny policies. Ensure only required traffic flows:

```bash
# Verify no unintended traffic
kubectl get networkpolicies -n petstore

# Test with a temporary pod
kubectl run test-pod --rm -it --image=curlimages/curl -n petstore -- /bin/sh
# Inside the pod:
curl petstore-product-service:8083  # Should work (same namespace)
curl petstore-store-front:80        # Should be denied
```

### 9.4 Image Scanning

```bash
# Install Trivy operator for continuous scanning
helm install trivy-operator aquasecurity/trippy \
  --namespace trivy-system --create-namespace \
  --set trivy.severity="HIGH,CRITICAL"

# Or scan manually
trivy image --severity HIGH,CRITICAL registry.contoso.local:5000/ai-service:latest
```

### 9.5 OPA Gatekeeper (Optional)

```yaml
# Enforce image registry policy
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedregistries
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRegistries
      validation:
        openAPIV3Schema:
          type: object
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sallowedregistries
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not startswith(container.image, input.parameters.registries[_])
          msg := sprintf("Container %v uses image %v which is not from an allowed registry", [container.name, container.image])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRegistries
metadata:
  name: require-contoso-registry
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - petstore
  parameters:
    registries:
      - "registry.contoso.local:5000/"
      - "docker.io/library/"
```

---

## 10. Monitoring

### 10.1 Prometheus ServiceMonitors

```yaml
# templates/servicemonitor.yaml
{{- if .Values.metrics.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ .Release.Name }}-services
  namespace: {{ .Values.namespace.name }}
  labels:
    release: prometheus  # Match Prometheus operator selector
spec:
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  namespaceSelector:
    matchNames:
      - {{ .Values.namespace.name }}
  endpoints:
    - port: http
      interval: 30s
      path: /metrics
{{- end }}
```

### 10.2 Grafana Dashboard ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-petstore
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  petstore-overview.json: |
    {
      "dashboard": {
        "title": "Contoso Pet Store",
        "uid": "petstore-overview",
        "panels": [
          {
            "title": "Request Rate (RPS)",
            "type": "timeseries",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{namespace=\"petstore\"}[5m])) by (service)",
                "legendFormat": "{{service}}"
              }
            ]
          },
          {
            "title": "Error Rate",
            "type": "timeseries",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{namespace=\"petstore\",code=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total{namespace=\"petstore\"}[5m])) by (service) * 100",
                "legendFormat": "{{service}} - 5xx %"
              }
            ]
          },
          {
            "title": "P99 Latency",
            "type": "timeseries",
            "targets": [
              {
                "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace=\"petstore\"}[5m])) by (le, service))",
                "legendFormat": "{{service}}"
              }
            ]
          }
        ]
      }
    }
```

### 10.3 Prometheus Alerting Rules

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: petstore-alerts
  namespace: monitoring
spec:
  groups:
    - name: petstore
      rules:
        - alert: PetStoreHighErrorRate
          expr: |
            sum(rate(http_requests_total{namespace="petstore",code=~"5.."}[5m])) by (service)
            / sum(rate(http_requests_total{namespace="petstore"}[5m])) by (service) > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High error rate on {{ $labels.service }}"
            description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.service }}"

        - alert: PetStoreHighLatency
          expr: |
            histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{namespace="petstore"}[5m])) by (le, service)) > 2
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High P99 latency on {{ $labels.service }}"
            description: "P99 latency is {{ $value }}s for {{ $labels.service }}"

        - alert: PetStorePodCrashLooping
          expr: |
            rate(kube_pod_container_status_restarts_total{namespace="petstore"}[15m]) > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Pod {{ $labels.pod }} is crash looping"

        - alert: PetStoreHighMemoryUsage
          expr: |
            container_memory_usage_bytes{namespace="petstore",container!=""}
            / container_spec_memory_limit_bytes{namespace="petstore",container!=""} > 0.85
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High memory usage on {{ $labels.pod }}"
```

### 10.4 Metrics Endpoints Per Service

| Service | Metrics Path | Key Metrics |
|---------|-------------|-------------|
| ai-service | `/metrics` | `ai_inference_duration`, `ai_model_load_time`, `ai_requests_total` |
| makeline-service | `/metrics` | `makeline_batch_size`, `makeline_processing_time`, `makeline_queue_depth` |
| order-service | `/metrics` | `http_requests_total`, `http_request_duration_seconds`, `orders_created_total` |
| product-service | `/metrics` | `http_requests_total`, `product_queries_total`, `product_cache_hits` |
| store-front | `/metrics` | `http_requests_total`, `http_request_duration_seconds` |
| store-admin | `/metrics` | `http_requests_total`, `http_request_duration_seconds` |

---

## 11. Logging

### 11.1 Structured Logging Format

All services should emit JSON logs with these fields:

```json
{
  "timestamp": "2026-09-04T10:30:00.000Z",
  "level": "info",
  "service": "order-service",
  "trace_id": "abc123def456",
  "span_id": "789ghi012",
  "message": "Order created successfully",
  "order_id": "ord-12345",
  "customer_id": "cust-678",
  "amount": 49.99,
  "currency": "USD"
}
```

### 11.2 Loki + Promtail Configuration

```yaml
# Promtail DaemonSet config
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
  namespace: logging
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
    positions:
      filename: /tmp/positions.yaml
    clients:
      - url: http://loki.logging.svc.cluster.local:3100/loki/api/v1/push
    scrape_configs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels:
              - __meta_kubernetes_pod_label_app_kubernetes_io_name
            target_label: service
          - source_labels:
              - __meta_kubernetes_namespace
            target_label: namespace
          - source_labels:
              - __meta_kubernetes_pod_name
            target_label: pod
          - action: replace
            replacement: /var/log/pods/*$1/*.log
            separator: /
            source_labels:
              - __meta_kubernetes_pod_uid
              - __meta_kubernetes_pod_container_name
            target_label: __path__
```

### 11.3 Loki Queries

```logql
# All logs from petstore namespace
{namespace="petstore"}

# Error logs only
{namespace="petstore"} | json | level="error"

# Logs from a specific service
{namespace="petstore", service="order-service"}

# Logs with high latency
{namespace="petstore"} | json | latency > 1000

# Count errors per service per minute
sum(rate({namespace="petstore"} | json | level="error" [1m])) by (service)
```

---

## 12. Tracing

### 12.1 OpenTelemetry Collector

```yaml
# otel-collector-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: petstore
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      batch:
        timeout: 5s
        send_batch_size: 1000
      memory_limiter:
        check_interval: 5s
        limit_mib: 512
        spike_limit_mib: 128
    exporters:
      jaeger:
        endpoint: jaeger-collector.tracing.svc.cluster.local:14250
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [jaeger]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: petstore
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
        - name: collector
          image: otel/opentelemetry-collector:0.90.0
          args: ["--config=/etc/otel/config.yaml"]
          ports:
            - containerPort: 4317
              name: otlp-grpc
            - containerPort: 4318
              name: otlp-http
          volumeMounts:
            - name: config
              mountPath: /etc/otel
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
      volumes:
        - name: config
          configMap:
            name: otel-collector-config
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: petstore
spec:
  selector:
    app: otel-collector
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: otlp-grpc
    - name: otlp-http
      port: 4318
      targetPort: otlp-http
```

### 12.2 Jaeger Deployment

```bash
# Deploy Jaeger all-in-one for development
kubectl apply -n tracing --filename - <<'EOF'
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: petstore-jaeger
spec:
  allInOne:
    image: jaegertracing/all-in-one:1.53
    options:
      log-level: debug
  storage:
    type: memory
  ingress:
    enabled: true
EOF
```

### 12.3 Service Instrumentation

**Python (FastAPI):**
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="otel-collector:4317"))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("ai-service")

@app.get("/health")
async def health():
    with tracer.start_as_current_span("health_check"):
        return {"status": "healthy"}
```

**Go (Gin):**
```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/trace"
)

func initTracer() (*trace.TracerProvider, error) {
    exporter, err := otlptracegrpc.New(context.Background(),
        otlptracegrpc.WithEndpoint("otel-collector:4317"),
        otlptracegrpc.WithInsecure())
    if err != nil { return nil, err }

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
        trace.WithSampler(trace.AlwaysSample()),
    )
    otel.SetTracerProvider(tp)
    return tp, nil
}
```

**Node.js (Fastify):**
```javascript
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');

const provider = new NodeTracerProvider({
  exporter: new OTLPTraceExporter({ url: 'otel-collector:4317' }),
});
provider.register();
```

**Rust (Actix):**
```rust
use opentelemetry::trace::TracerProvider;
use opentelemetry_otlp::WithExportConfig;

let provider = opentelemetry_otlp::new_pipeline()
    .tracing()
    .with_exporter(
        opentelemetry_otlp::new_exporter().tonic()
            .with_endpoint("otel-collector:4317")
    )
    .install_batch(opentelemetry::runtime::Tokio)?;

opentelemetry::global::set_tracer_provider(provider);
```

---

## 13. CI/CD Pipeline

### 13.1 GitHub Actions Workflow

```yaml
# .github/workflows/deploy-petstore.yml
name: Deploy Contoso Pet Store

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: registry.contoso.local:5000
  TAG: ${{ github.sha }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run unit tests
        run: |
          for svc in ai-service makeline-service order-service product-service; do
            echo "Testing ${svc}..."
            cd ${svc}
            # Language-specific test commands
            case "${svc}" in
              ai-service) pip install -r requirements.txt && pytest ;;
              makeline-service) go test ./... ;;
              order-service) npm ci && npm test ;;
              product-service) cargo test ;;
            esac
            cd ..
          done

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and push images
        run: |
          for svc in ai-service makeline-service order-service product-service \
                     store-front store-admin virtual-customer virtual-worker; do
            DOCKER_BUILDKIT=1 docker build \
              -t ${REGISTRY}/${svc}:${TAG} \
              -t ${REGISTRY}/${svc}:latest \
              -f ${svc}/Dockerfile ${svc}/
            docker push ${REGISTRY}/${svc}:${TAG}
            docker push ${REGISTRY}/${svc}:latest
          done

  security-scan:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Install Trivy
        run: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
      
      - name: Scan images
        run: |
          for svc in ai-service makeline-service order-service product-service \
                     store-front store-admin virtual-customer virtual-worker; do
            trivy image --severity HIGH,CRITICAL --exit-code 1 \
              ${REGISTRY}/${svc}:${TAG}
          done

  deploy:
    needs: security-scan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Update Helm values with new tag
        run: |
          yq -i '.aiService.image.tag = "${TAG}"' contoso-petstore/values.yaml
          yq -i '.makelineService.image.tag = "${TAG}"' contoso-petstore/values.yaml
          yq -i '.orderService.image.tag = "${TAG}"' contoso-petstore/values.yaml
          yq -i '.productService.image.tag = "${TAG}"' contoso-petstore/values.yaml
          yq -i '.storeFront.image.tag = "${TAG}"' contoso-petstore/values.yaml
          yq -i '.storeAdmin.image.tag = "${TAG}"' contoso-petstore/values.yaml
      
      - name: Deploy to k3s
        run: |
          helm upgrade --install petstore contoso-petstore/ \
            --namespace petstore \
            --values contoso-petstore/values.yaml \
            --set image.tag=${TAG} \
            --wait --timeout 10m
```

### 13.2 ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: petstore
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  project: default
  source:
    repoURL: https://github.com/contoso/petstore-deploy
    targetRevision: main
    path: contoso-petstore
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: petstore
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

---

## 14. Scaling

### 14.1 Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: petstore-order-service
  namespace: petstore
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: petstore-order-service
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

### 14.2 Vertical Pod Autoscaler (VPA)

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: petstore-order-service
  namespace: petstore
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: petstore-order-service
  updatePolicy:
    updateMode: "Off"  # Recommendation only, no auto-update
  resourcePolicy:
    containerPolicies:
      - containerName: order-service
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 2
          memory: 2Gi
        controlledResources: ["cpu", "memory"]
```

### 14.3 Autoscaling — KEDA + Karpenter

#### KEDA: Event-Driven Pod Autoscaling

KEDA (Kubernetes Event-Driven Autoscaling) scales pods based on events — not just CPU/memory. It can also scale to zero.

```yaml
# order-service: Scale on RabbitMQ queue depth
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-service-scaler
  namespace: production
spec:
  scaleTargetRef:
    name: order-service
  minReplicaCount: 2        # Never below 2 (core service)
  maxReplicaCount: 10
  cooldownPeriod: 60
  pollingInterval: 15
  triggers:
    - type: rabbitmq
      metadata:
        queueName: orders
        host: amqp://rabbitmq.backend:5672
        queueLength: "5"
    - type: cpu
      metricType: Utilization
      value: "70"
    - type: memory
      metricType: Utilization
      value: "75"
```

```yaml
# virtual-customer: Cron-based + scale to zero
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: virtual-customer-scaler
  namespace: production
spec:
  scaleTargetRef:
    name: virtual-customer
  minReplicaCount: 0        # Scale to zero!
  maxReplicaCount: 5
  cooldownPeriod: 300       # 5 min before scaling to zero
  triggers:
    - type: cron
      metadata:
        schedule: "0 8 * * 1-5"     # Weekdays 8AM
        timezone: Europe/Paris
        desiredReplicaCount: "3"
    - type: cron
      metadata:
        schedule: "0 18 * * 1-5"    # Weekdays 6PM
        timezone: Europe/Paris
        desiredReplicaCount: "0"     # Scale down in evening
```

```yaml
# virtual-worker: Scale to zero when no work items
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: virtual-worker-scaler
  namespace: production
spec:
  scaleTargetRef:
    name: virtual-worker
  minReplicaCount: 0        # Scale to zero when queue empty
  maxReplicaCount: 3
  cooldownPeriod: 120
  triggers:
    - type: rabbitmq
      metadata:
        queueName: work-items
        host: amqp://rabbitmq.backend:5672
        queueLength: "1"
```

#### Karpenter: Node Autoscaling

Karpenter provisions nodes in seconds (vs Cluster Autoscaler's minutes). It right-sizes nodes based on actual pod demand.

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.medium", "t3.large"]
      nodeClassRef:
        name: default
  limits:
    cpu: "20"
    memory: 40Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h       # Recycle nodes every 30 days
```

### 14.4 Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: petstore-quota
  namespace: petstore
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
    services: "20"
    persistentvolumeclaims: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: petstore-limits
  namespace: petstore
spec:
  limits:
    - default:
        cpu: "1"
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      type: Container
```

---

## 15. Troubleshooting

### 15.1 Pod Issues

**Pod stuck in `Pending`:**
```bash
kubectl describe pod <pod-name> -n petstore
# Check events for scheduling failures

# Common causes:
# - No nodes with enough resources
# - PVC not bound
# - Node selectors/taints not matching

# Fix:
kubectl get nodes -o wide
kubectl top nodes
kubectl get pvc -n petstore
```

**Pod stuck in `CrashLoopBackOff`:**
```bash
# Check logs
kubectl logs <pod-name> -n petstore --previous

# Common causes:
# - Missing environment variables
# - Cannot connect to database
# - Port already in use
# - Application bug

# Check resource limits
kubectl describe pod <pod-name> -n petstore | grep -A5 "Limits\|Requests"
```

**Pod stuck in `ImagePullBackOff`:**
```bash
# Verify registry access
kubectl get events -n petstore --field-selector reason=Failed

# Check image name
kubectl get pod <pod-name> -n petstore -o jsonpath='{.spec.containers[*].image}'

# Test registry connectivity
curl http://registry.contoso.local:5000/v2/_catalog

# Check image pull secrets
kubectl get secret -n petstore
```

### 15.2 Service Issues

**Service cannot connect to backend:**
```bash
# Check endpoints
kubectl get endpoints <service-name> -n petstore

# If empty, check pod labels match service selector
kubectl get pods -n petstore --show-labels
kubectl describe svc <service-name> -n petstore

# Test connectivity from within cluster
kubectl run test --rm -it --image=curlimages/curl -n petstore -- \
  curl http://<service-name>:<port>/health
```

**DNS resolution fails:**
```bash
# Test DNS from within pod
kubectl run dns-test --rm -it --image=busybox -n petstore -- \
  nslookup petstore-order-service.petstore.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### 15.3 Ingress Issues

**Ingress returns 404:**
```bash
# Check ingress rules
kubectl describe ingress petstore-ingress -n petstore

# Verify backend services exist and have endpoints
kubectl get svc -n petstore
kubectl get endpoints -n petstore

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test with curl
curl -H "Host: petstore.contoso.local" http://<ingress-ip>/
```

**TLS certificate not working:**
```bash
# Check certificate status
kubectl get certificate -n petstore
kubectl describe certificate petstore-tls -n petstore

# Check cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager

# Verify ClusterIssuer
kubectl get clusterissuer letsencrypt-prod -o yaml
```

### 15.4 Storage Issues

**PVC stuck in Pending:**
```bash
# Check PVC status
kubectl get pvc -n petstore
kubectl describe pvc <pvc-name> -n petstore

# Check StorageClass
kubectl get storageclass
kubectl describe sc nfs-client

# Check provisioner pod
kubectl get pods -n kube-system | grep nfs
```

### 15.5 Database Issues

**PostgreSQL won't start:**
```bash
# Check PostgreSQL pod logs
kubectl logs petstore-postgresql-0 -n petstore

# Common causes:
# - Data directory corruption
# - PVC mount failure
# - Authentication failure

# Check PVC
kubectl get pvc -n petstore | grep postgresql
```

**Cannot connect to PostgreSQL:**
```bash
# Test connection from within cluster
kubectl run pg-test --rm -it --image=postgres:16 -n petstore -- \
  psql "postgresql://petstore:<password>@petstore-postgresql:5432/petstore"

# Check secret
kubectl get secret petstore-db-credentials -n petstore -o jsonpath='{.data.url}' | base64 -d
```

### 15.6 Application-Level Issues

**High error rates in Grafana:**
```bash
# Check specific service logs
kubectl logs -n petstore -l app.kubernetes.io/name=order-service --tail=100 | grep -i error

# Check for resource exhaustion
kubectl top pods -n petstore

# Check for OOMKilled
kubectl get pods -n petstore -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.lastState.terminated.reason}{"\n"}{end}{end}' | grep OOMKilled
```

**Slow response times:**
```bash
# Check database query performance
kubectl exec -it petstore-postgresql-0 -n petstore -- psql -U petstore -c \
  "SELECT pid, now() - pg_stat_activity.query_start AS duration, query
   FROM pg_stat_activity
   WHERE state != 'idle'
   ORDER BY duration DESC;"

# Check Redis hit rate
kubectl exec -it petstore-redis-master-0 -n petstore -- redis-cli INFO stats | grep keyspace
```

### 15.7 Networking Issues

**Pod cannot reach external services:**
```bash
# Check DNS resolution
kubectl exec -it <pod> -n petstore -- nslookup google.com

# Check NetworkPolicy
kubectl get networkpolicy -n petstore
kubectl describe networkpolicy <policy-name> -n petstore

# Test egress
kubectl exec -it <pod> -n petstore -- curl -s https://httpbin.org/ip
```

**Cross-namespace communication blocked:**
```bash
# Verify NetworkPolicy allows traffic from specific namespaces
kubectl describe networkpolicy petstore-order-service -n petstore

# Check if source pod has correct labels
kubectl get pods -n <source-namespace> --show-labels
```

### 15.8 Monitoring Issues

**Prometheus not scraping services:**
```bash
# Check ServiceMonitor
kubectl get servicemonitor -n petstore
kubectl describe servicemonitor petstore-services -n petstore

# Verify Prometheus can reach targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090/targets

# Check labels match
kubectl get svc -n petstore --show-labels | grep app.kubernetes.io/instance
```

**Grafana dashboard not showing data:**
```bash
# Check dashboard ConfigMap
kubectl get configmap -n monitoring | grep petstore

# Verify Grafana is loaded
kubectl port-forward -n monitoring svc/grafana 3000:80
# Login and check datasources
```

### 15.9 ArgoCD Issues

**Application stuck in "Progressing":**
```bash
# Check ArgoCD application status
argocd app get petstore

# Check sync status
argocd app sync petstore --dry-run

# Check for resource conflicts
argocd app get petstore -o json | jq '.status.resources[] | select(.health.status != "Healthy")'
```

**Auto-sync not working:**
```bash
# Check ArgoCD application
argocd app get petstore -o json | jq '.spec.syncPolicy'

# Verify git repo access
argocd repo list
argocd repo get https://github.com/contoso/petstore-deploy
```

### 15.10 Certificate Issues

**Certificate stuck in "Pending":**
```bash
# Check certificate request
kubectl get certificaterequest -n petstore
kubectl describe certificaterequest <name> -n petstore

# Check challenge
kubectl get challenge -n petstore
kubectl describe challenge <name> -n petstore

# Check cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager --tail=50
```

### 15.11 Secret Issues

**SealedSecret not unsealing:**
```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Verify the secret was created
kubectl get secret -n petstore | grep sealed

# Re-seal if needed
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
```

### 15.12 Load Testing Issues

**Virtual-customer/worker not generating load:**
```bash
# Check logs
kubectl logs -n petstore -l app.kubernetes.io/name=virtual-customer --tail=50

# Verify service endpoints
kubectl get endpoints petstore-order-service -n petstore

# Check resource usage
kubectl top pods -n petstore -l app.kubernetes.io/name=virtual-customer
```

### 15.13 RBAC Issues

**ServiceAccount token mount failures:**
```bash
# Check ServiceAccount
kubectl get sa petstore-sa -n petstore -o yaml

# Verify role bindings
kubectl get rolebinding -n petstore
kubectl describe rolebinding petstore-rolebinding -n petstore

# Check if automountServiceAccountToken is false
kubectl get sa petstore-sa -n petstore -o jsonpath='{.automountServiceAccountToken}'
```

### 15.14 Memory/CPU Pressure

**Nodes under resource pressure:**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes | grep -A10 "Conditions"

# Check pod resource usage
kubectl top pods -n petstore --sort-by=memory

# Identify OOMKilled pods
kubectl get events -n petstore --field-selector reason=OOMKilling
```

### 15.15 Network Policy Issues

**Traffic unexpectedly blocked:**
```bash
# List all NetworkPolicies
kubectl get networkpolicy -n petstore -o yaml

# Check default-deny policy
kubectl describe networkpolicy petstore-default-deny -n petstore

# Test connectivity
kubectl run test --rm -it --image=curlimages/curl -n petstore -- \
  curl -v http://petstore-product-service:8083/health
```

### 15.16 ConfigMap Issues

**ConfigMap changes not reflected in pods:**
```bash
# ConfigMaps are not hot-reloaded by default
# Options:
# 1. Restart the deployment
kubectl rollout restart deployment/<deployment-name> -n petstore

# 2. Use a volume mount with subPath (limited)
# 3. Use a sidecar to watch for changes

# Verify ConfigMap content
kubectl get configmap petstore-app-config -n petstore -o yaml
```

### 15.17 Horizontal Pod Autoscaler Issues

**HPA not scaling:**
```bash
# Check HPA status
kubectl get hpa -n petstore
kubectl describe hpa petstore-order-service -n petstore

# Common causes:
# - Metrics not available
# - Min/max already reached
# - Resource limits too low
# - Stabilization window

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server
```

### 15.18 PersistentVolume Issues

**PV/PVC binding issues:**
```bash
# Check PV status
kubectl get pv
kubectl describe pv <pv-name>

# Check PVC status
kubectl get pvc -n petstore
kubectl describe pvc <pvc-name> -n petstore

# Check reclaim policy
kubectl get pv <pv-name> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
```

### 15.19 Container Registry Issues

**Cannot push to registry:**
```bash
# Test registry connectivity
curl http://registry.contoso.local:5000/v2/_catalog

# Check registry logs
kubectl logs -n registry deployment/registry

# Verify image exists
curl http://registry.contoso.local:5000/v2/ai-service/tags/list
```

### 15.20 Time Synchronization Issues

**Stale data or ordering issues:**
```bash
# Check time on all nodes
kubectl exec -it <pod> -n petstore -- date
kubectl exec -it petstore-postgresql-0 -n petstore -- date

# Verify NTP is running
kubectl exec -it <pod> -n petstore -- ntpstat 2>/dev/null || echo "ntpstat not available"
```

---

## 16. Tips & Best Practices

### 16.1 Architecture Tips

1. **Design for failure**: Every service should handle upstream failures gracefully with circuit breakers, retries, and fallbacks.

2. **Use circuit breakers**: Implement patterns like Hystrix or Polly to prevent cascade failures when a service is down.

3. **Implement health checks properly**: Use `/health` (liveness) and `/ready` (readiness) endpoints separately. Liveness should check if the process is alive; readiness should check if the service can handle traffic.

4. **Use structured logging**: Always emit JSON logs with trace IDs for correlation across services.

5. **Implement distributed tracing**: Use OpenTelemetry from day one. It's much harder to add later.

6. **Design idempotent APIs**: Especially for order creation and payment processing. Clients may retry.

7. **Use API versioning**: Always version your APIs (e.g., `/api/v1/products`) to support backward compatibility.

8. **Implement rate limiting**: Protect services from being overwhelmed. Use nginx annotations or dedicated rate limit services.

### 16.2 Kubernetes Tips

9. **Set resource requests AND limits**: Requests ensure scheduling; limits prevent runaway processes.

10. **Use namespaces for isolation**: Separate environments (dev, staging, prod) into different namespaces.

11. **Implement Pod Disruption Budgets**: Ensure at least N pods are available during voluntary disruptions (node drains, upgrades).

12. **Use init containers for dependencies**: Wait for databases or other services to be ready before starting your application.

13. **Configure anti-affinity**: Spread replicas across nodes for high availability.

14. **Use topology spread constraints**: More flexible than anti-affinity for even distribution.

15. **Set appropriate termination grace periods**: Allow services to drain connections before termination.

### 16.3 Security Tips

16. **Never run as root**: Always set `runAsNonRoot: true` and `runAsUser: 1001` in security contexts.

17. **Use read-only root filesystems**: Prevent attackers from modifying binaries or writing malicious files.

18. **Rotate secrets regularly**: Use External Secrets Operator or Sealed Secrets with automated rotation.

19. **Scan images before deployment**: Integrate Trivy or Snyk into your CI pipeline.

20. **Implement network policies**: Start with default-deny and explicitly allow required traffic.

### 16.4 Operational Tips

21. **Use Helm for all deployments**: Never apply raw YAML in production. Helm provides rollback, versioning, and templating.

22. **Implement GitOps**: Use ArgoCD or Flux for declarative, auditable deployments.

23. **Set up automated backups**: Use CronJobs for database dumps and PV snapshots.

24. **Monitor resource trends**: Set up alerts for capacity planning, not just immediate issues.

25. **Use canary deployments**: Roll out changes to a small percentage of traffic first.

### 16.5 Performance Tips

26. **Implement caching**: Use Redis for frequently accessed, rarely changing data.

27. **Use connection pooling**: For databases, always pool connections to avoid exhaustion.

28. **Optimize container images**: Use multi-stage builds to keep images small and reduce attack surface.

29. **Enable HTTP/2**: Use gRPC or HTTP/2 for inter-service communication when possible.

30. **Use lazy loading**: Don't load all data at startup. Load on-demand and cache.

### 16.6 Debugging Tips

31. **Keep debugging tools handy**: `kubectl debug` or ephemeral debug containers are invaluable.

32. **Use port-forwarding**: For quick debugging without exposing services externally.

33. **Check events first**: `kubectl get events` often reveals the root cause immediately.

34. **Use k9s for quick overviews**: The TUI gives you a real-time view of all resources.

35. **Log correlation is king**: Without trace IDs, debugging distributed systems is nearly impossible.

### 16.7 Cost Optimization Tips

36. **Right-size your pods**: Use VPA recommendations to avoid over-provisioning.

37. **Use spot/preemption nodes**: For non-critical workloads, use cheaper compute.

38. **Implement auto-scaling**: Don't over-provision for peak load; let HPA handle it.

39. **Clean up unused resources**: Remove old PVCs, unused secrets, and completed Jobs.

40. **Monitor idle resources**: Set up alerts for pods using less than 10% of their allocated resources.

---

## 17. Full YAML Examples

### 17.1 Complete Namespace with All Resources

```yaml
# full-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: petstore
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: petstore-sa
  namespace: petstore
automountServiceAccountToken: false
---
# Resource Quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: petstore-quota
  namespace: petstore
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
---
# Limit Range
apiVersion: v1
kind: LimitRange
metadata:
  name: petstore-limits
  namespace: petstore
spec:
  limits:
    - default:
        cpu: "1"
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
      type: Container
---
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: petstore-config
  namespace: petstore
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  AI_SERVICE_MODEL: "gpt-4-turbo"
  ORDER_SERVICE_MAX_RETRY: "3"
  PRODUCT_SERVICE_CACHE_TTL: "300"
---
# PostgreSQL StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: petstore-postgresql
  namespace: petstore
spec:
  serviceName: petstore-postgresql
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      securityContext:
        fsGroup: 999
        runAsUser: 999
        runAsGroup: 999
      containers:
        - name: postgresql
          image: postgres:16-alpine
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: petstore
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
          livenessProbe:
            exec:
              command: ["pg_isready", "-U", "petstore"]
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "petstore"]
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: petstore-postgresql-data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: nfs-client
        resources:
          requests:
            storage: 10Gi
---
# PostgreSQL Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-postgresql
  namespace: petstore
spec:
  selector:
    app: postgresql
  ports:
    - port: 5432
      targetPort: 5432
---
# Redis StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: petstore-redis
  namespace: petstore
spec:
  serviceName: petstore-redis
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      securityContext:
        fsGroup: 999
        runAsUser: 999
      containers:
        - name: redis
          image: redis:7-alpine
          ports:
            - containerPort: 6379
          command: ["redis-server", "--requirepass", "$(REDIS_PASSWORD)"]
          env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: petstore-redis-credentials
                  key: password
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            exec:
              command: ["redis-cli", "-a", "$(REDIS_PASSWORD)", "ping"]
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            exec:
              command: ["redis-cli", "-a", "$(REDIS_PASSWORD)", "ping"]
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: petstore-redis-data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: nfs-client
        resources:
          requests:
            storage: 5Gi
---
# Redis Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-redis
  namespace: petstore
spec:
  selector:
    app: redis
  ports:
    - port: 6379
      targetPort: 6379
---
# Order Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-order-service
  namespace: petstore
  labels:
    app: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8082"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: petstore-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      terminationGracePeriodSeconds: 30
      containers:
        - name: order-service
          image: registry.contoso.local:5000/order-service:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8082
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-redis-credentials
                  key: url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: SERVICE_NAME
              value: "order-service"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
          startupProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: "1"
              memory: 512Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - order-service
                topologyKey: kubernetes.io/hostname
---
# Order Service Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-order-service
  namespace: petstore
  labels:
    app: order-service
spec:
  type: ClusterIP
  selector:
    app: order-service
  ports:
    - name: http
      port: 8082
      targetPort: http
---
# Order Service HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: petstore-order-service
  namespace: petstore
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: petstore-order-service
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
---
# Product Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-product-service
  namespace: petstore
  labels:
    app: product-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8083"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: petstore-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: product-service
          image: registry.contoso.local:5000/product-service:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8083
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-redis-credentials
                  key: url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: SERVICE_NAME
              value: "product-service"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Product Service Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-product-service
  namespace: petstore
  labels:
    app: product-service
spec:
  type: ClusterIP
  selector:
    app: product-service
  ports:
    - name: http
      port: 8083
      targetPort: http
---
# AI Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-ai-service
  namespace: petstore
  labels:
    app: ai-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ai-service
  template:
    metadata:
      labels:
        app: ai-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: petstore-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: ai-service
          image: registry.contoso.local:5000/ai-service:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-redis-credentials
                  key: url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: SERVICE_NAME
              value: "ai-service"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 20
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests:
              cpu: 200m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# AI Service Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-ai-service
  namespace: petstore
  labels:
    app: ai-service
spec:
  type: ClusterIP
  selector:
    app: ai-service
  ports:
    - name: http
      port: 8080
      targetPort: http
---
# Makeline Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-makeline-service
  namespace: petstore
  labels:
    app: makeline-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: makeline-service
  template:
    metadata:
      labels:
        app: makeline-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8081"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: petstore-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
        - name: makeline-service
          image: registry.contoso.local:5000/makeline-service:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8081
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-db-credentials
                  key: url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: petstore-redis-credentials
                  key: url
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: SERVICE_NAME
              value: "makeline-service"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Makeline Service Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-makeline-service
  namespace: petstore
  labels:
    app: makeline-service
spec:
  type: ClusterIP
  selector:
    app: makeline-service
  ports:
    - name: http
      port: 8081
      targetPort: http
---
# Store Front Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-store-front
  namespace: petstore
  labels:
    app: store-front
spec:
  replicas: 2
  selector:
    matchLabels:
      app: store-front
  template:
    metadata:
      labels:
        app: store-front
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 101
        runAsGroup: 101
        fsGroup: 101
      containers:
        - name: store-front
          image: registry.contoso.local:5000/store-front:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Store Front Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-store-front
  namespace: petstore
  labels:
    app: store-front
spec:
  type: ClusterIP
  selector:
    app: store-front
  ports:
    - name: http
      port: 80
      targetPort: http
---
# Store Admin Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-store-admin
  namespace: petstore
  labels:
    app: store-admin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: store-admin
  template:
    metadata:
      labels:
        app: store-admin
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 101
        runAsGroup: 101
        fsGroup: 101
      containers:
        - name: store-admin
          image: registry.contoso.local:5000/store-admin:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Store Admin Service
apiVersion: v1
kind: Service
metadata:
  name: petstore-store-admin
  namespace: petstore
  labels:
    app: store-admin
spec:
  type: ClusterIP
  selector:
    app: store-admin
  ports:
    - name: http
      port: 80
      targetPort: http
---
# Virtual Customer Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-virtual-customer
  namespace: petstore
  labels:
    app: virtual-customer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: virtual-customer
  template:
    metadata:
      labels:
        app: virtual-customer
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
      containers:
        - name: virtual-customer
          image: registry.contoso.local:5000/virtual-customer:latest
          imagePullPolicy: IfNotPresent
          env:
            - name: ORDER_SERVICE_URL
              value: "http://petstore-order-service:8082"
            - name: PRODUCT_SERVICE_URL
              value: "http://petstore-product-service:8083"
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Virtual Worker Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petstore-virtual-worker
  namespace: petstore
  labels:
    app: virtual-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: virtual-worker
  template:
    metadata:
      labels:
        app: virtual-worker
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
      containers:
        - name: virtual-worker
          image: registry.contoso.local:5000/virtual-worker:latest
          imagePullPolicy: IfNotPresent
          env:
            - name: MAKELINE_SERVICE_URL
              value: "http://petstore-makeline-service:8081"
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petstore-ingress
  namespace: petstore
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - petstore.contoso.local
        - admin.petstore.contoso.local
      secretName: petstore-tls
  rules:
    - host: petstore.contoso.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: petstore-store-front
                port:
                  number: 80
    - host: admin.petstore.contoso.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: petstore-store-admin
                port:
                  number: 80
---
# Network Policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: petstore-default-deny
  namespace: petstore
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: petstore-allow-dns
  namespace: petstore
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to: []
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
---
# Pod Disruption Budgets
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: petstore-order-service
  namespace: petstore
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: order-service
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: petstore-product-service
  namespace: petstore
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: product-service
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: petstore-store-front
  namespace: petstore
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: store-front
```

### 17.2 Complete Deployment Script

```bash
#!/bin/bash
# deploy-petstore.sh
set -euo pipefail

echo "=== Contoso Pet Store — Full Deployment ==="

# 1. Create namespace
echo "[1/8] Creating namespace..."
kubectl create namespace petstore --dry-run=client -o yaml | kubectl apply -f -

# 2. Create secrets
echo "[2/8] Creating secrets..."
DB_PASS=$(openssl rand -hex 16)
REDIS_PASS=$(openssl rand -hex 16)

kubectl create secret generic petstore-db-credentials \
  --namespace petstore \
  --from-literal=url="postgresql://petstore:${DB_PASS}@petstore-postgresql:5432/petstore" \
  --from-literal=username="petstore" \
  --from-literal=password="${DB_PASS}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic petstore-redis-credentials \
  --namespace petstore \
  --from-literal=url="redis://:${REDIS_PASS}@petstore-redis:6379" \
  --from-literal=password="${REDIS_PASS}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Apply full manifest
echo "[3/8] Applying Kubernetes manifests..."
kubectl apply -f full-deployment.yaml

# 4. Wait for database
echo "[4/8] Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod/petstore-postgresql-0 \
  --namespace petstore --timeout=120s

# 5. Wait for Redis
echo "[5/8] Waiting for Redis..."
kubectl wait --for=condition=ready pod/petstore-redis-0 \
  --namespace petstore --timeout=120s

# 6. Wait for all services
echo "[6/8] Waiting for all deployments..."
for deploy in order-service product-service ai-service makeline-service store-front store-admin; do
  echo "  Waiting for ${deploy}..."
  kubectl wait --for=condition=available deployment/petstore-${deploy} \
    --namespace petstore --timeout=120s
done

# 7. Verify ingress
echo "[7/8] Verifying ingress..."
kubectl get ingress petstore-ingress -n petstore

# 8. Print status
echo "[8/8] Deployment complete!"
echo ""
echo "=== Service URLs ==="
echo "Frontend: https://petstore.contoso.local"
echo "Admin:    https://admin.petstore.contoso.local"
echo ""
echo "=== Quick Test ==="
kubectl port-forward -n petstore svc/petstore-store-front 8080:80 &
sleep 2
curl -s http://localhost:8080/api/products | head -c 200
kill %1
echo ""
echo "=== Done! ==="
```

---

## Appendix A: Quick Reference

### Useful Commands

```bash
# View all resources in petstore namespace
kubectl get all -n petstore

# Tail logs for a specific service
kubectl logs -n petstore -l app=order-service -f

# Debug a failing pod
kubectl describe pod <pod-name> -n petstore
kubectl logs <pod-name> -n petstore --previous

# Scale a service manually
kubectl scale deployment petstore-order-service --replicas=5 -n petstore

# Port-forward for local testing
kubectl port-forward -n petstore svc/petstore-store-front 8080:80

# Check resource usage
kubectl top pods -n petstore
kubectl top nodes

# Restart a deployment (rolling restart)
kubectl rollout restart deployment petstore-order-service -n petstore

# View rollout status
kubectl rollout status deployment petstore-order-service -n petstore

# Rollback to previous version
kubectl rollout undo deployment petstore-order-service -n petstore
```

### Environment Variables Reference

| Variable | Service | Description |
|----------|---------|-------------|
| `DATABASE_URL` | All backend | PostgreSQL connection string |
| `REDIS_URL` | All backend | Redis connection string |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | All | OpenTelemetry collector endpoint |
| `SERVICE_NAME` | All | Service identifier for tracing |
| `LOG_LEVEL` | All | Log verbosity (debug/info/warn/error) |
| `APP_ENV` | All | Environment (development/staging/production) |
| `AI_SERVICE_MODEL` | ai-service | AI model to use |
| `ORDER_SERVICE_MAX_RETRY` | order-service | Max retry attempts |
| `PRODUCT_SERVICE_CACHE_TTL` | product-service | Cache TTL in seconds |
| `MAKELINE_BATCH_SIZE` | makeline-service | Batch processing size |

### Ports Reference

| Service | Port | Protocol |
|---------|------|----------|
| ai-service | 8080 | HTTP |
| makeline-service | 8081 | HTTP |
| order-service | 8082 | HTTP |
| product-service | 8083 | HTTP |
| virtual-customer | 8084 | HTTP |
| virtual-worker | 8085 | HTTP |
| store-front | 80 | HTTP |
| store-admin | 80 | HTTP |
| PostgreSQL | 5432 | TCP |
| Redis | 6379 | TCP |

---

*This guide covers the complete deployment of the Contoso Pet Store on a k3s cluster. For issues not covered here, consult the Kubernetes documentation at https://kubernetes.io/docs/ or the k3s documentation at https://docs.k3s.io/.*
