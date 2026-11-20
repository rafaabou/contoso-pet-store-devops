# Incus — Complete Guide

> From zero to production-ready Linux containers and virtual machines.

---

## Table of Contents

1. [What Is Incus?](#1-what-is-incus)
2. [Why Use It?](#2-why-use-it)
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
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

## 1. What Is Incus?

Incus is a **system container and virtual machine manager** created by the Linux Containers project as a fork of LXD. It provides a unified interface to manage both **OS-level containers** (similar to Docker but running a full Linux distribution) and **KVM virtual machines** on a single host.

### Plain English

Imagine you have a powerful Linux server. You want to run multiple isolated Linux environments on it — maybe one for a web server, one for a database, one for a VPN — all sharing the same hardware but completely separated from each other. Incus does exactly that. It's like having 10 computers inside one physical machine, each running its own Linux OS, but with near-zero overhead.

### Why It Exists

Before Incus/LXD, you had two choices:

- **Docker**: Great for running single applications in containers, but not designed to run a full Linux OS with systemd, cron, SSH, etc.
- **KVM/QEMU**: Full virtual machines, but heavy — each VM needs its own kernel, dedicated RAM, and takes minutes to boot.

Incus sits in the middle. It gives you **containers that behave like VMs** (running a full OS with init system) using Linux kernel features like **namespaces** and **cgroups**, but with the speed and efficiency of containers.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Your Hardware                     │
├─────────────────────────────────────────────────────┤
│                   Linux Kernel                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐             │
│  │Namespaces│  │ Cgroups │  │Seccomp  │             │
│  └─────────┘  └─────────┘  └─────────┘             │
├─────────────────────────────────────────────────────┤
│                  Incus Daemon (incusd)               │
│          REST API (Unix socket + TLS)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Container│  │ Container│  │   VM     │          │
│  │  "web"   │  │  "db"    │  │ "legacy" │          │
│  │ Ubuntu   │  │ Alpine   │  │ Windows  │          │
│  └──────────┘  └──────────┘  └──────────┘          │
├─────────────────────────────────────────────────────┤
│              Storage Backends                        │
│  dir │ zfs │ btrfs │ lvm │ ceph │ powerflex        │
└─────────────────────────────────────────────────────┘
```

**Key components:**

| Component | Role |
|-----------|------|
| `incusd` | The main daemon — manages everything, exposes the API |
| `incus` | The CLI client — talks to incusd via the API |
| `incus-agent` | Runs inside VMs to provide the same interface as containers |
| `liblxc` | The underlying container runtime (Incus uses LXC under the hood) |
| Linux Kernel | Namespaces (pid, net, mnt, uts, ipc, user, cgroup), cgroups v2, seccomp |

### Incus vs LXD

Incus is a **community-driven fork** of LXD (which was owned by Canonical). Key differences:

| Aspect | LXD | Incus |
|--------|-----|-------|
| Owner | Canonical | Linux Containers (community) |
| License | Apache 2.0 + CLA | Apache 2.0, no CLA |
| API | Same v1.0 API | Same v1.0 API (compatible) |
| Future | Development may slow | Active community development |
| Snap-only | Pushed snap installs | Supports apt, snap, binary, Docker |

Incus is **API-compatible** with LXD, so most LXD documentation and tools work with Incus.

---

## 2. Why Use It?

### Use Cases

1. **Homelab Servers**: Run multiple services (Nextcloud, Plex, Pi-hole) each in isolated containers
2. **Development Environments**: Spin up fresh Ubuntu/Fedora/Alpine containers in seconds for testing
3. **Kubernetes Nodes**: Run K3s/K8s nodes as Incus containers (privileged) for cluster testing
4. **CI/CD Build Agents**: Ephemeral build environments that are destroyed after each job
5. **Network Simulation**: Multiple isolated networks for testing firewall rules, routing, DNS
6. **Legacy Application Hosting**: Run old Linux apps in their native environment without VM overhead
7. **Database Hosting**: Isolated PostgreSQL/MySQL instances with storage snapshots
8. **Multi-tenant Hosting**: Isolate different customers' workloads on shared hardware

### Pros

- **Near-native performance**: Containers share the host kernel, minimal overhead
- **Full OS experience**: Run systemd, SSH, cron — everything works as expected
- **Instant cloning**: Copy a container in seconds (copy-on-write with ZFS/Btrfs)
- **Snapshots and rollback**: Take a snapshot before risky changes, roll back instantly
- **REST API**: Everything manageable via HTTP — easy automation
- **Clustering**: Multi-node clusters for high availability
- **Storage flexibility**: ZFS, Btrfs, LVM, Ceph, directory — choose your backend
- **Image server**: Download pre-built OS images from images.linuxcontainers.org
- **Both containers AND VMs**: One tool for both use cases

### Cons

- **Not app-level isolation**: Containers share the host kernel (a kernel bug affects all containers)
- **VMs need KVM**: Hardware virtualization support required (Intel VT-x / AMD-V)
- **Steeper learning curve**: More complex than Docker for simple app deployment
- **Less ecosystem**: Fewer pre-built images and community tutorials compared to Docker
- **Root daemon**: incusd runs as root (though API access is group-controlled)
- **Not for Windows containers**: Only Linux containers and Linux/Windows VMs

### When to Use What

| Scenario | Tool |
|----------|------|
| Run a single app (API, website) | Docker |
| Run a full Linux OS (SSH, systemd) | **Incus** |
| Run Windows or legacy OS | Incus (VM mode) |
| Need rootless containers | Podman |
| Need orchestration (hundreds of containers) | Kubernetes |
| Need to test on multiple distros | **Incus** (images for 50+ distros) |

---

## 3. Installation

### Method 1: APT (Debian/Ubuntu) — Recommended

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install -y curl gnupg

# Add the Incus repository
curl -fsSL https://pkgs.ephemeralcontainers.org/key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ephemeral.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/ephemeral.gpg] https://pkgs.ephemeralcontainers.org/debian bookworm main" | sudo tee /etc/apt/sources.list.d/ephemeral.list

sudo apt-get update
sudo apt-get install -y incus

# Add your user to the incus group (log out/in after)
sudo usermod -aG incus $USER
newgrp incus
```

### Method 2: Snap (Any Linux)

```bash
sudo snap install incus --classic
sudo usermod -aG incus $USER
newgrp incus
```

### Method 3: Binary (Manual Build)

```bash
# Install Go (required)
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone and build
git clone https://github.com/lxc/incus.git
cd incus
make

# Install binaries
sudo cp bin/* /usr/local/bin/
```

### Method 4: Docker (Container-in-Container)

```bash
docker run -d \
  --name incus \
  --privileged \
  -v /dev:/dev \
  -v /var/lib/incus:/var/lib/incus \
  -p 8443:8443 \
  images:incus/daily
```

> ⚠️ Running Incus inside Docker requires `--privileged` and is recommended only for development/testing.

### Post-Installation Setup

```bash
# Initialize Incus (interactive wizard)
sudo incus admin init

# Or quick init with defaults
sudo incus admin init --auto

# Verify
incus list
# +------+-------+------+------+-----------+-----------+
# | NAME | STATE | IPV4 | IPV6 |   TYPE    | SNAPSHOTS |
# +------+-------+------+------+-----------+-----------+
# +------+-------+------+------+-----------+-----------+
```

---

## 4. Configuration

### Global Daemon Configuration

The main config file is `/etc/incus/config.yaml`:

```yaml
# /etc/incus/config.yaml
config: {}

# Network configuration
networks: []

# Storage pools
storage_pools: []

# Profiles (default settings for containers)
profiles: []
```

Most configuration is done via `incus` commands rather than editing files directly.

### Setting Global Options

```bash
# View current config
incus admin init show

# Set cluster password
incus config set core._CLUSTER_PASSWORD "mysecretpassword"

# Enable HTTPS on the API (for remote connections)
incus config set core.https_address :8443

# Set the storage backend
incus storage create default zfs

# Enable images auto-update
incus config set images.auto_update_interval 6

# Set default architecture
incus config set default.architectures "x86_64"
```

### Client Configuration

The client config lives at `~/.config/incus/config.yml`:

```yaml
# ~/.config/incus/config.yml
config:
  default:
    remote_addr: unix:/var/lib/incus/unix.socket
    auth_type: tls
remotes:
  images:
    addr: https://images.linuxcontainers.org
    protocol: simplestreams
  ubuntu:
    addr: https://cloud-images.ubuntu.com/releases
    protocol: simplestreams
```

### Environment Variables

```bash
# Disable SSL verification (development only)
export INCUS_INSECURE=false

# Set the API endpoint
export INCUS_REMOTE_ADDRESS=https://server:8443

# Set the config directory
export INCUS_CONFIG=/etc/incus

# Verbose output
export INCUS_VERBOSE=true
```

### Systemd Service Tuning

```bash
# Edit the service
sudo systemctl edit incus

# Common overrides
[Service]
LimitNOFILE=1048576
LimitNPROC=131072
LimitCORE=infinity
LimitMEMLOCK=infinity
TimeoutStartSec=300
TimeoutStopSec=300

# Restart after editing
sudo systemctl daemon-reload
sudo systemctl restart incus
```

---

## 5. Core Concepts

### Containers vs VMs in Incus

| Feature | Container | VM |
|---------|-----------|-----|
| Kernel | Shared with host | Own kernel |
| Boot time | ~1 second | ~5-15 seconds |
| Memory overhead | Minimal (MBs) | Significant (100MBs+) |
| Isolation | Namespace-based | Hardware-level |
| Performance | Near-native | Near-native (with virtio) |
| Use case | Linux workloads | Windows, legacy OS, full isolation |

### Storage Backends

| Backend | Performance | Snapshots | Cloning | Dedup | Recommended |
|---------|-------------|-----------|---------|-------|-------------|
| **ZFS** | Excellent | Yes (instant) | Yes (instant) | Yes | ✅ Best overall |
| **Btrfs** | Excellent | Yes (instant) | Yes (instant) | Yes | ✅ Great alternative |
| **LVM** | Very Good | Yes (thin prov.) | No | No | Good for speed |
| **Ceph** | Good (network) | Yes | Yes | Yes | ✅ For clusters |
| **Directory** | Slow | No | No | No | Only for testing |
| **PowerFlex** | Enterprise | Yes | Yes | Yes | Enterprise only |

### Networking

Incus creates three network types:

1. **Bridge network** (`incusbr0`): Default, NAT-based, containers get private IPs
2. **Physical network**: Pass-through to a physical NIC (for MACVLAN/bridged)
3. **Overlay network**: For multi-node clusters (VXLAN tunnels)

```
Internet
    │
    ▼
┌──────┐     ┌──────────┐
│ Router│─────│ Host NIC │
│  NAT  │     │  eth0    │
└──────┘     └─────┬────┘
                    │
              ┌─────┴────┐
              │ incusbr0 │  ← Bridge (10.195.94.0/24)
              │ Gateway  │  ← 10.195.94.1
              └─────┬────┘
           ┌────────┼────────┐
           ▼        ▼        ▼
        ┌─────┐ ┌─────┐ ┌─────┐
        │ c1  │ │ c2  │ │ c3  │
        │.2   │ │.3   │ │.4   │
        └─────┘ └─────┘ └─────┘
```

### Images

Incus uses two image protocols:

- **Simplestreams**: Standard image server (images.linuxcontainers.org) — 50+ distros
- **LXD**: Incus's own image format (for custom images)

```bash
# List available images
incus image list images: ubuntu

# Filter by architecture
incus image list images: amd64

# Filter by variant
incus image list images: ubuntu jammy
```

### Profiles

Profiles are **templates** applied to containers. The default profile includes:

- Root storage device
- Network interface (incusbr0)
- Basic resource limits

```bash
# List profiles
incus profile list

# Show default profile
incus profile show default

# Create a new profile
incus profile create gpu
incus profile set gpu devices.gpu=1
```

### Projects

Projects isolate resources within the same Incus server:

```bash
# Create a project
incus project create dev

# Switch to project
incus project switch dev

# List projects
incus project list
```

---

## 6. Usage Guide

### Starting, Stopping, and Managing Containers

```bash
# Launch a new container
incus launch images:ubuntu/jammy web-server

# Launch with specific resources
incus launch images:ubuntu/jammy web-server \
  --config limits.cpu=2 \
  --config limits.memory=2GB

# Launch with a profile
incus launch images:ubuntu/jammy web-server --profile default --profile web

# List all instances
incus list

# List with specific format
incus list --format csv
incus list --format json

# Start/stop/restart
incus start web-server
incus stop web-server
incus restart web-server

# Stop forcefully (like pulling the power)
incus stop web-server --force

# Delete permanently
incus delete web-server

# Delete with confirmation
incus delete web-server --force
```

### Executing Commands

```bash
# Run a command in a running container
incus exec web-server -- ls -la /

# Interactive shell
incus exec web-server -- /bin/bash

# Run as specific user
incus exec web-server -- sudo -u www-data -- /bin/bash

# Set environment variables
incus exec web-server --env MY_VAR=hello -- /bin/bash

# Working directory
incus exec web-server --cwd /var/www -- /bin/bash
```

### File Operations

```bash
# Push file to container
incus file push /local/path/file.txt web-server/remote/path/file.txt

# Push directory
incus file push -r /local/dir/ web-server/remote/dir/

# Pull file from container
incus file pull web-server/remote/path/file.txt /local/path/file.txt

# Edit a file
incus file edit web-server/etc/hostname

# Create a file
incus file create web-server/tmp/test.txt

# Mkdir
incus file mkdir web-server/tmp/mydir

# Read a file
incus file show web-server/etc/hostname
```

### Networking

```bash
# List networks
incus network list

# Show network details
incus network show incusbr0

# Create a custom bridge
incus network create mybr0

# Attach container to network
incus network attach mybr0 web-server eth0

# Detach container from network
incus network detach incusbr0 web-server

# Set network config
incus network set incusbr0 ipv4.address=10.0.0.1/24
incus network set incusbr0 ipv4.nat=true

# Show DHCP leases
incus network list-leases incusbr0

# Show network stats
incus network info incusbr0
```

### Storage

```bash
# List storage pools
incus storage list

# Create a ZFS pool
incus storage create zfs-pool zfs /dev/sdb

# Create a Btrfs pool
incus storage create btrfs-pool btrfs /dev/sdb

# Create a directory pool (testing only)
incus storage create dir-pool dir /data/incus

# Create a volume
incus storage volume create zfs-pool mydata

# Attach volume to container
incus storage volume attach zfs-pool mydata web-server /data

# List volumes
incus storage volume list zfs-pool

# Take a snapshot of a volume
incus storage volume snapshot create zfs-pool mydata snap1

# Restore from snapshot
incus storage volume snapshot restore zfs-pool mydata snap1
```

### Snapshots

```bash
# Take a snapshot
incus snapshot web-server snap-before-upgrade

# List snapshots
incus snapshot list web-server

# Restore a snapshot
incus snapshot restore web-server snap-before-upgrade

# Delete a snapshot
incus snapshot delete web-server snap-before-upgrade

# Create an automatic snapshot (using profiles)
incus profile create auto-snapshot
incus profile set auto-snapshot snapshots.schedule="0 3 * * *"
incus profile set auto-snapshot snapshots.pattern="auto-{%Y-%m-%d-%H%M}"
```

### Images

```bash
# Import a local image
incus image import image.tar.xz --alias myimage

# Download from Simplestreams
incus image copy images:ubuntu/jammy local: --alias ubuntu-jammy

# List local images
incus image list

# Show image info
incus image info ubuntu-jammy

# Export an image
incus image export ubuntu-jammy ./exported-image

# Delete an image
incus image delete ubuntu-jammy

# Add image server
incus remote add images https://images.linuxcontainers.org
incus remote set-url images https://images.linuxcontainers.org
```

### Clustering

```bash
# Initialize a cluster (first node)
sudo incus admin init --cluster
# Follow the interactive wizard

# Generate join token (from existing cluster)
incus cluster add node2
# Outputs: eyJ... (join token)

# Join a new node to cluster
sudo incus admin init --cluster --join-token eyJ...

# List cluster members
incus cluster list

# Show cluster info
incus cluster show node1

# Evict a node
incus cluster remove node1

# Check cluster status
incus cluster list-aliases
```

---

## 7. Advanced Features

### Device Passthrough

**GPU passthrough:**
```bash
# NVIDIA GPU
incus config device add web-server gpu GPU \
  gpuid=0 \
  nvidia=true

# Intel GPU
incus config device add web-server gpu GPU \
  gpuid=0 \
  render=/dev/dri/renderD128
```

**USB device passthrough:**
```bash
# List USB devices
lsusb

# Pass through a specific USB device
incus config device add web-server myusb usb \
  vendorid=1234 \
  productid=5678

# Pass through by bus location
incus config device add web-server myusb usb \
  bus=1 \
  port=2
```

**Disk passthrough:**
```bash
# Pass a whole disk
incus config device add web-server mydisk disk \
  source=/dev/sdb

# Pass a loopback file
truncate -s 100G /data/disk.img
incus config device add web-server mydisk disk \
  source=/data/disk.img
```

**NIC passthrough:**
```bash
# Pass a physical NIC
incus config device add web-server eth0 nic \
  nictype=physical \
  parent=eth0

# MACVLAN (share NIC, own MAC)
incus config device add web-server eth0 nic \
  nictype=macvlan \
  parent=eth0

# SR-IOV (virtual function)
incus config device add web-server eth0 nic \
  nictype=sriov \
  parent=enp0s31f6
```

### Proxy Devices (Port Forwarding)

```bash
# Forward host port to container
incus config device add web-server proxy80 proxy \
  listen=tcp:0.0.0.0:80 \
  connect=tcp:127.0.0.1:80

# Forward multiple ports
incus config device add web-server proxy80 proxy \
  listen=tcp:0.0.0.0:80 \
  connect=tcp:127.0.0.1:80
incus config device add web-server proxy443 proxy \
  listen=tcp:0.0.0.0:443 \
  connect=tcp:127.0.0.1:443

# UDP forwarding
incus config device add web-server proxydns proxy \
  listen=udp:0.0.0.0:53 \
  connect=udp:127.0.0.1:53

# NAT proxy (better performance)
incus config device add web-server proxy80 proxy \
  nat=true \
  listen=tcp:0.0.0.0:80 \
  connect=tcp:127.0.0.1:80
```

### Resource Limits

```bash
# CPU limits
incus config set web-server limits.cpu=2
incus config set web-server limits.cpu.allowance=50%    # 50% of 1 core
incus config set web-server limits.cpu.priority=5        # Priority 0-10

# Memory limits
incus config set web-server limits.memory=2GB
incus config set web-server limits.memory.swap=2GB       # Allow swap
incus config set web-server limits.memory.swap.priority=5

# Disk limits (via device)
incus config device set web-server root size=20GB

# I/O limits
incus config device set web-server root limits.read=100MB
incus config device set web-server root limits.write=50MB

# Network limits
incus config device set web-server eth0 limits.ingress=100Mbit
incus config device set web-server eth0 limits.egress=50Mbit
```

### Live Migration

```bash
# Migrate a running container to another node
incus move web-server --target node2

# Move storage as well
incus move web-server --target node2 --mode=push

# Move a virtual machine
incus move myvm --target node2
```

### API Access

```bash
# Access the REST API via curl
curl --unix-socket /var/lib/incus/unix.socket \
  -X GET \
  https://localhost/1.0

# List all instances
curl --unix-socket /var/lib/incus/unix.socket \
  https://localhost/1.0/instances

# Create an instance via API
curl --unix-socket /var/lib/incus/unix.socket \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test",
    "source": {
      "alias": "ubuntu/jammy",
      "protocol": "simplestreams",
      "server": "https://images.linuxcontainers.org"
    }
  }' \
  https://localhost/1.0/instances
```

### Web UI (Incus UI)

```bash
# Enable the web UI
incus config set core.https_address :8443

# Access at: https://your-server:8443
# Default: local authentication with TLS client certificates
```

---

## 8. Integration

### Docker Inside Incus

```bash
# Launch with Docker support
incus launch images:ubuntu/jammy docker-host \
  --config security.nesting=true \
  --config security.privileged=true

# Install Docker inside the container
incus exec docker-host -- bash -c \
  "curl -fsSL https://get.docker.com | sh"

# Verify
incus exec docker-host -- docker run hello-world
```

### Kubernetes (K3s)

```bash
# Launch a K3s node
incus launch images:ubuntu/jammy k3s-master \
  --config security.nesting=true \
  --config security.privileged=true \
  --config limits.cpu=4 \
  --config limits.memory=8GB

# Install K3s inside
incus exec k3s-master -- curl -sfL https://get.k3s.io | sh -

# Get kubeconfig
incus exec k3s-master -- cat /etc/rancher/k3s/k3s.yaml
```

### Terraform Provider

```hcl
# main.tf
terraform {
  required_providers {
    incus = {
      source = "terraform-lxd/incus"
      version = "~> 1.0"
    }
  }
}

provider "incus" {
  remote_address = "server:8443"
}

resource "incus_instance" "web" {
  name      = "web-server"
  image     = "ubuntu/jammy"
  type      = "container"
  
  limits_cpu    = 2
  limits_memory = "2GB"
  
  devices {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = "incusbr0"
    }
  }
  
  devices {
    name = "proxy80"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:80"
      connect = "tcp:127.0.0.1:80"
    }
  }
}
```

### Ansible

```yaml
# playbook.yml
- hosts: localhost
  connection: local
  tasks:
    - name: Create web container
      community.general.lxd_container:
        name: web-server
        url: https://localhost:8443
        source:
          alias: ubuntu/jammy
          protocol: simplestreams
          server: https://images.linuxcontainers.org
        type: container
        profiles:
          - default
        config:
          limits.cpu: "2"
          limits.memory: "2GB"
        devices:
          eth0:
            type: nic
            nictype: bridged
            parent: incusbr0
```

### Prometheus Monitoring

```bash
# Enable Incus metrics
incus config set metrics.authentication.prometheus=false

# Access metrics at: https://server:8443/1.0/metrics

# Prometheus config
scrape_configs:
  - job_name: 'incus'
    metrics_path: '/1.0/metrics'
    static_configs:
      - targets: ['server:8443']
```

---

## 9. Security

### TLS Client Certificates

Incus uses **TLS client certificates** for authentication:

```bash
# Generate a client certificate
incus remote add server server:8443
# Prompts to generate a trust token

# On the server, trust the fingerprint
incus cluster add-trust <fingerprint>

# View certificates
incus config trust list
```

### Security Options

```bash
# Disable nesting (default: off)
incus config set web-server security.nesting=false

# Disable privileged mode (default: off)
incus config set web-server security.privileged=false

# Enable AppArmor (default: on)
incus config set web-server security.apparmor=true

# Enable seccomp (default: on)
incus config set web-server security.seccomp=true

# Restrict specific system calls
incus config set web-server security.syscalls.deny="mount"
```

### Network Security

```bash
# Disable DNS on bridge
incus network set incusbr0 dns.mode=none

# Enable firewall on the host
sudo ufw allow in on incusbr0
sudo ufw route allow in on incusbr0

# Restrict container-to-container traffic
incus network set incusbr0 ipv4.firewall=true

# Disable IPv6
incus network set incusbr0 ipv6.address=none
```

### Best Practices

1. **Never run containers as privileged** unless absolutely required
2. **Use profiles** to standardize security settings across containers
3. **Keep images updated**: `incus image refresh`
4. **Use snapshots** before making changes
5. **Limit resources** to prevent denial-of-service
6. **Enable AppArmor** for mandatory access control
7. **Use NAT/proxy devices** instead of direct port mapping
8. **Regular backups** of `/var/lib/incus` and the database

### Backup and Recovery

```bash
# Backup the database
sudo incus admin sql local "SELECT * FROM instances" > backup-instances.sql

# Backup storage volumes
sudo zfs snapshot -r zfs-pool/incus@backup
sudo zfs send zfs-pool/incus@backup | gzip > incus-backup.gz

# Restore from backup
sudo zfs receive zfs-pool/incus < incus-backup.gz
```

---

## 10. Troubleshooting

### 1. "Error: instance not found"

```bash
# Verify the instance exists
incus list

# Check if it's in a different project
incus project list
incus project switch default
incus list
```

### 2. "Error: connection refused"

```bash
# Check if incusd is running
sudo systemctl status incus

# Restart the daemon
sudo systemctl restart incus

# Check the socket
ls -la /var/lib/incus/unix.socket
```

### 3. "Error: failed to create network"

```bash
# Check for conflicting bridges
ip link show

# Kill any conflicting dnsmasq
sudo killall dnsmasq

# Recreate the network
incus network delete incusbr0
incus network create incusbr0
```

### 4. "Error: storage backend not supported"

```bash
# Check kernel modules
lsmod | grep zfs
lsmod | grep btrfs

# Load required modules
sudo modprobe zfs
sudo modprobe btrfs

# Verify storage backend is available
incus storage info
```

### 5. "Error: cannot allocate memory"

```bash
# Check host memory
free -h

# Check cgroup memory limits
cat /sys/fs/cgroup/memory/memory.limit_in_bytes

# Kill unused containers
incus list --format csv | awk -F, '$2=="STOPPED"{print $1}' | xargs -I{} incus delete {}
```

### 6. "Error: network unreachable inside container"

```bash
# Check container network config
incus config show web-server | grep -A 20 devices

# Verify DNS
incus exec web-server -- cat /etc/resolv.conf

# Test connectivity
incus exec web-server -- ping -c 3 8.8.8.8

# Check host firewall
sudo ufw status
sudo iptables -L -n
```

### 7. "Error: disk quota exceeded"

```bash
# Check storage usage
incus storage info

# Expand storage
sudo zfs set quota=200G zfs-pool

# Or delete unused images
incus image list --format csv | awk -F, '{print $1}' | xargs -I{} incus image delete {}
```

### 8. "Error: certificate has expired"

```bash
# Regenerate client certificate
rm -f ~/.config/incus/clientcerts.crt
incus remote add server server:8443

# On server, trust new fingerprint
incus config trust list
incus cluster add-trust <new-fingerprint>
```

### 9. Container won't start after reboot

```bash
# Check autostart setting
incus config get web-server boot.autostart

# Enable autostart
incus config set web-server boot.autostart true

# Set boot priority
incus config set web-server boot.autostart.priority 10

# Check container logs
incus info web-server --show-log
```

### 10. "Error: permission denied"

```bash
# Ensure user is in incus group
groups $USER
sudo usermod -aG incus $USER
newgrp incus

# Check file permissions
ls -la /var/lib/incus/unix.socket

# Verify API access
incus info
```

### 11. Slow container startup

```bash
# Use a local image instead of downloading
incus image copy images:ubuntu/jammy local: --alias ubuntu-jammy

# Use ZFS/Btrfs for instant cloning
incus storage create fast zfs /dev/nvme0n1

# Pre-create containers
incus profile create fast-start
incus profile set fast-start boot.autostart=true
```

### 12. DNS resolution fails in container

```bash
# Check DNS config
incus exec web-server -- resolvectl status

# Force DNS server
incus exec web-server -- bash -c \
  "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"

# Set DNS on the network
incus network set incusbr0 dns.nameserver=8.8.8.8
```

### 13. Container can't reach internet

```bash
# Check NAT is enabled
incus network get incusbr0 ipv4.nat

# Enable NAT
incus network set incusbr0 ipv4.nat=true

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Enable if disabled
sudo sysctl -w net.ipv4.ip_forward=1
```

### 14. "Error: unable to connect to LXD" (API timeout)

```bash
# Check incusd logs
sudo journalctl -u incus -f

# Check resource usage
top -u root | grep incus

# Restart with debug
sudo incusd --debug
```

### 15. Cluster node won't join

```bash
# Verify node can reach the cluster
ping node1-ip

# Check firewall between nodes
sudo ufw allow 8443/tcp
sudo ufw allow 8444/tcp

# Verify join token hasn't expired
incus cluster list-tokens
```

### 16. ZFS pool not detected

```bash
# Check ZFS is installed
zpool status

# Import the pool
sudo zpool import -f zfs-pool

# Verify Incus sees it
incus storage info
```

### 17. Container networking breaks after host reboot

```bash
# Recreate the bridge
sudo systemctl restart incus

# Or manually bring it up
sudo ip link set incusbr0 up
sudo dhclient incusbr0
```

---

## 11. Tips & Best Practices

### 1. Use Profiles for Everything

Don't set container configs directly. Create profiles:

```bash
incus profile create web
incus profile set web limits.cpu=2
incus profile set web limits.memory=1GB
incus config device add web proxy80 proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
```

### 2. Launch with Resource Limits

Always set limits when launching:

```bash
incus launch images:ubuntu/jammy app \
  --config limits.cpu=2 \
  --config limits.memory=2GB
```

### 3. Use ZFS for Production

ZFS gives you instant snapshots, instant cloning, and deduplication:

```bash
incus storage create default zfs /dev/nvme0n1
incus storage set default zfs.pool_name=incus
```

### 4. Keep Images Updated

```bash
# Auto-update images daily
incus config set images.auto_update_interval 24

# Manual refresh
incus image refresh
```

### 5. Automate with Snapshots

```bash
# Take daily snapshots
incus profile create snapshots
incus profile set snapshots snapshots.schedule="@daily"
incus profile set snapshots snapshots.expiry=30d
incus profile set snapshots snapshots.pattern="daily-{%Y-%m-%d}"
```

### 6. Use Clones for Development

```bash
# Create a base image, then clone
incus snapshot web-server clean-base
incus copy web-server web-dev --instance-only
incus start web-dev
```

### 7. Monitor Resource Usage

```bash
# Real-time stats
incus info --resources

# Per-container stats
incus info web-server
```

### 8. Use Projects for Isolation

```bash
incus project create team-dev
incus project set team-dev limits.containers=20
incus project switch team-dev
```

### 9. Enable the Web UI

```bash
incus config set core.https_address :8443
# Access at https://your-server:8443
```

### 10. Use Proxy Devices for Port Forwarding

```bash
incus config device add web proxy80 proxy \
  listen=tcp:0.0.0.0:80 \
  connect=tcp:127.0.0.1:80 \
  nat=true
```

### 11. Export Logs for Debugging

```bash
# Full system info
incus info > incus-info.txt

# Container logs
incus info web-server --show-log > container-log.txt

# Daemon logs
sudo journalctl -u incus --since "1 hour ago" > daemon-log.txt
```

### 12. Use Aliases for Common Commands

```bash
# Add to ~/.bashrc
alias ll='incus list --format table'
alias lsh='incus exec'
alias lpus='incus file push'
alias lpull='incus file pull'
```

### 13. Set Up Automatic Backups

```bash
#!/bin/bash
# /usr/local/bin/incus-backup.sh
DATE=$(date +%Y-%m-%d)
sudo zfs snapshot -r zfs-pool/incus@backup-$DATE
sudo zfs send zfs-pool/incus@backup-$DATE | gzip > /backup/incus-$DATE.gz
# Keep only last 7 backups
ls -t /backup/incus-*.gz | tail -n +8 | xargs rm
```

### 14. Use `incus exec` for Scripting

```bash
# Run a script inside a container
incus exec web-server -- bash -c "
  apt-get update
  apt-get install -y nginx
  systemctl enable nginx
  systemctl start nginx
"
```

### 15. Version Pin Images

```bash
# Instead of latest, pin a specific version
incus launch images:ubuntu/22.04 web-server
# Not: incus launch images:ubuntu/jammy web-server (gets latest point release)
```

---

## 12. Commands Reference

### Instance Management

| Command | Description |
|---------|-------------|
| `incus launch <image> <name>` | Launch a new instance |
| `incus start <name>` | Start an instance |
| `incus stop <name>` | Stop an instance |
| `incus restart <name>` | Restart an instance |
| `incus delete <name>` | Delete an instance |
| `incus list` | List all instances |
| `incus show <name>` | Show instance details |
| `incus info` | Show host information |
| `incus exec <name> -- <cmd>` | Execute command in instance |
| `incus pause <name>` | Pause a running instance (VM only) |
| `incus copy <src> <dst>` | Copy/clone an instance |
| `incus move <name> --target <node>` | Migrate instance to another node |
| `incus rename <old> <new>` | Rename an instance |
| `incus freeze <name>` | Freeze (suspend) an instance |
| `incus unfreeze <name>` | Unfreeze (resume) an instance |

### Snapshot Commands

| Command | Description |
|---------|-------------|
| `incus snapshot <name> <snap-name>` | Take a snapshot |
| `incus snapshot list <name>` | List snapshots |
| `incus snapshot restore <name> <snap>` | Restore from snapshot |
| `incus snapshot delete <name> <snap>` | Delete a snapshot |
| `incus copy <name>/<snap> <new>` | Create instance from snapshot |

### File Operations

| Command | Description |
|---------|-------------|
| `incus file push <local> <remote>` | Push file to instance |
| `incus file pull <remote> <local>` | Pull file from instance |
| `incus file edit <instance>/<path>` | Edit a file |
| `incus file show <instance>/<path>` | Show file contents |
| `incus file mkdir <instance>/<path>` | Create directory |
| `incus file delete <instance>/<path>` | Delete a file |
| `incus file create <instance>/<path>` | Create an empty file |

### Network Commands

| Command | Description |
|---------|-------------|
| `incus network list` | List networks |
| `incus network show <name>` | Show network details |
| `incus network create <name>` | Create a network |
| `incus network delete <name>` | Delete a network |
| `incus network attach <net> <inst> <dev>` | Attach network to instance |
| `incus network detach <net> <inst>` | Detach network from instance |
| `incus network set <net> <key> <val>` | Set network option |
| `incus network get <net> <key>` | Get network option |
| `incus network info <net>` | Show network info |
| `incus network list-leases <net>` | List DHCP leases |

### Storage Commands

| Command | Description |
|---------|-------------|
| `incus storage list` | List storage pools |
| `incus storage show <pool>` | Show pool details |
| `incus storage create <pool> <driver> [source]` | Create a storage pool |
| `incus storage delete <pool>` | Delete a storage pool |
| `incus storage set <pool> <key> <val>` | Set storage option |
| `incus storage volume create <pool> <vol>` | Create a volume |
| `incus storage volume delete <pool> <vol>` | Delete a volume |
| `incus storage volume attach <pool> <vol> <inst> <path>` | Attach volume |
| `incus storage volume snapshot create <pool> <vol> <snap>` | Snapshot volume |

### Image Commands

| Command | Description |
|---------|-------------|
| `incus image list [remote:]` | List images |
| `incus image info <alias>` | Show image info |
| `incus image copy <remote:alias> local:` | Download an image |
| `incus image import <file> --alias <name>` | Import a local image |
| `incus image export <alias> <file>` | Export an image |
| `incus image delete <alias>` | Delete an image |
| `incus image refresh` | Update all images |
| `incus image alias create <alias> <fingerprint>` | Create an alias |
| `incus image alias delete <alias>` | Delete an alias |

### Cluster Commands

| Command | Description |
|---------|-------------|
| `incus cluster list` | List cluster members |
| `incus cluster show <member>` | Show member details |
| `incus cluster add <name>` | Generate join token |
| `incus cluster remove <name>` | Evict a member |
| `incus cluster edit <name>` | Edit member config |
| `incus cluster list-tokens` | List active join tokens |
| `incus cluster rename <old> <new>` | Rename a member |
| `incus cluster update-cert` | Update cluster certificate |

### Profile Commands

| Command | Description |
|---------|-------------|
| `incus profile list` | List profiles |
| `incus profile show <name>` | Show profile details |
| `incus profile create <name>` | Create a profile |
| `incus profile delete <name>` | Delete a profile |
| `incus profile edit <name>` | Edit a profile |
| `incus profile set <name> <key> <val>` | Set profile option |
| `incus profile get <name> <key>` | Get profile option |
| `incus profile device add <prof> <dev> <type> <args>` | Add device to profile |

### Project Commands

| Command | Description |
|---------|-------------|
| `incus project list` | List projects |
| `incus project show <name>` | Show project details |
| `incus project create <name>` | Create a project |
| `incus project delete <name>` | Delete a project |
| `incus project switch <name>` | Switch active project |
| `incus project set <name> <key> <val>` | Set project option |

### Remote Commands

| Command | Description |
|---------|-------------|
| `incus remote list` | List remotes |
| `incus remote add <name> <url>` | Add a remote |
| `incus remote remove <name>` | Remove a remote |
| `incus remote rename <old> <new>` | Rename a remote |
| `incus remote set-url <name> <url>` | Set remote URL |
| `incus remote set-default <name>` | Set default remote |

### Admin Commands

| Command | Description |
|---------|-------------|
| `incus admin init` | Initialize Incus |
| `incus admin init --auto` | Initialize with defaults |
| `incus admin init --preseed <file>` | Initialize from config |
| `incus admin shutdown` | Shutdown the daemon |
| `incus admin sql <db> <query>` | Execute SQL on database |
| `incus admin log` | View daemon logs |
| `incus admin inituge` | Initialize UEFI |

---

## 13. Configuration Reference

### Global Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `core.https_address` | string | `:8443` | API listen address |
| `core.https_proxy` | string | | HTTPS proxy |
| `core.proxy_http` | string | | HTTP proxy |
| `core.proxy_https` | string | | HTTPS proxy |
| `core.proxy_ignore_hosts` | string | | Hosts to bypass proxy |
| `core.remote_token_expiry` | int | `0` | Token expiry (seconds) |
| `core.trust_password` | string | | Trust password |
| `images.auto_update_interval` | int | `6` | Auto-update interval (hours) |
| `images.remote_cache_interval` | int | `7` | Cache refresh interval (hours) |

### Instance Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `boot.autostart` | bool | `false` | Start on host boot |
| `boot.autostart.delay` | int | `0` | Delay before start (seconds) |
| `boot.autostart.priority` | int | `0` | Start order (higher first) |
| `limits.cpu` | string | | CPU cores/threads limit |
| `limits.cpu.allowance` | string | `100%` | CPU time allowance |
| `limits.cpu.priority` | int | `0` | CPU scheduling priority |
| `limits.disk.read` | string | | Disk read IOPS limit |
| `limits.disk.write` | string | | Disk write IOPS limit |
| `limits.memory` | string | | Memory limit |
| `limits.memory.swap` | string | | Swap limit |
| `limits.memory.swap.priority` | int | `0` | Swap priority |
| `limits.network.ingress` | string | | Ingress bandwidth limit |
| `limits.network.egress` | string | | Egress bandwidth limit |
| `security.apparmor` | bool | `true` | Enable AppArmor |
| `security.nesting` | bool | `false` | Allow nested containers |
| `security.privileged` | bool | `false` | Run as privileged |
| `security.seccomp` | bool | `true` | Enable seccomp |
| `security.syscalls.allow` | string | | Allowed syscalls |
| `security.syscalls.deny` | string | | Denied syscalls |
| `snapshots.schedule` | string | | Cron schedule for snapshots |
| `snapshots.pattern` | string | `snap%d` | Snapshot name pattern |
| `snapshots.expiry` | string | | Auto-delete after (e.g. 30d) |
| `user.*` | string | | Custom user data |

### Network Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `dns.mode` | string | `managed` | DNS mode (managed/dynamic/none) |
| `dns.search` | string | | DNS search domain |
| `ipv4.address` | string | `auto` | IPv4 CIDR |
| `ipv4.dhcp` | bool | `true` | Enable DHCPv4 |
| `ipv4.dhcp.ranges` | string | | DHCP range |
| `ipv4.nat` | bool | `false` | Enable NAT |
| `ipv4.routes` | string | | Additional routes |
| `ipv6.address` | string | `auto` | IPv6 CIDR |
| `ipv6.dhcp` | bool | `true` | Enable DHCPv6 |
| `ipv6.nat` | bool | `false` | Enable IPv6 NAT |

### Storage Pool Config Options

| Key | Type | Description |
|-----|------|-------------|
| `source` | string | Block device or directory |
| `zfs.pool_name` | string | ZFS pool name |
| `zfs.clone_copy` | bool | Use ZFS clone for copies |
| `zfs.use_refquota` | bool | Use refquota instead of quota |
| `btrfs.pool_name` | string | Btrfs pool name |

### Device Types

| Type | Description |
|------|-------------|
| `disk` | Disk or directory mount |
| `nic` | Network interface |
| `proxy` | Port forwarding/proxy |
| `gpu` | GPU passthrough |
| `usb` | USB device passthrough |
| `unix-char` | Unix character device |
| `unix-block` | Unix block device |
| `tpm` | TPM device passthrough |

---

## 14. Real-World Examples

### Our 2-PC Incus Setup

We have two physical PCs on the same network, both running Incus, connected via a Tailscale VPN for remote management.

**Physical Layout:**
```
┌─────────────────────────────────────────────────────┐
│                Local Network (192.168.1.0/24)        │
│                                                     │
│  ┌──────────────────┐    ┌──────────────────┐       │
│  │   PC 1 (Master)  │    │  PC 2 (Worker)   │       │
│  │   192.168.1.10   │    │  192.168.1.20    │       │
│  │                  │    │                  │       │
│  │  incusbr0        │    │  incusbr0        │       │
│  │  10.195.94.0/24  │    │  10.195.95.0/24  │       │
│  │                  │    │                  │       │
│  │  ┌────────────┐  │    │  ┌────────────┐  │       │
│  │  │ k3s-master │  │    │  │ k3s-worker │  │       │
│  │  │ 10.195.94.2│  │    │  │ 10.195.95.2│  │       │
│  │  └────────────┘  │    │  └────────────┘  │       │
│  │  ┌────────────┐  │    │  ┌────────────┐  │       │
│  │  │ k3s-worker │  │    │  │ k3s-worker2│  │       │
│  │  │ 10.195.94.3│  │    │  │ 10.195.95.3│  │       │
│  │  └────────────┘  │    │  └────────────┘  │       │
│  └──────────────────┘    └──────────────────┘       │
│                    ▲              ▲                  │
│                    │   Tailscale  │                  │
│                    │  100.x.x.x   │                  │
│                    └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

**PC 1 (Master) Setup:**
```bash
# Install Incus
sudo apt-get install -y incus

# Initialize with ZFS storage
sudo incus admin init
# Select: zfs, /dev/nvme0n1, bridge network

# Create K3s master container
incus launch images:ubuntu/jammy k3s-master \
  --config limits.cpu=4 \
  --config limits.memory=8GB \
  --config security.nesting=true \
  --config security.privileged=true \
  --config boot.autostart=true

# Set static IP
incus network attach incusbr0 k3s-master eth0
incus config device set k3s-master eth0 ipv4.address=10.195.94.2

# Enable /proc/sys remount (K3s requirement)
incus exec k3s-master -- bash -c "
  echo '[Unit]
Description=Remount /proc/sys rw
After=local-fs.target
Before=k3s.service

[Service]
Type=oneshot
ExecStart=/bin/mount -o remount,rw /proc/sys
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/proc-sys-rw.service
  systemctl enable proc-sys-rw
"
```

**PC 2 (Worker) Setup:**
```bash
# Same Incus install and init
sudo apt-get install -y incus
sudo incus admin init

# Create K3s worker containers
incus launch images:ubuntu/jammy k3s-worker-1 \
  --config limits.cpu=2 \
  --config limits.memory=4GB \
  --config security.nesting=true \
  --config security.privileged=true \
  --config boot.autostart=true

# Set static IP
incus network attach incusbr0 k3s-worker-1 eth0
incus config device set k3s-worker-1 eth0 ipv4.address=10.195.95.2
```

### K3s Cluster with Tailscale

```bash
# On PC 1 (k3s-master)
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16

# Get the join token
sudo cat /var/lib/rancher/k3s/server/node-token

# On PC 2 (k3s-worker)
curl -sfL https://get.k3s.io | K3S_URL=https://tailscale-ip:6443 \
  K3S_TOKEN=token-from-above sh -s - agent
```

### Docker-in-Incus for CI/CD

```bash
# Create a Docker build host
incus launch images:ubuntu/jammy docker-ci \
  --config limits.cpu=8 \
  --config limits.memory=16GB \
  --config security.nesting=true \
  --config security.privileged=true

# Install Docker
incus exec docker-ci -- bash -c "
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker jenkins
"

# Set up Jenkins
incus exec docker-ci -- bash -c "
  apt-get update
  apt-get install -y jenkins
  systemctl enable jenkins
"
```

### Multi-Tenant Web Hosting

```bash
# Create a profile for web servers
incus profile create web-server
incus profile set web-server limits.cpu=2
incus profile set web-server limits.memory=1GB
incus config device add web-server proxy80 proxy \
  listen=tcp:0.0.0.0:80 \
  connect=tcp:127.0.0.1:80 \
  nat=true
incus config device add web-server proxy443 proxy \
  listen=tcp:0.0.0.0:443 \
  connect=tcp:127.0.0.1:443 \
  nat=true

# Create tenant containers
for site in site1 site2 site3; do
  incus launch images:ubuntu/jammy $site \
    --profile default \
    --profile web-server
done
```

---

## 15. Further Reading

### Official Documentation

- **Incus Documentation**: https://linuxcontainers.org/incus/docs/main/
- **Incus GitHub**: https://github.com/lxc/incus
- **Incus Forum**: https://discuss.linuxcontainers.org/
- **Image Server**: https://images.linuxcontainers.org/

### Related Projects

- **LXC**: https://linuxcontainers.org/lxc/docs/master/ (Incus's underlying container runtime)
- **LXD**: https://lxd.readthedocs.io/ (Canonical's version, API-compatible)
- **Docker**: https://docs.docker.com/ (For app-level containers)
- **KVM/QEMU**: https://www.qemu.org/ (For full VMs)
- **K3s**: https://k3s.io/ (Lightweight Kubernetes)

### Books and Tutorials

- "Linux Containers and Hypervisor" by K. Y. Srinivasa Murthy
- "Mastering Linux Virtualization" by Shashank Sahay
- Incus how-to guides: https://linuxcontainers.org/incus/docs/main/howto/

### Community Resources

- Linux Containers IRC: #linuxcontainers on OFTC
- Reddit: r/linuxcontainers
- LinuxContainers.org Wiki: https://wiki.linuxcontainers.org/

### Tools That Work With Incus

- **Terraform LXD Provider**: Infrastructure as Code for Incus
- **Ansible LXD Modules**: Automation and configuration management
- **Prometheus LXD Exporter**: Monitoring and metrics
- **Incus UI**: Web-based management interface
- **Cockpit**: System management with LXD plugin

---

*Last updated: September 2026*
