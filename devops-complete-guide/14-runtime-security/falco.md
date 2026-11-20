# Falco Complete Guide

## Table of Contents

1. [What Is Falco](#1-what-is-falco)
2. [Why Use Falco](#2-why-use-falco)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide (Step-by-Step)](#7-usage-guide)
8. [Custom Rules](#8-custom-rules)
9. [Integrations & Outputs](#9-integrations--outputs)
10. [Security](#10-security)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips & Best Practices](#12-tips--best-practices)
13. [Command Reference](#13-command-reference)
14. [Configuration Reference](#14-configuration-reference)
15. [Real-World Examples](#15-real-world-examples)
16. [Further Reading](#16-further-reading)

---

## 1. What Is Falco

Falco is a cloud-native runtime security tool that detects threats and anomalous behavior in real-time. It monitors Linux systems at the kernel level using eBPF (extended Berkeley Packet Filter) or kernel modules, observing system calls to identify suspicious activity. Falco is a CNCF graduated project, originally developed by Sysdig and now the standard for Kubernetes runtime security.

### 1.1 Purpose

Falco acts as a security camera for your Linux systems and Kubernetes clusters. It watches syscalls and application behavior to detect:

- Unauthorized process execution in containers
- Unexpected network connections
- File system modifications in sensitive directories
- Privilege escalation attempts
- Container escapes
- Reverse shells and crypto miners

### 1.2 History

- **2013**: Sysdig created as a Linux system exploration tool
- **2016**: Falco project open-sourced by Sysdig
- **2018**: Joined CNCF as an incubating project
- **2020**: Graduated from CNCF
- **2022+**: Native eBPF support, cloud metadata detection, K8s audit log integration

### 1.3 Key Features

- Real-time syscall monitoring via eBPF or kernel module
- Declarative rule language for threat detection
- Kubernetes-aware (pod, namespace, container metadata)
- Integration with Falcosidekick for 50+ outputs (Slack, PagerDuty, Kafka, etc.)
- Cloud metadata threat detection (AWS, GCP, Azure)
- Process outlier detection
- K8s audit log integration

---

## 2. Why Use Falco

### 2.1 Runtime Threat Detection

| Threat | Falco Detection |
|---|---|
| Reverse shell in container | Detects spawned shell + outbound connection |
| Crypto miner installed | Detects known miner processes or CPU spikes |
| Sensitive file access | Detects reads/writes to `/etc/shadow`, `/etc/passwd` |
| Privilege escalation | Detects `sudo` in container, capability abuse |
| Container escape | Detects host mount access, process namespace breakout |
| Unauthorized image | Detects unexpected container images running |
| Lateral movement | Detects unexpected network connections between services |

### 2.2 Falco vs Other Runtime Security

| Feature | Falco | Aqua | Sysdig Secure | Twistlock |
|---|---|---|---|---|
| Open source | Yes | No (limited) | No | No |
| CNCF status | Graduated | N/A | N/A | N/A |
| eBPF support | Yes | Yes | Yes | Yes |
| Rule language | YAML rules | Policies | Rules | Policies |
| K8s integration | Native | Native | Native | Native |
| Kernel module fallback | Yes | Yes | Yes | Yes |

### 2.3 Use Cases

1. **Kubernetes runtime security** — detect threats in running containers
2. **Compliance monitoring** — track file access, process execution
3. **Incident response** — detect indicators of compromise
4. **Container drift detection** — alert on unexpected process/image changes
5. **Network security** — detect C2 callbacks, data exfiltration

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────┐
│              Kubernetes Node                  │
│  ┌─────────────────────────────────────────┐│
│  │         eBPF Probe / Kernel Module       ││
│  │   (monitors syscalls in real-time)       ││
│  └──────────────────┬──────────────────────┘│
│                     │ syscalls               │
│  ┌──────────────────▼──────────────────────┐│
│  │              Falco Engine               ││
│  │  ┌──────────┐  ┌──────────┐  ┌───────┐ ││
│  │  │  Rules   │  │  Filters │  │ Outputs│ ││
│  │  │  (YAML)  │  │ (output) │  │(gRPC) │ ││
│  │  └──────────┘  └──────────┘  └───┬───┘ ││
│  └──────────────────────────────────┼──────┘│
└─────────────────────────────────────┼───────┘
                                      │ gRPC/HTTP
                     ┌────────────────┼────────────────┐
                     ▼                ▼                ▼
              ┌────────────┐  ┌────────────┐  ┌────────────┐
              │  stdout    │  │  Syslog    │  │Falcosidekick│
              │  (default) │  │            │  │ (Slack,etc) │
              └────────────┘  └────────────┘  └──────┬─────┘
                                                     │
                                              ┌──────▼──────┐
                                              │  50+ outputs │
                                              │ Slack,PagerD │
                                              │ Kafka,SMTP.. │
                                              └─────────────┘
```

### 3.1 Components

| Component | Role |
|---|---|
| **eBPF Probe / Kernel Module** | Captures syscalls from the kernel |
| **Falco Engine** | Evaluates rules against captured events |
| **Rules (YAML)** | Define what constitutes a threat |
| **Output Channels** | stdout, syslog, gRPC, HTTP webhooks |
| **Falcosidekick** | Proxy to 50+ notification outputs |
| **Falcosidekick-UI** | Web dashboard for Falco alerts |
| **Kubernetes Audit Logs** | Additional data source for K8s API events |

---

## 4. Installation

### 4.1 Helm (Recommended)

```bash
# Add Helm repo
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install Falco
helm install falco falcosecurity/falco \
  --namespace falco --create-namespace \
  --set falcosidekick.enabled=true \
  --set falcosidekick.config.slack.webhookurl="https://hooks.slack.com/services/xxx" \
  --set driver.kind=ebpf \
  --set auditLog.enabled=true
```

### 4.2 Kubernetes DaemonSet (YAML)

```bash
# Install with default rules
kubectl apply -f https://raw.githubusercontent.com/falcosecurity/falco/master/install/manyops/falco-daemonset.yaml

# Or with Helm values
helm install falco falcosecurity/falco \
  --namespace falco --create-namespace \
  --set driver.kind=ebpf \
  --set falco.grpc.enabled=true \
  --set falco.grpc.output.enabled=true
```

### 4.3 Docker

```bash
# Run Falco in Docker
docker run --rm -d --name falco \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /proc:/host/proc:ro \
  -v /etc:/host/etc:ro \
  -v $(pwd)/rules:/etc/falco/rules.d \
  -v $(pwd)/falco.yaml:/etc/falco/falco.yaml \
  falcosecurity/falco:latest

# With eBPF
docker run --rm -d --name falco \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /proc:/host/proc:ro \
  -v /lib/modules:/host/lib/modules:ro \
  -v $(pwd)/rules:/etc/falco/rules.d \
  falcosecurity/falco-no-driver:latest
```

### 4.4 Linux (Debian/Ubuntu)

```bash
# Add Falcosecurity GPG key
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://dl.falcosecurity.org/stable/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/falcosecurity.list

# Install Falco
sudo apt-get update && sudo apt-get install -y falco

# Enable and start
sudo systemctl enable --now falco
```

### 4.5 Docker Compose (with Sidekick)

```yaml
version: '3.8'
services:
  falco:
    image: falcosecurity/falco:latest
    privileged: true
    volumes:
      - /var/run/docker.sock:/host/var/run/docker.sock
      - /proc:/host/proc:ro
      - /lib/modules:/host/lib/modules:ro
      - /etc:/host/etc:ro
      - ./rules:/etc/falco/rules.d
      - ./falco.yaml:/etc/falco/falco.yaml
    environment:
      - FALCO_GRPC_ENABLED=true
      - FALCO_GRPC_OUTPUT_ENABLED=true
      - FALCO_GRPC_BIND_ADDRESS=0.0.0.0:9966
    ports:
      - "9966:9966"
    restart: unless-stopped

  falcosidekick:
    image: falcosecurity/falcosidekick:latest
    volumes:
      - ./falcosidekick.yaml:/etc/falcosidekick/config.yaml
    ports:
      - "2801:2801"
    depends_on:
      - falco
    restart: unless-stopped

  falcosidekick-ui:
    image: falcosecurity/falcosidekick-ui:latest
    ports:
      - "2802:2802"
    volumes:
      - ./ui-config.yaml:/etc/falcosidekick-ui/config.yaml
    restart: unless-stopped
```

---

## 5. Configuration

### 5.1 Main Configuration (falco.yaml)

```yaml
# /etc/falco/falco.yaml
output_rate: 1
max_output_queue: 1000
drop_event_drops_rate_limit:
  frequency: 1
  max_burst: 1

# Logging
log_level: info
log_stderr: true
log_file: /var/log/falco/falco.log

# Syslog
syslog_output:
  enabled: false

# Stdout
stdout_output:
  enabled: true

# gRPC server
grpc:
  enabled: true
  bind_address: "0.0.0.0:9966"
  private_key: /etc/falco/falco.pem
  root_certs: /etc/falco/ca.pem
  server_cert: /etc/falco/server.pem
  output:
    enabled: true
  kafka_config:
    broker_list: "kafka:9092"
    topic: "falco-alerts"

# HTTP output
http_output:
  enabled: true
  url: "http://falcosidekick:2801"
  useragent: "falco/0.36.2"
  insecure: true

# HTTPS output
https_output:
  enabled: false
  ca_bundle: /etc/falco/ca.pem
  ca_path: /etc/falco/certs/

# File output
file_output:
  enabled: false
  keep_alive: false
  filename: /var/log/falco/events.json

# Programs output
program_output:
  enabled: false
  program: "cat >> /var/log/falco/alerts.log"
  keep_alive: false

# Priority filter
priority: "debug"

# Buffered output
buffered_outputs: false
# Number of outputs to buffer
outputs_queue:
  capacity: 0

# Rules files
rules_file:
  - /etc/falco/falco_rules.yaml
  - /etc/falco/rules.d
  - /etc/falco/k8s_audit_rules.yaml

# Syscall event source
syscall_event_drops:
  threshold: 0.1
  actions:
    - log
    - alert
  rate: 0.03333
  max_burst: 1

# Watch config files for changes
watch_config_files: true

# Libs config
libs_logger:
  enabled: false
  severity: debug

# Driver
driver:
  kind: ebpf  # or "module"
  ebpf:
    probe: "modern_bpf"  # or "legacy_bpf"
    buf_size_preset: 2
    drop_failed_exit: true
  module:
    root: /lib/modules
    buf_size_preset: 2
```

### 5.2 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `FALCO_LOG_LEVEL` | `info` | Logging level: debug, info, warning, error, critical |
| `FALCO_GRPC_ENABLED` | `false` | Enable gRPC server |
| `FALCO_GRPC_BIND_ADDRESS` | `0.0.0.0:9966` | gRPC listen address |
| `FALCO_HTTP_OUTPUT_ENABLED` | `false` | Enable HTTP output |
| `FALCO_HTTP_OUTPUT_URL` | — | HTTP output URL |
| `FALCO_FILE_OUTPUT_ENABLED` | `false` | Enable file output |
| `FALCO_FILE_OUTPUT_FILENAME` | — | Output file path |
| `FALCO_DRIVER_KIND` | `ebpf` | Driver type: ebpf, module |
| `FALCO_AUDIT_LOG_ENABLED` | `false` | Enable K8s audit log source |

---

## 6. Core Concepts

### 6.1 Rules

Rules define threats to detect. Each rule has:

```yaml
- rule: Terminal shell in container
  desc: >
    A shell was used as the entrypoint/exec point of a container. This
    should be highly unusual and is a good indicator of container
    breakout.
  condition: >
    spawned_process and container and shell_procs and proc.tty != 0
    and not proc.pname in (cron_finish, backup.sh)
  output: >
    Shell spawned in a container (user=%user.name user_uid=%user.uid
    command=%proc.cmdline pid=%proc.pid parent=%proc.pname
    terminal=%proc.tty container_id=%container.id
    container_name=%container.name image=%container.image.repository)
    priority=CRITICAL
  tags: [container, shell, mit_execution]
```

### 6.2 Macros

Reusable condition fragments:

```yaml
- macro: spawned_process
  condition: evt.type = clone or evt.type = clone3 or evt.type = fork or evt.type = vfork or evt.type = execve

- macro: container
  condition: container.id != host

- macro: shell_procs
  condition: proc.name in (bash, sh, dash, zsh, fish, csh, ksh, tcsh)
```

### 6.3 Lists

Named sets of values:

```yaml
- list: known_shells
  items: [bash, sh, dash, zsh, fish, csh, ksh, tcsh]

- list: trusted_images
  items: [nginx, redis, postgres, mysql]
```

### 6.4 Outputs and Priorities

| Priority | Description |
|---|---|
| `Emergency` | System is unusable |
| `Alert` | Action must be taken immediately |
| `Critical` | Critical conditions |
| `Error` | Error conditions |
| `Warning` | Warning conditions |
| `Notice` | Normal but significant |
| `Informational` | Informational |
| `Debug` | Debug-level messages |

### 6.5 Syscall Events

Every event captured by Falco includes:

| Field | Description |
|---|---|
| `evt.type` | System call name (e.g., `execve`, `open`) |
| `evt.num` | System call number |
| `evt.time` | Timestamp |
| `evt.latency` | Latency in nanoseconds |
| `evt.res` | Return value |
| `evt.dir` | Direction (>= enter, < exit) |
| `proc.name` | Process name |
| `proc.pid` | Process ID |
| `proc.pname` | Parent process name |
| `container.id` | Container ID |
| `container.name` | Container name |
| `container.image.repository` | Container image |
| `user.name` | User name |
| `user.uid` | User ID |

---

## 7. Usage Guide (Step-by-Step)

### Step 1: Install Falco

```bash
# Helm install
helm install falco falcosecurity/falco \
  --namespace falco --create-namespace \
  --set driver.kind=ebpf
```

### Step 2: Verify Installation

```bash
# Check pods
kubectl get pods -n falco

# Check logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Expected output:
# * Informing possible targets: ["driver", "plugin"]
# * Starting plugin...
# * Loading rules /etc/falco/falco_rules.yaml
# * Starting gRPC server
```

### Step 3: Test Default Rules

```bash
# Generate a test alert - shell in container
kubectl exec -it nginx-pod -- bash

# Check Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=20

# Expected alert:
# 12:34:56.789: Warning Shell spawned in a container
# (user=root command=bash container_id=abc123 container_name=nginx ...)
```

### Step 4: Write Custom Rule

```yaml
# /etc/falco/rules.d/custom-rules.yaml
- rule: Detect cryptocurrency miner
  desc: Detect known cryptocurrency miner processes
  condition: >
    spawned_process and container and
    proc.name in (xmrig, minerd, minergate, ethminer, cpuminer)
  output: >
    Cryptocurrency miner detected
    (user=%user.name command=%proc.cmdline container=%container.name
    image=%container.image.repository pod=%k8s.pod.name ns=%k8s.ns.name)
  priority: CRITICAL
  tags: [container, cryptomining, mit_execution]
```

### Step 5: Apply Custom Rules

```bash
# If using Helm, add rules via values
helm upgrade falco falcosecurity/falco \
  --namespace falco \
  --set-file customRules."custom-rules\.yaml"=./rules/custom-rules.yaml

# Or restart Falco to pick up new rules
kubectl rollout restart daemonset falco -n falco
```

### Step 6: Enable K8s Audit Log

```yaml
# falco-audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    resources:
      - group: ""
        resources: ["pods", "services", "configmaps"]
      - group: apps
        resources: ["deployments", "replicasets", "statefulsets"]
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets"]
  - level: None
    nonResourceURLs: ["/healthz", "/readyz"]
```

```bash
# Enable in Falco
helm upgrade falco falcosecurity/falco \
  --namespace falco \
  --set auditLog.enabled=true \
  --set auditLog.config.k8sAuditPolicy.enabled=true
```

### Step 7: Configure Falcosidekick

```yaml
# falcosidekick.yaml
slack:
  webhookurl: "https://hooks.slack.com/services/xxx/yyy/zzz"
  channel: "#security-alerts"
  username: "Falco"
  icon: https://falco.org/favicons/favicon-32x32.png
  footer: "Falco Alert"

pagerduty:
  routingKey: "xxx"

kafka:
  hostport: "kafka:9092"
  topic: "falco-alerts"

elasticsearch:
  hostport: "http://elasticsearch:9200"
  index: "falco-alerts"
  type: "_doc"

loki:
  hostport: "http://loki:3100"

prometheus:
  enabled: true
  hostport: "0.0.0.0:9093"
```

### Step 8: Monitor Alerts

```bash
# Stream Falco alerts
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep -E "Warning|Critical|Error"

# Check Falcosidekick alerts
curl http://localhost:2801/alerts | jq .

# Check Prometheus metrics
curl http://localhost:9093/metrics | grep falco
```

---

## 8. Custom Rules

### 8.1 Container Security Rules

```yaml
# Container escape attempt
- rule: Container escape via mount
  desc: Detect container escape via host filesystem mount
  condition: >
    open_read and container and
    fd.name startswith /host/ and
    not fd.name in (known_host_paths)
  output: >
    Container escape attempt via host mount
    (file=%fd.name user=%user.name container=%container.name
    image=%container.image.repository command=%proc.cmdline)
  priority: CRITICAL
  tags: [container, escape, mit_privilege_escalation]

# Detect crypto miners
- rule: Cryptocurrency miner process
  desc: Detect known crypto miner processes
  condition: >
    spawned_process and container and
    proc.name in (xmrig, minerd, minergate, ethminer, cpuminer,
    cpuminer-opt, cgminer, bfgminer, xmr-stak)
  output: >
    Crypto miner detected
    (user=%user.name command=%proc.cmdline container=%container.name
    image=%container.image.repository pod=%k8s.pod.name)
  priority: CRITICAL
  tags: [container, cryptomining, mit_execution]

# Detect credential stealing
- rule: Read sensitive file in container
  desc: Detect reads to sensitive credential files
  condition: >
    open_read and container and
    fd.name in (/etc/shadow, /etc/passwd, /etc/group,
    /root/.ssh/id_rsa, /root/.ssh/authorized_keys,
    /root/.bash_history, /home/*/.ssh/id_rsa)
  output: >
    Sensitive file read in container
    (file=%fd.name user=%user.name container=%container.name
    image=%container.image.repository command=%proc.cmdline)
  priority: WARNING
  tags: [container, credentials, mit_credential_access]
```

### 8.2 Kubernetes-Specific Rules

```yaml
# Detect kubectl exec
- rule: Kubectl exec in container
  desc: Detect kubectl exec into a running container
  condition: >
    k8s_audit and ka.verb = exec and
    ka.target.resource = pods and
    ka.target.namespace != "kube-system"
  output: >
    kubectl exec detected
    (user=%ka.user.name namespace=%ka.target.namespace
    pod=%ka.target.name command=%ka.req.content.spec.containers[0].command)
  priority: WARNING
  tags: [kubernetes, exec, kubectl]

# Detect pod creation with hostPID
- rule: Pod with hostPID
  desc: Detect pod created with hostPID set to true
  condition: >
    k8s_audit and ka.verb = create and
    ka.target.resource = pods and
    ka.req.pod.hostPID = true
  output: >
    Pod created with hostPID
    (user=%ka.user.name namespace=%ka.target.namespace
    pod=%ka.target.name)
  priority: WARNING
  tags: [kubernetes, hostPID, mit_privilege_escalation]

# Detect secret access
- rule: Secret read in Kubernetes
  desc: Detect reads to Kubernetes secrets
  condition: >
    k8s_audit and ka.verb = get and
    ka.target.resource = secrets and
    ka.target.namespace != "kube-system"
  output: >
    Secret read detected
    (user=%ka.user.name namespace=%ka.target.namespace
    secret=%ka.target.name)
  priority: NOTICE
  tags: [kubernetes, secrets, mit_credential_access]
```

### 8.3 Network Security Rules

```yaml
# Detect outbound DNS
- rule: Unexpected outbound DNS
  desc: Detect DNS queries to external servers from containers
  condition: >
    outbound and container and fd.type = ipv4 and
    fd.sport = 53 and
    not container.image.repository in (known_dns_images)
  output: >
    Unexpected outbound DNS query
    (src=%container.name dst=%fd.rIP:%fd.rport
    command=%proc.cmdline)
  priority: WARNING
  tags: [container, network, mit_exfiltration]

# Detect connection to known C2 servers
- rule: Connection to suspicious IP
  desc: Detect connections to known malicious IPs
  condition: >
    outbound and fd.sip and
    fd.sip in (suspicious_ips) and
    not proc.name in (known_benign)
  output: >
    Connection to suspicious IP detected
    (src=%container.name dst=%fd.rIP:%fd.rport
    command=%proc.cmdline)
  priority: CRITICAL
  tags: [network, c2, mit_command_and_control]
```

### 8.4 Compliance Rules

```yaml
# CIS Kubernetes Benchmark
- rule: CIS 5.1.2 - No privileged containers
  desc: CIS 5.1.2 Ensure that the cluster admin role is only used where required
  condition: >
    k8s_audit and ka.verb = create and
    ka.target.resource = pods and
    ka.req.pod.containers.privileged = true
  output: >
    Privileged container created
    (user=%ka.user.name namespace=%ka.target.namespace
    pod=%ka.target.name)
  priority: WARNING
  tags: [cis, kubernetes, privileged]

# PCI-DSS: Access to cardholder data
- rule: PCI-DSS - Access to payment logs
  desc: Detect access to payment processing logs
  condition: >
    open_read and container and
    fd.name startswith /var/log/payment and
    not proc.name in (allowed_payment_processors)
  output: >
    Access to payment logs
    (file=%fd.name user=%user.name container=%container.name
    command=%proc.cmdline)
  priority: WARNING
  tags: [pci-dss, compliance, payment]
```

---

## 9. Integrations & Outputs

### 9.1 Falcosidekick Outputs

```yaml
# /etc/falcosidekick/config.yaml

# Slack
slack:
  webhookurl: "https://hooks.slack.com/services/xxx"
  channel: "#security"
  username: "Falco"
  footer: "Security Alert"

# Microsoft Teams
ms teams:
  webhookurl: "https://outlook.office.com/webhook/xxx"

# PagerDuty
pagerduty:
  routingKey: "xxx"

# Kafka
kafka:
  hostport: "kafka:9092"
  topic: "falco-alerts"

# Elasticsearch
elasticsearch:
  hostport: "http://elasticsearch:9200"
  index: "falco"
  type: "_doc"

# Loki
loki:
  hostport: "http://loki:3100"

# Prometheus AlertManager
alertmanager:
  hostport: "http://alertmanager:9093"

# Jira
jira:
  project: SEC
  board: Security
  url: "https://jira.example.com"
  token: "xxx"

# AWS Lambda
aws:
  lambda:
    functionname: falco-alerts
    region: us-east-1

# GCP Pub/Sub
gcp:
  pubsub:
    project: my-project
    topic: falco-alerts

# SMTP (Email)
smtp:
  hostport: "smtp.example.com:587"
  from: "falco@example.com"
  user: "falco@example.com"
  password: "xxx"
  to:
    - "security@example.com"

# Grafana OnCall
grafana:
  oncall:
    apiurl: "http://grafana-oncall:8080"
    apitoken: "xxx"
    integrationkey: "xxx"
```

### 9.2 Custom Webhook

```yaml
http_output:
  enabled: true
  url: "http://my-webhook:8080/falco"
  method: POST
  headers:
    Authorization: "Bearer token123"
    Content-Type: "application/json"
  insecure: true
  ca_bundle: ""
  ca_path: /etc/ssl/certs/
```

### 9.3 Kafka Integration

```yaml
grpc:
  enabled: true
  bind_address: "0.0.0.0:9966"
  output:
    enabled: true
    kafka_config:
      broker_list: "kafka-0:9092,kafka-1:9092,kafka-2:9092"
      topic: "falco-alerts"
      compression: gzip
      tls:
        enabled: true
        certfile: /etc/falco/tls/client.crt
        keyfile: /etc/falco/tls/client.key
        cacerts: /etc/falco/tls/ca.crt
```

---

## 10. Security

### 10.1 TLS for gRPC

```yaml
grpc:
  enabled: true
  bind_address: "0.0.0.0:9966"
  private_key: /etc/falco/falco.key
  root_certs: /etc/falco/ca.crt
  server_cert: /etc/falco/falco.crt
```

### 10.2 RBAC (Kubernetes)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: falco
rules:
- apiGroups: [""]
  resources: ['pods', 'services', 'configmaps', 'events', 'nodes']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['apps']
  resources: ['deployments', 'replicasets', 'statefulsets', 'daemonsets']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['batch']
  resources: ['jobs', 'cronjobs']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['networking.k8s.io']
  resources: ['ingresses']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['policy']
  resources: ['podsecuritypolicies']
  verbs: ['get', 'list', 'watch']
```

### 10.3 Falco Resource Limits

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
securityContext:
  privileged: true  # Required for eBPF/kernel module
  runAsUser: 0
```

---

## 11. Troubleshooting

### Issue 1: Falco Pods CrashLoopBackOff

**Symptoms**: Falco pods restarting repeatedly.

**Diagnosis**:
```bash
kubectl logs -n falco -l app.kubernetes.io/name=falco --previous
```

**Common causes and fixes**:
- Missing kernel headers (for kernel module): Use eBPF driver instead
- Insufficient privileges: Ensure `privileged: true` is set
- Memory limits too low: Increase to 512Mi minimum

### Issue 2: No Alerts Generated

**Symptoms**: Falco running but no alerts appear.

**Diagnosis**:
```bash
# Check if rules are loaded
kubectl logs -n falco | grep "Loading rules"

# Test a rule manually
falco -r /etc/falco/falco_rules.yaml --dry-run
```

**Fix**: Ensure rules file syntax is correct. Check rule condition matches the event type.

### Issue 3: High CPU Usage

**Symptoms**: Falco consuming excessive CPU.

**Fix**:
```yaml
# Reduce event rate by filtering
- rule: Only alert on specific namespaces
  condition: >
    spawned_process and container and
    k8s.ns.name in (production, staging)
  output: "..."
  priority: WARNING

# Set output rate limit
output_rate: 1
max_output_queue: 100
```

### Issue 4: eBPF Not Supported

**Symptoms**: Error "eBPF not supported on this kernel".

**Diagnosis**:
```bash
# Check kernel version
uname -r

# Check if eBPF is available
cat /proc/sys/kernel/unprivileged_bpf_disabled
```

**Fix**: Use kernel module instead, or upgrade kernel to 4.14+.

### Issue 5: K8s Audit Logs Not Received

**Symptoms**: K8s audit rules not triggering.

**Fix**:
```bash
# Verify audit policy is applied
kubectl get --raw /apis/audit.k8s.io/v1/policies | jq .

# Check Falco audit config
kubectl get configmap -n falco falco-config -o yaml | grep -A 20 auditLog
```

### Issue 6: Falcosidekick Not Receiving Alerts

**Symptoms**: Falco alerts appear in logs but not in Sidekick.

**Fix**:
```yaml
# Ensure HTTP output is enabled
http_output:
  enabled: true
  url: "http://falcosidekick:2801"
  insecure: true
```

### Issue 7: Rules Syntax Error

**Symptoms**: Falco fails to start with "error loading rules".

**Diagnosis**:
```bash
# Validate rules
falco --validate /etc/falco/rules.d/custom-rules.yaml
```

**Fix**: Check YAML syntax, ensure macros/lists referenced in rules exist.

### Issue 8: False Positives

**Symptoms**: Too many false positive alerts.

**Fix**: Add exclusions:
```yaml
- rule: Shell in container (exclude known)
  condition: >
    spawned_process and container and shell_procs and
    not proc.pname in (background-scripts) and
    not proc.cmdline startswith (/usr/bin/tmux)
  output: "..."
```

### Issue 9: Falco Cannot Access Docker Socket

**Symptoms**: Container metadata not populated in alerts.

**Fix**:
```yaml
# Ensure Docker socket is mounted
volumes:
  - name: docker-socket
    mountPath: /var/run/docker.sock
    readOnly: true
```

### Issue 10: gRPC Connection Refused

**Symptoms**: Falcosidekick cannot connect to Falco gRPC.

**Fix**:
```bash
# Check gRPC is enabled
kubectl get configmap -n falco falco-config -o yaml | grep grpc

# Verify service
kubectl get svc -n falco
```

### Issue 11: High Memory Usage

**Symptoms**: Falco pods consuming excessive memory.

**Fix**:
```yaml
# Reduce internal buffer
syscall_event_drops:
  threshold: 0.1
  actions: [log]
  rate: 0.01

# Set memory limit
resources:
  limits:
    memory: 256Mi
```

### Issue 12: Falco Cannot Load Kernel Module

**Symptoms**: Error "could not load kernel module".

**Fix**:
```bash
# Check module
lsmod | grep falco

# Try eBPF instead
helm install falco falcosecurity/falco --set driver.kind=ebpf
```

### Issue 13: Missing Container Metadata

**Symptoms**: Alerts show "container=host" for containerized processes.

**Fix**: Ensure Docker socket or containerd socket is accessible:
```yaml
volumes:
  - name: containerd-sock
    mountPath: /var/run/containerd/containerd.sock
    readOnly: true
```

### Issue 14: Alert Rate Limiting

**Symptoms**: Alerts being dropped.

**Fix**:
```yaml
output_rate: 10
max_output_queue: 1000
syscall_event_drops:
  threshold: 0.5
```

### Issue 15: Falco Fails to Start After Update

**Symptoms**: Falco fails to start after upgrading.

**Fix**:
```bash
# Check for breaking changes
helm repo update
helm search repo falcosecurity/falco

# Rollback
helm rollback falco <previous-revision> -n falco

# Check logs for migration errors
kubectl logs -n falco -l app.kubernetes.io/name=falco --previous
```

---

## 12. Tips & Best Practices

### Tip 1: Start with Default Rules
Falco ships with 100+ rules covering common threats. Start with defaults and add custom rules as needed.

### Tip 2: Use eBPF Over Kernel Module
eBPF is safer and doesn't require kernel headers or module signing.

### Tip 3: Monitor Only Critical Namespaces
```yaml
- rule: Process spawned in production
  condition: >
    spawned_process and container and
    k8s.ns.name in (production, staging)
  output: "..."
```

### Tip 4: Exclude Known Good Behavior
```yaml
- list: allowed_containers
  items: [nginx, redis, postgres]

- rule: Shell in container (exclude known)
  condition: >
    spawned_process and container and shell_procs and
    not container.image.repository in (allowed_containers)
```

### Tip 5: Use Falcosidekick for Alert Routing
Route alerts to the right team/channel based on severity and category.

### Tip 6: Test Rules with Dry Run
```bash
falco -r custom-rules.yaml --dry-run
```

### Tip 7: Set Appropriate Priority Levels
Use `CRITICAL` for actual threats, `WARNING` for suspicious activity, `NOTICE` for audit.

### Tip 8: Use Kubernetes Audit Logs
Enable K8s audit log integration to detect K8s-specific threats.

### Tip 9: Monitor Falco Health
```bash
# Check Falco metrics
kubectl port-forward -n falco svc/falco-metrics 9092:9092
curl http://localhost:9092/metrics | grep falco
```

### Tip 10: Keep Rules in Version Control
```bash
# Store custom rules in Git
git add rules/custom-rules.yaml
git commit -m "Add crypto miner detection rule"
```

### Tip 11: Use Lists for Reusable Conditions
```yaml
- list: known_benign_shells
  items: [container-init, startup-script]
```

### Tip 12: Profile Your Workload
Run Falco in monitoring-only mode first, analyze false positives, then enable blocking.

### Tip 13: Use Falco for Compliance
Map rules to compliance frameworks (CIS, PCI-DSS, SOC2).

### Tip 14: Aggregate Alerts with Falcosidekick-UI
Use the UI dashboard to visualize alert trends and patterns.

### Tip 15: Integrate with SIEM
Forward Falco alerts to your SIEM (Splunk, ELK, Sentinel) for correlation.

---

## 13. Command Reference

### Falco CLI

```bash
# Run Falco with custom rules
falco -r /etc/falco/falco_rules.yaml -r /etc/falco/custom-rules.yaml

# Validate rules
falco --validate /etc/falco/rules.d/custom.yaml

# List available fields
falco --list

# Run in dry-run mode
falco --dry-run

# Show version
falco --version

# Run with gRPC server
falco --grpc-enabled --grpc-bind-address 0.0.0.0:9966

# Run with specific driver
falco --driver kind=ebpf

# List syscall events
falco -i evt.type=execve

# Filter by priority
falco -p priority=CRITICAL

# Output to file
falco -o /var/log/falco/alerts.log

# Enable debug logging
falco --log-level debug

# Run with K8s audit log
falco --audit-log --audit-log-config /etc/falco/audit-config.yaml
```

### Falcosidekick CLI

```bash
# Run Falcosidekick
falcosidekick -c /etc/falcosidekick/config.yaml

# Test webhook
curl -X POST http://localhost:2801/test

# Check health
curl http://localhost:2801/health

# View alerts
curl http://localhost:2801/alerts | jq .
```

### Environment Variables

```bash
# Falco
FALCO_LOG_LEVEL=info
FALCO_GRPC_ENABLED=true
FALCO_GRPC_BIND_ADDRESS=0.0.0.0:9966
FALCO_HTTP_OUTPUT_ENABLED=true
FALCO_HTTP_OUTPUT_URL=http://falcosidekick:2801
FALCO_DRIVER_KIND=ebpf
FALCO_AUDIT_LOG_ENABLED=true

# Falcosidekick
FALCOSIDEKICK_WEBHOOKURL_SLACK=https://hooks.slack.com/services/xxx
FALCOSIDEKICK_PDROUTINGKEY=pagerduty-key
FALCOSIDEKICK_KAFKAHOSTPORT=kafka:9092
```

---

## 14. Configuration Reference

### falco.yaml Full Reference

```yaml
# Rate limiting
output_rate: 1
max_output_queue: 1000

# Priority filter
priority: "debug"

# Buffered output
buffered_outputs: false

# Output channels
syslog_output:
  enabled: false

stdout_output:
  enabled: true

file_output:
  enabled: false
  keep_alive: false
  filename: /var/log/falco/events.json

http_output:
  enabled: true
  url: "http://falcosidekick:2801"
  insecure: true

https_output:
  enabled: false
  ca_bundle: /etc/falco/ca.pem

grpc:
  enabled: true
  bind_address: "0.0.0.0:9966"
  private_key: /etc/falco/falco.key
  root_certs: /etc/falco/ca.crt
  server_cert: /etc/falco/falco.crt
  output:
    enabled: true
  kafka_config:
    broker_list: "kafka:9092"
    topic: "falco-alerts"

program_output:
  enabled: false
  program: "cat >> /var/log/falco/alerts.log"

# Rules
rules_file:
  - /etc/falco/falco_rules.yaml
  - /etc/falco/k8s_audit_rules.yaml
  - /etc/falco/rules.d

# Syscall event drops
syscall_event_drops:
  threshold: 0.1
  actions: [log, alert]
  rate: 0.03333
  max_burst: 1

# Driver
driver:
  kind: ebpf
  ebpf:
    probe: "modern_bpf"
    buf_size_preset: 2

# Watch for config changes
watch_config_files: true

# Libs logging
libs_logger:
  enabled: false
  severity: debug

# Logging
log_level: info
log_stderr: true
log_file: /var/log/falco/falco.log

# Container metadata socket
container:
  socket: /var/run/docker.sock  # or containerd socket

# K8s metadata
k8s_api:
  kubeconfig: ""
  kube-apiserver-url: ""
  kubelet:
    kubelet_url: ""
    kubelet_cert: ""
    node_name: ""
```

### Rule Syntax Reference

```yaml
# Rule structure
- rule: Rule Name
  desc: Description
  condition: <filter expression>
  output: <output format string>
  priority: <priority level>
  tags: [tag1, tag2]
  source: syscall  # or "k8s_audit"
  append: false

# Condition operators
condition: >
  evt.type = execve and
  container and
  proc.name in (bash, sh) and
  user.uid = 0

# Output format fields
output: >
  Alert message
  (user=%user.name command=%proc.cmdline
  container=%container.name image=%container.image.repository
  pod=%k8s.pod.name namespace=%k8s.ns.name)
```

---

## 15. Real-World Examples

### 15.1 E-Commerce Security Rules

```yaml
# Detect payment data exfiltration
- rule: Payment data exfiltration
  desc: Detect network connections from payment processing containers
  condition: >
    outbound and container and
    k8s.ns.name = "payments" and
    fd.type = ipv4 and
    not fd.sip in (known_payment_services)
  output: >
    Potential payment data exfiltration
    (src=%container.name dst=%fd.rIP:%fd.rport
    command=%proc.cmdline pod=%k8s.pod.name)
  priority: CRITICAL
  tags: [pci-dss, exfiltration, payment]

# Detect unauthorized admin access
- rule: Admin access to production database
  desc: Detect non-admin users accessing production database
  condition: >
    open_read and container and
    k8s.ns.name = "production" and
    container.name contains "database" and
    user.uid != 0 and
    not user.name in (db_admins)
  output: >
    Unauthorized database access attempt
    (user=%user.name file=%fd.name container=%container.name)
  priority: CRITICAL
  tags: [compliance, database, unauthorized-access]
```

### 15.2 Microservices Security Rules

```yaml
# Detect service mesh bypass
- rule: Service mesh bypass attempt
  desc: Detect direct connections bypassing service mesh
  condition: >
    outbound and container and
    fd.type = ipv4 and
    fd.sport != 15001 and
    fd.sport != 15006 and
    not proc.name in (envoy, istio-proxy)
  output: >
    Possible service mesh bypass
    (src=%container.name dst=%fd.rIP:%fd.rport
    command=%proc.cmdline)
  priority: WARNING
  tags: [service-mesh, network, bypass]

# Detect config change in production
- rule: Config file modified in production
  desc: Detect modifications to config files in production
  condition: >
    modify and container and
    k8s.ns.name = "production" and
    fd.name in (/etc/nginx/nginx.conf, /etc/haproxy/haproxy.cfg)
  output: >
    Config file modified in production
    (file=%fd.name user=%user.name container=%container.name
    command=%proc.cmdline)
  priority: WARNING
  tags: [configuration, production, change-management]
```

### 15.3 Compliance Rules (SOC2)

```yaml
# SOC2 CC6.1 - Logical access controls
- rule: SOC2 - Unusual login pattern
  desc: Detect logins outside business hours
  condition: >
    spawned_process and container and
    proc.name in (login, sshd) and
    not (evt.hour >= 8 and evt.hour <= 18)
  output: >
    Unusual login outside business hours
    (user=%user.name time=%evt.time container=%container.name)
  priority: WARNING
  tags: [soc2, cc6, access-control]

# SOC2 CC7.2 - Monitoring
- rule: SOC2 - Sensitive file access audit
  desc: Track access to sensitive files for audit trail
  condition: >
    open_read and container and
    fd.name in (/etc/shadow, /etc/passwd, /root/.ssh/*)
  output: >
    Sensitive file access
    (file=%fd.name user=%user.name container=%container.name
    command=%proc.cmdline)
  priority: NOTICE
  tags: [soc2, cc7, monitoring]
```

### 15.4 Production Deployment (Helm Values)

```yaml
# values-production.yaml
driver:
  kind: ebpf

falco:
  rules:
    - /etc/falco/falco_rules.yaml
    - /etc/falco/k8s_audit_rules.yaml
    - /etc/falco/rules.d

  grpc:
    enabled: true
    output:
      enabled: true

  http_output:
    enabled: true
    url: "http://falcosidekick:2801"
    insecure: true

  auditLog:
    enabled: true
    config:
      k8sAuditPolicy:
        enabled: true

falcosidekick:
  enabled: true
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/xxx"
      channel: "#security-alerts"
    pagerduty:
      routingKey: "xxx"
    kafka:
      hostport: "kafka:9092"
      topic: "falco-alerts"
    prometheus:
      enabled: true
      hostport: "0.0.0.0:9093"

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

---

## 16. Further Reading

### Official Documentation
- [Falco Documentation](https://falco.org/docs/)
- [Falco Rules](https://falco.org/docs/rules/)
- [Falcosidekick](https://github.com/falcosecurity/falcosidekick)
- [Falcosecurity Helm Charts](https://github.com/falcosecurity/charts)
- [Falco GitHub](https://github.com/falcosecurity/falco)

### Books
- "Container Security" — Liz Rice
- "Kubernetes Security" — Liz Rice, Michael Hausenblas

### Tutorials
- [Falco Getting Started](https://falco.org/docs/getting-started/)
- [Falco Rules Examples](https://falco.org/docs/rules/default-custom/)
- [Falcosidekick Configuration](https://github.com/falcosecurity/falcosidekick)

### Related Projects
- [Sysdig](https://sysdig.com/) — System exploration and troubleshooting
- [Tetragon](https://github.com/cilium/tetragon) — eBPF-based security observability
- [KubeArmor](https://github.com/kubearmor/KubeArmor) — Runtime security enforcement

---

*Last updated: 2026-09-04*
