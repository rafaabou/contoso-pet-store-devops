# K3s Cluster — OpenTofu + Ansible Setup Guide (Production)

## Automated Infrastructure as Code

**Architecture:** 8 containers on Incus (PC1: k3s-master, k3s-worker-1, vault, monitoring; PC2: k3s-worker-2, sonarqube, forgejo-ci, runner-1), connected via Tailscale VPN, running production-grade k3s cluster with dedicated Vault, Monitoring, SonarQube and Forgejo CI servers. PC2 tofu runs ON PC2 (local daemon + local state — never cross-plan).

---

# Table of Contents

1. [File Structure](#1-file-structure)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Install Tailscale VPN](#3-step-1-install-tailscale-vpn)
4. [Step 2: Install Incus + OpenTofu + Ansible](#4-step-2-install-incus--opentofu--ansible)
5. [Step 3: Initialize Incus](#5-step-3-initialize-incus)
6. [Step 4: OpenTofu — Create Containers](#6-step-4-opentofu--create-containers)
7. [Step 5: Ansible — Configure & Install k3s](#7-step-5-ansible--configure--install-k3s)
8. [Step 6: Verify Cluster](#8-step-6-verify-cluster)
9. [Step 7: Configure Domain + DNS](#9-step-7-configure-domain--dns)
10. [Step 8: Access All Services](#10-step-8-access-all-services)
11. [Commands Reference](#11-commands-reference)
12. [Troubleshooting](#12-troubleshooting)

---

\newpage

# 1: File Structure

```
ansible-opentofu/
+-- opentofu/
|   +-- providers.tf          # Incus provider config
|   +-- variables.tf          # All configurable variables
|   +-- pc1/                  # PC1: antix (master + worker1 + vault + monitoring)
|   |   +-- main.tf           # 4 Incus containers
|   |   +-- variables.tf      # PC1-specific variables
|   |   +-- outputs.tf        # All IPs and names
|   +-- pc2/                  # PC2: worker2 + sonarqube + forgejo-ci + runner-1
|       +-- main.tf           # 4 Incus containers (privileged where needed)
|       +-- variables.tf      # PC2 vars (sonarqube 2560MB floor, vault trim pattern)
|       +-- outputs.tf        # Names + IPs (bridge + Tailscale after onboarding)
+-- ansible/
|   +-- ansible.cfg           # SSH + connection settings
|   +-- inventory/
|   |   +-- hosts.ini         # 8 nodes (PC1 bridge IPs + PC2 Tailscale IPs; SSH keys only, no passwords)
|   |   +-- group_vars/
|   |       +-- all.yml       # Global variables
|   +-- playbooks/            # Modular playbooks (run order = site.yml order)
|   |   +-- site-cluster.yml      # K3s cluster only
|   |   +-- site-nfs-server.yml   # NFS exports on master
|   |   +-- site-nfs-client.yml   # NFS mounts on workers only
|   |   +-- site-node-exporter.yml # Node metrics on K3s nodes
|   |   +-- site-tools.yml        # kubectl/helm/k9s toolchain on nodes
|   |   +-- site-vault.yml        # Vault server (+ OIDC method/role)
|   |   +-- site-networking.yml   # MetalLB + Istio + cert-manager + Gateway routes
|   |   +-- site-monitoring.yml   # Prometheus/Grafana/Alertmanager (+ blackbox role)
|   |   +-- site-opentelemetry.yml # OTel Collector + Jaeger + Loki
|   |   +-- site-minio.yml        # MinIO S3 (+ OIDC, Vault-sourced creds)
|   |   +-- site-sonarqube.yml    # SonarQube + PostgreSQL (+ OIDC plugin)
|   |   +-- site-argocd.yml       # ArgoCD (+ Dex OIDC connector)
|   |   +-- site-apps.yml         # Application namespace
|   |   +-- site-forgejo.yml      # Forgejo CI server + host-label runners
|   |   +-- site-security.yml     # RBAC + NetworkPolicies
|   +-- roles/
|   |   +-- common/           # Base packages, sysctl, iptables
|   |   +-- k3s-master/       # Install k3s server
|   |   +-- k3s-worker/       # Install k3s agent
|   |   +-- tools/            # kubectl, helm, k9s, stern, etc.
|   |   +-- metallb/          # MetalLB load balancer
|   |   +-- istio/            # Istio mesh + ingress gateway
|   |   +-- cert-manager/     # Let's Encrypt DNS-01 TLS
|   |   +-- monitoring/       # Prometheus + Grafana (+ blackbox role)
|   |   +-- opentelemetry/    # OTel Collector + Jaeger + Loki (VM services)
|   |   +-- node-exporter/    # Node metrics on K3s nodes
|   |   +-- vault/            # HashiCorp Vault (TLS + auto-unseal + OIDC)
|   |   +-- minio/            # MinIO S3 (Vault-sourced creds + OIDC)
|   |   +-- postgres-local/   # PostgreSQL data-dir placement
|   |   +-- sonarqube/         # SonarQube + branch plugin (+ OIDC plugin)
|   |   +-- argocd/           # ArgoCD GitOps (+ Dex OIDC connector)
|   |   +-- nfs-server/ nfs-client/ # NFS exports + workers-only mounts
|   |   +-- forgejo/ forgejo-runner/ # Forgejo CI + host-label runners
|   +-- site.yml              # Master playbook (imports modular playbooks)
+-- README.md                 # This file
```

---

\newpage

# 2: Prerequisites

## On Both PCs

| Requirement | PC1 (antix) | PC2 (i3) |
|-------------|-------------|----------|
| OS | Ubuntu 26.04 | Ubuntu/Debian |
| RAM | 14GB | 12GB |
| Disk | 50GB+ free | 50GB+ free |
| Incus | Installed | Installed |
| Tailscale | Installed | Installed |

## Install Terraform + Ansible

**On PC1 (antix):**

```bash
# OpenTofu
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install tofu -y

# Ansible
sudo apt install ansible -y
```

**On PC2:**

```bash
# OpenTofu (same as PC1)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install tofu -y

# Ansible
sudo apt install ansible -y
```

## Verify

```bash
tofu version
ansible --version
incus version
tailscale version
```

---

\newpage

# 3: Step 1 — Install Tailscale VPN

Tailscale bridges your two WiFi networks so k3s nodes can communicate.

## 3.1 Install on Both PCs

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

## 3.2 Start and Authenticate

```bash
sudo tailscale up
```

Open the URL in a browser, authenticate with Google/GitHub.

## 3.3 Verify VPN

```bash
# On PC1
tailscale status
# You should see PC2's Tailscale IP (100.x.x.2)

# On PC2
tailscale status
# You should see PC1's Tailscale IP (100.x.x.1)

# Test ping
# From PC1:
ping 100.x.x.2
```

## 3.4 Advertise Incus Routes

On **both PCs**:

```bash
sudo tailscale set --advertise-routes=10.195.94.0/24
```

Then approve both routes in the Tailscale admin console (https://login.tailscale.com/admin/machines).

---

\newpage

# 4: Step 2 — Install Incus + Terraform + Ansible

See [Prerequisites](#2-prerequisites) above for exact commands.

## 4.1 Pull Ubuntu Image (Both PCs)

```bash
incus image copy ubuntu:24.04 local: --alias ubuntu-noble
```

---

\newpage

# 5: Step 3 — Initialize Incus

Run on **BOTH PCs**:

```bash
sudo incus admin init
```

Answer:
- Clustering? -> **no**
- Storage pool? -> **yes**, name: **default**, backend: **btrfs** (or dir)
- MAAS? -> **no**
- Network bridge? -> **yes**, name: **incusbr0**, IPv4: **10.195.94.1/24**

## Verify

```bash
incus info
incus network ls
# Should show incusbr0
```

---

\newpage

# 6: Step 4 — OpenTofu: Create Containers

## 6.1 On PC1 (antix)

```bash
cd ansible-opentofu/opentofu/pc1

# Initialize OpenTofu
tofu init

# Plan (see what will be created)
tofu plan

# Apply (create the containers)
tofu apply -auto-approve
```

**Output:**
```
Apply complete! Resources: 4 added.

Outputs:
master_name = "k3s-master"
master_ip = "10.195.94.80"
worker1_name = "k3s-worker-1"
worker1_ip = "10.195.94.81"
vault_name = "k3s-vault"
vault_ip = "10.195.94.200"
monitoring_name = "k3s-monitoring"
monitoring_ip = "10.195.94.210"
```

## 6.2 On PC2

```bash
cd ansible-opentofu/opentofu/pc2

# Initialize
tofu init

# Plan
tofu plan

# Apply
tofu apply -auto-approve
```

**Output (4 containers — worker2 + sonarqube predate the Forgejo pair):**
```
Apply complete! Resources: 4 added (first run) / 2 added (Forgejo pair later).

Outputs (bridge IPs; Tailscale IPs recorded in inventory after onboarding):
worker2_name = "k3s-worker-2"
sonarqube_name = "k3s-sonarqube"
forgejo_ci_name = "k3s-forgejo-ci"
runner_1_name = "k3s-runner-1"
```
**Critical: run PC2 tofu ON PC2** (provider talks to the local daemon — PC1 plans phantom duplicates. And never sync `terraform.tfstate*` between PCs: each PC owns its state, sync code only).

## 6.3 Verify Containers

On each PC:
```bash
incus ls
# PC1: k3s-master (10.195.94.80), k3s-worker-1 (10.195.94.81), k3s-vault (10.195.94.200), k3s-monitoring (10.195.94.210)
# PC2: k3s-worker-2 (100.100.13.113)
```

---

\newpage

# 7: Step 5 — Ansible: Configure & Install k3s

## 7.1 Update Inventory

Edit `ansible-opentofu/ansible/inventory/hosts.ini` with your Tailscale IPs if different:

```ini
# SSH keys only (setup-ssh-keys.sh) — no passwords anywhere (retired, see ERROR 28).
# PC1 hosts: direct bridge IPs. PC2 hosts: Tailscale IPs (bridge invisible cross-PC).
[k3s_master]
k3s-master ansible_host=10.195.94.80

[k3s_workers]
k3s-worker-1 ansible_host=10.195.94.81
k3s-worker-2 ansible_host=100.100.13.113  # + k3s_server_url/nfs_server_override (Tailscale)

[vault_server]
vault ansible_host=10.195.94.200

[monitoring_server]
monitoring ansible_host=10.195.94.210

[sonarqube_server]
sonarqube ansible_host=100.73.135.124

[forgejo_server]
forgejo ansible_host=100.88.159.38

[ci_runners]
ci-runner-1 ansible_host=100.113.54.77
```

## 7.2 Test Connectivity

From PC1:
```bash
cd ansible-opentofu/ansible

# Test SSH to all nodes
ansible production -m ping

# Expected output:
# k3s-master | SUCCESS => { "ping": "pong" }
# k3s-worker-1 | SUCCESS => { "ping": "pong" }
# k3s-worker-2 | SUCCESS => { "ping": "pong" }
# vault | SUCCESS => { "ping": "pong" }
# monitoring | SUCCESS => { "ping": "pong" }
```

## 7.3 Run Full Setup

```bash
# Run everything from PC1
ansible-playbook site.yml
```

This will (15 steps, cluster → security):
1. K3s cluster (master + agents join) + NFS server/clients + node-exporter + tools
2. Vault (TLS + auto-init/unseal + KV + OIDC method/role)
3. Networking (MetalLB pool .100-150 + Istio mesh + ingress gateway pinned .100), cert-manager DNS-01 (token from Vault), Gateway routes for all UIs
4. Monitoring (Prometheus/Grafana/Alertmanager + blackbox probes + Telegram paging), OTel stack, MinIO S3 (Vault creds + OIDC), SonarQube + PostgreSQL (+ OIDC plugin), ArgoCD (+ Dex OIDC), Forgejo CI + runners
5. Applications namespace, then RBAC + NetworkPolicies lockdown

**Total time:** ~5-10 minutes

## 7.4 Run Specific Components Only

```bash
# Only cluster (K3s)
ansible-playbook playbooks/site-cluster.yml

# Only vault server
ansible-playbook playbooks/site-vault.yml

# Only monitoring server
ansible-playbook playbooks/site-monitoring.yml

# Only networking
ansible-playbook playbooks/site-networking.yml

# Only tools
ansible-playbook playbooks/site-tools.yml

# Only ArgoCD
ansible-playbook playbooks/site-argocd.yml

# Only MinIO / SonarQube / Forgejo / OTel / NFS
ansible-playbook playbooks/site-minio.yml
ansible-playbook playbooks/site-sonarqube.yml
ansible-playbook playbooks/site-forgejo.yml
ansible-playbook playbooks/site-opentelemetry.yml
ansible-playbook playbooks/site-nfs-server.yml
ansible-playbook playbooks/site-nfs-client.yml

# Only security
ansible-playbook playbooks/site-security.yml
```

---

\newpage

# 8: Step 6 — Verify Cluster

```bash
# Check all nodes
kubectl get nodes -o wide

# Expected output:
# NAME           STATUS   ROLES                  AGE   VERSION   INTERNAL-IP
# k3s-master     Ready    control-plane,master   5m    v1.36.2   10.195.94.80
# k3s-worker-1   Ready    <none>                 3m    v1.36.2   10.195.94.81
# k3s-worker-2   Ready    <none>                 2m    v1.36.2   10.195.94.82

# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A
```

---

\newpage

# 9: Step 7 — Configure Domain + DNS

## 9.1 Get Ingress IP

```bash
kubectl -n istio-ingress get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# 10.195.94.100 (pinned via loadBalancerIP; wildcard DNS points here)
```

## 9.2 Create DNS Records

In your domain registrar, create:

| Host | Type | Value |
|------|------|-------|
| `*` | A | 10.195.94.100 |

Or individual records:

| Host | Type | Value |
|------|------|-------|
| `argocd` | A | 10.195.94.100 |
| `grafana` | A | 10.195.94.100 |
| `prometheus` | A | 10.195.94.100 |
| `sonar` | A | 10.195.94.100 |
| `vault` | A | 10.195.94.200 |
| `monitoring` | A | 10.195.94.210 |
| `store` | A | 10.195.94.100 |
| `admin` | A | 10.195.94.100 |

## 9.3 Verify DNS

```bash
nslookup grafana.yourdomain.com
# Should return 10.195.94.100
```

---

\newpage

# 10: Step 8 — Access All Services

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD | https://argocd.yourdomain.com | admin + rotated value in Vault `kv/argocd` (+ SSO via Forgejo) |
| Grafana | https://grafana.yourdomain.com | rotated value in Vault `kv/grafana` (+ SSO) |
| SonarQube | https://sonar.yourdomain.com | rotated value in Vault `kv/sonarqube` (+ SSO via custom plugin) |
| Forgejo | https://forgejo.yourdomain.com | rotated value in Vault `kv/forgejo` |
| MinIO console | https://minio.yourdomain.com | rotated value in Vault `kv/minio` (+ SSO) |
| Prometheus/Alertmanager | https://prometheus.yourdomain.com | - (no login) |
| Vault | https://vault.yourdomain.com (or `:8200/ui` direct) | root token in `/root/vault-init.json` on Vault host (+ OIDC) |

**Never write credentials to files** (the old `/tmp/argocd-credentials.txt` pattern is retired — fetch from Vault, rotate in UI, verify, store, delete initial secrets).

---

\newpage

# 11: Commands Reference

## OpenTofu

```bash
# Initialize
tofu init

# See what will change
tofu plan

# Create/destroy resources
tofu apply
tofu destroy

# Show current state
tofu state list
tofu state show
```

## Ansible

```bash
# Test connectivity
ansible all -m ping

# Run all tasks
ansible-playbook site.yml

# Run specific role
ansible-playbook site.yml --tags "k3s-master"

# Dry run (check mode)
ansible-playbook site.yml --check

# Verbose output
ansible-playbook site.yml -vvv
```

## k3s

```bash
# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# Logs
stern -n <namespace> <app>

# Helm
helm list -A
helm upgrade <release> <chart> -n <namespace>
```

---

\newpage

# 12: Troubleshooting

## Worker 2 Can't Join Cluster

**Symptom:** `k3s-worker-2` shows `NotReady` or can't connect.

**Fix:**
1. Check VPN: `tailscale status` (both PCs must be connected)
2. Check routes: `tailscale set --advertise-routes=10.195.94.0/24`
3. Test ping: `incus exec k3s-worker-2 -- ping 10.195.94.80`
4. If ping fails, use Tailscale IP: edit inventory with 100.x.x.1 instead of 10.195.94.80

## Ansible SSH Fails

**Symptom:** `ansible all -m ping` returns "unreachable".

**Fix:**
1. Check containers are running: `incus ls`
2. Check IPs: `incus exec k3s-master -- ip addr`
3. Check SSH: `ssh root@10.195.94.80`
4. Ensure Ansible uses root: check `ansible.cfg` has `remote_user = root`

## cert-manager Not Issuing Certs

**Symptom:** TLS certs stuck in `Pending`.

**Fix:**
1. Check logs: `kubectl logs -n cert-manager -l app=cert-manager`
2. Verify issuer: `kubectl get clusterissuer -o wide`
3. Check ingress: `kubectl get gateway,virtualservice -A`

## Ingress Not Working

**Symptom:** Can't access services via domain.

**Fix:**
1. Check Gateway/VirtualService: `kubectl get gateway,virtualservice -A`
2. Check gateway + istiod: `kubectl -n istio-ingress get pods; kubectl -n istio-system get pods`
3. Check wildcard cert: `kubectl -n istio-ingress get certificate wildcard-tls`
4. Verify DNS: `nslookup grafana.yourdomain.com`
5. Test with IP: `curl -sk -H "Host: grafana.yourdomain.com" https://10.195.94.100 -o /dev/null -w '%{http_code}\n'`

## Destroy Everything

```bash
# On PC1
cd ansible-opentofu/opentofu/pc1
tofu destroy -auto-approve

# On PC2
cd ansible-opentofu/opentofu/pc2
tofu destroy -auto-approve
```

---

\newpage

# Variables Reference

Edit `ansible-opentofu/opentofu/variables.tf` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `prefix` | `k3s` | Container name prefix |
| `image` | `ubuntu-noble` | Ubuntu image alias |
| `k3s_version` | `v1.36.2+k3s1` | K3s version |
| `pc1_master_ip` | `10.195.94.80` | Master IP |
| `pc1_worker1_ip` | `10.195.94.81` | Worker1 IP |
| `pc2_worker2_ip` | `100.100.13.113` | Worker2 IP |
| `vault_server_ip` | `10.195.94.200` | Vault server IP |
| `monitoring_server_ip` | `10.195.94.210` | Monitoring server IP |
| `pc1_master_cpu` | `4` | Master CPU cores |
| `pc1_master_memory` | `4GB` | Master RAM |
| `domain` | `yourdomain.com` | Your domain name |
| `letsencrypt_email` | `admin@yourdomain.com` | TLS cert email |
| `metallb_pool` | `10.195.94.100-10.195.94.150` | MetalLB IP range |
