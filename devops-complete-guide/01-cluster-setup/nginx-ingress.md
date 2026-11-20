# nginx-ingress Complete Guide

## Table of Contents

1. [What Is nginx-ingress?](#1-what-is-nginx-ingress)
2. [Why Use nginx-ingress?](#2-why-use-nginx-ingress)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Advanced Features](#7-advanced-features)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting](#10-troubleshooting)
11. [Tips & Best Practices](#11-tips--best-practices)
12. [Commands Reference](#12-commands-reference)
13. [CRD Reference](#13-crd-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

## 1. What Is nginx-ingress?

The nginx-ingress controller is an Ingress controller that implements the Kubernetes Ingress resource using NGINX as the reverse proxy and load balancer. It watches for Ingress resources in the cluster and configures NGINX to route external HTTP/HTTPS traffic to internal services.

### The Problem nginx-ingress Solves

Kubernetes pods and services have internal cluster IPs that aren't directly accessible from outside the cluster. You need a way to expose services to external traffic. The Kubernetes `Service` of type `LoadBalancer` works, but:

- One Service = One LoadBalancer = One IP (wasteful)
- No path-based routing (only port-based)
- No virtual hosting (no multiple domains on one IP)
- No TLS termination at the edge

The `Ingress` resource solves this by providing a single entry point that routes traffic based on hostnames and paths to different services.

### Architecture

```
                        Internet
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     LoadBalancer (MetalLB)                   │
│                         192.168.1.200                       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  nginx-ingress Controller                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              NGINX Reverse Proxy                    │   │
│  │  - SSL termination                                  │   │
│  │  - Path-based routing                               │   │
│  │  - Rate limiting                                    │   │
│  │  - WebSocket support                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                               │
│                              ▼                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Service A│  │ Service B│  │ Service C│  │ Service D│   │
│  │ /api/*   │  │ /web/*   │  │ *.app.io │  │ TCP/3306 │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **Controller Pod** | Watches Ingress resources, configures NGINX |
| **NGINX Process** | The actual reverse proxy handling traffic |
| **Default Backend** | Returns 404 for unmatched requests |
| **Admission Webhook** | Validates Ingress resources |
| **Metrics Exporter** | Exposes NGINX metrics for Prometheus |

### How It Works

1. You create an `Ingress` resource in Kubernetes
2. The controller detects the new Ingress
3. It generates an NGINX configuration file
4. It reloads NGINX with the new configuration
5. NGINX starts routing traffic according to the rules

### NGINX vs NGINX Plus

| Feature | NGINX (Open Source) | NGINX Plus |
|---------|---------------------|------------|
| **Cost** | Free | Paid license |
| **Load Balancing** | Round-robin | Advanced (least connections, etc.) |
| **Rate Limiting** | Basic | Advanced with API |
| **Health Checks** | Passive | Active + Passive |
| **JWT** | Not supported | Supported |
| **Dashboard** | Not included | Web dashboard |
| **Support** | Community only | F5 support |

The nginx-ingress controller uses NGINX open source. For NGINX Plus features, use the NGINX Inc. controller.

---

## 2. Why Use nginx-ingress?

### Use Cases

**1. HTTP/HTTPS Routing**
Route external traffic to internal services based on hostnames and paths.

**2. TLS Termination**
Handle SSL/TLS certificates at the edge, offloading encryption from backend services.

**3. Microservices Gateway**
Single entry point for multiple microservices with path-based routing.

**4. API Gateway**
Rate limiting, authentication, and request transformation for APIs.

**5. WebSocket Applications**
Support for WebSocket connections with proper proxying.

**6. TCP/UDP Services**
Expose non-HTTP services like databases and game servers.

### Pros

| Advantage | Details |
|-----------|---------|
| **Battle-Tested** | NGINX is the most widely used web server |
| **High Performance** | Event-driven, non-blocking architecture |
| **Rich Features** | Rate limiting, caching, compression, etc. |
| **Extensible** | Custom annotations for advanced config |
| **Community** | Large community, many examples |
| **Well Documented** | Extensive official documentation |
| **Kubernetes Native** | Uses CRDs for advanced features |
| **Metrics** | Built-in Prometheus metrics |

### Cons

| Limitation | Details |
|------------|---------|
| **Configuration Reload** | NGINX reloads on every Ingress change |
| **No Dynamic Updates** | Some changes require full reload |
| **Complexity** | Many features = many options to learn |
| **Memory Usage** | Can be memory-hungry with many rules |
| **Reload Downtime** | Brief connection drop during reload (minimal) |
| **Lua Dependency** | Advanced features need Lua module |

### Alternatives Comparison

| Controller | Features | Complexity | Performance |
|------------|----------|------------|-------------|
| **nginx-ingress** | High | Medium | High |
| **traefik** | High | Medium | Medium |
| **HAProxy** | Very High | High | Very High |
| **Istio Gateway** | Very High | Very High | Medium |
| **Contour** | Medium | Low | High |

**Recommendation**: nginx-ingress for most use cases. Choose Traefik for auto-discovery, HAProxy for extreme performance, or Istio for service mesh.

---

## 3. Installation

### Prerequisites

1. **Kubernetes cluster running** (k3s, kubeadm, etc.)
2. **kubectl configured** to talk to your cluster
3. **Helm 3.x installed** (recommended)
4. **LoadBalancer available** (MetalLB or cloud provider)

### Method 1: Helm (Recommended)

```bash
# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Check available versions
helm search repo ingress-nginx/ingress-nginx --versions

# Install nginx-ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.config.use-forwarded-headers="true" \
  --set controller.config.proxy-body-size="50m" \
  --set controller.metrics.enabled=true \
  --set controller.admissionWebhooks.enabled=true

# Verify installation
kubectl get pods -n ingress-nginx
```

### Method 2: kubectl apply (Official Manifest)

```bash
# Apply the official manifest (checks your cloud provider)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml

# For bare-metal (NodePort)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/baremetal/deploy.yaml
```

### Method 3: Kustomize

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ingress-nginx

resources:
  - https://github.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml

patches:
  - target:
      kind: Deployment
      name: ingress-nginx-controller
    patch: |
      - op: replace
        path: /spec/replicas
        value: 2
  - target:
      kind: ConfigMap
      name: ingress-nginx-controller
    patch: |
      - op: add
        path: /data/proxy-body-size
        value: "50m"
```

### Method 4: k3s Integration

For k3s clusters, add to your installation script:

```bash
# After k3s installation
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.config.use-forwarded-headers="true"

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get the external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### Verify Installation

```bash
# Check pods
kubectl get pods -n ingress-nginx -o wide
# NAME                                       READY   STATUS    RESTARTS   AGE
# ingress-nginx-controller-xxx               1/1     Running   0          5m

# Check services
kubectl get svc -n ingress-nginx
# NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# ingress-nginx-controller   LoadBalancer   10.43.0.50     192.168.1.200    80:30080/TCP,443:30443/TCP
# ingress-nginx-controller-admission   ClusterIP   10.43.0.51   <none>           443/TCP

# Check ingress class
kubectl get ingressclass
# NAME      CONTROLLER                     PARAMETERS   AGE
# nginx     k8s.io/ingress-nginx           <none>       5m

# Test with a simple Ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: test.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes
                port:
                  number: 443
EOF
```

---

## 4. Configuration

### ConfigMap Settings

The ConfigMap `ingress-nginx-controller` controls NGINX behavior:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  # --- General Settings ---
  # Use generated server names instead of IPs
  use-gzip: "true"
  enable-brotli: "true"
  use-forwarded-headers: "true"
  compute-full-forwarded-for: "true"
  enable-real-ip: "true"

  # --- Proxy Settings ---
  proxy-body-size: "50m"
  proxy-connect-timeout: "10"
  proxy-read-timeout: "120"
  proxy-send-timeout: "120"
  proxy-buffer-size: "16k"
  proxy-buffers-number: "4"

  # --- SSL/TLS Settings ---
  ssl-protocols: "TLSv1.2 TLSv1.3"
  ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
  ssl-prefer-server-ciphers: "true"
  hsts: "true"
  hsts-max-age: "31536000"
  hsts-include-subdomains: "true"

  # --- Security Headers ---
  hide-headers: "X-Powered-By,Server"
  add-headers: "ingress-nginx/custom-headers"

  # --- Rate Limiting ---
  limit-req-status-code: "429"

  # --- Logging ---
  log-format-upstream: '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_length $request_time [$proxy_upstream_name] [$proxy_alternative_upstream_name] $upstream_addr $upstream_response_length $upstream_response_time $upstream_status $req_id'
  enable-access-log-for-default-backend: "true"

  # --- Compression ---
  gzip-min-length: "256"

  # --- WebSocket ---
  proxy-http-version: "1.1"

  # --- Custom Errors ---
  custom-http-errors: "404,503"
  default-backend-service: ingress-nginx/custom-default-backend
```

### Annotation-Based Configuration

Annotations on Ingress resources override ConfigMap defaults:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    # --- Proxy Settings ---
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "32k"
    nginx.ingress.kubernetes.io/proxy-buffers-number: "8"

    # --- SSL Settings ---
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256"

    # --- Rate Limiting ---
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
    nginx.ingress.kubernetes.io/limit-connections: "10"

    # --- CORS ---
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://example.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization"

    # --- Rewrite ---
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"

    # --- Backend Protocol ---
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"

    # --- WebSockets ---
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";

    # --- Custom Headers ---
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Custom-Header "my-value";

    # --- ModSecurity WAF ---
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRule REQUEST_URI "@contains /admin" "id:1001,phase:1,deny,status:403"

    # --- Server Snippet ---
    nginx.ingress.kubernetes.io/server-snippet: |
      add_header Strict-Transport-Security "max-age=31536000" always;
spec:
  ingressClassName: nginx
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

### IngressClass Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    # Make this the default IngressClass
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx
  parameters:
    # Reference a ConfigMap for parameters
    apiGroup: ""
    kind: ConfigMap
    name: nginx-parameters
```

### Controller Command-Line Flags

```yaml
# Helm values.yaml
controller:
  # Number of replicas
  replicaCount: 2

  # Resource limits
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

  # Node affinity
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - ingress-nginx
            topologyKey: kubernetes.io/hostname

  # Tolerations
  tolerations:
    - key: node-role.kubernetes.io/master
      operator: Exists
      effect: NoSchedule

  # Metrics
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

  # Admission webhooks
  admissionWebhooks:
    enabled: true

  # Custom default backend
  defaultBackend:
    enabled: true

  # ConfigMap
  config:
    use-gzip: "true"
    enable-brotli: "true"
    ssl-protocols: "TLSv1.2 TLSv1.3"
```

---

## 5. Core Concepts

### Ingress Resource

An Ingress defines routing rules:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
  rules:
    - host: app.example.com
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

### Path Types

| Type | Description | Example |
|------|-------------|---------|
| `Prefix` | Matches based on URL path prefix | `/api` matches `/api`, `/api/v1` |
| `Exact` | Matches the exact path only | `/api` matches only `/api` |
| `ImplementationSpecific` | Depends on the controller | Varies |

### Ingress Rules

```yaml
# Single host, single path
rules:
  - host: app.example.com
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: app
              port:
                number: 80

# Single host, multiple paths
rules:
  - host: app.example.com
    http:
      paths:
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: api-service
              port:
                number: 8080
        - path: /web
          pathType: Prefix
          backend:
            service:
              name: web-service
              port:
                number: 80
        - path: /
          pathType: Prefix
          backend:
            service:
              name: default-service
              port:
                number: 80

# Multiple hosts
rules:
  - host: api.example.com
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: api-service
              port:
                number: 8080
  - host: web.example.com
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: web-service
              port:
                number: 80
```

### TLS Configuration

```yaml
# Simple TLS
tls:
  - hosts:
      - app.example.com
    secretName: app-tls

# Multiple TLS secrets
tls:
  - hosts:
      - app1.example.com
    secretName: app1-tls
  - hosts:
      - app2.example.com
    secretName: app2-tls

# Wildcard TLS
tls:
  - hosts:
      - "*.example.com"
    secretName: wildcard-tls
```

### Default Backend

The default backend handles requests that don't match any Ingress rule:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: default-backend
  annotations:
    nginx.ingress.kubernetes.io/default-backend: default-backend
spec:
  ingressClassName: nginx
  rules: []
  defaultBackend:
    service:
      name: default-backend
      port:
        number: 80
```

### IngressClass

IngressClass defines which controller handles an Ingress:

```yaml
# Default IngressClass
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx
```

---

## 6. Usage Guide

### Step 1: Create a Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: web-app
          image: nginx:1.25
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Step 2: Create a Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: default
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

### Step 3: Create an Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - web-app.example.com
      secretName: web-app-tls
  rules:
    - host: web-app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app
                port:
                  number: 80
```

### Step 4: Create a TLS Secret

```bash
# Create a self-signed certificate for testing
kubectl create secret tls web-app-tls \
  --cert=<(openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /dev/stdout -out /dev/stdout \
    -subj "/CN=web-app.example.com" \
    -addext "subjectAltName=DNS:web-app.example.com") \
  -n default

# Or create from files
kubectl create secret tls web-app-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n default
```

### Step 5: Verify Access

```bash
# Get the ingress IP
kubectl get ingress web-app
# NAME       CLASS   HOSTS                 ADDRESS         PORTS     AGE
# web-app    nginx   web-app.example.com   192.168.1.200   80, 443   5m

# Test with curl
curl -H "Host: web-app.example.com" http://192.168.1.200
curl -k https://web-app.example.com

# Add to /etc/hosts for local testing
echo "192.168.1.200 web-app.example.com" | sudo tee -a /etc/hosts
```

### Step 6: Path-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-service
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
          - path: /web
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
          - path: /static
            pathType: Prefix
            backend:
              service:
                name: static-service
                port:
                  number: 80
```

### Step 7: Host-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
    - host: web.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
    - host: admin.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin-service
                port:
                  number: 80
```

### Step 8: Rewrite Target

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-example
  annotations:
    # Rewrite /api/v1 to /v1
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

### Step 9: Rate Limiting

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limited
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
    nginx.ingress.kubernetes.io/limit-connections: "5"
    nginx.ingress.kubernetes.io/limit-req-status-code: "429"
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

### Step 10: CORS Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cors-example
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.example.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization, X-Requested-With"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
    nginx.ingress.kubernetes.io/cors-max-age: "86400"
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

### Step 11: WebSocket Support

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: websocket-example
  annotations:
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_cache_bypass $http_upgrade;
spec:
  ingressClassName: nginx
  rules:
    - host: ws.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: websocket-service
                port:
                  number: 8080
```

### Step 12: SSL Passthrough

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ssl-passthrough
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-service
                port:
                  number: 443
```

---

## 7. Advanced Features

### Custom Default Backend

```yaml
# Deploy a custom 404 page
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-default-backend
  namespace: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: custom-default-backend
  template:
    metadata:
      labels:
        app: custom-default-backend
    spec:
      containers:
        - name: default-backend
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: config
              mountPath: /etc/nginx/conf.d/
      volumes:
        - name: config
          configMap:
            name: default-backend-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-backend-config
  namespace: ingress-nginx
data:
  default.conf: |
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        
        location / {
            return 404 '{"error":"Not Found","message":"The requested resource was not found"}';
            add_header Content-Type application/json;
        }
        
        location /healthz {
            return 200 'ok';
            add_header Content-Type text/plain;
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: custom-default-backend
  namespace: ingress-nginx
spec:
  selector:
    app: custom-default-backend
  ports:
    - port: 80
      targetPort: 80
```

### ModSecurity WAF

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: waf-enabled
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRule REQUEST_URI "@contains /admin" "id:1001,phase:1,deny,status:403"
      SecRule REQUEST_URI "@contains /phpmyadmin" "id:1002,phase:1,deny,status:403"
      SecRule ARGS "@select.*from" "id:1003,phase:2,deny,status:403"
      SecRule ARGS "@union.*select" "id:1004,phase:2,deny,status:403"
spec:
  ingressClassName: nginx
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-service
                port:
                  number: 80
```

### Custom Error Pages

```yaml
# Deploy custom error pages
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-error-pages
  namespace: ingress-nginx
data:
  404.html: |
    <!DOCTYPE html>
    <html>
    <head><title>404 Not Found</title></head>
    <body>
    <h1>404 Not Found</h1>
    <p>The requested resource was not found.</p>
    </body>
    </html>
  503.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Service Unavailable</title></head>
    <body>
    <h1>503 Service Unavailable</h1>
    <p>The service is temporarily unavailable.</p>
    </body>
    </html>
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-errors
  annotations:
    nginx.ingress.kubernetes.io/custom-http-errors: "404,503"
    nginx.ingress.kubernetes.io/default-backend: custom-default-backend
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
```

### TCP/UDP Services

```yaml
# ConfigMap for TCP/UDP services
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  # TCP services
  "3306": "default/mysql-service:3306"
  "5432": "default/postgres-service:5432"
  "6379": "default/redis-service:6379"
  
  # UDP services
  "53": "default/dns-service:53"
```

### Annotations Reference

| Annotation | Description | Default |
|------------|-------------|---------|
| `nginx.ingress.kubernetes.io/rewrite-target` | Rewrite URL path | `/` |
| `nginx.ingress.kubernetes.io/ssl-redirect` | Redirect HTTP to HTTPS | `false` |
| `nginx.ingress.kubernetes.io/force-ssl-redirect` | Force HTTPS even on 80 | `false` |
| `nginx.ingress.kubernetes.io/proxy-body-size` | Max request body size | `1m` |
| `nginx.ingress.kubernetes.io/proxy-connect-timeout` | Connection timeout | `10` |
| `nginx.ingress.kubernetes.io/proxy-read-timeout` | Read timeout | `60` |
| `nginx.ingress.kubernetes.io/proxy-send-timeout` | Send timeout | `60` |
| `nginx.ingress.kubernetes.io/proxy-buffer-size` | Proxy buffer size | `4k` |
| `nginx.ingress.kubernetes.io/proxy-buffers-number` | Number of buffers | `8` |
| `nginx.ingress.kubernetes.io/limit-rps` | Rate limit (requests/sec) | - |
| `nginx.ingress.kubernetes.io/limit-connections` | Connection limit | - |
| `nginx.ingress.kubernetes.io/enable-cors` | Enable CORS | `false` |
| `nginx.ingress.kubernetes.io/backend-protocol` | Backend protocol | `HTTP` |
| `nginx.ingress.kubernetes.io/ssl-passthrough` | Pass SSL to backend | `false` |
| `nginx.ingress.kubernetes.io/enable-modsecurity` | Enable ModSecurity | `false` |

---

## 8. Integration

### Integration with MetalLB

nginx-ingress uses MetalLB for external IP assignment:

```bash
# Install MetalLB (if not installed)
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace

# Configure IP pool
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ingress-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
  serviceSelectors:
    - matchLabels:
        app.kubernetes.io/name: ingress-nginx
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ingress-advertisement
  namespace: metallb-system
EOF

# Install nginx-ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Integration with cert-manager

cert-manager automatically provisions TLS certificates:

```bash
# Install cert-manager (if not installed)
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Create a ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# Create Ingress with TLS
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
EOF
```

### Integration with k3s

nginx-ingress works seamlessly with k3s:

```bash
# k3s includes Traefik by default
# Disable Traefik and install nginx-ingress instead

# Option 1: Install k3s without Traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Option 2: Uninstall Traefik
kubectl delete helmchart traefik kube-system
helm uninstall traefik -n kube-system

# Install nginx-ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Integration with Prometheus

```yaml
# ServiceMonitor for nginx-ingress metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ingress-nginx
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  namespaceSelector:
    matchNames:
      - ingress-nginx
  endpoints:
    - port: metrics
      interval: 30s
---
# PrometheusRule for alerts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ingress-nginx-alerts
  namespace: monitoring
spec:
  groups:
    - name: ingress-nginx
      rules:
        - alert: NginxIngressHighErrorRate
          expr: |
            sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) /
            sum(rate(nginx_ingress_controller_requests[5m])) > 0.05
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High error rate in nginx-ingress"
            description: "Error rate is {{ $value | humanizePercentage }}"
```

---

## 9. Security

### TLS Configuration

```yaml
# Strong TLS configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  ssl-protocols: "TLSv1.2 TLSv1.3"
  ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
  ssl-prefer-server-ciphers: "true"
  hsts: "true"
  hsts-max-age: "31536000"
  hsts-include-subdomains: "true"
  hsts-preload: "true"
```

### Security Headers

```yaml
# Create a ConfigMap with custom headers
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-headers
  namespace: ingress-nginx
data:
  X-Frame-Options: "DENY"
  X-Content-Type-Options: "nosniff"
  X-XSS-Protection: "1; mode=block"
  Referrer-Policy: "strict-origin-when-cross-origin"
  Content-Security-Policy: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
  Permissions-Policy: "camera=(), microphone=(), geolocation=()"
---
# Reference in ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  add-headers: "ingress-nginx/custom-headers"
  hide-headers: "X-Powered-By,Server"
```

### Rate Limiting

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limited
  annotations:
    # 10 requests per second with burst of 50
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
    # Max 10 concurrent connections
    nginx.ingress.kubernetes.io/limit-connections: "10"
    # Return 429 on rate limit
    nginx.ingress.kubernetes.io/limit-req-status-code: "429"
    # Rate limit by client IP
    nginx.ingress.kubernetes.io/limit-whitelist: "10.0.0.0/8"
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 80
```

### IP Whitelisting

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ip-whitelist
  annotations:
    # Allow only specific IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.1.0/24"
spec:
  ingressClassName: nginx
  rules:
    - host: admin.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin-service
                port:
                  number: 80
```

### Basic Authentication

```yaml
# Create a htpasswd secret
kubectl create secret generic basic-auth \
  --from-literal=auth=$(htpasswd -nb admin password123) \
  -n default

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-auth
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
    - host: secure.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-service
                port:
                  number: 80
```

### OAuth2 Proxy

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: oauth2-proxy
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.example.com/oauth2/start?rd=$scheme://$host$escaped_request_uri"
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - port: 80
          protocol: TCP
```

---

## 10. Troubleshooting

### Issue 1: 502 Bad Gateway

**Symptoms:**
- Ingress returns 502 errors
- Backend service is healthy

**Diagnosis:**
```bash
# Check if backend pods are running
kubectl get pods -l app=my-app

# Check if service endpoints exist
kubectl get endpoints my-app

# Check nginx logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep -i "502"
```

**Solutions:**
1. Ensure backend pods are in `Running` and `Ready` state
2. Check service selector matches pod labels
3. Verify container port matches service targetPort
4. Check if `readinessProbe` is passing

### Issue 2: 404 Not Found

**Symptoms:**
- Ingress returns 404 for all paths
- Service exists and is healthy

**Diagnosis:**
```bash
# Check ingress configuration
kubectl describe ingress my-ingress

# Check nginx configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep -A10 "server_name"

# Verify ingress class
kubectl get ingressclass
```

**Solutions:**
1. Verify `host` matches your request
2. Check `path` and `pathType` are correct
3. Ensure ingressClassName is set correctly
4. Check default backend is configured

### Issue 3: Connection Refused

**Symptoms:**
- Cannot connect to ingress IP
- Connection times out

**Diagnosis:**
```bash
# Check ingress controller pod
kubectl get pods -n ingress-nginx

# Check service
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check if controller is listening
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- netstat -tlnp
```

**Solutions:**
1. Ensure controller pod is running
2. Check LoadBalancer has external IP (MetalLB)
3. Verify firewall allows traffic on ports 80/443
4. Check node network connectivity

### Issue 4: SSL Certificate Errors

**Symptoms:**
- Browser shows certificate warning
- curl: SSL certificate problem

**Diagnosis:**
```bash
# Check TLS secret
kubectl get secret my-tls -o yaml

# Verify certificate
kubectl get secret my-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check ingress TLS configuration
kubectl describe ingress my-ingress | grep -A5 tls
```

**Solutions:**
1. Ensure secret contains valid `tls.crt` and `tls.key`
2. Certificate must match the hostname
3. Check certificate isn't expired
4. Use `--insecure` flag with curl for testing

### Issue 5: NGINX Reload Errors

**Symptoms:**
- Controller logs show reload errors
- New Ingress rules not applied

**Diagnosis:**
```bash
# Check controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep -i "reload"

# Check NGINX configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -t
```

**Solutions:**
1. Fix invalid NGINX configuration
2. Check for duplicate server blocks
3. Verify all referenced secrets exist
4. Restart controller pod

### Issue 6: High Memory Usage

**Symptoms:**
- Controller pod uses excessive memory
- OOMKilled errors

**Diagnosis:**
```bash
# Check pod resource usage
kubectl top pods -n ingress-nginx

# Check resource limits
kubectl get pod -n ingress-nginx -o yaml | grep -A10 resources
```

**Solutions:**
1. Increase memory limits
2. Reduce number of Ingress rules per controller
3. Use multiple controller instances
4. Optimize NGINX worker processes

### Issue 7: Slow Response Times

**Symptoms:**
- High latency for requests through ingress
- Timeouts on slow backends

**Diagnosis:**
```bash
# Check proxy timeouts
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep -i timeout

# Check backend response time
curl -w "@curl-format.txt" -o /dev/null -s http://backend-service
```

**Solutions:**
1. Increase proxy timeouts
2. Optimize backend service
3. Enable connection keep-alive
4. Check network latency

### Issue 8: WebSocket Connection Fails

**Symptoms:**
- WebSocket connections don't establish
- 400 Bad Request errors

**Diagnosis:**
```bash
# Check WebSocket annotations
kubectl describe ingress ws-ingress | grep -i websocket

# Check NGINX configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep -A5 "Upgrade"
```

**Solutions:**
1. Add WebSocket annotations
2. Set `proxy-http-version: "1.1"`
3. Configure upgrade headers
4. Check backend supports WebSocket

### Issue 9: CORS Errors

**Symptoms:**
- Browser shows CORS errors
- Preflight requests fail

**Diagnosis:**
```bash
# Check CORS headers
curl -I -H "Origin: https://app.example.com" http://ingress-ip/api

# Check CORS configuration
kubectl describe ingress my-ingress | grep -i cors
```

**Solutions:**
1. Enable CORS annotations
2. Set correct `cors-allow-origin`
3. Allow required methods and headers
4. Check preflight response

### Issue 10: Rate Limiting Not Working

**Symptoms:**
- Rate limit annotations have no effect
- No 429 responses

**Diagnosis:**
```bash
# Check rate limit configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep -i limit_req

# Test rate limiting
for i in {1..100}; do curl -s -o /dev/null -w "%{http_code}\n" http://ingress-ip/api; done
```

**Solutions:**
1. Verify rate limit annotations are correct
2. Check `limit-req-status-code` is set
3. Ensure annotations are on the correct Ingress
4. Check for conflicting configurations

### Issue 11: Custom Headers Not Applied

**Symptoms:**
- Security headers missing from response
- Custom headers not sent

**Diagnosis:**
```bash
# Check response headers
curl -I http://ingress-ip

# Check ConfigMap
kubectl get configmap ingress-nginx-controller -n ingress-nginx -o yaml
```

**Solutions:**
1. Verify ConfigMap is referenced
2. Check header syntax is correct
3. Ensure ConfigMap exists in correct namespace
4. Restart controller after ConfigMap changes

### Issue 12: Ingress Class Not Found

**Symptoms:**
- Ingress events show "no IngressClass"
- Ingress not configured

**Diagnosis:**
```bash
kubectl get ingressclass
kubectl describe ingress my-ingress | grep -i class
```

**Solutions:**
1. Ensure IngressClass exists
2. Set correct `ingressClassName` in Ingress
3. Mark a class as default if needed
4. Check controller is watching the correct class

### Issue 13: Load Balancer Stuck Pending

**Symptoms:**
- ingress-nginx-controller service has no EXTERNAL-IP
- Cannot reach ingress

**Diagnosis:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
kubectl describe svc -n ingress-nginx ingress-nginx-controller
```

**Solutions:**
1. Ensure MetalLB is installed and configured
2. Check IPAddressPool has available IPs
3. Verify service type is LoadBalancer
4. Check MetalLB controller logs

### Issue 14: Controller CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n ingress-nginx
# NAME                                       READY   STATUS             RESTARTS
# ingress-nginx-controller-xxx               0/1     CrashLoopBackOff   5
```

**Diagnosis:**
```bash
kubectl logs -n ingress-nginx pod/ingress-nginx-controller-xxx --previous
```

**Solutions:**
1. Check RBAC permissions
2. Verify ConfigMap syntax
3. Check for port conflicts
4. Review resource limits

### Issue 15: Metrics Not Available

**Symptoms:**
- Prometheus not scraping nginx-ingress
- No metrics endpoint

**Diagnosis:**
```bash
# Check if metrics port is exposed
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check ServiceMonitor
kubectl get servicemonitor -n monitoring
```

**Solutions:**
1. Enable metrics in Helm values
2. Create ServiceMonitor
3. Check Prometheus operator is running
4. Verify network policies allow scraping

---

## 11. Tips & Best Practices

### Tip 1: Always Use IngressClass

```yaml
# Set a default IngressClass
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx
```

### Tip 2: Use externalTrafficPolicy: Local

Preserve source IP and avoid extra hops:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preserves source IP
```

### Tip 3: Set Resource Limits

Always set resource limits for the controller:

```yaml
controller:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Tip 4: Enable Health Checks

```yaml
controller:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 10
```

### Tip 5: Use Pod Anti-Affinity

Spread controller pods across nodes:

```yaml
controller:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - ingress-nginx
            topologyKey: kubernetes.io/hostname
```

### Tip 6: Monitor with Prometheus

```yaml
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
```

### Tip 7: Use Custom Error Pages

Deploy custom 404/503 pages for better UX.

### Tip 8: Enable Compression

```yaml
config:
  use-gzip: "true"
  enable-brotli: "true"
  gzip-min-length: "256"
```

### Tip 9: Optimize Proxy Buffers

```yaml
config:
  proxy-buffer-size: "16k"
  proxy-buffers-number: "4"
  proxy-body-size: "50m"
```

### Tip 10: Use SSL Redirect

Force HTTPS for all services:

```yaml
config:
  ssl-redirect: "true"
  force-ssl-redirect: "true"
```

### Tip 11: Implement Rate Limiting

Protect backend services from abuse:

```yaml
annotations:
  nginx.ingress.kubernetes.io/limit-rps: "10"
  nginx.ingress.kubernetes.io/limit-burst-multiplier: "5"
```

### Tip 12: Enable CORS for APIs

```yaml
annotations:
  nginx.ingress.kubernetes.io/enable-cors: "true"
  nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.example.com"
```

### Tip 13: Use Configuration Snippets

For advanced NGINX configuration:

```yaml
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

### Tip 14: Keep Controllers Updated

Regularly update the ingress-nginx controller:

```bash
helm repo update
helm upgrade ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx
```

### Tip 15: Test Before Production

Always test Ingress changes in staging first:

```bash
# Test NGINX configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -t

# Check ingress events
kubectl describe ingress my-ingress
```

---

## 12. Commands Reference

### Installation Commands

```bash
# Install via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Uninstall
helm uninstall ingress-nginx -n ingress-nginx
```

### Pod Management

```bash
# List controller pods
kubectl get pods -n ingress-nginx -o wide

# View controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f

# Restart controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Check controller status
kubectl get deployment -n ingress-nginx ingress-nginx-controller
```

### Ingress Management

```bash
# List all Ingresses
kubectl get ingress -A

# Describe an Ingress
kubectl describe ingress my-ingress

# Check Ingress events
kubectl get events --field-selector reason=Create --for=Ingress/my-ingress

# Delete an Ingress
kubectl delete ingress my-ingress
```

### Configuration Management

```bash
# View ConfigMap
kubectl get configmap -n ingress-nginx ingress-nginx-controller -o yaml

# Edit ConfigMap
kubectl edit configmap -n ingress-nginx ingress-nginx-controller

# Test NGINX configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -t
```

### Networking Debugging

```bash
# Check ingress IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Test connectivity
curl -H "Host: my-app.example.com" http://<INGRESS-IP>
curl -k https://my-app.example.com

# Check endpoints
kubectl get endpoints my-app

# Check service
kubectl describe svc my-app
```

### Monitoring

```bash
# Check controller metrics
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 9090:10254

# Check NGINX status
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -t

# View access logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep "GET"
```

### TLS Management

```bash
# Create TLS secret
kubectl create secret tls my-tls --cert=tls.crt --key=tls.key

# Check TLS secret
kubectl get secret my-tls -o yaml

# Verify certificate
kubectl get secret my-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### Troubleshooting

```bash
# Check for errors
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep -i error

# Check for warnings
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep -i warn

# Check controller events
kubectl get events -n ingress-nginx

# Check resource usage
kubectl top pods -n ingress-nginx
```

---

## 13. CRD Reference

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: string              # Required: Ingress name
  namespace: string         # Required: Namespace
  annotations:              # Optional: nginx-ingress annotations
    nginx.ingress.kubernetes.io/rewrite-target: string
spec:
  ingressClassName: string  # Optional: IngressClass name
  tls:                      # Optional: TLS configuration
    - hosts:
        - string            # Required: Hostname
      secretName: string    # Required: TLS secret name
  rules:                    # Required: Routing rules
    - host: string          # Optional: Hostname
      http:
        paths:
          - path: string    # Required: URL path
            pathType: string  # Required: Prefix|Exact|ImplementationSpecific
            backend:
              service:
                name: string  # Required: Service name
                port:
                  number: int  # Required: Service port
```

### IngressClass

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: string              # Required: IngressClass name
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"  # Optional
spec:
  controller: string        # Required: Controller identifier
  parameters:               # Optional: Parameters reference
    apiGroup: string
    kind: string
    name: string
```

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  # General Settings
  use-gzip: "true"
  enable-brotli: "true"
  use-forwarded-headers: "true"
  compute-full-forwarded-for: "true"
  enable-real-ip: "true"
  
  # Proxy Settings
  proxy-body-size: "50m"
  proxy-connect-timeout: "10"
  proxy-read-timeout: "120"
  proxy-send-timeout: "120"
  proxy-buffer-size: "16k"
  proxy-buffers-number: "4"
  
  # SSL/TLS Settings
  ssl-protocols: "TLSv1.2 TLSv1.3"
  ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256"
  ssl-prefer-server-ciphers: "true"
  hsts: "true"
  hsts-max-age: "31536000"
  hsts-include-subdomains: "true"
  
  # Security Headers
  hide-headers: "X-Powered-By,Server"
  add-headers: "ingress-nginx/custom-headers"
  
  # Rate Limiting
  limit-req-status-code: "429"
  
  # Logging
  log-format-upstream: string
  
  # Compression
  gzip-min-length: "256"
  
  # WebSocket
  proxy-http-version: "1.1"
  
  # Custom Errors
  custom-http-errors: "404,503"
  default-backend-service: string
  
  # TCP/UDP Services
  "3306": "namespace/service:port"
  "5432": "namespace/service:port"
```

---

## 14. Real-World Examples

### Example 1: Simple Web Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: web-app
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: default
spec:
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - web-app.example.com
      secretName: web-app-tls
  rules:
    - host: web-app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app
                port:
                  number: 80
```

### Example 2: API Gateway

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "10"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.example.com"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /api/v1
            pathType: Prefix
            backend:
              service:
                name: api-v1
                port:
                  number: 8080
          - path: /api/v2
            pathType: Prefix
            backend:
              service:
                name: api-v2
                port:
                  number: 8080
```

### Example 3: Microservices

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
          - path: /api/users
            pathType: Prefix
            backend:
              service:
                name: user-service
                port:
                  number: 8080
          - path: /api/products
            pathType: Prefix
            backend:
              service:
                name: product-service
                port:
                  number: 8080
          - path: /api/orders
            pathType: Prefix
            backend:
              service:
                name: order-service
                port:
                  number: 8080
```

### Example 4: WebSocket Application

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: websocket-app
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      proxy_cache_bypass $http_upgrade;
      proxy_read_timeout 86400s;
spec:
  ingressClassName: nginx
  rules:
    - host: ws.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: websocket-service
                port:
                  number: 8080
```

### Example 5: TCP Service (Database)

```yaml
# ConfigMap for TCP services
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  "3306": "default/mysql-service:3306"
  "5432": "default/postgres-service:5432"
  "6379": "default/redis-service:6379"
---
# Service for MySQL
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: default
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
  type: ClusterIP
```

---

## 15. Further Reading

### Official Documentation
- [nginx-ingress GitHub](https://github.com/kubernetes/ingress-nginx)
- [nginx-ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Annotations Reference](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)
- [Configuration Guide](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)

### Tutorials
- [Basic Configuration](https://kubernetes.github.io/ingress-nginx/user-guide/basic-usage/)
- [TLS Termination](https://kubernetes.github.io/ingress-nginx/user-guide/tls/)
- [WebSockets](https://kubernetes.github.io/ingress-nginx/user-guide/miscellaneous/#websockets)
- [TCP/UDP](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/)

### Related Tools
- [MetalLB](./metallb.md)
- [cert-manager](./cert-manager.md)
- [NGINX Documentation](https://nginx.org/en/docs/)

### Community
- [Kubernetes Slack](https://slack.k8s.io/)
- [ingress-nginx Channel](https://kubernetes.slack.com/channels/ingress-nginx)

---

*Last Updated: 2026-09-03*
*Version: 1.0*
*Part of the DevOps Complete Guide Series*
