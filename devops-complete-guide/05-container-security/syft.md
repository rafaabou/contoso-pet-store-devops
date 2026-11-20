# Syft Complete Guide (SBOM)

## Table of Contents

1. [What Is Syft](#1-what-is-syft)
2. [Why Use Syft](#2-why-use-syft)
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

## 1. What Is Syft

Syft is a powerful and fast Software Bill of Materials (SBOM) generation tool developed by Anchore. It creates comprehensive inventories of all packages, dependencies, and libraries found in container images, filesystems, and archives.

### 1.1 Overview

Syft generates SBOMs by inspecting container image layers, reading package manifests, analyzing language ecosystems, and supporting multiple SBOM formats including CycloneDX, SPDX, and Syft's native JSON format. It uses multiple detection strategies to minimize false positives while maintaining high accuracy.

### 1.2 Architecture

Syft's architecture consists of a Cataloger Engine (pluggable system for detecting different package types), Source Provider (handles different input sources), SBOM Encoder (converts internal representation to standard formats), and File Parsers (handles different package manager metadata formats).

### 1.3 Supported Package Ecosystems

| Ecosystem | Package Manager | Metadata Format |
|---|---|---|
| Alpine | apk | APKINDEX |
| Debian/Ubuntu | dpkg | dpkg status |
| RHEL/CentOS | rpm | RPM database |
| Python | pip, poetry, conda | requirements.txt, pyproject.toml |
| JavaScript | npm, yarn | package-lock.json, yarn.lock |
| Go | go mod | go.sum |
| Ruby | bundler | Gemfile.lock |
| Rust | cargo | Cargo.lock |
| Java | Maven, Gradle | pom.xml, build.gradle |
| .NET | NuGet | .csproj, packages.config |
| PHP | composer | composer.lock |
| Dart | pub | pubspec.lock |
| Elixir | hex | mix.lock |
| Swift | Swift Package Manager | Package.resolved |

### 1.4 Supported Input Sources

| Source Type | Supported Formats |
|---|---|
| Container Images | Docker, OCI, Podman, TAR archives |
| Filesystem | Source code directories |
| Archives | TAR, ZIP, and other archive formats |
| SBOM Files | CycloneDX, SPDX (for re-encoding) |

### 1.5 Comparison with Other SBOM Tools

| Feature | Syft | Trivy | SPDX Tools | CycloneDX CLI |
|---|---|---|---|---|
| Open Source | Yes (Apache 2) | Yes (Apache 2) | Yes | Yes |
| Container Image SBOM | Yes | Yes | Limited | Limited |
| Language Ecosystems | 20+ | 15+ | 10+ | 5+ |
| Output Formats | CycloneDX, SPDX, JSON | CycloneDX, SPDX, JSON | SPDX | CycloneDX |
| Speed | Fastest | Fast | Slow | Medium |
| Accuracy | High | High | Medium | Medium |
| Grype Integration | Native | No | No | No |
| License Detection | Yes | Yes | Yes | Limited |
| Dependency Graph | Yes | Limited | Yes | Limited |

---

## 2. Why Use Syft

### 2.1 Supply Chain Security

SBOMs are critical for supply chain security because they provide transparency (complete visibility into all components), vulnerability tracking (ability to track vulnerabilities across your entire software stack), license compliance (ensure all components have compatible licenses), incident response (quickly identify affected systems when a new vulnerability is disclosed), and regulatory compliance (meet requirements from Executive Order 14028, EU Cyber Resilience Act, etc.).

### 2.2 Industry Standard Compliance

Syft generates SBOMs in industry-standard formats: CycloneDX (OWASP standard, widely supported by security tools) and SPDX (Linux Foundation standard, used in compliance and legal contexts).

### 2.3 Speed and Accuracy

Syft is the fastest SBOM generator available, scanning a typical container image in under 10 seconds. It uses multiple detection strategies for high accuracy and handles complex dependency graphs correctly.

### 2.4 Ecosystem Integration

Syft is part of the Anchore ecosystem: Syft (SBOM generation), Grype (vulnerability scanning using Syft SBOMs), and Anchore Enterprise (commercial supply chain security platform).

### 2.5 Executive Order 14028 Compliance

US Executive Order 14028 requires software vendors to provide SBOMs for all software sold to the federal government, use machine-readable SBOM formats, and include dependency information. Syft helps meet these requirements by generating compliant SBOMs.

---

## 3. Real-World Breaches

### 3.1 SolarWinds Supply Chain Attack (2020)

**What happened**: Attackers compromised the SolarWinds Orion build system and injected a backdoor (SUNBURST) into software updates distributed to 18,000+ organizations. An SBOM would have revealed the presence of the compromised component, all dependencies and their versions, and the ability to quickly identify affected systems.

### 3.2 Log4Shell (CVE-2021-44228)

**What happened**: A critical RCE vulnerability in Apache Log4j affected millions of Java applications worldwide. An SBOM would have revealed all applications using Log4j, the exact versions in use, and the dependency chain from application to vulnerable library.

### 3.3 Codecov Supply Chain Attack (2021)

**What happened**: Attackers modified the Codecov Bash Uploader script to exfiltrate environment variables, including CI/CD secrets, from over 29,000 repositories. An SBOM would have revealed the presence of the Codecov uploader script, all scripts and tools in the build pipeline, and the ability to track script changes over time.

### 3.4 Dependency Confusion Attacks (2021)

**What happened**: Security researcher Alex Birsan demonstrated that by publishing packages with the same name as internal packages on public registries, attackers could trick package managers into downloading malicious code. An SBOM would have revealed all dependencies, the origin of each dependency (public vs. private), and unexpected public dependencies that might be malicious.

### 3.5 OpenSSL Heartbleed (CVE-2014-0160)

**What happened**: A critical vulnerability in OpenSSL allowed attackers to read up to 64KB of server memory per request. An SBOM would have revealed all systems using OpenSSL, the exact versions in use, and the ability to quickly patch affected systems.

### 3.6 Spring4Shell (CVE-2022-22965)

**What happened**: A critical RCE vulnerability in Spring Framework affecting Spring Boot applications. An SBOM would have revealed all applications using Spring Framework, the exact versions in use, and the dependency chain from application to vulnerable library.

---

## 4. Installation

### 4.1 Quick Install (Recommended)

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
syft version
```

### 4.2 Package Managers

```bash
# Ubuntu/Debian
curl -1sLf 'https://raw.githubusercontent.com/anchore/syft/main/install.sh' | sudo -E bash
sudo apt-get install syft

# Homebrew (macOS)
brew install syft

# Snap
sudo snap install syft

# AUR (Arch Linux)
yay -S syft
```

### 4.3 Docker

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft:latest nginx:latest
docker run --rm -v /path/to/project:/project anchore/syft:latest dir:/project
```

### 4.4 Binary Download

```bash
SYFT_VERSION=$(curl -s https://api.github.com/repos/anchore/syft/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
curl -LO "https://github.com/anchore/syft/releases/download/${SYFT_VERSION}/syft_${SYFT_VERSION#v}_linux_amd64.tar.gz"
tar -xzf "syft_${SYFT_VERSION#v}_linux_amd64.tar.gz"
sudo mv syft /usr/local/bin/
```

### 4.5 Kubernetes Deployment

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: syft-sbom
spec:
  template:
    spec:
      containers:
      - name: syft
        image: anchore/syft:latest
        args:
        - nginx:latest
        - -o
        - cyclonedx-json=/tmp/sbom.json
        volumeMounts:
        - name: sbom-output
          mountPath: /tmp
      restartPolicy: Never
      volumes:
      - name: sbom-output
        emptyDir: {}
  backoffLimit: 1
```

---

## 5. Configuration

### 5.1 Configuration File

```yaml
# .syft.yaml
output:
  - cyclonedx-json=/dev/stdout
  - spdx-json=/tmp/sbom.spdx.json

catalogers:
  package:
    search:
      scope: all-layers
      nested: "false"
  python:
    search:
      scope: all-layers
  java:
    search:
      scope: all-layers
  javascript:
    search:
      scope: all-layers
  ruby:
    search:
      scope: all-layers
  go:
    search:
      scope: all-layers
  rust:
    search:
      scope: all-layers
  dotnet:
    search:
      scope: all-layers
  php:
    search:
      scope: all-layers
```

### 5.2 Environment Variables

```bash
export SYFT_OUTPUT=cyclonedx-json=/tmp/sbom.json
export SYFT_CATALOGERS_PACKAGE_SEARCH_SCOPE=all-layers
export SYFT_CATALOGERS_PACKAGE_SEARCH_NESTED=false
```

---

## 6. Core Concepts

### 6.1 SBOM Structure

An SBOM generated by Syft contains metadata (tool info, timestamp, component info), components (list of all packages with name, version, type, licenses), and dependencies (relationships between packages).

### 6.2 Catalogers

Syft uses catalogers to detect packages: dpkg-cataloger (Debian/Ubuntu), rpm-cataloger (RHEL/CentOS), apk-cataloger (Alpine), python-installed-package-cataloger (Python), javascript-package-cataloger (npm/yarn), go-module-cataloger (Go modules), ruby-gemfile-cataloger (Ruby gems), rust-cargo-cataloger (Rust crates), java-archive-cataloger (Java JARs), dotnet-deps-cataloger (.NET dependencies).

### 6.3 Search Scopes

- **Squashed**: Scan the squashed image (single layer)
- **All Layers**: Scan all image layers
- **All Packages**: Include packages from all layers

### 6.4 Output Formats

| Format | Description | Use Case |
|---|---|---|
| cyclonedx-json | CycloneDX JSON | Vulnerability scanning, compliance |
| cyclonedx-xml | CycloneDX XML | Legacy systems |
| spdx-json | SPDX JSON | Legal compliance |
| spdx-tag-value | SPDX Tag-Value | SPDX tools |
| syft-json | Syft native JSON | Debugging, custom processing |
| table | Human-readable table | Quick inspection |

### 6.5 Package Metadata

Syft captures name, version, type, foundBy, metadataType, metadata (ecosystem-specific), source, and locations for each package.

---

## 7. Usage Guide

### 7.1 Generating SBOMs from Container Images

```bash
syft nginx:latest -o cyclonedx-json=sbom.cdx.json
syft nginx:latest -o spdx-json=sbom.spdx.json
syft nginx:latest -o syft-json=sbom.syft.json
syft nginx:latest -o table
syft nginx:latest -o cyclonedx-json=sbom.cdx.json --scope all-layers
syft nginx:latest --platform linux/arm64 -o cyclonedx-json=sbom.cdx.json
```

### 7.2 Generating SBOMs from Filesystems

```bash
syft dir:./my-project -o cyclonedx-json=sbom.cdx.json
syft dir:./my-project -o cyclonedx-json=sbom.cdx.json --scope all-layers
syft dir:./my-project -o cyclonedx-json=sbom.cdx.json --catalogers javascript-package-cataloger
```

### 7.3 Generating SBOMs from Archives

```bash
syft docker-archive:my-image.tar -o cyclonedx-json=sbom.cdx.json
syft oci-archive:my-image.tar -o cyclonedx-json=sbom.cdx.json
syft podman-archive:my-image.tar -o cyclonedx-json=sbom.cdx.json
```

### 7.4 Re-encoding SBOMs

```bash
syft sbom:sbom.cdx.json -o spdx-json=sbom.spdx.json
syft sbom:sbom.spdx.json -o cyclonedx-json=sbom.cdx.json
syft sbom:sbom.syft.json -o cyclonedx-json=sbom.cdx.json
```

### 7.5 Scanning with Grype

```bash
syft nginx:latest -o cyclonedx-json=sbom.cdx.json
grype sbom:sbom.cdx.json

# Or in one command
syft nginx:latest -o cyclonedx-json=/dev/stdout | grype
```

### 7.6 Listing Packages

```bash
syft nginx:latest -o table
syft nginx:latest -o table --catalogers dpkg-cataloger,rpm-cataloger,apk-cataloger
syft nginx:latest -o table --catalogers javascript-package-cataloger,python-installed-package-cataloger
syft nginx:latest -o json | jq '.artifacts[] | select(.name | contains("nginx"))'
```

### 7.7 Comparing SBOMs

```bash
diff <(syft image1:latest -o json | jq '.artifacts[].name' | sort) \
     <(syft image2:latest -o json | jq '.artifacts[].name' | sort)

comm -13 \
  <(syft image1:latest -o json | jq -r '.artifacts[].name' | sort) \
  <(syft image2:latest -o json | jq -r '.artifacts[].name' | sort)

comm -23 \
  <(syft image1:latest -o json | jq -r '.artifacts[].name' | sort) \
  <(syft image2:latest -o json | jq -r '.artifacts[].name' | sort)
```

---

## 8. Custom Rules and Policies

### 8.1 Post-Processing with jq

```bash
syft nginx:latest -o json | jq '.artifacts[] | select(.type == "deb")'
syft nginx:latest -o json | jq '.artifacts[] | select(.name | startswith("lib"))'
syft nginx:latest -o json | jq '.artifacts[] | select(.version | startswith("1.25"))'
syft nginx:latest -o json | jq '[.artifacts[] | .type] | group_by(.) | map({type: .[0], count: length})'
syft nginx:latest -o json | jq '.artifacts[].licenses[].license.name' | sort | uniq
```

### 8.2 Custom SBOM Templates

```bash
syft nginx:latest -o template='{{ range .artifacts }}{{ .name }}@{{ .version }} ({{ .type }})
{{ end }}'

syft nginx:latest -o template='name,version,type
{{ range .artifacts }}{{ .name }},{{ .version }},{{ .type }}
{{ end }}'
```

### 8.3 Policy-as-Code with OPA

```rego
package main

default allow = false

allow {
    count(critical_vulnerabilities) == 0
}

critical_vulnerabilities[vuln] {
    vuln := input.vulnerabilities[_]
    vuln.severity == "critical"
}

allow {
    count(unlicensed_packages) == 0
}

unlicensed_packages[pkg] {
    pkg := input.components[_]
    count(pkg.licenses) == 0
}
```

### 8.4 License Compliance Rules

```bash
syft nginx:latest -o json | jq '.artifacts[].licenses[].license.name' | grep -i gpl
syft nginx:latest -o json | jq '.artifacts[].licenses[].license.name' | grep -iE "commercial|proprietary|enterprise"
syft nginx:latest -o json | jq '[.artifacts[] | {name: .name, license: .licenses[0].license.name}]' > licenses.json
```

---

## 9. Integration

### 9.1 GitHub Actions

```yaml
name: Syft SBOM Generation
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  generate-sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t my-app:${{ github.sha }} .

      - name: Generate CycloneDX SBOM
        uses: anchore/sbom-action@v0
        with:
          image: my-app:${{ github.sha }}
          format: cyclonedx
          output-file: sbom.cdx.json

      - name: Generate SPDX SBOM
        uses: anchore/sbom-action@v0
        with:
          image: my-app:${{ github.sha }}
          format: spdx-json
          output-file: sbom.spdx.json

      - name: Upload SBOMs
        uses: actions/upload-artifact@v4
        with:
          name: sboms
          path: |
            sbom.cdx.json
            sbom.spdx.json

      - name: Scan SBOM with Grype
        uses: anchore/scan-action@v6
        with:
          sbom: sbom.cdx.json
          fail-build: true
          severity-cutoff: high
```

### 9.2 GitLab CI/CD

```yaml
syft-sbom:
  stage: security
  image: anchore/syft:latest
  script:
    - syft $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -o cyclonedx-json=sbom.cdx.json
    - syft $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -o spdx-json=sbom.spdx.json
  artifacts:
    paths:
      - sbom.cdx.json
      - sbom.spdx.json
    reports:
      dependency_scanning: sbom.cdx.json
```

### 9.3 Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t my-app:${BUILD_NUMBER} .'
            }
        }
        stage('Generate SBOM') {
            steps {
                sh '''
                    syft my-app:${BUILD_NUMBER} \
                        -o cyclonedx-json=sbom-cdx.json \
                        -o spdx-json=sbom-spdx.json
                '''
            }
        }
        stage('Scan SBOM') {
            steps {
                sh 'grype sbom:sbom-cdx.json --fail-on high'
            }
        }
        stage('Upload SBOM') {
            steps {
                archiveArtifacts artifacts: 'sbom-*.json'
            }
        }
    }
}
```

### 9.4 ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  annotations:
    syft.anchore.io/image-ref: my-app:latest
    syft.anchore.io/format: cyclonedx
    syft.anchore.io/output: /tmp/sbom.json
```

### 9.5 k3s with Syft

```bash
# Deploy Syft as a CronJob in k3s
kubectl create job syft-sbom-$(date +%s) --from=cronjob/syft-scanner

# Or run ad-hoc
kubectl run syft-scan --rm -it --image=anchore/syft:latest -- nginx:latest -o cyclonedx-json=/dev/stdout
```

### 9.6 Harbor Integration

```bash
# Configure Harbor to use Syft for SBOM generation
# Harbor UI -> Administration -> Interrogation Services -> Scanner

# Or via Harbor API
curl -X POST "https://harbor.example.com/api/v2.0/scanners" \
  -H "Authorization: Basic $(echo -n admin:password | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Syft",
    "description": "Syft SBOM generator",
    "version": "0.100.0",
    "url": "http://syft-server:8080",
    "vendor": "Anchore",
    "enabled": true
  }'
```

---

## 10. Security Hardening

### 10.1 Running Syft in Restricted Mode

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: syft-scan
spec:
  template:
    spec:
      serviceAccountName: syft-scanner
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: syft
        image: anchore/syft:latest
        args:
        - nginx:latest
        - -o
        - cyclonedx-json=/tmp/sbom.json
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
        - name: docker-socket
          mountPath: /var/run/docker.sock
          readOnly: true
        - name: sbom-output
          mountPath: /tmp
      volumes:
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
      - name: sbom-output
        emptyDir: {}
      restartPolicy: Never
  backoffLimit: 1
```

### 10.2 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: syft-network-policy
  namespace: syft-system
spec:
  podSelector:
    matchLabels:
      app: syft
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

### 10.3 RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: syft-scanner
  namespace: syft-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: syft-scanner
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: syft-scanner
subjects:
- kind: ServiceAccount
  name: syft-scanner
  namespace: syft-system
roleRef:
  kind: ClusterRole
  name: syft-scanner
  apiGroup: rbac.authorization.k8s.io
```

---

## 11. Troubleshooting

### 11.1 Issue: Docker Socket Permission Denied

**Symptom**: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Fix**:
```bash
sudo usermod -aG docker $USER
sudo trivy image nginx:latest
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/syft:latest nginx:latest
```

### 11.2 Issue: Out of Memory

**Symptom**: `Killed` or `out of memory` error

**Fix**:
```bash
docker run --rm --memory=2g anchore/syft:latest nginx:latest
syft --scope squashed nginx:latest
```

### 11.3 Issue: Slow Scanning

**Symptom**: Scan takes too long

**Fix**:
```bash
syft --scope squashed nginx:latest
syft docker-archive:my-image.tar -o cyclonedx-json=sbom.cdx.json
```

### 11.4 Issue: Missing Packages

**Symptom**: Expected packages not found in SBOM

**Fix**:
```bash
syft --scope all-layers nginx:latest
syft --catalogers all nginx:latest
syft nginx:latest -o json | jq '.artifacts | length'
```

### 11.5 Issue: Invalid SBOM Output

**Symptom**: SBOM validation errors

**Fix**:
```bash
syft nginx:latest -o cyclonedx-json=sbom.cdx.json
cat sbom.cdx.json | jq '.bomFormat'
cyclonedx validate --input-file sbom.cdx.json
```

### 11.6 Issue: Private Registry Authentication

**Symptom**: `UNAUTHORIZED` or `authentication required`

**Fix**:
```bash
docker login registry.example.com
syft registry.example.com/my-app:v1

export SYFT_REGISTRY_AUTH_USERNAME=myuser
export SYFT_REGISTRY_AUTH_PASSWORD=mypassword
syft registry.example.com/my-app:v1
```

### 11.7 Issue: Large Image Scanning

**Symptom**: Scan fails on very large images

**Fix**:
```bash
docker run --rm --cpus=4 --memory=4g anchore/syft:latest large-image:latest
syft --scope squashed large-image:latest
```

### 11.8 Issue: Version Mismatch

**Symptom**: `schema version mismatch` error

**Fix**:
```bash
syft version
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

### 11.9 Issue: CI/CD Pipeline Timeout

**Symptom**: Scan times out in CI/CD pipeline

**Fix**:
```yaml
- name: Syft Scan
  uses: anchore/sbom-action@v0
  timeout-minutes: 30
  with:
    image: my-app:latest
```

### 11.10 Issue: Multiple Image Tags

**Symptom**: Cannot scan image with multiple tags

**Fix**:
```bash
syft myregistry/myapp:tag1
syft myregistry/myapp:tag2
```

### 11.11 Issue: Unicode and Internationalized Characters

**Symptom**: Incorrect package matching for international packages

**Fix**:
```bash
syft nginx:latest -o json | jq '.artifacts[] | select(.name | contains("特殊字符"))'
```

### 11.12 Issue: Garbage Collection of Old Reports

**Symptom**: Disk space issues from accumulated SBOMs

**Fix**:
```bash
find /var/log/syft -name "*.json" -mtime +7 -delete
```

### 11.13 Issue: SBOM File Too Large

**Symptom**: SBOM file exceeds storage limits

**Fix**:
```bash
syft nginx:latest -o cyclonedx-json=/dev/stdout | gzip > sbom.cdx.json.gz
```

### 11.14 Issue: Dependency Graph Not Complete

**Symptom**: Missing dependency relationships

**Fix**:
```bash
syft --scope all-layers nginx:latest -o cyclonedx-json=sbom.cdx.json
cat sbom.cdx.json | jq '.dependencies'
```

### 11.15 Issue: License Detection Not Working

**Symptom**: No licenses detected in SBOM

**Fix**:
```bash
syft nginx:latest -o json | jq '.artifacts[].licenses'
syft --scope all-layers nginx:latest -o json | jq '.artifacts[].licenses'
```

---

## 12. Tips and Best Practices

### 12.1 Generate SBOMs Early in the Pipeline

Generate SBOMs during the build stage and store them as artifacts for later vulnerability scanning.

### 12.2 Use Multiple Output Formats

Generate both CycloneDX (for vulnerability scanning) and SPDX (for legal compliance) SBOMs.

### 12.3 Store SBOMs in a Central Repository

Store generated SBOMs in a central repository (e.g., Harbor, Nexus, or S3) for tracking and auditing.

### 12.4 Use SBOMs for Incident Response

When a new vulnerability is disclosed, search your SBOM repository to quickly identify affected systems.

### 12.5 Combine with Grype for Vulnerability Scanning

Use Syft to generate SBOMs and Grype to scan them for vulnerabilities.

### 12.6 Use Digest pinning for Images

Instead of using tags (which are mutable), use image digests for reproducible SBOMs.

### 12.7 Scan Base Images Separately

Generate SBOMs for base images separately and reuse them across multiple application images.

### 12.8 Use SBOMs for License Compliance

Regularly audit SBOMs for license violations and ensure all components have compatible licenses.

### 12.9 Automate SBOM Generation

Use CI/CD pipelines to automatically generate SBOMs for every build.

### 12.10 Use SBOMs for Supply Chain Security

Verify that all components in your SBOM come from trusted sources.

### 12.11 Use SBOMs for Compliance

Use SBOMs to meet regulatory requirements (Executive Order 14028, EU Cyber Resilience Act).

### 12.12 Use SBOMs for Dependency Management

Track all dependencies and their versions to identify outdated or vulnerable components.

### 12.13 Use SBOMs for Audit Trail

Maintain a history of SBOMs for each version of your software for audit purposes.

### 12.14 Use SBOMs for Risk Assessment

Analyze SBOMs to identify high-risk components that require additional security controls.

### 12.15 Use SBOMs for Vendor Management

Require SBOMs from all software vendors and analyze them for security risks.

---

## 13. Command Reference

### 13.1 Global Flags

| Flag | Description | Default |
|---|---|---|
| `-o, --output` | Output format | table |
| `--scope` | Search scope | squashed |
| `--platform` | Platform (e.g., linux/amd64) | - |
| `--catalogers` | Cataloger selection | all |
| `-q, --quiet` | Suppress output | false |
| `-v, --verbose` | Verbose output | false |
| `--config` | Config file path | .syft.yaml |

### 13.2 Output Formats

| Format | Description |
|---|---|
| cyclonedx-json | CycloneDX JSON |
| cyclonedx-xml | CycloneDX XML |
| spdx-json | SPDX JSON |
| spdx-tag-value | SPDX Tag-Value |
| syft-json | Syft native JSON |
| table | Human-readable table |
| template | Custom Go template |

### 13.3 Source Types

| Source | Description |
|---|---|
| docker:IMAGE | Docker image |
| docker-archive:PATH | Docker save archive |
| oci-archive:PATH | OCI archive |
| podman-archive:PATH | Podman archive |
| dir:PATH | Directory |
| sbom:PATH | SBOM file |

---

## 14. Configuration Reference

### 14.1 Full Configuration Example

```yaml
# .syft.yaml
output:
  - cyclonedx-json=/dev/stdout
  - spdx-json=/tmp/sbom.spdx.json
  - table=/dev/stdout

catalogers:
  package:
    search:
      scope: all-layers
      nested: "false"
  python:
    search:
      scope: all-layers
  java:
    search:
      scope: all-layers
  javascript:
    search:
      scope: all-layers
  ruby:
    search:
      scope: all-layers
  go:
    search:
      scope: all-layers
  rust:
    search:
      scope: all-layers
  dotnet:
    search:
      scope: all-layers
  php:
    search:
      scope: all-layers
  dart:
    search:
      scope: all-layers
  elixir:
    search:
      scope: all-layers
  swift:
    search:
      scope: all-layers
```

### 14.2 Environment Variables Reference

| Variable | Description | Default |
|---|---|---|
| SYFT_OUTPUT | Output format | table |
| SYFT_CATALOGERS_PACKAGE_SEARCH_SCOPE | Search scope | squashed |
| SYFT_CATALOGERS_PACKAGE_SEARCH_NESTED | Nested search | false |
| SYFT_REGISTRY_AUTH_USERNAME | Registry username | - |
| SYFT_REGISTRY_AUTH_PASSWORD | Registry password | - |

---

## 15. Real-World Examples

### 15.1 Contoso Pet Store - SBOM Generation

**Scenario**: Contoso Pet Store runs a microservices architecture on Kubernetes with 15 container images in production.

#### 15.1.1 CI/CD Pipeline Integration

```yaml
name: Pet Store SBOM Generation
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  generate-sbom:
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

      - name: Generate CycloneDX SBOM
        uses: anchore/sbom-action@v0
        with:
          image: petstore/${{ matrix.service }}:${{ github.sha }}
          format: cyclonedx
          output-file: sbom-${{ matrix.service }}.cdx.json

      - name: Generate SPDX SBOM
        uses: anchore/sbom-action@v0
        with:
          image: petstore/${{ matrix.service }}:${{ github.sha }}
          format: spdx-json
          output-file: sbom-${{ matrix.service }}.spdx.json

      - name: Upload SBOMs to Artifact Registry
        run: |
          gcloud artifacts repositories create petstore-sboms \
            --repository-format=docker \
            --location=us-central1
          gsutil cp sbom-${{ matrix.service }}.cdx.json \
            gs://petstore-sboms/${{ matrix.service }}/${{ github.sha }}/sbom.cdx.json

      - name: Scan SBOM with Grype
        uses: anchore/scan-action@v6
        with:
          sbom: sbom-${{ matrix.service }}.cdx.json
          fail-build: true
          severity-cutoff: high
```

#### 15.1.2 Incident Response Workflow

```bash
#!/bin/bash
# petstore-incident-response.sh

VULNERABILITY="$1"

echo "Searching for packages affected by $VULNERABILITY..."

# Search all SBOMs in GCS
for sbom in $(gsutil ls gs://petstore-sboms/*/sbom.cdx.json); do
    echo "Checking $sbom..."
    if cat "$sbom" | jq -e ".components[] | select(.name | contains(\"$VULNERABILITY\"))" > /dev/null 2>&1; then
        echo "  AFFECTED: $sbom"
    fi
done
```

---

## 16. Further Reading

### 16.1 Official Documentation

- [Syft Documentation](https://github.com/anchore/syft)
- [Syft GitHub Repository](https://github.com/anchore/syft)
- [Grype Documentation](https://github.com/anchore/grype)
- [Anchore Enterprise](https://www.anchore.com/products/enterprise/)

### 16.2 Blog Posts and Tutorials

- [Getting Started with Syft](https://github.com/anchore/syft#getting-started)
- [Syft vs Trivy: A Comparison](https://blog.anchore.com/syft-vs-trivy)
- [Securing Kubernetes with Anchore](https://www.anchore.com/blog/securing-kubernetes-with-anchore/)

### 16.3 Community Resources

- [Syft Slack Channel](https://slack.anchore.com/)
- [Syft Discussions](https://github.com/anchore/syft/discussions)
- [Syft Issues](https://github.com/anchore/syft/issues)

### 16.4 Related Tools

- [Grype](https://github.com/anchore/grype) - Vulnerability scanner
- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner
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
*Syft version: 0.100.0+*
