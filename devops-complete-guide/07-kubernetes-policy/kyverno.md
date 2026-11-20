# Kyverno Complete Guide

## Table of Contents

1. [What Is Kyverno](#what-is-kyverno)
2. [Why Use Kyverno](#why-use-kyverno)
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

## What Is Kyverno

Kyverno is a policy engine designed for Kubernetes. It allows you to validate, mutate, and generate Kubernetes resources using policies written in YAML or JSON, without requiring knowledge of a separate policy language like Rego.

### Key Features

- **Kubernetes-native**: Policies are Kubernetes resources
- **YAML-based**: No need to learn Rego
- **Validate, Mutate, Generate**: Full lifecycle policy enforcement
- **Audit and Enforce**: Background scanning and real-time enforcement
- **Report Generation**: Detailed violation reports
- **Policy Reports**: Standardized reporting format

### How It Works

```
kubectl apply -f pod.yaml
        |
        v
[API Server] --> [Webhook] --> [Kyverno]
        |                          |
        v                          v
   [AdmissionReview]      [Evaluate Policies]
        |                          |
        v                          v
   [Allow/Deny]          [Policy Results]
```

### Comparison with Other Tools

| Feature | Kyverno | OPA Gatekeeper | Pod Security |
|---------|---------|----------------|--------------|
| Policy Language | YAML/JSON | Rego | Built-in |
| Learning Curve | Low | Steep | Low |
| Mutation | Yes | Limited | No |
| Generation | Yes | No | No |
| Reporting | Yes | Limited | No |
| External Data | Limited | Yes | No |

---

## Why Use Kyverno

### Kubernetes-Native Policies

- Policies are just Kubernetes resources
- No separate policy language to learn
- Use familiar kubectl commands
- Integrate with GitOps workflows

### Comprehensive Policy Types

- **Validate**: Block resources that violate policies
- **Mutate**: Automatically modify resources
- **Generate**: Create new resources based on triggers
- **Verify Images**: Validate container image signatures
- **Exceptions**: Define policy exceptions

### Audit and Enforcement

- **Audit mode**: Scan existing resources without blocking
- **Enforce mode**: Block resources in real-time
- **Background scanning**: Continuously check existing resources
- **Reports**: Generate detailed violation reports

### Advantages

1. **Easy to learn**: YAML-based policies
2. **Kubernetes-native**: Works with kubectl
3. **Comprehensive**: Validate, mutate, generate
4. **Extensible**: Custom policies with variables
5. **Observable**: Detailed reports and metrics

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
|         Kyverno Webhook (HTTPS)           |
|  +------------------------------------+  |
|  |       Admission Controller          |  |
|  |   - ValidatingWebhookConfiguration |  |
|  |   - MutatingWebhookConfiguration   |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Kyverno Controller              |
|  +------------------------------------+  |
|  |       Reconciler (watcher)          |  |
|  |   - Watches ClusterPolicies         |  |
|  |   - Watches Policies                |  |
|  |   - Watches PolicyReports           |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Policy Engine                  |
|  +------------------------------------+  |
|  |       Policy Evaluation             |  |
|  |   - Load policies                   |  |
|  |   - Evaluate against resources      |  |
|  |   - Return deny/allow/modify        |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Reporting System               |
|  +------------------------------------+  |
|  |   - PolicyReport CRD               |  |
|  |   - ClusterPolicyReport CRD        |  |
|  |   - Violation details               |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Webhook Flow

1. **Registration**: Kyverno registers ValidatingWebhookConfiguration and MutatingWebhookConfiguration
2. **Interception**: API server intercepts matching requests
3. **Evaluation**: Request sent to Kyverno pod
4. **Decision**: Allow, Deny, or Modify returned

### Controller Flow

1. **Watch**: Controller watches ClusterPolicies and Policies
2. **Cache**: Stores policies in memory for fast evaluation
3. **Evaluate**: Real-time evaluation against incoming requests
4. **Report**: Generate PolicyReport for violations

---

## Installation

### Prerequisites

- Kubernetes cluster v1.25+
- kubectl configured
- Helm v3
- Sufficient permissions (cluster-admin)
- Network access to Kyverno image registry

### Method 1: Helm Installation (Recommended)

```bash
# Add the Kyverno Helm repository
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno
helm install kyverno kyverno/kyverno \
  --namespace kyverno-system \
  --create-namespace \
  --set replicaCount=3 \
  --set backgroundController.replicaCount=2 \
  --set cleanupController.replicaCount=1 \
  --set reportsController.replicaCount=1 \
  --set webhooks.timeoutSeconds=3

# Verify installation
kubectl get pods -n kyverno-system
```

### Method 2: kubectl Installation

```bash
# Download the latest release
export KYVERNO_VERSION=$(curl -s https://api.github.com/repos/kyverno/kyverno/releases/latest | grep -o '"tag_name":.*' | sed -E 's/.*"([^"]+)".*/\1/')

# Apply the manifest
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/release-1.10/config/install-latest-testing.yaml

# Wait for pods to be ready
kubectl rollout status deployment/kyverno -n kyverno-system
```

### Method 3: kustomize Installation

```bash
# Clone the repository
git clone https://github.com/kyverno/kyverno.git
cd kyverno

# Apply with kustomize
kubectl apply -k config/

# Or with specific overlay
kubectl apply -k config/overlays/
```

### Method 4: From Source

```bash
# Clone the repository
git clone https://github.com/kyverno/kyverno.git
cd kyverno

# Build and push
make docker-build docker-push IMG=your-registry/kyverno:latest

# Deploy
make deploy IMG=your-registry/kyverno:latest
```

### Verification

```bash
# Check pods
kubectl get pods -n kyverno-system

# Expected output
NAME                        READY   STATUS    RESTARTS   AGE
kyverno-xxxxx               1/1     Running   0          5m
kyverno-background-xxxxx    1/1     Running   0          5m
kyverno-cleanup-xxxxx       1/1     Running   0          5m

# Check webhook
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno

# Check CRDs
kubectl get crd | grep kyverno
```

---

## Configuration

### Global Configuration

```yaml
apiVersion: kyverno.io/v1
kind: AdmissionReport
metadata:
  name: kyverno-config
  namespace: kyverno-system
spec:
  # Webhook configuration
  webhooks:
    timeoutSeconds: 3
    failurePolicy: Ignore
    namespaceSelector:
      matchLabels:
        kyverno.io/policy: enabled
  
  # Background scanning
  background:
    enabled: true
    interval: 10m
  
  # Reporting
  reports:
    enabled: true
    aggregateReports: true
```

### Webhook Configuration

```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: webhook-config
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-webhook
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Webhook configuration check"
        pattern:
          spec:
            containers:
              - name: "*"
```

### Background Scanning

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: background-scan
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: scan-pods
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Background scan check"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "*"
```

---

## Core Concepts

### Policy Types

#### Validate Policies

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
              environment: "?*"
```

#### Mutate Policies

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-labels
spec:
  rules:
    - name: add-labels
      match:
        resources:
          kinds:
            - Pod
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              app: "{{request.object.metadata.name}}"
```

#### Generate Policies

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
    - name: generate-network-policy
      match:
        resources:
          kinds:
            - Namespace
          selector:
            matchLabels:
              generate-network-policy: "true"
      generate:
        synchronize: true
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: "default-allow-{{request.object.metadata.name}}"
        namespace: "{{request.object.metadata.name}}"
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
              - Egress
```

#### Verify Image Policies

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-image-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - imageReferences:
            - "ghcr.io/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      ...
                      -----END PUBLIC KEY-----
```

### Variables

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: variable-example
spec:
  rules:
    - name: check-variable
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Container name must be {{request.object.metadata.name}}"
        pattern:
          spec:
            containers:
              - name: "{{request.object.metadata.name}}"
```

### Predefined Variables

```yaml
# Available variables
{{request.object}}           # The resource being admitted
{{request.kind}}             # The resource kind
{{request.name}}             # The resource name
{{request.namespace}}        # The resource namespace
{{request.operation}}        # The operation (CREATE, UPDATE, DELETE)
{{request.userInfo}}         # The user information
{{request.roles}}            # The user's roles
{{request.clusterRoles}}     # The user's cluster roles
```

### Background Scanning

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: background-scan
spec:
  validationFailureAction: Audit
  background: true
  rules:
    - name: scan-pods
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Background scan check"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "*"
```

---

## Usage Guide

### Step 1: Install Kyverno

```bash
helm install kyverno kyverno/kyverno \
  --namespace kyverno-system \
  --create-namespace
```

### Step 2: Create First Policy

```yaml
# require-labels.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels: app, environment"
        pattern:
          metadata:
            labels:
              app: "?*"
              environment: "?*"
```

### Step 3: Apply Policy

```bash
kubectl apply -f require-labels.yaml
```

### Step 4: Test Policy

```bash
# This should be denied
kubectl run nginx --image=nginx:latest

# This should be allowed
kubectl run nginx --image=nginx:latest --labels=app=nginx,environment=production
```

### Step 5: Check Reports

```bash
# Get policy reports
kubectl get policyreports -A

# Get cluster policy reports
kubectl get clusterpolicyreports

# Describe specific report
kubectl describe policyreport <name>
```

---

## Custom Policies

### Require Resource Limits

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-resource-limits
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "All containers must have resource limits"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

### Block Latest Tag

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-latest-tag
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-latest-tag
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Containers cannot use latest tag"
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

### Add Default Labels

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-labels
spec:
  rules:
    - name: add-labels
      match:
        resources:
          kinds:
            - Pod
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              environment: "development"
              managed-by: "kyverno"
```

### Generate Network Policy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
    - name: generate-network-policy
      match:
        resources:
          kinds:
            - Namespace
          selector:
            matchLabels:
              generate-network-policy: "true"
      generate:
        synchronize: true
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: "default-allow-{{request.object.metadata.name}}"
        namespace: "{{request.object.metadata.name}}"
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
              - Egress
```

### Image Verification

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-image-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - imageReferences:
            - "ghcr.io/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      ...
                      -----END PUBLIC KEY-----
```

---

## Integration

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: Policy Check
on: [pull_request]
jobs:
  kyverno:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Kyverno CLI
        run: |
          curl -L -o kyverno https://github.com/kyverno/kyverno/releases/download/v1.10.0/kyverno-cli_Linux_x86_64.tar.gz
          tar -xzf kyverno.tar.gz
          sudo mv kyverno /usr/local/bin/
      
      - name: Run Kyverno CLI
        run: |
          kyverno apply policy/ --resource k8s/ --detailed-results
```

### ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kyverno-policies
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/kyverno-policies.git
    targetRevision: HEAD
    path: policies
  destination:
    server: https://kubernetes.default.svc
    namespace: kyverno-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Prometheus Monitoring

```yaml
# ServiceMonitor for Kyverno
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kyverno
  namespace: kyverno-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: kyverno
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
      "title": "Kyverno Policy Violations",
      "type": "graph",
      "targets": [
        {
          "expr": "kyverno_policy_results_total{result=\"fail\"}",
          "legendFormat": "{{policy_name}}/{{rule_name}}"
        }
      ]
    },
    {
      "title": "Kyverno Webhook Duration",
      "type": "graph",
      "targets": [
        {
          "expr": "kyverno_webhook_duration_seconds",
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
  name: kyverno-manager-role
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["kyverno.io"]
    resources: ["*"]
    verbs: ["create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["create", "update", "patch", "delete"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kyverno-network-policy
  namespace: kyverno-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: kyverno
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
          port: 9443
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
  name: kyverno-pod
  namespace: kyverno-system
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: kyverno
      image: ghcr.io/kyverno/kyverno:v1.10.0
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
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=kyverno-svc.kyverno-system.svc"

# Create secret
kubectl create secret tls kyverno-svc-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n kyverno-system
```

---

## Troubleshooting

### Issue 1: Webhook Timeout

**Symptoms**: Requests taking too long, timeout errors
**Diagnosis**:
```bash
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i timeout
kubectl get events --field-selector reason=WebhookTimeout
```
**Solution**:
- Increase webhook timeout: `--set webhooks.timeoutSeconds=5`
- Check network latency between API server and Kyverno
- Verify DNS resolution

### Issue 2: Audit Not Working

**Symptoms**: No violations reported
**Diagnosis**:
```bash
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno -c background | grep -i error
kubectl get policies -o yaml | grep -A 10 background
```
**Solution**:
- Verify background is enabled
- Check policy rules
- Ensure resources exist

### Issue 3: Policy Not Evaluating

**Symptoms**: Policy exists but not enforced
**Diagnosis**:
```bash
kubectl get policies -o yaml
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i policy
```
**Solution**:
- Check validationFailureAction
- Verify match criteria
- Review policy syntax

### Issue 4: High Memory Usage

**Symptoms**: Kyverno pods OOMKilled
**Diagnosis**:
```bash
kubectl top pods -n kyverno-system
kubectl describe pod <kyverno-pod> -n kyverno-system
```
**Solution**:
- Increase memory limits
- Reduce number of policies
- Optimize policy rules

### Issue 5: Webhook Certificates Expired

**Symptoms**: Connection refused errors
**Diagnosis**:
```bash
kubectl get secret kyverno-svc-tls -n kyverno-system -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```
**Solution**:
- Renew certificates
- Restart Kyverno pods
- Verify cert rotation

### Issue 6: Namespace Exclusion Not Working

**Symptoms**: Policies applied to excluded namespaces
**Diagnosis**:
```bash
kubectl get policies -o yaml | grep -A 10 "exclude"
```
**Solution**:
- Check namespace labels
- Verify match criteria syntax
- Ensure excluded namespaces are correct

### Issue 7: Constraint Violations Not Appearing

**Symptoms**: No violations in policy status
**Diagnosis**:
```bash
kubectl get policyreports -o yaml | grep -A 10 violations
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i audit
```
**Solution**:
- Check validationFailureAction
- Verify audit interval
- Ensure resources exist

### Issue 8: Webhook Connection Refused

**Symptoms**: API server cannot connect to webhook
**Diagnosis**:
```bash
kubectl get endpoints -n kyverno-system kyverno-svc
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i webhook
```
**Solution**:
- Verify webhook service exists
- Check service selector labels
- Review network policies

### Issue 9: Mutation Not Working

**Symptoms**: Resources not being modified
**Diagnosis**:
```bash
kubectl get policies -o yaml | grep -A 10 mutate
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i mutate
```
**Solution**:
- Check mutation rules
- Verify patch syntax
- Review mutation operations

### Issue 10: Generation Not Working

**Symptoms**: Resources not being created
**Diagnosis**:
```bash
kubectl get policies -o yaml | grep -A 10 generate
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i generate
```
**Solution**:
- Check generation rules
- Verify API version and kind
- Review synchronization settings

### Issue 11: Image Verification Failing

**Symptoms**: Image verification always fails
**Diagnosis**:
```bash
kubectl get policies -o yaml | grep -A 10 verifyImages
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i image
```
**Solution**:
- Check image references
- Verify public keys
- Review attestor configuration

### Issue 12: Background Scan Performance

**Symptoms**: Background scanning taking too long
**Diagnosis**:
```bash
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno -c background | grep -i duration
```
**Solution**:
- Reduce scan interval
- Optimize policy rules
- Increase resources

### Issue 13: Policy Report Not Generated

**Symptoms**: No PolicyReport created
**Diagnosis**:
```bash
kubectl get policyreports -A
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i report
```
**Solution**:
- Verify reporting is enabled
- Check policy configuration
- Review controller logs

### Issue 14: Webhook Not Registering

**Symptoms**: Webhook not appearing in API server
**Diagnosis**:
```bash
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl describe validatingwebhookconfiguration kyverno-validating-webhook
```
**Solution**:
- Verify webhook configuration
- Check service account permissions
- Review network policies

### Issue 15: Policy Evaluation Error

**Symptoms**: Policy evaluation returns error
**Diagnosis**:
```bash
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno | grep -i error
kyverno apply policy/ --resource test.yaml --detailed-results
```
**Solution**:
- Validate policy syntax
- Check for missing variables
- Review policy logic

---

## Tips and Best Practices

### 1. Start with Audit Mode

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Audit  # Start with audit, then switch to enforce
  background: true
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### 2. Use Namespace Exclusions

```yaml
spec:
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
          exclude:
            namespaces:
              - kube-system
              - kube-public
              - kyverno-system
```

### 3. Optimize Policy Rules

```yaml
spec:
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
          namespaces:
            - production
            - staging
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### 4. Use Variables for Reusability

```yaml
spec:
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Container name must be {{request.object.metadata.name}}"
        pattern:
          spec:
            containers:
              - name: "{{request.object.metadata.name}}"
```

### 5. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
kubectl apply -f policy-audit.yaml

# Phase 2: Enforce mode
kubectl apply -f policy-enforce.yaml
```

### 6. Use Policy Reports

```bash
# Get policy reports
kubectl get policyreports -A

# Get cluster policy reports
kubectl get clusterpolicyreports

# Describe specific report
kubectl describe policyreport <name>
```

### 7. Monitor with Prometheus

```yaml
# Enable Prometheus metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kyverno
spec:
  endpoints:
    - port: metrics
      path: /metrics
```

### 8. Use GitOps for Policy Management

```bash
# Store policies in Git
git add policies/
git commit -m "Update kyverno policies"
git push origin main

# Apply with ArgoCD or Flux
```

### 9. Test Policies Locally

```bash
# Test with Kyverno CLI
kyverno apply policy/ --resource test.yaml --detailed-results

# Run tests
kyverno test policy/ -v
```

### 10. Use Labels for Policy Selection

```yaml
spec:
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
          selector:
            matchLabels:
              enforce: "true"
```

### 11. Implement Caching

```yaml
# Enable caching
spec:
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### 12. Use External Data

```yaml
spec:
  rules:
    - name: check-external
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Check external data"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### 13. Implement Policy Versioning

```bash
# Version policies
git tag -a v1.0.0 -m "Policy version 1.0.0"
git push origin v1.0.0

# Use specific version
kyverno apply policy-v1.0.0/ --resource test.yaml
```

### 14. Use Policy Coverage

```bash
# Check policy coverage
kyverno verify --trace policy/
```

### 15. Implement Policy Documentation

```yaml
# policy/README.md
# Resource Limits Policy

This policy ensures all containers have resource limits.

## Usage

```bash
kubectl apply -f policy.yaml
```

## Rules

- All containers must have CPU limits
- All containers must have memory limits
```

---

## Command Reference

### Basic Commands

```bash
# Apply policy
kubectl apply -f policy.yaml

# Get policies
kubectl get policies
kubectl get clusterpolicies

# Describe policy
kubectl describe policy <name>
kubectl describe clusterpolicy <name>

# Delete policy
kubectl delete policy <name>
kubectl delete clusterpolicy <name>

# Get policy reports
kubectl get policyreports -A
kubectl get clusterpolicyreports
```

### Kyverno CLI Commands

```bash
# Apply policies
kyverno apply policy/ --resource k8s/

# Test policies
kyverno test policy/ -v

# Verify policies
kyverno verify --trace policy/

# Show version
kyverno --version

# Show help
kyverno --help
kyverno apply --help
```

### Webhook Commands

```bash
# Get webhook configurations
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno

# Describe webhook
kubectl describe validatingwebhookconfiguration kyverno-validating-webhook

# Get webhook service
kubectl get endpoints -n kyverno-system kyverno-svc
```

### Reporting Commands

```bash
# Get policy reports
kubectl get policyreports -A

# Get cluster policy reports
kubectl get clusterpolicyreports

# Describe policy report
kubectl describe policyreport <name>

# Get violations
kubectl get policyreports -o json | jq '.items[].results[] | select(.result=="fail")'
```

### Debugging Commands

```bash
# Get Kyverno logs
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno

# Get background controller logs
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno -c background

# Get cleanup controller logs
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno -c cleanup

# Get reports controller logs
kubectl logs -n kyverno-system -l app.kubernetes.io/name=kyverno -c reports
```

---

## CRD Reference

### ClusterPolicy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### Policy

```yaml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: require-labels
  namespace: default
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-labels
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Missing required labels"
        pattern:
          metadata:
            labels:
              app: "?*"
```

### PolicyReport

```yaml
apiVersion: wgpolicyk8s.io/v1alpha2
kind: PolicyReport
metadata:
  name: policy-report
  namespace: default
summary:
  pass: 10
  fail: 5
  warn: 2
  error: 1
  skip: 3
results:
  - policy: require-labels
    rule: check-labels
    result: fail
    message: "Missing required labels"
    resource:
      kind: Pod
      name: nginx
      namespace: default
```

### ClusterPolicyReport

```yaml
apiVersion: wgpolicyk8s.io/v1alpha2
kind: ClusterPolicyReport
metadata:
  name: cluster-policy-report
summary:
  pass: 100
  fail: 50
  warn: 20
  error: 10
  skip: 30
results:
  - policy: require-labels
    rule: check-labels
    result: fail
    message: "Missing required labels"
    resource:
      kind: Pod
      name: nginx
      namespace: default
```

---

## Real-World Examples

### Production Cluster Policies

```yaml
# require-production-labels.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-production-labels
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-production-labels
      match:
        resources:
          kinds:
            - Pod
            - Deployment
            - StatefulSet
          namespaces:
            - production
      validate:
        message: "Production resources must have environment=production label"
        pattern:
          metadata:
            labels:
              environment: "production"
```

### Image Security

```yaml
# block-latest-tag.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: block-latest-tag
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-latest-tag
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Containers cannot use latest tag"
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

### Resource Quotas

```yaml
# require-resource-limits.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: check-resource-limits
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "All containers must have resource limits"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

### Network Policies

```yaml
# generate-network-policy.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: generate-network-policy
spec:
  rules:
    - name: generate-network-policy
      match:
        resources:
          kinds:
            - Namespace
          selector:
            matchLabels:
              generate-network-policy: "true"
      generate:
        synchronize: true
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: "default-allow-{{request.object.metadata.name}}"
        namespace: "{{request.object.metadata.name}}"
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
              - Egress
```

### Image Verification

```yaml
# verify-images.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-image-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - imageReferences:
            - "ghcr.io/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      ...
                      -----END PUBLIC KEY-----
```

---

## Further Reading

### Official Documentation

- [Kyverno Website](https://kyverno.io/)
- [Kyverno GitHub](https://github.com/kyverno/kyverno)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Best Practices](https://kyverno.io/docs/best-practices/)

### Community Resources

- [Kyverno Policy Library](https://kyverno.io/policy-library/)
- [Kyverno Examples](https://github.com/kyverno/kyverno/tree/main/examples)
- [Kyverno Discussions](https://github.com/kyverno/kyverno/discussions)

### Books and Tutorials

- "Kyverno Policy Enforcement" by CNCF
- "Kubernetes Policy Management" by Kyverno
- "YAML-Based Policies" by Kyverno

### Videos and Talks

- "Kyverno Deep Dive" by CNCF
- "Kubernetes Policy Enforcement" by KubeCon
- "Policy as Code Patterns" by ThoughtWorks

### Related Projects

- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
