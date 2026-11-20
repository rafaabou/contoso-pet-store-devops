# kube-bench Complete Guide

## Table of Contents

1. What Is kube-bench
2. Why Use kube-bench
3. Architecture Overview
4. Installation and Setup
5. Core Concepts
6. Usage Guide
7. CIS Kubernetes Benchmark Controls
8. Integration with Kubernetes
9. Custom Policies
10. Security
11. Troubleshooting
12. Tips and Best Practices
13. Command Reference
14. Configuration Reference
15. Real-World Examples
16. Further Reading

---

## 1. What Is kube-bench

kube-bench is a tool that checks whether Kubernetes is deployed securely by running the checks documented in the CIS Kubernetes Benchmark. It is an open-source tool developed by Aqua Security and is the official tool for checking CIS Kubernetes Benchmark compliance.

### 1.1 Overview

kube-bench is:
- **CIS Benchmark Implementation**: Automated checks for CIS Kubernetes Benchmark
- **Open Source**: Freely available and community-driven
- **Kubernetes Native**: Designed specifically for Kubernetes environments
- **Comprehensive**: Covers master, worker, and policy controls
- **Extensible**: Supports custom checks and configurations

### 1.2 Key Features

- **Automated Scanning**: Runs all CIS Benchmark checks automatically
- **Multiple Output Formats**: JSON, JUnit XML, CSV output
- **Remediation Guidance**: Provides remediation instructions for failed checks
- **In-Cluster Execution**: Can run as a Kubernetes Job
- **Custom Checks**: Support for organization-specific controls
- **Integration Ready**: Works with Prometheus, Grafana, CI/CD pipelines
- **Cloud Provider Support**: AWS, GCP, Azure specific checks

### 1.3 Comparison with Other Tools

| Feature | kube-bench | CIS-CAT | Lynis |
|---------|-----------|---------|-------|
| Kubernetes-specific | Yes | Partial | No |
| Open source | Yes | No | Yes |
| CIS Benchmark official | No (community) | Yes | No |
| In-cluster execution | Yes | No | No |
| Custom checks | Yes | Limited | Yes |
| Free | Yes | No (paid) | Yes |

---

## 2. Why Use kube-bench

### 2.1 Benefits

**Security Assurance**
- Verify Kubernetes cluster security configuration
- Identify misconfigurations before they are exploited
- Validate compliance with industry best practices

**Compliance**
- Meet regulatory requirements (PCI DSS, HIPAA, SOC 2)
- Pass security audits and assessments
- Demonstrate due diligence in security practices

**Operational Excellence**
- Automate security validation in CI/CD pipelines
- Reduce manual security review effort
- Enable shift-left security practices

**Risk Reduction**
- Identify and remediate security gaps
- Reduce attack surface
- Minimize risk of security incidents

### 2.2 Use Cases

**DevSecOps**
- Integrate security checks into deployment pipelines
- Gate releases on compliance scores
- Shift-left security validation

**SRE and Platform Engineering**
- Validate cluster security posture
- Monitor configuration drift
- Ensure consistent security configurations

**Compliance Teams**
- Generate compliance evidence
- Track compliance trends over time
- Prepare for security audits

**Security Teams**
- Identify security misconfigurations
- Prioritize remediation efforts
- Track security improvements

### 2.3 Prerequisites

- Running Kubernetes cluster (v1.15+)
- kubectl access to the cluster
- Understanding of Kubernetes security concepts
- Familiarity with CIS Kubernetes Benchmark
- Administrative access for in-cluster execution

---

## 3. Architecture Overview

### 3.1 Execution Modes

**Local Execution**

```
+-------------------+     +-------------------+
| kube-bench CLI    | --> | Kubernetes API    |
| (local machine)   |     | Server            |
+-------------------+     +-------------------+
        |
        v
+-------------------+
| kubeconfig file   |
| (cluster access)  |
+-------------------+
```

**In-Cluster Execution**

```
+-------------------+     +-------------------+
| kube-bench Pod    | --> | Kubernetes API    |
| (in cluster)      |     | Server            |
+-------------------+     +-------------------+
        |
        v
+-------------------+
| ServiceAccount    |
| (RBAC permissions)|
+-------------------+
```

### 3.2 Component Architecture

```
+---------------------------------------------------+
|                kube-bench Architecture              |
|  +----------+  +----------+  +------------------+ |
|  | Scanner  |  | Checker  |  | Reporter         | |
|  |          |  |          |  | (JSON/JUnit/CSV) | |
|  +----------+  +----------+  +------------------+ |
|         |              |              |             |
|         +--------------+--------------+             |
|                        |                            |
|              +---------v---------+                  |
|              | CIS Benchmark     |                  |
|              | Controls          |                  |
|              | (YAML files)      |                  |
|              +-------------------+                  |
+--------------------------+-------------------------+
                           |
              +------------+------------+
              |            |            |
       +------v------+ +--v------+ +--v------+
       | Master      | | Worker  | | Policy  |
       | Checks      | | Checks  | | Checks  |
       +-------------+ +---------+ +---------+
```

### 3.3 Check Execution Flow

```
1. Load Benchmark -> Load CIS Benchmark control definitions
2. Discover Components -> Identify Kubernetes components
3. Run Checks -> Execute each check against components
4. Evaluate Results -> Pass/Fail/Warn/Info
5. Generate Report -> Output results in specified format
6. Provide Remediation -> Show remediation for failed checks
```

---

## 4. Installation and Setup

### 4.1 Installation Options

**Binary Installation**

```bash
# Download latest release
KUBE_BENCH_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/kube-bench/releases/latest | jq -r .tag_name)
curl -L https://github.com/aquasecurity/kube-bench/releases/download/${KUBE_BENCH_VERSION}/kube-bench_${KUBE_BENCH_VERSION}_linux_amd64.tar.gz -o kube-bench.tar.gz

# Extract
tar -xzf kube-bench.tar.gz

# Install
sudo mv kube-bench /usr/local/bin/

# Verify
kube-bench version
```

**Docker Installation**

```bash
# Pull image
docker pull aquasec/kube-bench:latest

# Run locally
docker run --rm aquasec/kube-bench:latest version

# Run in-cluster (requires Docker-in-Docker)
docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v /usr/lib:/usr/lib:ro \
  aquasec/kube-bench:latest
```

**Helm Installation (In-Cluster)**

```bash
# Add Helm repo
helm repo add kube-bench https://aquasecurity.github.io/helm-charts
helm repo update

# Install
helm install kube-bench kube-bench/kube-bench \
  --namespace kube-bench \
  --create-namespace \
  --set image.tag=latest

# Run as CronJob
helm install kube-bench kube-bench/kube-bench \
  --namespace kube-bench \
  --set runAsJob=true \
  --set schedule="0 2 * * 1"
```

**Kubernetes Job Manifest**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench
  namespace: kube-bench
spec:
  template:
    spec:
      hostPID: true
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench", "run", "--targets", "master,worker,policies"]
        volumeMounts:
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
          readOnly: true
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
          readOnly: true
      restartPolicy: Never
      volumes:
      - name: var-lib-kubelet
        hostPath:
          path: /var/lib/kubelet
      - name: etc-kubernetes
        hostPath:
          path: /etc/kubernetes
  backoffLimit: 0
```

### 4.2 RBAC Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-bench
  namespace: kube-bench
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-bench
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
  verbs: ["get", "list"]
- apiGroups: ["security.openshift.io"]
  resources: ["securitycontextconstraints"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-bench
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-bench
subjects:
- kind: ServiceAccount
  name: kube-bench
  namespace: kube-bench
```

### 4.3 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kube-bench-network-policy
  namespace: kube-bench
spec:
  podSelector:
    matchLabels:
      app: kube-bench
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 6443
```

---

## 5. Core Concepts

### 5.1 Benchmark Structure

```yaml
# CIS Kubernetes Benchmark Structure
controls:
  - id: "1"
    name: "Master Components"
    description: "Checks for Kubernetes master components"
    checks:
      - id: "1.1.1"
        description: "Ensure that the --anonymous-auth argument is set to false"
        audit: "ps -ef | grep kube-apiserver | grep -v grep"
        tests:
          test_items:
            - flag: "--anonymous-auth"
              compare:
                op: eq
                value: false
        remediation: "Edit the API server pod specification file and set --anonymous-auth=false"
        scored: true
      
      - id: "1.1.2"
        description: "Ensure that the --basic-auth-file argument is not set"
        audit: "ps -ef | grep kube-apiserver | grep -v grep"
        tests:
          test_items:
            - flag: "--basic-auth-file"
              set: false
        remediation: "Remove the --basic-auth-file argument from the API server"
        scored: true
```

### 5.2 Check Types

**Command Checks**
```yaml
checks:
  - id: "1.1.1"
    audit: "ps -ef | grep kube-apiserver | grep -v grep"
    tests:
      test_items:
        - flag: "--anonymous-auth"
          compare:
            op: eq
            value: false
```

**File Permission Checks**
```yaml
checks:
  - id: "1.1.15"
    audit: "stat -c %a /etc/kubernetes/manifests/kube-apiserver.yaml"
    tests:
      test_items:
        - flag: "permission"
          compare:
            op: bitmask
            value: "644"
```

**File Ownership Checks**
```yaml
checks:
  - id: "1.1.16"
    audit: "stat -c %U:%G /etc/kubernetes/manifests/kube-apiserver.yaml"
    tests:
      test_items:
        - flag: "ownership"
          compare:
            op: eq
            value: "root:root"
```

**Kubernetes API Checks**
```yaml
checks:
  - id: "5.1.1"
    audit: "kubectl get clusterrolebindings -o json"
    tests:
      test_items:
        - path: '{range .items[*]}{.roleRef.name}{"\n"}{end}'
          compare:
            op: not_in
            value: ["cluster-admin"]
```

### 5.3 Test Evaluation

**Comparison Operators**
- `eq`: Equals
- `noteq`: Not equals
- `gt`: Greater than
- `gte`: Greater than or equal
- `lt`: Less than
- `lte`: Less than or equal
- `in`: Value in list
- `notin`: Value not in list
- `bitmask`: Bitwise AND comparison

**Logical Operators**
- `and`: All conditions must be true
- `or`: At least one condition must be true
- `not`: Negate condition

### 5.4 Scoring

```yaml
scoring:
  # Controls with scored: true contribute to score
  # Controls with scored: false are informational only
  
  summary:
    pass: 85
    fail: 10
    warn: 3
    info: 2
    total: 100
  
  # Score calculation
  score: (pass / (pass + fail)) * 100
```

---

## 6. Usage Guide

### 6.1 Basic Scanning

**Run All Checks**

```bash
# Run all checks for all targets
kube-bench run

# Run checks for master only
kube-bench run --targets master

# Run checks for worker only
kube-bench run --targets worker

# Run checks for policies only
kube-bench run --targets policies
```

**Run Specific Checks**

```bash
# Run specific control family
kube-bench run --targets master --check 1.1

# Run specific check
kube-bench run --targets master --check 1.1.1

# Run multiple checks
kube-bench run --targets master --check 1.1.1,1.1.2,1.1.3
```

### 6.2 Output Formats

**JSON Output**

```bash
# Generate JSON report
kube-bench run --json > report.json

# Parse results
cat report.json | jq '.summary'
cat report.json | jq '.controls[].checks[] | select(.status == "FAIL")'
```

**JUnit XML Output**

```bash
# Generate JUnit XML for CI/CD
kube-bench run --junit > report.xml

# Integrate with test frameworks
# (e.g., Jenkins, GitHub Actions, GitLab CI)
```

**CSV Output**

```bash
# Generate CSV for analysis
kube-bench run --csv > report.csv

# Import into spreadsheet
# Analyze compliance trends
```

### 6.3 Remediation

**Show Remediation Instructions**

```bash
# Show remediation for failed checks
kube-bench run --targets master --remediate

# Show remediation for specific check
kube-bench run --targets master --check 1.1.1 --remediate
```

**Auto-Remediation**

```bash
# Apply remediation (use with caution)
kube-bench run --targets master --remediate --apply

# Preview changes first
kube-bench run --targets master --remediate | less
```

### 6.4 In-Cluster Execution

**Run as Pod**

```bash
# Create and run pod
kubectl run kube-bench --image=aquasec/kube-bench:latest --restart=Never --hostPID=true

# Check logs
kubectl logs kube-bench

# Delete pod
kubectl delete pod kube-bench
```

**Run as Job**

```bash
# Apply job manifest
kubectl apply -f kube-bench-job.yaml

# Check job status
kubectl get jobs -n kube-bench

# View logs
kubectl logs -l job-name=kube-bench -n kube-bench

# Delete job
kubectl delete job kube-bench -n kube-bench
```

**Run as CronJob**

```bash
# Apply cronjob manifest
kubectl apply -f kube-bench-cronjob.yaml

# Check cronjob status
kubectl get cronjobs -n kube-bench

# View recent jobs
kubectl get jobs -n kube-bench --sort-by=.metadata.creationTimestamp
```

### 6.5 Configuration

**Custom kubeconfig**

```bash
# Use specific kubeconfig
kube-bench run --kubeconfig /path/to/kubeconfig

# Use in-cluster config
kube-bench run --kubeconfig /var/run/secrets/kubernetes.io/serviceaccount/token
```

**Target Selection**

```bash
# Run all targets
kube-bench run --targets master,worker,policies

# Run multiple targets
kube-bench run --targets master,worker

# Run specific target
kube-bench run --targets master
```

---

## 7. CIS Kubernetes Benchmark Controls

### 7.1 Master Components (Control Family 1)

**API Server (1.1)**

| Control | Description | Severity |
|---------|-------------|----------|
| 1.1.1 | --anonymous-auth=false | Critical |
| 1.1.2 | --basic-auth-file not set | Critical |
| 1.1.3 | --token-auth-file not set | Critical |
| 1.1.4 | --kubelet-https=true | Medium |
| 1.1.5 | --kubelet-client-certificate and --kubelet-client-key set | High |
| 1.1.6 | --kubelet-certificate-authority set | High |
| 1.1.7 | --authorization-mode not set to AlwaysAllow | Critical |
| 1.1.8 | --authorization-mode includes Node | High |
| 1.1.9 | --authorization-mode includes RBAC | High |
| 1.1.10 | --insecure-bind-address not set | Critical |
| 1.1.11 | --insecure-port set to 0 | Critical |
| 1.1.12 | --secure-port set to 6443 | Medium |
| 1.1.13 | --profiling set to false | Medium |
| 1.1.14 | --audit-log-path set | High |
| 1.1.15 | --audit-log-maxage set to appropriate value | Medium |
| 1.1.16 | --audit-log-maxbackup set to appropriate value | Medium |
| 1.1.17 | --audit-log-maxsize set to appropriate value | Medium |
| 1.1.18 | --request-timeout set appropriately | Medium |
| 1.1.19 | --service-account-lookup set to true | High |
| 1.1.20 | --service-account-key-file set | High |
| 1.1.21 | --service-account-signing-key-file set | High |
| 1.1.22 | --etcd-certfile and --etcd-keyfile set | High |
| 1.1.23 | --tls-cert-file and --tls-private-key-file set | High |
| 1.1.24 | --client-ca-file set | High |
| 1.1.25 | --etcd-cafile set | High |

**Controller Manager (1.2)**

| Control | Description | Severity |
|---------|-------------|----------|
| 1.2.1 | --terminated-pod-gc-threshold set | Medium |
| 1.2.2 | --profiling set to false | Medium |
| 1.2.3 | --use-service-account-credentials set to true | High |
| 1.2.4 | --service-account-private-key-file set | High |
| 1.2.5 | --root-ca-file set | High |
| 1.2.6 | --leader-elect set to true | Medium |

**Scheduler (1.3)**

| Control | Description | Severity |
|---------|-------------|----------|
| 1.3.1 | --profiling set to false | Medium |
| 1.3.2 | --leader-elect set to true | Medium |

**etcd (1.4)**

| Control | Description | Severity |
|---------|-------------|----------|
| 1.4.1 | --cert-file and --key-file set | High |
| 1.4.2 | --client-cert-auth set to true | High |
| 1.4.3 | --auto-tls not set to true | High |
| 1.4.4 | --peer-cert-file and --peer-key-file set | High |
| 1.4.5 | --peer-client-cert-auth set to true | High |
| 1.4.6 | --peer-auto-tls not set to true | High |
| 1.4.7 | Unique CA for etcd | High |

### 7.2 Worker Components (Control Family 2)

**kubelet (2.1)**

| Control | Description | Severity |
|---------|-------------|----------|
| 2.1.1 | kubelet config file permissions 644 | Medium |
| 2.1.2 | kubelet config file ownership root:root | Medium |
| 2.1.3 | --anonymous-auth set to false | Critical |
| 2.1.4 | --authorization-mode set to Webhook | High |
| 2.1.5 | --client-ca-file set | High |
| 2.1.6 | --read-only-port set to 0 | High |
| 2.1.7 | --streaming-connection-idle-timeout set appropriately | Medium |
| 2.1.8 | --protect-kernel-defaults set to true | High |
| 2.1.9 | --make-iptables-util-chains set to true | Medium |
| 2.1.10 | --hostname-override set appropriately | Medium |
| 2.1.11 | --event-qps set appropriately | Medium |
| 2.1.12 | --tls-cert-file and --tls-private-key-file set | High |
| 2.1.13 | --tls-cipher-suites set appropriately | Medium |
| 2.1.14 | --rotate-certificates set to true | High |
| 2.1.15 | --rotate-certificates set to true | High |
| 2.1.16 | --feature-gates="RotateKubeletServerCertificate=true" | High |

**kube-proxy (2.2)**

| Control | Description | Severity |
|---------|-------------|----------|
| 2.2.1 | --metrics-bind-address set appropriately | Medium |
| 2.2.2 | --conntrack-max-per-core set appropriately | Medium |
| 2.2.3 | --conntrack-tcp-timeout-established set appropriately | Medium |
| 2.2.4 | --kubeconfig set appropriately | High |
| 2.2.5 | --kube-proxy-arg set appropriately | Medium |

### 7.3 Policies (Control Family 3)

**RBAC and Service Accounts (3.1)**

| Control | Description | Severity |
|---------|-------------|----------|
| 3.1.1 | cluster-admin role used only where required | High |
| 3.1.2 | Minimize use of wildcards | High |
| 3.1.3 | Minimize access to secrets | High |
| 3.1.4 | Default service account not used | Medium |
| 3.1.5 | Service account tokens not mounted automatically | Medium |

**Pod Security (3.2)**

| Control | Description | Severity |
|---------|-------------|----------|
| 3.2.1 | Minimize admission of privileged containers | Critical |
| 3.2.2 | Minimize admission of containers wishing to share host process ID namespace | High |
| 3.2.3 | Minimize admission of containers wishing to share host IPC namespace | High |
| 3.2.4 | Minimize admission of containers wishing to share host network namespace | High |
| 3.2.5 | Minimize admission of containers with allowPrivilegeEscalation | High |
| 3.2.6 | Minimize admission of root containers | High |
| 3.2.7 | Minimize admission of containers with added capabilities | High |
| 3.2.8 | Minimize admission of containers with the NET_RAW capability | High |
| 3.2.9 | Minimize admission of containers with the SYS_ADMIN capability | High |

**Network Policies (3.3)**

| Control | Description | Severity |
|---------|-------------|----------|
| 3.3.1 | Ensure all namespaces have Network Policies defined | Medium |
| 3.3.2 | Ensure kubelet is configured to only listen on HTTPS | High |
| 3.3.3 | Ensure kubelet is configured to not admit containers with hostNetwork | High |

**Secrets Management (3.4)**

| Control | Description | Severity |
|---------|-------------|----------|
| 3.4.1 | Prefer using Secrets as files over environment variables | Medium |
| 3.4.2 | Consider external secret storage | Medium |

---

## 8. Integration with Kubernetes

### 8.1 Running as Kubernetes Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench-master
  namespace: kube-bench
spec:
  template:
    spec:
      hostPID: true
      nodeSelector:
        node-role.kubernetes.io/master: ""
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench", "run", "--targets", "master"]
        volumeMounts:
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
          readOnly: true
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
          readOnly: true
      restartPolicy: Never
      serviceAccountName: kube-bench
      volumes:
      - name: var-lib-kubelet
        hostPath:
          path: /var/lib/kubelet
      - name: etc-kubernetes
        hostPath:
          path: /etc/kubernetes
  backoffLimit: 0
```

### 8.2 Running as CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kube-bench
  namespace: kube-bench
spec:
  schedule: "0 2 * * 1"
  jobTemplate:
    spec:
      template:
        spec:
          hostPID: true
          containers:
          - name: kube-bench
            image: aquasec/kube-bench:latest
            command: ["kube-bench", "run", "--json", "--outputfile", "/results/report.json"]
            volumeMounts:
            - name: results
              mountPath: /results
          restartPolicy: Never
          volumes:
          - name: results
            persistentVolumeClaim:
              claimName: kube-bench-results
```

### 8.3 DaemonSet for Continuous Monitoring

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-bench
  namespace: kube-bench
spec:
  selector:
    matchLabels:
      app: kube-bench
  template:
    metadata:
      labels:
        app: kube-bench
    spec:
      hostPID: true
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench", "run", "--json", "--outputfile", "/results/report.json"]
        volumeMounts:
        - name: results
          mountPath: /results
      volumes:
      - name: results
        hostPath:
          path: /var/lib/kube-bench
```

### 8.4 Prometheus Integration

```yaml
# ServiceMonitor for kube-bench metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kube-bench
  namespace: kube-bench
spec:
  selector:
    matchLabels:
      app: kube-bench
  endpoints:
  - port: metrics
    interval: 30s
```

---

## 9. Custom Policies

### 9.1 Custom Check Definition

```yaml
# custom-controls.yaml
controls:
  - id: "custom-1"
    name: "Custom Security Controls"
    description: "Organization-specific security checks"
    checks:
      - id: "custom-1.1"
        description: "Ensure cluster has required labels"
        audit: "kubectl get nodes -o json"
        tests:
          test_items:
            - path: "{.items[*].metadata.labels}"
              check:
                key: "environment"
                op: exists
              assign: "environment_label"
        remediation: "Add environment label to all nodes"

      - id: "custom-1.2"
        description: "Ensure required namespaces exist"
        audit: "kubectl get namespaces -o json"
        tests:
          test_items:
            - path: "{.items[*].metadata.name}"
              check:
                op: contains
                value: "production"
        remediation: "Create production namespace"
```

### 9.2 Custom Configuration File

```yaml
# kube-bench-config.yaml
master:
  apiServer:
    config: /etc/kubernetes/manifests/kube-apiserver.yaml
    kubeconfig: /etc/kubernetes/admin.conf
  
  controllerManager:
    config: /etc/kubernetes/manifests/kube-controller-manager.yaml
  
  scheduler:
    config: /etc/kubernetes/manifests/kube-scheduler.yaml
  
  etcd:
    config: /etc/kubernetes/manifests/etcd.yaml

worker:
  kubelet:
    config: /var/lib/kubelet/config.yaml
    kubeconfig: /var/lib/kubelet/kubeconfig

policies:
  podSecurity:
    enabled: true
    profile: restricted
  
  networkPolicies:
    enabled: true
  
  rbac:
    enabled: true
```

### 9.3 Custom Control Families

```yaml
# custom-control-families.yaml
controlFamilies:
  - id: "custom-1"
    name: "Application Security"
    description: "Application-level security checks"
    controls:
      - id: "custom-1.1"
        description: "Ensure application uses non-root user"
        audit: |
          kubectl get pods --all-namespaces -o json | \
          jq '.items[] | select(.spec.containers[].securityContext.runAsNonRoot == false) | .metadata.name'
        remediation: "Configure securityContext.runAsNonRoot: true"

      - id: "custom-1.2"
        description: "Ensure application has resource limits"
        audit: |
          kubectl get pods --all-namespaces -o json | \
          jq '.items[] | select(.spec.containers[].resources.limits == null) | .metadata.name'
        remediation: "Add resource limits to containers"

  - id: "custom-2"
    name: "Operational Security"
    description: "Operational security checks"
    controls:
      - id: "custom-2.1"
        description: "Ensure pod disruption budgets are configured"
        audit: |
          kubectl get pdb --all-namespaces
        remediation: "Create PodDisruptionBudgets for critical workloads"
```

### 9.4 Integrating Custom Checks

```bash
# Run with custom controls
kube-bench run --targets master --config custom-controls.yaml

# Combine with standard checks
kube-bench run --targets master,worker --config custom-config.yaml

# Export custom checks for CI/CD
kube-bench run --targets master --config custom-controls.yaml --json > custom-results.json
```

---

## 10. Security

### 10.1 Security Best Practices

**RBAC Configuration**
- Use dedicated ServiceAccount for kube-bench
- Apply principle of least privilege
- Restrict access to sensitive resources
- Audit all kube-bench operations

**Network Security**
- Use network policies to restrict kube-bench traffic
- Encrypt communication with API server
- Limit access to Kubernetes API

**Pod Security**
- Run kube-bench as non-root when possible
- Use read-only root filesystem
- Drop unnecessary capabilities
- Apply security context constraints

### 10.2 ServiceAccount Configuration

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-bench
  namespace: kube-bench
  annotations:
    description: "Service account for kube-bench security scanning"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-bench
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "configmaps", "namespaces"]
  verbs: ["get", "list"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
  verbs: ["get", "list"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["get", "list"]
- apiGroups: ["policy"]
  resources: ["podsecuritypolicies"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-bench
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-bench
subjects:
- kind: ServiceAccount
  name: kube-bench
  namespace: kube-bench
```

### 10.3 Security Context

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-bench
  namespace: kube-bench
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: kube-bench
    image: aquasec/kube-bench:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

---

## 11. Troubleshooting

### 11.1 Common Issues and Solutions

**Issue 1: kube-bench cannot find API server**

```bash
# Check kubeconfig
kubectl config view

# Verify API server endpoint
kubectl cluster-info

# Test connectivity
kube-bench run --kubeconfig /etc/kubernetes/admin.conf

# Fix: Ensure correct kubeconfig path
```

**Issue 2: Permission denied errors**

```bash
# Check ServiceAccount
kubectl get sa kube-bench -n kube-bench

# Check ClusterRoleBinding
kubectl get clusterrolebinding kube-bench

# Test permissions
kubectl auth can-i get nodes --as=system:serviceaccount:kube-bench:kube-bench

# Fix: Update RBAC permissions
```

**Issue 3: Host PID namespace not accessible**

```bash
# Verify hostPID setting
kubectl get pod kube-bench -n kube-bench -o yaml | grep hostPID

# Check if hostPID is enabled
# Fix: Enable hostPID in pod spec
```

**Issue 4: kubelet config not found**

```bash
# Check kubelet config location
ls -la /var/lib/kubelet/config.yaml

# Verify kubelet is using config file
ps -ef | grep kubelet | grep config

# Fix: Ensure kubelet config file exists and is accessible
```

**Issue 5: Control plane components not detected**

```bash
# Check component labels
kubectl get nodes --show-labels

# Verify control plane components
kubectl get pods -n kube-system

# Fix: Ensure proper node labels and component identification
```

**Issue 6: Custom checks not running**

```bash
# Verify custom control file syntax
kube-bench run --config custom-controls.yaml --json

# Check for YAML errors
yamllint custom-controls.yaml

# Fix: Validate custom control file format
```

**Issue 7: Scan results not persisting**

```bash
# Check volume mount
kubectl get pod kube-bench -n kube-bench -o yaml | grep -A 5 volumeMounts

# Verify PVC is bound
kubectl get pvc -n kube-bench

# Fix: Configure persistent storage for results
```

**Issue 8: CronJob not scheduling**

```bash
# Check CronJob status
kubectl get cronjobs -n kube-bench

# Check recent jobs
kubectl get jobs -n kube-bench --sort-by=.metadata.creationTimestamp

# Verify schedule
kubectl describe cronjob kube-bench -n kube-bench

# Fix: Verify cron schedule and job history limits
```

**Issue 9: High resource consumption**

```bash
# Monitor resource usage
kubectl top pods -n kube-bench

# Check resource limits
kubectl get pod kube-bench -n kube-bench -o yaml | grep -A 5 resources

# Fix: Adjust resource limits and requests
```

**Issue 10: Scan timeout**

```bash
# Increase timeout
kube-bench run --targets master --timeout 600

# Run specific controls
kube-bench run --targets master --check 1.1

# Fix: Optimize scan scope or increase timeout
```

**Issue 11: False positives**

```bash
# Review control descriptions
kube-bench run --json | jq '.controls[].checks[] | select(.status == "FAIL") | {id, description}'

# Document exceptions
# Fix: Review each finding and document legitimate exceptions
```

**Issue 12: Benchmark version mismatch**

```bash
# Check kube-bench version
kube-bench version

# Verify Kubernetes version
kubectl version

# Download correct benchmark version
# Fix: Use benchmark version matching your Kubernetes version
```

**Issue 13: Cannot run as non-root**

```bash
# Check security context
kubectl get pod kube-bench -n kube-bench -o yaml | grep securityContext

# Verify non-root user
# Fix: Configure appropriate security context
```

**Issue 14: Network connectivity issues**

```bash
# Test API server connectivity
kubectl get nodes

# Check network policies
kubectl get networkpolicies -n kube-bench

# Fix: Update network policies to allow kube-bench traffic
```

**Issue 15: Results not matching manual checks**

```bash
# Compare automated vs manual results
kube-bench run --json | jq '.controls[].checks[] | select(.status == "FAIL")'

# Verify check logic
# Fix: Review each check and validate against manual verification
```

---

## 12. Tips and Best Practices

### 12.1 Scanning Best Practices

1. **Schedule regular scans**: Run kube-bench daily or weekly
2. **Monitor trends**: Track compliance scores over time
3. **Set thresholds**: Define minimum compliance requirements
4. **Alert on drift**: Notify when compliance drops below threshold
5. **Integrate with CI/CD**: Include compliance checks in deployment pipeline

### 12.2 Remediation Best Practices

6. **Prioritize findings**: Address critical findings first
7. **Test in staging**: Validate changes before production
8. **Document exceptions**: Record and approve all exceptions
9. **Verify remediation**: Run follow-up scans after remediation
10. **Rollback plan**: Have rollback procedures ready

### 12.3 Organizational Best Practices

11. **Assign ownership**: Designate compliance owners for each control
12. **Regular training**: Train teams on CIS Kubernetes Benchmark
13. **Share knowledge**: Document lessons learned
14. **Continuous improvement**: Regularly review and update processes
15. **Executive visibility**: Report compliance status to leadership

### 12.4 Technical Best Practices

16. **Version control**: Store benchmark configurations in version control
17. **Infrastructure-as-Code**: Implement compliance as code
18. **Immutable infrastructure**: Use immutable infrastructure patterns
19. **Defense-in-depth**: Layer security controls
20. **Least privilege**: Implement principle of least privilege

### 12.5 Advanced Tips

21. **Custom checks**: Extend kube-bench with organization-specific controls
22. **Multi-cluster**: Deploy kube-bench across multiple clusters
23. **Centralized reporting**: Aggregate results from multiple clusters
24. **Automated remediation**: Use tools like Ansible or Terraform for remediation
25. **Compliance dashboards**: Create dashboards for compliance visibility

---

## 13. Command Reference

### 13.1 kube-bench CLI Commands

```bash
# Basic Commands
kube-bench version                                      # Show version
kube-bench run                                           # Run all checks
kube-bench run --targets master                          # Run master checks
kube-bench run --targets worker                          # Run worker checks
kube-bench run --targets policies                        # Run policy checks

# Specific Checks
kube-bench run --check 1.1.1                            # Run specific check
kube-bench run --targets master --check 1.1              # Run specific control

# Output Formats
kube-bench run --json                                   # JSON output
kube-bench run --junit                                  # JUnit XML output
kube-bench run --csv                                    # CSV output

# Remediation
kube-bench run --targets master --remediate              # Show remediation
kube-bench run --targets master --remediate --apply      # Auto-remediate

# Configuration
kube-bench run --kubeconfig /path/to/kubeconfig         # Specify kubeconfig
kube-bench run --json-config /path/to/config.json       # Use config file

# Advanced
kube-bench run --targets master --timeout 600           # Set timeout
kube-bench run --targets master --outputfile report.json # Output to file
```

### 13.2 API Endpoints

```bash
# Health Check
GET /healthz

# Metrics
GET /metrics

# Results API
GET /results                          # Get latest results
GET /results/{id}                     # Get specific result
GET /results?control={id}             # Get results by control
```

### 13.3 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| KUBECONFIG | Path to kubeconfig file | ~/.kube/config |
| KUBEBENCH_CONFIG | Path to custom config file | - |
| KUBEBENCH_OUTPUT | Output format | json |
| KUBEBENCH_OUTPUTFILE | Output file path | stdout |
| KUBEBENCH_TIMEOUT | Scan timeout (seconds) | 300 |
| KUBEBENCH_TARGETS | Scan targets | master,worker,policies |
| KUBEBENCH_CHECKS | Specific checks to run | all |

---

## 14. Configuration Reference

### 14.1 Command Line Options

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| --targets | string | Targets to scan | master,worker,policies |
| --check | string | Specific check to run | all |
| --json | bool | Output JSON | false |
| --junit | bool | Output JUnit XML | false |
| --csv | bool | Output CSV | false |
| --remediate | bool | Show remediation | false |
| --kubeconfig | string | Path to kubeconfig | ~/.kube/config |
| --json-config | string | JSON config file | - |
| --timeout | int | Scan timeout (seconds) | 300 |
| --outputfile | string | Output file path | stdout |

### 14.2 Configuration File Format

```yaml
# kube-bench-config.yaml
master:
  apiServer:
    config: /etc/kubernetes/manifests/kube-apiserver.yaml
    kubeconfig: /etc/kubernetes/admin.conf
  controllerManager:
    config: /etc/kubernetes/manifests/kube-controller-manager.yaml
  scheduler:
    config: /etc/kubernetes/manifests/kube-scheduler.yaml
  etcd:
    config: /etc/kubernetes/manifests/etcd.yaml

worker:
  kubelet:
    config: /var/lib/kubelet/config.yaml
    kubeconfig: /var/lib/kubelet/kubeconfig

policies:
  podSecurity:
    enabled: true
    profile: restricted
  networkPolicies:
    enabled: true
  rbac:
    enabled: true
```

### 14.3 Custom Check Format

```yaml
controls:
  - id: "custom-1"
    name: "Custom Controls"
    description: "Organization-specific controls"
    checks:
      - id: "custom-1.1"
        description: "Custom check description"
        audit: "command to execute"
        tests:
          test_items:
            - flag: "flag-name"
              compare:
                op: eq
                value: "expected-value"
        remediation: "Remediation instructions"
        scored: true
```

---

## 15. Real-World Examples

### 15.1 Production Cluster Scanning

```bash
#!/bin/bash
# production-scan.sh

# Configuration
CLUSTER_NAME="production"
REPORT_DIR="/var/reports/kube-bench"
DATE=$(date +%Y%m%d_%H%M%S)

# Create report directory
mkdir -p ${REPORT_DIR}

# Run scan
kube-bench run \
  --kubeconfig /etc/kubernetes/admin.conf \
  --json > ${REPORT_DIR}/${CLUSTER_NAME}_${DATE}.json

# Parse results
PASS=$(cat ${REPORT_DIR}/${CLUSTER_NAME}_${DATE}.json | jq '.summary.pass')
FAIL=$(cat ${REPORT_DIR}/${CLUSTER_NAME}_${DATE}.json | jq '.summary.fail')
TOTAL=$((PASS + FAIL))
SCORE=$((PASS * 100 / TOTAL))

echo "Cluster: ${CLUSTER_NAME}"
echo "Date: ${DATE}"
echo "Score: ${SCORE}% (${PASS}/${TOTAL})"

# Alert if below threshold
if [ ${SCORE} -lt 80 ]; then
  echo "ALERT: Compliance score below threshold"
  # Send notification
fi

# Archive old reports
find ${REPORT_DIR} -name "*.json" -mtime +30 -delete
```

### 15.2 CI/CD Integration

```yaml
# .github/workflows/kube-bench.yml
name: kube-bench Compliance Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  kube-bench:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
      
      - name: Run kube-bench
        run: |
          kube-bench run --json > results.json
      
      - name: Check compliance score
        run: |
          SCORE=$(cat results.json | jq '.summary.pass / (.summary.pass + .summary.fail) * 100')
          echo "Compliance score: ${SCORE}%"
          
          if (( $(echo "${SCORE} < 80" | bc -l) )); then
            echo "ERROR: Compliance score below threshold"
            exit 1
          fi
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: kube-bench-results
          path: results.json
```

### 15.3 Multi-Cluster Monitoring

```python
#!/usr/bin/env python3
# multi-cluster-monitor.py

import json
import subprocess
from datetime import datetime

CLUSTERS = [
    {"name": "production", "kubeconfig": "/etc/kubernetes/admin.conf"},
    {"name": "staging", "kubeconfig": "/etc/staging/admin.conf"},
    {"name": "development", "kubeconfig": "/etc/development/admin.conf"},
]

def run_kube_bench(cluster):
    cmd = [
        "kube-bench",
        "run",
        "--kubeconfig", cluster["kubeconfig"],
        "--json"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

def analyze_results(cluster_name, results):
    summary = results.get("summary", {})
    pass_count = summary.get("pass", 0)
    fail_count = summary.get("fail", 0)
    total = pass_count + fail_count
    
    score = (pass_count / total * 100) if total > 0 else 0
    
    return {
        "cluster": cluster_name,
        "timestamp": datetime.now().isoformat(),
        "score": score,
        "pass": pass_count,
        "fail": fail_count,
        "total": total
    }

def main():
    all_results = []
    
    for cluster in CLUSTERS:
        try:
            results = run_kube_bench(cluster)
            analysis = analyze_results(cluster["name"], results)
            all_results.append(analysis)
            
            print(f"Cluster: {cluster['name']}")
            print(f"  Score: {analysis['score']:.1f}%")
            print(f"  Pass: {analysis['pass']}")
            print(f"  Fail: {analysis['fail']}")
            print()
        except Exception as e:
            print(f"Error scanning {cluster['name']}: {e}")
    
    # Save results
    with open("multi-cluster-results.json", "w") as f:
        json.dump(all_results, f, indent=2)

if __name__ == "__main__":
    main()
```

### 15.4 Compliance Dashboard

```yaml
# prometheus-rules.yaml
groups:
  - name: kube-bench
    rules:
      - alert: KubeBenchLowCompliance
        expr: kube_bench_score_total < 80
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Low compliance score detected"
          description: "kube-bench compliance score is {{ $value }}%"
      
      - alert: KubeBenchHighFailures
        expr: kube_bench_fail_total > 20
        for: 1h
        labels:
          severity: critical
        annotations:
          summary: "High number of compliance failures"
          description: "kube-bench has {{ $value }} failures"
```

---

## 16. Further Reading

### 16.1 Official Documentation

- kube-bench GitHub: https://github.com/aquasecurity/kube-bench
- CIS Kubernetes Benchmark: https://www.cisecurity.org/benchmark/kubernetes
- Aqua Security Blog: https://blog.aquasec.com
- Kubernetes Security Documentation: https://kubernetes.io/docs/concepts/security/

### 16.2 Books and Guides

- "Kubernetes Security" by Liz Rice, Michael Hausenblas
- "Container Security" by Liz Rice
- "Hacking Kubernetes" by Andrew Martin, Michael Hausenblas
- "Learning Kubernetes" by Saad Ali, Joe Beda

### 16.3 Community Resources

- Kubernetes Slack: https://kubernetes.slack.com
- CNCF Slack: https://cloud-native.slack.com
- Aqua Security Community: https://community.aquasec.com

### 16.4 Related Tools

- kube-hunter: https://github.com/aquasecurity/kube-hunter
- kubeaudit: https://github.com/Shopify/kubeaudit
- kubesec: https://github.com/controlplaneio/kubesec
- Falco: https://falco.org

### 16.5 Blog Posts and Tutorials

- Getting Started with kube-bench
- Automating CIS Kubernetes Benchmark Compliance
- Custom Checks in kube-bench
- Integrating kube-bench with CI/CD Pipelines

---

*Last updated: 2026*
