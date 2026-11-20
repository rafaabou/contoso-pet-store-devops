# Checkov Complete Guide

## Table of Contents

1. [What Is Checkov](#1-what-is-checkov)
2. [Why Use Checkov](#2-why-use-checkov)
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

# 1. What Is Checkov

Checkov is an open-source static analysis tool for Infrastructure as Code (IaC) developed by Bridgecrew (now part of Palo Alto Networks). It scans Terraform, CloudFormation, Kubernetes, Docker, Ansible, and other IaC frameworks for security misconfigurations and compliance violations.

## 1.1 History

- **2019**: Created by Bridgecrew as an open-source IaC scanner
- **2020**: Rapid growth with 1,000+ built-in policies
- **2021**: Bridgecrew acquired by Palo Alto Networks
- **2022**: Checkov 2.x with custom policy support via Python
- **2023**: Checkov 3.x with enhanced scanning and custom graph policies
- **2024**: Continued expansion of policy library and framework support

## 1.2 Architecture

```
┌─────────────────────────────────────────────────┐
│                  Checkov                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │  Parser  │  │ Graph    │  │   Policy     │  │
│  │  Engine  │  │ Builder  │  │   Engine     │  │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │
│       │              │               │           │
│  ┌────┴──────────────┴───────────────┴────────┐ │
│  │         Policy Definitions (YAML/Python)   │ │
│  │    (CKV, CKV2_AWS, CKV2_AZURE, etc.)      │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │      Framework Adapters                    │ │
│  │  Terraform │ CF │ K8s │ Docker │ ARM       │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## 1.3 Key Features

- **Multi-Framework**: Terraform, CloudFormation, Kubernetes, Docker, ARM, Ansible, Serverless, etc.
- **1,000+ Built-in Policies**: CIS, SOC2, PCI-DSS, HIPAA, and custom rules
- **Graph-Based Analysis**: Detects cross-resource misconfigurations
- **Custom Policies**: Write Python or YAML-based custom checks
- **CI/CD Integration**: GitHub Actions, GitLab CI, Jenkins, Azure DevOps, etc.
- **IDE Integration**: VS Code, IntelliJ plugins
- **Output Formats**: CLI, JSON, SARIF, JUnit XML, CLI Compact
- **Baseline Support**: Ignore known issues, track new violations only
- **Adaptive Frameworks**: Auto-detect IaC type

## 1.4 Supported Frameworks

| Framework | File Extensions | Description |
|-----------|----------------|-------------|
| Terraform | `.tf`, `.tf.json` | HCL and JSON Terraform configs |
| CloudFormation | `.json`, `.yaml`, `.template` | AWS CloudFormation templates |
| Kubernetes | `.yaml`, `.json` | K8s manifests and Helm charts |
| Docker | `Dockerfile`, `*.dockerfile` | Dockerfile scanning |
| Ansible | `playbooks/*.yml` | Ansible playbooks and roles |
| ARM | `.json`, `.bicep` | Azure Resource Manager templates |
| Serverless | `serverless.yml` | Serverless Framework configs |
| GitHub Actions | `.github/workflows/*.yml` | CI/CD workflow scanning |

---

# 2. Why Use Checkov

## 2.1 The Problem Checkov Solves

Security misconfigurations in IaC are one of the leading causes of cloud breaches:

- **Public S3 buckets** exposing sensitive data
- **Unencrypted databases** violating compliance
- **Overly permissive IAM policies** granting excessive access
- **Open security groups** allowing unrestricted access
- **Missing logging and monitoring** creating blind spots
- **Hardcoded secrets** in configuration files

Manual review of IaC files is:
- **Error-prone**: Humans miss issues in large codebases
- **Slow**: Security reviews bottleneck deployments
- **Inconsistent**: Different reviewers apply different standards
- **Late**: Issues found after deployment instead of before

## 2.2 Benefits

| Benefit | Description |
|---------|-------------|
| **Shift-Left Security** | Catch issues before deployment |
| **Automated Compliance** | Enforce CIS, SOC2, PCI-DSS, HIPAA |
| **Developer Feedback** | Immediate feedback on misconfigurations |
| **No Agent Required** | Static analysis, no runtime overhead |
| **Custom Policies** | Organization-specific security rules |
| **Graph Analysis** | Detect cross-resource issues |
| **Baseline Support** | Ignore known, track only new issues |
| **Multi-Framework** | One tool for all IaC |
| **CI/CD Native** | Integrate into existing pipelines |

## 2.3 When to Use Checkov

**Good fit:**
- Pre-commit hooks for immediate feedback
- CI/CD pipeline gates for deployment blocking
- Security audits and compliance scanning
- Code review automation
- Ongoing infrastructure monitoring

**Not ideal for:**
- Runtime security (use Prisma Cloud, Falco)
- Application code scanning (use SonarQube, Snyk)
- Dynamic testing (use DAST tools)

## 2.4 Checkov vs. Other IaC Scanners

| Tool | Frameworks | Custom Rules | License | Best For |
|------|-----------|--------------|---------|----------|
| Checkov | Terraform, CF, K8s, Docker, ARM | Python, YAML | Apache 2.0 | Comprehensive multi-framework |
| tfsec | Terraform | Go | MIT | Terraform-specific |
| Terrascan | Terraform, K8s, Docker, Helm | Rego | Apache 2.0 | OPA-based policies |
| Trivy | Terraform, K8s, Docker | Go | Apache 2.0 | Vulnerability + IaC |
| KICS | Terraform, CF, K8s, Docker | Rego | Apache 2.0 | Multi-framework |
| Snyk IaC | Terraform, CF, K8s | Snyk DSL | Proprietary | Snyk ecosystem |
| cfn-lint | CloudFormation | Python | MIT-0 | CF-specific |

---

# 3. Installation

## 3.1 Prerequisites

- **Python**: 3.7 or later
- **Pip**: Python package manager
- **Git**: For cloning repositories (optional)

## 3.2 Install via pip

```bash
# Install Checkov
pip install checkov

# Install with all extras
pip install checkov[all]

# Install specific version
pip install checkov==3.1.0

# Upgrade
pip install --upgrade checkov
```

## 3.3 Install via pipx (Isolated)

```bash
pipx install checkov
```

## 3.4 Install via Docker

```bash
# Pull the image
docker pull bridgecrew/checkov

# Scan current directory
docker run --rm -v "$(pwd):/tf" bridgecrew/checkov -d /tf

# Scan specific file
docker run --rm -v "$(pwd):/tf" bridgecrew/checkov -f /tf/main.tf
```

## 3.5 Install via Homebrew (macOS)

```bash
brew install checkov
```

## 3.6 Verify Installation

```bash
checkov --version
# 3.1.x

# Run a quick test
checkov -d .
```

## 3.7 Shell Completion

```bash
# Bash
checkov --install-completion bash

# Zsh
checkov --install-completion zsh

# Fish
checkov --install-completion fish
```

---

# 4. Configuration

## 4.1 Configuration File

Checkov uses a `.checkov.yml` file in the project root:

```yaml
# .checkov.yml

# Frameworks to scan
framework:
  - terraform
  - cloudformation
  - kubernetes
  - dockerfile

# Skip specific checks
skip-check:
  - CKV_AWS_18  # S3 bucket access logging
  - CKV_AWS_20  # S3 bucket versioning
  - CKV2_AWS_5  # ALB HTTPS only

# Skip checks for specific resources
skip-checks:
  - check_id: CKV_AWS_18
    resource: "aws_s3_bucket.logs"
  - check_id: CKV_AWS_20
    resource: "module.backup.aws_s3_bucket.backup"

# Exclude directories
exclude:
  - .git
  - node_modules
  - .terraform
  - test/
  - tests/

# Include only specific directories
include:
  - modules/
  - environments/

# Output format
output: cli

# Quiet mode (only failed checks)
quiet: false

# Compact output
compact: true

# Soft fail (exit code 0 even with failures)
soft-fail: false

# Hard fail on specific checks
hard-fail-on:
  - CKV_AWS_14
  - CKV_AWS_16

# Specific check configuration
check-config:
  CKV_AWS_14:
    # Custom threshold
    max_connections: 100
```

## 4.2 Environment Variables

```bash
# Set check ID to skip
export CHECKOV_SKIP_CHECK=CKV_AWS_18,CKV_AWS_20

# Set output format
export CHECKOV_OUTPUT=json

# Set log level
export CHECKOV_LOG_LEVEL=INFO
```

## 4.3 Pre-Commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
        args:
          - --directory
          - .
          - --framework
          - terraform
          - --hard-fail-on
          - CKV_AWS_14
```

---

# 5. Core Concepts

## 5.1 Policy IDs

Checkov policies follow a naming convention:

| Prefix | Framework |
|--------|-----------|
| CKV_AWS_* | AWS services |
| CKV_AZURE_* | Azure services |
| CKV_GCP_* | Google Cloud services |
| CKV_K8S_* | Kubernetes |
| CKV_DOCKER_* | Dockerfile |
| CKV2_AWS_* | AWS graph-based checks |
| CKV2_GCP_* | GCP graph-based checks |
| CKV_TF_* | Terraform-specific |

## 5.2 Check Types

### Configuration Checks
Validate individual resource configurations:
```python
class CKV_AWS_18(BaseCheck):
    def scan_resource_conf(self, conf):
        # Check if S3 bucket has access logging enabled
        if conf.get("logging") and conf["logging"].get("target_bucket"):
            return CheckResult.PASSED
        return CheckResult.FAILED
```

### Graph-Based Checks
Analyze relationships between resources:
```python
class CKV2_AWS_5(BaseGraphCheck):
    def scan_resource_conf(self, conf):
        # Check if ALB has HTTPS listener
        pass
```

### Composite Checks
Combine multiple checks:
```yaml
composite_checks:
  - id: CKV_CIS_AWS_1_3
    checks:
      - CKV_AWS_14
      - CKV_AWS_18
      - CKV_AWS_20
    eval_method: all
```

## 5.3 Severities

| Level | Description |
|-------|-------------|
| UNKNOWN | Unspecified severity |
| LOW | Low risk |
| MEDIUM | Medium risk |
| HIGH | High risk |
| CRITICAL | Critical risk |

```yaml
# Custom severity
severity: CRITICAL

# Or from configuration
severity_mapping:
  CKV_AWS_14: HIGH
  CKV_AWS_18: MEDIUM
```

## 5.4 Check Categories

| Category | Description |
|----------|-------------|
| ENCRYPTION | Data encryption at rest/in transit |
| NETWORKING | Network configuration and security |
| IAM | Identity and access management |
| LOGGING | Audit logging and monitoring |
| COMPLIANCE | Regulatory compliance |
| SECRETS | Hardcoded secrets detection |
| VULNERABILITY | Known vulnerabilities |

## 5.5 Guideline URLs

Each check includes a URL to documentation:
```
Check: CKV_AWS_14
	[PASSED] Resource: aws_s3_bucket.example
	Guide: https://docs.checkov.io/page_27.html
```

## 5.6 Baselines

Track only new violations in existing code:

```bash
# Save baseline
checkov -d . --download-external-modules true --output json > baseline.json

# Use baseline
checkov -d . --baseline baseline.json
```

## 5.7 Custom Policies (YAML)

```yaml
# custom_policies/CKV_CUSTOM_1.yaml
metadata:
  id: "CKV_CUSTOM_1"
  name: "Ensure S3 bucket has encryption enabled"
  category: "ENCRYPTION"
  severity: "HIGH"
  description: "S3 buckets must have server-side encryption enabled"

definition:
  or:
    - cond_type: attribute
      resource_types:
        - aws_s3_bucket
      attribute: server_side_encryption_configuration.rule.apply_server_side_encryption_by_default.sse_algorithm
      operator: exists
    - cond_type: attribute
      resource_types:
        - aws_s3_bucket_server_side_encryption_configuration
      attribute: rule.apply_server_side_encryption_by_default.sse_algorithm
      operator: exists
```

## 5.8 Custom Policies (Python)

```python
# custom_policies/check_s3_encryption.py
from checkov.common.checks.base_check import BaseCheck
from checkov.common.models.enums import CheckCategories, CheckResult

class S3EncryptionCheck(BaseCheck):
    def __init__(self):
        name = "Ensure S3 bucket has encryption enabled"
        id = "CKV_CUSTOM_1"
        supported_resources = ["aws_s3_bucket"]
        categories = [CheckCategories.ENCRYPTION]
        super().__init__(name, id, categories)

    def scan_resource_conf(self, conf):
        encryption = conf.get("server_side_encryption_configuration")
        if encryption:
            return CheckResult.PASSED
        return CheckResult.FAILED

check = S3EncryptionCheck()
```

---

# 6. Usage Guide (Step-by-Step)

## 6.1 Step 1: Scan a Directory

```bash
# Scan current directory
checkov -d .

# Scan specific directory
checkov -d /path/to/terraform

# Scan with verbose output
checkov -d . -v
```

## 6.2 Step 2: Scan Specific Files

```bash
# Scan single file
checkov -f main.tf

# Scan multiple files
checkov -f main.tf variables.tf outputs.tf
```

## 6.3 Step 3: Filter by Framework

```bash
# Scan only Terraform
checkov -d . --framework terraform

# Scan only CloudFormation
checkov -d . --framework cloudformation

# Scan only Kubernetes
checkov -d . --framework kubernetes

# Scan multiple frameworks
checkov -d . --framework terraform kubernetes dockerfile
```

## 6.4 Step 4: Skip Specific Checks

```bash
# Skip check by ID
checkov -d . --skip-check CKV_AWS_18

# Skip multiple checks
checkov -d . --skip-check CKV_AWS_18,CKV_AWS_20

# Skip check for specific resource
checkov -d . --skip-check CKV_AWS_18 --check-skip-resource "aws_s3_bucket.logs"
```

## 6.5 Step 5: Use Output Formats

```bash
# CLI (default)
checkov -d . --output cli

# JSON output
checkov -d . --output json > results.json

# SARIF output (for GitHub Advanced Security)
checkov -d . --output sarif > results.sarif

# JUnit XML (for CI/CD)
checkov -d . --output junitxml > results.xml

# Compact output
checkov -d . --output cli --compact
```

## 6.6 Step 6: Enforce Hard Fail

```bash
# Fail on critical checks
checkov -d . --hard-fail-on CRITICAL

# Fail on specific checks
checkov -d . --hard-fail-on CKV_AWS_14

# Soft fail (always exit 0)
checkov -d . --soft-fail
```

## 6.7 Step 7: Download External Modules

```bash
# Download Terraform modules
checkov -d . --download-external-modules true

# Specify module download directory
checkov -d . --external-modules-dir /tmp/terraform-modules
```

## 6.8 Step 8: Create Baseline

```bash
# Generate baseline
checkov -d . --output json > baseline.json

# Use baseline (only report new issues)
checkov -d . --baseline baseline.json
```

## 6.9 Step 9: Integrate in CI/CD

```yaml
# .github/workflows/checkov.yml
name: Checkov Security Scan

on: [push, pull_request]

jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: terraform
          soft_fail: false
          output_format: cli,sarif
          output_file_path: console,results.sarif

      - name: Upload SARIF to GitHub
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

## 6.10 Step 10: Review and Remediate

```bash
# View all failures
checkov -d . --output json | jq '.results.failed_checks'

# Group by check ID
checkov -d . --output json | jq '[.results.failed_checks[] | .check_id] | group_by(.) | map({check: .[0], count: length})'

# View specific check details
checkov -d . --check CKV_AWS_14 -v
```

---

# 7. Custom Policies

## 7.1 YAML-Based Custom Policies

```yaml
# custom_policies/CKV_CUSTOM_AWS_1.yaml
metadata:
  id: "CKV_CUSTOM_AWS_1"
  name: "Ensure EC2 instances have termination protection"
  category: "GENERAL_SECURITY"
  severity: "HIGH"
  description: "EC2 instances in production should have termination protection enabled"
  framework: terraform
  platform: aws

definition:
  cond_type: attribute
  resource_types:
    - aws_instance
  attribute: disable_api_termination
  operator: equals
  value: true
```

## 7.2 Python-Based Custom Policies

```python
# custom_checks/check_ec2_termination_protection.py
from checkov.common.checks.base_check import BaseCheck
from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.context_parsers.registry import Registry

class EC2TerminationProtection(BaseCheck):
    def __init__(self):
        name = "Ensure EC2 instances have termination protection"
        id = "CKV_CUSTOM_AWS_1"
        supported_resources = ["aws_instance"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name, id, categories)

    def scan_resource_conf(self, conf):
        """Check if EC2 instance has termination protection"""
        termination_protection = conf.get("disable_api_termination")
        if termination_protection and termination_protection[0] is True:
            return CheckResult.PASSED
        return CheckResult.FAILED

check = EC2TerminationProtection()
```

## 7.3 Graph-Based Custom Policies

```python
# custom_checks/check_s3_public_access.py
from checkov.common.checks.base_check import BaseCheck
from checkov.common.models.enums import CheckResult
from checkov.terraform.checks.resource.registry import Registry

class S3PublicAccessCheck(BaseCheck):
    def __init__(self):
        name = "Ensure S3 buckets are not publicly accessible"
        id = "CKV_CUSTOM_AWS_2"
        supported_resources = ["aws_s3_bucket"]
        super().__init__(name, id)

    def scan_resource_conf(self, conf):
        """Check if S3 bucket has public access blocked"""
        acl = conf.get("acl")
        if acl and "public" in str(acl).lower():
            return CheckResult.FAILED

        public_access_block = conf.get("public_access_block")
        if public_access_block:
            if (public_access_block.get("block_public_acls") and
                public_access_block.get("block_public_policy")):
                return CheckResult.PASSED

        return CheckResult.FAILED

check = S3PublicAccessCheck()
```

## 7.4 Graph-Based Cross-Resource Policies

```yaml
# custom_policies/CKV2_CUSTOM_AWS_1.yaml
metadata:
  id: "CKV2_CUSTOM_AWS_1"
  name: "Ensure VPC has flow logs enabled"
  category: "LOGGING"
  severity: "HIGH"
  framework: terraform
  platform: aws
  graph_resource_type: "AWS::EC2::VPC"

definition:
  cond_type: attribute
  resource_types:
    - aws_vpc
    - aws_flow_log
  attribute: vpc_id
  operator: exists
```

## 7.5 Custom Policy Tests

```python
# tests/test_custom_checks.py
import pytest
from custom_checks.check_ec2_termination_protection import EC2TerminationProtection

def test_ec2_termination_protection_pass():
    check = EC2TerminationProtection()
    config = {
        "disable_api_termination": [True],
        "instance_type": ["t3.micro"]
    }
    assert check.scan_resource_conf(config) == CheckResult.PASSED

def test_ec2_termination_protection_fail():
    check = EC2TerminationProtection()
    config = {
        "disable_api_termination": [False],
        "instance_type": ["t3.micro"]
    }
    assert check.scan_resource_conf(config) == CheckResult.FAILED
```

## 7.6 Composite Policies

```yaml
# custom_policies/CKV_COMPOSITE_AWS_1.yaml
metadata:
  id: "CKV_COMPOSITE_AWS_1"
  name: "AWS Security Best Practices"
  category: "COMPLIANCE"
  severity: "HIGH"

composite_checks:
  - id: CKV_AWS_14
    resource: aws_s3_bucket
  - id: CKV_AWS_18
    resource: aws_s3_bucket
  - id: CKV_AWS_20
    resource: aws_s3_bucket
  - id: CKV_AWS_21
    resource: aws_s3_bucket

eval_method: all
```

---

# 8. Integration

## 8.1 GitHub Actions

```yaml
# .github/workflows/checkov.yml
name: Checkov

on: [push, pull_request]

jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: .
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: checkov-results.sarif
```

## 8.2 GitLab CI

```yaml
# .gitlab-ci.yml
checkov:
  image:
    name: bridgecrew/checkov
    entrypoint: [""]
  script:
    - checkov -d . --output gitlab_sast
  artifacts:
    reports:
      sast: gl-sast-report.json
```

## 8.3 Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Checkov Scan') {
            steps {
                sh '''
                    docker run --rm -v $(pwd):/tf bridgecrew/checkov \
                        -d /tf \
                        --output junitxml \
                        --output-file /tf/checkov-results.xml
                '''
                junit 'checkov-results.xml'
            }
        }
    }
}
```

## 8.4 Azure DevOps

```yaml
# azure-pipelines.yml
steps:
  - task: Docker@2
    displayName: 'Run Checkov'
    inputs:
      command: run
      containerRegistry: 'checkov-image'
      arguments: '-v $(Build.SourcesDirectory):/tf bridgecrew/checkov -d /tf --output junitxml --output-file /tf/checkov-results.xml'

  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'checkov-results.xml'
```

## 8.5 Pre-Commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
        args:
          - --directory
          - .
          - --framework
          - terraform
          - --compact
          - --quiet
```

## 8.6 IDE Integration

### VS Code

```
Install "Checkov" extension from marketplace
Configure in settings.json:
{
  "checkov.enable": true,
  "checkov.directory": ".",
  "checkov.frameworks": ["terraform"]
}
```

### IntelliJ

```
Install "Checkov" plugin from JetBrains Marketplace
Configure in Settings > Tools > Checkov
```

## 8.7 Terragrunt Integration

```yaml
# terragrunt.hcl
# Run Checkov before apply
terraform {
  before_hook "checkov" {
    commands = ["apply", "plan"]
    execute = ["checkov", "-d", ".", "--hard-fail-on", "CRITICAL"]
  }
}
```

## 8.8 Terraform Cloud Integration

```hcl
# In Terraform Cloud workspace settings
# Add Checkov as a Run Task

# Or use Sentinel with Checkov results
```

---

# 9. Security

## 9.1 Secret Detection

```bash
# Checkov detects hardcoded secrets
checkov -d . --framework secrets

# Custom secret patterns
checkov -d . --check CKV_SECRET_1
```

## 9.2 SAST Integration

```bash
# Combine with SAST tools
checkov -d . --output sarif > checkov.sarif

# Upload to GitHub Advanced Security
# (see GitHub Actions integration)
```

## 9.3 Supply Chain Security

```bash
# Scan Terraform modules
checkov -d . --download-external-modules true --external-modules-dir /tmp/modules

# Pin module versions
checkov -d . --check CKV_TF_1  # Ensure modules use pinned versions
```

## 9.4 Secrets Scanning

```yaml
# .checkov.yml - Enable secret scanning
framework:
  - secrets
```

## 9.5 CIS Benchmarks

```bash
# Run CIS AWS Foundations Benchmark
checkov -d . --check CKV_AWS_2,CKV_AWS_3,CKV_AWS_4,CKV_AWS_5,CKV_AWS_6

# Run CIS Kubernetes Benchmark
checkov -d . --framework kubernetes --check CKV_K8S_1,CKV_K8S_2,CKV_K8S_3
```

## 9.6 Compliance Frameworks

```yaml
# .checkov.yml - Enable compliance frameworks
compliance:
  - aws_foundations
  - pci_dss
  - hipaa
  - soc2
```

## 9.7 Scanning Docker Images

```bash
# Scan Dockerfile
checkov -f Dockerfile --framework dockerfile

# Scan docker-compose
checkov -f docker-compose.yml --framework docker_compose
```

## 9.8 Scanning Kubernetes Manifests

```bash
# Scan K8s manifests
checkov -d k8s/ --framework kubernetes

# Scan Helm chart
helm template . | checkov -f - --framework kubernetes
```

---

# 10. Troubleshooting

## Issue 1: Checkov Skips Files

```
WARNING: No files were scanned
```

**Cause**: File extensions not recognized or excluded.

**Fix**:
```bash
# Check file extensions
ls *.tf

# Run with verbose
checkov -d . -v

# Check exclude patterns
checkov -d . --exclude test/
```

## Issue 2: False Positives

Checkov flags a correctly configured resource.

**Fix**:
```yaml
# .checkov.yml - Skip for specific resource
skip-checks:
  - check_id: CKV_AWS_18
    resource: "aws_s3_bucket.logs"
```

```bash
# Or skip globally
checkov -d . --skip-check CKV_AWS_18
```

## Issue 3: External Module Errors

```
ERROR: Failed to download module
```

**Fix**:
```bash
# Download modules manually
terraform init

# Then scan
checkov -d . --download-external-modules true
```

## Issue 4: Slow Performance

Scanning large repositories takes too long.

**Fix**:
```bash
# Scan specific directory
checkov -d modules/

# Limit frameworks
checkov -d . --framework terraform

# Use parallel scanning
checkov -d . --parallel 4

# Skip external modules
checkov -d . --download-external-modules false
```

## Issue 5: Check ID Not Found

```
Check 'CKV_AWS_9999' was not found
```

**Fix**:
```bash
# List available checks
checkov -d . --list

# Check specific framework
checkov -d . --framework terraform --list | grep CKV_AWS_14
```

## Issue 6: Permission Denied

```
Permission denied: /path/to/file
```

**Fix**:
```bash
# Fix file permissions
chmod 644 *.tf

# Or run as root (not recommended)
sudo checkov -d .
```

## Issue 7: Module Parsing Error

```
ERROR: Failed to parse module
```

**Fix**:
```bash
# Validate Terraform first
terraform validate

# Check for syntax errors
tflint

# Then run Checkov
checkov -d .
```

## Issue 8: Output Format Not Supported

```
ERROR: Output format 'xyz' not supported
```

**Fix**:
```bash
# Supported formats
checkov -d . --output cli
checkov -d . --output json
checkov -d . --output sarif
checkov -d . --output junitxml
checkov -d . --output github_failed_only
```

## Issue 9: Checkov Version Conflicts

```
ERROR: Incompatible check version
```

**Fix**:
```bash
# Upgrade checkov
pip install --upgrade checkov

# Check version
checkov --version
```

## Issue 10: Python Version Error

```
ERROR: Python 3.7+ required
```

**Fix**:
```bash
# Check Python version
python3 --version

# Install correct Python
sudo apt install python3.8

# Use virtual environment
python3.8 -m venv venv
source venv/bin/activate
pip install checkov
```

## Issue 11: Timeout During Scan

Scan times out on large codebases.

**Fix**:
```bash
# Increase timeout
checkov -d . --timeout 300

# Scan specific directory
checkov -d modules/important/
```

## Issue 12: Custom Policy Not Loaded

Custom policy not executing.

**Fix**:
```bash
# Check policy path
checkov -d . --config-file .checkov.yml

# Verify YAML syntax
python -c "import yaml; yaml.safe_load(open('custom_policy.yaml'))"

# Run with verbose
checkov -d . -v
```

## Issue 13: Baseline Mismatch

Baseline file doesn't match current scan.

**Fix**:
```bash
# Regenerate baseline
checkov -d . --output json > new_baseline.json

# Compare with old
diff baseline.json new_baseline.json

# Update baseline
checkov -d . --baseline baseline.json --update-baseline
```

## Issue 14: CI/CD Exit Code Issues

Checkov passes even with failures.

**Fix**:
```bash
# Set hard fail
checkov -d . --hard-fail-on HIGH

# Or use exit code
checkov -d .; exit $?
```

## Issue 15: Docker Permission Issues

```
ERROR: Permission denied when accessing files
```

**Fix**:
```bash
# Fix volume permissions
docker run --rm -v "$(pwd):/tf" bridgecrew/checkov -d /tf

# Or run with user mapping
docker run --rm -u $(id -u):$(id -g) -v "$(pwd):/tf" bridgecrew/checkov -d /tf
```

## Issue 16: SARIF Output Issues

SARIF file not recognized by GitHub.

**Fix**:
```bash
# Ensure correct format
checkov -d . --output sarif > results.sarif

# Validate SARIF
python -c "import json; json.load(open('results.sarif'))"
```

## Issue 17: Helm Chart Scanning Issues

```
ERROR: Failed to render Helm chart
```

**Fix**:
```bash
# Render Helm template first
helm template . > rendered.yaml

# Then scan
checkov -f rendered.yaml --framework kubernetes
```

## Issue 18: Memory Issues

Out of memory during scan.

**Fix**:
```bash
# Limit parallel scanning
checkov -d . --parallel 2

# Scan specific directory
checkov -d modules/
```

## Issue 19: Network Errors

Checkov can't download external modules.

**Fix**:
```bash
# Disable external module download
checkov -d . --download-external-modules false

# Or pre-download
terraform init
checkov -d . --download-external-modules true
```

## Issue 20: Custom Check Not Appearing

Custom check not showing in results.

**Fix**:
```bash
# Verify check is loaded
checkov -d . --list | grep CKV_CUSTOM

# Check file location
ls custom_checks/

# Check check ID format
# Must start with CKV_ and be unique
```

---

# 11. Tips and Best Practices

## Tip 1: Use Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
        args:
          - --framework
          - terraform
          - --compact
          - --quiet
```

## Tip 2: Use Baselines for Existing Code

```bash
# Generate baseline for existing code
checkov -d . --output json > baseline.json

# Use in CI/CD
checkov -d . --baseline baseline.json
```

## Tip 3: Create Custom Policies for Organization Rules

```python
# custom_checks/check_required_tags.py
class RequiredTagsCheck(BaseCheck):
    def __init__(self):
        name = "Ensure required tags are present"
        id = "CKV_CUSTOM_TAGS"
        supported_resources = ["*"]
        super().__init__(name, id)

    def scan_resource_conf(self, conf):
        tags = conf.get("tags")
        required_tags = ["Environment", "Team", "CostCenter"]
        if not tags:
            return CheckResult.FAILED
        missing = [t for t in required_tags if t not in tags]
        if missing:
            return CheckResult.FAILED
        return CheckResult.PASSED
```

## Tip 4: Use Severity Filtering

```bash
# Only report high/critical
checkov -d . --minimum-severity HIGH

# Skip low severity
checkov -d . --skip-check-severity LOW
```

## Tip 5: Use Graph Checks for Complex Rules

```yaml
# Ensure all public subnets have NAT gateways
metadata:
  id: "CKV2_CUSTOM_1"
  name: "Public subnets must have NAT gateways"
  framework: terraform

definition:
  and:
    - cond_type: attribute
      resource_types:
        - aws_subnet
      attribute: map_public_ip_on_launch
      operator: equals
      value: true
    - cond_type: attribute
      resource_types:
        - aws_subnet
      attribute: route_table_id
      operator: exists
```

## Tip 6: Integrate with Code Review

```yaml
# GitHub Actions - comment on PR
- name: Run Checkov
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: .
    soft_fail: true

- name: Comment on PR
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      const results = JSON.parse(fs.readFileSync('checkov-results.json'));
      // Post comment with results
```

## Tip 7: Use Config for Per-Project Settings

```yaml
# .checkov.yml
framework:
  - terraform
skip-check:
  - CKV_AWS_18
exclude:
  - test/
  - modules/legacy/
```

## Tip 8: Use Multiple Output Formats

```bash
# Generate multiple outputs
checkov -d . --output cli --output json --output sarif

# Or separately
checkov -d . --output cli
checkov -d . --output json > results.json
```

## Tip 9: Use Hard Fail in CI/CD

```bash
# Fail pipeline on high severity
checkov -d . --hard-fail-on HIGH

# Or on specific checks
checkov -d . --hard-fail-on CKV_AWS_14
```

## Tip 10: Use Quiet Mode for Clean Output

```bash
# Only show failures
checkov -d . --quiet

# Compact output
checkov -d . --compact
```

## Tip 11: Use Checkov with Terraform Cloud

```hcl
# Add as run task
# In Terraform Cloud workspace settings
# Add webhook for Checkov
```

## Tip 12: Use Custom Registries

```yaml
# .checkov.yml
registries:
  - https://custom-registry.example.com/checkov-policies
```

## Tip 13: Use for Compliance Auditing

```bash
# Generate compliance report
checkov -d . --output junitxml > compliance-report.xml

# Use in audit
checkov -d . --check CKV_AWS_2,CKV_AWS_3,CKV_AWS_4
```

## Tip 14: Use for Cost Optimization

```bash
# Check for oversized resources
checkov -d . --check CKV_AWS_35  # RDS instance size
```

## Tip 15: Use with Infracost

```yaml
# Pre-commit
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
  - repo: https://github.com/infracost/pre-commit
    rev: v0.10.0
    hooks:
      - id: infracost-usage-sync
```

## Tip 16: Scan Kubernetes in CI

```yaml
# Scan rendered Helm templates
- name: Scan K8s
  run: |
    helm template . > rendered.yaml
    checkov -f rendered.yaml --framework kubernetes
```

## Tip 17: Use for Secrets Detection

```bash
# Enable secrets scanning
checkov -d . --framework secrets
```

## Tip 18: Use with Docker Images

```bash
# Scan Dockerfile
checkov -f Dockerfile --framework dockerfile

# Scan docker-compose
checkov -f docker-compose.yml --framework docker_compose
```

## Tip 19: Use Checkov in IDE

Install VS Code or IntelliJ plugin for immediate feedback.

## Tip 20: Keep Checkov Updated

```bash
# Update regularly
pip install --upgrade checkov

# Check for new policies
checkov --list | wc -l
```

---

# 12. Command Reference

## checkov

Main command.

```bash
checkov [OPTIONS]

# Options:
-d DIR, --directory DIR    # Directory to scan
-f FILE, --file FILE       # File to scan
--framework FRAMEWORK      # Framework(s) to scan
--skip-check CHECK         # Check ID(s) to skip
--check CHECK              # Check ID(s) to run
--output FORMAT            # Output format
--output-file FILE         # Output file
--soft-fail                # Exit 0 even with failures
--hard-fail-on SEVERITY    # Fail on severity level
--quiet                    # Only show failures
--compact                  # Compact output
--verbose                  # Verbose output
--baseline FILE            # Baseline file
--config-file FILE         # Config file
--create-config FILE       # Create config file
--list                     # List available checks
--download-external-modules BOOL  # Download external modules
--external-modules-dir DIR # External modules directory
--parallel N               # Parallel scanning threads
--timeout N                # Scan timeout in seconds
--minimum-severity LEVEL   # Minimum severity level
```

## checkov --list

List all available checks.

```bash
checkov --list
checkov --list --framework terraform
checkov --list --check-type CKV_AWS
```

## checkov --output

Output formats.

```bash
--output cli              # CLI output (default)
--output json             # JSON output
--output sarif            # SARIF format
--output junitxml         # JUnit XML
--output github_failed_only  # GitHub format
--output gitlab_sast      # GitLab SAST
--output cli_compact      # Compact CLI
```

## checkov --framework

Filter by framework.

```bash
--framework terraform
--framework cloudformation
--framework kubernetes
--framework dockerfile
--framework ansible
--framework arm
--framework serverless
--framework github_actions
--framework secrets
```

---

# 13. Configuration Reference

## 13.1 .checkov.yml

```yaml
# Framework selection
framework:
  - terraform
  - cloudformation
  - kubernetes
  - dockerfile

# Skip checks
skip-check:
  - CKV_AWS_18
  - CKV_AWS_20

# Skip checks for specific resources
skip-checks:
  - check_id: CKV_AWS_18
    resource: "aws_s3_bucket.logs"

# Include only specific checks
check:
  - CKV_AWS_14
  - CKV_AWS_16

# Exclude patterns
exclude:
  - .git
  - node_modules
  - test/

# Include patterns
include:
  - modules/

# Output configuration
output: cli
output-file: results.json

# Severity filtering
minimum-severity: MEDIUM

# Hard fail configuration
hard-fail-on:
  - CRITICAL
  - HIGH

# Soft fail
soft-fail: false

# Quiet mode
quiet: false

# Compact output
compact: false

# External modules
download-external-modules: true
external-modules-dir: /tmp/terraform-modules

# Parallel scanning
parallel: 4

# Timeout
timeout: 300

# Custom policy paths
check:
  - custom_policies/
```

## 13.2 Check Configuration

```yaml
# Per-check configuration
check-config:
  CKV_AWS_14:
    # Custom parameters
    max_connections: 100

  CKV_AWS_18:
    # Custom parameters
    required_fields:
      - target_bucket
      - target_prefix
```

## 13.3 Severity Configuration

```yaml
# Severity mapping
severity_mapping:
  CKV_AWS_14: CRITICAL
  CKV_AWS_18: HIGH
  CKV_AWS_20: MEDIUM
  CKV_AWS_21: LOW
```

## 13.4 Custom Policy Schema

```yaml
metadata:
  id: "CKV_CUSTOM_1"           # Required, unique
  name: "Policy Name"           # Required
  category: "CATEGORY"          # Required
  severity: "HIGH"              # Required
  description: "Description"    # Optional
  framework: "terraform"        # Optional
  platform: "aws"               # Optional
  guidance_url: "https://..."   # Optional

definition:
  # Configuration-based
  cond_type: attribute
  resource_types:
    - aws_s3_bucket
  attribute: encryption
  operator: exists
  value: true

  # Or graph-based
  cond_type: attribute
  resource_types:
    - aws_vpc
    - aws_flow_log
  attribute: vpc_id
  operator: exists
```

## 13.5 Pre-Commit Config

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
        args:
          - --directory
          - .
          - --framework
          - terraform
          - --compact
          - --quiet
          - --soft-fail
          - --skip-check
          - CKV_AWS_18
```

---

# 14. Real-World Examples

## Example 1: Complete Terraform Project Scan

```bash
# Project structure
project/
  main.tf
  variables.tf
  outputs.tf
  modules/
    vpc/
    ecs/
    rds/
  environments/
    dev/
    prod/

# Scan entire project
checkov -d . --framework terraform

# Scan with external modules
checkov -d . --download-external-modules true

# Scan and generate report
checkov -d . --output json > checkov-report.json
```

## Example 2: Kubernetes Security Scan

```bash
# Scan K8s manifests
checkov -d k8s/ --framework kubernetes

# Scan Helm templates
helm template . | checkov -f - --framework kubernetes

# Generate SARIF for GitHub
checkov -d k8s/ --framework kubernetes --output sarif > k8s-scan.sarif
```

## Example 3: Docker Security Scan

```bash
# Scan Dockerfile
checkov -f Dockerfile --framework dockerfile

# Scan docker-compose
checkov -f docker-compose.yml --framework docker_compose

# Scan with specific checks
checkov -f Dockerfile --check CKV_DOCKER_1,CKV_DOCKER_2
```

## Example 4: CI/CD Pipeline with Multiple Stages

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  checkov-terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/
          framework: terraform
          output_format: sarif
          output_file_path: checkov-terraform.sarif

  checkov-k8s:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bridgecrewio/checkov-action@v12
        with:
          directory: k8s/
          framework: kubernetes
          output_format: sarif
          output_file_path: checkov-k8s.sarif

  upload-sarif:
    runs-on: ubuntu-latest
    needs: [checkov-terraform, checkov-k8s]
    steps:
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov-terraform.sarif
```

## Example 5: Custom Policy for Organization

```yaml
# custom_policies/CKV_ORG_1.yaml
metadata:
  id: "CKV_ORG_1"
  name: "Ensure all resources have required tags"
  category: "GENERAL_SECURITY"
  severity: "HIGH"
  description: "All resources must have Environment, Team, and CostCenter tags"

definition:
  and:
    - cond_type: attribute
      resource_types:
        - aws_instance
        - aws_s3_bucket
        - aws_db_instance
      attribute: tags.Environment
      operator: exists
    - cond_type: attribute
      resource_types:
        - aws_instance
        - aws_s3_bucket
        - aws_db_instance
      attribute: tags.Team
      operator: exists
    - cond_type: attribute
      resource_types:
        - aws_instance
        - aws_s3_bucket
        - aws_db_instance
      attribute: tags.CostCenter
      operator: exists
```

## Example 6: Pre-Commit with Multiple Tools

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: '3.1.0'
    hooks:
      - id: checkov
        args:
          - --framework
          - terraform
          - --compact
          - --quiet

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: tflint

  - repo: https://github.com/tenable/terrascan
    rev: v1.18.0
    hooks:
      - id: terrascan
        args:
          - --policy-type
          - aws
```

---

# 15. Further Reading

## Official Resources

- [Checkov Documentation](https://www.checkov.io/)
- [Checkov GitHub](https://github.com/bridgecrewio/checkov)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/README.html)
- [Bridgecrew Platform](https://www.bridgecrewcloud.com/)
- [Prisma Cloud](https://www.paloaltonetworks.com/prisma/cloud)

## Learning Resources

- [Checkov Getting Started](https://www.checkov.io/1.Welcome/Getting%20Started.html)
- [Custom Policies Guide](https://www.checkov.io/4.Custom%20Policies/Custom%20Policies.html)
- [Graph-Based Checks](https://www.checkov.io/4.Custom%20Policies/Graph%20Policy%20Composer.html)

## Community

- [Checkov Discussions](https://github.com/bridgecrewio/checkov/discussions)
- [Checkov Slack](https://bridgecrewio.slack.com/)
- [Bridgecrew Blog](https://www.bridgecrewcloud.com/blog/)

## Related Tools

- **tfsec**: Terraform-specific security scanner
- **Trivy**: Vulnerability and IaC scanner
- **Terrascan**: OPA-based IaC scanner
- **KICS**: Keeping Infrastructure as Code Secure
- **cfn-lint**: CloudFormation linter
- **tflint**: Terraform linter
- **Infracost**: Cost estimation for IaC
- **Prisma Cloud**: Commercial security platform

---

*This guide covers Checkov as of version 3.1.x. For the latest features, refer to the official documentation.*
