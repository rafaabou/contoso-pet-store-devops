# Vertical Pod Autoscaler (VPA) — Complete Guide

## Table of Contents

1. [What Is VPA](#what-is-vpa)
2. [Why Use VPA](#why-use-vpa)
3. [Architecture](#architecture)
4. [Installation](#installation)
5. [Core Concepts](#core-concepts)
6. [Configuration](#configuration)
7. [VPA vs HPA](#vpa-vs-hpa)
8. [Troubleshooting](#troubleshooting)
9. [Tips](#tips)
10. [Real-World Example](#real-world-example)
11. [Commands Reference](#commands-reference)
12. [Further Reading](#further-reading)

---

## What Is VPA

The Vertical Pod Autoscaler (VPA) automatically adjusts CPU and memory resource requests for pods based on historical usage. Unlike HPA (which adds/removes replicas), VPA adjusts the resources allocated to each individual pod — making pods larger or smaller vertically.

VPA operates in three modes:

- **Off**: Provides recommendations only. Does not modify pods. Safe for observation.
- **Initial**: Applies recommendations only when pods are created. Existing pods are unaffected.
- **Auto**: Applies recommendations by evicting pods so they restart with new resource settings.

VPA is particularly useful for workloads where:
- Resource usage is variable but replica count should stay fixed.
- Memory leaks or growing usage patterns need periodic resizing.
- You want to right-size resource requests to prevent waste.

### How VPA Differs from HPA

| Aspect | HPA | VPA |
|--------|-----|-----|
| Scaling Direction | Horizontal (replicas) | Vertical (resources) |
| Metric Focus | CPU, Memory, Custom | CPU, Memory |
| Pod Lifecycle | Adds/removes pods | Evicts/restarts pods |
| Downtime | No | Brief restart during eviction |
| Stateful Workloads | Limited | Better (preserves replica count) |

### When to Use VPA

- Databases, caches, and stateful workloads where you can't easily add replicas.
- Workloads with unpredictable memory usage patterns.
- Right-sizing pods after initial capacity planning.
- Environments where you want to reduce resource waste without changing replica counts.

---

## Why Use VPA

### Right-Sizing Resources

Most Kubernetes workloads are over-provisioned. Developers set resource requests based on guesses, not data. VPA analyzes historical usage and recommends optimal values, often reducing resource consumption by 30-60%.

### Reducing Waste

Over-provisioned requests mean the scheduler allocates more resources than needed. Across a large cluster, this wastes thousands of dollars monthly. VPA identifies and corrects this.

### Preventing OOMKills

When actual usage exceeds memory limits, pods get OOMKilled. VPA adjusts limits upward based on actual usage patterns, preventing unexpected restarts.

### Handling Memory Leaks

For applications with gradual memory growth, VPA periodically resizes pods, giving them more headroom before OOMKill.

### Complementing HPA

VPA recommends while HPA scales. Used together (on different metrics or with VPA in Off mode), they provide comprehensive autoscaling.

---

## Architecture

### Components

VPA consists of three independent components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                     │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Recommender  │  │  Updater    │  │ Admission Controller│ │
│  │              │  │             │  │                     │ │
│  │ Analyzes     │  │ Evicts pods │  │ Mutates pod specs  │ │
│  │ metrics and  │  │ that need   │  │ at creation with   │ │
│  │ recommends   │  │ resource    │  │ VPA recommendations│ │
│  │ resource     │  │ updates     │  │                     │ │
│  │ requests     │  │             │  │                     │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
│         │                │                     │            │
│         ▼                ▼                     ▼            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              VPA Object (Custom Resource)               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Recommender

- Watches VPA objects and pod resource usage.
- Collects metrics from Metrics Server.
- Calculates recommended CPU and memory requests.
- Stores recommendations in the VPA status.
- Runs a long-running process, updating recommendations every 1 minute.

### Updater

- Watches VPA objects with `updateMode: Auto` or `Initial`.
- Identifies pods whose current resources differ from recommendations by more than 10% (configurable).
- Evicts pods that need updating (uses Eviction API, respects PDBs).
- New pods are created with updated resources via the Admission Controller.

### Admission Controller

- Mutating webhook that intercepts pod creation.
- Injects VPA-recommended resource requests into new pods.
- Only modifies pods that match a VPA's `targetRef`.
- Runs as a Kubernetes ValidatingWebhookConfiguration.

### How VPA Recommendations Work

1. Recommender collects CPU/memory usage over a window (typically 24 hours).
2. Calculates the 90th percentile usage (configurable).
3. Adds a safety margin (default 15% for CPU, 15% for memory).
4. Produces three recommendation values: `lowerBound`, `target`, `upperBound`.
5. The `target` value is what gets applied to pods.

### Metrics Flow

```
Pod → kubelet/cadvisor → Metrics Server → VPA Recommender
                                              │
                                              ▼
                                        Recommendations
                                              │
                                              ▼
                                   VPA Status (kubectl describe vpa)
```

---

## Installation

### Install via Helm

```bash
# Add the autoscaler Helm repo
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

# Install VPA
helm install vpa autoscaler/vertical-pod-autoscaler \
  --namespace kube-system \
  --set recommender.image.tag=1.2.0 \
  --set updater.image.tag=1.2.0 \
  --set admissionController.image.tag=1.2.0
```

### Install via Manifest

```bash
# Clone the autoscaler repo
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Run the installer script
./hack/vpa-up.sh
```

### Verify Installation

```bash
kubectl get pods -n kube-system -l app=vpa-recommender
kubectl get pods -n kube-system -l app=vpa-updater
kubectl get pods -n kube-system -l app=vpa-admission-controller
```

All three components should be `Running`.

### Uninstall

```bash
helm uninstall vpa -n kube-system
# or
./hack/vpa-down.sh
```

### Prerequisites

- Metrics Server installed and running.
- Kubernetes 1.22+ (VPA CRD availability).
- No existing HPA targeting CPU/memory on the same workloads (see VPA vs HPA section).

---

## Core Concepts

### Update Modes

#### Off Mode

VPA computes recommendations but does not apply them. Safe for observation.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  updatePolicy:
    updateMode: "Off"
```

**Use case**: Evaluate VPA recommendations before enabling auto-update.

#### Initial Mode

VPA applies recommendations only when pods are created. Existing pods are untouched.

```yaml
updatePolicy:
  updateMode: "Initial"
```

**Use case**: You want new pods to get optimized resources but don't want existing pods restarted.

#### Auto Mode

VPA evicts pods that need updated resources. The Updater kills pods, and the Admission Controller sets new values on restart.

```yaml
updatePolicy:
  updateMode: "Auto"
```

**Use case**: Fully automated vertical scaling.

#### Recreate Mode

Similar to Auto but explicitly triggers pod recreation when recommendations change significantly.

```yaml
updatePolicy:
  updateMode: "Recreate"
```

### Recommendation Types

| Type | Description |
|------|-------------|
| `lowerBound` | Minimum recommended resources |
| `target` | Recommended resources (what VPA applies) |
| `upperBound` | Maximum recommended resources |
| `uncappedTarget` | Target without min/max constraints |

### Resource Targeting

VPA can target specific containers within a pod:

```yaml
resourcePolicy:
  containerPolicies:
    - containerName: api
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 4
        memory: 8Gi
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits
```

### Off Mode Recommendations

Even in Off mode, VPA provides valuable insights:

```bash
kubectl describe vpa api-vpa
```

Output shows `recommendation.containerRecommendations[].target` with optimal CPU/memory values.

---

## Configuration

### Full VPA Spec

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
  namespace: production
  labels:
    app: api
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api

  updatePolicy:
    updateMode: "Auto"
    minReplicas: 2  # Always keep at least this many pods during updates

  resourcePolicy:
    containerPolicies:
      - containerName: api
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 4
          memory: 8Gi
        controlledResources: ["cpu", "memory"]
        controlledValues: RequestsAndLimits

      - containerName: sidecar
        mode: "Off"  # Don't touch the sidecar
```

### Configuration Fields

| Field | Description | Default |
|-------|-------------|---------|
| `targetRef` | Workload to target (Deployment, StatefulSet, etc.) | Required |
| `updatePolicy.updateMode` | Mode: Off, Initial, Auto, Recreate | Off |
| `updatePolicy.minReplicas` | Min pods during update | 2 |
| `resourcePolicy.containerPolicies` | Per-container resource rules | All containers |
| `resourcePolicy.containerPolicies[].mode` | Off to skip a container | - |
| `resourcePolicy.containerPolicies[].minAllowed` | Floor for recommendations | 0 |
| `resourcePolicy.containerPolicies[].maxAllowed` | Ceiling for recommendations | ∞ |
| `resourcePolicy.containerPolicies[].controlledResources` | Which resources to control | [cpu, memory] |
| `resourcePolicy.containerPolicies[].controlledValues` | Requests only or both | RequestsAndLimits |

### Multiple Container Policies

```yaml
resourcePolicy:
  containerPolicies:
    # Main application container
    - containerName: app
      minAllowed:
        cpu: 200m
        memory: 256Mi
      maxAllowed:
        cpu: 8
        memory: 16Gi
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits

    # Logging sidecar
    - containerName: log-shipper
      minAllowed:
        cpu: 50m
        memory: 64Mi
      maxAllowed:
        cpu: 500m
        memory: 512Mi
      controlledResources: ["cpu"]
      controlledValues: RequestsOnly

    # Monitoring sidecar
    - containerName: envoy
      mode: "Off"  # Don't modify this container
```

### VPA with StatefulSets

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: postgres
  updatePolicy:
    updateMode: "Auto"
    minReplicas: 3
  resourcePolicy:
    containerPolicies:
      - containerName: postgres
        minAllowed:
          cpu: 500m
          memory: 1Gi
        maxAllowed:
          cpu: 16
          memory: 64Gi
```

---

## VPA vs HPA

### The Golden Rule

**Never use VPA and HPA on the same resource (CPU/memory) for the same workload.**

VPA changes resource requests, which changes the denominator in HPA's utilization calculation. This creates a feedback loop:

1. HPA sees high CPU utilization → adds pods.
2. VPA sees high CPU usage → increases requests.
3. Lower utilization → HPA removes pods.
4. Higher utilization → HPA adds pods.
5. Infinite loop.

### When to Use Both

You CAN use VPA and HPA together if:

1. **VPA in Off mode**: VPA provides recommendations; HPA acts on them.
2. **Different metrics**: VPA targets CPU/memory; HPA targets custom/external metrics.
3. **Different workloads**: VPA on StatefulSets; HPA on Deployments.

### Recommended Pattern

```yaml
# VPA in Off mode for recommendations
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  updatePolicy:
    updateMode: "Off"
---
# HPA for actual scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

### Decision Matrix

| Scenario | VPA | HPA |
|----------|-----|-----|
| Need more capacity during spikes | - | ✓ |
| Right-size over-provisioned pods | ✓ | - |
| Stateful workloads (DBs, caches) | ✓ | - |
| Stateless web services | - | ✓ |
| Cost optimization (reducing waste) | ✓ | ✓ |
| Scale from zero | - | ✓ |
| Event-driven workloads | - | ✓ (KEDA) |

---

## Troubleshooting

### Issue 1: VPA Recommendations Not Updating

**Symptom**: VPA status shows stale recommendations.

**Cause**: VPA Recommender not running or Metrics Server not providing data.

**Fix**:
```bash
kubectl get pods -n kube-system -l app=vpa-recommender
kubectl logs -n kube-system -l app=vpa-recommender
kubectl top pods
```
Ensure Metrics Server is running and returning data.

### Issue 2: Pods Not Being Updated

**Symptom**: VPA is in Auto mode but pods keep old resources.

**Cause**: Recommendations haven't changed enough (default 10% threshold).

**Fix**: Wait for usage to deviate, or reduce the update threshold. Check VPA status:
```bash
kubectl describe vpa api-vpa
```

### Issue 3: Pods OOMKilled Despite VPA

**Symptom**: VPA recommends higher memory but pods still get OOMKilled.

**Cause**: VPA recommendations are based on historical usage; a spike exceeds the upperBound.

**Fix**: Set higher `maxAllowed` or use `controlledValues: RequestsOnly` to let limits grow with requests.

### Issue 4: VPA Evicts Pods Too Frequently

**Symptom**: Pods restart constantly.

**Cause**: Usage oscillates around the threshold, causing repeated evictions.

**Fix**: Increase `minReplicas` in `updatePolicy`, or switch to `Initial` mode.

### Issue 5: VPA Conflicts with HPA

**Symptom**: Pod count and resource requests oscillate.

**Cause**: Both VPA and HPA are active on the same workload targeting CPU/memory.

**Fix**: Set VPA to `Off` mode, or have HPA target custom metrics instead.

### Issue 6: Sidecar Containers Modified

**Symptom**: VPA changes resources on sidecar containers unexpectedly.

**Cause**: No per-container resource policy defined.

**Fix**: Add `containerPolicies` with `mode: "Off"` for sidecars.

### Issue 7: VPA Not Installing

**Symptom**: VPA pods not created after installation.

**Cause**: CRDs not installed, or RBAC permissions missing.

**Fix**:
```bash
kubectl get crd | grep vpa
kubectl get clusterrole vpa-actor -o yaml
```
Reinstall VPA with proper permissions.

### Issue 8: Recommendations Way Too High

**Symptom**: VPA recommends 16 CPU for a pod that uses 200m.

**Cause**: Memory leak or burst causing extreme usage; VPA's safety margin amplifies the spike.

**Fix**: Set `maxAllowed` to cap recommendations:
```yaml
resourcePolicy:
  containerPolicies:
    - containerName: app
      maxAllowed:
        cpu: 4
        memory: 8Gi
```

### Issue 9: VPA Recreate Mode Causes Downtime

**Symptom**: Brief downtime during VPA-triggered pod recreation.

**Cause**: VPA evicts pods without respecting PDBs (depending on version).

**Fix**: Ensure PodDisruptionBudgets are set, and VPA respects them. Use `minReplicas: 2` in update policy.

### Issue 10: VPA Recommendations Don't Match Actual Usage

**Symptom**: kubectl top shows different values than VPA recommendations.

**Cause**: VPA uses a 24-hour window with safety margins; kubectl top shows real-time.

**Fix**: This is expected. VPA recommendations include headroom for spikes. Compare with `kubectl describe vpa` lower/upper bounds.

---

## Tips

### 1. Start with Off Mode

Always begin with `updateMode: Off`. Observe recommendations for 24-48 hours before enabling auto-update.

### 2. Set minAllowed and maxAllowed

Prevent VPA from recommending absurdly low or high values. Use baselines from your current resource settings.

### 3. Use Per-Container Policies

Don't let VPA modify sidecars or init containers unless you explicitly want it to.

### 4. Monitor VPA Recommendations

```bash
kubectl get vpa -A
kubectl describe vpa api-vpa
```

### 5. Combine with Goldilocks

Goldilocks (Fairwinds) provides a dashboard showing VPA recommendations for all workloads.

### 6. Set Update Mode Based on Risk Tolerance

- Off: Zero risk, observation only.
- Initial: Low risk, only new pods affected.
- Auto: Medium risk, pods evicted periodically.

### 7. Use VPA for Right-Sizing

Run VPA in Off mode on all workloads for 2 weeks. The recommendations reveal where you're over-provisioned.

### 8. Respect PodDisruptionBudgets

VPA's Updater respects PDBs. Ensure PDBs are configured so VPA doesn't violate availability.

### 9. Pair with Cluster Autoscaler

VPA makes pods larger; Cluster Autoscaler adds nodes to fit them.

### 10. Don't Use VPA for Stateless Web Services

HPA is better for stateless workloads. VPA shines for stateful, fixed-replica workloads.

---

## Real-World Example

### Contoso Pet Store VPA Configuration

```yaml
# Database VPA (PostgreSQL)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
  namespace: contoso
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: postgres
  updatePolicy:
    updateMode: "Auto"
    minReplicas: 3
  resourcePolicy:
    containerPolicies:
      - containerName: postgres
        minAllowed:
          cpu: 500m
          memory: 1Gi
        maxAllowed:
          cpu: 16
          memory: 64Gi
        controlledResources: ["cpu", "memory"]
        controlledValues: RequestsAndLimits
      - containerName: exporter
        mode: "Off"

---
# Redis VPA (Cache)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: redis-vpa
  namespace: contoso
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: redis
  updatePolicy:
    updateMode: "Auto"
    minReplicas: 3
  resourcePolicy:
    containerPolicies:
      - containerName: redis
        minAllowed:
          cpu: 200m
          memory: 512Mi
        maxAllowed:
          cpu: 8
          memory: 32Gi
        controlledResources: ["memory"]
        controlledValues: RequestsAndLimits

---
# API Gateway VPA (Off mode for recommendations only)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-gateway-vpa
  namespace: contoso
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  updatePolicy:
    updateMode: "Off"
```

---

## Commands Reference

```bash
# List all VPAs
kubectl get vpa -A

# Describe VPA
kubectl describe vpa postgres-vpa -n contoso

# Check VPA recommendations
kubectl get vpa postgres-vpa -o jsonpath='{.status.recommendation}'

# Check VPA pods
kubectl get pods -n kube-system -l app=vpa-recommender
kubectl get pods -n kube-system -l app=vpa-updater
kubectl get pods -n kube-system -l app=vpa-admission-controller

# Check VPA logs
kubectl logs -n kube-system -l app=vpa-recommender
kubectl logs -n kube-system -l app=vpa-updater

# Apply VPA
kubectl apply -f vpa.yaml

# Delete VPA
kubectl delete vpa postgres-vpa -n contoso

# Check pod resources
kubectl get pods -n contoso -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}'
```

---

## Further Reading

- [VPA Documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [VPA Design Proposal](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#design)
- [Goldilocks](https://github.com/FairwindsOps/goldilocks)
- [HPA + VPA Together](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#scaling-on-multiple-metrics)
