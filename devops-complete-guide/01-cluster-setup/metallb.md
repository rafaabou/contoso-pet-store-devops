# MetalLB Complete Guide

## Table of Contents

1. [What Is MetalLB?](#1-what-is-metallb)
2. [Why Use MetalLB?](#2-why-use-metallb)
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

## 1. What Is MetalLB?

MetalLB is a load balancer implementation for bare-metal Kubernetes clusters. In cloud environments (AWS, GCP, Azure), cloud providers offer native load balancer integrations. When you create a `Service` of type `LoadBalancer`, the cloud controller automatically provisions a cloud load balancer. On bare-metal clusters, there is no cloud provider to fulfill this request, and `LoadBalancer` services get stuck in `Pending` state indefinitely. MetalLB fills this gap.

### The Problem MetalLB Solves

When you deploy a Kubernetes cluster on bare metal, you typically have:

- Nodes with private IP addresses on a local network
- A router/gateway for external access
- No cloud load balancer API to call

When you create a `Service` of type `LoadBalancer`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

Without MetalLB, this service will show:

```bash
kubectl get svc my-app
# NAME     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
# my-app   LoadBalancer   10.43.0.100    <pending>     80:31234/TCP
```

The `EXTERNAL-IP` stays `<pending>` forever. MetalLB assigns a real IP from a configured pool and announces it on the network.

### Architecture

MetalLB runs as a controller and speaker pods on your cluster:

```
┌──────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                      │
│                                                            │
│  ┌─────────────────────┐  ┌──────────────────────────┐    │
│  │  Controller Pod      │  │  Speaker Pod (each node) │    │
│  │  (1 replica)         │  │  - L2 mode: ARP/NDP      │    │
│  │  - IP allocation     │  │  - BGP mode: BGP peers    │    │
│  │  - Assignment logic  │  │  - Announces IPs          │    │
│  └─────────────────────┘  └──────────────────────────┘    │
│              │                         │                    │
│              ▼                         ▼                    │
│  ┌──────────────────────────────────────────────────┐     │
│  │              LoadBalancer Services                │     │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐         │     │
│  │  │ svc-A   │  │ svc-B   │  │ svc-C   │         │     │
│  │  │ 10.0.0.5│  │ 10.0.0.6│  │ 10.0.0.7│         │     │
│  │  └─────────┘  └─────────┘  └─────────┘         │     │
│  └──────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

**Controller** (single replica):
- Watches for new `LoadBalancer` services
- Allocates IPs from configured address pools
- Creates `Endpoints` objects pointing to the service's pods
- Manages IP assignment conflicts and reassignments

**Speaker** (one per node, runs as DaemonSet):
- Announces allocated IPs to the network
- In L2 mode: responds to ARP/NDP requests
- In BGP mode: establishes BGP sessions with routers
- Handles failover by re-announcing IPs when a node goes down

### Supported Modes

| Mode | Protocol | Use Case |
|------|----------|----------|
| **L2 (ARP)** | ARP/NDP | Simple setups, single network segment |
| **BGP** | BGP | Large networks, multi-path routing, ECMP |
| **Layer 2** | ARP/NDP | Default, easiest to configure |

### Key Features

- Works with any Kubernetes cluster (not just k3s)
- L2 and BGP announcement modes
- Automatic failover between nodes
- IP address pool management
- Zero configuration for basic usage
- Compatible with kube-vip, kube-proxy, and other CNI plugins
- No external dependencies or cloud providers needed
- Native Kubernetes integration via CRDs

---

## 2. Why Use MetalLB?

### Use Cases

**1. Bare-Metal Clusters**
The primary use case. MetalLB makes `LoadBalancer` services work on bare metal just like they do in the cloud.

**2. Home Labs**
Perfect for k3s/kind/minikube clusters in home environments where you want to expose services with real IPs.

**3. Development Environments**
Developers can test LoadBalancer services locally without cloud accounts.

**4. On-Premise Production**
Enterprise data centers running Kubernetes need load balancer functionality.

**5. Edge Computing**
IoT and edge deployments where cloud load balancers are impractical.

### Pros

| Advantage | Details |
|-----------|---------|
| **Free & Open Source** | Apache 2.0 license, active community |
| **Simple Setup** | 5-minute installation with sensible defaults |
| **Cloud-Native** | Uses Kubernetes CRDs, integrates with existing workflows |
| **Automatic Failover** | IPs move to healthy nodes automatically |
| **No Cloud Dependencies** | Works anywhere with network access |
| **Production Ready** | Used by CNCF projects, battle-tested |
| **Dual Mode** | L2 for simplicity, BGP for advanced routing |
| **Ingress Compatible** | Works perfectly with nginx-ingress and cert-manager |

### Cons

| Limitation | Details |
|------------|---------|
| **L2 Mode: Single Node** | Traffic always enters via the node owning the IP |
| **L2 Mode: No ECMP** | No load balancing across multiple nodes |
| **BGP Complexity** | BGP mode requires router configuration |
| **No TLS Termination** | MetalLB only handles IP assignment, not TLS |
| **Network Dependent** | ARP/NDP must be allowed on your network |
| **No Host Network** | BGP mode needs BGP-speaking router |
| **Maintenance Overhead** | Need to manage IP pools manually |

### Alternatives Comparison

| Tool | Mode | Complexity | Production Ready |
|------|------|------------|------------------|
| **MetalLB** | L2/BGP | Low-Medium | Yes |
| **kube-vip** | L2/BGP/ARP | Medium | Yes |
| **Keepalived** | VRRP | High | Yes |
| **OpenELB** | BGP/ARP | Medium | Yes |

**Recommendation**: MetalLB for most bare-metal setups. kube-vip if you need VIP for the Kubernetes control plane as well.

---

## 3. Installation

### Prerequisites

Before installing MetalLB, ensure:

1. **Kubernetes cluster is running** (k3s, kubeadm, etc.)
2. **Helm 3.x is installed** (recommended for installation)
3. **kubectl is configured** to talk to your cluster
4. **No existing load balancer** is running
5. **Network supports ARP/NDP** (for L2 mode) or you have a BGP router

### Method 1: Helm (Recommended)

Helm is the easiest way to install MetalLB with full configuration control.

```bash
# Add the MetalLB Helm repository
helm repo add metallb https://metallb.github.io/metallb
helm repo update

# Check available versions
helm search repo metallb/metallb --versions

# Install MetalLB (namespace metallb-system is created automatically)
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace \
  --version 0.14.9 \
  --set controller.replicas=1 \
  --set speaker.tolerations[0].key=node-role.kubernetes.io/master \
  --set speaker.tolerations[0].operator=Exists \
  --set speaker.tolerations[0].effect=NoSchedule

# Verify installation
kubectl get pods -n metallb-system
```

### Method 2: kubectl apply (Latest Manifest)

Use the official manifest for the latest version:

```bash
# Apply the latest release manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Or for a specific version
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

### Method 3: Kustomize

```bash
# Create a kustomization.yaml
cat <<EOF > metallb-kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: metallb-system

resources:
  - https://github.com/metallb/metallb/config/manifests/metallb-native.yaml?ref=v0.14.9

patches:
  - target:
      kind: Deployment
      name: metallb-controller
    patch: |
      - op: replace
        path: /spec/replicas
        value: 1

  - target:
      kind: DaemonSet
      name: metallb-speaker
    patch: |
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits
        value:
          cpu: 100m
          memory: 100Mi
EOF

kubectl apply -k metallb-kustomization.yaml
```

### Method 4: k3s Auto-Install

For k3s clusters, you can include MetalLB in the installation script:

```bash
# After k3s installation, add MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Wait for pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=metallb \
  --timeout=120s

# Apply your IP pool configuration
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
```

### Verify Installation

```bash
# Check all MetalLB pods are running
kubectl get pods -n metallb-system -o wide
# NAME                          READY   STATUS    RESTARTS   AGE
# metallb-controller-xxx        1/1     Running   0          2m
# metallb-speaker-xxx           1/1     Running   0          2m
# metallb-speaker-yyy           1/1     Running   0          2m

# Check CRDs are installed
kubectl get crds | grep metallb
# NAME                                    CREATED AT
# addresspools.metallb.io                 2024-01-01T00:00:00Z
# bgpadvertisements.metallb.io            2024-01-01T00:00:00Z
# bgppeers.metallb.io                     2024-01-01T00:00:00Z
# communitymetallbs.metallb.io            2024-01-01T00:00:00Z
# ipaddresspools.metallb.io               2024-01-01T00:00:00Z
# l2advertisements.metallb.io             2024-01-01T00:00:00Z
# servicel2s.metallb.io                   2024-01-01T00:00:00Z

# Check logs
kubectl logs -n metallb-system deployment/metallb-controller
kubectl logs -n metallb-system daemonset/metallb-speaker
```

---

## 4. Configuration

### MetalLB Configuration Components

MetalLB uses three types of configuration:

1. **IPAddressPool** - Defines ranges of IPs that MetalLB can assign
2. **L2Advertisement** - Announces IPs via ARP/NDP (L2 mode)
3. **BGPAdvertisement** - Announces IPs via BGP (BGP mode)

### IPAddressPool CRD

The `IPAddressPool` CRD defines which IPs MetalLB can use:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: my-pool
  namespace: metallb-system
spec:
  # List of IP ranges
  addresses:
    # CIDR notation (one IP)
    - 192.168.1.200/32
    # Range notation
    - 192.168.1.200-192.168.1.250
    # IPv6
    - fd00:100::100-fd00:100::200
  # Optional: disable auto-assignment
  autoAssign: true
  # Optional: limit to specific namespaces
  namespaces:
    - production
    - staging
  # Optional: limit to specific services
  serviceSelectors:
    - matchLabels:
        app: web
```

### L2Advertisement CRD

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: my-advertisement
  namespace: metallb-system
spec:
  # Optional: advertise only on specific interfaces
  interfaces:
    - eth0
    - ens192
  # Optional: limit to specific pools
  ipAddressPools:
    - my-pool
  # Optional: limit to specific namespaces
  namespaces:
    - production
  # Optional: limit to specific services
  serviceSelectors:
    - matchLabels:
        app: web
```

### BGPAdvertisement CRD

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: my-advertisement
  namespace: metallb-system
spec:
  # BGP peers to advertise to
  bgpPeers:
    - my-router
  # Optional: limit to specific pools
  ipAddressPools:
    - my-pool
  # Optional: ASN override
  localPref: 100
  # Optional: communities
  communities:
    - 65535:65281
  # Optional: node selectors
  nodeSelectors:
    - matchLabels:
        kubernetes.io/hostname: k3s-worker-1
```

### BGPConfiguration CRD

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: my-router
  namespace: metallb-system
spec:
  # Router ASN
  myASN: 64500
  # Peer (router) ASN
  peerASN: 64501
  # Peer (router) IP
  peerAddress: 192.168.1.1
  # Optional: source IP (for multi-homing)
  sourceAddress: 192.168.1.100
  # Optional: BFD profile
  bfdProfile: fast
  # Optional: hold time
  holdTime: 90s
  # Optional: keepalive time
  keepaliveTime: 30s
  # Optional: password
  password: secret123
  # Optional: node selectors
  nodeSelectors:
    - matchLabels:
        kubernetes.io/hostname: k3s-worker-1
```

### Multiple Pools Example

```yaml
# Pool 1: Production services
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
  autoAssign: true
  serviceSelectors:
    - matchLabels:
        environment: production
---
# Pool 2: Internal services
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: internal-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.2.100-10.0.2.150
  autoAssign: false
  serviceSelectors:
    - matchLabels:
        environment: internal
---
# Pool 3: Demo/Testing
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: demo-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.3.100-10.0.3.110
  autoAssign: false
```

### Namespace Restriction

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dev-only-pool
  namespace: metallb-system
spec:
  addresses:
    - 172.16.0.100-172.16.0.200
  namespaces:
    - development
    - testing
```

### Service Selector Example

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: web-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.50-192.168.1.100
  serviceSelectors:
    - matchLabels:
        app.kubernetes.io/name: nginx-ingress
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: db-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.210
  serviceSelectors:
    - matchLabels:
        app.kubernetes.io/name: postgresql
```

---

## 5. Core Concepts

### IP Address Management

MetalLB manages IP addresses through pools. Each pool defines a range of IPs that can be assigned to `LoadBalancer` services.

**Assignment Rules:**
1. If a service has `spec.loadBalancerIP`, MetalLB tries to assign that specific IP
2. If the IP is in a pool, it's assigned (if available)
3. If no specific IP is requested, MetalLB assigns from a pool with `autoAssign: true`
4. Pools with `autoAssign: false` only serve services that explicitly request their IPs

**IP Ownership:**
- Only one node can own an IP at a time
- Ownership is determined by ARP (L2) or BGP announcements
- When a node fails, another node takes over the IP

### ARP/NDP Announcements (L2 Mode)

In L2 mode, the speaker pod responds to ARP (IPv4) or NDP (IPv6) requests:

```
┌──────────┐     ARP Request      ┌──────────┐
│  Router  │  "Who has 10.0.1.50?" │  Node 1  │
│          │ ──────────────────────▶│ (owner)  │
│          │ ◀──────────────────────│          │
│          │  "10.0.1.50 is at     │          │
│          │   MAC: AA:BB:CC:DD:EE"│          │
└──────────┘                       └──────────┘
```

**Characteristics:**
- All traffic enters through the owning node
- Node forwards traffic to the correct pod
- Works within a single L2 network segment
- No router configuration needed
- Automatic failover when node goes down

### BGP Announcements

In BGP mode, speakers establish BGP sessions with routers and announce IP prefixes:

```
┌──────────┐     BGP Session      ┌──────────┐
│  Router  │ ◀─────────────────────▶│  Node 1  │
│          │  Announces: 10.0.1.0/24│          │
│          │                       └──────────┘
│          │     BGP Session      ┌──────────┐
│          │ ◀─────────────────────▶│  Node 2  │
│          │  Announces: 10.0.1.0/24│          │
└──────────┘                       └──────────┘
```

**Characteristics:**
- Traffic can be load-balanced across nodes (ECMP)
- Requires BGP router configuration
- More complex but more powerful
- Supports multiple paths and communities

### Failover

When a node goes down:

1. **Detection**: Other speakers notice the node is unreachable
2. **Re-announcement**: A new speaker starts announcing the IPs
3. **ARP/NDP Update**: The new speaker sends gratuitous ARP/NDP
4. **Traffic Redirect**: Network switches update their MAC tables

**Failover time**: Usually 10-30 seconds for L2 mode, faster for BGP.

### Speaker Election

MetalLB uses a leader election mechanism:

- **Controller**: Single leader, manages IP allocation
- **Speakers**: One per node, announce IPs
- When a speaker node fails, another speaker takes over its IPs
- The new speaker announces the IP to minimize downtime

---

## 6. Usage Guide

### Step 1: Configure IP Pool

Create a file `metallb-pool.yaml`:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
```

Apply it:

```bash
kubectl apply -f metallb-pool.yaml
```

### Step 2: Create a LoadBalancer Service

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 80
```

### Step 3: Verify Assignment

```bash
# Check the service
kubectl get svc nginx-demo
# NAME         TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# nginx-demo   LoadBalancer   10.43.0.100    192.168.1.200    80:31234/TCP

# Test access
curl http://192.168.1.200
# Welcome to nginx!
```

### Step 4: Assign Specific IP

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: default
  annotations:
    # Request a specific IP from a specific pool
    metallb.universe.tf/address-pool: my-pool
spec:
  type: LoadBalancer
  loadBalancerIP: 192.168.1.210  # Specific IP
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```

### Step 5: Multi-Port Services

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: multi-port
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
    - name: ssh
      port: 22
      targetPort: 22
```

### Step 6: TCP and UDP Services

```yaml
apiVersion: v1
kind: Service
metadata:
  name: game-server
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: game-server
  ports:
    - name: game-tcp
      port: 7777
      targetPort: 7777
      protocol: TCP
    - name: game-udp
      port: 7777
      targetPort: 7777
      protocol: UDP
```

### Step 7: Disable Auto-Assignment

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: manual-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.30-192.168.1.40
  autoAssign: false  # Only assigned if service requests specific IP
```

### Step 8: Limit to Specific Namespaces

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: prod-only
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.100-10.0.0.200
  namespaces:
    - production
    - staging
```

### Step 9: Monitor Allocation

```bash
# Check all allocated IPs
kubectl get services -A -o wide | grep LoadBalancer

# Check MetalLB logs
kubectl logs -n metallb-system deployment/metallb-controller -f

# Check speaker logs
kubectl logs -n metallb-system daemonset/metallb-speaker -f

# Check for warnings
kubectl logs -n metallb-system deployment/metallb-controller | grep -i warn
```

### Step 10: Remove an IP Allocation

```bash
# Delete the service
kubectl delete svc my-service

# Or change the service type
kubectl patch svc my-service -p '{"spec":{"type":"ClusterIP"}}'

# Verify IP is released
kubectl get ipaddresspools -n metallb-system -o yaml
```

---

## 7. Advanced Features

### Multiple Address Pools

MetalLB supports multiple pools for different purposes:

```yaml
# Pool for ingress controllers
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ingress-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.150
  serviceSelectors:
    - matchLabels:
        app.kubernetes.io/name: ingress-nginx
---
# Pool for databases
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: database-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.150-10.0.1.160
  serviceSelectors:
    - matchLabels:
        app.kubernetes.io/name: postgresql
---
# Pool for shared services
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: shared-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.2.100-10.0.2.200
  serviceSelectors:
    - matchLabels:
        environment: production
```

### BGP Mode Configuration

```yaml
# BGP Peer
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: router-1
  namespace: metallb-system
spec:
  myASN: 64500
  peerASN: 64501
  peerAddress: 192.168.1.1
  password: bgp-secret
  nodeSelectors:
    - matchLabels:
        kubernetes.io/hostname: k3s-worker-1
---
# BGP Advertisement
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: production-advertisement
  namespace: metallb-system
spec:
  bgpPeers:
    - router-1
  ipAddressPools:
    - production-pool
  localPref: 200
  communities:
    - 65535:65281
---
# BGP Configuration
apiVersion: metallb.io/v1beta1
kind: BGPConfiguration
metadata:
  name: default
  namespace: metallb-system
spec:
  # Local ASN (default: 64500)
  localASN: 64500
  # Node exclusion
  nodeExclusionAnnotations:
    - metallb.universe.tf/exclude
```

### Community Tags

```yaml
# Define communities
apiVersion: metallb.io/v1beta1
kind: Community
metadata:
  name: my-communities
  namespace: metallb-system
spec:
  communities:
    - name: production
      value: 64500:100
    - name: staging
      value: 64500:200
    - name: local
      value: 65535:65281
---
# Use communities in advertisements
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: prod-advertisement
  namespace: metallb-system
spec:
  bgpPeers:
    - router-1
  ipAddressPools:
    - production-pool
  communities:
    - production
```

### BFD Profile

```yaml
apiVersion: metallb.io/v1beta1
kind: BFDProfile
metadata:
  name: fast-bfd
  namespace: metallb-system
spec:
  # Transmit interval (ms)
  transmitInterval: 100
  # Receive interval (ms)
  receiveInterval: 100
  # Detect multiplier
  detectMultiplier: 3
  # Echo mode
  echoMode: false
  # Passive mode
  passiveMode: false
  # Minimum TTL
  minimumTTL: 254
---
# Reference in BGP peer
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: router-1
  namespace: metallb-system
spec:
  myASN: 64500
  peerASN: 64501
  peerAddress: 192.168.1.1
  bfdProfile: fast-bfd
```

### Node Exclusion

```yaml
# Exclude a node from being a speaker
apiVersion: v1
kind: Node
metadata:
  name: worker-2
  labels:
    metallb.universe.tf/exclude: "true"
```

Or via annotation:

```yaml
apiVersion: v1
kind: Node
metadata:
  name: worker-2
  annotations:
    metallb.universe.tf/exclude: "true"
```

### IPv6 Dual-Stack

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dual-stack-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
    - fd00:100::100-fd00:100::200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: dual-stack
  namespace: metallb-system
spec:
  ipAddressPools:
    - dual-stack-pool
```

---

## 8. Integration

### Integration with nginx-ingress

MetalLB provides the external IP for nginx-ingress:

```yaml
# Install nginx-ingress with LoadBalancer type
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.config.use-forwarded-headers="true"

# MetalLB automatically assigns an IP from the pool
kubectl get svc -n ingress-nginx ingress-nginx-controller
# NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
# ingress-nginx-controller   LoadBalancer   10.43.0.50     192.168.1.200    80:30080/TCP,443:30443/TCP
```

### Integration with cert-manager

MetalLB provides the IP for cert-manager's ACME challenge solver:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  annotations:
    metallb.universe.tf/address-pool: ingress-pool
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: ingress-nginx
  ports:
    - port: 80
      targetPort: 80
```

### Integration with k3s

MetalLB works seamlessly with k3s:

```bash
# 1. Install k3s
curl -sfL https://get.k3s.io | sh -

# 2. Install MetalLB via Helm
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace

# 3. Configure IP pool
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: k3s-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.195.94.200-10.195.94.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: k3s-advertisement
  namespace: metallb-system
EOF
```

### Integration with kube-vip

If using kube-vip for control plane VIP, ensure no IP conflicts:

```yaml
# kube-vip uses 10.195.94.1 for VIP
# MetalLB should use a different range
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: metallb-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.195.94.200-10.195.94.250  # Don't overlap with kube-vip
```

### Integration with CNI (Flannel/Canal)

MetalLB works with any CNI plugin:

```bash
# For k3s with Flannel (default)
# No special configuration needed
# MetalLB operates independently of CNI

# For Calico with BGP
# MetalLB BGP and Calico BGP can coexist
# but use different ASNs
```

---

## 9. Security

### Network Policies

MetalLB itself doesn't enforce network policies, but you can use them:

```yaml
# Allow traffic to MetalLB speaker
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: metallb-speaker
  namespace: metallb-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: metallb-speaker
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow ARP/NDP responses
    - ports:
        - port: 7472
          protocol: UDP
  egress:
    # Allow ARP/NDP announcements
    - ports:
        - port: 7472
          protocol: UDP
    # Allow DNS
    - ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
    # Allow BGP (if using BGP mode)
    - ports:
        - port: 179
          protocol: TCP
```

### RBAC Hardening

MetalLB creates its own RBAC rules. You can review them:

```bash
kubectl get clusterrole | grep metallb
kubectl describe clusterrole metallb-controller
```

### BGP Authentication

Use BGP password for security:

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: secure-router
  namespace: metallb-system
spec:
  myASN: 64500
  peerASN: 64501
  peerAddress: 192.168.1.1
  password: YourStrongBGPPassword  # Use Kubernetes secrets in production
```

### IP Pool Restriction

Limit pools to specific namespaces:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: restricted-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.5.100-10.0.5.200
  namespaces:
    - production  # Only production namespace can use this pool
```

### Monitoring & Auditing

```bash
# Check MetalLB events
kubectl get events -n metallb-system

# Check for unauthorized IP assignments
kubectl get services -A -o yaml | grep -A5 "loadBalancerIP"

# Monitor speaker logs for anomalies
kubectl logs -n metallb-system daemonset/metallb-speaper | grep -i "unauthorized"
```

---

## 10. Troubleshooting

### Issue 1: Service Stuck in Pending

**Symptoms:**
```bash
kubectl get svc my-service
# NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)
# my-service   LoadBalancer   10.43.0.10   <pending>     80:31234/TCP
```

**Diagnosis:**
```bash
# Check MetalLB controller logs
kubectl logs -n metallb-system deployment/metallb-controller | tail -50

# Check if pools exist
kubectl get ipaddresspools -n metallb-system

# Check if pool has available IPs
kubectl describe ipaddresspools -n metallb-system
```

**Solutions:**
1. Ensure IPAddressPool is created in the `metallb-system` namespace
2. Check pool has available IPs
3. Verify service namespace matches pool's namespace restriction
4. Check service labels match pool's serviceSelector

### Issue 2: IP Not Reachable

**Symptoms:**
- Service has EXTERNAL-IP assigned
- Cannot ping or curl the IP

**Diagnosis:**
```bash
# Check which node owns the IP
kubectl logs -n metallb-system daemonset/metallb-speaker | grep "announcing"

# Check ARP table on your machine
arp -a | grep <EXTERNAL-IP>

# Check node network interfaces
ip addr show
```

**Solutions:**
1. Verify node is on the same L2 network
2. Check ARP isn't blocked by firewall
3. Ensure node's interface is up and has correct IP
4. Check switch port configuration

### Issue 3: IP Fails Over Slowly

**Symptoms:**
- IP takes >30 seconds to failover to another node

**Diagnosis:**
```bash
# Check speaker health
kubectl get pods -n metallb-system -o wide

# Check for network partitions
kubectl get nodes

# Check speaker logs for failover events
kubectl logs -n metallb-system daemonset/metallb-speaker | grep -i "failover"
```

**Solutions:**
1. Reduce speaker liveness probe timeout
2. Check network connectivity between nodes
3. Verify no network policies blocking speaker communication
4. Consider using BGP mode for faster failover

### Issue 4: Duplicate IP Assignment

**Symptoms:**
- Two services get the same IP
- ARP conflicts on the network

**Diagnosis:**
```bash
# List all LoadBalancer services with IPs
kubectl get svc -A -o custom-columns=\
'NAME:.metadata.name,NAMESPACE:.metadata.namespace,IP:.status.loadBalancer.ingress[0].ip,TYPE:.spec.type' \
| grep LoadBalancer

# Check controller logs for conflicts
kubectl logs -n metallb-system deployment/metallb-controller | grep -i conflict
```

**Solutions:**
1. Use service selectors to separate pools
2. Set `autoAssign: false` for specific pools
3. Use unique service annotations

### Issue 5: MetalLB Conflicts with kube-proxy

**Symptoms:**
- Intermittent connectivity
- Connection refused errors

**Diagnosis:**
```bash
# Check kube-proxy mode
kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode

# Check for iptables conflicts
sudo iptables -t nat -L | grep <EXTERNAL-IP>
```

**Solutions:**
1. Ensure kube-proxy is in iptables or ipvs mode
2. MetalLB and kube-proxy should use the same mode
3. For k3s, kube-proxy is built-in and compatible

### Issue 6: BGP Session Not Establishing

**Symptoms:**
- BGP peers show `Established` but IPs not announced
- BGP mode not working

**Diagnosis:**
```bash
# Check BGP peer status
kubectl get bgppeers -n metallb-system

# Check speaker logs for BGP errors
kubectl logs -n metallb-system daemonset/metallb-speaker | grep -i bgp

# Verify router configuration
show ip bgp summary  # On your router
```

**Solutions:**
1. Verify ASN matches on both sides
2. Check BGP password is correct
3. Ensure TCP port 179 is open
4. Verify router is reachable from all nodes

### Issue 7: Speaker Pod CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n metallb-system
# NAME                          READY   STATUS             RESTARTS
# metallb-speaker-xxx           0/1     CrashLoopBackOff   5
```

**Diagnosis:**
```bash
kubectl logs -n metallb-system pod/metallb-speaker-xxx --previous
```

**Solutions:**
1. Check RBAC permissions
2. Verify network interface exists
3. Check for port conflicts
4. Review resource limits

### Issue 8: Controller Pod Not Starting

**Symptoms:**
```bash
kubectl get pods -n metallb-system
# NAME                          READY   STATUS
# metallb-controller-xxx         0/1     Pending
```

**Diagnosis:**
```bash
kubectl describe pod metallb-controller-xxx -n metallb-system
```

**Solutions:**
1. Check for resource constraints
2. Verify node has enough CPU/memory
3. Check for taints/tolerations issues
4. Ensure etcd is healthy

### Issue 9: IP Pool Exhausted

**Symptoms:**
- New services stuck in Pending
- Controller logs show "no available IPs"

**Diagnosis:**
```bash
# Check allocated IPs
kubectl get svc -A -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | .status.loadBalancer.ingress[0].ip' | sort

# Check pool size
kubectl get ipaddresspools -n metallb-system -o yaml
```

**Solutions:**
1. Expand the IP pool range
2. Remove unused LoadBalancer services
3. Create additional pools
4. Use `autoAssign: false` for non-critical pools

### Issue 10: Service Selector Not Matching

**Symptoms:**
- Service assigned wrong pool
- IPs from unexpected ranges

**Diagnosis:**
```bash
# Check service labels
kubectl get svc my-service -o yaml | grep -A5 labels

# Check pool selectors
kubectl get ipaddresspools -n metallb-system -o yaml | grep -A5 serviceSelectors
```

**Solutions:**
1. Ensure service labels match pool's serviceSelector
2. Use `kubectl describe` to check matching
3. Verify labels are correctly set

### Issue 11: External Traffic Policy Issues

**Symptoms:**
- Traffic only hitting one pod
- Load balancing not working

**Diagnosis:**
```bash
kubectl get svc my-service -o yaml | grep externalTrafficPolicy
```

**Solutions:**
1. Use `externalTrafficPolicy: Local` for direct pod access
2. Use `externalTrafficPolicy: Cluster` for kube-proxy load balancing
3. Note: `Local` preserves source IP but may cause uneven load

### Issue 12: MetalLB After Node Reboot

**Symptoms:**
- Node rejoins cluster but doesn't take over IPs
- IPs stuck on failed node

**Diagnosis:**
```bash
kubectl get nodes
kubectl get pods -n metallb-system -o wide
kubectl logs -n metallb-system daemonset/metallb-speaker | grep -i "re-announce"
```

**Solutions:**
1. Wait for speaker to re-elect (automatic)
2. Restart speaker on the node: `kubectl delete pod <speaker-pod>`
3. Check node network interface is up

### Issue 13: Conflicting with Other Load Balancers

**Symptoms:**
- ARP conflicts
- IPs intermittently unreachable

**Diagnosis:**
```bash
# Check for other ARP responders
sudo arping -I eth0 <IP>
# Look for multiple responses
```

**Solutions:**
1. Ensure no other load balancer is running
2. Disable keepalived if present
3. Check for duplicate MetalLB installations

### Issue 14: IPv6 Not Working

**Symptoms:**
- IPv4 addresses work, IPv6 don't
- NDP not resolving

**Diagnosis:**
```bash
# Check IPv6 is enabled on nodes
ip -6 addr show

# Check NDP table
ip -6 neigh show

# Check MetalLB speaker logs for IPv6
kubectl logs -n metallb-system daemonset/metallb-speaper | grep -i ipv6
```

**Solutions:**
1. Ensure IPv6 is enabled on all nodes
2. Check router advertisements are enabled
3. Verify IPv6 pool is correctly configured
4. Check firewall allows ICMPv6

### Issue 15: Monitoring Alerts Not Firing

**Symptoms:**
- Prometheus not scraping MetalLB
- No metrics available

**Diagnosis:**
```bash
# Check if metrics port is exposed
kubectl get svc -n metallb-system

# Check Prometheus ServiceMonitor
kubectl get servicemonitor -n metallb-system
```

**Solutions:**
1. Enable metrics in MetalLB Helm values
2. Create ServiceMonitor for Prometheus
3. Check Prometheus operator is running
4. Verify network policies allow scraping

---

## 11. Tips & Best Practices

### Tip 1: Always Use Service Selectors

Don't rely on auto-assignment. Use explicit service selectors:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
  serviceSelectors:
    - matchLabels:
        metallb.universe.tf/address-pool: production
```

### Tip 2: Separate Pools by Environment

```yaml
# Development pool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dev
  namespace: metallb-system
spec:
  addresses:
    - 172.16.0.100-172.16.0.200
  serviceSelectors:
    - matchLabels:
        environment: dev
---
# Production pool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
  serviceSelectors:
    - matchLabels:
        environment: production
```

### Tip 3: Use externalTrafficPolicy: Local

Preserve source IP and avoid extra hops:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local  # Preserves source IP
```

### Tip 4: Monitor IP Pool Usage

Create a script to monitor pool usage:

```bash
#!/bin/bash
# metallb-monitor.sh

echo "=== MetalLB IP Pool Usage ==="
kubectl get ipaddresspools -n metallb-system -o yaml | \
  grep -A5 "addresses:" | grep -E "\- [0-9]"

echo ""
echo "=== Allocated IPs ==="
kubectl get svc -A -o json | jq -r \
  '.items[] | select(.spec.type=="LoadBalancer") | 
   "\(.metadata.namespace)/\(.metadata.name): \(.status.loadBalancer.ingress[0].ip // "pending")"'
```

### Tip 5: Set Resource Limits

Always set resource limits for MetalLB pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metallb-controller
  namespace: metallb-system
spec:
  template:
    spec:
      containers:
        - name: metallb-controller
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 500m
              memory: 256Mi
```

### Tip 6: Use Node Affinity

Control which nodes run MetalLB speakers:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: metallb-speaker
  namespace: metallb-system
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-role.kubernetes.io/worker
                    operator: Exists
```

### Tip 7: Keep Pools Small

Don't create huge IP ranges. Start small and expand as needed:

```yaml
# Good: Start with 10 IPs
spec:
  addresses:
    - 10.0.1.100-10.0.1.110

# Bad: Starting with 250 IPs
spec:
  addresses:
    - 10.0.1.100-10.0.1.250
```

### Tip 8: Document Your IP Assignments

Maintain a spreadsheet of IP assignments:

| IP | Service | Namespace | Pool | Notes |
|----|---------|-----------|------|-------|
| 10.0.1.100 | ingress-nginx | ingress-nginx | production | Main ingress |
| 10.0.1.101 | grafana | monitoring | production | Dashboard |
| 10.0.1.102 | prometheus | monitoring | production | Metrics |

### Tip 9: Test Failover

Regularly test failover scenarios:

```bash
# Drain a node
kubectl drain <node-name> --ignore-daemonsets

# Verify IPs moved
kubectl logs -n metallb-system daemonset/metallb-speaker | grep -i "re-announce"

# Uncordon the node
kubectl uncordon <node-name>
```

### Tip 10: Use Annotation for Specific Pools

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    metallb.universe.tf/address-pool: my-pool
spec:
  type: LoadBalancer
```

### Tip 11: Separate Internal and External IPs

```yaml
# Internal pool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: internal
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
  serviceSelectors:
    - matchLabels:
        visibility: internal
---
# External pool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: external
  namespace: metallb-system
spec:
  addresses:
    - 203.0.113.100-203.0.113.200
  serviceSelectors:
    - matchLabels:
        visibility: external
```

### Tip 12: Avoid Cross-Namespace Conflicts

Use namespace restrictions to prevent IP conflicts:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: team-a-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.150
  namespaces:
    - team-a
```

### Tip 13: Monitor with Prometheus

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metallb
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: metallb
  namespaceSelector:
    matchNames:
      - metallb-system
  endpoints:
    - port: http-metrics
      interval: 30s
```

### Tip 14: Use Health Checks

MetalLB has built-in health checks. Ensure your pods respond:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
        - name: my-app
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Tip 15: Plan for Growth

Design IP pools with growth in mind:

```yaml
# Reserve space for expansion
spec:
  addresses:
    - 10.0.1.100-10.0.1.200  # Current usage: 50 IPs
                             # Available for growth: 50 IPs
```

---

## 12. Commands Reference

### Installation Commands

```bash
# Install via Helm
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace

# Install via manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Uninstall
helm uninstall metallb -n metallb-system
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

### Pod Management

```bash
# List MetalLB pods
kubectl get pods -n metallb-system -o wide

# View controller logs
kubectl logs -n metallb-system deployment/metallb-controller -f

# View speaker logs (all speakers)
kubectl logs -n metallb-system daemonset/metallb-speaker -f

# View specific speaker logs
kubectl logs -n metallb-system pod/metallb-speaker-xxxxx

# Restart controller
kubectl rollout restart deployment/metallb-controller -n metallb-system

# Restart all speakers
kubectl rollout restart daemonset/metallb-speaker -n metallb-system
```

### CRD Management

```bash
# List MetalLB CRDs
kubectl get crds | grep metallb

# List IPAddressPools
kubectl get ipaddresspools -n metallb-system

# List L2Advertisements
kubectl get l2advertisements -n metallb-system

# List BGPAdvertisements
kubectl get bgpadvertisements -n metallb-system

# List BGPPeers
kubectl get bgppeers -n metallb-system

# Describe a pool
kubectl describe ipaddresspools -n metallb-system <pool-name>

# Delete a pool
kubectl delete ipaddresspools -n metallb-system <pool-name>
```

### Service Inspection

```bash
# List all LoadBalancer services
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Get service with external IP
kubectl get svc -A -o custom-columns=\
'NAME:.metadata.name,NAMESPACE:.metadata.namespace,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip'

# Check service events
kubectl describe svc <service-name>

# Watch for service changes
kubectl get svc -A -w --field-selector spec.type=LoadBalancer
```

### Network Debugging

```bash
# Check ARP table
arp -a | grep <EXTERNAL-IP>

# Ping the external IP
ping <EXTERNAL-IP>

# Check node network
ip addr show

# Trace traffic
traceroute <EXTERNAL-IP>

# Check iptables (if using kube-proxy)
sudo iptables -t nat -L KUBE-SVC-* | grep <EXTERNAL-IP>
```

### Monitoring

```bash
# Check MetalLB metrics (if Prometheus enabled)
kubectl port-forward -n metallb-system svc/metallb-controller 9091:9091

# Check speaker metrics
kubectl port-forward -n metallb-system svc/metallb-speaker 9092:9091

# Check for errors
kubectl logs -n metallb-system deployment/metallb-controller | grep -i error

# Check for warnings
kubectl logs -n metallb-system deployment/metallb-controller | grep -i warn
```

### Upgrading

```bash
# Check current version
helm list -n metallb-system

# Upgrade via Helm
helm upgrade metallb metallb/metallb -n metallb-system --version 0.14.9

# Upgrade via manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

---

## 13. CRD Reference

### IPAddressPool

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: string        # Required: Pool name
  namespace: string   # Required: Must be metallb-system
spec:
  addresses:          # Required: List of IP ranges
    - string          # Format: "IP/CIDR" or "IP-IP"
  autoAssign: bool    # Optional: Default true
  namespaces:         # Optional: Namespace restrictions
    - string
  serviceSelectors:   # Optional: Service matching rules
    - matchLabels:
        key: string
      matchExpressions:
        - key: string
          operator: In|NotIn|Exists|DoesNotExist
          values:
            - string
```

### L2Advertisement

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: string        # Required: Advertisement name
  namespace: string   # Required: Must be metallb-system
spec:
  interfaces:         # Optional: Network interfaces
    - string
  ipAddressPools:     # Optional: Pool references
    - string
  namespaces:         # Optional: Namespace restrictions
    - string
  serviceSelectors:   # Optional: Service matching rules
    - matchLabels:
        key: string
```

### BGPAdvertisement

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: string        # Required: Advertisement name
  namespace: string   # Required: Must be metallb-system
spec:
  bgpPeers:           # Required: Peer references
    - string
  ipAddressPools:     # Optional: Pool references
    - string
  localPref: int      # Optional: BGP local preference
  communities:        # Optional: Community values
    - string|int
  nodeSelectors:      # Optional: Node matching rules
    - matchLabels:
        key: string
```

### BGPPeer

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: string        # Required: Peer name
  namespace: string   # Required: Must be metallb-system
spec:
  myASN: int          # Required: Local ASN
  peerASN: int        # Required: Peer ASN
  peerAddress: string # Required: Peer IP address
  sourceAddress: string  # Optional: Source IP
  bfdProfile: string     # Optional: BFD profile name
  holdTime: duration     # Optional: BGP hold time
  keepaliveTime: duration  # Optional: Keepalive time
  password: string       # Optional: BGP password
  nodeSelectors:         # Optional: Node matching
    - matchLabels:
        key: string
```

### BFDProfile

```yaml
apiVersion: metallb.io/v1beta1
kind: BFDProfile
metadata:
  name: string        # Required: Profile name
  namespace: string   # Required: Must be metallb-system
spec:
  transmitInterval: int  # Optional: TX interval (ms)
  receiveInterval: int   # Optional: RX interval (ms)
  detectMultiplier: int  # Optional: Multiplier
  echoMode: bool         # Optional: Echo mode
  passiveMode: bool      # Optional: Passive mode
  minimumTTL: int        # Optional: Minimum TTL
```

### Community

```yaml
apiVersion: metallb.io/v1beta1
kind: Community
metadata:
  name: string        # Required: Community name
  namespace: string   # Required: Must be metallb-system
spec:
  communities:        # Required: Community definitions
    - name: string    # Required: Community name
      value: string   # Required: Community value (ASN:Value)
```

### BGPConfiguration

```yaml
apiVersion: metallb.io/v1beta1
kind: BGPConfiguration
metadata:
  name: string        # Required: "default"
  namespace: string   # Required: Must be metallb-system
spec:
  localASN: int       # Optional: Default local ASN
  nodeExclusionAnnotations:  # Optional: Node exclusion
    - string
```

---

## 14. Real-World Examples

### Example 1: Home Lab Setup

```yaml
# metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: home-lab-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.200-192.168.1.250
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: home-lab-advertisement
  namespace: metallb-system
spec:
  interfaces:
    - eth0
  ipAddressPools:
    - home-lab-pool
```

### Example 2: Production Cluster

```yaml
# production-metallb.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
  autoAssign: true
  serviceSelectors:
    - matchLabels:
        environment: production
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: staging
  namespace: metallb-system
spec:
  addresses:
    - 10.0.2.100-10.0.2.150
  autoAssign: true
  serviceSelectors:
    - matchLabels:
        environment: staging
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: production-advertisement
  namespace: metallb-system
spec:
  interfaces:
    - ens192
  ipAddressPools:
    - production
    - staging
```

### Example 3: BGP Mode with Router

```yaml
# bgp-metallb.yaml
apiVersion: metallb.io/v1beta1
kind: BGPPeer
metadata:
  name: core-router
  namespace: metallb-system
spec:
  myASN: 64500
  peerASN: 64501
  peerAddress: 10.0.0.1
  password: bgp-secret
  holdTime: 90s
  keepaliveTime: 30s
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: bgp-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.100-10.0.0.200
---
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: bgp-advertisement
  namespace: metallb-system
spec:
  bgpPeers:
    - core-router
  ipAddressPools:
    - bgp-pool
  localPref: 200
  communities:
    - 64500:100
```

### Example 4: Dual-Stack IPv4/IPv6

```yaml
# dual-stack-metallb.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dual-stack
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.200
    - fd00:100::100-fd00:100::200
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: dual-stack-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - dual-stack
```

### Example 5: Multi-Tenant Setup

```yaml
# tenant-metallb.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: team-alpha
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.100-10.0.1.150
  namespaces:
    - team-alpha
  serviceSelectors:
    - matchLabels:
        team: alpha
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: team-beta
  namespace: metallb-system
spec:
  addresses:
    - 10.0.1.150-10.0.1.200
  namespaces:
    - team-beta
  serviceSelectors:
    - matchLabels:
        team: beta
```

---

## 15. Further Reading

### Official Documentation
- [MetalLB Website](https://metallb.universe.tf/)
- [MetalLB GitHub](https://github.com/metallb/metallb)
- [MetalLB Configuration Reference](https://metallb.universe.tf/configuration/)
- [MetalLB Concepts](https://metallb.universe.tf/concepts/)

### Tutorials
- [MetalLB on k3s](https://metallb.universe.tf/installation/k3s/)
- [MetalLB with nginx-ingress](https://metallb.universe.tf/usage/nginx/)
- [MetalLB BGP Mode](https://metallb.universe.tf/configuration/bgp/)

### Related Tools
- [nginx-ingress Controller](./nginx-ingress.md)
- [cert-manager](./cert-manager.md)
- [kube-vip](https://kube-vip.io/)

### Community
- [MetalLB Slack](https://cloud-native.slack.com/channels/metallb)
- [Kubernetes Slack](https://slack.k8s.io/)

---

*Last Updated: 2026-09-03*
*Version: 1.0*
*Part of the DevOps Complete Guide Series*
