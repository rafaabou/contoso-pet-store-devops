#!/bin/bash
# ============================================
# DevOps Complete Guide — Verify All Tools
# Run this to check everything is working
# ============================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0

check() {
    if eval "$2" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1"
        ((FAIL++))
    fi
}

warn() {
    if eval "$2" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${YELLOW}~${NC} $1 (optional)"
        ((WARN++))
    fi
}

echo "============================================"
echo "  DevOps Tool Verification"
echo "============================================"
echo ""

# ---- Local Tools ----
echo "--- Local Tools ---"
check "Docker" "docker --version"
check "Terraform" "terraform --version"
check "Ansible" "ansible --version"
check "kubectl" "kubectl version --client"
check "Helm" "helm version"
check "Git" "git --version"
check "Gitleaks" "gitleaks version"
check "Hadolint" "hadolint --version"
check "Syft" "syft version"
check "Cosign" "cosign version"
check "Checkov" "checkov --version"
warn "Trivy" "trivy --version"
warn "Grype" "grype version"
warn "Semgrep" "semgrep --version"
echo ""

# ---- Kubernetes Cluster ----
echo "--- Kubernetes Cluster ---"
check "kubectl can connect" "kubectl cluster-info"
check "All nodes Ready" "kubectl get nodes --no-headers | grep -q Ready"
echo ""

# ---- Cluster Services ----
echo "--- Cluster Services ---"
check "MetalLB" "kubectl get ns metallb-system"
check "nginx-ingress" "kubectl get ns ingress-nginx"
check "cert-manager" "kubectl get ns cert-manager"
check "Prometheus" "kubectl get ns monitoring"
check "Vault" "kubectl get ns vault"
check "ArgoCD" "kubectl get ns argocd"
check "OPA Gatekeeper" "kubectl get ns gatekeeper-system"
check "Falco" "kubectl get ns falco"
echo ""

# ---- Pods ----
echo "--- Pod Status ---"
NOT_RUNNING=$(kubectl get pods -A --no-headers 2>/dev/null | grep -v Running | grep -v Completed | wc -l)
TOTAL=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All pods running (${TOTAL} total)"
    ((PASS++))
else
    echo -e "${RED}✗${NC} ${NOT_RUNNING} pods not running (out of ${TOTAL})"
    ((FAIL++))
fi
echo ""

# ---- Services ----
echo "--- LoadBalancer Services ---"
kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>/dev/null | while read -r line; do
    echo -e "${GREEN}✓${NC} $line"
done
echo ""

# ---- Summary ----
echo "============================================"
echo "  Results: ${PASS} passed, ${FAIL} failed, ${WARN} optional"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some checks failed. Run 'scripts/install-all.sh' to fix.${NC}"
    exit 1
else
    echo -e "${GREEN}All critical checks passed!${NC}"
    exit 0
fi
