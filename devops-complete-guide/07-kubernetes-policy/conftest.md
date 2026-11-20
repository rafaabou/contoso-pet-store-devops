# Conftest Complete Guide

## Table of Contents

1. [What Is Conftest](#what-is-conftest)
2. [Why Use Conftest](#why-use-conftest)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Core Concepts](#core-concepts)
6. [Usage Guide](#usage-guide)
7. [Custom Policies](#custom-policies)
8. [Integration](#integration)
9. [Security](#security)
10. [Troubleshooting](#troubleshooting)
11. [Tips and Best Practices](#tips-and-best-practices)
12. [Command Reference](#command-reference)
13. [CRD Reference](#crd-reference)
14. [Real-World Examples](#real-world-examples)
15. [Further Reading](#further-reading)

---

## What Is Conftest

Conftest is a tool for testing configuration files using Open Policy Agent (OPA). It allows you to write policies in Rego and apply them to various configuration formats (YAML, JSON, TOML, INI, etc.) to validate that configurations meet your requirements.

### Key Features

- **Multi-format support**: YAML, JSON, TOML, INI, HCL, Dockerfile, Kubernetes manifests
- **OPA/Rego policies**: Write policies using OPA's powerful policy language
- **CI/CD integration**: Easy to integrate into pipelines
- **Multiple output formats**: Table, JSON, TAP, JUnit
- **Bundle support**: Package policies for distribution
- **Template support**: Generate policies from templates

### How It Works

```
Configuration File --> [Conftest] --> [OPA/Rego Engine] --> Results
        |                                    |
        v                                    v
  Parse Config                    Evaluate Policies
        |                                    |
        v                                    v
  Extract Data                     Return Violations
```

### Comparison with Other Tools

| Feature | Conftest | OPA Gatekeeper | Kyverno |
|---------|----------|----------------|---------|
| Purpose | CI/CD validation | Admission control | Admission control |
| Execution | CLI/CI | Kubernetes | Kubernetes |
| Policies | Rego | Rego | YAML/JSON |
| Formats | Multiple | Kubernetes only | Kubernetes only |
| Learning Curve | Moderate | Steep | Low |

---

## Why Use Conftest

### Shift-Left Security

- Test configurations before deployment
- Catch policy violations early in development
- Integrate into CI/CD pipelines
- Reduce deployment failures

### Compliance as Code

- Encode compliance requirements as policies
- Automate compliance checks
- Maintain audit trail
- Version control policies

### Multi-Environment Support

- Test configurations for different environments
- Validate Kubernetes manifests, Terraform, Docker Compose
- Check Helm charts
- Validate Ansible playbooks

### Advantages

1. **Early detection**: Catch issues before deployment
2. **Automated validation**: No manual review needed
3. **Consistent enforcement**: Same policies across environments
4. **Version control**: Track policy changes
5. **Reusable policies**: Share policies across teams

---

## Installation

### Method 1: Binary Download

```bash
# Linux amd64
curl -L -o conftest https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_Linux_x86_64.tar.gz
tar -xzf conftest.tar.gz
sudo mv conftest /usr/local/bin/

# macOS
brew install conftest

# Windows
choco install conftest
```

### Method 2: Go Install

```bash
go install github.com/open-policy-agent/conftest@v0.46.0
```

### Method 3: Docker

```bash
docker run --rm -v $(pwd):/workspace openpolicyagent/conftest test /workspace
```

### Method 4: From Source

```bash
git clone https://github.com/open-policy-agent/conftest.git
cd conftest
make build
sudo mv conftest /usr/local/bin/
```

### Verification

```bash
conftest --version
# Expected output: conftest version 0.46.0

# Test installation
echo "test: true" > test.yaml
cat <<EOF > policy.rego
package main

violation[{"msg": msg}] {
  input.test != true
  msg := "test must be true"
}
EOF
conftest test test.yaml -p policy.rego
```

---

## Configuration

### Policy Directory Structure

```
policy/
├── main.rego
├── kubernetes/
│   ├── deployment.rego
│   ├── service.rego
│   └── pod.rego
├── terraform/
│   ├── aws.rego
│   └── gcp.rego
└── docker/
    └── dockerfile.rego
```

### conftest.toml Configuration

```toml
[global]
# Default policy directory
policy = "policy"

# Output format
output = "json"

# All namespaces (for Kubernetes)
all-namespaces = true

[policy.missing-key]
# How to handle missing keys
# "info", "warning", "error"
default = "warning"

[policy.schema]
# Enable schema validation
enabled = true
path = "schemas"

[policy.libraries]
# External libraries
paths = ["lib", "vendor"]
```

### Environment Variables

```bash
# Policy directory
export CONTEST_POLICY="policy"

# Output format
export CONTEST_OUTPUT="json"

# Log level
export CONTEST_LOG="debug"

# Rego base URL
export CONTEST_REGO_BASE_URL="https://example.com/policies"
```

### Makefile Integration

```makefile
# Makefile
.PHONY: test-policies

test-policies:
	conftest test --output json k8s/
	conftest test --output json terraform/
	conftest test --output json docker/

validate:
	conftest test k8s/ -p policy/kubernetes/
	conftest test terraform/ -p policy/terraform/
	conftest test docker/ -p policy/docker/

policy-coverage:
	conftest verify --trace policy/
```

---

## Core Concepts

### Rego Policies

```rego
# Basic policy structure
package main

# Default allow to false
default allow = false

# Allow if conditions met
allow {
  input.kind == "Deployment"
  input.spec.replicas >= 2
}

# Violations
violation[{"msg": msg}] {
  input.kind == "Deployment"
  input.spec.replicas < 2
  msg := "Deployment must have at least 2 replicas"
}
```

### Input Formats

```yaml
# Kubernetes manifest input
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.21
          resources:
            limits:
              cpu: "1"
              memory: 128Mi
```

```json
// Terraform plan input
{
  "resource_changes": [
    {
      "address": "aws_instance.example",
      "type": "aws_instance",
      "change": {
        "after": {
          "instance_type": "t2.micro",
          "ami": "ami-12345"
        }
      }
    }
  ]
}
```

### Policy Evaluation

```bash
# Test single file
conftest test deployment.yaml -p policy.rego

# Test directory
conftest test k8s/ -p policy/

# Test with multiple policies
conftest test k8s/ -p policy/main.rego -p policy/kubernetes/

# Test with bundle
conftest test k8s/ --policies bundle.tar.gz
```

### Output Formats

```bash
# Table format (default)
conftest test deployment.yaml -p policy.rego

# JSON format
conftest test deployment.yaml -p policy.rego --output json

# TAP format
conftest test deployment.yaml -p policy.rego --output tap

# JUnit format
conftest test deployment.yaml -p policy.rego --output junit

# CSV format
conftest test deployment.yaml -p policy.rego --output csv
```

---

## Usage Guide

### Step 1: Create Policy Structure

```bash
mkdir -p policy/kubernetes
touch policy/kubernetes/main.rego
touch policy/kubernetes/deployment.rego
touch policy/kubernetes/pod.rego
```

### Step 2: Write First Policy

```yaml
# policy/kubernetes/main.rego
package main

default allow = false

allow {
  input.kind == "Deployment"
  input.spec.replicas >= 2
}

allow {
  input.kind == "Service"
}
```

### Step 3: Create Test File

```yaml
# test/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.21
```

### Step 4: Run Test

```bash
conftest test test/deployment.yaml -p policy/
# Expected output: PASS: main
```

### Step 5: Add More Policies

```yaml
# policy/kubernetes/deployment.rego
package kubernetes.deployment

deny[msg] {
  input.kind == "Deployment"
  input.spec.replicas < 2
  msg := "Deployment must have at least 2 replicas"
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %s must have resource limits", [container.name])
}
```

### Step 6: Test with Multiple Files

```bash
conftest test k8s/ -p policy/
```

---

## Custom Policies

### Resource Limits Policy

```yaml
# policy/resource-limits.rego
package main

deny[msg] {
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container %s must have CPU limits", [container.name])
}

deny[msg] {
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("Container %s must have memory limits", [container.name])
}
```

### Image Registry Policy

```yaml
# policy/image-registry.rego
package main

deny[msg] {
  container := input.spec.template.spec.containers[_]
  not startswith(container.image, "registry.k8s.io/")
  msg := sprintf("Container %s image must be from approved registry", [container.name])
}
```

### Label Policy

```yaml
# policy/labels.rego
package main

deny[msg] {
  required := {"app", "environment", "team"}
  provided := {key | input.metadata.labels[key]}
  missing := required - provided
  count(missing) > 0
  msg := sprintf("Missing required labels: %v", [missing])
}
```

### Network Policy

```yaml
# policy/network.rego
package main

deny[msg] {
  input.kind == "Service"
  input.spec.type == "LoadBalancer"
  not input.spec.loadBalancerSourceRanges
  msg := "LoadBalancer must specify source ranges"
}
```

### RBAC Policy

```yaml
# policy/rbac.rego
package main

deny[msg] {
  input.kind == "ClusterRoleBinding"
  input.roleRef.kind == "ClusterRole"
  input.roleRef.name == "cluster-admin"
  msg := "Cannot bind to cluster-admin role"
}
```

---

## Integration

### GitHub Actions

```yaml
# .github/workflows/policy-check.yml
name: Policy Check
on: [pull_request]
jobs:
  conftest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Conftest
        run: |
          curl -L -o conftest https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_Linux_x86_64.tar.gz
          tar -xzf conftest.tar.gz
          sudo mv conftest /usr/local/bin/
      
      - name: Run Conftest
        run: |
          conftest test k8s/ -p policy/ --output json > results.json
          if [ $(cat results.json | jq '.results | length') -gt 0 ]; then
            echo "Policy violations found!"
            cat results.json | jq '.results[].msg'
            exit 1
          fi
```

### GitLab CI

```yaml
# .gitlab-ci.yml
policy-check:
  stage: test
  image: openpolicyagent/conftest:latest
  script:
    - conftest test k8s/ -p policy/ --output json > results.json
    - |
      if [ $(cat results.json | jq '.results | length') -gt 0 ]; then
        echo "Policy violations found!"
        cat results.json | jq '.results[].msg'
        exit 1
      fi
  artifacts:
    paths:
      - results.json
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Policy Check') {
            steps {
                sh 'conftest test k8s/ -p policy/ --output json > results.json'
                script {
                    def results = readJSON file: 'results.json'
                    if (results.results.size() > 0) {
                        error "Policy violations found: ${results.results.collect { it.msg }.join(', ')}"
                    }
                }
            }
        }
    }
}
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/open-policy-agent/conftest
    rev: v0.46.0
    hooks:
      - id: conftest
        args: ['-p', 'policy/', '--output', 'json']
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  policy-check:
    image: openpolicyagent/conftest:latest
    volumes:
      - ./k8s:/workspace
      - ./policy:/policy
    command: test /workspace -p /policy/
```

---

## Security

### Policy Security

```yaml
# policy/security.rego
package main

# Block privileged containers
deny[msg] {
  container := input.spec.template.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Container %s cannot run privileged", [container.name])
}

# Block host network
deny[msg] {
  input.spec.template.spec.hostNetwork == true
  msg := "Cannot use host network"
}

# Block host PID
deny[msg] {
  input.spec.template.spec.hostPID == true
  msg := "Cannot use host PID"
}
```

### RBAC Policies

```yaml
# policy/rbac-security.rego
package main

deny[msg] {
  input.kind == "ClusterRoleBinding"
  input.roleRef.name == "cluster-admin"
  msg := "Cannot bind to cluster-admin"
}

deny[msg] {
  input.kind == "Role"
  rule := input.rules[_]
  rule.verbs[_] == "*"
  rule.resources[_] == "*"
  msg := "Role cannot have wildcard permissions"
}
```

### Network Policies

```yaml
# policy/network-security.rego
package main

deny[msg] {
  input.kind == "NetworkPolicy"
  not input.spec.podSelector
  msg := "NetworkPolicy must specify pod selector"
}

deny[msg] {
  input.kind == "NetworkPolicy"
  not input.spec.policyTypes
  msg := "NetworkPolicy must specify policy types"
}
```

### Secrets Management

```yaml
# policy/secrets.rego
package main

deny[msg] {
  input.kind == "Secret"
  input.type != "Opaque"
  msg := "Secrets must be Opaque type"
}

deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  env := container.env[_]
  env.valueFrom.secretKeyRef
  msg := sprintf("Container %s uses secret directly", [container.name])
}
```

---

## Troubleshooting

### Issue 1: Policy Not Found

**Symptoms**: `Error: policy not found`
**Diagnosis**:
```bash
ls -la policy/
conftest test --help | grep policy
```
**Solution**:
- Verify policy directory exists
- Check policy path in command
- Ensure .rego files are in correct location

### Issue 2: Rego Syntax Error

**Symptoms**: `Error: rego syntax error`
**Diagnosis**:
```bash
opa fmt policy.rego
opa check policy.rego
```
**Solution**:
- Fix syntax errors
- Check for missing brackets
- Validate Rego syntax

### Issue 3: Input Format Error

**Symptoms**: `Error: failed to parse input`
**Diagnosis**:
```bash
cat input.yaml | head -20
conftest test input.yaml --trace
```
**Solution**:
- Validate YAML/JSON syntax
- Check for missing fields
- Verify input structure

### Issue 4: Policy Evaluation Error

**Symptoms**: `Error: evaluation error`
**Diagnosis**:
```bash
conftest test --trace input.yaml
opa eval --data policy.rego --input input.json "data.main.violation"
```
**Solution**:
- Check for undefined variables
- Verify input structure matches policy
- Review policy logic

### Issue 5: Missing Dependencies

**Symptoms**: `Error: missing package`
**Diagnosis**:
```bash
grep -r "import" policy/
ls -la policy/lib/
```
**Solution**:
- Check import statements
- Verify library paths
- Include required packages

### Issue 6: Output Format Error

**Symptoms**: `Error: unknown output format`
**Diagnosis**:
```bash
conftest test --help | grep output
```
**Solution**:
- Use supported format (json, table, tap, junit)
- Check output flag syntax
- Verify Conftest version

### Issue 7: Bundle Error

**Symptoms**: `Error: failed to load bundle`
**Diagnosis**:
```bash
ls -la bundle.tar.gz
tar -tzf bundle.tar.gz
```
**Solution**:
- Verify bundle exists
- Check bundle structure
- Recreate bundle if corrupted

### Issue 8: Schema Validation Error

**Symptoms**: `Error: schema validation failed`
**Diagnosis**:
```bash
conftest test --schema schemas/ input.yaml
```
**Solution**:
- Check schema file
- Verify input matches schema
- Update schema if needed

### Issue 9: Permission Denied

**Symptoms**: `Error: permission denied`
**Diagnosis**:
```bash
ls -la policy/
whoami
```
**Solution**:
- Check file permissions
- Use sudo if needed
- Verify read access

### Issue 10: Timeout Error

**Symptoms**: `Error: context deadline exceeded`
**Diagnosis**:
```bash
time conftest test input.yaml
```
**Solution**:
- Simplify policies
- Increase timeout
- Optimize Rego code

### Issue 11: Memory Error

**Symptoms**: `Error: out of memory`
**Diagnosis**:
```bash
top -p $(pgrep conftest)
```
**Solution**:
- Reduce input size
- Optimize policies
- Increase memory limits

### Issue 12: Network Error

**Symptoms**: `Error: network timeout`
**Diagnosis**:
```bash
curl -I https://example.com
```
**Solution**:
- Check network connectivity
- Verify proxy settings
- Use local policies

### Issue 13: Version Mismatch

**Symptoms**: `Error: incompatible version`
**Diagnosis**:
```bash
conftest --version
```
**Solution**:
- Update Conftest
- Check compatibility
- Use matching versions

### Issue 14: Configuration Error

**Symptoms**: `Error: invalid configuration`
**Diagnosis**:
```bash
cat conftest.toml
conftest test --debug input.yaml
```
**Solution**:
- Check configuration file
- Verify TOML syntax
- Remove invalid options

### Issue 15: Test Data Error

**Symptoms**: `Error: test data not found`
**Diagnosis**:
```bash
ls -la test/
conftest test --help | grep data
```
**Solution**:
- Check test data location
- Verify file paths
- Create test data if needed

---

## Tips and Best Practices

### 1. Organize Policies by Type

```
policy/
├── main.rego
├── kubernetes/
│   ├── deployment.rego
│   ├── service.rego
│   └── pod.rego
├── terraform/
│   ├── aws.rego
│   └── gcp.rego
└── docker/
    └── dockerfile.rego
```

### 2. Use Package Namespaces

```rego
package kubernetes.deployment

deny[msg] {
  input.kind == "Deployment"
  msg := "deployment policy"
}
```

### 3. Test Policies Locally

```bash
# Test single file
conftest test deployment.yaml -p policy/

# Test with trace
conftest test deployment.yaml -p policy/ --trace

# Test with output
conftest test deployment.yaml -p policy/ --output json
```

### 4. Use Bundles for Distribution

```bash
# Create bundle
tar -czf policy-bundle.tar.gz policy/

# Use bundle
conftest test k8s/ --policies bundle.tar.gz
```

### 5. Implement Policy Testing

```bash
# Create test cases
mkdir -p tests/kubernetes
cat <<EOF > tests/kubernetes/deployment_test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
spec:
  replicas: 3
EOF

# Run tests
conftest test tests/ -p policy/
```

### 6. Use External Data

```rego
# Fetch external data
import future.keywords.in

get_data(url) = data {
  http.send({
    "method": "get",
    "url": url
  })
}
```

### 7. Implement Caching

```bash
# Cache policy compilation
conftest test k8s/ -p policy/ --cache-dir .conftest-cache
```

### 8. Use Multiple Output Formats

```bash
# Generate multiple outputs
conftest test k8s/ -p policy/ --output json > results.json
conftest test k8s/ -p policy/ --output junit > results.xml
conftest test k8s/ -p policy/ --output table
```

### 9. Implement Policy Versioning

```bash
# Version policies
git tag -a v1.0.0 -m "Policy version 1.0.0"
git push origin v1.0.0

# Use specific version
conftest test k8s/ --policies policy-v1.0.0.tar.gz
```

### 10. Use CI/CD Integration

```yaml
# GitHub Actions
- name: Run Conftest
  run: |
    conftest test k8s/ -p policy/ --output json > results.json
    if [ $(cat results.json | jq '.results | length') -gt 0 ]; then
      echo "Policy violations found!"
      exit 1
    fi
```

### 11. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
conftest test k8s/ -p policy/ --output json | tee audit.json

# Phase 2: Enforce mode
conftest test k8s/ -p policy/ --output json --fail-on-warning
```

### 12. Use Policy Coverage

```bash
# Check policy coverage
conftest verify --trace policy/
```

### 13. Implement Policy Documentation

```yaml
# policy/README.md
# Resource Limits Policy

This policy ensures all containers have resource limits.

## Usage

```bash
conftest test k8s/ -p policy/
```

## Rules

- All containers must have CPU limits
- All containers must have memory limits
```

### 14. Use Policy Libraries

```bash
# Create library
mkdir -p policy/lib
cat <<EOF > policy/lib/utils.rego
package lib.utils

get_containers(obj) = containers {
  containers := obj.spec.template.spec.containers
}
EOF

# Use library
import data.lib.utils
containers := utils.get_containers(input)
```

### 15. Implement Policy Reviews

```yaml
# .github/CODEOWNERS
policy/ @security-team
policy/kubernetes/ @platform-team
policy/terraform/ @infrastructure-team
```

---

## Command Reference

### Basic Commands

```bash
# Test configuration files
conftest test <file> -p <policy>

# Test directory
conftest test <dir> -p <policy>

# Verify policies
conftest verify -p <policy>

# Show version
conftest --version

# Show help
conftest --help
conftest test --help
```

### Test Options

```bash
# Output format
conftest test <file> --output json
conftest test <file> --output table
conftest test <file> --output tap
conftest test <file> --output junit

# Trace evaluation
conftest test <file> --trace

# Debug mode
conftest test <file> --debug

# Fail on warning
conftest test <file> --fail-on-warning

# All namespaces
conftest test <file> --all-namespaces

# Schema validation
conftest test <file> --schema <schema-dir>

# Combine config
conftest test <file> --combine

# Skip known files
conftest test <file> --skip-known
```

### Verify Options

```bash
# Trace verification
conftest verify --trace

# All-namespaces
conftest verify --all-namespaces

# Namespace
conftest verify --namespace <namespace>

# Output format
conftest verify --output json
```

### Bundle Commands

```bash
# Create bundle
tar -czf bundle.tar.gz policy/

# Use bundle
conftest test <file> --policies bundle.tar.gz

# Verify bundle
conftest verify --policies bundle.tar.gz
```

### Policy Options

```bash
# Single policy file
conftest test <file> -p policy.rego

# Policy directory
conftest test <file> -p policy/

# Multiple policies
conftest test <file> -p policy/main.rego -p policy/kubernetes/

# External libraries
conftest test <file> -p policy/ --lib-path lib/
```

---

## CRD Reference

### Policy Schema

```json
{
  "type": "object",
  "properties": {
    "policy": {
      "type": "object",
      "properties": {
        "version": {"type": "string"},
        "packages": {
          "type": "array",
          "items": {"type": "string"}
        },
        "rules": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "description": {"type": "string"},
              "severity": {"type": "string"},
              "match": {"type": "object"}
            }
          }
        }
      }
    }
  }
}
```

### Test Schema

```json
{
  "type": "object",
  "properties": {
    "test": {
      "type": "object",
      "properties": {
        "name": {"type": "string"},
        "input": {"type": "object"},
        "expected": {
          "type": "object",
          "properties": {
            "allow": {"type": "boolean"},
            "deny": {
              "type": "array",
              "items": {"type": "string"}
            }
          }
        }
      }
    }
  }
}
```

### Bundle Schema

```json
{
  "type": "object",
  "properties": {
    "bundle": {
      "type": "object",
      "properties": {
        "version": {"type": "string"},
        "revision": {"type": "string"},
        "data": {"type": "object"},
        "wasm": {"type": "array"}
      }
    }
  }
}
```

---

## Real-World Examples

### Kubernetes Deployment Validation

```yaml
# policy/kubernetes/deployment.rego
package kubernetes.deployment

deny[msg] {
  input.kind == "Deployment"
  input.spec.replicas < 2
  msg := "Deployment must have at least 2 replicas"
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container %s must have CPU limits", [container.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("Container %s must have memory limits", [container.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("Container %s uses latest tag", [container.name])
}
```

### Terraform AWS Validation

```yaml
# policy/terraform/aws.rego
package terraform.aws

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  resource.change.after.instance_type == "t2.micro"
  msg := sprintf("Instance %s cannot be t2.micro", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.versioning
  msg := sprintf("S3 bucket %s must have versioning enabled", [resource.address])
}
```

### Docker Compose Validation

```yaml
# policy/docker/docker-compose.rego
package docker.compose

deny[msg] {
  service := input.services[name]
  not service.restart
  msg := sprintf("Service %s must have restart policy", [name])
}

deny[msg] {
  service := input.services[name]
  service.ports[_] == "80:80"
  msg := sprintf("Service %s cannot expose port 80", [name])
}
```

### Helm Chart Validation

```yaml
# policy/helm/chart.rego
package helm.chart

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  container.image | contains("docker.io")
  msg := sprintf("Container %s uses Docker Hub", [container.name])
}
```

### Ansible Playbook Validation

```yaml
# policy/ansible/playbook.rego
package ansible.playbook

deny[msg] {
  task := input.tasks[_]
  task.name == "Install packages"
  not task.when
  msg := "Package installation must be conditional"
}
```

---

## Further Reading

### Official Documentation

- [Conftest GitHub](https://github.com/open-policy-agent/conftest)
- [OPA Documentation](https://www.openpolicyagent.org/docs/)
- [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)

### Community Resources

- [Conftest Examples](https://github.com/open-policy-agent/conftest/tree/main/examples)
- [OPA Best Practices](https://www.openpolicyagent.org/docs/latest/security/)
- [Policy Testing Patterns](https://www.openpolicyagent.org/docs/latest/policy-testing/)

### Books and Tutorials

- "Policy-Based Configuration Testing" by OPA
- "Conftest Best Practices" by CNCF
- "Rego Programming" by OPA

### Videos and Talks

- "Conftest Deep Dive" by CNCF
- "OPA in CI/CD" by KubeCon
- "Policy Enforcement Patterns" by ThoughtWorks

### Related Projects

- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno](https://kyverno.io/)
- [Checkov](https://www.checkov.io/)
