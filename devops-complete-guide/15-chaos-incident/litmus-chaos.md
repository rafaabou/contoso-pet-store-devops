# Litmus Chaos Complete Guide

## Table of Contents

1. [What Is Litmus Chaos](#1-what-is-litmus-chaos)
2. [Why Use Litmus Chaos](#2-why-use-litmus-chaos)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Chaos Experiments](#8-custom-chaos-experiments)
9. [ChaosHub and Experiment Library](#9-chaoshub-and-experiment-library)
10. [Integration with Kubernetes](#10-integration-with-kubernetes)
11. [ChaosCenter Web UI](#11-chaoscenter-web-ui)
12. [Security](#12-security)
13. [Troubleshooting](#13-troubleshooting)
14. [Tips and Best Practices](#14-tips-and-best-practices)
15. [Command Reference](#15-command-reference)
16. [Configuration Reference](#16-configuration-reference)
17. [Real-World Examples](#17-real-world-examples)
18. [Further Reading](#18-further-reading)

---

## 1. What Is Litmus Chaos

Litmus Chaos is a cloud-native chaos engineering framework designed specifically for Kubernetes environments. It enables teams to proactively test the resilience of their applications and infrastructure by introducing controlled, well-defined faults into a running system.

### 1.1 The Chaos Engineering Principle

Chaos engineering is the discipline of experimenting on a system to build confidence in its capability to withstand turbulent conditions in production. Rather than waiting for failures to occur naturally, chaos engineering intentionally injects faults to discover weaknesses before they cause outages.

Litmus Chaos implements this principle through:

- **Chaos Experiments**: Pre-defined or custom fault injection scenarios
- **Chaos Engines**: Workflow definitions that orchestrate experiments
- **Chaos Results**: Structured output capturing experiment outcomes
- **ChaosHub**: A centralized repository of chaos experiments
- **ChaosCenter**: A web-based dashboard for managing and monitoring chaos

### 1.2 LitmusChaos Versions

The LitmusChaos ecosystem has evolved through several major versions:

- **LitmusChaos 1.x**: The original Litmus chaos operator with CRD-based chaos resources
- **LitmusChaos 2.x (ChaosCenter)**: Introduced the ChaosCenter web UI, ChaosHub, centralized control plane, and a REST/gRPC API layer
- **LitmusChaos 3.x**: Latest release with improved agent management, GitOps integration, and enhanced experiment execution

### 1.3 Key Differentiators

| Feature | Litmus Chaos | Other Tools |
|---------|-------------|-------------|
| Kubernetes-native | Yes (CRDs, operators) | Varies |
| Web UI | ChaosCenter | Some have dashboards |
| Experiment marketplace | ChaosHub (100+ experiments) | Limited |
| Multi-cluster | Yes (agents + control plane) | Varies |
| GitOps support | Yes (ArgoCD/Flux) | Some support |
| RBAC | Fine-grained | Varies |
| CNCF project | Yes (Incubating) | Varies |

---

## 2. Why Use Litmus Chaos

### 2.1 Benefits

**Proactive Resilience Testing**
- Discover failure modes before they impact users
- Validate assumptions about system behavior under stress
- Build confidence in disaster recovery procedures

**Kubernetes-Native Design**
- Experiments run as Kubernetes resources (CRDs)
- Native integration with RBAC, namespaces, and service accounts
- Leverages Kubernetes constructs like pods, jobs, and daemonsets

**Extensive Experiment Library**
- 100+ pre-built experiments on ChaosHub
- Covers infrastructure (node, disk, network), application (pod, container), and platform (k8s API, etcd) faults
- Community-contributed experiments with peer review

**Observability Integration**
- Native Prometheus metrics
- Webhook-based notifications (Slack, Teams, PagerDuty)
- Integration with Grafana dashboards
- Chaos analytics and resilience scoring

**Enterprise Features**
- Multi-tenant ChaosCenter
- LDAP/SAML/SSO authentication
- Audit logging
- Scheduled experiments and chaos workflows

### 2.2 Use Cases

**CI/CD Pipeline Integration**
- Run lightweight chaos experiments as part of deployment pipelines
- Gate releases on chaos experiment pass/fail results
- Shift-left resilience testing

**SRE and Platform Engineering**
- Validate SLOs under failure conditions
- Test auto-scaling, self-healing, and failover mechanisms
- Verify monitoring and alerting accuracy

**Compliance and Certification**
- Demonstrate resilience posture to auditors
- Map chaos results to compliance frameworks
- Generate evidence for disaster recovery readiness

**Development Teams**
- Understand failure modes during development
- Build fault-tolerant code by design
- Reduce mean time to recovery (MTTR) through practice

### 2.3 Prerequisites for Adopting Litmus Chaos

Before adopting Litmus Chaos, teams should have:

1. A running Kubernetes cluster (v1.20+)
2. Basic understanding of Kubernetes concepts (pods, namespaces, RBAC)
3. Observability stack (Prometheus, Grafana recommended)
4. Communication tools for incident notification (Slack, PagerDuty)
5. Organizational buy-in for chaos engineering practice
6. A staging or non-production environment for initial experiments

---

## 3. Architecture Overview

### 3.1 Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ChaosCenter                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐     │
│  │ Web UI   │  │ API      │  │ Authentication   │     │
│  │ (React)  │  │ (gRPC/   │  │ (RBAC/LDAP/SSO) │     │
│  │          │  │  REST)   │  │                  │     │
│  └──────────┘  └──────────┘  └──────────────────┘     │
│         │              │              │                 │
│         └──────────────┼──────────────┘                 │
│                        │                                │
│              ┌─────────▼─────────┐                      │
│              │    MongoDB        │                      │
│              │ (experiment data, │                      │
│              │  results, config) │                      │
│              └───────────────────┘                      │
└──────────────────────────┬──────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  gRPC API   │
                    │  (control)  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐ ┌──▼──────┐ ┌──▼──────┐
       │  Agent      │ │ Agent   │ │ Agent   │
       │ (Cluster A) │ │(Clust B)│ │(Clust C)│
       └──────┬──────┘ └──┬──────┘ └──┬──────┘
              │            │            │
       ┌──────▼──────┐ ┌──▼──────┐ ┌──▼──────┐
       │ Chaos       │ │ Chaos   │ │ Chaos   │
       │ Runner      │ │ Runner  │ │ Runner  │
       └─────────────┘ └─────────┘ └─────────┘
```

### 3.2 Component Descriptions

**ChaosCenter (Control Plane)**
- Web-based dashboard for managing chaos experiments
- Authentication and authorization (RBAC, LDAP, SSO)
- Experiment scheduling, execution, and result visualization
- ChaosHub integration for experiment marketplace
- GitOps synchronization with ArgoCD/Flux

**ChaosCenter Agent (Agent Plane)**
- Deployed in target Kubernetes clusters
- Connects to ChaosCenter via gRPC
- Executes chaos experiments in the target cluster
- Reports results back to the control plane

**ChaosRunner**
- Kubernetes Job created for each experiment execution
- Manages the lifecycle of chaos probes and faults
- Publishes experiment results as Kubernetes events
- Supports multiple concurrent experiment runs

**Chaos Engine**
- Custom Resource Definition (CRD) defining an experiment workflow
- Specifies the sequence of experiments to run
- Defines chaos infrastructure (tolerations, node selectors, etc.)
- References experiments from ChaosHub or custom definitions

**Chaos Experiment**
- Defines a single fault injection scenario
- Specifies the target application/infrastructure
- Defines the fault parameters and expected outcomes
- Includes chaos faults (the actual fault injection code)

**ChaosHub**
- Centralized repository of chaos experiments
- Community-contributed and reviewed experiments
- Version-controlled experiment definitions
- GitOps-compatible experiment distribution

---

## 4. Installation

### 4.1 Prerequisites

- Kubernetes cluster v1.20+
- kubectl configured with cluster access
- Helm 3.x (recommended)
- Minimum 2 CPU, 2GB RAM available for Litmus components
- Storage class with dynamic provisioning (recommended)

### 4.2 Installation via Helm (Recommended)

**Step 1: Add the Litmus Helm repository**

```bash
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm
helm repo update
```

**Step 2: Create the litmus namespace**

```bash
kubectl create namespace litmus
```

**Step 3: Install ChaosCenter**

```bash
helm install chaoscenter litmuschaos/chaoscenter \
  --namespace litmus \
  --setChaosCenter.enabled=true \
  --setChaosCenter.mongoDB.enabled=true \
  --setChaosCenter.chaosCenterSecret=<your-secret-key> \
  --setChaosCenter.loadBalancer=true
```

**Step 4: Verify installation**

```bash
kubectl get pods -n litmus
```

Expected output:
```
NAME                                        READY   STATUS    RESTARTS   AGE
chaoscenter-xxxxx-xxxxx                     1/1     Running   0          5m
chaoscenter-portal-xxxxx-xxxxx              1/1     Running   0          5m
chaoscenter-mongodb-0                       2/2     Running   0          5m
chaoscenter-redis-0                         1/1     Running   0          5m
chaoscenter-subscriber-xxxxx-xxxxx         1/1     Running   0          5m
```

**Step 5: Get the access URL**

```bash
kubectl get svc chaoscenter-portal -n litmus
```

**Step 6: Create the admin user**

```bash
kubectl port-forward svc/chaoscenter-portal 8080:8080 -n litmus
# Open http://localhost:8080 in browser
# Follow the setup wizard to create the admin account
```

### 4.3 Installation via LitmusChaos 3.x

**Step 1: Install the ChaosCenter (Control Plane)**

```bash
helm install chaoscenter litmuschaos/chaoscenter \
  --namespace litmus \
  --create-namespace \
  --setChaosCenter.enablePortal=true \
  --setChaosCenter.chaosCenterSecret=<secret-key> \
  --setChaosCenter.mongodb.auth.enabled=false \
  --setChaosCenter.redis.auth.enabled=false
```

**Step 2: Install the Agent in a target cluster**

```bash
# Generate agent install command from ChaosCenter UI
# Or manually:

helm install chaos-agent litmuschaos/chaos-agent \
  --namespace litmus \
  --create-namespace \
  --set agentScope=cluster \
  --set controlPlaneURL=<chaoscenter-url> \
  --setChaosCenter.chaosCenterSecret=<secret-key>
```

### 4.4 Installation via LitmusChaos 2.x (Legacy)

```bash
kubectl apply -f https://litmuschaos.github.io/litmus/litmus-2.x/litmus-2.x.yaml
```

### 4.5 Verifying the Installation

```bash
# Check all Litmus pods
kubectl get pods -n litmus -l app.kubernetes.io/part-of=litmus

# Check CRDs
kubectl get crd | grep litmus

# Expected CRDs:
# chaosengines.litmuschaos.io
# chaosexperiments.litmuschaos.io
# chaosengines.litmuschaos.io
```

### 4.6 Uninstallation

```bash
# Via Helm
helm uninstall chaoscenter -n litmus

# Remove CRDs (WARNING: deletes all experiment data)
kubectl delete crd chaosengines.litmuschaos.io
kubectl delete crd chaosexperiments.litmuschaos.io
kubectl delete crd chaosresult.litmuschaos.io

# Remove namespace
kubectl delete namespace litmus
```

---

## 5. Configuration

### 5.1 ChaosCenter Configuration

```yaml
# chaoscenter-values.yaml
chaosCenter:
  enablePortal: true
  chaosCenterSecret: "your-24-char-secret-key-here!!"
  chaosInfraSecret: "your-infra-secret-key-here!!"
  
  # MongoDB
  mongoDB:
    enabled: true
    auth:
      enabled: true
      rootUser: admin
      rootPassword: "mongodb-password"
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "standard"
  
  # Redis
  redis:
    enabled: true
    auth:
      enabled: false
    persistence:
      enabled: true
      size: 5Gi
  
  # Portal
  portal:
    port: 8080
  
  # Subscriber
  subscriber:
    image:
      repository: litmuschaos/chaos-center-subscriber
      tag: "3.0.0"
  
  # Frontend
  frontend:
    image:
      repository: litmuschaos/chaos-center-frontend
      tag: "3.0.0"
```

### 5.2 Agent Configuration

```yaml
# agent-values.yaml
agentScope: cluster
controlPlaneURL: "https://chaoscenter.example.com"
chaosCenterSecret: "your-chaos-center-secret"
agentToken: ""
listenPort: 8000

image:
  repository: litmuschaos/chaos-operator
  tag: "3.0.0"

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### 5.3 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CHAOS_CENTER_URL` | ChaosCenter URL | - |
| `CHAOS_CENTER_SECRET` | Authentication secret | - |
| `CHAOS_INFRA_ID` | Infrastructure agent ID | - |
| `AGENT_SCOPE` | Scope: namespace or cluster | cluster |
| `LISTEN_PORT` | gRPC listen port | 8000 |
| `LOG_LEVEL` | Log verbosity (info, debug, error) | info |

---

## 6. Core Concepts

### 6.1 Chaos Engine

The ChaosEngine is the central CRD that orchestrates chaos experiments.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: nginx-chaos-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: 'app=nginx'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '30'
            - name: CHAOS_NAMESPACE
              value: 'default'
```

### 6.2 Chaos Experiment

Defines a single fault injection scenario with all necessary parameters.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-delete
  namespace: litmus
spec:
  definition:
    image: litmuschaos/pod-delete:3.0.0
    scope: Pod
    args:
      - -c
      - ./experiments -name pod-delete
    command:
      - /bin/bash
    env:
      - name: TOTAL_CHAOS_DURATION
        value: '30'
      - name: CHAOS_NAMESPACE
        value: 'default'
      - name: POD_NAME
        value: ''
    labels:
      app.kubernetes.io/part-of: litmus
```

### 6.3 Chaos Result

Records the outcome of an experiment execution.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosResult
metadata:
  name: pod-delete-engine-pod-delete
  namespace: litmus
spec:
  engine: nginx-chaos-engine
  experiment: pod-delete
  experimentStatus:
    phase: completed
    verdict: pass
```

### 6.4 Probes

Probes validate system state during and after chaos injection.

```yaml
spec:
  experiments:
    - name: pod-delete
      spec:
        probe:
          - name: check-pod-recovery
            type: httpProbe
            httpProbe/inputs:
              url: http://nginx-service:80/health
              method:
                get:
                  criteria: ==
                  responseCode: "200"
            mode: Continuous
            runProperties:
              probeTimeout: 5s
              retry: 3
              interval: 2s
          - name: check-endpoint
            type: k8sProbe
            k8sProbe/inputs:
              command: get
              resource: pods
              namespace: default
              fieldSelector: status.phase=Running
            mode: OnChaos
            runProperties:
              probeTimeout: 10s
              retry: 5
              interval: 2s
```

### 6.5 Chaos Infrastructure

Defines the infrastructure configuration for chaos execution.

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosInfrastructure
metadata:
  name: my-cluster
  namespace: litmus
spec:
  scope: cluster
  agentScope: cluster
  appScope: ""
  components:
    infraAgent:
      image: litmuschaos/chaos-operator:3.0.0
```

---

## 7. Usage Guide

### 7.1 Running Your First Experiment

**Step 1: Install Litmus (see Section 4)**

**Step 2: Create a target application**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-chaos-target
  namespace: default
spec:
  replicas: 3
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
        image: nginx:1.24
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
EOF
```

**Step 3: Create the ServiceAccount and RBAC**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: litmus-admin
  namespace: litmus
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: litmus-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: litmus-admin
  namespace: litmus
EOF
```

**Step 4: Create the ChaosEngine**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-delete-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: 'app=nginx'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '30'
            - name: PODS_AFFECTED_PERC
              value: '50'
            - name: FORCE
              value: 'false'
EOF
```

**Step 5: Monitor the experiment**

```bash
# Watch the ChaosEngine
kubectl get chaosengine pod-delete-engine -n litmus -w

# Watch the ChaosResult
kubectl get chaosresult pod-delete-engine-pod-delete -n litmus -w

# Check experiment logs
kubectl logs -f job/pod-delete-engine-pod-delete -n litmus
```

**Step 6: Verify the result**

```bash
kubectl get chaosresult pod-delete-engine-pod-delete -n litmus -o yaml
```

Look for `experimentStatus.verdict: pass` or `fail`.

### 7.2 Running Experiments via ChaosCenter

**Step 1: Access ChaosCenter**

```bash
kubectl port-forward svc/chaoscenter-portal 8080:8080 -n litmus
```

**Step 2: Add Infrastructure**

1. Go to **ChaosCenter > Infrastructure**
2. Click **Connect New Infrastructure**
3. Copy the generated agent install command
4. Run the command in the target cluster

**Step 3: Select an Experiment**

1. Go to **ChaosHub**
2. Browse available experiments (e.g., pod-delete, node-drain, pod-network-latency)
3. Click **Add to Studio**

**Step 4: Configure the Experiment**

1. Set experiment parameters (duration, percentage, target labels)
2. Add probes (optional)
3. Set resilience score thresholds

**Step 5: Run the Experiment**

1. Click **Run Experiment**
2. Monitor real-time results in the dashboard
3. View detailed logs and metrics

### 7.3 Scheduling Experiments

**Via ChaosCenter:**
1. Go to **Chaos Studio > Scheduled Runs**
2. Set cron expression and target experiment
3. Enable/disable as needed

**Via CLI:**

```bash
# Create a CronJob for the ChaosEngine
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pod-delete-schedule
  namespace: litmus
spec:
  schedule: "0 2 * * 1"  # Every Monday at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: litmus-admin
          containers:
          - name: chaos-runner
            image: litmuschaos/chaos-runner:3.0.0
            command: ["/bin/sh", "-c"]
            args:
              - kubectl apply -f /engine/engine.yaml
          restartPolicy: Never
```

### 7.4 GitOps with ArgoCD

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - chaosengine-pod-delete.yaml
  - chaosengine-network-latency.yaml
  - chaosengine-disk-fill.yaml
```

Sync via ArgoCD to version-control your chaos experiments.

---

## 8. Custom Chaos Experiments

### 8.1 Creating a Custom Experiment

**Step 1: Define the experiment manifest**

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: custom-api-chaos
  namespace: litmus
spec:
  definition:
    image: myregistry/custom-chaos:1.0
    scope: Pod
    args:
      - -c
      - ./experiments -name custom-api-chaos
    command:
      - /bin/bash
    env:
      - name: TOTAL_CHAOS_DURATION
        value: '60'
      - name: TARGET_ENDPOINT
        value: 'http://api-service:8080/health'
      - name: FAULT_TYPE
        value: 'latency'
    secrets:
      - name: api-credentials
        mountPath: /etc/chaos/credentials
    labels:
      app.kubernetes.io/part-of: litmus
```

**Step 2: Build the chaos container**

```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o chaos-fault ./cmd/fault

FROM alpine:3.18
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/chaos-fault /usr/local/bin/chaos-fault
ENTRYPOINT ["/usr/local/bin/chaos-fault"]
```

**Step 3: Implement the fault logic**

```go
package main

import (
    "context"
    "flag"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    duration := flag.Int("duration", 60, "chaos duration in seconds")
    endpoint := flag.String("endpoint", "", "target endpoint")
    faultType := flag.String("fault", "latency", "fault type")
    flag.Parse()

    ctx, cancel := context.WithTimeout(
        context.Background(), 
        time.Duration(*duration)*time.Second,
    )
    defer cancel()

    log.Printf("Injecting %s chaos on %s for %ds", *faultType, *endpoint, *duration)

    // Implement fault injection
    switch *faultType {
    case "latency":
        injectLatency(ctx, *endpoint)
    case "error":
        injectErrors(ctx, *endpoint)
    case "timeout":
        injectTimeouts(ctx, *endpoint)
    }

    log.Println("Chaos experiment completed")
}

func injectLatency(ctx context.Context, endpoint string) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            log.Printf("Injecting latency at %s", endpoint)
            client := &http.Client{Timeout: 30 * time.Second}
            req, _ := http.NewRequest("GET", endpoint, nil)
            req.Header.Set("X-Chaos-Latency", "5000")
            resp, err := client.Do(req)
            if err != nil {
                log.Printf("Request failed: %v", err)
            } else {
                resp.Body.Close()
            }
        }
    }
}

func injectErrors(ctx context.Context, endpoint string) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            log.Printf("Injecting 503 errors at %s", endpoint)
        }
    }
}

func injectTimeouts(ctx context.Context, endpoint string) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            log.Printf("Injecting timeouts at %s", endpoint)
        }
    }
}
```

### 8.2 Custom Network Chaos

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: custom-network-chaos
  namespace: litmus
spec:
  definition:
    image: litmuschaos/pod-network-chaos:3.0.0
    scope: Pod
    args:
      - -c
      - ./experiments -name custom-network-chaos
    command:
      - /bin/bash
    env:
      - name: TOTAL_CHAOS_DURATION
        value: '120'
      - name: NETWORK_LATENCY
        value: '200'
      - name: JITTER
        value: '50'
      - name: DESTINATION_IPS
        value: '10.0.0.0/8'
      - name: DESTINATION_HOSTS
        value: 'database-service,cache-service'
    labels:
      app.kubernetes.io/part-of: litmus
```

### 8.3 Custom Resource Chaos

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: custom-resource-chaos
  namespace: litmus
spec:
  definition:
    image: litmuschaos/disk-fill:3.0.0
    scope: Node
    args:
      - -c
      - ./experiments -name custom-disk-fill
    command:
      - /bin/bash
    env:
      - name: TOTAL_CHAOS_DURATION
        value: '180'
      - name: FILL_PERCENTAGE
        value: '80'
      - name: FILL_PATH
        value: '/var/lib/docker'
      - name: FILL_BLOCK_SIZE
        value: '1M'
    labels:
      app.kubernetes.io/part-of: litmus
```

### 8.4 Chaos Workflow

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: multi-experiment-chaos
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: 'app=web'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-network-latency
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: NETWORK_LATENCY
              value: '200'
    - name: pod-io-chaos
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: FILE_PATH
              value: '/var/log/app.log'
            - name: FILE_SIZE
              value: '100'
    - name: pod-cpu-chaos
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: CPU_CORES
              value: '2'
    - name: pod-memory-chaos
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: MEMORY_CONSUMPTION
              value: '200'
```

---

## 9. ChaosHub and Experiment Library

### 9.1 Available Experiments by Category

**Infrastructure Chaos:**
- `node-drain` - Drain a Kubernetes node
- `node-taint` - Add taints to a node
- `node-cpu-hog` - High CPU usage on node
- `node-memory-hog` - High memory usage on node
- `node-network-loss` - Network loss on node
- `node-network-latency` - Network latency on node

**Application Chaos:**
- `pod-delete` - Delete running pods
- `pod-drain` - Drain pods from a node
- `pod-chaos` - Apply resource constraints
- `pod-io-chaos` - Inject I/O delays
- `pod-io-error` - Inject I/O errors
- `pod-cpu-hog` - CPU stress on pods
- `pod-memory-hog` - Memory stress on pods
- `pod-network-latency` - Network latency for pods
- `pod-network-dns-failure` - DNS failures for pods
- `pod-network-dup` - Network duplication for pods

**AWS Chaos:**
- `aws-ec2-termination` - Terminate EC2 instances
- `aws-ec2-stop` - Stop EC2 instances
- `aws-ec2-hibernate` - Hibernate EC2 instances

**GCP Chaos:**
- `gcp-vm-delete` - Delete GCP VMs
- `gcp-vm-stop` - Stop GCP VMs

### 9.2 Connecting ChaosHub

**Via ChaosCenter UI:**
1. Go to **Settings > ChaosHub**
2. Click **Connect New Hub**
3. Enter the hub URL: `https://hub.litmuschaos.io`
4. Verify the connection

**Via CLI:**

```bash
# Install a specific experiment from ChaosHub
kubectl apply -f https://hub.litmuschaos.io/litmus/experiments/pod/pod-delete
```

### 9.3 Version Control for Experiments

```bash
# Export experiment to YAML
kubectl get chaosexperiment pod-delete -n litmus -o yaml > pod-delete.yaml

# Apply to another cluster
kubectl apply -f pod-delete.yaml --context=staging
```

---

## 10. Integration with Kubernetes

### 10.1 RBAC Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: litmus-chaos
rules:
  - apiGroups: ["litmuschaos.io"]
    resources: ["chaosengines", "chaosexperiments", "chaosresults"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["litmuschaos.io"]
    resources: ["chaosengines/status", "chaosexperiments/status", "chaosresults/status"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods", "pods/log", "events"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["services", "endpoints"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### 10.2 Pod Security Standards

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: chaos-runner
  namespace: litmus
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: chaos-fault
    image: litmuschaos/chaos-fault:3.0.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
```

### 10.3 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: litmus-chaos-policy
  namespace: litmus
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: litmus
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: default
```

---

## 11. ChaosCenter Web UI

### 11.1 Dashboard Overview

The ChaosCenter dashboard provides:

- **Chaos Center**: Main navigation hub
- **Infrastructure**: List and manage connected clusters
- **ChaosHub**: Browse and import experiments
- **Chaos Studio**: Create and customize experiments
- **Resilience Score**: Visualize experiment results
- **Settings**: User management, RBAC, and configurations

### 11.2 Key Features

**Experiment Builder**
- Drag-and-drop experiment composition
- Visual parameter configuration
- Probe configuration wizard
- Real-time preview

**Chaos Analytics**
- Experiment history and trends
- Resilience score tracking
- Failure pattern analysis
- Custom dashboards

**Multi-Cluster Management**
- Centralized control plane
- Agent-based remote execution
- Cross-cluster experiment orchestration
- Unified result aggregation

### 11.3 Authentication and RBAC

**Built-in Authentication:**
- Username/password authentication
- Session management with JWT tokens
- Password policies and rotation

**External Authentication:**
- LDAP integration
- SAML/SSO
- OAuth2/OIDC providers

**RBAC Roles:**

| Role | Permissions |
|------|------------|
| Admin | Full access to all features |
| Editor | Create, edit, and run experiments |
| Viewer | View experiments and results only |
| Custom | Fine-grained permissions |

---

## 12. Security

### 12.1 Security Best Practices

**Principle of Least Privilege:**
- Create dedicated ServiceAccounts for chaos experiments
- Use Role-based access control (RBAC) for all chaos resources
- Restrict chaos execution to specific namespaces
- Use Pod Security Standards/Policies

**Network Security:**
- Encrypt chaos control traffic (TLS/mTLS)
- Use network policies to restrict chaos communication
- Implement API rate limiting for chaos operations
- Audit all chaos-related API calls

**Data Security:**
- Encrypt chaos experiment data at rest (MongoDB)
- Use Kubernetes secrets for sensitive configuration
- Implement secret rotation for chaos credentials
- Enable audit logging for compliance

**Runtime Security:**
- Run chaos containers as non-root
- Use read-only root filesystems
- Drop all unnecessary Linux capabilities
- Apply seccomp and AppArmor profiles

### 12.2 TLS Configuration

```yaml
# Enable TLS for ChaosCenter
apiVersion: v1
kind: ConfigMap
metadata:
  name: chaoscenter-config
  namespace: litmus
data:
  CHAOS_CENTER_TLS_ENABLED: "true"
  CHAOS_CENTER_TLS_CERT: "/etc/tls/tls.crt"
  CHAOS_CENTER_TLS_KEY: "/etc/tls/tls.key"
```

### 12.3 Secrets Management

```yaml
# External Secrets Operator integration
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: chaos-center-secrets
  namespace: litmus
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: chaos-center-secrets
  data:
  - secretKey: chaos-center-secret
    remoteRef:
      key: chaos/center-secret
  - secretKey: mongodb-password
    remoteRef:
      key: chaos/mongodb-password
```

### 12.4 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: chaos-center-network-policy
  namespace: litmus
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: chaoscenter
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: litmus
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: litmus
  - to: []
    ports:
    - protocol: TCP
      port: 443
```

---

## 13. Troubleshooting

### 13.1 Common Issues and Solutions

**Issue 1: ChaosEngine stuck in "pending" state**

```bash
# Check ChaosEngine status
kubectl describe chaosengine <engine-name> -n litmus

# Common cause: Missing RBAC
kubectl get sa litmus-admin -n litmus
kubectl get clusterrolebinding litmus-admin

# Fix: Create proper ServiceAccount and RBAC
kubectl apply -f litmus-rbac.yaml
```

**Issue 2: Experiment pods not scheduling**

```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <experiment-pod> -n litmus

# Fix: Add tolerations and nodeSelector
spec:
  tolerations:
  - key: "chaos"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  nodeSelector:
    chaos: "enabled"
```

**Issue 3: ChaosRunner fails to start**

```bash
# Check logs
kubectl logs job/<engine-name>-<experiment-name> -n litmus

# Check RBAC
kubectl auth can-i get pods -n litmus --as=system:serviceaccount:litmus:litmus-admin

# Fix: Ensure proper RBAC is configured
```

**Issue 4: Experiment results not updating**

```bash
# Check ChaosResult
kubectl get chaosresult <engine-name>-<experiment-name> -n litmus -o yaml

# Check subscriber logs
kubectl logs -l app=subscriber -n litmus

# Fix: Ensure subscriber is running and connected to ChaosCenter
```

**Issue 5: Probes failing**

```bash
# Check probe configuration
kubectl describe chaosengine <engine-name> -n litmus | grep -A 20 probe

# Test probe endpoint manually
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl -v http://<service>:<port>/<path>

# Fix: Verify endpoint accessibility and update probe config
```

**Issue 6: Network chaos not working**

```bash
# Check netshoot container
kubectl logs job/<engine-name>-pod-network-chaos -n litmus | grep netshoot

# Verify tc/iptables commands
kubectl exec -it <netshoot-pod> -n litmus -- tc qdisc show

# Fix: Ensure netshoot container is running with proper capabilities
```

**Issue 7: ChaosCenter UI not accessible**

```bash
# Check pod status
kubectl get pods -n litmus -l app=chaoscenter

# Check service
kubectl get svc chaoscenter-portal -n litmus

# Check ingress (if used)
kubectl get ingress -n litmus

# Fix: Port-forward for testing
kubectl port-forward svc/chaoscenter-portal 8080:8080 -n litmus
```

**Issue 8: MongoDB connection failures**

```bash
# Check MongoDB pods
kubectl get pods -n litmus -l app=mongodb

# Check MongoDB logs
kubectl logs chaoscenter-mongodb-0 -c mongodb -n litmus

# Verify connection string
kubectl get secret chaoscenter-mongodb-secret -n litmus -o yaml

# Fix: Ensure MongoDB is healthy and credentials are correct
```

**Issue 9: Agent not connecting to ChaosCenter**

```bash
# Check agent logs
kubectl logs -l app=chaos-center-subscriber -n litmus

# Verify control plane URL
kubectl get configmap chaos-center-agent-config -n litmus -o yaml

# Fix: Update controlPlaneURL and restart agent
```

**Issue 10: Experiment stuck in "running" state**

```bash
# Check ChaosEngine status
kubectl get chaosengine <name> -n litmus -o yaml | grep -A 5 experimentStatus

# Check experiment pod
kubectl get pods -n litmus | grep <engine-name>

# Force delete stuck experiment
kubectl delete chaosengine <name> -n litmus --force
kubectl delete pods -n litmus -l chaos-engine=<name>
```

**Issue 11: ChaosHub not loading experiments**

```bash
# Check ChaosHub connection
kubectl logs -l app=chaos-center-subscriber -n litmus | grep hub

# Verify network connectivity
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl -v https://hub.litmuschaos.io

# Fix: Check firewall rules and proxy settings
```

**Issue 12: Resilience score not updating**

```bash
# Check ChaosResult
kubectl get chaosresult <name> -n litmus -o jsonpath='{.status.experimentStatus}'

# Verify probes are passing
kubectl describe chaosengine <name> -n litmus | grep -A 10 probes

# Fix: Update probe configuration and re-run experiment
```

**Issue 13: Memory/CPU issues with chaos agents**

```bash
# Check resource usage
kubectl top pods -n litmus

# Check agent resource limits
kubectl get deployment chaos-center-subscriber -n litmus -o yaml | grep -A 10 resources

# Fix: Increase resource limits in agent configuration
```

**Issue 14: RBAC permission denied errors**

```bash
# Check ServiceAccount
kubectl get sa litmus-admin -n litmus

# Check role bindings
kubectl get clusterrolebinding litmus-admin

# Test permissions
kubectl auth can-i create pods -n litmus --as=system:serviceaccount:litmus:litmus-admin

# Fix: Create proper RBAC rules for chaos operations
```

**Issue 15: Experiments not cleaning up**

```bash
# Check for orphaned resources
kubectl get jobs,pods,configmaps -n litmus | grep <engine-name>

# Force cleanup
kubectl delete chaosengine <name> -n litmus --cascade=foreground

# Fix: Set proper finalizers and cleanup policies
```

---

## 14. Tips and Best Practices

### 14.1 Experiment Design

1. **Start with blast radius control**: Begin with low-impact experiments (pod-delete with small percentage) and gradually increase blast radius
2. **Use steady state hypothesis**: Define what "normal" looks like before running experiments
3. **Set reasonable timeouts**: Use appropriate TOTAL_CHAOS_DURATION to avoid experiment timeout issues
4. **Use probes**: Always validate expected behavior with probes, not just fault injection
5. **Document experiments**: Maintain a chaos experiment catalog with descriptions, purpose, and expected outcomes

### 14.2 Safety Measures

6. **Implement circuit breakers**: Stop experiments automatically if system health drops below threshold
7. **Use runbooks**: Document manual intervention procedures for each experiment type
8. **Schedule chaos windows**: Run experiments during maintenance windows or low-traffic periods
9. **Notify stakeholders**: Always notify teams before running chaos experiments
10. **Start in staging**: Validate all experiments in staging before running in production

### 14.3 Observability

11. **Monitor metrics**: Use Prometheus metrics to track experiment impact
12. **Set up alerts**: Create alerts for anomaly detection during chaos experiments
13. **Log everything**: Enable detailed logging for chaos components
14. **Use dashboards**: Create Grafana dashboards for chaos experiment visualization
15. **Track resilience scores**: Monitor long-term resilience improvement trends

### 14.4 Kubernetes Best Practices

16. **Use dedicated namespaces**: Isolate chaos resources in litmus namespace
17. **Implement network policies**: Restrict chaos component communication
18. **Apply resource quotas**: Set resource limits for chaos components
19. **Use Pod Security Standards**: Apply restricted security context
20. **Enable audit logging**: Log all chaos-related API operations

### 14.5 Team Collaboration

21. **Share experiment libraries**: Maintain shared chaos experiment repositories
22. **Conduct chaos reviews**: Regularly review experiment results with the team
23. **Train team members**: Ensure all team members understand chaos engineering principles
24. **Create runbooks**: Document step-by-step procedures for chaos experiments
25. **Celebrate learning**: Treat failures as learning opportunities, not blame events

---

## 15. Command Reference

### 15.1 kubectl Commands

```bash
# List all chaos engines
kubectl get chaosengine -n litmus

# Get chaos engine details
kubectl describe chaosengine <engine-name> -n litmus

# Delete a chaos engine
kubectl delete chaosengine <engine-name> -n litmus

# List chaos experiments
kubectl get chaosexperiment -n litmus

# Get chaos experiment YAML
kubectl get chaosexperiment <experiment-name> -n litmus -o yaml

# List chaos results
kubectl get chaosresult -n litmus

# Watch chaos result in real-time
kubectl get chaosresult <result-name> -n litmus -w

# Check chaos runner logs
kubectl logs job/<engine-name>-<experiment-name> -n litmus

# Get chaos infrastructure
kubectl get chaosinfrastructure -n litmus

# Apply chaos engine from file
kubectl apply -f chaosengine.yaml

# Force delete stuck resources
kubectl delete chaosengine <name> -n litmus --force --grace-period=0
```

### 15.2 Helm Commands

```bash
# List Litmus Helm releases
helm list -n litmus

# Upgrade ChaosCenter
helm upgrade chaoscenter litmuschaos/chaoscenter -n litmus -f values.yaml

# Rollback ChaosCenter
helm rollback chaoscenter 1 -n litmus

# Show Helm values
helm show values litmuschaos/chaoscenter

# Diff before upgrade
helm diff upgrade chaoscenter litmuschaos/chaoscenter -n litmus -f values.yaml
```

### 15.3 ChaosCenter API Commands

```bash
# Get auth token
TOKEN=$(curl -s -X POST https://chaoscenter/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | jq -r '.token')

# List experiments
curl -s -X GET https://chaoscenter/api/experiments \
  -H "Authorization: Bearer $TOKEN"

# Create experiment
curl -s -X POST https://chaoscenter/api/experiments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @experiment.json

# Run experiment
curl -s -X POST https://chaoscenter/api/experiments/<id>/run \
  -H "Authorization: Bearer $TOKEN"

# Get experiment result
curl -s -X GET https://chaoscenter/api/experiments/<id>/result \
  -H "Authorization: Bearer $TOKEN"
```

---

## 16. Configuration Reference

### 16.1 ChaosEngine Spec

| Field | Type | Description |
|-------|------|-------------|
| `appinfo.appns` | string | Target application namespace |
| `appinfo.applabel` | string | Target application label selector |
| `appinfo.appkind` | string | Target application kind |
| `chaosServiceAccount` | string | ServiceAccount for chaos execution |
| `engineState` | string | active/pause/engineManagedBy |
| `experiments[]` | array | List of experiments to run |
| `experiments[].name` | string | Experiment name |
| `experiments[].spec.components.env` | array | Environment variables |
| `experiments[].spec.probe` | array | Probes to validate results |

### 16.2 ChaosExperiment Spec

| Field | Type | Description |
|-------|------|-------------|
| `definition.image` | string | Experiment container image |
| `definition.scope` | string | Pod/Node/Container |
| `definition.args` | array | Container arguments |
| `definition.command` | array | Container command |
| `definition.env` | array | Environment variables |
| `definition.secrets` | array | Secrets to mount |
| `definition.labels` | map | Additional labels |

### 16.3 Common Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TOTAL_CHAOS_DURATION` | Experiment duration (seconds) | 30 |
| `CHAOS_NAMESPACE` | Target namespace | default |
| `PODS_AFFECTED_PERC` | Percentage of pods to affect | 0 (all) |
| `FORCE` | Force delete pods | false |
| `CHAOS_INTERVAL` | Interval between chaos iterations | 1 |
| `LIVENESS_PORT` | Liveness probe port | - |
| `APP_NODE_SELECTOR` | Node selector for experiment pods | - |
| `TARGET_CONTAINER` | Target container name | - |

### 16.4 Probe Types

| Probe Type | Description | Use Case |
|------------|-------------|----------|
| `httpProbe` | HTTP endpoint check | Validate service health |
| `k8sProbe` | Kubernetes resource check | Verify pod/node state |
| `cmdProbe` | Command execution check | Run custom validation scripts |
| `promProbe` | Prometheus query check | Validate metrics thresholds |
| `dnsProbe` | DNS resolution check | Verify DNS functionality |

### 16.5 Probe Modes

| Mode | Description | When It Runs |
|------|-------------|--------------|
| `Continuous` | Runs throughout experiment | During chaos injection |
| `Edge` | Runs once at experiment end | After fault injection |
| `OnChaos` | Runs during chaos only | While fault is active |

---

## 17. Real-World Examples

### 17.1 Pod Delete with Recovery Verification

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-delete-nginx
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: 'app=nginx'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '30'
            - name: PODS_AFFECTED_PERC
              value: '50'
            - name: FORCE
              value: 'false'
        probe:
          - name: check-pod-recovery
            type: k8sProbe
            k8sProbe/inputs:
              command: get
              resource: pods
              namespace: default
              fieldSelector: status.phase=Running
              labelSelector: 'app=nginx'
            mode: Edge
            runProperties:
              probeTimeout: 60s
              retry: 10
              interval: 5s
```

### 17.2 Network Latency Testing

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-latency-api
  namespace: litmus
spec:
  appinfo:
    appns: production
    applabel: 'app=api'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-network-latency
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '120'
            - name: NETWORK_LATENCY
              value: '200'
            - name: JITTER
              value: '50'
            - name: DESTINATION_IPS
              value: '10.0.0.0/8'
        probe:
          - name: check-api-latency
            type: httpProbe
            httpProbe/inputs:
              url: http://api-service:8080/health
              method:
                get:
                  criteria: ==
                  responseCode: "200"
            mode: Continuous
            runProperties:
              probeTimeout: 10s
              retry: 5
              interval: 2s
```

### 17.3 Disk Fill Experiment

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: disk-fill-database
  namespace: litmus
spec:
  appinfo:
    appns: production
    applabel: 'app=database'
    appkind: statefulset
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-disk-fill
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '180'
            - name: FILL_PERCENTAGE
              value: '80'
            - name: FILL_PATH
              value: '/var/lib/mysql'
        probe:
          - name: check-disk-usage
            type: httpProbe
            httpProbe/inputs:
              url: http://prometheus:9090/api/v1/query?query=100-(node_filesystem_avail_bytes/node_filesystem_size_bytes*100)
              method:
                get:
                  criteria: <=
                  responseCode: "90"
            mode: Continuous
            runProperties:
              probeTimeout: 10s
              retry: 3
              interval: 10s
```

### 17.4 Comprehensive Resilience Suite

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: resilience-suite
  namespace: litmus
spec:
  appinfo:
    appns: production
    applabel: 'app=web'
    appkind: deployment
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: pod-network-latency
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: NETWORK_LATENCY
              value: '200'
    - name: pod-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: CPU_CORES
              value: '2'
    - name: pod-memory-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: MEMORY_CONSUMPTION
              value: '200'
    - name: pod-io-chaos
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '60'
            - name: FILE_PATH
              value: '/var/log/app.log'
```

### 17.5 Node-Level Chaos

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-chaos-worker
  namespace: litmus
spec:
  appinfo:
    appns: production
    applabel: 'node-role.kubernetes.io/worker='
    appkind: node
  chaosServiceAccount: litmus-admin
  engineState: active
  experiments:
    - name: node-drain
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '120'
            - name: TARGET_NODE
              value: 'worker-2'
            - name: DRAIN_TIMEOUT
              value: '60'
        probe:
          - name: check-pod-reschedule
            type: k8sProbe
            k8sProbe/inputs:
              command: get
              resource: pods
              namespace: production
              fieldSelector: spec.nodeName=worker-2
            mode: Edge
            runProperties:
              probeTimeout: 120s
              retry: 5
              interval: 10s
```

---

## 18. Further Reading

### 18.1 Official Documentation

- LitmusChaos Documentation: https://litmuschaos.io/docs
- ChaosCenter Guide: https://litmuschaos.io/docs/chaoscenter
- ChaosHub: https://hub.litmuschaos.io
- GitHub Repository: https://github.com/litmuschaos/litmus
- CNCF Project Page: https://www.cncf.io/projects/litmuschaos/

### 18.2 Books and Guides

- "Chaos Engineering: System Resiliency in Practice" by Casey Rosenthal, Nora Jones
- "The Chaos Engineering Workbook" by Casey Rosenthal, Nora Jones
- "Building Secure & Reliable Systems" by Google SRE Team

### 18.3 Community Resources

- LitmusChaos Slack: https://kubernetes.slack.com/messages/litmus
- CNCF Slack: https://cloud-native.slack.com
- LitmusChaos Community: https://github.com/litmuschaos/community
- Weekly Community Meeting: https://zoom.us/j/91289375995

### 18.4 Related Tools

- Chaos Mesh: https://chaos-mesh.org
- Chaos Toolkit: https://chaostoolkit.org
- Gremlin: https://www.gremlin.com
- AWS Fault Injection Simulator: https://aws.amazon.com/fis

### 18.5 Blog Posts and Tutorials

- Getting Started with LitmusChaos
- Building Resilient Microservices with Chaos Engineering
- Chaos Engineering in Production: Lessons Learned
- Integrating Chaos Engineering into CI/CD Pipelines
- Measuring and Improving Resilience Scores

---

*Last updated: 2026*
