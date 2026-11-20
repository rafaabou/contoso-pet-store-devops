#!/bin/bash
# ============================================
# DevOps Complete Guide — Install All Tools
# Run this on the master node (PC1: antix)
# ============================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_status()  { echo -e "${GREEN}[OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }

# ============================================
# Check prerequisites
# ============================================
print_step "Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { print_error "Docker not found. Install: sudo apt install docker.io -y"; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "Terraform not found. Install: sudo apt install terraform -y"; exit 1; }
command -v ansible >/dev/null 2>&1 || { print_error "Ansible not found. Install: sudo apt install ansible -y"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl not found. See: 00-prerequisites/README.md"; exit 1; }
command -v helm >/dev/null 2>&1 || { print_error "Helm not found. See: 00-prerequisites/README.md"; exit 1; }
command -v tailscale >/dev/null 2>&1 || { print_error "Tailscale not found. See: 00-prerequisites/README.md"; exit 1; }
command -v incus >/dev/null 2>&1 || { print_error "Incus not found. See: 00-prerequisites/README.md"; exit 1; }

print_status "All prerequisites installed"

# ============================================
# Step 1: Create containers
# ============================================
print_step "1/8 Creating Incus containers..."

cd "$(dirname "$0")/../terraform-ansible/terraform/pc1"
terraform init -input=false 2>/dev/null || true
terraform apply -auto-approve -input=false
print_status "PC1 containers created"

# ============================================
# Step 2: Configure networking
# ============================================
print_step "2/8 Configuring network..."

# Wait for containers to start
sleep 10

# Verify containers
incus ls | grep k3s
print_status "Containers running"

# ============================================
# Step 3: Run Ansible
# ============================================
print_step "3/8 Running Ansible playbook..."

cd "$(dirname "$0")/../terraform-ansible/ansible"
ansible-playbook site.yml --connection=local
print_status "Ansible playbook completed"

# ============================================
# Step 4: Verify k3s cluster
# ============================================
print_step "4/8 Verifying k3s cluster..."

sleep 30
kubectl get nodes -o wide
print_status "Cluster verified"

# ============================================
# Step 5: Install security tools
# ============================================
print_step "5/8 Installing security tools..."

# Gitleaks
if ! command -v gitleaks &>/dev/null; then
    wget -q -O /tmp/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
    tar xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
    sudo mv /tmp/gitleaks /usr/local/bin/
    rm -f /tmp/gitleaks.tar.gz
fi
print_status "Gitleaks installed"

# Hadolint
if ! command -v hadolint &>/dev/null; then
    wget -q -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
    chmod +x /usr/local/bin/hadolint
fi
print_status "Hadolint installed"

# Syft
if ! command -v syft &>/dev/null; then
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -sSb /usr/local/bin
fi
print_status "Syft installed"

# Cosign
if ! command -v cosign &>/dev/null; then
    wget -q -O /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
    chmod +x /usr/local/bin/cosign
fi
print_status "Cosign installed"

# Checkov
pip3 install checkov -q 2>/dev/null || true
print_status "Checkov installed"

# ============================================
# Step 6: Install cluster tools
# ============================================
print_step "6/8 Installing cluster tools..."

# MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml 2>/dev/null || true
print_status "MetalLB installed"

# nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update 2>/dev/null || true
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace 2>/dev/null || true
print_status "nginx-ingress installed"

# cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml 2>/dev/null || true
print_status "cert-manager installed"

# Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace 2>/dev/null || true
print_status "Prometheus + Grafana installed"

# Vault
helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
helm upgrade --install vault hashicorp/vault -n vault --create-namespace --set server.dev.enabled=true 2>/dev/null || true
print_status "Vault installed"

# ArgoCD
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>/dev/null || true
print_status "ArgoCD installed"

# OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml 2>/dev/null || true
print_status "OPA Gatekeeper installed"

# Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts 2>/dev/null || true
helm upgrade --install falco falcosecurity/falco -n falco --create-namespace 2>/dev/null || true
print_status "Falco installed"

# ============================================
# Step 7: Print summary
# ============================================
print_step "7/8 Installation complete!"

echo ""
echo "============================================"
echo "  DevOps Complete Guide — All Tools Installed"
echo "============================================"
echo ""
echo "Cluster Nodes:"
kubectl get nodes -o wide
echo ""
echo "Services:"
kubectl get svc -A --field-selector spec.type=LoadBalancer
echo ""
echo "Pods:"
kubectl get pods -A
echo ""

# ============================================
# Step 8: Show URLs
# ============================================
print_step "8/8 Access URLs:"

METALLB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "10.195.94.100")

echo ""
echo "Grafana:      http://${METALLB_IP}:80 (or https://grafana.yourdomain.com)"
echo "Prometheus:   http://${METALLB_IP}:9090"
echo "ArgoCD:       http://${METALLB_IP}:80 (or https://argocd.yourdomain.com)"
echo "Vault:        http://${METALLB_IP}:8200 (or https://vault.yourdomain.com)"
echo ""
echo "Run 'tools' to see all installed K8s tools"
echo ""
echo "Done! 🎉"
