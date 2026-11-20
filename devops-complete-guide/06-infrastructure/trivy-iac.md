# Trivy IaC Complete Guide

## Table of Contents

1. [What Is Trivy IaC](#1-what-is-trivy-iac)
2. [Why Use Trivy IaC](#2-why-use-trivy-iac)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide (Step-by-Step)](#6-usage-guide-step-by-step)
7. [Custom Policies](#7-custom-policies)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting (20 Issues)](#10-troubleshooting)
11. [Tips and Best Practices (20 Tips)](#11-tips-and-best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

# 1. What Is Trivy IaC

Trivy (the Swiss Army knife for security) is an open-source security scanner developed by Aqua Security. While Trivy is best known for vulnerability scanning of container images, it also includes comprehensive Infrastructure as Code (IaC) scanning capabilities for Terraform, CloudFormation, Kubernetes, Dockerfile, and ARM templates.

## 1.1 History

- **2019**: Trivy created by Knqyf263 (Teppei Fukuda) at Aqua Security
- **2020**: Rapid adoption as the go-to container vulnerability scanner
- **2021**: Added IaC scanning capabilities (Terraform, CloudFormation)
- **2022**: Added Kubernetes manifest scanning, Helm chart scanning
- **2023**: Enhanced custom policy support via Rego (OPA)
- **2024**: Trivy 0.50+ with improved IaC scanning and custom policies

## 1.2 Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Trivy                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Scanner │  │  Parser  │  │  Policy Engine   │  │
│  │  Engine  │  │  Engine  │  │  (Rego/OPA)      │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │              │                 │             │
│  ┌────┴──────────────┴─────────────────┴──────────┐ │
│  │           Built-in Policies (500+)              │ │
│  │    AWS │ Azure │ GCP │ K8s │ Docker │ ARM       │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │          Custom Policies (Rego)                 │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │     Additional: Vulnerability Scanning          │ │
│  │   Container Images │ OS Packages │ Libraries    │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## 1.3 Key Features

- **Multi-Purpose Scanner**: Container vulnerabilities + IaC security in one tool
- **IaC Frameworks**: Terraform, CloudFormation, Kubernetes, Dockerfile, ARM, Helm
- **500+ Built-in Policies**: AWS, Azure, GCP security checks
- **Custom Policies**: Write rules in Rego (OPA)
- **Benchmarks**: CIS, NIST, PCI-DSS, HIPAA compliance
- **SBOM Generation**: Software Bill of Materials
- **Vulnerability Scanning**: Container image scanning (bonus)
- **Misconfiguration Detection**: Infrastructure security issues
- **Secret Detection**: Hardcoded credentials and API keys
- **Multiple Output Formats**: Table, JSON, SARIF, JUnit XML, CycloneDX
- **CI/CD Integration**: GitHub Actions, GitLab CI, Jenkins, etc.
- **Agent Mode**: Server-based scanning for large environments

## 1.4 Trivy IaC vs. Other Tools

| Feature | Trivy IaC | tfsec | Checkov | Terrascan |
|---------|----------|-------|---------|-----------|
| IaC Scanning | ✅ | ✅ | ✅ | ✅ |
| Container Scanning | ✅ | ❌ | ❌ | ❌ |
| OS Package Scanning | ✅ | ❌ | ❌ | ❌ |
| Library Scanning | ✅ | ❌ | ❌ | ❌ |
| SBOM Generation | ✅ | ❌ | ❌ | ❌ |
| Secret Detection | ✅ | ❌ | ❌ | ❌ |
| Custom Policies | Rego | Go/Rego | Python/YAML | Rego |
| Built-in Policies | 500+ | 1,000+ | 1,000+ | 500+ |
| Speed | Fast | Fast | Medium | Medium |
| License | Apache 2.0 | MIT | Apache 2.0 | Apache 2.0 |

---

# 2. Why Use Trivy IaC

## 2.1 The Problem Trivy IaC Solves

Modern applications use multiple layers of infrastructure:

1. **Container Images**: OS packages and application libraries
2. **IaC Code**: Terraform, CloudFormation defining cloud resources
3. **Kubernetes Manifests**: Deployment, Service, ConfigMap definitions
4. **Dockerfiles**: Container build instructions
5. **Helm Charts**: Kubernetes package management

Security issues exist at every layer:
- **Vulnerable packages** in container images
- **Misconfigured infrastructure** (public S3 buckets, open security groups)
- **Hardcoded secrets** in configuration files
- **Non-compliant configurations** (missing encryption, logging)
- **Overly permissive IAM policies**
- **Missing security controls**

Previously, organizations needed 3-4 separate tools to scan all these layers. Trivy provides a single tool for all security scanning needs.

## 2.2 Benefits

| Benefit | Description |
|---------|-------------|
| **Unified Scanner** | One tool for containers, IaC, and dependencies |
| **Fast Scanning** | Go-based, fast execution |
| **Low Resource Usage** | Minimal memory and CPU requirements |
| **Simple CLI** | Easy to learn and use |
| **Offline Capable** | Can scan without internet access |
| **Custom Policies** | Write rules in Rego (OPA) |
| **CI/CD Native** | Easy integration into pipelines |
| **Active Development** | Frequent releases and new features |
| **SBOM Support** | Generate Software Bill of Materials |
| **Vulnerability + IaC** | Scan containers and infrastructure in one run |

## 2.3 When to Use Trivy IaC

**Good fit:**
- Organizations wanting a single security scanner
- CI/CD pipelines (one tool for all scanning)
- Container + IaC security combined
- SBOM generation and supply chain security
- Teams already using Trivy for container scanning

**Not ideal for:**
- Terraform-only scanning (tfsec is more specialized)
- Python-based custom policies (Checkov is better)
- Enterprise compliance with complex policies (Checkov or Prisma Cloud)

---

# 3. Installation

## 3.1 Prerequisites

- **Operating System**: Linux, macOS, Windows
- **Architecture**: amd64, arm64, arm, s390x, ppc64le
- **No dependencies required** for basic usage

## 3.2 Install on Linux

### Binary Download

```bash
# Latest version (check https://github.com/aquasecurity/trivy/releases)
TRIVY_VERSION="0.55.0"

# Download
wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz

# Extract
tar xvzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz

# Install
sudo mv trivy /usr/local/bin/

# Verify
trivy version
```

### Via Package Manager (Debian/Ubuntu)

```bash
# Add GPG key
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

# Add repo
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

# Install
sudo apt-get update
sudo apt-get install trivy
```

### Via Package Manager (RHEL/CentOS/Fedora)

```bash
sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.55.0/trivy_0.55.0_Linux-64bit.rpm
```

## 3.3 Install on macOS

```bash
# Homebrew
brew install trivy

# Or MacPorts
sudo port install trivy
```

## 3.4 Install on Windows

```powershell
# Chocolatey
choco install trivy

# Scoop
scoop install trivy

# winget
winget install Aquasec.Trivy

# Binary download
# https://github.com/aquasecurity/trivy/releases
```

## 3.5 Install via Docker

```bash
# Pull image
docker pull aquasec/trivy:latest

# Scan current directory
docker run --rm -v "$(pwd):/src" aquasec/trivy fs /src

# Scan Terraform
docker run --rm -v "$(pwd):/src" aquasec/trivy config /src
```

## 3.6 Verify Installation

```bash
trivy version
# Version: 0.55.0

trivy --help
```

---

# 4. Configuration

## 4.1 Configuration File

Trivy uses a `trivy.yaml` file in the project root or `$HOME/.trivy.yaml`:

```yaml
# trivy.yaml

# Severity threshold
severity: "HIGH,CRITICAL"

# Exit code for CI/CD
exit-code: 1

# Output format
format: table

# Ignore unfixed vulnerabilities
ignore-unfixed: false

# Scan depth
scan-sbom: true

# Cache directory
cache-dir: /tmp/trivy-cache

# Custom policies
policy:
  - ./policy/

# Skip directories
skip-dirs:
  - .git
  - node_modules
  - vendor

# Skip files
skip-files:
  - "*.md"
  - "LICENSE"

# Exclude checks
exclude-checks:
  - AWS001  # S3 bucket logging
  - AWS002  # S3 bucket versioning

# Include checks
include-checks:
  - AWS001

# Namespaces for Rego
namespaces:
  - main
  - custom
```

## 4.2 Environment Variables

```bash
# Set severity
export TRIVY_SEVERITY="HIGH,CRITICAL"

# Set exit code
export TRIVY_EXIT_CODE=1

# Set output format
export TRIVY_FORMAT=json

# Set cache directory
export TRIVY_CACHE_DIR=/tmp/trivy-cache

# Disable update check
export TRIVY_SKIP_DB_UPDATE=false
```

## 4.3 CLI Flags

```bash
# Severity filter
trivy config --severity HIGH,CRITICAL .

# Exit code
trivy config --exit-code 1 .

# Output format
trivy config --format json .

# Skip directories
trivy config --skip-dirs ".git,node_modules" .

# Custom policy
trivy config --policy ./policy/ .
```

---

# 5. Core Concepts

## 5.1 Scan Types

| Command | Purpose |
|---------|---------|
| `trivy image` | Scan container image vulnerabilities |
| `trivy fs` | Scan filesystem for vulnerabilities and misconfigs |
| `trivy config` | Scan IaC for misconfigurations |
| `trivy sbom` | Scan SBOM for vulnerabilities |
| `trivy repo` | Scan Git repository |
| `trivy rootfs` | Scan root filesystem |

## 5.2 IaC Frameworks

| Framework | Command |
|-----------|---------|
| Terraform | `trivy config --scanners misconfig .` |
| CloudFormation | `trivy config --scanners misconfig .` |
| Kubernetes | `trivy config --scanners misconfig k8s/` |
| Dockerfile | `trivy config --scanners misconfig Dockerfile` |
| Helm | `trivy config --scanners misconfig helm/` |

## 5.3 Policy Types

### Built-in Policies
```bash
# Run built-in policies
trivy config .

# List available policies
trivy config --list-all-policies .
```

### Custom Rego Policies
```bash
# Run with custom policies
trivy config --policy ./custom-policy/ .

# Run with multiple policy directories
trivy config --policy ./policy1/ --policy ./policy2/ .
```

## 5.4 Severities

| Level | Description |
|-------|-------------|
| UNKNOWN | Unspecified severity |
| LOW | Low risk |
| MEDIUM | Medium risk |
| HIGH | High risk |
| CRITICAL | Critical risk |

## 5.5 Misconfiguration Categories

| Category | Examples |
|----------|----------|
| Network | Security groups, VPCs, firewalls |
| Storage | S3 buckets, EBS volumes, encryption |
| IAM | Roles, policies, users |
| Logging | CloudTrail, CloudWatch, audit logs |
| Encryption | KMS, TLS, data at rest |
| Compliance | CIS, NIST, PCI-DSS, HIPAA |

## 5.6 Check IDs

Trivy uses check IDs for built-in policies:

| ID | Framework | Description |
|----|-----------|-------------|
| AWS001 | AWS | S3 bucket does not have logging enabled |
| AWS002 | AWS | S3 bucket does not have versioning enabled |
| AWS003 | AWS | S3 bucket does not have server-side encryption |
| AWS004 | AWS | S3 bucket does not have public access blocked |
| AWS005 | AWS | VPC does not have flow logs enabled |
| AWS006 | AWS | Security group allows unrestricted ingress |
| AWS007 | AWS | EC2 instance does not have termination protection |
| AWS008 | AWS | RDS instance does not have encryption enabled |
| AWS009 | AWS | RDS instance does not have backup enabled |
| AWS010 | AWS | SQS queue does not have encryption enabled |
| AZU001 | Azure | Storage account does not have HTTPS traffic only |
| AZU002 | Azure | Storage account does not have secure transfer |
| AZU003 | Azure | Key Vault does not have soft delete enabled |
| AZU004 | Azure | NSG allows unrestricted SSH access |
| GCP001 | GCP | GCE instance does not have IP forwarding disabled |
| GCP002 | GCP | GCP project does not have OS login enabled |
| GCP003 | GCP | GCS bucket does not have logging enabled |
| KSV001 | K8s | Container should not run as root |
| KSV002 | K8s | Container should not have privileged access |
| KSV003 | K8s | Container should not run as host |
| KSV004 | K8s | Container should not allow privilege escalation |

## 5.7 Output Formats

```bash
# Table (default)
trivy config --format table .

# JSON
trivy config --format json .

# SARIF (GitHub Advanced Security)
trivy config --format sarif .

# JUnit XML
trivy config --format junit .

# CycloneDX SBOM
trivy config --format cyclonedx .
```

## 5.8 Caching

```bash
# Trivy caches vulnerability database
# Default cache directory: /tmp/trivy-cache

# Set custom cache
trivy --cache-dir /var/cache/trivy config .

# Clear cache
trivy --clean-cache

# Skip DB update
trivy --skip-db-update config .
```

---

# 6. Usage Guide (Step-by-Step)

## 6.1 Step 1: Scan Terraform Directory

```bash
# Basic scan
trivy config .

# Scan specific directory
trivy config ./modules/infrastructure

# Scan with severity filter
trivy config --severity HIGH,CRITICAL .
```

## 6.2 Step 2: Scan Kubernetes Manifests

```bash
# Scan K8s YAML files
trivy config --scanners misconfig k8s/

# Scan Helm chart
helm template . | trivy config --scanners misconfig -

# Scan rendered Helm
helm template . > rendered.yaml
trivy config --scanners misconfig rendered.yaml
```

## 6.3 Step 3: Scan Dockerfile

```bash
# Scan Dockerfile
trivy config --scanners misconfig Dockerfile

# Scan docker-compose
trivy config --scanners misconfig docker-compose.yml
```

## 6.4 Step 4: Scan CloudFormation

```bash
# Scan CloudFormation templates
trivy config --scanners misconfig cloudformation/

# Scan single template
trivy config --scanners misconfig template.json
```

## 6.5 Step 5: Output Formats

```bash
# CLI output
trivy config .

# JSON output
trivy config --format json > results.json

# SARIF output
trivy config --format sarif > results.sarif

# JUnit XML
trivy config --format junit > results.xml
```

## 6.6 Step 6: CI/CD Integration

```yaml
# .github/workflows/trivy-iac.yml
name: Trivy IaC

on: [push, pull_request]

jobs:
  trivy-iac:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy IaC scanner
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

## 6.7 Step 7: Custom Policies

```bash
# Create custom policy directory
mkdir -p policy

# Write Rego policy
cat > policy/required_tags.rego << 'EOF'
package main

deny[msg] {
    resource := input.aws_s3_bucket[name]
    not resource.tags.Environment
    msg := sprintf("S3 bucket '%s' is missing Environment tag", [name])
}
EOF

# Run with custom policy
trivy config --policy ./policy/ .
```

## 6.8 Step 8: Ignore Unfixed

```bash
# Only report fixable issues
trivy config --ignore-unfixed .

# Combined with severity
trivy config --severity HIGH,CRITICAL --ignore-unfixed .
```

## 6.9 Step 9: Baseline

```bash
# Generate baseline
trivy config --format json > baseline.json

# Use baseline
trivy config --baseline baseline.json .
```

## 6.10 Step 10: Review and Remediate

```bash
# View all failures
trivy config --format json | jq '.Results[] | select(.Misconfigurations) | .Misconfigurations[]'

# Group by severity
trivy config --format json | jq '[.Results[].Misconfigurations[] | .Severity] | group_by(.) | map({severity: .[0], count: length})'

# View specific check
trivy config --format json | jq '.Results[].Misconfigurations[] | select(.ID == "AWS001")'
```

---

# 7. Custom Policies

## 7.1 Rego Policy Structure

```rego
# policy/required_tags.rego
package main

import rego.v1

deny contains msg if {
    resource := input.aws_s3_bucket[name]
    not resource.tags.Environment
    msg := sprintf("S3 bucket '%s' is missing Environment tag", [name])
}

deny contains msg if {
    resource := input.aws_s3_bucket[name]
    not resource.tags.Team
    msg := sprintf("S3 bucket '%s' is missing Team tag", [name])
}
```

## 7.2 Custom Policy for EC2

```rego
# policy/ec2_termination_protection.rego
package main

import rego.v1

deny contains msg if {
    resource := input.aws_instance[name]
    not resource.disable_api_termination
    msg := sprintf("EC2 instance '%s' does not have termination protection enabled", [name])
}
```

## 7.3 Custom Policy for Security Groups

```rego
# policy/no_public_ingress.rego
package main

import rego.v1

deny contains msg if {
    resource := input.aws_security_group[name]
    ingress := resource.ingress[_]
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows unrestricted ingress from 0.0.0.0/0", [name])
}
```

## 7.4 Custom Policy for Kubernetes

```rego
# policy/k8s_no_privileged.rego
package main

import rego.v1

deny contains msg if {
    container := input.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' should not run in privileged mode", [container.name])
}
```

## 7.5 Custom Policy with Severity

```rego
# policy/custom_with_severity.rego
package main

import rego.v1

# severity: HIGH

deny contains msg if {
    resource := input.aws_s3_bucket[name]
    not resource.server_side_encryption_configuration
    msg := sprintf("S3 bucket '%s' does not have server-side encryption enabled", [name])
}
```

## 7.6 Custom Policy with Fix Suggestion

```rego
# policy/custom_with_fix.rego
package main

import rego.v1

deny contains msg if {
    resource := input.aws_s3_bucket[name]
    not resource.versioning.enabled
    msg := sprintf("S3 bucket '%s' does not have versioning enabled. Fix: add versioning { enabled = true }", [name])
}
```

## 7.7 Testing Custom Policies

```bash
# Test custom policy
trivy config --policy ./policy/ .

# Test specific policy file
trivy config --policy ./policy/required_tags.rego .

# Debug policy
trivy config --policy ./policy/ --debug .
```

## 7.8 Policy Directory Structure

```
policy/
  required_tags.rego
  encryption.rego
  logging.rego
  network.rego
  compliance/
    cis.rego
    pci_dss.rego
```

---

# 8. Integration

## 8.1 GitHub Actions

```yaml
# .github/workflows/trivy-iac.yml
name: Trivy IaC

on: [push, pull_request]

jobs:
  trivy-iac:
    name: Trivy IaC Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy IaC
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'
          skip-dirs: '.git,node_modules'

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

## 8.2 GitLab CI

```yaml
# .gitlab-ci.yml
trivy-iac:
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy config --format json --output trivy-results.json .
  artifacts:
    reports:
      sast: trivy-results.json
```

## 8.3 Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Trivy IaC Scan') {
            steps {
                sh 'trivy config --format junit --output trivy-results.xml .'
                junit 'trivy-results.xml'
            }
        }
    }
}
```

## 8.4 Azure DevOps

```yaml
# azure-pipelines.yml
steps:
  - script: |
      docker run --rm -v $(Build.SourcesDirectory):/src aquasec/trivy config /src \
        --format junit \
        --output /src/trivy-results.xml
    displayName: 'Trivy IaC Scan'

  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'trivy-results.xml'
```

## 8.5 Pre-Commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/trivy
    rev: '0.24.0'
    hooks:
      - id: trivy-config
        args:
          - --severity
          - HIGH,CRITICAL
```

## 8.6 Terragrunt Integration

```hcl
# terragrunt.hcl
terraform {
  before_hook "trivy" {
    commands = ["apply", "plan"]
    execute = ["trivy", "config", ".", "--severity", "HIGH,CRITICAL"]
  }
}
```

## 8.7 Combined Container + IaC Scanning

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  container-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp .

      - name: Scan container
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: 'myapp'
          format: 'sarif'
          output: 'container-scan.sarif'

  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Scan IaC
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'iac-scan.sarif'
```

---

# 9. Security

## 9.1 CIS Benchmarks

```bash
# Run CIS AWS Foundations Benchmark
trivy config --scanners misconfig --severity HIGH,CRITICAL .

# Run specific CIS checks
trivy config --include-checks AWS001,AWS002,AWS003 .
```

## 9.2 NIST Compliance

```bash
# Run NIST checks
trivy config --severity HIGH,CRITICAL .
```

## 9.3 PCI-DSS Compliance

```bash
# Run PCI-DSS checks
trivy config --severity HIGH,CRITICAL .
```

## 9.4 HIPAA Compliance

```bash
# Run HIPAA checks
trivy config --severity HIGH,CRITICAL .
```

## 9.5 Secret Detection

```bash
# Trivy detects hardcoded secrets
trivy fs --scanners secret .

# Scan for secrets in IaC
trivy config --scanners secret .
```

## 9.6 Vulnerability Scanning + IaC

```bash
# Scan container image
trivy image myapp:latest

# Scan IaC
trivy config .

# Combine in CI/CD
trivy image --format json > image-scan.json
trivy config --format json > iac-scan.json
```

## 9.7 Supply Chain Security

```bash
# Generate SBOM
trivy image --format cyclonedx myapp:latest > sbom.json

# Scan SBOM
trivy sbom sbom.json
```

## 9.8 Network Security

```bash
# Check for public access
trivy config --severity HIGH,CRITICAL . | grep -i "public"

# Check for unrestricted ingress
trivy config --severity HIGH,CRITICAL . | grep -i "ingress"
```

---

# 10. Troubleshooting

## Issue 1: "No misconfigurations found"

```
No misconfigurations found
```

**Cause**: No IaC files or all checks pass.

**Fix**:
```bash
# Check files exist
find . -name "*.tf" -o -name "*.yml" -o -name "*.json" | head -20

# Scan specific directory
trivy config ./modules/

# Check for all severities
trivy config --severity LOW,MEDIUM,HIGH,CRITICAL .
```

## Issue 2: "Failed to parse HCL"

```
Failed to parse HCL: unexpected token
```

**Cause**: Syntax error in Terraform files.

**Fix**:
```bash
# Validate Terraform first
terraform validate

# Check syntax
tflint

# Then run Trivy
trivy config .
```

## Issue 3: "Policy not found"

```
Failed to load policy: open policy/required_tags.rego: no such file
```

**Fix**:
```bash
# Check policy path
ls -la policy/

# Use absolute path
trivy config --policy /absolute/path/to/policy/ .

# Verify Rego syntax
opa fmt policy/required_tags.rego
```

## Issue 4: "Module not found"

```
Failed to load module: module not found
```

**Cause**: Referenced modules not downloaded.

**Fix**:
```bash
# Download modules
terraform init

# Or exclude modules
trivy config --skip-dirs ".terraform" .
```

## Issue 5: "Custom policy syntax error"

```
Failed to evaluate policy: rego syntax error
```

**Fix**:
```bash
# Check Rego syntax
opa fmt policy/

# Validate policy
opa eval data.main.deny

# Debug policy
trivy config --policy ./policy/ --debug .
```

## Issue 6: "Exit code issues"

Trivy always returns 0.

**Fix**:
```bash
# Set exit code
trivy config --exit-code 1 .

# Or check JSON output
trivy config --format json | jq '.Results[].Misconfigurations | length'
```

## Issue 7: "Performance issues"

Scan takes too long.

**Fix**:
```bash
# Scan specific directory
trivy config ./modules/important/

# Skip directories
trivy config --skip-dirs ".git,node_modules,vendor" .

# Disable update check
trivy --skip-db-update config .
```

## Issue 8: "False positives"

Trivy flags correctly configured resources.

**Fix**:
```yaml
# trivy.yaml - exclude specific checks
exclude-checks:
  - AWS001
  - AWS002
```

```bash
# Or inline
trivy config --exclude-checks AWS001 .
```

## Issue 9: "Version conflict"

Trivy version incompatible with policies.

**Fix**:
```bash
# Update Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Check version
trivy --version
```

## Issue 10: "Memory issues"

Out of memory during scan.

**Fix**:
```bash
# Scan specific directory
trivy config ./modules/

# Skip large directories
trivy config --skip-dirs "vendor,node_modules" .

# Disable cache
trivy --cache-dir /dev/null config .
```

## Issue 11: "SARIF output not recognized"

SARIF file not accepted by GitHub.

**Fix**:
```bash
# Generate valid SARIF
trivy config --format sarif . > results.sarif

# Validate SARIF
python -c "import json; json.load(open('results.sarif'))"
```

## Issue 12: "Baseline not working"

Baseline file not filtering old issues.

**Fix**:
```bash
# Regenerate baseline
trivy config --format json > baseline.json

# Verify baseline
cat baseline.json | jq '.Results[].Misconfigurations | length'

# Use baseline
trivy config --baseline baseline.json .
```

## Issue 13: "Docker permission issues"

Permission denied when running in Docker.

**Fix**:
```bash
# Fix volume permissions
docker run --rm -v "$(pwd):/src" aquasec/trivy config /src

# Or run with user mapping
docker run --rm -u $(id -u):$(id -g) -v "$(pwd):/src" aquasec/trivy config /src
```

## Issue 14: "Helm template issues"

Can't scan Helm charts directly.

**Fix**:
```bash
# Render Helm template first
helm template . > rendered.yaml

# Then scan
trivy config --scanners misconfig rendered.yaml
```

## Issue 15: "Kubernetes manifest issues"

Can't scan raw K8s YAML.

**Fix**:
```bash
# Use --scanners misconfig
trivy config --scanners misconfig k8s/

# Or scan individual files
trivy config --scanners misconfig deployment.yaml
```

## Issue 16: "Network errors"

Trivy can't download vulnerability database.

**Fix**:
```bash
# Skip DB update
trivy --skip-db-update config .

# Or pre-download
trivy --download-db-only

# Use offline cache
trivy --cache-dir /var/cache/trivy config .
```

## Issue 17: "Exit code 1 in CI/CD"

CI/CD pipeline fails on any finding.

**Fix**:
```bash
# Soft fail
trivy config --exit-code 0 .

# Or fail only on critical
trivy config --severity CRITICAL --exit-code 1 .
```

## Issue 18: "Policy evaluation error"

Custom policy evaluation fails.

**Fix**:
```bash
# Debug policy
trivy config --policy ./policy/ --debug .

# Test policy independently
opa eval data.main.deny --input test.json --data policy/

# Check input format
trivy config --format json . | jq '.Results[0].Target'
```

## Issue 19: "Skip files not working"

Skip files pattern not working.

**Fix**:
```yaml
# trivy.yaml
skip-dirs:
  - .git
  - node_modules
  - vendor

skip-files:
  - "*.md"
  - "LICENSE"
  - "tests/"
```

## Issue 20: "No rules found"

```
No rules to check
```

**Cause**: All rules excluded or wrong scanner.

**Fix**:
```bash
# Check excluded rules
cat trivy.yaml | grep exclude

# Run with all rules
trivy config --scanners misconfig .

# Check available checks
trivy config --list-all-policies .
```

---

# 11. Tips and Best Practices

## Tip 1: Use Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/trivy
    rev: '0.24.0'
    hooks:
      - id: trivy-config
        args:
          - --severity
          - HIGH,CRITICAL
```

## Tip 2: Use Severity Filtering

```bash
# Only critical/high
trivy config --severity HIGH,CRITICAL .

# Or in config
severity: "HIGH,CRITICAL"
```

## Tip 3: Use Exit Code in CI/CD

```bash
# Fail pipeline on findings
trivy config --exit-code 1 .

# Or fail only on critical
trivy config --severity CRITICAL --exit-code 1 .
```

## Tip 4: Use Custom Rego Policies

```rego
# Write policies for your requirements
deny contains msg if {
    resource := input.aws_s3_bucket[name]
    not resource.tags.Environment
    msg := sprintf("S3 bucket '%s' is missing Environment tag", [name])
}
```

## Tip 5: Use Combined Scanning

```bash
# Scan container image + IaC in one pipeline
trivy image myapp:latest
trivy config .
```

## Tip 6: Use SARIF for GitHub

```bash
# Generate SARIF for GitHub Advanced Security
trivy config --format sarif . > results.sarif
```

## Tip 7: Use Baselines for Existing Code

```bash
# Generate baseline
trivy config --format json > baseline.json

# Use baseline
trivy config --baseline baseline.json .
```

## Tip 8: Use for Compliance Auditing

```bash
# Run CIS checks
trivy config --severity HIGH,CRITICAL .

# Generate compliance report
trivy config --format json > compliance-report.json
```

## Tip 9: Use for Secret Detection

```bash
# Scan for secrets
trivy fs --scanners secret .

# Scan IaC for secrets
trivy config --scanners secret .
```

## Tip 10: Use for SBOM Generation

```bash
# Generate SBOM
trivy image --format cyclonedx myapp:latest > sbom.json

# Scan SBOM
trivy sbom sbom.json
```

## Tip 11: Use Trivy in IDE

Install VS Code or IntelliJ plugin for immediate feedback.

## Tip 12: Use Multiple Output Formats

```bash
# CLI for developers
trivy config .

# JSON for processing
trivy config --format json > results.json

# SARIF for GitHub
trivy config --format sarif > results.sarif
```

## Tip 13: Use for Incident Response

```bash
# Quick scan after incident
trivy config --format json > post-incident-scan.json

# Check for specific issues
trivy config --severity HIGH,CRITICAL .
```

## Tip 14: Use with Other Tools

```yaml
# Combine with other tools
repos:
  - repo: https://github.com/aquasecurity/trivy
    rev: '0.24.0'
    hooks:
      - id: trivy-config
  - repo: https://github.com/terraform-linters/tflint
    rev: v0.48.0
    hooks:
      - id: tflint
```

## Tip 15: Use for Cost Optimization

```bash
# Find expensive resources
trivy config --format json | jq '.Results[].Misconfigurations[] | select(.ID == "AWS007")'
```

## Tip 16: Use for Training

```bash
# Use Trivy to learn IaC security
trivy config --format json | jq '.Results[].Misconfigurations[] | {ID, Title, Resolution}'
```

## Tip 17: Use for Documentation

```bash
# Generate security documentation
trivy config --format json | jq '.Results[].Misconfigurations[] | {ID: .ID, Description: .Description, Resolution: .Resolution}'
```

## Tip 18: Use for Metrics

```bash
# Count issues by severity
trivy config --format json | jq '[.Results[].Misconfigurations[] | .Severity] | group_by(.) | map({severity: .[0], count: length})'

# Count by rule
trivy config --format json | jq '[.Results[].Misconfigurations[] | .ID] | group_by(.) | map({rule: .[0], count: length})'
```

## Tip 19: Use for Debugging

```bash
# Verbose output
trivy --debug config .

# Show all checks
trivy config --list-all-policies .

# Check specific rule
trivy config --include-checks AWS001 .
```

## Tip 20: Keep Trivy Updated

```bash
# Update regularly
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Check for new checks
trivy config --list-all-policies . | wc -l
```

---

# 12. Command Reference

## trivy

Main command.

```bash
trivy [global flags] <command> [command flags]

# Global Flags:
--cache-dir DIR        # Cache directory
--clean-cache          # Clean cache
--debug                # Debug mode
--insecure             # Allow insecure connections
--offline-scan         # Offline scan
--skip-db-update       # Skip DB update
--download-db-only     # Download DB only
--db-repository        # DB repository
--quiet                # Quiet mode
--timeout DURATION     # Timeout
--version              # Show version
-h, --help             # Show help
```

## trivy config

Scan IaC for misconfigurations.

```bash
trivy config [flags] <TARGET>

# Flags:
--scanners SCANNERS    # Scanner type (misconfig, secret)
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
--skip-dirs DIRS       # Skip directories
--skip-files FILES     # Skip files
--include-checks IDS  # Include specific checks
--exclude-checks IDS  # Exclude specific checks
--baseline FILE        # Baseline file
--policy DIR           # Custom policy directory
--namespaces NS        # Rego namespaces
--list-all-policies    # List all policies
```

## trivy fs

Scan filesystem for vulnerabilities and misconfigurations.

```bash
trivy fs [flags] <TARGET>

# Flags:
--scanners SCANNERS    # Scanner type (vuln, misconfig, secret)
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
--skip-dirs DIRS       # Skip directories
--skip-files FILES     # Skip files
--ignore-unfixed       # Ignore unfixed vulnerabilities
```

## trivy image

Scan container image for vulnerabilities.

```bash
trivy image [flags] <IMAGE>

# Flags:
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
--ignore-unfixed       # Ignore unfixed vulnerabilities
--vuln-type TYPE       # Vulnerability type (os, library)
--ignorefile FILE      # Ignore file
--skip-dirs DIRS       # Skip directories
```

## trivy sbom

Scan SBOM for vulnerabilities.

```bash
trivy sbom [flags] <SBOM>

# Flags:
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
--ignore-unfixed       # Ignore unfixed vulnerabilities
```

## trivy repo

Scan Git repository.

```bash
trivy repo [flags] <REPO>

# Flags:
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
--scanners SCANNERS    # Scanner type
```

## trivy rootfs

Scan root filesystem.

```bash
trivy rootfs [flags] <TARGET>

# Flags:
--scanners SCANNERS    # Scanner type
--format FORMAT        # Output format
--output FILE          # Output file
--severity SEVERITY    # Severity filter
--exit-code CODE       # Exit code
```

---

# 13. Configuration Reference

## 13.1 trivy.yaml

```yaml
# Severity filter
severity: "HIGH,CRITICAL"

# Exit code for CI/CD
exit-code: 1

# Output format
format: table

# Ignore unfixed
ignore-unfixed: false

# Cache directory
cache-dir: /tmp/trivy-cache

# Custom policies
policy:
  - ./policy/

# Skip directories
skip-dirs:
  - .git
  - node_modules
  - vendor

# Skip files
skip-files:
  - "*.md"
  - "LICENSE"

# Exclude checks
exclude-checks:
  - AWS001
  - AWS002

# Include checks
include-checks:
  - AWS001

# Namespaces for Rego
namespaces:
  - main
  - custom

# Vulnerability options
vuln-type:
  - os
  - library

# Skip DB update
skip-db-update: false

# Offline scan
offline-scan: false

# Timeout
timeout: 5m
```

## 13.2 Scan Types Reference

| Scan Type | Command | Purpose |
|-----------|---------|---------|
| `config` | `trivy config` | Scan IaC for misconfigurations |
| `fs` | `trivy fs` | Scan filesystem for vulns + misconfigs |
| `image` | `trivy image` | Scan container image |
| `sbom` | `trivy sbom` | Scan SBOM |
| `repo` | `trivy repo` | Scan Git repository |
| `rootfs` | `trivy rootfs` | Scan root filesystem |

## 13.3 Output Formats Reference

| Format | Command | Use Case |
|--------|---------|----------|
| `table` | `--format table` | CLI display |
| `json` | `--format json` | Processing, APIs |
| `sarif` | `--format sarif` | GitHub Advanced Security |
| `junit` | `--format junit` | CI/CD test results |
| `cyclonedx` | `--format cyclonedx` | SBOM format |
| `spdx` | `--format spdx` | SBOM format |

## 13.4 IaC Frameworks Reference

| Framework | Extensions | Scan Command |
|-----------|-----------|--------------|
| Terraform | `.tf`, `.tf.json` | `trivy config` |
| CloudFormation | `.json`, `.yaml`, `.template` | `trivy config` |
| Kubernetes | `.yaml`, `.json` | `trivy config --scanners misconfig` |
| Dockerfile | `Dockerfile`, `*.dockerfile` | `trivy config` |
| Helm | `Chart.yaml`, `values.yaml` | `trivy config` |
| ARM | `.json`, `.bicep` | `trivy config` |
| Docker Compose | `docker-compose.yml` | `trivy config` |

## 13.5 Check IDs Reference

| ID | Framework | Severity | Description |
|----|-----------|----------|-------------|
| AWS001 | AWS | MEDIUM | S3 bucket does not have logging enabled |
| AWS002 | AWS | MEDIUM | S3 bucket does not have versioning enabled |
| AWS003 | AWS | HIGH | S3 bucket does not have server-side encryption |
| AWS004 | AWS | HIGH | S3 bucket does not have public access blocked |
| AWS005 | AWS | MEDIUM | VPC does not have flow logs enabled |
| AWS006 | AWS | CRITICAL | Security group allows unrestricted ingress |
| AWS007 | AWS | LOW | EC2 instance does not have termination protection |
| AWS008 | AWS | HIGH | RDS instance does not have encryption enabled |
| AWS009 | AWS | MEDIUM | RDS instance does not have backup enabled |
| AWS010 | AWS | MEDIUM | SQS queue does not have encryption enabled |
| AZU001 | Azure | HIGH | Storage account does not have HTTPS traffic only |
| AZU002 | Azure | HIGH | Storage account does not have secure transfer |
| AZU003 | Azure | MEDIUM | Key Vault does not have soft delete enabled |
| AZU004 | Azure | CRITICAL | NSG allows unrestricted SSH access |
| GCP001 | GCP | MEDIUM | GCE instance does not have IP forwarding disabled |
| GCP002 | GCP | MEDIUM | GCP project does not have OS login enabled |
| GCP003 | GCP | MEDIUM | GCS bucket does not have logging enabled |
| KSV001 | K8s | HIGH | Container should not run as root |
| KSV002 | K8s | CRITICAL | Container should not have privileged access |
| KSV003 | K8s | HIGH | Container should not run as host |
| KSV004 | K8s | HIGH | Container should not allow privilege escalation |

---

# 14. Real-World Examples

## Example 1: Complete CI/CD Pipeline

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  container-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Scan container
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'container-scan.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Scan Terraform
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: 'terraform/'
          format: 'sarif'
          output: 'terraform-scan.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

      - name: Scan Kubernetes
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: 'k8s/'
          format: 'sarif'
          output: 'k8s-scan.sarif'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

  upload-sarif:
    runs-on: ubuntu-latest
    needs: [container-scan, iac-scan]
    steps:
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: container-scan.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: terraform-scan.sarif
      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: k8s-scan.sarif
```

## Example 2: Custom Policy for Organization

```rego
# policy/required_tags.rego
package main

import rego.v1

# Check that all AWS resources have required tags
required_tags := {"Environment", "Team", "CostCenter"}

deny contains msg if {
    resource := input.aws_s3_bucket[name]
    tags := resource.tags
    missing := required_tags - {t | tags[t]}
    count(missing) > 0
    msg := sprintf("S3 bucket '%s' is missing required tags: %v", [name, missing])
}

deny contains msg if {
    resource := input.aws_instance[name]
    tags := resource.tags
    missing := required_tags - {t | tags[t]}
    count(missing) > 0
    msg := sprintf("EC2 instance '%s' is missing required tags: %v", [name, missing])
}

deny contains msg if {
    resource := input.aws_db_instance[name]
    tags := resource.tags
    missing := required_tags - {t | tags[t]}
    count(missing) > 0
    msg := sprintf("RDS instance '%s' is missing required tags: %v", [name, missing])
}
```

## Example 3: Multi-Cloud Security Scan

```bash
# Scan AWS
trivy config ./aws/ --severity HIGH,CRITICAL

# Scan Azure
trivy config ./azure/ --severity HIGH,CRITICAL

# Scan GCP
trivy config ./gcp/ --severity HIGH,CRITICAL

# Generate combined report
trivy config ./aws/ --format json > aws-results.json
trivy config ./azure/ --format json > azure-results.json
trivy config ./gcp/ --format json > gcp-results.json
```

## Example 4: Pre-Commit with Multiple Tools

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/trivy
    rev: '0.24.0'
    hooks:
      - id: trivy-config
        args:
          - --severity
          - HIGH,CRITICAL

  - repo: https://github.com/terraform-linters/tflint
    rev: v0.48.0
    hooks:
      - id: tflint

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

## Example 5: Container + IaC Combined Security

```yaml
# .github/workflows/complete-security.yml
name: Complete Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp .

      - name: Scan container image
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: 'myapp'
          format: 'sarif'
          output: 'image-scan.sarif'

      - name: Scan IaC
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: '.'
          format: 'sarif'
          output: 'iac-scan.sarif'

      - name: Scan Dockerfile
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: 'config'
          scan-ref: 'Dockerfile'
          format: 'sarif'
          output: 'dockerfile-scan.sarif'

      - name: Generate SBOM
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: 'myapp'
          format: 'cyclonedx'
          output: 'sbom.json'
```

## Example 6: Compliance Auditing

```bash
# Generate compliance report
trivy config --format json > compliance-report.json

# Extract findings by compliance framework
cat compliance-report.json | jq '.Results[].Misconfigurations[] | select(.ID | startswith("AWS")) | {ID, Title, Severity, Compliance}'

# Generate JUnit XML for CI/CD
trivy config --format junit > compliance-report.xml
```

---

# 15. Further Reading

## Official Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [Trivy IaC Scanning](https://aquasecurity.github.io/trivy/latest/docs/target/iac/)
- [Custom Policies](https://aquasecurity.github.io/trivy/latest/docs/target/iac/custom/)
- [Aqua Security](https://www.aquasec.com/)

## Learning Resources

- [Trivy Getting Started](https://aquasecurity.github.io/trivy/latest/getting-started/)
- [IaC Scanning Guide](https://aquasecurity.github.io/trivy/latest/docs/target/iac/)
- [Rego Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Terraform Security Best Practices](https://www.hashicorp.com/blog/terraform-security-best-practices)

## Community

- [Trivy GitHub Discussions](https://github.com/aquasecurity/trivy/discussions)
- [Trivy Slack](https://aquasecurity.github.io/trivy/latest/community/)
- [Aqua Security Blog](https://blog.aquasec.com/)

## Related Tools

- **tfsec**: Terraform-specific security scanner
- **Checkov**: Multi-framework IaC scanner
- **Terrascan**: OPA-based IaC scanner
- **KICS**: Keeping Infrastructure as Code Secure
- **tflint**: Terraform linter
- **cfn-lint**: CloudFormation linter
- **OPA/Rego**: Policy engine

---

*This guide covers Trivy as of version 0.55.x. For the latest features, refer to the official documentation.*
