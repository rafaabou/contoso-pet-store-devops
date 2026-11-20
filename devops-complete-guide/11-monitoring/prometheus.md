# Prometheus Complete Guide

## Table of Contents

1. [What Is Prometheus](#1-what-is-prometheus)
2. [Why Use Prometheus](#2-why-use-prometheus)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [PromQL Query Language](#7-promql-query-language)
8. [Usage Guide](#8-usage-guide-step-by-step)
9. [Custom Exporters](#9-custom-exporters)
10. [Service Discovery](#10-service-discovery)
11. [Storage and Retention](#11-storage-and-retention)
12. [Federation](#12-federation)
13. [Integrations](#13-integrations)
14. [Security](#14-security)
15. [High Availability](#15-high-availability)
16. [Troubleshooting](#16-troubleshooting)
17. [Tips and Best Practices](#17-tips-and-best-practices)
18. [Command Reference](#18-command-reference)
19. [Configuration Reference](#19-configuration-reference)
20. [Real-World Examples](#20-real-world-examples)
21. [Further Reading](#21-further-reading)

---

## 1. What Is Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit originally developed at SoundCloud in 2012. It became the second project to graduate from the Cloud Native Computing Foundation (CNCF) after Kubernetes in 2016. Prometheus collects and stores its metrics as time series data, meaning metrics are stored with a timestamp at which they were recorded, optional key-value pairs called labels, and numeric measurements.

### Key Characteristics

- **Multi-dimensional data model**: Metrics are identified by metric name and optional key-value pairs (labels), enabling rich, flexible queries.
- **Pull-based collection**: Prometheus scrapes metrics from instrumented targets at configured intervals rather than receiving pushed data.
- **Powerful query language**: PromQL enables ad-hoc queries, aggregations, and real-time alerting.
- **No reliance on distributed storage**: Single-server nodes are autonomous, using local storage.
- **Time series database (TSDB)**: Purpose-built storage engine optimized for metric workloads.
- **HTTP pull model**: Every server is independently runnable and does not depend on remote storage.

### Components

The Prometheus ecosystem consists of multiple components:

| Component | Purpose |
|-----------|---------|
| **Prometheus Server** | Scrapes and stores time series data |
| **Alertmanager** | Handles alerts (deduplication, grouping, routing, silencing) |
| **Pushgateway** | Accepts metrics pushed via HTTP for short-lived jobs |
| **Exporters** | Translate third-party metrics into Prometheus format |
| **Client Libraries** | Instrument application code |
| **Promtool** | CLI for rules testing, TSDB operations, and configuration validation |

### Metric Types

Prometheus defines four core metric types:

1. **Counter**: A monotonically increasing value (e.g., total HTTP requests). Resets to zero on process restart.
2. **Gauge**: A value that can go up or down (e.g., temperature, memory usage, queue depth).
3. **Histogram**: Samples observations and counts them in configurable buckets (e.g., request duration). Also provides a sum and count.
4. **Summary**: Similar to histogram but calculates quantiles on the client side.

### Data Model

Every time series is uniquely identified by its metric name and a set of label-value pairs:

```
http_requests_total{method="POST", handler="/api/users"}
```

- **Metric name**: `http_requests_total`
- **Labels**: `method="POST"`, `handler="/api/users"`
- **Sample**: `http_requests_total{method="POST", handler="/api/users"} 1027 1395066363000`

The value `1027` is the sample value, and `1395066363000` is the Unix timestamp in milliseconds.

---

## 2. Why Use Prometheus

### Advantages

- **De facto standard**: Widely adopted in cloud-native ecosystems, with broad tooling and community support.
- **Pull model benefits**: Targets do not need to know about the monitoring system; a broken monitoring target does not affect the target itself.
- **Multi-dimensional labeling**: Labels enable powerful slicing and dicing of metrics without needing separate metric names for each variant.
- **Built-in TSDB**: No external database dependency; data is stored locally with efficient compression.
- **PromQL**: Expressive query language supporting aggregation, filtering, joining, and mathematical operations.
- **Service discovery**: Automatic detection of targets via Kubernetes, Consul, DNS, EC2, and many more.
- **Small footprint**: Single binary, minimal dependencies, low resource usage for small to medium deployments.
- **Active development**: Regular releases, large contributor community, and ecosystem growth.

### When to Use Prometheus

- Container and microservice monitoring (Kubernetes, Docker, ECS)
- Infrastructure monitoring (CPU, memory, disk, network)
- Application performance monitoring (latency, throughput, error rates)
- Business metrics (signups, payments, orders per second)
- Predictive alerting based on rate of change

### Limitations

- **Single-node focus**: Not designed for horizontal scaling or long-term global queries out of the box (requires Thanos or Cortex for that).
- **Pull-based**: Requires targets to be network-reachable; not ideal for edge devices or firewalled environments (use Pushgateway as workaround).
- **Local storage only**: No built-in replication or remote storage (remote_write and Thanos bridge this gap).
- **Alert management**: Alertmanager is a separate component; alerts are not bundled with the server.

---

## 3. Architecture Overview

```
                    ┌──────────────────┐
                    │   Alertmanager   │
                    │  (dedup/route)   │
                    └────────▲─────────┘
                             │ alerts
                    ┌────────┴─────────┐
                    │  Prometheus      │
                    │  Server          │
                    │  ┌────────────┐  │
                    │  │   TSDB     │  │
                    │  └────────────┘  │
                    │  ┌────────────┐  │
                    │  │ PromQL     │  │
                    │  └────────────┘  │
                    └────────▲─────────┘
                             │ scrape (pull)
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────┴───┐  ┌──────┴──────┐  ┌───┴────────┐
     │ Node       │  │ Application │  │ Pushgateway│
     │ Exporter   │  │ /metrics    │  │            │
     └────────────┘  └─────────────┘  └────────────┘
```

### Data Flow

1. **Instrumentation**: Applications expose metrics via an HTTP endpoint (usually `/metrics`) using client libraries.
2. **Scraping**: Prometheus pulls metrics from targets at the configured `scrape_interval`.
3. **Storage**: Scraped samples are written to the local TSDB on disk.
4. **Querying**: PromQL queries retrieve data for dashboards (Grafana) or ad-hoc analysis.
5. **Alerting**: Alert rules evaluate PromQL expressions; firing alerts are sent to Alertmanager.
6. **Notification**: Alertmanager routes alerts to configured receivers (Slack, email, PagerDuty, etc.).

### Relabeling

Relabeling is the process of modifying target labels before they are stored. This is critical for:

- Filtering targets
- Adding or removing labels
- Converting labels from one form to another
- Enriching targets with metadata

---

## 4. Installation

### Binary Download

```bash
PROMETHEUS_VERSION="2.53.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
```

### Systemd Service

```ini
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=30d \
  --web.enable-lifecycle \
  --web.listen-address=:9090
Restart=always

[Install]
WantedBy=multi-user.target
```

### Docker

```bash
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v prometheus_data:/prometheus \
  prom/prometheus:v2.53.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.retention.time=30d
```

### Kubernetes (Helm)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### Docker Compose

```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:v2.53.0
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    restart: unless-stopped

volumes:
  prometheus_data:
```

### Verifying Installation

```bash
# Check version
prometheus --version

# Verify config syntax
promtool check config /etc/prometheus/prometheus.yml

# Test rule files
promtool check rules /etc/prometheus/rules/*.yml
```

---

## 5. Configuration

### Main Configuration File

The main configuration file (`prometheus.yml`) is divided into four sections:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s
  external_labels:
    cluster: production
    region: us-east-1

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets:
          - node1:9100
          - node2:9100
    relabel_configs:
      - source_labels: [__address__]
        regex: '(.+):(\d+)'
        target_label: instance
        replacement: '${1}'

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: ${1}
```

### Global Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `scrape_interval` | `1m` | How frequently to scrape targets |
| `evaluation_interval` | `1m` | How frequently to evaluate rules |
| `scrape_timeout` | `10s` | Per-scrape timeout |
| `external_labels` | | Labels added to time series for federation |

### Scrape Configurations

Each `scrape_config` defines a job:

```yaml
scrape_configs:
  - job_name: 'my-app'
    metrics_path: /metrics
    scheme: http
    scrape_interval: 10s
    scrape_timeout: 5s

    tls_config:
      ca_file: /etc/prometheus/ca.crt
      insecure_skip_verify: false

    basic_auth:
      username: prometheus
      password_file: /etc/prometheus/password

    static_configs:
      - targets: ['app:8080']
        labels:
          env: production

    params:
      format: ['prometheus']
```

### Relabel Config Reference

```yaml
relabel_configs:
  - source_labels: [__address__]
    target_label: instance
    regex: '(.+):\d+'
    replacement: '${1}'

  - source_labels: [__meta_consul_tags]
    regex: '.*,production,.*'
    action: keep

  - source_labels: [__meta_ec2_tag_Name]
    target_label: name

  - source_labels: [__meta_kubernetes_namespace]
    target_label: namespace

  - action: labeldrop
    regex: __meta_.*
```

---

## 6. Core Concepts

### Targets and Endpoints

A target is an endpoint that Prometheus scrapes. Targets can be defined statically or discovered dynamically.

### Jobs and Instances

- **Job**: A group of targets with the same purpose (e.g., all node exporters).
- **Instance**: An individual target within a job, identified by its `instance` label (usually `host:port`).

```
{job="node-exporter", instance="node1:9100"}
{job="node-exporter", instance="node2:9100"}
```

### Labels

Labels are key-value pairs attached to time series:

- Enable dimensional data modeling
- Enable efficient querying and aggregation
- Must have a value (empty string is allowed)
- Must be consistent across all metrics in a job

### Scrape Protocol

Prometheus supports two scrape protocols:

1. **OpenMetrics text format** (preferred): Uses `# EOF` delimiter
2. **Prometheus text format**: Simple line-based

Example metric endpoint:

```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1047 1395066363000
http_requests_total{method="GET",status="404"} 3 1395066363000
# HELP http_request_duration_seconds Request latency
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 1240
http_request_duration_seconds_bucket{le="0.5"} 1300
http_request_duration_seconds_bucket{le="1.0"} 1320
http_request_duration_seconds_bucket{le="+Inf"} 1337
http_request_duration_seconds_sum 873.5
http_request_duration_seconds_count 1337
```

### Recording Rules

Recording rules precompute frequently used or expensive PromQL expressions and save their result as a new time series:

```yaml
groups:
  - name: http.rules
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job)

      - record: instance:node_cpu_utilization
        expr: 1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)
```

### Alert Rules

Alert rules define conditions that trigger notifications:

```yaml
groups:
  - name: alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
          /
          sum(rate(http_requests_total[5m])) by (job)
          > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate is {{ $value | humanizePercentage }}"

      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
```

---

## 7. PromQL Query Language

### Instant Vectors

Select a single sample per time series (the most recent sample):

```
http_requests_total
http_requests_total{method="GET"}
http_requests_total{status=~"5.."}
http_requests_total{handler!~"/api/.*"}
```

### Range Vectors

Select a range of samples:

```
http_requests_total[5m]
rate(http_requests_total[5m])
```

### Scalar

A single numeric value:

```
1024
time()
```

### Common Functions

#### Rate and Increase

```promql
# Per-second average rate of increase over 5 minutes
rate(http_requests_total[5m])

# Total increase over 1 hour
increase(http_requests_total[1h])
```

#### Aggregation

```promql
# Total requests by job
sum(rate(http_requests_total[5m])) by (job)

# Average CPU usage per instance
avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)

# Top 5 instances by memory usage
topk(5, node_memory_MemAvailable_bytes)

# Lowest 3 instances by free disk space
bottomk(3, node_filesystem_avail_bytes)

# Count of targets per job
count(up) by (job)

# Standard deviation of request duration
stddev(http_request_duration_seconds)
```

#### Histogram Quantiles

```promql
# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 99th percentile latency by handler
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, handler)
)
```

#### Predictive Queries

```promql
# Linear prediction of disk space remaining in 4 hours
predict_linear(node_filesystem_avail_bytes[6h], 4*3600)

# Whether disk will be full in 4 hours
predict_linear(node_filesystem_avail_bytes[6h], 4*3600) < 0
```

#### Mathematical Operations

```promql
# CPU utilization percentage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk usage percentage
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# Network bandwidth in Mbps
rate(node_network_receive_bytes_total{device="eth0"}[5m]) * 8 / 1024 / 1024
```

#### Joining Series

```promql
# Join CPU usage with memory usage by instance
node_cpu_seconds_total * on(instance) group_left() node_memory_MemTotal_bytes

# Using label_replace
label_replace(
  up,
  "host",
  "$1",
  "instance",
  "(.*):\d+"
)
```

### Subqueries

```promql
# Max of rate over last 1h, sampled every 5m
max_over_time(
  rate(http_requests_total[5m])[1h:5m]
)
```

---

## 8. Usage Guide (Step-by-Step)

### Step 1: Deploy and Verify

```bash
# Start Prometheus
prometheus --config.file=prometheus.yml

# Verify it is running
curl http://localhost:9090/-/healthy
# Should return "Prometheus Server is Healthy."

# Check targets
curl http://localhost:9090/api/v1/targets | jq
```

### Step 2: Add Your First Target

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'my-app'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:8080']
```

```bash
# Validate configuration
promtool check config prometheus.yml

# Hot-reload (if --web.enable-lifecycle is set)
curl -X POST http://localhost:9090/-/reload
```

### Step 3: Query Metrics

```bash
# Using the API
curl 'http://localhost:9090/api/v1/query?query=up'
curl 'http://localhost:9090/api/v1/query_range?query=rate(http_requests_total[5m])&start=2024-01-01T00:00:00Z&end=2024-01-02T00:00:00Z&step=60'
```

### Step 4: Set Up Recording Rules

```yaml
# /etc/prometheus/rules/app.rules.yml
groups:
  - name: app
    interval: 30s
    rules:
      - record: http_requests:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job, method, status)
```

### Step 5: Set Up Alert Rules

```yaml
groups:
  - name: alerts
    rules:
      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency > 1s on {{ $labels.job }}"
```

### Step 6: Configure Alertmanager

```yaml
# prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### Step 7: Connect Grafana

1. Add Prometheus as a data source in Grafana (URL: `http://prometheus:9090`)
2. Create dashboards using PromQL queries
3. Import community dashboards from grafana.com/dashboards

### Step 8: Monitor Kubernetes

```yaml
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

---

## 9. Custom Exporters

### Building an Exporter

```python
from prometheus_client import start_http_server, Counter, Gauge, Histogram
import time

# Define metrics
REQUEST_COUNT = Counter(
    'myapp_requests_total',
    'Total requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'myapp_request_duration_seconds',
    'Request latency in seconds',
    ['method', 'endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.5, 1.0, 5.0]
)

ACTIVE_CONNECTIONS = Gauge(
    'myapp_active_connections',
    'Number of active connections'
)

def process_request(method, endpoint, status, duration):
    REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status).inc()
    REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(duration)

if __name__ == '__main__':
    start_http_server(8000)
    while True:
        time.sleep(1)
```

### Common Exporters

| Exporter | Port | Purpose |
|----------|------|---------|
| node_exporter | 9100 | System metrics (CPU, disk, memory, network) |
| mysqld_exporter | 9104 | MySQL metrics |
| postgres_exporter | 9187 | PostgreSQL metrics |
| redis_exporter | 9121 | Redis metrics |
| nginx_exporter | 9113 | Nginx metrics |
| blackbox_exporter | 9115 | HTTP/TCP/ICMP/DNS probing |
| process_exporter | 9256 | Process-level metrics |
| kafka_exporter | 9308 | Kafka metrics |
| rabbitmq_exporter | 9419 | RabbitMQ metrics |
| elasticsearch_exporter | 9114 | Elasticsearch metrics |

---

## 10. Service Discovery

### Kubernetes SD

```yaml
scrape_configs:
  # Pod discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

  # Service discovery
  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true

  # Node discovery
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - source_labels: [__meta_kubernetes_node_label_kubernetes_io_os]
        action: keep
        regex: linux
```

### Consul SD

```yaml
scrape_configs:
  - job_name: 'consul'
    consul_sd_configs:
      - server: 'consul:8500'
        services: []
        tags:
          - prometheus
    relabel_configs:
      - source_labels: [__meta_consul_service_metadata_prometheus_path]
        target_label: __metrics_path__
      - source_labels: [__meta_consul_service_metadata_prometheus_port]
        target_label: __address__
        regex: (.+)
        replacement: ${1}
```

### EC2 SD

```yaml
scrape_configs:
  - job_name: 'ec2'
    ec2_sd_configs:
      - region: us-east-1
        access_key: YOUR_ACCESS_KEY
        secret_key: YOUR_SECRET_KEY
        port: 9100
        filters:
          - name: tag:Environment
            values:
              - production
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: name
```

### File SD

```json
[
  {
    "targets": ["host1:9100", "host2:9100"],
    "labels": {
      "env": "production",
      "job": "node-exporter"
    }
  }
]
```

```yaml
scrape_configs:
  - job_name: 'file-sd'
    file_sd_configs:
      - files:
          - /etc/prometheus/targets/*.json
        refresh_interval: 5m
```

### DNS SD

```yaml
scrape_configs:
  - job_name: 'dns'
    dns_sd_configs:
      - names:
          - 'prometheus.service.consul'
        type: SRV
        refresh_interval: 30s
```

---

## 11. Storage and Retention

### Local Storage Configuration

```bash
prometheus \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=30d \
  --storage.tsdb.retention.size=10GB
```

### Remote Write

```yaml
remote_write:
  - url: "http://thanos-receive:19291/api/v1/receive"
    queue_config:
      max_samples_per_send: 10000
      batch_send_deadline: 5s
      max_shards: 30
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'go_.*'
        action: drop
```

### Remote Read

```yaml
remote_read:
  - url: "http://thanos-query:9090/api/v1/read"
    read_recent: true
```

### Storage Optimization

- Use recording rules to precompute expensive queries
- Drop high-cardinality labels at scrape time via relabeling
- Use `metric_relabel_configs` to drop unwanted metrics
- Monitor TSDB metrics (prometheus_tsdb_head_series, prometheus_tsdb_storage_blocks_bytes)

### Compaction and Cleanup

```bash
# Delete data for a specific time range
promtool tsdb delete-tombstones --match='{job="test"}' /var/lib/prometheus

# Analyze TSDB
promtool tsdb analyze /var/lib/prometheus

# Check admin API (requires --web.enable-admin-api)
curl -X POST http://localhost:9090/api/v1/admin/tsdb/clean_tombstones
```

---

## 12. Federation

### Hierarchical Federation

```yaml
# Global Prometheus (federates from regional)
scrape_configs:
  - job_name: 'federate-us-east'
    honor_labels: true
    metrics_path: /federate
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets:
          - us-east-prometheus:9090

  - job_name: 'federate-eu-west'
    honor_labels: true
    metrics_path: /federate
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets:
          - eu-west-prometheus:9090
```

### Cross-Service Federation

```yaml
# Only federate specific metrics
params:
  'match[]':
    - '{__name__=~"job:.*"}'
    - '{__name__=~"node_.*"}'
    - '{job="prometheus"}'
```

---

## 13. Integrations

### Grafana

```yaml
# grafana.ini or provisioning
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
```

### Alertmanager

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
      timeout: 10s
```

### Kubernetes Metrics

```bash
# Install kube-state-metrics
kubectl apply -f https://github.com/kubernetes/kube-state-metrics/releases/latest/download/standalone/kube-state-metrics.yaml

# Install Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack
```

### Service Mesh (Istio)

Prometheus automatically scrapes Istio sidecar metrics when configured for pod discovery.

### CI/CD Integration

```yaml
# GitLab CI
prometheus:
  image: prom/prometheus:v2.53.0
  script:
    - promtool check config prometheus.yml
    - promtool check rules rules/*.yml
```

---

## 14. Security

### TLS Configuration

```yaml
global:
  tls_config:
    ca_file: /etc/prometheus/ca.crt
    cert_file: /etc/prometheus/server.crt
    key_file: /etc/prometheus/server.key
    client_auth_type: RequireAndVerifyClientCert
    client_ca_file: /etc/prometheus/ca.crt
```

### Authentication

```bash
# Basic auth for web UI
prometheus \
  --web.config.file=/etc/prometheus/web.yml

# /etc/prometheus/web.yml
basic_auth_users:
  admin: $2y$10$hash_here
tls_server_config:
  cert_file: /etc/prometheus/server.crt
  key_file: /etc/prometheus/server.key
```

### Scrape Authentication

```yaml
scrape_configs:
  - job_name: 'secure-app'
    tls_config:
      ca_file: /etc/prometheus/ca.crt
    basic_auth:
      username: prometheus
      password_file: /etc/prometheus/password
```

### RBAC (Kubernetes)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
  - apiGroups: [""]
    resources: ['nodes', 'nodes/proxy', 'services', 'endpoints', 'pods']
    verbs: ['get', 'list', 'watch']
  - apiGroups: ['extensions']
    resources: ['ingresses']
    verbs: ['get', 'list', 'watch']
  - nonResourceURLs: ['/metrics']
    verbs: ['get']
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus
spec:
  podSelector:
    matchLabels:
      app: prometheus
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - protocol: TCP
          port: 9090
  egress:
    - to: []
      ports:
        - protocol: TCP
          port: 9093
```

---

## 15. High Availability

### Two-Server Redundancy

Run two identical Prometheus servers scraping the same targets:

```yaml
# Server 1 and Server 2 have identical configs
# Use external_label to distinguish
global:
  external_labels:
    replica: A  # or B
```

### Load Balancing

Place a load balancer in front:

```
                    ┌─────────────┐
                    │ Load Balancer│
                    └──────┬──────┘
                   ┌───────┴───────┐
              ┌────┴────┐     ┌────┴────┐
              │Prom. A  │     │Prom. B  │
              └─────────┘     └─────────┘
```

### Thanos for HA and Long-Term Storage

```yaml
# Thanos Sidecar
thanos sidecar \
  --tsdb.path=/var/lib/prometheus \
  --prometheus.url=http://localhost:9090 \
  --objstore.config-file=bucket.yml

# Thanos Query
thanos query \
  --store=sidecar1:10901 \
  --store=sidecar2:10901 \
  --store=store1:10901
```

---

## 16. Troubleshooting

### Issue 1: Targets Showing as DOWN

**Symptoms**: Target shows `up == 0` in the Targets page.

**Diagnosis**:
```bash
# Check if the endpoint is reachable
curl http://target:9100/metrics

# Check Prometheus logs
journalctl -u prometheus | grep -i error

# Check scrape errors
curl 'http://localhost:9090/api/v1/query?query=scrape_duration_seconds{job="node-exporter"}'
```

**Resolution**: Ensure the target is running, firewall allows port 9090→9100, and the metrics path is correct.

### Issue 2: High Memory Usage

**Symptoms**: Prometheus OOM or using excessive RAM.

**Diagnosis**:
```bash
# Check time series count
curl 'http://localhost:9090/api/v1/status/tsdb' | jq '.data.seriesCountByMetricName[:10]'

# Check head stats
curl 'http://localhost:9090/api/v1/status/runtimeinfo' | jq '.data'
```

**Resolution**:
- Reduce cardinality by dropping high-cardinality labels
- Use `metric_relabel_configs` to drop unused metrics
- Increase `--storage.tsdb.retention.time` less aggressively
- Increase memory limit

### Issue 3: PromQL Query Timeout

**Symptoms**: Dashboard queries timing out, "context deadline exceeded" errors.

**Diagnosis**:
```bash
# Check query performance
curl 'http://localhost:9090/api/v1/status/config' | jq

# Test query with timeout
curl --max-time 30 'http://localhost:9090/api/v1/query?query=rate(http_requests_total[5m])'
```

**Resolution**: Use recording rules for expensive queries, increase `--query.timeout`, reduce time range in queries.

### Issue 4: Disk Space Exhaustion

**Symptoms**: `no space left on device` errors in logs.

**Diagnosis**:
```bash
du -sh /var/lib/prometheus
ls -la /var/lib/prometheus/
promtool tsdb analyze /var/lib/prometheus
```

**Resolution**: Reduce retention time, enable remote_write to offload data, add disk capacity.

### Issue 5: Stale Data After Target Migration

**Symptoms**: Old instance data persisting after target moves.

**Resolution**: Ensure `honor_labels: false` (default) is set, or use `honor_labels: true` if targets override instance labels.

### Issue 6: Config Reload Fails

**Symptoms**: `/-/reload` returns error.

**Diagnosis**:
```bash
promtool check config /etc/prometheus/prometheus.yml
promtool check rules /etc/prometheus/rules/*.yml
```

**Resolution**: Fix YAML syntax errors, check for duplicate labels or rule names.

### Issue 7: Missing Metrics

**Symptoms**: Expected metrics not appearing in queries.

**Diagnosis**:
```bash
# Check if metric exists at all
curl 'http://localhost:9090/api/v1/label/__name__/values' | jq '.data[] | select(startswith("http_"))'

# Check scrape targets
curl 'http://localhost:9090/api/v1/targets' | jq '.data.activeTargets[].lastScrapeError'
```

**Resolution**: Verify the metric name, check that the exporter is correctly instrumented, and ensure the scrape is succeeding.

### Issue 8: Alert Not Firing

**Symptoms**: Alert rule exists but never fires.

**Diagnosis**:
```bash
# Check rule evaluation
curl 'http://localhost:9090/api/v1/rules' | jq '.data.groups[].rules[] | select(.name=="HighErrorRate")'

# Check alert state
curl 'http://localhost:9090/api/v1/alerts' | jq
```

**Resolution**: Verify the PromQL expression, check the `for` duration, ensure `evaluation_interval` is sufficient.

### Issue 9: High Scrape Duration

**Symptoms**: Scrape duration exceeding `scrape_timeout`.

**Diagnosis**:
```bash
curl 'http://localhost:9090/api/v1/query?query=scrape_duration_seconds'
```

**Resolution**: Increase `scrape_timeout`, optimize the exporter, reduce metric cardinality, or split into smaller jobs.

### Issue 10: Timestamp Issues

**Symptoms**: Duplicate or missing data points, out-of-order samples.

**Resolution**: Ensure targets are sending monotonic counters, avoid using `time()` in instrumented code, check for clock skew.

### Issue 11: Cannot Scrape HTTPS Targets

**Symptoms**: TLS handshake errors when scraping.

**Resolution**:
```yaml
scrape_configs:
  - job_name: 'https-app'
    scheme: https
    tls_config:
      ca_file: /etc/prometheus/ca.crt
      insecure_skip_verify: false
```

### Issue 12: Too Many Time Series (Cardinality Explosion)

**Symptoms**: Memory usage spiking, slow queries.

**Diagnosis**:
```bash
curl 'http://localhost:9090/api/v1/status/tsdb' | jq '.data.seriesCountByLabelName[:10]'
```

**Resolution**: Drop high-cardinality labels with `metric_relabel_configs`, use `labeldrop` regex.

### Issue 13: Federation Returns Empty Results

**Symptoms**: Federated Prometheus shows no data from regional servers.

**Diagnosis**:
```bash
curl 'http://regional:9090/federate?match[]={job="node-exporter"}'
```

**Resolution**: Verify `match[]` parameters, check firewall rules, ensure `honor_labels` is correctly set.

### Issue 14: Pushgateway Metrics Disappearing

**Symptoms**: Metrics pushed to Pushgateway not scraped.

**Resolution**: Pushgateway does not persist metrics by default. Push metrics with a TTL: `pushgateway_ttl=1h` in push URL.

### Issue 15: Prometheus Service Discovery Not Finding Pods

**Symptoms**: Kubernetes pods not showing up as targets.

**Diagnosis**:
```bash
curl 'http://localhost:9090/api/v1/targets?discoveredLabels={"job":"kubernetes-pods"}'
```

**Resolution**: Check RBAC permissions, verify annotations, ensure `prometheus.io/scrape: "true"` annotation exists.

### Issue 16: Alertmanager Not Receiving Alerts

**Symptoms**: Alerts firing in Prometheus but not reaching Alertmanager.

**Diagnosis**:
```bash
# Check Prometheus alertmanager config
curl 'http://localhost:9090/api/v1/status/config' | jq '.data.yaml' | grep alertmanager

# Check Alertmanager
curl http://alertmanager:9093/-/healthy
```

**Resolution**: Verify `alerting` section in prometheus.yml, check network connectivity, ensure Alertmanager is running.

### Issue 17: TSDB Corruption

**Symptoms**: Prometheus crashes on startup with TSDB errors.

**Resolution**:
```bash
# Check block integrity
promtool tsdb check /var/lib/prometheus

# Delete corrupted blocks (data loss)
promtool tsdb clean-tombstones /var/lib/prometheus
```

---

## 17. Tips and Best Practices

### 1. Use Recording Rules for Expensive Queries

Precompute frequently used expressions to reduce query load and improve dashboard performance.

### 2. Keep Label Cardinality Low

Avoid using user IDs, request IDs, or timestamps as labels. These create millions of time series and exhaust memory.

### 3. Use `metric_relabel_configs` to Drop Unwanted Metrics

```yaml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'go_.*|process_.*'
    action: drop
```

### 4. Set Appropriate Scrape Intervals

- Infrastructure: 15-30s (node_exporter)
- Application: 10-15s
- Business metrics: 60s

### 5. Use `honor_labels: true` When Targets Provide Correct Labels

This prevents Prometheus from overriding target-provided labels with job/instance.

### 6. Version Control Everything

Store `prometheus.yml`, rule files, and dashboards in Git. Use CI/CD for validation and deployment.

### 7. Test Alert Rules Before Deploying

```bash
promtool test rules test_alerts.yml
```

### 8. Monitor Prometheus Itself

Track these internal metrics:
- `prometheus_tsdb_head_series` (total time series)
- `prometheus_config_last_reload_successful` (config reload status)
- `scrape_duration_seconds` (scrape performance)
- `prometheus_engine_query_duration_seconds` (query performance)

### 9. Use External Labels for Federation

Always set `external_labels` in the global section for cross-cluster queries.

### 10. Implement Alertmanager Alert Routing

Group related alerts, use inhibition rules to suppress low-severity alerts during incidents, and configure silences for maintenance windows.

### 11. Plan for Capacity

Monitor:
- Ingestion rate (samples/sec)
- Time series count
- Disk usage growth rate
- Query performance

### 12. Use Thanos or Cortex for Long-Term Storage

Local storage is not suitable for months or years of data retention. Use remote_write to offload to long-term storage.

### 13. Secure All Endpoints

Enable TLS, use authentication, and restrict network access to Prometheus and Alertmanager endpoints.

### 14. Use Consistent Label Naming

Follow conventions: use snake_case, be consistent across jobs (e.g., always use `method` not `http_method`).

### 15. Set `scrape_timeout` Appropriately

`scrape_timeout` should be less than `scrape_interval` to prevent overlapping scrapes.

### 16. Use Prometheus Operator in Kubernetes

The Prometheus Operator manages Prometheus instances declaratively, providing CRDs for `Prometheus`, `ServiceMonitor`, `PrometheusRule`, and `AlertmanagerConfig`.

### 17. Enable Lifecycle API for Hot Reloads

`--web.enable-lifecycle` enables `/-/reload` for configuration updates without restart.

---

## 18. Command Reference

### prometheus

```bash
prometheus --config.file=prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=30d \
  --web.listen-address=:9090 \
  --web.enable-lifecycle \
  --web.enable-admin-api
```

### promtool

```bash
# Validate config
promtool check config prometheus.yml

# Validate rules
promtool check rules rules/*.yml

# Test rules
promtool test rules tests/*.yml

# Query (non-interactive)
promtool query instant --remote.url http://localhost:9090 'up'

# TSDB operations
promtool tsdb analyze /var/lib/prometheus
promtool tsdb check /var/lib/prometheus
promtool tsdb clean-tombstones /var/lib/prometheus

# Debug queries
promtool debug query 'up' --remote.url http://localhost:9090
```

### Hot Reload

```bash
# Via HTTP API
curl -X POST http://localhost:9090/-/reload

# Via SIGHUP
kill -HUP $(pidof prometheus)
```

### API Endpoints

```bash
# Health check
curl http://localhost:9090/-/healthy

# Ready check
curl http://localhost:9090/-/ready

# Runtime info
curl http://localhost:9090/api/v1/status/runtimeinfo

# TSDB info
curl http://localhost:9090/api/v1/status/tsdb

# Config
curl http://localhost:9090/api/v1/status/config

# Targets
curl http://localhost:9090/api/v1/targets

# Rules
curl http://localhost:9090/api/v1/rules

# Alerts
curl http://localhost:9090/api/v1/alerts
```

---

## 19. Configuration Reference

### Global Section

```yaml
global:
  scrape_interval: 15s          # Default scrape interval
  evaluation_interval: 15s      # Rule evaluation interval
  scrape_timeout: 10s           # Scrape timeout
  external_labels:              # Added to all metrics for federation
    cluster: production
    environment: prod
    replica: a
```

### Scrape Config

```yaml
scrape_configs:
  - job_name: string              # Required: job label
    metrics_path: /metrics        # Path to scrape
    scheme: http                  # http or https
    scrape_interval: 15s          # Override global
    scrape_timeout: 10s           # Override global
    sample_limit: 5000            # Max samples per scrape
    series_limit: 10000           # Max unique series per scrape

    tls_config:                   # TLS settings
      ca_file: string
      cert_file: string
      key_file: string
      insecure_skip_verify: false
      min_version: TLS12

    basic_auth:                   # Basic auth
      username: string
      password: string
      password_file: string

    bearer_token: string          # Bearer token
    bearer_token_file: string     # Bearer token file

    honor_labels: false           # Override target labels
    honor_timestamps: true        # Use target timestamps

    static_configs: []            # Static targets
    kubernetes_sd_configs: []     # Kubernetes discovery
    consul_sd_configs: []         # Consul discovery
    dns_sd_configs: []            # DNS discovery
    ec2_sd_configs: []            # EC2 discovery
    file_sd_configs: []           # File discovery

    relabel_configs: []           # Relabel before scrape
    metric_relabel_configs: []    # Relabel after scrape
```

### Alerting Section

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
      timeout: 10s
    - consul_sd_configs:
        - server: consul:8500
          services: ['alertmanager']
  alert_relabel_configs:          # Deduplicate alerts
    - source_labels: [__name__]
      regex: 'alertmanagers'
      action: drop
```

### Rule Files

```yaml
groups:
  - name: string                  # Group name
    interval: 15s                 # Evaluation interval
    rules:
      - alert: string             # Alert name (alerts only)
        expr: PromQL              # Expression (required)
        for: 5m                   # Duration before firing
        labels: {}                # Additional labels
        annotations: {}           # Alert annotations
      - record: string            # Recording rule name
        expr: PromQL              # Expression (required)
```

---

## 20. Real-World Examples

### Example 1: Node Monitoring

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
          - web1:9100
          - web2:9100
          - db1:9100
        labels:
          env: production

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

      - alert: NodeHighMemory
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Memory critical on {{ $labels.instance }}"

      - alert: NodeDiskSpaceLow
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 85
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"
```

### Example 2: HTTP Service Monitoring

```yaml
groups:
  - name: http
    interval: 30s
    rules:
      - record: http_requests:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job, method, handler, status)

      - record: http_request_duration:p99
        expr: histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job, handler))

      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job) /
          sum(rate(http_requests_total[5m])) by (job) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate > 5% on {{ $labels.job }}"

      - alert: HighLatency
        expr: histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job)) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency > 2s on {{ $labels.job }}"
```

### Example 3: Database Monitoring

```yaml
scrape_configs:
  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

groups:
  - name: database
    rules:
      - alert: MySQLDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MySQL is down"

      - alert: PostgreSQLConnectionsHigh
        expr: sum(pg_stat_activity_count) / pg_settings_max_connections > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PostgreSQL connections > 80%"

      - alert: SlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High slow query rate"
```

### Example 4: Kubernetes Monitoring

```yaml
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__

groups:
  - name: kubernetes
    rules:
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} crash looping"

      - alert: PodNotReady
        expr: kube_pod_status_ready{condition="true"} == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} not ready"

      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.node }} not ready"
```

---

## 21. Further Reading

### Official Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Tutorial](https://prometheus.io/docs/practices/instrumentation/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Alerting Best Practices](https://prometheus.io/docs/practices/alerting/)

### Books

- *Monitoring with Prometheus* by James Turnbull
- *Prometheus: Up & Running* by Brian Brazil
- *Site Reliability Engineering* by Google (Chapter on Monitoring)

### Community Resources

- [Prometheus GitHub](https://github.com/prometheus/prometheus)
- [Prometheus Community Dashboards](https://grafana.com/grafana/dashboards/?search=prometheus)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [Prometheus Blog](https://prometheus.io/blog/)

### Related Tools

- [Thanos](https://thanos.io/) - Highly available Prometheus with long-term storage
- [Cortex](https://cortexmetrics.io/) - Horizontally scalable Prometheus
- [VictoriaMetrics](https://victoriametrics.com/) - Fast, cost-effective Prometheus-compatible TSDB
- [Mimir](https://grafana.com/oss/mimir/) - Grafana Mimir for long-term storage
- [Alertmanager](https://prometheus.io/docs/alerting/latest/configuration/) - Alert routing and deduplication
