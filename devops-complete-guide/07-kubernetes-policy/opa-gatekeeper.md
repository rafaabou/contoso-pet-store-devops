# OPA Gatekeeper Complete Guide

## Table of Contents

1. [What Is OPA Gatekeeper](#what-is-opa-gatekeeper)
2. [Why Use OPA Gatekeeper](#why-use-opa-gatekeeper)
3. [Architecture Overview](#architecture-overview)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Core Concepts](#core-concepts)
7. [Usage Guide](#usage-guide)
8. [Custom Policies](#custom-policies)
9. [Integration](#integration)
10. [Security](#security)
11. [Troubleshooting](#troubleshooting)
12. [Tips and Best Practices](#tips-and-best-practices)
13. [Command Reference](#command-reference)
14. [CRD Reference](#crd-reference)
15. [Real-World Examples](#real-world-examples)
16. [Further Reading](#further-reading)

---

## What Is OPA Gatekeeper

OPA Gatekeeper is a policy engine for Kubernetes that combines Open Policy Agent (OPA) with Kubernetes admission control. It allows you to enforce custom policies on Kubernetes resources before they are persisted to the cluster, providing a flexible and powerful way to ensure compliance, security, and operational standards.

### Key Definitions

- **OPA (Open Policy Agent)**: A general-purpose policy engine that evaluates policies written in Rego
- **Gatekeeper**: The Kubernetes-native integration layer for OPA
- **Rego**: The policy language used by OPA to express rules
- **Constraint**: A CRD that enforces a policy on specific resources
- **ConstraintTemplate**: A CRD that defines reusable policy logic
- **Audit**: Background scanning of existing resources against policies

### How It Works

```
kubectl apply -f pod.yaml
        |
        v
[API Server] --> [Webhook] --> [Gatekeeper]
        |                          |
        v                          v
   [AdmissionReview]      [Evaluate Rego]
        |                          |
        v                          v
   [Allow/Deny]          [Constraint Results]
```

When a resource is created, updated, or deleted:
1. Kubernetes API server sends an AdmissionReview request to the Gatekeeper webhook
2. Gatekeeper evaluates the request against all applicable constraints
3. Each constraint runs its associated Rego policy
4. If any constraint fails, the request is denied
5. Results are returned to the API server

---

## Why Use OPA Gatekeeper

### Compliance Enforcement

- Enforce naming conventions across all resources
- Require specific labels or annotations
- Restrict container images to approved registries
- Enforce resource limits and requests
- Prevent privileged containers

### Security Hardening

- Block containers running as root
- Prevent hostPath mounts
- Require read-only root filesystems
- Enforce seccomp and AppArmor profiles
- Restrict capabilities

### Operational Excellence

- Ensure all deployments have health checks
- Require proper resource quotas
- Enforce namespace isolation
- Mandate backup labels
- Prevent undeletable resources

### Advantages Over Alternatives

| Feature | Gatekeeper | Kyverno | Pod Security |
|---------|-----------|---------|--------------|
| Policy Language | Rego | YAML/JSON | Built-in |
| Custom Policies | Full flexibility | Limited | None |
| Audit Mode | Yes | Yes | Yes |
| External Data | Yes | Limited | No |
| Ecosystem | Mature | Growing | Built-in |
| Learning Curve | Steep | Moderate | Low |

---

## Architecture Overview

### Component Diagram

```
+------------------------------------------+
|            Kubernetes API Server          |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|         Gatekeeper Webhook (HTTPS)        |
|  +------------------------------------+  |
|  |       Admission Controller          |  |
|  |   - MutatingWebhookConfiguration   |  |
|  |   - ValidatingWebhookConfiguration |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Gatekeeper Controller           |
|  +------------------------------------+  |
|  |       Reconciler (watcher)          |  |
|  |   - Watches ConstraintTemplates     |  |
|  |   - Watches Constraints             |  |
|  |   - Watches Audited Resources       |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           OPA Rego Engine                |
|  +------------------------------------+  |
|  |       Policy Evaluation             |  |
|  |   - Compile Rego policies           |  |
|  |   - Evaluate against resources      |  |
|  |   - Return deny/allow decisions     |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Constraint Cache               |
|  +------------------------------------+  |
|  |   Compiled policy cache             |  |
|  |   - Pre-compiled Rego               |  |
|  |   - Fast evaluation                 |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Webhook Flow

1. **Registration**: Gatekeeper registers ValidatingWebhookConfiguration and MutatingWebhookConfiguration
2. **Interception**: API server intercepts matching requests
3. **Evaluation**: Request sent to Gatekeeper pod
4. **Decision**: Allow or Deny returned

### Controller Flow

1. **Watch**: Controller watches ConstraintTemplates and Constraints
2. **Compile**: Compiles Rego policies from ConstraintTemplates
3. **Cache**: Stores compiled policies for fast evaluation
4. **Audit**: Periodically scans existing resources for violations

---

## Installation

### Prerequisites

- Kubernetes cluster v1.20+
- kubectl configured
- Helm v3
- Sufficient permissions (cluster-admin)
- Network access to Gatekeeper image registry

### Method 1: Helm Installation (Recommended)

```bash
# Add the Gatekeeper Helm repository
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

# Install Gatekeeper
helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --set replicas=3 \
  --set audit.replicas=1 \
  --set webhook.replicas=3 \
  --set audit.interval=60 \
  --set audit.chunkSize=500 \
  --set webhook.failurePolicy=Ignore \
  --set webhook.timeoutSeconds=3

# Verify installation
kubectl get pods -n gatekeeper-system
```

### Method 2: kubectl Installation

```bash
# Download the latest release
export GATEKEEPER_VERSION=$(curl -s https://api.github.com/repos/open-policy-agent/gatekeeper/releases/latest | grep -o '"tag_name":.*' | sed -E 's/.*"([^"]+)".*/\1/')

# Apply the manifest
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml

# Wait for pods to be ready
kubectl rollout status deployment/gatekeeper-audit -n gatekeeper-system
kubectl rollout status deployment/gatekeeper-controller -n gatekeeper-system
```

### Method 3: kustomize Installation

```bash
# Clone the repository
git clone https://github.com/open-policy-agent/gatekeeper.git
cd gatekeeper

# Apply with kustomize
kubectl apply -k config/

# Or with specific overlay
kubectl apply -k config/overlays/
```

### Method 4: From Source

```bash
# Clone the repository
git clone https://github.com/open-policy-agent/gatekeeper.git
cd gatekeeper

# Build and push
make docker-build docker-push IMG=your-registry/gatekeeper:latest

# Deploy
make deploy IMG=your-registry/gatekeeper:latest
```

### Verification

```bash
# Check pods
kubectl get pods -n gatekeeper-system

# Expected output
NAME                                            READY   STATUS    RESTARTS   AGE
gatekeeper-audit-xxxxx                          1/1     Running   0          5m
gatekeeper-controller-xxxxx                     1/1     Running   0          5m
gatekeeper-controller-xxxxx                     1/1     Running   0          5m

# Check webhook
kubectl get validatingwebhookconfigurations | grep gatekeeper
kubectl get mutatingwebhookconfigurations | grep gatekeeper

# Check CRDs
kubectl get crd | grep gatekeeper
```

---

## Configuration

### Global Configuration

```yaml
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: gatekeeper-system
spec:
  match:
    - kinds: ["Pod"]
      apiGroups: [""]
      namespaces: ["production", "staging"]
    - kinds: ["Deployment"]
      apiGroups: ["apps"]
      labelSelector:
        matchLabels:
          enforce: "true"
  sync:
    syncOnly:
      - kind: Namespace
        version: v1
      - kind: Pod
        version: v1
  audit:
    interval: 60
    chunkSize: 500
    limit: -1
    Matchers:
      - apiversion: v1
        kinds: ["Pod"]
      - apiversion: "apps/v1"
        kinds: ["Deployment"]
  trace:
    maxDepth: 5
    authorizedDebuggerport: 8888
```

### Webhook Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gatekeeper-webhook-config
  namespace: gatekeeper-system
data:
  webhook.yaml: |
    apiVersion: admissionregistration.k8s.io/v1
    kind: ValidatingWebhookConfiguration
    metadata:
      name: gatekeeper-validating-webhook
    webhooks:
      - name: validation.gatekeeper.sh
        admissionReviewVersions: ["v1", "v1beta1"]
        clientConfig:
          service:
            name: gatekeeper-webhook-service
            namespace: gatekeeper-system
            path: /v1/admit
        failurePolicy: Ignore
        sideEffects: None
        timeoutSeconds: 3
        rules:
          - apiGroups: ["*"]
            apiVersions: ["*"]
            operations: ["CREATE", "UPDATE"]
            resources: ["*"]
```

### Audit Configuration

```bash
# Configure audit interval
kubectl patch config config \
  -n gatekeeper-system \
  --type merge \
  -p '{"spec":{"audit":{"interval":"30s"}}}'

# Configure audit chunk size
kubectl patch config config \
  -n gatekeeper-system \
  --type merge \
  -p '{"spec":{"audit":{"chunkSize":100}}}'

# Enable audit for specific namespaces
kubectl patch config config \
  -n gatekeeper-system \
  --type merge \
  -p '{"spec":{"match":[{"kinds":["Pod"],"namespaces":["production"]}]}'
```

---

## Core Concepts

### Rego Language

Rego is OPA's policy language. Key concepts:

```rego
# Basic rule
deny[msg] {
  input.review.kind.kind == "Pod"
  container := input.review.object.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %v must have resource limits", [container.name])
}

# Violation (standard Gatekeeper pattern)
violation[{"msg": msg}] {
  input.review.kind.kind == "Pod"
  container := input.review.object.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %v must have resource limits", [container.name])
}
```

### ConstraintTemplates

Define reusable policy logic:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Missing required labels: %v", [missing])
        }
```

### Constraints

Apply policies to resources:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-team-label
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - production
  parameters:
    labels:
      - team
      - environment
```

### Audit Results

Check audit results:

```bash
# List all constraint violations
kubectl get constraints -o json | jq -r '.items[] | select(.status.totalViolations > 0) | "\(.metadata.name): \(.status.totalViolations) violations"'

# Get detailed violations
kubectl describe constraint require-team-label

# Get audit violations for specific constraint
kubectl get constraints require-team-label -o json | jq '.status.violations'
```

---

## Usage Guide

### Step 1: Install Gatekeeper

```bash
helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --set replicas=3
```

### Step 2: Create ConstraintTemplate

```yaml
# require-image-registry.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredimageregistry
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredImageRegistry
      validation:
        openAPIV3Schema:
          type: object
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredimageregistry

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not startswith(container.image, input.parameters.registries[_])
          msg := sprintf("Container %v image must be from approved registry", [container.name])
        }
```

### Step 3: Create Constraint

```yaml
# require-approved-registry.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredImageRegistry
metadata:
  name: require-approved-registry
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    registries:
      - "registry.k8s.io/"
      - "docker.io/library/"
```

### Step 4: Test Policy

```bash
# This should be denied
kubectl run nginx --image=nginx:latest

# This should be allowed
kubectl run nginx --image=registry.k8s.io/nginx:latest
```

### Step 5: Monitor Violations

```bash
# Check constraint status
kubectl get constraint require-approved-registry -o yaml

# Check audit results
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -c audit
```

---

## Custom Policies

### Require Labels

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: object
                properties:
                  key:
                    type: string
                  allowedRegex:
                    type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not has_required_labels(container)
          msg := sprintf("Container %v missing required labels", [container.name])
        }

        has_required_labels(obj) {
          labels := {key | obj.metadata.labels[key]}
          required := {key | key := input.parameters.labels[_].key}
          missing := required - labels
          count(missing) == 0
        }
```

### Resource Limits

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sresourcelimits
spec:
  crd:
    spec:
      names:
        kind: K8sResourceLimits
      validation:
        openAPIV3Schema:
          type: object
          properties:
            cpuLimit:
              type: string
            memoryLimit:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sresourcelimits

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := sprintf("Container %v must have CPU limits", [container.name])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container %v must have memory limits", [container.name])
        }
```

### Image Tag Restrictions

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8simagetag
spec:
  crd:
    spec:
      names:
        kind: K8sImageTag
      validation:
        openAPIV3Schema:
          type: object
          properties:
            tagPatterns:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8simagetag

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          image := container.image
          not matches_tag_pattern(image)
          msg := sprintf("Container %v image must follow tag pattern", [container.name])
        }

        matches_tag_pattern(image) {
          tag := split(image, ":")[1]
          pattern := input.parameters.tagPatterns[_]
          re_match(pattern, tag)
        }
```

---

## Integration

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: Policy Check
on: [pull_request]
jobs:
  gatekeeper:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
          chmod +x opa
          sudo mv opa /usr/local/bin/
      
      - name: Test Policies
        run: |
          opa test policy/ -v
      
      - name: Validate Manifests
        run: |
          for f in $(find . -name "*.yaml" -type f); do
            echo "Checking $f"
            opa eval --data policy/ --input $f "data.gatekeeper.violation" --format raw
          done
```

### ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gatekeeper-policies
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gatekeeper-policies.git
    targetRevision: HEAD
    path: policies
  destination:
    server: https://kubernetes.default.svc
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Prometheus Monitoring

```yaml
# ServiceMonitor for Gatekeeper
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gatekeeper
  namespace: gatekeeper-system
spec:
  selector:
    matchLabels:
      control-plane: controller-manager
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

### Grafana Dashboard

```json
{
  "panels": [
    {
      "title": "Gatekeeper Constraint Violations",
      "type": "graph",
      "targets": [
        {
          "expr": "gatekeeper_violations{enforcement_action=\"deny\"}",
          "legendFormat": "{{constraint_kind}}/{{constraint_name}}"
        }
      ]
    },
    {
      "title": "Gatekeeper Audit Duration",
      "type": "graph",
      "targets": [
        {
          "expr": "gatekeeper_audit_duration_seconds",
          "legendFormat": "{{operation}}"
        }
      ]
    }
  ]
}
```

---

## Security

### RBAC Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gatekeeper-manager-role
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["templates.gatekeeper.sh"]
    resources: ["constrainttemplates"]
    verbs: ["create", "update", "patch", "delete"]
  - apiGroups: ["constraints.gatekeeper.sh"]
    resources: ["*"]
    verbs: ["create", "update", "patch", "delete"]
  - apiGroups: ["config.gatekeeper.sh"]
    resources: ["configs"]
    verbs: ["create", "update", "patch", "delete"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gatekeeper-network-policy
  namespace: gatekeeper-system
spec:
  podSelector:
    matchLabels:
      control-plane: controller-manager
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: TCP
          port: 8443
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 6443
```

### Pod Security

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gatekeeper-pod
  namespace: gatekeeper-system
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: gatekeeper
      image: registry.k8s.io/gatekeeper/gatekeeper:v3.14.0
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
        readOnlyRootFilesystem: true
        runAsNonRoot: true
      resources:
        limits:
          cpu: "1"
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 256Mi
```

### TLS Configuration

```bash
# Generate certificates
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=gatekeeper-webhook-service.gatekeeper-system.svc"

# Create secret
kubectl create secret tls gatekeeper-webhook-server-cert \
  --cert=tls.crt \
  --key=tls.key \
  -n gatekeeper-system
```

---

## Troubleshooting

### Issue 1: Webhook Timeout

**Symptoms**: Requests taking too long, timeout errors
**Diagnosis**:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i timeout
kubectl get events --field-selector reason=WebhookTimeout
```
**Solution**:
- Increase webhook timeout: `--set webhook.timeoutSeconds=5`
- Check network latency between API server and Gatekeeper
- Verify DNS resolution

### Issue 2: Audit Not Working

**Symptoms**: No violations reported
**Diagnosis**:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -c audit | grep -i error
kubectl get config config -n gatekeeper-system -o yaml
```
**Solution**:
- Verify Config resource exists
- Check audit interval
- Ensure match criteria include target resources

### Issue 3: Constraint Template Compilation Error

**Symptoms**: ConstraintTemplate stuck in pending
**Diagnosis**:
```bash
kubectl get constrainttemplates
kubectl describe constrainttemplate <name>
```
**Solution**:
- Validate Rego syntax: `opa eval --data policy.rego "data.gatekeeper.violation"`
- Check CRD schema
- Review Gatekeeper logs

### Issue 4: High Memory Usage

**Symptoms**: Gatekeeper pods OOMKilled
**Diagnosis**:
```bash
kubectl top pods -n gatekeeper-system
kubectl describe pod <gatekeeper-pod> -n gatekeeper-system
```
**Solution**:
- Increase memory limits
- Reduce number of constraints
- Optimize Rego policies

### Issue 5: Webhook Certificates Expired

**Symptoms**: Connection refused errors
**Diagnosis**:
```bash
kubectl get secret gatekeeper-webhook-server-cert -n gatekeeper-system -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```
**Solution**:
- Renew certificates
- Restart Gatekeeper pods
- Verify cert rotation

### Issue 6: Namespace Exclusion Not Working

**Symptoms**: Policies applied to excluded namespaces
**Diagnosis**:
```bash
kubectl get constraints -o yaml | grep -A 10 "excludedNamespaces"
```
**Solution**:
- Check namespace labels
- Verify match criteria syntax
- Ensure excluded namespaces are correct

### Issue 7: Constraint Violations Not Appearing

**Symptoms**: No violations in constraint status
**Diagnosis**:
```bash
kubectl get constraints <name> -o jsonpath='{.status.violations}'
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i audit
```
**Solution**:
- Check enforcementAction (audit vs deny)
- Verify audit interval
- Ensure resources exist

### Issue 8: Webhook Connection Refused

**Symptoms**: API server cannot connect to webhook
**Diagnosis**:
```bash
kubectl get endpoints -n gatekeeper-system gatekeeper-webhook-service
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i webhook
```
**Solution**:
- Verify webhook service exists
- Check service selector labels
- Review network policies

### Issue 9: Rego Policy Not Evaluating

**Symptoms**: Policy exists but not enforced
**Diagnosis**:
```bash
kubectl get constraints <name> -o yaml
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i rego
```
**Solution**:
- Check constraint spec
- Verify match criteria
- Review Rego policy syntax

### Issue 10: Gatekeeper Pods Not Starting

**Symptoms**: Pods in CrashLoopBackOff
**Diagnosis**:
```bash
kubectl describe pod <gatekeeper-pod> -n gatekeeper-system
kubectl logs <gatekeeper-pod> -n gatekeeper-system
```
**Solution**:
- Check image availability
- Verify RBAC permissions
- Review resource limits

### Issue 11: Webhook Rejection Loop

**Symptoms**: Infinite rejection loop
**Diagnosis**:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i loop
```
**Solution**:
- Add exceptions for Gatekeeper resources
- Use failurePolicy: Ignore
- Configure webhook rules carefully

### Issue 12: Constraint Template Not Syncing

**Symptoms**: ConstraintTemplate not created
**Diagnosis**:
```bash
kubectl get constrainttemplates -o yaml | grep -A 10 status
```
**Solution**:
- Check controller logs
- Verify RBAC permissions
- Review CRD installation

### Issue 13: Audit Performance Issues

**Symptoms**: Audit taking too long
**Diagnosis**:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -c audit | grep -i duration
```
**Solution**:
- Increase chunk size
- Reduce audit interval
- Optimize match criteria

### Issue 14: Webhook Not Registering

**Symptoms**: Webhook not appearing in API server
**Diagnosis**:
```bash
kubectl get validatingwebhookconfigurations | grep gatekeeper
kubectl describe validatingwebhookconfiguration gatekeeper-validating-webhook
```
**Solution**:
- Verify webhook configuration
- Check service account permissions
- Review network policies

### Issue 15: Rego Compilation Error

**Symptoms**: ConstraintTemplate creation fails
**Diagnosis**:
```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager | grep -i compile
```
**Solution**:
- Validate Rego syntax
- Check for missing imports
- Review constraint template structure

---

## Tips and Best Practices

### 1. Start with Audit Mode

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-team-label
spec:
  enforcementAction: audit  # Start with audit, then switch to deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
```

### 2. Use Namespace Exclusions

```yaml
spec:
  match:
    excludedNamespaces:
      - kube-system
      - kube-public
      - gatekeeper-system
```

### 3. Optimize Rego Policies

```rego
# Use input.review.object for efficiency
violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  msg := "message"
}

# Avoid unnecessary loops
violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  container.resources.limits.cpu
  # Don't loop if not needed
}
```

### 4. Use Chunk Size for Large Clusters

```bash
kubectl patch config config -n gatekeeper-system \
  --type merge \
  -p '{"spec":{"audit":{"chunkSize":500}}}'
```

### 5. Monitor Gatekeeper Metrics

```yaml
# Enable Prometheus metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gatekeeper
spec:
  endpoints:
    - port: metrics
      path: /metrics
```

### 6. Use GitOps for Policy Management

```bash
# Store policies in Git
git add policies/
git commit -m "Update gatekeeper policies"
git push origin main

# Apply with ArgoCD or Flux
```

### 7. Test Policies Locally

```bash
# Test with OPA
opa eval --data policy.rego --input test.json "data.gatekeeper.violation"

# Run tests
opa test policy/ -v
```

### 8. Use Labels for Policy Selection

```yaml
spec:
  match:
    labelSelector:
      matchLabels:
        enforce: "true"
```

### 9. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
kubectl apply -f constraint-audit.yaml

# Phase 2: Warn mode
kubectl apply -f constraint-warn.yaml

# Phase 3: Deny mode
kubectl apply -f constraint-deny.yaml
```

### 10. Use External Data

```rego
# Fetch data from external source
import future.keywords.in

get_data(url) = data {
  http.send({
    "method": "get",
    "url": url,
    "headers": {"Authorization": "Bearer " + token}
  })
}
```

### 11. Implement Caching

```yaml
spec:
  sync:
    syncOnly:
      - kind: Namespace
        version: v1
      - kind: ConfigMap
        version: v1
```

### 12. Use Webhook Timeout Appropriately

```yaml
# For complex policies
webhook:
  timeoutSeconds: 5

# For simple policies
webhook:
  timeoutSeconds: 3
```

### 13. Implement Audit Chunking

```bash
# For large clusters
kubectl patch config config -n gatekeeper-system \
  --type merge \
  -p '{"spec":{"audit":{"chunkSize":1000}}}'
```

### 14. Use Namespace Isolation

```yaml
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaceSelector:
      matchLabels:
        environment: production
```

### 15. Implement Policy Testing Framework

```bash
#!/bin/bash
# test-policies.sh

# Test 1: Valid resource
kubectl apply -f valid-pod.yaml
# Expect: allowed

# Test 2: Invalid resource
kubectl apply -f invalid-pod.yaml
# Expect: denied

# Test 3: Audit violations
kubectl get constraints -o json | jq '.items[].status.totalViolations'
# Expect: violations > 0
```

---

## Command Reference

### kubectl Commands

```bash
# Get Gatekeeper pods
kubectl get pods -n gatekeeper-system

# Get constraints
kubectl get constraints

# Get constraint templates
kubectl get constrainttemplates

# Describe constraint
kubectl describe constraint <name>

# Get Gatekeeper logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager

# Get audit logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -c audit

# Get webhook logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -c webhook

# Restart Gatekeeper
kubectl rollout restart deployment/gatekeeper-controller -n gatekeeper-system

# Check webhook configuration
kubectl get validatingwebhookconfigurations | grep gatekeeper
kubectl get mutatingwebhookconfigurations | grep gatekeeper

# Check Gatekeeper config
kubectl get config config -n gatekeeper-system -o yaml
```

### OPA Commands

```bash
# Evaluate policy
opa eval --data policy.rego --input input.json "data.gatekeeper.violation"

# Run tests
opa test policy/ -v

# Format Rego
opa fmt policy.rego

# Check syntax
opa check policy.rego

# Build policy
opa build policy/ -o bundle.tar.gz
```

### Helm Commands

```bash
# Install Gatekeeper
helm install gatekeeper gatekeeper/gatekeeper -n gatekeeper-system --create-namespace

# Upgrade Gatekeeper
helm upgrade gatekeeper gatekeeper/gatekeeper -n gatekeeper-system

# Uninstall Gatekeeper
helm uninstall gatekeeper -n gatekeeper-system

# List releases
helm list -n gatekeeper-system

# Show values
helm show values gatekeeper/gatekeeper
```

### Docker Commands

```bash
# Build Gatekeeper
docker build -t gatekeeper:latest .

# Run Gatekeeper
docker run -p 8443:8443 gatekeeper:latest

# Push to registry
docker push registry.example.com/gatekeeper:latest
```

---

## CRD Reference

### ConstraintTemplate

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          msg := "test"
        }
```

### Constraint

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-team-label
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    labels:
      - team
```

### Config

```yaml
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: gatekeeper-system
spec:
  match:
    - kinds:
        - Pod
      apiGroups:
        - ""
  sync:
    syncOnly:
      - kind: Namespace
        version: v1
```

---

## Real-World Examples

### Production Cluster Policies

```yaml
# require-production-labels.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sproductionlabels
spec:
  crd:
    spec:
      names:
        kind: K8sProductionLabels
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sproductionlabels
        violation[{"msg": msg}] {
          input.review.object.metadata.labels.environment != "production"
          msg := "All resources must have environment=production label"
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sProductionLabels
metadata:
  name: production-label-required
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet"]
    namespaces:
      - production
```

### Image Security

```yaml
# block-latest-tag.yaml
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
          msg := sprintf("Container %s uses latest tag", [container.name])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBlockLatestTag
metadata:
  name: block-latest-tag
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
```

### Resource Quotas

```yaml
# require-resource-limits.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequireresourcelimits
spec:
  crd:
    spec:
      names:
        kind: K8sRequireResourceLimits
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequireresourcelimits
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits
          msg := sprintf("Container %s must have resource limits", [container.name])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireResourceLimits
metadata:
  name: require-resource-limits
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
```

---

## Further Reading

### Official Documentation

- [Gatekeeper Website](https://open-policy-agent.github.io/gatekeeper/)
- [Gatekeeper GitHub](https://github.com/open-policy-agent/gatekeeper)
- [OPA Documentation](https://www.openpolicyagent.org/docs/)
- [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)

### Community Resources

- [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library)
- [OPA Best Practices](https://www.openpolicyagent.org/docs/latest/security/)
- [Kubernetes Policy](https://kubernetes.io/docs/concepts/security/)

### Books and Tutorials

- "Policy-Based Control for Kubernetes" by OPA
- "Gatekeeper Best Practices" by CNCF
- "Rego Programming" by OPA

### Videos and Talks

- "Gatekeeper Deep Dive" by CNCF
- "OPA in Kubernetes" by KubeCon
- "Policy Enforcement Patterns" by ThoughtWorks

### Related Projects

- [Kyverno](https://kyverno.io/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
