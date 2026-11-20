# Pod Security Standards Complete Guide

## Table of Contents

1. [What Are Pod Security Standards](#what-are-pod-security-standards)
2. [Why Use Pod Security Standards](#why-use-pod-security-standards)
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

## What Are Pod Security Standards

Pod Security Standards are a set of Kubernetes-native security policies that define three different levels of security restrictions for pods: Privileged, Baseline, and Restricted. These standards are enforced through the Pod Security Admission controller, which is built into Kubernetes.

### Key Definitions

- **Pod Security Admission**: Built-in Kubernetes admission controller
- **Pod Security Standards**: Three security levels (Privileged, Baseline, Restricted)
- **Pod Security Admission Controller**: Validates pod security contexts
- **Namespace Labels**: Control enforcement per namespace
- **Enforcement Modes**: Enforce, Audit, Warn

### Security Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| Privileged | Unrestricted | System workloads, trusted code |
| Baseline | Minimally restrictive | Most applications |
| Restricted | Heavily restricted | Security-critical workloads |

### How It Works

```
kubectl apply -f pod.yaml
        |
        v
[API Server] --> [Pod Security Admission]
        |                          |
        v                          v
[Pod Security Standards]    [Evaluate Pod Security]
        |                          |
        v                          v
[Allow/Deny/Modify]         [Security Results]
```

---

## Why Use Pod Security Standards

### Kubernetes-Native Security

- Built into Kubernetes (no external tools needed)
- No additional components to install
- Native kubectl support
- Standard Kubernetes resources

### Three Security Levels

- **Privileged**: No restrictions (system workloads)
- **Baseline**: Minimally restrictive (most applications)
- **Restricted**: Heavily restricted (security-critical)

### Granular Control

- Per-namespace enforcement
- Multiple enforcement modes
- Audit without blocking
- Gradual rollout capability

### Advantages

1. **Built-in**: No external tools required
2. **Native**: Uses standard Kubernetes resources
3. **Simple**: YAML-based configuration
4. **Flexible**: Multiple levels and modes
5. **Auditable**: Full audit trail

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
|      Pod Security Admission Controller   |
|  +------------------------------------+  |
|  |   Admission Controller              |  |
|  |   - ValidatingWebhook               |  |
|  |   - Namespace Label Matching        |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|      Pod Security Standards              |
|  +------------------------------------+  |
|  |   Privileged                        |  |
|  |   - No restrictions                 |  |
|  |   - System workloads                |  |
|  +------------------------------------+  |
|  +------------------------------------+  |
|  |   Baseline                          |  |
|  |   - Minimally restrictive           |  |
|  |   - Most applications               |  |
|  +------------------------------------+  |
|  +------------------------------------+  |
|  |   Restricted                        |  |
|  |   - Heavily restricted              |  |
|  |   - Security-critical               |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|      Enforcement Modes                   |
|  +------------------------------------+  |
|  |   Enforce                           |  |
|  |   - Block violations                |  |
|  |   - Prevent creation                |  |
|  +------------------------------------+  |
|  +------------------------------------+  |
|  |   Audit                             |  |
|  |   - Log violations                  |  |
|  |   - Don't block                     |  |
|  +------------------------------------+  |
|  +------------------------------------+  |
|  |   Warn                              |  |
|  |   - Show warnings                   |  |
|  |   - Don't block                     |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Admission Flow

1. **Interception**: API server intercepts pod creation/update
2. **Label Matching**: Check namespace labels for Pod Security Standards
3. **Policy Evaluation**: Evaluate pod against specified security level
4. **Decision**: Allow, Deny, or Warn based on enforcement mode

### Label Namespace Flow

1. **Label Namespace**: Apply Pod Security labels to namespace
2. **Evaluate Policies**: Check pod against specified security level
3. **Enforce/Warn/Audit**: Apply enforcement based on mode
4. **Report Violations**: Log or block violations

---

## Installation

### Prerequisites

- Kubernetes cluster v1.25+
- kubectl configured
- Sufficient permissions (cluster-admin)
- Namespace access

### Method 1: Enable Pod Security Admission (Default in v1.25+)

```bash
# Pod Security Admission is enabled by default in Kubernetes v1.25+
# Verify it's enabled
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i pod-security

# If not enabled, edit kube-apiserver configuration
kubectl edit -n kube-system configmap kube-apiserver
```

### Method 2: Enable via kube-apiserver Configuration

```bash
# Edit kube-apiserver static pod manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add or modify the following flags:
--enable-admission-plugins=PodSecurity
--admission-control-config-file=/etc/kubernetes/pod-security-config.yaml
```

### Method 3: Create Pod Security Configuration

```bash
# Create pod security configuration file
cat <<EOF | sudo tee /etc/kubernetes/pod-security-config.yaml
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
exemptions:
  usernames: []
  runtimeClassNames: []
  namespaces: ["kube-system", "kube-public", "kube-node-lease"]
EOF
```

### Method 4: Restart kube-apiserver

```bash
# If using static pods, kube-apiserver will restart automatically
# If using systemd, restart the service
sudo systemctl restart kubelet

# Verify Pod Security Admission is enabled
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i pod-security
```

### Verification

```bash
# Check if Pod Security Admission is enabled
kubectl get --raw /api/v1/namespaces | jq '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"] != null) | .metadata.name'

# Test with a restricted pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
spec:
  containers:
    - name: nginx
      image: nginx:latest
      securityContext:
        privileged: true
EOF
# Expected output: Error (if enforce=restricted)

# Test with a compliant pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
EOF
# Expected output: pod/test-pod created
```

---

## Configuration

### Namespace Labels

```yaml
# Label namespace with Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Multiple Levels per Namespace

```yaml
# Different levels for different namespaces
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: latest
```

### Admission Configuration

```yaml
# Pod Security Admission configuration
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
exemptions:
  usernames: ["system:serviceaccount:kube-system:konnectivity-agent"]
  runtimeClassNames: ["gvisor", "kata"]
  namespaces: ["kube-system", "kube-public", "kube-node-lease"]
```

### Custom Exemptions

```yaml
# Exempt specific users
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
exemptions:
  usernames: 
    - "system:serviceaccount:kube-system:konnectivity-agent"
    - "system:serviceaccount:cert-manager:cert-manager"
  runtimeClassNames: 
    - "gvisor"
    - "kata"
  namespaces: 
    - "kube-system"
    - "kube-public"
    - "kube-node-lease"
    - "cert-manager"
```

---

## Core Concepts

### Security Levels

#### Privileged Level

```yaml
# No restrictions - system workloads
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: kube-system
spec:
  containers:
    - name: nginx
      image: nginx:latest
      securityContext:
        privileged: true
```

#### Baseline Level

```yaml
# Minimally restrictive - most applications
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
  namespace: default
spec:
  containers:
    - name: nginx
      image: nginx:latest
      securityContext:
        allowPrivilegeEscalation: false
```

#### Restricted Level

```yaml
# Heavily restricted - security-critical
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

### Enforcement Modes

#### Enforce Mode

```yaml
# Block violations
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
```

#### Audit Mode

```yaml
# Log violations but don't block
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
```

#### Warn Mode

```yaml
# Show warnings but don't block
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Namespace Labels

```yaml
# All three modes
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

---

## Usage Guide

### Step 1: Label Namespace

```bash
# Label namespace with restricted level
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=latest \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=latest
```

### Step 2: Test Policy

```bash
# This should be denied (if enforce=restricted)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: production
spec:
  containers:
    - name: nginx
      image: nginx:latest
      securityContext:
        privileged: true
EOF
```

### Step 3: Create Compliant Pod

```bash
# This should be allowed
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
EOF
```

### Step 4: Check Audit Logs

```bash
# Check audit logs for violations
kubectl get --raw /api/v1/namespaces/production/events | jq '.items[] | select(.reason == "FailedCreate") | .message'
```

### Step 5: Remove Label

```bash
# Remove Pod Security label
kubectl label namespace production pod-security.kubernetes.io/enforce-
kubectl label namespace production pod-security.kubernetes.io/audit-
kubectl label namespace production pod-security.kubernetes.io/warn-
```

---

## Custom Policies

### Custom Baseline Policy

```yaml
# Custom baseline policy using Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: custom-baseline
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Custom Restricted Policy

```yaml
# Custom restricted policy using Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: custom-restricted
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Custom Privileged Policy

```yaml
# Custom privileged policy using Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: custom-privileged
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: latest
```

### Multiple Namespaces

```yaml
# Apply different policies to different namespaces
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: latest
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
```

---

## Integration

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: Pod Security Check
on: [pull_request]
jobs:
  pod-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check Pod Security
        run: |
          # Check if pods comply with Pod Security Standards
          kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].securityContext.privileged == true) | .metadata.name'
```

### ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pod-security-policies
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/pod-security-policies.git
    targetRevision: HEAD
    path: policies
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Prometheus Monitoring

```yaml
# ServiceMonitor for Pod Security
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pod-security
  namespace: kube-system
spec:
  selector:
    matchLabels:
      component: kube-apiserver
  endpoints:
    - port: https-metrics
      interval: 30s
      path: /metrics
      scheme: https
      tlsConfig:
        insecureSkipVerify: true
```

### Grafana Dashboard

```json
{
  "panels": [
    {
      "title": "Pod Security Violations",
      "type": "graph",
      "targets": [
        {
          "expr": "kube_pod_security_violations_total",
          "legendFormat": "{{namespace}}/{{pod}}"
        }
      ]
    },
    {
      "title": "Pod Security Audit Duration",
      "type": "graph",
      "targets": [
        {
          "expr": "kube_pod_security_audit_duration_seconds",
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
  name: pod-security-role
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    verbs: ["get", "list", "watch"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pod-security-network-policy
  namespace: kube-system
spec:
  podSelector:
    matchLabels:
      component: kube-apiserver
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
          port: 6443
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
```

### Pod Security

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-security-pod
  namespace: kube-system
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: nginx
      image: nginx:latest
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

---

## Troubleshooting

### Issue 1: Pod Security Admission Not Working

**Symptoms**: Pods not being validated
**Diagnosis**:
```bash
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i pod-security
kubectl get --raw /api/v1/namespaces | jq '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"] != null)'
```
**Solution**:
- Verify Pod Security Admission is enabled
- Check kube-apiserver configuration
- Ensure namespace labels are correct

### Issue 2: Namespace Labels Not Applied

**Symptoms**: Namespace labels not taking effect
**Diagnosis**:
```bash
kubectl describe namespace production
kubectl get namespace production -o yaml
```
**Solution**:
- Verify label syntax
- Check namespace permissions
- Ensure labels are correct

### Issue 3: Pod Violations Not Appearing

**Symptoms**: No violations in audit logs
**Diagnosis**:
```bash
kubectl get --raw /api/v1/namespaces/production/events | jq '.items[] | select(.reason == "FailedCreate")'
```
**Solution**:
- Verify audit mode is enabled
- Check pod security context
- Review audit logs

### Issue 4: Webhook Timeout

**Symptoms**: Requests taking too long
**Diagnosis**:
```bash
kubectl logs -n kube-system -l component=kube-apiserver | grep -i timeout
```
**Solution**:
- Increase webhook timeout
- Check network latency
- Verify DNS resolution

### Issue 5: High Memory Usage

**Symptoms**: API server memory usage high
**Diagnosis**:
```bash
kubectl top pods -n kube-system
```
**Solution**:
- Reduce number of policies
- Optimize policy rules
- Increase resources

### Issue 6: Namespace Exclusion Not Working

**Symptoms**: Policies applied to excluded namespaces
**Diagnosis**:
```bash
kubectl get pod-security-config -n kube-system -o yaml
```
**Solution**:
- Check namespace labels
- Verify exclusion syntax
- Ensure namespaces are correct

### Issue 7: Pod Security Admission Configuration Error

**Symptoms**: Configuration not loaded
**Diagnosis**:
```bash
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i admission
```
**Solution**:
- Check configuration file
- Verify syntax
- Restart kube-apiserver

### Issue 8: Webhook Connection Refused

**Symptoms**: API server cannot connect to webhook
**Diagnosis**:
```bash
kubectl get endpoints -n kube-system kube-apiserver
```
**Solution**:
- Verify webhook service exists
- Check service selector labels
- Review network policies

### Issue 9: Policy Not Evaluating

**Symptoms**: Policy exists but not enforced
**Diagnosis**:
```bash
kubectl get pod-security-config -n kube-system -o yaml
```
**Solution**:
- Check policy configuration
- Verify enforcement mode
- Review namespace labels

### Issue 10: Audit Logs Not Generated

**Symptoms**: No audit logs
**Diagnosis**:
```bash
kubectl get --raw /api/v1/namespaces/production/events | jq '.items[] | select(.reason == "FailedCreate")'
```
**Solution**:
- Verify audit mode is enabled
- Check audit configuration
- Review audit logs

### Issue 11: Webhook Certificates Expired

**Symptoms**: Connection refused errors
**Diagnosis**:
```bash
kubectl get secret -n kube-system kube-apiserver-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```
**Solution**:
- Renew certificates
- Restart kube-apiserver
- Verify cert rotation

### Issue 12: Namespace Exclusion Not Working

**Symptoms**: Policies applied to excluded namespaces
**Diagnosis**:
```bash
kubectl get pod-security-config -n kube-system -o yaml
```
**Solution**:
- Check namespace labels
- Verify exclusion syntax
- Ensure namespaces are correct

### Issue 13: Pod Security Admission Not Working

**Symptoms**: Pods not being validated
**Diagnosis**:
```bash
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i pod-security
kubectl get --raw /api/v1/namespaces | jq '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"] != null)'
```
**Solution**:
- Verify Pod Security Admission is enabled
- Check kube-apiserver configuration
- Ensure namespace labels are correct

### Issue 14: Namespace Labels Not Applied

**Symptoms**: Namespace labels not taking effect
**Diagnosis**:
```bash
kubectl describe namespace production
kubectl get namespace production -o yaml
```
**Solution**:
- Verify label syntax
- Check namespace permissions
- Ensure labels are correct

### Issue 15: Pod Violations Not Appearing

**Symptoms**: No violations in audit logs
**Diagnosis**:
```bash
kubectl get --raw /api/v1/namespaces/production/events | jq '.items[] | select(.reason == "FailedCreate")'
```
**Solution**:
- Verify audit mode is enabled
- Check pod security context
- Review audit logs

---

## Tips and Best Practices

### 1. Start with Audit Mode

```yaml
# Start with audit, then switch to enforce
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### 2. Use Namespace Exclusions

```yaml
# Exclude system namespaces
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
exemptions:
  namespaces: ["kube-system", "kube-public", "kube-node-lease"]
```

### 3. Optimize Pod Security Context

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

### 4. Use Labels for Policy Selection

```yaml
# Label namespaces for policy selection
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    environment: production
```

### 5. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
kubectl label namespace production pod-security.kubernetes.io/audit=restricted

# Phase 2: Warn mode
kubectl label namespace production pod-security.kubernetes.io/warn=restricted

# Phase 3: Enforce mode
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted
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
  name: pod-security
spec:
  endpoints:
    - port: metrics
      path: /metrics
```

### 8. Use GitOps for Policy Management

```bash
# Store policies in Git
git add policies/
git commit -m "Update pod security policies"
git push origin main

# Apply with ArgoCD or Flux
```

### 9. Test Policies Locally

```bash
# Test with kubectl
kubectl apply -f pod.yaml --dry-run=server

# Test with dry-run
kubectl apply -f pod.yaml --dry-run=client
```

### 10. Use Labels for Policy Selection

```yaml
# Label namespaces for policy selection
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    environment: production
```

### 11. Implement Caching

```yaml
# Enable caching
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
```

### 12. Use External Data

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

### 13. Implement Policy Versioning

```bash
# Version policies
git tag -a v1.0.0 -m "Policy version 1.0.0"
git push origin v1.0.0

# Use specific version
kubectl apply -f policy-v1.0.0.yaml
```

### 14. Use Policy Coverage

```bash
# Check policy coverage
kubectl get --raw /api/v1/namespaces | jq '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"] != null)'
```

### 15. Implement Policy Documentation

```yaml
# policy/README.md
# Pod Security Standards Policy

This policy enforces Pod Security Standards on namespaces.

## Usage

```bash
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted
```

## Rules

- Enforce restricted level on production namespaces
- Audit restricted level on staging namespaces
- Warn restricted level on development namespaces
```

---

## Command Reference

### Namespace Commands

```bash
# Label namespace
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# Remove label
kubectl label namespace production pod-security.kubernetes.io/enforce-

# Get namespace labels
kubectl get namespace production -o jsonpath='{.metadata.labels}'

# Describe namespace
kubectl describe namespace production
```

### Pod Commands

```bash
# Get pods
kubectl get pods -A

# Describe pod
kubectl describe pod <name>

# Get pod security context
kubectl get pod <name> -o jsonpath='{.spec.securityContext}'

# Test pod creation
kubectl apply -f pod.yaml --dry-run=server
```

### Admission Commands

```bash
# Get admission configuration
kubectl get -n kube-system configmap kube-apiserver -o yaml

# Get Pod Security Admission configuration
kubectl get --raw /api/v1/namespaces | jq '.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"] != null)'

# Test admission
kubectl apply -f pod.yaml --dry-run=server
```

### Audit Commands

```bash
# Get audit logs
kubectl get --raw /api/v1/namespaces/production/events | jq '.items[] | select(.reason == "FailedCreate")'

# Get audit configuration
kubectl get -n kube-system configmap kube-apiserver -o yaml | grep -i audit
```

### Debugging Commands

```bash
# Get kube-apiserver logs
kubectl logs -n kube-system -l component=kube-apiserver

# Get admission controller logs
kubectl logs -n kube-system -l component=kube-apiserver | grep -i pod-security

# Get webhook logs
kubectl logs -n kube-system -l component=kube-apiserver | grep -i webhook
```

---

## CRD Reference

### PodSecurityConfiguration

```yaml
apiVersion: pod-security.admission.config.k8s.io/v1
kind: PodSecurityConfiguration
defaults:
  enforce: "restricted"
  enforce-version: "latest"
  audit: "restricted"
  audit-version: "latest"
  warn: "restricted"
  warn-version: "latest"
exemptions:
  usernames: []
  runtimeClassNames: []
  namespaces: []
```

### Namespace Labels

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Pod Security Context

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

---

## Real-World Examples

### Production Cluster Policies

```yaml
# production-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
    environment: production
```

### System Namespace Policies

```yaml
# kube-system-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: latest
    environment: system
```

### Development Namespace Policies

```yaml
# development-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: latest
    environment: development
```

### Restricted Pod Template

```yaml
# restricted-pod-template.yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: nginx
      image: nginx:latest
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
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
```

---

## Further Reading

### Official Documentation

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

### Community Resources

- [Pod Security Standards Examples](https://github.com/kubernetes/website/tree/main/content/en/examples/pod-security)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards Guide](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

### Books and Tutorials

- "Kubernetes Security" by O'Reilly
- "Pod Security Standards" by CNCF
- "Kubernetes Security Patterns" by Christian Posta

### Videos and Talks

- "Pod Security Standards Deep Dive" by CNCF
- "Kubernetes Security" by KubeCon
- "Pod Security Patterns" by ThoughtWorks

### Related Projects

- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno](https://kyverno.io/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
