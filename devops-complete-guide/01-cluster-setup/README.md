# 01 — Cluster Setup

> Build the foundation: a production-grade Kubernetes cluster with networking, ingress, and TLS — all from scratch on commodity hardware.

This category covers the core infrastructure that every other tool in this guide depends on. You'll provision lightweight VMs with Incus, install k3s, configure cluster networking with MetalLB and Tailscale, expose services via nginx-ingress, and automate TLS certificate management with cert-manager. Everything runs on 2 PCs (antix Core Ultra 5 125U + i3 3rd gen) — no cloud required.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **k3s** | Lightweight Kubernetes distribution (single binary, SQLite, ideal for edge/small clusters) | [k3s.md](k3s.md) |
| **kubectl** | CLI for interacting with the Kubernetes API — deploy, inspect, debug, and manage workloads | [kubectl.md](kubectl.md) |
| **Helm** | Kubernetes package manager — templated manifests, versioned releases, dependency management | [helm.md](helm.md) |
| **Incus** | System container manager (LXD successor) — creates the VMs that host your k3s nodes | [incus.md](incus.md) |
| **Tailscale** | WireGuard-based mesh VPN — secure access to your cluster from anywhere without port forwarding | [tailscale.md](tailscale.md) |
| **MetalLB** | Bare-metal load balancer — assigns external IPs to LoadBalancer services (replaces cloud LB) | [metallb.md](metallb.md) |
| **nginx-ingress** | Ingress controller — routes HTTP/HTTPS traffic to services based on hostnames and paths | [nginx-ingress.md](nginx-ingress.md) |
| **cert-manager** | Automated TLS certificate management — issues and renews Let's Encrypt certificates for your ingress | [cert-manager.md](cert-manager.md) |

## What You'll Learn

- Provision lightweight VMs with Incus (networking, storage, kernel modules)
- Install k3s in HA mode (server + agent nodes)
- Manage cluster resources with kubectl and Helm
- Expose services externally with MetalLB + nginx-ingress
- Secure all traffic with automated TLS via cert-manager + Let's Encrypt
- Access the cluster remotely via Tailscale VPN

## Prerequisites

- 2 machines running Linux (Ubuntu/Debian recommended)
- 4 GB+ RAM, 40 GB+ disk per node
- Network connectivity between nodes (LAN or VPN)
- Root/sudo access on both machines
- Domain name with DNS pointing to your cluster (for TLS)

## Difficulty

**Beginner** — Start here. This is the foundation everything else builds on.

## Learning Path

```
Prerequisites (00) → k3s → kubectl → Helm
→ MetalLB → nginx-ingress → cert-manager
→ Tailscale (for remote access)
```
