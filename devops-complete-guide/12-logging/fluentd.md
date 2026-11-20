# Fluentd Complete Guide

## Table of Contents

1. [What Is Fluentd](#1-what-is-fluentd)
2. [Why Use Fluentd](#2-why-use-fluentd)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Input Plugins (Sources)](#7-input-plugins-sources)
8. [Filter Plugins](#8-filter-plugins)
9. [Output Plugins (Matches)](#9-output-plugins-matches)
10. [Buffer and Retry](#10-buffer-and-retry)
11. [Routing](#11-routing)
12. [Record Transformation](#12-record-transformation)
13. [Kubernetes Integration](#13-kubernetes-integration)
14. [Docker Integration](#14-docker-integration)
15. [Security](#15-security)
16. [Monitoring and Metrics](#16-monitoring-and-metrics)
17. [Troubleshooting](#17-troubleshooting)
18. [Tips and Best Practices](#18-tips-and-best-practices)
19. [Command Reference](#19-command-reference)
20. [Configuration Reference](#20-configuration-reference)
21. [Real-World Examples](#21-real-world-examples)
22. [Further Reading](#22-further-reading)

---

## 1. What Is Fluentd

Fluentd is an open-source data collector for unified logging, written in Ruby. It allows you to unify data collection and consumption for a better use and understanding of data. Fluentd is a CNCF graduated project, the second CNCF project to graduate after Kubernetes itself.

### Key Characteristics

- **Unified Logging Layer**: Collects, processes, and forwards logs from various sources
- **Plugin-Based Architecture**: Over 500 community-contributed plugins
- **Tag-Based Routing**: Route logs based on tags with sophisticated matching
- **Buffering and Retry**: Built-in buffering with automatic retry and exponential backoff
- **JSON-Centric**: All records in JSON format for easy processing
- **Ruby-Based**: Easy to extend and customize with Ruby plugins
- **Production Ready**: Battle-tested at scale by major companies

### Use Cases

- **Centralized Logging**: Aggregate logs from multiple services and servers
- **Log Processing**: Parse, filter, and transform log data
- **Log Shipping**: Forward logs to various backends (Elasticsearch, S3, Kafka)
- **Kubernetes Logging**: Native Kubernetes support for container log collection
- **IoT Data Collection**: Collect telemetry from IoT devices
- **Security Log Aggregation**: Centralize security logs for analysis
- **Microservices Logging**: Distributed logging across microservices

### Fluentd vs Fluent Bit

| Feature | Fluentd | Fluent Bit |
|---------|---------|------------|
| Language | Ruby + C | C |
| Memory | ~40MB baseline | ~1MB baseline |
| Plugins | 500+ | 50+ |
| Use case | Enterprise, complex processing | Edge, embedded, resource-constrained |
| Processing | Advanced filters, parsers | Lightweight filtering |
| Buffering | File and memory buffers | Memory only |
| Configuration | Complex but powerful | Simple and lightweight |

---

## 2. Why Use Fluentd

### Advantages Over Alternatives

**Compared to Logstash:**
- Lower resource footprint (40MB vs 200MB+)
- Better plugin ecosystem for diverse outputs
- Simpler configuration syntax
- Better Kubernetes integration
- More flexible tag-based routing

**Compared to rsyslog/syslog-ng:**
- Structured JSON logging
- Rich plugin ecosystem
- Better cloud-native integration
- Centralized configuration management

**Compared to Fluent Bit:**
- More plugins for complex processing
- Better buffer management
- More mature enterprise features
- Better for complex routing scenarios

### When Fluentd Excels

- You need to aggregate logs from multiple heterogeneous sources
- You need complex log processing and transformation
- You're running Kubernetes and need a logging solution
- You need to forward logs to multiple destinations
- You need reliable delivery with buffering and retry
- You need enterprise-grade logging features

---

## 3. Architecture Overview

### Fluentd Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                     Fluentd Pipeline                         │
│                                                               │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌──────────┐ │
│  │ SOURCE  │───▶│ FILTER  │───▶│ OUTPUT  │───▶│ DESTINA- │ │
│  │ (Input) │    │         │    │ (Match) │    │ TION     │ │
│  └─────────┘    └─────────┘    └─────────┘    └──────────┘ │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    BUFFER (Memory/File)                  ││
│  └─────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    ROUTER (Tag-based)                    ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. SOURCE: Receives data (files, network, HTTP, etc.)
2. TAG: Assigns a tag to the record
3. FILTER: Transforms, enriches, or drops records
4. ROUTER: Matches tags to output plugins
5. OUTPUT: Sends records to destination (Elasticsearch, S3, etc.)
6. BUFFER: Temporarily stores records for retry
```

### Plugin Types

| Type | Purpose | Examples |
|------|---------|----------|
| Input/Source | Receive data | tail, forward, http, exec |
| Filter | Transform data | grep, record_transformer, parser |
| Output/Match | Send data | elasticsearch, s3, kafka, stdout |
| Buffer | Temporarily store data | file, memory |
| Formatter | Format output | json, text, csv |
| Parser | Parse input | json, csv, regex, multiline |

---

## 4. Installation

### Prerequisites

```bash
# System requirements
- Ruby 2.4+ (for Ruby gems)
- GCC or Clang (for C extensions)
- Memory: 512MB minimum (1GB+ recommended)
- Disk: 1GB for log files and buffers
```

### Install via RubyGems

```bash
# Install Ruby and Bundler
sudo apt-get install ruby ruby-dev build-essential

# Install Fluentd (td-agent)
curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-td-agent4.sh | sh

# Or install Fluentd (OSS version)
gem install fluentd

# Create configuration
fluentd --setup /etc/fluent

# Start Fluentd
sudo systemctl start td-agent
# Or
fluentd -c /etc/fluent/fluent.conf
```

### Install via Package Manager

```bash
# Ubuntu/Debian
curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-td-agent4.sh | sh

# RHEL/CentOS
curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh

# macOS
brew install fluentd
```

### Install with Docker

```bash
# Basic Fluentd
docker run -d \
  --name fluentd \
  -p 24224:24224 \
  -v /var/log:/var/log \
  fluent/fluentd:v1.16

# With custom config
docker run -d \
  --name fluentd \
  -v /etc/fluent:/fluentd/etc \
  -v /var/log:/var/log \
  -p 24224:24224 \
  -p 24224:24224/udp \
  fluent/fluentd:v1.16 -c /fluentd/etc/fluent.conf
```

### Install with Docker Compose

```yaml
version: '3.8'
services:
  fluentd:
    build: ./fluentd
    volumes:
      - ./fluentd/conf:/fluentd/etc
      - /var/log:/var/log
    ports:
      - "24224:24224"
      - "24224:24224/udp"
      - "24223:24223"
    environment:
      - FLUENTD_CONF=fluent.conf
      - FLUENTD_ARGS=--no-supervisor
    depends_on:
      - elasticsearch

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
```

### Install with Kubernetes (DaemonSet)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <source>
      @type forward
      port 24224
      bind 0.0.0.0
    </source>

    <match **>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      index_name fluentd
    </match>
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch8-1
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: config
          mountPath: /fluentd/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
      - name: config
        configMap:
          name: fluentd-config
```

---

## 5. Configuration

### Configuration Structure

```ruby
# fluent.conf

# ======================== Sources ========================

# Forward input
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Tail log file
<source>
  @type tail
  path /var/log/syslog
  pos_file /var/log/td-agent/syslog.pos
  tag system.syslog
  <parse>
    @type syslog
  </parse>
</source>

# ======================== Filters ========================

# Filter by tag
<filter system.**>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
  </record>
</filter>

# ======================== Outputs ========================

# Match all
<match **>
  @type elasticsearch
  host localhost
  port 9200
  index_name logs
  <buffer>
    @type file
    path /var/log/td-agent/buffer
    flush_interval 5s
    retry_type exponential_backoff
    chunk_limit_size 2M
    queue_limit_length 32
  </buffer>
</match>
```

### Configuration Sections

```ruby
# Global settings
<system>
  log_level info
  log /var/log/td-agent.log
  flush_interval 5s
  retry_limit 17
  retry_wait 1s
  max_retry_wait 30s
  immerge_limit 64
  emit_error_log_interval 30s
  reload_workers 2
  reload_restart_workers 1
  suppress_repeated_stacktrace true
  enable_ruby false
</system>

# Source plugins
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Filter plugins
<filter **>
  @type grep
</filter>

# Match plugins
<match **>
  @type stdout
</match>
```

### Include Files

```ruby
# Include other config files
@include /etc/fluent/source.d/*.conf
@include /etc/fluent/filter.d/*.conf
@include /etc/fluent/output.d/*.conf

# Include with wildcard
@include ./conf.d/*.conf
```

### Environment Variables

```ruby
# Use environment variables
<source>
  @type forward
  port ${PORT:-24224}
  bind ${BIND:-0.0.0.0}
</source>

# Reference system environment
<filter **>
  @type record_transformer
  <record>
    env "#{ENV['RAILS_ENV']}"
    hostname "#{Socket.gethostname}"
  </record>
</filter>
```

---

## 6. Core Concepts

### Tags

Tags determine how events are routed through Fluentd.

```ruby
# Tag assigned to events
<source>
  @type tail
  path /var/log/app/*.log
  tag app.access
</source>

# Tag routing
<match app.**>
  @type elasticsearch
</match>

# Tag patterns
<match **>           # Match all
<match app.*>        # Match one level
<match app.**>       # Match multiple levels
<match app.{error,warn}>  # Match specific tags
```

### Records

Events in Fluentd are JSON objects (records).

```ruby
# Input record
{
  "message": "User logged in",
  "user_id": "12345",
  "timestamp": "2024-01-15T10:30:00Z"
}

# After filter transformation
{
  "message": "User logged in",
  "user_id": "12345",
  "timestamp": "2024-01-15T10:30:00Z",
  "hostname": "web-server-01",
  "service": "auth-service"
}
```

### Time

```ruby
# Time is automatically added to each event
# Format: Unix epoch (seconds)

# Add time to record
<filter **>
  @type record_transformer
  <record>
    event_time ${time}
  </record>
</filter>

# Use time in output
<match **>
  @type elasticsearch
  logstash_format true
  logstash_prefix logs
  logstash_dateformat %Y.%m.%d
</match>
```

### Buffers

Buffers handle temporary storage and retry logic.

```ruby
<match **>
  @type elasticsearch
  <buffer>
    @type file
    path /var/log/fluentd/buffer
    flush_mode interval
    flush_interval 5s
    retry_type exponential_backoff
    retry_wait 1s
    retry_max_interval 30s
    retry_timeout 60s
    chunk_limit_size 2M
    total_limit_size 512M
    queue_limit_length 64
    overflow_action block
  </buffer>
</match>
```

### Plugins

Fluentd's plugin system provides extensibility.

```ruby
# Plugin naming convention
# Input plugins: in_forward, in_tail, in_http
# Filter plugins: grep, record_transformer, parser
# Output plugins: out_elasticsearch, out_s3, out_forward
# Buffer plugins: file, memory

# Plugin configuration
<source>
  @type forward
  @id input_forward
</source>

<filter **>
  @type grep
  @id filter_grep
</filter>

<match **>
  @type elasticsearch
  @id output_elasticsearch
</match>
```

---

## 7. Input Plugins (Sources)

### forward (Network Input)

```ruby
<source>
  @type forward
  port 24224
  bind 0.0.0.0
  
  # Authentication
  <security>
    self_hostname web-server-01
    shared_key my_shared_secret
  </security>
  
  # Buffering
  chunk_size_limit 10m
  total_chunk_size_limit 1g
  
  # Protocol
  protocol tcp
  backlog 1024
</source>
```

### tail (Log Files)

```ruby
<source>
  @type tail
  path /var/log/syslog
  path_key tailed_path
  pos_file /var/log/fluentd/syslog.pos
  tag system.syslog
  read_from_head true
  refresh_interval 30s
  rotate_wait 10s
  
  <parse>
    @type syslog
    time_format %b %d %H:%M:%S
  </parse>
</source>

# Multiple files
<source>
  @type tail
  path /var/log/nginx/access.log,/var/log/nginx/error.log
  pos_file /var/log/fluentd/nginx.pos
  tag nginx.*
  <parse>
    @type json
  </parse>
</source>

# Wildcard
<source>
  @type tail
  path /var/log/app/**/*.log
  pos_file /var/log/fluentd/app.pos
  tag app.*
  <parse>
    @type json
  </parse>
</source>
```

### http (HTTP Input)

```ruby
<source>
  @type http
  port 9880
  bind 0.0.0.0
  
  # Authentication
  <security>
    self_hostname web-server-01
    shared_key my_shared_secret
    client_auth true
  </security>
  
  # Parsing
  <parse>
    @type json
  </parse>
  
  # CORS
  cors_allow_origins ["*"]
  cors_allow_methods ["GET","POST","OPTIONS"]
  cors_allow_headers ["Content-Type","Authorization"]
</source>
```

### exec (Command Execution)

```ruby
<source>
  @type exec
  command "df -h | tail -n +2"
  tag system.disk
  run_interval 60s
  <parse>
    @type tsv
    keys host,size,used,avail,pcent,mount
  </parse>
</source>

# Multiple commands
<source>
  @type exec
  command "top -bn1 | head -5"
  tag system.top
  run_interval 30s
  <parse>
    @type multiline
    format /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.*)/
    time_key 1
    time_format %H:%M:%S
  </parse>
</source>
```

### tail with Multiline

```ruby
<source>
  @type tail
  path /var/log/app/exceptions.log
  pos_file /var/log/fluentd/exceptions.pos
  tag app.exceptions
  
  <parse>
    @type multiline
    format /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(\w+)\s+(.*)/
    time_key 1
    time_format %Y-%m-%d %H:%M:%S
    flush_interval 5s
  </parse>
</source>
```

### in_forward with TLS

```ruby
<source>
  @type forward
  port 24224
  
  <transport tcp>
    cert_path /etc/td-agent/certs/server.crt
    private_key_path /etc/td-agent/certs/server.key
    ca_path /etc/td-agent/certs/ca.crt
    client_cert_auth true
  </transport>
  
  <security>
    self_hostname server-01
    shared_key super_secret_key
  </security>
</source>
```

---

## 8. Filter Plugins

### record_transformer

```ruby
# Add fields
<filter app.**>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    service app
    env "${ENV['RAILS_ENV']}"
    env_key RAILS_ENV
  </record>
</filter>

# Remove fields
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    ${record.reject { |k,v| k == "password" || k == "secret" }}
  </record>
</filter>

# Rename fields
<filter app.**>
  @type record_transformer
  <record>
    host ${record["server_name"]}
    log ${record["message"]}
  </record>
</filter>
```

### grep

```ruby
# Include records matching pattern
<filter app.**>
  @type grep
  <regexp>
    key level
    pattern /^ERROR|WARN$/
  </regexp>
  <exclude>
    key message
    pattern /debug/
  </exclude>
</filter>

# Multiple conditions
<filter app.**>
  @type grep
  <and>
    <regexp>
      key level
      pattern /^ERROR$/
    </regexp>
    <regexp>
      key service
      pattern /^auth-service$/
    </regexp>
  </and>
</filter>
```

### parser

```ruby
# Parse JSON
<filter app.**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

# Parse CSV
<filter app.**>
  @type parser
  key_name message
  <parse>
    @type csv
    keys time,level,service,message
    time_key time
  </parse>
</filter>

# Parse multiline
<filter app.**>
  @type parser
  key_name message
  <parse>
    @type multiline
    format1 /^(\d{4}-\d{2}-\d{2})\s+(\w+)\s+(.*)/
    format2 /^\s+(.*)/
    time_key 1
    time_format %Y-%m-%d
  </parse>
</filter>
```

### record_transformer with Ruby

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    # Add computed field
    message_upper ${record["message"].upcase}
    
    # Conditional field
    level ${record["status_code"] >= 400 ? "error" : "info"}
    
    # JSON manipulation
    tags ${record["raw_tags"].split(",")}
    
    # Time manipulation
    hour ${Time.at(record["timestamp"].to_i).hour}
  </record>
</filter>
```

### geoip

```ruby
<filter app.**>
  @type geoip
  geoip_lookup_keys client_ip
  <record>
    country ${client_ip.country.name}
    city ${client_ip.city.name}
    latitude ${client_ip.location.latitude}
    longitude ${client_ip.location.longitude}
  </record>
</filter>
```

### speed_index

```ruby
<filter app.**>
  @type speed_index
  key_name response_time
  <aggregate>
    output_key speed_index
    output_timestamp_key timestamp
  </aggregate>
</filter>
```

---

## 9. Output Plugins (Matches)

### elasticsearch

```ruby
<match app.**>
  @type elasticsearch
  
  host localhost
  port 9200
  scheme http
  
  # Authentication
  user elastic
  password changeme
  
  # Index settings
  index_name logs
  logstash_format true
  logstash_prefix logs
  logstash_dateformat %Y.%m.%d
  
  # Template
  template_name logs
  template_file /etc/fluentd/templates/logs.json
  template_overwrite true
  
  # Buffer
  <buffer>
    @type file
    path /var/log/fluentd/buffer/elasticsearch
    flush_mode interval
    flush_interval 5s
    retry_type exponential_backoff
    retry_wait 1s
    retry_max_interval 30s
    chunk_limit_size 2M
    total_limit_size 512M
    queue_limit_length 64
  </buffer>
</match>
```

### s3

```ruby
<match app.**>
  @type s3
  
  aws_key_id ${ENV['AWS_ACCESS_KEY_ID']}
  aws_sec_key ${ENV['AWS_SECRET_ACCESS_KEY']}
  s3_bucket my-logs-bucket
  s3_region us-east-1
  
  # Path
  path logs/
  buffer_path /var/log/fluentd/buffer/s3
  
  # Format
  format json
  
  # Time
  use_utc true
  <buffer time>
    @type file
    path /var/log/fluentd/buffer/s3
    timekey 3600
    timekey_wait 10m
    timekey_use_utc true
  </buffer>
</match>
```

### forward (Remote Fluentd)

```ruby
<match app.**>
  @type forward
  
  send_timeout 60s
  recover_wait 10s
  heartbeat_type tcp
  heartbeat_interval 15s
  
  <server>
    name server-1
    host 192.168.1.100
    port 24224
    weight 60
    priority 1
  </server>
  
  <server>
    name server-2
    host 192.168.1.101
    port 24224
    weight 60
    priority 1
  </server>
  
  <security>
    self_hostname web-server-01
    shared_key my_shared_secret
  </security>
  
  <buffer>
    @type file
    path /var/log/fluentd/buffer/forward
    flush_mode interval
    flush_interval 5s
  </buffer>
</match>
```

### kafka

```ruby
<match app.**>
  @type kafka
  
  brokers localhost:9092
  topic_name logs
  
  # Message format
  message_key_key message_key
  default_message_key message_key
  
  # Compression
  compression_codec gzip
  
  # Buffer
  <buffer>
    @type file
    path /var/log/fluentd/buffer/kafka
    flush_interval 1s
    chunk_limit_size 1M
  </buffer>
</match>
```

### stdout

```ruby
<match **>
  @type stdout
  
  <format>
    @type json
  </format>
  
  <inject>
    time_key time
    tag_key tag
  </inject>
</match>
```

### file

```ruby
<match app.**>
  @type file
  
  path /var/log/app
  append true
  
  <format>
    @type json
  </format>
  
  <buffer time>
    @type file
    path /var/log/fluentd/buffer/file
    timekey 3600
    timekey_wait 10m
  </buffer>
</match>
```

---

## 10. Buffer and Retry

### Buffer Types

```ruby
# Memory buffer (fast, not persistent)
<buffer>
  @type memory
  chunk_limit_size 2M
  total_limit_size 512M
  queue_limit_length 64
</buffer>

# File buffer (persistent, slower)
<buffer>
  @type file
  path /var/log/fluentd/buffer
  chunk_limit_size 2M
  total_limit_size 1GB
  queue_limit_length 256
  flush_interval 5s
</buffer>
```

### Buffer Configuration

```ruby
<match **>
  @type elasticsearch
  <buffer>
    @type file
    
    # Chunk settings
    path /var/log/fluentd/buffer/elasticsearch
    chunk_limit_size 8M          # Max chunk size
    total_limit_size 2GB         # Max total buffer size
    queue_limit_length 128       # Max queue length
    
    # Flush settings
    flush_mode interval          # interval, immediate, or lazy
    flush_interval 5s            # Flush interval
    flush_thread_count 4         # Number of flush threads
    delayed_commit_timeout 60s   # Delayed commit timeout
    
    # Retry settings
    retry_type exponential_backoff  # exponential_backoff or periodic
    retry_wait 1s                     # Initial retry wait
    retry_max_interval 30s           # Max retry interval
    retry_timeout 60s                # Max retry duration
    retry_forever true               # Retry forever
    
    # Overflow
    overflow_action block            # block, drop_oldest_chunk, or throw_exception
  </buffer>
</match>
```

### Time-Based Chunking

```ruby
<match logs.**>
  @type s3
  <buffer time>
    @type file
    path /var/log/fluentd/buffer/s3
    timekey 3600           # 1 hour chunks
    timekey_wait 10m       # Wait 10 minutes before flushing
    timekey_use_utc true   # Use UTC for time
  </buffer>
</match>
```

### Key-Based Chunking

```ruby
<match logs.**>
  @type elasticsearch
  <buffer>
    @type file
    path /var/log/fluentd/buffer/elasticsearch
    chunk_keys host          # Chunk by host field
    <secondary>
      @type file
      path /var/log/fluentd/buffer/secondary
    </secondary>
  </buffer>
</match>
```

### Overflow Actions

```ruby
<buffer>
  @type file
  overflow_action block           # Block new events
  # overflow_action drop_oldest_chunk  # Drop oldest chunk
  # overflow_action throw_exception     # Throw exception
  
  # Chunk limit actions
  chunk_limit_records 100000     # Max records per chunk
  chunk_limit_size 8M            # Max chunk size in bytes
</buffer>
```

---

## 11. Routing

### Tag-Based Routing

```ruby
# Simple routing
<match app.error>
  @type elasticsearch
  index_name app-errors
</match>

<match app.access>
  @type elasticsearch
  index_name app-access
</match>

<match **>
  @type stdout
</match>
```

### Multiple Outputs

```ruby
# Route to multiple destinations
<match **>
  @type copy
  
  <store>
    @type elasticsearch
    host localhost
    port 9200
    index_name logs
  </store>
  
  <store>
    @type s3
    s3_bucket my-logs-bucket
  </store>
  
  <store>
    @type forward
    <server>
      host 192.168.1.100
      port 24224
    </server>
  </store>
</match>
```

### Conditional Routing

```ruby
# Route based on content
<match **>
  @type rewrite_tag_filter
  
  # Route based on log level
  <rule>
    key level
    pattern /^ERROR$/
    tag error.${tag}
  </rule>
  
  <rule>
    key level
    pattern /^WARN$/
    tag warn.${tag}
  </rule>
  
  <rule>
    key level
    pattern /^INFO$/
    tag info.${tag}
  </rule>
</match>

# Handle different tags
<match error.**>
  @type elasticsearch
  index_name app-errors
</match>

<match warn.**>
  @type elasticsearch
  index_name app-warnings
</match>

<match info.**>
  @type elasticsearch
  index_name app-logs
</match>
```

### Route with Record Transformer

```ruby
# Add routing key
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    routing_key ${record["service"]}.${record["level"]}
  </record>
</filter>

<match **>
  @type record_transformer
  enable_ruby true
  <record>
    tag ${record["routing_key"]}
  </record>
</match>
```

### Failover

```ruby
<match **>
  @type forward
  
  # Primary server
  <server>
    name primary
    host 192.168.1.100
    port 24224
    weight 60
    priority 0
  </server>
  
  # Secondary server (failover)
  <server>
    name secondary
    host 192.168.1.101
    port 24224
    weight 60
    priority 1
  </server>
  
  <buffer>
    @type file
    path /var/log/fluentd/buffer/forward
    flush_interval 5s
    retry_type exponential_backoff
  </buffer>
</match>
```

---

## 12. Record Transformation

### Adding Fields

```ruby
<filter app.**>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    service app
    environment "${ENV['RAILS_ENV']}"
    timestamp_unix ${Time.now.to_i}
  </record>
</filter>
```

### Removing Fields

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    ${record.reject { |k,v| %w[password secret token].include?(k) }}
  </record>
</filter>
```

### Renaming Fields

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    host ${record["server_name"]}
    log ${record["message"]}
    level ${record["severity"]}
  </record>
</filter>
```

### Merging Records

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    ${record.merge({"extra_field" => "value"})}
  </record>
</filter>
```

### Conditionals

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    level ${record["status_code"] >= 500 ? "ERROR" : record["status_code"] >= 400 ? "WARN" : "INFO"}
    is_error ${record["status_code"] >= 500}
  </record>
</filter>
```

### Type Conversion

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    count ${record["count"].to_i}
    price ${record["price"].to_f}
    active ${record["active"] == "true"}
  </record>
</filter>
```

---

## 13. Kubernetes Integration

### DaemonSet Configuration

```yaml
# fluentd-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      - key: node.kubernetes.io/not-ready
        effect: NoExecute
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.16-debian-elasticsearch8-1
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: config
          mountPath: /fluentd/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
      - name: config
        configMap:
          name: fluentd-config
```

### Pod Log Collection

```ruby
# Fluentd config for Kubernetes
<source>
  @type tail
  path /var/log/containers/*.log
  pos_file /var/log/fluentd-containers.log.pos
  tag kubernetes.*
  exclude_path ["/var/log/containers/fluentd*"]
  read_from_head true
  
  <parse>
    @type multiline
    format /^(?<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)\s+(?<stream>stdout|stderr)\s+F\s+(?<log>.*)/
    time_key time
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

# Add Kubernetes metadata
<filter kubernetes.**>
  @type kubernetes_metadata
  merge_json_log true
  preserve_json_log true
  kubernetes_url "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}"
  verify_ssl false
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
</filter>
```

### Namespace Filtering

```ruby
# Only collect logs from specific namespaces
<filter kubernetes.**>
  @type kubernetes_metadata
  skip_labels true
  skip_container_metadata true
  skip_master_url true
  skip_namespace_metadata false
</filter>

<filter kubernetes.**>
  @type record_transformer
  enable_ruby true
  <record>
    namespace ${record["kubernetes"]["namespace_name"]}
  </record>
</filter>

<match kubernetes.**>
  @type rewrite_tag_filter
  <rule>
    key namespace
    pattern /^production$/
    tag k8s.production.**
  </rule>
  <rule>
    key namespace
    pattern /^staging$/
    tag k8s.staging.**
  </rule>
</match>
```

---

## 14. Docker Integration

### Docker Logging Driver

```bash
# Run container with Fluentd logging driver
docker run \
  --log-driver=fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag="docker.{{.Name}}" \
  nginx

# With buffer
docker run \
  --log-driver=fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag="docker.{{.Name}}" \
  --log-opt fluentd-async=true \
  --log-opt fluentd-buffer-limit=64 \
  nginx
```

### Docker Compose

```yaml
version: '3.8'
services:
  nginx:
    image: nginx
    logging:
      driver: fluentd
      options:
        fluentd-address: "localhost:24224"
        tag: "docker.nginx.{{.Name}}"
        fluentd-async: "true"
        fluentd-buffer-limit: "64"

  fluentd:
    build: ./fluentd
    ports:
      - "24224:24224"
    volumes:
      - ./fluentd/conf:/fluentd/etc
```

### Docker Container Logs

```ruby
# Collect Docker container logs
<source>
  @type tail
  path /var/lib/docker/containers/**/*-json.log
  pos_file /var/log/fluentd/docker-containers.pos
  tag docker.*
  <parse>
    @type json
    time_key time
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

# Add container metadata
<filter docker.**>
  @type record_transformer
  enable_ruby true
  <record>
    container_id ${record["container_id"]}
    container_name ${record["container_name"]}
    image ${record["image"]}
  </record>
</filter>
```

---

## 15. Security

### TLS Encryption

```ruby
# Server with TLS
<source>
  @type forward
  port 24224
  
  <transport tcp>
    cert_path /etc/fluentd/certs/server.crt
    private_key_path /etc/fluentd/certs/server.key
    ca_path /etc/fluentd/certs/ca.crt
  </transport>
</source>

# Client with TLS
<match **>
  @type forward
  
  <transport tcp>
    cert_path /etc/fluentd/certs/client.crt
    private_key_path /etc/fluentd/certs/client.key
    ca_path /etc/fluentd/certs/ca.crt
  </transport>
  
  <server>
    host 192.168.1.100
    port 24224
  </server>
</match>
```

### Shared Key Authentication

```ruby
# Server
<source>
  @type forward
  port 24224
  
  <security>
    self_hostname server-01
    shared_key my_super_secret_key
  </security>
</source>

# Client
<match **>
  @type forward
  
  <security>
    self_hostname client-01
    shared_key my_super_secret_key
  </security>
  
  <server>
    host 192.168.1.100
    port 24224
  </server>
</match>
```

### Forward with Mutual TLS

```ruby
<source>
  @type forward
  port 24224
  
  <transport tcp>
    cert_path /etc/fluentd/certs/server.crt
    private_key_path /etc/fluentd/certs/server.key
    ca_path /etc/fluentd/certs/ca.crt
    client_cert_auth true
  </transport>
  
  <security>
    self_hostname server-01
    shared_key my_secret_key
  </security>
</source>
```

### Masking Sensitive Data

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  <record>
    # Mask email
    email ${record["email"].gsub(/(.{2})(.*)(@.*)/, '\1***\3')}
    
    # Mask credit card
    card ${record["card"].gsub(/(\d{4})(\d+)(\d{4})/, '****-\2-****')}
    
    # Remove sensitive fields
    ${record.reject { |k,v| %w[password token secret].include?(k) }}
  </record>
</filter>
```

### Access Control

```ruby
# Restrict source IPs
<source>
  @type forward
  port 24224
  bind 0.0.0.0
  
  # Allow specific IPs only
  <security>
    self_hostname server-01
    shared_key my_secret_key
  </security>
</source>
```

---

## 16. Monitoring and Metrics

### Built-in Monitoring

```ruby
# Enable monitoring endpoint
<system>
  log_level info
  log /var/log/td-agent.log
  
  # Prometheus metrics
  metrics_port 24220
  
  # Health check
  health_check_port 24221
</system>

# Prometheus output
<match fluentd.**>
  @type prometheus
  <labels>
    host "#{Socket.gethostname}"
    tag ${tag}
  </labels>
</match>
```

### Monitor Buffer Health

```ruby
# Check buffer status
curl http://localhost:24220/api/plugins.json

# Check buffer metrics
curl http://localhost:24220/api/config.json
```

### Logging Configuration

```ruby
<system>
  log_level info          # debug, info, warn, error, fatal
  log /var/log/td-agent.log
  log_rotate_age 10      # Rotate after 10 days
  log_rotate_size 104857600  # Rotate at 100MB
</system>
```

### Error Handling

```ruby
<match **>
  @type elasticsearch
  
  # Handle errors
  <buffer>
    @type file
    path /var/log/fluentd/buffer
    retry_type exponential_backoff
    retry_wait 1s
    retry_max_interval 30s
    retry_timeout 60s
    
    # Secondary output on failure
    <secondary>
      @type file
      path /var/log/fluentd/failed
      append true
      <format>
        @type json
      </format>
    </secondary>
  </buffer>
</match>
```

---

## 17. Troubleshooting

### Issue 1: Fluentd Not Starting

```bash
# Check configuration
fluentd -c /etc/fluent/fluent.conf --dry-run

# Check logs
tail -f /var/log/td-agent.log

# Check permissions
ls -la /var/log/td-agent/
ls -la /var/run/td-agent/

# Check Ruby version
ruby --version

# Restart service
sudo systemctl restart td-agent
```

### Issue 2: No Output to Elasticsearch

```bash
# Check buffer status
curl http://localhost:24220/api/plugins.json | jq .

# Check Elasticsearch connectivity
curl -u elastic:changeme http://localhost:9200/_cat/health

# Check Fluentd logs for errors
grep -i error /var/log/td-agent.log

# Check buffer files
ls -la /var/log/td-agent/buffer/

# Flush buffer manually
curl -X POST http://localhost:24220/api/fluentd/config Reload
```

### Issue 3: High Memory Usage

```bash
# Check buffer size
curl http://localhost:24220/api/plugins.json | jq '.buffers[] | .buffer_length, .buffer_total_limit_size'

# Reduce buffer size
<buffer>
  @type memory
  chunk_limit_size 1M
  total_limit_size 256M
  queue_limit_length 32
</buffer>

# Use file buffer instead
<buffer>
  @type file
  path /var/log/td-agent/buffer
  chunk_limit_size 8M
  total_limit_size 1GB
</buffer>
```

### Issue 4: Fluentd Dropping Events

```bash
# Check overflow action
<buffer>
  @type file
  overflow_action block  # or drop_oldest_chunk
</buffer>

# Increase buffer size
<buffer>
  chunk_limit_size 16M
  total_limit_size 4GB
  queue_limit_length 256
</buffer>

# Check disk space
df -h /var/log/td-agent/buffer/

# Monitor events
curl http://localhost:24220/api/plugins.json | jq '.plugins[] | .output_plugin, .buffer_queue_length, .buffer_total_limit_size'
```

### Issue 5: Slow Processing

```bash
# Check flush interval
<buffer>
  flush_interval 1s  # Reduce from 5s
</buffer>

# Increase flush threads
<buffer>
  flush_thread_count 8  # Increase from 4
</buffer>

# Check for slow plugins
grep "slow event" /var/log/td-agent.log

# Profile Fluentd
fluentd -c /etc/fluent/fluent.conf --under-plugin-development
```

### Issue 6: Connection Refused

```bash
# Check if Fluentd is running
sudo systemctl status td-agent

# Check port binding
ss -tlnp | grep 24224

# Check firewall
sudo ufw status
sudo iptables -L

# Check network connectivity
telnet localhost 24224
nc -zv localhost 24224
```

### Issue 7: Authentication Failed

```bash
# Check shared key
# Verify shared_key matches between client and server

# Check SSL certificates
openssl s_client -connect localhost:24224 -CAfile ca.crt

# Check certificate expiration
openssl x509 -in server.crt -noout -dates
```

### Issue 8: Plugin Not Found

```bash
# List installed plugins
fluent-gem list | grep fluent-plugin

# Install missing plugin
fluent-gem install fluent-plugin-elasticsearch

# Check plugin path
fluentd --show-plugin-config

# Check Ruby path
which ruby
ruby -e "puts \$LOAD_PATH"
```

### Issue 9: Config Parse Error

```bash
# Validate config
fluentd -c /etc/fluent/fluent.conf --dry-run

# Check syntax
ruby -c /etc/fluent/fluent.conf

# Check for common errors
grep -n "<" /etc/fluent/fluent.conf | head -20
```

### Issue 10: Fluentd Crashes

```bash
# Check for OOM
dmesg | grep -i oom

# Check Ruby segmentation fault
grep "Segmentation fault" /var/log/td-agent.log

# Check core dumps
ls -la /var/crash/
ls -la /tmp/

# Run in foreground for debugging
fluentd -c /etc/fluent/fluent.conf -vv --no-supervisor
```

### Issue 11: Tag Not Matching

```bash
# Debug tag matching
<match **>
  @type stdout
</match>

# Check tag in record
<filter **>
  @type record_transformer
  <record>
    tag ${tag}
  </record>
</filter>

# Verify tag patterns
# Use ** for multi-level, * for single level
```

### Issue 12: Buffer Full

```bash
# Check buffer usage
curl http://localhost:24220/api/plugins.json | jq '.plugins[] | select(.output_plugin) | .buffer_queue_length, .buffer_total_limit_size'

# Clear buffer (causes data loss)
rm -rf /var/log/td-agent/buffer/*
sudo systemctl restart td-agent

# Increase buffer size
<buffer>
  total_limit_size 2GB
</buffer>
```

### Issue 13: Time Not Parsing

```bash
# Check time format
<parse>
  @type json
  time_key timestamp
  time_format %Y-%m-%dT%H:%M:%S.%NZ
</parse>

# Use local time
<parse>
  @type json
  time_key timestamp
  keep_time_key true
</parse>
```

### Issue 14: Forward Authentication Failed

```bash
# Check shared key matches
# Server
<source>
  <security>
    shared_key server_key
  </security>
</source>

# Client
<match **>
  <security>
    shared_key server_key  # Must match server
  </security>
</match>

# Check hostname
# self_hostname must match the hostname used by the other end
```

### Issue 15: Buffer File Corruption

```bash
# Check buffer files
ls -la /var/log/td-agent/buffer/

# Remove corrupted buffer
rm -rf /var/log/td-agent/buffer/buffer*
sudo systemctl restart td-agent

# Check disk space
df -h
```

### Issue 16: Memory Leak

```bash
# Monitor memory usage over time
watch -n 10 'ps aux | grep fluentd'

# Check for buffer accumulation
curl http://localhost:24220/api/plugins.json | jq '.plugins[] | select(.output_plugin) | .buffer_queue_length'

# Restart periodically
# Add cron job:
0 0 * * * sudo systemctl restart td-agent
```

### Issue 17: Slow Network

```bash
# Increase timeout
<match **>
  @type forward
  send_timeout 120s
  recover_wait 30s
  
  <server>
    host 192.168.1.100
    port 24224
    connect_timeout 30s
  </server>
</match>

# Use compression
<match **>
  @type forward
  compress gzip
</match>
```

---

## 18. Tips and Best Practices

### Tip 1: Use File Buffers for Production

File buffers survive restarts. Memory buffers are faster but lose data on crash.

```ruby
<buffer>
  @type file
  path /var/log/fluentd/buffer
</buffer>
```

### Tip 2: Set Appropriate Chunk Limits

Balance memory usage and I/O efficiency:

```ruby
<buffer>
  chunk_limit_size 8M       # Good default for most use cases
  total_limit_size 2GB      # Prevent memory exhaustion
  queue_limit_length 128    # Limit queued chunks
</buffer>
```

### Tip 3: Use Tag-Based Routing

Organize logs by source, service, or environment:

```ruby
# Good: Use structured tags
tag app.web.access
tag app.auth.error
tag system.syslog

# Bad: Use generic tags
tag logs
```

### Tip 4: Enable Retry with Exponential Backoff

Always configure retry to handle temporary failures:

```ruby
<buffer>
  retry_type exponential_backoff
  retry_wait 1s
  retry_max_interval 30s
  retry_timeout 60s
</buffer>
```

### Tip 5: Use Secondary Outputs

Have a fallback output for when the primary fails:

```ruby
<match **>
  @type elasticsearch
  <buffer>
    <secondary>
      @type file
      path /var/log/fluentd/secondary
    </secondary>
  </buffer>
</match>
```

### Tip 6: Validate Configuration Before Deployment

Always test config changes:

```bash
fluentd -c /etc/fluent/fluent.conf --dry-run
fluentd -c /etc/fluent/fluent.conf -vv --no-supervisor
```

### Tip 7: Use Include Files for Organization

Split complex configs into manageable files:

```ruby
@include /etc/fluent/source.d/*.conf
@include /etc/fluent/filter.d/*.conf
@include /etc/fluent/output.d/*.conf
```

### Tip 8: Monitor Buffer Health

Set up alerts for buffer queue length:

```ruby
# Check buffer status
curl http://localhost:24220/api/plugins.json | jq '.plugins[] | select(.output_plugin) | .buffer_queue_length'
```

### Tip 9: Use Ruby Expressions Sparingly

Ruby expressions add overhead. Use record_transformer only when necessary:

```ruby
# Good: Use built-in plugins
<filter **>
  @type grep
  <regexp>
    key level
    pattern /^ERROR$/
  </regexp>
</filter>

# Avoid: Ruby for simple operations
<filter **>
  @type record_transformer
  enable_ruby true
  <record>
    level ${record["level"]}
  </record>
</filter>
```

### Tip 10: Set Up Log Rotation

Prevent disk space issues:

```ruby
<system>
  log /var/log/td-agent.log
  log_rotate_age 10
  log_rotate_size 104857600
</system>
```

### Tip 11: Use Environment Variables for Secrets

Never hardcode credentials:

```ruby
<match **>
  @type elasticsearch
  user ${ENV['ELASTIC_USER']}
  password ${ENV['ELASTIC_PASSWORD']}
</match>
```

### Tip 12: Chunk by Time for S3

Use time-based chunking for S3 output:

```ruby
<match **>
  @type s3
  <buffer time>
    timekey 3600
    timekey_wait 10m
  </buffer>
</match>
```

### Tip 13: Use Rewrite Tag Filter

Route logs based on content:

```ruby
<match **>
  @type rewrite_tag_filter
  <rule>
    key level
    pattern /^ERROR$/
    tag error.${tag}
  </rule>
</match>
```

### Tip 14: Enable Graceful Shutdown

Handle signals properly:

```bash
# Send SIGTERM for graceful shutdown
kill -TERM $(pidof fluentd)

# Wait for buffer to flush
# Default timeout: 30s
```

### Tip 15: Use Buffered Output for Performance

Buffered outputs are faster than non-buffered:

```ruby
# Good: Buffered
<match **>
  @type elasticsearch
  <buffer>
    @type file
    flush_interval 5s
  </buffer>
</match>

# Avoid: Non-buffered
<match **>
  @type elasticsearch
  flush_interval 0  # Flush every event
</match>
```

### Tip 16: Test with Sample Data

```bash
# Send test event
echo '{"message":"test","level":"info"}' | fluent-cat test.tag

# Or via HTTP
curl -X POST -d '{"message":"test"}' http://localhost:9880/test.tag
```

### Tip 17: Use Fluentd as a DaemonSet in Kubernetes

Collect logs from all nodes efficiently:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    spec:
      containers:
      - name: fluentd
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: containers
        hostPath:
          path: /var/lib/docker/containers
```

### Tip 18: Use Multiple Flush Threads

Increase throughput with parallel flushing:

```ruby
<buffer>
  flush_thread_count 4
</buffer>
```

### Tip 19: Monitor Fluentd Metrics

```ruby
# Enable Prometheus metrics
<system>
  metrics_port 24220
</system>

# Export metrics
<match fluentd.**>
  @type prometheus
</match>
```

### Tip 20: Use Graceful Shutdown

```bash
# Graceful shutdown
kill -TERM $(pidof fluentd)

# Wait for buffer to flush
# Default timeout: 30s
```

---

## 19. Command Reference

### Fluentd Commands

| Command | Description |
|---------|-------------|
| `fluentd -c config` | Start Fluentd with config file |
| `fluentd --dry-run` | Validate config without starting |
| `fluentd --show-plugin-config` | Show plugin configuration |
| `fluentd --setup directory` | Setup default config directory |
| `fluentd -vv` | Verbose logging |
| `fluentd --no-supervisor` | Run without supervisor |
| `fluentd --background` | Run in background |

### td-agent Commands

| Command | Description |
|---------|-------------|
| `sudo systemctl start td-agent` | Start td-agent |
| `sudo systemctl stop td-agent` | Stop td-agent |
| `sudo systemctl restart td-agent` | Restart td-agent |
| `sudo systemctl status td-agent` | Check status |
| `sudo td-agent-gem install plugin` | Install plugin |
| `sudo td-agent-gem list` | List plugins |

### Fluentd CLI Options

```bash
# Basic options
fluentd -c /etc/fluent/fluent.conf    # Config file
fluentd -p /etc/fluent/plugin          # Plugin directory
fluentd -o /var/log/fluent.log          # Log file
fluentd -vv                             # Verbose mode
fluentd --dry-run                       # Validate config
fluentd --no-supervisor                 # Run without supervisor
fluentd --background                    # Run in background
fluentd --chunk-limit-size 8M           # Chunk limit
fluentd --queue-limit-length 64         # Queue limit
fluentd --flush-interval 5s             # Flush interval
fluentd --flush-thread-count 4          # Flush threads
fluentd --retry-limit 17                # Retry limit
fluentd --retry-wait 1s                 # Retry wait
fluentd --max-retry-wait 30s            # Max retry wait
fluentd --immerge-limit 64              # Immerge limit
fluentd --emit-error-log-interval 30s   # Error log interval
fluentd --suppress-repeated-stacktrace  # Suppress repeated stacktrace
fluentd --enable-ruby                   # Enable Ruby expressions
fluentd --log-level info                # Log level
fluentd --log-auto-refresh              # Auto refresh log
fluentd --log-rotate-age 10             # Log rotate age
fluentd --log-rotate-size 104857600     # Log rotate size
fluentd --suppress-config-dump          # Suppress config dump
fluentd --disable-sigdump               # Disable sigdump
fluentd --use-v1-config                 # Use v1 config format
fluentd --use-v0-config                 # Use v0 config format
```

### Fluentd Client (fluent-cat)

```bash
# Send event via fluent-cat
echo '{"message":"hello"}' | fluent-cat test.tag

# Send via HTTP
curl -X POST -d '{"message":"hello"}' http://localhost:9880/test.tag

# Send with timestamp
echo '{"message":"hello"}' | fluent-cat -t test.tag
```

### Fluentd API Endpoints

```bash
# Get plugin info
curl http://localhost:24220/api/plugins.json

# Get config
curl http://localhost:24220/api/config.json

# Reload config
curl -X POST http://localhost:24220/api/config Reload

# Get metrics
curl http://localhost:24220/api/metrics.json

# Health check
curl http://localhost:24220/api/health
```

---

## 20. Configuration Reference

### System Configuration

```ruby
<system>
  log_level info
  log /var/log/td-agent.log
  log_auto_refresh true
  log_rotate_age 10
  log_rotate_size 104857600
  suppress_repeated_stacktrace true
  enable_ruby false
  
  # Buffer defaults
  flush_interval 5s
  flush_thread_count 4
  chunk_limit_size 8M
  total_limit_size 512M
  queue_limit_length 64
  
  # Retry defaults
  retry_type exponential_backoff
  retry_wait 1s
  retry_max_interval 30s
  retry_timeout 60s
  retry_limit 17
  
  # Other
  emit_error_log_interval 30s
  immerge_limit 64
  reload_workers 2
  reload_restart_workers 1
  
  # Prometheus
  metrics_port 24220
  
  # HTTP server
  http_server true
  http_server_port 24221
</system>
```

### Source Plugin: forward

```ruby
<source>
  @type forward
  port 24224
  bind 0.0.0.0
  
  # Protocol
  protocol tcp
  backlog 1024
  
  # Authentication
  <security>
    self_hostname server-01
    shared_key my_shared_secret
  </security>
  
  # TLS
  <transport tcp>
    cert_path /etc/fluentd/certs/server.crt
    private_key_path /etc/fluentd/certs/server.key
    ca_path /etc/fluentd/certs/ca.crt
    client_cert_auth true
  </transport>
  
  # Limits
  chunk_size_limit 10m
  total_chunk_size_limit 1g
  
  # Read timeout
  read_timeout 60s
  read_size_limit 1048576
</source>
```

### Source Plugin: tail

```ruby
<source>
  @type tail
  path /var/log/syslog,/var/log/messages
  pos_file /var/log/fluentd/syslog.pos
  tag system.*
  read_from_head true
  refresh_interval 30s
  rotate_wait 10s
  skip_refresh_on_restart true
  
  <parse>
    @type syslog
    time_format %b %d %H:%M:%S
  </parse>
</source>
```

### Source Plugin: http

```ruby
<source>
  @type http
  port 9880
  bind 0.0.0.0
  
  <parse>
    @type json
  </parse>
  
  # CORS
  cors_allow_origins ["*"]
  cors_allow_methods ["GET","POST","OPTIONS"]
  cors_allow_headers ["Content-Type","Authorization"]
  
  # Auth
  <security>
    self_hostname web-server-01
    shared_key my_shared_secret
    client_auth true
  </security>
</source>
```

### Filter Plugin: grep

```ruby
<filter app.**>
  @type grep
  
  # Include
  <regexp>
    key level
    pattern /^ERROR|WARN$/
  </regexp>
  
  # Exclude
  <exclude>
    key message
    pattern /debug/
  </exclude>
  
  # AND conditions
  <and>
    <regexp>
      key level
      pattern /^ERROR$/
    </regexp>
    <regexp>
      key service
      pattern /^auth-service$/
    </regexp>
  </and>
  
  # OR conditions
  <or>
    <regexp>
      key level
      pattern /^ERROR$/
    </regexp>
    <regexp>
      key level
      pattern /^WARN$/
    </regexp>
  </or>
</filter>
```

### Filter Plugin: record_transformer

```ruby
<filter app.**>
  @type record_transformer
  enable_ruby true
  auto_typecast true
  
  <record>
    hostname "#{Socket.gethostname}"
    service app
    env "${ENV['RAILS_ENV']}"
    timestamp ${Time.now.to_i}
    level ${record["status_code"] >= 500 ? "ERROR" : "INFO"}
    ${record.reject { |k,v| %w[password secret].include?(k) }}
  </record>
  
  # Remove keys
  remove_keys hostname
</filter>
```

### Output Plugin: elasticsearch

```ruby
<match app.**>
  @type elasticsearch
  
  # Connection
  host localhost
  port 9200
  scheme http
  user elastic
  password changeme
  
  # Index
  index_name logs
  logstash_format true
  logstash_prefix logs
  logstash_dateformat %Y.%m.%d
  
  # Template
  template_name logs
  template_file /etc/fluentd/templates/logs.json
  template_overwrite true
  
  # Type
  type_name _doc
  
  # ID
  id_key _id
  
  # Include tag
  include_tag_key true
  tag_key @log_name
  
  # Request timeout
  request_timeout 15s
  
  # Reload connections
  reload_connections true
  reload_on_failure true
  
  # Buffer
  <buffer>
    @type file
    path /var/log/fluentd/buffer/elasticsearch
    flush_mode interval
    flush_interval 5s
    retry_type exponential_backoff
    retry_wait 1s
    retry_max_interval 30s
    chunk_limit_size 2M
    total_limit_size 512M
    queue_limit_length 64
  </buffer>
</match>
```

### Output Plugin: s3

```ruby
<match app.**>
  @type s3
  
  # AWS credentials
  aws_key_id ${ENV['AWS_ACCESS_KEY_ID']}
  aws_sec_key ${ENV['AWS_SECRET_ACCESS_KEY']}
  s3_bucket my-logs-bucket
  s3_region us-east-1
  s3_endpoint https://s3.us-east-1.amazonaws.com
  
  # Path
  path logs/
  buffer_path /var/log/fluentd/buffer/s3
  
  # Format
  format json
  
  # Time
  use_utc true
  <buffer time>
    @type file
    path /var/log/fluentd/buffer/s3
    timekey 3600
    timekey_wait 10m
    timekey_use_utc true
  </buffer>
</match>
```

---

## 21. Real-World Examples

### Example 1: Centralized Logging with Elasticsearch

```ruby
# fluent.conf

# System logs
<source>
  @type tail
  path /var/log/syslog
  pos_file /var/log/fluentd/syslog.pos
  tag system.syslog
  <parse>
    @type syslog
  </parse>
</source>

# Application logs
<source>
  @type tail
  path /var/log/app/*.log
  pos_file /var/log/fluentd/app.pos
  tag app.*
  <parse>
    @type json
  </parse>
</source>

# Nginx access logs
<source>
  @type tail
  path /var/log/nginx/access.log
  pos_file /var/log/fluentd/nginx.pos
  tag nginx.access
  <parse>
    @type combined
  </parse>
</source>

# Add hostname to all logs
<filter **>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    env "${ENV['RAILS_ENV']}"
  </record>
</filter>

# Route by type
<match system.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name system-logs
  logstash_format true
  <buffer>
    @type file
    path /var/log/fluentd/buffer/system
    flush_interval 5s
  </buffer>
</match>

<match app.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name app-logs
  logstash_format true
  <buffer>
    @type file
    path /var/log/fluentd/buffer/app
    flush_interval 5s
  </buffer>
</match>

<match nginx.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name nginx-logs
  logstash_format true
  <buffer>
    @type file
    path /var/log/fluentd/buffer/nginx
    flush_interval 5s
  </buffer>
</match>
```

### Example 2: Kubernetes Logging

```ruby
# Kubernetes Fluentd config

# Collect container logs
<source>
  @type tail
  path /var/log/containers/*.log
  pos_file /var/log/fluentd-containers.log.pos
  tag kubernetes.*
  exclude_path ["/var/log/containers/fluentd*"]
  <parse>
    @type multiline
    format /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)\s+(stdout|stderr)\s+F\s+(.*)/
    time_key 1
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

# Add Kubernetes metadata
<filter kubernetes.**>
  @type kubernetes_metadata
  merge_json_log true
  preserve_json_log true
</filter>

# Route by namespace
<match kubernetes.**>
  @type rewrite_tag_filter
  <rule>
    key kubernetes.namespace_name
    pattern /^production$/
    tag k8s.production.**
  </rule>
  <rule>
    key kubernetes.namespace_name
    pattern /^staging$/
    tag k8s.staging.**
  </rule>
  <rule>
    key kubernetes.namespace_name
    pattern /^kube-system$/
    tag k8s.system.**
  </rule>
</match>

# Production logs to Elasticsearch
<match k8s.production.**>
  @type elasticsearch
  host elasticsearch.logging.svc.cluster.local
  port 9200
  index_name k8s-production
  logstash_format true
  <buffer>
    @type file
    path /var/log/fluentd/buffer/k8s-production
    flush_interval 5s
  </buffer>
</match>

# All logs to S3 for archival
<match k8s.**>
  @type s3
  aws_key_id ${ENV['AWS_ACCESS_KEY_ID']}
  aws_sec_key ${ENV['AWS_SECRET_ACCESS_KEY']}
  s3_bucket my-k8s-logs
  s3_region us-east-1
  path logs/
  <buffer time>
    @type file
    timekey 3600
    timekey_wait 10m
  </buffer>
</match>
```

### Example 3: Multi-Output with Failover

```ruby
# Primary Elasticsearch with Kafka backup
<match app.**>
  @type copy
  
  # Primary: Elasticsearch
  <store>
    @type elasticsearch
    host elasticsearch-1:9200
    host elasticsearch-2:9200
    host elasticsearch-3:9200
    index_name logs
    logstash_format true
    
    <buffer>
      @type file
      path /var/log/fluentd/buffer/elasticsearch
      flush_interval 5s
      retry_type exponential_backoff
      
      <secondary>
        @type file
        path /var/log/fluentd/buffer/elasticsearch-fallback
      </secondary>
    </buffer>
  </store>
  
  # Backup: Kafka
  <store>
    @type kafka
    brokers kafka-1:9092,kafka-2:9092,kafka-3:9092
    topic_name logs-backup
    compression_codec gzip
    
    <buffer>
      @type file
      path /var/log/fluentd/buffer/kafka
      flush_interval 5s
    </buffer>
  </store>
  
  # Archive: S3
  <store>
    @type s3
    aws_key_id ${ENV['AWS_ACCESS_KEY_ID']}
    aws_sec_key ${ENV['AWS_SECRET_ACCESS_KEY']}
    s3_bucket my-logs-archive
    s3_region us-east-1
    
    <buffer time>
      @type file
      path /var/log/fluentd/buffer/s3
      timekey 86400
      timekey_wait 1h
    </buffer>
  </store>
</match>
```

### Example 4: Log Processing Pipeline

```ruby
# Multi-stage log processing

# Raw logs input
<source>
  @type tail
  path /var/log/app/production.log
  pos_file /var/log/fluentd/production.pos
  tag raw.app
  <parse>
    @type json
  </parse>
</source>

# Stage 1: Parse and enrich
<filter raw.app>
  @type record_transformer
  enable_ruby true
  <record>
    hostname "#{Socket.gethostname}"
    service app
    env "${ENV['RAILS_ENV']}"
    timestamp_unix ${Time.now.to_i}
    log_level ${record["severity"] || "INFO"}
  </record>
</filter>

# Stage 2: Parse message field
<filter raw.app>
  @type parser
  key_name message
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

# Stage 3: Add geo information
<filter raw.app>
  @type geoip
  geoip_lookup_keys client_ip
  <record>
    country ${client_ip.country.name}
    city ${client_ip.city.name}
  </record>
</filter>

# Stage 4: Route by level
<filter raw.app>
  @type rewrite_tag_filter
  <rule>
    key log_level
    pattern /^ERROR$/
    tag error.app
  </rule>
  <rule>
    key log_level
    pattern /^WARN$/
    tag warn.app
  </rule>
  <rule>
    key log_level
    pattern /^INFO$/
    tag info.app
  </rule>
</filter>

# Stage 5: Route to destinations
<match error.app>
  @type elasticsearch
  host localhost
  port 9200
  index_name app-errors
  <buffer>
    @type file
    path /var/log/fluentd/buffer/errors
    flush_interval 1s
  </buffer>
</match>

<match warn.app>
  @type elasticsearch
  host localhost
  port 9200
  index_name app-warnings
  <buffer>
    @type file
    path /var/log/fluentd/buffer/warnings
    flush_interval 5s
  </buffer>
</match>

<match info.app>
  @type elasticsearch
  host localhost
  port 9200
  index_name app-logs
  <buffer>
    @type file
    path /var/log/fluentd/buffer/info
    flush_interval 10s
  </buffer>
</match>
```

### Example 5: Microservices Logging

```ruby
# Microservices with service discovery

# Consul-based service discovery
<source>
  @type consul
  tag consul.service
  interval 10s
  
  <parse>
    @type json
  </parse>
</source>

# Collect from all services
<source>
  @type forward
  port 24224
  <security>
    self_hostname fluentd
    shared_key microservices_key
  </security>
</source>

# Enrich with service metadata
<filter consul.**>
  @type record_transformer
  enable_ruby true
  <record>
    service ${record["ServiceName"]}
    node ${record["Node"]}
    tags ${record["ServiceTags"].split(",")}
  </record>
</filter>

# Route by service type
<match consul.**>
  @type rewrite_tag_filter
  <rule>
    key tags
    pattern /web/
    tag web.**
  </rule>
  <rule>
    key tags
    pattern /api/
    tag api.**
  </rule>
  <rule>
    key tags
    pattern /worker/
    tag worker.**
  </rule>
</match>

# Web services
<match web.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name web-services
  logstash_format true
  <buffer>
    @type file
    flush_interval 5s
  </buffer>
</match>

# API services
<match api.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name api-services
  logstash_format true
  <buffer>
    @type file
    flush_interval 5s
  </buffer>
</match>

# Worker services
<match worker.**>
  @type elasticsearch
  host localhost
  port 9200
  index_name worker-services
  logstash_format true
  <buffer>
    @type file
    flush_interval 5s
  </buffer>
</match>
```

---

## 22. Further Reading

### Official Documentation

- [Fluentd Documentation](https://docs.fluentd.org/)
- [Fluentd GitHub](https://github.com/fluent/fluentd)
- [Fluentd Plugin Repository](https://www.fluentd.org/plugins)
- [Fluentd Kubernetes DaemonSet](https://github.com/fluent/fluentd-kubernetes-daemonset)

### Books

- *Fluentd: Unified Logging with Ruby* by Masahiro Nagai
- *Kubernetes Patterns* (chapter on logging)
- *Cloud Native DevOps with Kubernetes* (logging sections)

### Online Resources

- [Fluentd Blog](https://www.fluentd.org/blog)
- [Fluentd Community](https://www.fluentd.org/community)
- [CNCF Fluentd Page](https://www.cncf.io/projects/fluentd/)
- [Fluentd YouTube Channel](https://www.youtube.com/c/fluentd)

### Related Tools

- [Fluent Bit](https://fluentbit.io/) — Lightweight log processor
- [Kubernetes](https://kubernetes.io/) — Container orchestration
- [Elasticsearch](https://www.elastic.co/elasticsearch/) — Search engine
- [Kibana](https://www.elastic.co/kibana) — Visualization
- [Prometheus](https://prometheus.io/) — Monitoring
- [Grafana](https://grafana.com/) — Dashboards

### Community

- [Fluentd Slack](https://slack.fluentd.org/)
- [Fluentd Mailing List](https://groups.google.com/group/fluentd)
- [Fluentd Stack Overflow](https://stackoverflow.com/questions/tagged/fluentd)
