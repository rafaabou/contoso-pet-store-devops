# Trivy Complete Guide

## Table of Contents

1. [What Is Trivy](#1-what-is-trivy)
2. [Why Use Trivy](#2-why-use-trivy)
3. [Real-World Breaches](#3-real-world-breaches)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Rules and Policies](#8-custom-rules-and-policies)
9. [Integration](#9-integration)
10. [Security Hardening](#10-security-hardening)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips and Best Practices](#12-tips-and-best-practices)
13. [Command Reference](#13-command-reference)
14. [Configuration Reference](#14-configuration-reference)
15. [Real-World Examples](#15-real-world-examples)
16. [Further Reading](#16-further-reading)

---

## 1. What Is Trivy

Trivy is a comprehensive, open-source security scanner developed by Aqua Security. It is the most popular and widely adopted vulnerability scanner for cloud-native environments, designed to detect security issues across multiple layers of modern infrastructure.

### 1.1 Overview

Trivy scans for:

- **OS Package Vulnerabilities**: CVEs in Alpine, RHEL, Debian, Ubuntu, Amazon Linux, CentOS, SUSE, Oracle Linux, and 20+ other distributions
- **Application Dependency Vulnerabilities**: CVEs in npm, pip, Go modules, RubyGems, Cargo, Composer, .NET, Java (Maven/Gradle), and 15+ other ecosystems
- **Container Image Misconfigurations**: Dockerfile best practices, Kubernetes YAML security issues, Terraform cloud misconfigurations
- **Sensitive Information and Secrets**: Hardcoded passwords, API keys, tokens, private keys embedded in images or code
- **Software Bill of Materials (SBOM)**: Comprehensive inventory of all packages and dependencies in an image
- **License Compliance**: Detection of restrictive or non-compliant licenses in dependencies

### 1.2 Architecture

Trivy operates as a single binary with no external dependencies. Its architecture includes:

- **Vulnerability Database**: Mirrors the GitHub Advisory Database (GHSA), OS-specific advisory databases (Alpine, Debian, RHEL, Ubuntu), and NVD
- **Walker**: Traverses the target (container image filesystem, filesystem directory, or config files)
- **Detector**: Identifies packages, dependencies, and configuration files
- **Analyzer**: Parses package metadata to extract name, version, and dependency information
- **Scanner**: Compares detected versions against the vulnerability database
- **Reporter**: Outputs results in multiple formats (table, JSON, SARIF, CycloneDX, etc.)

### 1.3 Supported Targets

| Target Type | Supported Formats |
|---|---|
| Container Images | Docker, OCI, TAR, Podman, containerd |
| Filesystem | Source code directories, SBOM files |
| Configuration | Dockerfile, docker-compose, Kubernetes YAML, Terraform, CloudFormation, Pulumi |
| Repository | Git repositories (local and remote) |
| Virtual Machine | VM images (qcow2, vmdk) |

### 1.4 Comparison with Other Scanners

| Feature | Trivy | Grype | Snyk Container | Twistlock |
|---|---|---|---|---|
| Open Source | Yes (Apache 2) | Yes (Apache 2) | Freemium | Commercial |
| Image Scanning | Yes | Yes | Yes | Yes |
| FS Scanning | Yes | No | Yes | Yes |
| IaC Scanning | Yes | No | Yes | Yes |
| Secret Detection | Yes | No | Yes | Yes |
| SBOM Generation | Yes | No (uses Syft) | No | Yes |
| License Detection | Yes | No | Yes | Yes |
| Kubernetes Scanning | Yes | No | Yes | Yes |
| Speed | Fast | Fastest | Medium | Slow |

---

## 2. Why Use Trivy

### 2.1 Simplicity

Trivy requires zero configuration to start scanning. Unlike other scanners that require database setup, authentication tokens, or complex configuration files, Trivy works out of the box:

```bash
# Scan an image with zero configuration
trivy image nginx:latest

# Scan a directory with zero configuration
trivy fs ./my-project

# Scan Kubernetes manifests with zero configuration
trivy config ./k8s-manifests/
```

### 2.2 Comprehensive Coverage

Trivy covers the entire container lifecycle:

1. **Build time**: Scan Dockerfiles and base images before building
2. **CI/CD**: Integrate into pipelines to catch vulnerabilities before deployment
3. **Registry**: Scan images in container registries (Harbor, ECR, GCR, ACR, Docker Hub)
4. **Runtime**: Scan running containers and Kubernetes clusters
5. **Infrastructure**: Scan Terraform, CloudFormation, Kubernetes manifests

### 2.3 Speed

Trivy scans a typical container image in under 10 seconds. It achieves this through:

- Efficient filesystem traversal
- Parallel database downloads
- Caching of vulnerability databases
- Stream-based processing of image layers

### 2.4 Active Community and Maintenance

- Over 25,000 GitHub stars
- Weekly releases with new vulnerability data
- Supports the latest CVEs within hours of disclosure
- Extensive documentation and community support

### 2.5 Kubernetes-Native Integration

Trivy integrates natively with:

- **ArgoCD**: Trivy Scanner for continuous vulnerability monitoring
- **Kyverno**: Policy-as-code enforcement using Trivy checks
- **OPA/Gatekeeper**: Custom Rego policies backed by Trivy data
- **Helm**: Scan Helm charts before deployment
- **Kustomize**: Scan Kustomize overlays

---

## 3. Real-World Breaches

### 3.1 Log4Shell (CVE-2021-44228)

**What happened**: A critical RCE vulnerability in Apache Log4j affected millions of Java applications worldwide. Attackers could execute arbitrary code by injecting specially crafted strings into logged data.

**Trivy detection**: Trivy identifies Log4j vulnerabilities in Java application images by scanning JAR files and Maven/Gradle dependency trees:

```bash
trivy image my-java-app:latest | grep -i log4j
```

**Impact**: Equifax, Apple, Amazon, Twitter, Minecraft, and thousands of other organizations were affected. The vulnerability had a CVSS score of 10.0.

### 3.2 SolarWinds Supply Chain Attack (CVE-2020-10148)

**What happened**: Attackers compromised SolarWinds Orion build system and injected a backdoor (SUNBURST) into software updates distributed to 18,000+ organizations.

**Trivy detection**: While Trivy cannot detect the specific SUNBURST backdoor, it can:

- Scan SolarWinds-related container images for known CVEs
- Generate SBOMs to track all components for supply chain auditing
- Detect known vulnerabilities in the build pipeline

### 3.3 Codecov Supply Chain Attack (2021)

**What happened**: Attackers modified the Codecov Bash Uploader script to exfiltrate environment variables, including CI/CD secrets, from over 29,000 repositories.

**Trivy detection**: Trivy's secret scanning capability can detect hardcoded secrets and credentials:

```bash
trivy fs --scanners secret ./my-repo
```

### 3.4 Log4j in Minecraft Servers (2021)

**What happened**: Multiple Minecraft server operators were compromised through the Log4Shell vulnerability, with attackers gaining remote code execution.

**Trivy detection**: Before deploying a Minecraft server container:

```bash
trivy image itzg/minecraft-server:latest
```

### 3.5 OpenSSL Heartbleed (CVE-2014-0160)

**What happened**: A critical vulnerability in OpenSSL allowed attackers to read up to 64KB of server memory per request, potentially exposing private keys and session data.

**Trivy detection**: Trivy scans for OpenSSL versions in container images:

```bash
trivy image ubuntu:20.04 | grep -i openssl
```

### 3.6 Dependency Confusion Attacks (2021)

**What happened**: Security researcher Alex Birsan demonstrated that by publishing packages with the same name as internal packages on public registries (npm, PyPI, RubyGems), he could trick package managers into downloading malicious code.

**Trivy detection**: Trivy's dependency scanning and SBOM generation can help identify the full dependency tree and detect unexpected public dependencies.

---

## 4. Installation

### 4.1 Quick Install (Recommended)

```bash
# Install via the official install script (Linux/macOS)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Verify installation
trivy --version
```

### 4.2 Package Managers

```bash
# Ubuntu/Debian
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# RHEL/CentOS/Fedora
sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.58.0/trivy_0.58.0_Linux-64bit.rpm

# Homebrew (macOS)
brew install trivy

# Snap
sudo snap install trivy

# Arch Linux
pacman -S trivy
```

### 4.3 Docker

```bash
# Run Trivy as a container (no installation needed)
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image nginx:latest

# Scan a local directory
docker run --rm \
  -v /path/to/project:/project \
  aquasec/trivy:latest fs /project
```

### 4.4 Container Image from Docker Hub

```bash
# Pull the image
docker pull aquasec/trivy:latest

# Use with Docker-in-Docker for CI/CD
docker run --rm -it \
  --name trivy-scanner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/workspace \
  -w /workspace \
  aquasec/trivy:latest fs .
```

### 4.5 Kubernetes Deployment

```bash
# Deploy Trivy as a Kubernetes Job
kubectl create job trivy-scan --from=cronjob/trivy-scanner -- image=nginx:latest

# Or deploy as a standalone Job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: trivy-image-scan
spec:
  template:
    spec:
      containers:
      - name: trivy
        image: aquasec/trivy:latest
        args:
        - image
        - --severity
        - HIGH,CRITICAL
        - --exit-code
        - "1"
        - nginx:latest
      restartPolicy: Never
  backoffLimit: 1
EOF
```

### 4.6 Binary Download

```bash
# Download the latest release directly
TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
curl -LO "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz"
tar -xzf "trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz"
sudo mv trivy /usr/local/bin/
```

---

## 5. Configuration

### 5.1 Configuration File

Trivy can be configured via a YAML file (`.trivy.yaml` or `trivy.yaml`):

```yaml
# .trivy.yaml
scan:
  scanners:
    - vuln       # Vulnerability scanning
    - secret     # Secret detection
    - misconfig  # Misconfiguration scanning

severity:
  - HIGH
  - CRITICAL

ignore-unfixed: true

timeout: 10m

cache:
  dir: /tmp/trivy-cache

db:
  repository: ghcr.io/aquasecurity/trivy-db
  skip-update: false

report:
  format: table
  output: trivy-results.txt

misconfiguration:
  scanners:
    - dockerfile
    - cloudformation
    - docker-compose
    - kubernetes
    - terraform
    - terraformplan

secret:
  scanning-mode: retained

registry:
  mirror:
    docker.io:
      - mirror.example.com
```

### 5.2 Environment Variables

```bash
# Skip vulnerability database update
export TRIVY_SKIP_DB_UPDATE=false

# Set cache directory
export TRIVY_CACHE_DIR=/tmp/trivy-cache

# Set database repository
export TRIVY_DB_REPOSITORY=ghcr.io/aquasecurity/trivy-db

# Set severity filter
export TRIVY_SEVERITY=HIGH,CRITICAL

# Set output format
export TRIVY_OUTPUT=results.json

# Set timeout
export TRIVY_TIMEOUT=30m

# Set username/password for private registries
export TRIVY_USERNAME=myuser
export TRIVY_PASSWORD=mypassword

# Set GITHUB_TOKEN for private repositories
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 5.3 Flag Precedence

The precedence order for configuration (highest to lowest):

1. Command-line flags
2. Environment variables
3. Configuration file (`.trivy.yaml`)
4. Default values

### 5.4 Multiple Configuration Files

Trivy supports merging multiple configuration files:

```bash
# Use a custom config file
trivy fs --config custom-trivy.yaml ./my-project

# Multiple config files (later overrides earlier)
trivy fs --config base.yaml --config override.yaml ./my-project
```

---

## 6. Core Concepts

### 6.1 Vulnerability Scanning

Trivy matches detected package versions against vulnerability databases from:

- **GitHub Advisory Database (GHSA)**: Covers all ecosystems (npm, pip, Go, RubyGems, etc.)
- **NVD (National Vulnerability Database)**: US government CVE database
- **OS-specific advisories**: Alpine, Debian, Ubuntu, RHEL, SUSE, Amazon Linux, Oracle Linux, etc.

Each vulnerability is classified by:

- **Severity**: CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN
- **CVSS Score**: Common Vulnerability Scoring System (0.0-10.0)
- **Fix Version**: Available patched version (or "unfixed" if no fix exists)
- **Reference**: CVE ID, advisory URL, and related links

### 6.2 Misconfiguration Scanning

Trivy detects misconfigurations in:

- **Dockerfile**: Best practices, security settings, layer optimization
- **Kubernetes YAML**: Security contexts, resource limits, RBAC issues
- **Terraform**: Cloud resource misconfigurations (AWS, GCP, Azure, Alibaba)
- **CloudFormation**: AWS CloudFormation template issues
- **Docker Compose**: Docker Compose file misconfigurations
- **Pulumi**: Infrastructure-as-code issues

### 6.3 Secret Scanning

Trivy detects hardcoded secrets including:

- AWS Access Keys and Secret Keys
- GitHub/GitLab/Bitbucket tokens
- SSH private keys
- TLS certificates and private keys
- Database connection strings
- API keys and tokens
- Passwords in configuration files

### 6.4 SBOM (Software Bill of Materials)

Trivy generates SBOMs in multiple formats:

- **CycloneDX**: OWASP standard, widely supported
- **SPDX**: Linux Foundation standard, used in compliance
- **JSON**: Trivy's native format with full metadata

### 6.5 VEX (Vulnerability Exploitability eXchange)

Trivy supports VEX documents to provide context about vulnerability exploitability:

- **Notaffected**: The component is not affected by the vulnerability
- **Fixed**: The vulnerability has been fixed
- **UnderInvestigation**: The vulnerability is being investigated
- **Analyzed**: The vulnerability has been analyzed

---

## 7. Usage Guide

### 7.1 Scanning Container Images

```bash
# Scan a remote image
trivy image nginx:latest

# Scan a local image
trivy image my-app:local

# Scan with specific severity
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan and exit with non-zero code for HIGH/CRITICAL
trivy image --exit-code 1 --severity HIGH,CRITICAL nginx:latest

# Scan and output JSON
trivy image --format json --output results.json nginx:latest

# Scan with ignore unfixed vulnerabilities
trivy image --ignore-unfixed nginx:latest

# Scan and generate SARIF for GitHub Security tab
trivy image --format sarif --output results.sarif nginx:latest

# Scan a specific platform
trivy image --platform linux/arm64 nginx:latest

# Scan an image from a private registry
trivy image --username user --password pass registry.example.com/my-app:v1

# Scan without downloading DB update
trivy image --skip-db-update nginx:latest
```

### 7.2 Scanning Filesystems

```bash
# Scan a project directory
trivy fs ./my-project

# Scan with specific scanners
trivy fs --scanners vuln,secret ./my-project

# Scan a Helm chart
trivy fs --scanners misconfig ./my-helm-chart/

# Scan a Kubernetes manifest directory
trivy fs --scanners misconfig ./k8s/

# Scan and show only misconfigurations
trivy fs --scanners misconfig --format json --output misconfig.json ./my-project

# Scan with custom ignore file
trivy fs --ignorefile .trivyignore ./my-project
```

### 7.3 Scanning Configuration Files

```bash
# Scan a Dockerfile
trivy config --scanners misconfig Dockerfile

# Scan Kubernetes manifests
trivy config --scanners misconfig ./k8s/

# Scan Terraform files
trivy config --scanners misconfig ./terraform/

# Scan with specific checks
trivy config --checks ALL ./k8s/

# Scan and output SARIF
trivy config --format sarif --output config.sarif ./k8s/
```

### 7.4 Scanning Repositories

```bash
# Scan a local Git repository
trivy repo /path/to/repo

# Scan a remote repository
trivy repo https://github.com/org/repo

# Scan a specific branch
trivy repo --branch main https://github.com/org/repo

# Scan a private repository
trivy repo --token ghp_xxxxx https://github.com/org/private-repo

# Scan with specific scanners
trivy repo --scanners vuln,secret,misconfig ./repo
```

### 7.5 Generating SBOMs

```bash
# Generate CycloneDX SBOM
trivy image --format cyclonedx --output sbom.cdx.json nginx:latest

# Generate SPDX SBOM
trivy image --format spdx --output sbom.spdx.json nginx:latest

# Generate SBOM and scan it
trivy sbom sbom.cdx.json

# Generate SBOM from filesystem
trivy fs --format cyclonedx --output project-sbom.cdx.json ./my-project
```

### 7.6 Scanning Kubernetes Clusters

```bash
# Scan a running cluster
trivy k8s --report summary cluster

# Scan a specific namespace
trivy k8s --report summary --namespace kube-system cluster

# Scan and output JSON
trivy k8s --report all --format json --output k8s-scan.json cluster

# Scan specific resources
trivy k8s --report summary --resource pod/nginx-default cluster

# Scan with specific severity
trivy k8s --severity HIGH,CRITICAL --report summary cluster
```

### 7.7 Client/Server Mode

```bash
# Start the Trivy server
trivy server --listen 0.0.0.0:8080

# Scan using the remote server
trivy image --server http://trivy-server:8080 nginx:latest

# Scan filesystem using the remote server
trivy fs --server http://trivy-server:8080 ./my-project
```

---

## 8. Custom Rules and Policies

### 8.1 Custom Rego Policies

Create custom policies using Open Policy Agent (OPA) Rego:

```rego
# custom_policy.rego
package trivy

__rego_metadoc__ := {
    "id": "CUSTOM-001",
    "title": "Custom policy: Require non-root user",
    "severity": "CRITICAL",
    "description": "Ensure containers run as non-root user"
}

deny[msg] {
    input.config_type == "Dockerfile"
    input.dockerfile[_].Cmd == "USER"
    input.dockerfile[_].Value[0] == "root"
    msg := "Running as root is not allowed"
}
```

### 8.2 Custom Policy Directory Structure

```
policies/
├── custom/
│   ├── dockerfile/
│   │   ├── require_non_root.rego
│   │   └── no_latest_tag.rego
│   ├── kubernetes/
│   │   ├── require_limits.rego
│   │   └── require_security_context.rego
│   └── terraform/
│       ├── require_encryption.rego
│       └── no_public_access.rego
└── .trivyignore
```

### 8.3 Ignore File

Create a `.trivyignore` file to suppress specific vulnerabilities:

```
# .trivyignore
# Ignore specific CVEs
CVE-2021-44228
CVE-2021-45046

# Ignore specific advisories with a reason
ALPINE-2023-001  # Not applicable to our deployment

# Ignore vulnerabilities with a description
CVE-2022-1234  # False positive - we use a custom build
```

### 8.4 Ignore Unfixed Vulnerabilities

```bash
# Only show vulnerabilities with available fixes
trivy image --ignore-unfixed nginx:latest

# Or in configuration
scan:
  ignore-unfixed: true
```

### 8.5 Custom Severity Thresholds

```bash
# Only report HIGH and CRITICAL
trivy image --severity HIGH,CRITICAL nginx:latest

# Only report CRITICAL
trivy image --severity CRITICAL nginx:latest

# Report all severities
trivy image --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL nginx:latest
```

---

## 9. Integration

### 9.1 GitHub Actions

```yaml
# .github/workflows/trivy-scan.yml
name: Trivy Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: 'my-app:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
          ignore-unfixed: true

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run Trivy FS scanner
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

### 9.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
trivy-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity HIGH,CRITICAL --format json --output trivy.json $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      container_scanning: trivy.json
  allow_failure: false

trivy-fs:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy fs --exit-code 1 --severity HIGH,CRITICAL --format json --output trivy-fs.json .
  artifacts:
    paths:
      - trivy-fs.json
```

### 9.3 ArgoCD Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/repo
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.snamespace
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

# Add Trivy scanner annotation
  annotations:
    trivy.scanner.aquasecurity.github.io/image-ref: my-app:latest
    trivy.scanner.aquasecurity.github.io/severity: HIGH,CRITICAL
    trivy.scanner.aquasecurity.github.io/exit-code: "1"
```

### 9.4 Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t my-app:${BUILD_NUMBER} .'
            }
        }
        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image \
                        --exit-code 1 \
                        --severity HIGH,CRITICAL \
                        --format json \
                        --output trivy-results.json \
                        my-app:${BUILD_NUMBER}
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-results.json'
                }
                failure {
                    slackSend color: 'danger', message: "Trivy scan failed for ${env.JOB_NAME}"
                }
            }
        }
    }
}
```

### 9.5 k3s with Trivy Operator

```bash
# Install Trivy Operator via Helm
helm install trivy-operator aquasecurity/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set trivy.severity="HIGH,CRITICAL" \
  --set trivy.skipUpdate=false \
  --set operator.scanJobTimeout=10m

# Verify installation
kubectl get pods -n trivy-system

# Check vulnerability reports
kubectl get vulnerabilityreports --all-namespaces

# Check misconfiguration reports
kubectl get configauditreports --all-namespaces

# Check secret scan reports
kubectl get secretscanreports --all-namespaces

# View a specific vulnerability report
kubectl get vulnerabilityreports -n default -o yaml my-app-pod-nginx
```

### 9.6 Harbor Integration

```bash
# Configure Harbor to use Trivy as scanner
# Harbor UI → Administration → Interrogation Services → Scanner

# Or via Harbor API
curl -X POST "https://harbor.example.com/api/v2.0/scanners" \
  -H "Authorization: Basic $(echo -n admin:password | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Trivy",
    "description": "Trivy vulnerability scanner",
    "version": "0.58.0",
    "url": "http://trivy-server:8080",
    "vendor": "Aqua Security",
    "enabled": true
  }'

# Trigger scan via API
curl -X POST "https://harbor.example.com/api/v2.0/projects/myproject/repositories/myrepo/artifacts/latest/scan" \
  -H "Authorization: Basic $(echo -n admin:password | base64)"
```

### 9.7 Slack Integration

```bash
#!/bin/bash
# trivy-slack.sh - Send Trivy results to Slack

IMAGE="$1"
RESULTS=$(trivy image --format json "$IMAGE")

HIGH_COUNT=$(echo "$RESULTS" | jq '[.Results[].Vulnerabilities[] | select(.Severity == "HIGH")] | length')
CRITICAL_COUNT=$(echo "$RESULTS" | jq '[.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL")] | length')

if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{
            \"text\": \"🚨 Trivy Scan Alert\",
            \"blocks\": [{
                \"type\": \"section\",
                \"text\": {
                    \"type\": \"mrkdwn\",
                    \"text\": \"*Trivy Security Scan*\nImage: \`${IMAGE}\`\nCritical: ${CRITICAL_COUNT}\nHigh: ${HIGH_COUNT}\"
                }
            }]
        }" \
        "$SLACK_WEBHOOK_URL"
fi
```

---

## 10. Security Hardening

### 10.1 Running Trivy in Restricted Mode

```yaml
# trivy-job-restricted.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: trivy-scan
spec:
  template:
    spec:
      serviceAccountName: trivy-scanner
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: trivy
        image: aquasec/trivy:latest
        args:
        - image
        - --exit-code
        - "1"
        - --severity
        - HIGH,CRITICAL
        - nginx:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        volumeMounts:
        - name: trivy-cache
          mountPath: /tmp/trivy-cache
        - name: docker-socket
          mountPath: /var/run/docker.sock
          readOnly: true
      volumes:
      - name: trivy-cache
        emptyDir: {}
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
      restartPolicy: Never
  backoffLimit: 1
```

### 10.2 Network Policies

```yaml
# trivy-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: trivy-network-policy
  namespace: trivy-system
spec:
  podSelector:
    matchLabels:
      app: trivy
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: argocd
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443  # HTTPS for DB downloads
    - protocol: TCP
      port: 80   # HTTP for DB downloads
```

### 10.3 RBAC Configuration

```yaml
# trivy-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: trivy-scanner
  namespace: trivy-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: trivy-scanner
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["security.aquasecurity.github.io"]
  resources: ["vulnerabilityreports", "configauditreports", "secretscanreports"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: trivy-scanner
subjects:
- kind: ServiceAccount
  name: trivy-scanner
  namespace: trivy-system
roleRef:
  kind: ClusterRole
  name: trivy-scanner
  apiGroup: rbac.authorization.k8s.io
```

### 10.4 Secret Management for Private Registries

```yaml
# trivy-registry-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: trivy-registry-credentials
  namespace: trivy-system
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>

---
# trivy-scan-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: trivy-scan-credentials
  namespace: trivy-system
type: Opaque
data:
  TRIVY_USERNAME: <base64-encoded-username>
  TRIVY_PASSWORD: <base64-encoded-password>
```

---

## 11. Troubleshooting

### 11.1 Issue: Database Download Timeout

**Symptom**: `FATAL   failed to initialize a vulnerability DB`

**Cause**: Network connectivity issues or slow download.

**Fix**:
```bash
# Increase timeout
trivy image --timeout 30m nginx:latest

# Use a local cache
export TRIVY_CACHE_DIR=/var/cache/trivy
trivy image --download-db-only nginx:latest

# Use a mirror
export TRIVY_DB_REPOSITORY=mirror.example.com/trivy-db
```

### 11.2 Issue: Permission Denied on Docker Socket

**Symptom**: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Fix**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Or run with sudo
sudo trivy image nginx:latest

# Or use Docker-in-Docker
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image nginx:latest
```

### 11.3 Issue: Out of Memory

**Symptom**: `Killed` or `out of memory` error

**Fix**:
```bash
# Limit concurrent workers
export TRIVY_CACHE_DIR=/tmp/trivy-cache
trivy image --timeout 30m nginx:latest

# Use Docker with memory limit
docker run --rm --memory=2g aquasec/trivy image nginx:latest

# Scan specific layers only
trivy image --skip-dirs '/var/cache/*' nginx:latest
```

### 11.4 Issue: False Positives

**Symptom**: Vulnerability reported but not applicable

**Fix**:
```bash
# Create ignore file
echo "CVE-2021-44228" >> .trivyignore

# Ignore unfixed vulnerabilities
trivy image --ignore-unfixed nginx:latest

# Use VEX documents for complex cases
trivy image --vex trivy.vex nginx:latest
```

### 11.5 Issue: Private Registry Authentication

**Symptom**: `UNAUTHORIZED` or `authentication required`

**Fix**:
```bash
# Docker login first
docker login registry.example.com
trivy image registry.example.com/my-app:v1

# Or use environment variables
export TRIVY_USERNAME=myuser
export TRIVY_PASSWORD=mypassword
trivy image registry.example.com/my-app:v1

# Or use a docker config
export DOCKER_CONFIG=/path/to/.docker
trivy image registry.example.com/my-app:v1
```

### 11.6 Issue: Slow Scanning

**Symptom**: Scan takes too long

**Fix**:
```bash
# Update DB first (caches for subsequent scans)
trivy image --download-db-only

# Scan specific layers
trivy image --layer-ids sha256:abc123 nginx:latest

# Use client/server mode
trivy server --listen 0.0.0.0:8080 &
trivy image --server http://localhost:8080 nginx:latest
```

### 11.7 Issue: SARIF Output Format Issues

**Symptom**: SARIF file not recognized by GitHub

**Fix**:
```bash
# Ensure proper SARIF format
trivy image --format sarif --output results.sarif nginx:latest

# Verify SARIF validity
cat results.sarif | jq '.version'

# Upload with correct action version
# Use: github/codeql-action/upload-sarif@v3
```

### 11.8 Issue: Kubernetes RBAC Errors

**Symptom**: `Error: forbidden` when scanning cluster

**Fix**:
```bash
# Create proper RBAC
kubectl apply -f trivy-rbac.yaml

# Check permissions
kubectl auth can-i list pods --as=system:serviceaccount:trivy-system:trivy-scanner

# Use kubeconfig with proper context
trivy k8s --kubeconfig /path/to/kubeconfig --context my-cluster cluster
```

### 11.9 Issue: Version Mismatch

**Symptom**: `DB schema version mismatch`

**Fix**:
```bash
# Force DB update
trivy image --reset
trivy image nginx:latest

# Or manually clear cache
rm -rf /tmp/trivy-cache
trivy image nginx:latest
```

### 11.10 Issue: Large Image Scanning

**Symptom**: Scan fails on very large images (>10GB)

**Fix**:
```bash
# Increase timeout
export TRIVY_TIMEOUT=60m

# Use Docker with more resources
docker run --rm --cpus=4 --memory=4g aquasec/trivy image large-image:latest

# Scan specific layers
trivy image --layer-ids sha256:specific-layer large-image:latest
```

### 11.11 Issue: Alpine Linux Vulnerabilities Not Found

**Symptom**: No vulnerabilities detected for Alpine image

**Fix**:
```bash
# Force Alpine DB download
export TRIVY_DB_REPOSITORY=ghcr.io/aquasecurity/trivy-db
trivy image alpine:latest

# Verify Alpine DB
trivy image --download-db-only
```

### 11.12 Issue: CI/CD Pipeline Timeout

**Symptom**: Scan times out in CI/CD pipeline

**Fix**:
```yaml
# GitHub Actions - increase timeout
- name: Trivy Scan
  uses: aquasecurity/trivy-action@0.28.0
  timeout-minutes: 30
  with:
    image-ref: my-app:latest
```

### 11.13 Issue: Multiple Image Tags

**Symptom**: Cannot scan image with multiple tags

**Fix**:
```bash
# Use full image reference
trivy image myregistry/myapp:tag1,tag2

# Or scan each tag separately
trivy image myregistry/myapp:tag1
trivy image myregistry/myapp:tag2
```

### 11.14 Issue: Trivy Server Connection Refused

**Symptom**: `connection refused` when connecting to Trivy server

**Fix**:
```bash
# Check server is running
curl http://trivy-server:8080/healthz

# Check network connectivity
kubectl exec -it client-pod -- curl http://trivy-server:8080/healthz

# Check service exists
kubectl get svc -n trivy-system trivy-server
```

### 11.15 Issue: Garbage Collection of Old Reports

**Symptom**: Disk space issues from accumulated scan reports

**Fix**:
```bash
# Use Kubernetes CronJob with TTL
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-cleanup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 86400  # 24 hours
      template:
        spec:
          containers:
          - name: cleanup
            image: aquasec/trivy:latest
            command:
            - /bin/sh
            - -c
            - |
              kubectl delete vulnerabilityreports --all-namespaces \
                --field-selector=status.phase=Complete \
                --field-selector=metadata.creationTimestamp<$(date -d "7 days ago" -Iseconds)
```

### 11.16 Issue: Unicode and Internationalized Characters

**Symptom**: Incorrect vulnerability matching for international packages

**Fix**:
```bash
# Use JSON output for precise matching
trivy image --format json nginx:latest | jq '.Results[].Vulnerabilities[] | select(.PkgName | contains("特殊字符"))'

# Or use table format for human readability
trivy image --format table nginx:latest
```

---

## 12. Tips and Best Practices

### 12.1 Scan Early and Often

Run Trivy scans in your CI/CD pipeline at multiple stages:

1. **PR stage**: Scan Dockerfile and filesystem for misconfigurations
2. **Build stage**: Scan the built image before pushing to registry
3. **Registry stage**: Scan images in the registry periodically
4. **Deploy stage**: Scan running pods in Kubernetes

### 12.2 Use Exit Codes Correctly

```bash
# Fail on HIGH or CRITICAL
trivy image --exit-code 1 --severity HIGH,CRITICAL nginx:latest

# Fail on any vulnerability
trivy image --exit-code 1 nginx:latest

# Don't fail, just report
trivy image nginx:latest
```

### 12.3 Cache DB Locally

```bash
# Pre-download DB for faster scans
trivy image --download-db-only

# Use persistent cache
export TRIVY_CACHE_DIR=/var/cache/trivy
mkdir -p $TRIVY_CACHE_DIR
```

### 12.4 Use Client/Server Mode

For frequent scans, run a Trivy server to avoid re-downloading the DB:

```bash
# Start server
trivy server --listen 0.0.0.0:8080

# Scan using server
trivy image --server http://trivy-server:8080 nginx:latest
```

### 12.5 Use Ignore Files for Accepted Risks

```bash
# Create .trivyignore
echo "CVE-2021-44228" >> .trivyignore
echo "# Reason: We use custom Log4j configuration that mitigates this" >> .trivyignore
```

### 12.6 Combine with Other Security Tools

Use Trivy alongside:
- **Grype**: For alternative vulnerability database comparison
- **Syft**: For detailed SBOM generation
- **Cosign**: For image signing and verification
- **OPA/Gatekeeper**: For policy enforcement

### 12.7 Monitor for New Vulnerabilities

```bash
# Schedule daily scans
# crontab
0 6 * * * trivy image myregistry/myapp:latest --format json --output /var/log/trivy/$(date +\%Y\%m\%d).json
```

### 12.8 Use Severity-Based Policies

```yaml
# In your CI/CD pipeline
trivy image --severity CRITICAL --exit-code 1 nginx:latest  # Block on CRITICAL only
trivy image --severity HIGH,CRITICAL --exit-code 1 nginx:latest  # Block on HIGH and CRITICAL
```

### 12.9 Scan Base Images Separately

```bash
# Scan base image
trivy image --severity CRITICAL ubuntu:22.04

# Scan application layer only
trivy image --vuln-type os my-app:latest
```

### 12.10 Use VEX for False Positive Management

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "version": 1,
  "vulnerabilities": [
    {
      "id": "CVE-2021-44228",
      "analysis": {
        "state": "not_affected",
        "justification": "component_not_present",
        "response": []
      }
    }
  ]
}
```

### 12.11 Use Policy-as-Code

```bash
# Kyverno policy that uses Trivy data
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-scan
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-image-vulnerabilities
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Image has HIGH or CRITICAL vulnerabilities"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!*:latest"
```

### 12.12 Use Automated PR Comments

```yaml
# GitHub Actions - comment on PR
- name: Trivy Scan and Comment
  uses: aquasecurity/trivy-action@0.28.0
  with:
    image-ref: my-app:${{ github.sha }}
    format: 'table'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
  continue-on-error: true

- name: Comment on PR
  uses: actions/github-script@v7
  with:
    script: |
      const result = '${{ steps.trivy.outputs.stdout }}';
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## Trivy Security Scan Results\n\n\`\`\`\n${result}\n\`\`\``
      });
```

### 12.13 Use Digest pinning for Images

```bash
# Instead of tag (mutable)
trivy image nginx:latest

# Use digest (immutable)
trivy image nginx@sha256:abc123def456...
```

### 12.14 Scan Helm Charts Before Deployment

```bash
# Lint and scan Helm chart
helm lint ./my-chart
trivy config --scanners misconfig ./my-chart/

# Scan rendered templates
helm template my-release ./my-chart | trivy config --scanners misconfig -
```

### 12.15 Use Trivy in Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
- repo: https://github.com/aquasecurity/trivy
  rev: 0.58.0
  hooks:
  - id: trivy-config
    args: ['--severity', 'HIGH,CRITICAL', '--exit-code', '1']
  - id: trivy-fs
    args: ['--severity', 'HIGH,CRITICAL', '--exit-code', '1', '--scanners', 'vuln,secret']
```

---

## 13. Command Reference

### 13.1 Global Flags

| Flag | Description | Default |
|---|---|---|
| `--cache-dir` | Cache directory | `/tmp/trivy-cache` |
| `--clear-cache` | Clear cache | false |
| `--config` | Config file path | `.trivy.yaml` |
| `--debug` | Debug mode | false |
| `--exit-code` | Exit code on vulnerability found | 0 |
| `--format` | Output format | table |
| `--ignore-unfixed` | Ignore unfixed vulnerabilities | false |
| `--no-progress` | Disable progress bar | false |
| `--output` | Output file path | stdout |
| `--quiet` | Suppress output | false |
| `--severity` | Severity levels | UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL |
| `--timeout` | Scan timeout | 5m0s |
| `--vuln-type` | Vulnerability type filter | os,library |

### 13.2 Image Scan Flags

| Flag | Description | Default |
|---|---|---|
| `--auth-url` | Registry authentication URL | - |
| `--cert-dir` | TLS certificate directory | - |
| `--dockerfile` | Dockerfile path | - |
| `--image-src` | Image source (docker, remote, podman) | docker |
| `--insecure` | Allow insecure connections | false |
| `--k8s-cache-dir` | K8s cache directory | - |
| `--k8s-url` | K8s API server URL | - |
| `--keep-trivy-db` | Keep downloaded DB | false |
| `--offline-scan` | Offline scan mode | false |
| `--password` | Registry password | - |
| `--platform` | Platform (e.g., linux/amd64) | - |
| `--registry-mirror` | Registry mirror URL | - |
| `--removed-pkg-names` | Show removed packages | false |
| `--skip-dirs` | Skip directories | - |
| `--skip-files` | Skip files | - |
| `--username` | Registry username | - |

### 13.3 FS Scan Flags

| Flag | Description | Default |
|---|---|---|
| `--dependency-tree` | Show dependency tree | false |
| `--file-patterns` | File pattern rules | - |
| `--offline-scan` | Offline scan mode | false |
| `--recomend` | Show fix recommendations | true |
| `--scanners` | Scanner types | vuln,secret,misconfig |

### 13.4 Config Scan Flags

| Flag | Description | Default |
|---|---|---|
| `--check-namespaces` | Check namespaces | false |
| `--checks` | Check types (ALL, DEFAULT) | DEFAULT |
| `--dockerfile-only` | Scan Dockerfile only | false |
| `--from-policy-file` | Load policies from file | false |
| `--include-non-failures` | Include non-failure results | false |
| `--namespaces` | Namespace filter | - |
| `--policy` | Policy file path | - |
| `--policy-namespaces` | Policy namespaces | - |
| `--schema-version` | Schema version | - |
| `--trace` | Enable trace output | false |

### 13.5 Repository Scan Flags

| Flag | Description | Default |
|---|---|---|
| `--branch` | Branch to scan | - |
| `--commit` | Commit to scan | - |
| `--depth` | Repository depth | - |
| `--detached` | Scan detached HEAD | false |
| `--pull` | Pull remote changes | false |
| `--recurse-modules` | Scan Git submodules | false |
| `--skip-dirs` | Skip directories | - |
| `--token` | Authentication token | - |

---

## 14. Configuration Reference

### 14.1 Full Configuration Example

```yaml
# .trivy.yaml
scan:
  scanners:
    - vuln
    - secret
    - misconfig
  include-dev-dependencies: false

severity:
  - UNKNOWN
  - LOW
  - MEDIUM
  - HIGH
  - CRITICAL

vulnerability:
  ignore-unfixed: false
  ignorefile: .trivyignore
  vuln-type:
    - os
    - library

cache:
  dir: /tmp/trivy-cache
  clear: false

db:
  repository: ghcr.io/aquasecurity/trivy-db
  skip-update: false
  light: false

report:
  format: table
  output: trivy-results.txt
  template: ""

misconfiguration:
  scanners:
    - dockerfile
    - cloudformation
    - docker-compose
    - kubernetes
    - terraform
    - terraformplan
  include-non-failures: false
  policy-namespaces:
    - main

secret:
  scanning-mode: auto

registry:
  mirror:
    docker.io:
      - mirror.example.com
      - registry.internal

image:
  platform: linux/amd64
  removed-pkg-names: false
  skip-dirs:
    - /var/cache
    - /tmp
  skip-files:
    - "*.log"

kubernetes:
  context: my-cluster
  namespace: default
  report: all

license:
  confidence: 0.9
```

### 14.2 Environment Variables Reference

| Variable | Description | Default |
|---|---|---|
| `TRIVY_CACHE_DIR` | Cache directory | `/tmp/trivy-cache` |
| `TRIVY_DB_REPOSITORY` | DB repository URL | `ghcr.io/aquasecurity/trivy-db` |
| `TRIVY_DEBUG` | Debug mode | `false` |
| `TRIVY_EXIT_CODE` | Exit code | `0` |
| `TRIVY_FORMAT` | Output format | `table` |
| `TRIVY_IGNORE_UNFIXED` | Ignore unfixed | `false` |
| `TRIVY_OUTPUT` | Output file | stdout |
| `TRIVY_PASSWORD` | Registry password | - |
| `TRIVY_SEVERITY` | Severity levels | `UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL` |
| `TRIVY_SKIP_DB_UPDATE` | Skip DB update | `false` |
| `TRIVY_TIMEOUT` | Scan timeout | `5m0s` |
| `TRIVY_USERNAME` | Registry username | - |
| `TRIVY_VEX` | VEX file path | - |
| `TRIVY_VULN_TYPE` | Vulnerability types | `os,library` |
| `GITHUB_TOKEN` | GitHub token for private repos | - |

---

## 15. Real-World Examples

### 15.1 Contoso Pet Store - Container Security

**Scenario**: Contoso Pet Store runs a microservices architecture on Kubernetes with 15 container images in production.

#### 15.1.1 CI/CD Pipeline Integration

```yaml
# .github/workflows/petstore-security.yml
name: Pet Store Security Scan
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - api-gateway
          - product-service
          - cart-service
          - order-service
          - user-service
          - payment-service
          - notification-service

    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t petstore/${{ matrix.service }}:${{ github.sha }} ./services/${{ matrix.service }}

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: 'petstore/${{ matrix.service }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-${{ matrix.service }}.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
          ignore-unfixed: true
          timeout: '10m'

      - name: Upload SARIF results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-${{ matrix.service }}.sarif'

      - name: Generate SBOM
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: 'petstore/${{ matrix.service }}:${{ github.sha }}'
          format: 'cyclonedx'
          output: 'sbom-${{ matrix.service }}.cdx.json'

      - name: Upload SBOM to Artifact Registry
        run: |
          gcloud artifacts repositories create petstore-sboms \
            --repository-format=docker \
            --location=us-central1
          gsutil cp sbom-${{ matrix.service }}.cdx.json \
            gs://petstore-sboms/${{ matrix.service }}/${{ github.sha }}/sbom.cdx.json
```

#### 15.1.2 Kubernetes Security Policies

```yaml
# petstore-kyverno-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: petstore-image-scan
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: require-trivy-scan
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    validate:
      message: "Image must pass Trivy security scan (no CRITICAL vulnerabilities)"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "!petstore/*:*@sha256:*"
            imagePullPolicy: Always

  - name: restrict-image-registries
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
    validate:
      message: "Images must come from authorized registries"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "gcr.io/petstore-production/*|docker.io/petstore/*"
```

#### 15.1.3 Monitoring Dashboard

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: trivy-alerts
spec:
  groups:
  - name: trivy
    rules:
    - alert: TrivyCriticalVulnerability
      expr: |
        increase(trivy_vulnerability_vulnerabilities_total{severity="CRITICAL"}[1h]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "New CRITICAL vulnerability detected"
        description: "Trivy detected {{ $value }} new CRITICAL vulnerabilities in the last hour"

    - alert: TrivyScanFailure
      expr: |
        increase(trivy_scan_errors_total[1h]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Trivy scan failed"
        description: "Trivy scan failed {{ $value }} times in the last hour"

    - alert: TrivyDatabaseStale
      expr: |
        time() - trivy_db_last_updated > 86400
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Trivy vulnerability database is stale"
        description: "Trivy DB was last updated {{ $value }} seconds ago"
```

#### 15.1.4 Automated Remediation

```bash
#!/bin/bash
# petstore-remediate.sh

set -euo pipefail

IMAGE="$1"
RESULTS=$(trivy image --format json "$IMAGE")

CRITICAL=$(echo "$RESULTS" | jq '[.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL")] | length')
HIGH=$(echo "$RESULTS" | jq '[.Results[].Vulnerabilities[] | select(.Severity == "HIGH")] | length')

if [ "$CRITICAL" -gt 0 ]; then
    echo "🚨 CRITICAL vulnerabilities found in $IMAGE"
    echo "$RESULTS" | jq -r '.Results[].Vulnerabilities[] | select(.Severity == "CRITICAL") | "  - \(.VulnerabilityID): \(.PkgName) (\(.InstalledVersion) → \(.FixedVersion // "unfixed"))"'

    # Create Jira ticket
    curl -X POST "https://contoso.atlassian.net/rest/api/3/issue" \
      -H "Authorization: Basic $JIRA_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "fields": {
          "project": {"key": "SEC"},
          "issuetype": {"name": "Bug"},
          "priority": {"name": "Critical"},
          "summary": "CRITICAL vulnerability in '"$IMAGE"'",
          "description": "Trivy scan detected '"$CRITICAL"' CRITICAL vulnerabilities. See attached scan results."
        }
      }'

    # Block deployment
    exit 1
elif [ "$HIGH" -gt 0 ]; then
    echo "⚠️  HIGH vulnerabilities found in $IMAGE (non-blocking)"
    exit 0
else
    echo "✅ No HIGH or CRITICAL vulnerabilities found"
    exit 0
fi
```

---

## 16. Further Reading

### 16.1 Official Documentation

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub Repository](https://github.com/aquasecurity/trivy)
- [Trivy Configuration Reference](https://aquasecurity.github.io/trivy/latest/docs/configuration/)
- [Trivy Policy Examples](https://github.com/aquasecurity/trivy/tree/main/pkg/commands/app.go)

### 16.2 Blog Posts and Tutorials

- [Getting Started with Trivy](https://aquasecurity.github.io/trivy/latest/getting-started/quickstart/)
- [Trivy vs Grype: A Comparison](https://blog.aquasec.com/trivy-vs-grype)
- [Securing Kubernetes with Trivy Operator](https://aquasecurity.github.io/trivy-operator/)
- [Trivy in CI/CD Pipelines](https://aquasecurity.github.io/trivy/latest/docs/integrations/)

### 16.3 Community Resources

- [Trivy Slack Channel](https://slack.aquasecurity.com/)
- [Trivy Discussions](https://github.com/aquasecurity/trivy/discussions)
- [Trivy Issues](https://github.com/aquasecurity/trivy/issues)

### 16.4 Related Tools

- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - Vulnerability scanner
- [Cosign](https://github.com/sigstore/cosign) - Image signing
- [Conftest](https://github.com/open-policy-agent/conftest) - Policy testing
- [OPA](https://www.openpolicyagent.org/) - Policy engine

### 16.5 Standards and Specifications

- [CycloneDX](https://cyclonedx.org/) - SBOM standard
- [SPDX](https://spdx.org/) - SBOM standard
- [VEX](https://cyclonedx.org/capabilities/vex/) - Vulnerability exploitability exchange
- [SLSA](https://slsa.dev/) - Supply chain integrity framework

---

*Last updated: September 2026*
*Trivy version: 0.58.0+*
