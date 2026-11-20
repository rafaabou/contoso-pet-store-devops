# Loki Complete Guide

## Table of Contents

1. [What Is Loki](#1-what-is-loki)
2. [Why Use Loki](#2-why-use-loki)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [LogQL Query Language](#7-logql-query-language)
8. [Promtail](#8-promtail)
9. [Log Labels](#9-log-labels)
10. [Retention and Compaction](#10-retention-and-compaction)
11. [Grafana Integration](#11-grafana-integration)
12. [Alerting](#12-alerting)
13. [Security](#13-security)
14. [Performance Tuning](#14-performance-tuning)
15. [Backup and Recovery](#15-backup-and-recovery)
16. [Troubleshooting](#16-troubleshooting)
17. [Tips and Best Practices](#17-tips-and-best-practices)
18. [Command Reference](#18-command-reference)
19. [Configuration Reference](#19-configuration-reference)
20. [Real-World Examples](#20-real-world-examples)
21. [Further Reading](#21-further-reading)

---

## 1. What Is Loki

Grafana Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus. It does not index the contents of logs but rather only indexes labels for each log stream, making it more cost-effective and operationally simpler than other logging solutions.

### Key Characteristics

- **Label-Based Indexing**: Only indexes labels, not log content
- **Cost-Effective**: Lower storage requirements than full-text indexing
- **Horizontally Scalable**: Add more nodes to increase capacity
- **Multi-Tenant**: Support for multiple organizations
- **Grafana Native**: Seamless integration with Grafana
- **Prometheus-Inspired**: Similar query language and operational model
- **Push and Pull**: Support for both log shipping methods
- **Chunk-Based Storage**: Logs stored in compressed chunks

### Use Cases

- **Kubernetes Logging**: Native Kubernetes support with labels
- **Application Logging**: Centralized logging for applications
- **Infrastructure Monitoring**: Server and infrastructure logs
- **Compliance Logging**: Audit and compliance log storage
- **Debugging**: Quick log search during incident response
- **Cost Optimization**: Lower cost alternative to Elasticsearch
- **Grafana Ecosystem**: When already using Grafana for metrics

### Loki vs Other Solutions

| Feature | Loki | Elasticsearch | Splunk |
|---------|------|---------------|--------|
| Indexing | Labels only | Full-text | Full-text |
| Storage | Compressed chunks | Inverted index | Proprietary |
| Query Language | LogQL | KQL/Lucene | SPL |
| Cost | Low | High | High |
| Scalability | Excellent | Good | Good |
| Grafana Integration | Native | Plugin | Plugin |

---

## 2. Why Use Loki

### Advantages Over Alternatives

**Compared to Elasticsearch:**
- 10x lower storage costs
- Simpler operations
- Better Kubernetes integration
- Native Grafana support
- Lower resource usage

**Compared to Splunk:**
- Free and open-source
- Better for high-volume logs
- Simpler query language
- Better Grafana integration

**Compared to Fluentd/Fluent Bit:**
- Purpose-built for log aggregation
- Better storage efficiency
- Built-in query capabilities
- Native Grafana dashboards

### When Loki Excels

- You already use Grafana for metrics
- You need cost-effective log storage
- You're running Kubernetes
- You have high-volume log data
- You need simple operations
- You want label-based querying

---

## 3. Architecture Overview

### Loki Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Loki Architecture                          │
│                                                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  Promtail   │    │  Promtail   │    │  Promtail   │     │
│  │  (Node 1)   │    │  (Node 2)   │    │  (Node 3)   │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Loki Distributor                       ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             ││
│  │  │ Ingest   │  │ Ingest   │  │ Ingest   │             ││
│  │  │ Ring     │  │ Ring     │  │ Ring     │             ││
│  │  └──────────┘  └──────────┘  └──────────┘             ││
│  └─────────────────────────────────────────────────────────┘│
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Loki Ingester                         ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             ││
│  │  │ Ingester │  │ Ingester │  │ Ingester │             ││
│  │  │ (Flush)  │  │ (Flush)  │  │ (Flush)  │             ││
│  │  └──────────┘  └──────────┘  └──────────┘             ││
│  └─────────────────────────────────────────────────────────┘│
│         │                  │                  │              │
│         ▼                  ▼                  ▼              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Object Storage                        ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             ││
│  │  │ S3/GCS  │  │ S3/GCS  │  │ S3/GCS  │             ││
│  │  │ MinIO   │  │ MinIO   │  │ MinIO   │             ││
│  │  └──────────┘  └──────────┘  └──────────┘             ││
│  └─────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Loki Querier                          ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             ││
│  │  │ Querier  │  │ Querier  │  │ Querier  │             ││
│  │  │ (Index)  │  │ (Index)  │  │ (Index)  │             ││
│  │  └──────────┘  └──────────┘  └──────────┘             ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **Distributor** | Receives log entries, validates, and distributes to ingesters |
| **Ingester** | Receives log entries, builds chunks, flushes to storage |
| **Querier** | Handles LogQL queries, fetches data from ingesters and storage |
| **Query Frontend** | Splits and caches queries for better performance |
| **Compactor** | Compacts and deduplicates stored chunks |
| **Ruler** | Evaluates recording and alerting rules |
| **Index Gateway** | Caches index data for faster queries |

### Data Flow

```
1. Promtail → Distributor: Log entries with labels
2. Distributor → Ingester: Distributes via hash ring
3. Ingester → Storage: Flushes compressed chunks
4. Querier → Storage: Fetches chunks for queries
5. Query Frontend → Querier: Splits and caches queries
6. Ruler → Storage: Evaluates rules, writes alerts
```

---

## 4. Installation

### Prerequisites

```bash
# System requirements
- RAM: 2GB minimum (4GB+ recommended)
- CPU: 2+ cores
- Disk: 50GB+ (SSD recommended for index)
- Object storage: S3, GCS, or MinIO
```

### Install Binary

```bash
# Download Loki
wget https://github.com/grafana/loki/releases/download/v2.9.4/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
chmod +x loki-linux-amd64
sudo mv loki-linux-amd64 /usr/local/bin/loki

# Download Promtail
wget https://github.com/grafana/loki/releases/download/v2.9.4/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
chmod +x promtail-linux-amd64
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# Download LogCLI (optional)
wget https://github.com/grafana/loki/releases/download/v2.9.4/logcli-linux-amd64.zip
unzip logcli-linux-amd64.zip
chmod +x logcli-linux-amd64
sudo mv logcli-linux-amd64 /usr/local/bin/logcli

# Download Loki Canary (optional)
wget https://github.com/grafana/loki/releases/download/v2.9.4/loki-canary-linux-amd64.zip
unzip loki-canary-linux-amd64.zip
chmod +x loki-canary-linux-amd64
sudo mv loki-canary-linux-amd64 /usr/local/bin/loki-canary
```

### Install with Docker

```bash
# Single instance
docker run -d \
  --name loki \
  -p 3100:3100 \
  -v /var/log:/var/log \
  grafana/loki:2.9.4

# With configuration
docker run -d \
  --name loki \
  -p 3100:3100 \
  -v /var/log:/var/log \
  -v ./loki-config.yml:/etc/loki/local-config.yaml \
  grafana/loki:2.9.4 -config.file=/etc/loki/local-config.yaml

# Promtail
docker run -d \
  --name promtail \
  -v /var/log:/var/log \
  -v ./promtail-config.yml:/etc/promtail/config.yml \
  grafana/promtail:2.9.4 -config.file=/etc/promtail/config.yml
```

### Install with Docker Compose

```yaml
version: '3.8'
services:
  loki:
    image: grafana/loki:2.9.4
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:2.9.4
    container_name: promtail
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - loki
    networks:
      - loki

volumes:
  loki-data:
  grafana-data:

networks:
  loki:
    driver: bridge
```

### Install with Helm (Kubernetes)

```bash
# Add Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
helm install loki grafana/loki \
  --namespace logging \
  --create-namespace \
  --set persistence.enabled=true \
  --set persistence.size=10Gi

# Install Promtail
helm install promtail grafana/promtail \
  --namespace logging \
  --set config.lokiAddress=http://loki:3100/loki/api/v1/push

# Install Grafana
helm install grafana grafana/grafana \
  --namespace logging \
  --set adminPassword=admin \
  --set persistence.enabled=true
```

### Install with Helm (Distributed Mode)

```bash
# Install Loki in distributed mode
helm install loki grafana/loki-distributed \
  --namespace logging \
  --set distributor.replicas=3 \
  --set ingester.replicas=3 \
  --set querier.replicas=3
```

---

## 5. Configuration

### loki-config.yml (Basic Config)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: /loki/chunks

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_query_parallelism: 32
  max_query_series: 5000
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150

chunk_store_config:
  max_look_back_period: 0

table_manager:
  retention_deletes_enabled: false
  retention_period: 0

analytics:
  reporting_enabled: false
```

### loki-config.yml (S3 Backend)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    s3:
      s3: https://s3.amazonaws.com
      bucketnames: my-loki-bucket
      access_key_id: AKIAIOSFODNN7EXAMPLE
      secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
      region: us-east-1
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  aws:
    s3: https://s3.amazonaws.com
    bucketnames: my-loki-bucket
    access_key_id: AKIAIOSFODNN7EXAMPLE
    secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    region: us-east-1
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    shared_store: s3

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_query_parallelism: 32
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  s3:
    bucketnames: my-loki-bucket
```

### loki-config.yml (Microservices)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

distributor:
  ring:
    kvstore:
      store: memberlist

ingester:
  lifecycler:
    ring:
      kvstore:
        store: memberlist
      replication_factor: 3
  chunk_idle_period: 5m
  chunk_retain_period: 30s

memberlist:
  join_members:
    - loki-0.loki-headless.logging.svc.cluster.local
    - loki-1.loki-headless.logging.svc.cluster.local
    - loki-2.loki-headless.logging.svc.cluster.local

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  aws:
    s3: https://s3.amazonaws.com
    bucketnames: my-loki-bucket
    region: us-east-1
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    shared_store: s3

limits_config:
  max_query_parallelism: 32
  ingestion_rate_mb: 16
```

---

## 6. Core Concepts

### Log Streams

A log stream is a unique combination of labels that identifies a set of logs.

```
# Log stream = labels + logs
{app="nginx", env="production", instance="web-1"} 
  -> [log1, log2, log3, ...]

# Different streams
{app="nginx", env="production", instance="web-1"}
{app="nginx", env="production", instance="web-2"}
{app="auth-service", env="production", instance="api-1"}
```

### Labels

Labels are key-value pairs that identify log streams.

```
# Good labels (low cardinality)
app="nginx"
env="production"
level="error"
job="api-server"

# Bad labels (high cardinality - avoid!)
user_id="12345"
request_id="abc-def-ghi"
session_id="xyz-789"
```

### Chunks

Logs are stored in compressed chunks on the filesystem or object storage.

```
# Chunk lifecycle
1. Ingested → In-memory buffer
2. Full → Flushed to storage
3. Compacted → Merged with other chunks
4. Expired → Deleted (based on retention)
```

### Index

The index maps label sets to chunks for efficient querying.

```
# Index structure
Label Set → Chunk ID → Chunk Location

Example:
{app="nginx", level="error"} → chunk_001 → s3://bucket/chunks/chunk_001
{app="nginx", level="info"}  → chunk_002 → s3://bucket/chunks/chunk_002
```

### Querying

Loki queries logs using LogQL, which is similar to Prometheus PromQL.

```
# Basic query
{app="nginx"}

# With filter
{app="nginx"} |~ "error"

# With aggregation
count_over_time({app="nginx"} [5m])

# With unwrap
rate({app="nginx"} | unwrap duration [5m])
```

---

## 7. LogQL Query Language

### Log Queries

```logql
# Match all logs from a stream
{app="nginx"}

# Multiple labels
{app="nginx", env="production"}

# Regex matching
{app=~"nginx|apache"}

# Negation
{app="nginx", env!="development"}

# Log pipeline
{app="nginx"} | logfmt | level="error"
{app="nginx"} | json | status >= 500
{app="nginx"} | pattern "<method> <path> <status>" | status="500"
{app="nginx"} | regexp "(?P<ip>\\d+\\.\\d+\\.\\d+\\.\\d+)"

# Line filters
{app="nginx"} |= "error"
{app="nginx"} != "debug"
{app="nginx"} |~ "error|fail"
{app="nginx"} !~ "debug|trace"
```

### Metric Queries

```logql
# Count logs per second
rate({app="nginx"}[5m])

# Count logs per label
count_over_time({app="nginx"}[5m])

# Sum of values
sum(rate({app="nginx"} | unwrap bytes [5m]))

# Average
avg_over_time({app="nginx"} | unwrap duration [5m])

# Quantiles
quantile_over_time(0.99, {app="nginx"} | unwrap duration [5m])

# Topk
topk(10, sum by (path) (rate({app="nginx"}[5m])))

# Bottomk
bottomk(5, sum by (path) (rate({app="nginx"}[5m])))

# Label aggregation
sum by (status) (rate({app="nginx"}[5m]))
sum without (instance) (rate({app="nginx"}[5m]))
```

### Parse Operations

```logql
# JSON parsing
{app="nginx"} | json
{app="nginx"} | json | level="error"

# Logfmt parsing
{app="nginx"} | logfmt
{app="nginx"} | logfmt | level="error"

# Pattern parsing
{app="nginx"} | pattern "<method> <path> <status>"
{app="nginx"} | pattern "<method> <path> <status>" | status="500"

# Regexp parsing
{app="nginx"} | regexp "(?P<ip>\\d+\\.\\d+\\.\\d+\\.\\d+) (?P<method>\\w+) (?P<path>\\S+)"
{app="nginx"} | regexp "(?P<ip>\\d+\\.\\d+\\.\\d+\\.\\d+) (?P<method>\\w+) (?P<path>\\S+)" | method="POST"
```

### Unwrap Operations

```logql
# Unwrap numeric value
{app="nginx"} | unwrap duration

# Rate with unwrap
rate({app="nginx"} | unwrap duration [5m])

# Sum with unwrap
sum(rate({app="nginx"} | unwrap bytes [5m]))

# Quantile with unwrap
quantile_over_time(0.99, {app="nginx"} | unwrap response_time [5m])
```

### Aggregation Operations

```logql
# sum
sum(rate({app="nginx"}[5m]))

# count
count(rate({app="nginx"}[5m]))

# avg
avg(rate({app="nginx"}[5m]))

# min
min(rate({app="nginx"}[5m]))

# max
max(rate({app="nginx"}[5m]))

# topk
topk(10, rate({app="nginx"}[5m]))

# bottomk
bottomk(5, rate({app="nginx"}[5m]))

# stdvar
stdvar(rate({app="nginx"}[5m]))

# stddev
stddev(rate({app="nginx"}[5m]))
```

### Log Pipeline Examples

```logql
# Extract fields from nginx logs
{app="nginx"} 
| pattern "<remote_addr> - <remote_user> [<_>] \"<method> <path> <_>\" <status> <body_bytes_sent>" 
| status >= 500

# Extract JSON fields
{app="nginx"} 
| json 
| line_format "{{.method}} {{.path}} {{.status}} {{.duration}}"

# Filter and transform
{app="nginx"} 
| json 
| line_format "{{.status}} {{.method}} {{.path}}" 
| label_format "status_class", "{{if eq .status \"200\"}}success{{else if eq .status \"404\"}}not_found{{else}}error{{end}}"
```

### Binary Operations

```logql
# Arithmetic
sum(rate({app="nginx"}[5m])) + sum(rate({app="nginx-error"}[5m]))

# Comparison
sum(rate({app="nginx"}[5m])) > 100

# Logical
sum(rate({app="nginx"}[5m])) > 100 and sum(rate({app="nginx"}[5m])) < 1000
```

---

## 8. Promtail

### Promtail Configuration

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog

  # Nginx logs
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<server_protocol>\S+)" (?P<status>\d{3}) (?P<body_bytes_sent>\d+)( "(?P<http_referer>[^"]*)"( "(?P<http_user_agent>[^"]*)")?)?'
      - labels:
          method:
          status:
      - timestamp:
          source: time_local
          format: "02/Jan/2006:15:04:05 -0700"

  # Docker logs
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    pipeline_stages:
      - json:
          expressions:
            log: log
            stream: stream
            time: time
      - labels:
          stream:
      - timestamp:
          source: time
          format: RFC3339Nano

  # Kubernetes logs
  - job_name: kubernetes
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - action: replace
        replacement: $1
        separator: /
        source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
        target_label: __path__
      - replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
        target_label: __path__
```

### Promtail Stages

```yaml
scrape_configs:
  - job_name: app
    static_configs:
      - targets: [localhost]
        labels:
          job: app
          __path__: /var/log/app/*.log
    pipeline_stages:
      # JSON parsing
      - json:
          expressions:
            level: level
            message: message
            user_id: user.id
            timestamp: timestamp

      # Regex parsing
      - regex:
          expression: '^(?P<level>\w+) (?P<timestamp>\S+) (?P<message>.*)'
          source: output

      # Label extraction
      - labels:
          level:
          environment:

      # Timestamp extraction
      - timestamp:
          source: timestamp
          format: RFC3339

      # Line formatting
      - output:
          source: message

      # Template
      - template:
          source: message
          template: '{{ ToLower .Value }}'

      # Label formatting
      - label_format:
          level: '{{ ToLower .level }}'

      # Drop empty lines
      - drop:
          expression: "^$"

      # Drop debug logs
      - drop:
          expression: "level=debug"
```

### Promtail Limits

```yaml
limits_config:
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  max_entries_limit_per_query: 10000
  max_query_series: 5000
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_cache_freshness_per_query: 10m

tracing:
  enabled: true
  exporter: jaeger
  jaeger:
    agent_host: jaeger
    agent_port: 6831
```

---

## 9. Log Labels

### Label Best Practices

```logql
# Good labels (low cardinality, useful for filtering)
app="nginx"
env="production"
level="error"
job="api-server"
instance="web-1"
namespace="production"
container="nginx"

# Bad labels (high cardinality - avoid!)
user_id="12345"
request_id="abc-def-ghi"
session_id="xyz-789"
ip_address="192.168.1.1"
path="/api/v1/users/123"
```

### Label Guidelines

| Cardinality | Example | Impact |
|-------------|---------|--------|
| Low (1-100) | app, env, level | Good, use freely |
| Medium (100-1000) | job, instance | Use carefully |
| High (1000+) | user_id, request_id | Avoid, use filters |

### Label Strategies

```logql
# Strategy 1: Use app label for grouping
{app="nginx"}
{app="auth-service"}
{app="database"}

# Strategy 2: Use level for filtering
{app="nginx", level="error"}
{app="nginx", level="warn"}

# Strategy 3: Use instance for specific targets
{app="nginx", instance="web-1"}
{app="nginx", instance="web-2"}

# Strategy 4: Use job for job-based queries
{job="api-server"}
{job="worker"}
```

### Label Cardinality Management

```yaml
# Promtail: Drop high-cardinality labels
scrape_configs:
  - job_name: app
    pipeline_stages:
      - label_drop:
          - user_id
          - request_id
          - session_id
          - ip_address

# Promtail: Keep only necessary labels
scrape_configs:
  - job_name: app
    pipeline_stages:
      - label_keep:
          - app
          - env
          - level
          - job
```

---

## 10. Retention and Compaction

### Retention Configuration

```yaml
# loki-config.yml
limits_config:
  retention_period: 720h  # 30 days
  reject_old_samples: true
  reject_old_samples_max_age: 168h  # 7 days

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
  delete_request_store: filesystem

# S3 retention
compactor:
  retention_enabled: true
  delete_request_store: s3
  s3:
    bucketnames: my-loki-bucket
```

### Retention Strategies

```yaml
# Strategy 1: Global retention
limits_config:
  retention_period: 720h  # 30 days

# Strategy 2: Per-tenant retention (multi-tenant)
limits_config:
  retention_period:
    tenant1: 720h
    tenant2: 168h

# Strategy 3: Per-stream retention
# Use custom_retention_period in Promtail
scrape_configs:
  - job_name: app
    pipeline_stages:
      - custom_retention_period:
          value: 168h
          action: set
```

### Compaction

```yaml
compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
  delete_request_store: filesystem
  
  # S3 compaction
  compaction_interval: 10m
  retention_enabled: true
  s3:
    bucketnames: my-loki-bucket
```

### Cleanup

```bash
# Check compaction status
curl http://localhost:3100/loki/api/v1/status/config

# Force compaction
curl -X POST http://localhost:3100/loki/api/v1/compactor/flush

# Check retention status
curl http://localhost:3100/loki/api/v1/status/retention

# Delete old logs manually
curl -X POST http://localhost:3100/loki/api/v1/delete \
  -H "Content-Type: application/json" \
  -d '{
    "selector": "{app=\"nginx\"}",
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-01-31T23:59:59Z"
  }'
```

---

## 11. Grafana Integration

### Add Loki Data Source

```
1. Go to Grafana → Configuration → Data Sources
2. Click "Add data source"
3. Search for "Loki"
4. Configure:
   - Name: Loki
   - URL: http://loki:3100
   - Access: Server (Proxy)
5. Click "Save & Test"
```

### Create Dashboards

```
# Dashboard panels
1. Log Panel
   - Data source: Loki
   - Query: {app="nginx"} | json
   - Show: time, level, message

2. Graph Panel
   - Data source: Loki
   - Query: sum(rate({app="nginx"}[5m])) by (status)
   - Show: rate over time

3. Stat Panel
   - Data source: Loki
   - Query: sum(rate({app="nginx", level="error"}[5m]))
   - Show: error rate
```

### Grafana Dashboard Example

```json
{
  "dashboard": {
    "title": "Application Logs",
    "panels": [
      {
        "type": "logs",
        "title": "Recent Logs",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "{app=\"nginx\"} | json",
            "legendFormat": "{{app}}",
            "refId": "A"
          }
        ]
      },
      {
        "type": "timeseries",
        "title": "Log Rate",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "sum(rate({app=\"nginx\"}[5m]))",
            "legendFormat": "Total",
            "refId": "A"
          },
          {
            "expr": "sum(rate({app=\"nginx\", level=\"error\"}[5m]))",
            "legendFormat": "Errors",
            "refId": "B"
          }
        ]
      },
      {
        "type": "stat",
        "title": "Error Rate",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "sum(rate({app=\"nginx\", level=\"error\"}[5m]))",
            "legendFormat": "Errors/s",
            "refId": "A"
          }
        ]
      },
      {
        "type": "piechart",
        "title": "Status Codes",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "sum by (status) (count_over_time({app=\"nginx\"} | json | __error__=\"\" [5m]))",
            "legendFormat": "{{status}}",
            "refId": "A"
          }
        ]
      }
    ]
  }
}
```

---

## 12. Alerting

### Alert Rules

```yaml
# /etc/loki/rules/fake/alerts.yml
groups:
  - name: app-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({app="nginx", level="error"}[5m])) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} per second"

      - alert: HighLatency
        expr: |
          quantile_over_time(0.99, {app="nginx"} | unwrap duration [5m]) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "P99 latency is {{ $value }} seconds"

      - alert: LogVolumeHigh
        expr: |
          sum(rate({app="nginx"}[5m])) > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High log volume"
          description: "Log rate is {{ $value }} per second"
```

### Alert Configuration

```yaml
# loki-config.yml
ruler:
  storage:
    type: local
    local:
      directory: /etc/loki/rules
  rule_path: /loki/rules-temp
  alertmanager_url: http://alertmanager:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true

# Alertmanager configuration
alertmanager:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'password'
  smtp_require_tls: true
```

### Alertmanager Integration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@example.com'
        subject: 'Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

---

## 13. Security

### TLS Configuration

```yaml
# loki-config.yml
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  http_server_read_timeout: 30s
  http_server_write_timeout: 30s

# TLS for distributor
distributor:
  tls:
    cert_path: /etc/loki/certs/server.crt
    key_path: /etc/loki/certs/server.key
    ca_path: /etc/loki/certs/ca.crt

# TLS for querier
querier:
  tls:
    cert_path: /etc/loki/certs/server.crt
    key_path: /etc/loki/certs/server.key
    ca_path: /etc/loki/certs/ca.crt
```

### Authentication

```yaml
# loki-config.yml
auth_enabled: true

# OIDC authentication
auth:
  type: oidc
  oidc:
    issuer_url: https://auth.example.com
    client_id: loki
    client_secret: secret
    redirect_url: http://localhost:3100/oidc/callback

# Basic auth
auth:
  type: basic
  basic:
    username: admin
    password: password
```

### Multi-Tenancy

```yaml
# loki-config.yml
auth_enabled: true

# Per-tenant limits
limits_config:
  ingestion_rate_mb:
    tenant1: 16
    tenant2: 8
  max_query_series:
    tenant1: 10000
    tenant2: 5000
  retention_period:
    tenant1: 720h
    tenant2: 168h
```

### Network Security

```yaml
# Firewall rules
# Allow only specific IPs
iptables -A INPUT -p tcp --dport 3100 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 3100 -j DROP

# Kubernetes NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loki-network-policy
spec:
  podSelector:
    matchLabels:
      app: loki
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: promtail
    ports:
    - protocol: TCP
      port: 3100
```

---

## 14. Performance Tuning

### Query Performance

```yaml
# loki-config.yml
query_range:
  results_cache:
    cache: embeddedLRU
    embedded_cache:
      enabled: true
      max_size_mb: 256

# Query parallelism
limits_config:
  max_query_parallelism: 32
  max_query_series: 5000
  max_entries_limit_per_query: 10000

# Query splitting
query_range:
  split_queries_by_interval: 15m
```

### Ingestion Performance

```yaml
# loki-config.yml
ingester:
  lifecycler:
    ring:
      replication_factor: 3
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 10
  chunk_target_size: 1572864
  chunk_max_age: 1h

limits_config:
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  per_stream_rate_limit: 5MB
  per_stream_rate_limit_burst: 15MB
```

### Storage Performance

```yaml
# loki-config.yml
storage_config:
  filesystem:
    directory: /loki/chunks
    max_parallelism: 2

  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    cache_ttl: 24h
    shared_store: filesystem

  aws:
    s3: https://s3.amazonaws.com
    bucketnames: my-loki-bucket
    region: us-east-1
    s3forcepathstyle: true

# Caching
query_range:
  results_cache:
    cache: embeddedLRU
    embedded_cache:
      enabled: true
      max_size_mb: 256
```

### Resource Limits

```yaml
# Kubernetes resource limits
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2
    memory: 4Gi

# Loki resource management
ingester:
  chunk_target_size: 1572864
  max_chunk_age: 1h
  chunk_idle_period: 5m
  chunk_retain_period: 30s

limits_config:
  max_series_per_query: 10000
  max_entries_limit_per_query: 10000
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
```

---

## 15. Backup and Recovery

### Backup Strategy

```bash
# Backup chunks
tar -czf loki-backup-$(date +%Y%m%d).tar.gz /loki/chunks

# Backup index
tar -czf loki-index-backup-$(date +%Y%m%d).tar.gz /loki/index

# Backup config
tar -czf loki-config-backup-$(date +%Y%m%d).tar.gz /etc/loki/

# Backup rules
tar -czf loki-rules-backup-$(date +%Y%m%d).tar.gz /etc/loki/rules/
```

### S3 Backup

```bash
# Backup to S3
aws s3 sync /loki/ s3://my-loki-backup/$(date +%Y%m%d)/

# Restore from S3
aws s3 sync s3://my-loki-backup/20240115/ /loki/
```

### Recovery

```bash
# Stop Loki
sudo systemctl stop loki

# Restore data
tar -xzf loki-backup-20240115.tar.gz -C /

# Start Loki
sudo systemctl start loki

# Verify
curl http://localhost:3100/ready
```

### Automated Backup Script

```bash
#!/bin/bash
# /usr/local/bin/loki-backup.sh

BACKUP_DIR="/backup/loki"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Backup chunks
tar -czf ${BACKUP_DIR}/chunks-${DATE}.tar.gz /loki/chunks

# Backup index
tar -czf ${BACKUP_DIR}/index-${DATE}.tar.gz /loki/index

# Backup config
tar -czf ${BACKUP_DIR}/config-${DATE}.tar.gz /etc/loki/

# Upload to S3
aws s3 sync ${BACKUP_DIR}/ s3://my-loki-backup/${DATE}/

# Cleanup old backups
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

# Log
echo "$(date): Backup completed: ${DATE}" >> /var/log/loki-backup.log
```

---

## 16. Troubleshooting

### Issue 1: Loki Not Starting

```bash
# Check logs
tail -f /var/log/loki/loki.log

# Check configuration
loki -config.file=/etc/loki/loki-config.yaml --dry-run

# Check port binding
ss -tlnp | grep 3100

# Check disk space
df -h /loki/

# Check permissions
ls -la /loki/
```

### Issue 2: Promtail Not Sending Logs

```bash
# Check Promtail logs
tail -f /var/log/promtail/promtail.log

# Check positions file
cat /tmp/positions.yaml

# Check Loki connectivity
curl http://loki:3100/ready

# Check Promtail targets
curl http://localhost:9080/targets
```

### Issue 3: Queries Timing Out

```bash
# Check query complexity
# Use | label_format to simplify labels
# Use | drop to remove unnecessary fields

# Increase timeout
limits_config:
  max_query_length: 721h
  max_query_parallelism: 32

# Check index health
curl http://localhost:3100/loki/api/v1/status/config
```

### Issue 4: High Memory Usage

```bash
# Check memory usage
ps aux | grep loki

# Reduce chunk size
ingester:
  chunk_target_size: 1048576  # 1MB
  max_chunk_age: 30m

# Check for memory leaks
curl http://localhost:3100/metrics
```

### Issue 5: Disk Space Issues

```bash
# Check disk usage
df -h /loki/

# Check compaction status
curl http://localhost:3100/loki/api/v1/status/config

# Manually compact
curl -X POST http://localhost:3100/loki/api/v1/compactor/flush

# Check retention
limits_config:
  retention_period: 168h  # 7 days
```

### Issue 6: Ingestion Rate Limited

```bash
# Check ingestion rate
curl http://localhost:3100/metrics | grep ingestion

# Increase rate limit
limits_config:
  ingestion_rate_mb: 32
  ingestion_burst_size_mb: 64

# Check for high-cardinality labels
# Drop unnecessary labels in Promtail
```

### Issue 7: Queries Returning No Data

```bash
# Check time range
# Ensure correct time range in Grafana

# Check labels
{app="nginx"}

# Check log content
{app="nginx"} |~ "error"

# Check index
curl http://localhost:3100/loki/api/v1/labels
```

### Issue 8: Slow Queries

```bash
# Use logcli for debugging
logcli query '{app="nginx"}' --start="2024-01-15T00:00:00Z" --end="2024-01-15T01:00:00Z"

# Check query plan
curl -X POST http://localhost:3100/loki/api/v1/query_range \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{app=\"nginx\"}",
    "start": "2024-01-15T00:00:00Z",
    "end": "2024-01-15T01:00:00Z",
    "limit": 1000
  }'

# Optimize query
# Use | line_format to reduce data transfer
# Use | drop to remove unnecessary fields
```

### Issue 9: Promtail Buffer Full

```bash
# Check buffer usage
curl http://localhost:9080/targets

# Increase buffer size
limits_config:
  ingestion_rate_mb: 32
  ingestion_burst_size_mb: 64

# Check for slow Loki
curl http://loki:3100/ready
```

### Issue 10: Multi-Tenancy Issues

```bash
# Check tenant ID
# Ensure X-Scope-OrgID header is set

# Check per-tenant limits
limits_config:
  ingestion_rate_mb:
    tenant1: 16
    tenant2: 8

# Check tenant data
curl http://localhost:3100/loki/api/v1/labels -H "X-Scope-OrgID: tenant1"
```

### Issue 11: Alert Rules Not Firing

```bash
# Check ruler status
curl http://localhost:3100/loki/api/v1/rules

# Check rule syntax
ruler:
  storage:
    type: local
    local:
      directory: /etc/loki/rules

# Test rule expression
curl -X POST http://localhost:3100/loki/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "sum(rate({app=\"nginx\", level=\"error\"}[5m])) > 0.1"
  }'
```

### Issue 12: Chunk Not Flushing

```bash
# Check ingester status
curl http://localhost:3100/metrics | grep ingester

# Check chunk age
ingester:
  chunk_idle_period: 5m
  max_chunk_age: 1h

# Force flush
curl -X POST http://localhost:3100/loki/api/v1/ingester/flush
```

### Issue 13: Index Corruption

```bash
# Check index health
curl http://localhost:3100/loki/api/v1/status/config

# Rebuild index
compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m

# Manual compaction
curl -X POST http://localhost:3100/loki/api/v1/compactor/flush
```

### Issue 14: Network Issues

```bash
# Check connectivity
ping loki
telnet loki 3100

# Check DNS
nslookup loki

# Check firewall
iptables -L -n | grep 3100

# Check Kubernetes services
kubectl get svc -n logging
```

### Issue 15: Version Upgrade Issues

```bash
# Check version
curl http://localhost:3100/ready

# Backup before upgrade
tar -czf loki-pre-upgrade.tar.gz /loki/

# Check changelog
# https://github.com/grafana/loki/releases

# Upgrade process
# 1. Backup
# 2. Stop Loki
# 3. Upgrade binary
# 4. Start Loki
# 5. Verify
```

### Issue 16: High CPU Usage

```bash
# Check CPU usage
top -p $(pgrep loki)

# Check for expensive queries
curl http://localhost:3100/metrics | grep query

# Optimize queries
# Use filters early in pipeline
# Reduce time range
# Use aggregation functions
```

---

## 17. Tips and Best Practices

### Tip 1: Use Low-Cardinality Labels

```logql
# Good
{app="nginx", env="production"}

# Bad
{app="nginx", user_id="12345"}
```

### Tip 2: Use Log Pipeline Efficiently

```logql
# Good: Filter early
{app="nginx"} |= "error" | json | level="error"

# Bad: Parse first, filter later
{app="nginx"} | json | level="error" |= "error"
```

### Tip 3: Use Appropriate Time Ranges

```logql
# Good: Short time range for recent logs
{app="nginx"} [5m]

# Bad: Long time range for recent logs
{app="nginx"} [7d]
```

### Tip 4: Use Label Matchers Wisely

```logql
# Good: Exact match
{app="nginx"}

# Good: Regex for multiple values
{app=~"nginx|apache"}

# Bad: Regex for single value
{app=~"nginx"}
```

### Tip 5: Use LogQL Functions

```logql
# Count logs per second
rate({app="nginx"}[5m])

# Count logs per label
count_over_time({app="nginx"}[5m])

# Quantile
quantile_over_time(0.99, {app="nginx"} | unwrap duration [5m])
```

### Tip 6: Use Line Formatting

```logql
# Reduce data transfer
{app="nginx"} | line_format "{{.level}} {{.message}}"

# Remove unnecessary fields
{app="nginx"} | drop user_id, session_id
```

### Tip 7: Use Promtail Pipeline Stages

```yaml
# Parse early
pipeline_stages:
  - json:
      expressions:
        level: level
        message: message
  - labels:
      level:
```

### Tip 8: Set Appropriate Retention

```yaml
# Keep logs for required time only
limits_config:
  retention_period: 168h  # 7 days
```

### Tip 9: Use Compaction

```yaml
# Enable compaction
compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: true
```

### Tip 10: Monitor Loki

```bash
# Check metrics
curl http://localhost:3100/metrics

# Key metrics
loki_ingester_memory_chunks
loki_ingester_chunk_entries
loki_query_duration_seconds
```

### Tip 11: Use Grafana for Visualization

```json
// Create effective dashboards
{
  "panels": [
    {
      "type": "logs",
      "title": "Recent Logs",
      "datasource": "Loki",
      "targets": [{
        "expr": "{app=\"nginx\"} | json"
      }]
    }
  ]
}
```

### Tip 12: Set Up Alerts

```yaml
# Alert on error rate
groups:
  - name: app-alerts
    rules:
      - alert: HighErrorRate
        expr: sum(rate({app="nginx", level="error"}[5m])) > 0.1
        for: 5m
```

### Tip 13: Use Logcli for Debugging

```bash
# Query logs
logcli query '{app="nginx"}'

# Check labels
logcli labels

# Check label values
logcli labels app
```

### Tip 14: Use Proper Labels

```logql
# Use app for grouping
{app="nginx"}

# Use level for filtering
{app="nginx", level="error"}

# Use env for environment
{app="nginx", env="production"}
```

### Tip 15: Optimize Queries

```logql
# Good: Filter early
{app="nginx"} |= "error" | json

# Bad: Parse first
{app="nginx"} | json |= "error"

# Use line_format to reduce data
{app="nginx"} | line_format "{{.level}} {{.message}}"
```

### Tip 16: Use Chunk Size Appropriately

```yaml
# Default chunk size
ingester:
  chunk_target_size: 1572864  # 1.5MB

# Larger chunks for high volume
ingester:
  chunk_target_size: 3145728  # 3MB
```

### Tip 17: Use Object Storage for Production

```yaml
# S3 for production
storage_config:
  aws:
    s3: https://s3.amazonaws.com
    bucketnames: my-loki-bucket
    region: us-east-1
```

### Tip 18: Use Kubernetes Operator

```bash
# Install Loki Operator
helm install loki grafana/loki-stack

# Use Prometheus-style labels
{app="nginx", namespace="production", pod="nginx-123"}
```

### Tip 19: Use LogQL Consistently

```logql
# Consistent query pattern
{app="nginx"} | json | level="error"

# Reusable queries
{app="nginx", level="error"} | json
{app="nginx", level="warn"} | json
```

### Tip 20: Document Your Queries

```logql
# Add comments to dashboards
# Error rate: Logs with level=error per second
sum(rate({app="nginx", level="error"}[5m]))

# Latency: P99 response time
quantile_over_time(0.99, {app="nginx"} | unwrap duration [5m])
```

---

## 18. Command Reference

### Loki CLI Commands

| Command | Description |
|---------|-------------|
| `loki` | Start Loki |
| `loki -config.file=path` | Start with config file |
| `loki -config.expand-env=true` | Expand env vars in config |
| `loki --help` | Show help |
| `loki --version` | Show version |

### LogCLI Commands

| Command | Description |
|---------|-------------|
| `logcli query` | Query logs |
| `logcli labels` | List labels |
| `logcli label` | Get label values |
| `logcli series` | Query series |
| `logcli stats` | Query statistics |
| `logcli head` | Show head of query |
| `logcli instant` | Instant query |

### LogCLI Usage

```bash
# Query logs
logcli query '{app="nginx"}'

# Query with time range
logcli query '{app="nginx"}' --start="2024-01-15T00:00:00Z" --end="2024-01-15T01:00:00Z"

# Query with limit
logcli query '{app="nginx"}' --limit=100

# Query with statistics
logcli query '{app="nginx"}' --stats

# List labels
logcli labels

# Get label values
logcli labels app

# Get label values with filter
logcli labels app --from="2024-01-15T00:00:00Z" --to="2024-01-15T01:00:00Z"

# Query series
logcli series '{app="nginx"}'

# Query statistics
logcli stats '{app="nginx"}'
```

### Loki API Endpoints

```bash
# Ready
GET /ready

# Health
GET /loki/api/v1/health

# Labels
GET /loki/api/v1/labels
GET /loki/api/v1/label/{name}/values
GET /loki/api/v1/label/{name}/values?start=2024-01-15T00:00:00Z&end=2024-01-15T01:00:00Z

# Query
GET /loki/api/v1/query?query={app="nginx"}
GET /loki/api/v1/query_range?query={app="nginx"}&start=2024-01-15T00:00:00Z&end=2024-01-15T01:00:00Z

# Series
GET /loki/api/v1/series?match[]={app="nginx"}

# Push
POST /loki/api/v1/push

# Delete
POST /loki/api/v1/delete

# Rules
GET /loki/api/v1/rules
GET /loki/api/v1/rules/{namespace}
GET /loki/api/v1/rules/{namespace}/{group}

# Config
GET /loki/api/v1/status/config
GET /loki/api/v1/status/flags
```

### Loki Client Commands

```bash
# Logcli query with output format
logcli query '{app="nginx"}' --output=json
logcli query '{app="nginx"}' --output=raw

# Logcli query with interval
logcli query 'rate({app="nginx"}[5m])' --step=1m

# Logcli query with limit
logcli query '{app="nginx"}' --limit=100 --offset=0

# Logcli query with direction
logcli query '{app="nginx"}' --direction=forward
logcli query '{app="nginx"}' --direction=backward

# Logcli query with quiet
logcli query '{app="nginx"}' --quiet

# Logcli query with no labels
logcli query '{app="nginx"}' --no-labels

# Logcli query with concierge
logcli query '{app="nginx"}' --concurrency=4

# Logcli query with orgid
logcli query '{app="nginx"}' --org-id=tenant1
```

---

## 19. Configuration Reference

### loki-config.yml Complete Reference

```yaml
# ======================== General ========================

# Authentication
auth_enabled: false

# Server
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  http_server_read_timeout: 30s
  http_server_write_timeout: 30s
  http_server_idle_timeout: 120s
  grpc_server_max_recv_msg_size: 4194304
  grpc_server_max_send_msg_size: 4194304

# ======================== Common ========================

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
    heartbeat_timeout: 1m

# ======================== Schema ========================

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

# ======================== Storage ========================

storage_config:
  filesystem:
    directory: /loki/chunks
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache
    cache_ttl: 24h
    shared_store: filesystem

# ======================== Limits ========================

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_query_parallelism: 32
  max_query_series: 5000
  max_entries_limit_per_query: 10000
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  per_stream_rate_limit: 5MB
  per_stream_rate_limit_burst: 15MB
  max_query_length: 721h
  max_query_lookback: 0
  retention_period: 0
  max_cache_freshness_per_query: 10m
  split_queries_by_interval: 15m

# ======================== Ingester ========================

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
      heartbeat_timeout: 1m
    join_after: 0s
    observe_period: 0s
    sync_period: 0s
    min_ready_duration: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  chunk_target_size: 1572864
  chunk_max_age: 1h
  max_transfer_retries: 10

# ======================== Distributor ========================

distributor:
  ring:
    kvstore:
      store: inmemory
    heartbeat_timeout: 1m
  rate_store:
    limits:
      ingestion_rate_mb: 16
      ingestion_burst_size_mb: 32

# ======================== Querier ========================

querier:
  max_concurrent: 10
  query_timeout: 1m
  tail_max_duration: 1h
  extra_query_delay: 0s

# ======================== Query Frontend ========================

query_range:
  results_cache:
    cache: embeddedLRU
    embedded_cache:
      enabled: true
      max_size_mb: 256
  cache_results: true
  max_retries: 5
  split_queries_by_interval: 15m

# ======================== Compactor ========================

compactor:
  working_directory: /loki/compactor
  compaction_interval: 10m
  retention_enabled: false
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
  delete_request_store: filesystem

# ======================== Ruler ========================

ruler:
  storage:
    type: local
    local:
      directory: /etc/loki/rules
  rule_path: /loki/rules-temp
  alertmanager_url: http://alertmanager:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
  enable_alertmanager_v2: true

# ======================== Analytics ========================

analytics:
  reporting_enabled: false
```

### Promtail Configuration Reference

```yaml
# ======================== Server ========================

server:
  http_listen_port: 9080
  grpc_listen_port: 0

# ======================== Positions ========================

positions:
  filename: /tmp/positions.yaml

# ======================== Clients ========================

clients:
  - url: http://loki:3100/loki/api/v1/push
    batchwait: 1s
    batchsize: 1048576
    timeout: 10s
    backoff_config:
      min_period: 500ms
      max_period: 5m
      max_retries: 10
    external_labels:
      labels:
        env: production

# ======================== Scrape Configs ========================

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog

  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<server_protocol>\S+)" (?P<status>\d{3}) (?P<body_bytes_sent>\d+)'
      - labels:
          method:
          status:
      - timestamp:
          source: time_local
          format: "02/Jan/2006:15:04:05 -0700"

# ======================== Limits ========================

limits_config:
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32
  max_entries_limit_per_query: 10000
  max_query_series: 5000
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_cache_freshness_per_query: 10m

# ======================== Tracing ========================

tracing:
  enabled: false
  exporter: jaeger
  jaeger:
    agent_host: jaeger
    agent_port: 6831
```

---

## 20. Real-World Examples

### Example 1: Application Logging

```yaml
# Promtail config for application
scrape_configs:
  - job_name: app
    static_configs:
      - targets:
          - localhost
        labels:
          job: app
          __path__: /var/log/app/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            timestamp: timestamp
            service: service
      - labels:
          level:
          service:
      - timestamp:
          source: timestamp
          format: RFC3339

# Loki query
{job="app"} | json | level="error"

# Grafana dashboard
{
  "panels": [
    {
      "type": "logs",
      "title": "Application Logs",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "{job=\"app\"} | json",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ]
    }
  ]
}
```

### Example 2: Nginx Access Logs

```yaml
# Promtail config for nginx
scrape_configs:
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/access.log
    pipeline_stages:
      - regex:
          expression: '^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<server_protocol>\S+)" (?P<status>\d{3}) (?P<body_bytes_sent>\d+) (?P<request_time>\S+)'
      - labels:
          method:
          status:
      - timestamp:
          source: time_local
          format: "02/Jan/2006:15:04:05 -0700"
      - metrics:
          request_duration_seconds:
            type: Histogram
            description: "Request duration in seconds"
            source: request_time
            config:
              buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5]

# Loki query
{job="nginx"} | json | status="500"

# Rate of 500 errors
sum(rate({job="nginx"} | json | status="500" [5m]))
```

### Example 3: Kubernetes Pod Logs

```yaml
# Promtail config for Kubernetes
scrape_configs:
  - job_name: kubernetes
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - source_labels: [__meta_kubernetes_pod_container_name]
        target_label: container
      - action: replace
        replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
        target_label: __path__
    pipeline_stages:
      - cri: {}
      - json:
          expressions:
            level: level
            message: message
      - labels:
          level:

# Loki query
{namespace="production", app="nginx"} | json | level="error"

# Grafana dashboard
{
  "panels": [
    {
      "type": "logs",
      "title": "Pod Logs",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "{namespace=\"production\"} | json",
          "legendFormat": "{{app}}/{{pod}}",
          "refId": "A"
        }
      ]
    }
  ]
}
```

### Example 4: Error Monitoring

```yaml
# Loki alert rule
groups:
  - name: error-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({job="app"} | json | level="error" [5m])) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} per second"

      - alert: SpikeInErrors
        expr: |
          sum(rate({job="app"} | json | level="error" [5m])) > 10 * sum(rate({job="app"} | json | level="error" [1h] offset 1d)
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Spike in errors detected"
          description: "Error rate is 10x higher than yesterday"

# Grafana dashboard
{
  "panels": [
    {
      "type": "timeseries",
      "title": "Error Rate Over Time",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "sum(rate({job=\"app\"} | json | level=\"error\" [5m]))",
          "legendFormat": "Errors per second",
          "refId": "A"
        }
      ]
    }
  ]
}
```

### Example 5: Microservices Logging

```yaml
# Promtail config for microservices
scrape_configs:
  - job_name: microservices
    static_configs:
      - targets:
          - localhost
        labels:
          __path__: /var/log/services/*/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            service: service
            trace_id: trace_id
      - labels:
          level:
          service:
      - timestamp:
          source: timestamp
          format: RFC3339

# Loki queries
# Service-specific logs
{service="auth-service"} | json | level="error"

# All errors across services
{job="microservices"} | json | level="error"

# Trace-specific logs
{job="microservices"} | json | trace_id="abc-123"

# Grafana dashboard
{
  "panels": [
    {
      "type": "logs",
      "title": "Service Logs",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "{job=\"microservices\"} | json",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ]
    },
    {
      "type": "timeseries",
      "title": "Errors by Service",
      "datasource": "Loki",
      "targets": [
        {
          "expr": "sum by (service) (rate({job=\"microservices\"} | json | level=\"error\" [5m]))",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ]
    }
  ]
}
```

---

## 21. Further Reading

### Official Documentation

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Reference](https://grafana.com/docs/loki/latest/query/)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [Loki API Reference](https://grafana.com/docs/loki/latest/reference/api/)

### Books

- *Observability Engineering* (chapter on logging)
- *Kubernetes in Action* (logging sections)
- *Cloud Native DevOps with Kubernetes* (logging)

### Online Resources

- [Grafana Blog](https://grafana.com/blog/)
- [Loki GitHub](https://github.com/grafana/loki)
- [Grafana Community](https://community.grafana.com/)
- [Grafana Slack](https://slack.grafana.com/)

### Related Tools

- [Grafana](https://grafana.com/) — Visualization and dashboards
- [Prometheus](https://prometheus.io/) — Metrics collection
- [Tempo](https://grafana.com/products/tempo/) — Distributed tracing
- [Mimir](https://grafana.com/products/mimir/) — Long-term storage for Prometheus
- [Alloy](https://grafana.com/products/alloy/) — OpenTelemetry collector

### Community

- [Grafana Community](https://community.grafana.com/)
- [Loki GitHub Discussions](https://github.com/grafana/loki/discussions)
- [Grafana Slack](https://slack.grafana.com/)
- [Grafana Mailing List](https://community.grafana.com/)
