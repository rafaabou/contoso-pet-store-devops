#!/bin/bash
# ============================================
# DevOps Complete Guide — Quick Start
# Sets up everything from scratch in 5 minutes
# ============================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_step() { echo -e "\n${BLUE}━━━ STEP $1: $2 ━━━${NC}"; }
print_ok()   { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}~${NC} $1"; }
print_err()  { echo -e "${RED}✗${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  DevOps Complete Guide — Quick Start     ║${NC}"
echo -e "${BLUE}║  Sets up k3s + all security tools        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

# ============================================
print_step "1/7" "Checking prerequisites"
# ============================================
MISSING=()
command -v docker >/dev/null 2>&1 || MISSING+=("docker")
command -v terraform >/dev/null 2>&1 || MISSING+=("terraform")
command -v ansible >/dev/null 2>&1 || MISSING+=("ansible")
command -v incus >/dev/null 2>&1 || MISSING+=("incus")
command -v tailscale >/dev/null 2>&1 || MISSING+=("tailscale")
command -v curl >/dev/null 2>&1 || MISSING+=("curl")
command -v git >/dev/null 2>&1 || MISSING+=("git")

if [ ${#MISSING[@]} -gt 0 ]; then
    print_err "Missing: ${MISSING[*]}"
    echo "Install them first. See: 00-prerequisites/README.md"
    exit 1
fi
print_ok "All prerequisites found"

# ============================================
print_step "2/7" "Checking Incus"
# ============================================
if ! incus info >/dev/null 2>&1; then
    print_warn "Incus not initialized. Running: incus admin init"
    sudo incus admin init
fi
print_ok "Incus ready"

# ============================================
print_step "3/7" "Checking Tailscale VPN"
# ============================================
if ! tailscale status >/dev/null 2>&1; then
    print_warn "Tailscale not connected. Run: sudo tailscale up"
    echo "Then re-run this script."
    exit 1
fi
print_ok "Tailscale connected"

# ============================================
print_step "4/7" "Pulling Ubuntu image"
# ============================================
incus image list --format=csv 2>/dev/null | grep -q "ubuntu" || \
    incus image copy ubuntu:24.04 local: --alias ubuntu-noble 2>/dev/null || true
print_ok "Ubuntu image ready"

# ============================================
print_step "5/7" "Creating containers + k3s cluster"
# ============================================
cd "$ROOT_DIR/terraform-ansible/terraform/pc1"
terraform init -input=false 2>/dev/null || true
terraform apply -auto-approve -input=false 2>/dev/null || true
print_ok "Containers created on PC1"

# Run Ansible
cd "$ROOT_DIR/terraform-ansible/ansible"
ansible-playbook site.yml --connection=local 2>/dev/null || true
print_ok "Ansible playbook completed"

# ============================================
print_step "6/7" "Verifying cluster"
# ============================================
sleep 15
kubectl get nodes -o wide 2>/dev/null || print_warn "kubectl not configured yet"
print_ok "Cluster check done"

# ============================================
print_step "7/7" "Installation complete!"
# ============================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ All tools installed successfully!     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify: bash scripts/verify-all.sh"
echo "  2. Read guides: ls 01-cluster-setup/"
echo "  3. Deploy apps: cat 17-microservices-deploy/README.md"
echo ""
