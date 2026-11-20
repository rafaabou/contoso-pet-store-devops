# Tailscale — Complete Guide

> From zero to a secure, zero-config mesh VPN in 5 minutes.

---

## Table of Contents

1. [What Is Tailscale?](#1-what-is-tailscale)
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

## 1. What Is Tailscale?

Tailscale is a **mesh VPN** built on top of **WireGuard** that connects your devices securely without the complexity of traditional VPNs. It creates a private network (your "tailnet") where every device can talk to every other device directly, encrypted end-to-end, without opening ports or configuring firewalls.

### Plain English

Imagine you have a laptop at home, a server at work, and a phone on the road. Normally, to access the work server from your laptop, you'd need to configure a VPN, set up port forwarding, deal with dynamic IPs, and fight firewalls. Tailscale eliminates all of that. Install the app, log in, and every device automatically finds each other and communicates securely — even if they're behind NATs, firewalls, or on different continents.

### Why It Exists

Traditional VPNs have several pain points:

1. **Complex setup**: Configuring WireGuard/OpenVPN requires certificates, keys, port forwarding, and networking knowledge
2. **NAT traversal**: Devices behind routers can't directly communicate without port forwarding
3. **Dynamic IPs**: Home IP addresses change, breaking static VPN configs
4. **Key management**: Exchanging and rotating WireGuard keys manually is error-prone
5. **No discovery**: You need to know every peer's IP and manage a list manually

Tailscale solves all of these by providing a **control plane** that handles key exchange, NAT traversal, and device discovery automatically. The actual data flows peer-to-peer using WireGuard — Tailscale servers never see your traffic.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Your Devices                         │
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Laptop  │  │ Server  │  │ Phone   │  │  IoT    │   │
│  │ 100.x   │  │ 100.x   │  │ 100.x   │  │ 100.x   │   │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   │
│       │             │            │             │        │
│       │    WireGuard (encrypted) │             │        │
│       └─────────────┼────────────┼─────────────┘        │
│                     │            │                      │
│              ┌──────┴────────────┴──────┐               │
│              │    Tailscale Control      │               │
│              │    (coordinates only)     │               │
│              │    + DERP relay servers   │               │
│              └──────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

**Key insight**: Tailscale servers only handle **coordination** (key exchange, discovery). The actual traffic flows **peer-to-peer** between your devices using WireGuard encryption. If a direct connection isn't possible (symmetric NAT), Tailscale falls back to **DERP** relay servers, but the traffic is still encrypted end-to-end.

### How It Works (Step by Step)

1. You install Tailscale on a device
2. You authenticate (GitHub, Google, Azure AD, etc.)
3. Tailscale assigns a **100.x.x.x** IP address (stable for the life of the device)
4. Tailscale exchanges WireGuard public keys with your other devices
5. If a direct path exists → **direct P2P connection** (fastest)
6. If behind NAT → Tailscale uses **hole punching** to establish a direct connection
7. If NAT traversal fails → **DERP relay** (still encrypted, slightly slower)

### DERP (Designated Encrypted Relay for Packets)

DERP servers are Tailscale's relay fallback. They're used when:
- Both devices are behind symmetric NAT
- A firewall blocks UDP entirely
- Direct P2P connection hasn't been established yet

DERP servers are **encrypted relay** — they forward encrypted WireGuard packets but **cannot read them**. They're in the data path only when necessary.

### Coordination Server (Control Plane)

The control server (controlplane.tailscale.com) handles:
- **Key exchange**: Distributes WireGuard public keys
- **ACL enforcement**: Checks access rules before allowing connections
- **NAT traversal**: Coordinates hole-punching attempts
- **DERP assignment**: Tells clients which DERP to use
- **Node registration**: Onboarding new devices

It never sees your data traffic — only control messages.

---

## 2. Why Use It?

### Use Cases

1. **Remote Access**: Access your home server from anywhere without port forwarding
2. **Site-to-Site VPN**: Connect office, data center, and cloud networks
3. **Developer Access**: Give team members access to staging/production servers
4. **IoT Management**: Securely manage IoT devices across locations
5. **Self-Hosting**: Expose self-hosted apps (Nextcloud, Jellyfin, GitLab) securely
6. **Multi-Cloud**: Connect AWS, GCP, Azure, and on-prem networks
7. **Database Access**: Connect to databases without exposing them publicly
8. **CI/CD**: Give build agents access to internal resources
9. **Education**: Connect school devices securely
10. **HomeLab**: Access homelab services from mobile devices

### Pros

- **Zero config**: Install and log in — it just works
- **NAT traversal**: Works without port forwarding, UPnP, or static IPs
- **WireGuard encryption**: Modern, fast, audited cryptography
- **No logs of your traffic**: Tailscale can't see what data you transmit
- **Free tier**: Up to 100 devices, 3 users — generous for homelabs
- **Cross-platform**: Linux, macOS, Windows, iOS, Android, Docker
- **ACL-based access control**: Fine-grained permissions
- **MagicDNS**: Human-readable names for every device
- **Exit nodes**: Route all traffic through a remote device
- **Subnet routers**: Expose entire networks without installing Tailscale everywhere
- **Open source client**: The client (tailscaled) is fully open source

### Cons

- **Requires internet** for initial setup (can work offline after, with DERP)
- **Traffic routed through Tailscale** for coordination (though data is P2P)
- **DERP relay adds latency** when direct connection isn't possible
- **Free tier limited**: 3 users, 100 devices (paid for more)
- **Not a full tunnel VPN**: By default, only routes 100.x.x.x traffic (exit nodes optional)
- **Control plane dependency**: If Tailscale's coordination server is down, new connections can't be established (existing P2P connections continue)
- **Not self-hosted control plane** (though Headscale is an open-source alternative)

### When to Use What

| Scenario | Tool |
|----------|------|
| Access homelab from phone | **Tailscale** |
| Full tunnel VPN for all traffic | WireGuard/OpenVPN |
| Connect offices site-to-site | **Tailscale** or WireGuard |
| Anonymous browsing | Tor, ProtonVPN |
| Self-hosted VPN | Headscale + Tailscale client |
| Simple LAN sharing | Samba, NFS (no VPN needed) |
| Encrypted P2P file transfer | Magic Wormhole |

---

## 3. Installation

### Method 1: Package Manager (Linux) — Recommended

**Debian/Ubuntu:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh

# Start the service
sudo systemctl enable --now tailscaled

# Connect to your tailnet
sudo tailscale up
# Opens browser for authentication
```

**Fedora/RHEL:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Arch Linux:**
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

### Method 2: Docker

```bash
# Run Tailscale in a container
docker run -d \
  --name=tailscale \
  --hostname=my-server \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --cap-add=SYS_MODULE \
  -v /dev/net/tun:/dev/net/tun \
  -v /var/lib/tailscale:/var/lib/tailscale \
  -e TS_AUTHKEY=tskey-auth-xxxxx \
  -e TS_STATE_DIR=/var/lib/tailscale \
  -e TS_USERSPACE=false \
  --network=host \
  tailscale/tailscale

# Get the auth key from: https://login.tailscale.com/admin/settings/keys
```

**Docker Compose:**
```yaml
version: '3'
services:
  tailscale:
    image: tailscale/tailscale
    container_name: tailscale
    hostname: my-server
    cap_add:
      - NET_ADMIN
      - NET_RAW
      - SYS_MODULE
    volumes:
      - /dev/net/tun:/dev/net/tun
      - tailscale-state:/var/lib/tailscale
    environment:
      - TS_AUTHKEY=tskey-auth-xxxxx
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
    network_mode: host
    restart: unless-stopped

volumes:
  tailscale-state:
```

### Method 3: macOS

```bash
# Download from: https://tailscale.com/download/mac
# Or use Homebrew:
brew install --cask tailscale

# Or command line only:
brew install tailscale
sudo tailscale install-system-daemon
tailscale up
```

### Method 4: Windows

Download from: https://tailscale.com/download/windows

Or use winget:
```powershell
winget install tailscale.tailscale
```

### Method 5: Mobile (iOS/Android)

- **iOS**: App Store → Search "Tailscale"
- **Android**: Play Store → Search "Tailscale"

### Method 6: Manual Binary (Any Linux)

```bash
# Download the latest
wget https://pkgs.tailscale.com/stable/tailscale_latest_amd64.tgz

# Extract
tar xzf tailscale_latest_amd64.tgz
sudo cp tailscale*/tailscale /usr/local/bin/
sudo cp tailscale*/tailscaled /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/tailscaled.service <<EOF
[Unit]
Description=Tailscale node agent
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tailscaled

# Connect
sudo tailscale up
```

### Post-Installation Verification

```bash
# Check status
tailscale status

# Check version
tailscale version

# Check IP
tailscale ip

# Check connectivity
tailscale ping <other-device>
```

---

## 4. Configuration

### The `tailscale up` Command

The main configuration happens through `tailscale up`:

```bash
# Basic usage (opens browser for auth)
sudo tailscale up

# Use an auth key (for headless/automated setups)
sudo tailscale up --authkey=tskey-auth-xxxxx

# Enable exit node
sudo tailscale up --exit-node=<node-ip>

# Use specific DNS
sudo tailscale up --accept-dns=true --accept-routes=true

# Reset configuration
sudo tailscale up --reset
```

### Key Configuration Flags

```bash
# Accept routes pushed by other nodes
sudo tailscale up --accept-routes

# Use Tailscale DNS (MagicDNS)
sudo tailscale up --accept-dns=true

# Set a custom hostname
sudo tailscale up --hostname=my-server

# Set tags (for ACL enforcement)
sudo tailscale up --advertise-tags=tag:server

# Advertise subnets
sudo tailscale up --advertise-routes=192.168.1.0/24

# Use an exit node
sudo tailscale up --exit-node=100.x.x.x

# Exit node for all traffic (full tunnel)
sudo tailscale up --exit-node=100.x.x.x --exit-node-allow-lan-access

# Disable key expiry (keep connection forever)
sudo tailscale set --key-expires=false

# Specify an auth key
sudo tailscale up --authkey=tskey-auth-xxxxx
```

### Configuration Files

**State file location:**
- Linux: `/var/lib/tailscale/tailscaled.state`
- macOS: `/Library/Application Support/Tailscale/tailscaled.state`
- Windows: `C:\ProgramData\Tailscale\tailscaled.state`

**Socket file:**
- Linux: `/var/run/tailscale/tailscaled.sock` or `/run/tailscale/tailscaled.sock`
- macOS: `/var/run/tailscale/tailscaled.sock`

**Environment variables:**
```bash
# For Docker/headless setups
TS_AUTHKEY=tskey-auth-xxxxx
TS_STATE_DIR=/var/lib/tailscale
TS_SOCKET=/var/run/tailscale/tailscaled.sock
TS_EXTRA_ARGS=--advertise-routes=192.168.1.0/24
TS_USERSPACE=false
TS_ACCEPT_DNS=true
TS_ACCEPT_ROUTES=true
```

### Systemd Service Options

```bash
# Edit the service
sudo systemctl edit tailscaled

# Common overrides:
[Service]
ExecStart=
ExecStart=/usr/sbin/tailscaled \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/run/tailscale/tailscaled.sock \
  --port=41641/udp \
  --verbose=1
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576
```

---

## 5. Core Concepts

### Tailnet

Your private network. Every device you connect to Tailscale becomes part of your **tailnet**. Devices are identified by:

- **Tailscale IP**: 100.x.x.x.x (unique, stable)
- **MagicDNS name**: my-device.tail1234.ts.net (human-readable)
- **Machine name**: Derived from hostname

### Nodes

A **node** is any device on your tailnet. Nodes can be:

| Type | Role |
|------|------|
| Regular node | Default, can connect to any peer |
| Exit node | Routes all internet traffic through itself |
| Subnet router | Exposes a local network to the tailnet |
| Relay node (DERP) | Relays traffic when direct connection fails |

### ACLs (Access Control Lists)

ACLs define **who can access what**. They're configured in the Tailscale admin console:

```json
{
  "ACLs": [
    {
      // Allow all users to access all devices
      "Action": "accept",
      "Users": ["*"],
      "Ports": ["*:*"]
    }
  ],
  "TagOwners": {
    "tag:server": ["group:admin"],
    "tag:dev": ["group:developers"]
  }
}
```

### Auth Keys

Used for automated/headless authentication:

```bash
# Generate an auth key in the admin console
# https://login.tailscale.com/admin/settings/keys

# Use it
sudo tailscale up --authkey=tskey-auth-xxxxx

# Reusable key (can be used multiple times)
sudo tailscale up --authkey=tskey-auth-xxxxx?reusable=true

# Ephemeral key (removed after disconnect)
sudo tailscale up --authkey=tskey-auth-xxxxx?ephemeral=true

# Pre-approved key (skip ACL approval)
sudo tailscale up --authkey=tskey-auth-xxxxx?preauthorized=true
```

### MagicDNS

Automatic DNS for your tailnet:

```
my-laptop.tail1234.ts.net    → 100.x.x.1
my-server.tail1234.ts.net    → 100.x.x.2
my-phone.tail1234.ts.net     → 100.x.x.3
```

### Exit Nodes

When a device is an exit node, other devices can route ALL their internet traffic through it:

```
Phone (on 4G) → Exit Node (home server) → Internet
All traffic encrypted, appears to come from home IP
```

### Subnet Routers

Expose an entire local network to the tailnet without installing Tailscale on every device:

```
Tailnet device → Subnet Router → 192.168.1.0/24 (office LAN)
```

### Key Expiry

By default, machine keys expire after **180 days**. Expired devices must re-authenticate. You can disable expiry for trusted devices.

---

## 6. Usage Guide

### Connecting a Device

```bash
# Linux (first time)
sudo tailscale up
# Browser opens, authenticate with your identity provider

# Headless/automated
sudo tailscale up --authkey=tskey-auth-xxxxx

# Check you're connected
tailscale status
# my-laptop     user@      linux   -
# my-server     user@      linux   -
```

### Accessing a Remote Device

```bash
# By Tailscale IP
ssh user@100.x.x.x

# By MagicDNS name
ssh user@my-server.tail1234.ts.net

# Using the web browser
# Open: http://100.x.x.x:8080
```

### Checking Connectivity

```bash
# Ping another device
tailscale ping my-server

# Detailed status
tailscale status

# Show your IP
tailscale ip
tailscale ip -4  # IPv4 only
tailscale ip -6  # IPv6 only

# Check connection quality
tailscale ping --verbose my-server
```

### Managing Your Device

```bash
# Change hostname
tailscale set --hostname=new-name

# Disconnect
sudo tailscale down

# Reconnect
sudo tailscale up

# Logout completely
sudo tailscale logout

# Show detailed status
tailscale status --json
```

### File Sharing (Taildrop)

```bash
# Send a file to another device
tailscale file cp myfile.txt my-server:

# Receive files
tailscale file get /path/to/receive/
```

### Using as an Exit Node

```bash
# On the device that will be the exit node
sudo tailscale up --advertise-exit-node

# Approve in admin console:
# https://login.tailscale.com/admin/machines → Edit → Use as exit node

# On the client device
sudo tailscale up --exit-node=my-server.tail1234.ts.net

# Verify
tailscale status  # Shows "exit node" flag
curl ifconfig.me  # Shows the exit node's IP
```

### Subnet Routing

```bash
# On the router device
sudo tailscale up --advertise-routes=192.168.1.0/24

# Approve in admin console
# https://login.tailscale.com/admin/machines → Edit routes

# From a tailnet device, access 192.168.1.x directly
```

### SSH via Tailscale

```bash
# Tailscale provides Tailscale SSH (no keys needed)
# On the server, enable Tailscale SSH:
sudo tailscale up --ssh

# From client
tailscale ssh my-server
# Authenticates via your Tailscale identity, no SSH keys needed
```

### Serving a Local Service

```bash
# Expose a local port to the tailnet
tailscale serve --bg 8080

# Expose with a specific path
tailscale serve --bg /api http://localhost:3000

# List active serves
tailscale serve status

# Stop serving
tailscale serve --remove
```

### Funnel (Public Access)

```bash
# Expose a local service to the internet
tailscale funnel --bg 8080

# Access at: https://your-machine.tail1234.ts.net
# This is publicly accessible (not just tailnet)
```

---

## 7. Advanced Features

### Tailscale Funnel

Funnel exposes a local service to the public internet:

```bash
# Expose port 8080
tailscale funnel --bg 8080

# The service is available at:
# https://your-machine.tail1234.ts.net

# Behind the scenes:
# - TLS certificate provisioned automatically
# - Traffic routed through Tailscale's edge
# - Local firewall not touched
```

### Tailscale SSH

Passwordless, keyless SSH using your Tailscale identity:

```bash
# Enable on the server
sudo tailscale up --ssh

# Connect from client
tailscale ssh user@my-server

# Works with:
# - GitHub/Azure AD/Google identity
# - No SSH keys to manage
# - Audit log in admin console
```

### TCP Relay (WireGuard over TCP)

When UDP is blocked (corporate firewalls):

```bash
# Force TCP relay
sudo tailscale up --transport-protocol=tcp

# Or use a specific port
sudo tailscale up --port=443/udp
```

### Custom DERP Servers

Run your own relay servers for privacy:

```bash
# Run a DERP server
docker run -d \
  --name=derp \
  -p 8080:8080 \
  -p 8080:8080/udp \
  -v /etc/derp:/etc/derp \
  tailscale/derper \
  --hostname=derp.example.com \
  --certmode=manual \
  --certfile=/etc/derp/cert.pem \
  --certkey=/etc/derp/key.pem

# In admin console, add your DERP:
# Settings →DERP Map → Add server
```

### Use Your Own Domain

```bash
# In admin console:
# Settings → MagicDNS → Add domain

# Then your devices are accessible at:
# my-server.yourdomain.com
```

### Kubernetes Operator

```bash
# Install via Helm
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm install tailscale-operator tailscale/tailscale-operator

# Expose a service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    tailscale.com/hostname: my-service
spec:
  selector:
    app: my-service
  ports:
    - port: 80
      targetPort: 8080
EOF
```

### Container NAT Mode

Run Tailscale inside a Docker container with NAT:

```yaml
# docker-compose.yml
services:
  app:
    image: my-app
    network_mode: service:tailscale
  tailscale:
    image: tailscale/tailscale
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - /dev/net/tun:/dev/net/tun
      - tailscale-state:/var/lib/tailscale
    environment:
      - TS_AUTHKEY=tskey-auth-xxxxx
      - TS_STATE_DIR=/var/lib/tailscale
    # app uses tailscale's network stack
```

### Monitoring

```bash
# Prometheus metrics (enable in admin console)
# http://100.x.x.x:9001/metrics

# Key metrics:
# tailscale_nodes_total
# tailscale_connected_nodes
# tailscale_bytes_sent
# tailscale_bytes_received
# tailscale DERP_relayed_bytes
```

---

## 8. Integration

### With Incus

```bash
# Install Tailscale in an Incus container
incus launch images:ubuntu/jammy tailscale-node \
  --config security.nesting=true \
  --config security.privileged=true

incus exec tailscale-node -- bash -c \
  "curl -fsSL https://tailscale.com/install.sh | sh"

incus exec tailscale-node -- tailscale up --authkey=tskey-auth-xxxxx

# The container now has a 100.x.x.x address
```

### With K3s

```bash
# Install Tailscale on the K3s node
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=tskey-auth-xxxxx --hostname=k3s-node

# K3s can use Tailscale IP for cluster communication
curl -sfL https://get.k3s.io | K3S_URL=https://tailscale-ip:6443 K3S_TOKEN=xxx sh -s - server
```

### With Docker Compose

```yaml
version: '3.8'
services:
  tailscale:
    image: tailscale/tailscale
    container_name: ts-proxy
    hostname: proxy-server
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - /dev/net/tun:/dev/net/tun
      - ts-state:/var/lib/tailscale
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
    restart: unless-stopped
    network_mode: host

  nginx:
    image: nginx
    ports:
      - "80:80"
    # Use tailscale's network
    network_mode: service:tailscale

volumes:
  ts-state:
```

### With Prometheus + Grafana

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'tailscale'
    static_configs:
      - targets: ['tailscale-node:9001']
    metrics_path: /metrics
```

### With Terraform

```hcl
# Using tailscale provider
terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.15"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = "your-tailnet"
}

resource "tailscale_acl" "acl" {
  acl = jsonencode({
    ACLs = [
      {
        Action = "accept"
        Users  = ["*"]
        Ports  = ["*:*"]
      }
    ]
  })
}

resource "tailscale_device_key" "server" {
  device_id = "server-device-id"
  key_expiry_disabled = true
}
```

### With Ansible

```yaml
# playbook.yml
- hosts: all
  become: yes
  tasks:
    - name: Install Tailscale
      shell: curl -fsSL https://tailscale.com/install.sh | sh

    - name: Start Tailscale
      systemd:
        name: tailscaled
        state: started
        enabled: yes

    - name: Join tailnet
      command: tailscale up --authkey={{ tailscale_authkey }}
      args:
        creates: /var/lib/tailscale/tailscaled.state
```

---

## 9. Security

### WireGuard Encryption

- All data flows are encrypted with **Noise protocol** (ChaCha20-Poly1305)
- Keys are rotated automatically every ~2 minutes
- Forward secrecy: compromised key doesn't expose past traffic
- Quantum-resistant: Tailscale uses a hybrid approach with post-quantum algorithms

### Access Control (ACLs)

```json
{
  "ACLs": [
    {
      // Developers can access dev servers
      "Action": "accept",
      "Users": ["group:developers"],
      "Ports": ["tag:dev:*"]
    },
    {
      // Admins can access everything
      "Action": "accept",
      "Users": ["group:admin"],
      "Ports": ["*:*"]
    },
    {
      // Block specific access
      "Action": "drop",
      "Users": ["group:everyone"],
      "Ports": ["tag:production:22"]
    }
  ],
  "TagOwners": {
    "tag:server": ["group:admin"],
    "tag:dev": ["group:developers"],
    "tag:production": ["group:admin"]
  },
  "Groups": {
    "group:admin": ["alice@company.com", "bob@company.com"],
    "group:developers": ["dev1@company.com", "dev2@company.com"],
    "group:everyone": ["everyone"]
  },
  "Hosts": {
    "reserved-ports": ["production-db:3306"]
  }
}
```

### Key Expiry

```bash
# Keys expire after 180 days by default
# Disable for trusted servers
tailscale set --key-expires=false

# Re-enable expiry
tailscale set --key-expires=true
```

### Device Approval

```bash
# Require admin approval for new devices
# Admin console → Settings → Device approval → Enable

# Pre-approve a device
tailscale up --authkey=tskey-auth-xxxxx?preauthorized=true
```

### Tailscale SSH Security

```bash
# Tailscale SSH authenticates via your identity provider
# No SSH keys to manage
# Audit trail in admin console
# Works with:
# - GitHub SSO
# - Google Workspace
# - Azure AD
# - Okta
# - OIDC providers
```

### Audit Logging

```bash
# Enable in admin console:
# Settings → Logging → Enable audit logging

# Logs include:
# - Device registration
# - Key rotations
# - ACL changes
# - SSH connections
# - Funnel/serve changes
```

### Best Practices

1. **Use auth keys for automated setups** — not interactive login
2. **Set key expiry on untrusted devices**
3. **Use ACLs** — don't rely on default "allow all"
4. **Tag devices** — group by function for ACL rules
5. **Enable device approval** in production
6. **Monitor SSH access** via audit logs
7. **Rotate auth keys** regularly
8. **Use ephemeral keys** for CI/CD
9. **Disable exit nodes** unless explicitly needed
10. **Review ACLs** periodically

---

## 10. Troubleshooting

### 1. "Not logged in" / "No state found"

```bash
# Check status
tailscale status

# If not logged in
sudo tailscale up

# If using auth key
sudo tailscale up --authkey=tskey-auth-xxxxx

# Check state file
ls -la /var/lib/tailscale/tailscaled.state
```

### 2. "Can't reach peer" / "Ping timeout"

```bash
# Check connectivity
tailscale ping <peer-ip>

# Check DERP relay status
tailscale netcheck

# Check if direct connection is possible
tailscale ping --verbose <peer-ip>

# If behind symmetric NAT, DERP relay is used
# Check DERP usage in status output
```

### 3. "DNS not resolving MagicDNS names"

```bash
# Check DNS config
tailscale dns status

# Enable MagicDNS
sudo tailscale up --accept-dns=true

# Check resolv.conf
cat /etc/resolv.conf
# Should contain: nameserver 100.x.x.x (Tailscale DNS)

# If not, manually set
sudo resolvectl dns tailscale0 100.100.100.100
```

### 4. "Tailscale not starting"

```bash
# Check service status
sudo systemctl status tailscaled

# Check logs
sudo journalctl -u tailscaled -f

# Restart
sudo systemctl restart tailscaled

# Check for kernel module issues
lsmod | grep wireguard
sudo modprobe wireguard
```

### 5. "Permission denied" / "No such file or directory"

```bash
# Check socket exists
ls -la /var/run/tailscale/tailscaled.sock

# Restart to recreate socket
sudo systemctl restart tailscaled

# Check permissions
groups $USER
# Should include "tailscale" group
sudo usermod -aG tailscale $USER
newgrp tailscale
```

### 6. "Docker container can't connect"

```bash
# Ensure NET_ADMIN capability
docker run --cap-add=NET_ADMIN ...

# Check /dev/net/tun exists
ls -la /dev/net/tun
# If missing: sudo mkdir -p /dev/net && sudo mknod /dev/net/tun c 10 200

# Check TS_USERSPACE
docker run -e TS_USERSPACE=false ...
```

### 7. "High latency / slow connection"

```bash
# Check if using DERP relay
tailscale ping <peer-ip>
# "direct" = good, "derp" = relayed

# Try forcing direct connection
tailscale set --derp=direct

# Check network quality
tailscale ping --verbose <peer-ip>

# If both on same LAN, ensure direct connection
# Check: tailscale status shows "direct" not "relay"
```

### 8. "Exit node not working"

```bash
# On exit node device
tailscale up --advertise-exit-node

# Approve in admin console
# https://login.tailscale.com/admin/machines

# On client
tailscale up --exit-node=<exit-node-ip>

# Verify
tailscale status  # Should show "exit: <node>" flag
curl ifconfig.me  # Should show exit node's IP
```

### 9. "Subnet routes not accessible"

```bash
# Advertise routes
sudo tailscale up --advertise-routes=192.168.1.0/24

# Approve in admin console
# https://login.tailscale.com/admin/machines → Edit → Routes

# On client, accept routes
sudo tailscale up --accept-routes

# Check route is available
ip route | grep 192.168.1
```

### 10. "Authentication failed"

```bash
# Check auth key is valid
# https://login.tailscale.com/admin/settings/keys

# Use a fresh key
sudo tailscale up --authkey=tskey-auth-NEWKEY

# Check key hasn't expired
tailscale status
# Look for "key expiry" field
```

### 11. "Tailscale SSH not working"

```bash
# Enable SSH on server
sudo tailscale up --ssh

# Check ACL allows SSH
# In admin console, ensure ACL has SSH rule

# Connect
tailscale ssh user@server

# If "Permission denied", check ACL
tailscale status --json | grep -i ssh
```

### 12. "Funnel not accessible"

```bash
# Enable funnel
tailscale funnel --bg 8080

# Check TLS cert is provisioned
tailscale serve status

# Access at: https://your-machine.tail1234.ts.net
# Check DNS resolves correctly
```

### 13. "Subnet router not working"

```bash
# On router device
sudo tailscale up --advertise-routes=10.0.0.0/24

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
# Make persistent
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# Approve routes in admin console
```

### 14. "Tailscale inside Docker can't reach host"

```bash
# Use --network=host
docker run --network=host tailscale/tailscale

# Or add route to host network
docker run --add-host=host.docker.internal:host-gateway ...
```

### 15. "tailscaled won't start after reboot"

```bash
# Check systemd status
sudo systemctl status tailscaled

# Check if state file exists
ls -la /var/lib/tailscale/tailscaled.state

# If corrupted, re-authenticate
sudo tailscale down
sudo tailscale up

# Check for competing instances
ps aux | grep tailscale
sudo killall tailscaled
```

---

## 11. Tips & Best Practices

### 1. Use Auth Keys for Automation

```bash
# Generate reusable, pre-approved keys
# https://login.tailscale.com/admin/settings/keys

# Use in scripts
sudo tailscale up --authkey=tskey-auth-xxxxx

# Use in Docker
docker run -e TS_AUTHKEY=tskey-auth-xxxxx ...
```

### 2. Disable Key Expiry for Servers

```bash
# Servers should stay connected permanently
tailscale set --key-expires=false
```

### 3. Use Tags for ACL Management

```json
{
  "TagOwners": {
    "tag:server": ["group:admin"],
    "tag:dev": ["group:developers"],
    "tag:staging": ["group:developers"]
  }
}
```

### 4. Use Exit Nodes for Remote Access

```bash
# On home server (exit node)
sudo tailscale up --advertise-exit-node

# On laptop (client)
sudo tailscale up --exit-node=home-server
# All traffic now routes through home
```

### 5. Use Subnet Routers for Legacy Devices

```bash
# Don't install Tailscale on every old device
# Use a subnet router to expose the network
sudo tailscale up --advertise-routes=192.168.1.0/24
```

### 6. Use Tailscale SSH Instead of Keys

```bash
# On server
sudo tailscale up --ssh

# From client
tailscale ssh user@server
# No SSH keys to manage, authenticated via SSO
```

### 7. Use MagicDNS for Everything

```bash
# Enable MagicDNS
sudo tailscale up --accept-dns=true

# Access devices by name
ssh user@my-server
curl http://my-webapp:8080
```

### 8. Use Funnel for Public Services

```bash
# Expose a local service publicly
tailscale funnel --bg 8080
# Available at: https://your-machine.tail1234.ts.net
```

### 9. Monitor with Prometheus

```bash
# Enable metrics endpoint in admin console
# http://100.x.x.x:9001/metrics

# Key metrics to watch:
# - tailscale_connected_nodes
# - tailscale_bytes_sent/received
# - tailscale DERP_relayed_bytes (should be low)
```

### 10. Use Docker Compose for Multi-Container

```yaml
# Share Tailscale network between containers
services:
  tailscale:
    image: tailscale/tailscale
    cap_add: [NET_ADMIN]
    volumes: [/dev/net/tun:/dev/net/tun, ts-state:/var/lib/tailscale]
    environment: [TS_AUTHKEY=${AUTHKEY}]
  app:
    image: my-app
    network_mode: service:tailscale
```

### 11. Regular Key Rotation

```bash
# Tailscale automatically rotates WireGuard keys every ~2 minutes
# Machine keys expire after 180 days
# Monitor expiry in admin console
```

### 12. Use `tailscale status` as First Debug Step

```bash
# Shows all devices, their IPs, connection type (direct/relay)
tailscale status

# Detailed JSON
tailscale status --json
```

### 13. Test Connectivity

```bash
# Quick test
tailscale ping <device>

# Detailed test
tailscale ping --verbose <device>

# Check network quality
tailscale netcheck
```

### 14. Use Auth Key Expiry for CI/CD

```bash
# Ephemeral keys auto-remove device when it disconnects
sudo tailscale up --authkey=tskey-auth-xxxxx?ephemeral=true

# Good for CI runners that are destroyed after each job
```

### 15. Keep Tailscale Updated

```bash
# Check version
tailscale version

# Update (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install tailscale

# Or
curl -fsSL https://tailscale.com/install.sh | sh
```

---

## 12. Commands Reference

### Core Commands

| Command | Description |
|---------|-------------|
| `tailscale up [flags]` | Connect to tailnet |
| `tailscale down` | Disconnect from tailnet |
| `tailscale logout` | Logout and remove state |
| `tailscale status` | Show connection status |
| `tailscale status --json` | JSON output |
| `tailscale ip` | Show Tailscale IP |
| `tailscale ip -4` | Show IPv4 address |
| `tailscale ip -6` | Show IPv6 address |
| `tailscale version` | Show version |
| `tailscale ping <host>` | Ping a peer |
| `tailscale ping --verbose <host>` | Verbose ping |
| `tailscale netcheck` | Check network conditions |
| `tailscale dns status` | Show DNS configuration |
| `tailscale set [flags]` | Set configuration |

### `tailscale up` Flags

| Flag | Description |
|------|-------------|
| `--authkey=<key>` | Use an auth key |
| `--hostname=<name>` | Set hostname |
| `--advertise-routes=<cidr>` | Advertise subnet routes |
| `--advertise-exit-node` | Offer as exit node |
| `--exit-node=<ip>` | Use an exit node |
| `--exit-node-allow-lan-access` | Allow LAN access through exit node |
| `--accept-routes` | Accept routes from peers |
| `--accept-dns` | Use Tailscale DNS |
| `--ssh` | Enable Tailscale SSH |
| `--reset` | Reset configuration |
| `--timeout=<dur>` | Connection timeout |
| `--stateful-filtering` | Enable stateful filtering |
| `--derp=<uri>` | Control DERP usage |
| `--transport-protocol=<proto>` | Force TCP or UDP |

### `tailscale set` Flags

| Flag | Description |
|------|-------------|
| `--hostname=<name>` | Set hostname |
| `--advertise-routes=<cidr>` | Advertise routes |
| `--advertise-exit-node` | Offer as exit node |
| `--exit-node=<ip>` | Use exit node |
| `--accept-routes` | Accept routes |
| `--accept-dns` | Accept DNS |
| `--ssh` | Enable/disable SSH |
| `--key-expires` | Enable/disable key expiry |
| `--log-timeout` | Log timeout |
| `--posture-checking` | Enable posture checks |
| `--auto-update` | Enable auto-updates |

### File Operations (Taildrop)

| Command | Description |
|---------|-------------|
| `tailscale file cp <src> <dest>:` | Send file to peer |
| `tailscale file get <dir>` | Receive files |

### Serve Commands

| Command | Description |
|---------|-------------|
| `tailscale serve --bg <port>` | Serve a local port |
| `tailscale serve --bg /path http://host:port` | Serve specific path |
| `tailscale serve status` | List active serves |
| `tailscale serve --remove` | Stop serving |
| `tailscale funnel --bg <port>` | Publicly serve a port |

### Debug Commands

| Command | Description |
|---------|-------------|
| `tailscale bugreport` | Generate debug report |
| `tailscale metrics` | Show Prometheus metrics |
| `tailscale debug prefs` | Show preferences |
| `tailscale debug peers` | Show peer info |

---

## 13. Configuration Reference

### Global Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `hostname` | string | System hostname | Device hostname on tailnet |
| `advertise-routes` | string | | Subnet routes to advertise |
| `advertise-exit-node` | bool | `false` | Offer as exit node |
| `exit-node` | string | | Exit node IP to use |
| `accept-routes` | bool | `false` | Accept routes from peers |
| `accept-dns` | bool | `false` | Use Tailscale DNS |
| `ssh` | bool | `false` | Enable Tailscale SSH |
| `key-expires` | bool | `true` | Machine key expiry |
| `auto-update` | bool | `true` | Auto-update tailscale |
| `log-timeout` | duration | `720h` | Log retention |

### Auth Key Parameters

| Parameter | Description |
|-----------|-------------|
| `reusable` | Can be used by multiple devices |
| `ephemeral` | Removed after disconnect |
| `preauthorized` | Skip ACL approval |
| `expiry` | Expiry duration (e.g. `24h`) |
| `tags` | Tags to apply |
| `csrf` | CSRF protection |

### Environment Variables (Docker)

| Variable | Description |
|----------|-------------|
| `TS_AUTHKEY` | Auth key for authentication |
| `TS_STATE_DIR` | State directory path |
| `TS_SOCKET` | Socket file path |
| `TS_USERSPACE` | Use userspace networking |
| `TS_ACCEPT_DNS` | Accept Tailscale DNS |
| `TS_ACCEPT_ROUTES` | Accept routes from peers |
| `TS_ADVERTISE_ROUTES` | Routes to advertise |
| `TS_ADVERTISE_EXIT_NODE` | Advertise as exit node |
| `TS_EXIT_NODE` | Use specified exit node |
| `TS_HOSTNAME` | Set hostname |
| `TS_EXTRA_ARGS` | Additional flags for `tailscale up` |
| `TS_LOG` | Log target (stdout, syslog) |

### ACL Syntax

```json
{
  "ACLs": [
    {
      "Action": "accept" | "drop",
      "Users": ["user@domain.com", "group:name", "*"],
      "Ports": ["tag:name:port", "ip:port", "*:*"]
    }
  ],
  "Groups": {
    "group:name": ["user@domain.com"]
  },
  "TagOwners": {
    "tag:name": ["user@domain.com", "group:name"]
  },
  "Hosts": {
    "name": ["ip:port"]
  },
  "DERPMap": {
    "Regions": {...}
  },
  "NodeAttrs": [
    {
      "Target": ["tag:name"],
      "Attr": ["advertise-exit-node"]
    }
  ],
  "SSH": [
    {
      "Action": "accept",
      "Users": ["group:admin"],
      "BareNames": ["*"],
      "Principals": ["root"],
      "CheckPeriod": "24h"
    }
  ]
}
```

### Network Configuration

| Setting | Description |
|---------|-------------|
| Direct connections | P2P WireGuard (fastest) |
| DERP relay | Encrypted relay (fallback) |
| TCP relay | WireGuard over TCP (firewall bypass) |
| UDP port | Default 41641/udp |
| Subnet routing | Expose local networks |
| Exit nodes | Route all traffic |

---

## 14. Real-World Examples

### Our 2-PC Setup with Incus + Tailscale

We have two physical PCs:

1. **PC 1 (Master)**: Runs Incus with K3s master container
2. **PC 2 (Worker)**: Runs Incus with K3s worker containers

Both are connected via **Tailscale** for remote access and cluster communication.

```
┌──────────────────────────────────────────────────────────────┐
│                     Tailscale Tailnet                         │
│                                                              │
│  ┌────────────────────────┐    ┌────────────────────────┐    │
│  │   PC 1 (antix)         │    │   PC 2                 │    │
│  │   Tailscale: 100.x.x.1 │    │   Tailscale: 100.x.x.2│    │
│  │                        │    │                        │    │
│  │   Incus:               │    │   Incus:               │    │
│  │   ┌──────────────────┐ │    │   ┌──────────────────┐ │    │
│  │   │ incusbr0         │ │    │   │ incusbr0         │ │    │
│  │   │ 10.195.94.0/24   │ │    │   │ 10.195.95.0/24   │ │    │
│  │   │                  │ │    │   │                  │ │    │
│  │   │ ┌──────────────┐ │ │    │   │ ┌──────────────┐ │ │    │
│  │   │ │ k3s-master   │ │ │    │   │ │ k3s-worker-1 │ │ │    │
│  │   │ │ 10.195.94.2  │ │ │    │   │ │ 10.195.95.2  │ │ │    │
│  │   │ └──────────────┘ │ │    │   │ └──────────────┘ │ │    │
│  │   │ ┌──────────────┐ │ │    │   │ ┌──────────────┐ │ │    │
│  │   │ │ k3s-worker-1 │ │ │    │   │ │ k3s-worker-2 │ │ │    │
│  │   │ │ 10.195.94.3  │ │ │    │   │ │ 10.195.95.3  │ │ │    │
│  │   │ └──────────────┘ │ │    │   │ └──────────────┘ │ │    │
│  │   └──────────────────┘ │    │   └──────────────────┘ │    │
│  └────────────────────────┘    └────────────────────────┘    │
│                                                              │
│  From Phone (4G):                                            │
│  ssh user@antix (100.x.x.1) → PC 1                         │
│  kubectl → 100.x.x.1:6443 → K3s cluster                    │
│  http://100.x.x.1:8080 → Incus Web UI                       │
└──────────────────────────────────────────────────────────────┘
```

**PC 1 (Master) — Complete Setup:**

```bash
# 1. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=antix --authkey=tskey-auth-xxx

# 2. Install Incus
sudo apt-get install -y incus
sudo usermod -aG incus $USER
newgrp incus

# 3. Initialize Incus
sudo incus admin init
# Select: ZFS storage, default bridge

# 4. Create K3s master
incus launch images:ubuntu/jammy k3s-master \
  --config limits.cpu=4 \
  --config limits.memory=8GB \
  --config security.nesting=true \
  --config security.privileged=true \
  --config boot.autostart=true

# 5. Set static IP
incus network attach incusbr0 k3s-master eth0
incus config device set k3s-master eth0 ipv4.address=10.195.94.2

# 6. Create K3s worker
incus launch images:ubuntu/jammy k3s-worker-1 \
  --config limits.cpu=2 \
  --config limits.memory=4GB \
  --config security.nesting=true \
  --config security.privileged=true \
  --config boot.autostart=true

incus network attach incusbr0 k3s-worker-1 eth0
incus config device set k3s-worker-1 eth0 ipv4.address=10.195.94.3

# 7. Install Tailscale in containers
for container in k3s-master k3s-worker-1; do
  incus exec $container -- bash -c \
    "curl -fsSL https://tailscale.com/install.sh | sh"
  incus exec $container -- tailscale up --authkey=tskey-auth-xxx
done
```

**PC 2 (Worker) — Complete Setup:**

```bash
# Same Tailscale + Incus install as PC 1
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=worker --authkey=tskey-auth-xxx

sudo apt-get install -y incus
sudo incus admin init

# Create workers
incus launch images:ubuntu/jammy k3s-worker-2 \
  --config limits.cpu=2 \
  --config limits.memory=4GB \
  --config security.nesting=true \
  --config security.privileged=true

incus network attach incusbr0 k3s-worker-2 eth0
incus config device set k3s-worker-2 eth0 ipv4.address=10.195.95.2

# Install Tailscale in container
incus exec k3s-worker-2 -- bash -c \
  "curl -fsSL https://tailscale.com/install.sh | sh"
incus exec k3s-worker-2 -- tailscale up --authkey=tskey-auth-xxx
```

**Connecting the Cluster:**

```bash
# On k3s-master (PC 1)
curl -sfL https://get.k3s.io | K3S_TOKEN=mysecret sh -s - server

# Get join token
sudo cat /var/lib/rancher/k3s/server/node-token

# On k3s-worker-1 (PC 1)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://antix.tail1234.ts.net:6443 \
  K3S_TOKEN=<token-from-above> \
  sh -s - agent

# On k3s-worker-2 (PC 2)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://antix.tail1234.ts.net:6443 \
  K3S_TOKEN=<token-from-above> \
  sh -s - agent
```

**Access from Phone:**

```bash
# Install Tailscale on phone
# Now you can:
# - SSH: ssh user@antix (Tailscale IP)
# - K3s: kubectl --server=https://antix.tail1234.ts.net:6443
# - Incus: https://antix:8443 (with TLS client cert)
# - Web apps: http://k3s-master:8080
```

### Exposing Self-Hosted Services

```bash
# Nextcloud on PC 1
incus launch images:ubuntu/jammy nextcloud \
  --config limits.cpu=4 \
  --config limits.memory=8GB

# Install Nextcloud inside
incus exec nextcloud -- bash -c "
  apt-get update
  apt-get install -y nextcloud
"

# Expose via Tailscale
incus exec nextcloud -- tailscale serve --bg 80

# Access from any device: https://nextcloud.tail1234.ts.net
```

### Multi-Cloud with Tailscale

```bash
# AWS EC2 instance
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=tskey-auth-xxx

# GCP instance
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=tskey-auth-xxx

# Azure instance
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --authkey=tskey-auth-xxx

# All three are now on the same tailnet
# 100.x.x.1 (AWS) ↔ 100.x.x.2 (GCP) ↔ 100.x.x.3 (Azure)
```

---

## 15. Further Reading

### Official Documentation

- **Tailscale Docs**: https://tailscale.com/kb/
- **Tailscale GitHub**: https://github.com/tailscale/tailscale
- **Tailscale Blog**: https://tailscale.com/blog/
- **Admin Console**: https://login.tailscale.com/admin

### Related Projects

- **Headscale**: https://github.com/juanfont/headscale (Self-hosted control plane)
- **WireGuard**: https://www.wireguard.com/ (The underlying VPN)
- **DERP**: Tailscale's relay protocol
- **Taildrop**: Tailscale's file sharing feature
- **Funnel**: Tailscale's public HTTPS tunnel

### Community Resources

- Tailscale Reddit: r/tailscale
- Tailscale Discord
- Tailscale Community Forum: https://community.tailscale.com/

### Books and Tutorials

- "WireGuard: Modern, Secure, Fast VPN" (official docs)
- Tailscale how-to guides: https://tailscale.com/kb/1017/
- WireGuard cookbook: https://www.wireguard.com/cookbook/

### Tools That Work With Tailscale

- **Kubernetes**: Tailscale operator for service exposure
- **Docker**: Tailscale container for networking
- **Terraform**: Tailscale provider for IaC
- **Ansible**: Tailscale roles for automation
- **Prometheus**: Tailscale metrics exporter

---

*Last updated: September 2026*
