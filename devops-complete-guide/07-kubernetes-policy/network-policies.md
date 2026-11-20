# Network Policies Complete Guide

## Table of Contents

1. [What Are Network Policies](#what-are-network-policies)
2. [Why Use Network Policies](#why-use-network-policies)
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

## What Are Network Policies

Network Policies are Kubernetes resources that control traffic flow between pods, namespaces, and external endpoints. They allow you to define rules for ingress and egress traffic, providing network-level security for your applications.

### Key Definitions

- **Ingress**: Incoming traffic to pods
- **Egress**: Outgoing traffic from pods
- **Pod Selector**: Selects pods to apply policies to
- **Namespace Selector**: Selects namespaces to apply policies to
- **CIDR**: Classless Inter-Domain Routing for IP ranges
- **Network Plugin**: CNI plugin that implements Network Policies (Calico, Cilium, etc.)

### How It Works

```
kubectl apply -f network-policy.yaml
        |
        v
[API Server] --> [Network Plugin]
        |                  |
        v                  v
[Network Policy]    [Enforce Rules]
        |                  |
        v                  v
[Allow/Deny Traffic]  [Traffic Flow]
```

### Supported Network Plugins

| Plugin | Support | Features |
|--------|---------|----------|
| Calico | Full | Network Policies, Global Network Policies |
| Cilium | Full | Network Policies, L7 Policies |
| Weave Net | Full | Network Policies |
| Flannel | None | Requires additional plugin |
| Kubernetes | Partial | Basic Network Policies |

---

## Why Use Network Policies

### Micro-Segmentation

- Isolate pods from each other
- Control traffic between namespaces
- Restrict external access
- Implement zero-trust networking

### Security Hardening

- Block unauthorized traffic
- Restrict pod-to-pod communication
- Control egress traffic
- Prevent lateral movement

### Compliance

- Meet regulatory requirements
- Implement audit trails
- Enforce security policies
- Maintain compliance documentation

### Advantages

1. **Kubernetes-native**: Built into Kubernetes
2. **Flexible**: Fine-grained control
3. **Auditable**: Full audit trail
4. **Composable**: Stack multiple policies
5. **Standard**: Works with any CNI

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
|           Network Plugin                 |
|  +------------------------------------+  |
|  |   Calico / Cilium / Weave           |  |
|  |   - Implements Network Policies     |  |
|  |   - Manages iptables/IPVS           |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|         Network Policy Controller        |
|  +------------------------------------+  |
|  |   Watches NetworkPolicy resources   |  |
|  |   - Creates iptables rules          |  |
|  |   - Manages traffic flow            |  |
|  +------------------------------------+  |
+------------------------------------------+
                    |
                    v
+------------------------------------------+
|           Pod Network                    |
|  +------------------------------------+  |
|  |   Pod-to-Pod Communication          |  |
|  |   - Ingress rules                   |  |
|  |   - Egress rules                    |  |
|  +------------------------------------+  |
+------------------------------------------+
```

### Network Plugin Flow

1. **Watch**: Network plugin watches NetworkPolicy resources
2. **Apply**: Applies rules to pod network
3. **Enforce**: Controls traffic flow
4. **Audit**: Logs policy violations

### Traffic Flow

1. **Pod A** sends traffic to **Pod B**
2. **Network Plugin** intercepts traffic
3. **Evaluate** against NetworkPolicy rules
4. **Allow/Deny** based on policy

---

## Installation

### Prerequisites

- Kubernetes cluster v1.20+
- kubectl configured
- Network plugin with NetworkPolicy support (Calico, Cilium, etc.)
- Sufficient permissions (cluster-admin)

### Method 1: Calico Installation

```bash
# Install Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Verify installation
kubectl get pods -n kube-system | grep calico

# Install Calicoctl
curl -L https://github.com/projectcalico/calico/releases/download/v3.26.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
chmod +x /usr/local/bin/calicoctl
```

### Method 2: Cilium Installation

```bash
# Install Cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system

# Verify installation
kubectl get pods -n kube-system | grep cilium

# Install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}
```

### Method 3: Weave Net Installation

```bash
# Install Weave Net
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Verify installation
kubectl get pods -n kube-system | grep weave
```

### Method 4: Flannel with Calico

```bash
# Install Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Install Calico for NetworkPolicy support
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Verify installation
kubectl get pods -n kube-system | grep -E "flannel|calico"
```

### Verification

```bash
# Check Network Policy support
kubectl get networkpolicies

# Test with a simple policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
EOF

# Check if policy is applied
kubectl describe networkpolicy test-network-policy
```

---

## Configuration

### Basic Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### Ingress-Only Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

### Egress-Only Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
```

### Namespace Isolation

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              environment: production
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              environment: production
```

---

## Core Concepts

### Pod Selectors

```yaml
spec:
  podSelector:
    matchLabels:
      app: nginx
```

### Namespace Selectors

```yaml
spec:
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              environment: production
```

### CIDR Ranges

```yaml
spec:
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
            except:
              - 10.0.1.0/24
```

### Port Definitions

```yaml
spec:
  ingress:
    - ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
```

### Combined Selectors

```yaml
spec:
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
        - namespaceSelector:
            matchLabels:
              environment: production
      ports:
        - protocol: TCP
          port: 8080
```

---

## Usage Guide

### Step 1: Create Default Deny Policy

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
EOF
```

### Step 2: Allow Frontend to Backend

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
EOF
```

### Step 3: Allow Backend to Database

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
EOF
```

### Step 4: Test Connectivity

```bash
# Test frontend to backend
kubectl exec -it frontend-pod -- curl backend-service:8080

# Test backend to database
kubectl exec -it backend-pod -- psql database-service:5432

# Test frontend to database (should fail)
kubectl exec -it frontend-pod -- curl database-service:5432
```

### Step 5: Monitor Network Policies

```bash
# Get network policies
kubectl get networkpolicies -A

# Describe network policy
kubectl describe networkpolicy <name>

# Check network plugin logs
kubectl logs -n kube-system -l k8s-app=calico-node
```

---

## Custom Policies

### DNS Egress Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### External Access Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-access
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
```

### Ingress from Specific Namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-monitoring
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 9090
```

### Egress to Specific IP Range

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-database
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.1.0/24
      ports:
        - protocol: TCP
          port: 5432
```

---

## Integration

### CI/CD Integration

```yaml
# GitHub Actions workflow
name: Network Policy Check
on: [pull_request]
jobs:
  network-policy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install kubectl
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/
      
      - name: Check Network Policies
        run: |
          kubectl get networkpolicies -A
          kubectl describe networkpolicies -A
```

### ArgoCD Integration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: network-policies
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/network-policies.git
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
# ServiceMonitor for Network Policies
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: network-policies
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: calico-node
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
      "title": "Network Policy Violations",
      "type": "graph",
      "targets": [
        {
          "expr": "calico_network_policy_violations_total",
          "legendFormat": "{{namespace}}/{{policy}}"
        }
      ]
    },
    {
      "title": "Network Policy Enforcement",
      "type": "graph",
      "targets": [
        {
          "expr": "calico_network_policy_enforcement_duration_seconds",
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
  name: network-policy-role
rules:
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["get", "list", "watch"]
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: network-policy-network-policy
  namespace: kube-system
spec:
  podSelector:
    matchLabels:
      k8s-app: calico-node
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
          port: 179
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
  name: network-policy-pod
  namespace: kube-system
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
    - name: calico-node
      image: calico/node:v3.26.0
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

### Issue 1: Network Policy Not Working

**Symptoms**: Traffic not being blocked
**Diagnosis**:
```bash
kubectl get networkpolicies -A
kubectl describe networkpolicy <name>
```
**Solution**:
- Verify NetworkPolicy exists
- Check pod selector
- Verify network plugin supports NetworkPolicy

### Issue 2: Pods Cannot Communicate

**Symptoms**: Pods cannot reach each other
**Diagnosis**:
```bash
kubectl exec -it <pod> -- curl <service>:<port>
kubectl logs -n kube-system -l k8s-app=calico-node
```
**Solution**:
- Check NetworkPolicy rules
- Verify pod labels
- Review network plugin logs

### Issue 3: DNS Resolution Failing

**Symptoms**: Pods cannot resolve DNS
**Diagnosis**:
```bash
kubectl exec -it <pod> -- nslookup kubernetes.default
kubectl get networkpolicies -A | grep dns
```
**Solution**:
- Allow DNS egress traffic
- Check DNS service labels
- Verify DNS policy

### Issue 4: External Access Blocked

**Symptoms**: Pods cannot reach external services
**Diagnosis**:
```bash
kubectl exec -it <pod> -- curl google.com
kubectl get networkpolicies -A | grep egress
```
**Solution**:
- Allow egress to external IPs
- Check IPBlock rules
- Verify CIDR ranges

### Issue 5: Network Policy Conflict

**Symptoms**: Multiple policies conflicting
**Diagnosis**:
```bash
kubectl get networkpolicies -A -o yaml
kubectl describe networkpolicy <name1>
kubectl describe networkpolicy <name2>
```
**Solution**:
- Review policy priorities
- Check for overlapping rules
- Simplify policy structure

### Issue 6: Network Plugin Not Installed

**Symptoms**: NetworkPolicy not implemented
**Diagnosis**:
```bash
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
kubectl get daemonset -n kube-system
```
**Solution**:
- Install NetworkPolicy-capable plugin
- Verify plugin is running
- Check plugin logs

### Issue 7: Namespace Isolation Not Working

**Symptoms**: Cross-namespace traffic not blocked
**Diagnosis**:
```bash
kubectl get networkpolicies -A | grep namespace
kubectl describe namespace <name>
```
**Solution**:
- Check namespace selector
- Verify namespace labels
- Review policy rules

### Issue 8: Pod Selector Not Matching

**Symptoms**: Policy not applied to pods
**Diagnosis**:
```bash
kubectl get pods --show-labels
kubectl describe networkpolicy <name>
```
**Solution**:
- Check pod labels
- Verify selector syntax
- Test with kubectl describe

### Issue 9: Port Configuration Error

**Symptoms**: Specific ports blocked
**Diagnosis**:
```bash
kubectl exec -it <pod> -- nc -zv <service> <port>
kubectl get networkpolicies -A -o yaml | grep -A 5 ports
```
**Solution**:
- Check port definitions
- Verify protocol (TCP/UDP)
- Test connectivity

### Issue 10: CIDR Range Error

**Symptoms**: IP range not allowed
**Diagnosis**:
```bash
kubectl get networkpolicies -A -o yaml | grep -A 5 cidr
kubectl exec -it <pod> -- curl <ip>:<port>
```
**Solution**:
- Check CIDR syntax
- Verify IP ranges
- Test with kubectl exec

### Issue 11: Network Policy Audit Not Working

**Symptoms**: No audit logs
**Diagnosis**:
```bash
kubectl logs -n kube-system -l k8s-app=calico-node | grep -i audit
```
**Solution**:
- Enable audit logging
- Check audit configuration
- Review audit logs

### Issue 12: Network Policy Performance Issues

**Symptoms**: Slow network performance
**Diagnosis**:
```bash
kubectl top pods -n kube-system
kubectl logs -n kube-system -l k8s-app=calico-node | grep -i duration
```
**Solution**:
- Optimize policy rules
- Reduce number of policies
- Increase resources

### Issue 13: Network Policy Not Syncing

**Symptoms**: Policy not applied to nodes
**Diagnosis**:
```bash
kubectl get networkpolicies -A
kubectl logs -n kube-system -l k8s-app=calico-node | grep -i sync
```
**Solution**:
- Check network plugin status
- Verify policy synchronization
- Restart network plugin

### Issue 14: Network Policy Not Applied to New Pods

**Symptoms**: New pods not protected
**Diagnosis**:
```bash
kubectl get pods --show-labels
kubectl describe networkpolicy <name>
```
**Solution**:
- Verify pod labels match selector
- Check policy is applied to namespace
- Test with kubectl describe

### Issue 15: Network Policy Not Applied to Existing Pods

**Symptoms**: Existing pods not protected
**Diagnosis**:
```bash
kubectl get pods --show-labels
kubectl describe networkpolicy <name>
```
**Solution**:
- Verify pod labels match selector
- Check policy is applied to namespace
- Test with kubectl describe

---

## Tips and Best Practices

### 1. Start with Default Deny

```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### 2. Use Namespace Isolation

```yaml
# Isolate namespaces
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: namespace-isolation
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              environment: production
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              environment: production
```

### 3. Allow DNS Egress

```yaml
# Always allow DNS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### 4. Use Specific Pod Selectors

```yaml
# Use specific labels
spec:
  podSelector:
    matchLabels:
      app: nginx
      environment: production
```

### 5. Implement Gradual Rollout

```bash
# Phase 1: Audit mode
kubectl apply -f network-policy-audit.yaml

# Phase 2: Enforce mode
kubectl apply -f network-policy-enforce.yaml
```

### 6. Use Labels for Policy Selection

```yaml
# Label namespaces for policy selection
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    network-policy: enabled
```

### 7. Monitor Network Policies

```yaml
# Enable Prometheus metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: network-policies
spec:
  endpoints:
    - port: metrics
      path: /metrics
```

### 8. Use GitOps for Policy Management

```bash
# Store policies in Git
git add policies/
git commit -m "Update network policies"
git push origin main

# Apply with ArgoCD or Flux
```

### 9. Test Policies Locally

```bash
# Test with kubectl
kubectl apply -f network-policy.yaml --dry-run=server

# Test with dry-run
kubectl apply -f network-policy.yaml --dry-run=client
```

### 10. Use Labels for Policy Selection

```yaml
# Label namespaces for policy selection
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    network-policy: enabled
```

### 11. Implement Caching

```yaml
# Enable caching
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
```

### 12. Use External Data

```yaml
spec:
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
            except:
              - 10.0.1.0/24
```

### 13. Implement Policy Versioning

```bash
# Version policies
git tag -a v1.0.0 -m "Policy version 1.0.0"
git push origin v1.0.0

# Use specific version
kubectl apply -f network-policy-v1.0.0.yaml
```

### 14. Use Policy Coverage

```bash
# Check policy coverage
kubectl get networkpolicies -A
kubectl describe networkpolicies -A
```

### 15. Implement Policy Documentation

```yaml
# policy/README.md
# Network Policy

This policy controls network traffic between pods.

## Usage

```bash
kubectl apply -f network-policy.yaml
```

## Rules

- Deny all traffic by default
- Allow frontend to backend
- Allow backend to database
- Allow DNS egress
```

---

## Command Reference

### Basic Commands

```bash
# Get network policies
kubectl get networkpolicies -A

# Describe network policy
kubectl describe networkpolicy <name>

# Create network policy
kubectl apply -f network-policy.yaml

# Delete network policy
kubectl delete networkpolicy <name>
```

### Debugging Commands

```bash
# Get network plugin logs
kubectl logs -n kube-system -l k8s-app=calico-node

# Get network plugin pods
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"

# Test connectivity
kubectl exec -it <pod> -- curl <service>:<port>

# Test DNS resolution
kubectl exec -it <pod> -- nslookup kubernetes.default
```

### Monitoring Commands

```bash
# Get network policy metrics
kubectl get --raw /metrics | grep -i network

# Get network plugin metrics
kubectl get --raw /metrics | grep -i calico

# Get network policy events
kubectl get events --field-selector reason=NetworkPolicy
```

### Debugging Commands

```bash
# Get network plugin logs
kubectl logs -n kube-system -l k8s-app=calico-node

# Get network plugin pods
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"

# Test connectivity
kubectl exec -it <pod> -- curl <service>:<port>

# Test DNS resolution
kubectl exec -it <pod> -- nslookup kubernetes.default
```

---

## CRD Reference

### NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
```

### Namespace Labels

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    network-policy: enabled
```

### Pod Labels

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
    environment: production
spec:
  containers:
    - name: nginx
      image: nginx:latest
```

---

## Real-World Examples

### Production Cluster Policies

```yaml
# production-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: production-network-policy
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              environment: production
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              environment: production
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Micro-Segmentation

```yaml
# micro-segmentation.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: micro-segmentation
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 8080
```

### Database Isolation

```yaml
# database-isolation.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-isolation
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 5432
  egress: []
```

### External Access

```yaml
# external-access.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: external-access
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 10.0.0.0/8
              - 172.16.0.0/12
              - 192.168.0.0/16
```

---

## Further Reading

### Official Documentation

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [Cilium Documentation](https://docs.cilium.io/)

### Community Resources

- [Network Policy Examples](https://github.com/kubernetes/website/tree/main/content/en/examples/service/networking/)
- [Calico Network Policies](https://docs.projectcalico.org/security/)
- [Cilium Network Policies](https://docs.cilium.io/en/stable/security/)

### Books and Tutorials

- "Kubernetes Networking" by O'Reilly
- "Network Policies" by CNCF
- "Kubernetes Security Patterns" by Christian Posta

### Videos and Talks

- "Network Policies Deep Dive" by CNCF
- "Kubernetes Networking" by KubeCon
- "Network Policy Patterns" by ThoughtWorks

### Related Projects

- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Kyverno](https://kyverno.io/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
