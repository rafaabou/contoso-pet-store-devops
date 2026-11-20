# tfsec Complete Guide

## Table of Contents

1. [What Is tfsec](#1-what-is-tfsec)
2. [Why Use tfsec](#2-why-use-tfsec)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide (Step-by-Step)](#6-usage-guide-step-by-step)
7. [Custom Rules](#7-custom-rules)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting (20 Issues)](#10-troubleshooting)
11. [Tips and Best Practices (20 Tips)](#11-tips-and-best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

# 1. What Is tfsec

tfsec is an open-source static analysis security scanner for Terraform code. Developed by Aqua Security, it detects security misconfigurations in Terraform configurations before they are deployed, providing actionable feedback to developers and security teams.

## 1.1 History

- **2019**: Created by LIAM GALLAGHER (then at Aqua Security) as a Terraform-specific security scanner
- **2020**: Rapid adoption, became the de facto Terraform security tool
- **2021**: tfsec 1.x with custom rules in Rego/Go
- **2022**: Enhanced custom rule support, improved accuracy
- **2023**: tfsec 2.x with improved scanning and custom rules
- **2024**: Continued maintenance, now part of Aqua Security's open-source portfolio

## 1.2 Architecture

```
┌──────────────────────────────────────────────┐
│                tfsec                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Parser  │  │  Rule    │  │  Output   │  │
│  │  Engine  │  │  Engine  │  │  Formatter│  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       │              │              │          │
│  ┌────┴──────────────┴──────────────┴──────┐  │
│  │     Built-in Rules (AWS, Azure, GCP)    │  │
│  │   (CIS, PCI-DSS, HIPAA, SOC2)          │  │
│  └─────────────────────────────────────────┘  │
│                                                │
│  ┌─────────────────────────────────────────┐  │
│  │        Custom Rules (Go/Rego)           │  │
│  └─────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

## 1.3 Key Features

- **Terraform-Only Focus**: Deep understanding of Terraform HCL and providers
- **1,000+ Built-in Rules**:覆盖 AWS, Azure, GCP, Alibaba Cloud
- **Compliance Checks**: CIS, PCI-DSS, HIPAA, SOC2, NIST
- **Custom Rules**: Write rules in Go or Rego (OPA)
- **Severity Levels**: CRITICAL, HIGH, MEDIUM, LOW, WARNING
- **CI/CD Integration**: GitHub Actions, GitLab CI, Jenkins, etc.
- **Multiple Output Formats**: CLI, JSON, SARIF, JUnit XML
- **Baseline Support**: Ignore known issues
- **Exclude by Path/Code**: Fine-grained exclusion
- **Module Scanning**: Scan downloaded Terraform modules

## 1.4 tfsec vs. Other Tools

| Feature | tfsec | Checkov | Terrascan | Trivy |
|---------|-------|---------|-----------|-------|
| Terraform Focus | ✅ | ✅ | ✅ | ✅ |
| Multi-Framework | ❌ | ✅ | ✅ | ✅ |
| Custom Rules | Go/Rego | Python/YAML | Rego | Go |
| Built-in Rules | 1,000+ | 1,000+ | 500+ | 100+ |
| Speed | Fast | Medium | Medium | Fast |
| Module Support | ✅ | ✅ | ✅ | ✅ |
| License | MIT | Apache 2.0 | Apache 2.0 | Apache 2.0 |

---

# 2. Why Use tfsec

## 2.1 The Problem tfsec Solves

Terraform makes it easy to provision infrastructure, but security misconfigurations are common:

- **Public S3 buckets** exposing sensitive data
- **Unencrypted EBS volumes** violating compliance
- **Open security groups** allowing unrestricted access
- **Missing CloudTrail logging** creating blind spots
- **Overly permissive IAM policies** granting excessive access
- **Hardcoded secrets** in configuration files
- **Missing encryption** on databases and storage
- **Public RDS instances** exposed to the internet

These misconfigurations are:
- **Hard to catch** in code review
- **Expensive to fix** after deployment
- **Compliance violations** with regulatory requirements
- **Security risks** leading to data breaches

## 2.2 Benefits

| Benefit | Description |
|---------|-------------|
| **Shift-Left Security** | Catch issues before deployment |
| **Terraform-Deep** | Understands HCL syntax and provider semantics |
| **Fast Scanning** | Scan in seconds, not minutes |
| **Low False Positives** | High-quality, focused rules |
| **Custom Rules** | Organization-specific security policies |
| **CI/CD Native** | Easy integration into pipelines |
| **Free & Open Source** | No licensing costs |
| **Active Community** | Regular updates and new rules |

## 2.3 When to Use tfsec

**Good fit:**
- Pre-commit hooks for immediate feedback
- CI/CD pipeline gates for Terraform
- Security audits of Terraform codebases
- Compliance checking (CIS, PCI-DSS, HIPAA)
- Ongoing security monitoring

**Not ideal for:**
- Non-Terraform IaC (use Checkov or Terrascan)
- CloudFormation (use cfn-lint or Checkov)
- Kubernetes (use Checkov or Trivy)
- Docker (use Trivy or Checkov)

---

# 3. Installation

## 3.1 Prerequisites

- **Terraform**: Not required for scanning (tfsec parses files directly)
- **Go**: 1.18+ (for building from source)

## 3.2 Install via Go

```bash
# Install directly
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Verify
tfsec --version
```

## 3.3 Install via Binary

```bash
# Linux (amd64)
curl -sL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec_linux_amd64.tar.gz | tar xz
sudo mv tfsec /usr/local/bin/

# Linux (arm64)
curl -sL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec_linux_arm64.tar.gz | tar xz
sudo mv tfsec /usr/local/bin/

# macOS (amd64)
curl -sL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec_darwin_amd64.tar.gz | tar xz
sudo mv tfsec /usr/local/bin/

# macOS (arm64 - M1/M2)
curl -sL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec_darwin_arm64.tar.gz | tar xz
sudo mv tfsec /usr/local/bin/
```

## 3.4 Install via Package Manager

```bash
# Homebrew (macOS)
brew install tfsec

# Chocolatey (Windows)
choco install tfsec

# Snap
sudo snap install tfsec
```

## 3.5 Install via Docker

```bash
# Pull image
docker pull aquasec/tfsec

# Scan current directory
docker run --rm -v "$(pwd):/src" aquasec/tfsec /src
```

## 3.6 Verify Installation

```bash
tfsec --version
# v1.28.x

# Quick test
tfsec --help
```

---

# 4. Configuration

## 4.1 Configuration File

tfsec uses a `.tfsec.yml` file in the project root:

```yaml
# .tfsec.yml

# Minimum severity to report
minimum_severity: MEDIUM

# Exclude specific checks
exclude:
  - aws-s3-enable-bucket-logging
  - aws-vpc-no-public-ingress-sg

# Exclude by path
exclude-downloaded-modules: true

# Custom rules directory
custom_check_dir: .tfsec/

# Output format
format: default

# Strict mode (fail on any issue)
strict: true

# Include downloaded modules
include-downloaded-modules: true

# Costs estimation
calculate-costs: true
```

## 4.2 Command Line Flags

```bash
# Skip specific checks
tfsec --exclude aws-s3-enable-bucket-logging,aws-s3-enable-versioning

# Minimum severity
tfsec --minimum-severity HIGH

# Exclude downloaded modules
tfsec --exclude-downloaded-modules

# Include specific paths
tfsec --include-path modules/

# Custom rules directory
tfsec --custom-check-dir .tfsec/

# Output format
tfsec --format json
```

## 4.3 Excluding Checks

```yaml
# .tfsec.yml
exclude:
  - aws-s3-enable-bucket-logging
  - aws-s3-enable-versioning
  - aws-vpc-no-public-ingress-sg
```

Or inline in Terraform:

```hcl
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

## 4.4 Custom Rules Directory

```
project/
  .tfsec/
    custom_rules/
      check_required_tags.go
  main.tf
  variables.tf
```

---

# 5. Core Concepts

## 5.1 Rule IDs

tfsec rules follow a naming convention:

| Pattern | Description |
|---------|-------------|
| `aws-*` | AWS rules |
| `azure-*` | Azure rules |
| `gcp-*` | GCP rules |
| `alicloud-*` | Alibaba Cloud rules |

Examples:
- `aws-s3-enable-bucket-logging`: S3 bucket logging
- `aws-vpc-no-public-ingress-sg`: No public ingress
- `aws-rds-enable encryption`: RDS encryption

## 5.2 Severities

| Level | Description |
|-------|-------------|
| CRITICAL | Critical security risk |
| HIGH | High security risk |
| MEDIUM | Medium security risk |
| LOW | Low security risk |
| WARNING | Informational |

## 5.3 Rule Attributes

Each rule has:
- **ID**: Unique identifier
- **ShortCode**: Short identifier
- **Summary**: Brief description
- **Severity**: Risk level
- **Provider**: Cloud provider
- **Service**: AWS/Azure/GCP service
- **Impact**: Security impact
- **Resolution**: How to fix
- **Links**: Documentation
- **扫描类型**: Attribute check, block check, etc.

## 5.4 Check Types

### Attribute Check
Validate resource attributes:
```go
func checkAttributes(block hcl.Attributes) {
    // Check if encryption is enabled
}
```

### Block Check
Validate resource blocks:
```go
func checkBlock(block hcl.Block) {
    // Check block structure
}
```

### Resource Type Check
Validate entire resource:
```go
func checkResource(resourceType string, resource hcl.Body) {
    // Check resource
}
```

## 5.5 Baseline

Track only new violations:

```bash
# Generate baseline
tfsec --format json > baseline.json

# Use baseline (only report new issues)
tfsec --baseline baseline.json
```

## 5.6 Module Scanning

```bash
# Scan downloaded modules
tfsec --include-downloaded-modules

# Exclude downloaded modules
tfsec --exclude-downloaded-modules
```

## 5.7 Cost Estimation

```bash
# Show cost impact
tfsec --calculate-costs

# Output with costs
tfsec --format json --calculate-costs
```

---

# 6. Usage Guide (Step-by-Step)

## 6.1 Step 1: Scan Current Directory

```bash
# Basic scan
tfsec .

# Scan with verbose output
tfsec . -v
```

## 6.2 Step 2: Scan Specific Directory

```bash
# Scan specific path
tfsec ./modules/infrastructure

# Scan multiple paths
tfsec ./modules/vpc ./modules/ecs
```

## 6.3 Step 3: Filter by Severity

```bash
# Only high/critical
tfsec . --minimum-severity HIGH

# Only critical
tfsec . --minimum-severity CRITICAL
```

## 6.4 Step 4: Exclude Checks

```bash
# Exclude specific checks
tfsec --exclude aws-s3-enable-bucket-logging,aws-s3-enable-versioning

# Exclude by path
tfsec --include-path modules/vpc
```

## 6.5 Step 5: Output Formats

```bash
# Default CLI output
tfsec .

# JSON output
tfsec . --format json > results.json

# SARIF output
tfsec . --format sarif > results.sarif

# JUnit XML
tfsec . --format junit > results.xml

# CSV output
tfsec . --format csv > results.csv
```

## 6.6 Step 6: Use in CI/CD

```yaml
# .github/workflows/tfsec.yml
name: tfsec

on: [push, pull_request]

jobs:
  tfsec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: .
          soft_fail: false

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: tfsec-results.sarif
```

## 6.7 Step 7: Use Inline Exclusions

```hcl
# Ignore specific resource
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "logs" {
  bucket = "logs-bucket"
}

# Ignore in block
resource "aws_s3_bucket" "data" {
  bucket = "data-bucket"

  # tfsec:ignore:aws-s3-enable-versioning
  versioning {
    enabled = false
  }
}
```

## 6.8 Step 8: Generate Baseline

```bash
# Generate baseline for existing code
tfsec --format json > baseline.json

# Use in subsequent scans
tfsec . --baseline baseline.json
```

## 6.9 Step 9: Review Results

```bash
# View all failures
tfsec . --format json | jq '.results[].description'

# Group by severity
tfsec . --format json | jq '[.results[] | {severity, description}] | group_by(.severity)'

# Count by rule
tfsec . --format json | jq '[.results[].ruleID] | group_by(.) | map({rule: .[0], count: length})'
```

## 6.10 Step 10: Fix Issues

```bash
# View resolution for each issue
tfsec . | grep -A 5 "Resolution:"

# Auto-fix suggestions
tfsec . --format json | jq '.results[] | {id, resolution}'
```

---

# 7. Custom Rules

## 7.1 Custom Rule Structure

```go
// .tfsec/custom_rules/check_required_tags.go
package custom_rules

import (
    "github.com/aquasecurity/tfsec/pkg/rule"
    "github.com/aquasecurity/tfsec/pkg/provider"
    "github.com/aquasecurity/tfsec/pkg/severity"
    "github.com/aquasecurity/tfsec/pkg/check"
    "github.com/hashicorp/hcl/v2"
)

func init() {
    rule.Register(&check.Check{
        RuleID:   "custom-aws-required-tags",
        Provider: provider.AWSProvider,
        Severity: severity.High,
        Service:  "general",
        ShortCode: "required-tags",
        Summary:  "Ensure all resources have required tags",
        Impact:   "Missing tags make resource management difficult",
        Resolution: "Add Environment, Team, and CostCenter tags",
        Links: []string{
            "https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html",
        },
    })
}
```

## 7.2 Custom Rule Implementation

```go
// .tfsec/custom_rules/check_required_tags.go
package custom_rules

import (
    "github.com/aquasecurity/tfsec/pkg/rule"
    "github.com/aquasecurity/tfsec/pkg/provider"
    "github.com/aquasecurity/tfsec/pkg/severity"
    "github.com/aquasecurity/tfsec/pkg/check"
    "github.com/hashicorp/hcl/v2"
    "github.com/zclconf/go-cty/cty"
)

func init() {
    rule.Register(&check.Check{
        RuleID:   "custom-aws-required-tags",
        Provider: provider.AWSProvider,
        Severity: severity.High,
        Service:  "general",
        ShortCode: "required-tags",
        Summary:  "Ensure all resources have required tags",
        Impact:   "Missing tags make resource management difficult",
        Resolution: "Add Environment, Team, and CostCenter tags",
        Links: []string{
            "https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html",
        },
    })
}

func (c *RequiredTagsCheck) Run(block *hcl.Block, _ interface{}) ([]check.Result, error) {
    var results []check.Result

    tags := block.GetAttribute("tags")
    if tags == nil {
        results = append(results, check.Result{
            Severity: severity.High,
            Summary:  "Missing required tags",
            Details:  "Resource does not have a 'tags' attribute",
        })
        return results, nil
    }

    requiredTags := []string{"Environment", "Team", "CostCenter"}
    for _, tag := range requiredTags {
        if tags.GetAttribute(tag) == nil {
            results = append(results, check.Result{
                Severity: severity.High,
                Summary:  "Missing required tag: " + tag,
                Details:  "Resource is missing tag '" + tag + "'",
            })
        }
    }

    return results, nil
}
```

## 7.3 Rego-Based Custom Rules

```rego
# .tfsec/custom_rules/required_tags.rego
package custom.aws.required_tags

__rego_metadoc__ := {
    "id": "custom-aws-required-tags",
    "title": "Ensure required tags",
    "severity": "High",
    "description": "All resources must have Environment, Team, and CostCenter tags",
    "impact": "Missing tags make resource management difficult",
    "resolution": "Add required tags to all resources",
}

resource_type := "aws_instance"

deny[msg] {
    resource := input.aws_instance[name]
    not resource.tags.Environment
    msg := sprintf("Instance '%s' is missing Environment tag", [name])
}

deny[msg] {
    resource := input.aws_instance[name]
    not resource.tags.Team
    msg := sprintf("Instance '%s' is missing Team tag", [name])
}

deny[msg] {
    resource := input.aws_instance[name]
    not resource.tags.CostCenter
    msg := sprintf("Instance '%s' is missing CostCenter tag", [name])
}
```

## 7.4 Testing Custom Rules

```go
// .tfsec/custom_rules/check_required_tags_test.go
package custom_rules

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/hashicorp/hcl/v2"
)

func TestRequiredTagsCheck(t *testing.T) {
    tests := []struct {
        name     string
        config   string
        expected int // number of failures
    }{
        {
            name: "all tags present",
            config: `
                resource "aws_instance" "example" {
                    tags = {
                        Environment = "dev"
                        Team        = "platform"
                        CostCenter  = "cc-123"
                    }
                }
            `,
            expected: 0,
        },
        {
            name: "missing tags",
            config: `
                resource "aws_instance" "example" {
                    tags = {
                        Name = "example"
                    }
                }
            `,
            expected: 3,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

## 7.5 Using Custom Rules

```bash
# Run with custom rules
tfsec . --custom-check-dir .tfsec/

# Or specify custom rules directory in config
# .tfsec.yml
custom_check_dir: .tfsec/
```

---

# 8. Integration

## 8.1 GitHub Actions

```yaml
# .github/workflows/tfsec.yml
name: tfsec

on: [push, pull_request]

jobs:
  tfsec:
    name: tfsec security scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: .
          soft_fail: false
          format: sarif
          outputFile: tfsec-results.sarif

      - name: Upload SARIF to GitHub
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: tfsec-results.sarif
```

## 8.2 GitLab CI

```yaml
# .gitlab-ci.yml
tfsec:
  image:
    name: aquasec/tfsec
    entrypoint: [""]
  script:
    - tfsec . --format json > tfsec-results.json
    - |
      if [ -s tfsec-results.json ]; then
        echo "Security issues found"
        cat tfsec-results.json
        exit 1
      fi
  artifacts:
    reports:
      sast: tfsec-results.json
```

## 8.3 Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Security Scan') {
            steps {
                sh 'tfsec . --format junit --output-file tfsec-results.xml'
                junit 'tfsec-results.xml'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'tfsec-results.*'
                }
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
      docker run --rm -v $(Build.SourcesDirectory):/src aquasec/tfsec /src \
        --format junit \
        --output-file /src/tfsec-results.xml
    displayName: 'Run tfsec'

  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'tfsec-results.xml'
```

## 8.5 Pre-Commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/tfsec
    rev: v1.28.0
    hooks:
      - id: tfsec
        args:
          - --minimum-severity
          - MEDIUM
```

## 8.6 Terragrunt Integration

```hcl
# terragrunt.hcl
terraform {
  before_hook "tfsec" {
    commands = ["apply", "plan"]
    execute = ["tfsec", ".", "--minimum-severity", "HIGH"]
  }
}
```

## 8.7 IDE Integration

### VS Code
```
Install "tfsec" extension from marketplace
```

### IntelliJ
```
Install "tfsec" plugin from JetBrains Marketplace
```

---

# 9. Security

## 9.1 CIS Benchmarks

```bash
# Run CIS AWS Foundations Benchmark
tfsec . --include-aws-cis-1.2

# Run CIS specific rules
tfsec . --exclude-all --include-aws-cis-1.2
```

## 9.2 PCI-DSS Compliance

```bash
# Run PCI-DSS rules
tfsec . --include-aws-pci-dss-3.2.1
```

## 9.3 HIPAA Compliance

```bash
# Run HIPAA rules
tfsec . --include-aws-hipaa
```

## 9.4 NIST Compliance

```bash
# Run NIST rules
tfsec . --include-aws-nist
```

## 9.5 SOC2 Compliance

```bash
# Run SOC2 rules
tfsec . --include-aws-soc2
```

## 9.6 Secret Detection

```bash
# tfsec detects hardcoded secrets
tfsec . | grep -i secret

# Custom secret detection
tfsec --custom-check-dir .tfsec/secrets/
```

## 9.7 Network Security

```bash
# Check for public access
tfsec . | grep -i "public"

# Check for unrestricted ingress
tfsec . | grep -i "ingress"
```

## 9.8 Encryption Checks

```bash
# Check for encryption
tfsec . | grep -i "encrypt"

# Check for missing encryption
tfsec . | grep -i "no encryption"
```

---

# 10. Troubleshooting

## Issue 1: "No files found to scan"

```
No HCL files found to scan in '.'
```

**Cause**: No `.tf` files in directory or wrong path.

**Fix**:
```bash
# Check directory
ls -la *.tf

# Scan specific path
tfsec /path/to/terraform

# Check for hidden files
find . -name "*.tf" -type f
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

# Then run tfsec
tfsec .
```

## Issue 3: "Module not found"

```
Failed to load module: module not found
```

**Cause**: tfsec can't find referenced modules.

**Fix**:
```bash
# Download modules first
terraform init

# Or exclude modules
tfsec --exclude-downloaded-modules
```

## Issue 4: "Provider not found"

```
Unknown provider: aws
```

**Cause**: Provider block missing or unrecognized.

**Fix**:
```hcl
# Ensure provider is declared
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Issue 5: "Custom rule not loading"

Custom rules not appearing in results.

**Fix**:
```bash
# Check custom rules directory
ls -la .tfsec/

# Verify rule syntax
go build .tfsec/custom_rules/

# Run with verbose
tfsec -v .
```

## Issue 6: "Exclude not working"

Excluded checks still appearing.

**Fix**:
```yaml
# Use exact check ID in .tfsec.yml
exclude:
  - aws-s3-enable-bucket-logging

# Or use inline exclusion
# tfsec:ignore:aws-s3-enable-bucket-logging
```

## Issue 7: "Performance issues"

Scan takes too long on large codebase.

**Fix**:
```bash
# Scan specific directory
tfsec ./modules/important

# Exclude downloaded modules
tfsec --exclude-downloaded-modules

# Use parallel scanning
tfsec . --parallel 4
```

## Issue 8: "False positives"

tfsec flags correctly configured resources.

**Fix**:
```bash
# Skip false positive
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "example" {
  # ...
}

# Or in config
exclude:
  - aws-s3-enable-bucket-logging
```

## Issue 9: "Version conflict"

tfsec version incompatible with Terraform.

**Fix**:
```bash
# Update tfsec
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Check version
tfsec --version
```

## Issue 10: "Memory issues"

Out of memory during scan.

**Fix**:
```bash
# Scan specific directory
tfsec ./modules/

# Exclude modules
tfsec --exclude-downloaded-modules

# Increase Go memory
GOGC=100 tfsec .
```

## Issue 11: "Exit code issues"

tfsec always returns 0.

**Fix**:
```bash
# Use strict mode
tfsec --strict

# Or check JSON output
tfsec --format json | jq '.results | length'
```

## Issue 12: "SARIF output not recognized"

SARIF file not accepted by GitHub.

**Fix**:
```bash
# Generate valid SARIF
tfsec --format sarif > results.sarif

# Validate SARIF
python -c "import json; json.load(open('results.sarif'))"
```

## Issue 13: "Baseline not working"

Baseline file not filtering old issues.

**Fix**:
```bash
# Regenerate baseline
tfsec --format json > baseline.json

# Verify baseline
cat baseline.json | jq '.results | length'

# Use baseline
tfsec --baseline baseline.json
```

## Issue 14: "Cost estimation errors"

Cost calculation failing.

**Fix**:
```bash
# Disable cost estimation
tfsec --no-costs

# Or skip specific checks
tfsec --exclude aws-s3-bucket-expensive
```

## Issue 15: "Terraform 1.5+ compatibility"

tfsec not parsing newer Terraform syntax.

**Fix**:
```bash
# Update tfsec to latest
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Check for HCL2 syntax issues
terraform fmt -check
```

## Issue 16: "Variable resolution fails"

tfsec can't resolve variable values.

**Fix**:
```hcl
# Use default values
variable "environment" {
  default = "dev"
}

# Or pass values
tfsec . --var environment=prod
```

## Issue 17: "Local values not resolved"

Local values not evaluated correctly.

**Fix**:
```hcl
# Ensure locals are defined
locals {
  environment = "dev"
  tags = {
    Environment = local.environment
  }
}
```

## Issue 18: "Dynamic blocks not scanned"

Dynamic blocks not evaluated.

**Fix**:
```bash
# tfsec doesn't support dynamic blocks
# Use static blocks or custom rules

# Or rewrite as static
resource "aws_security_group" "example" {
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

## Issue 19: "Count/for_each issues"

tfsec can't evaluate count or for_each.

**Fix**:
```hcl
# Use static values for tfsec
resource "aws_instance" "example" {
  count = 2  # tfsec evaluates this as literal "2"
  # ...
}
```

## Issue 20: "No rules found"

```
No rules to check
```

**Cause**: All rules excluded or wrong provider.

**Fix**:
```bash
# Check excluded rules
cat .tfsec.yml | grep exclude

# Run with all rules
tfsec . --exclude-all

# Check provider
tfsec . | head -20
```

---

# 11. Tips and Best Practices

## Tip 1: Use Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/tfsec
    rev: v1.28.0
    hooks:
      - id: tfsec
        args:
          - --minimum-severity
          - MEDIUM
```

## Tip 2: Use Inline Exclusions

```hcl
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "logs" {
  bucket = "logs-bucket"
}
```

## Tip 3: Use Severity Filtering

```bash
# Only critical/high
tfsec --minimum-severity HIGH

# Or in config
minimum_severity: HIGH
```

## Tip 4: Use Baselines for Existing Code

```bash
# Generate baseline
tfsec --format json > baseline.json

# Use in CI/CD
tfsec --baseline baseline.json
```

## Tip 5: Use Custom Rules for Organization Policies

```go
// Write rules for your specific requirements
func init() {
    rule.Register(&check.Check{
        RuleID:   "custom-aws-required-tags",
        Severity: severity.High,
        Summary:  "Ensure all resources have required tags",
    })
}
```

## Tip 6: Use Multiple Output Formats

```bash
# CLI for developers
tfsec .

# JSON for processing
tfsec --format json > results.json

# SARIF for GitHub
tfsec --format sarif > results.sarif
```

## Tip 7: Use Hard Fail in CI/CD

```bash
# Fail on any issue
tfsec --strict

# Fail on specific severity
tfsec --hard-fail-on HIGH
```

## Tip 8: Use tfsec with Terraform Cloud

```hcl
# Add as run task
# In workspace settings
# Add webhook for tfsec
```

## Tip 9: Use for Cost Optimization

```bash
# Show cost impact
tfsec --calculate-costs

# Find expensive resources
tfsec --format json | jq '.results[] | select(.cost > 100)'
```

## Tip 10: Use for Compliance Auditing

```bash
# Run specific compliance checks
tfsec --include-aws-cis-1.2
tfsec --include-aws-pci-dss-3.2.1
```

## Tip 11: Use tfsec in IDE

Install VS Code or IntelliJ plugin for immediate feedback.

## Tip 12: Use for Code Review

```bash
# Generate report for PR
tfsec --format json > tfsec-report.json

# Post to PR
# See CI/CD integration examples
```

## Tip 13: Use for Security Audits

```bash
# Generate comprehensive report
tfsec --format json --calculate-costs > audit-report.json

# Include all severities
tfsec --minimum-severity LOW
```

## Tip 14: Use with Other Tools

```yaml
# Combine with other tools
repos:
  - repo: https://github.com/aquasecurity/tfsec
    rev: v1.28.0
    hooks:
      - id: tfsec
  - repo: https://github.com/terraform-linters/tflint
    rev: v0.48.0
    hooks:
      - id: tflint
```

## Tip 15: Use for Incident Response

```bash
# Quick scan after incident
tfsec . --format json > post-incident-scan.json

# Check for specific issues
tfsec . | grep -i "security"
```

## Tip 16: Use for Training

```bash
# Use tfsec to learn Terraform security
tfsec . --format json | jq '.results[] | {rule, description, resolution}'
```

## Tip 17: Use for Documentation

```bash
# Generate security documentation
tfsec --format json | jq '.results[] | {rule: .ruleID, description: .description, resolution: .resolution}'
```

## Tip 18: Use for Metrics

```bash
# Count issues by severity
tfsec --format json | jq '[.results[] | .severity] | group_by(.) | map({severity: .[0], count: length})'

# Count by rule
tfsec --format json | jq '[.results[].ruleID] | group_by(.) | map({rule: .[0], count: length})'
```

## Tip 19: Use for Debugging

```bash
# Verbose output
tfsec -v .

# Show all rules
tfsec --list-rules

# Check specific rule
tfsec --include-rule aws-s3-enable-bucket-logging
```

## Tip 20: Keep tfsec Updated

```bash
# Update regularly
go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Check for new rules
tfsec --list-rules | wc -l
```

---

# 12. Command Reference

## tfsec

Main command.

```bash
tfsec [OPTIONS] [PATH]

# Options:
--format FORMAT           # Output format (default, json, sarif, junit, csv)
--output-file FILE        # Output file
--minimum-severity LEVEL  # Minimum severity level
--exclude CHECK           # Exclude specific check
--exclude-all             # Exclude all checks
--include-rule RULE       # Include specific rule
--include-path PATH       # Include specific path
--exclude-downloaded-modules  # Exclude downloaded modules
--include-downloaded-modules  # Include downloaded modules
--custom-check-dir DIR    # Custom rules directory
--soft-fail               # Exit 0 even with failures
--strict                  # Exit 1 on any issue
--calculate-costs         # Show cost estimation
--no-costs                # Disable cost estimation
--list-rules              # List all rules
-v, --verbose             # Verbose output
--version                 # Show version
-h, --help                # Show help
```

## tfsec --list-rules

List all available rules.

```bash
tfsec --list-rules
tfsec --list-rules | grep aws
```

## tfsec --format

Output formats.

```bash
--format default          # CLI output (default)
--format json             # JSON output
--format sarif            # SARIF format
--format junit            # JUnit XML
--format csv              # CSV output
```

## tfsec --exclude

Exclude specific checks.

```bash
--exclude aws-s3-enable-bucket-logging
--exclude aws-s3-enable-versioning,aws-vpc-no-public-ingress-sg
```

## tfsec --minimum-severity

Filter by severity.

```bash
--minimum-severity CRITICAL
--minimum-severity HIGH
--minimum-severity MEDIUM
--minimum-severity LOW
```

## tfsec --include-aws-cis-1.2

Include CIS benchmark rules.

```bash
tfsec --include-aws-cis-1.2
tfsec --include-aws-pci-dss-3.2.1
tfsec --include-aws-hipaa
tfsec --include-aws-soc2
tfsec --include-aws-nist
```

---

# 13. Configuration Reference

## 13.1 .tfsec.yml

```yaml
# Minimum severity to report
minimum_severity: MEDIUM

# Exclude specific checks
exclude:
  - aws-s3-enable-bucket-logging
  - aws-s3-enable-versioning
  - aws-vpc-no-public-ingress-sg

# Exclude by path
exclude-downloaded-modules: true

# Include downloaded modules
include-downloaded-modules: false

# Custom rules directory
custom_check_dir: .tfsec/

# Output format
format: default

# Strict mode
strict: true

# Cost estimation
calculate-costs: true

# Include specific rules
include:
  - aws-s3-enable-bucket-logging
  - aws-rds-enable-encryption

# Exclude all then include specific
exclude-all: false
```

## 13.2 Rule Schema

```go
type Rule struct {
    RuleID      string
    Provider    provider.Provider
    Severity    severity.Severity
    Service     string
    ShortCode   string
    Summary     string
    Impact      string
    Resolution  string
    Links       []string
}
```

## 13.3 Severity Levels

```go
type Severity string

const (
    Critical Severity = "Critical"
    High     Severity = "High"
    Medium   Severity = "Medium"
    Low      Severity = "Low"
    Warning  Severity = "Warning"
)
```

## 13.4 Check Result

```go
type Result struct {
    RuleID      string
    Severity    severity.Severity
    Status      Status
    Summary     string
    Details     string
    Range       hcl.Range
    Resource    string
    Cost        int
}
```

## 13.5 Provider Mapping

| Provider | Prefix |
|----------|--------|
| AWS | `aws-` |
| Azure | `azure-` |
| GCP | `gcp-` |
| Alibaba Cloud | `alicloud-` |

## 13.6 Service Categories

| Service | Examples |
|---------|----------|
| S3 | `aws-s3-*` |
| EC2 | `aws-ec2-*` |
| RDS | `aws-rds-*` |
| VPC | `aws-vpc-*` |
| IAM | `aws-iam-*` |
| CloudWatch | `aws-cloudwatch-*` |
| KMS | `aws-kms-*` |
| Lambda | `aws-lambda-*` |

---

# 14. Real-World Examples

## Example 1: Scan Complete Terraform Project

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

# Scan all
tfsec .

# Scan with module support
tfsec . --include-downloaded-modules

# Generate report
tfsec . --format json > tfsec-report.json
```

## Example 2: CI/CD Pipeline

```yaml
# .github/workflows/terraform-security.yml
name: Terraform Security

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.0"

      - name: Terraform Init
        run: terraform init

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          soft_fail: false

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: tfsec-results.sarif
```

## Example 3: Custom Policy for Organization

```go
// .tfsec/custom_rules/check_required_tags.go
package custom_rules

import (
    "github.com/aquasecurity/tfsec/pkg/rule"
    "github.com/aquasecurity/tfsec/pkg/provider"
    "github.com/aquasecurity/tfsec/pkg/severity"
    "github.com/aquasecurity/tfsec/pkg/check"
)

func init() {
    rule.Register(&check.Check{
        RuleID:   "custom-aws-required-tags",
        Provider: provider.AWSProvider,
        Severity: severity.High,
        Service:  "general",
        ShortCode: "required-tags",
        Summary:  "Ensure all resources have required tags",
        Impact:   "Missing tags make resource management difficult",
        Resolution: "Add Environment, Team, and CostCenter tags",
    })
}
```

## Example 4: Pre-Commit with Multiple Tools

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/aquasecurity/tfsec
    rev: v1.28.0
    hooks:
      - id: tfsec
        args:
          - --minimum-severity
          - MEDIUM

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

## Example 5: Multi-Cloud Security

```bash
# Scan AWS
tfsec ./aws/ --include-aws-cis-1.2

# Scan Azure
tfsec ./azure/ --include-azure-cis-1.4

# Scan GCP
tfsec ./gcp/ --include-gcp-cis-1.1
```

## Example 6: Cost-Optimized Security

```bash
# Scan with cost estimation
tfsec . --calculate-costs

# Find expensive security issues
tfsec . --format json | jq '.results[] | select(.cost > 100)'
```

---

# 15. Further Reading

## Official Resources

- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [tfsec GitHub](https://github.com/aquasecurity/tfsec)
- [Custom Rules Guide](https://aquasecurity.github.io/tfsec/latest/custom/)
- [Aqua Security](https://www.aquasec.com/)

## Learning Resources

- [tfsec Getting Started](https://aquasecurity.github.io/tfsec/latest/getting-started/)
- [Custom Rules Tutorial](https://aquasecurity.github.io/tfsec/latest/custom/writing/)
- [Terraform Security Best Practices](https://www.hashicorp.com/blog/terraform-security-best-practices)

## Community

- [tfsec GitHub Discussions](https://github.com/aquasecurity/tfsec/discussions)
- [Aqua Security Blog](https://blog.aquasec.com/)
- [Terraform Security Forum](https://discuss.hashicorp.com/c/terraform/)

## Related Tools

- **Trivy**: Vulnerability and IaC scanner
- **Checkov**: Multi-framework IaC scanner
- **Terrascan**: OPA-based IaC scanner
- **KICS**: Keeping Infrastructure as Code Secure
- **tflint**: Terraform linter
- **Terraform fmt**: Terraform formatter
- **Infracost**: Cost estimation for Terraform

---

*This guide covers tfsec as of version 1.28.x. For the latest features, refer to the official documentation.*
