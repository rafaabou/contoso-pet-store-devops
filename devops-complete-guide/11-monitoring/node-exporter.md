# Node Exporter Complete Guide

## Table of Contents

1. [What Is Node Exporter](#1-what-is-node-exporter)
2. [Why Use Node Exporter](#2-why-use-node-exporter)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Metrics Reference](#7-metrics-reference)
8. [Usage Guide (Step-by-Step)](#8-usage-guide-step-by-step)
9. [Custom Collectors](#9-custom-collectors)
10. [Textfile Collector](#10-textfile-collector)
11. [Container Deployment](#11-container-deployment)
12. [Kubernetes Deployment](#12-kubernetes-deployment)
13. [Integrations](#13-integrations)
14. [Security](#14-security)
15. [Performance Tuning](#15-performance-tuning)
16. [Troubleshooting](#16-troubleshooting)
17. [Tips and Best Practices](#17-tips-and-best-practices)
18. [Command Reference](#18-command-reference)
19. [Configuration Reference](#19-configuration-reference)
20. [Real-World Examples](#20-real-world-examples)
21. [Further Reading](#21-further-reading)

---

## 1. What Is Node Exporter

Node Exporter is a Prometheus exporter for hardware and OS-level metrics from *nix kernels. It collects metrics related to CPU, memory, disk, network, filesystem, and other system resources, exposing them via an HTTP endpoint for Prometheus to scrape.

### Key Features

- **CPU metrics**: Usage per mode (user, system, idle, iowait)
- **Memory metrics**: Total, free, available, buffers, cached, swap
- **Disk metrics**: I/O, usage, space, inodes, I/O time
- **Network metrics**: Traffic, errors, drops, TCP connections
- **Filesystem metrics**: Usage, inodes, mount options
- **Load average**: 1, 5, and 15 minute averages
- **File descriptor metrics**: Allocated and used
- **Kernel metrics**: Boot time, context switches, processes
- **NFS metrics**: NFS server and client statistics
- **TCP metrics**: TCP connections, retransmits
- **ARP metrics**: ARP table entries
- **Conntrack metrics**: Connection tracking

### Metric Prefixes

| Prefix | Collector | Description |
|--------|-----------|-------------|
| `node_` | All collectors | Default prefix for all metrics |
| `node_cpu_` | cpu | CPU metrics |
| `node_memory_` | meminfo | Memory metrics |
| `node_disk_` | diskstats | Disk I/O metrics |
| `node_filesystem_` | filesystem | Filesystem metrics |
| `node_network_` | netdev | Network metrics |
| `node_load` | loadavg | Load average |
| `node_filefd_` | filefd | File descriptor metrics |
| `node_time_` | time | Time metrics |
| `node_uname_` | uname | System information |

---

## 2. Why Use Node Exporter

### Advantages

- **Standard metrics**: Well-defined, consistent metric names across systems
- **Zero configuration**: Works out of the box on most Linux systems
- **Low resource usage**: Lightweight binary, minimal CPU and memory footprint
- **Broad coverage**: 600+ metrics covering all major subsystems
- **Active development**: Regularly updated with new collectors and improvements
- **Widely supported**: De facto standard for node-level metrics in Prometheus ecosystem

### When to Use Node Exporter

- Infrastructure monitoring (bare metal, VMs, cloud instances)
- Capacity planning and resource utilization tracking
- Performance analysis and troubleshooting
- SLA/SLO monitoring for system availability
- Compliance auditing (disk usage, user access, etc.)

### Alternatives

| Tool | Description |
|------|-------------|
| Telegraf | InfluxData's agent with 200+ plugins |
| Collectd | daemon for collecting system statistics |
| Datadog Agent | Datadog's proprietary agent |
| Prometheus Windows Exporter | Windows-specific metrics |
| cadvisor | Container metrics (not node-level) |

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────┐
│              Node (Host)                 │
│  ┌─────────────────────────────────┐    │
│  │         Node Exporter            │    │
│  │  ┌─────────┐  ┌──────────────┐  │    │
│  │  │Collectors│  │Text Collector│  │    │
│  │  └────┬────┘  └──────────────┘  │    │
│  │       │                          │    │
│  │  ┌────┴──────────────────────┐   │    │
│  │  │     /metrics endpoint     │   │    │
│  │  │  (HTTP :9100)             │   │    │
│  │  └───────────────────────────┘   │    │
│  └─────────────────────────────────┘    │
└────────────────────────┬────────────────┘
                         │ scrape (HTTP)
                    ┌────┴────┐
                    │Prometheus│
                    └─────────┘
```

### Components

1. **Collectors**: Modules that gather specific metrics (cpu, meminfo, diskstats, etc.)
2. **Text Collector**: Reads `.prom` files from a directory for custom metrics
3. **HTTP Server**: Serves `/metrics` endpoint on port 9100
4. **Process Collector**: Collects metrics about the exporter process itself

### Data Flow

1. Collectors read from `/proc` and `/sys` filesystems
2. Metrics are stored in memory
3. Prometheus scrapes `http://host:9100/metrics`
4. Metrics are returned in Prometheus exposition format
5. Prometheus stores the data in TSDB

---

## 4. Installation

### Binary Download

```bash
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
```

### Systemd Service

```ini
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100 \
  --collector.systemd \
  --collector.processes
Restart=always

[Install]
WantedBy=multi-user.target
```

### Create Service Account

```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
```

### Docker

```bash
docker run -d \
  --name node-exporter \
  --net=host \
  --pid=host \
  -v /:/host:ro,rslave \
  prom/node-exporter:v1.8.1 \
  --path.rootfs=/host \
  --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($$|/)"
```

### Docker Compose

```yaml
version: '3.8'
services:
  node-exporter:
    image: prom/node-exporter:v1.8.1
    ports:
      - "9100:9100"
    volumes:
      - /:/host:ro,rslave
    pid: host
    command:
      - '--path.rootfs=/host'
      - '--collector.systemd'
      - '--collector.processes'
    restart: unless-stopped
```

### Kubernetes (DaemonSet)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostPID: true
      hostNetwork: true
      containers:
        - name: node-exporter
          image: prom/node-exporter:v1.8.1
          args:
            - '--path.procfs=/host/proc'
            - '--path.sysfs=/host/sys'
            - '--path.rootfs=/host'
            - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
          ports:
            - containerPort: 9100
              hostPort: 9100
          resources:
            limits:
              memory: 128Mi
              cpu: 250m
            requests:
              memory: 64Mi
              cpu: 100m
          volumeMounts:
            - name: proc
              mountPath: /host/proc
              readOnly: true
            - name: sys
              mountPath: /host/sys
              readOnly: true
            - name: root
              mountPath: /host
              readOnly: true
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
        - name: root
          hostPath:
            path: /
```

### Package Manager

```bash
# Debian/Ubuntu
sudo apt-get install prometheus-node-exporter

# RHEL/CentOS
sudo yum install prometheus-node-exporter

# Arch Linux
sudo pacman -S prometheus-node-exporter
```

### Verifying Installation

```bash
# Check version
node_exporter --version

# Check metrics
curl http://localhost:9100/metrics

# Check health
curl http://localhost:9100/-/healthy
```

---

## 5. Configuration

### Command-Line Flags

```bash
node_exporter \
  --web.listen-address=:9100 \
  --web.telemetry-path=/metrics \
  --web.config.file=/etc/node-exporter/web.yml \
  --path.procfs=/proc \
  --path.sysfs=/sys \
  --path.rootfs=/ \
  --collector.cpu \
  --collector.meminfo \
  --collector.diskstats \
  --collector.filesystem \
  --collector.netdev \
  --collector.loadavg \
  --collector.filefd \
  --collector.uname \
  --collector.time \
  --no-collector.nfs \
  --no-collector.infiniband \
  --collector.systemd \
  --collector.processes \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \
  --collector.wifi \
  --collector.pressure \
  --log.level=info
```

### Web Configuration (TLS)

```yaml
# /etc/node-exporter/web.yml
tls_server_config:
  cert_file: /etc/node-exporter/server.crt
  key_file: /etc/node-exporter/server.key
  client_auth_type: VerifyIfGiven
  client_ca_file: /etc/node-exporter/ca.crt
basic_auth_users:
  prometheus: $2y$10$hash
```

### Systemd Override

```ini
# /etc/systemd/system/node_exporter.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100 \
  --collector.systemd \
  --collector.processes \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
```

---

## 6. Core Concepts

### Collectors

Collectors are modules that gather specific metrics. They read from `/proc` and `/sys`:

| Collector | Metrics | Description |
|-----------|---------|-------------|
| cpu | `node_cpu_seconds_total` | CPU usage by mode |
| meminfo | `node_memory_*` | Memory statistics |
| diskstats | `node_disk_*` | Disk I/O |
| filesystem | `node_filesystem_*` | Filesystem usage |
| netdev | `node_network_*` | Network traffic |
| loadavg | `node_load*` | Load average |
| filefd | `node_filefd_*` | File descriptors |
| uname | `node_uname_*` | System information |
| time | `node_time_*` | System time |
| arp | `node_arp_entries` | ARP table |
| conntrack | `node_conntrack_*` | Connection tracking |
| cpufreq | `node_cpufreq_*` | CPU frequency |
| infiniband | `node_infiniband_*` | InfiniBand |
| nfs | `node_nfs_*` | NFS statistics |
| nfsd | `node_nfsd_*` | NFS server |
| pressure | `node_pressure_*` | PSI (Pressure Stall Information) |
| processes | `node_processes_*` | Process statistics |
| rapidjson_collector | custom | RapidJSON-based collector |
| slabinfo | `node_slabinfo_*` | Kernel slab allocator |
| softnet | `node_softnet_*` | Softnet statistics |
| stat | `node_context_switches_total` | Kernel statistics |
| tapestats | `node_tape_*` | Tape drive statistics |
| textfile | custom | Custom metrics from files |
| thermal_zone | `node_thermal_*` | Thermal zones |
| time | `node_time_*` | System time |
| udp_queues | `node_udp_*` | UDP queues |
| uname | `node_uname_*` | System information |
| vmstat | `node_vmstat_*` | Virtual memory statistics |
| wifi | `node_wifi_*` | Wireless statistics |
| xfs | `node_xfs_*` | XFS filesystem |
| zfs | `node_zfs_*` | ZFS filesystem |

### Enabling/Disabling Collectors

```bash
# Enable specific collectors
node_exporter --collector.cpu --collector.meminfo --no-collector.infiniband

# List all collectors
node_exporter --collectors-enabled

# Show available collectors
node_exporter --help | grep collector
```

### Metric Types

- **Counter**: Monotonically increasing (e.g., `node_cpu_seconds_total`)
- **Gauge**: Value that can go up or down (e.g., `node_memory_MemAvailable_bytes`)
- **Histogram**: Distribution of values (e.g., `node_disk_read_time_seconds`)

---

## 7. Metrics Reference

### CPU Metrics

```promql
# Total CPU time per mode
node_cpu_seconds_total{mode="user",cpu="0"}

# CPU utilization percentage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU frequency
node_cpufreq_current_frequency_hertz{cpu="0"}
```

### Memory Metrics

```promql
# Total memory
node_memory_MemTotal_bytes

# Available memory
node_memory_MemAvailable_bytes

# Used memory
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Memory usage percentage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Swap usage
node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes

# Buffers and cached
node_memory_Buffers_bytes
node_memory_Cached_bytes
```

### Disk Metrics

```promql
# Disk I/O
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])

# Disk space usage
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# Inode usage
(1 - node_filesystem_files_free / node_filesystem_files) * 100

# I/O utilization
rate(node_disk_io_time_seconds_total[5m])

# I/O time
rate(node_disk_io_time_seconds_total[5m])
```

### Network Metrics

```promql
# Network traffic
rate(node_network_receive_bytes_total{device="eth0"}[5m])
rate(node_network_transmit_bytes_total{device="eth0"}[5m])

# Network errors
rate(node_network_receive_errs_total{device="eth0"}[5m])
rate(node_network_transmit_errs_total{device="eth0"}[5m])

# Network drops
rate(node_network_receive_drop_total{device="eth0"}[5m])
rate(node_network_transmit_drop_total{device="eth0"}[5m])

# Bandwidth in Mbps
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1024 / 1024
```

### Filesystem Metrics

```promql
# Filesystem usage
node_filesystem_avail_bytes{mountpoint="/"}
node_filesystem_size_bytes{mountpoint="/"}

# Filesystem usage percentage
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# Filesystem reads/writes
rate(node_disk_reads_completed_total[5m])
rate(node_disk_writes_completed_total[5m])
```

### Load Average

```promql
node_load1    # 1-minute load average
node_load5    # 5-minute load average
node_load15   # 15-minute load average
```

### System Metrics

```promql
# Boot time
node_boot_time_seconds

# Context switches
rate(node_context_switches_total[5m])

# Processes
node_procs_running
node_procs_blocked

# File descriptors
node_filefd_allocated
node_filefd_maximum
```

### Pressure Metrics (PSI)

```promql
# CPU pressure
node_pressure_cpu_waiting_seconds_total

# Memory pressure
node_pressure_memory_waiting_seconds_total
node_pressure_memory_stalled_seconds_total

# I/O pressure
node_pressure_io_waiting_seconds_total
node_pressure_io_stalled_seconds_total
```

---

## 8. Usage Guide (Step-by-Step)

### Step 1: Install Node Exporter

```bash
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
```

### Step 2: Create Service Account

```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
```

### Step 3: Create Systemd Service

```ini
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100
Restart=always

[Install]
WantedBy=multi-user.target
```

### Step 4: Start Node Exporter

```bash
sudo systemctl daemon-reload
sudo systemctl enable node-exporter
sudo systemctl start node-exporter
```

### Step 5: Verify Metrics

```bash
curl http://localhost:9100/metrics | head -20
curl http://localhost:9100/-/healthy
```

### Step 6: Configure Prometheus to Scrape

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node1:9100', 'node2:9100', 'node3:9100']
```

### Step 7: Test Queries in Prometheus

```promql
# CPU usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk usage
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```

### Step 8: Create Grafana Dashboard

1. Import community dashboard (e.g., ID 1860 for Node Exporter Full)
2. Configure data source as Prometheus
3. Customize panels as needed

---

## 9. Custom Collectors

### Writing a Custom Collector (Python)

```python
#!/usr/bin/env python3
"""Custom node_exporter collector using textfile collector."""

import time
import os

TEXTFILE_DIR = "/var/lib/node_exporter/textfile_collector"
METRICS_FILE = os.path.join(TEXTFILE_DIR = "/var/lib/node_exporter/textfile_collector"
METRICS_FILE = os.path.join(TEXTFILE_DIR, "custom.prom")

def collect_metrics():
    """Collect custom metrics and write to .prom file."""
    metrics = []
    
    # Example: count active SSH sessions
    ssh_count = os.popen("ss -tn state established '( dport = :22 or sport = :22 )' | wc -l").read().strip()
    metrics.append(f'ssh_sessions_active {ssh_count}')
    
    # Example: disk health (SMART)
    healthy = 1 if os.popen("smartctl -H /dev/sda | grep -q PASSED").read() else 0
    metrics.append(f'disk_healthy{{device="sda"}} {healthy}')
    
    # Write to textfile
    with open(METRICS_FILE, 'w') as f:
        f.write('\n'.join(metrics) + '\n')

if __name__ == '__main__':
    collect_metrics()
```

### Text Collector Format

```promql
# HELP my_custom_metric Description of the metric
# TYPE my_custom_metric gauge
my_custom_metric{label="value"} 42

# HELP my_custom_counter Description
# TYPE my_custom_counter counter
my_custom_counter_total 12345
```

---

## 10. Textfile Collector

### Purpose

The textfile collector reads `.prom` files from a directory and exposes them as metrics. This allows you to add custom metrics without writing a full collector.

### Configuration

```bash
node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
```

### Writing Custom Metrics

```bash
# Create a script that generates metrics
cat > /usr/local/bin/custom_metrics.sh << 'EOF'
#!/bin/bash
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
mkdir -p "$TEXTFILE_DIR"

# Custom metric: SSL certificate expiry
EXPIRY=$(echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

cat > "$TEXTFILE_DIR/ssl_expiry.prom" << PROMEOF
# HELP ssl_certificate_expiry_days Days until SSL certificate expires
# TYPE ssl_certificate_expiry_days gauge
ssl_certificate_expiry_days{domain="example.com"} $DAYS_LEFT
PROMEOF
EOF

chmod +x /usr/local/bin/custom_metrics.sh
```

### Cron Job

```bash
# Run every 5 minutes
*/5 * * * * /usr/local/bin/custom_metrics.sh
```

### systemd Timer

```ini
# /etc/systemd/system/custom-metrics.service
[Unit]
Description=Generate custom metrics

[Service]
Type=oneshot
ExecStart=/usr/local/bin/custom_metrics.sh

# /etc/systemd/system/custom-metrics.timer
[Unit]
Description=Run custom metrics every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

---

## 11. Container Deployment

### Docker

```bash
docker run -d \
  --name node-exporter \
  --net=host \
  --pid=host \
  -v /:/host:ro,rslave \
  prom/node-exporter:v1.8.1 \
  --path.rootfs=/host \
  --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($$|/)" \
  --collector.systemd \
  --collector.processes
```

### Docker Compose (Full Stack)

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:v2.53.0
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    depends_on:
      - node-exporter

  node-exporter:
    image: prom/node-exporter:v1.8.1
    ports:
      - "9100:9100"
    volumes:
      - /:/host:ro,rslave
    pid: host
    command:
      - '--path.rootfs=/host'
      - '--collector.systemd'
      - '--collector.processes'

  grafana:
    image: grafana/grafana:11.0.0
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### Container Best Practices

1. **Mount `/` as rootfs**: Use `--path.rootfs=/host` with `-v /:/host:ro,rslave`
2. **Use host PID namespace**: Required for process metrics
3. **Use read-only mounts**: Prevent accidental modifications
4. **Resource limits**: Set memory and CPU limits

---

## 12. Kubernetes Deployment

### DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9100"
    spec:
      hostPID: true
      hostNetwork: true
      containers:
        - name: node-exporter
          image: prom/node-exporter:v1.8.1
          args:
            - '--path.procfs=/host/proc'
            - '--path.sysfs=/host/sys'
            - '--path.rootfs=/host'
            - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
          ports:
            - containerPort: 9100
              hostPort: 9100
              name: metrics
          resources:
            limits:
              memory: 128Mi
              cpu: 250m
            requests:
              memory: 64Mi
              cpu: 100m
          volumeMounts:
            - name: proc
              mountPath: /host/proc
              readOnly: true
            - name: sys
              mountPath: /host/sys
              readOnly: true
            - name: root
              mountPath: /host
              readOnly: true
              mountPropagation: HostToContainer
          securityContext:
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 65534
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
        - name: root
          hostPath:
            path: /
  updateStrategy:
    type: RollingUpdate
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    app: node-exporter
spec:
  clusterIP: None
  ports:
    - port: 9100
      targetPort: 9100
      name: metrics
  selector:
    app: node-exporter
```

### ServiceMonitor (Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: node-exporter
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
```

---

## 13. Integrations

### Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node1:9100', 'node2:9100']
    relabel_configs:
      - source_labels: [__address__]
        regex: '(.+):(\d+)'
        target_label: instance
        replacement: '${1}'

  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - source_labels: [__meta_kubernetes_node_label_kubernetes_io_os]
        action: keep
        regex: linux
```

### Grafana

```yaml
# grafana datasource
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
```

### Alertmanager

```yaml
# prometheus.yml alerting
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

# Alert rules
groups:
  - name: node
    rules:
      - alert: NodeHighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels:
          severity: warning

      - alert: NodeHighMemory
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90
        for: 5m
        labels:
          severity: critical

      - alert: NodeDiskSpaceLow
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 85
        for: 15m
        labels:
          severity: warning
```

### Blackbox Exporter

```yaml
# Monitor node availability
scrape_configs:
  - job_name: 'blackbox-node'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://node1:9100/-/healthy
          - http://node2:9100/-/healthy
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

---

## 14. Security

### TLS Configuration

```yaml
# /etc/node-exporter/web.yml
tls_server_config:
  cert_file: /etc/node-exporter/server.crt
  key_file: /etc/node-exporter/server.key
  client_auth_type: VerifyIfGiven
  client_ca_file: /etc/node-exporter/ca.crt
  min_version: TLS12
```

### Basic Authentication

```yaml
# /etc/node-exporter/web.yml
basic_auth_users:
  prometheus: $2y$10$hash
```

### Network Security

```bash
# Firewall rules
ufw allow from 10.0.0.0/8 to any port 9100
ufw deny 9100

# Or use iptables
iptables -A INPUT -p tcp --dport 9100 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 9100 -j DROP
```

### Process Isolation

```bash
# Run as non-root user
useradd --no-create-home --shell /bin/false node_exporter

# Limit capabilities
--no-collector.sysctl
--no-collector.bcache
```

### Filesystem Permissions

```bash
# Restrict textfile collector directory
chmod 755 /var/lib/node_exporter/textfile_collector
chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector
```

---

## 15. Performance Tuning

### Disable Unnecessary Collectors

```bash
# Disable heavy collectors
node_exporter \
  --no-collector.nfs \
  --no-collector.nfsd \
  --no-collector.infiniband \
  --no-collector.tapestats \
  --no-collector.xfs \
  --no-collector.zfs
```

### Increase Scrape Interval

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    scrape_interval: 30s  # Default is 15s
```

### Use Metric Relabeling to Drop Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_nfsd_.*|node_nfs_.*'
        action: drop
```

### Resource Limits

```bash
# Systemd service limits
[Service]
MemoryMax=128M
CPUQuota=25%

# Docker limits
docker run -m 128m --cpus=0.25 ...
```

### Reduce Metric Cardinality

```bash
# Drop high-cardinality labels
--no-collector.textfile
--no-collector.wifi
```

### Use `--collector.filesystem.mount-points-exclude`

```bash
# Exclude virtual filesystems
--collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($$|/)"
```

---

## 16. Troubleshooting

### Issue 1: Node Exporter Not Starting

**Symptoms**: Service fails to start

**Diagnosis**:
```bash
journalctl -u node-exporter -f
node_exporter --web.listen-address=:9100
```

**Resolution**: Check port conflicts, verify file permissions, ensure binary is executable.

### Issue 2: No Metrics Appearing

**Symptoms**: `curl http://localhost:9100/metrics` returns empty

**Diagnosis**:
```bash
curl -v http://localhost:9100/metrics
netstat -tlnp | grep 9100
```

**Resolution**: Check if Node Exporter is running, verify firewall rules, ensure correct port.

### Issue 3: Prometheus Cannot Scrape

**Symptoms**: Target shows DOWN in Prometheus

**Diagnosis**:
```bash
curl http://node:9100/metrics
# Check from Prometheus server
curl http://node:9100/-/healthy
```

**Resolution**: Check network connectivity, firewall rules, DNS resolution, Node Exporter logs.

### Issue 4: High CPU Usage

**Symptoms**: Node Exporter consuming excessive CPU

**Diagnosis**:
```bash
ps aux | grep node_exporter
top -p $(pgrep node_exporter)
```

**Resolution**: Disable heavy collectors (nfsd, infiniband), increase scrape interval, check for metric explosion.

### Issue 5: Missing Specific Metrics

**Symptoms**: Expected metrics not in `/metrics`

**Diagnosis**:
```bash
# Check enabled collectors
curl http://localhost:9100/metrics | grep node_cpu

# List available collectors
node_exporter --help | grep collector
```

**Resolution**: Enable the specific collector, check if collector is disabled by default.

### Issue 6: Permission Denied Errors

**Symptoms**: Logs show "permission denied" for certain collectors

**Diagnosis**:
```bash
ls -la /proc/sys/
ls -la /sys/class/net/
```

**Resolution**: Run as root or add capabilities, disable restricted collectors, use appropriate `--path.*` flags.

### Issue 7: Textfile Collector Not Working

**Symptoms**: Custom metrics not appearing

**Diagnosis**:
```bash
ls -la /var/lib/node_exporter/textfile_collector/
cat /var/lib/node_exporter/textfile_collector/custom.prom
```

**Resolution**: Check directory exists, verify file permissions, ensure file has `.prom` extension, validate Prometheus exposition format.

### Issue 8: Docker Container Metrics Missing

**Symptoms**: Container metrics not reporting

**Diagnosis**:
```bash
docker exec node-exporter curl http://localhost:9100/metrics | grep node_cpu
```

**Resolution**: Ensure `/proc` and `/sys` are mounted, verify `--path.rootfs` is set correctly, check container has host PID namespace.

### Issue 9: Kubernetes DaemonSet Not Running

**Symptoms**: Node Exporter pods not on all nodes

**Diagnosis**:
```bash
kubectl get pods -n monitoring -o wide
kubectl describe pod node-exporter-xxxxx -n monitoring
```

**Resolution**: Check node selectors, verify RBAC permissions, check for resource constraints, ensure image is pulled.

### Issue 10: Metrics Have Gaps

**Symptoms**: Intermittent gaps in metric data

**Diagnosis**:
```bash
# Check Node Exporter uptime
curl http://localhost:9100/metrics | grep process_start_time_seconds

# Check Prometheus scrape duration
curl 'http://localhost:9090/api/v1/query?query=scrape_duration_seconds{job="node"}'
```

**Resolution**: Increase scrape timeout, reduce collector count, check system load, verify Node Exporter stability.

### Issue 11: Incorrect Metric Values

**Symptoms**: Metrics seem wrong or inconsistent

**Diagnosis**:
```bash
# Compare with system commands
free -m
cat /proc/meminfo
df -h
```

**Resolution**: Check for metric type mismatch (counter vs gauge), verify rate calculations, check for unit conversion errors.

### Issue 12: Network Metrics Not Appearing

**Symptoms**: `node_network_*` metrics missing

**Diagnosis**:
```bash
curl http://localhost:9100/metrics | grep node_network
ip link show
```

**Resolution**: Enable netdev collector, check interface names, verify `/sys/class/net` is accessible.

### Issue 13: Disk Metrics Not Correct

**Symptoms**: Disk I/O metrics seem wrong

**Diagnosis**:
```bash
# Check diskstats
cat /proc/diskstats
# Compare with iostat
iostat -x 1
```

**Resolution**: Verify correct device names, check for virtual disks, use appropriate metric queries.

### Issue 14: Memory Metrics Mismatch

**Symptoms**: Node Exporter memory metrics differ from `free`

**Diagnosis**:
```bash
free -m
curl http://localhost:9100/metrics | grep node_memory
```

**Resolution**: Use `node_memory_MemAvailable_bytes` for available memory (includes buffers/cache), not `MemFree`.

### Issue 15: Load Average Not Matching

**Symptoms**: `node_load*` metrics differ from `uptime`

**Diagnosis**:
```bash
uptime
cat /proc/loadavg
curl http://localhost:9100/metrics | grep node_load
```

**Resolution**: Verify correct metric names, check for time alignment, use `node_load1`, `node_load5`, `node_load15`.

### Issue 16: Collector Errors in Logs

**Symptoms**: Node Exporter logs show collector errors

**Diagnosis**:
```bash
journalctl -u node-exporter | grep -i error
```

**Resolution**: Disable problematic collectors, check file system permissions, verify `/proc` and `/sys` are mounted correctly.

---

## 17. Tips and Best Practices

### 1. Use Standard Naming Conventions

Follow the Node Exporter naming conventions for custom metrics:
```
node_<subsystem>_<metric_name>_<unit>
```

### 2. Disable Unused Collectors

```bash
# Only enable what you need
node_exporter \
  --no-collector.nfs \
  --no-collector.nfsd \
  --no-collector.infiniband \
  --no-collector.tapestats \
  --no-collector.xfs \
  --no-collector.zfs
```

### 3. Use `--collector.filesystem.mount-points-exclude`

Exclude virtual filesystems to reduce metric noise.

### 4. Use Textfile Collector for Custom Metrics

Add custom metrics without writing a full collector.

### 5. Set Resource Limits

Always set memory and CPU limits for Node Exporter in containers.

### 6. Use Relabeling to Drop Unnecessary Metrics

```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'node_nfsd_.*'
    action: drop
```

### 7. Monitor Node Exporter Itself

Track `process_*` metrics and `scrape_duration_seconds`.

### 8. Use Consistent Tags

Tag nodes with `env`, `region`, `team`, and `role`.

### 9. Use Recording Rules for Expensive Queries

Precompute CPU, memory, and disk usage percentages.

### 10. Use Appropriate Scrape Intervals

- Critical nodes: 15s
- Standard nodes: 30s
- Non-critical: 60s

### 11. Keep Node Exporter Updated

Regularly update to the latest version for bug fixes and new collectors.

### 12. Use Security Best Practices

Enable TLS, use basic auth, and restrict network access.

### 13. Document Custom Collectors

Document what each custom collector does and how to interpret its metrics.

### 14. Use Version Control for Configuration

Store Node Exporter configuration in Git.

### 15. Test Changes Before Deploying

Test configuration changes on a single node before rolling out.

### 16. Use Dashboards for Visualization

Import community dashboards and customize for your needs.

---

## 18. Command Reference

### node_exporter

```bash
node_exporter \
  --web.listen-address=:9100 \
  --web.telemetry-path=/metrics \
  --web.config.file=/etc/node-exporter/web.yml \
  --path.procfs=/proc \
  --path.sysfs=/sys \
  --path.rootfs=/ \
  --collector.cpu \
  --collector.meminfo \
  --collector.diskstats \
  --collector.filesystem \
  --collector.netdev \
  --collector.loadavg \
  --collector.filefd \
  --collector.uname \
  --collector.time \
  --no-collector.nfs \
  --no-collector.infiniband \
  --collector.systemd \
  --collector.processes \
  --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \
  --log.level=info \
  --version
```

### Useful Commands

```bash
# Check version
node_exporter --version

# List all collectors
node_exporter --help | grep collector

# Test metrics endpoint
curl http://localhost:9100/metrics

# Check health
curl http://localhost:9100/-/healthy

# Check process metrics
curl http://localhost:9100/metrics | grep process_

# Count metrics
curl http://localhost:9100/metrics | grep -v '^#' | grep -v '^$' | wc -l
```

### Common Queries

```promql
# CPU usage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk usage
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# Network bandwidth
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1024 / 1024

# Load average
node_load1
node_load5
node_load15

# Disk I/O
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])
```

---

## 19. Configuration Reference

### Command-Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--web.listen-address` | `:9100` | Address to listen on |
| `--web.telemetry-path` | `/metrics` | Metrics path |
| `--web.config.file` | | Web configuration file |
| `--path.procfs` | `/proc` | procfs mountpoint |
| `--path.sysfs` | `/sys` | sysfs mountpoint |
| `--path.rootfs` | `/` | Root filesystem |
| `--collector.<name>` | | Enable collector |
| `--no-collector.<name>` | | Disable collector |
| `--collector.textfile.directory` | | Textfile collector directory |
| `--collector.filesystem.mount-points-exclude` | | Filesystem exclusion regex |
| `--log.level` | `info` | Log level |

### Collector Configuration

```bash
# Enable specific collectors
node_exporter --collector.cpu --collector.meminfo --collector.diskstats

# Disable specific collectors
node_exporter --no-collector.nfs --no-collector.infiniband

# List enabled collectors
node_exporter --collectors-enabled
```

### Web Configuration

```yaml
# /etc/node-exporter/web.yml
tls_server_config:
  cert_file: string
  key_file: string
  client_auth_type: string
  client_ca_file: string
  min_version: string
basic_auth_users:
  username: password_hash
```

### Systemd Service

```ini
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100 \
  --collector.systemd \
  --collector.processes
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 20. Real-World Examples

### Example 1: Complete Node Monitoring Stack

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
          - web1:9100
          - web2:9100
          - db1:9100
        labels:
          env: production
    relabel_configs:
      - source_labels: [__address__]
        regex: '(.+):(\d+)'
        target_label: instance
        replacement: '${1}'

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml
```

### Example 2: Alert Rules for Node Monitoring

```yaml
# /etc/prometheus/rules/node.rules.yml
groups:
  - name: node
    rules:
      - alert: NodeHighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanizePercentage }}"

      - alert: NodeHighMemory
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Memory critical on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      - alert: NodeDiskSpaceLow
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 85
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanizePercentage }}"

      - alert: NodeNetworkDown
        expr: node_network_up{device="eth0"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Network down on {{ $labels.instance }}"
```

### Example 3: Recording Rules

```yaml
# /etc/prometheus/rules/node_recording.yml
groups:
  - name: node_recording
    interval: 30s
    rules:
      - record: instance:node_cpu_utilization
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

      - record: instance:node_memory_utilization
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

      - record: instance:node_disk_utilization
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

      - record: instance:node_network_receive_rate
        expr: rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1024 / 1024

      - record: instance:node_network_transmit_rate
        expr: rate(node_network_transmit_bytes_total{device="eth0"}[5m]) * 8 / 1024 / 1024
```

### Example 4: Grafana Dashboard Variables

```json
{
  "templating": {
    "list": [
      {
        "name": "instance",
        "type": "query",
        "query": "label_values(node_cpu_seconds_total, instance)",
        "refresh": 2,
        "sort": 1
      },
      {
        "name": "device",
        "type": "query",
        "query": "label_values(node_network_receive_bytes_total{instance=\"$instance\"}, device)",
        "refresh": 2,
        "sort": 1
      },
      {
        "name": "mountpoint",
        "type": "query",
        "query": "label_values(node_filesystem_size_bytes{instance=\"$instance\"}, mountpoint)",
        "refresh": 2,
        "sort": 1
      }
    ]
  }
}
```

---

## 21. Further Reading

### Official Documentation

- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Node Exporter Releases](https://github.com/prometheus/node_exporter/releases)
- [Prometheus Exporter Toolkit](https://github.com/prometheus/exporter-toolkit)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)

### Community Resources

- [Node Exporter Full Dashboard](https://grafana.com/grafana/dashboards/1860)
- [Node Exporter for Prometheus](https://grafana.com/grafana/dashboards/11074)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [Prometheus Community Dashboards](https://grafana.com/grafana/dashboards/?search=node+exporter)

### Books

- *Monitoring with Prometheus* by James Turnbull
- *Prometheus: Up & Running* by Brian Brazil
- *Site Reliability Engineering* by Google

### Related Tools

- [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) - InfluxData's metrics collector
- [collectd](https://collectd.org/) - System statistics collection daemon
- [cadvisor](https://github.com/google/cadvisor) - Container metrics
- [Windows Exporter](https://github.com/prometheus-community/windows_exporter) - Windows metrics
- [MySQL Exporter](https://github.com/prometheus/mysqld_exporter) - MySQL metrics
- [PostgreSQL Exporter](https://github.com/prometheus-community/postgres_exporter) - PostgreSQL metrics
