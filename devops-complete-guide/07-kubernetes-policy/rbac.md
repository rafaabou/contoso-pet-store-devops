# RBAC Complete Guide

## Table of Contents

1. [What Is RBAC](#what-is-rbac)
2. [Why Use RBAC](#why-use-rbac)
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

## What Is RBAC

Role-Based Access Control (RBAC) is a method of regulating access to resources based on the roles of individual users. In Kubernetes, RBAC allows you to define who can perform what actions on which resources, providing fine-grained access control for your cluster.

### Key Definitions

- **Role**: A set of permissions within a namespace
- **ClusterRole**: A set of permissions cluster-wide
- **RoleBinding**: Grants a Role to users/service accounts in a namespace
- **ClusterRoleBinding**: Grants a ClusterRole to users/service accounts cluster-wide
- **Subject**: Users, groups, or service accounts
- **Verb**: Actions (get, list, watch, create, update, patch, delete)

### How It Works

```
User/ServiceAccount --> [RBAC] --> [Authorization] --> [Resource Access]
        |                              |
        v                              v
  [Role/ClusterRole]           [Allow/Deny]
        |                              |
        v                              v
  [Permissions]                [Audit Trail]
```

### RBAC Components

| Component | Scope | Purpose |
|-----------|-------|---------|
| Role | Namespace | Define permissions within a namespace |
| ClusterRole | Cluster | Define permissions cluster-wide |
| RoleBinding | Namespace | Grant Role to subjects in namespace |
| ClusterRoleBinding | Cluster | Grant ClusterRole to subjects cluster-wide |

---

## Why Use RBAC

### Least Privilege Principle

- Grant only necessary permissions
- Reduce attack surface
- Prevent unauthorized access
- Implement zero-trust security

### Compliance

- Meet regulatory requirements
- Implement audit trails
- Enforce security policies
- Maintain compliance documentation

### Operational Excellence

- Simplify access management
- Enable self-service
- Reduce administrative overhead
- Improve security posture

### Advantages

1. **Fine-grained control**: Precise permission management
2. **Kubernetes-native**: Built into Kubernetes
3. **Auditable**: Full audit trail
4. **Flexible**: Support for users, groups, service accounts
5. **Standard**: Works with any Kubernetes distribution

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
|           RBAC Authorization             |
|  +------------------------------------+  |
|  |   Role / ClusterRole                |  |
|  |   - Define permissions              |  |
|  |   - Specify verbs and resources     |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|         RoleBinding / ClusterRoleBinding  |
|  +------------------------------------+  |
|  |   Bind roles to subjects            |  |
|  |   - Users                           |  |
|  |   - Groups                          |  |
|  |   - Service Accounts                |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Authorization                  |
|  +------------------------------------+  |
|  |   Evaluate access                   |  |
|  |   - Check Role/ClusterRole          |  |
|  |   - Check RoleBinding/ClusterRoleBinding|  |
|  |   - Allow/Deny decision             |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### RBAC Flow

1. **Request**: User/ServiceAccount makes API request
2. **Authentication**: Verify identity
3. **Authorization**: Check RBAC permissions
4. **Decision**: Allow or Deny request
5. **Audit**: Log access decision

### Role Binding Flow

1. **Create Role/ClusterRole**: Define permissions
2. **Create RoleBinding/ClusterRoleBinding**: Bind to subjects
3. **Evaluate**: Check access for each request
4. **Audit**: Log access decisions

---

## Installation

### Prerequisites

- Kubernetes cluster v1.20+
- kubectl configured
- Sufficient permissions (cluster-admin)
- Access to cluster

### Method 1: Enable RBAC (Default in v1.8+)

```bash
# RBAC is enabled by default in Kubernetes v1.8+
# Verify RBAC is enabled
kubectl auth can-i --list

# Check RBAC configuration
kubectl get --raw /api/v1/namespaces | jq '.items[0].metadata'
```

### Method 2: Verify RBAC Authorization

```bash
# Check current user permissions
kubectl auth can-i --list

# Check specific permission
kubectl auth can-i get pods --namespace default

# Check if user can perform action
kubectl auth can-i create deployments --namespace production --as user@example.com
```

### Method 3: Enable RBAC in kube-apiserver

```bash
# Edit kube-apiserver configuration
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Add or modify the following flags:
--authorization-mode=RBAC,Node

# Restart kube-apiserver
sudo systemctl restart kubelet
```

### Verification

```bash
# Check RBAC is enabled
kubectl auth can-i --list

# Check ClusterRoles
kubectl get clusterroles | head -20

# Check ClusterRoleBindings
kubectl get clusterrolebindings | head -20

# Test RBAC
kubectl auth can-i get pods --namespace default
kubectl auth can-i create deployments --namespace production --as user@example.com
```

---

## Configuration

### Basic Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### Basic ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-cluster
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-cluster
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader-cluster
  apiGroup: rbac.authorization.k8s.io
```

---

## Core Concepts

### Roles and ClusterRoles

```yaml
# Role (namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]

# ClusterRole (cluster-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-cluster
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
```

### RoleBindings and ClusterRoleBindings

```yaml
# RoleBinding (namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
  - kind: ServiceAccount
    name: default
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

# ClusterRoleBinding (cluster-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-cluster
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: admins
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader-cluster
  apiGroup: rbac.authorization.k8s.io
```

### Verbs and Resources

```yaml
spec:
  rules:
    - apiGroups: [""]
      resources: ["pods", "services"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    - apiGroups: ["apps"]
      resources: ["deployments", "statefulsets"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    - apiGroups: ["networking.k8s.io"]
      resources: ["networkpolicies"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### Subjects

```yaml
spec:
  subjects:
    - kind: User
      name: user@example.com
      apiGroup: rbac.authorization.k8s.io
    - kind: Group
      name: developers
      apiGroup: rbac.authorization.k8s.io
    - kind: ServiceAccount
      name: default
      namespace: default
```

---

## Usage Guide

### Step 1: Create Role

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
EOF
```

### Step 2: Create RoleBinding

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Step 3: Test Access

```bash
# Test as user
kubectl auth can-i get pods --namespace default --as user@example.com

# Test as group
kubectl auth can-i get pods --namespace default --as group:developers

# Test as service account
kubectl auth can-i get pods --namespace default --as system:serviceaccount:default:default
```

### Step 4: Verify Permissions

```bash
# List all permissions
kubectl auth can-i --list --as user@example.com

# Check specific permission
kubectl auth can-i get pods --namespace default --as user@example.com

# Check multiple permissions
kubectl auth can-i get,create,update pods --namespace default --as user@example.com
```

### Step 5: Monitor RBAC

```bash
# Get roles
kubectl get roles -A

# Get cluster roles
kubectl get clusterroles | head -20

# Get role bindings
kubectl get rolebindings -A

# Get cluster role bindings
kubectl get clusterrolebindings | head -20
```

---

## Custom Policies

### Developer Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: developer
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch"]
```

### Operations Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: operations
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies", "ingresses"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### Security Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: security
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies", "ingresses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    verbs: ["get", "list", "watch"]
```

### Monitoring Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch"]
```

---

## Integration

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: RBAC Check
on: [pull_request]
jobs:
  rbac:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install kubectl
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/
      
      - name: Check RBAC
        run: |
          kubectl get roles -A
          kubectl get clusterroles | head -20
          kubectl get rolebindings -A
          kubectl get clusterrolebindings | head -20
```

### ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: rbac-policies
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/rbac-policies.git
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
# ServiceMonitor for RBAC
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rbac
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
      "title": "RBAC Authorization Decisions",
      "type": "graph",
      "targets": [
        {
          "expr": "apiserver_authorization_decisions_total",
          "legendFormat": "{{user}}/{{verb}}/{{resource}}"
        }
      ]
    },
    {
      "title": "RBAC Authorization Duration",
      "type": "graph",
      "targets": [
        {
          "expr": "apiserver_authorization_duration_seconds",
          "legendFormat": "{{verb}}/{{resource}}"
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
  name: rbac-admin
rules:
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "clusterroles", "rolebindings", "clusterrolebindings"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: rbac-network-policy
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
  name: rbac-pod
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

### Issue 1: RBAC Not Working

**Symptoms**: Access denied errors
**Diagnosis**:
```bash
kubectl auth can-i --list --as user@example.com
kubectl get roles -A
kubectl get clusterroles | head -20
```
**Solution**:
- Verify RBAC is enabled
- Check Role/ClusterRole exists
- Verify RoleBinding/ClusterRoleBinding

### Issue 2: Permission Denied

**Symptoms**: Cannot perform action
**Diagnosis**:
```bash
kubectl auth can-i get pods --namespace default --as user@example.com
kubectl describe role pod-reader --namespace default
```
**Solution**:
- Check Role permissions
- Verify RoleBinding
- Test with kubectl auth can-i

### Issue 3: Service Account Not Working

**Symptoms**: Service account cannot access resources
**Diagnosis**:
```bash
kubectl get serviceaccounts -A
kubectl describe serviceaccount default --namespace default
```
**Solution**:
- Verify service account exists
- Check RoleBinding for service account
- Verify namespace

### Issue 4: ClusterRole Not Working

**Symptoms**: ClusterRole not applied
**Diagnosis**:
```bash
kubectl get clusterroles | grep pod-reader
kubectl describe clusterrole pod-reader
```
**Solution**:
- Verify ClusterRole exists
- Check ClusterRoleBinding
- Test with kubectl auth can-i

### Issue 5: RoleBinding Not Working

**Symptoms**: RoleBinding not applied
**Diagnosis**:
```bash
kubectl get rolebindings -A | grep read-pods
kubectl describe rolebinding read-pods --namespace default
```
**Solution**:
- Verify RoleBinding exists
- Check subjects
- Verify roleRef

### Issue 6: Namespace Isolation Not Working

**Symptoms**: Cross-namespace access
**Diagnosis**:
```bash
kubectl get roles -A | grep pod-reader
kubectl get rolebindings -A | grep read-pods
```
**Solution**:
- Check namespace in Role
- Verify RoleBinding namespace
- Test with kubectl auth can-i

### Issue 7: Group Not Working

**Symptoms**: Group permissions not applied
**Diagnosis**:
```bash
kubectl auth can-i get pods --namespace default --as group:developers
kubectl get rolebindings -A -o yaml | grep -A 5 developers
```
**Solution**:
- Verify group exists
- Check RoleBinding for group
- Test with kubectl auth can-i

### Issue 8: ClusterRoleBinding Not Working

**Symptoms**: ClusterRoleBinding not applied
**Diagnosis**:
```bash
kubectl get clusterrolebindings | grep read-pods
kubectl describe clusterrolebinding read-pods
```
**Solution**:
- Verify ClusterRoleBinding exists
- Check subjects
- Verify roleRef

### Issue 9: RBAC Audit Not Working

**Symptoms**: No audit logs
**Diagnosis**:
```bash
kubectl logs -n kube-system -l component=kube-apiserver | grep -i rbac
```
**Solution**:
- Enable audit logging
- Check audit configuration
- Review audit logs

### Issue 10: RBAC Performance Issues

**Symptoms**: Slow RBAC evaluation
**Diagnosis**:
```bash
kubectl top pods -n kube-system
kubectl logs -n kube-system -l component=kube-apiserver | grep -i duration
```
**Solution**:
- Optimize RBAC rules
- Reduce number of roles
- Increase resources

### Issue 11: RBAC Not Syncing

**Symptoms**: RBAC not applied to nodes
**Diagnosis**:
```bash
kubectl get roles -A
kubectl get clusterroles | head -20
```
**Solution**:
- Check RBAC configuration
- Verify Role/ClusterRole exists
- Restart kube-apiserver

### Issue 12: RBAC Not Applied to New Pods

**Symptoms**: New pods not protected
**Diagnosis**:
```bash
kubectl get pods --show-labels
kubectl describe role pod-reader --namespace default
```
**Solution**:
- Verify pod labels match selector
- Check RoleBinding is applied
- Test with kubectl auth can-i

### Issue 13: RBAC Not Applied to Existing Pods

**Symptoms**: Existing pods not protected
**Diagnosis**:
```bash
kubectl get pods --show-labels
kubectl describe role pod-reader --namespace default
```
**Solution**:
- Verify pod labels match selector
- Check RoleBinding is applied
- Test with kubectl auth can-i

### Issue 14: RBAC Conflict

**Symptoms**: Multiple roles conflicting
**Diagnosis**:
```bash
kubectl get roles -A -o yaml
kubectl describe role pod-reader --namespace default
```
**Solution**:
- Review role priorities
- Check for overlapping permissions
- Simplify role structure

### Issue 15: RBAC Not Working with OIDC

**Symptoms**: OIDC users cannot access resources
**Diagnosis**:
```bash
kubectl auth can-i --list --as user@example.com
kubectl get rolebindings -A -o yaml | grep -A 5 user@example.com
```
**Solution**:
- Verify OIDC configuration
- Check RoleBinding for OIDC user
- Test with kubectl auth can-i

---

## Tips and Best Practices

### 1. Use Least Privilege Principle

```yaml
# Grant only necessary permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### 2. Use Groups for User Management

```yaml
# Use groups for user management
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. Use Service Accounts for Applications

```yaml
# Use service accounts for applications
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 4. Use ClusterRoles for Cluster-Wide Access

```yaml
# Use ClusterRoles for cluster-wide access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-cluster
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### 5. Use RoleBindings for Namespace Access

```yaml
# Use RoleBindings for namespace access
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 6. Use ClusterRoleBindings for Cluster-Wide Access

```yaml
# Use ClusterRoleBindings for cluster-wide access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-cluster
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader-cluster
  apiGroup: rbac.authorization.k8s.io
```

### 7. Use Labels for Role Selection

```yaml
# Use labels for role selection
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
  labels:
    app: nginx
    environment: production
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### 8. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
kubectl apply -f role-audit.yaml

# Phase 2: Enforce mode
kubectl apply -f role-enforce.yaml
```

### 9. Use GitOps for RBAC Management

```bash
# Store RBAC in Git
git add rbac/
git commit -m "Update RBAC policies"
git push origin main

# Apply with ArgoCD or Flux
```

### 10. Test RBAC Locally

```bash
# Test with kubectl
kubectl auth can-i get pods --namespace default --as user@example.com

# Test with dry-run
kubectl auth can-i get pods --namespace default --as user@example.com --dry-run=client
```

### 11. Use Labels for Role Selection

```yaml
# Use labels for role selection
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
  labels:
    app: nginx
    environment: production
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### 12. Implement Caching

```yaml
# Enable caching
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### 13. Use External Data

```yaml
spec:
  subjects:
    - kind: User
      name: user@example.com
      apiGroup: rbac.authorization.k8s.io
    - kind: Group
      name: developers
      apiGroup: rbac.authorization.k8s.io
```

### 14. Implement Policy Versioning

```bash
# Version policies
git tag -a v1.0.0 -m "RBAC version 1.0.0"
git push origin v1.0.0

# Use specific version
kubectl apply -f rbac-v1.0.0.yaml
```

### 15. Use Policy Coverage

```bash
# Check policy coverage
kubectl get roles -A
kubectl get clusterroles | head -20
kubectl get rolebindings -A
kubectl get clusterrolebindings | head -20
```

---

## Command Reference

### Basic Commands

```bash
# Get roles
kubectl get roles -A

# Get cluster roles
kubectl get clusterroles | head -20

# Get role bindings
kubectl get rolebindings -A

# Get cluster role bindings
kubectl get clusterrolebindings | head -20

# Describe role
kubectl describe role <name> --namespace <namespace>

# Describe cluster role
kubectl describe clusterrole <name>

# Describe role binding
kubectl describe rolebinding <name> --namespace <namespace>

# Describe cluster role binding
kubectl describe clusterrolebinding <name>
```

### Authorization Commands

```bash
# Check current user permissions
kubectl auth can-i --list

# Check specific permission
kubectl auth can-i get pods --namespace default

# Check as specific user
kubectl auth can-i get pods --namespace default --as user@example.com

# Check as group
kubectl auth can-i get pods --namespace default --as group:developers

# Check as service account
kubectl auth can-i get pods --namespace default --as system:serviceaccount:default:default
```

### Debugging Commands

```bash
# Get RBAC logs
kubectl logs -n kube-system -l component=kube-apiserver | grep -i rbac

# Get RBAC events
kubectl get events --field-selector reason=RBAC

# Get RBAC configuration
kubectl get --raw /api/v1/namespaces | jq '.items[0].metadata'
```

### Monitoring Commands

```bash
# Get RBAC metrics
kubectl get --raw /metrics | grep -i rbac

# Get RBAC authorization decisions
kubectl get --raw /metrics | grep -i authorization

# Get RBAC authorization duration
kubectl get --raw /metrics | grep -i duration
```

---

## CRD Reference

### Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-cluster
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-cluster
subjects:
  - kind: User
    name: user@example.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader-cluster
  apiGroup: rbac.authorization.k8s.io
```

---

## Real-World Examples

### Production Cluster RBAC

```yaml
# production-developer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: developer
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch"]
---
# production-developer-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: production
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

### Operations Team RBAC

```yaml
# operations-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: operations
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies", "ingresses"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
# operations-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: operations-binding
subjects:
  - kind: Group
    name: operations
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: operations
  apiGroup: rbac.authorization.k8s.io
```

### Security Team RBAC

```yaml
# security-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: security
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies", "ingresses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    verbs: ["get", "list", "watch"]
---
# security-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: security-binding
subjects:
  - kind: Group
    name: security
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: security
  apiGroup: rbac.authorization.k8s.io
```

### Monitoring Team RBAC

```yaml
# monitoring-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch"]
---
# monitoring-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-binding
subjects:
  - kind: Group
    name: monitoring
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: monitoring
  apiGroup: rbac.authorization.k8s.io
```

---

## Further Reading

### Official Documentation

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Kubernetes Authorization](https://kubernetes.io/docs/reference/access-authn-authz/authorization/)

### Community Resources

- [RBAC Examples](https://github.com/kubernetes/website/tree/main/content/en/examples/access/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [RBAC Best Practices](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#good-practices)

### Books and Tutorials

- "Kubernetes Security" by O'Reilly
- "RBAC Authorization" by CNCF
- "Kubernetes Security Patterns" by Christian Posta

### Videos and Talks

- "RBAC Deep Dive" by CNCF
- "Kubernetes Security" by KubeCon
- "RBAC Patterns" by ThoughtWorks

### Related Projects

- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno](https://kyverno.io/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
