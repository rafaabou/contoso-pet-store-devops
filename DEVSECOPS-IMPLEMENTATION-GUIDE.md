# DevSecOps Implementation Guide

## Complete Hands-On Guide for the Contoso Pet Store Application

**Target Application:** Store-App_Soruce_Code-GitHub (GenAiStoreApp)
**Author:** Generated for local 2-PC k3s cluster
**Last Updated:** September 2026

---

# Table of Contents

1. [Project Overview + Security Gap Analysis](#section-1-project-overview)
2. [Complete DevSecOps Tool Map](#section-2-complete-devsecops-tool-map)
3. [Cluster Setup (2 PCs)](#section-3-cluster-setup)
4. [Secret Scanning — Gitleaks](#section-4-secret-scanning)
5. [Dockerfile Security — Hadolint](#section-5-dockerfile-security)
6. [Container Security — Trivy + SBOM + Cosign](#section-6-container-security)
7. [Dependency Security — Dependabot + Snyk](#section-7-dependency-security)
8. [Infrastructure Security — Checkov](#section-8-infrastructure-security)
9. [Kubernetes Policy — OPA Gatekeeper](#section-9-kubernetes-policy)
10. [Network Policies — Microsegmentation](#section-10-network-policies)
11. [Runtime Security — Falco](#section-11-runtime-security)
12. [Pod Security Standards + RBAC](#section-12-pod-security-rbac)
13. [Secrets Management — Vault + Sealed Secrets](#section-13-secrets-management)
14. [Complete CI/CD Pipeline](#section-14-complete-cicd-pipeline)
15. [Incident Response + Chaos Testing](#section-15-incident-chaos)
16. [Appendix A: Install Commands One-Liner](#appendix-a-install-commands)
17. [Appendix B: File-by-File Mapping](#appendix-b-file-mapping)
18. [Appendix C: Troubleshooting](#appendix-c-troubleshooting)

---

\newpage

# 1: Project Overview

## 1.1 Your Application Architecture

The Contoso Pet Store is a polyglot microservices e-commerce application with 8 services:

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│   store-front (Vue.js 3, port 8080)                            │
│   store-admin (Vue.js 3, port 8081)                            │
└──────────┬──────────────────────────┬──────────────────────────┘
           │                          │
           ▼                          ▼
┌─────────────────────┐    ┌─────────────────────────────┐
│   product-service   │    │      order-service           │
│  (Rust/Actix,3002)  │    │   (Node/Fastify, 3000)       │
│  + WASM rules       │    │   + RabbitMQ publisher        │
└────────┬────────────┘    └─────────────┬───────────────┘
         │                               │
         ▼                               ▼
┌─────────────────────┐    ┌─────────────────────────────┐
│    ai-service       │    │       RabbitMQ               │
│ (Python/FastAPI,    │    │  (AMQP message queue)        │
│  port 5001)         │    └─────────────┬───────────────┘
│  Azure OpenAI/LLM   │                  │
└─────────────────────┘                  ▼
                              ┌─────────────────────────────┐
                              │    makeline-service          │
                              │    (Go/Gin, port 3001)       │
                              │    Queue consumer + DB        │
                              └─────────────┬───────────────┘
                                            │
                                            ▼
                              ┌─────────────────────────────┐
                              │       MongoDB                │
                              │    (Order persistence)       │
                              └─────────────────────────────┘

  ┌──────────────────────┐     ┌──────────────────────┐
  │  virtual-customer    │     │   virtual-worker      │
  │  (Rust, simulator)   │     │   (Rust, simulator)   │
  │  Sends random orders │     │   Processes orders    │
  └──────────────────────┘     └──────────────────────┘
```

## 1.2 Languages and Frameworks

| Service | Language | Framework | Port |
|---------|----------|-----------|------|
| ai-service | Python 3.12 | FastAPI + Semantic Kernel | 5001 |
| makeline-service | Go 1.22 | Gin + dd-trace-go | 3001 |
| order-service | Node.js 18 | Fastify 4 + rhea (AMQP) | 3000 |
| product-service | Rust 2021 | Actix-Web 4 + Wasmtime 15 | 3002 |
| store-front | Vue.js 3 | Vue Router + nginx | 8080 |
| store-admin | Vue.js 3 | Vue Router + nginx | 8081 |
| virtual-customer | Rust 2021 | reqwest | N/A |
| virtual-worker | Rust 2021 | reqwest | N/A |

## 1.3 Security Gap Analysis

### What You ALREADY HAVE

| Tool | Where | File |
|------|-------|------|
| SonarCloud (SAST) | CI workflow | `github/workflows/*.yaml` |
| OWASP Dependency Check | CI workflow | `github/workflows/*.yaml` |
| Trivy image scan | CI workflow | `github/workflows/*.yaml` |
| Helm charts | All 8 services | `helm-charts/*/` |
| ArgoCD + Rollouts | GitOps | `Deployment_Automation/` |
| Argo Image Updater | Auto-update images | `Deployment_Automation/` |
| Istio service mesh | Traffic management | `Istio_Service_mesh/` |
| Prometheus + Grafana | Monitoring | `monitoring/` |
| Jaeger + Kiali | Tracing + mesh viz | `observability/` |
| Loki | Log aggregation | `observability/loki/` |
| EFK stack | Logging | `logging/EFK_Logging/` |
| Vault + PostgreSQL | Secrets | `vault_pgsql_sonarqube/` |
| Terraform | AWS EKS provisioning | `aws_eks_infrastructure/` |
| Datadog | APM + RUM | `monitoring/datadog/` |

### What's MISSING (12 gaps)

| Gap | Why It Matters | Priority |
|-----|---------------|----------|
| Gitleaks / TruffleHog | No secret scanning — API keys can leak to Git | CRITICAL |
| Hadolint | No Dockerfile linting — insecure configs slip through | HIGH |
| Syft (SBOM) | No software bill of materials — can't track dependencies | HIGH |
| Cosign (image signing) | No image integrity verification — supply chain risk | HIGH |
| Checkov (IaC scan) | No Terraform security scanning before apply | HIGH |
| OPA Gatekeeper | No K8s admission control — any manifest can deploy | HIGH |
| Network Policies | No microsegmentation — pods can talk to anything | MEDIUM |
| Pod Security Standards | No container restriction — privileged pods possible | MEDIUM |
| Falco | No runtime threat detection — can't catch attacks in real-time | MEDIUM |
| Dependabot | No auto dependency updates — manual tracking needed | MEDIUM |
| Sealed Secrets | No encrypted secrets in Git — plaintext risk | MEDIUM |
| Incident Runbooks | No documented response procedures | LOW |

---

\newpage

# 2: Complete DevSecOps Tool Map

## 2.1 Full Tool Map — By Pipeline Layer

### CODE

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| SonarQube/SonarCloud | SAST — code quality + security bugs | push/PR | [YES] |
| Semgrep | Pattern-based security scanning | PR | ADD |
| Gitleaks | Detect hardcoded secrets | commit/PR | ADD |
| TruffleHog | Secret scanning with entropy detection | PR | Nice to have |
| Hadolint | Dockerfile linting | Dockerfile change | ADD |
| ESLint/PyLint | Language-specific linting with security rules | push | Nice to have |

### DEPENDENCIES

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Dependabot | Auto-detect outdated/vulnerable deps | daily scan + PR | ADD |
| Renovate | Alternative to Dependabot | daily scan + PR | Nice to have |
| Snyk | Open source vulnerability + license scan | build | ADD |
| OWASP Dependency Check | Dependency vulnerability scanning | build | [YES] |
| OSV-Scanner | Google's open source vuln scanner | build | Nice to have |

### BUILD

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| GitHub Actions | CI/CD pipeline orchestration | push/PR | [YES] |
| Act | Run GitHub Actions locally | local testing | Nice to have |
| BuildKit | Secure Docker builds with secret mounting | docker build | Nice to have |

### CONTAINER

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Trivy | Scan images for CVEs | after image build | [YES] |
| Grype | Alternative image scanner (Anchore) | after image build | Nice to have |
| Syft | Generate SBOM (Software Bill of Materials) | after image build | ADD |
| Cosign (Sigstore) | Sign images — verify integrity | after push | ADD |
| Notary | Alternative image signing | after push | Nice to have |
| Distroless base images | Minimal attack surface (no shell) | docker build | ADD |
| Non-root user | Containers must not run as root | docker build | ADD |

### INFRASTRUCTURE

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Terraform | Infrastructure as Code provisioning | before deploy | [YES] |
| Checkov | Scan Terraform for misconfigurations | before apply | ADD |
| tfsec | Terraform security scanner (alternative) | before apply | Nice to have |
| Trivy IaC | Scan YAML + Terraform for misconfigs | before apply | Nice to have |

### K8S POLICY

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| OPA Gatekeeper | Policy-as-code admission controller | kubectl apply | ADD |
| Conftest | Test K8s manifests against OPA policies | CI pipeline | ADD |
| Kyverno | K8s-native policy engine (easier than OPA) | pod creation | Nice to have |
| Pod Security Standards | Restrict privileged containers | cluster-wide | ADD |
| Network Policies | Microsegmentation — pod-to-pod traffic | cluster-wide | ADD |
| RBAC | Role-based access control — least privilege | cluster-wide | ADD |

### SECRETS

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| HashiCorp Vault | Centralized secrets management | runtime injection | [YES] |
| Vault Agent Injector | Auto-inject secrets into pods via sidecar | pod startup | ADD |
| Vault Dynamic Secrets | Short-lived DB credentials (auto-rotate) | on demand | ADD |
| Sealed Secrets | Encrypt secrets for safe Git storage | in Git repo | ADD |
| SOPS | Alternative secret encryption (Mozilla) | in Git repo | Nice to have |

### CI/CD + GITOPS

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| ArgoCD | GitOps — declarative deploys from Git | continuous sync | [YES] |
| Argo Rollouts | Canary + Blue-Green deployment strategies | during deploy | [YES] |
| Argo Image Updater | Auto-update images in Git | new image push | [YES] |
| Helm Charts | Package + version K8s manifests | before deploy | [YES] |
| Kustomize | Override configs per environment | before deploy | Nice to have |

### SERVICE MESH

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Istio | mTLS, traffic management, observability | cluster-wide | [YES] |
| Kiali | Istio service mesh dashboard | monitoring | [YES] |

### MONITORING

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Prometheus | Metrics collection + alerting | cluster-wide | [YES] |
| Grafana | Metrics dashboards + visualization | monitoring | [YES] |
| Alertmanager | Alert routing (Slack, PagerDuty, email) | alert management | [YES] |
| Datadog | APM + RUM + infrastructure monitoring | cluster-wide | [YES] |
| Node Exporter | Host-level metrics (CPU, RAM, disk) | every node | [YES] |
| kube-state-metrics | K8s object state metrics | cluster-wide | [YES] |

### LOGGING

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Elasticsearch | Log storage + search engine | cluster-wide | [YES] |
| Fluentd | Log processing + transformation | log pipeline | [YES] |
| Kibana | Log visualization + search UI | monitoring | [YES] |
| Loki | Alternative to ELK — lighter, label-based | cluster-wide | [YES] |

### TRACING

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Jaeger | Distributed tracing across microservices | cluster-wide | [YES] |
| OpenTelemetry | Vendor-neutral telemetry collection | cluster-wide | [YES] |

### RUNTIME SECURITY

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Falco | Runtime threat detection (syscall monitoring) | cluster-wide | ADD |
| Tetragon | eBPF kernel-level observability + enforcement | cluster-wide | Nice to have |
| AppArmor | Mandatory access control for containers | every node | ADD |
| Seccomp | System call filtering for containers | every pod | ADD |

### CHAOS + INCIDENT

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| Litmus Chaos | Inject failures (pod kill, network, disk) | testing | ADD |
| Chaos Monkey | Random instance termination | testing | Nice to have |
| Runbooks | Step-by-step incident response docs | documentation | ADD |

### COMPLIANCE

| Tool | Purpose | When | Status |
|------|---------|------|--------|
| CIS Benchmark | K8s security best practices audit | periodic scan | Nice to have |
| kube-bench | Automated CIS Benchmark checks | periodic scan | Nice to have |

## 2.2 Quick Reference — By Phase

| Phase | Tools to Install | Status |
|-------|-----------------|--------|
| Cluster | k3s, kubectl, helm | Plan to install |
| Ingress | MetalLB, nginx-ingress | Plan to install |
| Registry | Harbor or local registry | Plan to install |
| Code Security | SonarQube, Semgrep, Gitleaks | SonarQube [YES], others to add |
| Dependencies | Dependabot, Snyk | To add |
| Container Security | Trivy, Syft, Cosign, Hadolint | Trivy [YES], others to add |
| IaC Security | Checkov, tfsec | To add |
| Policy | OPA Gatekeeper, Conftest | To add |
| Secrets | Vault | [YES] You have this |
| CI/CD | ArgoCD, Argo Rollouts | [YES] You have this |
| Service Mesh | Istio, Kiali | [YES] You have this |
| Monitoring | Prometheus, Grafana, Alertmanager | [YES] You have this |
| Logging | ELK or Loki | [YES] You have this |
| Tracing | Jaeger, OpenTelemetry | [YES] You have this |
| Runtime | Falco, AppArmor, Seccomp | To add |
| Chaos | Litmus Chaos | To add |

## 2.3 Install Order (Recommended)

```
 1. k3s cluster (master + worker)
 2. MetalLB + nginx-ingress
 3. Local Docker registry
 4. Vault (secrets management)
 5. SonarQube (code scanning)
 6. OPA Gatekeeper (policy engine)
 7. Istio (service mesh)
 8. ArgoCD + Argo Rollouts (GitOps)
 9. Prometheus + Grafana (monitoring)
10. ELK or Loki (logging)
11. Jaeger + OpenTelemetry (tracing)
12. Falco (runtime security)
13. Microservices project (deploy all 8 apps)
14. CI/CD pipeline (GitHub Actions + all security scans)
15. GitOps apps (ArgoCD syncs everything)
16. Chaos testing (Litmus experiments)
```

## 2.4 One-Liner Quick Install

```bash
# ============================================
# ON ANTIX (MASTER NODE)
# ============================================

# 1. Install k3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644" sh -

# 2. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 3. Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 4. MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# 5. nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# 6. Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace --set server.dev.enabled=true

# 7. SonarQube
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm install sonarqube sonarqube/sonarqube -n sonarqube --create-namespace

# 8. OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml

# 9. Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-* && export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# 10. ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 11. Argo Rollouts
kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 12. Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# 13. Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace

# 14. Jaeger
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/latest/download/jaeger-operator.yaml \
  -n jaeger --create-namespace

# ============================================
# ON PC2 (WORKER NODE)
# ============================================

# Get join token from antix
# sudo cat /var/lib/rancher/k3s/server/node-token

# Install k3s agent
curl -sfL https://get.k3s.io | K3S_URL=https://<ANTIX_IP>:6443 \
  K3S_TOKEN=<TOKEN> sh -

# Install Docker (for self-hosted GitHub Actions runner)
sudo apt install docker.io -y
sudo usermod -aG docker $USER
```

---

\newpage

# 3: Cluster Setup

## 3.1 Hardware Overview

| | antix (Master) | PC2 (Worker) |
|---|---|---|
| CPU | Core Ultra 5 125U | i3 3rd gen |
| RAM | 14GB | 12GB |
| OS | Ubuntu 26.04 | Ubuntu/Debian |
| Role | k3s server + control plane | k3s agent + workloads |
| IP | 192.168.1.x (WiFi) | 192.168.1.y (LAN) |

## 3.2 Install k3s Master (on antix)

```bash
# Install k3s with traefik and servicelb disabled (we'll use nginx-ingress + MetalLB)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644 \
  --tls-san=$(hostname -I | awk '{print $1}')" sh -

# Copy kubeconfig to your user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Verify
kubectl get nodes
```

## 3.3 Install k3s Worker (on PC2)

```bash
# First, get the join token from antix
# Run on antix: sudo cat /var/lib/rancher/k3s/server/node-token

# Then on PC2:
curl -sfL https://get.k3s.io | K3S_URL=https://<ANTIX_IP>:6443 \
  K3S_TOKEN=<PASTE_TOKEN_HERE> sh -

# On antix, verify both nodes are ready
kubectl get nodes -o wide
# Should show:
# NAME     STATUS   ROLES                  AGE   VERSION   INTERNAL-IP
# antix    Ready    control-plane,master   5m    v1.30.x   192.168.1.x
# pc2      Ready    <none>                 2m    v1.30.x   192.168.1.y
```

## 3.4 Install kubectl and Helm (on antix)

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
kubectl version --client
helm version
```

## 3.5 MetalLB (LoadBalancer for bare metal)

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Wait for pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Configure IP pool (use IPs from your LAN that are NOT DHCP-assigned)
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-address-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.200-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
```

## 3.6 nginx-ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace

# Get the external IP
kubectl get svc -n ingress-nginx
# Use this IP to access all services via hostname
```

---

\newpage

# 4: Secret Scanning — Gitleaks

## 4.1 What It Does

Gitleaks scans your Git repository for hardcoded secrets like API keys, passwords, tokens, and connection strings. It catches secrets BEFORE they're committed.

## 4.2 Install

```bash
# On your development machine
sudo apt install gitleaks -y
# OR
brew install gitleaks  # macOS
# OR download binary
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

## 4.3 Configuration — `.gitleaks.toml`

Create this file in your project root:

```toml
# .gitleaks.toml
title = "Gitleaks config for Contoso Pet Store"

[allowlist]
  description = "Global allowlist"
  # Ignore test files and false positives
  paths = [
    '''dlls''',
    '''node_modules''',
    '''vendor''',
    '''target''',
    '''\.sum$''',
    '''helm-charts/.*templates/.*''',
  ]
  # Ignore specific rules
  regexes = [
    '''^test$''',
    '''^example$''',
    '''^placeholder$''',
  ]

[[rules]]
  id = "aws-access-key"
  description = "AWS Access Key"
  regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
  tags = ["key", "AWS"]

[[rules]]
  id = "aws-secret-key"
  description = "AWS Secret Access Key"
  regex = '''(?i)aws(.{0,20})?[\"'][0-9a-zA-Z/+]{40}["\']'''
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

[[rules]]
  id = "private-key"
  description = "Private Key"
  regex = '''-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY-----'''
  tags = ["key", "Private"]
```

## 4.4 Run Manually

```bash
# Scan entire repo
gitleaks detect --source /home/antix/Videos/Store-App_Soruce_Code-GitHub -v

# Scan with specific config
gitleaks detect --source . --config .gitleaks.toml -v

# Scan only staged files (pre-commit)
gitleaks protect --staged -v
```

## 4.5 Add to GitHub Actions

Add this job to each workflow file in `github/workflows/`:

```yaml
  # ==========================================
  # JOB 0: Secret Scanning (add BEFORE sonarqube-analysis)
  # ==========================================
  secret-scan:
    name: Secret Scanning (Gitleaks)
    runs-on: self-hosted
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Gitleaks Report Summary
        if: always()
        run: |
          echo "### Gitleaks Secret Scan Complete" >> $GITHUB_STEP_SUMMARY
```

Then update the `needs` array of `sonarqube-analysis` to include `secret-scan`:

```yaml
  sonarqube-analysis:
    name: SonarQube Code Analysis
    runs-on: self-hosted
    needs: [secret-scan]  # ADD THIS
    ...
```

## 4.6 Pre-commit Hook (Optional)

```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
EOF

# Install the hook
pre-commit install
```

---

\newpage

# 5: Dockerfile Security — Hadolint

## 5.1 What It Does

Hadolint lints your Dockerfiles against best practices: running as non-root, pinning versions, minimizing layers, avoiding `apk update` without version pins.

## 5.2 Install

```bash
# Docker-based (recommended)
docker pull hadolint/hadolint

# Binary download
wget https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64
sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint
```

## 5.3 Lint Your Dockerfiles

```bash
# Lint all Dockerfiles
for f in $(find src/ -name Dockerfile); do
  echo "=== $f ==="
  hadolint "$f"
  echo ""
done
```

## 5.4 Issues Found in Your Project

### ai-service/Dockerfile — Problems:

```dockerfile
# PROBLEM 1: No version pin on system packages
FROM python:3.12.4-alpine
RUN apk update && apk add --no-cache gcc musl-dev libffi-dev  # unpinned

# PROBLEM 2: Runs as root (no USER directive)
# PROBLEM 3: No HEALTHCHECK
# PROBLEM 4: Single-stage build (larger image)
```

### Fix — ai-service/Dockerfile:

```dockerfile
# STAGE 1: Build
FROM python:3.12.4-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# STAGE 2: Runtime (minimal)
FROM python:3.12.4-alpine
RUN apk add --no-cache gcc musl-dev libffi-dev \
    && addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost:5001/health || exit 1
CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5001"]
```

### order-service/Dockerfile — Problems:

```dockerfile
# PROBLEM: Runs as root, no HEALTHCHECK
FROM node:18.20.4-alpine
```

### Fix — order-service/Dockerfile:

```dockerfile
FROM node:18.20.4-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /usr/src/app
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost:3000/health || exit 1
CMD ["node", "app.js"]
```

### Apply same pattern to ALL 8 Dockerfiles:
- `src/makeline-service/Dockerfile`
- `src/product-service/Dockerfile`
- `src/store-admin/Dockerfile`
- `src/store-front/Dockerfile`
- `src/virtual-customer/Dockerfile`
- `src/virtual-worker/Dockerfile`

## 5.5 Hadolint Configuration — `.hadolint.yaml`

Create in project root:

```yaml
# .hadolint.yaml
ignored:
  - DL3008  # Pin versions in apt-get install
  - DL3013  # Pin versions in pip install

trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io

override:
  warning:
    - DL3007  # Using latest is not allowed
    - DL3028  # Pin versions in gem install
```

## 5.6 Add to GitHub Actions

```yaml
  # Add to each workflow, BEFORE Docker build
  hadolint:
    name: Dockerfile Lint (Hadolint)
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run Hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: ${{ env.SERVICE_PATH }}/Dockerfile
          failure-threshold: warning
```

---

\newpage

# 6: Container Security — Trivy + SBOM + Cosign

## 6.1 SBOM Generation — Syft

### What It Does
Syft creates a Software Bill of Materials (SBOM) — a complete inventory of every package, library, and dependency inside your container image.

### Install

```bash
# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -sSb /usr/local/bin

# Verify
syft version
```

### Generate SBOM

```bash
# Generate SBOM for your image
syft ai-service:latest -o spdx-json > sbom-ai-service.json

# Generate SBOM for all services
for svc in ai-service makeline-service order-service product-service store-admin store-front virtual-customer virtual-worker; do
  echo "Generating SBOM for $svc..."
  syft $svc:latest -o spdx-json > sbom-$svc.json
done

# Scan SBOM for vulnerabilities with Grype
grype sbom:sbom-ai-service.json --fail-on high
```

### Add to GitHub Actions

```yaml
  # After Trivy scan, before push to ECR
  - name: Generate SBOM
    run: |
      syft ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} \
        -o spdx-json > trivy-reports/sbom-${{ env.SERVICE_NAME }}.json
      echo "SBOM generated" >> $GITHUB_STEP_SUMMARY

  - name: Upload SBOM
    if: always()
    uses: actions/upload-artifact@v4
    with:
      name: sbom-${{ env.SERVICE_NAME }}-${{ github.run_number }}
      path: trivy-reports/sbom-${{ env.SERVICE_NAME }}.json
      retention-days: 90
```

## 6.2 Image Signing — Cosign

### What It Does
Cosign signs your container images cryptographically. ArgoCD can verify signatures before deploying — preventing tampered images from reaching production.

### Install

```bash
# Install Cosign
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Keyless signing (uses Sigstore/Fulcio — no key management needed)
cosign version
```

### Sign Images

```bash
# Keyless signing (recommended — uses your GitHub identity)
cosign sign $ECR_REGISTRY/ai-service:1.0.0-abc1234

# Or with a key
cosign generate-key-pair  # creates cosign.key and cosign.pub
cosign sign --key cosign.key $ECR_REGISTRY/ai-service:1.0.0-abc1234
```

### Verify Images

```bash
# Verify a signed image
cosign verify --key cosign.pub $ECR_REGISTRY/ai-service:1.0.0-abc1234

# Keyless verify
cosign verify $ECR_REGISTRY/ai-service:1.0.0-abc1234 \
  --certificate-identity=your-email@example.com \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

### Add to GitHub Actions

```yaml
  # After push to ECR
  - name: Sign Image with Cosign (keyless)
    run: |
      cosign sign ${{ env.ECR_REGISTRY }}/${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} \
        --yes
      echo "Image signed" >> $GITHUB_STEP_SUMMARY
    env:
      COSIGN_EXPERIMENTAL: 1
```

### ArgoCD Verification

Add to your ArgoCD Application manifests:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ai-service
spec:
  source:
    plugin:
      name: argocd-image-updater
  # Add signature verification
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

\newpage

# 7: Dependency Security — Dependabot + Snyk

## 7.1 Dependabot

### What It Does
Dependabot automatically detects outdated/vulnerable dependencies and creates PRs to update them.

### Configuration — `.github/dependabot.yml`

```yaml
version: 2
updates:
  # Python (ai-service)
  - package-ecosystem: "pip"
    directory: "/src/ai-service"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "python"

  # Go (makeline-service)
  - package-ecosystem: "gomod"
    directory: "/src/makeline-service"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "go"

  # Node.js (order-service, store-admin, store-front)
  - package-ecosystem: "npm"
    directory: "/src/order-service"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "npm"
    directory: "/src/store-admin"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/src/store-front"
    schedule:
      interval: "weekly"

  # Rust (product-service, virtual-customer, virtual-worker)
  - package-ecosystem: "cargo"
    directory: "/src/product-service"
    schedule:
      interval: "weekly"

  - package-ecosystem: "cargo"
    directory: "/src/virtual-customer"
    schedule:
      interval: "weekly"

  - package-ecosystem: "cargo"
    directory: "/src/virtual-worker"
    schedule:
      interval: "weekly"

  # Docker
  - package-ecosystem: "docker"
    directory: "/src/ai-service"
    schedule:
      interval: "weekly"

  # Terraform
  - package-ecosystem: "terraform"
    directory: "/aws_eks_infrastructure/Env/Dev"
    schedule:
      interval: "monthly"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## 7.2 Snyk

### What It Does
Snyk scans for open source vulnerabilities AND license compliance issues.

### Install

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate (free for public repos, requires token for private)
snyk auth
```

### Run Manually

```bash
# Test Python dependencies
cd src/ai-service
snyk test --file=requirements.txt

# Test Node.js dependencies
cd src/order-service
snyk test

# Test Go dependencies
cd src/makeline-service
snyk test

# Monitor (continuous monitoring on Snyk.io)
snyk monitor
```

### Add to GitHub Actions

```yaml
  # Add as new job
  snyk-scan:
    name: Snyk Vulnerability + License Scan
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/python@master
        continue-on-error: true  # Don't fail the build, just report
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --file=${{ env.SERVICE_PATH }}/requirements.txt --severity-threshold=high
```

---

\newpage

# 8: Infrastructure Security — Checkov

## 8.1 What It Does

Checkov scans Terraform, CloudFormation, and Kubernetes manifests for security misconfigurations. It catches issues like public S3 buckets, unencrypted databases, and overly permissive IAM policies.

## 8.2 Install

```bash
pip install checkov
```

## 8.3 Scan Your Terraform

```bash
# Scan the entire Terraform directory
checkov -d /home/antix/Videos/Store-App_Soruce_Code-GitHub/aws_eks_infrastructure/ \
  --framework terraform \
  --compact \
  --output cli

# Scan specific environment
checkov -d /home/antix/Videos/Store-App_Soruce_Code-GitHub/aws_eks_infrastructure/Env/Dev \
  --framework terraform

# Output as JSON for CI integration
checkov -d ./aws_eks_infrastructure/ \
  --framework terraform \
  --output json > checkov-report.json
```

## 8.4 Common Failures to Fix

| Check ID | Issue | Fix |
|----------|-------|-----|
| CKV_AWS_18 | S3 bucket no access logging | Add `logging { target_bucket = ... }` |
| CKV_AWS_19 | S3 bucket no server-side encryption | Add `server_side_encryption_configuration` |
| CKV_AWS_145 | RDS no IAM authentication | Add `iam_database_authentication_enabled = true` |
| CKV_AWS_39 | EKS cluster not using private endpoint | Set `endpoint_public_access = false` |
| CKV_AWS_58 | EKS secrets not encrypted | Add `encryption_config` block |
| CKV_AWS_7 | EBS volumes not encrypted | Add `encrypted = true` |
| CKV_AWS_3 | Security groups allow unrestricted ingress | Restrict CIDR blocks |

## 8.5 Add to Terraform Workflows

Update `github/workflows/eks_infra_deployment.yaml`:

```yaml
  # ADD this job before terraform-plan
  checkov-scan:
    name: Checkov IaC Security Scan
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: aws_eks_infrastructure/Env/Dev
          framework: terraform
          output_format: cli,sarif
          output_file_path: checkov-results.sarif
          soft_fail: false  # Set to true to not fail the pipeline
          skip_check: CKV_AWS_18,CKV_AWS_19  # Skip checks you accept

  # Then update terraform-plan to depend on checkov-scan
  terraform-plan:
    needs: [checkov-scan]
    ...
```

---

\newpage

# 9: Kubernetes Policy — OPA Gatekeeper

## 9.1 What It Does

OPA Gatekeeper is an admission controller that enforces policies on Kubernetes resources. It blocks deployments that violate your security rules (e.g., privileged containers, images without digest pinning, missing resource limits).

## 9.2 Install

```bash
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml

# Wait for pods
kubectl wait --namespace gatekeeper-system \
  --for=condition=ready pod \
  --selector=control-plane=controller-manager \
  --timeout=90s
```

## 9.3 Policy 1: No Privileged Containers

```yaml
# gatekeeper/policies/no-privileged.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spspprivilegedcontainer
spec:
  crd:
    spec:
      names:
        kind: K8sPSPPrivilegedContainer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spspprivilegedcontainer
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.privileged == true
          msg := sprintf("Privileged container '%v' is not allowed", [container.name])
        }
        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          container.securityContext.privileged == true
          msg := sprintf("Privileged init container '%v' is not allowed", [container.name])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPPrivilegedContainer
metadata:
  name: deny-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system"]
```

## 9.4 Policy 2: No Latest Image Tags

```yaml
# gatekeeper/policies/no-latest-tag.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sblocklatesttag
spec:
  crd:
    spec:
      names:
        kind: K8sBlockLatestTag
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sblocklatesttag
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          endswith(container.image, ":latest")
          msg := sprintf("Image '%v' uses ':latest' tag — use a specific version or digest", [container.image])
        }
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not contains(container.image, ":")
          msg := sprintf("Image '%v' has no tag — use a specific version or digest", [container.image])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBlockLatestTag
metadata:
  name: deny-latest-tag
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system"]
```

## 9.5 Policy 3: Resource Limits Required

```yaml
# gatekeeper/policies/require-resources.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredresources
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredResources
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredresources
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := sprintf("Container '%v' must have CPU limits", [container.name])
        }
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container '%v' must have memory limits", [container.name])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
metadata:
  name: require-resource-limits
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system", "monitoring"]
```

## 9.6 Test the Policies

```bash
# This should be REJECTED (privileged + latest tag)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-bad-pod
spec:
  containers:
  - name: bad
    image: nginx:latest
    securityContext:
      privileged: true
EOF
# Expected: Error from server (Forbidden): admission webhook denied the request

# This should be ALLOWED (secure pod)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-good-pod
spec:
  containers:
  - name: good
    image: nginx:1.25.3
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
EOF
```

## 9.7 Conftest (CI Pipeline Testing)

```bash
# Install Conftest
wget https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
tar xzf conftest_0.46.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/

# Test K8s manifests against OPA policies
conftest test helm-charts/ai-service/templates/ -p gatekeeper/policies/
```

---

\newpage

# 10: Network Policies — Microsegmentation

## 10.1 What It Does

Network Policies restrict which pods can communicate with each other. Without them, any pod can talk to any other pod — a compromised container could reach your database.

## 10.2 Default Deny All

```yaml
# network-policies/default-deny.yaml
# Apply to ALL namespaces
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: monitoring
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: argocd
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

## 10.3 Allow Specific Traffic Paths

```yaml
# network-policies/allow-store-front.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-store-front
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: store-front
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
    # Allow order-service
    - to:
        - podSelector:
            matchLabels:
              app: order-service
      ports:
        - port: 3000
    # Allow product-service
    - to:
        - podSelector:
            matchLabels:
              app: product-service
      ports:
        - port: 3002
```

```yaml
# network-policies/allow-order-service.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-order-service
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: order-service
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
    # Allow RabbitMQ
    - to:
        - podSelector:
            matchLabels:
              app: rabbitmq
      ports:
        - port: 5672
```

```yaml
# network-policies/allow-makeline-service.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-makeline-service
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: makeline-service
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
    # Allow RabbitMQ
    - to:
        - podSelector:
            matchLabels:
              app: rabbitmq
      ports:
        - port: 5672
    # Allow MongoDB
    - to:
        - podSelector:
            matchLabels:
              app: mongodb
      ports:
        - port: 27017
```

```yaml
# network-policies/allow-store-admin.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-store-admin
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: store-admin
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
      ports:
        - port: 53
          protocol: UDP
    # Allow all backend services
    - to:
        - podSelector:
            matchLabels:
              app: makeline-service
      ports:
        - port: 3001
    - to:
        - podSelector:
            matchLabels:
              app: order-service
      ports:
        - port: 3000
    - to:
        - podSelector:
            matchLabels:
              app: product-service
      ports:
        - port: 3002
    - to:
        - podSelector:
            matchLabels:
              app: ai-service
      ports:
        - port: 5001
```

## 10.4 Apply All Network Policies

```bash
kubectl apply -f network-policies/

# Verify policies are enforced
kubectl get networkpolicies --all-namespaces
```

---

\newpage

# 11: Runtime Security — Falco

## 11.1 What It Does

Falco monitors running containers in real-time by analyzing system calls. It detects threats like: crypto mining, shell spawning in containers, unexpected file access, privilege escalation.

## 11.2 Install

```bash
# Add Falco Helm repo
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install Falco with eBPF (modern kernels)
helm install falco falcosecurity/falco \
  -n falco --create-namespace \
  --set driver.kind=ebpf \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.slack.webhookurl="YOUR_SLACK_WEBHOOK_URL"

# Verify
kubectl get pods -n falco
```

## 11.3 Custom Rules for Your App

```yaml
# falco/custom-rules.yaml
- rule: Detect Shell in Container
  desc: Detect shell spawned inside a container (potential reverse shell)
  condition: >
    spawned_process and container and
    proc.name in (bash, sh, dash, zsh, csh, ksh)
    and not proc.pname in (sshd, sudo, docker-init)
  output: >
    Shell spawned in container
    (user=%user.name container=%container.name image=%container.image.repository
     shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline)
  priority: WARNING
  tags: [container, shell, mitre_execution]

- rule: Detect Crypto Mining
  desc: Detect crypto mining process in container
  condition: >
    spawned_process and container and
    proc.name in (xmrig, minerd, minergate, cpuminer, nbminer, t-rex)
  output: >
    Crypto mining detected
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: CRITICAL
  tags: [container, crypto, mitre_impact]

- rule: Unexpected Outbound Connection
  desc: Container making outbound connection to unusual port
  condition: >
    outbound and container and
    fd.typechar='4' and
    fd.sport != 80 and fd.sport != 443 and fd.sport != 5672
    and fd.sport != 27017 and fd.sport != 5001 and fd.sport != 3000
    and fd.sport != 3001 and fd.sport != 3002 and fd.sport != 8080
    and fd.sport != 8081 and fd.sport != 9090 and fd.sport != 30000
  output: >
    Unexpected outbound connection from container
    (container=%container.name image=%container.image.repository
     connection=%fd.name sport=%fd.sport)
  priority: WARNING
  tags: [container, network, mitre_command_and_control]

- rule: Write to /etc in Container
  desc: Container writing to /etc directory (possible persistence)
  condition: >
    open_write and container and
    fd.name startswith /etc and
    not fd.name startswith /etc/hosts and
    not fd.name startswith /etc/resolv.conf and
    not fd.name startswith /etc/passwd
  output: >
    Write to /etc in container
    (container=%container.name file=%fd.name user=%user.name)
  priority: WARNING
  tags: [container, filesystem, mitre_persistence]

- rule: Sensitive File Read in Container
  desc: Container reading sensitive files
  condition: >
    open_read and container and
    (fd.name = /etc/shadow or fd.name = /etc/sudoers or
     fd.name endswith .pem or fd.name endswith .key)
  output: >
    Sensitive file read in container
    (container=%container.name file=%fd.name user=%user.name)
  priority: WARNING
  tags: [container, filesystem, mitre_credential_access]
```

## 11.4 Deploy Custom Rules

```bash
# Create ConfigMap with custom rules
kubectl create configmap falco-custom-rules \
  --from-file=falco/custom-rules.yaml \
  -n falco

# Upgrade Falco to use custom rules
helm upgrade falco falcosecurity/falco \
  -n falco \
  --set-file customRules."rules\.yaml"=falco/custom-rules.yaml
```

## 11.5 Alert to Slack via Falcosidekick

```yaml
# falco/falcosidekick-values.yaml
falcosidekick:
  enabled: true
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
      channel: "#security-alerts"
      username: "Falco"
      footer: "Contoso Pet Store Security"
    alertmanager:
      hostport: "alertmanager.monitoring.svc.cluster.local:9093"
```

---

\newpage

# 12: Pod Security Standards + RBAC

## 12.1 Pod Security Standards

Apply these labels to your namespaces:

```bash
# Restrict pods in default namespace
kubectl label namespace default \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Allow privileged in monitoring (needed for some exporters)
kubectl label namespace monitoring \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted
```

## 12.2 Service Accounts (Least Privilege)

```yaml
# rbac/service-accounts.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ai-service-sa
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: order-service-sa
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: makeline-service-sa
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: product-service-sa
  namespace: default
```

Then reference in Helm charts:

```yaml
# In helm-charts/ai-service/templates/deployment.yaml
spec:
  template:
    spec:
      serviceAccountName: ai-service-sa
```

## 12.3 RBAC Roles

```yaml
# rbac/roles.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: service-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-reader-binding
  namespace: default
subjects:
  - kind: ServiceAccount
    name: ai-service-sa
    namespace: default
  - kind: ServiceAccount
    name: order-service-sa
    namespace: default
  - kind: ServiceAccount
    name: makeline-service-sa
    namespace: default
  - kind: ServiceAccount
    name: product-service-sa
    namespace: default
roleRef:
  kind: Role
  name: service-reader
  apiGroup: rbac.authorization.k8s.io
```

---

\newpage

# 13: Secrets Management — Vault + Sealed Secrets

## 13.1 Vault Agent Injector

Auto-inject secrets into pods without putting them in environment variables or YAML.

```yaml
# vault/agent-injector-values.yaml
global:
  enabled: true
injector:
  enabled: true
server:
  dev:
    enabled: true
```

```yaml
# vault/pod-with-vault.yaml
apiVersion: v1
kind: Pod
metadata:
  name: order-service
  labels:
    app: order-service
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "order-service"
    vault.hashicorp.com/agent-inject-secret-rabbitmq: "secret/data/rabbitmq"
    vault.hashicorp.com/agent-inject-template-rabbitmq: |
      {{- with secret "secret/data/rabbitmq" -}}
      RABBITMQ_HOST={{ .Data.data.host }}
      RABBITMQ_USER={{ .Data.data.username }}
      RABBITMQ_PASS={{ .Data.data.password }}
      {{- end }}
spec:
  serviceAccountName: order-service-sa
  containers:
    - name: order-service
      image: your-ecr/order-service:latest
      ports:
        - containerPort: 3000
```

## 13.2 Vault Dynamic Secrets (MongoDB)

```bash
# Enable database secrets engine
vault secrets enable database

# Configure MongoDB connection
vault write database/config/mongodb \
  plugin_name=mongodb-database-plugin \
  connection_url=mongodb://{{username}}:{{password}}@mongodb:27017 \
  allowed_roles="order-service-role" \
  username="admin" \
  password="your-password"

# Create a role that generates short-lived credentials
vault write database/roles/order-service-role \
  db_name=mongodb \
  creation_statements='{"db":"admin","roles":[{"role":"readWrite","db":"orders"}]}' \
  default_ttl="1h" \
  max_ttl="24h"

# Now your pod can request dynamic credentials:
vault read database/creds/order-service-role
# Returns: username=temp-user-xyz, password=temp-pass-abc (expires in 1 hour)
```

## 13.3 Sealed Secrets (Encrypt Secrets for Git)

```bash
# Install Sealed Secrets controller
helm repo add sealed-secrets https://charts.appuio.cloud
helm install sealed-secrets sealed-secrets/sealed-secrets \
  -n kube-system

# Install kubeseal CLI
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-linux-amd64
chmod +x kubeseal-linux-amd64
sudo mv kubeseal-linux-amd64 /usr/local/bin/kubeseal

# Create a regular secret
kubectl create secret generic order-service-secrets \
  --from-literal=rabbitmq-password=SuperSecret123 \
  --from-literal=mongodb-password=MongoSecret456 \
  --dry-run=yaml > order-service-secrets.yaml

# Seal it (encrypted — safe to commit to Git)
kubeseal --format yaml < order-service-secrets.yaml > order-service-sealed-secret.yaml

# Delete the plaintext secret
kubectl delete secret order-service-secrets

# Apply the sealed secret (controller decrypts it)
kubectl apply -f order-service-sealed-secret.yaml
```

---

\newpage

# 14: Complete CI/CD Pipeline

This is the FULL GitHub Actions workflow with ALL security steps integrated. Apply this pattern to all 8 services.

## 14.1 Complete Workflow — Example for ai-service

```yaml
# github/workflows/ai-service-complete.yaml
name: Store AI Service — Full DevSecOps Pipeline

on:
  workflow_dispatch: {}

env:
  SERVICE_NAME: ai-service
  SERVICE_PATH: src/ai-service
  AWS_REGION: us-east-1
  ECR_REGISTRY: ${{ secrets.ECR_REGISTRY }}
  SONAR_HOST_URL: https://sonarcloud.io
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  SONAR_ORGANIZATION: ${{ secrets.SONAR_ORGANIZATION }}
  PYTHON_VERSION: '3.12.3'

jobs:
  # ==========================================
  # JOB 1: Secret Scanning (Gitleaks)
  # ==========================================
  secret-scan:
    name: Secret Scanning (Gitleaks)
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # ==========================================
  # JOB 2: Dockerfile Linting (Hadolint)
  # ==========================================
  hadolint:
    name: Dockerfile Lint (Hadolint)
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run Hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: ${{ env.SERVICE_PATH }}/Dockerfile
          failure-threshold: warning

  # ==========================================
  # JOB 3: SonarQube Code Analysis
  # ==========================================
  sonarqube-analysis:
    name: SonarQube Code Analysis
    runs-on: self-hosted
    needs: [secret-scan, hadolint]
    outputs:
      version: ${{ steps.tag.outputs.version }}
      image_tag: ${{ steps.tag.outputs.image_tag }}
      short_sha: ${{ steps.tag.outputs.short_sha }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Generate Image Tag
        id: tag
        run: |
          SHORT_SHA=$(git rev-parse --short=7 HEAD || echo "nosha")
          LATEST_TAG=$(aws ecr describe-images \
            --repository-name "${{ env.SERVICE_NAME }}" \
            --region "${{ env.AWS_REGION }}" \
            --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
            --output text 2>/dev/null || echo "")
          if [ -z "${LATEST_TAG}" ] || [ "${LATEST_TAG}" = "None" ]; then
            BASE_VERSION="1.0.0"
          else
            [[ ${LATEST_TAG} =~ ^([0-9]+\.[0-9]+\.[0-9]+) ]] && BASE_VERSION="${BASH_REMATCH[1]}" || BASE_VERSION="1.0.0"
          fi
          IFS='.' read -r major minor patch <<< "${BASE_VERSION}"
          VERSION="${major}.${minor}.$(( ${patch:-0} + 1 ))"
          IMAGE_TAG="${VERSION}-${SHORT_SHA}"
          echo "image_tag=${IMAGE_TAG}" >> "$GITHUB_OUTPUT"
          echo "short_sha=${SHORT_SHA}" >> "$GITHUB_OUTPUT"
          echo "version=${VERSION}" >> "$GITHUB_OUTPUT"
      - name: SonarCloud Analysis
        working-directory: ${{ env.SERVICE_PATH }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=ai-service-app \
            -Dsonar.organization=${{ env.SONAR_ORGANIZATION }} \
            -Dsonar.host.url=${{ env.SONAR_HOST_URL }} \
            -Dsonar.token=${{ env.SONAR_TOKEN }} \
            -Dsonar.projectVersion=${{ steps.tag.outputs.version }}

  # ==========================================
  # JOB 4: OWASP Dependency Check
  # ==========================================
  owasp-dependency-check:
    name: OWASP Dependency Check
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: OWASP Dependency Check
        working-directory: ${{ env.SERVICE_PATH }}
        run: |
          mkdir -p dependency-check-report
          dependency-check.sh \
            --project "${{ env.SERVICE_NAME }}" \
            --scan . --format ALL \
            --out ./dependency-check-report \
            --enableExperimental --disableOssIndex || true

  # ==========================================
  # JOB 5: Snyk Vulnerability + License Scan
  # ==========================================
  snyk-scan:
    name: Snyk Vulnerability Scan
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Run Snyk
        uses: snyk/actions/python@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --file=${{ env.SERVICE_PATH }}/requirements.txt --severity-threshold=high

  # ==========================================
  # JOB 6: Build, Scan, Sign, Push
  # ==========================================
  build-scan-push:
    name: Build, Trivy Scan, SBOM, Sign & Push
    runs-on: self-hosted
    needs: [sonarqube-analysis, owasp-dependency-check, snyk-scan]
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      # --- Build ---
      - name: Build Docker Image
        working-directory: ${{ env.SERVICE_PATH }}
        run: |
          docker build --no-cache \
            -t ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} \
            --build-arg VERSION=${{ needs.sonarqube-analysis.outputs.version }} .

      # --- Trivy Scan ---
      - name: Create Reports Directory
        run: mkdir -p trivy-reports
      - name: Trivy Scan - Table
        run: trivy image --severity HIGH,CRITICAL --format table \
          --output trivy-reports/trivy-table.txt \
          ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} || true
      - name: Trivy Scan - SARIF
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }}
          format: sarif
          output: trivy-reports/trivy.sarif
          severity: CRITICAL,HIGH
      - name: Upload Trivy Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: trivy-${{ env.SERVICE_NAME }}-${{ github.run_number }}
          path: trivy-reports/

      # --- SBOM ---
      - name: Generate SBOM (Syft)
        run: |
          syft ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} \
            -o spdx-json > trivy-reports/sbom.json
          echo "SBOM generated" >> $GITHUB_STEP_SUMMARY
      - name: Upload SBOM
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: sbom-${{ env.SERVICE_NAME }}-${{ github.run_number }}
          path: trivy-reports/sbom.json

      # --- Tag & Push ---
      - name: Tag for ECR
        run: |
          docker tag ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} \
            ${{ env.ECR_REGISTRY }}/${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }}
      - name: Configure AWS Credentials
        run: aws ecr get-login-password --region ${{ env.AWS_REGION }} | \
          docker login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}
      - name: Push to ECR
        run: docker push ${{ env.ECR_REGISTRY }}/${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }}

      # --- Sign Image ---
      - name: Sign Image (Cosign keyless)
        run: |
          cosign sign ${{ env.ECR_REGISTRY }}/${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} --yes
          echo "Image signed" >> $GITHUB_STEP_SUMMARY
        env:
          COSIGN_EXPERIMENTAL: 1

      # --- Cleanup ---
      - name: Clean Up
        if: always()
        run: |
          docker rmi ${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} 2>/dev/null || true
          docker rmi ${{ env.ECR_REGISTRY }}/${{ env.SERVICE_NAME }}:${{ needs.sonarqube-analysis.outputs.image_tag }} 2>/dev/null || true
          docker image prune -f
```

## 14.2 Security Pipeline Flow

```
Developer pushes code
    │
    ▼
┌─────────────────────────────────────────────────┐
│ PARALLEL SECURITY SCANS (no waiting)            │
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Gitleaks │  │ Hadolint │  │ Semgrep  │     │
│  │ (secrets)│  │(Dockerfile)│ │  (SAST)  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
│                                                 │
│  ┌──────────┐  ┌──────────┐                    │
│  │  OWASP   │  │  Snyk    │                    │
│  │(dep scan)│  │(vuln+lic)│                    │
│  └──────────┘  └──────────┘                    │
└─────────────────────────────────────────────────┘
    │
    ▼ (all pass)
┌─────────────────────────────────────────────────┐
│ BUILD + DEEPER SCANS                            │
│                                                 │
│  1. Docker build                                │
│  2. Trivy image scan (CVEs)                     │
│  3. Syft SBOM generation                        │
│  4. Push to ECR                                 │
│  5. Cosign image signing                        │
└─────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ArgoCD Image Updater detects new image tag      │
│    │                                            │
│    ▼                                            │
│ ArgoCD auto-updates Helm values.yaml in Git     │
│    │                                            │
│    ▼                                            │
│ Argo Rollouts canary deployment:                │
│    20% → check metrics → 40% → 60% → 80% → 100%│
└─────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────┐
│ RUNTIME MONITORING                              │
│                                                 │
│  Falco: watches syscalls for threats            │
│  Prometheus: metrics + alerts                   │
│  Jaeger: distributed tracing                    │
│  Grafana: dashboards                            │
└─────────────────────────────────────────────────┘
```

---

\newpage

# 15: Incident Response + Chaos Testing

## 15.1 Litmus Chaos Experiments

```yaml
# chaos/order-service-pod-delete.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: order-service-pod-delete
  namespace: default
spec:
  appinfo:
    appns: default
    applabel: app=order-service
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "false"
```

```yaml
# chaos/network-latency.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: order-service-network-latency
  namespace: default
spec:
  appinfo:
    appns: default
    applabel: app=order-service
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: network-loss
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NETWORK_INTERFACE
              value: "eth0"
            - name: NETWORK_LATENCY
              value: "300"
```

## 15.2 Install Litmus

```bash
# Install Litmus Chaos
kubectl apply -f https://litmuschaos.github.io/litmus/litmus-3.0.0.yaml

# Create service account
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: litmus-admin
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: litmus-admin
subjects:
  - kind: ServiceAccount
    name: litmus-admin
    namespace: default
roleRef:
  kind: ClusterRole
  name: litmus-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

## 15.3 Incident Runbook Template

Create `RUNBOOKS.md` in your project root:

```markdown
# Incident Runbooks

## Runbook 1: order-service Down

**Symptoms:** Orders not being accepted, store-front checkout fails
**Severity:** P1 — Critical

### Detection
- Grafana alert: order-service pod restart > 3 in 5 minutes
- Falco alert: unexpected process in order-service container
- User reports: checkout button returns 500

### Investigation
1. Check pod status: `kubectl get pods -l app=order-service`
2. Check logs: `kubectl logs -l app=order-service --tail=100`
3. Check events: `kubectl describe pod -l app=order-service`
4. Check RabbitMQ: `kubectl exec -it rabbitmq-0 -- rabbitmqctl list_queues`

### Resolution
1. If OOMKilled: increase memory limit in Helm values
2. If CrashLoopBackOff: check logs for application error
3. If RabbitMQ unreachable: check network policies
4. If Argo Rollout stuck: `kubectl argo rollouts abort order-service`

### Recovery
1. Argo Rollouts should auto-rollback if canary fails
2. If manual: `kubectl argo rollouts undo order-service`
3. Verify: `curl http://order-service:3000/health`

## Runbook 2: MongoDB Crash

**Symptoms:** makeline-service cannot write orders, data loss risk
**Severity:** P0 — Critical

### Investigation
1. `kubectl get pods -l app=mongodb`
2. `kubectl logs mongodb-0 --tail=200`
3. Check disk: `kubectl exec -it mongodb-0 -- df -h /data/db`

### Resolution
1. If disk full: expand PVC or clean old data
2. If memory: increase resource limits
3. If corruption: restore from backup

## Runbook 3: RabbitMQ Overload

**Symptoms:** Message queue growing, order processing slow
**Severity:** P1 — High

### Investigation
1. Check queue depth: `kubectl exec -it rabbitmq-0 -- rabbitmqctl list_queues`
2. Check connections: `kubectl exec -it rabbitmq-0 -- rabbitmqctl list_connections`
3. Check memory: `kubectl exec -it rabbitmq-0 -- rabbitmqctl status`

### Resolution
1. Scale makeline-service: `kubectl scale deployment makeline-service --replicas=3`
2. If memory: increase RabbitMQ memory limit
3. Emergency: purge old messages: `rabbitmqctl purge_queue order-queue`

## Runbook 4: Istio Service Mesh Failure

**Symptoms:** Services can't communicate, 503 errors
**Severity:** P1 — High

### Investigation
1. Check istiod: `kubectl get pods -n istio-system`
2. Check sidecar injection: `kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'`
3. Check Kiali dashboard

### Resolution
1. Restart istiod: `kubectl rollout restart deployment istiod -n istio-system`
2. Re-inject sidecars: `kubectl label namespace default istio-injection=enabled --overwrite`
3. Remove faulty VirtualService rules
```

---

\newpage

# A: Install Commands One-Liner

Copy-paste this entire block to set up everything:

```bash
#!/bin/bash
# ============================================
# DevSecOps Complete Setup Script
# Run on antix (master node)
# ============================================
set -euo pipefail

echo "=== Step 1: k3s Master ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644" sh -

echo "=== Step 2: kubectl ==="
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "=== Step 3: Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Step 4: MetalLB ==="
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

echo "=== Step 5: nginx-ingress ==="
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

echo "=== Step 6: Vault ==="
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace --set server.dev.enabled=true

echo "=== Step 7: OPA Gatekeeper ==="
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml

echo "=== Step 8: Istio ==="
curl -L https://istio.io/downloadIstio | sh -
cd istio-* && export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
cd ..

echo "=== Step 9: ArgoCD ==="
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Step 10: Argo Rollouts ==="
kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

echo "=== Step 11: Prometheus + Grafana ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

echo "=== Step 12: Falco ==="
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace

echo "=== Step 13: Jaeger ==="
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/latest/download/jaeger-operator.yaml \
  -n jaeger --create-namespace

echo "=== Step 14: Security Tools ==="
# Gitleaks
wget -q https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
rm gitleaks_8.18.0_linux_x64.tar.gz

# Hadolint
wget -q https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64
sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint

# Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -sSb /usr/local/bin

# Cosign
wget -q https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Checkov
pip install checkov

# Conftest
wget -q https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
tar xzf conftest_0.46.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/
rm conftest_0.46.0_Linux_x86_64.tar.gz

echo "=== Step 15: Sealed Secrets ==="
helm repo add sealed-secrets https://charts.appuio.cloud
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system
wget -q https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-linux-amd64
chmod +x kubeseal-linux-amd64
sudo mv kubeseal-linux-amd64 /usr/local/bin/kubeseal

echo "=== Step 16: Litmus Chaos ==="
kubectl apply -f https://litmuschaos.github.io/litmus/litmus-3.0.0.yaml

echo ""
echo "=== ALL DONE ==="
echo "Run 'kubectl get nodes' to verify cluster"
echo "Run 'kubectl get pods --all-namespaces' to see all components"
```

---

\newpage

# B: File-by-File Mapping

Which security tool applies to which file in your project:

| Your File | Security Tool | What to Add |
|-----------|--------------|-------------|
| `src/ai-service/Dockerfile` | Hadolint | Add USER, HEALTHCHECK, multi-stage |
| `src/makeline-service/Dockerfile` | Hadolint | Add USER, HEALTHCHECK |
| `src/order-service/Dockerfile` | Hadolint | Add USER, HEALTHCHECK |
| `src/product-service/Dockerfile` | Hadolint | Add USER, HEALTHCHECK |
| `src/store-admin/Dockerfile` | Hadolint | Add USER, HEALTHCHECK |
| `src/store-front/Dockerfile` | Hadolint | Add USER, HEALTHCHECK |
| `src/virtual-customer/Dockerfile` | Hadolint | Add USER |
| `src/virtual-worker/Dockerfile` | Hadolint | Add USER |
| `src/*/requirements.txt` | Snyk, Dependabot | Auto-update PRs |
| `src/makeline-service/go.mod` | Dependabot | Auto-update PRs |
| `src/*/package.json` | Dependabot | Auto-update PRs |
| `src/*/Cargo.toml` | Dependabot | Auto-update PRs |
| `github/workflows/*.yaml` | Gitleaks, Hadolint, Snyk | Add scan jobs |
| `github/workflows/eks_infra_deployment.yaml` | Checkov | Add IaC scan job |
| `github/workflows/tf_aws_eks_prod.yaml` | Checkov | Add IaC scan job |
| `aws_eks_infrastructure/**/*.tf` | Checkov | Scan before apply |
| `helm-charts/*/templates/*.yaml` | OPA Gatekeeper | Test with Conftest |
| `helm-charts/*/values.yaml` | Checkov | Scan for misconfigs |
| `infrastructure/argocd/applications/*.yaml` | ArgoCD | Signature verification |
| `vault_pgsql_sonarqube/` | Vault | Dynamic secrets |
| All K8s namespaces | Network Policies | Apply deny-all + allow rules |
| All K8s namespaces | Pod Security Standards | Apply enforce=restricted |
| Running cluster | Falco | Runtime threat detection |
| Git repo | Sealed Secrets | Encrypt secrets before commit |

---

\newpage

# C: Troubleshooting

## C.1 k3s Cluster Issues

```bash
# Node not joining
k3s-agent.service: check logs
journalctl -u k3s-agent -f

# kubeconfig not working
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Pods stuck in Pending
kubectl describe pod <pod-name>
# Usually: not enough resources on node
kubectl top nodes  # check RAM/CPU
```

## C.2 MetalLB Issues

```bash
# Service stuck on Pending
kubectl describe svc -n ingress-nginx ingress-nginx-controller
# Check: Events section for MetalLB errors

# IP pool not working
kubectl get ipaddresspool -n metallb-system -o yaml
# Verify IPs are in your LAN range and not used by DHCP
```

## C.3 Falco Issues

```bash
# Falco pod CrashLoopBackOff
kubectl logs -n falco falco-xxxxx
# Common: eBPF not supported on old kernels
# Fix: use --set driver.kind=falco for legacy mode

# Too many alerts
# Tune rules: increase priority threshold or add exceptions
```

## C.4 Gatekeeper Issues

```bash
# All pods rejected
kubectl get constraints
# Check: which constraint is blocking
kubectl describe k8spspprivilegedcontainer deny-privileged-containers

# Temporarily disable a constraint
kubectl delete constraint deny-privileged-containers
```

## C.5 Vault Issues

```bash
# Vault pod not starting
kubectl logs -n vault vault-0
# Common: dev mode needs server.dev.enabled=true

# Can't read secrets
kubectl exec -it vault-0 -n vault -- vault status
# Must be initialized and unsealed (dev mode auto-unseals)
```

## C.6 ArgoCD Issues

```bash
# ArgoCD not syncing
kubectl get applications -n argocd
kubectl describe application <name> -n argocd
# Check: Status.OperationState and Status.Sync

# Image Updater not detecting new images
kubectl logs -n argocd deployment/argocd-image-updater
# Check: annotations in Argo Application match ECR registry
```

## C.7 Network Policy Issues

```bash
# Service can't reach another service
kubectl get networkpolicies -o wide
# Check: is there an Egress rule allowing the connection?

# Temporarily test without Network Policies
kubectl delete networkpolicies --all -n default
# If it works now, you need to add the right Egress rule
```

---

**END OF GUIDE**

Total tools covered: 40+
Total files in your project that need changes: 25+
Estimated implementation time: 2-3 weeks at 2-3 hours/day
