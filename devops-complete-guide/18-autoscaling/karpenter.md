# Karpenter — Complete Guide

## Table of Contents

1. [What Is Karpenter?](#1-what-is-karpenter)
2. [Why Use Karpenter?](#2-why-use-karpenter)
3. [Architecture](#3-architecture)
4. [Installation](#4-installation)
5. [Core Concepts](#5-core-concepts)
6. [Cloud Providers](#6-cloud-providers)
7. [NodePool Configuration](#7-nodepool-configuration)
8. [Disruption](#8-disruption)
9. [Node Class Reference](#9-node-class-reference)
10. [Karpenter + K3s](#10-karpenter--k3s)
11. [Karpenter Metrics](#11-karpenter-metrics)
12. [Karpenter + Helm](#12-karpenter--helm)
13. [Karpenter + KEDA](#13-karpenter--keda)
14. [Troubleshooting](#14-troubleshooting)
15. [Tips & Best Practices](#15-tips--best-practices)
16. [Real-World Example](#16-real-world-example-contoso-pet-store)
17. [Commands Reference](#17-commands-reference)
18. [Further Reading](#18-further-reading)

---

## 1. What Is Karpenter?

Karpenter is an open-source Kubernetes node autoscaler built by AWS and now a CNCF
sandbox project. It observes unschedulable pods and automatically launches just the
right compute resources to run them — in seconds, not minutes.

### Karpenter vs. Cluster Autoscaler

| Feature | Cluster Autoscaler | Karpenter |
|---|---|---|
| Scope | Node group level | Individual pod requirements |
| Speed | 5–10 min (ASG/Launch Template) | 30–90 sec (direct EC2 API) |
| Bin-packing | Static node groups | Dynamic, right-sized instances |
| Consolidation | Scale down underused groups | Drift + consolidate nodes in place |
| Provisioner | Node group configuration | NodePool declarative spec |
| Cloud support | Multi-cloud (via cloud provider) | AWS, Azure, GCP (on-prem experimental) |
| Pod awareness | Indirect (waits for unschedulable) | Direct (watches pods, nodes, probe lifecycles) |
| Price optimization | None built-in | Spot/On-Demand selection, price-aware scheduling |
| Disruption budgets | Not natively supported | PodDisruptionBudget-aware node consolidation |

**Key difference:** Cluster Autoscaler works at the **node group** layer — it scales
entire ASGs up or down. Karpenter works at the **individual node** layer — it picks
the exact instance type, AZ, and capacity type that best fits unschedulable pods.

### How It Works (Simplified)

```
Unschedulable Pod
       │
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Karpenter   │────▶│  Cloud API   │────▶│  New Node Ready   │
│  Controller  │     │  (EC2/AKS)   │     │  Pod Scheduled    │
└──────────────┘     └──────────────┘     └──────────────────┘
       │
       ▼
  NodePool constraints
  (instance types, AZs,
   capacity, labels, taints)
```

1. A pod becomes unschedulable (no node matches its resource requests or constraints).
2. Karpenter's controller detects the unschedulable pod.
3. The controller consults the matching NodePool to determine valid instance types,
   subnets, security groups, and other constraints.
4. Karpenter calls the cloud API directly to launch the best-fit instance.
5. The new node registers with the cluster and the pod is scheduled.

---

## 2. Why Use Karpenter?

### Fast Provisioning

Traditional autoscalers rely on **managed node groups** (ASG + Launch Template on
AWS). Launching an EC2 instance through an ASG involves:

1. ASG decides to scale.
2. Launch Template is evaluated.
3. AMI is resolved.
4. Instance is requested from EC2 fleet.
5. Instance boots, runs cloud-init, joins the cluster.

This typically takes **5–10 minutes** end-to-end.

Karpenter bypasses the ASG layer entirely. It calls `RunInstances` or
`CreateFleet` directly with fully resolved parameters, skipping steps 1–2. The
bottleneck becomes EC2 cold-start time (~30–60 sec for most AMIs) plus node
bootstrap (~10–20 sec). **Total: 40–90 seconds.**

### Right-Sizing

Karpenter evaluates the **actual resource requests** of unschedulable pods and
selects the **smallest instance type** that fits. If pods request 2 vCPU and 4Gi
RAM, Karpenter might launch a `c6i.large` (2 vCPU, 4Gi) instead of a `m5.xlarge`
(4 vCPU, 16Gi) that a static node group might prefer for uniformity.

### Consolidation

When nodes become underutilized (after pod deletion, scale-down, or scheduling
changes), Karpenter can:

- **Delete** empty or underutilized nodes.
- **Replace** a large node with smaller ones.
- **Consolidate** workloads onto fewer nodes.

This happens automatically, continuously, and with PDB-aware disruption budgets.

### Cost Savings

Real-world results from AWS case studies:

| Metric | Cluster Autoscaler | Karpenter |
|---|---|---|
| Node provisioning time | 5–10 min | 30–90 sec |
| Instance type flexibility | Fixed per node group | Any type in pool |
| Spot utilization | Manual configuration | Automatic, price-aware |
| Cluster utilization | ~40–50% | ~70–85% |
| Monthly cost (typical) | Baseline | 30–50% reduction |

### Simplified Operations

- No ASGs to manage, no Launch Templates to update.
- One NodePool can replace 5–10 node groups.
- Automatic drift detection (AMI, subnets, security groups).
- Built-in consolidation without external tooling.

---

## 3. Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes API                         │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  NodePool    │  │ EC2NodeClass │  │  NodeClaim        │  │
│  │  (CRD)      │  │ (CRD)        │  │  (CRD)            │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬──────────┘  │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Karpenter Controller                  │   │
│  │  ┌────────────┐ ┌────────────┐ ┌──────────────────┐  │   │
│  │  │ Provisioner│ │ Disruptor  │ │  Terminator      │  │   │
│  │  │            │ │            │ │  (drift, expiry)  │  │   │
│  │  └────────────┘ └────────────┘ └──────────────────┘  │   │
│  └───────────────────────┬──────────────────────────────┘   │
│                          │                                  │
│  ┌───────────────────────▼──────────────────────────────┐   │
│  │              Cloud Provider Interface                  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐  │   │
│  │  │   AWS    │ │  Azure   │ │   GCP    │ │ On-Prem │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └─────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### CRDs (Custom Resource Definitions)

| CRD | Purpose | Scope |
|---|---|---|
| **NodePool** | Defines constraints for node provisioning (instance types, labels, taints, disruption) | Namespaced |
| **NodeClaim** | Represents a single node that Karpenter provisions or manages | Namespaced |
| **EC2NodeClass** (AWS) | Defines cloud-specific configuration (AMI, subnets, security groups, IAM) | Namespaced |
| **NodeClass** (GCP/Azure) | Equivalent cloud-specific config for other providers | Namespaced |

### Control Flow

```
Pod pending ──▶ SchedulingQueue ──▶ Karpenter watches
                                        │
                               ┌─────────▼──────────┐
                               │  Filter NodePools   │
                               │  (requirements,     │
                               │   labels, taints)   │
                               └─────────┬──────────┘
                                        │
                               ┌─────────▼──────────┐
                               │  Compute best-fit   │
                               │  instance type      │
                               │  (bin-packing +     │
                               │   price optimization)│
                               └─────────┬──────────┘
                                        │
                               ┌─────────▼──────────┐
                               │  Launch NodeClaim   │
                               │  (via cloud API)    │
                               └─────────┬──────────┘
                                        │
                               ┌─────────▼──────────┐
                               │  Node registers     │
                               │  Pod scheduled      │
                               └────────────────────┘
```

### NodeClaim Lifecycle

1. **Pending** — Karpenter creates a NodeClaim, instance is launching.
2. **Launched** — Instance is running but not yet joined to cluster.
3. **Registered** — Node joined cluster, kubelet registered.
4. **Initialized** — Node is Ready and available for scheduling.
5. **Drifting** — Karpenter detected drift (AMI, config) and is replacing.
6. **Empty** — No pods on node, candidate for consolidation.
7. **Terminating** — Node is being drained and terminated.

---

## 4. Installation

### Prerequisites

- Kubernetes 1.24+ (tested with 1.27–1.30)
- Helm 3.x
- Cloud provider credentials (AWS: IRSA/Instance Profile, Azure: Workload Identity)
- Cert-manager (required by Karpenter webhook)

### 4.1 AWS Installation

#### Step 1: Install cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --version v1.14.4
```

#### Step 2: Install Karpenter

```bash
helm repo add karpenter https://charts.karpenter.sh
helm repo update

helm install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$KARPENTER_IAM_ROLE_ARN \
  --set settings.aws.clusterName=$CLUSTER_NAME \
  --set settings.aws.clusterEndpoint=$CLUSTER_ENDPOINT \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-$CLUSTER_NAME \
  --set settings.aws.interruptionQueueName=karpenter-$CLUSTER_NAME \
  --version 0.35.0 \
  --wait
```

#### Step 3: Create NodePool + EC2NodeClass

```yaml
# ec2nodeclass.yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: KarpenterNodeRole-$CLUSTER_NAME
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: $CLUSTER_NAME
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: $CLUSTER_NAME
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 3000
        throughput: 125
        encrypted: true
        kmsKeyId: alias/$CLUSTER_NAME
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 1
    httpTokens: required
---
# nodepool.yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.instance-generation
          operator: Gt
          values: ["2"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ["medium", "large", "xlarge", "2xlarge"]
      nodeClassRef:
        name: default
  limits:
    cpu: "100"
    memory: 400Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
  weight: 10
```

#### Step 4: Apply and Verify

```bash
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f nodepool.yaml

kubectl get nodepools
kubectl get ec2nodeclasses
kubectl get nodeclaims
```

### 4.2 Azure Installation

```bash
helm install karpenter oci://ghcr.io/karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --version 0.35.0 \
  --set settings.azure.clusterName=$CLUSTER_NAME \
  --set settings.azure.clusterEndpoint=$CLUSTER_ENDPOINT \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=$KARPENTER_CLIENT_ID \
  --wait
```

### 4.3 GCP Installation

```bash
helm install karpenter oci://ghcr.io/karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --version 0.35.0 \
  --set settings.gcp.projectID=$PROJECT_ID \
  --set settings.gcp.clusterName=$CLUSTER_NAME \
  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"=$KARPENTER_SA_EMAIL \
  --wait
```

### 4.4 Kustomize Installation (Alternative)

```bash
kubectl apply -f https://raw.githubusercontent.com/karpenter-provider/aws/main/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/karpenter-project/karpenter/main/pkg/apis/crds/karpenter.sh_nodepools.yaml
kubectl apply -f https://raw.githubusercontent.com/karpenter-project/karpenter/main/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
```

### 4.5 Verify Installation

```bash
# Check controller pods
kubectl get pods -n karpenter -l app.kubernetes.io/name=karpenter

# Check CRDs
kubectl get crd | grep karpenter

# Check NodePool status
kubectl describe nodepool default

# Check controller logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=50
```

---

## 5. Core Concepts

### NodePool

A NodePool defines **what kinds of nodes** Karpenter can create. It specifies:

- **Requirements** — instance types, architectures, capacity types, zones
- **Labels** — key-value pairs added to provisioned nodes
- **Taints** — taints added to provisioned nodes (with effect NoSchedule, PreferNoSchedule, NoExecute)
- **Limits** — maximum resource consumption (CPU, memory)
- **Disruption** — how nodes can be consolidated or expired
- **Weight** — priority when multiple NodePools match a pod

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: production
spec:
  template:
    metadata:
      labels:
        env: production
        team: platform
    spec:
      taints:
        - key: dedicated
          value: production
          effect: NoSchedule
      requirements:
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m", "r"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: topology.kubernetes.io/zone
          operator: In
          values: ["us-west-2a", "us-west-2b", "us-west-2c"]
      nodeClassRef:
        name: production
  limits:
    cpu: "200"
    memory: 800Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    budgets:
      - nodes: "10%"
  weight: 50
```

### Requirements

Requirements are the core filtering mechanism. Karpenter uses them to determine
which instance types are valid for a NodePool.

#### Operator Types

| Operator | Description | Example |
|---|---|---|
| `In` | Value must be in the list | `values: ["c", "m", "r"]` |
| `NotIn` | Value must not be in the list | `values: ["t2", "t3"]` |
| `Exists` | Key must exist | No values needed |
| `DoesNotExist` | Key must not exist | No values needed |
| `Gt` | Value must be greater than | `values: ["2"]` |
| `Lt` | Value must be less than | `values: ["5"]` |

#### Key Well-Known Labels

```yaml
requirements:
  # Instance category (AWS-specific)
  - key: karpenter.k8s.aws/instance-category
    operator: In
    values: ["c", "m", "r", "t"]

  # Instance generation (AWS)
  - key: karpenter.k8s.aws/instance-generation
    operator: Gt
    values: ["2"]

  # Capacity type
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot", "on-demand", "reserved"]

  # Architecture
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64", "arm64"]

  # OS
  - key: kubernetes.io/os
    operator: In
    values: ["linux"]

  # Zone (topology)
  - key: topology.kubernetes.io/zone
    operator: In
    values: ["us-west-2a", "us-west-2b"]

  # Region (topology)
  - key: topology.kubernetes.io/region
    operator: In
    values: ["us-west-2"]

  # Instance size (AWS)
  - key: karpenter.k8s.aws/instance-size
    operator: In
    values: ["large", "xlarge", "2xlarge"]

  # Custom labels
  - key: team
    operator: In
    values: ["backend", "ml"]
```

### Limits

Limits prevent Karpenter from creating unbounded resources:

```yaml
limits:
  cpu: "100"           # Max 100 vCPUs across all nodes in this pool
  memory: 400Gi         # Max 400Gi RAM
  # resources that can be extended:
  # nvidia.com/gpu: "8"
  # aws.amazon.com/efa: "4"
```

When a limit is reached, Karpenter stops provisioning from that NodePool. Pods
that can't be placed will remain pending until resources are freed (by disruption,
expiration, or manual scaling).

### NodeClaim

NodeClaim is the internal representation of a single node Karpenter manages.
You typically don't create NodeClaims directly — Karpenter creates them
automatically when it provisions a node.

```bash
# View NodeClaims
kubectl get nodeclaims -o wide

# Describe a NodeClaim
kubectl describe nodeclaim <name>

# Delete a specific NodeClaim (triggers drain + termination)
kubectl delete nodeclaim <name>
```

---

## 6. Cloud Providers

### 6.1 AWS (EC2NodeClass)

The most mature provider. Uses EC2 directly.

```yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  # IAM role for nodes
  role: KarpenterNodeRole-cluster-name

  # AMI selection
  amiSelectorTerms:
    - alias: al2023@latest
    # Or by ID:
    # - id: ami-0abcdef1234567890
    # Or by tags:
    # - tags:
    #     Environment: production

  # Subnet selection
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: cluster-name
    # Or by ID:
    # - id: subnet-0abc123

  # Security group selection
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: cluster-name

  # Block device configuration
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 3000
        throughput: 125
        encrypted: true

  # Instance metadata
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 1
    httpTokens: required   # IMDSv2 enforced

  # User data (optional)
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh cluster-name

  # Instance profile (alternative to role)
  instanceProfile: MyInstanceProfile

  # Tags applied to EC2 instances
  tags:
    Environment: production
    Team: platform
```

#### AWS IAM Permissions

The Karpenter controller needs these IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:CreateFleet",
        "ec2:CreateLaunchTemplate",
        "ec2:DeleteLaunchTemplate",
        "ec2:RequestSpotFleet",
        "ec2:CancelSpotFleetRequests",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstances",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeImages",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeVpcs",
        "ec2:TerminateInstances",
        "ec2:DeleteTags",
        "ec2:CreateTags",
        "ec2:DescribeAvailabilityZones",
        "iam:PassRole",
        "ssm:GetParameter",
        "pricing:GetProducts"
      ],
      "Resource": "*"
    }
  ]
}
```

### 6.2 Azure (AKSNodePool)

Uses Azure VM Scale Sets (VMSS).

```yaml
apiVersion: karpenter.azure.com/v1alpha2
kind: AKSNodeClass
metadata:
  name: default
spec:
  # Image reference
  imageReference:
    publisher: azurelinux
    offer: azure-linux
    sku: azure-linux-3
    version: latest

  # OS disk
  osDiskSizeGB: 100
  osDiskType: Ephemeral
  osDiskEncryptionSetID: /subscriptions/.../diskEncryptionSets/...

  # Network
  vnetSubnetID: /subscriptions/.../subnets/karpenter

  # Identity
  identityID: /subscriptions/.../userAssignedIdentities/karpenter

  # Security group
  nsg: /subscriptions/.../networkSecurityGroups/karpenter

  # Tags
  tags:
    environment: production
```

### 6.3 GCP (NodePool)

Uses GCE instance groups.

```yaml
apiVersion: karpenter.gcp.kubernetes.io/v1alpha1
kind: GCPNodeClass
metadata:
  name: default
spec:
  # Project
  projectID: my-gcp-project

  # Image
  imageFamily: ubuntu-2204-lts
  imageProject: ubuntu-os-cloud

  # Machine types (via requirements)
  # Network
  networkTags:
    - karpenter
  subnetworks:
    - karpenter-subnet

  # Service account
  serviceAccount: karpenter@my-project.iam.gserviceaccount.com
```

### 6.4 On-Premises / Custom

Karpenter's architecture is extensible. For on-prem environments, you can implement
a custom cloud provider or use the **Karpenter Provider Interface**.

For Kubernetes on bare metal with technologies like Incus/LXC:

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: bare-metal
spec:
  template:
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["bare-metal-large", "bare-metal-xlarge"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      nodeClassRef:
        name: bare-metal
  disruption:
    consolidationPolicy: WhenEmpty
---
apiVersion: karpenter.sh/v1beta1
kind: NodeClass
metadata:
  name: bare-metal
spec:
  # Custom provider handles node lifecycle
  # via external controller watching NodeClass
```

---

## 7. NodePool Configuration

### Instance Type Selection

```yaml
# Prefer specific families
requirements:
  - key: karpenter.k8s.aws/instance-category
    operator: In
    values: ["c", "m", "r"]

# Exclude cheap/weak types
  - key: karpenter.k8s.aws/instance-category
    operator: NotIn
    values: ["t", "nano", "micro"]

# Only latest generation
  - key: karpenter.k8s.aws/instance-generation
    operator: Gt
    values: ["2"]

# Specific sizes
  - key: karpenter.k8s.aws/instance-size
    operator: In
    values: ["large", "xlarge", "2xlarge", "4xlarge"]
```

### Capacity Type

```yaml
# Prefer spot, fall back to on-demand
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot", "on-demand"]

# On-demand only (for critical workloads)
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["on-demand"]

# Spot only (for batch/ML)
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot"]
```

### Availability Zones

```yaml
# Spread across all AZs
requirements:
  - key: topology.kubernetes.io/zone
    operator: In
    values: ["us-east-1a", "us-east-1b", "us-east-1c"]

# Restrict to specific AZs
requirements:
  - key: topology.kubernetes.io/zone
    operator: In
    values: ["us-east-1a"]

# Exclude specific AZs
requirements:
  - key: topology.kubernetes.io/zone
    operator: NotIn
    values: ["us-east-1c"]
```

### Architecture

```yaml
# AMD64 only
requirements:
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64"]

# ARM64 only (Graviton/ Ampere)
requirements:
  - key: kubernetes.io/arch
    operator: In
    values: ["arm64"]

# Both architectures
requirements:
  - key: kubernetes.io/arch
    operator: In
    values: ["amd64", "arm64"]
```

### Labels

Labels added to provisioned nodes:

```yaml
template:
  metadata:
    labels:
      # Custom labels
      env: production
      team: platform
      cost-center: engineering
      # Karpenter-specific labels (auto-applied)
      # karpenter.sh/provisioner-name: <pool-name>
      # karpenter.sh/capacity-type: spot|on-demand
      # karpenter.k8s.aws/instance-type: m5.large
```

### Taints

Taints added to provisioned nodes:

```yaml
template:
  spec:
    taints:
      # No pods without matching tolerations
      - key: dedicated
        value: production
        effect: NoSchedule

      # Prefer not to schedule
      - key: experimental
        value: "true"
        effect: PreferNoSchedule

      # Evict pods without matching tolerations
      - key: spot
        value: "true"
        effect: NoExecute
```

### Multi-NodePool Strategy

```yaml
# NodePool for production workloads
---
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: production
spec:
  template:
    metadata:
      labels:
        tier: production
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m", "r"]
      nodeClassRef:
        name: production
  disruption:
    consolidationPolicy: WhenUnderutilized
    budgets:
      - nodes: "0"
  weight: 100

# NodePool for batch/ML workloads (spot)
---
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: batch
spec:
  template:
    metadata:
      labels:
        tier: batch
    spec:
      taints:
        - key: workload
          value: batch
          effect: NoSchedule
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "p"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      nodeClassRef:
        name: batch
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 24h
  weight: 50

# NodePool for development/staging
---
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: development
spec:
  template:
    metadata:
      labels:
        tier: development
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["t", "m"]
      nodeClassRef:
        name: development
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 168h  # 7 days
  weight: 10
```

---

## 8. Disruption

### Consolidation Policies

#### WhenUnderutilized

Karpenter continuously monitors node utilization. When a node becomes
underutilized (not enough pods to justify the instance), Karpenter:

1. Identifies which pods can be moved to other nodes.
2. Drains the underutilized node.
3. Terminates the EC2 instance.

```yaml
disruption:
  consolidationPolicy: WhenUnderutilized
```

#### WhenEmpty

Only consolidates nodes that have **zero pods** (all pods were evicted or moved).

```yaml
disruption:
  consolidationPolicy: WhenEmpty
```

### Disruption Budgets

Disruption budgets control **how many nodes** Karpenter can disrupt simultaneously.

```yaml
disruption:
  budgets:
    # Absolute number
    - nodes: 2

    # Percentage
    - nodes: "10%"

    # Schedule-specific budgets
    - nodes: "15%"
      schedule: "0 22 * * 1-5"  # Weekdays 10pm-6am: stricter
    - nodes: "30%"
      schedule: "0 6 * * 1-5"   # Weekdays 6am-10pm: more aggressive

    # Disable disruption entirely
    - nodes: "0"
```

#### Budget Evaluation

When multiple budgets are defined, Karpenter evaluates:

1. **Schedule check** — Which budgets match the current time?
2. **Budget selection** — Pick the most restrictive matching budget.
3. **Node count** — Compute maximum nodes that can be disrupted.
4. **PDB compliance** — Additionally respect PodDisruptionBudgets.

### Expiration

Nodes can be automatically terminated after a time period:

```yaml
disruption:
  expireAfter: 720h  # 30 days
```

Expiration is useful for:
- **Spot instances** — Prevent long-running spot interruptions.
- **AMI updates** — Force node rotation after AMI changes.
- **Security compliance** — Regular node replacement.
- **Cost optimization** — Periodic right-sizing.

### Drift Detection

Karpenter detects when nodes drift from their expected configuration:

- **AMI drift** — A new AMI is available matching the selector terms.
- **Subnet drift** — Subnets are changed or new subnets become available.
- **Security group drift** — Security groups are modified.

```yaml
# Drift is automatic. To check:
kubectl get nodeclaims -o jsonpath='{.items[*].status.conditions}' | jq .

# Force drift detection:
kubectl annotate nodeclaim <name> karpenter.sh/initialized-
```

---

## 9. Node Class Reference

### EC2NodeClass (AWS) Full Reference

```yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: full-reference
spec:
  # ──── IAM ────
  role: KarpenterNodeRole-cluster-name
  # OR
  instanceProfile: MyInstanceProfile

  # ──── AMI Selection ────
  amiSelectorTerms:
    # By alias (recommended)
    - alias: al2023@latest
    # By specific ID
    - id: ami-0abcdef1234567890
    # By tags
    - tags:
        Environment: production
        AMIType: gpu
    # Multiple terms (OR logic)
    - alias: al2023@latest
    - id: ami-0custom123

  # ──── Subnet Selection ────
  subnetSelectorTerms:
    # By tags
    - tags:
        karpenter.sh/discovery: cluster-name
        Environment: production
    # By ID
    - id: subnet-0abc123
    - id: subnet-0def456

  # ──── Security Group Selection ────
  securityGroupSelectorTerms:
    # By tags
    - tags:
        karpenter.sh/discovery: cluster-name
    # By ID
    - id: sg-0abc123

  # ──── Block Devices ────
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        iops: 3000
        throughput: 125
        encrypted: true
        kmsKeyId: alias/my-key
        snapshotId: snap-0abc123
    # Additional data volume
    - deviceName: /dev/sdf
      ebs:
        volumeSize: 500Gi
        volumeType: gp3
        encrypted: true

  # ──── Metadata Options ────
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 2  # For containers needing IMDS
    httpTokens: required        # IMDSv2

  # ──── User Data ────
  userData: |
    #!/bin/bash
    set -euo pipefail
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} \
      --kubelet-extra-args '--node-labels=env=production'

  # ──── Tags ────
  tags:
    Environment: production
    Team: platform
    ManagedBy: karpenter

  # ──── AMI Family (deprecated, use alias) ────
  # amiFamily: AL2  # Use alias instead

  # ──── Context ────
  context: "arn:aws:eks:us-west-2:123456789012:cluster/..."
```

### NodeClassSelector in NodePool

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: with-nodeclass
spec:
  template:
    spec:
      nodeClassRef:
        name: my-ec2nodeclass
      # OR cross-namespace (v1.1+)
      # nodeClassRef:
      #   name: my-nodeclass
      #   namespace: karpenter-system
```

---

## 10. Karpenter + K3s

Karpenter can work with K3s (lightweight Kubernetes) for on-premises or edge
deployments. This requires a custom approach since K3s doesn't use the standard
cloud provider interfaces.

### Architecture

```
┌──────────────────────────────────────────────┐
│               K3s Cluster                     │
│                                               │
│  ┌─────────────┐  ┌──────────────────────┐   │
│  │  Karpenter   │  │  Custom Controller   │   │
│  │  (standard)  │  │  (Incus provider)    │   │
│  └──────┬──────┘  └──────────┬───────────┘   │
│         │                    │                │
│         ▼                    ▼                │
│  ┌──────────────────────────────────────────┐ │
│  │           Incus / LXC                     │ │
│  │  Create containers as K3s nodes          │ │
│  └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### Custom Provisioner for Incus

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: incus-nodes
spec:
  template:
    metadata:
      labels:
        provisioner: incus
        env: on-prem
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["incus-medium", "incus-large"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      nodeClassRef:
        name: incus
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 720h
  limits:
    cpu: "50"
    memory: 200Gi
---
apiVersion: karpenter.sh/v1beta1
kind: NodeClass
metadata:
  name: incus
spec:
  # Custom provider implementation needed
  # Controller watches NodeClass and:
  # 1. Creates Incus container
  # 2. Installs K3s agent
  # 3. Registers with K3s server
  # 4. Reports Ready
```

### Manual K3s Integration

For environments where a custom provider isn't available, you can use Karpenter's
NodePool with a **mutation webhook** or **external controller** that watches
NodeClaims and provisions Incus containers.

```bash
# Example: external controller watches NodeClaims
kubectl get nodeclaims -o jsonpath='{range .items[?(@.status.phase=="Pending")]}{.metadata.name}{"\t"}{.spec.requirements}{"\n"}{end}'
```

---

## 11. Karpenter Metrics

### Prometheus Metrics

Karpenter exposes metrics on port 8080 at `/metrics`.

#### Key Metrics

```
# Provisioning
karpenter_provisioner_scheduling_duration_seconds
karpenter_provisioner_scheduling_queue_depth
karpenter_provisioner_node_fulfillment
karpenter_provisioner_node_creation_seconds

# Disruption
karpenter_disruption_replacement_nodeclaim_fallback_seconds
karpenter_disruption_consolidation_duration_seconds
karpenter_disruption_budgets_active

# Node Claims
karpenter_nodeclaims_terminated
karpenter_nodeclaims_created
karpenter_nodeclaims_drifted

# Node Usage
karpenter_node_usage
karpenter_node_utilization

# Cloud Provider
karpenter_cloudprovider_duration_seconds
karpenter_cloudprovider_error_count

# Interruption
karpenter_interruption_actions_taken
```

#### Prometheus Scrape Config

```yaml
# prometheus-additional-scrape-config
- job_name: karpenter
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - karpenter
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
      regex: karpenter
      action: keep
    - source_labels: [__meta_kubernetes_pod_container_port_number]
      regex: "8080"
      action: keep
```

#### ServiceMonitor (if using Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: karpenter
  namespace: karpenter
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: karpenter
  endpoints:
    - port: http-metrics
      interval: 30s
      path: /metrics
```

### Grafana Dashboards

#### Dashboard 1: Karpenter Overview

```json
{
  "panels": [
    {
      "title": "Node Claims",
      "type": "stat",
      "targets": [
        {
          "expr": "count(karpenter_nodeclaims_created)",
          "legendFormat": "Total NodeClaims"
        }
      ]
    },
    {
      "title": "Provisioning Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(karpenter_provisioner_node_creation_seconds_count[5m])",
          "legendFormat": "Nodes/sec"
        }
      ]
    },
    {
      "title": "Disruption Events",
      "type": "graph",
      "targets": [
        {
          "expr": "increase(karpenter_disruption_replacement_nodeclaim_fallback_seconds_count[1h])",
          "legendFormat": "Replacements/hour"
        }
      ]
    },
    {
      "title": "Node Utilization",
      "type": "graph",
      "targets": [
        {
          "expr": "avg(karpenter_node_utilization) by (node)",
          "legendFormat": "{{node}}"
        }
      ]
    }
  ]
}
```

#### Dashboard 2: Cost Optimization

```json
{
  "panels": [
    {
      "title": "Spot vs On-Demand",
      "type": "piechart",
      "targets": [
        {
          "expr": "count by (capacity_type) (karpenter_nodeclaims_created)",
          "legendFormat": "{{capacity_type}}"
        }
      ]
    },
    {
      "title": "Instance Types",
      "type": "barchart",
      "targets": [
        {
          "expr": "count by (instance_type) (karpenter_nodeclaims_created)",
          "legendFormat": "{{instance_type}}"
        }
      ]
    },
    {
      "title": "Consolidation Savings",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(karpenter_disruption_nodes_deleted) * 0.15",
          "legendFormat": "Est. hourly savings ($)"
        }
      ]
    }
  ]
}
```

---

## 12. Karpenter + Helm

### Helm Chart for NodePool Deployment

```yaml
# Chart.yaml
apiVersion: v2
name: karpenter-nodepools
description: Helm chart for deploying Karpenter NodePools
version: 0.1.0
dependencies:
  - name: karpenter
    version: 0.35.0
    repository: https://charts.karpenter.sh
    condition: karpenter.enabled
```

### values.yaml

```yaml
# Global settings
clusterName: my-cluster
awsRegion: us-west-2

# NodePool definitions
nodepools:
  - name: production
    weight: 100
    labels:
      tier: production
    taints: []
    requirements:
      - key: karpenter.k8s.aws/instance-category
        operator: In
        values: ["m", "r"]
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
    limits:
      cpu: "200"
      memory: 800Gi
    disruption:
      consolidationPolicy: WhenUnderutilized
      budgets:
        - nodes: "10%"
    ec2nodeclass:
      name: production
      role: KarpenterNodeRole-${clusterName}
      amiSelectorTerms:
        - alias: al2023@latest
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${clusterName}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${clusterName}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 100Gi
            volumeType: gp3
            encrypted: true

  - name: batch
    weight: 50
    labels:
      tier: batch
    taints:
      - key: workload
        value: batch
        effect: NoSchedule
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot"]
      - key: karpenter.k8s.aws/instance-category
        operator: In
        values: ["c", "p"]
    limits:
      cpu: "100"
      memory: 400Gi
    disruption:
      consolidationPolicy: WhenEmpty
      expireAfter: 24h
    ec2nodeclass:
      name: batch
      role: KarpenterNodeRole-${clusterName}
      amiSelectorTerms:
        - alias: al2023@latest
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${clusterName}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${clusterName}
```

### templates/nodepool.yaml

```yaml
{{- range .Values.nodepools }}
---
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: {{ .name }}
  labels:
    {{- toYaml .labels | nindent 4 }}
spec:
  weight: {{ .weight | default 50 }}
  template:
    metadata:
      labels:
        {{- toYaml .labels | nindent 8 }}
    spec:
      {{- if .taints }}
      taints:
        {{- toYaml .taints | nindent 8 }}
      {{- end }}
      requirements:
        {{- toYaml .requirements | nindent 8 }}
      nodeClassRef:
        name: {{ .ec2nodeclass.name }}
  limits:
    {{- toYaml .limits | nindent 4 }}
  disruption:
    {{- toYaml .disruption | nindent 4 }}
{{- end }}
```

### templates/ec2nodeclass.yaml

```yaml
{{- range .Values.nodepools }}
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: {{ .ec2nodeclass.name }}
spec:
  role: {{ .ec2nodeclass.role | replace "${clusterName}" $.Values.clusterName }}
  amiSelectorTerms:
    {{- toYaml .ec2nodeclass.amiSelectorTerms | nindent 4 }}
  subnetSelectorTerms:
    {{- toYaml .ec2nodeclass.subnetSelectorTerms | nindent 4 }}
  securityGroupSelectorTerms:
    {{- toYaml .ec2nodeclass.securityGroupSelectorTerms | nindent 4 }}
  blockDeviceMappings:
    {{- toYaml .ec2nodeclass.blockDeviceMappings | nindent 4 }}
{{- end }}
```

### Install

```bash
helm install karpenter-pools ./charts/karpenter-nodepools \
  --set clusterName=my-cluster \
  --set awsRegion=us-west-2 \
  --namespace karpenter
```

---

## 13. Karpenter + KEDA

Karpenter and KEDA operate at **different levels** and complement each other perfectly:

```
┌──────────────────────────────────────────────────────┐
│                   Application Layer                   │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │  KEDA (Pod-Level Autoscaling)                   │ │
│  │  - Scales HPA replicas based on metrics         │ │
│  │  - CPU, Memory, Prometheus, Kafka, SQS, etc.    │ │
│  │  - Operates within existing node capacity       │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Karpenter (Node-Level Autoscaling)             │ │
│  │  - Adds nodes when pods are unschedulable       │ │
│  │  - Removes underutilized nodes                  │ │
│  │  - Right-sizes instance types                   │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Flow

1. KEDA detects metric spike → scales HPA → creates new pods.
2. If existing nodes can't fit the new pods → pods become Pending.
3. Karpenter detects Pending pods → launches new node.
4. Pods are scheduled on new node.
5. Metric drops → KEDA scales down HPA → pods are removed.
6. Karpenter detects underutilized node → consolidates.

### KEDA ScaledObject Example

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-scaler
  namespace: production
spec:
  scaleTargetRef:
    name: api-deployment
  minReplicaCount: 2
  maxReplicaCount: 50
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        metricName: http_requests_total
        threshold: "100"
        query: |
          sum(rate(http_requests_total{service="api"}[1m]))
    - type: cpu
      metadata:
        type: Utilization
        value: "70"
    - type: memory
      metadata:
        type: Utilization
        value: "80"
```

### NodePool with KEDA in Mind

```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: keda-workloads
spec:
  template:
    metadata:
      labels:
        autoscaler: keda
    spec:
      requirements:
        # KEDA workloads can use spot (they're stateless)
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        # Fast-boot instances for quick scale-up
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
      nodeClassRef:
        name: default
  limits:
    cpu: "200"
    memory: 800Gi
  disruption:
    # Aggressive consolidation for KEDA (pods scale down fast)
    consolidationPolicy: WhenUnderutilized
    budgets:
      - nodes: "20%"
```

### Advanced: KEDA + Karpenter + Scheduled Scaling

```yaml
# KEDA with scheduled scaling for predictable traffic
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-scaler
spec:
  scaleTargetRef:
    name: api-deployment
  minReplicaCount: 2
  maxReplicaCount: 100
  pollingInterval: 15
  cooldownPeriod: 60
  advanced:
    # Restore to min after cooldown
    restoreToOriginalReplicaCount: false
    # Horizontal pod autoscaler behavior
    horizontalPodAutoscalerConfig:
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 30
          policies:
            - type: Percent
              value: 100
              periodSeconds: 60
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
  triggers:
    - type: cron
      metadata:
        timezone: America/New_York
        start: 0 8 * * 1-5    # Weekdays 8am
        end: 0 20 * * 1-5     # Weekdays 8pm
        desiredReplicas: "20"
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        metricName: http_requests_per_second
        threshold: "50"
        query: |
          sum(rate(http_requests_total{service="api"}[2m]))
```

---

## 14. Troubleshooting

### Issue 1: Pods stuck in Pending

```bash
# Check why pods aren't scheduling
kubectl describe pod <pod-name> | grep -A 5 Events

# Check NodePool limits
kubectl describe nodepool <pool-name> | grep -A 3 Limits

# Check NodeClaims
kubectl get nodeclaims

# Check controller logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=100
```

**Common causes:**
- NodePool limits reached (CPU/memory exhausted)
- No matching NodePool (requirements don't match pod's resource requests)
- Cloud API errors (quotas, permissions, invalid parameters)

### Issue 2: Nodes not launching

```bash
# Check controller events
kubectl get events -n karpenter --field-selector reason=ProvisioningFailed

# Check cloud provider errors
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep -i error

# Verify IAM permissions (AWS)
aws sts get-caller-identity
aws iam simulate-principal-policy \
  --policy-source-arn $KARPENTER_ROLE_ARN \
  --action-names ec2:RunInstances

# Check EC2 quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region us-west-2
```

### Issue 3: Disruption not happening

```bash
# Check disruption budgets
kubectl describe nodepool <pool-name> | grep -A 10 Disruption

# Check PDBs
kubectl get pdb -A

# Check if consolidation is disabled
kubectl get nodepool <pool-name> -o yaml | grep consolidation

# Force a consolidation check
kubectl delete nodeclaim <name>
```

### Issue 4: Wrong instance types being selected

```bash
# Check what instance types are available
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep "instance type"

# Verify requirements
kubectl get nodepool <pool-name> -o yaml | grep -A 30 requirements

# Check if price filtering is working
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep -i price
```

### Issue 5: Spot interruptions

```bash
# Check interruption queue (SQS)
aws sqs get-queue-attributes \
  --queue-url $INTERRUPTION_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages

# Check for interruption events
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep -i interruption

# Verify instance is spot
kubectl get node <node-name> -o jsonpath='{.metadata.labels.karpenter\.sh/capacity-type}'
```

### Issue 6: Node not joining cluster

```bash
# Check kubelet logs on the node
ssh ubuntu@<node-ip> sudo journalctl -u kubelet --no-pager | tail -50

# Check bootstrap script output
ssh ubuntu@<node-ip> cat /var/log/cloud-init-output.log | tail -100

# Verify cluster endpoint is accessible
ssh ubuntu@<node-ip> curl -k https://<cluster-endpoint>/healthz
```

### Issue 7: AMI drift detected but not resolved

```bash
# Check drift status
kubectl get nodeclaims -o jsonpath='{range .items[*]}{.metadata.name}{.statusconditions}' | jq .

# Check AMI selector terms
kubectl get ec2nodeclass <name> -o yaml | grep -A 5 amiSelector

# Force drift resolution
kubectl annotate nodeclaim <name> karpenter.sh/initialized-
```

### Issue 8: Memory/CPU not matching expectations

```bash
# Check actual node resources
kubectl describe node <node-name> | grep -A 5 Allocatable

# Check NodeClaim resources
kubectl get nodeclaim <name> -o yaml | grep -A 10 resources

# Compare with instance type
aws ec2 describe-instance-types \
  --instance-types <type> \
  --query 'InstanceTypes[0].[VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]'
```

### Issue 9: Taints/labels not applied

```bash
# Check node labels
kubectl get node <node-name> --show-labels

# Check node taints
kubectl describe node <node-name> | grep -A 5 Taints

# Verify NodePool template
kubectl get nodepool <pool-name> -o yaml | grep -A 20 template
```

### Issue 10: Webhook errors

```bash
# Check webhook pods
kubectl get pods -n karpenter -l app.kubernetes.io/name=karpenter-webhook

# Check cert-manager certificates
kubectl get certificates -n karpenter

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep karpenter
kubectl get mutatingwebhookconfigurations | grep karpenter
```

### Issue 11: Slow node provisioning

```bash
# Check provisioning duration
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep "launch duration"

# Check if using optimal instance types
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter | grep "instance type"

# Consider using warm pools or over-provisioning
# Add a NodePool with lower priority for fast cold starts
```

### Issue 12: Consolidation causing too many evictions

```bash
# Check PDB compliance
kubectl get pdb -A

# Adjust disruption budgets
kubectl edit nodepool <name>
# Change: budgets: [{ nodes: "5%" }] to [{ nodes: "2" }]

# Or disable disruption temporarily
# disruption: { consolidationPolicy: WhenEmpty }
```

### Issue 13: Cross-AZ issues

```bash
# Check which AZs are being used
kubectl get nodes -o custom-columns='NAME:.metadata.name,AZ:.metadata.labels.topology\.kubernetes\.io/zone'

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=tag:karpenter.sh/discovery,Values=my-cluster"

# Check AZ-specific requirements
kubectl get nodepool <name> -o yaml | grep -A 10 topology.kubernetes.io/zone
```

### Issue 14: Cloud provider quota exceeded

```bash
# Check EC2 instance limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region us-west-2

# Check vCPU limits per instance family
aws service-quotas list-aws-service-quotas \
  --service-code ec2 \
  --query "Quotas[?contains(Name, 'Running On-Demand')]"
```

### Issue 15: Karpenter controller OOMKilled

```bash
# Check resource limits
kubectl describe pod -n karpenter -l app.kubernetes.io/name=karpenter | grep -A 5 Limits

# Increase memory limit
helm upgrade karpenter oci://public.ecr.aws/karpenter/karpenter \
  --set controller.resources.limits.memory=1Gi \
  --reuse-values

# Check memory usage
kubectl top pod -n karpenter -l app.kubernetes.io/name=karpenter
```

### Issue 16: Node not draining properly

```bash
# Check drain events
kubectl describe node <node-name> | grep -A 10 Events

# Check for finalizers
kubectl get nodeclaim <name> -o yaml | grep finalizers

# Force delete stuck NodeClaim
kubectl delete nodeclaim <name> --grace-period=0 --force
```

---

## 15. Tips & Best Practices

### Tip 1: Use Multiple NodePools for Workload Separation

Don't put everything in one NodePool. Separate by:
- **Criticality** (production vs dev)
- **Cost sensitivity** (spot vs on-demand)
- **Architecture** (amd64 vs arm64)
- **Workload type** (stateless vs stateful)

### Tip 2: Set Appropriate Limits

Always set CPU and memory limits per NodePool to prevent runaway provisioning:

```yaml
limits:
  cpu: "100"    # Adjust based on budget
  memory: 400Gi
```

### Tip 3: Use Disruption Budgets Wisely

```yaml
# Production: strict
disruption:
  budgets:
    - nodes: "0"       # No disruption

# Staging: moderate
disruption:
  budgets:
    - nodes: "15%"

# Development: aggressive
disruption:
  budgets:
    - nodes: "100%"
```

### Tip 4: Prefer Spot for Stateless Workloads

```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot", "on-demand"]  # Karpenter picks cheapest
```

### Tip 5: Use Expiration for Security Compliance

```yaml
disruption:
  expireAfter: 720h  # 30 days — force node rotation
```

### Tip 6: Tag Everything

```yaml
ec2nodeclass:
  tags:
    Environment: production
    Team: platform
    CostCenter: engineering-123
    ManagedBy: karpenter
```

### Tip 7: Monitor with Prometheus + Grafana

Set up dashboards for:
- Node count over time
- Instance type distribution
- Spot vs On-Demand ratio
- Consolidation frequency
- Provisioning latency

### Tip 8: Use Weight for NodePool Priority

```yaml
# When multiple NodePools match, higher weight wins
nodepool-production:
  weight: 100

nodepool-default:
  weight: 50

nodepool-spot:
  weight: 30
```

### Tip 9: Test with `kubectl delete nodeclaim`

Force consolidation by deleting a NodeClaim:
```bash
kubectl delete nodeclaim <name>
# Karpenter will try to move pods to other nodes
```

### Tip 10: Use `consolidationPolicy: WhenEmpty` for Batch

Batch workloads create and destroy pods frequently. `WhenEmpty` avoids
disrupting running pods:

```yaml
disruption:
  consolidationPolicy: WhenEmpty
```

### Tip 11: Set Up Interruption Handling (AWS)

Configure the SQS queue for spot interruption notices:

```bash
aws sqs create-queue --queue-name karpenter-${CLUSTER_NAME}
```

### Tip 12: UseAMI Selector Terms for Version Control

```yaml
# Pin to specific AMI for reproducibility
amiSelectorTerms:
  - id: ami-0abcdef1234567890

# Use alias for latest (auto-updates)
amiSelectorTerms:
  - alias: al2023@latest
```

### Tip 13: Monitor Cloud Provider Quotas

```bash
# Set up CloudWatch alarms for EC2 quotas
aws cloudwatch put-metric-alarm \
  --alarm-name ec2-vcpu-limit \
  --metric-name ServiceQuota \
  --namespace AWS/Usage \
  --dimensions Name=Service,Value=EC2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Tip 14: Use Over-Provisioner for Latency-Sensitive Workloads

```yaml
# Pre-provision a buffer of capacity
apiVersion: apps/v1
kind: Deployment
metadata:
  name: over-provisioner
spec:
  replicas: 3
  template:
    spec:
      priorityClassName: system-cluster-critical
      containers:
        - name: pause
          image: registry.k8s.io/pause:3.9
          resources:
            requests:
              cpu: "4"
              memory: 8Gi
```

### Tip 15: Regularly Review NodePool Utilization

```bash
# Check actual vs allocated resources
kubectl top nodes
kubectl describe node <name> | grep -A 5 Allocatable
kubectl describe node <name> | grep -A 5 "Allocated resources"
```

### Tip 16: Use Labels for Pod-to-NodePool Targeting

```yaml
# NodePool labels
nodepool:
  template:
    metadata:
      labels:
        nodepool: gpu-workloads

# Pod affinity
pod:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: nodepool
                operator: In
                values: ["gpu-workloads"]
```

### Tip 17: Enable Drift Detection

Drift detection is automatic in recent versions. Verify it's enabled:

```bash
kubectl get nodeclaims -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.drifted}{"\n"}{end}'
```

---

## 16. Real-World Example: Contoso Pet Store

### Scenario

Contoso Pet Store runs a microservices architecture on EKS:
- **API Gateway** (critical, on-demand, amd64)
- **Product Service** (stateless, spot OK, amd64/arm64)
- **Order Service** (critical, on-demand, amd64)
- **ML Recommendations** (GPU, on-demand, batch)
- **Background Jobs** (spot, batch, flexible)

### NodePool Definitions

```yaml
# ──── EC2NodeClass: Production ────
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: production
spec:
  role: KarpenterNodeRole-contoso-eks
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: contoso-eks
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: contoso-eks
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        encrypted: true
  metadataOptions:
    httpEndpoint: enabled
    httpTokens: required
---
# ──── EC2NodeClass: GPU ────
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: gpu
spec:
  role: KarpenterNodeRole-contoso-eks
  amiSelectorTerms:
    - alias: al2023@latest
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: contoso-eks
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: contoso-eks
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 200Gi
        volumeType: gp3
        encrypted: true
---
# ──── NodePool: Critical Services ────
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: critical
  labels:
    tier: critical
spec:
  weight: 100
  template:
    metadata:
      labels:
        tier: critical
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      nodeClassRef:
        name: production
  limits:
    cpu: "100"
    memory: 400Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    budgets:
      - nodes: "0"   # No disruption for critical
---
# ──── NodePool: General Workloads ────
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: general
  labels:
    tier: general
spec:
  weight: 50
  template:
    metadata:
      labels:
        tier: general
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
      nodeClassRef:
        name: production
  limits:
    cpu: "200"
    memory: 800Gi
  disruption:
    consolidationPolicy: WhenUnderutilized
    budgets:
      - nodes: "15%"
---
# ──── NodePool: ML / GPU ────
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: ml-gpu
  labels:
    tier: ml
spec:
  weight: 80
  template:
    metadata:
      labels:
        tier: ml
        accelerator: nvidia
    spec:
      taints:
        - key: nvidia.com/gpu
          value: "true"
          effect: NoSchedule
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["p", "g"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["2"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
      nodeClassRef:
        name: gpu
  limits:
    cpu: "48"
    memory: 192Gi
    nvidia.com/gpu: "8"
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 168h  # 7 days
---
# ──── NodePool: Batch / Background Jobs ────
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: batch
  labels:
    tier: batch
spec:
  weight: 30
  template:
    metadata:
      labels:
        tier: batch
    spec:
      taints:
        - key: workload
          value: batch
          effect: NoSchedule
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
      nodeClassRef:
        name: production
  limits:
    cpu: "100"
    memory: 400Gi
  disruption:
    consolidationPolicy: WhenEmpty
    expireAfter: 24h  # Force rotation daily
```

### Deployment Manifests

```yaml
# ──── API Gateway ────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: contoso
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
        tier: critical
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: tier
                    operator: In
                    values: ["critical"]
      containers:
        - name: api-gateway
          image: contoso/api-gateway:latest
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: "1"
              memory: 1Gi
---
# ──── ML Recommendations ────
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-recommendations
  namespace: contoso
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ml-recommendations
  template:
    metadata:
      labels:
        app: ml-recommendations
        tier: ml
    spec:
      tolerations:
        - key: nvidia.com/gpu
          value: "true"
          effect: NoSchedule
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: tier
                    operator: In
                    values: ["ml"]
      containers:
        - name: ml-recommendations
          image: contoso/ml-recommendations:latest
          resources:
            requests:
              cpu: "4"
              memory: 8Gi
              nvidia.com/gpu: "1"
            limits:
              cpu: "8"
              memory: 16Gi
              nvidia.com/gpu: "1"
---
# ──── Batch Jobs ────
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-etl
  namespace: contoso
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            tier: batch
        spec:
          tolerations:
            - key: workload
              value: batch
              effect: NoSchedule
          containers:
            - name: etl
              image: contoso/etl:latest
              resources:
                requests:
                  cpu: "2"
                  memory: 4Gi
          restartPolicy: OnFailure
```

---

## 17. Commands Reference

### Karpenter Controller

```bash
# View controller pods
kubectl get pods -n karpenter -l app.kubernetes.io/name=karpenter

# View controller logs (real-time)
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f

# View controller logs (last 100 lines)
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter --tail=100

# Restart controller
kubectl rollout restart deployment karpenter -n karpenter

# Check controller version
kubectl get deployment karpenter -n karpenter -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### NodePools

```bash
# List all NodePools
kubectl get nodepools

# Describe a NodePool
kubectl describe nodepool <name>

# Edit a NodePool
kubectl edit nodepool <name>

# Delete a NodePool (drains all nodes)
kubectl delete nodepool <name>

# Get NodePool as YAML
kubectl get nodepool <name> -o yaml

# Check NodePool events
kubectl get events --field-selector involvedObject.kind=NodePool
```

### NodeClaims

```bash
# List all NodeClaims
kubectl get nodeclaims

# Describe a NodeClaim
kubectl describe nodeclaim <name>

# Delete a specific NodeClaim (triggers consolidation)
kubectl delete nodeclaim <name>

# Get NodeClaims with node info
kubectl get nodeclaims -o wide

# Check NodeClaim drift status
kubectl get nodeclaims -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.drifted}{"\n"}{end}'

# Force drift resolution
kubectl annotate nodeclaim <name> karpenter.sh/initialized-
```

### EC2NodeClass (AWS)

```bash
# List all EC2NodeClasses
kubectl get ec2nodeclasses

# Describe an EC2NodeClass
kubectl describe ec2nodeclass <name>

# Edit an EC2NodeClass
kubectl edit ec2nodeclass <name>

# Check AMI selector
kubectl get ec2nodeclass <name> -o jsonpath='{.spec.amiSelectorTerms}'
```

### Nodes

```bash
# List nodes with labels
kubectl get nodes --show-labels

# List nodes with taints
kubectl get nodes -o custom-columns='NAME:.metadata.name,TAINTS:.spec.taints'

# List nodes by NodePool
kubectl get nodes -l karpenter.sh/provisioner-name=<pool-name>

# Check node utilization
kubectl top nodes

# Drain a node (respects PDBs)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

### Monitoring

```bash
# Port-forward to Karpenter metrics
kubectl port-forward -n karpenter svc/karpenter 8080:8080

# View metrics
curl http://localhost:8080/metrics | grep karpenter

# Check Prometheus targets
kubectl get servicemonitors -n karpenter

# View Grafana dashboards
kubectl get configmaps -n monitoring | grep karpenter
```

### Debugging

```bash
# Enable debug logging
kubectl set env deployment/karpenter -n karpenter --overwrite LOG_LEVEL=debug

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep karpenter
kubectl get mutatingwebhookconfigurations | grep karpenter

# Check cert-manager certificates
kubectl get certificates -n karpenter

# View controller resource usage
kubectl top pod -n karpenter -l app.kubernetes.io/name=karpenter

# Check for OOMKilled events
kubectl get events -n karpenter --field-selector reason=OOMKilling
```

### Cloud Provider (AWS)

```bash
# Check EC2 instances launched by Karpenter
aws ec2 describe-instances \
  --filters "Name=tag:karpenter.sh/provisioner-name,Values=*" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name}'

# Check SQS interruption queue
aws sqs get-queue-attributes \
  --queue-url $INTERRUPTION_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages

# Check IAM role
aws iam get-role --role-name KarpenterNodeRole-$CLUSTER_NAME

# Check EC2 quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region $AWS_REGION
```

### Upgrading Karpenter

```bash
# Check current version
helm list -n karpenter

# Upgrade Karpenter
helm upgrade karpenter oci://public.ecr.aws/karpenter/karpenter \
  --namespace karpenter \
  --version 0.36.0 \
  --reuse-values

# Upgrade CRDs
kubectl apply -f https://raw.githubusercontent.com/karpenter-provider/aws/main/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/karpenter-project/karpenter/main/pkg/apis/crds/karpenter.sh_nodepools.yaml

# Rollback if needed
helm rollback karpenter <revision> -n karpenter
```

---

## 18. Further Reading

### Official Documentation

- [Karpenter Documentation](https://karpenter.sh/docs/)
- [Karpenter AWS Provider](https://karpenter.sh/docs/contributing/providers/aws/)
- [Karpenter Azure Provider](https://karpenter.sh/docs/contributing/providers/azure/)
- [Karpenter GCP Provider](https://karpenter.sh/docs/contributing/providers/gcp/)
- [Karpenter GitHub Repository](https://github.com/kubernetes-sigs/karpenter)
- [Karpenter AWS Provider GitHub](https://github.com/aws/karpenter-provider-aws)

### Blog Posts & Tutorials

- [Introducing Karpenter](https://aws.amazon.com/blogs/containers/introducing-karpenter/)
- [Karpenter Best Practices](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [Karpenter vs Cluster Autoscaler](https://www.eksworkshop.com/docs/autoscaling/comparisons)
- [Cost Optimization with Karpenter](https://aws.amazon.com/blogs/architecture/cost-optimization-for-amazon-eks-with-karpenter/)

### CNCF & Community

- [Karpenter CNCF Sandbox](https://www.cncf.io/projects/karpenter/)
- [Karpenter Slack Channel](https://kubernetes.slack.com/messages/karpenter)
- [Karpenter Office Hours](https://zoom.us/j/94638251492)

### Related Tools

- [KEDA](https://keda.sh/) — Kubernetes Event-Driven Autoscaling
- [Descheduler](https://github.com/kubernetes-sigs/descheduler) — Rebalance pods across nodes
- [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) — Vertical Pod Autoscaler
- [Goldilocks](https://github.com/FairwindsOps/goldilocks) — VPA recommendations

### Videos & Talks

- [KubeCon talks on Karpenter](https://www.youtube.com/results?search_query=kubecon+karpenter)
- [Karpenter deep-dive](https://www.youtube.com/results?search_query=karpenter+deep+drive+kubernetes)
- [AWS re:Invent Karpenter sessions](https://www.youtube.com/results?search_query=reinvent+karpenter)

---

*Last updated: September 2026 — Karpenter v0.35.x / v0.36.x*
