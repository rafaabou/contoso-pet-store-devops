# BuildKit Complete Guide

## Table of Contents

1. [What Is BuildKit](#what-is-buildkit)
2. [Why Use BuildKit](#why-use-buildkit)
3. [Installation](#installation)
4. [Core Concepts](#core-concepts)
5. [Configuration](#configuration)
6. [Usage Guide (Step-by-Step)](#usage-guide)
7. [Custom Configuration](#custom-configuration)
8. [Integration](#integration)
9. [Security](#security)
10. [Troubleshooting](#troubleshooting)
11. [Tips & Best Practices](#tips--best-practices)
12. [Command Reference](#command-reference)
13. [Configuration Reference](#configuration-reference)
14. [Real-World Examples](#real-world-examples)
15. [Further Reading](#further-reading)

---

## What Is BuildKit

BuildKit is the next-generation build engine for Docker and container images. Developed by Docker and integrated into Docker Engine since version 23.0 (and as an optional feature before that), BuildKit replaces the legacy Docker build engine with a completely new architecture designed for performance, security, and flexibility.

BuildKit processes Dockerfiles using a directed acyclic graph (DAG) of build operations. Instead of executing Dockerfile instructions sequentially (as the legacy builder did), BuildKit analyzes the entire Dockerfile upfront, identifies independent operations that can run in parallel, and executes them concurrently. This parallelism dramatically reduces build times, especially for complex multi-stage Dockerfiles with independent stages.

Key architectural improvements include:

- **Parallel execution**: Independent build stages and instructions run concurrently
- **Incremental builds**: Only changed layers and their dependents are rebuilt
- **Cache mount**: Persistent caches survive across builds, dramatically speeding up package installation
- **Secret mounts**: Sensitive data can be used during build without being embedded in the final image
- **SSH mounts**: Forward SSH agent sockets for git clone operations without embedding credentials
- **Multi-platform builds**: Native support for building images for multiple architectures
- **Build secrets**: Build-time secrets that are never stored in the image or build cache
- **Flexible output**: Build images directly to a registry, local Docker, or export to tarballs

BuildKit also introduces a new Dockerfile syntax (`# syntax=docker/dockerfile:1`) that enables advanced features like inline caching, build secrets, and advanced mount types. The BuildKit frontend parses the Dockerfile and converts it into a build graph that the BuildKit daemon executes.

---

## Why Use BuildKit

**Dramatically Faster Builds**: Parallel execution of independent stages and cache mount can reduce build times by 50-90% for complex Dockerfiles.

**Improved Security**: Secrets are never stored in intermediate layers or the final image. BuildKit only adds content-addressable data to the image, making it impossible for secrets to leak through image layers.

**Better Caching**: The cache mount feature allows persistent caches for package managers (apt, npm, pip, cargo) that survive across builds without being part of the image layer.

**Multi-Platform Support**: Build images for multiple architectures (amd64, arm64, arm/v7, etc.) from a single build command, essential for ARM cloud instances and Apple Silicon development.

**Flexible Output**: Export images directly to registries, local Docker daemon, tar archives, or OCI image layouts. No need to load into Docker daemon first.

**Improved Developer Experience**: Better error messages, progress reporting, and build log output compared to the legacy builder.

**Dockerfile Frontend**: The new `# syntax=docker/dockerfile:1` directive enables features like heredocs, build checks, and automatic COPY --link optimization.

**Build Checks**: `docker buildx build --check` validates Dockerfiles for best practices and potential issues before building.

**Inline Caching**: Embed build cache metadata directly in images, enabling faster CI/CD builds by reusing layers from a registry.

**OCI Compliance**: BuildKit produces OCI-compliant images by default, ensuring compatibility with any OCI-compliant runtime.

---

## Installation

### Docker Desktop

BuildKit is included and enabled by default in Docker Desktop (version 2.0+).

```bash
# Verify BuildKit is available
docker buildx version
# BuildKit is integrated with buildx
```

### Docker Engine (Linux)

```bash
# Docker Engine 23.0+ has BuildKit as default
docker version
# If version is 23.0+, BuildKit is already enabled

# For older versions, enable BuildKit
export DOCKER_BUILDKIT=1

# Or permanently in /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  }
}
sudo systemctl restart docker
```

### Standalone BuildKit

```bash
# Install standalone BuildKit daemon
go install github.com/moby/buildkit/cmd/buildkitd@latest

# Or using Docker
docker pull moby/buildkit:latest

# Run standalone BuildKit
docker run -d --name buildkitd \
  -p 1234:1234 \
  moby/buildkit:latest \
  --addr tcp://0.0.0.0:1234
```

### BuildKit with Containerd

```bash
# For containerd-based setups
nerdctl build --use-buildkit
```

### Buildx Installation

```bash
# Docker Desktop includes buildx
# For Linux, install buildx
mkdir -p ~/.docker/cli-plugins
curl -sL https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-amd64 \
  -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

# Verify installation
docker buildx version
```

### Verify BuildKit is Enabled

```bash
# Check if BuildKit is the active builder
docker buildx ls

# Check BuildKit version
docker buildx version

# Test BuildKit is working
echo 'FROM alpine:3.19' > Dockerfile
docker buildx build -t test-buildkit .
```

### Install Buildx on Older Docker

```bash
# Download latest buildx binary
BUILDX_VERSION=v0.12.1
mkdir -p ~/.docker/cli-plugins
curl -sL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" \
  -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

# Verify
docker buildx version
```

---

## Core Concepts

### Build Graph

BuildKit constructs a directed acyclic graph (DAG) from the Dockerfile. Each instruction becomes a node in the graph, and dependencies between instructions are represented as edges. Independent operations run in parallel:

```dockerfile
# These stages can build in parallel:
FROM golang:1.21 AS builder1
# ... build service 1

FROM golang:1.21 AS builder2
# ... build service 2

# This stage depends on both:
FROM alpine:3.19
COPY --from=builder1 /app/service1 /usr/local/bin/
COPY --from=builder2 /app/service2 /usr/local/bin/
```

### Cache Mount

The `--mount=type=cache` instruction provides persistent caches that survive across builds:

```dockerfile
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y curl

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

RUN --mount=type=cache,target=/root/.cargo/registry \
    cargo build --release
```

### Secret Mount

The `--mount=type=secret` instruction provides access to secrets during build without embedding them in the image:

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install --production
```

```bash
docker buildx build --secret id=npmrc,src=$HOME/.npmrc .
```

### SSH Mount

The `--mount=type=ssh` instruction forwards the SSH agent socket for cloning private repositories:

```dockerfile
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git
```

```bash
# Forward SSH agent
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
docker buildx build --ssh default .
```

### Multi-Platform Builds

BuildKit supports building for multiple architectures simultaneously:

```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t myapp:latest \
  --push .
```

### Build Secrets

BuildKit provides secure secret handling:

```bash
# From files
docker buildx build --secret id=db_password,src=./db_password.txt .

# From environment variables
docker buildx build --secret id=api_key,env=API_KEY .

# From file with custom ID
docker buildx build --secret id=npmrc,src=$HOME/.npmrc .
```

### Inline Caching

Embed cache metadata directly in images for faster CI/CD builds:

```bash
# Export cache to registry
docker buildx build \
  --cache-to type=registry,ref=myregistry/myapp:cache \
  --cache-from type=registry,ref=myregistry/myapp:cache \
  -t myapp:latest \
  --push .
```

### Build Outputs

BuildKit supports multiple output formats:

```bash
# Output to Docker daemon (default)
docker buildx build -t myapp .

# Output to registry
docker buildx build --push -t registry/myapp:latest .

# Output to tarball
docker buildx build --output type=tar,dest=image.tar .

# Output to OCI layout
docker buildx build --output type=oci,dest=image.tar .

# Output to local directory
docker buildx build --output type=local,dest=./output .
```

---

## Configuration

### Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  },
  "buildkitd-config": "/etc/buildkit/buildkitd.toml"
}
```

### BuildKit Daemon Configuration

```toml
# /etc/buildkit/buildkitd.toml

# Worker configuration
[worker.oci]
  enabled = true
  snapshotter = "overlayfs"
  rootless = false

# Registry mirrors
[registry."docker.io"]
  mirrors = ["mirror.gcr.io"]

# Build cache configuration
[cache."s3"]
  bucket = "buildkit-cache"
  region = "us-east-1"

# Entitlements
[entitlements]
  allow = ["network.host"]
```

### Buildx Builder Configuration

```bash
# Create a builder with specific configuration
docker buildx create \
  --name mybuilder \
  --driver docker-container \
  --driver-opt network=host \
  --config /etc/buildkit/buildkitd.toml

# Use the builder
docker buildx use mybuilder

# Inspect builder
docker buildx inspect mybuilder
```

### Docker Buildx Bake

```hcl
# bake.hcl
variable "REGISTRY" {
  default = "docker.io"
}

variable "TAG" {
  default = "latest"
}

target "app" {
  dockerfile = "Dockerfile"
  context = "."
  tags = ["${REGISTRY}/myapp:${TAG}"]
  cache-from = ["type=registry,ref=${REGISTRY}/myapp:cache"]
  cache-to = ["type=registry,ref=${REGISTRY}/myapp:cache,mode=max"]
}

target "test" {
  dockerfile = "Dockerfile.test"
  context = "."
  target = "test"
}
```

### Buildx Bake with Compose

```yaml
# docker-bake.override.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - type=registry,ref=docker.io/myorg/app:cache
      cache_to:
        - type=registry,ref=docker.io/myorg/app:cache,mode=max
```

### Build Context Configuration

```dockerfile
# .dockerignore
.git
node_modules
*.md
.env
.dockerignore
Dockerfile
```

```bash
# Use specific build context
docker buildx build -f Dockerfile.prod .

# Use named context
docker buildx build --build-context node_modules=./dist/node_modules .
```

### Multi-Stage Build Configuration

```dockerfile
# syntax=docker/dockerfile:1

# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --production
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## Usage Guide

### Step 1: Basic Build with BuildKit

```bash
# Enable BuildKit (if not default)
export DOCKER_BUILDKIT=1

# Basic build
docker build -t myapp .

# Or using buildx
docker buildx build -t myapp .
```

### Step 2: Multi-Stage Build

```dockerfile
# Dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/server /usr/local/bin/server
CMD ["server"]
```

```bash
docker buildx build -t myapp .
```

### Step 3: Cache Mount for Package Managers

```dockerfile
FROM node:20-alpine
WORKDIR /app

# Cache npm downloads
RUN --mount=type=cache,target=/root/.npm \
    npm install --production

COPY . .
CMD ["node", "index.js"]
```

```bash
docker buildx build -t myapp .
```

### Step 4: Build Secrets

```dockerfile
FROM node:20-alpine
WORKDIR /app

# Use secret for .npmrc
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install --production

COPY . .
CMD ["node", "index.js"]
```

```bash
# Create .npmrc with auth token
echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" > .npmrc

# Build with secret
docker buildx build \
  --secret id=npmrc,src=.npmrc \
  -t myapp .

# Clean up
rm .npmrc
```

### Step 5: SSH Mount for Private Repos

```dockerfile
FROM golang:1.21-alpine
WORKDIR /app

# Clone private repo using SSH
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git .

RUN go build -o /app/server
CMD ["server"]
```

```bash
# Ensure SSH agent is running
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

# Build with SSH
docker buildx build --ssh default -t myapp .
```

### Step 6: Multi-Platform Build

```bash
# Create a builder with QEMU support
docker buildx create \
  --name multiarch \
  --driver docker-container \
  --use

# Install QEMU for cross-platform
docker run --privileged --rm tonistiigi/binfmt --install all

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myregistry/myapp:latest \
  --push .
```

### Step 7: Inline Caching

```bash
# Build and push with cache
docker buildx build \
  --cache-to type=registry,ref=myregistry/myapp:cache \
  --cache-from type=registry,ref=myregistry/myapp:cache \
  -t myregistry/myapp:latest \
  --push .

# Subsequent builds will use the cache
docker buildx build \
  --cache-from type=registry,ref=myregistry/myapp:cache \
  -t myregistry/myapp:latest \
  --push .
```

### Step 8: Build Checks

```bash
# Validate Dockerfile
docker buildx build --check .

# Check with specific configuration
docker buildx build --check \
  --check-buildinfo=false \
  --check-image=false \
  .
```

### Step 9: Named Build Contexts

```bash
# Use named contexts
docker buildx build \
  --build-context node_modules=./dist/node_modules \
  --build-context configs=./configs \
  -t myapp .

# In Dockerfile:
# FROM alpine
# COPY --from=node_modules /app/node_modules .
# COPY --from=configs /app/configs .
```

### Step 10: Build with Bake

```bash
# Define build targets in bake.hcl
cat > bake.hcl << 'EOF'
target "app" {
  dockerfile = "Dockerfile"
  tags = ["myapp:latest"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}
EOF

# Build using bake
docker buildx bake

# Or specific target
docker buildx bake app
```

### Step 11: Export to Tarball

```bash
# Export image to tarball
docker buildx build \
  --output type=tar,dest=image.tar \
  -t myapp .

# Or export OCI layout
docker buildx build \
  --output type=oci,dest=image.tar \
  -t myapp .
```

### Step 12: Build with Specific Cache Backend

```bash
# Local cache
docker buildx build \
  --cache-to type=local,dest=/tmp/buildcache \
  --cache-from type=local,src=/tmp/buildcache \
  -t myapp .

# GitHub Actions cache
docker buildx build \
  --cache-to type=gha \
  --cache-from type=gha \
  -t myapp .

# Registry cache
docker buildx build \
  --cache-to type=registry,ref=myregistry/cache:latest \
  --cache-from type=registry,ref=myregistry/cache:latest \
  -t myapp .
```

### Step 13: Progressive Disclosure

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine

# Progressive disclosure of features
# https://docs.docker.com/engine/reference/builder/#syntax

RUN --mount=type=cache,target=/root/.npm \
    npm install
```

### Step 14: Build with Entitlements

```bash
# Allow network access during build
docker buildx build \
  --allow network.host \
  -t myapp .

# Allow security.insecure
docker buildx build \
  --allow security.insecure \
  -t myapp .
```

### Step 15: Debug Build

```bash
# Build with progress output
docker buildx build --progress=plain -t myapp .

# Build with debug output
docker buildx build --progress=plain --no-cache -t myapp .

# Check build cache
docker buildx du

# List build history
docker buildx history ls
```

---

## Custom Configuration

### Custom BuildKit Daemon

```toml
# /etc/buildkit/buildkitd.toml

[worker.oci]
  enabled = true
  snapshotter = "overlayfs"
  rootless = false
  max-parallelism = 4

[worker.containerd]
  enabled = true
  namespace = "buildkit"

[registry."docker.io"]
  mirrors = ["mirror.gcr.io"]
  http = false
  insecure = false

[registry."myregistry.local"]
  http = true
  insecure = true

[cache."s3"]
  bucket = "buildkit-cache"
  region = "us-east-1"
  access_key_id = "${AWS_ACCESS_KEY_ID}"
  secret_access_key = "${AWS_SECRET_ACCESS_KEY}"

[cache."local"]
  dir = "/var/cache/buildkit"

[entitlements]
  allow = ["network.host", "security.insecure"]
```

### Custom Buildx Builder

```bash
# Create builder with custom configuration
docker buildx create \
  --name custom-builder \
  --driver docker-container \
  --driver-opt network=host \
  --config /etc/buildkit/buildkitd.toml \
  --platform linux/amd64,linux/arm64 \
  --buildkitd-flags '--debug'

# Use the builder
docker buildx use custom-builder

# Inspect
docker buildx inspect
```

### Custom Bake Configuration

```hcl
# bake.hcl
variable "DOCKER_REGISTRY" {
  default = "docker.io"
}

variable "IMAGE_NAME" {
  default = "myapp"
}

variable "TAG" {
  default = "latest"
}

target "app" {
  dockerfile = "Dockerfile"
  context = "."
  tags = [
    "${DOCKER_REGISTRY}/${IMAGE_NAME}:${TAG}",
    "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
  ]
  cache-from = [
    "type=registry,ref=${DOCKER_REGISTRY}/${IMAGE_NAME}:cache"
  ]
  cache-to = [
    "type=registry,ref=${DOCKER_REGISTRY}/${IMAGE_NAME}:cache,mode=max"
  ]
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
}

target "test" {
  dockerfile = "Dockerfile.test"
  context = "."
  target = "test"
  cache-from = [
    "type=registry,ref=${DOCKER_REGISTRY}/${IMAGE_NAME}:test-cache"
  ]
}

target "lint" {
  dockerfile = "Dockerfile.lint"
  context = "."
  target = "lint"
}
```

### Custom .dockerignore

```dockerignore
# Version control
.git
.gitignore

# Dependencies
node_modules
vendor
vendor/**/*

# Build artifacts
dist
build
output

# Documentation
*.md
docs
LICENSE

# Configuration
.env
.env.*
docker-compose*.yml
Dockerfile*

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Test
coverage
.nyc_output
*.test.js
```

---

## Integration

### BuildKit + Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - type=registry,ref=docker.io/myorg/app:cache
      cache_to:
        - type=registry,ref=docker.io/myorg/app:cache,mode=max
    ports:
      - "3000:3000"
```

```bash
docker compose build
```

### BuildKit + GitHub Actions

```yaml
# .github/workflows/docker.yml
name: Docker Build

on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: myapp:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
```

### BuildKit + GitLab CI

```yaml
# .gitlab-ci.yml
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker buildx create --use
    - docker buildx build --push -t registry.example.com/myapp:$CI_COMMIT_SHA .
```

### BuildKit + Kubernetes

```yaml
# k8s-buildkit.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: buildkitd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: buildkitd
  template:
    metadata:
      labels:
        app: buildkitd
    spec:
      containers:
        - name: buildkitd
          image: moby/buildkit:latest
          ports:
            - containerPort: 1234
          volumeMounts:
            - name: cache
              mountPath: /var/lib/buildkit
      volumes:
        - name: cache
          persistentVolumeClaim:
            claimName: buildkit-cache
```

### BuildKit + Registry Mirrors

```json
// /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  },
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://registry.docker-cn.com"
  ]
}
```

### BuildKit + CI/CD Pipeline

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD

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
      
      - name: Cache Docker layers
        uses: actions/cache@v4
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: myapp:${{ github.sha }}
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max
      
      - name: Move cache
        run: |
          rm -rf /tmp/.buildx-cache
          mv /tmp/.buildx-cache-new /tmp/.buildx-cache
```

---

## Security

### Build Secrets

```dockerfile
# Never hardcode secrets in Dockerfiles
# Use secret mounts instead

FROM node:20-alpine
WORKDIR /app

# Use secret for npm authentication
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install --production

# Use secret for SSH key
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git .

# Use secret for API key
RUN --mount=type=secret,id=api_key,target=/run/secrets/api_key \
    curl -H "Authorization: Bearer $(cat /run/secrets/api_key)" https://api.example.com
```

```bash
# Pass secrets at build time
docker buildx build \
  --secret id=npmrc,src=$HOME/.npmrc \
  --secret id=api_key,env=API_KEY \
  --ssh default \
  -t myapp .
```

### Secure Build Context

```bash
# Use .dockerignore to exclude sensitive files
echo -e ".env\n.git\n*.key\n*.pem" > .dockerignore

# Use specific build context
docker buildx build -f Dockerfile.prod .

# Use named contexts for controlled access
docker buildx build --build-context app=./safe-context .
```

### Entitlements

```bash
# Allow specific capabilities
docker buildx build \
  --allow network.host \
  --allow security.insecure \
  -t myapp .

# In Dockerfile, entitlements are requested
# syntax=docker/dockerfile:1
FROM alpine
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update  # Requires cache entitlement
```

### Non-Root Build

```dockerfile
# Use non-root user for build
FROM node:20-alpine AS builder
RUN addgroup -g 1001 -S appgroup
RUN adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --chown=appuser:appgroup . .
RUN npm ci --production

# Production stage
FROM node:20-alpine
RUN addgroup -g 1001 -S appgroup
RUN adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app .
USER appuser
CMD ["node", "index.js"]
```

### Cache Security

```bash
# Use registry-based cache for better security
docker buildx build \
  --cache-to type=registry,ref=myregistry/cache:latest \
  --cache-from type=registry,ref=myregistry/cache:latest \
  -t myapp .

# Avoid local cache on shared systems
docker buildx build \
  --cache-to type=inline \
  -t myapp .
```

---

## Troubleshooting

### Issue 1: BuildKit Not Enabled

**Symptom**: `WARNING: No limit specified for max-parallelism. Using default limits.`

**Solution**: Enable BuildKit explicitly:
```bash
export DOCKER_BUILDKIT=1
# Or in /etc/docker/daemon.json
{
  "features": {
    "buildkit": true
  }
}
sudo systemctl restart docker
```

### Issue 2: Cache Mount Not Working

**Symptom**: `--mount=type=cache` not speeding up builds

**Solution**: Ensure you're using BuildKit (not legacy builder) and the cache mount path is correct:
```bash
docker buildx build -t myapp .  # Use buildx, not docker build
```

### Issue 3: Multi-Platform Build Fails

**Symptom**: `exec format error` on non-native platforms

**Solution**: Install QEMU for cross-platform emulation:
```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name multiarch --driver docker-container --use
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .
```

### Issue 4: Secret Mount Fails

**Symptom**: `secret not found` error

**Solution**: Ensure the secret is passed correctly:
```bash
docker buildx build --secret id=mysecret,src=./secret.txt -t myapp .
```

### Issue 5: SSH Mount Fails

**Symptom**: `ssh-agent` not available in build

**Solution**: Forward the SSH agent properly:
```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
docker buildx build --ssh default -t myapp .
```

### Issue 6: Inline Cache Not Working

**Symptom**: Cache not being reused between builds

**Solution**: Ensure `--push` is used (inline cache requires pushing to registry):
```bash
docker buildx build \
  --cache-to type=inline \
  -t myregistry/myapp:latest \
  --push .
```

### Issue 7: Build Context Too Large

**Symptom**: `context canceled` or slow builds

**Solution**: Use `.dockerignore` to exclude unnecessary files:
```bash
echo -e ".git\nnode_modules\ndist\n*.md" > .dockerignore
```

### Issue 8: Error Loading Module

**Symptom**: `module not found` in Go or Python builds

**Solution**: Use cache mount for module downloads:
```dockerfile
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
```

### Issue 9: Builder Not Found

**Symptom**: `no builder found` error

**Solution**: Create and use a builder:
```bash
docker buildx create --name mybuilder --driver docker-container --use
docker buildx inspect --bootstrap
```

### Issue 10: Privileged Container Required

**Symptom**: `permission denied` for QEMU or buildkitd

**Solution**: Run with `--privileged` or use rootless buildkit:
```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

### Issue 11: Buildkitd Crashes

**Symptom**: `buildkitd` container exits immediately

**Solution**: Check logs and ensure sufficient resources:
```bash
docker logs buildkitd
docker stats
# Ensure at least 2GB RAM and 2 CPU cores available
```

### Issue 12: Slow First Build

**Symptom**: First build takes much longer than expected

**Solution**: This is normal — BuildKit downloads images and creates layers. Subsequent builds will be faster due to caching.

### Issue 13: Cache Mount Fills Disk

**Symptom**: Disk space exhaustion from cache mounts

**Solution**: Use cache eviction or limit cache size:
```bash
docker buildx du  # Check cache size
docker system prune -a  # Clean up
```

### Issue 14: Build Fails with BuildKit But Works with Legacy

**Symptom**: Dockerfile works with `DOCKER_BUILDKIT=0` but fails with BuildKit

**Solution**: Check for BuildKit-specific syntax issues:
```bash
# Add BuildKit syntax directive
# syntax=docker/dockerfile:1
FROM alpine
```

### Issue 15: Registry Push Fails

**Symptom**: `unauthorized` or `denied` when pushing

**Solution**: Ensure you're logged in and have push permissions:
```bash
docker login
docker buildx build --push -t registry/myapp:latest .
```

### Issue 16: Network Access Denied During Build

**Symptom**: `network is unreachable` during build

**Solution**: Allow network access:
```bash
docker buildx build --allow network.host -t myapp .
# Or in Dockerfile
# syntax=docker/dockerfile:1
FROM alpine
RUN --network=host ping -c 1 google.com
```

### Issue 17: Buildkitd.toml Not Loading

**Symptom**: Configuration changes not applied

**Solution**: Ensure the config file path is correct and the daemon is restarted:
```bash
docker buildx create --config /etc/buildkit/buildkitd.toml --use
docker buildx inspect
```

### Issue 18: Multi-Stage Build Broken

**Symptom**: `COPY --from=builder` fails

**Solution**: Ensure the stage name matches exactly and the build succeeded:
```bash
docker buildx build --target builder -t myapp-builder .
docker buildx build --target production -t myapp .
```

### Issue 19: Platform Not Supported

**Symptom**: `platform not supported` error

**Solution**: Check available platforms:
```bash
docker buildx ls
# Or install QEMU
docker run --privileged --rm tonistiigi/binfmt --install all
```

### Issue 20: Cache Mode Incorrect

**Symptom**: Cache not working as expected

**Solution**: Use the correct cache mode:
```bash
# min mode: only cache final layers
docker buildx build --cache-to type=registry,ref=cache:latest,mode=min .

# max mode: cache all layers
docker buildx build --cache-to type=registry,ref=cache:latest,mode=max .
```

---

## Tips & Best Practices

### 1. Use Multi-Stage Builds

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o /app/server

FROM alpine:3.19
COPY --from=builder /app/server /usr/local/bin/
```

### 2. Leverage Cache Mount

```dockerfile
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y curl
```

### 3. Use Build Secrets

```dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install
```

### 4. Enable Inline Caching

```bash
docker buildx build \
  --cache-to type=inline \
  -t myapp:latest \
  --push .
```

### 5. Use Named Build Contexts

```bash
docker buildx build \
  --build-context node_modules=./node_modules \
  -t myapp .
```

### 6. Run Build Checks

```bash
docker buildx build --check .
```

### 7. Use .dockerignore

```dockerignore
.git
node_modules
dist
*.md
.env
```

### 8. Optimize Layer Caching

```dockerfile
# Copy dependency files first
COPY package*.json ./
RUN npm ci

# Copy application code last
COPY . .
```

### 9. Use Specific Base Image Tags

```dockerfile
# Instead of
FROM node

# Use
FROM node:20-alpine
```

### 10. Minimize Image Size

```dockerfile
# Use multi-stage build
FROM golang:1.21-alpine AS builder
RUN go build -o /app/server

FROM alpine:3.19
COPY --from=builder /app/server /usr/local/bin/
```

### 11. Use BuildKit Frontend

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-alpine
RUN --mount=type=cache,target=/root/.npm npm install
```

### 12. Clean Up Cache

```bash
docker buildx du  # Check cache size
docker system prune -a  # Clean up
```

### 13. Use Bake for Complex Builds

```hcl
# bake.hcl
target "app" {
  tags = ["myapp:latest"]
  cache-from = ["type=registry,ref=myregistry/cache:latest"]
}
```

### 14. Use Build Context Effectively

```bash
# Use specific context
docker buildx build -f Dockerfile.prod .

# Or use piped context
tar czf - . | docker buildx build -t myapp -
```

### 15. Monitor Build Performance

```bash
docker buildx build --progress=plain -t myapp .
# Check build times and layer sizes
```

### 16. Use Remote BuildKit

```bash
# Connect to remote BuildKit daemon
export BUILDKIT_HOST=tcp://buildkit.example.com:1234
docker buildx build -t myapp .
```

### 17. Use Build Context Exclusion

```dockerignore
# Exclude large files
node_modules
vendor
.git
*.tar.gz
*.zip
```

### 18. Optimize COPY Instructions

```dockerfile
# Instead of copying everything
COPY . .

# Copy specific files
COPY package*.json ./
COPY src/ ./src/
COPY tsconfig.json ./
```

### 19. Use Build Secrets for Credentials

```bash
# Never commit secrets to git
docker buildx build \
  --secret id=credentials,src=./credentials.json \
  -t myapp .
```

### 20. Use BuildKit with CI/CD

```yaml
# GitHub Actions example
- uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## Command Reference

### Docker Build Commands

```bash
# Basic build
docker build -t myapp .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t myapp .

# Build with build args
docker build --build-arg NODE_VERSION=20 -t myapp .

# Build without cache
docker build --no-cache -t myapp .

# Build with specific target
docker build --target builder -t myapp .

# Build with specific platform
docker build --platform linux/amd64 -t myapp .
```

### Docker Buildx Commands

```bash
# Build with BuildKit
docker buildx build -t myapp .

# Build and push
docker buildx build --push -t registry/myapp:latest .

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .

# Build with cache
docker buildx build \
  --cache-to type=registry,ref=cache:latest \
  --cache-from type=registry,ref=cache:latest \
  -t myapp .

# Build with secrets
docker buildx build --secret id=npmrc,src=.npmrc -t myapp .

# Build with SSH
docker buildx build --ssh default -t myapp .

# Build checks
docker buildx build --check .

# Build with named context
docker buildx build --build-context node_modules=./node_modules -t myapp .
```

### Docker Buildx Bake Commands

```bash
# Build all targets
docker buildx bake

# Build specific target
docker buildx bake app

# Build with variable
docker buildx bake TAG=v1.0

# Build with file
docker buildx bake -f bake.hcl

# Build with override
docker buildx bake -f docker-compose.override.yml
```

### Buildkitd Commands

```bash
# Run buildkitd
docker run -d --name buildkitd moby/buildkit:latest

# Check buildkitd status
docker logs buildkitd

# Connect to buildkitd
export BUILDKIT_HOST=tcp://localhost:1234
```

### Docker Buildx Builder Commands

```bash
# List builders
docker buildx ls

# Create builder
docker buildx create --name mybuilder

# Use builder
docker buildx use mybuilder

# Inspect builder
docker buildx inspect

# Remove builder
docker buildx rm mybuilder

# Bootstrap builder
docker buildx inspect --bootstrap
```

### Docker Buildx Cache Commands

```bash
# Check cache usage
docker buildx du

# Prune cache
docker buildx prune

# Prune all cache
docker buildx prune -a
```

---

## Configuration Reference

### BuildKit Daemon Configuration (buildkitd.toml)

```toml
# Worker configuration
[worker.oci]
  enabled = true
  snapshotter = "overlayfs"
  rootless = false
  max-parallelism = 4

[worker.containerd]
  enabled = true
  namespace = "buildkit"

# Registry configuration
[registry."docker.io"]
  mirrors = ["mirror.gcr.io"]
  http = false
  insecure = false

[registry."myregistry.local"]
  http = true
  insecure = true

# Cache configuration
[cache."s3"]
  bucket = "buildkit-cache"
  region = "us-east-1"
  access_key_id = "${AWS_ACCESS_KEY_ID}"
  secret_access_key = "${AWS_SECRET_ACCESS_KEY}"

[cache."local"]
  dir = "/var/cache/buildkit"

# Entitlements
[entitlements]
  allow = ["network.host", "security.insecure"]
```

### Bake Configuration (bake.hcl)

```hcl
variable "REGISTRY" {
  default = "docker.io"
}

variable "TAG" {
  default = "latest"
}

target "app" {
  dockerfile = "Dockerfile"
  context = "."
  tags = ["${REGISTRY}/myapp:${TAG}"]
  cache-from = ["type=registry,ref=${REGISTRY}/myapp:cache"]
  cache-to = ["type=registry,ref=${REGISTRY}/myapp:cache,mode=max"]
  args = {
    BUILDKIT_INLINE_CACHE = "1"
  }
}

target "test" {
  dockerfile = "Dockerfile.test"
  context = "."
  target = "test"
}
```

### Dockerfile Syntax Directives

```dockerfile
# syntax=docker/dockerfile:1

# Mount types
# --mount=type=cache,target=<path>
# --mount=type=secret,id=<id>,target=<path>
# --mount=type=ssh
# --mount=type=bind,source=<path>,target=<path>
# --mount=type=tmpfs,target=<path>

# Build checks
# --check
# --check-buildinfo
# --check-image
# --check-gateway

# Entitlements
# --allow network.host
# --allow security.insecure
```

### Output Types

```bash
# Output to Docker daemon
docker buildx build --output type=docker .

# Output to registry
docker buildx build --output type=registry .

# Output to tarball
docker buildx build --output type=tar,dest=image.tar .

# Output to OCI layout
docker buildx build --output type=oci,dest=image.tar .

# Output to local directory
docker buildx build --output type=local,dest=./output .
```

### Cache Types

```bash
# Local cache
docker buildx build --cache-to type=local,dest=/tmp/cache .

# Registry cache
docker buildx build --cache-to type=registry,ref=cache:latest .

# Inline cache
docker buildx build --cache-to type=inline .

# GitHub Actions cache
docker buildx build --cache-to type=gha .

# S3 cache
docker buildx build --cache-to type=s3,bucket=mybucket .
```

---

## Real-World Examples

### Example 1: Node.js Application

```dockerfile
# syntax=docker/dockerfile:1

FROM node:20-alpine AS builder
WORKDIR /app

# Cache dependencies
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

# Build application
COPY . .
RUN npm run build

# Production image
FROM node:20-alpine
WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

RUN --mount=type=cache,target=/root/.npm npm ci --production

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Example 2: Go Application

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.21-alpine AS builder
WORKDIR /app

# Cache Go modules
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Build application
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -o /app/server

# Production image
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/server /usr/local/bin/
EXPOSE 8080
CMD ["server"]
```

### Example 3: Python Application

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
WORKDIR /app

# Cache pip packages
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt

# Production image
FROM python:3.12-slim
WORKDIR /app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . .

EXPOSE 8000
CMD ["python", "app.py"]
```

### Example 4: Rust Application

```dockerfile
# syntax=docker/dockerfile:1

FROM rust:1.75-slim AS builder
WORKDIR /app

# Cache Cargo dependencies
COPY Cargo.toml Cargo.lock ./
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release

# Production image
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/myapp /usr/local/bin/
EXPOSE 8080
CMD ["myapp"]
```

### Example 5: Multi-Platform Build

```bash
# Create builder
docker buildx create --name multiarch --driver docker-container --use

# Install QEMU
docker run --privileged --rm tonistiigi/binfmt --install all

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t myregistry/myapp:latest \
  --push .
```

### Example 6: CI/CD with Cache

```yaml
# .github/workflows/docker.yml
name: Docker Build

on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: myapp:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
```

### Example 7: Private Registry with Secrets

```bash
# Build with registry credentials
docker buildx build \
  --secret id=npmrc,src=$HOME/.npmrc \
  --secret id=ssh_key,src=$HOME/.ssh/id_rsa \
  -t myregistry/myapp:latest \
  --push .
```

### Example 8: Export to OCI Layout

```bash
# Export image to OCI layout
docker buildx build \
  --output type=oci,dest=image.tar \
  -t myapp .

# Load OCI layout into Docker
docker load --input image.tar
```

---

## Further Reading

### Official Documentation
- [BuildKit Documentation](https://github.com/moby/buildkit)
- [Docker Buildx Documentation](https://docs.docker.com/build/buildx/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [BuildKit Frontend](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/reference.md)

### Related Tools
- [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action) — GitHub Action for Buildx
- [docker/build-push-action](https://github.com/docker/build-push-action) — GitHub Action for building
- [docker/login-action](https://github.com/docker/login-action) — GitHub Action for Docker login

### Community Resources
- [BuildKit Discussions](https://github.com/moby/buildkit/discussions)
- [Docker Community Forum](https://forums.docker.com/c/docker-community/46)
- [Stack Overflow — BuildKit](https://stackoverflow.com/questions/tagged/buildkit)

### Learning Resources
- [Docker Build Best Practices](https://docs.docker.com/build/building/best-practices/)
- [Multi-Platform Build Guide](https://docs.docker.com/build/building/multi-platform/)
- [BuildKit Cache Backends](https://docs.docker.com/build/cache/backends/)
- [Docker Build Secrets](https://docs.docker.com/build/building/secrets/)
