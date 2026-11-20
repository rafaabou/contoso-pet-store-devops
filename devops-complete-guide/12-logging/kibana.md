# Kibana Complete Guide

## Table of Contents

1. [What Is Kibana](#1-what-is-kibana)
2. [Why Use Kibana](#2-why-use-kibana)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Discover](#7-discover)
8. [Dashboards](#8-dashboards)
9. [Visualizations](#9-visualizations)
10. [Lens](#10-lens)
11. [Maps](#11-maps)
12. [Machine Learning](#12-machine-learning)
13. [Alerting and Actions](#13-alerting-and-actions)
14. [Index Pattern Management](#14-index-pattern-management)
15. [Security](#15-security)
16. [Advanced Features](#16-advanced-features)
17. [Troubleshooting](#17-troubleshooting)
18. [Tips and Best Practices](#18-tips-and-best-practices)
19. [Command Reference](#19-command-reference)
20. [Configuration Reference](#20-configuration-reference)
21. [Real-World Examples](#21-real-world-examples)
22. [Further Reading](#22-further-reading)

---

## 1. What Is Kibana

Kibana is an open-source data visualization and exploration tool for log analytics, time-series data, and application monitoring. It provides a web-based interface for interacting with Elasticsearch, allowing users to search, analyze, and visualize data in real time.

### Key Characteristics

- **Data Visualization**: Create charts, graphs, maps, and dashboards
- **Real-Time Exploration**: Search and filter data interactively
- **Time-Series Analysis**: Analyze trends over time
- **Geospatial Analysis**: Visualize location data on maps
- **Machine Learning**: Anomaly detection and forecasting
- **Alerting**: Set up notifications based on conditions
- **Reporting**: Generate and schedule reports
- **Canvas**: Create custom, pixel-perfect visualizations

### Use Cases

- **Log Analytics**: Explore and visualize log data
- **Application Monitoring**: Track application performance
- **Infrastructure Monitoring**: Monitor servers, containers, and services
- **Security Analytics**: Analyze security events and threats
- **Business Intelligence**: Visualize business metrics
- **IoT Dashboards**: Monitor IoT device data
- **Network Monitoring**: Analyze network traffic

### Kibana Version History

| Version | Key Features |
|---------|--------------|
| 8.x | Data views, Lens improvements, ES|QL, Fleet integration |
| 7.x | Canvas, Maps, Lens, Machine Learning |
| 6.x | Timelion, TSVB, APM |
| 5.x | Visual Builder, Canvas (beta) |

---

## 2. Why Use Kibana

### Advantages Over Alternatives

**Compared to Grafana:**
- Better integration with Elasticsearch
- More advanced search capabilities
- Better for log analytics use cases
- Built-in machine learning features

**Compared to Tableau/Power BI:**
- Real-time data exploration
- Better for time-series data
- Free and open-source
- Tighter integration with Elastic Stack

**Compared to Custom Dashboards:**
- No coding required
- Rich built-in visualizations
- Real-time updates
- Enterprise-ready features

### When Kibana Excels

- Your data is in Elasticsearch
- You need real-time data exploration
- You want rich search and filtering
- You need geospatial visualization
- You want machine learning on your data
- You need alerting and reporting

---

## 3. Architecture Overview

### Kibana Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Kibana Architecture                │
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │              Browser (Client)                 │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │ Discover│  │Dashboard│  │ Visualize│     │   │
│  │  └─────────┘  └─────────┘  └─────────┘     │   │
│  └──────────────────────────────────────────────┘   │
│                        │                              │
│                        ▼                              │
│  ┌──────────────────────────────────────────────┐   │
│  │              Kibana Server                    │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │  Node.js │  │  Hapi   │  │   OSS   │     │   │
│  │  │  Server  │  │  Server │  │ Modules │     │   │
│  │  └─────────┘  └─────────┘  └─────────┘     │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │  Saved  │  │  Task   │  │  Spaces │     │   │
│  │  │ Objects │  │ Manager │  │         │     │   │
│  │  └─────────┘  └─────────┘  └─────────┘     │   │
│  └──────────────────────────────────────────────┘   │
│                        │                              │
│                        ▼                              │
│  ┌──────────────────────────────────────────────┐   │
│  │              Elasticsearch                     │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │  .kibana│  │ .alerting│  │ .ml-*   │     │   │
│  │  │  index  │  │  index   │  │ indices │     │   │
│  │  └─────────┘  └─────────┘  └─────────┘     │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **Discover** | Search and explore documents |
| **Dashboard** | Combine visualizations |
| **Visualize** | Create charts and graphs |
| **Lens** | Drag-and-drop visualization editor |
| **Maps** | Geospatial data visualization |
| **Machine Learning** | Anomaly detection, forecasting |
| **Alerting** | Set up notifications |
| **Dev Tools** | Console, search profiler |
| **Index Management** | Manage indices and data views |

---

## 4. Installation

### Prerequisites

```bash
# System requirements
- RAM: 4GB minimum (8GB+ recommended)
- CPU: 2+ cores
- Disk: 50GB+ (SSD recommended)
- Elasticsearch: Must match Kibana version
- Browser: Chrome, Firefox, Safari (latest versions)
```

### Install via Package Manager

```bash
# Ubuntu/Debian
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
sudo apt-get install kibana

# RHEL/CentOS
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF | sudo tee /etc/yum.repos.d/kibana.repo
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
sudo yum install kibana

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana
```

### Install with Docker

```bash
# Basic Kibana
docker run -d \
  --name kibana \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  -e "ELASTICSEARCH_USERNAME=kibana_system" \
  -e "ELASTICSEARCH_PASSWORD=changeme" \
  docker.elastic.co/kibana/kibana:8.12.0

# With persistent data
docker run -d \
  --name kibana \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  -v kibana-data:/usr/share/kibana/data \
  docker.elastic.co/kibana/kibana:8.12.0
```

### Install with Docker Compose

```yaml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=changeme
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
    volumes:
      - es-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - elastic

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=changeme
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - elastic
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u kibana_system:changeme http://localhost:5601/api/status | grep -q '\"overall\":{\"level\":\"available\"}'"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  es-data:
    driver: local

networks:
  elastic:
    driver: bridge
```

### Install with Kubernetes (ECK Operator)

```bash
# Install operator
kubectl create -f https://download.elastic.co/downloads/eck/2.12.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.12.0/operator.yaml

# Create Kibana instance
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.12.0
  count: 1
  elasticsearchRef:
    name: quickstart
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 1Gi
            cpu: 500m
EOF
```

---

## 5. Configuration

### kibana.yml (Main Config)

```yaml
# ======================== Kibana Configuration ========================

# Server
server.port: 5601
server.host: "0.0.0.0"
server.name: "kibana.example.com"
server.publicBaseUrl: "https://kibana.example.com"

# Elasticsearch connection
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "changeme"

# Kibana index
kibana.index: ".kibana"

# Logging
logging.verbose: false
logging.dest: /var/log/kibana/kibana.log
logging.quiet: false
logging.silent: false

# SSL/TLS
server.ssl.enabled: true
server.ssl.certificate: /path/to/cert.crt
server.ssl.key: /path/to/cert.key

# Elasticsearch SSL
elasticsearch.ssl.certificate: /path/to/es-cert.crt
elasticsearch.ssl.key: /path/to/es-cert.key
elasticsearch.ssl.certificateAuthorities: ["/path/to/ca.crt"]

# Security
xpack.security.enabled: true
xpack.security.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.security.session.idleTimeout: "1h"
xpack.security.session.lifespan: "24h"

# Monitoring
xpack.monitoring.enabled: true
xpack.monitoring.ui.container.elasticsearch.enabled: true

# Machine Learning
xpack.ml.enabled: true

# Alerting
xpack.encryptedSavedObjects.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.actions.allowedHosts: ["*"]

# Reporting
xpack.reporting.enabled: true
xpack.reporting.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.reporting.kibana.serverHostname: "localhost"

# Saved Objects
xpack.saved_objects.maxImportExportSize: 10000

# Maps
xpack.maps.enabled: true

# Canvas
xpack.canvas.enabled: true
```

### Environment Variables

```bash
# Docker
ELASTICSEARCH_HOSTS=http://elasticsearch:9200
ELASTICSEARCH_USERNAME=kibana_system
ELASTICSEARCH_PASSWORD=changeme
SERVER_PORT=5601
SERVER_HOST=0.0.0.0
XPACK_SECURITY_ENABLED=true

# Kubernetes
- name: ELASTICSEARCH_HOSTS
  value: "http://elasticsearch:9200"
```

### Multi-Kibana Setup

```yaml
# Load balancing with nginx
upstream kibana {
    server kibana-1:5601 weight=1;
    server kibana-2:5601 weight=1;
    server kibana-3:5601 weight=1 backup;
}

server {
    listen 443 ssl;
    server_name kibana.example.com;

    ssl_certificate /etc/ssl/certs/kibana.crt;
    ssl_certificate_key /etc/ssl/private/kibana.key;

    location / {
        proxy_pass http://kibana;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 6. Core Concepts

### Data Views (Index Patterns)

A data view (formerly index pattern) tells Kibana which Elasticsearch indices to query.

```
Data View Examples:
  logs-*          (matches all log indices)
  filebeat-*      (matches all Filebeat indices)
  my-app-2024.*   (matches monthly indices)
  logs-2024.01.*  (matches specific month)
```

### Saved Objects

Saved objects are reusable configurations stored in the `.kibana` index:

- **Index Patterns / Data Views**: Define which indices to query
- **Visualizations**: Charts, graphs, and other visual elements
- **Dashboards**: Collections of visualizations
- **Saved Searches**: Reusable search queries
- **Alerts**: Notification rules
- **Maps**: Geospatial visualizations
- **Canvas**: Custom workpads

### Time Range

Kibana uses time ranges to filter data:

```
Quick Select:
  Last 15 minutes
  Last 1 hour
  Last 24 hours
  Last 7 days
  Last 30 days

Absolute:
  2024-01-01 00:00:00 to 2024-01-31 23:59:59

Relative:
  Last 7 days, now-7d to now
  Last 2 hours, now-2h to now
```

### Fields

Each field has a type:

| Type | Description | Example |
|------|-------------|---------|
| text | Full-text searchable | "Hello World" |
| keyword | Exact value | "published" |
| number | Numeric values | 42, 3.14 |
| date | Date/time | 2024-01-15 |
| boolean | True/false | true |
| geo_point | Lat/lon | 40.7, -74.0 |
| ip | IP address | 192.168.1.1 |
| nested | Array of objects | [...] |
| flattened | Flattened object | {...} |

### Spaces

Spaces allow you to organize saved objects by use case:

```
Default:           All saved objects
Production:        Production dashboards and alerts
Development:       Development and testing
Security:          Security-related visualizations
```

---

## 7. Discover

### Basic Search

```
# Simple text search
error

# Field-specific search
message:"connection refused"
level:ERROR

# Wildcard
service:web-*

# Boolean operators
level:ERROR AND service:auth
level:ERROR OR level:WARN
NOT level:DEBUG

# Range queries
response_time > 1000
date >= "2024-01-01" AND date < "2024-02-01"
```

### KQL (Kibana Query Language)

```
# Exact match
level: "ERROR"

# Wildcard
message: *error*

# Exists
tags: *

# Boolean
level: "ERROR" and service: "auth"
level: "ERROR" or level: "WARN"
not service: "test"

# Range
response_time > 1000
date >= "2024-01-01"

# Nested field
user.name: "john"

# Phrase match
message: "connection refused"

# Existence
error: *
```

### Lucene Query Syntax

```
# Full-text search
error connection

# Field-specific
level:ERROR
message:"connection refused"

# Wildcard
service:web-*
message: *error*

# Fuzzy
message:error~

# Range
date:[2024-01-01 TO 2024-01-31]
response_time:[1000 TO *]

# Boolean
level:ERROR AND service:auth
level:ERROR OR level:WARN
NOT service:test
```

### Filtering

```
# Add filters
level is ERROR
service is "auth-service"
date is in the last 24 hours

# Filter types
is          - Exact match
is not      - Negation
is one of   - Multiple values
exists      - Field exists
does not exist - Field doesn't exist
```

### Discover Features

- **Field Statistics**: View field distribution
- **Document Viewer**: Expand documents to see full content
- **Column Management**: Add/remove columns
- **Sort**: Sort by any field
- **Export**: Export to CSV or JSON
- **Share**: Generate shareable links

---

## 8. Dashboards

### Creating Dashboards

1. Go to **Dashboard** → **Create dashboard**
2. Add visualizations
3. Arrange and resize panels
4. Set time range
5. Save the dashboard

### Dashboard Features

```
# Auto-refresh
Auto-refresh: 5s, 10s, 30s, 1m, 5m

# Time range
Last 15 minutes
Last 1 hour
Last 24 hours
Last 7 days
Last 30 days
Absolute time range

# Full screen
Click full screen icon

# Share
Generate link
Embed code
Export PDF
```

### Dashboard Layout

```
┌─────────────────────────────────────────────────────┐
│                    Dashboard                          │
│                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │ Metric 1    │  │ Metric 2    │  │ Metric 3    │ │
│  │ 1,234       │  │ 567         │  │ 89%         │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
│                                                       │
│  ┌─────────────────────────┐  ┌─────────────────────┐│
│  │                         │  │                     ││
│  │   Line Chart            │  │   Pie Chart         ││
│  │                         │  │                     ││
│  └─────────────────────────┘  └─────────────────────┘│
│                                                       │
│  ┌─────────────────────────────────────────────────┐│
│  │                                                 ││
│  │              Data Table                          ││
│  │                                                 ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

### Dashboard Actions

```
# Panel actions
Edit visualization
Delete panel
Clone panel
More actions
  - Edit panel title
  - Edit panel description
  - Duplicate panel
  - Open in Lens

# Dashboard actions
Save
Share
Full screen
Auto-refresh
Time range
Add new visualization
```

### Import/Export Dashboards

```bash
# Export dashboard
Management → Saved Objects → Export

# Import dashboard
Management → Saved Objects → Import

# Via API
POST /api/kibana/dashboards/export
{
  "objects": [
    {
      "type": "dashboard",
      "id": "my-dashboard"
    }
  ]
}
```

---

## 9. Visualizations

### Visualization Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Lens** | Drag-and-drop editor | General purpose |
| **TSVB** | Time Series Visual Builder | Time-series analysis |
| **Timelion** | Time-series expressions | Advanced time-series |
| **Vega** | Custom visualizations | Complex charts |
| **Metric** | Single number display | KPIs |
| **Gauge** | Gauge visualization | Progress, percentages |
| **Goal** | Goal visualization | Targets |
| **Pie** | Pie chart | Proportions |
| **Donut** | Donut chart | Proportions |
| **Tagcloud** | Tag cloud | Text analysis |
| **Heatmap** | Heat map | Correlations |
| **Area** | Area chart | Trends over time |
| **Bar** | Bar chart | Comparisons |
| **Line** | Line chart | Trends |
| **Horizontal Bar** | Horizontal bar chart | Comparisons |
| **Data Table** | Data table | Detailed data |
| **Metric** | Metric visualization | KPIs |
| **Gauge** | Gauge | Progress |
| **Goal** | Goal | Targets |
| **Controls** | Input controls | Filtering |

### Creating Visualizations

```json
// Line chart configuration
{
  "type": "line",
  "title": "Request Rate Over Time",
  "params": {
    "type": "line",
    "grid": {
      "categoryLines": false
    },
    "categoryAxes": [
      {
        "id": "CategoryAxis-1",
        "type": "category",
        "position": "bottom",
        "show": true,
        "labels": {
          "show": true,
          "filter": true,
          "truncate": 100
        }
      }
    ],
    "valueAxes": [
      {
        "id": "ValueAxis-1",
        "name": "LeftAxis-1",
        "type": "value",
        "position": "left",
        "show": true,
        "labels": {
          "show": true,
          "rotate": 0,
          "filter": false,
          "truncate": 100
        }
      }
    ]
  },
  "aggs": [
    {
      "id": "1",
      "enabled": true,
      "type": "count",
      "schema": "metric",
      "params": {}
    },
    {
      "id": "2",
      "enabled": true,
      "type": "date_histogram",
      "schema": "segment",
      "params": {
        "field": "@timestamp",
        "timeRange": {
          "from": "now-1h",
          "to": "now"
        },
        "interval": "auto",
        "used_interval": "1m",
        "drop_partials": false,
        "min_doc_count": 0,
        "extended_bounds": {}
      }
    }
  ]
}
```

### Table Visualization

```json
{
  "type": "table",
  "title": "Top Services by Error Count",
  "params": {
    "perPage": 10,
    "showPartialRows": false,
    "showMetricsAtAllLevels": false,
    "showTotal": false,
    "totalFunc": "sum"
  },
  "aggs": [
    {
      "id": "1",
      "enabled": true,
      "type": "count",
      "schema": "metric",
      "params": {}
    },
    {
      "id": "2",
      "enabled": true,
      "type": "terms",
      "schema": "bucket",
      "params": {
        "field": "service",
        "size": 10,
        "order": "desc",
        "orderBy": "1"
      }
    }
  ]
}
```

---

## 10. Lens

### Lens Features

- **Drag-and-drop**: No code required
- **Smart suggestions**: Auto-suggests chart types
- **Quickly change**: Switch between visualization types
- **Layer system**: Multiple data layers
- **Reference lines**: Add thresholds and targets
- **Color mapping**: Custom color schemes

### Lens Chart Types

```
# Basic charts
Line
Area
Bar
Histogram
Donut
Pie
Metric
Gauge
Goal
Tagcloud
Heatmap
Table

# Advanced charts
Mixed (XY)
Lens form-based
```

### Lens Configuration

```
# X-Axis
Field: @timestamp
Interval: Auto, Minute, Hour, Day, Week, Month

# Y-Axis
Function: Count, Average, Sum, Min, Max, Unique Count
Field: response_time

# Breakdown
Field: service
Size: 10

# Filters
level: ERROR
service: auth-service

# Color
By breakdown value
Custom palette
```

### Lens Example

```
Create a line chart showing request rate by service:

1. Select "Line" chart type
2. X-Axis: @timestamp (auto interval)
3. Y-Axis: Count
4. Breakdown: service field
5. Add filter: level is not DEBUG
6. Set time range: Last 24 hours
7. Save as "Request Rate by Service"
```

---

## 11. Maps

### Map Features

- **Vector maps**: Country, region boundaries
- **Tile maps**: Background map layers
- **Point data**: Latitude/longitude fields
- **Heat maps**: Density visualization
- **Clustering**: Group nearby points
- **Choropleth**: Color by value
- **Labels**: Custom labels
- **Filters**: Spatial filtering

### Creating Maps

```
# Layer types
Documents: Elasticsearch documents
Geo JSON: Upload custom shapes
EMS boundaries: Elastic Maps Service
Tile map: Background tiles
Web map service: WMS layers

# Configuration
Index pattern: logs-*
Geo field: geo.coordinates
Style: 
  - Fill color
  - Border color
  - Border width
  - Symbol size
  - Label
```

### Map Example

```
Create a map showing error locations:

1. Go to Maps
2. Click "Add layer"
3. Select "Documents"
4. Select data view "logs-*"
5. Select geo field "geo.coordinates"
6. Set style:
   - Fill color: Red
   - Symbol size: 8
   - Label: error message
7. Add filters:
   - level is ERROR
8. Set time range: Last 24 hours
9. Save as "Error Locations"
```

### Spatial Queries

```json
// Bounding box
{
  "geo_bounding_box": {
    "location": {
      "top_left": { "lat": 40.7, "lon": -74.1 },
      "bottom_right": { "lat": 40.6, "lon": -74.0 }
    }
  }
}

// Distance
{
  "geo_distance": {
    "distance": "10km",
    "location": {
      "lat": 40.7,
      "lon": -74.0
    }
  }
}
```

---

## 12. Machine Learning

### ML Features

- **Anomaly Detection**: Detect unusual patterns
- **Forecasting**: Predict future values
- **Data Frame Analytics**: Classification, regression, outlier detection
- **NLP**: Natural language processing

### Anomaly Detection Jobs

```json
// Create an anomaly detection job
PUT _ml/anomalydetection/my-job
{
  "description": "Detect unusual request rates",
  "analysis_config": {
    "bucket_span": "15m",
    "detectors": [
      {
        "function": "high_count",
        "by_field_name": "service",
        "detector_description": "High count by service"
      }
    ],
    "influencers": [
      {
        "field_name": "service"
      }
    ]
  },
  "data_description": {
    "time_field": "@timestamp",
    "time_format": "epoch_ms"
  },
  "analysis_limits": {
    "model_memory_limit": "256mb"
  }
}
```

### ML Dashboard

```
# ML Dashboard shows:
- Anomaly score timeline
- Top anomalies
- Influencer analysis
- Forecast visualization
- Model performance
```

### Creating ML Job

1. Go to **Machine Learning** → **Anomaly Detection**
2. Click **Create job**
3. Select data view
4. Select detector (e.g., "high_count")
5. Configure bucket span
6. Set influencers
7. Review and create
8. Start job

---

## 13. Alerting and Actions

### Alert Types

| Type | Description |
|------|-------------|
| **Index Threshold** | Alert when index query meets threshold |
| **Metric Threshold** | Alert when metric meets threshold |
| **Elasticsearch Query** | Alert on ES query results |
| **Geothreshold** | Alert when entities cross boundaries |
| **ML Anomaly Detection** | Alert on ML anomalies |
| **Monitor Indicator** | Alert on metric indicators |

### Creating Alerts

```
# Example: Error rate alert

1. Go to Alerts → Create rule
2. Select type: "Index threshold"
3. Configure:
   - Index: logs-*
   - Time field: @timestamp
   - Threshold: When count > 100
   - Time window: Last 5 minutes
4. Add action:
   - Type: Email
   - To: admin@example.com
   - Subject: High error rate detected
   - Body: Error count exceeded threshold
5. Save and activate
```

### Action Types

| Type | Description |
|------|-------------|
| **Email** | Send email notification |
| **Slack** | Send Slack message |
| **Webhook** | HTTP POST to URL |
| **Index** | Write to Elasticsearch index |
| **Log** | Write to Kibana log |
| **Jira** | Create/update Jira issue |
| **PagerDuty** | Send PagerDuty alert |
| **Teams** | Send Microsoft Teams message |

### Alert Configuration

```json
{
  "name": "High Error Rate",
  "rule_type_id": ".index-threshold",
  "consumer": "alerts",
  "schedule": {
    "interval": "5m"
  },
  "params": {
    "index": "logs-*",
    "timeField": "@timestamp",
    "threshold": [100],
    "thresholdComparator": ">",
    "timeWindowSize": 5,
    "timeWindowUnit": "m",
    "groupBy": "top",
    "termField": "service",
    "termSize": 10
  },
  "actions": [
    {
      "group": "threshold met",
      "action_type_id": ".email",
      "params": {
        "to": ["admin@example.com"],
        "subject": "High Error Rate Alert",
        "body": "Error count exceeded threshold for service: {{context.term}}"
      }
    }
  ]
}
```

---

## 14. Index Pattern Management

### Creating Data Views

```
1. Go to Management → Stack Management → Index Patterns
2. Click "Create data view"
3. Enter name: logs-*
4. Select time field: @timestamp
5. Click "Create data view"
```

### Data View Configuration

```json
{
  "data_view": {
    "id": "logs-*",
    "title": "logs-*",
    "timeFieldName": "@timestamp",
    "fields": [
      {
        "name": "@timestamp",
        "type": "date",
        "searchable": true,
        "aggregatable": true
      },
      {
        "name": "message",
        "type": "text",
        "searchable": true,
        "aggregatable": false
      },
      {
        "name": "level",
        "type": "keyword",
        "searchable": true,
        "aggregatable": true
      }
    ]
  }
}
```

### Field Configuration

```
# Field formatting
Format:
  - Default
  - Bytes
  - Number
  - Percent
  - Currency
  - Date
  - URL
  - Image
  - Bytes
  - Duration
  - Number
  - Percent
  - Static lookup

# Custom labels
Label: "Error Level"
Description: "Log level field"

# Custom parameters
JSON: {"width": 200}
```

### Runtime Fields

```json
// Create runtime field
{
  "runtime_mappings": {
    "response_time_seconds": {
      "type": "double",
      "script": {
        "source": "emit(doc['response_time'].value / 1000.0)"
      }
    }
  }
}

// Use in query
GET /logs-*/_search
{
  "runtime_mappings": {
    "response_time_seconds": {
      "type": "double",
      "script": {
        "source": "emit(doc['response_time'].value / 1000.0)"
      }
    }
  },
  "query": {
    "range": {
      "response_time_seconds": {
        "gte": 1.0
      }
    }
  }
}
```

---

## 15. Security

### Enable Security

```yaml
# kibana.yml
xpack.security.enabled: true
xpack.security.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.security.session.idleTimeout: "1h"
xpack.security.session.lifespan: "24h"

# SSL
server.ssl.enabled: true
server.ssl.certificate: /path/to/cert.crt
server.ssl.key: /path/to/cert.key
```

### Role-Based Access Control

```json
// Create role
POST /_security/role/kibana_dashboard_user
{
  "indices": [
    {
      "names": ["logs-*", "metrics-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["feature_discover.read", "feature_dashboard.read"],
      "resources": ["*"]
    }
  ]
}

// Create user
POST /_security/user/john
{
  "password": "changeme",
  "roles": ["kibana_dashboard_user"],
  "full_name": "John Doe"
}
```

### Space-Based Access

```
# Spaces configuration
Space: Production
  - Dashboards: [prod-dashboard-1, prod-dashboard-2]
  - Visualizations: [prod-viz-1, prod-viz-2]
  - Index patterns: [logs-prod-*, metrics-prod-*]

Space: Development
  - Dashboards: [dev-dashboard-1]
  - Visualizations: [dev-viz-1]
  - Index patterns: [logs-dev-*, metrics-dev-*]
```

### Feature Controls

```json
// Disable features per space
{
  "disabledFeatures": [
    "ml",
    "canvas",
    "maps",
    "graphs",
    "shortUrl"
  ]
}
```

---

## 16. Advanced Features

### Dev Tools Console

```
# Query Elasticsearch
GET /_cluster/health
GET /logs-*/_search?size=10

# Create index
PUT /my-index
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}

# Index document
POST /my-index/_doc/1
{
  "message": "Hello World",
  "level": "INFO"
}
```

### Search Profiler

```
# Profile query
GET /logs-*/_search
{
  "profile": true,
  "query": {
    "match": {
      "message": "error"
    }
  }
}

# Shows:
# - Query timing
# - Breakdown by component
# - Shard-level details
```

### Painless Scripting

```painless
// Runtime field script
emit(doc['response_time'].value / 1000.0)

// Conditional logic
if (doc['level'].value == 'ERROR') {
  emit('error');
} else {
  emit('info');
}

// String manipulation
emit(doc['message'].value.toLowerCase())

// Date manipulation
emit(doc['@timestamp'].value.getHour())
```

### Reporting

```
# Generate PDF report
1. Go to Dashboard
2. Click Share → PDF Reports
3. Configure:
   - Title
   - Time range
   - Layout
   - Logo
4. Generate

# Schedule report
1. Go to Stack Management → Reporting
2. Create scheduled report
3. Configure:
   - Frequency
   - Recipients
   - Format
4. Save
```

### Canvas

```
# Canvas features
- Custom layouts
- Dynamic data
- Custom styling
- Elements:
  - Metric
  - Image
  - Markdown
  - Visualization
  - Filter
  - Map
  - Table
```

---

## 17. Troubleshooting

### Issue 1: Kibana Won't Start

```bash
# Check logs
tail -f /var/log/kibana/kibana.log

# Check Elasticsearch connection
curl -u elastic:changeme http://localhost:9200/_cluster/health

# Check port binding
ss -tlnp | grep 5601

# Check configuration
kibana --config /etc/kibana/kibana.yml

# Check permissions
ls -la /var/log/kibana/
ls -la /etc/kibana/
```

### Issue 2: Cannot Connect to Elasticsearch

```bash
# Check Elasticsearch status
curl -u elastic:changeme http://localhost:9200

# Check Kibana configuration
grep elasticsearch /etc/kibana/kibana.yml

# Check network connectivity
telnet localhost 9200
curl -I http://localhost:9200

# Check credentials
curl -u kibana_system:changeme http://localhost:9200
```

### Issue 3: Dashboard Not Loading

```bash
# Clear browser cache
Ctrl+Shift+Delete

# Check saved objects
Management → Saved Objects

# Export and reimport
Management → Saved Objects → Export

# Check index pattern
Management → Index Patterns
```

### Issue 4: Slow Queries

```bash
# Enable slow queries
# kibana.yml
logging.verbose: true

# Check query performance
Dev Tools → POST /logs-*/_search
{
  "profile": true,
  "query": { "match_all": {} }
}

# Optimize index
POST /logs-*/_forcemerge?max_num_segments=1
```

### Issue 5: Visualization Not Showing Data

```bash
# Check time range
Top right corner → Time picker

# Check filters
Discover → Check active filters

# Check index pattern
Management → Index Patterns → logs-*

# Check field mapping
Dev Tools → GET /logs-*/_mapping
```

### Issue 6: Authentication Failed

```bash
# Reset kibana_system password
POST /_security/user/kibana_system/_password
{
  "password": "new_password"
}

# Update kibana.yml
elasticsearch.password: "new_password"

# Restart Kibana
sudo systemctl restart kibana
```

### Issue 7: Memory Issues

```bash
# Check memory usage
ps aux | grep kibana

# Increase Node.js memory
# kibana.yml
node.options: "--max-old-space-size=4096"

# Check Elasticsearch memory
curl -u elastic:changeme http://localhost:9200/_cat/nodes?v&h=name,heap.percent
```

### Issue 8: SSL Certificate Errors

```bash
# Check certificate validity
openssl x509 -in /etc/kibana/cert.crt -noout -dates

# Check certificate chain
openssl verify -CAfile /etc/kibana/ca.crt /etc/kibana/cert.crt

# Regenerate certificates
bin/elasticsearch-certutil ca
bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12
```

### Issue 9: Export/Import Issues

```bash
# Check saved objects
curl -u elastic:changeme http://localhost:9200/.kibana/_search

# Export via API
POST /api/kibana/dashboards/export
{
  "objects": [
    {
      "type": "dashboard",
      "id": "my-dashboard"
    }
  ]
}

# Import via API
POST /api/kibana/dashboards/import
{
  "objects": [...]
}
```

### Issue 10: Reporting Issues

```bash
# Check reporting status
Management → Stack Management → Reporting

# Check report generation
curl -u elastic:changeme http://localhost:9200/.reporting-*/_search

# Generate test report
1. Go to Dashboard
2. Click Share → PDF Reports
3. Generate
```

### Issue 11: Alert Not Firing

```bash
# Check alert status
Alerts → Manage Rules

# Check action connectors
Stack Management → Connectors

# Test alert
1. Go to Alerts
2. Click on rule
3. Click "Run now"

# Check Elasticsearch query
Dev Tools → POST /logs-*/_count
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-5m"
      }
    }
  }
}
```

### Issue 12: ML Job Not Working

```bash
# Check ML job status
Machine Learning → Anomaly Detection → Jobs

# Check job data
Dev Tools → GET _ml/anomalydetection/my-job/_stats

# Check data feed
Dev Tools → GET _ml/datafeeds/datafeed-my-job

# Start job
Dev Tools → POST _ml/anomalydetection/my-job/_start
```

### Issue 13: Maps Not Loading

```bash
# Check map configuration
Management → Advanced Settings → Maps

# Check tile service
# Try different tile server

# Check geo_point field
Dev Tools → GET /logs-*/_mapping
```

### Issue 14: Space Issues

```bash
# Check spaces
Management → Stack Management → Spaces

# Switch space
Click space selector in top navigation

# Check space permissions
Management → Stack Management → Roles
```

### Issue 15: Upgrade Issues

```bash
# Check version compatibility
# Kibana version must match Elasticsearch version

# Upgrade process
1. Backup data
2. Stop Kibana
3. Install new version
4. Start Kibana
5. Check saved objects

# Check upgrade status
curl -u elastic:changeme http://localhost:9200/_cat/indices?v
```

---

## 18. Tips and Best Practices

### Tip 1: Use Data Views Wisely

```bash
# Good: Specific patterns
logs-2024.01.*
filebeat-*

# Bad: Too broad
*
logs-*
```

### Tip 2: Optimize Time Range

```
# Use appropriate time range
Last 15 minutes - for real-time monitoring
Last 24 hours - for daily analysis
Last 7 days - for weekly trends
Last 30 days - for monthly analysis
```

### Tip 3: Use Filters Effectively

```
# Pin frequently used filters
- level is ERROR
- service is "auth-service"

# Use filter context
level: "ERROR" and service: "auth"
```

### Tip 4: Create Reusable Dashboards

```
# Dashboard organization
- Overview Dashboard - High-level metrics
- Service Dashboard - Service-specific
- Error Dashboard - Error analysis
- Performance Dashboard - Response times
```

### Tip 5: Use Lens for Quick Visualizations

```
# Lens benefits
- Drag-and-drop
- Smart suggestions
- Quick to create
- Easy to modify
```

### Tip 6: Set Up Alerts

```
# Alert examples
- Error rate > 100 per minute
- Response time > 5 seconds
- Disk usage > 90%
- Service down
```

### Tip 7: Use Spaces for Organization

```
# Space examples
- Production - All prod dashboards
- Development - All dev dashboards
- Security - Security-related
- Team-specific - Team dashboards
```

### Tip 8: Export/Import Saved Objects

```bash
# Backup dashboards
Management → Saved Objects → Export

# Share dashboards
Management → Saved Objects → Import
```

### Tip 9: Use Time Series Visual Builder (TSVB)

```
# TSVB benefits
- Advanced time-series
- Multiple aggregations
- Math operations
- Color rules
```

### Tip 10: Optimize Query Performance

```bash
# Use filters instead of queries
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "level": "ERROR" } }
      ]
    }
  }
}

# Use source filtering
GET /logs-*/_search
{
  "_source": ["message", "level"]
}
```

### Tip 11: Create Effective Visualizations

```
# Visualization best practices
- Choose right chart type
- Use appropriate colors
- Label axes
- Add titles and descriptions
- Use consistent scales
```

### Tip 12: Use Canvas for Custom Reports

```
# Canvas benefits
- Custom layouts
- Dynamic data
- Branding
- PDF export
```

### Tip 13: Monitor Kibana Health

```bash
# Check status
curl -u elastic:changeme http://localhost:5601/api/status

# Check logs
tail -f /var/log/kibana/kibana.log
```

### Tip 14: Use Dev Tools for Debugging

```
# Dev Tools features
- Console for API calls
- Search Profiler for query analysis
- Grok Debugger for pattern testing
```

### Tip 15: Set Up User Roles

```bash
# Role examples
- dashboard_user: Can view dashboards
- dashboard_admin: Can edit dashboards
- ml_user: Can view ML jobs
- alert_user: Can manage alerts
```

### Tip 16: Use Kibana Query Language (KQL)

```
# KQL benefits
- More intuitive than Lucene
- Better autocomplete
- Field-level filtering
- Boolean operators
```

### Tip 17: Schedule Reports

```
# Report scheduling
- Daily summary
- Weekly overview
- Monthly report
- Ad-hoc reports
```

### Tip 18: Use Machine Learning

```
# ML use cases
- Anomaly detection
- Forecasting
- Outlier detection
- Classification
```

### Tip 19: Optimize Dashboard Loading

```
# Dashboard optimization
- Limit visualizations
- Use appropriate time ranges
- Cache frequently accessed data
- Use filters efficiently
```

### Tip 20: Document Your Dashboards

```
# Dashboard documentation
- Title: Clear and descriptive
- Description: What it shows
- Time range: Default time range
- Filters: Default filters
- Visualizations: What each shows
```

---

## 19. Command Reference

### Kibana CLI Commands

| Command | Description |
|---------|-------------|
| `kibana` | Start Kibana |
| `kibana --config path` | Start with config file |
| `kibana --port 5602` | Start on specific port |
| `kibana --host localhost` | Bind to specific host |
| `kibana --verbose` | Verbose logging |
| `kibana --quiet` | Quiet mode |
| `kibana --silent` | Silent mode |
| `kibana --version` | Show version |
| `kibana --help` | Show help |

### Kibana API Endpoints

```bash
# Status
GET /api/status

# Health
GET /api/health

# Saved Objects
GET /api/saved_objects/_find?type=dashboard
GET /api/saved_objects/dashboard/{id}
POST /api/saved_objects/dashboard
PUT /api/saved_objects/dashboard/{id}
DELETE /api/saved_objects/dashboard/{id}

# Export/Import
POST /api/kibana/dashboards/export
POST /api/kibana/dashboards/import

# Alerts
GET /api/alerting/rules
POST /api/alerting/rules
GET /api/alerting/rules/{id}

# Actions
GET /api/actions/connectors
POST /api/actions/connectors
GET /api/actions/connectors/{id}

# ML
GET /api/ml/anomaly_detectors
POST /api/ml/anomaly_detectors
GET /api/ml/anomaly_detectors/{id}

# Index Patterns
GET /api/data_views
POST /api/data_views
GET /api/data_views/{id}
PUT /api/data_views/{id}

# Fields
GET /api/data_views/{id}/fields
POST /api/data_views/{id}/fields
```

### Kibana Objects API

```bash
# List all dashboards
GET /api/saved_objects/_find?type=dashboard&per_page=100

# Export dashboard with all references
POST /api/kibana/dashboards/export
{
  "objects": [
    {
      "type": "dashboard",
      "id": "my-dashboard"
    }
  ]
}

# Import dashboard
POST /api/kibana/dashboards/import
{
  "objects": [...],
  "overwrite": true
}
```

---

## 20. Configuration Reference

### kibana.yml Complete Reference

```yaml
# ======================== Server ========================

# Server host and port
server.port: 5601
server.host: "0.0.0.0"
server.name: "kibana.example.com"

# Public base URL
server.publicBaseUrl: "https://kibana.example.com"

# Server SSL
server.ssl.enabled: false
server.ssl.certificate: /path/to/cert.crt
server.ssl.key: /path/to/cert.key
server.ssl.certificateAuthorities: ["/path/to/ca.crt"]
server.ssl.supportedProtocols: ["TLSv1.2", "TLSv1.3"]
server.ssl.clientAuthentication: "none"

# ======================== Elasticsearch ========================

# Elasticsearch hosts
elasticsearch.hosts: ["http://localhost:9200"]

# Authentication
elasticsearch.username: "kibana_system"
elasticsearch.password: "changeme"

# SSL
elasticsearch.ssl.enabled: false
elasticsearch.ssl.certificate: /path/to/es-cert.crt
elasticsearch.ssl.key: /path/to/es-cert.key
elasticsearch.ssl.certificateAuthorities: ["/path/to/es-ca.crt"]
elasticsearch.ssl.verificationMode: full

# ======================== Kibana ========================

# Kibana index
kibana.index: ".kibana"

# ======================== Logging ========================

logging.verbose: false
logging.dest: stdout
logging.quiet: false
logging.silent: false

# ======================== Security ========================

xpack.security.enabled: false
xpack.security.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.security.session.idleTimeout: "30m"
xpack.security.session.lifespan: "24h"
xpack.security.cookieName: "kibana-session"
xpack.security.secureCookies: false

# ======================== Encryption ========================

xpack.encryptedSavedObjects.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.reporting.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.security.encryptionKey: "min-32-byte-long-encryption-key-here!!"

# ======================== Monitoring ========================

xpack.monitoring.enabled: false
xpack.monitoring.ui.container.elasticsearch.enabled: false

# ======================== Machine Learning ========================

xpack.ml.enabled: false

# ======================== Alerting ========================

xpack.actions.enabled: true
xpack.actions.allowedHosts: ["*"]
xpack.actions.connector.email.smtp.host: "smtp.example.com"
xpack.actions.connector.email.smtp.port: 587
xpack.actions.connector.email.smtp.secure: false
xpack.actions.connector.email.smtp.user: "user@example.com"
xpack.actions.connector.email.smtp.password: "changeme"

# ======================== Reporting ========================

xpack.reporting.enabled: false
xpack.reporting.encryptionKey: "min-32-byte-long-encryption-key-here!!"
xpack.reporting.kibana.serverHostname: "localhost"
xpack.reporting.kibana.port: 5601
xpack.reporting.kibana.protocol: "http"
xpack.reporting.capture.browser.chromium.preferred: true
xpack.reporting.capture.timeouts.openUrl: "60s"
xpack.reporting.capture.timeouts.waitForElements: "60s"
xpack.reporting.capture.timeouts.waitForSelector: "30s"

# ======================== Saved Objects ========================

xpack.saved_objects.maxImportExportSize: 10000
xpack.saved_objects.maxImportPayloadBytes: 26214400

# ======================== Maps ========================

xpack.maps.enabled: false

# ======================== Canvas ========================

xpack.canvas.enabled: false

# ======================== Advanced ========================

# CUI settings
csp.strict: false
csp.warnLegacyBrowsers: true

# Telemetry
telemetry.enabled: true
telemetry.allowChangingOptInStatus: true

# Newsfeed
newsfeed.enabled: true

# Custom branding
branding.enabled: true
branding.applicationTitle: "My Kibana"
branding.loadingLogo.defaultUrl: ""
branding.loadingLogo.darkMode: ""
branding.mark.defaultUrl: ""
branding.mark.darkMode: ""
branding.favicon.defaultUrl: ""
branding.favicon.darkMode: ""
```

### Environment Variables Reference

```bash
# Server
SERVER_PORT=5601
SERVER_HOST=0.0.0.0
SERVER_NAME=kibana.example.com
SERVER_BASEPATH=/
SERVER_PUBLICBASEURL=https://kibana.example.com

# Elasticsearch
ELASTICSEARCH_HOSTS=http://localhost:9200
ELASTICSEARCH_USERNAME=kibana_system
ELASTICSEARCH_PASSWORD=changeme

# Security
XPACK_SECURITY_ENABLED=true
XPACK_SECURITY_ENCRYPTIONKEY=min-32-byte-long-encryption-key!!
XPACK_SECURITY_SESSION_IDLETIMEOUT=30m
XPACK_SECURITY_SESSION_LIFESPAN=24h

# Logging
LOGGING_VERBOSE=false
LOGGING_DEST=stdout
LOGGING_QUIET=false
LOGGING_SILENT=false

# SSL
SERVER_SSL_ENABLED=true
SERVER_SSL_CERTIFICATE=/path/to/cert.crt
SERVER_SSL_KEY=/path/to/cert.key
ELASTICSEARCH_SSL_ENABLED=true
ELASTICSEARCH_SSL_CERTIFICATE=/path/to/es-cert.crt
ELASTICSEARCH_SSL_KEY=/path/to/es-cert.key

# Monitoring
XPACK_MONITORING_ENABLED=true
XPACK_MONITORING_UI_CONTAINER_ELASTICSEARCH_ENABLED=true

# ML
XPACK_ML_ENABLED=true

# Alerting
XPACK_ACTIONS_ENABLED=true
XPACK_ACTIONS_ALLOWEDHOSTS=*
XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY=min-32-byte-long-encryption-key!!

# Reporting
XPACK_REPORTING_ENABLED=true
XPACK_REPORTING_ENCRYPTIONKEY=min-32-byte-long-encryption-key!!
XPACK_REPORTING_KIBANA_SERVERHOSTNAME=localhost
```

---

## 21. Real-World Examples

### Example 1: Application Monitoring Dashboard

```json
{
  "dashboard": {
    "title": "Application Monitoring",
    "description": "Monitor application performance and errors",
    "panels": [
      {
        "type": "visualization",
        "title": "Request Rate",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "count", "schema": "metric" },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Error Rate",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "count", "schema": "metric", "params": { "json": "{\"query\":{\"term\":{\"level\":\"ERROR\"}}}" } },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Response Time",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "avg", "schema": "metric", "params": { "field": "response_time" } },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Top Errors",
        "visState": {
          "type": "pie",
          "aggs": [
            { "type": "count", "schema": "metric" },
            { "type": "terms", "params": { "field": "error_type", "size": 10 }, "schema": "segment" }
          ]
        }
      }
    ]
  }
}
```

### Example 2: Security Dashboard

```json
{
  "dashboard": {
    "title": "Security Monitoring",
    "description": "Monitor security events and threats",
    "panels": [
      {
        "type": "visualization",
        "title": "Failed Logins",
        "visState": {
          "type": "metric",
          "aggs": [
            { "type": "count", "schema": "metric", "params": { "json": "{\"query\":{\"term\":{\"event_type\":\"authentication_failed\"}}}" } }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Attack Sources",
        "visState": {
          "type": "map",
          "params": {
            "mapType": "points",
            "geoField": "src_ip_geo.coordinates"
          }
        }
      },
      {
        "type": "visualization",
        "title": "Suspicious Activity",
        "visState": {
          "type": "table",
          "aggs": [
            { "type": "count", "schema": "metric" },
            { "type": "terms", "params": { "field": "src_ip", "size": 20 }, "schema": "bucket" },
            { "type": "terms", "params": { "field": "event_type", "size": 10 }, "schema": "bucket" }
          ]
        }
      }
    ]
  }
}
```

### Example 3: Infrastructure Monitoring

```json
{
  "dashboard": {
    "title": "Infrastructure Monitoring",
    "description": "Monitor servers and services",
    "panels": [
      {
        "type": "visualization",
        "title": "CPU Usage",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "avg", "schema": "metric", "params": { "field": "system.cpu.user.pct" } },
            { "type": "terms", "params": { "field": "host.name", "size": 10 }, "schema": "group" },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Memory Usage",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "avg", "schema": "metric", "params": { "field": "system.memory.actual.used.pct" } },
            { "type": "terms", "params": { "field": "host.name", "size": 10 }, "schema": "group" },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Disk Usage",
        "visState": {
          "type": "gauge",
          "aggs": [
            { "type": "max", "schema": "metric", "params": { "field": "system.filesystem.used.pct" } },
            { "type": "terms", "params": { "field": "host.name", "size": 10 }, "schema": "segment" }
          ]
        }
      }
    ]
  }
}
```

### Example 4: Business Analytics Dashboard

```json
{
  "dashboard": {
    "title": "Business Analytics",
    "description": "Track business metrics and KPIs",
    "panels": [
      {
        "type": "visualization",
        "title": "Daily Active Users",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "cardinality", "schema": "metric", "params": { "field": "user_id" } },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1d" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Revenue",
        "visState": {
          "type": "area",
          "aggs": [
            { "type": "sum", "schema": "metric", "params": { "field": "order_total" } },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1d" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Top Products",
        "visState": {
          "type": "pie",
          "aggs": [
            { "type": "sum", "schema": "metric", "params": { "field": "quantity" } },
            { "type": "terms", "params": { "field": "product_name", "size": 10 }, "schema": "segment" }
          ]
        }
      }
    ]
  }
}
```

### Example 5: Kubernetes Monitoring

```json
{
  "dashboard": {
    "title": "Kubernetes Monitoring",
    "description": "Monitor Kubernetes cluster and pods",
    "panels": [
      {
        "type": "visualization",
        "title": "Pod CPU Usage",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "avg", "schema": "metric", "params": { "field": "kubernetes.pod.cpu.usage.core.ns" } },
            { "type": "terms", "params": { "field": "kubernetes.pod.name", "size": 20 }, "schema": "group" },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Pod Memory Usage",
        "visState": {
          "type": "line",
          "aggs": [
            { "type": "avg", "schema": "metric", "params": { "field": "kubernetes.pod.memory.usage.bytes" } },
            { "type": "terms", "params": { "field": "kubernetes.pod.name", "size": 20 }, "schema": "group" },
            { "type": "date_histogram", "params": { "field": "@timestamp", "interval": "1m" }, "schema": "segment" }
          ]
        }
      },
      {
        "type": "visualization",
        "title": "Pod Status",
        "visState": {
          "type": "pie",
          "aggs": [
            { "type": "count", "schema": "metric" },
            { "type": "terms", "params": { "field": "kubernetes.pod.status.phase", "size": 5 }, "schema": "segment" }
          ]
        }
      }
    ]
  }
}
```

---

## 22. Further Reading

### Official Documentation

- [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Kibana API Reference](https://www.elastic.co/guide/en/kibana/current/api.html)
- [Kibana Developer Guide](https://www.elastic.co/guide/en/kibana/current/development.html)
- [Kibana Security](https://www.elastic.co/guide/en/kibana/current/security.html)

### Books

- *Elasticsearch in Action* (Kibana chapters)
- *Elasticsearch 7.x Cookbook* (Kibana recipes)
- *Kibana 7.x Quick Start Guide*

### Online Resources

- [Elastic Blog](https://www.elastic.co/blog)
- [Kibana Discuss Forums](https://discuss.elastic.co/c/kibana)
- [Kibana GitHub](https://github.com/elastic/kibana)
- [Elastic YouTube](https://www.youtube.com/elastic)

### Related Tools

- [Elasticsearch](https://www.elastic.co/elasticsearch/) — Search engine
- [Logstash](https://www.elastic.co/products/logstash) — Data processing
- [Beats](https://www.elastic.co/beats) — Data shippers
- [APM](https://www.elastic.co/apm) — Application monitoring
- [Fleet](https://www.elastic.co/elastic-agent) — Agent management
- [SIEM](https://www.elastic.co/security) — Security analytics

### Community

- [Elastic Community](https://www.elastic.co/community)
- [Elastic Slack](https://elasticstack.herokuapp.com/)
- [Elastic User Groups](https://www.elastic.co/community/groups)
