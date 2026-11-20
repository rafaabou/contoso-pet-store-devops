# Tetragon Complete Guide

## Table of Contents

1. [What Is Tetragon](#1-what-is-tetragon)
2. [Why Use Tetragon](#2-why-use-tetragon)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide (Step-by-Step)](#7-usage-guide)
8. [Tracing Policies](#8-tracing-policies)
9. [Security Enforcement](#9-security-enforcement)
10. [Integration](#10-integration)
11. [Security](#11-security)
12. [Troubleshooting](#12-troubleshooting)
13. [Tips & Best Practices](#13-tips--best-practices)
14. [Command Reference](#14-command-reference)
15. [Configuration Reference](#15-configuration-reference)
16. [Real-World Examples](#16-real-world-examples)
17. [Further Reading](#17-further-reading)

---

## 1. What Is Tetragon

Tetragon is an eBPF-based security observability and enforcement tool from the Cilium project. It provides deep visibility into system behavior at the kernel level and can both observe and enforce security policies in real-time. Unlike traditional security tools that only observe, Tetragon can block malicious system calls before they complete.

### 1.1 Purpose

Tetragon bridges the gap between runtime security monitoring and active enforcement. It uses eBPF to:

- Monitor system calls, file access, network connections, and process execution
- Enforce security policies at the kernel level (block syscalls)
- Correlate events to build process execution trees
- Detect and prevent container escapes
- Enforce Least Privilege security policies

### 1.2 History

- **2021**: Cilium project announces Tetragon
- **2022**: Tetragon open-sourced by Isovalent
- **2023**: CNCF Incubating project
- **2024**: Production-grade enforcement capabilities
- **2025+**: Network policy enforcement, multi-cluster support

### 1.3 Key Features

- eBPF-based kernel-level monitoring (no userspace overhead)
- Both observation AND enforcement (can block syscalls)
- Process execution tree correlation
- Kubernetes-aware (pod, namespace, container labels)
- File, network, and process event monitoring
- Enforcement: kill process, override return values, inject errors
- Single binary, minimal footprint
- Cilium integration for network policy enforcement

---

## 2. Why Use Tetragon

### 2.1 Observability + Enforcement

| Capability | Falco | Tetragon |
|---|---|---|
| Detect threats | Yes | Yes |
| Block syscalls | No (alert only) | Yes (kill, override, inject) |
| Process tree | No | Yes (full execution graph) |
| File monitoring | Yes | Yes |
| Network monitoring | Limited | Yes (L3/L4/L7) |
| eBPF native | Optional | Native |
| Kernel enforcement | No | Yes |

### 2.2 Use Cases

1. **Least privilege enforcement** — block unauthorized syscalls in containers
2. **Container escape prevention** — kill processes attempting escape
3. **Process execution control** — allow only specific binaries to run
4. **File integrity monitoring** — block writes to sensitive files
5. **Network enforcement** — block unauthorized connections at kernel level

### 2.3 Tetragon vs Falco

| Aspect | Falco | Tetragon |
|---|---|---|
| Primary focus | Detection & alerting | Detection & enforcement |
| Enforcement | No (external response) | Yes (kernel-level) |
| Process tree | No | Yes (BPF map-based) |
| Network visibility | Basic | Full L3/L4/L7 |
| Complexity | Lower | Higher |
| Maturity | Higher | Growing |

---

## 3. Architecture Overview

```
┌──────────────────────────────────────────────────┐
│                  Kubernetes Node                  │
│  ┌──────────────────────────────────────────────┐│
│  │              eBPF Programs                   ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ││
│  │  │ Process  │  │  File    │  │ Network  │  ││
│  │  │ Tracer   │  │ Monitor  │  │ Monitor  │  ││
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  ││
│  │       │              │              │         ││
│  │  ┌────┴──────────────┴──────────────┴─────┐  ││
│  │  │         eBPF Ring Buffer / Perf         │  ││
│  │  └────────────────────┬───────────────────┘  ││
│  └───────────────────────┼──────────────────────┘│
└──────────────────────────┼───────────────────────┘
                           │ events
┌──────────────────────────▼───────────────────────┐
│              Tetragon Agent (per node)            │
│  ┌──────────────────────────────────────────────┐│
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ││
│  │  │  Event   │  │ Policy  │  │ Process  │  ││
│  │  │  Parser  │  │ Engine  │  │ Tree     │  ││
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  ││
│  │       │              │              │         ││
│  │  ┌────┴──────────────┴──────────────┴─────┐  ││
│  │  │         gRPC Server (export)           │  ││
│  │  └────────────────────┬───────────────────┘  ││
│  └───────────────────────┼──────────────────────┘│
└──────────────────────────┼───────────────────────┘
                           │ gRPC
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  tetra   │ │  Hubble  │ │ External │
        │  CLI     │ │  UI      │ │ Exporter │
        └──────────┘ └──────────┘ └──────────┘
```

### 3.1 Components

| Component | Role |
|---|---|
| **eBPF Programs** | Kernel-level event capture and enforcement |
| **Tetragon Agent** | Userspace daemon; processes eBPF events, applies policies |
| **TracingPolicy** | CRD defining what to monitor/enforce |
| **Process Recorder** | Builds process execution trees from eBPF events |
| **tetra CLI** | Command-line interface for Tetragon |
| **Exporter** | Sends events to external systems (gRPC, stdout, JSON) |

---

## 4. Installation

### 4.1 Helm (Recommended)

```bash
# Add Cilium Helm repo
helm repo add cilium https://helm.cilium.io
helm repo update

# Install Tetragon
helm install tetragon cilium/tetragon \
  --namespace kube-system \
  --set tetragon.enabled=true \
  --set tetragon.export.stdout.enabled=true \
  --set tetragon.export.stdout.outputEncoding=json
```

### 4.2 Kubernetes YAML

```bash
# Install Tetragon operator and agent
kubectl apply -f https://raw.githubusercontent.com/cilium/tetragon/main/install/kubernetes/resources/operator/cilium-helm/template.yaml

# Or using the tetragon-operator
kubectl apply -f https://github.com/cilium/tetragon/releases/latest/download/tetragon.yaml
```

### 4.3 Standalone Binary

```bash
# Download tetra CLI
TETRAGON_VERSION=1.1.0
curl -LO https://github.com/cilium/tetragon/releases/download/v${TETRAGON_VERSION}/tetra_linux_amd64.tar.gz
tar xzf tetra_linux_amd64.tar.gz
sudo mv tetra /usr/local/bin/

# Install Tetragon agent (requires root, eBPF kernel support)
curl -LO https://github.com/cilium/tetragon/releases/download/v${TETRAGON_VERSION}/tetragon-${TETRAGON_VERSION}-linux-amd64.tar.gz
tar xzf tetragon-${TETRAGON_VERSION}-linux-amd64.tar.gz
sudo cp tetragon-${TETRAGON_VERSION}-linux-amd64/usr/local/bin/tetragon /usr/local/bin/
```

### 4.4 Docker

```bash
# Run Tetragon agent
docker run --rm --privileged --pid=host \
  -v /sys/kernel:/sys/kernel:ro \
  -v /var/run/tetragon:/var/run/tetragon \
  cilium/tetragon:latest

# Run with specific options
docker run --rm --privileged --pid=host \
  -v /sys/kernel:/sys/kernel:ro \
  -v /proc:/proc:ro \
  -v /var/run/tetragon:/var/run/tetragon \
  cilium/tetragon:latest \
  /usr/local/bin/tetragon \
    --export stdout \
    --log-level info
```

### 4.5 Verify Installation

```bash
# Check Tetragon pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon

# Check Tetragon operator
kubectl get pods -n kube-system -l name=tetragon-operator

# Verify eBPF is working
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --help
```

---

## 5. Configuration

### 5.1 Tetragon Agent Config

```yaml
# /etc/tetragon/tetragon.yaml
process:
  # Enable process tree recording
  enable ProcessTree: true

export:
  # Export to stdout
  stdout:
    enabled: true
    outputEncoding: json
  
  # Export to gRPC
  grpc:
    enabled: true
    address: "0.0.0.0:54321"
  
  # Export to file
  file:
    enabled: false
    filename: /var/log/tetragon/events.log
  
  # Export to OpenTelemetry
  otlp:
    enabled: false
    endpoint: "otel-collector:4317"

# Rate limiting
rateLimit:
  # Max events per second
  maxEventsPerSecond: 1000
  # Burst size
  burst: 2000

# Kernel settings
kernel:
  # BPF map sizes
  bpfMapSize: 256000
  # Perf buffer size
  perfBufferSize: 65536

# Logging
log:
  level: info
  format: text  # or json

# Health
health:
  enabled: true
  address: "0.0.0.0:54321"

# Metrics
metrics:
  enabled: true
  address: "0.0.0.0:2112"
  path: /metrics
```

### 5.2 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `TETRAGON_EXPORT_STDOUT` | `false` | Export events to stdout |
| `TETRAGON_EXPORT_GRPC` | `false` | Export events via gRPC |
| `TETRAGON_LOG_LEVEL` | `info` | Log level: debug, info, warn, error |
| `TETRAGON_BPF_MAP_SIZE` | `256000` | Size of BPF maps |
| `TETRAGON_PERF_BUFFER_SIZE` | `65536` | Perf buffer size |
| `TETRAGON_RATE_LIMIT` | `1000` | Max events/sec |
| `TETRAGON_HEALTH_ADDRESS` | `0.0.0.0:54321` | Health check address |
| `TETRAGON_METRICS_ADDRESS` | `0.0.0.0:2112` | Prometheus metrics address |

---

## 6. Core Concepts

### 6.1 Tracing Policies

TracingPolicy is a CRD (Custom Resource Definition) that defines what events to monitor and what actions to take.

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: sensitive-file-access
spec:
  kprobes:
  - call: fd_install
    syscall: false
    args:
    - index: 1
      type: file
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - /etc/shadow
        - /etc/passwd
    - matchActions:
      - SigKill  # Kill the process
```

### 6.2 Process Tree

Tetragon maintains a process execution tree, correlating parent-child relationships across the entire system:

```
systemd (1)
├── sshd (1234)
│   └── bash (5678)
│       └── kubectl (9012)
│           └── containerd-shim (3456)
│               └── nginx (7890)
└── kubelet (2345)
    └── containerd (6789)
        └── docker (0123)
```

### 6.3 Events

| Event Type | Description |
|---|---|
| `ProcessExec` | Process execution (execve) |
| `ProcessExit` | Process exit |
| `ProcessKprobe` | Kernel probe event (file, network, etc.) |
| `ProcessTracepoint` | Tracepoint event |
| `ProcessUprobe` | User-space probe event |
| `ProcessLsm` | LSM (Linux Security Module) event |

### 6.4 Selectors

Selectors filter which events to process:

```yaml
selectors:
- matchArgs:
  - index: 0
    operator: Equals
    values: ["/etc/shadow"]
- matchNamespaces:
  - namespace: production
- matchPodLabels:
  - key: app
    operator: In
    values: [nginx, redis]
- matchCapabilities:
  - type: Effective
    capability: CAP_NET_ADMIN
- matchActions:
  - SigKill  # Kill the process
```

### 6.5 Enforcement Actions

| Action | Description |
|---|---|
| `SigKill` | Kill the process |
| `OverrideReturn` | Override syscall return value |
| `Override` | Override with specific value |
| `PostSigKill` | Kill after syscall completes |
| `Sig_append` | Send signal |

---

## 7. Usage Guide (Step-by-Step)

### Step 1: Install Tetragon

```bash
helm install tetragon cilium/tetragon \
  --namespace kube-system \
  --set tetragon.export.stdout.enabled=true
```

### Step 2: Verify Installation

```bash
# Check pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=tetragon

# Check events
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output compact
```

### Step 3: Create Basic Tracing Policy

```yaml
# file-monitor.yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: file-monitor
spec:
  kprobes:
  - call: fd_install
    syscall: false
    args:
    - index: 1
      type: file
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - /etc/shadow
        - /etc/passwd
        - /root/.ssh/
    - matchActions:
      - Sigkill
```

```bash
kubectl apply -f file-monitor.yaml

# Watch events
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output compact --namespace production
```

### Step 4: Monitor Process Execution

```yaml
# process-monitor.yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: process-monitor
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    args:
    - index: 0
      type: string
    selectors:
    - matchArgs:
      - index: 0
        operator: Prefix
        values:
        - /bin/
        - /usr/bin/
    - matchActions:
      - Post
```

### Step 5: Enforce Least Privilege in Containers

```yaml
# container-least-privilege.yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: container-least-privilege
spec:
  kprobes:
  # Block ptrace in containers
  - call: __x64_sys_ptrace
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: 0  # Silently block
  # Block mount in containers
  - call: __x64_sys_mount
    syscall: true
    selectors:
    - matchActions:
      - SigKill  # Kill process attempting mount
  # Block network in specific namespaces
  - call: __x64_sys_connect
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: -1  # Return EPERM
```

### Step 6: View Process Trees

```bash
# View full process tree
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra process tree

# View events for specific pod
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output json | jq 'select(.process_kprobe.process.pod.name == "nginx-pod")'
```

### Step 7: Export Events

```bash
# Export to stdout (JSON)
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output json

# Export to file
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output json > /var/log/tetragon/events.jsonl

# Stream events to Kafka
# (configure in tetragon.yaml)
```

### Step 8: Monitor with Prometheus

```bash
# Access Tetragon metrics
kubectl port-forward -n kube-system svc/tetragon 2112:2112

# Query metrics
curl http://localhost:2112/metrics | grep tetragon
```

---

## 8. Tracing Policies

### 8.1 File Access Monitoring

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: file-access-monitor
spec:
  kprobes:
  - call: fd_install
    syscall: false
    args:
    - index: 1
      type: file
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - /etc/shadow
        - /etc/passwd
        - /root/.ssh/
    - matchActions:
      - Sigkill
```

### 8.2 Network Connection Monitoring

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: network-monitor
spec:
  kprobes:
  - call: __x64_sys_connect
    syscall: true
    args:
    - index: 1
      type: sockaddr
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - "10.0.0.0/8"
    - matchActions:
      - Post
```

### 8.3 Process Execution Control

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: process-control
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    args:
    - index: 0
      type: string
    selectors:
    - matchArgs:
      - index: 0
        operator: NotIn
        values:
        - /bin/bash
        - /bin/sh
        - /usr/bin/python3
        - /usr/bin/java
    - matchActions:
      - SigKill  # Kill unauthorized processes
```

### 8.4 Capability Enforcement

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: capability-enforcement
spec:
  kprobes:
  - call: __x64_sys_capset
    syscall: true
    args:
    - index: 1
      type: cap_user_header_t
    selectors:
    - matchActions:
      - SigKill  # Block capability changes
  - call: __x64_sys_setuid
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: 0  # Silently ignore setuid
```

### 8.5 Container Escape Prevention

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: container-escape-prevention
spec:
  kprobes:
  # Block access to /proc/sysrq-trigger
  - call: fd_install
    syscall: false
    args:
    - index: 1
      type: file
    selectors:
    - matchArgs:
      - index: 1
        operator: Equals
        values:
        - /proc/sysrq-trigger
    - matchActions:
      - SigKill
  # Block nsenter
  - call: __x64_sys_setns
    syscall: true
    selectors:
    - matchActions:
      - SigKill
  # Block access to host PID namespace
  - call: __x64_sys_pidfd_open
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: -1
```

---

## 9. Security Enforcement

### 9.1 Process Kill Enforcement

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: kill-miners
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    args:
    - index: 0
      type: string
    selectors:
    - matchArgs:
      - index: 0
        operator: In
        values:
        - /usr/bin/xmrig
        - /usr/bin/minerd
        - /tmp/.miner
    - matchActions:
      - SigKill
```

### 9.2 Return Value Override

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: override-syscall
spec:
  kprobes:
  - call: __x64_sys_mount
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: -1  # Return -EPERM
```

### 9.3 Selective Enforcement

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: selective-enforcement
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    selectors:
    # Kill if running as root in production namespace
    - matchArgs:
      - index: 0
        operator: Prefix
        values: [/bin/]
      matchNamespaces:
      - namespace: production
      matchActions:
        - SigKill
    # Allow if running as non-root
    - matchArgs:
      - index: 0
        operator: Prefix
        values: [/usr/bin/]
      matchActions:
        - Post
```

---

## 10. Integration

### 10.1 Cilium Network Policies

```yaml
# Tetragon + Cilium: block network at kernel level
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: network-enforcement
spec:
  kprobes:
  - call: __x64_sys_connect
    syscall: true
    args:
    - index: 1
      type: sockaddr
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - "10.0.0.0/8"
    - matchActions:
      - OverrideReturn: -1  # Block connections to 10.x
```

### 10.2 Prometheus Metrics

```yaml
# tetragon.yaml
metrics:
  enabled: true
  address: "0.0.0.0:2112"
  path: /metrics

# Prometheus scrape config
scrape_configs:
  - job_name: 'tetragon'
    static_configs:
      - targets: ['tetragon:2112']
```

### 10.3 Falco Integration

```yaml
# Tetragon detects, Falco correlates
# Use Tetragon for enforcement, Falco for complex detection rules

# Tetragon: block crypto miners
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: block-miners
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    selectors:
    - matchArgs:
      - index: 0
        operator: In
        values: [/usr/bin/xmrig, /usr/bin/minerd]
    - matchActions:
      - SigKill

# Falco: complex detection rules for other threats
```

### 10.4 SIEM Integration

```bash
# Export Tetragon events to ELK/Splunk
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output json | \
  curl -XPOST -H 'Content-Type: application/json' \
  -d @- http://logstash:5044/tetragon
```

---

## 11. Security

### 11.1 RBAC

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tetragon
rules:
- apiGroups: [""]
  resources: ['pods', 'nodes', 'namespaces']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['cilium.io']
  resources: ['tracingpolicies', 'tracingpolicies/status']
  verbs: ['get', 'list', 'watch', 'create', 'update', 'patch', 'delete']
- apiGroups: [""]
  resources: ['events']
  verbs: ['create', 'patch']
```

### 11.2 Network Policy

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: tetragon-network-policy
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: tetragon
  ingress:
  - fromEndpoints:
    - matchLabels:
        app.kubernetes.io/name: tetragon-operator
    toPorts:
    - ports:
      - port: "54321"
        protocol: TCP
  egress:
  - toEndpoints:
    - matchLabels:
        app.kubernetes.io/name: tetragon-operator
    toPorts:
    - ports:
      - port: "54321"
        protocol: TCP
```

### 11.3 Pod Security

```yaml
securityContext:
  privileged: true  # Required for eBPF
  runAsUser: 0
  capabilities:
    add:
    - BPF
    - PERFMON
    - NET_ADMIN
    - SYS_ADMIN
```

---

## 12. Troubleshooting

### Issue 1: Tetragon Agent CrashLoopBackOff

**Symptoms**: Tetragon pods restart repeatedly.

**Diagnosis**:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=tetragon --previous
```

**Common causes**:
- eBPF not supported on kernel (need 5.4+)
- Insufficient privileges (need `privileged: true`)
- BPF map size too large

**Fix**:
```bash
# Check kernel version
uname -r

# Check eBPF support
cat /sys/kernel/btf/vmlinux | head -c 4

# Increase memory limit
resources:
  limits:
    memory: 512Mi
```

### Issue 2: No Events Generated

**Symptoms**: TracingPolicy applied but no events appear.

**Diagnosis**:
```bash
# Check TracingPolicy status
kubectl get tracingpolicy -o yaml

# Check if eBPF programs loaded
kubectl exec -n kube-system -l app.kubernetes.io/name=tetragon -- \
  tetra getevents --output compact --timeout 10
```

**Fix**:
- Verify TracingPolicy syntax
- Check namespace/pod selectors match running workloads
- Ensure eBPF programs are loaded (check tetragon logs)

### Issue 3: High CPU Usage

**Symptoms**: Tetragon consuming excessive CPU.

**Fix**:
```yaml
# Reduce event rate
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: selective-monitoring
spec:
  kprobes:
  - call: __x64_sys_execve
    selectors:
    - matchNamespaces:
      - namespace: production  # Only monitor production
```

### Issue 4: eBPF Programs Not Loading

**Symptoms**: "cannot load BPF program" errors.

**Diagnosis**:
```bash
# Check kernel version
uname -r

# Check BTF support
ls -la /sys/kernel/btf/vmlinux

# Check BPF capabilities
cat /proc/sys/kernel/unprivileged_bpf_disabled
```

**Fix**:
```bash
# Enable BTF (if not enabled)
echo 1 > /sys/kernel/btf/vmlinux

# Or use BTF-less mode
helm install tetragon cilium/tetragon \
  --set tetragon.btf=false
```

### Issue 5: Tetragon Cannot See Pods

**Symptoms**: Pod metadata not populated in events.

**Fix**:
```yaml
# Ensure container runtime socket is mounted
volumes:
- name: containerd-socket
  mountPath: /var/run/containerd/containerd.sock
  readOnly: true
```

### Issue 6: gRPC Connection Refused

**Symptoms**: External tools cannot connect to Tetragon gRPC.

**Fix**:
```yaml
# Ensure gRPC is enabled
tetragon:
  export:
    grpc:
      enabled: true
      address: "0.0.0.0:54321"
```

### Issue 7: Events Missing Process Tree

**Symptoms**: Events show process info but no parent.

**Fix**:
```yaml
# Ensure process tree is enabled
process:
  enable ProcessTree: true
```

### Issue 8: Enforcement Not Working

**Symptoms**: SigKill policy applied but processes not killed.

**Diagnosis**:
```bash
# Check if Tetragon has SYS_ADMIN capability
kubectl get pod -n kube-system -l app.kubernetes.io/name=tetragon -o yaml | grep -A 5 capabilities
```

**Fix**: Ensure Tetragon has `SYS_ADMIN` and `BPF` capabilities.

### Issue 9: Slow Event Delivery

**Symptoms**: Events delayed or lost.

**Fix**:
```yaml
# Increase buffer sizes
kernel:
  bpfMapSize: 512000
  perfBufferSize: 131072
```

### Issue 10: Tetragon Fails to Start After Kernel Update

**Symptoms**: Tetragon fails after kernel upgrade.

**Fix**:
```bash
# Check for BTF changes
ls -la /sys/kernel/btf/vmlinux

# May need to rebuild eBPF programs
helm upgrade tetragon cilium/tetragon \
  --namespace kube-system
```

### Issue 11: Memory Pressure

**Symptoms**: Tetragon OOMKilled.

**Fix**:
```yaml
# Reduce process tree retention
process:
  enable ProcessTree: true
  maxProcesses: 10000

# Increase memory limit
resources:
  limits:
    memory: 1Gi
```

### Issue 12: Conflicts with Falco

**Symptoms**: Both Tetragon and Falco fighting for eBPF resources.

**Fix**: Use separate eBPF programs; Tetragon and Falco can coexist if they use different BPF maps.

### Issue 13: Tetray Metrics Not Scraped

**Symptoms**: Prometheus not receiving Tetragon metrics.

**Fix**:
```yaml
# Ensure metrics endpoint is exposed
tetragon:
  metrics:
    enabled: true
    address: "0.0.0.0:2112"
```

### Issue 14: Namespace Selectors Not Working

**Symptoms**: TracingPolicy not matching expected pods.

**Fix**: Verify namespace labels:
```bash
kubectl get namespaces --show-labels
```

### Issue 15: Tetragon Operator Not Creating Resources

**Symptoms**: Operator running but no agent pods.

**Diagnosis**:
```bash
kubectl describe pod -n kube-system -l name=tetragon-operator
kubectl logs -n kube-system -l name=tetragon-operator
```

**Fix**: Check operator RBAC permissions and CRD installation.

---

## 13. Tips & Best Practices

### Tip 1: Start with Observation Mode
Deploy Tetragon with `Post` actions first, then add enforcement once you understand your workload patterns.

### Tip 2: Use Namespace Selectors
```yaml
selectors:
- matchNamespaces:
  - namespace: production
```

### Tip 3: Combine with Cilium
Use Cilium for network policies and Tetragon for kernel-level enforcement.

### Tip 4: Monitor Process Trees
```bash
tetra process tree --namespace production
```

### Tip 5: Export Events for Analysis
```bash
tetra getevents --output json > tetragon-events.jsonl
```

### Tip 6: Use SigKill Sparingly
`SigKill` is powerful but irreversible. Use `OverrideReturn` for softer enforcement.

### Tip 7: Test Policies in Staging First
Always test TracingPolicies in a non-production namespace before deploying.

### Tip 8: Keep Policies in Version Control
```bash
git add tracing-policies/
git commit -m "Add container escape prevention policy"
```

### Tip 9: Use Prometheus for Monitoring
Monitor Tetragon's own health and event rates via Prometheus.

### Tip 10: Set Appropriate BPF Map Sizes
Larger maps = more memory but fewer dropped events. Start with 256000.

### Tip 11: Use Process Trees for Forensics
```bash
tetra process tree --pid 12345
```

### Tip 12: Layer Security Policies
Combine file, network, and process policies for defense in depth.

### Tip 13: Monitor Enforcement Actions
Track how often SigKill/Override are triggered to tune policies.

### Tip 14: Use MatchActions for Specific Responses
Different actions for different threat levels:
- `Post` for monitoring
- `OverrideReturn` for soft block
- `SigKill` for hard block

### Tip 15: Keep Tetragon Updated
eBPF features improve with each release. Stay current for best kernel support.

---

## 14. Command Reference

### tetra CLI

```bash
# Get events
tetra getevents
tetra getevents --output json
tetra getevents --output compact
tetra getevents --timeout 30

# Process tree
tetra process tree
tetra process tree --pid 1234
tetra process tree --namespace production

# List TracingPolicies
tetra tracingpolicy list
tetra tracingpolicy get <name>

# Apply TracingPolicy
tetra tracingpolicy apply -f policy.yaml
tetra tracingpolicy delete <name>

# Get process info
tetra process get --pid 1234
tetra process get --namespace production

# Watch events
tetra getevents --output json | jq 'select(.process_kprobe.process.pod.name == "nginx")'

# Filter by event type
tetra getevents --event-type ProcessExec
tetra getevents --event-type ProcessKprobe

# Export to file
tetra getevents --output json > events.jsonl

# Health check
tetra health

# Version
tetra version
```

### Environment Variables

```bash
# Tetragon agent
TETRAGON_EXPORT_STDOUT=true
TETRAGON_EXPORT_GRPC=true
TETRAGON_LOG_LEVEL=info
TETRAGON_BPF_MAP_SIZE=256000
TETRAGON_PERF_BUFFER_SIZE=65536
TETRAGON_RATE_LIMIT=1000
TETRAGON_HEALTH_ADDRESS=0.0.0.0:54321
TETRAGON_METRICS_ADDRESS=0.0.0.0:2112
```

---

## 15. Configuration Reference

### tetragon.yaml Full Reference

```yaml
process:
  enableProcessTree: true
  maxProcesses: 10000

export:
  stdout:
    enabled: true
    outputEncoding: json
  grpc:
    enabled: true
    address: "0.0.0.0:54321"
  file:
    enabled: false
    filename: /var/log/tetragon/events.log
  otlp:
    enabled: false
    endpoint: "otel-collector:4317"

rateLimit:
  maxEventsPerSecond: 1000
  burst: 2000

kernel:
  bpfMapSize: 256000
  perfBufferSize: 65536

log:
  level: info
  format: text

health:
  enabled: true
  address: "0.0.0.0:54321"

metrics:
  enabled: true
  address: "0.0.0.0:2112"
  path: /metrics
```

### TracingPolicy Reference

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: policy-name
spec:
  kprobes:
  - call: <kernel-function>
    syscall: true|false
    args:
    - index: <arg-index>
      type: <arg-type>  # int, string, file, sockaddr, etc.
    selectors:
    - matchArgs:
      - index: <arg-index>
        operator: <operator>  # Equals, NotIn, Prefix, etc.
        values: [<values>]
      matchNamespaces:
      - namespace: <namespace>
      matchPodLabels:
      - key: <key>
        operator: <operator>
        values: [<values>]
      matchActions:
      - <action>  # SigKill, OverrideReturn, Post, etc.
```

---

## 16. Real-World Examples

### 16.1 Production Security Policy

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: production-security
spec:
  kprobes:
  # Block crypto miners
  - call: __x64_sys_execve
    syscall: true
    args:
    - index: 0
      type: string
    selectors:
    - matchArgs:
      - index: 0
        operator: In
        values:
        - /usr/bin/xmrig
        - /usr/bin/minerd
        - /tmp/.miner
    - matchActions:
      - SigKill

  # Block sensitive file access
  - call: fd_install
    syscall: false
    args:
    - index: 1
      type: file
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - /etc/shadow
        - /etc/passwd
        - /root/.ssh/
    - matchActions:
      - SigKill

  # Block ptrace in containers
  - call: __x64_sys_ptrace
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: 0
```

### 16.2 Compliance Policy

```yaml
# PCI-DSS: Block access to payment logs
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: pci-dss-payment-logs
spec:
  kprobes:
  - call: fd_install
    syscall: false
    selectors:
    - matchArgs:
      - index: 1
        operator: Prefix
        values:
        - /var/log/payment/
    - matchActions:
      - SigKill
```

### 16.3 Microservices Security

```yaml
# Block service mesh bypass
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: service-mesh-enforcement
spec:
  kprobes:
  - call: __x64_sys_connect
    syscall: true
    selectors:
    - matchActions:
      - OverrideReturn: -1  # Block all direct connections
```

### 16.4 Development Environment

```yaml
# Allow everything but log process execution
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: dev-monitoring
spec:
  kprobes:
  - call: __x64_sys_execve
    syscall: true
    selectors:
    - matchActions:
      - Post  # Just log, don't block
```

---

## 17. Further Reading

### Official Documentation
- [Tetragon Documentation](https://tetragon.cilium.io/)
- [Tetragon GitHub](https://github.com/cilium/tetragon)
- [Cilium Documentation](https://docs.cilium.io/)
- [eBPF Documentation](https://ebpf.io/)
- [TracingPolicy Examples](https://tetragon.cilium.io/docs/tracing-policies/)

### Tutorials
- [Tetragon Getting Started](https://tetragon.cilium.io/docs/getting-started/)
- [Tetragon Tracing Policies](https://tetragon.cilium.io/docs/tracing-policies/)
- [Tetragon Enforcement](https://tetragon.cilium.io/docs/enforcement/)

### Related Projects
- [Cilium](https://cilium.io/) — eBPF-based networking and security
- [Falco](https://falco.org/) — Runtime security detection
- [Hubble](https://github.com/cilium/hubble) — Network observability
- [Pixie](https://px.dev/) — Kubernetes observability

---

*Last updated: 2026-09-04*
