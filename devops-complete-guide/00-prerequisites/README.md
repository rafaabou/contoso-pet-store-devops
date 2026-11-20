# Prerequisites — What You Need Before Starting

## Hardware Requirements

### Minimum Setup (2 PCs)
| Component | PC1 (antix) | PC2 (i3) |
|-----------|-------------|----------|
| CPU | Core Ultra 5 125U | i3 3rd gen |
| RAM | 14GB | 12GB |
| Disk | 50GB+ free | 50GB+ free |
| OS | Ubuntu 26.04 | Ubuntu/Debian |
| Network | WiFi 1 | WiFi 2 (different router) |
| Role | master + worker1 | worker2 |

### Single PC Setup (Minimum)
| Component | Minimum |
|-----------|---------|
| CPU | 4 cores |
| RAM | 8GB |
| Disk | 30GB free |
| OS | Ubuntu 22.04+ |

## Software Requirements

### Must Install
| Software | Version | Purpose |
|----------|---------|---------|
| Docker | 24+ | Container runtime |
| Terraform | 1.5+ | Infrastructure as Code |
| Ansible | 2.15+ | Configuration Management |
| kubectl | 1.30+ | Kubernetes CLI |
| Helm | 3.12+ | K8s package manager |
| Git | 2.40+ | Version control |

### Must Create Accounts
| Service | Purpose | Free Tier |
|---------|---------|-----------|
| GitHub | Source code + CI/CD | Yes |
| Tailscale | VPN between PCs | Yes (100 devices) |
| SonarCloud | Code quality scanning | Yes (public repos) |
| Docker Hub | Container registry | Yes (1 private repo) |
| Cloudflare | DNS management | Yes |
| Let's Encrypt | TLS certificates | Yes (unlimited) |

### Optional Accounts
| Service | Purpose | Cost |
|---------|---------|------|
| Snyk | Vulnerability scanning | Free (500 tests/month) |
| Datadog | APM + monitoring | Free (5 hosts, 14 days) |
| PagerDuty | Incident alerting | Free (5 users) |

## Network Requirements

### Ports to Open
| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH (Ansible) |
| 6443 | TCP | k3s API server |
| 80 | TCP | HTTP (ingress) |
| 443 | TCP | HTTPS (ingress) |
| 2379-2380 | TCP | etcd (k3s) |
| 8472 | UDP | VXLAN (k3s) |
| 10250 | TCP | kubelet |
| 5000 | TCP | Docker registry |
| 8200 | TCP | Vault |
| 9000 | TCP | SonarQube |
| 30000-32767 | TCP | NodePort services |

### Firewall Rules (UFW)
```bash
# On PC1
sudo ufw allow 22/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 8200/tcp
sudo ufw allow 9000/tcp
sudo ufw allow 30000:32767/tcp
sudo ufw enable
```

## DNS Requirements

### Domain Records
You need a domain name (e.g., `yourdomain.com`). Create these DNS records:

| Host | Type | Value | TTL |
|------|------|-------|-----|
| `@` | A | 10.195.94.100 | Auto |
| `*` | A | 10.195.94.100 | Auto |

The wildcard record (`*.yourdomain.com`) points all subdomains to your ingress IP.

## Step-by-Step Prerequisites Setup

### Step 1: Install Docker
```bash
# On both PCs
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
# Log out and back in for group changes
```

### Step 2: Install Terraform
```bash
# On both PCs
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
```

### Step 3: Install Ansible
```bash
# On both PCs
sudo apt install ansible -y
```

### Step 4: Install kubectl
```bash
# On both PCs
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Step 5: Install Helm
```bash
# On both PCs
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Step 6: Install Tailscale
```bash
# On both PCs
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Step 7: Install Incus
```bash
# On both PCs
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
echo 'Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: resolute
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/zabbly.asc' | sudo tee /etc/apt/sources.list.d/zabbly-incus-stable.sources
sudo apt update && sudo apt install incus incus-ui-canonical -y
sudo usermod -aG incus-admin $USER
newgrp incus-admin
```

### Step 8: Verify Everything
```bash
# Run this script to verify all prerequisites
docker --version
terraform --version
ansible --version
kubectl version --client
helm version
tailscale version
incus version
git --version
```

## Troubleshooting Prerequisites

### Docker permission denied
```bash
# After adding user to docker group, log out and back in
# Or use:
newgrp docker
```

### kubectl can't connect to cluster
```bash
# Make sure kubeconfig exists
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### Terraform Incus provider error
```bash
# Make sure Incus is running
incus admin init  # if not initialized
incus info        # verify it's running
```

### Ansible SSH connection refused
```bash
# Make sure SSH is running on all nodes
sudo systemctl enable ssh
sudo systemctl start ssh
# And that root login is allowed
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```
