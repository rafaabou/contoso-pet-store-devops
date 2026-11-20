# Distroless Images Complete Guide

## Table of Contents

1. [What Are Distroless Images](#1-what-are-distroless-images)
2. [Why Use Distroless Images](#2-why-use-distroless-images)
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

## 1. What Are Distroless Images

Distroless images are container images developed by Google that contain only the application and its runtime dependencies. They do not contain package managers, shells, or any other operating system utilities. This minimal approach significantly reduces the attack surface of container images.

### 1.1 Overview

Distroless images provide:

- **Minimal Attack Surface**: No package managers, shells, or unnecessary utilities
- **Reduced Vulnerability Count**: Fewer packages mean fewer potential CVEs
- **Small Image Size**: Typically 2-10x smaller than traditional images
- **Better Security Posture**: Harder for attackers to exploit
- **Compliance**: Meets requirements for minimal container images

### 1.2 Available Distroless Images

| Language | Base Image | Description |
|---|---|---|
| Java | `gcr.io/distroless/java17-debian12` | Java 17 runtime |
| Java | `gcr.io/distroless/java11-debian12` | Java 11 runtime |
| Java | `gcr.io/distroless/java8-debian12` | Java 8 runtime |
| Python | `gcr.io/distroless/python3-debian12` | Python 3 runtime |
| Node.js | `gcr.io/distroless/nodejs18-debian12` | Node.js 18 runtime |
| Go | `gcr.io/distroless/static-debian12` | Static Go binaries |
| .NET | `gcr.io/distroless/dotnet-debian12` | .NET runtime |
| Rust | `gcr.io/distroless/static-debian12` | Static Rust binaries |
| C/C++ | `gcr.io/distroless/static-debian12` | Static C/C++ binaries |
| Nonroot | `gcr.io/distroless/static-debian12:nonroot` | Non-root variant |

### 1.3 Architecture

Distroless images are built on top of Debian base images and include:

- **Base Layer**: Minimal Debian runtime
- **Language Runtime**: Specific language runtime (e.g., Java, Python, Node.js)
- **Application**: Your compiled application
- **No Package Managers**: No apt, yum, or apk
- **No Shells**: No bash, sh, or other shells
- **No Utilities**: No curl, wget, or other utilities

### 1.4 Comparison with Other Images

| Feature | Distroless | Alpine | Ubuntu | Debian |
|---|---|---|---|---|
| Package Manager | No | apk | apt | apt |
| Shell | No | sh | bash | bash |
| Utilities | No | Limited | Full | Full |
| Image Size | Smallest | Small | Large | Large |
| Vulnerability Count | Lowest | Low | High | High |
| Attack Surface | Minimal | Small | Large | Large |
| Debugging | Difficult | Easy | Easy | Easy |
| Security | Best | Good | Fair | Fair |

---

## 2. Why Use Distroless Images

### 2.1 Reduced Attack Surface

Traditional container images include:

- Package managers (apt, yum, apk) that can install additional software
- Shells (bash, sh) that allow attackers to execute commands
- Utilities (curl, wget, netcat) that attackers can use for reconnaissance or exfiltration
- System utilities (ps, top, netstat) that attackers can use for enumeration

Distroless images eliminate all of these, making it much harder for attackers to:

- Install malicious software
- Execute arbitrary commands
- Perform reconnaissance
- Exfiltrate data
- Maintain persistence

### 2.2 Fewer Vulnerabilities

Because Distroless images contain fewer packages, they have fewer potential CVEs:

- **Alpine**: ~30-50 CVEs per image
- **Ubuntu**: ~100-200 CVEs per image
- **Debian**: ~80-150 CVEs per image
- **Distroless**: ~5-15 CVEs per image

### 2.3 Smaller Image Size

Distroless images are significantly smaller than traditional images:

- **Java Distroless**: ~50-100 MB
- **Java Ubuntu**: ~200-500 MB
- **Python Distroless**: ~30-50 MB
- **Python Ubuntu**: ~100-300 MB
- **Static Distroless**: ~2-5 MB
- **Alpine**: ~5-15 MB

### 2.4 Better Compliance

Distroless images help meet compliance requirements:

- **CIS Benchmark**: Recommends minimal container images
- **NIST**: Recommends removing unnecessary software
- **PCI DSS**: Requires minimal attack surface
- **HIPAA**: Requires security controls for healthcare data

### 2.5 Supply Chain Security

Distroless images improve supply chain security by:

- **Reducing Dependencies**: Fewer packages mean fewer potential supply chain attacks
- **Trusted Sources**: Built by Google using official Debian packages
- **Reproducible Builds**: Built from specific Debian versions
- **SBOM Support**: Can generate SBOMs for compliance

---

## 3. Real-World Breaches

### 3.1 Docker Hub Malware (2020)

**What happened**: Researchers found thousands of malicious Docker images on Docker Hub, including cryptominers and credential stealers.

**Distroless prevention**: Distroless images would have prevented:

- Installation of malicious packages
- Execution of malicious scripts
- Persistence mechanisms
- Data exfiltration

### 3.2 Log4Shell (CVE-2021-44228)

**What happened**: A critical RCE vulnerability in Apache Log4j affected millions of Java applications worldwide.

**Distroless prevention**: While Distroless cannot prevent the vulnerability itself, it can:

- Limit the impact by preventing attacker reconnaissance
- Prevent installation of additional malicious software
- Reduce the attack surface for exploitation

### 3.3 Dependency Confusion Attacks (2021)

**What happened**: Security researcher Alex Birsan demonstrated that by publishing packages with the same name as internal packages on public registries, attackers could trick package managers into downloading malicious code.

**Distroless prevention**: Distroless images would have prevented:

- Installation of malicious packages via package managers
- Execution of post-exploitation scripts
- Persistence mechanisms

### 3.4 Supply Chain Attacks (2021)

**What happened**: Multiple supply chain attacks affected npm, PyPI, and other package ecosystems.

**Distroless prevention**: Distroless images would have prevented:

- Installation of malicious packages
- Execution of compromised build scripts
- Runtime exploitation of vulnerable dependencies

### 3.5 Container Escape Attacks

**What happened**: Multiple container escape vulnerabilities were discovered in Docker and Kubernetes.

**Distroless prevention**: Distroless images would have:

- Reduced the tools available for exploitation
- Limited the attacker's ability to pivot
- Made post-exploitation more difficult

### 3.6 Cryptojacking Attacks

**What happened**: Attackers compromised container images to install cryptocurrency miners.

**Distroless prevention**: Distroless images would have prevented:

- Installation of mining software
- Execution of mining scripts
- Persistence of mining processes

---

## 4. Installation

### 4.1 Pulling Distroless Images

```bash
# Pull Java 17 Distroless
docker pull gcr.io/distroless/java17-debian12

# Pull Python 3 Distroless
docker pull gcr.io/distroless/python3-debian12

# Pull Node.js 18 Distroless
docker pull gcr.io/distroless/nodejs18-debian12

# Pull Static Distroless (for Go/Rust)
docker pull gcr.io/distroless/static-debian12

# Pull .NET Distroless
docker pull gcr.io/distroless/dotnet-debian12
```

### 4.2 Using with Docker

```bash
# Run a Java application
docker run --rm gcr.io/distroless/java17-debian12 -jar my-app.jar

# Run a Python application
docker run --rm gcr.io/distroless/python3-debian12 python my-app.py

# Run a static binary
docker run --rm gcr.io/distroless/static-debian12 /my-app
```

### 4.3 Using with Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: gcr.io/distroless/java17-debian12
        args: ["-jar", "/app/my-app.jar"]
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
```

### 4.4 Building Multi-Stage Dockerfiles

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o my-app

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/my-app /my-app
CMD ["/my-app"]
```

---

## 5. Configuration

### 5.1 Dockerfile Best Practices

```dockerfile
# Multi-stage build
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o my-app

# Runtime stage
FROM gcr.io/distroless/static-debian12

# Copy the binary
COPY --from=builder /app/my-app /my-app

# Copy configuration files
COPY --from=builder /app/config /config

# Set the user
USER nonroot:nonroot

# Set the entrypoint
ENTRYPOINT ["/my-app"]
```

### 5.2 Nonroot User

Distroless images include a `nonroot` user with UID 65532:

```dockerfile
# Use nonroot user
USER nonroot:nonroot

# Or specify UID/GID
USER 65532:65532
```

### 5.3 Read-Only Filesystem

```dockerfile
# Set read-only filesystem
RUN chmod -R 555 /app

# Or mount as read-only in Kubernetes
```

### 5.4 Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  runAsGroup: 65532
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
```

---

## 6. Core Concepts

### 6.1 Minimal Base

Distroless images are built on top of a minimal Debian base:

- **Debian 12 (Bookworm)**: Latest stable Debian release
- **Minimal packages**: Only essential runtime libraries
- **No package managers**: Cannot install additional software
- **No shells**: Cannot execute arbitrary commands

### 6.2 Language Runtimes

Distroless images include specific language runtimes:

- **Java**: OpenJDK runtime
- **Python**: CPython interpreter
- **Node.js**: Node.js runtime
- **.NET**: .NET runtime
- **Go/Rust**: Static binaries (no runtime needed)

### 6.3 Nonroot User

Distroless images include a `nonroot` user:

- **UID**: 65532
- **GID**: 65532
- **Home**: /home/nonroot
- **Shell**: /usr/sbin/nologin (no login shell)

### 6.4 Debugging Images

Distroless provides debugging variants:

- **debug**: Includes a shell and basic utilities
- **busybox**: Includes BusyBox utilities

```bash
# Use debug variant for debugging
docker run --rm -it gcr.io/distroless/java17-debian12:debug

# Use busybox variant
docker run --rm -it gcr.io/distroless/java17-debian12:busybox
```

### 6.5 SBOM Support

Distroless images support SBOM generation:

```bash
# Generate SBOM for Distroless image
syft gcr.io/distroless/java17-debian12 -o cyclonedx-json=sbom.json

# Scan SBOM for vulnerabilities
grype sbom:sbom.json
```

---

## 7. Usage Guide

### 7.1 Java Applications

```dockerfile
# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Runtime stage
FROM gcr.io/distroless/java17-debian12
COPY --from=builder /app/target/my-app.jar /app/my-app.jar
ENTRYPOINT ["java", "-jar", "/app/my-app.jar"]
```

### 7.2 Python Applications

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --prefix=/install

# Runtime stage
FROM gcr.io/distroless/python3-debian12
COPY --from=builder /install /usr/local
COPY . /app
WORKDIR /app
CMD ["python", "main.py"]
```

### 7.3 Node.js Applications

```dockerfile
# Build stage
FROM node:18-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Runtime stage
FROM gcr.io/distroless/nodejs18-debian12
COPY --from=builder /app /app
WORKDIR /app
CMD ["server.js"]
```

### 7.4 Go Applications

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o my-app

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/my-app /my-app
ENTRYPOINT ["/my-app"]
```

### 7.5 Rust Applications

```dockerfile
# Build stage
FROM rust:1.75 AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
COPY src ./src
RUN cargo build --release

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/target/release/my-app /my-app
ENTRYPOINT ["/my-app"]
```

### 7.6 .NET Applications

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS builder
WORKDIR /app
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o out

# Runtime stage
FROM gcr.io/distroless/dotnet-debian12
COPY --from=builder /app/out /app
ENTRYPOINT ["dotnet", "/app/my-app.dll"]
```

### 7.7 Static Binaries

```dockerfile
# Build stage
FROM gcc:13 AS builder
WORKDIR /app
COPY main.c .
RUN gcc -static -o my-app main.c

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/my-app /my-app
ENTRYPOINT ["/my-app"]
```

### 7.8 Multi-Architecture Builds

```dockerfile
# Build stage
FROM --platform=$BUILDPLATFORM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o my-app

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/my-app /my-app
ENTRYPOINT ["/my-app"]
```

---

## 8. Custom Rules and Policies

### 8.1 Kyverno Policy for Distroless Images

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-distroless-images
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: check-distroless-image
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Images must use Distroless base"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "gcr.io/distroless/*|*.distroless.*"
  - name: check-nonroot-user
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Containers must run as nonroot"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 65532
  - name: check-read-only-rootfs
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Root filesystem must be read-only"
      pattern:
        spec:
          containers:
          - name: "*"
            securityContext:
              readOnlyRootFilesystem: true
```

### 8.2 OPA/Rego Policy for Distroless Images

```rego
# distroless-policy.rego
package main

default deny = false

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "gcr.io/distroless/")
    msg := sprintf("Image %s must use Distroless base", [container.image])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.runAsNonRoot != true
    msg := sprintf("Container %s must run as nonroot", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.readOnlyRootFilesystem != true
    msg := sprintf("Container %s must have read-only root filesystem", [container.name])
}
```

### 8.3 Trivy Custom Policy for Distroless

```rego
# trivy-distroless-policy.rego
package trivy

__rego_metadoc__ := {
    "id": "DS-001",
    "title": "Distroless image check",
    "severity": "CRITICAL",
    "description": "Ensure images use Distroless base"
}

deny[msg] {
    input.config_type == "Dockerfile"
    input.dockerfile[_].Cmd == "FROM"
    not startswith(input.dockerfile[_].Value[0], "gcr.io/distroless/")
    msg := "Image must use Distroless base"
}
```

### 8.4 Custom Security Policies

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: distroless-policies
  namespace: security
data:
  policy.yaml: |
    rules:
    - name: require-nonroot
      description: "Containers must run as nonroot"
      validation:
        pattern:
          spec:
            securityContext:
              runAsNonRoot: true
    - name: require-read-only-rootfs
      description: "Root filesystem must be read-only"
      validation:
        pattern:
          spec:
            containers:
            - securityContext:
                readOnlyRootFilesystem: true
    - name: drop-all-capabilities
      description: "Drop all capabilities"
      validation:
        pattern:
          spec:
            containers:
            - securityContext:
                capabilities:
                  drop:
                  - ALL
```

---

## 9. Integration

### 9.1 GitHub Actions

```yaml
# .github/workflows/distroless-build.yml
name: Distroless Build
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          platforms: linux/amd64,linux/arm64

      - name: Scan for vulnerabilities
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ghcr.io/${{ github.repository }}:${{ github.sha }}
          format: table
          exit-code: 1
          severity: CRITICAL,HIGH
```

### 9.2 GitLab CI/CD

```yaml
# .gitlab-ci.yml
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity CRITICAL,HIGH $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

### 9.3 Jenkins Pipeline

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
        stage('Scan') {
            steps {
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH my-app:${BUILD_NUMBER}'
            }
        }
        stage('Push') {
            steps {
                sh 'docker push my-app:${BUILD_NUMBER}'
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
    distroless.example.com/image-ref: my-app:latest
    distroless.example.com/verify: "true"
spec:
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
```

### 9.5 k3s with Distroless

```bash
# Deploy application with Distroless image
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: gcr.io/distroless/java17-debian12
        args: ["-jar", "/app/my-app.jar"]
        securityContext:
          runAsNonRoot: true
          runAsUser: 65532
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: app-config
          mountPath: /config
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: app-config
        configMap:
          name: my-app-config
      - name: tmp
        emptyDir: {}
EOF
```

### 9.6 Harbor Integration

```bash
# Configure Harbor to require Distroless images
# Harbor UI -> Projects -> Configuration -> Deployment Security

# Or via Harbor API
curl -X PUT "https://harbor.example.com/api/v2.0/projects/myproject" \
  -H "Authorization: Basic $(echo -n admin:password | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "enable_content_trust": "true",
      "prevent_vul": "true",
      "severity": "high"
    }
  }'
```

---

## 10. Security Hardening

### 10.1 Run as Nonroot

```dockerfile
# Use nonroot user
USER nonroot:nonroot
```

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  runAsGroup: 65532
```

### 10.2 Read-Only Filesystem

```dockerfile
# Set read-only filesystem
RUN chmod -R 555 /app
```

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

### 10.3 Drop All Capabilities

```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

### 10.4 Seccomp Profile

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

### 10.5 Resource Limits

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

### 10.6 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: distroless-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

### 10.7 RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: my-app
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-app
subjects:
- kind: ServiceAccount
  name: my-app
  namespace: production
roleRef:
  kind: ClusterRole
  name: my-app
  apiGroup: rbac.authorization.k8s.io
```

### 10.8 Secret Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: production
type: Opaque
data:
  api-key: <base64-encoded-api-key>
  db-password: <base64-encoded-db-password>
```

---

## 11. Troubleshooting

### 11.1 Issue: Cannot Execute Shell Commands

**Symptom**: `exec: "sh": executable file not found`

**Fix**:
```bash
# Use debug variant for debugging
docker run --rm -it gcr.io/distroless/java17-debian12:debug

# Or use busybox variant
docker run --rm -it gcr.io/distroless/java17-debian12:busybox
```

### 11.2 Issue: Permission Denied

**Symptom**: `permission denied` or `cannot create`

**Fix**:
```dockerfile
# Set correct permissions
RUN chmod -R 555 /app
RUN chown -R 65532:65532 /app

# Use nonroot user
USER nonroot:nonroot
```

### 11.3 Issue: Missing Dependencies

**Symptom**: `error while loading shared libraries` or `library not found`

**Fix**:
```dockerfile
# Copy required libraries
COPY --from=builder /lib/x86_64-linux-gnu/libfoo.so /lib/x86_64-linux-gnu/

# Or use static linking
RUN CGO_ENABLED=0 go build -o my-app
```

### 11.4 Issue: Application Cannot Write to Disk

**Symptom**: `read-only file system` or `permission denied`

**Fix**:
```yaml
# Add writable volumes
volumes:
- name: tmp
  mountPath: /tmp
- name: app-data
  mountPath: /app/data
```

### 11.5 Issue: Debugging Difficulties

**Symptom**: Cannot debug application issues

**Fix**:
```bash
# Use debug variant
docker run --rm -it gcr.io/distroless/java17-debian12:debug

# Or use busybox variant
docker run --rm -it gcr.io/distroless/java17-debian12:busybox

# Or copy debug tools
COPY --from=alpine /usr/bin/strace /usr/bin/strace
```

### 11.6 Issue: Application Crashes on Startup

**Symptom**: Application exits immediately

**Fix**:
```bash
# Check application logs
kubectl logs my-pod

# Use debug variant to check
docker run --rm -it gcr.io/distroless/java17-debian12:debug

# Check application configuration
docker run --rm -v /path/to/config:/config gcr.io/distroless/java17-debian12:debug cat /config/app.yaml
```

### 11.7 Issue: Cannot Install Packages

**Symptom**: `apt: command not found` or `apk: not found`

**Fix**:
```dockerfile
# Install packages in build stage
FROM golang:1.21 AS builder
RUN apt-get update && apt-get install -y libfoo-dev

# Copy required libraries
COPY --from=builder /lib/x86_64-linux-gnu/libfoo.so /lib/x86_64-linux-gnu/
```

### 11.8 Issue: Environment Variables Not Working

**Symptom**: Application cannot read environment variables

**Fix**:
```yaml
# Set environment variables
env:
- name: MY_VAR
  value: "my-value"

# Or use secrets
envFrom:
- secretRef:
    name: my-secret
```

### 11.9 Issue: Health Checks Failing

**Symptom**: Kubernetes health checks failing

**Fix**:
```yaml
# Use correct health check command
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 11.10 Issue: Application Cannot Connect to Database

**Symptom**: Database connection refused

**Fix**:
```yaml
# Check database service
kubectl get svc my-database

# Check network policies
kubectl get networkpolicies

# Use correct connection string
env:
- name: DATABASE_URL
  value: "postgresql://user:password@my-database:5432/mydb"
```

### 11.11 Issue: Application Cannot Resolve DNS

**Symptom**: `name resolution failed` or `dns: lookup failed`

**Fix**:
```yaml
# Check DNS configuration
kubectl get configmap kube-dns -n kube-system

# Use correct DNS settings
dnsPolicy: ClusterFirst
```

### 11.12 Issue: Application Cannot Access Filesystem

**Symptom**: `no such file or directory` or `permission denied`

**Fix**:
```yaml
# Mount required volumes
volumes:
- name: app-config
  configMap:
    name: my-app-config
- name: app-secrets
  secret:
    secretName: my-app-secrets

volumeMounts:
- name: app-config
  mountPath: /config
  readOnly: true
- name: app-secrets
  mountPath: /secrets
  readOnly: true
```

### 11.13 Issue: Application Cannot Use Network

**Symptom**: `connection refused` or `network unreachable`

**Fix**:
```yaml
# Check network policies
kubectl get networkpolicies

# Check service mesh configuration
kubectl get virtualservices -A
```

### 11.14 Issue: Application Cannot Use TLS

**Symptom**: `certificate signed by unknown authority` or `tls: handshake failure`

**Fix**:
```dockerfile
# Copy CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Or mount CA certificates
volumes:
- name: ca-certs
  mountPath: /etc/ssl/certs
  readOnly: true
```

### 11.15 Issue: Application Cannot Use Kubernetes API

**Symptom**: `forbidden` or `unable to load kubeconfig`

**Fix**:
```yaml
# Use service account
serviceAccountName: my-app

# Grant necessary permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-app
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
```

---

## 12. Tips and Best Practices

### 12.1 Use Multi-Stage Builds

Always use multi-stage builds to separate build and runtime stages.

### 12.2 Use Nonroot User

Always run containers as the nonroot user (UID 65532).

### 12.3 Use Read-Only Filesystem

Always use read-only root filesystem to prevent attackers from modifying the container.

### 12.4 Drop All Capabilities

Always drop all capabilities and only add back what's needed.

### 12.5 Use Debug Variants for Troubleshooting

Use debug variants when you need to debug application issues.

### 12.6 Use Static Binaries When Possible

Use static binaries (Go, Rust, C) for the smallest possible attack surface.

### 12.7 Use SBOM Generation

Generate SBOMs for all Distroless images for compliance and vulnerability tracking.

### 12.8 Use Image Scanning

Scan all Distroless images for vulnerabilities before deployment.

### 12.9 Use Image Signing

Sign all Distroless images to ensure integrity and authenticity.

### 12.10 Use Network Policies

Use network policies to restrict container communication.

### 12.11 Use Resource Limits

Always set resource limits to prevent resource exhaustion attacks.

### 12.12 Use Health Checks

Always implement health checks for production applications.

### 12.13 Use Secrets Management

Use Kubernetes secrets or external secret management for sensitive data.

### 12.14 Use RBAC

Use RBAC to restrict access to Kubernetes resources.

### 12.15 Monitor Applications

Monitor Distroless applications for security events and performance issues.

---

## 13. Command Reference

### 13.1 Docker Commands

| Command | Description |
|---|---|
| `docker pull gcr.io/distroless/static-debian12` | Pull static Distroless image |
| `docker pull gcr.io/distroless/java17-debian12` | Pull Java 17 Distroless image |
| `docker pull gcr.io/distroless/python3-debian12` | Pull Python 3 Distroless image |
| `docker pull gcr.io/distroless/nodejs18-debian12` | Pull Node.js 18 Distroless image |
| `docker run --rm gcr.io/distroless/static-debian12` | Run static binary |

### 13.2 Kubernetes Commands

| Command | Description |
|---|---|
| `kubectl get pods` | List pods |
| `kubectl logs my-pod` | Get pod logs |
| `kubectl describe pod my-pod` | Describe pod |
| `kubectl exec -it my-pod -- /bin/sh` | exec into pod (debug variant only) |

### 13.3 Security Commands

| Command | Description |
|---|---|
| `trivy image gcr.io/distroless/static-debian12` | Scan for vulnerabilities |
| `syft gcr.io/distroless/static-debian12` | Generate SBOM |
| `cosign verify --key cosign.pub gcr.io/distroless/static-debian12` | Verify signature |

---

## 14. Configuration Reference

### 14.1 Dockerfile Example

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o my-app

# Runtime stage
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/my-app /my-app
USER nonroot:nonroot
ENTRYPOINT ["/my-app"]
```

### 14.2 Kubernetes Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: gcr.io/distroless/static-debian12
        args: ["/my-app"]
        securityContext:
          runAsNonRoot: true
          runAsUser: 65532
          runAsGroup: 65532
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
          seccompProfile:
            type: RuntimeDefault
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: app-config
          mountPath: /config
          readOnly: true
      volumes:
      - name: tmp
        emptyDir: {}
      - name: app-config
        configMap:
          name: my-app-config
```

### 14.3 Network Policy Example

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

---

## 15. Real-World Examples

### 15.1 Contoso Pet Store - Distroless Migration

**Scenario**: Contoso Pet Store runs a microservices architecture on Kubernetes with 15 container images in production.

#### 15.1.1 Migration Strategy

```bash
#!/bin/bash
# migrate-to-distroless.sh

SERVICES=(
  "api-gateway"
  "product-service"
  "cart-service"
  "order-service"
  "user-service"
  "payment-service"
  "notification-service"
)

for service in "${SERVICES[@]}"; do
  echo "Migrating $service to Distroless..."

  # Build with Distroless
  docker build -t petstore/$service:distroless -f Dockerfile.distroless ./services/$service

  # Scan for vulnerabilities
  trivy image --severity CRITICAL,HIGH petstore/$service:distroless

  # Test
  docker run --rm petstore/$service:distroless

  # Push
  docker push petstore/$service:distroless

  echo "Migrated $service to Distroless"
done
```

#### 15.1.2 CI/CD Pipeline Integration

```yaml
name: Pet Store Distroless Build
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
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
        run: docker build -t petstore/${{ matrix.service }}:${{ github.sha }} -f Dockerfile.distroless ./services/${{ matrix.service }}

      - name: Scan for vulnerabilities
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: petstore/${{ matrix.service }}:${{ github.sha }}
          format: table
          exit-code: 1
          severity: CRITICAL,HIGH

      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: petstore/${{ matrix.service }}:${{ github.sha }}
          format: cyclonedx
          output-file: sbom-${{ matrix.service }}.cdx.json

      - name: Push image
        run: |
          docker tag petstore/${{ matrix.service }}:${{ github.sha }} petstore/${{ matrix.service }}:latest
          docker push petstore/${{ matrix.service }}:${{ github.sha }}
          docker push petstore/${{ matrix.service }}:latest
```

#### 15.1.3 Kubernetes Security Policies

```yaml
# petstore-distroless-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: petstore-distroless
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: require-distroless
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    validate:
      message: "Images must use Distroless base"
      pattern:
        spec:
          containers:
          - name: "*"
            image: "petstore/*:latest"
  - name: require-nonroot
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    validate:
      message: "Containers must run as nonroot"
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
            runAsUser: 65532
  - name: require-read-only-rootfs
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - petstore-production
          - petstore-staging
    validate:
      message: "Root filesystem must be read-only"
      pattern:
        spec:
          containers:
          - name: "*"
            securityContext:
              readOnlyRootFilesystem: true
```

---

## 16. Further Reading

### 16.1 Official Documentation

- [Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Distroless Documentation](https://github.com/GoogleContainerTools/distroless/blob/main/README.md)
- [Distroless Best Practices](https://github.com/GoogleContainerTools/distroless/blob/main/README.md#best-practices)
- [Distroless Security](https://github.com/GoogleContainerTools/distroless/blob/main/README.md#security)

### 16.2 Blog Posts and Tutorials

- [Getting Started with Distroless](https://github.com/GoogleContainerTools/distroless#getting-started)
- [Distroless vs Alpine: A Comparison](https://blog.google/products/containers/distroless-vs-alpine)
- [Distroless Security Best Practices](https://cloud.google.com/blog/products/containers-security/distroless-container-images)

### 16.3 Community Resources

- [Distroless GitHub](https://github.com/GoogleContainerTools/distroless)
- [Distroless Issues](https://github.com/GoogleContainerTools/distroless/issues)
- [Distroless Discussions](https://github.com/GoogleContainerTools/distroless/discussions)

### 16.4 Related Tools

- [Trivy](https://github.com/aquasecurity/trivy) - Vulnerability scanner
- [Syft](https://github.com/anchore/syft) - SBOM generation
- [Grype](https://github.com/anchore/grype) - Vulnerability scanner
- [Cosign](https://github.com/sigstore/cosign) - Image signing
- [Kyverno](https://kyverno.io/) - Policy engine

### 16.5 Standards and Specifications

- [CIS Benchmark](https://www.cisecurity.org/benchmark/kubernetes) - Kubernetes security benchmark
- [NIST SP 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final) - Application container security guide
- [PCI DSS](https://www.pcisecuritystandards.org/document_library/) - Payment card industry data security standard
- [HIPAA](https://www.hhs.gov/hipaa/index.html) - Health insurance portability and accountability act

---

*Last updated: September 2026*
*Distroless version: latest*
