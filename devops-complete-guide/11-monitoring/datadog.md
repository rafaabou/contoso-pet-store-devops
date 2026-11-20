# Datadog Complete Guide

## Table of Contents

1. [What Is Datadog](#1-what-is-datadog)
2. [Why Use Datadog](#2-why-use-datadog)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Agent Configuration](#7-agent-configuration)
8. [Metrics](#8-metrics)
9. [Dashboards](#9-dashboards)
10. [Usage Guide (Step-by-Step)](#10-usage-guide-step-by-step)
11. [Monitors and Alerts](#11-monitors-and-alerts)
12. [Logs](#12-logs)
13. [APM (Application Performance Monitoring)](#13-apm-application-performance-monitoring)
14. [Integrations](#14-integrations)
15. [Security](#15-security)
16. [Cost Optimization](#16-cost-optimization)
17. [Troubleshooting](#17-troubleshooting)
18. [Tips and Best Practices](#18-tips-and-best-practices)
19. [Command Reference](#19-command-reference)
20. [Configuration Reference](#20-configuration-reference)
21. [Real-World Examples](#21-real-world-examples)
22. [Further Reading](#22-further-reading)

---

## 1. What Is Datadog

Datadog is a cloud-based SaaS monitoring and analytics platform that provides infrastructure monitoring, application performance monitoring (APM), log management, security monitoring, and real-user monitoring. It is one of the leading observability platforms for modern cloud environments.

### Key Features

- **Infrastructure Monitoring**: CPU, memory, disk, network across hosts, containers, and cloud services
- **APM**: Distributed tracing, service maps, error tracking, and performance analysis
- **Log Management**: Centralized logging with search, parsing, and alerting
- **Security Monitoring**: Threat detection and compliance monitoring
- **Real User Monitoring (RUM)**: Frontend performance and user experience
- **Synthetic Monitoring**: API and browser testing
- **Database Monitoring**: Query-level performance for SQL and NoSQL databases
- **Network Monitoring**: Network performance monitoring and DNS analytics
- **CI/CD Visibility**: Pipeline monitoring and deployment tracking
- **Over 800 integrations**: Pre-built integrations for cloud providers, databases, messaging systems, and more

### Datadog vs. Open-Source Stack

| Feature | Datadog | Prometheus + Grafana + Loki |
|---------|---------|-----------------------------|
| Setup | Minutes (SaaS) | Hours/Days (self-hosted) |
| Maintenance | None (managed) | High (self-hosted) |
| Scalability | Automatic | Manual |
| Cost | Per-host/per-day | Infrastructure cost only |
| Learning curve | Moderate | High |
| Custom metrics | Expensive ($$$) | Free |
| Data retention | 15-45 months | Configurable |
| Vendor lock-in | High | None |

### Pricing

Datadog pricing is based on:
- **Infrastructure**: Per host per month ($15-$23/host)
- **APM**: Per host per month ($31-$40/host)
- **Logs**: Per GB ingested ($0.10/GB)
- **Custom metrics**: Per metric per month ($0.05/metric)
- **Synthetic tests**: Per 10K test runs ($5-$12)
- **RUM**: Per 10K sessions ($1.50/session)

---

## 2. Why Use Datadog

### Advantages

- **All-in-one platform**: Metrics, logs, traces, and security in a single tool
- **No infrastructure to manage**: SaaS platform handles storage, scaling, and availability
- **800+ pre-built integrations**: Drop-in support for AWS, Azure, GCP, Kubernetes, and more
- **Powerful query language**: DQL (Datadog Query Language) for ad-hoc analysis
- **Real-time alerting**: Monitors with multiple notification channels
- **AI-powered insights**: Anomaly detection, forecasting, and correlation
- **Collaboration**: Shared dashboards, notebooks, and status pages
- **Security**: SOC 2, HIPAA, GDPR compliant

### When to Use Datadog

- Teams that want fast time-to-value without infrastructure management
- Multi-cloud or hybrid-cloud environments requiring unified visibility
- Organizations with limited DevOps/SRE bandwidth
- Applications requiring APM, logs, and infrastructure correlation
- Enterprises needing compliance and security monitoring

### Limitations

- **Cost**: Can become expensive at scale (especially custom metrics and logs)
- **Vendor lock-in**: Data and dashboards are proprietary
- **Custom metrics limits**: Each plan has a custom metrics cap
- **Data locality**: Limited control over data residency (improving with regions)

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Datadog Cloud                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Metrics  │  │  Logs    │  │  APM (Traces)        │  │
│  │  Store    │  │  Store   │  │  Store               │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │Dashboards│  │Monitors  │  │  Notebooks            │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS (443)
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────┴────┐    ┌─────┴─────┐    ┌───┴────┐
    │Datadog  │    │ Datadog   │    │Datadog │
    │Agent    │    │ Agent     │    │Agent   │
    │(Host)   │    │ (K8s)     │    │(Docker)│
    └─────────┘    └───────────┘    └────────┘
```

### Components

1. **Datadog Agent**: Lightweight agent installed on each host/container
2. **Datadog Backend**: SaaS platform storing and processing data
3. **Integrations**: Pre-built data collection for 800+ technologies
4. **Dashboards**: Visualization and reporting
5. **Monitors**: Alerting and notification
6. **APIs**: Programmatic access to data and configuration

### Data Flow

1. Agent collects metrics, logs, and traces from the host
2. Agent sends data to Datadog over HTTPS (port 443)
3. Datadog processes, stores, and indexes the data
4. Dashboards visualize the data in real-time
5. Monitors evaluate conditions and trigger alerts
6. Alerts are sent to configured notification channels

---

## 4. Installation

### Linux (Package Manager)

```bash
# Debian/Ubuntu
DD_API_KEY=YOUR_API_KEY DD_SITE="datadoghq.com" bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script.sh)"

# RHEL/CentOS
DD_API_KEY=YOUR_API_KEY DD_SITE="datadoghq.com" bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script.sh)"
```

### Docker

```bash
docker run -d \
  --name datadog-agent \
  -e DD_API_KEY=YOUR_API_KEY \
  -e DD_SITE="datadoghq.com" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  gcr.io/datadoghq/agent:latest
```

### Kubernetes (Helm)

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update
helm install datadog datadog/datadog \
  --namespace datadog \
  --create-namespace \
  --set datadog.apiKey=YOUR_API_KEY \
  --set datadog.site=datadoghq.com \
  --set datadog.logs.enabled=true \
  --set datadog.apm.enabled=true \
  --set datadog.process.enabled=true
```

### Kubernetes (Operator)

```bash
kubectl apply -f https://raw.githubusercontent.com/DataDog/datadog-operator/main/deployments/helm/datadog-operator/crds/datadoghq.com_datadogagents.yaml
```

### macOS

```bash
# Install via Homebrew
brew install datadog-agent
datadog-agent start
```

### Windows

```powershell
# Download installer from Datadog website
# Or use Chocolatey
choco install datadog-agent -y
```

### Verifying Installation

```bash
# Check agent status
datadog-agent status

# Check agent version
datadog-agent version

# Test connectivity
datadog-agent flare --send

# Check integration status
datadog-agent status | grep -A5 "Running Checks"
```

---

## 5. Configuration

### Main Configuration File

```yaml
# /etc/datadog-agent/datadog.yaml
api_key: YOUR_API_KEY
site: datadoghq.com

# Hostname
hostname: my-hostname

# Tags
tags:
  - env:production
  - team:backend
  - region:us-east-1

# Forwarder
forwarder:
  timeout: 30

# Logs
logs_config:
  enabled: true
  logs_dd_url: intake.logs.datadoghq.com:443
  logs_no_ssl: false

# APM
apm_config:
  enabled: true
  apm_non_local_traffic: false

# Process
process_config:
  enabled: "true"

# Metrics
metrics_config:
  collect_default_metrics: true

# Network Performance Monitoring
network_monitoring:
  enabled: false
```

### Agent Integration Configuration

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
init_config:

instances:
  - nginx_status_url: http://localhost/nginx_status
    tags:
      - env:production
    metrics:
      - active_connections
      - accepts
      - handled
      - requests
      - reading
      - writing
      - waiting
```

### Log Collection Configuration

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
init_config:

logs:
  - type: file
    path: /var/log/nginx/access.log
    service: nginx
    source: nginx
    sourcecategory: httpweb
    tags:
      - env:production

  - type: file
    path: /var/log/nginx/error.log
    service: nginx
    source: nginx-error
    sourcecategory: httpweb
```

### APM Configuration

```yaml
# /etc/datadog-agent/conf.d/python.d/conf.yaml
init_config:

instances:
  - host: localhost
    port: 8126
    service: my-python-app
    env: production
    version: "1.0.0"
```

---

## 6. Core Concepts

### Tags

Tags are key-value pairs that label and filter data in Datadog:

```yaml
tags:
  - env:production
  - service:api-gateway
  - team:backend
  - host:web-server-01
  - region:us-east-1
```

Best practices:
- Use consistent tag naming (snake_case)
- Limit tag cardinality (avoid user IDs, request IDs)
- Standardize across services (env, service, team, region)

### Metrics

Datadog supports multiple metric types:
- **Gauge**: Point-in-time value (e.g., CPU usage)
- **Counter**: Monotonically increasing value (e.g., total requests)
- **Rate**: Per-second rate of change
- **Histogram**: Distribution of values (count, sum, quantiles)

### Distributions

Distributions are a metric type that calculates statistically significant quantiles across hosts:

```python
from datadog import initialize, StatsD
initialize(statsd_host="localhost", statsd_port=8125)
statsd.distribution("myapp.request.duration", duration)
```

### Monitors

Monitors are conditions that trigger notifications:
- Metric monitors
- Anomaly monitors
- Forecast monitors
- APM monitors
- Log monitors
- Process monitors
- Network monitors
- Composite monitors

### Notebooks

Notebooks are collaborative documents for incident response and postmortems:
- Rich text, charts, and data
- Real-time collaboration
- Version history
- Templates

---

## 7. Agent Configuration

### Agent Commands

```bash
# Start/Stop/Restart
sudo systemctl start datadog-agent
sudo systemctl stop datadog-agent
sudo systemctl restart datadog-agent

# Status
datadog-agent status

# Configuration
datadog-agent configcheck

# Flare (diagnostic bundle)
datadog-agent flare

# Integration management
datadog-agent integration install datadog-nginx==2.0.0
datadog-agent integration remove datadog-nginx
```

### Agent Tags

```bash
# Add tags via config
datadog-agent tag "env:production" "team:backend"

# List tags
datadog-agent tag --list

# Remove tags
datadog-agent tag --remove "env:production"
```

### Agent Configuration Checks

```bash
# Check all integrations
datadog-agent configcheck

# Check specific integration
datadog-agent configcheck -d nginx

# List all integrations
datadog-agent integration list
```

### Agent in Docker

```yaml
# docker-compose.yml
version: '3.8'
services:
  datadog:
    image: gcr.io/datadoghq/agent:latest
    environment:
      - DD_API_KEY=YOUR_API_KEY
      - DD_SITE=datadoghq.com
      - DD_LOGS_ENABLED=true
      - DD_APM_ENABLED=true
      - DD_PROCESS_ENABLED=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /etc/datadog-agent:/etc/datadog-agent:ro
    ports:
      - "8126:8126"  # APM
      - "8125:8125"  # DogStatsD
```

### Agent in Kubernetes

```yaml
# DaemonSet spec
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
spec:
  selector:
    matchLabels:
      app: datadog-agent
  template:
    metadata:
      labels:
        app: datadog-agent
    spec:
      containers:
        - name: datadog-agent
          image: gcr.io/datadoghq/agent:latest
          env:
            - name: DD_API_KEY
              valueFrom:
                secretKeyRef:
                  name: datadog-secret
                  key: api-key
            - name: DD_SITE
              value: "datadoghq.com"
            - name: DD_LOGS_ENABLED
              value: "true"
          volumeMounts:
            - name: docker-socket
              mountPath: /var/run/docker.sock
            - name: proc
              mountPath: /host/proc
              readOnly: true
            - name: cgroup
              mountPath: /host/sys/fs/cgroup
              readOnly: true
      volumes:
        - name: docker-socket
          hostPath:
            path: /var/run/docker.sock
        - name: proc
          hostPath:
            path: /proc
        - name: cgroup
          hostPath:
            path: /sys/fs/cgroup
```

---

## 8. Metrics

### Custom Metrics via DogStatsD

```python
from datadog import initialize, StatsD

initialize(statsd_host="localhost", statsd_port=8125)

# Increment counter
StatsD.increment("myapp.requests.total", tags=["method:GET", "status:200"])

# Gauge
StatsD.gauge("myapp.connections.active", 42)

# Histogram
StatsD.histogram("myapp.request.duration", 0.5)

# Distribution
StatsD.distribution("myapp.request.duration", 0.5)

# Timing
StatsD.timing("myapp.request.duration", 500)

# Set
StatsD.set("myapp.users.unique", "user-123")
```

### Metrics Submission via API

```bash
# Submit a metric
curl -X POST "https://api.datadoghq.com/api/v2/series" \
  -H "DD-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "series": [{
      "metric": "myapp.requests.total",
      "type": 0,
      "points": [[1700000000, 42]],
      "tags": ["env:production", "service:api"]
    }]
  }'
```

### Metric Types

| Type | Description | Example |
|------|-------------|---------|
| Gauge | Point-in-time value | CPU usage, memory used |
| Counter | Monotonically increasing | Total requests, errors |
| Rate | Per-second rate of change | Request rate |
| Histogram | Distribution of values | Request latency |
| Distribution | Global distribution | P99 latency |

### Metric Naming Conventions

```
<namespace>.<metric_name>.<unit>

# Examples
system.cpu.user
system.memory.used
nginx.requests.total
http.request.duration
```

### Querying Metrics

```datadog
# Basic query
avg:system.cpu.user{env:production}

# Aggregation
sum:nginx.requests.total{service:api}.as_rate()

# Rolling windows
avg:system.cpu.user{host:web-01}.rollup(avg, 60)

# Arithmetic
avg:system.cpu.user{host:web-01} / avg:system.cpu.user{host:web-02}
```

---

## 9. Dashboards

### Creating Dashboards

1. Go to **Dashboards → New Dashboard**
2. Choose a layout (free-form or timeboard)
3. Add widgets (timeseries, heatmap, top list, etc.)
4. Configure queries and visualizations
5. Save with a name and tags

### Dashboard Types

- **Timeboard**: All widgets share the same time range
- **Screenboard**: Widgets can have independent time ranges
- **Powerpack**: Reusable group of widgets

### Widget Types

| Widget | Description |
|--------|-------------|
| Timeseries | Line or area chart over time |
| Heatmap | Color-coded density visualization |
| Top List | Ranked list of values |
| Query Value | Single value display |
| Table | Tabular data |
| Distribution | Histogram or violin chart |
| SLO | Service Level Objective status |
| Geomap | Geographic visualization |
| Hostmap | Host or container map |
| Log Stream | Live log feed |
| Monitor Summary | Alert status overview |
| Powerpack | Reusable widget group |

### Dashboard JSON Example

```json
{
  "title": "API Overview",
  "widgets": [
    {
      "id": 1,
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "sum:nginx.requests.total{service:api}.as_rate()",
            "display_type": "line",
            "style": {
              "palette": "dog_classic",
              "line_type": "solid",
              "line_width": "normal"
            }
          }
        ],
        "title": "Request Rate",
        "show_legend": true
      }
    },
    {
      "id": 2,
      "definition": {
        "type": "query_value",
        "requests": [
          {
            "q": "avg:system.cpu.user{host:web-01}",
            "aggregator": "avg"
          }
        ],
        "title": "CPU Usage",
        "precision": 2
      }
    }
  ],
  "template_variables": [
    {
      "name": "env",
      "prefix": "env",
      "default": "production"
    }
  ],
  "tags": ["team:backend"]
}
```

### Dashboard Templates

```yaml
# Dashboard template variable
template_variable:
  name: service
  prefix: service
  default: "*"
  defaults:
    - "api-gateway"
    - "web-app"
```

### Dashboard Sharing

1. **Export JSON**: Settings → Export JSON
2. **Share link**: Settings → Share
3. **Embed**: Settings → Embed
4. **Clone**: File → Clone

---

## 10. Usage Guide (Step-by-Step)

### Step 1: Install the Agent

```bash
DD_API_KEY=YOUR_API_KEY DD_SITE="datadoghq.com" bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script.sh)"
```

### Step 2: Verify Agent is Running

```bash
datadog-agent status
```

### Step 3: Enable an Integration

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
init_config:

instances:
  - nginx_status_url: http://localhost/nginx_status
    tags:
      - env:production
```

### Step 4: Restart the Agent

```bash
sudo systemctl restart datadog-agent
```

### Step 5: Verify Metrics Are Flowing

```bash
# Check metrics are being sent
datadog-agent status | grep -A10 "Running Checks"

# Search in Datadog UI
# Metrics → Explorer → search for "nginx"
```

### Step 6: Create a Dashboard

1. Go to **Dashboards → New Dashboard**
2. Add a **Timeseries** widget
3. Enter query: `sum:nginx.requests.total{service:api}.as_rate()`
4. Set title and save

### Step 7: Create a Monitor

1. Go to **Monitors → New Monitor → Metric**
2. Enter alert condition:
   ```datadog
   avg(last_5m):avg:system.cpu.user{host:web-01} > 85
   ```
3. Set alert thresholds
4. Configure notification channels
5. Save

### Step 8: Enable Log Collection

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
logs:
  - type: file
    path: /var/log/nginx/access.log
    service: nginx
    source: nginx
```

### Step 9: Enable APM

```yaml
# /etc/datadog-agent/datadog.yaml
apm_config:
  enabled: true
  apm_non_local_traffic: false
```

### Step 10: Install the Python APM Library

```bash
pip install ddtrace
```

```python
# instrument your application
from ddtrace import patch_all
patch_all()

# Your Flask/Django/FastAPI app automatically gets traced
```

---

## 11. Monitors and Alerts

### Monitor Types

1. **Metric Monitor**: Alert on metric thresholds
2. **Anomaly Monitor**: Detect unusual patterns
3. **Forecast Monitor**: Predict future values
4. **Composite Monitor**: Combine multiple monitors
5. **Log Monitor**: Alert on log patterns
6. **Process Monitor**: Alert on process status
7. **Network Monitor**: Alert on network issues
8. **SLO Monitor**: Alert on SLA breaches
9. **Event Monitor**: Alert on event patterns
10. **Audit Monitor**: Alert on audit trail changes

### Creating a Metric Monitor

```bash
# Via API
curl -X POST "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "metric alert",
    "query": "avg(last_5m):avg:system.cpu.user{host:web-01} > 85",
    "name": "High CPU on web-01",
    "message": "CPU usage is above 85% on web-01. @slack-alerts",
    "options": {
      "thresholds": {
        "critical": 85,
        "warning": 70
      },
      "notify_no_data": true,
      "no_data_timeframe": 10
    },
    "tags": ["env:production"]
  }'
```

### Alert Thresholds

```yaml
options:
  thresholds:
    critical: 85        # Critical threshold
    warning: 70         # Warning threshold
    critical_recovery: 80  # Recovery threshold
    warning_recovery: 65
```

### Notification Channels

```yaml
# Slack
@slack-#alerts

# Email
@team@example.com

# PagerDuty
@pagerduty-service-key

# Webhook
@webhook-https://example.com/alerts

# Microsoft Teams
@teams-channel

# Custom
@custom-channel
```

### Monitor Templates

```yaml
# Multi-alert monitor
query: "avg(last_5m):avg:system.cpu.user{host} > 85"
multi: true  # Alert per host

# composite monitor
query: "monitor1 && monitor2"
type: composite
```

### SLO Monitoring

```yaml
# Define an SLO
slo:
  type: "metric"
  query:
    numerator: "sum:requests.total{service:api}.as_count()"
    denominator: "sum:requests.total{service:api}.as_count() - sum:errors.total{service:api}.as_count()"
  target: 99.9
  window: 30d
```

---

## 12. Logs

### Log Collection

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
logs:
  - type: file
    path: /var/log/nginx/access.log
    service: nginx
    source: nginx
    sourcecategory: httpweb
    tags:
      - env:production

  - type: tcp
    port: 10514
    service: app
    source: custom
```

### Log Parsing

```yaml
# /etc/datadog-agent/conf.d/nginx.d/conf.yaml
logs:
  - type: file
    path: /var/log/nginx/access.log
    service: nginx
    source: nginx
    processing_rules:
      - type: mask_sequences
        name: mask_ip
        pattern: "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
        replace_string: "XXX.XXX.XXX.XXX"
```

### Log Pipelines

Log pipelines parse and enrich logs:

1. **Grok Parser**: Extract fields from log lines
2. **Date Remapper**: Extract timestamp
3. **Status Remapper**: Map to severity
4. **Service Remapper**: Set service name
5. **Tag Remapper**: Add tags
6. **Arithmetic Processor**: Calculate new fields
7. **String Builder Processor**: Create new fields

### Log Search Syntax

```datadog
# Simple search
service:nginx status:500

# Advanced search
service:nginx @http.method:POST @http.status_code:500

# Facets
service:nginx status:500 by @http.url

# Log stream
service:nginx status:500 live
```

### Logs-to-Metrics

```yaml
# Generate metrics from logs
logs:
  - type: file
    path: /var/log/nginx/access.log
    service: nginx
    source: nginx
    processing_rules:
      - type: pipeline
        name: count-errors
        filter:
          query: "status:500"
        processors:
          - type: log-parser
            grok:
              support_rules: ""
              match_rules: |
                log_format <method> <url> <status>
```

---

## 13. APM (Application Performance Monitoring)

### Instrumentation

```python
# Python (Flask)
from flask import Flask
from ddtrace import patch_all
patch_all()

app = Flask(__name__)

@app.route("/")
def index():
    return "Hello World"

# Automatic tracing of Flask routes, database calls, HTTP requests
```

```javascript
// Node.js (Express)
const tracer = require('dd-trace').init();
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello World');
});

// Automatic tracing of Express routes, HTTP requests, database calls
```

```go
// Go
import (
    "gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func main() {
    tracer.Start()
    defer tracer.Stop()
    // Your Go application
}
```

### Trace Structure

```
Trace (request)
├── Span (service A)
│   ├── Span (database query)
│   └── Span (HTTP call to service B)
│       ├── Span (service B processing)
│       │   └── Span (database query)
│       └── Span (cache lookup)
```

### Service Maps

Service maps visualize service dependencies:
- Auto-generated from trace data
- Show request rate, error rate, and latency between services
- Support drill-down to specific traces

### Trace Search

```datadog
# Search traces
service:api-gateway resource_name:/api/users duration:>1000

# Filter by status
service:api-gateway http.status_code:500

# Group by resource
service:api-gateway resource_name:* by {resource_name}
```

### RUM (Real User Monitoring)

```javascript
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: 'xxx',
  clientToken: 'xxx',
  site: 'datadoghq.com',
  service: 'my-web-app',
  env: 'production',
  version: '1.0.0',
  trackInteractions: true,
  trackResources: true,
  trackLongTasks: true
});
```

---

## 14. Integrations

### AWS Integration

```bash
# Install AWS integration
datadog-agent integration install datadog-aws==2.0.0

# Configure
# /etc/datadog-agent/conf.d/aws.d/conf.yaml
init_config:
  aws_access_key_id: YOUR_ACCESS_KEY
  aws_secret_access_key: YOUR_SECRET_KEY

instances:
  - role_arn: arn:aws:iam::ACCOUNT:role/datadog
    regions:
      - us-east-1
      - us-west-2
```

### Kubernetes Integration

```yaml
# Helm values
datadog:
  apiKey: YOUR_API_KEY
  site: datadoghq.com
  logs:
    enabled: true
    containerCollectAll: true
  apm:
    enabled: true
  process:
    enabled: true
  orchestratorExplorer:
    enabled: true
  clusterChecks:
    enabled: true
```

### Docker Integration

```bash
# Auto-detected via Docker socket
docker run -d \
  --name datadog-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e DD_API_KEY=YOUR_API_KEY \
  gcr.io/datadoghq/agent:latest
```

### Database Integrations

```yaml
# PostgreSQL
# /etc/datadog-agent/conf.d/postgres.d/conf.yaml
init_config:

instances:
  - host: postgres
    port: 5432
    username: datadog
    password: password
    dbname: mydb
    tags:
      - env:production

# MySQL
# /etc/datadog-agent/conf.d/mysql.d/conf.yaml
init_config:

instances:
  - host: mysql
    port: 3306
    username: datadog
    password: password
    tags:
      - env:production
```

### Cloud Provider Integrations

- **AWS**: CloudWatch, RDS, ElastiCache, S3, Lambda, ECS, EKS
- **Azure**: Monitor, SQL Database, Cosmos DB, AKS
- **GCP**: Cloud Monitoring, Cloud SQL, GKE, Cloud Functions

---

## 15. Security

### API Key Management

```bash
# Rotate API key
datadog-agent config set api_key NEW_API_KEY

# Or via environment variable
export DD_API_KEY=NEW_API_KEY
```

### Agent Security

```yaml
# /etc/datadog-agent/secure.yaml
# Restrict agent to specific hosts
allowed_hosts:
  - "web-*"
  - "api-*"

# Encrypt communications
agent_https_proxy: "http://proxy:8080"
```

### Log Scrubbing

```yaml
logs:
  - type: file
    path: /var/log/app.log
    service: app
    processing_rules:
      - type: mask_sequences
        name: mask_password
        pattern: "password=[^&]*"
        replace_string: "password=*****"
      - type: mask_sequences
        name: mask_credit_card
        pattern: "\d{4}-\d{4}-\d{4}-\d{4}"
        replace_string: "XXXX-XXXX-XXXX-XXXX"
```

### Compliance

Datadog is compliant with:
- SOC 2 Type II
- HIPAA (with BAA)
- GDPR
- PCI DSS
- FedRAMP
- ISO 27001

### Data Residency

```yaml
# Configure data residency
site: datadoghq.com          # US
site: datadoghq.eu           # EU
site: ap1.datadoghq.com      # Asia Pacific
```

---

## 16. Cost Optimization

### Custom Metrics Cost Control

```bash
# Check custom metric count
datadog-agent status | grep "Custom Metrics"

# List all custom metrics
datadog-agent tag --list
```

### Tips to Reduce Costs

1. **Filter out unnecessary metrics**: Use `exclude` in integration configs
2. **Use tags strategically**: Avoid high-cardinality tags
3. **Set metric retention**: Use shorter retention for non-critical metrics
4. **Optimize log volume**: Filter logs before ingestion
5. **Use log archival**: Store old logs in cloud storage
6. **Consolidate dashboards**: Fewer dashboards = fewer queries
7. **Use monitors efficiently**: Avoid redundant monitors

### Log Volume Management

```yaml
# Filter logs at the agent
logs:
  - type: file
    path: /var/log/app.log
    service: app
    processing_rules:
      - type: exclude_at_match
        name: exclude_debug
        pattern: "DEBUG"
```

### Metric Aggregation

```datadog
# Use rollups to reduce data points
avg:system.cpu.user{host:web-01}.rollup(avg, 60)

# Use percentiles sparingly
p99:system.cpu.user{host:web-01}
```

---

## 17. Troubleshooting

### Issue 1: Agent Not Sending Metrics

**Symptoms**: No data appearing in Datadog

**Diagnosis**:
```bash
datadog-agent status
datadog-agent configcheck
curl -v https://api.datadoghq.com
```

**Resolution**: Check API key, verify network connectivity, check firewall rules (port 443), ensure agent is running.

### Issue 2: Integration Not Working

**Symptoms**: Metrics from a specific integration not appearing

**Diagnosis**:
```bash
datadog-agent status | grep -A5 "Running Checks"
datadog-agent configcheck -d nginx
```

**Resolution**: Verify integration config, check log files for errors, ensure integration is installed.

### Issue 3: Logs Not Appearing

**Symptoms**: No logs in Log Explorer

**Diagnosis**:
```bash
datadog-agent status | grep -A10 "Logs Agent"
ls -la /var/log/nginx/
```

**Resolution**: Check log file paths, verify log collection is enabled, ensure file permissions, check source/service tags.

### Issue 4: APM Traces Not Showing

**Symptoms**: No traces in APM Explorer

**Diagnosis**:
```bash
# Check agent is listening on port 8126
netstat -tlnp | grep 8126

# Check application is sending traces
curl http://localhost:8126/debug/trace
```

**Resolution**: Ensure `DD_APM_ENABLED=true`, check application is instrumented, verify port 8126 is accessible.

### Issue 5: High Agent CPU Usage

**Symptoms**: Agent consuming excessive CPU

**Diagnosis**:
```bash
ps aux | grep datadog-agent
datadog-agent status
```

**Resolution**: Reduce collection frequency, disable unnecessary integrations, increase agent resources.

### Issue 6: Custom Metrics Not Appearing

**Symptoms**: Custom metrics not in Datadog

**Diagnosis**:
```bash
# Check DogStatsD is listening
netstat -tlnp | grep 8125

# Test metric submission
echo -e "my.metric:1|c" | nc -u -w1 localhost 8125
```

**Resolution**: Verify DogStatsD is enabled, check metric name format, ensure application is sending to correct host/port.

### Issue 7: Monitor Not Firing

**Symptoms**: Alert conditions met but no notification

**Diagnosis**:
```bash
# Check monitor status via API
curl -X GET "https://api.datadoghq.com/api/v1/monitor/MONITOR_ID" \
  -H "DD-API-KEY: YOUR_API_KEY"
```

**Resolution**: Check monitor query, verify thresholds, check notification channels, ensure no silences are active.

### Issue 8: Dashboard Not Loading

**Symptoms**: Dashboard shows "Loading" indefinitely

**Resolution**: Check browser console for errors, clear browser cache, verify dashboard permissions, check query syntax.

### Issue 9: Agent Flare Fails

**Symptoms**: `datadog-agent flare` command fails

**Resolution**: Check network connectivity to Datadog, verify API key, try with `--send` flag.

### Issue 10: Container Metrics Missing

**Symptoms**: Kubernetes/Docker containers not reporting metrics

**Resolution**: Ensure Docker socket is mounted, check container runtime permissions, verify DD_AGENT_HOST is set correctly.

### Issue 11: Metric Gaps

**Symptoms**: Intermittent gaps in metric data

**Resolution**: Check agent uptime, verify network stability, increase agent resources, check for metric drop in agent logs.

### Issue 12: Log Parsing Errors

**Symptoms**: Logs appear but fields are not extracted

**Resolution**: Verify grok patterns, test patterns against sample logs, check log pipeline configuration.

### Issue 13: APM Propagation Issues

**Symptoms**: Traces not connecting across services

**Resolution**: Ensure all services are instrumented, check trace context propagation headers, verify DD_TRACE_HEADER_TAGS configuration.

### Issue 14: Agent Cannot Connect

**Symptoms**: Agent logs show connection errors

**Resolution**: Check firewall rules (port 443), verify proxy settings, check DNS resolution, test with `curl -v https://api.datadoghq.com`.

### Issue 15: Custom Metrics Rate Limiting

**Symptoms**: "Rate limited" errors in agent logs

**Resolution**: Reduce custom metric cardinality, use tag aggregation, contact Datadog support to increase limits.

### Issue 16: Process Collection Not Working

**Symptoms**: No process data in Datadog

**Resolution**: Verify `process_config.enabled=true`, check agent has sufficient permissions, ensure `/proc` is mounted.

---

## 18. Tips and Best Practices

### 1. Use Consistent Tagging

Standardize tags across all services: `env`, `service`, `team`, `region`, `host`.

### 2. Use Synthetics for Critical Paths

Create API and browser tests for critical user journeys.

### 3. Create SLOs for Key Services

Define and monitor service level objectives for availability and latency.

### 4. Use APM for Distributed Tracing

Instrument all services with Datadog APM libraries.

### 5. Implement Log Correlation

Correlate logs with traces using `dd.trace_id` and `dd.span_id`.

### 6. Use Monitors for Everything

Create monitors for all critical metrics, not just CPU and memory.

### 7. Use Dashboard Templates

Create reusable dashboard templates with variables for different environments.

### 8. Use Notebooks for Incident Response

Document incident response procedures in notebooks.

### 9. Use Service Maps for Dependency Visualization

Regularly review service maps to understand and monitor dependencies.

### 10. Set Up Synthetic Monitoring

Create API and browser tests to proactively detect issues.

### 11. Use RUM for Frontend Monitoring

Monitor real user experience with RUM sessions.

### 12. Implement Database Monitoring

Use Database Monitoring for query-level performance analysis.

### 13. Use CI/CD Visibility

Track deployment performance and failures in CI/CD pipelines.

### 14. Regular Agent Updates

Keep the Datadog agent updated to the latest version.

### 15. Use Logs for Debugging

Enable log collection for all services for debugging.

### 16. Use Anomaly Detection

Create anomaly monitors for metrics with seasonal patterns.

### 17. Use Forecast Monitors

Predict resource exhaustion with forecast monitors.

---

## 19. Command Reference

### Agent Commands

```bash
# Status
datadog-agent status
datadog-agent status --json

# Version
datadog-agent version

# Configuration
datadog-agent configcheck
datadog-agent configcheck -d nginx
datadog-agent config set api_key KEY

# Flare (diagnostic)
datadog-agent flare
datadog-agent flare --send

# Integration management
datadog-agent integration install datadog-nginx==2.0.0
datadog-agent integration remove datadog-nginx
datadog-agent integration list

# Tagging
datadog-agent tag "env:production" "team:backend"
datadog-agent tag --list
datadog-agent tag --remove "env:production"

# Diagnostics
datadog-agent diagnose
datadog-agent stop
datadog-agent restart
```

### API Examples

```bash
# List metrics
curl -X GET "https://api.datadoghq.com/api/v1/query" \
  -H "DD-API-KEY: YOUR_API_KEY" \
  -d 'query=avg:system.cpu.user{host:web-01}&from=now-1h&to=now'

# List monitors
curl -X GET "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: YOUR_API_KEY"

# Create monitor
curl -X POST "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d @monitor.json

# List dashboards
curl -X GET "https://api.datadoghq.com/api/v1/dashboard" \
  -H "DD-API-KEY: YOUR_API_KEY"

# Submit metrics
curl -X POST "https://api.datadoghq.com/api/v2/series" \
  -H "DD-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d @metrics.json
```

### DogStatsD

```bash
# Submit a counter
echo "my.metric:1|c" | nc -u -w1 localhost 8125

# Submit a gauge
echo "my.gauge:42|g" | nc -u -w1 localhost 8125

# Submit a histogram
echo "my.histogram:0.5|h" | nc -u -w1 localhost 8125

# With tags
echo "my.metric:1|c|#env:production,team:backend" | nc -u -w1 localhost 8125
```

---

## 20. Configuration Reference

### Agent Configuration

```yaml
# /etc/datadog-agent/datadog.yaml
api_key: string                  # Required: API key
site: datadoghq.com              # Datadog site
hostname: string                 # Agent hostname
tags: [string, ...]              # Global tags
forwarder:
  timeout: 30                    # Forwarder timeout
logs_config:
  enabled: false                 # Enable log collection
  logs_dd_url: string            # Log endpoint
apm_config:
  enabled: false                 # Enable APM
  apm_non_local_traffic: false   # Accept remote connections
process_config:
  enabled: "false"               # Enable process collection
metrics_config:
  collect_default_metrics: true  # Collect default metrics
```

### Integration Configuration

```yaml
# /etc/datadog-agent/conf.d/<integration>.d/conf.yaml
init_config:
  # Integration-specific init config

instances:
  - # Integration-specific instance config
    tags: [string, ...]
    min_collection_interval: 15  # Collection interval
```

### Log Collection

```yaml
logs:
  - type: file|tcp|udp|docker
    path: string                  # File path (file type)
    port: int                     # Port (tcp/udp type)
    service: string               # Service name
    source: string                # Source type
    sourcecategory: string        # Source category
    tags: [string, ...]
    processing_rules:
      - type: mask_sequences|exclude_at_match|include_at_match
        name: string
        pattern: string
        replace_string: string
```

### APM Configuration

```yaml
apm_config:
  enabled: false
  apm_non_local_traffic: false
  apm_dd_port: 8126
  receiver_port: 8126
  receiver_socket: string
  max_traces_per_second: 10
  ignore_resources: [string, ...]
  replace_tags:
    - name: string
      pattern: string
      repl: string
```

---

## 21. Real-World Examples

### Example 1: Full Stack Monitoring

```yaml
# datadog.yaml
api_key: YOUR_API_KEY
site: datadoghq.com
hostname: web-server-01
tags:
  - env:production
  - team:backend
  - region:us-east-1

logs_config:
  enabled: true

apm_config:
  enabled: true

process_config:
  enabled: "true"
```

### Example 2: Kubernetes Monitoring

```yaml
# Helm values
datadog:
  apiKey: YOUR_API_KEY
  site: datadoghq.com
  logs:
    enabled: true
    containerCollectAll: true
  apm:
    enabled: true
    port: 8126
  process:
    enabled: true
  orchestratorExplorer:
    enabled: true
  clusterChecks:
    enabled: true
  kubeStateMetricsCore:
    enabled: true
  kubelet:
    tlsVerify: false
```

### Example 3: Multi-Service Dashboard

```json
{
  "title": "Microservices Overview",
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "requests": [{
          "q": "sum:requests.total{service:*}.as_rate() by {service}",
          "display_type": "line"
        }],
        "title": "Request Rate by Service"
      }
    },
    {
      "definition": {
        "type": "timeseries",
        "requests": [{
          "q": "sum:errors.total{service:*}.as_rate() by {service} / sum:requests.total{service:*}.as_rate() by {service} * 100",
          "display_type": "line"
        }],
        "title": "Error Rate by Service"
      }
    },
    {
      "definition": {
        "type": "top_list",
        "requests": [{
          "q": "avg:request.duration{service:*} by {service}",
          "sort": {"order": "desc", "name": "value"}
        }],
        "title": "P95 Latency by Service"
      }
    }
  ]
}
```

### Example 4: SLO Dashboard

```json
{
  "title": "Service SLOs",
  "widgets": [
    {
      "definition": {
        "type": "slo",
        "requests": [{
          "slo_id": "SLO_ID"
        }],
        "title": "API Availability SLO"
      }
    },
    {
      "definition": {
        "type": "query_value",
        "requests": [{
          "q": "100 - (sum:errors.total{service:api}.as_count() / sum:requests.total{service:api}.as_count() * 100)",
          "aggregator": "avg"
        }],
        "title": "Availability %"
      }
    }
  ]
}
```

---

## 22. Further Reading

### Official Documentation

- [Datadog Documentation](https://docs.datadoghq.com/)
- [Agent Configuration](https://docs.datadoghq.com/agent/configuration/)
- [Metrics Explorer](https://docs.datadoghq.com/metrics/explorer/)
- [Log Management](https://docs.datadoghq.com/logs/)
- [APM](https://docs.datadoghq.com/tracing/)
- [Monitors](https://docs.datadoghq.com/monitors/)

### Books

- *Observability Engineering* by Charity Majors et al.
- *Site Reliability Engineering* by Google
- *The Site Reliability Workbook* by Google

### Community Resources

- [Datadog Blog](https://www.datadoghq.com/blog/)
- [Datadog YouTube](https://www.youtube.com/datadoghq)
- [Datadog Community](https://docs.datadoghq.com/help/)
- [Datadog Status Page](https://status.datadoghq.com/)

### Related Tools

- [Prometheus](https://prometheus.io/) - Open-source metrics collection
- [Grafana](https://grafana.com/) - Open-source dashboards
- [Jaeger](https://www.jaegertracing.io/) - Open-source distributed tracing
- [OpenTelemetry](https://opentelemetry.io/) - Open-source observability framework
- [VictoriaMetrics](https://victoriametrics.com/) - Fast, cost-effective TSDB
