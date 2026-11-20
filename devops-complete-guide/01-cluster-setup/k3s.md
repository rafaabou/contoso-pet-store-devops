# k3s — Complete Guide

**Version:** v1.33.x (as of 2026)
**Last Updated:** September 2026

---

## Table of Contents

1. [What Is k3s?](#1-what-is-k3s)
2. [Why Use k3s?](#2-why-use-k3s)
3. [Architecture](#3-architecture)
4. [Prerequisites](#4-prerequisites)
5. [Installation Methods](#5-installation-methods)
6. [Server Mode (Control Plane)](#6-server-mode-control-plane)
7. [Agent Mode (Worker)](#7-agent-mode-worker)
8. [Configuration](#8-configuration)
9. [Networking](#9-networking)
10. [Storage](#10-storage)
11. [Load Balancing](#11-load-balancing)
12. [Ingress](#12-ingress)
13. [High Availability](#13-high-availability)
14. [Security](#14-security)
15. [Multi-Cluster](#15-multi-cluster)
16. [Uninstalling](#16-uninstalling)
17. [Commands Reference](#17-commands-reference)
18. [Configuration File Reference](#18-configuration-file-reference)
19. [Environment Variables](#19-environment-variables)
20. [Troubleshooting](#20-troubleshooting)
21. [Tips & Best Practices](#21-tips--best-practices)
22. [Real-World Example](#22-real-world-example)
23. [Further Reading](#23-further-reading)

---

## 1. What Is k3s?

### Plain English Explanation

k3s is a lightweight, certified Kubernetes distribution designed for resource-constrained environments. Think of it as "Kubernetes, but small" — it packs the entire Kubernetes control plane and worker functionality into a single binary under 100MB, with minimal external dependencies.

If Kubernetes is a heavy freight truck that can carry massive loads across continents, k3s is a nimble delivery van that gets packages to your door — same purpose, different scale, far easier to park.

### How It Differs from Full Kubernetes

| Feature | Full Kubernetes | k3s |
|---------|----------------|-----|
| Binary size | ~500MB+ | <100MB |
| RAM required | 2GB+ recommended | 512MB minimum |
| Storage required | 10GB+ | 1GB minimum |
| External database | Often required (etcd cluster) | Embedded SQLite or etcd |
| Cloud providers | Complex setup | Built-in ServiceLB |
| Ingress | Install separately | Traefik pre-installed |
| Service mesh | Install separately | Built-in options |
| Certificate management | Manual or install cert-manager | Built-in (cert-manager included) |
| Metrics server | Install separately | Built-in |
| Local storage | Install separately | Built-in local-path provisioner |
| Install method | Kubeadm + many steps | Single curl command |
| Architecture | Separate components | Single binary (server + agent) |

### ASCII Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        k3s Server Node                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    k3s (single binary)                    │  │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────────────┐     │  │
│  │  │ API      │  │ Scheduler│  │ Controller Manager │     │  │
│  │  │ Server   │  │          │  │                    │     │  │
│  │  └────┬─────┘  └────┬─────┘  └─────────┬──────────┘     │  │
│  │       │              │                   │                │  │
│  │       └──────────────┼───────────────────┘                │  │
│  │                      │                                    │  │
│  │              ┌───────▼───────┐                            │  │
│  │              │   Data Store  │                            │  │
│  │              │ (SQLite/etcd) │                            │  │
│  │              └───────────────┘                            │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │              Add-ons (built-in)                   │    │  │
│  │  │  ┌─────────┐ ┌────────┐ ┌─────────┐ ┌────────┐ │    │  │
│  │  │  │ Traefik │ │CoreDNS │ │Metrics  │ │Service │ │    │  │
│  │  │  │ Ingress │ │        │ │ Server  │ │  LB    │ │    │  │
│  │  │  └─────────┘ └────────┘ └─────────┘ └────────┘ │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         │                                      │
│              ┌──────────▼──────────┐                           │
│              │   kubelet + kube-proxy│                          │
│              └──────────┬──────────┘                           │
└─────────────────────────┼──────────────────────────────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
     ┌──────▼──────┐ ┌────▼─────┐ ┌────▼─────┐
     │  Worker 1   │ │ Worker 2 │ │ Worker 3 │
     │  (k3s       │ │ (k3s     │ │ (k3s     │
     │   agent)    │ │  agent)  │ │  agent)  │
     │             │ │          │ │          │
     │ ┌─────────┐ │ │┌────────┐│ │┌────────┐│
     │ │ kubelet │ │ ││ kubelet││ ││ kubelet││
     │ └─────────┘ │ │└────────┘│ │└────────┘│
     │ ┌─────────┐ │ │┌────────┐│ │┌────────┐│
     │ │kube-proxy│ │ ││kube-   ││ ││kube-   ││
     │ └─────────┘ │ ││proxy   ││ ││proxy   ││
     │             │ │└────────┘│ │└────────┘│
     └─────────────┘ └──────────┘ └──────────┘
```

### What k3s Includes Out of the Box

1. **API Server** — Kubernetes API endpoint
2. **etcd / SQLite** — Data store (SQLite for single-node, etcd for HA)
3. **Scheduler** — Assigns pods to nodes
4. **Controller Manager** — Manages desired state
5. **Kubelet** — Node agent
6. **Kube-proxy** — Network proxy for Services
7. **Container runtime** — containerd (built-in)
8. **CoreDNS** — Cluster DNS
9. **Traefik** — Ingress controller
10. **ServiceLB** — Load balancer (replaces MetalLB)
11. **Local Path Provisioner** — Default storage
12. **Metrics Server** — Resource metrics API
13. **Traefik** — Ingress controller
14. **cert-manager** — Certificate management (optional enable)

---

## 2. Why Use k3s?

### Use Cases

**Edge Computing**
Deploy at retail locations, factories, or remote sites with limited hardware. A Raspberry Pi 4 running k3s can orchestrate containers just like a data center cluster.

**IoT and ARM Devices**
k3s builds for ARM64 (aarch64) and ARM (armhf), making it ideal for IoT gateways, industrial controllers, and single-board computers.

**Development and Testing**
Spin up a local Kubernetes cluster on your laptop in seconds. Test Helm charts, operators, and deployments without touching production.

**CI/CD Pipelines**
Use k3s as ephemeral build environments. Each pipeline gets its own cluster, runs tests, then tears down.

**Small to Medium Production**
Run production workloads on 2-5 nodes without the overhead of managing a full Kubernetes installation.

**Learning Kubernetes**
Learn Kubernetes concepts, YAML manifests, and kubectl without needing a cloud account or complex setup.

### Pros

| Advantage | Details |
|-----------|---------|
| **Simplicity** | Single binary, single command install |
| **Lightweight** | Runs on devices with 512MB RAM |
| **Fast** | Installs in seconds, not minutes |
| **Certified** | Passes all CNCF conformance tests |
| **Secure** | Defaults to hardened configuration |
| **Storage** | Built-in local storage, NFS, CSI |
| **Networking** | Built-in Flannel, CoreDNS, ServiceLB |
| **Ingress** | Traefik included by default |
| **HA Support** | Embedded etcd for multi-server clusters |
| **Air-Gapped** | Supports offline installation |
| **SQL Backend** | SQLite (simple) or etcd (HA) |
| **Component Options** | Disable any built-in component |

### Cons

| Disadvantage | Details |
|--------------|---------|
| **Single Binary** | Can't replace individual components |
| **Community** | Smaller ecosystem than full Kubernetes |
| **Enterprise Features** | Fewer enterprise integrations out-of-box |
| **Cloud Integration** | No native cloud load balancer integration |
| **Node Limits** | Practical limit ~500 nodes (vs thousands) |
| **etcd** | Embedded etcd not as battle-tested as external |
| **Debugging** | Harder to debug individual components |
| **Customization** | Less flexible than kubeadm for custom setups |

### When to Use k3s vs Full Kubernetes

**Use k3s when:**
- Running fewer than 500 nodes
- Resource constraints matter (IoT, edge, embedded)
- You want simplicity over customization
- Single-binary management appeals to you
- Built-in components (Traefik, ServiceLB) meet your needs
- Air-gapped deployment is required
- Learning Kubernetes on a laptop

**Use full Kubernetes when:**
- You need specific component versions or forks
- Running thousands of nodes
- Enterprise integrations are critical
- Custom admission controllers or webhooks are complex
- You need cloud-provider-specific features (cloud-controller-manager)
- Detailed component-level debugging is needed

---

## 3. Architecture

### Core Components

k3s bundles the following Kubernetes components into a single binary, differentiated by command flags:

```
k3s server    → API Server + etcd + Scheduler + Controller Manager + kubelet + kube-proxy
k3s agent     → kubelet + kube-proxy
```

#### API Server (kube-apiserver)
The front door to Kubernetes. All operations (kubectl, controllers, kubelet) communicate through the API server.

- Validates and processes REST API calls
- Updates etcd with cluster state
- Triggers controllers when state changes
- Enforces RBAC and admission policies

#### Scheduler (kube-scheduler)
Decides which node runs each new pod.

- Watches for unscheduled pods
- Evaluates node resources, taints, tolerations, affinity
- Binds pods to nodes
- Supports custom schedulers

#### Controller Manager (kube-controller-manager)
Maintains desired state by running reconciliation loops.

- **Deployment controller**: Manages ReplicaSets
- **Node controller**: Handles node status updates
- **Service controller**: Manages load balancers
- **Endpoint controller**: Populates Endpoints objects
- **Namespace controller**: Cleans up deleted namespaces
- Dozens more controllers for every Kubernetes resource type

#### etcd
The distributed key-value store that holds all cluster state.

- Single-node: Embedded etcd (simpler)
- HA cluster: Embedded etcd with peers (3 or 5 nodes)
- Stores: Nodes, pods, secrets, configmaps, services, etc.
- Supports snapshots and restore for backups

#### kubelet
The node agent that runs on every node.

- Watches API server for pods assigned to this node
- Manages pod lifecycle (create, start, stop, delete)
- Reports node status to API server
- Manages container runtime (containerd)
- Handles volume mounts and device plugins

#### kube-proxy
Manages network rules for Services.

- Implements ClusterIP, NodePort, LoadBalancer services
- Manages iptables or IPVS rules
- Handles service discovery and load balancing
- Runs in userspace, iptables, or IPVS mode

### Data Flow

```
1. User runs: kubectl apply -f deployment.yaml
       │
       ▼
2. kubectl sends POST to API Server
       │
       ▼
3. API Server validates request (RBAC, admission)
       │
       ▼
4. API Server writes to etcd: "Deployment nginx created"
       │
       ▼
5. Deployment Controller sees new Deployment
       │
       ▼
6. Creates ReplicaSet (writes to etcd)
       │
       ▼
7. ReplicaSet Controller sees new ReplicaSet
       │
       ▼
8. Creates Pod objects (writes to etcd)
       │
       ▼
9. Scheduler sees unscheduled Pods
       │
       ▼
10. Assigns Pod to Node (writes to etcd)
        │
        ▼
11. kubelet on target Node sees Pod assigned
        │
        ▼
12. kubelet tells containerd to pull image & start container
        │
        ▼
13. kube-proxy updates iptables for Service load balancing
```

### Container Runtime

k3s uses **containerd** as its container runtime (not Docker). This is the same runtime used by Docker Engine internally, but accessed directly without the Docker daemon overhead.

- **CRI (Container Runtime Interface)**: k3s uses containerd's CRI plugin
- **No Docker socket**: Don't expect `/var/run/docker.sock`
- **crictl**: CLI tool to interact with containerd (replaces `docker ps`)
- **ctr**: Low-level containerd CLI (rarely needed)

---

## 4. Prerequisites

### System Requirements

#### Server Node (Control Plane)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2+ cores |
| RAM | 512MB | 2GB+ |
| Disk | 1GB | 10GB+ (SSD preferred) |
| Network | 1 NIC | 1 Gbps+ NIC |

#### Agent Node (Worker)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 1 core | 2+ cores |
| RAM | 256MB | 1GB+ |
| Disk | 500MB | 5GB+ |
| Network | 1 NIC | 1 Gbps+ NIC |

#### Supported Platforms

- **Linux**: Ubuntu, Debian, CentOS, RHEL, Alpine, SUSE, Arch, Amazon Linux
- **ARM**: ARM64 (aarch64), ARM (armhf) — Raspberry Pi, AWS Graviton
- **Windows**: Experimental support (via WSL2 or native)

### Network Requirements

#### Ports

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| 6443 | TCP | Kubernetes API server | Yes |
| 8472 | UDP | Flannel VXLAN | If using Flannel |
| 10250 | TCP | kubelet API | Yes |
| 10251 | TCP | kube-scheduler | Server only |
| 10252 | TCP | kube-controller-manager | Server only |
| 10257 | TCP | kube-controller-manager | Server only |
| 10259 | TCP | kube-scheduler | Server only |
| 2379 | TCP | etcd client port | If using etcd |
| 2380 | TCP | etcd peer port | If using etcd |
| 51820 | UDP | WireGuard (if enabled) | Optional |
| 80 | TCP | HTTP Ingress | If using Traefik |
| 443 | TCP | HTTPS Ingress | If using Traefik |
| 5001 | TCP | k3s serviceLB | If using ServiceLB |
| 8080 | TCP | Traefik metrics | Optional |
| 9090 | TCP | Prometheus metrics | Optional |

#### Firewall Rules

**Server Node:**
```bash
# Allow API server
sudo ufw allow 6443/tcp

# Allow Flannel VXLAN
sudo ufw allow 8472/udp

# Allow kubelet
sudo ufw allow 10250/tcp

# Allow etcd (if HA cluster)
sudo ufw allow 2379/tcp
sudo ufw allow 2380/tcp

# Allow node ports (Services with type NodePort)
sudo ufw allow 30000:32767/tcp
```

**Agent Node:**
```bash
# Allow kubelet
sudo ufw allow 10250/tcp

# Allow Flannel VXLAN (if cross-node traffic)
sudo ufw allow 8472/udp

# Allow node ports
sudo ufw allow 30000:32767/tcp
```

### Storage Requirements

- **Minimum**: 1GB for k3s binaries and container images
- **Recommended**: 10GB+ for images, volumes, and logs
- **For Longhorn**: 10GB+ per node for distributed storage
- **For etcd**: SSD recommended for production HA clusters
- **For databases**: Fast IOPS matters more than capacity

### Prerequisites Checklist

```bash
# 1. Check kernel version (3.10+ required, 4.18+ recommended)
uname -r

# 2. Check available memory
free -h

# 3. Check available disk space
df -h

# 4. Check CPU
lscpu

# 5. Disable swap (recommended for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 6. Enable required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k3s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 7. Set required sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 8. Ensure time synchronization
sudo apt install -y chrony  # or chronyd on RHEL
sudo systemctl enable --now chrony
```

### For Incus/LXC Containers

If running k3s in Incus (or LXC) containers, additional setup is needed:

```bash
# On the host, enable nesting and bridge access for the container
incus config set <container-name> security.nesting true
incus config set <container-name> linux.kernel_modules "overlay br_netfilter ip_tables ip6_tables iptable_nat iptable_filter br_netfilter"

# Inside the container, mount /proc/sys as read-write
# (Create a systemd unit since LXC mounts it read-only)
cat <<'EOF' | sudo tee /etc/systemd/system/proc-sys-rw.service
[Unit]
Description=Remount /proc/sys as read-write
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/mount -o remount,rw /proc/sys
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now proc-sys-rw.service
```

---

## 5. Installation Methods

### Method 1: Curl Script (Recommended)

The fastest way to install k3s:

```bash
# Install k3s server (control plane + agent on same node)
curl -sfL https://get.k3s.io | sh -

# Install k3s agent only (join an existing cluster)
curl -sfL https://get.k3s.io | K3S_URL=https://server-ip:6443 K3S_TOKEN=token sh -
```

**How the script works:**
1. Detects your OS and architecture
2. Downloads the k3s binary from GitHub releases
3. Installs to `/usr/local/bin/k3s`
4. Creates systemd service files
5. Generates kubeconfig at `/etc/rancher/k3s/k3s.yaml`
6. Starts the k3s service

### Method 2: Script Options (Flags)

Every flag you can pass to the installation script:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="flags" sh -
```

#### Installation Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `INSTALL_K3S_SKIP_DOWNLOAD` | Use local binary instead of downloading | `false` |
| `INSTALL_K3S_BIN_DIR` | Installation directory | `/usr/local/bin` |
| `INSTALL_K3S_BIN_DIR_READ_ONLY` | Make bin dir read-only | `false` |
| `INSTALL_K3S_SYSTEMD_DIR` | Systemd unit directory | `/etc/systemd/system` |
| `INSTALL_K3S_EXEC` | Command to run (server/agent) | `server` |
| `INSTALL_K3S_NAME` | Name of the systemd service | `k3s` |
| `INSTALL_K3S_SKIP_ENABLE` | Don't enable the service | `false` |
| `INSTALL_K3S_SKIP_START` | Don't start the service | `false` |
| `INSTALL_K3S_SKIP_SELINUX_RPM` | Don't install SELinux RPM | `false` |
| `INSTALL_K3S_SELINUX_WARN` | Warn instead of fail on SELinux | `false` |
| `INSTALL_K3S_SELINUX_VERSION` | SELinux policy version | `1.6` |
| `INSTALL_K3S_CHANNEL` | Release channel (stable/latest) | `stable` |
| `INSTALL_K3SCumhur` | Custom mirror URL | — |
| `K3S_TOKEN` | Token for agent registration | Auto-generated |
| `K3S_URL` | Server URL for agents | — |
| `K3S_TOKEN_FILE` | File containing token | `/var/lib/rancher/k3s/server/token` |

#### Examples with Flags

```bash
# Install with specific version
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.30.4+k3s1 sh -

# Install agent only, skip starting
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="agent" \
  INSTALL_K3S_SKIP_START=true \
  K3S_URL=https://10.0.0.1:6443 \
  K3S_TOKEN="K10a3..." sh -

# Install using local binary (air-gapped)
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_DOWNLOAD=true sh -

# Install to custom directory
curl -sfL https://get.k3s.io | INSTALL_K3S_BIN_DIR=/opt/k3s/bin sh -

# Install with specific release channel
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -

# Install with custom systemd service name
curl -sfL https://get.k3s.io | INSTALL_K3S_NAME=k3s-prod sh -
```

### Method 3: Direct Binary Download

Download the binary directly without the script:

```bash
# Download from GitHub releases
wget https://github.com/k3s-io/k3s/releases/download/v1.33.0+k3s1/k3s

# Make executable and install
chmod +x k3s
sudo mv k3s /usr/local/bin/k3s

# Create systemd service manually
cat <<'EOF' | sudo tee /etc/systemd/system/k3s.service
[Unit]
Description=k3s
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s server
KillMode=process
Restart=always
RestartSec=5
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
TimeoutStopSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now k3s
```

### Method 4: Air-Gapped Installation

For environments without internet access:

```bash
# On a machine with internet:
# 1. Download the k3s binary
wget https://github.com/k3s-io/k3s/releases/download/v1.33.0+k3s1/k3s
chmod +x k3s

# 2. Download required images
wget https://github.com/k3s-io/k3s/releases/download/v1.33.0+k3s1/k3s-images.txt
# Or create your own images list:
cat <<EOF > k3s-images.txt
rancher/mirrored-library-etcd:3.5.21-k3s1
rancher/mirrored-coreos-etcd-operator:v0.12.0
rancher/k3s-updateroot:1.33.0-k3s1
rancher/k3s:1.33.0-k3s1
rancher/mirrored-pause:3.6
rancher/mirrored-coredns-coredns:1.11.1
rancher/mirrored-metrics-server:v0.7.2
rancher/mirrored-klipper-lb:v0.4.10
rancher/mirrored-traefik:3.3.6
rancher/mirrored-cilium-cilium:1.16.4
rancher/local-path-provisioner:v0.0.30
rancher/mirrored-paths-generator:0.1.1
EOF

# 3. Save images to tar files
while IFS= read -r line; do
  docker pull "$line"
done < k3s-images.txt
docker save -o k3s-images.tar $(cat k3s-images.txt)

# 4. Transfer k3s binary and images to air-gapped machine
scp k3s k3s-images.txt k3s-images.tar user@target:/tmp/

# On the air-gapped machine:
# 5. Install binary
sudo mv /tmp/k3s /usr/local/bin/k3s
sudo chmod +x /usr/local/bin/k3s

# 6. Import images
sudo k3s ctr images import /tmp/k3s-images.txt  # or use --image
# Or for each image:
sudo k3s ctr images import /tmp/k3s-images.tar

# 7. Configure and start
export INSTALL_K3S_SKIP_DOWNLOAD=true
export K3S_TOKEN="your-token-here"
# ... (same as curl install with INSTALL_K3S_SKIP_DOWNLOAD=true)
```

### Method 5: Binary Download with Systemd

```bash
# Download
curl -LO https://github.com/k3s-io/k3s/releases/download/v1.33.0+k3s1/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/k3s

# Create server service
cat <<'EOF' | sudo tee /etc/systemd/system/k3s.service
[Unit]
Description=k3s
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s server --disable=traefik
KillMode=process
Restart=always
RestartSec=5
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
TimeoutStopSec=0
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N

[Install]
WantedBy=multi-user.target
EOF

# Create agent service
cat <<'EOF' | sudo tee /etc/systemd/system/k3s-agent.service
[Unit]
Description=k3s agent
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s agent
KillMode=process
Restart=always
RestartSec=5
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
TimeoutStopSec=0
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now k3s.service
```

### Method 6: Helm Chart (for Kubernetes clusters)

k3s can also be installed as a Helm chart on an existing cluster:

```bash
helm repo add k3s https://k3s-io.github.io/k3s/
helm install k3s k3s/k3s \
  --namespace k3s-system \
  --create-namespace \
  --set k3s.token=your-token
```

---

## 6. Server Mode (Control Plane)

### What the Server Does

When you run `k3s server`, you're starting the Kubernetes control plane with an embedded agent. This single node acts as both the brain (API server, scheduler, controller manager, etcd) and a worker (kubelet, kube-proxy).

### Starting the Server

```bash
# Basic server start (runs in foreground)
sudo k3s server

# Start as systemd service
sudo systemctl start k3s

# Check status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f
```

### Server Configuration Options

#### API Server Flags

```bash
# Disable insecure port (default: 0.0.0.0:8080)
--kube-apiserver-arg=secure-port=6443

# Set audit log policy
--kube-apiserver-arg=audit-policy-file=/etc/rancher/k3s/audit-policy.yaml

# Enable API audit logging
--kube-apiserver-arg=audit-log-path=/var/log/k3s/audit.log

# Set API server advertise address (for multi-NIC servers)
--kube-apiserver-arg=advertise-address=10.0.0.1

# Set service account signing key
--kube-apiserver-arg=service-account-signing-key-file=/path/to/key

# Enable admission controllers
--kube-apiserver-arg=enable-admission-plugins=NodeRestriction,PodSecurity

# Set etcd endpoints
--datastore-endpoint=etcd
--datastore-cafile=/path/to/ca.crt
--datastore-certfile=/path/to/tls.crt
--datastore-keyfile=/path/to/tls.key
```

#### TLS Configuration

```bash
# k3s automatically generates TLS certificates at:
# /etc/rancher/k3s/tls/
#   ├── ca.crt
#   ├── ca.key
#   ├── server.crt
#   ├── server.key
#   ├── client.crt
#   └── client.key

# Custom TLS certificates
--tls-cert-file=/path/to/server.crt
--tls-key-file=/path/to/server.key

# Custom CA certificate
--cluster-ca-file=/path/to/ca.crt
```

#### Audit Logging

Create an audit policy:

```yaml
# /etc/rancher/k3s/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  # Don't log read-only requests to certain endpoints
  - level: None
    resources:
      - group: ""
        resources: ["events", "endpoints"]
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
      - group: ""
        resources: ["endpoints", "services", "services/status"]
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pods"]
    verbs: ["create", "update", "patch", "delete"]
  # Log everything else at Metadata level
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]
  - level: Request
    resources:
      - group: ""
        resources: ["*"]
```

Start k3s with audit logging:

```bash
sudo k3s server \
  --kube-apiserver-arg=audit-policy-file=/etc/rancher/k3s/audit-policy.yaml \
  --kube-apiserver-arg=audit-log-path=/var/log/k3s/audit.log \
  --kube-apiserver-arg=audit-log-maxage=30 \
  --kube-apiserver-arg=audit-log-maxbackup=10 \
  --kube-apiserver-arg=audit-log-maxsize=100
```

### Datastore Configuration

k3s supports multiple datastores:

```bash
# SQLite (default, single-node only)
--datastore-endpoint=""

# Embedded etcd (HA capable)
--datastore-endpoint=etcd

# External etcd
--datastore-endpoint=https://etcd1:2379,https://etcd2:2379,https://etcd3:2379
--datastore-cafile=/path/to/ca.crt
--datastore-certfile=/path/to/tls.crt
--datastore-keyfile=/path/to/tls.key

# MySQL
--datastore-endpoint="tcp://mysql-host:3306/k3s?parseTime=true"
--datastore-cafile=/path/to/ca.pem

# PostgreSQL
--datastore-endpoint="postgres://user:pass@pg-host:5432/k3s?sslmode=disable"
--datastore-cafile=/path/to/ca.pem
```

### Accessing the Cluster

```bash
# k3s.yaml is automatically created at:
# /etc/rancher/k3s/k3s.yaml

# Copy to your workstation
scp root@server:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Edit the server URL
sed -i "s/127.0.0.1/server-ip/g" ~/.kube/config

# Or use the built-in command
k3s kubectl config view --raw

# Test
kubectl get nodes
```

### kubeconfig Management

```bash
# View current kubeconfig
cat /etc/rancher/k3s/k3s.yaml

# Merge with existing kubeconfig
KUBECONFIG=~/.kube/config:/etc/rancher/k3s/k3s.yaml \
  kubectl config view --merge --flatten > /tmp/merged

# Set as default
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# For non-root users, set permissions
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# Or copy and fix ownership
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config
```

---

## 7. Agent Mode (Worker)

### What an Agent Does

An agent node joins an existing k3s server cluster and runs workloads. It provides:
- **kubelet**: Manages pods on this node
- **kube-proxy**: Handles networking for Services
- **containerd**: Runs containers
- **flannel**: Manages pod networking

### Joining an Agent

#### Step 1: Get the Join Token

On the server node:

```bash
# View token
sudo cat /var/lib/rancher/k3s/server/node-token

# Or use the k3s command
sudo k3s token list
```

The token looks like: `K10a3b4c5d6e7f8g9h0i1j2k3l4m5n6o7p8q9r0s1t2u3v4w5x6y7z8::server:abc123...`

#### Step 2: Install Agent

```bash
# Using curl (with URL and token)
curl -sfL https://get.k3s.io | K3S_URL=https://server-ip:6443 K3S_TOKEN="K10..." sh -

# Or set environment variables first
export K3S_URL=https://server-ip:6443
export K3S_TOKEN="K10..."
curl -sfL https://get.k3s.io | sh -
```

#### Step 3: Verify

On the server:

```bash
kubectl get nodes
# NAME       STATUS   ROLES                  AGE   VERSION
# server     Ready    control-plane,master   10m   v1.33.0+k3s1
# worker-1   Ready    <none>                 2m    v1.33.0+k3s1
```

### Node Labels

Labels add metadata to nodes for scheduling:

```bash
# Add a label
kubectl label node worker-1 disktype=ssd

# Add multiple labels
kubectl label node worker-1 zone=us-east-1a team=backend

# Remove a label
kubectl label node worker-1 disktype-

# List labels
kubectl get nodes --show-labels

# Select nodes by label
kubectl get nodes -l disktype=ssd
kubectl get nodes -l 'disktype in (ssd,hdd)'
```

### Node Taints

Taints prevent pods from being scheduled unless they tolerate the taint:

```bash
# Add a taint
kubectl taint nodes worker-1 dedicated=gpu:NoSchedule

# Add with NoExecute (evicts existing pods)
kubectl taint nodes worker-1 dedicated=gpu:NoExecute

# Remove a taint
kubectl taint nodes worker-1 dedicated=gpu:NoSchedule-

# List taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

#### Common Taints and Tolerations

```yaml
# Taint: dedicated=gpu:NoSchedule
# Toleration in pod spec:
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"

# Taint: node-role.kubernetes.io/control-plane:NoSchedule (on server)
# Tolerate it:
tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
```

### Drain and Uncordon

#### Drain a Node

Removes pods and marks the node as unschedulable:

```bash
# Drain a node (safe)
kubectl drain worker-1 --ignore-daemonsets --delete-emptydir-data

# Drain with timeout
kubectl drain worker-1 --ignore-daemonsets --timeout=300s

# Drain and cordon (permanently mark unschedulable)
kubectl drain worker-1 --ignore-daemonsets --force

# Skip specific pods
kubectl drain worker-1 --ignore-daemonsets --pod-selector='app!=important-app'
```

#### Uncordon a Node

Makes the node schedulable again:

```bash
# Uncordon a node
kubectl uncordon worker-1

# Check node status
kubectl get nodes
# NAME       STATUS     ROLES                  AGE   VERSION
# worker-1   NotReady   <none>                 5m    v1.33.0+k3s1
# (after uncordon and pod rescheduling)
# worker-1   Ready      <none>                 5m    v1.33.0+k3s1
```

#### Cordoning

Marks the node as unschedulable without evicting pods:

```bash
# Cordon (don't schedule new pods here)
kubectl cordon worker-1

# Check
kubectl get nodes
# NAME       STATUS     ROLES                  AGE   VERSION
# worker-1   SchedulingDisabled   <none>                 5m    v1.33.0+k3s1
```

### Agent Configuration

```bash
# Agent with custom node name
sudo k3s agent --node-name=my-worker

# Agent with specific labels
sudo k3s agent --node-label=zone=us-east-1a

# Agent with specific taints
sudo k3s agent --node-taint=dedicated=gpu:NoSchedule

# Agent with custom kubelet args
sudo k3s agent --kubelet-arg=max-pods=200

# Agent joining a different server
sudo k3s agent --server=https://other-server:6443 --token=K10...
```

---

## 8. Configuration

### k3s.yaml Explained

The default kubeconfig file at `/etc/rancher/k3s/k3s.yaml`:

```yaml
apiVersion: v1
clusters:
  - cluster:
      certificate-authority-data: LS0tLS1CRUdJTi...  # Base64-encoded CA cert
      server: https://127.0.0.1:6443                  # API server URL
    name: default                                      # Cluster name
contexts:
  - context:
      cluster: default                                # Cluster reference
      user: default                                   # User reference
      namespace: default                              # Default namespace
    name: default                                      # Context name
current-context: default                              # Active context
kind: Config
preferences: {}
users:
  - name: default
    user:
      client-certificate-data: LS0tLS1CRUdJTi...     # Base64-encoded client cert
      client-key-data: LS0tLS1CRUdJTi...             # Base64-encoded client key
```

### Every Field Explained

| Field | Description |
|-------|-------------|
| `apiVersion` | Kubernetes API version (always `v1` for kubeconfig) |
| `clusters[].cluster.certificate-authority-data` | Base64-encoded CA certificate for TLS verification |
| `clusters[].cluster.server` | API server URL (default: `https://127.0.0.1:6443`) |
| `clusters[].cluster.insecure-skip-tls-verify` | Skip TLS verification (NOT recommended) |
| `clusters[].cluster.proxy-url` | HTTP proxy for API server connection |
| `clusters[].cluster.tls-server-name` | Override TLS server name |
| `contexts[].context.cluster` | Cluster to use |
| `contexts[].context.user` | User to authenticate as |
| `contexts[].context.namespace` | Default namespace |
| `current-context` | Currently active context |
| `users[].user.client-certificate-data` | Base64-encoded client certificate |
| `users[].user.client-key-data` | Base64-encoded client key |
| `users[].user.token` | Bearer token (alternative to cert) |
| `users[].user.username` | Basic auth username (NOT recommended) |
| `users[].user.password` | Basic auth password (NOT recommended) |
| `users[].user.exec` | External credential plugin |
| `users[].user.auth-provider` | Auth provider config (OIDC, GCP, etc.) |

### k3s Server Configuration File

k3s can read a server config file instead of CLI flags:

```yaml
# /etc/rancher/k3s/config.yaml
# This file is read by k3s server

# Cluster configuration
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"
cluster-domain: "cluster.local"

# Network configuration
flannel-backend: "vxlan"  # none, host-gw, vxlan, wireguard, wireguard-native
disable-network-policy: false

# Disable components
disable:
  - traefik           # Disable built-in ingress
  - servicelb         # Disable built-in load balancer
  - metrics-server    # Disable built-in metrics

# Enable components
disable:
  - traefik           # Keep ServiceLB but disable Traefik

# API server configuration
kube-apiserver-arg:
  - "audit-policy-file=/etc/rancher/k3s/audit-policy.yaml"
  - "audit-log-path=/var/log/k3s/audit.log"
  - "audit-log-maxage=30"
  - "audit-log-maxbackup=10"

# Kubelet configuration
kubelet-arg:
  - "max-pods=200"
  - "eviction-hard=memory.available<256Mi,nodefs.available<10%"
  - "system-reserved=cpu=200m,memory=512Mi"
  - "kube-reserved=cpu=200m,memory=512Mi"

# Proxy configuration
kube-proxy-arg:
  - "proxy-mode=iptables"  # or ipvs

# TLS configuration
tls-cert-file: "/etc/rancher/k3s/tls/server.crt"
tls-key-file: "/etc/rancher/k3s/tls/server.key"

# Datastore configuration
datastore-endpoint: "etcd"  # or mysql/postgres URL

# Agent configuration
node-name: "my-server"
node-label:
  - "node-role.kubernetes.io/control-plane="
  - "zone=us-east-1a"

# Logging
log: "/var/log/k3s/k3s.log"
v: 0  # Verbosity level (0-10)

# Extra arguments
extra-env:
  - "HTTP_PROXY=http://proxy:8080"
  - "HTTPS_PROXY=http://proxy:8080"
```

### Environment Variables

k3s supports these environment variables:

| Variable | Description |
|----------|-------------|
| `K3S_TOKEN` | Token for agent registration |
| `K3S_TOKEN_FILE` | File containing the token |
| `K3S_URL` | Server URL for agents |
| `K3S_CLUSTER_SECRET` | Cluster secret (deprecated, use K3S_TOKEN) |
| `K3S_KUBECONFIG_OUTPUT` | Output kubeconfig path |
| `K3S_KUBECONFIG_MODE` | Kubeconfig file permissions |
| `K3S_RESOLV_CONF` | Custom resolv.conf path |
| `K3S_CERTIFICATE_AUTHORITIES` | Custom CA certificates |
| `K3S_DISABLE_SERVICES` | Services to disable |
| `K3S_DATASTORE_ENDPOINT` | Datastore endpoint |
| `K3S_DATASTORE_CAFILE` | Datastore CA file |
| `K3S_DATASTORE_CERTFILE` | Datastore cert file |
| `K3S_DATASTORE_KEYFILE` | Datastore key file |
| `K3S_FLANNEL_BACKEND` | Flannel backend |
| `K3S_FLANNEL_IFACE` | Network interface for Flannel |
| `K3S_FLANNEL_EXTERNAL_IP` | External IP for Flannel |
| `K3S_NODE_IP` | Node IP address |
| `K3S_NODE_NAME` | Node hostname |
| `K3S_NODE_LABEL` | Node labels |
| `K3S_NODE_TAINT` | Node taints |
| `K3S_BIND_ADDRESS` | Bind address for API server |
| `K3S_HTTP_PROXY` | HTTP proxy |
| `K3S_HTTPS_PROXY` | HTTPS proxy |
| `K3S_NO_PROXY` | Proxy exceptions |
| `K3S_SYSTEM_DEFAULT_REGISTRY` | Default image registry |

---

## 9. Networking

### Flannel

k3s uses Flannel for pod networking by default. Flannel provides a flat network where every pod gets a routable IP address.

#### Flannel Backends

| Backend | Description | Performance | Use Case |
|---------|-------------|-------------|----------|
| `vxlan` | Default, UDP encapsulation | Good | Most environments |
| `host-gw` | Direct routing, no encapsulation | Best | Single-LAN, bare metal |
| `wireguard` | Encrypted tunnel | Good | Multi-site, security |
| `wireguard-native` | Native WireGuard kernel support | Better | Modern kernels (5.6+) |
| `none` | No Flannel (bring your own CNI) | N/A | Calico, Cilium, etc. |

```bash
# Start with specific Flannel backend
sudo k3s server --flannel-backend=vxlan

# Start with host-gw (single LAN)
sudo k3s server --flannel-backend=host-gw

# Start with WireGuard encryption
sudo k3s server --flannel-backend=wireguard-native

# Disable Flannel entirely (use your own CNI)
sudo k3s server --flannel-backend=none --disable-network-policy
```

#### Network Interface Selection

```bash
# Specify which interface Flannel uses
sudo k3s server --flannel-iface=eth0

# Or in config file
flannel-iface: "eth0"

# Auto-detect (default)
flannel-iface: ""  # Empty string = auto-detect
```

#### External IP for Flannel

If nodes have public IPs:

```bash
sudo k3s server --flannel-external-ip=203.0.113.1
```

### CoreDNS

k3s includes CoreDNS for cluster DNS resolution.

#### How DNS Works

```
Pod A                    CoreDNS                    External DNS
   │                        │                            │
   │ 1. "What's the IP of  │                            │
   │     nginx.default.svc. │                            │
   │     cluster.local?"   │                            │
   │───────────────────────>│                            │
   │                        │ 2. Resolve from services   │
   │                        │    and pods                │
   │ <──────────────────────│                            │
   │ 3. Return 10.43.x.x  │                            │
   │                        │                            │
   │ 4. "What's google.com?"│                           │
   │───────────────────────>│                            │
   │                        │ 5. Forward to upstream     │
   │                        │    DNS server              │
   │                        │───────────────────────────>│
   │                        │ <──────────────────────────│
   │ <──────────────────────│ 6. Return 142.250.x.x    │
```

#### Custom DNS Configuration

```yaml
# /etc/rancher/k3s/config.yaml
# Change cluster DNS IP
cluster-dns: "10.43.0.10"  # Default

# Change cluster domain
cluster-domain: "cluster.local"  # Default
```

#### Testing DNS

```bash
# Run a test pod
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml
```

### Service CIDR and Pod CIDR

#### Default CIDRs

| CIDR | Default | Description |
|------|---------|-------------|
| `cluster-cidr` | `10.42.0.0/16` | Pod network (every pod gets an IP from here) |
| `service-cidr` | `10.43.0.0/16` | Service virtual IPs (ClusterIP) |

#### Custom CIDRs

```bash
# Start with custom CIDRs
sudo k3s server \
  --cluster-cidr=192.168.100.0/16 \
  --service-cidr=192.168.200.0/16

# Config file
cluster-cidr: "192.168.100.0/16"
service-cidr: "192.168.200.0/16"
```

#### Dual-Stack (IPv4 + IPv6)

```bash
# Enable dual-stack networking
sudo k3s server \
  --cluster-cidr=10.42.0.0/16,fd00:42::/48 \
  --service-cidr=10.43.0.0/16,fd00:43::/112 \
  --cluster-dns=10.43.0.10,fd00:43::10
```

### Network Policies

k3s includes network policy enforcement by default. You can disable it:

```bash
# Disable network policies (allow all traffic)
sudo k3s server --disable-network-policy

# Or in config file
disable-network-policy: true
```

#### Example Network Policy

```yaml
# Allow only pods with label "role: frontend" to access pods with label "role: backend"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
      ports:
        - protocol: TCP
          port: 8080
```

---

## 10. Storage

### Local Path Provisioner

k3s includes a local path provisioner that creates directories on the node where the pod is scheduled.

#### Default StorageClass

```bash
# Check default StorageClass
kubectl get storageclass
# NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
# local-path (default) rancher.io/local-path   Delete          WaitForFirstConsumer
```

#### Creating a PVC

```yaml
# my-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
```

```bash
kubectl apply -f my-pvc.yaml
kubectl get pvc
```

### NFS Storage

#### Server Setup

```bash
# On NFS server (Ubuntu/Debian)
sudo apt install -y nfs-kernel-server

# Create export directory
sudo mkdir -p /srv/nfs/k3s
sudo chown nobody:nogroup /srv/nfs/k3s

# Export to cluster network
echo "/srv/nfs/k3s 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)" | \
  sudo tee -a /etc/exports

# Apply exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

#### k3s NFS Client Setup

```bash
# Install nfs-common on all nodes
sudo apt install -y nfs-common

# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
provisioner: nfs
parameters:
  server: 10.0.0.1
  path: /srv/nfs/k3s
reclaimPolicy: Retain
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF
```

### Longhorn (Distributed Storage)

Longhorn provides replicated storage across nodes.

#### Installation

```bash
# Using Helm
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.8.1

# Or using kubectl apply
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/deploy/longhorn.yaml
```

#### StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  fromBackup: ""
reclaimPolicy: Delete
allowVolumeExpansion: true
```

### CSI Drivers

k3s supports Container Storage Interface (CSI) drivers for various storage backends:

```bash
# Install a CSI driver (example: OpenEBS)
helm repo add openebs https://openebs.github.io/openebs
helm install openebs openebs/openebs \
  --namespace openebs \
  --create-namespace

# List CSI drivers
kubectl get csidrivers

# Check CSI nodes
kubectl get csinodes
```

### Volume Snapshots

```bash
# Enable volume snapshots
sudo k3s server --enable-features=VolumeSnapshot

# Create a VolumeSnapshotClass
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapclass
driver: rancher.io/local-path
deletionPolicy: Delete
parameters: {}
EOF

# Create a snapshot
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: my-pvc
EOF
```

---

## 11. Load Balancing

### ServiceLB (k3s Built-in)

k3s includes ServiceLB (formerly Klipper LB) which provides LoadBalancer services without requiring MetalLB.

#### How ServiceLB Works

```
Service Type: LoadBalancer
   │
   ├── k3s allocates an external IP (from node IP or pool)
   │
   ├── Creates a DaemonSet pod on each node
   │
   ├── Each pod listens on the allocated IP:port
   │
   └── Traffic is forwarded to ClusterIP service
```

#### Configuration

```yaml
# /etc/rancher/k3s/config.yaml
# Enable/disable ServiceLB
disable:
  - servicelb  # Disable built-in load balancer

# Or start with flag
# sudo k3s server --disable=servicelb
```

#### Using ServiceLB

```yaml
# my-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```

```bash
kubectl apply -f my-service.yaml
kubectl get svc my-app
# NAME     TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
# my-app   LoadBalancer   10.43.100.50   10.0.0.100      80:31234/TCP   5m

# Access via external IP
curl http://10.0.0.100
```

### MetalLB Integration

If you disable ServiceLB, you can use MetalLB instead:

```bash
# Disable ServiceLB
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=servicelb" sh -

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=120s

# Configure IP pool
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.100-10.0.0.200
EOF

# Configure L2 advertisement
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec: {}
EOF
```

### LoadBalancer Service Examples

```yaml
# Web application with LoadBalancer
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443

---
# TCP Load Balancer
apiVersion: v1
kind: Service
metadata:
  name: redis-lb
spec:
  type: LoadBalancer
  selector:
    app: redis
  ports:
    - port: 6379
      targetPort: 6379
  sessionAffinity: ClientIP
```

---

## 12. Ingress

### Traefik (Built-in)

k3s includes Traefik as the default ingress controller.

#### How Traefik Works

```
Internet/Client
      │
      ▼
  Traefik (port 80/443)
      │
      ├── Route by Host: app.example.com → Service A
      │
      ├── Route by Path: /api/* → Service B
      │
      └── Route by Header: X-Custom: foo → Service C
```

#### Configuration

```yaml
# /etc/rancher/k3s/config.yaml
# Disable Traefik if you don't need it
disable:
  - traefik

# Or start with flag
# sudo k3s server --disable=traefik
```

#### Basic Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
  ingressClassName: traefik
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

#### Traefik Annotations

```yaml
# Rate limiting
annotations:
  traefik.ingress.kubernetes.io/rate-limit: "100"

# Circuit breaker
annotations:
  traefik.ingress.kubernetes.io/circuit-breaker-expression: "ResponseCodeRatio(500, 600, 0, 600) > 0.25"

# Load balancing
annotations:
  traefik.ingress.kubernetes.io/service.sticky.cookie: "true"
  traefik.ingress.kubernetes.io/service.sticky.cookie.name: "my-sticky-cookie"
  traefik.ingress.kubernetes.io/service.sticky.cookie.secure: "true"

# CORS
annotations:
  traefik.ingress.kubernetes.io/service.sticky.cookie: "true"
  traefik.ingress.kubernetes.io/service.sticky.cookie.name: "my-sticky-cookie"
  traefik.ingress.kubernetes.io/service.sticky.cookie.secure: "true"

# Redirect to HTTPS
annotations:
  traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd
```

### nginx-ingress

If you prefer nginx over Traefik:

```bash
# Disable Traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Install nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Or use kubectl apply
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
```

### Alternative Ingress Controllers

| Controller | Description | Use Case |
|------------|-------------|----------|
| Traefik | Built-in, auto-discovery | Most use cases |
| nginx-ingress | Popular, well-documented | Existing nginx users |
| HAProxy | High-performance | Heavy traffic |
| Istio Gateway | Service mesh integration | With Istio |
| Kong | API Gateway | API management |

---

## 13. High Availability

### Embedded etcd vs External DB

| Feature | Embedded etcd | External DB |
|---------|---------------|-------------|
| Setup complexity | Simple | Complex |
| Required nodes | 3+ servers | External database |
| Backup/restore | Built-in snapshots | DB-specific tools |
| Scalability | Good to ~500 nodes | Unlimited |
| Fault tolerance | Self-healing | Depends on DB |

### Server Tokens

In an HA setup, multiple server nodes share the same token:

```bash
# First server (creates the cluster)
sudo k3s server --cluster-init

# Additional servers (join existing cluster)
curl -sfL https://get.k3s.io | K3S_URL=https://server1:6443 K3S_TOKEN=token sh -
```

### HA Cluster Setup

#### Step 1: Initialize First Server

```bash
# On first server node
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init" sh -

# Save the token
sudo cat /var/lib/rancher/k3s/server/token
```

#### Step 2: Join Additional Servers

```bash
# On second server node
curl -sfL https://get.k3s.io | \
  K3S_URL=https://server1:6443 \
  K3S_TOKEN="K10..." \
  INSTALL_K3S_EXEC="server" sh -

# On third server node
curl -sfL https://get.k3s.io | \
  K3S_URL=https://server1:6443 \
  K3S_TOKEN="K10..." \
  INSTALL_K3S_EXEC="server" sh -
```

#### Step 3: Verify HA Cluster

```bash
# Check node status
kubectl get nodes
# NAME       STATUS   ROLES                  AGE     VERSION
# server1    Ready    control-plane,master   10m     v1.33.0+k3s1
# server2    Ready    control-plane,master   5m      v1.33.0+k3s1
# server3    Ready    control-plane,master   2m      v1.33.0+k3s1

# Check etcd member status
kubectl get etcd -n kube-system
# NAME                      READY   STATUS    AGE
# etcd-server1              1/1     Running   10m
# etcd-server2              1/1     Running   5m
# etcd-server3              1/1     Running   2m
```

### Snapshots and Restore

#### Create a Snapshot

```bash
# On any server node
sudo k3s etcd-snapshot save

# List snapshots
sudo k3s etcd-snapshot ls

# Delete old snapshots
sudo k3s etcd-snapshot delete --name snapshot-name
```

#### Restore from Snapshot

```bash
# Stop k3s on all nodes
sudo systemctl stop k3s

# Restore on the first server node
sudo k3s server --cluster-init --etcd-snapshot-name=server1-1234567890

# Start k3s on other server nodes
sudo systemctl start k3s
```

#### Automated Snapshots

```bash
# k3s creates automatic snapshots every 12 hours
# Stored at: /var/lib/rancher/k3s/server/db/snapshots/

# Configure snapshot retention
sudo k3s server \
  --etcd-snapshot-dir=/var/lib/rancher/k3s/server/db/snapshots \
  --etcd-snapshot-retention=5

# Cron job for external backup
cat <<'EOF' | sudo tee /etc/cron.d/k3s-backup
0 */6 * * * root /usr/local/bin/k3s etcd-snapshot save --name backup-$(date +\%Y\%m\%d-\%H\%M)
EOF
```

### External Database Options

#### MySQL

```bash
# On MySQL server
mysql -u root -p -e "CREATE DATABASE k3s; CREATE USER k3s IDENTIFIED BY 'password'; GRANT ALL ON k3s.* TO k3s;"

# On k3s server
sudo k3s server \
  --datastore-endpoint="tcp://mysql-host:3306/k3s?parseTime=true" \
  --datastore-cafile=/path/to/ca.pem
```

#### PostgreSQL

```bash
# On PostgreSQL server
sudo -u postgres createdb k3s
sudo -u postgres createuser k3s
sudo -u postgres psql -c "ALTER USER k3s WITH PASSWORD 'password';"

# On k3s server
sudo k3s server \
  --datastore-endpoint="postgres://k3s:password@pg-host:5432/k3s?sslmode=disable"
```

---

## 14. Security

### RBAC (Role-Based Access Control)

k3s enables RBAC by default. Every user and service account needs explicit permissions.

#### Creating a Role

```yaml
# Read-only role for a namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]

---
# Bind the role to a user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: jane
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### ClusterRole for Cluster-Wide Access

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes/status"]
    verbs: ["patch"]
```

### Pod Security Standards (PSS)

Replace the deprecated PodSecurityPolicy (PSP):

```yaml
# Enforce restricted security standard on a namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Network Policies

```yaml
# Deny all ingress in a namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress

---
# Allow specific pod communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
      ports:
        - port: 8080
```

### Secrets Encryption

```bash
# Enable encryption at rest for secrets
sudo k3s server \
  --secrets-encryption \
  --secrets-encryption-key-file=/path/to/encryption-config.yaml

# Encryption config
cat <<EOF > /path/to/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-encoded-32-byte-key>
      - identity: {}
EOF
```

### Security Context

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
    - name: app
      image: myapp:latest
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
      resources:
        limits:
          memory: "128Mi"
          cpu: "500m"
        requests:
          memory: "64Mi"
          cpu: "250m"
```

### TLS and Certificates

```bash
# k3s automatically manages TLS certificates
# Location: /etc/rancher/k3s/tls/

# View certificate details
openssl x509 -in /etc/rancher/k3s/tls/server.crt -text -noout

# Check certificate expiration
openssl x509 -in /etc/rancher/k3s/tls/server.crt -enddate -noout

# Install cert-manager for custom certificates
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

### Image Security

```yaml
# Use specific image tags, not latest
containers:
  - name: app
    image: myapp:v1.2.3  # Good
    # image: myapp:latest  # Bad

# Use image pull secrets for private registries
spec:
  imagePullSecrets:
    - name: my-registry-secret

# Create image pull secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

---

## 15. Multi-Cluster

### Cluster Federation

Run workloads across multiple k3s clusters:

```bash
# Using Kubefed (Kubernetes Federation)
helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts
helm install kubefed kubefed-charts/kubefed \
  --namespace kube-federation-system \
  --create-namespace

# Join clusters
kubefedctl join cluster1 --cluster-context cluster1
kubefedctl join cluster2 --cluster-context cluster2

# Federate a deployment
kubefedctl federate deployment nginx
```

### Sub-Clusters

Create child clusters under a parent:

```bash
# Using vCluster for virtual clusters
helm repo add vcluster https://charts.vcluster.com
helm install my-vcluster vcluster/vcluster \
  --namespace vcluster \
  --create-namespace \
  --set service.type=LoadBalancer

# Access the virtual cluster
kubectl --context vcluster_my-vcluster get nodes
```

### Cluster Pairing

Use Submariner for cross-cluster networking:

```bash
# Install Submariner broker
subctl deploy-broker

# Join clusters
subctl join broker-info.subm --clusterid=cluster1
subctl join broker-info.subm --clusterid=cluster2

# Verify connectivity
subctl show connections
subctl show endpoints
```

---

## 16. Uninstalling

### Clean Uninstall

```bash
# Stop and remove k3s
/usr/local/bin/k3s-uninstall.sh

# For agent nodes
/usr/local/bin/k3s-agent-uninstall.sh
```

### Manual Cleanup

```bash
# Stop the service
sudo systemctl stop k3s
sudo systemctl disable k3s

# Remove binaries
sudo rm -f /usr/local/bin/k3s
sudo rm -f /usr/local/bin/k3s-uninstall.sh
sudo rm -f /usr/local/bin/k3s-agent-uninstall.sh

# Remove configuration
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /etc/rancher/k3s-canal
sudo rm -rf /etc/rancher/k3s/config.yaml.d

# Remove data
sudo rm -rf /var/lib/rancher/k3s

# Remove systemd service
sudo rm -f /etc/systemd/system/k3s.service
sudo rm -f /etc/systemd/system/k3s.service.env
sudo systemctl daemon-reload

# Remove files
sudo rm -f /run/k3s
sudo rm -f /var/lib/rancher/k3s/agent/etc/containerd/config.toml

# Clean up iptables
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Remove Flannel network
sudo ip link delete cni0 2>/dev/null
sudo ip link delete flannel.1 2>/dev/null

# Remove cni configuration
sudo rm -rf /etc/cni/net.d
```

### Troubleshooting Uninstall

```bash
# If uninstall script fails, check what's running
ps aux | grep k3s

# Kill remaining processes
sudo killall -9 k3s

# Check for leftover files
find / -name "*k3s*" -type f 2>/dev/null

# Check systemd
systemctl list-units --type=service | grep k3s

# Check for leftover containers
sudo crictl ps -a
sudo crictl rm $(sudo crictl ps -aq)

# Remove containerd state
sudo rm -rf /run/containerd
```

---

## 17. Commands Reference

### k3s Binary Commands

```bash
# Server commands
k3s server [flags]              # Start k3s server
k3s etcd-snapshot save          # Save etcd snapshot
k3s etcd-snapshot ls            # List snapshots
k3s etcd-snapshot delete        # Delete snapshot
k3s etcd-snapshot restore       # Restore snapshot
k3s token create               # Create new token
k3s token list                 # List tokens
k3s token delete              # Delete token

# Agent commands
k3s agent [flags]              # Start k3s agent

# Utility commands
k3s kubectl [args]             # Run kubectl
k3s ctr [args]                 # Run containerd CLI
k3s crictl [args]              # Run crictl CLI

# Version and info
k3s --version                  # Show k3s version
k3s --help                     # Show help
```

### kubectl Commands (via k3s)

```bash
# Via k3s binary
k3s kubectl get nodes
k3s kubectl get pods -A
k3s kubectl describe pod pod-name
k3s kubectl logs pod-name
k3s kubectl exec -it pod-name -- /bin/sh

# Or use regular kubectl (if kubeconfig is set)
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services
kubectl get ingress
kubectl get persistentvolumeclaims
kubectl get storageclass
```

### containerd Commands (via k3s)

```bash
# Via k3s binary
k3s ctr images list
k3s ctr images pull docker.io/library/nginx:latest
k3s ctr containers list
k3s ctr tasks list
k3s ctr namespaces list

# Via crictl (more user-friendly)
k3s crictl ps
k3s crictl pods
k3s crictl images
k3s crictl logs pod-id
k3s crictl inspect pod-id
k3s crictl stats
```

---

## 18. Configuration File Reference

### Server Config File

Location: `/etc/rancher/k3s/config.yaml`

```yaml
# === Cluster Configuration ===
cluster-cidr: "10.42.0.0/16"                    # Pod network CIDR
service-cidr: "10.43.0.0/16"                    # Service CIDR
cluster-dns: "10.43.0.10"                       # CoreDNS IP
cluster-domain: "cluster.local"                  # Cluster domain

# === Network Configuration ===
flannel-backend: "vxlan"                         # Flannel backend: none, host-gw, vxlan, wireguard, wireguard-native
flannel-iface: ""                                # Network interface for Flannel
disable-network-policy: false                    # Disable network policies
cluster-cidr: "10.42.0.0/16"                    # Pod CIDR
service-cidr: "10.43.0.0/16"                    # Service CIDR

# === Disable Components ===
disable:
  - traefik                                      # Disable Traefik ingress
  - servicelb                                     # Disable ServiceLB
  - metrics-server                                # Disable metrics server
  - local-storage                                 # Disable local storage
  - coredns                                       # Disable CoreDNS

# === API Server Configuration ===
kube-apiserver-arg:
  - "audit-policy-file=/etc/rancher/k3s/audit-policy.yaml"
  - "audit-log-path=/var/log/k3s/audit.log"
  - "audit-log-maxage=30"
  - "audit-log-maxbackup=10"
  - "audit-log-maxsize=100"
  - "enable-admission-plugins=NodeRestriction,PodSecurity"
  - "service-account-lookup=true"
  - "request-timeout=300s"

# === Scheduler Configuration ===
kube-scheduler-arg:
  - "profiling=false"

# === Controller Manager Configuration ===
kube-controller-manager-arg:
  - "terminated-pod-gc-threshold=100"
  - "profiling=false"

# === Kubelet Configuration ===
kubelet-arg:
  - "max-pods=200"
  - "eviction-hard=memory.available<256Mi,nodefs.available<10%"
  - "eviction-soft=memory.available<512Mi,nodefs.available<15%"
  - "eviction-soft-grace-period=memory.available=2m,nodefs.available=2m"
  - "system-reserved=cpu=200m,memory=512Mi"
  - "kube-reserved=cpu=200m,memory=512Mi"
  - "serialize-image-pulls=false"
  - "image-gc-high-threshold=85"
  - "image-gc-low-threshold=80"
  - "eviction-minimum-reclaim=imagefs.available=1Gi"
  - "container-log-max-size=50Mi"
  - "container-log-max-files=5"

# === Proxy Configuration ===
kube-proxy-arg:
  - "proxy-mode=iptables"
  - "masquerade-all=false"
  - "masquerade-bits=14"
  - "conntrack-max-per-core=32768"
  - "conntrack-tcp-timeout-established=86400"

# === TLS Configuration ===
tls-cert-file: "/etc/rancher/k3s/tls/server.crt"
tls-key-file: "/etc/rancher/k3s/tls/server.key"
cluster-ca-file: "/etc/rancher/k3s/tls/ca.crt"

# === Datastore Configuration ===
datastore-endpoint: ""                           # Empty = SQLite; "etcd" = embedded; or mysql/postgres URL
datastore-cafile: ""                             # Datastore CA file
datastore-certfile: ""                           # Datastore cert file
datastore-keyfile: ""                            # Datastore key file

# === Node Configuration ===
node-name: ""                                    # Custom node name
node-label: []                                   # Node labels
node-taint: []                                   # Node taints
node-ip: ""                                      # Node IP address

# === Agent Configuration ===
agent-token: ""                                  # Separate token for agents
token-file: ""                                   # Token file path

# === Logging ===
log: ""                                          # Log file path
v: 0                                             # Verbosity level (0-10)

# === Extra Arguments ===
extra-env: []                                    # Extra environment variables
```

### Agent Config File

Location: `/etc/rancher/k3s/config.yaml` (same structure, different fields used)

```yaml
# Agent-specific config
node-name: "worker-1"
node-label:
  - "disktype=ssd"
  - "zone=us-east-1a"
node-taint: []
node-ip: ""
server: "https://server:6443"
token: "K10..."
kubelet-arg:
  - "max-pods=200"
kube-proxy-arg:
  - "proxy-mode=iptables"
log: ""
v: 0
```

---

## 19. Environment Variables

### k3s Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `K3S_TOKEN` | Token for agent registration | Auto-generated |
| `K3S_TOKEN_FILE` | File containing the token | `/var/lib/rancher/k3s/server/token` |
| `K3S_URL` | Server URL for agents | — |
| `K3S_CLUSTER_SECRET` | Cluster secret (deprecated) | — |
| `K3S_KUBECONFIG_OUTPUT` | Output kubeconfig path | — |
| `K3S_KUBECONFIG_MODE` | Kubeconfig file permissions | — |
| `K3S_RESOLV_CONF` | Custom resolv.conf path | `/etc/resolv.conf` |
| `K3S_CERTIFICATE_AUTHORITIES` | Custom CA certificates | — |
| `K3S_DISABLE_SERVICES` | Services to disable | — |
| `K3S_DATASTORE_ENDPOINT` | Datastore endpoint | — |
| `K3S_DATASTORE_CAFILE` | Datastore CA file | — |
| `K3S_DATASTORE_CERTFILE` | Datastore cert file | — |
| `K3S_DATASTORE_KEYFILE` | Datastore key file | — |
| `K3S_FLANNEL_BACKEND` | Flannel backend | `vxlan` |
| `K3S_FLANNEL_IFACE` | Network interface for Flannel | Auto-detect |
| `K3S_FLANNEL_EXTERNAL_IP` | External IP for Flannel | — |
| `K3S_NODE_IP` | Node IP address | Auto-detect |
| `K3S_NODE_NAME` | Node hostname | `hostname` |
| `K3S_NODE_LABEL` | Node labels | — |
| `K3S_NODE_TAINT` | Node taints | — |
| `K3S_BIND_ADDRESS` | Bind address for API server | `0.0.0.0` |
| `K3S_HTTP_PROXY` | HTTP proxy | — |
| `K3S_HTTPS_PROXY` | HTTPS proxy | — |
| `K3S_NO_PROXY` | Proxy exceptions | — |
| `K3S_SYSTEM_DEFAULT_REGISTRY` | Default image registry | — |
| `K3S_DISABLE_SERVICES` | Disable built-in services | — |
| `K3S_DISABLE_AGENT` | Disable agent on server | `false` |
| `K3S_DATASTORE-cafile` | Datastore CA file | — |
| `K3S_DATASTORE-certfile` | Datastore cert file | — |
| `K3S_DATASTORE-keyfile` | Datastore key file | — |
| `K3S_DATASTORE_ENDPOINT` | Datastore connection string | — |
| `K3S_DISABLE` | Disable components | — |
| `K3S_ENABLE` | Enable features | — |

### Systemd Environment File

Location: `/etc/systemd/system/k3s.service.env` or `/etc/default/k3s`

```bash
# Example environment file
K3S_TOKEN=K10abc123...
K3S_URL=https://server:6443
K3S_NODE_NAME=worker-1
K3S_FLANNEL_IFACE=eth0
K3S_HTTP_PROXY=http://proxy:8080
K3S_NO_PROXY=localhost,127.0.0.1,10.0.0.0/8
```

---

## 20. Troubleshooting

### Common Issues and Solutions

#### 1. k3s service won't start

```bash
# Check service status
sudo systemctl status k3s

# Check logs
sudo journalctl -u k3s -n 50

# Common fix: Ensure kernel modules are loaded
sudo modprobe br_netfilter
sudo modprobe overlay

# Check sysctl
sysctl net.bridge.bridge-nf-call-iptables
# Should return 1
```

#### 2. Nodes stuck in NotReady

```bash
# Check kubelet logs
sudo journalctl -u k3s -f

# Check node conditions
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml | grep -A 5 conditions

# Common fix: Check containerd
sudo crictl ps
sudo ctr images list

# Check Flannel
kubectl get pods -n kube-system -l app=flannel
kubectl logs -n kube-system -l app=flannel
```

#### 3. Pods stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>
kubectl get events --field-selector reason=FailedScheduling

# Check node resources
kubectl top nodes
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# Check taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

#### 4. DNS resolution not working

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS from a pod
kubectl run test --image=busybox --rm -it -- nslookup kubernetes.default

# Check CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

#### 5. Service LoadBalancer not getting external IP

```bash
# Check if ServiceLB is running
kubectl get pods -n kube-system -l app=svclb

# Check service status
kubectl get svc <service-name>

# Check node IPs
kubectl get nodes -o wide

# Verify ServiceLB is not disabled
cat /etc/rancher/k3s/config.yaml | grep -i disable
```

#### 6. Storage issues (PVC stuck in Pending)

```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check StorageClass
kubectl get storageclass

# Check provisioner pods
kubectl get pods -n kube-system | grep -i local

# For Longhorn
kubectl get pods -n longhorn-system
kubectl logs -n longhorn-system -l app=longhorn-manager
```

#### 7. High memory usage

```bash
# Check memory usage per container
sudo crictl stats

# Check kubelet config
kubectl get cm kubelet -n kube-system -o yaml

# Adjust kubelet eviction thresholds
# In /etc/rancher/k3s/config.yaml
kubelet-arg:
  - "eviction-hard=memory.available<256Mi"
  - "system-reserved=cpu=200m,memory=512Mi"
```

#### 8. Container image pull failures

```bash
# Check image pull errors
kubectl describe pod <pod-name> | grep -A 5 events

# Check image pull secrets
kubectl get secrets | grep docker

# Test image pull manually
sudo crictl pull <image>

# For private registries
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

#### 9. Network connectivity between pods

```bash
# Test pod-to-pod connectivity
kubectl run test1 --image=busybox --rm -it -- ping <pod-ip>

# Check network policies
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>

# Check Flannel status
kubectl get pods -n kube-system | grep flannel
kubectl logs -n kube-system -l app=flannel

# Check iptables rules
sudo iptables -t nat -L -n | head -20
```

#### 10. k3s in LXC/Incus container crashes

```bash
# Check if /proc/sys is writable
ls -ld /proc/sys
mount | grep proc/sys

# Enable nesting on host
incus config set <container> security.nesting true

# Add kernel modules
incus config set <container> linux.kernel_modules "overlay br_netfilter ip_tables iptable_nat"

# Check kernel modules inside container
lsmod | grep -E "overlay|br_netfilter|ip_tables"

# Check kubelet logs for /proc/sys errors
sudo journalctl -u k3s | grep "proc/sys"
```

#### 11. etcd health issues

```bash
# Check etcd member status
kubectl get etcd -n kube-system

# Check etcd health
sudo k3s etcd-snapshot ls

# Check etcd logs
sudo journalctl -u k3s | grep etcd

# Compact and defragment
sudo k3s etcd-snapshot save
```

#### 12. Token issues

```bash
# View current token
sudo cat /var/lib/rancher/k3s/server/token

# Create new token
k3s token create

# List tokens
k3s token list

# Delete old tokens
k3s token delete <token>
```

#### 13. kubeconfig issues

```bash
# Check kubeconfig
cat /etc/rancher/k3s/k3s.yaml

# Regenerate kubeconfig
sudo systemctl restart k3s

# Merge with existing kubeconfig
KUBECONFIG=~/.kube/config:/etc/rancher/k3s/k3s.yaml \
  kubectl config view --merge --flatten > ~/.kube/config
```

#### 14. Slow pod scheduling

```bash
# Check scheduler logs
kubectl logs -n kube-system kube-scheduler-<node-name>

# Check pending pods
kubectl get pods --field-selector status.phase=Pending -o wide

# Check node capacity
kubectl describe nodes | grep -A 5 "Capacity:"
```

#### 15. Service iptables rules not updating

```bash
# Restart kube-proxy
kubectl rollout restart daemonset kube-proxy -n kube-system

# Check iptables
sudo iptables -t nat -L -n | grep <service-ip>

# Check kube-proxy mode
kubectl get cm kube-proxy -n kube-system -o yaml
```

#### 16. Persistent volume attach/detach issues

```bash
# Check volume attachments
kubectl get volumeattachments

# Check CSI driver
kubectl get pods -n kube-system | grep csi

# Force detach (use with caution)
kubectl delete volumeattachment <name>
```

#### 17. Ingress not routing traffic

```bash
# Check ingress resources
kubectl get ingress
kubectl describe ingress <name>

# Check Traefik/ingress controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# Test with curl
curl -v -H "Host: app.example.com" http://ingress-ip
```

#### 18. Time synchronization issues

```bash
# Check time on all nodes
date
timedatectl status

# Install chrony
sudo apt install -y chrony
sudo systemctl enable --now chrony

# Check chrony peers
chronyc peers
```

#### 19. Disk space issues

```bash
# Check disk usage
df -h

# Clean up images
sudo crictl rmi --prune

# Clean up containerd
sudo ctr images ls | wc -l
sudo ctr images ls | grep -v "sha256" | head -20

# Remove unused volumes
sudo crictl volume ls | grep -v "used"
```

#### 20. Firewall blocking k3s traffic

```bash
# Check firewall rules
sudo ufw status
sudo iptables -L -n

# Allow k3s ports
sudo ufw allow 6443/tcp
sudo ufw allow 8472/udp
sudo ufw allow 10250/tcp

# For Incus containers
sudo ufw allow in on incusbr0
```

---

## 21. Tips & Best Practices

### 1. Use a Dedicated Server for Control Plane

Don't run production workloads on your server/control plane nodes. Keep the control plane dedicated for stability and performance.

### 2. Use SSDs for etcd

etcd performance is critical. Always use SSDs for etcd storage, especially in HA clusters.

### 3. Set Resource Limits on All Pods

Always set CPU and memory limits/requests on pods to prevent resource exhaustion:

```yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "500m"
  requests:
    memory: "128Mi"
    cpu: "250m"
```

### 4. Use Namespaces for Isolation

Create namespaces for different environments and teams:

```bash
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development
```

### 5. Implement Network Policies

Deny all traffic by default and only allow what's needed:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### 6. Enable Audit Logging

Always enable audit logging in production:

```yaml
kube-apiserver-arg:
  - "audit-policy-file=/etc/rancher/k3s/audit-policy.yaml"
  - "audit-log-path=/var/log/k3s/audit.log"
  - "audit-log-maxage=30"
  - "audit-log-maxbackup=10"
```

### 7. Use Specific Image Tags

Never use `latest` tag in production:

```yaml
# Bad
image: nginx:latest

# Good
image: nginx:1.27.0
# Better
image: nginx@sha256:abc123...
```

### 8. Implement Pod Disruption Budgets

Ensure high availability during maintenance:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

### 9. Use Liveness and Readiness Probes

Detect and recover from application issues:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 3
```

### 10. Monitor Resource Usage

```bash
# Install metrics server (usually built-in)
kubectl top nodes
kubectl top pods

# Use Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 11. Regular Backups

```bash
# Daily etcd snapshot
cat <<'EOF' > /etc/cron.d/k3s-backup
0 2 * * * root /usr/local/bin/k3s etcd-snapshot save --name daily-$(date +\%Y\%m\%d)
EOF

# Retain only last 7 snapshots
sudo k3s etcd-snapshot ls | tail -n +8 | xargs -I {} sudo k3s etcd-snapshot delete --name {}
```

### 12. Use Helm for Complex Deployments

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-redis bitnami/redis --set auth.password=my-password
```

### 13. Implement Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

### 14. Use Node Affinity for Pod Placement

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: disktype
              operator: In
              values:
                - ssd
```

### 15. Keep Kubernetes Updated

```bash
# Check current version
k3s --version

# Update agent nodes
curl -sfL https://get.k3s.io | K3S_URL=https://server:6443 K3S_TOKEN=token sh -

# Update server nodes
sudo systemctl stop k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -
sudo systemctl start k3s
```

### 16. Use Labels and Selectors

Organize your workloads with labels:

```yaml
metadata:
  labels:
    app: web
    tier: frontend
    version: v1.2.3
    team: platform
    environment: production
```

### 17. Implement Logging

```bash
# View pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # Follow
kubectl logs <pod-name> --previous  # Previous container

# Aggregate logs with Loki
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack
```

---

## 22. Real-World Example

### Deploy k3s on 2 PCs with Incus + Tailscale VPN

This example matches a common homelab setup: two PCs running Incus containers, connected via Tailscale VPN.

#### Architecture

```
PC 1 (antix, 192.168.1.100)          PC 2 (secondary, 192.168.1.101)
┌────────────────────────┐            ┌────────────────────────┐
│  Incus                 │            │  Incus                 │
│  ┌──────────────────┐  │            │  ┌──────────────────┐  │
│  │ k3s-master        │  │            │  │ k3s-worker-1      │  │
│  │ (server mode)     │  │  Tailscale│  │ (agent mode)      │  │
│  │ IP: 10.0.0.1      │◄─┼──────────┼─►│ IP: 10.0.0.2      │  │
│  └──────────────────┘  │  VPN      │  └──────────────────┘  │
│  ┌──────────────────┐  │  Cloud    │  ┌──────────────────┐  │
│  │ k3s-worker-2      │  │          │  │ (future)         │  │
│  │ (agent mode)      │  │          │  └──────────────────┘  │
│  │ IP: 10.0.0.3      │  │          │                        │
│  └──────────────────┘  │            │                        │
└────────────────────────┘            └────────────────────────┘
```

#### Step 1: Create Incus Containers

```bash
# On PC 1
incus launch images:ubuntu/24.04 k3s-master --network incusbr0
incus launch images:ubuntu/24.04 k3s-worker-2 --network incusbr0

# On PC 2
incus launch images:ubuntu/24.04 k3s-worker-1 --network incusbr0

# Enable nesting for all containers
incus config set k3s-master security.nesting true
incus config set k3s-worker-1 security.nesting true
incus config set k3s-worker-2 security.nesting true

# Add kernel modules
for c in k3s-master k3s-worker-1 k3s-worker-2; do
  incus config set $c linux.kernel_modules "overlay br_netfilter ip_tables ip6_tables iptable_nat br_netfilter"
done
```

#### Step 2: Install k3s on Master

```bash
# Inside k3s-master
curl -sfL https://get.k3s.io | sh -

# Check status
sudo systemctl status k3s

# Get node token
sudo cat /var/lib/rancher/k3s/server/token
```

#### Step 3: Join Worker Nodes

```bash
# Inside k3s-worker-1
curl -sfL https://get.k3s.io | K3S_URL=https://k3s-master:6443 K3S_TOKEN="K10..." sh -

# Inside k3s-worker-2
curl -sfL https://get.k3s.io | K3S_URL=https://k3s-master:6443 K3S_TOKEN="K10..." sh -
```

#### Step 4: Set Up Tailscale VPN

```bash
# On PC 1
tailscale up --hostname=pc1

# On PC 2
tailscale up --hostname=pc2

# On k3s-master container
tailscale up --hostname=k3s-master

# Verify connectivity
tailscale status
ping 100.x.x.x  # Tailscale IP
```

#### Step 5: Configure kubeconfig

```bash
# On k3s-master
sudo cat /etc/rancher/k3s/k3s.yaml

# Copy to your workstation
scp root@k3s-master:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Edit server URL to use Tailscale IP
sed -i "s/127.0.0.1/100.x.x.x/" ~/.kube/config

# Test
kubectl get nodes
# NAME           STATUS   ROLES                  AGE     VERSION
# k3s-master     Ready    control-plane,master   5m      v1.33.0+k3s1
# k3s-worker-1   Ready    <none>                 2m      v1.33.0+k3s1
# k3s-worker-2   Ready    <none>                 1m      v1.33.0+k3s1
```

#### Step 6: Deploy Workloads

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx:1.27 --replicas=3

# Expose as LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check external IP
kubectl get svc nginx
# NAME    TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
# nginx   LoadBalancer   10.43.100.50   10.0.0.100      80:31234/TCP   5m

# Test
curl http://10.0.0.100
```

#### Step 7: Enable Tailscale Integration (Optional)

```bash
# Install Tailscale operator
helm repo add tailscale https://pkgs.tailscale.com/helm-charts
helm install tailscale tailscale/tailscale-operator \
  --namespace tailscale \
  --create-namespace \
  --set apiKey=$(tailscale apikey) \
  --set hostname=k3s-tailscale

# Create a Tailscale service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-tailscale
  annotations:
    tailscale.com/expose: "true"
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
EOF
```

---

## 23. Further Reading

### Official Documentation

- [k3s Documentation](https://docs.k3s.io/)
- [k3s GitHub](https://github.com/k3s-io/k3s)
- [k3s Releases](https://github.com/k3s-io/k3s/releases)

### Kubernetes Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Kubernetes Best Practices](https://kubernetes.io/docs/setup/best-practices/)

### Books

- *Kubernetes in Action* by Marko Lukša
- *Kubernetes Patterns* by Bilgin Ibryam and Roland Huß
- *The Kubernetes Book* by Nigel Poulton
- *Kubernetes Up & Running* by Kelsey Hightower, Brendan Burns, and Joe Beda

### Tools

- [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Kubernetes CLI
- [k9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [Helm](https://helm.sh/) - Package manager for Kubernetes
- [ArgoCD](https://argoproj.github.io/cd/) - GitOps continuous delivery
- [Flux](https://fluxcd.io/) - GitOps toolkit for Kubernetes
- [Velero](https://velero.io/) - Backup and disaster recovery

### Community

- [k3s Slack](https://k3s.io/)
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [CNCF Slack](https://cloud-native.slack.com/)

### Tutorials

- [K3s Quick Start](https://docs.k3s.io/quick-start)
- [K3s HA Setup](https://docs.k3s.io/advanced/ha)
- [K3s Air-Gapped](https://docs.k3s.io/installation/airgap)
- [K3s SELinux](https://docs.k3s.io/security/selinux)

### Videos

- [K3s YouTube Playlist](https://www.youtube.com/playlist?list=PLHm6FeJTk3zOvDSxPdNqRTKcGPIWQx)
- [Kubernetes YouTube Channel](https://www.youtube.com/kubernetesio)

---

*This guide covers k3s v1.33.x. For older or newer versions, refer to the official documentation.*

*Last updated: September 2026*
