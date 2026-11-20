# Cluster Autoscaler — Complete Guide

## Table of Contents

1. [What Is Cluster Autoscaler](#what-is-cluster-autoscaler)
2. [Why Use It](#why-use-it)
3. [Architecture](#architecture)
4. [Installation (Helm)](#installation-helm)
5. [Core Concepts](#core-concepts)
6. [Configuration](#configuration)
7. [Cluster Autoscaler vs Karpenter](#cluster-autoscaler-vs-karpenter)
8. [Cloud-Specific Setup](#cloud-specific-setup)
9. [On-Premise Setup](#on-premise-setup)
10. [Troubleshooting](#troubleshooting)
11. [Tips](#tips)
12. [Real-World Example](#real-world-example)
13. [Commands Reference](#commands-reference)
14. [Further Reading](#further-reading)

---

## What Is Cluster Autoscaler

The Cluster Autoscaler automatically adjusts the number of nodes in a Kubernetes cluster based on pending pods and node utilization. When pods can't be scheduled due to insufficient resources, Cluster Autoscaler adds nodes. When nodes become underutilized, it removes them.

Cluster Autoscaler is a component of the Kubernetes project (under `kubernetes/autoscaler`) and works with major cloud providers (AWS, GCP, Azure) and some on-premises solutions (via APIs).

### How It Differs from HPA and VPA

| Component | Scales | What Changes |
|-----------|--------|--------------|
| HPA | Pods | Number of pod replicas |
| VPA | Pods | CPU/memory per pod |
| Cluster Autoscaler | Nodes | Number of nodes in the cluster |

All three work together:
1. HPA adds pods when load increases.
2. Cluster Autoscaler adds nodes when pods are pending.
3. When load decreases, HPA removes pods.
4. When nodes become empty, Cluster Autoscaler removes them.

---

## Why Use It

### Cost Optimization

Running fixed-size clusters wastes money during low-traffic periods. A cluster scaled to peak capacity at 3 AM wastes 80% of its resources. Cluster Autoscaler scales down during quiet hours, reducing cloud bills by 30-50%.

### Improved Scheduling

When pods are in `Pending` state due to insufficient resources, Cluster Autoscaler adds nodes to fit them. This prevents deployment delays and keeps workloads running.

### High Availability

By maintaining enough nodes to satisfy pod scheduling constraints (topology spread, node affinity, etc.), Cluster Autoscaler ensures workloads can recover from node failures.

### Developer Productivity

Developers don't need to worry about cluster capacity. They set resource requests; the cluster grows to accommodate them.

### Handling Batch Workloads

Batch jobs (ML training, data processing) need large clusters temporarily. Cluster Autoscaler spins up nodes for the job and removes them when done.

---

## Architecture

### Components

```
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes API Server                      │
│                                                              │
│  ┌──────────────────┐    ┌───────────────────────────────┐   │
│  │ Cluster Autoscaler│    │   Cloud Provider API          │   │
│  │                   │───▶│   (AWS EC2, GCP GCE, Azure)  │   │
│  │  Watches:         │    │                               │   │
│  │  - Unschedulable  │    │   Actions:                    │   │
│  │    pods           │    │   - Create node               │   │
│  │  - Node utilization│   │   - Delete node               │   │
│  │  - Node counts    │    │   - Resize node group         │   │
│  └──────────────────┘    └───────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              Node Group (ASG / MIG / VMSS)            │    │
│  │  Node 1    Node 2    Node 3    Node 4    Node 5      │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

### Scale-Up Flow

1. HPA (or other controller) creates a pod.
2. Pod has resource requests that can't be satisfied by existing nodes.
3. Pod remains in `Pending` state with `Unschedulable` condition.
4. Cluster Autoscaler detects the pending pod.
5. Analyzes pod requirements (CPU, memory, taints, tolerations, affinity).
6. Determines which node group to scale.
7. Calls cloud provider API to add a node.
8. New node joins the cluster.
9. Scheduler places the pending pod on the new node.

### Scale-Down Flow

1. Cluster Autoscaler periodically checks node utilization (every 10 seconds).
2. If a node has been underutilized (most pods have low utilization) for 10 minutes (configurable).
3. Checks if pods can be moved to other nodes.
4. Checks PodDisruptionBudgets (PDBs).
5. Cordons the node (marks unschedulable).
6. Evicts pods gracefully.
7. When node is empty, calls cloud provider API to delete it.

### Timing

| Action | Default Timing |
|--------|----------------|
| Scale-up check | Every 10 seconds |
| Scale-down delay | 10 minutes underutilized |
| Scale-down scan | Every 15 seconds |
| Node deletion | After pods are evicted |
| Total scale-up time | 30 seconds - 5 minutes |

---

## Installation (Helm)

### Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Cloud provider credentials configured

### Install via Helm

```bash
# Add the autoscaler Helm repo
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

# Install Cluster Autoscaler (AWS example)
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-cluster \
  --set awsRegion=us-west-2 \
  --set rbac.create=true \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler
```

### Install for GCP

```bash
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-cluster \
  --set cloudProvider=gce \
  --set rbac.create=true
```

### Install for Azure

```bash
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-cluster \
  --set cloudProvider=azure \
  --set azure.resourceGroup=my-resource-group \
  --set azure.subscriptionId=my-subscription-id \
  --set azure.tenantId=my-tenant-id \
  --set azure.clientId=my-client-id \
  --set azure.clientSecret=my-client-secret \
  --set rbac.create=true
```

### Verify Installation

```bash
kubectl get pods -n kube-system -l app=cluster-autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler
```

### Uninstall

```bash
helm uninstall cluster-autoscaler -n kube-system
```

---

## Core Concepts

### Expander

The expander decides which node group to scale when multiple groups could fit the pending pods.

| Expander | Behavior |
|----------|----------|
| `random` | Randomly picks a node group (default) |
| `least-waste` | Picks the group that will have the least unused resources |
| `most-pods` | Picks the group that will schedule the most pending pods |
| `priority` | Uses priority annotations to pick groups |
| `price` | Picks the cheapest option (AWS only) |
| `clusterinfo` | Picks the group with the most nodes (for debugging) |

**Priority Expander Example:**

```yaml
# ClusterProportionalAutoscaler annotation
autoscaling.k8s.io/expander: priority
autoscaling.k8s.io/priority: "1"  # Higher = preferred
```

### Scale-Down

Scale-down removes underutilized nodes:

- **Threshold**: Node utilization below `--scale-down-utilization-threshold` (default 0.5).
- **Delay**: Node must be underutilized for `--scale-down-unneeded-time` (default 10 minutes).
- **Graceful**: Respects PDBs, cordons node, evicts pods, waits for deletion.
- **Empty nodes**: Deleted after `--node-empty` timeout (default 10 minutes).

### Balance-Similar-Node-Groups

Ensures node groups with similar configurations (instance types, labels, zones) stay balanced. If one group has significantly more nodes than another, Cluster Autoscaler may prefer adding to the less-represented group.

### Max Node Provision Time

Maximum time to wait for a new node to become ready (default 15 minutes). If the node isn't ready by then, Cluster Autoscaler may delete it and try another group.

### Pod Priority and Preemption

Cluster Autoscaler respects pod priorities. High-priority pods may preempt low-priority pods, freeing resources without adding nodes.

---

## Configuration

### Key Parameters

```yaml
# Helm values.yaml
autoDiscovery:
  clusterName: my-cluster

awsRegion: us-west-2

rbac:
  create: true
  serviceAccount:
    create: true
    name: cluster-autoscaler
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler

extraArgs:
  balance-similar-node-groups: "true"
  skip-nodes-with-local-storage: "false"
  expander: least-waste
  scale-down-utilization-threshold: "0.5"
  scale-down-unneeded-time: "10m"
  scale-down-delay-after-add: "10m"
  scale-down-delay-after-delete: "0s"
  scale-down-delay-after-failure: "3m"
  max-node-provision-time: "15m"
  node-group-auto-discovery: "asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/my-cluster"
  balance-similar-node-groups: "true"
  skip-nodes-with-system-pods: "true"
  skip-nodes-with-local-storage: "false"
  ignore-mirror-pods-utilization: "true"
  max-graceful-termination-sec: "600"
  max-total-unready-percentage: "33"
  ok-total-unready-count: "3"
  new-node-scale-up-delay: "10s"
  max-node-group-nodes: "100"
  min-node-group-target-size: "1"

resources:
  requests:
    cpu: 100m
    memory: 300Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Annotation-Based Configuration

```yaml
# On node group (ASG/MIG)
autoscaling.k8s.io/expander: least-waste
autoscaling.k8s.io/min-size: "2"
autoscaling.k8s.io/max-size: "20"
```

### PodDisruptionBudgets

Cluster Autoscaler respects PDBs. Ensure critical workloads have PDBs:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
```

### Priority Classes

Use priority classes to protect critical workloads from preemption:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical
value: 1000000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: Critical workloads that must not be evicted
```

---

## Cluster Autoscaler vs Karpenter

### Karpenter Overview

Karpenter (AWS only, open-source by AWS) is a next-generation node autoscaler that directly provisions nodes without cloud provider node groups.

### Comparison

| Feature | Cluster Autoscaler | Karpenter |
|---------|-------------------|-----------|
| Cloud Providers | AWS, GCP, Azure, on-prem | AWS only |
| Node Provisioning | Via ASG/MIG/VMSS | Direct EC2 API |
| Provisioning Speed | 3-5 minutes | 30-60 seconds |
| Node Flexibility | Fixed instance types per group | Any compatible instance type |
| Consolidation | Basic (delete underutilized) | Advanced (consolidate workloads) |
| Configuration | Cloud-specific | Provider-agnostic CRDs |
| Maturity | Very mature | Production-ready (GA since 0.32) |

### When to Use Cluster Autoscaler

- Multi-cloud or on-premises environments.
- GCP or Azure deployments.
- Existing infrastructure with managed node groups.
- Stable, predictable scaling patterns.

### When to Use Karpenter

- AWS-only environments.
- Need fast provisioning (ML training, batch jobs).
- Want optimal instance selection (cost/performance).
- Complex scheduling requirements (GPU, spot, etc.).

### Using Both

Do NOT use both on the same cluster. They will conflict over node management. Choose one per cluster.

---

## Cloud-Specific Setup

### AWS (EKS)

#### IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    }
  ]
}
```

#### ASG Tags

Each ASG must have tags:

```
k8s.io/cluster-autoscaler/enabled = true
k8s.io/cluster-autoscaler/my-cluster = owned
```

#### Helm Values

```yaml
autoDiscovery:
  clusterName: my-cluster
awsRegion: us-west-2
rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/cluster-autoscaler
```

### GCP (GKE)

#### IAM Roles

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.admin
```

#### MIG Labels

```bash
gcloud compute instance-groups managed set-auto-scaling MIN_SIZE MAX_SIZE \
  --group my-mig \
  --zone us-central1-a
```

#### Helm Values

```yaml
autoDiscovery:
  clusterName: my-cluster
cloudProvider: gce
```

### Azure (AKS)

#### Service Principal

```bash
az ad sp create-for-rbac --name cluster-autoscaler
```

#### Helm Values

```yaml
autoDiscovery:
  clusterName: my-cluster
cloudProvider: azure
azure:
  resourceGroup: my-resource-group
  subscriptionId: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  tenantId: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  clientId: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  clientSecret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## On-Premise Setup

### Requirements

- A cloud-like API for node management (e.g., vSphere, bare metal with API).
- Cluster Autoscaler supports "clusterapi" provider for custom infrastructure.

### Using Cluster API Provider

```yaml
# Install Cluster API
# https://cluster-api.sigs.k8s.io/user/quick-start.html

# Helm values for on-prem
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set cloudProvider=clusterapi \
  --set clusterapi.cloudConfigSecretName=cluster-autoscaler-cloud-config \
  --set clusterapi.cloudConfigSecretNamespace=kube-system
```

### Using Custom Scripts

For bare-metal environments, you can implement a custom autoscaler using the Cluster Autoscaler SDK:

```bash
# Example: using the autoscaler with a custom cloud provider
# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/builder
```

### On-Prem Considerations

- Scaling is slower (provisioning physical/virtual machines).
- Node pools must be pre-provisioned (e.g., vSphere templates).
- Consider using Kubelet's `--register-with-taints` for dedicated node pools.

---

## Troubleshooting

### Issue 1: Cluster Autoscaler Not Scaling Up

**Symptom**: Pods stuck in Pending, but no new nodes added.

**Cause**: Multiple possible causes:
- Tags/labels not set on node group.
- IAM permissions insufficient.
- `--skip-nodes-with-system-pods: true` and system pods occupying resources.

**Fix**:
```bash
kubectl logs -n kube-system -l app=cluster-autoscaler | grep -i "unable"
kubectl describe node <pending-node>
```

### Issue 2: Cluster Autoscaler Not Scaling Down

**Symptom**: Nodes underutilized but not removed.

**Cause**: Pods with `cluster-autoscaler.kubernetes.io/safe-to-evict: false` annotation, or PDBs preventing eviction.

**Fix**:
```bash
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.metadata.annotations["cluster-autoscaler.kubernetes.io/safe-to-evict"]=="false") | .metadata'
```

### Issue 3: Nodes Added but Pods Still Pending

**Symptom**: New nodes join cluster but pods remain Pending.

**Cause**: Pod scheduling constraints don't match new node labels/taints.

**Fix**:
```bash
kubectl describe pod <pending-pod>
kubectl get node --show-labels
```

### Issue 4: Cluster Autoscaler Crash Looping

**Symptom**: Cluster Autoscaler pod restarts repeatedly.

**Cause**: Invalid configuration, missing CRDs, or RBAC issues.

**Fix**:
```bash
kubectl logs -n kube-system -l app=cluster-autoscaler --previous
kubectl get clusterrole cluster-autoscaler -o yaml
```

### Issue 5: Too Many Nodes Provisioned

**Symptom**: Cluster grows beyond expected size.

**Cause**: `max-size` set too high, or scale-down delay too long.

**Fix**: Reduce `max-size` on node groups and ensure `scale-down-delay-after-add` is reasonable.

### Issue 6: Nodes Deleted Too Quickly

**Symptom**: Nodes removed while pods are still running.

**Cause**: Scale-down delay too short, or node utilization calculation incorrect.

**Fix**: Increase `scale-down-delay-after-add` and `scale-down-unneeded-time`.

### Issue 7: Conflicting with Karpenter

**Symptom**: Both autoscalers fighting over nodes.

**Cause**: Using both Cluster Autoscaler and Karpenter on same cluster.

**Fix**: Remove one. Do not use both on the same cluster.

### Issue 8: Spot Instance Interruptions

**Symptom**: Nodes disappear unexpectedly.

**Cause**: Cloud provider reclaimed spot instances.

**Fix**: Use multiple node groups with different instance types, set `max-node-provision-time` appropriately.

### Issue 9: Cluster Autoscaler Pod Not Found

**Symptom**: `kubectl get pods -n kube-system -l app=cluster-autoscaler` returns nothing.

**Cause**: Cluster Autoscaler not installed or different label.

**Fix**:
```bash
kubectl get pods -n kube-system | grep autoscal
kubectl get deployment -n kube-system | grep autoscal
```

### Issue 10: Slow Node Provisioning

**Symptom**: Pods pending for minutes before nodes appear.

**Cause**: Launch templates slow, AMI issues, or instance type limits.

**Fix**:
- Use pre-warmed AMIs.
- Increase `max-node-provision-time`.
- Check cloud provider API rate limits.

---

## Tips

### 1. Start with 2 Node Groups

Use one on-demand group for critical workloads and one spot/low-priority group for batch jobs.

### 2. Set Realistic Min/Max Sizes

Don't set `max-size` to 1000. Start conservatively and adjust based on actual usage.

### 3. Use PodDisruptionBudgets

Protect critical workloads from being evicted during scale-down.

### 4. Label Your Node Groups

Clear labels help Cluster Autoscaler make better decisions about which group to scale.

### 5. Monitor Cluster Utilization

Use `kubectl top nodes` and dashboards to understand node usage patterns.

### 6. Set Appropriate Delays

Too-short delays cause flapping. Too-long delays waste money. Start with defaults and tune.

### 7. Test with Real Workloads

Load test your autoscaling configuration before production. Use tools like `k6` or `hey`.

### 8. Combine with HPA

HPA manages pods; Cluster Autoscaler manages nodes. Use both for full autoscaling.

### 9. Use Priority Classes

Protect critical workloads from preemption during scaling events.

### 10. Monitor Cloud Costs

Track node group costs. Ensure autoscaling actually reduces costs.

### 11. Review Scale-Down Events

```bash
kubectl get events --field-selector reason=ScalingDown
```

### 12. Use Node Affinity for Workload Placement

Ensure critical pods land on appropriate node groups using node affinity and tolerations.

### 13. Set max-node-provision-time Appropriately

For slow-provisioning environments (bare metal), increase this value.

### 14. Document Your Node Groups

Maintain a clear mapping of node group purpose, instance types, and scaling policies.

### 15. Review IAM Permissions Regularly

Ensure Cluster Autoscaler has only the permissions it needs.

---

## Real-World Example: Contoso Pet Store

### Architecture

Contoso runs 3 node groups:

1. **on-demand-general**: General workloads (API, product, search).
2. **spot-batch**: Batch jobs (notifications, reports).
3. **on-demand-databases**: Databases (PostgreSQL, Redis).

### Configuration

```yaml
# Helm values.yaml for Contoso
autoDiscovery:
  clusterName: contoso-production
awsRegion: us-west-2

rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/cluster-autoscaler

extraArgs:
  balance-similar-node-groups: "true"
  skip-nodes-with-local-storage: "false"
  expander: least-waste
  scale-down-utilization-threshold: "0.5"
  scale-down-unneeded-time: "10m"
  scale-down-delay-after-add: "10m"
  max-node-provision-time: "15m"
  skip-nodes-with-system-pods: "true"
  balance-similar-node-groups: "true"

resources:
  requests:
    cpu: 100m
    memory: 300Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Node Group Configurations

```bash
# on-demand-general
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name contoso-general \
  --launch-template LaunchTemplateName=contoso-general \
  --min-size 3 \
  --max-size 20 \
  --vpc-zone-identifier subnet-xxx,subnet-yyy \
  --tag Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true \
  --tag Key=k8s.io/cluster-autoscaler/contoso-production,Value=owned,PropagateAtLaunch=true

# spot-batch
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name contoso-batch \
  --launch-template LaunchTemplateName=contoso-batch \
  --min-size 0 \
  --max-size 10 \
  --vpc-zone-identifier subnet-xxx,subnet-yyy \
  --tag Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true \
  --tag Key=k8s.io/cluster-autoscaler/contoso-production,Value=owned,PropagateAtLaunch=true

# on-demand-databases
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name contoso-databases \
  --launch-template LaunchTemplateName=contoso-databases \
  --min-size 3 \
  --max-size 5 \
  --vpc-zone-identifier subnet-xxx,subnet-yyy \
  --tag Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true \
  --tag Key=k8s.io/cluster-autoscaler/contoso-production,Value=owned,PropagateAtLaunch=true
```

---

## Commands Reference

```bash
# Check Cluster Autoscaler status
kubectl get pods -n kube-system -l app=cluster-autoscaler
kubectl logs -n kube-system -l app=cluster-autoscaler

# Check node groups
kubectl get nodes --show-labels
kubectl top nodes

# Check pending pods
kubectl get pods --field-selector status.phase=Pending

# Check scaling events
kubectl get events --field-selector reason=ScalingUp
kubectl get events --field-selector reason=ScalingDown

# Check Cluster Autoscaler config
kubectl get configmap cluster-autoscaler-config -n kube-system -o yaml

# Apply configuration
kubectl apply -f cluster-autoscaler.yaml

# Restart Cluster Autoscaler
kubectl rollout restart deployment cluster-autoscaler -n kube-system

# Check Cluster Autoscaler RBAC
kubectl get clusterrole cluster-autoscaler -o yaml
kubectl get clusterrolebinding cluster-autoscaler -o yaml
```

---

## Further Reading

- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [Cluster Autoscaler FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)
- [Karpenter](https://karpenter.sh/)
- [HPA + Cluster Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
