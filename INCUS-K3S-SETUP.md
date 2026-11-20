# K3s Cluster on Incus — Step-by-Step Setup Guide

## Full End-to-End: Incus + VPN + k3s + Domain + TLS + DevSecOps

**Architecture:** 2 PCs on different WiFi networks, connected via Tailscale VPN, running 3-node k3s cluster inside Incus containers.

---

# Table of Contents

1. [Hardware Overview](#1-hardware-overview)
2. [Install Incus on Both PCs](#2-install-incus-on-both-pcs)
3. [VPN Setup (Tailscale)](#3-vpn-setup-tailscale)
4. [Create Incus Containers](#4-create-incus-containers)
5. [Network Config + LXC Fixes](#5-network-config--lxc-fixes)
6. [Install k3s Cluster](#6-install-k3s-cluster)
7. [Verify Cluster](#7-verify-cluster)
8. [MetalLB (LoadBalancer)](#8-metallb-loadbalancer)
9. [nginx-ingress](#9-nginx-ingress)
10. [cert-manager + Let's Encrypt](#10-cert-manager--lets-encrypt)
11. [DNS Configuration](#11-dns-configuration)
12. [Local Docker Registry](#12-local-docker-registry)
13. [Install K8s Tools on Master](#13-install-k8s-tools-on-master)
14. [SonarQube](#14-sonarqube)
15. [Security Tools (Gitleaks, Hadolint, etc.)](#15-security-tools)
16. [Monitoring (Prometheus + Grafana)](#16-monitoring-prometheus--grafana)
17. [Vault (Secrets Management)](#17-vault-secrets-management)
18. [Deploy Microservices via ArgoCD](#18-deploy-microservices-via-argocd)

---

\newpage

# 1: Hardware Overview

| | PC1: antix (Master) | PC2: Worker |
|---|---|---|
| CPU | Core Ultra 5 125U | i3 3rd gen |
| RAM | 14GB | 12GB |
| OS | Ubuntu 26.04 | Ubuntu/Debian |
| Network | WiFi 1 (192.168.1.x) | WiFi 2 (192.168.2.y) |
| VPN IP | Tailscale 100.x.x.1 | Tailscale 100.x.x.2 |
| Incus Role | master + worker1 | worker2 |
| k3s Role | control-plane + worker | worker |

**Why 2 PCs on different WiFi?** If one WiFi goes down, the other PC keeps running. Tailscale VPN bridges them so k3s nodes can communicate.

**Cluster layout:**

```
PC1 (antix, WiFi 1)                      PC2 (WiFi 2)
+----------------------------------+     +-----------------------------+
| Tailscale: 100.x.x.1            |     | Tailscale: 100.x.x.2       |
|                                  |<--->|                             |
| Incus: k3s-tf-master            | VPN | Incus: k3s-tf-worker-2     |
|   IP: 10.195.94.80              |     |   IP: 10.195.94.82         |
|   Role: control-plane           |     |   Role: worker              |
|                                  |     +-----------------------------+
| Incus: k3s-tf-worker-1          |
|   IP: 10.195.94.81              |
|   Role: worker                  |
+----------------------------------+
           |
    MetalLB: 10.195.94.100-150
    Domain: *.yourdomain.com -> 10.195.94.100
    TLS: Let's Encrypt via cert-manager
```

---

\newpage

# 2: Install Incus on Both PCs

Run these commands on **BOTH PCs**.

## 2.1 Add Zabbly Repository (latest stable Incus)

```bash
# Remove old Ubuntu Incus repo if present
sudo rm /etc/apt/sources.list.d/incus-stable.list 2>/dev/null

# Add Zabbly GPG key
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc

# Add Zabbly stable repo
echo 'Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: resolute
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/zabbly.asc' | sudo tee /etc/apt/sources.list.d/zabbly-incus-stable.sources
```

> **Note:** Replace `resolute` with your Ubuntu codename:
> - Ubuntu 24.04 = `noble`
> - Ubuntu 22.04 = `jammy`
> - Ubuntu 26.04 = `resolute`

## 2.2 Install Incus

```bash
sudo apt update
sudo apt install incus incus-ui-canonical -y
```

## 2.3 Add Your User to Incus Group

```bash
sudo usermod -aG incus-admin $USER
newgrp incus-admin
```

## 2.4 Verify Installation

```bash
incus version
# Expected: Client version: 7.x, Server version: 7.x
```

## 2.5 Initialize Incus

```bash
sudo incus admin init
```

Answer the prompts:
- `Would you like to use clustering?` -> **no**
- `Would you like to configure a new storage pool?` -> **yes**
- `Name of the new storage pool` -> **default**
- `Name of the storage backend` -> **btrfs** (or `dir` if no btrfs)
- `Would you like to connect to a MAAS server?` -> **no**
- `Would you like to create a new local network bridge?` -> **yes**
- `What should the new bridge be called?` -> **incusbr0**
- `What IPv4 address should be used?` -> **10.195.94.1/24**
- `What IPv6 address should be used?` -> **fd42:ffc0:ad6f:6676::1/64**
- `Would you like to run Incus in a project?` -> **no**

## 2.6 Enable Web UI (Optional)

```bash
incus config set core.https_address :8443
```

Access at: `https://<PC_IP>:8443/ui/`

---

\newpage

# 3: VPN Setup (Tailscale)

Tailscale bridges your two WiFi networks so k3s nodes can communicate across different routers.

## 3.1 Install Tailscale on BOTH PCs

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

## 3.2 Start Tailscale on BOTH PCs

```bash
sudo tailscale up
```

This will output a login URL. Open it in a browser and authenticate with your Tailscale account (Google, GitHub, etc.).

## 3.3 Verify VPN Connectivity

On PC1:
```bash
tailscale status
# You should see PC2 listed with its Tailscale IP (100.x.x.2)
```

On PC2:
```bash
tailscale status
# You should see PC1 listed with its Tailscale IP (100.x.x.1)
```

Test connectivity:
```bash
# From PC1, ping PC2's Tailscale IP
ping 100.x.x.2

# From PC2, ping PC1's Tailscale IP
ping 100.x.x.1
```

## 3.4 Allow LAN Bypass (Optional)

If you want devices on the same LAN to reach Incus containers without going through Tailscale:

```bash
# On PC1
sudo tailscale set --advertise-routes=10.195.94.0/24

# On PC2
sudo tailscale set --advertise-routes=10.195.94.0/24
```

Then approve the routes in the Tailscale admin console.

---

\newpage

# 4: Create Incus Containers

## 4.1 Pull Ubuntu Image (Both PCs)

```bash
incus image copy ubuntu:24.04 local: --alias ubuntu-24-04
```

## 4.2 Create Containers on PC1 (antix)

```bash
# Master node
incus launch ubuntu-24-04 k3s-tf-master \
  -c security.privileged=true \
  -c security.nesting=true \
  -c limits.cpu=4 \
  -c limits.memory=4GB

# Worker 1
incus launch ubuntu-24-04 k3s-tf-worker-1 \
  -c security.privileged=true \
  -c security.nesting=true \
  -c limits.cpu=2 \
  -c limits.memory=4GB
```

## 4.3 Create Container on PC2

```bash
# Worker 2
incus launch ubuntu-24-04 k3s-tf-worker-2 \
  -c security.privileged=true \
  -c security.nesting=true \
  -c limits.cpu=2 \
  -c limits.memory=4GB
```

## 4.4 Assign Static IPs

**On PC1:**
```bash
# Stop containers first
incus stop k3s-tf-master k3s-tf-worker-1

# Assign IPs
incus config device add k3s-tf-master eth0 nic \
  name=eth0 nictype=bridged parent=incusbr0 ipv4.address=10.195.94.80

incus config device add k3s-tf-worker-1 eth0 nic \
  name=eth0 nictype=bridged parent=incusbr0 ipv4.address=10.195.94.81

# Start containers
incus start k3s-tf-master k3s-tf-worker-1
```

**On PC2:**
```bash
# Stop container
incus stop k3s-tf-worker-2

# Assign IP
incus config device add k3s-tf-worker-2 eth0 nic \
  name=eth0 nictype=bridged parent=incusbr0 ipv4.address=10.195.94.82

# Start container
incus start k3s-tf-worker-2
```

## 4.5 Verify Containers Running

```bash
incus ls
# +-----------------+---------+----------------------+
# | k3s-tf-master   | RUNNING | 10.195.94.80 (eth0)  |
# | k3s-tf-worker-1 | RUNNING | 10.195.94.81 (eth0)  |
# +-----------------+---------+----------------------+
```

---

\newpage

# 5: Network Config + LXC Fixes

Run these on **ALL 3 containers**.

## 5.1 Set Static IP Inside Container

For each node, create the network config:

```bash
# For k3s-tf-master (10.195.94.80)
incus exec k3s-tf-master -- sh -c "
cat > /etc/systemd/network/10-static-eth0.network << 'EOF'
[Match]
Name=eth0

[Network]
Address=10.195.94.80/24
Gateway=10.195.94.1
DNS=1.1.1.1
EOF
"
incus exec k3s-tf-master -- sh -c "
rm -f /etc/netplan/*.yaml /run/systemd/network/*.network
systemctl enable systemd-networkd
systemctl restart systemd-networkd
"
```

Repeat for worker-1 (10.195.94.81) and worker-2 (10.195.94.82), changing the IP address.

## 5.2 Fix /dev/kmsg (All Nodes)

```bash
for NODE in k3s-tf-master k3s-tf-worker-1 k3s-tf-worker-2; do
  incus exec "$NODE" -- ln -sf /dev/console /dev/kmsg
  incus exec "$NODE" -- sh -c "
cat > /etc/systemd/system/dev-kmsg.service << 'SRV'
[Unit]
Description=Symlink /dev/kmsg to /dev/console
DefaultDependencies=no
Before=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/ln -sf /dev/console /dev/kmsg
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
SRV
"
  incus exec "$NODE" -- systemctl daemon-reload
  incus exec "$NODE" -- systemctl enable dev-kmsg.service
done
```

## 5.3 Fix /proc/sys Read-Only (All Nodes)

```bash
for NODE in k3s-tf-master k3s-tf-worker-1 k3s-tf-worker-2; do
  incus exec "$NODE" -- mount -o remount,rw /proc/sys 2>/dev/null || true
  incus exec "$NODE" -- sh -c "
    grep -q '/proc/sys' /etc/fstab 2>/dev/null || \
    echo 'none /proc/sys proc defaults,bind,remount,rw 0 0' >> /etc/fstab
  "
done
```

## 5.4 Install iptables (All Nodes)

```bash
for NODE in k3s-tf-master k3s-tf-worker-1 k3s-tf-worker-2; do
  incus exec "$NODE" -- apt-get update -qq
  incus exec "$NODE" -- apt-get install -y -qq curl iptables
  incus exec "$NODE" -- update-alternatives --set iptables /usr/sbin/iptables-nft 2>/dev/null || true
done
```

---

\newpage

# 6: Install k3s Cluster

## 6.1 Install k3s Master (on PC1)

```bash
incus exec k3s-tf-master -- bash -c "
export K3S_KUBECONFIG_MODE=644
export INSTALL_K3S_VERSION='v1.36.2+k3s1'
curl -sfL https://get.k3s.io | sh -s - \
  --disable=traefik \
  --node-ip=10.195.94.80 \
  --advertise-address=10.195.94.80
"
```

Wait for master to be Ready:
```bash
for i in $(seq 1 30); do
  if incus exec k3s-tf-master -- kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    echo "Master is Ready!"
    break
  fi
  sleep 5; echo -n "."
done
```

## 6.2 Get Join Token

```bash
TOKEN=$(incus exec k3s-tf-master -- cat /var/lib/rancher/k3s/server/node-token)
echo "Token: $TOKEN"
```

## 6.3 Join Worker 1 (on PC1)

```bash
incus exec k3s-tf-worker-1 -- bash -c "
export K3S_URL='https://10.195.94.80:6443'
export K3S_TOKEN='$TOKEN'
export INSTALL_K3S_VERSION='v1.36.2+k3s1'
curl -sfL https://get.k3s.io | sh -
"
```

## 6.4 Join Worker 2 (on PC2) — Via VPN

**Important:** Worker 2 is on PC2 (different WiFi). The k3s agent needs to reach the master at 10.195.94.80, which is on PC1's Incus bridge. This works because:

1. PC2's Incus container (10.195.94.82) is on PC2's local bridge
2. PC1's Incus container (10.195.94.80) is on PC1's local bridge
3. Tailscale routes traffic between the two PCs

**Option A: Direct VPN routing (recommended)**

On PC1, advertise the Incus bridge route via Tailscale:
```bash
sudo tailscale set --advertise-routes=10.195.94.0/24
```

On PC2, advertise the Incus bridge route via Tailscale:
```bash
sudo tailscale set --advertise-routes=10.195.94.0/24
```

Then approve both routes in the Tailscale admin console.

Now join worker 2:
```bash
incus exec k3s-tf-worker-2 -- bash -c "
export K3S_URL='https://10.195.94.80:6443'
export K3S_TOKEN='$TOKEN'
export INSTALL_K3S_VERSION='v1.36.2+k3s1'
curl -sfL https://get.k3s.io | sh -
"
```

**Option B: Use Tailscale IP for master (if routing doesn't work)**

If the above doesn't work, use the master's Tailscale IP instead:
```bash
# On PC1, find master's Tailscale IP
tailscale ip -4  # e.g., 100.x.x.1

# On PC2, join using Tailscale IP
incus exec k3s-tf-worker-2 -- bash -c "
export K3S_URL='https://100.x.x.1:6443'
export K3S_TOKEN='$TOKEN'
export INSTALL_K3S_VERSION='v1.36.2+k3s1'
curl -sfL https://get.k3s.io | sh -
"
```

---

\newpage

# 7: Verify Cluster

## 7.1 Check All Nodes

```bash
incus exec k3s-tf-master -- kubectl get nodes -o wide
# Expected output:
# NAME             STATUS   ROLES                  AGE   VERSION   INTERNAL-IP
# k3s-tf-master    Ready    control-plane,master   5m    v1.36.2   10.195.94.80
# k3s-tf-worker-1  Ready    <none>                 3m    v1.36.2   10.195.94.81
# k3s-tf-worker-2  Ready    <none>                 2m    v1.36.2   10.195.94.82
```

## 7.2 Test Cross-Network Connectivity

```bash
# From master, ping worker 2 (on PC2)
incus exec k3s-tf-master -- ping -c 3 10.195.94.82

# From worker 2, ping master (on PC1)
incus exec k3s-tf-worker-2 -- ping -c 3 10.195.94.80
```

## 7.3 Set Up Kubeconfig on Host

```bash
# On PC1 (antix)
mkdir -p ~/.kube
incus file pull k3s-tf-master/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i "s/127.0.0.1/10.195.94.80/g" ~/.kube/config

# Verify
kubectl get nodes
```

---

\newpage

# 8: MetalLB (LoadBalancer)

MetalLB gives your bare-metal cluster external IPs for services.

## 8.1 Install MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

Wait for pods:
```bash
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

## 8.2 Configure IP Pool

```bash
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-address-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.195.94.100-10.195.94.150
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
```

## 8.3 Verify

```bash
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

---

\newpage

# 9: nginx-ingress

## 9.1 Install nginx-ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace
```

## 9.2 Get External IP

```bash
kubectl get svc -n ingress-nginx
# NAME                       TYPE           EXTERNAL-IP     PORT
# ingress-nginx-controller   LoadBalancer   10.195.94.100   80:xxxxx/TCP,443:xxxxx/TCP
```

The EXTERNAL-IP (10.195.94.100) is your ingress IP. All services will be accessed through this IP via different hostnames.

---

\newpage

# 10: cert-manager + Let's Encrypt

## 10.1 Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml
```

Wait for pods:
```bash
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s
```

## 10.2 Create ClusterIssuer for Let's Encrypt

Replace `your-email@example.com` with your actual email:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 10.3 Verify

```bash
kubectl get clusterissuer
# NAME                 READY   AGE
# letsencrypt-prod     True    30s
# letsencrypt-staging  True    30s
```

---

\newpage

# 11: DNS Configuration

## 11.1 Create DNS Records

In your domain registrar (GoDaddy, Cloudflare, Namecheap, etc.), create these A records:

| Host | Type | Value | TTL |
|------|------|-------|-----|
| `@` | A | 10.195.94.100 | Auto |
| `*` | A | 10.195.94.100 | Auto |

The wildcard record (`*.yourdomain.com`) points all subdomains to your ingress IP.

If your registrar doesn't support wildcard A records, create individual records:

| Host | Type | Value |
|------|------|-------|
| `argocd` | A | 10.195.94.100 |
| `grafana` | A | 10.195.94.100 |
| `sonar` | A | 10.195.94.100 |
| `vault` | A | 10.195.94.100 |
| `jaeger` | A | 10.195.94.100 |
| `kiali` | A | 10.195.94.100 |
| `store` | A | 10.195.94.100 |
| `admin` | A | 10.195.94.100 |
| `registry` | A | 10.195.94.100 |

## 11.2 Verify DNS

```bash
# From any machine with internet
nslookup grafana.yourdomain.com
# Should return 10.195.94.100
```

## 11.3 Local DNS (Optional — for faster resolution)

On PC1, add to `/etc/hosts`:
```bash
echo "10.195.94.100 argocd.yourdomain.com grafana.yourdomain.com sonar.yourdomain.com vault.yourdomain.com store.yourdomain.com admin.yourdomain.com registry.yourdomain.com" | sudo tee -a /etc/hosts
```

---

\newpage

# 12: Local Docker Registry

## 12.1 Deploy Registry

```bash
kubectl create namespace registry

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-pvc
  namespace: registry
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: local-path
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: data
          mountPath: /var/lib/registry
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: registry-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  type: LoadBalancer
  selector:
    app: registry
  ports:
  - port: 5000
    targetPort: 5000
EOF
```

## 12.2 Get Registry IP

```bash
kubectl get svc -n registry
# NAME       TYPE           EXTERNAL-IP     PORT
# registry   LoadBalancer   10.195.94.101   5000:xxxxx/TCP
```

## 12.3 Configure k3s to Trust Registry

On each node:

```bash
for NODE in k3s-tf-master k3s-tf-worker-1 k3s-tf-worker-2; do
  incus exec "$NODE" -- sh -c "
mkdir -p /etc/rancher/k3s/registries.d
cat > /etc/rancher/k3s/registries.yaml << EOF
mirrors:
  '10.195.94.101:5000':
    endpoint:
      - http://10.195.94.101:5000
EOF
  "
done
```

Restart k3s on all nodes:
```bash
incus exec k3s-tf-master -- systemctl restart k3s
incus exec k3s-tf-worker-1 -- systemctl restart k3s
incus exec k3s-tf-worker-2 -- systemctl restart k3s-agent
```

## 12.4 Test Push/Pull

```bash
# Pull alpine
docker pull alpine:3.20

# Tag for local registry
docker tag alpine:3.20 10.195.94.101:5000/alpine:test

# Push (insecure, no TLS)
docker push 10.195.94.101:5000/alpine:test

# Verify
curl http://10.195.94.101:5000/v2/_catalog
# {"repositories":["alpine"]}
```

---

\newpage

# 13: Install K8s Tools on Master

```bash
incus exec k3s-tf-master -- bash -c "
# kubectl
ARCH=\$(uname -m); [[ \"\$ARCH\" == 'x86_64' ]] && ARCH='amd64' || ARCH='arm64'
curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v1.36.3/bin/linux/\$ARCH/kubectl
chmod +x /usr/local/bin/kubectl

# k wrapper
echo '#!/bin/sh' > /usr/local/bin/k
echo 'exec kubectl \"\$@\"' >> /usr/local/bin/k
chmod +x /usr/local/bin/k

# Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null

# k9s
K9S_VER=\$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d'\"' -f4)
wget -q -O /tmp/k9s.tar.gz https://github.com/derailed/k9s/releases/download/\$K9S_VER/k9s_Linux_\$ARCH.tar.gz
tar xzf /tmp/k9s.tar.gz -C /tmp k9s && mv /tmp/k9s /usr/local/bin/k9s && chmod +x /usr/local/bin/k9s
rm -f /tmp/k9s.tar.gz

# stern
STERN_VER=\$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d'\"' -f4)
wget -q -O /tmp/stern.tar.gz https://github.com/stern/stern/releases/download/\$STERN_VER/stern_\${STERN_VER#v}_linux_\$ARCH.tar.gz
tar xzf /tmp/stern.tar.gz -C /tmp stern && mv /tmp/stern /usr/local/bin/stern && chmod +x /usr/local/bin/stern
rm -f /tmp/stern.tar.gz

# kubectx + kubens
git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx 2>/dev/null
ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

# popeye
POP_VER=\$(curl -fsSL https://api.github.com/repos/derailed/popeye/releases/latest | grep tag_name | cut -d'\"' -f4)
wget -q -O /tmp/popeye.tar.gz https://github.com/derailed/popeye/releases/download/\$POP_VER/popeye_Linux_\$ARCH.tar.gz
tar xzf /tmp/popeye.tar.gz -C /tmp popeye && mv /tmp/popeye /usr/local/bin/popeye && chmod +x /usr/local/bin/popeye
rm -f /tmp/popeye.tar.gz

# kube-linter
KUL_VER=\$(curl -fsSL https://api.github.com/repos/stackrox/kube-linter/releases/latest | grep tag_name | cut -d'\"' -f4)
wget -q -O /tmp/kube-linter.tar.gz https://github.com/stackrox/kube-linter/releases/download/\$KUL_VER/kube-linter_Linux_\$ARCH.tar.gz
tar xzf /tmp/kube-linter.tar.gz -C /tmp kube-linter && mv /tmp/kube-linter /usr/local/bin/kube-linter && chmod +x /usr/local/bin/kube-linter
rm -f /tmp/kube-linter.tar.gz

# checkov
pip3 install checkov 2>/dev/null || pip install checkov 2>/dev/null

echo 'All tools installed!'
"
```

Verify:
```bash
incus exec k3s-tf-master -- kubectl version --client
incus exec k3s-tf-master -- helm version
incus exec k3s-tf-master -- k9s version --short
```

---

\newpage

# 14: SonarQube

## 14.1 Deploy SonarQube

```bash
kubectl create namespace sonarqube

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-pvc
  namespace: sonarqube
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-path
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    metadata:
      labels:
        app: sonarqube
    spec:
      containers:
      - name: sonarqube
        image: sonarqube:community
        ports:
        - containerPort: 9000
        env:
        - name: SONAR_SEARCH_JAVAADDITIONALOPTS
          value: "-Xmx512m -Xms512m"
        volumeMounts:
        - name: data
          mountPath: /opt/sonarqube/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: sonarqube-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  type: LoadBalancer
  selector:
    app: sonarqube
  ports:
  - port: 9000
    targetPort: 9000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarqube
  namespace: sonarqube
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - sonar.yourdomain.com
    secretName: sonarqube-tls
  rules:
  - host: sonar.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sonarqube
            port:
              number: 9000
EOF
```

## 14.2 Access SonarQube

```bash
# Get the URL
echo "https://sonar.yourdomain.com"

# Default credentials: admin / admin (change on first login)
```

---

\newpage

# 15: Security Tools

## 15.1 Gitleaks (Secret Scanning)

Create `.gitleaks.toml` in your project root:

```toml
title = "Gitleaks config for Contoso Pet Store"

[allowlist]
  description = "Global allowlist"
  paths = [
    '''dlls''',
    '''node_modules''',
    '''vendor''',
    '''target''',
    '''\.sum$''',
  ]

[[rules]]
  id = "aws-access-key"
  description = "AWS Access Key"
  regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
  tags = ["key", "AWS"]

[[rules]]
  id = "github-token"
  description = "GitHub Token"
  regex = '''ghp_[0-9a-zA-Z]{36}'''
  tags = ["key", "GitHub"]

[[rules]]
  id = "generic-api-key"
  description = "Generic API Key"
  regex = '''(?i)(api[_-]?key|apikey|api_key|secret[_-]?key|secretkey|secret_key)[\"'\s]*[:=][\"'\s]*[0-9a-zA-Z]{32,}'''
  tags = ["key", "Generic"]
```

Install and run:
```bash
# Install gitleaks
sudo apt install gitleaks -y
# OR
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# Scan repo
gitleaks detect --source /home/antix/Videos/Store-App_Soruce_Code-GitHub -v
```

## 15.2 Hadolint (Dockerfile Linting)

```bash
# Install
docker pull hadolint/hadolint
# OR binary
wget https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64
sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint

# Lint all Dockerfiles
for f in $(find src/ -name Dockerfile); do
  echo "=== $f ==="
  hadolint "$f"
done
```

## 15.3 Syft (SBOM Generation)

```bash
# Install
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -sSb /usr/local/bin

# Generate SBOM for all services
for svc in ai-service makeline-service order-service product-service store-admin store-front virtual-customer virtual-worker; do
  syft $svc:latest -o spdx-json > sbom-$svc.json
done
```

## 15.4 Cosign (Image Signing)

```bash
# Install
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Generate key pair
cosign generate-key-pair

# Sign image
cosign sign --key cosign.key 10.195.94.101:5000/ai-service:1.0.0

# Verify
cosign verify --key cosign.pub 10.195.94.101:5000/ai-service:1.0.0
```

## 15.5 Checkov (IaC Security Scanning)

```bash
# Install
pip3 install checkov

# Scan Terraform
checkov -d /home/antix/Videos/Store-App_Soruce_Code-GitHub/aws_eks_infrastructure/ \
  --framework terraform \
  --compact \
  --output cli
```

## 15.6 OPA Gatekeeper (K8s Policy Engine)

```bash
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml

# Wait for pods
kubectl wait --namespace gatekeeper-system \
  --for=condition=ready pod \
  --selector=control-plane=controller-manager \
  --timeout=120s

# Apply a sample constraint: require labels
cat <<EOF | kubectl apply -f -
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-app-label
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - default
  parameters:
    labels:
    - "app"
    - "version"
EOF
```

---

\newpage

# 16: Monitoring (Prometheus + Grafana)

## 16.1 Install kube-prometheus-stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.hosts[0]=grafana.yourdomain.com \
  --set grafana.ingress.tls[0].secretName=grafana-tls \
  --set grafana.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
  --set prometheus.ingress.enabled=true \
  --set prometheus.ingress.hosts[0]=prometheus.yourdomain.com \
  --set prometheus.ingress.tls[0].secretName=prometheus-tls \
  --set prometheus.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod \
  --set alertmanager.ingress.enabled=true \
  --set alertmanager.ingress.hosts[0]=alertmanager.yourdomain.com \
  --set alertmanager.ingress.tls[0].secretName=alertmanager-tls \
  --set alertmanager.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod
```

## 16.2 Access Dashboards

```bash
# Grafana
echo "https://grafana.yourdomain.com"
# Login: admin / admin

# Prometheus
echo "https://prometheus.yourdomain.com"

# Alertmanager
echo "https://alertmanager.yourdomain.com"
```

---

\newpage

# 17: Vault (Secrets Management)

## 17.1 Install Vault

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault -n vault --create-namespace \
  --set server.dev.enabled=true \
  --set server.ingress.enabled=true \
  --set server.ingress.hosts[0]=vault.yourdomain.com \
  --set server.ingress.tls[0].secretName=vault-tls \
  --set server.ingress.annotations."cert-manager\.io/cluster-issuer"=letsencrypt-prod
```

## 17.2 Initialize Vault

```bash
# Port-forward to access Vault UI
kubectl port-forward -n vault svc/vault 8200:8200 &

# Open https://vault.yourdomain.com in browser
# Or http://localhost:8200

# Unseal (dev mode — use root token)
kubectl exec -n vault vault-0 -- vault status
```

## 17.3 Access Vault

```bash
echo "https://vault.yourdomain.com"
# Dev mode: root token = "root"
```

---

\newpage

# 18: Deploy Microservices via ArgoCD

## 18.1 Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for pods:
```bash
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=120s
```

## 18.2 Create ArgoCD Ingress with TLS

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd
  namespace: argocd
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - argocd.yourdomain.com
    secretName: argocd-tls
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
```

## 18.3 Get ArgoCD Initial Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
```

## 18.4 Access ArgoCD

```bash
echo "https://argocd.yourdomain.com"
# Username: admin
# Password: (from command above)
```

## 18.5 Configure ArgoCD to Use Local Registry

Add your local registry as an image source in ArgoCD:

```bash
# In ArgoCD UI: Settings -> Repositories -> Connect
# Or via CLI:
argocd repo add http://10.195.94.101:5000 --username admin --password admin
```

## 18.6 Deploy Application

```bash
# Example: deploy ai-service from your Helm chart
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ai-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/Store-App_Soruce_Code-GitHub
    targetRevision: main
    path: helm-charts/ai-service
    helm:
      valueFiles:
      - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
```

Repeat for all 8 services:
- ai-service
- makeline-service
- order-service
- product-service
- store-front
- store-admin
- virtual-customer
- virtual-worker

## 18.7 Access Store Front

```bash
# Create Ingress for store-front
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: store-front
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - store.yourdomain.com
    secretName: store-front-tls
  rules:
  - host: store.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: store-front
            port:
              number: 8080
EOF
```

```bash
echo "https://store.yourdomain.com"
echo "https://admin.yourdomain.com"
```

---

\newpage

# Quick Reference — Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD | https://argocd.yourdomain.com | admin / (see 18.3) |
| Grafana | https://grafana.yourdomain.com | admin / admin |
| Prometheus | https://prometheus.yourdomain.com | - |
| Alertmanager | https://alertmanager.yourdomain.com | - |
| SonarQube | https://sonar.yourdomain.com | admin / admin |
| Vault | https://vault.yourdomain.com | root token = root |
| Store Front | https://store.yourdomain.com | - |
| Store Admin | https://admin.yourdomain.com | - |
| Registry | http://10.195.94.101:5000 | - |

---

\newpage

# Troubleshooting

## Worker 2 Can't Join Cluster

**Symptom:** `k3s-tf-worker-2` stays in `NotReady` or can't connect to master.

**Fix:**
1. Check VPN connectivity: `incus exec k3s-tf-worker-2 -- ping 10.195.94.80`
2. If ping fails, check Tailscale routes are advertised and approved
3. Check master's kubelet: `incus exec k3s-tf-master -- systemctl status k3s`
4. Check worker's agent: `incus exec k3s-tf-worker-2 -- systemctl status k3s-agent`

## Pods Stuck in Pending

**Symptom:** `kubectl get pods` shows pods in `Pending` state.

**Fix:**
1. Check node resources: `kubectl describe node <node-name>`
2. Check if PVCs are bound: `kubectl get pvc`
3. Check storage class: `kubectl get sc`

## cert-manager Not Issuing Certs

**Symptom:** TLS certificates stuck in `Pending` or `False`.

**Fix:**
1. Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
2. Verify ClusterIssuer: `kubectl get clusterissuer -o wide`
3. Check certificate status: `kubectl get certificate -A`

## Ingress Not Working

**Symptom:** Can't access services via domain name.

**Fix:**
1. Check ingress rules: `kubectl get ingress -A`
2. Check ingress controller: `kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx`
3. Verify DNS resolution: `nslookup grafana.yourdomain.com`
4. Test with IP directly: `curl -H "Host: grafana.yourdomain.com" http://10.195.94.100`

---

\newpage

# Command Reference

```bash
# Check cluster
kubectl get nodes -o wide
kubectl get pods -A

# Logs
stern -n <namespace> <app>
kubectl logs -f -n <namespace> <pod-name>

# Shell into pod
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Restart k3s
incus exec k3s-tf-master -- systemctl restart k3s
incus exec k3s-tf-worker-1 -- systemctl restart k3s
incus exec k3s-tf-worker-2 -- systemctl restart k3s-agent

# Helm
helm list -A
helm status <release> -n <namespace>
helm upgrade <release> <chart> -n <namespace>

# ArgoCD
argocd app list
argocd app sync <app-name>
argocd app get <app-name>
```
