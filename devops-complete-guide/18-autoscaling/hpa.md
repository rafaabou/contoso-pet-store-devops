# Horizontal Pod Autoscaler (HPA) — Complete Guide

## Table of Contents

1. [What Is HPA](#what-is-hpa)
2. [Why Use HPA](#why-use-hpa)
3. [Architecture](#architecture)
4. [Installation (metrics-server)](#installation-metrics-server)
5. [Core Concepts](#core-concepts)
6. [Configuration Reference](#configuration-reference)
7. [Scaling Behavior](#scaling-behavior)
8. [HPA vs KEDA](#hpa-vs-keda)
9. [HPA with Argo Rollouts](#hpa-with-argo-rollouts)
10. [Troubleshooting](#troubleshooting)
11. [Tips](#tips)
12. [Real-World Example: Contoso Pet Store](#real-world-example-contoso-pet-store)
13. [Commands Reference](#commands-reference)
14. [Further Reading](#further-reading)

---

## What Is HPA

The Horizontal Pod Autoscaler (HPA) is a Kubernetes resource that automatically scales the number of pod replicas in a workload resource (Deployment, StatefulSet, ReplicaSet, or Job) based on observed metrics such as CPU utilization, memory usage, or custom metrics.

HPA operates on a reconciliation loop — typically every 15 seconds — during which it:

1. Collects metrics from the Metrics Server or a custom metrics adapter.
2. Computes the desired replica count based on the current metric value and the target value.
3. Scales the workload's replica count up or down.

The core formula HPA uses is:

```
desiredReplicas = ceil[currentReplicas * ( currentMetricValue / desiredMetricValue )]
```

For example, if you have 4 pods each using 80% CPU and your target is 40%, HPA calculates:

```
desiredReplicas = ceil[4 * (80 / 40)] = ceil[8] = 8 pods
```

HPA was introduced as a Kubernetes alpha feature in version 1.2, graduated to beta in 1.6, and became stable (GA) in 1.23. It is one of the three pillars of Kubernetes autoscaling alongside VPA (Vertical Pod Autoscaler) and the Cluster Autoscaler.

### HPA v1 vs v2

- **HPA v1** (stable since 1.23): Supports only CPU utilization scaling. Simple and sufficient for basic workloads.
- **HPA v2** (stable since 1.23): Adds support for memory, custom metrics, and external metrics, plus the `behavior` field for fine-grained scaling control.

### When HPA Is the Right Choice

- Web servers, API backends, microservices with variable traffic.
- Workloads where you can add or remove replicas without coordination.
- Applications that are stateless or have externalized state.
- Batch processing workers that accept work from a queue.

---

## Why Use HPA

### Cost Optimization

Running fixed replica counts means over-provisioning during off-peak hours. HPA scales down during quiet periods, reducing compute costs by 30-60% for variable workloads. For a 4-pod deployment that only needs 1 pod at night, you save roughly 75% of compute cost during low-traffic hours.

### Performance Under Load

Manual scaling introduces delay — someone must notice the issue, decide, and act. HPA reacts in seconds. When traffic spikes at 2 AM, HPA scales up immediately, keeping latency within SLA without human intervention.

### Reliability

By maintaining the target metric thresholds, HPA prevents cascading failures. If a pod is consuming 90% CPU, response times degrade and eventually health checks fail. HPA adds capacity before this happens.

### Eliminating Toil

Scaling decisions are repetitive and predictable. Automating them removes operational toil — a core SRE principle. Engineers focus on architecture and features, not watching dashboards.

### Graceful Degradation

HPA gradually reduces capacity during quiet periods, allowing pods to drain connections naturally. This is far better than killing pods at random during low traffic.

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                │
│                                                         │
│  ┌──────────────────┐    ┌──────────────────────────┐   │
│  │   HPA Controller │◄───│    Metrics Server        │   │
│  │  (kube-controller │    │  (or custom metrics      │   │
│  │   -manager)       │    │   adapter)               │   │
│  └────────┬─────────┘    └──────────┬───────────────┘   │
│           │                         │                   │
│           ▼                         ▼                   │
│  ┌──────────────────┐    ┌──────────────────────────┐   │
│  │  Target Workload │    │    Metrics API            │   │
│  │  (Deployment,    │    │  (metrics.k8s.io/v1beta1) │   │
│  │   StatefulSet)   │    └──────────────────────────┘   │
│  └──────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
```

### Flow

1. **Metrics Collection**: Metrics Server scrapes kubelet cadvisor endpoints on each node, aggregates pod-level CPU/memory, and exposes them via the Metrics API (`metrics.k8s.io/v1beta1`).

2. **HPA Controller Loop** (every 15s by default):
   - Fetches current metrics from the Metrics API.
   - Fetches current replica count from the workload's `.status.replicas`.
   - Computes the desired replica count.
   - Updates the workload's `.spec.replicas` via the API server.

3. **Workload Controller**: The Deployment/StatefulSet controller observes the replica count change and creates or terminates pods accordingly.

### Metrics Sources

| Source | Metrics | Use Case |
|--------|---------|----------|
| Metrics Server | CPU, Memory | Basic autoscaling |
| Prometheus Adapter | Custom metrics (queue length, RPS) | Application-aware scaling |
| External Metrics Adapter | Cloud metrics (SQS depth, RPS) | Infrastructure-aware scaling |

### Timing

- Metrics Server scrapes every 60 seconds.
- HPA controller polls every 15 seconds (configurable via `--horizontal-pod-autoscaler-sync-period`).
- There is a minimum 30-second stabilization window before scaling down (configurable).
- Total reaction time: typically 30-90 seconds from load spike to new pods ready.

---

## Installation (metrics-server)

### Verify Metrics Server

```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods
```

If not installed:

### Install via Helm

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args[0]="--kubelet-insecure-tls" \
  --set args[1]="--kubelet-preferred-address-types=InternalIP"
```

### Install via Manifest

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### For Local Clusters (minikube, kind)

```bash
minikube addons enable metrics-server
```

For kind:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Then patch the deployment to allow self-signed certificates:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP"}
]'
```

### Verify Installation

```bash
kubectl top nodes
kubectl top pods -n kube-system
```

If you see CPU/memory numbers, metrics-server is working.

### Resource Requests

Metrics Server needs at least:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 200Mi
  limits:
    cpu: 300m
    memory: 400Mi
```

---

## Core Concepts

### targetCPUUtilizationPercentage

The most common metric. HPA targets average CPU utilization across all pods. When the average exceeds the target, HPA scales up; when below, HPA scales down.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

### targetMemoryUtilizationPercentage

Same concept but for memory. Useful for memory-bound workloads like caches.

```yaml
metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

### targetAverageValue

Scales based on a raw metric value (e.g., 1000 requests per second) rather than a percentage.

```yaml
metrics:
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

### behavior

The `behavior` field (HPA v2) controls how aggressively HPA scales up and down, including:

- `scaleUp`: Policies and stabilization windows for increasing replicas.
- `scaleDown`: Policies and stabilization windows for decreasing replicas.
- `selectPolicy`: Which policy to use when multiple policies conflict (`Max`, `Min`, or `Disabled`).

### stabilizationWindowSeconds

A window (in seconds) over which HPA considers metric values before making a scaling decision. This prevents oscillation (rapid scaling up/down).

- **Scale-up stabilization**: Default 0 (scale immediately).
- **Scale-down stabilization**: Default 300 (5 minutes of sustained low usage before scaling down).

### minReplicas / maxReplicas

The bounds within which HPA operates. HPA will never scale below `minReplicas` or above `maxReplicas`, regardless of metrics.

### currentReplicas vs desiredReplicas

- `currentReplicas`: The actual number of running pods.
- `desiredReplicas`: The number HPA calculates pods should be.
- HPA updates the workload's `.spec.replicas` to `desiredReplicas`.

### Scaling Formula (v2 with multiple metrics)

When multiple metrics are specified, HPA takes the maximum of all desired replica counts:

```
desiredReplicas = max(
  ceil[currentReplicas * (metric1_current / metric1_target)],
  ceil[currentReplicas * (metric2_current / metric2_target)],
  ...
)
```

This ensures all metric targets are met — the most demanding metric wins.

---

## Configuration Reference

### HPA v2 Full Spec

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: production
  labels:
    app: api
    team: backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 50
  metrics:
    # CPU utilization
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65

    # Memory utilization
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75

    # Custom metric: requests per second per pod
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
          selector:
            matchLabels:
              app: api
        target:
          type: AverageValue
          averageValue: "2000"

    # External metric: SQS queue depth
    - type: External
      external:
        metric:
          name: sqs_queue_length
          selector:
            matchLabels:
              queue: orders
        target:
          type: AverageValue
          averageValue: "30"

  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
        - type: Pods
          value: 10
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
      selectPolicy: Min
```

### HPA v1 (Legacy)

```yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
```

### Metric Types Explained

| Type | Description | Example |
|------|-------------|---------|
| Resource | CPU or memory utilization percentage | `averageUtilization: 65` |
| Pods | Custom per-pod metric (average value) | `averageValue: "1000"` |
| Object | Metric from another Kubernetes object | `averageValue: "100"` |
| External | Metric from outside the cluster | `averageValue: "30"` |

---

## Scaling Behavior

### scaleUp Policies

Control how fast HPA adds pods during traffic spikes.

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      # Add at most 100% more pods per minute
      - type: Percent
        value: 100
        periodSeconds: 60
      # Or add at most 10 pods per minute (whichever is larger)
      - type: Pods
        value: 10
        periodSeconds: 60
    selectPolicy: Max  # Use the policy that allows most scaling
```

### scaleDown Policies

Control how fast HPA removes pods during quiet periods. Slower scale-down is recommended to avoid disruption.

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300  # 5 minutes
    policies:
      # Remove at most 10% of pods per 2 minutes
      - type: Percent
        value: 10
        periodSeconds: 120
    selectPolicy: Min  # Use the policy that allows least scaling
```

### Policy Types

| Type | Value | Effect |
|------|-------|--------|
| Percent | 100 | Double the pod count per period |
| Percent | 10 | Remove 10% of pods per period |
| Pods | 5 | Add/remove 5 pods per period |

### selectPolicy

- **Max**: Picks the policy that allows the most scaling (aggressive).
- **Min**: Picks the policy that allows the least scaling (conservative).
- **Disabled**: Turns off scaling in that direction entirely.

### Stabilization Window

The stabilization window is a rolling window over which HPA looks at metrics. For scale-down, it ensures that a brief dip in traffic doesn't trigger pod removal.

```
Time ──────────────────────────────►
      │◄── stabilizationWindow ──►│
      │   looks at avg over this  │
      │   window before deciding  │
      └───────────────────────────┘
```

**Default stabilization windows:**
- scaleUp: 0 seconds (immediate)
- scaleDown: 300 seconds (5 minutes)

### Practical Behavior Configurations

**Burst-friendly (API with sudden spikes):**

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
      - type: Pods
        value: 20
        periodSeconds: 15
    selectPolicy: Max
  scaleDown:
    stabilizationWindowSeconds: 600
    policies:
      - type: Percent
        value: 5
        periodSeconds: 120
    selectPolicy: Min
```

**Steady-state (background worker):**

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 120
    policies:
      - type: Percent
        value: 25
        periodSeconds: 120
    selectPolicy: Min
  scaleDown:
    stabilizationWindowSeconds: 600
    policies:
      - type: Percent
        value: 10
        periodSeconds: 300
    selectPolicy: Min
```

---

## HPA vs KEDA

### KEDA Overview

KEDA (Kubernetes Event-Driven Autoscaler) extends HPA with rich event-driven scaling. It supports 60+ scalers (Kafka, RabbitMQ, Prometheus, CloudWatch, etc.) and can scale from 0 to N replicas.

### Comparison

| Feature | HPA | KEDA |
|---------|-----|------|
| Metrics | CPU, Memory, Custom, External | All HPA + 60+ scalers |
| Scale to Zero | No (minReplicas >= 1) | Yes (minReplicas: 0) |
| Scaling Speed | 15-90 seconds | 15-30 seconds |
| Complex Triggers | Limited | Yes (multiple triggers) |
| Prometheus Integration | Via adapter | Native |
| Installation | Built-in | Helm chart |
| Operational Complexity | Low | Medium |

### When to Use HPA

- Simple CPU/memory-based scaling.
- Workloads that always need at least 1 replica.
- Standard web services with predictable traffic patterns.

### When to Use KEDA

- Event-driven workloads (queue consumers, stream processors).
- Need to scale from zero (cost optimization for sporadic workloads).
- Complex scaling logic (e.g., scale based on Kafka lag + CPU).
- Cloud-specific metrics without custom adapters.

### KEDA + HPA Coexistence

KEDA creates HPA objects under the hood. You can use both in the same cluster — just not on the same metric for the same workload.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: queue-worker
spec:
  scaleTargetRef:
    name: queue-worker
  minReplicaCount: 0
  maxReplicaCount: 100
  triggers:
    - type: kafka
      metadata:
        bootstrapServers: kafka:9092
        consumerGroup: orders
        topic: orders
        lagThreshold: "50"
    - type: cpu
      metricType: Utilization
      metadata:
        value: "60"
```

---

## HPA with Argo Rollouts

### The Challenge

Argo Rollouts manages progressive delivery (canary, blue-green). When combined with HPA, scaling decisions must not interfere with rollout strategy.

### Best Practices

1. **Set HPA minReplicas equal to rollout strategy's maxSurge + maxUnavailable + 1** to ensure enough headroom during rollouts.

2. **Use Rollout-aware metrics** — avoid scaling during an active rollout by using Argo's built-in analysis.

3. **Stabilize before scaling** — use longer stabilization windows to prevent HPA from scaling during a canary promotion.

### Example Configuration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: api-rollout
spec:
  replicas: 5
  strategy:
    canary:
      maxSurge: 25%
      maxUnavailable: 0
      steps:
        - setWeight: 20
        - pause: {duration: 5m}
        - analysis:
            templates:
              - templateName: success-rate
        - setWeight: 60
        - pause: {duration: 5m}
        - setWeight: 100
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    name: api-rollout
  minReplicas: 5
  maxReplicas: 30
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 600
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
```

### Interaction Rules

- HPA manages `.spec.replicas` on the Rollout object.
- Rollout manages pod creation during canary/blue-green.
- HPA should use conservative scale-down to avoid removing pods during a rollout.

---

## Troubleshooting

### Issue 1: HPA shows `<unknown>` for Current

**Symptom**: `kubectl get hpa` shows `<unknown>` in CURRENT column.

**Cause**: Metrics Server not installed or not returning data.

**Fix**:
```bash
kubectl top nodes
kubectl top pods -n kube-system
kubectl logs -n kube-system deployment/metrics-server
```
If `kubectl top` fails, install or fix Metrics Server.

### Issue 2: HPA Not Scaling Up

**Symptom**: CPU is above target but pod count doesn't increase.

**Cause**: Multiple possible causes:
- Metrics not yet available (first 2-3 minutes after deployment).
- `maxReplicas` already reached.
- Workload has no resource requests defined.

**Fix**:
```bash
kubectl describe hpa api-hpa
kubectl get deployment api -o yaml | grep -A5 resources
```
Add resource requests if missing:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### Issue 3: HPA Not Scaling Down

**Symptom**: Traffic decreased but pod count remains high.

**Cause**: Stabilization window not yet elapsed. Default is 300 seconds.

**Fix**: Wait 5 minutes, or reduce `stabilizationWindowSeconds`:
```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 60
```

### Issue 4: Pods Flapping (Oscillation)

**Symptom**: HPA rapidly scales up and down.

**Cause**: Stabilization window too short, or metrics are volatile.

**Fix**: Increase stabilization windows and use `selectPolicy: Min` for scale-down.

### Issue 5: Memory-Based Scaling Unstable

**Symptom**: HPA scales based on memory but pods get OOMKilled.

**Cause**: Memory metric reports usage before OOM kill, but new pods also hit limits.

**Fix**: Set `averageUtilization` well below limits (60-70%), and ensure requests reflect actual usage.

### Issue 6: Custom Metrics Return 0

**Symptom**: Custom metric shows 0 in HPA status.

**Cause**: Metrics adapter not configured or metric not exposed.

**Fix**:
```bash
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/my_metric
```

### Issue 7: HPA Conflicts with VPA

**Symptom**: HPA and VPA both try to manage the same workload.

**Cause**: VPA changes resource requests, which changes HPA's denominator, causing scale oscillation.

**Fix**: Use VPA in "Off" mode (recommendation only) or target different metrics. Never use both on CPU/memory for the same workload.

### Issue 8: Scale-Up Is Too Slow

**Symptom**: Latency spikes during traffic surges.

**Cause**: Default `selectPolicy` may pick the more conservative policy.

**Fix**: Set `selectPolicy: Max` and use `Pods` policy type for faster scale-up:
```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
      - type: Pods
        value: 10
        periodSeconds: 15
    selectPolicy: Max
```

### Issue 9: HPA Does Not Scale from Zero

**Symptom**: Workload starts with 0 pods and never scales up.

**Cause**: HPA requires at least 1 pod to collect metrics. Use KEDA for scale-from-zero.

**Fix**: Switch to KEDA or set `minReplicas: 1`.

### Issue 10: External Metrics Not Working

**Symptom**: External metric shows `0` or `<unknown>`.

**Cause**: External metrics adapter not installed or misconfigured.

**Fix**:
```bash
kubectl get --raw /apis/external.metrics.k8s.io/v1beta1
```
Install the appropriate adapter (e.g., Prometheus Adapter, CloudWatch Adapter).

### Issue 11: HPA Using Wrong Metric Source

**Symptom**: HPA targets CPU but uses memory values.

**Cause**: Metric type mismatch in configuration.

**Fix**: Verify with `kubectl describe hpa` — check the metrics section matches your intent.

### Issue 12: Pods Not Ready When HPA Scales

**Symptom**: HPA scales but new pods are in `Pending` or `CrashLoopBackOff`.

**Cause**: Insufficient cluster resources, or pods take too long to become ready.

**Fix**: Increase cluster capacity, optimize startup time, or reduce `maxReplicas`.

### Issue 13: HPA Stuck at minReplicas Despite High Load

**Symptom**: Load is extreme but pods remain at minimum.

**Cause**: `maxReplicas` set too low, or resource requests are so high that new pods can't be scheduled.

**Fix**: Lower resource requests or increase cluster capacity and `maxReplicas`.

### Issue 14: Metrics API Reports Stale Data

**Symptom**: HPA decisions seem delayed or based on old data.

**Cause**: Metrics Server scraping interval (60s) plus HPA sync period (15s) plus stabilization window.

**Fix**: Reduce stabilization windows and wait for metrics to stabilize. Consider a faster metrics adapter.

### Issue 15: HPA Deletes Pods During Rolling Update

**Symptom**: Pod count drops during deployment, causing downtime.

**Cause**: HPA sees reduced average CPU (new pods not yet receiving traffic) and scales down.

**Fix**: Use longer stabilization windows during deployments, or pause HPA during rollouts:
```bash
kubectl patch hpa api-hpa -p '{"spec":{"minReplicas":5,"maxReplicas":5}}'
# ... deploy ...
kubectl patch hpa api-hpa -p '{"spec":{"minReplicas":3,"maxReplicas":30}}'
```

---

## Tips

### 1. Always Set Resource Requests

HPA calculates utilization as `usage / requests`. Without requests, utilization is undefined and HPA won't work.

### 2. Use Multiple Metrics for Resilience

Target both CPU and memory (or CPU + a custom metric). HPA takes the maximum, ensuring all targets are respected.

### 3. Set Conservative Scale-Down

Pods are cheap to create but expensive to kill (connection draining, cache warming). Use 5-10% scale-down per 2-3 minutes with a 5-minute stabilization window.

### 4. Use Aggressive Scale-Up

Traffic spikes are time-sensitive. Use `selectPolicy: Max` with `Pods` policy to add capacity fast.

### 5. Monitor HPA Status

```bash
kubectl get hpa --watch
kubectl describe hpa api-hpa
```

### 6. Use Readiness Probes

HPA only counts ready pods. If readiness probes are slow or flaky, HPA may over-scale.

### 7. Test with Load Generators

Use tools like `hey`, `wrk`, or `k6` to validate HPA behavior before production.

### 8. Pair with Cluster Autoscaler

HPA scales pods; Cluster Autoscaler scales nodes. Use both for full autoscaling.

### 9. Avoid HPA on DaemonSets

DaemonSets run one pod per node. HPA cannot manage DaemonSet replica counts.

### 10. Use appropriate minReplicas for Availability

`minReplicas: 1` means a single pod failure causes downtime. Use at least 2 for production.

### 11. Document Your Scaling Policies

Scaling behavior is part of your SLA. Document the expected scale-up/down times and thresholds.

### 12. Use Labels for Targeting

Use `scaleTargetRef` with specific labels to avoid accidentally targeting the wrong workload.

### 13. Version Control Your HPA

Treat HPA manifests as code. Review changes through PRs.

### 14. Set Realistic Targets

A 50% CPU target gives headroom for spikes. A 90% target leaves almost no buffer.

### 15. Test Disaster Scenarios

Simulate node failures, metrics server outages, and traffic spikes to validate HPA resilience.

---

## Real-World Example: Contoso Pet Store

### Architecture

Contoso Pet Store runs a microservices e-commerce platform on Kubernetes:

- **api-gateway**: Handles all incoming HTTP requests.
- **product-service**: Serves product catalog.
- **order-service**: Processes orders.
- **notification-service**: Sends emails/SMS.
- **search-service**: Elasticsearch-backed search.

### Current HPA Configurations

#### api-gateway (Burst-Heavy)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway-hpa
  namespace: contoso
  labels:
    app: api-gateway
    team: platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 4
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 55
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "3000"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 20
          periodSeconds: 15
        - type: Percent
          value: 100
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 600
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
      selectPolicy: Min
```

**Rationale**: API gateway must respond instantly to traffic spikes. Aggressive scale-up (20 pods per 15s). Conservative scale-down (10% per 2min, 10min stabilization) to avoid connection drops during brief quiet periods.

#### product-service (Steady-State)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
  namespace: contoso
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
  minReplicas: 3
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
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 180
      selectPolicy: Min
```

**Rationale**: Product service is memory-heavy (caching). Moderate scale-up, slow scale-down to preserve cache warmth.

#### order-service (Queue-Driven)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: contoso
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 2
  maxReplicas: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
    - type: External
      external:
        metric:
          name: sqs_queue_depth
          selector:
            matchLabels:
              queue: orders
        target:
          type: AverageValue
          averageValue: "20"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 5
          periodSeconds: 30
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 15
          periodSeconds: 120
      selectPolicy: Min
```

**Rationale**: Order service scales based on SQS queue depth. When orders spike, queue grows, and pods are added to drain the queue.

#### notification-service (Background Worker)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: notification-service-hpa
  namespace: contoso
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: notification-service
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: External
      external:
        metric:
          name: sqs_queue_depth
          selector:
            matchLabels:
              queue: notifications
        target:
          type: AverageValue
          averageValue: "10"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 3
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 600
      policies:
        - type: Percent
          value: 20
          periodSeconds: 180
      selectPolicy: Min
```

**Rationale**: Notifications are non-urgent. Slow scale-down preserves processing capacity for queued messages.

#### search-service (CPU-Heavy)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: search-service-hpa
  namespace: contoso
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: search-service
  minReplicas: 3
  maxReplicas: 25
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
    - type: Pods
      pods:
        metric:
          name: search_queries_per_second
        target:
          type: AverageValue
          averageValue: "500"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 10
          periodSeconds: 30
        - type: Percent
          value: 75
          periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 120
      selectPolicy: Min
```

**Rationale**: Search is CPU-intensive and latency-sensitive. Fast scale-up to maintain search performance.

---

## Commands Reference

### Basic Operations

```bash
# List all HPAs
kubectl get hpa -A

# Get HPA details
kubectl describe hpa api-hpa -n contoso

# Get HPA in YAML
kubectl get hpa api-hpa -o yaml

# Watch HPA status
kubectl get hpa api-hpa --watch

# Get current metrics
kubectl top pods -l app=api-gateway

# Check if metrics server is running
kubectl get deployment metrics-server -n kube-system
```

### Create / Apply

```bash
# Apply HPA from file
kubectl apply -f hpa.yaml

# Create HPA via kubectl
kubectl autoscale deployment api-gateway \
  --cpu-percent=60 \
  --min=3 \
  --max=20 \
  -n contoso

# Create HPA for a StatefulSet
kubectl autoscale statefulset redis \
  --cpu-percent=70 \
  --min=3 \
  --max=10
```

### Update

```bash
# Update HPA via kubectl patch
kubectl patch hpa api-hpa -n contoso --type='json' -p='[
  {"op":"replace","path":"/spec/maxReplicas","value":30}
]'

# Update via YAML
kubectl apply -f hpa-updated.yaml

# Scale manually (bypasses HPA temporarily)
kubectl scale deployment api-gateway --replicas=10 -n contoso
# Note: HPA will revert this on next sync cycle
```

### Delete

```bash
# Delete HPA
kubectl delete hpa api-gapi-hpa -n contoso

# Delete all HPAs in namespace
kubectl delete hpa --all -n contoso
```

### Debugging

```bash
# Check HPA events
kubectl describe hpa api-hpa -n contoso | grep -A20 Events

# Check metrics API
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Check custom metrics
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1

# Check external metrics
kubectl get --raw /apis/external.metrics.k8s.io/v1beta1

# Logs for HPA controller
kubectl logs -n kube-system -l component=kube-controller-manager

# Check replica counts
kubectl get deployment api-gateway -n contoso -o jsonpath='{.status}'
```

### Metrics Verification

```bash
# Verify pod-level metrics
kubectl top pods -n contoso --sort-by=cpu

# Verify node-level metrics
kubectl top nodes --sort-by=cpu

# Get pod metrics in JSON
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/contoso/pods" | jq .
```

### Scaling Tests

```bash
# Install hey for load testing
# hey -z 10m -c 50 http://api-gateway.contoso.svc.cluster.local/api/products

# Watch HPA during test
kubectl get hpa api-gateway -n contoso --watch

# Check pod count
kubectl get pods -n contoso -l app=api-gateway --watch

# Stop load test and watch scale-down
# Ctrl+C hey, then watch HPA
```

---

## Further Reading

### Official Documentation

- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Custom Metrics API](https://github.com/kubernetes/custom-metrics-apiserver)

### Tools and Extensions

- [KEDA](https://keda.sh/) — Event-driven autoscaling
- [Prometheus Adapter](https://github.com/kubernetes-sigs/prometheus-adapter) — Custom metrics from Prometheus
- [Goldilocks](https://github.com/FairwindsOps/goldilocks) — VPA recommendation dashboard
- [Kubecost](https://www.kubecost.com/) — Cost-aware autoscaling

### Blog Posts and Guides

- "Autoscaling best practices" — Kubernetes documentation
- "HPA deep dive" — The New Stack
- "Scaling Kubernetes with HPA and KEDA" — CNCF blog
- "Performance tuning for HPA" — Kubernetes blog

### Videos

- "Kubernetes Autoscaling: HPA, VPA, and Cluster Autoscaler" — KubeCon talks
- "KEDA: Event-driven Autoscaling for Kubernetes" — KubeCon talks

### RFCs and Design Proposals

- [KEP-853: HPA Behavioral Config](https://github.com/kubernetes/enhancements/tree/master/keps/sig-autoscaling/853-hpa-configurable-scaling)
- [KEP-961: HPA to GA](https://github.com/kubernetes/enhancements/tree/master/keps/sig-autoscaling/961-hpa-ga)
