# Grafana Complete Guide

## Table of Contents

1. [What Is Grafana](#1-what-is-grafana)
2. [Why Use Grafana](#2-why-use-grafana)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Data Sources](#7-data-sources)
8. [Dashboards](#8-dashboards)
9. [Panels and Visualizations](#9-panels-and-visualizations)
10. [Usage Guide (Step-by-Step)](#10-usage-guide-step-by-step)
11. [Alerting](#11-alerting)
12. [Provisioning](#12-provisioning)
13. [Plugins](#13-plugins)
14. [Templating and Variables](#14-templating-and-variables)
15. [Integrations](#15-integrations)
16. [Security](#16-security)
17. [Performance Optimization](#17-performance-optimization)
18. [Troubleshooting](#18-troubleshooting)
19. [Tips and Best Practices](#19-tips-and-best-practices)
20. [Command Reference](#20-command-reference)
21. [Configuration Reference](#21-configuration-reference)
22. [Real-World Examples](#22-real-world-examples)
23. [Further Reading](#23-further-reading)

---

## 1. What Is Grafana

Grafana is an open-source analytics and interactive visualization platform that provides charts, graphs, and alerts when connected to supported data sources. It is the most popular dashboarding tool for DevOps, SRE, and platform engineering teams. Grafana does not store metric data itself; instead, it connects to databases like Prometheus, Elasticsearch, InfluxDB, Loki, and many others to visualize their contents.

### Key Features

- **Multi-data-source support**: Connect to 100+ data sources (Prometheus, Loki, Elasticsearch, MySQL, PostgreSQL, CloudWatch, etc.)
- **Rich visualization**: Time series, bar charts, pie charts, heatmaps, geomaps, tables, logs, traces, and more
- **Alerting**: Unified alerting with rules, contact points, and notification policies
- **Templating**: Dynamic dashboards with variables for filtering
- **Annotations**: Mark events on dashboards from alerts, deployments, or manual input
- **Explore mode**: Ad-hoc querying across all data sources
- **Correlations**: Link queries across data sources (logs to traces, metrics to logs)
- **Recording rules**: Precompute frequently used queries
- **Plugin ecosystem**: 180+ community and enterprise plugins
- **Teams and permissions**: Fine-grained access control
- **Provisioning**: Manage dashboards, data sources, and alerts as code

### Editions

| Feature | Open Source | Enterprise | Cloud |
|---------|-------------|------------|-------|
| Dashboards | Yes | Yes | Yes |
| Alerting | Yes | Yes | Yes |
| RBAC | Basic | Advanced | Advanced |
| SAML/OAuth | No | Yes | Yes |
| Reporting | No | Yes | Yes |
| Tempo/Mimir | Yes | Yes | Yes |
| Support | Community | Official | Official |

### Version History (Key Milestones)

- **5.0** (2018): Dashboard folders, organizations
- **6.0** (2019): React migration, Explore mode
- **7.0** (2020): Unified alerting, bar gauge panel
- **8.0** (2021): Live data, transformations
- **9.0** (2022): Unified alerting GA, expression editor
- **10.0** (2023): Correlations, improved dashboard management
- **11.0** (2024): Playlist improvements, Grafana 11 features

---

## 2. Why Use Grafana

### Advantages

- **Universal data source support**: One dashboard can show data from Prometheus, Loki, Elasticsearch, and MySQL simultaneously.
- **Beautiful visualizations**: Professional-grade charts and graphs out of the box.
- **Active community**: Thousands of community dashboards and plugins.
- **Flexible deployment**: Docker, Kubernetes, bare metal, cloud-managed.
- **Free and open source**: Core functionality is free; Enterprise adds RBAC, reporting, and SSO.
- **Declarative provisioning**: Manage everything as code with YAML provisioning files.
- **Correlations**: Link metrics to logs to traces for full observability.
- **Templating**: Build interactive dashboards that users can filter dynamically.

### When to Use Grafana

- Centralized monitoring for multiple data sources
- Executive dashboards and status pages
- Real-time operations dashboards
- Troubleshooting with correlated metrics, logs, and traces
- Capacity planning and trend analysis
- SLA/SLO monitoring and reporting

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                    Grafana                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │Dashboard │  │Alerting  │  │  Explore     │  │
│  │Engine    │  │Engine    │  │  Mode        │  │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │
│       │              │               │           │
│  ┌────┴──────────────┴───────────────┴───────┐  │
│  │           Query Engine / Data Proxy        │  │
│  └───────────────────┬───────────────────────┘  │
└──────────────────────┼──────────────────────────┘
                       │
         ┌─────────────┼─────────────────┐
         │             │                 │
    ┌────┴────┐  ┌─────┴─────┐  ┌───────┴──────┐
    │Prometheus│  │   Loki    │  │ Elasticsearch│
    └─────────┘  └───────────┘  └──────────────┘
```

### Storage

Grafana stores:
- **Dashboards**: JSON files in the database (SQLite, MySQL, PostgreSQL)
- **Data sources**: Configuration in the database
- **Users and organizations**: Database records
- **Alert rules and contact points**: Database records

Grafana does NOT store metric data; it queries upstream data sources on demand.

### Components

- **Frontend**: React-based SPA served by the Grafana server
- **Backend**: Go server handling API, provisioning, alerting, and data proxy
- **Database**: SQLite (default), MySQL, or PostgreSQL for configuration storage
- **Plugins**: Angular and React panel/app/data source plugins

---

## 4. Installation

### Docker

```bash
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -v grafana_data:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:11.0.0
```

### Docker Compose

```yaml
version: '3.8'
services:
  grafana:
    image: grafana/grafana:11.0.0
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning
      - ./dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    restart: unless-stopped

volumes:
  grafana_data:
```

### Debian/Ubuntu

```bash
sudo apt-get install -y apt-transport-https software-properties-common wget
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### RPM/CentOS/RHEL

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.grafana.com
sudo yum install grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Kubernetes (Helm)

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana \
  --namespace monitoring \
  --create-namespace \
  --set adminPassword=admin \
  --set persistence.enabled=true
```

### Kubernetes (Operator)

```bash
kubectl apply -f https://github.com/grafana/grafana-operator/releases/latest/download/deploy.yaml
```

### Verifying Installation

```bash
# Check version
grafana-server -v

# Check health
curl http://localhost:3000/api/health

# Check logs
journalctl -u grafana-server -f
```

### Default Credentials

- **URL**: http://localhost:3000
- **Username**: admin
- **Password**: admin (change on first login)

---

## 5. Configuration

### Configuration File Locations

| Platform | Default Path |
|----------|-------------|
| Linux | `/etc/grafana/grafana.ini` |
| Docker | `/etc/grafana/grafana.ini` |
| Homebrew | `/usr/local/etc/grafana/grafana.ini` |
| Windows | `C:\Program Files\Grafana\conf\grafana.ini` |

### Key Configuration Sections

```ini
[server]
protocol = http
http_addr = 0.0.0.0
http_port = 3000
domain = grafana.example.com
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = false

[database]
type = sqlite3
path = /var/lib/grafana/grafana.db

[security]
admin_user = admin
admin_password = admin
secret_key = SW2YcwTIb9zpO1hA
cookie_secure = true
cookie_samesite = lax
allow_embedding = false
content_security_policy = true

[auth]
disable_login_form = false
disable_signout_menu = false
login_maximum_inactive_lifetime_duration = 7d
login_maximum_lifetime_duration = 30d

[auth.google]
enabled = false
client_id = CLIENT_ID
client_secret = CLIENT_SECRET
allowed_domains = example.com

[auth.github]
enabled = false
client_id = CLIENT_ID
client_secret = CLIENT_SECRET
allowed_organizations = my-org

[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Viewer

[log]
mode = console file
level = info
filters = rendering:debug

[metrics]
enabled = true
interval_seconds = 60

[unified_alerting]
enabled = true
max_attempts = 3

[alerting]
enabled = false
```

### Environment Variables

```bash
# Override any config key with GF_ prefix
GF_SERVER_HTTP_PORT=8080
GF_SECURITY_ADMIN_PASSWORD=secret
GF_DATABASE_TYPE=mysql
GF_DATABASE_HOST=mysql:3306
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=grafana
GF_DATABASE_PASSWORD=secret
```

### Anonymous Access

```ini
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer
hide_version = true
```

---

## 6. Core Concepts

### Organizations

- Top-level isolation unit
- Each org has its own dashboards, data sources, and users
- Users can belong to multiple organizations
- Default org is "Main Org."

### Teams

- Groups of users within an organization
- Permissions can be assigned to teams
- Members inherit team permissions

### Roles

| Role | Permissions |
|------|-------------|
| Viewer | Read-only access to dashboards |
| Editor | Can create and edit dashboards |
| Admin | Full access including settings and users |
| Grafana Admin | Server-wide administration |

### Dashboards

A dashboard is a collection of panels arranged in a grid layout. Dashboards are stored as JSON and can be versioned, exported, and imported.

### Panels

A panel is a single visualization in a dashboard. Each panel:
- Queries one or more data sources
- Applies transformations
- Renders using a visualization type
- Has its own title, description, and links

### Data Models

- **Datasource**: Connection to an external data store
- **Query**: Request to a data source for specific data
- **Transformation**: Operation applied to query results
- **Annotation**: Event markers on panels
- **Variable**: Dynamic placeholder for dashboard filtering

### Dashboard JSON Model

```json
{
  "id": null,
  "uid": "my-dashboard",
  "title": "My Dashboard",
  "tags": ["infrastructure"],
  "timezone": "browser",
  "refresh": "30s",
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "templating": {
    "list": []
  },
  "panels": [],
  "schemaVersion": 38
}
```

---

## 7. Data Sources

### Supported Data Sources

| Data Source | Type | Use Case |
|-------------|------|----------|
| Prometheus | Metrics | Infrastructure and app monitoring |
| Loki | Logs | Log aggregation |
| Tempo | Traces | Distributed tracing |
| Elasticsearch | Logs/Metrics | Full-text search, APM |
| MySQL | SQL | Relational data |
| PostgreSQL | SQL | Relational data |
| InfluxDB | Time Series | IoT, sensor data |
| CloudWatch | AWS Metrics | AWS infrastructure |
| Azure Monitor | Azure Metrics | Azure infrastructure |
| Google Cloud Monitoring | GCP Metrics | GCP infrastructure |
| Jaeger | Traces | Distributed tracing |
| Zipkin | Traces | Distributed tracing |
| OpenSearch | Logs | Search and analytics |
| Graphite | Metrics | Legacy monitoring |
| Microsoft SQL Server | SQL | Enterprise databases |

### Adding a Data Source

1. Navigate to **Settings → Data Sources**
2. Click **Add data source**
3. Select the type
4. Configure connection details
5. Click **Save & Test**

### Data Source Configuration (Prometheus)

```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "timeInterval": "15s",
    "httpMethod": "POST",
    "exemplarTraceIdDestinations": [
      {
        "name": "traceID",
        "datasourceUid": "tempo"
      }
    ]
  },
  "secureJsonFields": {}
}
```

### Mixed Data Sources

A panel can query multiple data sources:

1. In the query editor, select **Mixed** from the data source dropdown
2. Add multiple queries, each specifying a different data source
3. Apply transformations to combine results

---

## 8. Dashboards

### Creating Dashboards

1. Click **+ → Dashboard**
2. Add panels using the **Add** button
3. Configure each panel with queries and visualization
4. Arrange panels by dragging and resizing
5. Set dashboard variables for filtering
6. Save with a name and folder

### Dashboard Management

- **Folders**: Organize dashboards into logical groups
- **Favorites**: Star dashboards for quick access
- **Recent**: View recently visited dashboards
- **Search**: Filter by name, tag, or folder

### Importing Dashboards

1. Click **+ → Import**
2. Paste the dashboard JSON or enter the Grafana.com ID
3. Select the target data source
4. Click **Import**

### Exporting Dashboards

1. Open dashboard settings (gear icon)
2. Click **JSON Model**
3. Copy the JSON for sharing or version control

### Dashboard Versioning

Grafana automatically versions dashboards:
- View history under **Settings → Version History**
- Compare versions to see changes
- Restore previous versions

### Dashboard Links

```json
{
  "links": [
    {
      "title": "Overview",
      "type": "dashboards",
      "tags": ["overview"],
      "icon": "external link",
      "url": "",
      "asDropdown": false,
      "targetBlank": true
    }
  ]
}
```

---

## 9. Panels and Visualizations

### Visualization Types

| Type | Best For |
|------|----------|
| Time series | Trend analysis over time |
| Stat | Single important number |
| Gauge | Value within a range |
| Bar gauge | Multiple gauges in a row |
| Bar chart | Comparing categories |
| Pie chart | Part-of-whole |
| Table | Tabular data |
| Heatmap | Density over time |
| Logs | Log line display |
| Traces | Distributed trace visualization |
| State timeline | State changes over time |
| Status history | Periodic status snapshots |
| Geomap | Geographic data |
| Canvas | Custom layouts |

### Panel Configuration

```json
{
  "id": 1,
  "title": "CPU Usage",
  "type": "timeseries",
  "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
  "datasource": {
    "type": "prometheus",
    "uid": "prometheus"
  },
  "targets": [
    {
      "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "{{ instance }}",
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "thresholds": {
        "steps": [
          { "color": "green", "value": null },
          { "color": "yellow", "value": 70 },
          { "color": "red", "value": 90 }
        ]
      }
    }
  },
  "options": {
    "legend": { "displayMode": "table", "placement": "bottom" },
    "tooltip": { "mode": "multi" }
  }
}
```

### Grid Positions

Panels are arranged on a 24-column grid:

```json
{
  "h": 8,   // Height in grid units (each = 30px)
  "w": 12,  // Width in grid units (24 = full width)
  "x": 0,   // Horizontal position (0-23)
  "y": 0    // Vertical position
}
```

### Transformations

Transformations modify query results before visualization:

| Transformation | Purpose |
|----------------|---------|
| Reduce | Aggregate all values into a single value per series |
| Filter by name | Include/exclude fields by name |
| Filter by value | Include/exclude rows by value |
| Organize fields | Rename, hide, or reorder fields |
| Join by field | Merge results from multiple queries |
| Calculate | Create new fields with math |
| Group by | Aggregate rows by field |
| Sort by | Sort results by field |
| Rename by regex | Rename fields using regex |
| Labels to fields | Convert label values to table columns |

### Value Mappings

Map data values to display text and colors:

```json
{
  "mappings": [
    { "type": "value", "options": { "0": { "text": "Down", "color": "red" } } },
    { "type": "value", "options": { "1": { "text": "Up", "color": "green" } } },
    { "type": "range", "options": { "from": 0, "to": 50, "result": { "text": "Low" } } }
  ]
}
```

---

## 10. Usage Guide (Step-by-Step)

### Step 1: First Login

1. Navigate to `http://localhost:3000`
2. Log in with admin/admin
3. Change the admin password
4. Skip or complete the getting started wizard

### Step 2: Add a Data Source

1. Go to **Settings → Data Sources → Add data source**
2. Select **Prometheus**
3. Set URL to `http://prometheus:9090`
4. Click **Save & Test** (should show "Data source is working")

### Step 3: Create Your First Dashboard

1. Click **+ → New Dashboard**
2. Click **Add visualization**
3. Select your Prometheus data source
4. Enter a PromQL query: `rate(http_requests_total[5m])`
5. Set visualization to **Time series**
6. Click **Apply**
7. Resize and position the panel
8. Click **Save dashboard** (disk icon)

### Step 4: Add Dashboard Variables

1. Open dashboard **Settings → Variables**
2. Click **Add variable**
3. Configure:
   - Name: `instance`
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(http_requests_total, instance)`
4. Click **Apply**
5. Use `$instance` in queries: `rate(http_requests_total{instance="$instance"}[5m])`

### Step 5: Add Annotations

1. Open dashboard **Settings → Annotations**
2. Click **Add annotation query**
3. Configure:
   - Name: Deployments
   - Data source: Prometheus
   - Query: `deployment_events`
4. Events appear as vertical lines on the dashboard

### Step 6: Create Alert Rules

1. Go to **Alerting → Alert rules → New alert rule**
2. Select data source and query
3. Set condition (e.g., average > 80 for 5 minutes)
4. Configure labels and annotations
5. Choose a notification policy or contact point
6. Click **Save rule and exit**

### Step 7: Share the Dashboard

1. Click **Share** (top-right)
2. Snapshot: Creates a static, shareable snapshot
3. Link: Generate a link with options
4. Export: Download as JSON

### Step 8: Use Explore Mode

1. Click **Explore** (compass icon)
2. Select a data source
3. Write a PromQL query
4. Switch between Table, Time series, and Logs views
5. Use this for ad-hoc debugging

---

## 11. Alerting

### Unified Alerting Architecture

```
┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│  Alert Rules │ ──▶ │ Alertmanager   │ ──▶ │  Contact     │
│  (Evaluation)│     │ (Grouping,     │     │  Points      │
│              │     │  Routing)      │     │  (Slack,     │
│              │     │                │     │   Email,     │
│              │     │                │     │   PagerDuty) │
└──────────────┘     └────────────────┘     └──────────────┘
```

### Alert Rule Types

1. **Grafana-managed**: Evaluated by Grafana, can query multiple data sources
2. **Data source-managed**: Evaluated by the data source (e.g., Prometheus rules)

### Creating Alert Rules

```yaml
# Via provisioning
apiVersion: 1
groups:
  - orgId: 1
    name: Infrastructure
    folder: alerts
    interval: 1m
    rules:
      - uid: high-cpu-alert
        title: High CPU Usage
        condition: C
        data:
          - refId: A
            datasourceUid: prometheus
            model:
              expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
              legendFormat: "{{ instance }}"
          - refId: B
            datasourceUid: __expr__
            model:
              type: reduce
              expression: A
              reducer: mean
          - refId: C
            datasourceUid: __expr__
            model:
              type: threshold
              expression: B
              conditions:
                - evaluator:
                    type: gt
                    params: [85]
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
        execErrState: Error
        noDataState: NoData
```

### Contact Points

```yaml
apiVersion: 1
contactPoints:
  - orgId: 1
    name: Slack
    receivers:
      - uid: slack-channel
        type: slack
        settings:
          url: https://hooks.slack.com/services/xxx/yyy/zzz
          recipient: "#alerts"
          title: |
            {{ len .Alerts.Firing }} firing alert(s)
          text: |
            {{ range .Alerts }}
            *{{ .Labels.alertname }}*: {{ .Annotations.summary }}
            {{ end }}
```

### Notification Policies

```yaml
apiVersion: 1
policies:
  - orgId: 1
    receiver: Slack
    group_by: ['alertname', 'namespace']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    routes:
      - receiver: PagerDuty
        matchers:
          - severity = critical
        group_wait: 10s
        repeat_interval: 1h
```

### Silences

Silences suppress notifications for a specified period:

1. Go to **Alerting → Silences → New silence**
2. Set matchers (e.g., `alertname = HighCPU`)
3. Set start and end time
4. Add a reason

### muteTimeIntervals

```yaml
apiVersion: 1
muteTimeIntervals:
  - name: maintenance-window
    timeIntervals:
      - times:
          - start_time: '02:00'
            end_time: '04:00'
        weekdays: ['saturday', 'sunday']
```

---

## 12. Provisioning

### Provisioning Directory Structure

```
/etc/grafana/provisioning/
├── datasources/
│   └── datasources.yaml
├── dashboards/
│   └── dashboards.yaml
├── alerting/
│   ├── alert_rules.yaml
│   ├── contact_points.yaml
│   └── notification_policies.yaml
├── notifiers/
│   └── notifiers.yaml
└── plugins/
    └── apps.yaml
```

### Data Source Provisioning

```yaml
# /etc/grafana/provisioning/datasources/datasources.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      timeInterval: 15s
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false
```

### Dashboard Provisioning

```yaml
# /etc/grafana/provisioning/dashboards/dashboards.yaml
apiVersion: 1
providers:
  - name: Infrastructure
    orgId: 1
    folder: Infrastructure
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards/infrastructure
      foldersFromFilesStructure: false
```

### Alert Provisioning

```yaml
# /etc/grafana/provisioning/alerting/alert_rules.yaml
apiVersion: 1
groups:
  - orgId: 1
    name: Default
    folder: alerts
    interval: 1m
    rules:
      - uid: node-down
        title: Node Down
        condition: C
        data:
          - refId: A
            datasourceUid: prometheus
            model:
              expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Node {{ $labels.instance }} is down"
```

---

## 13. Plugins

### Plugin Types

- **Panels**: New visualization types (pie chart, plotly, etc.)
- **Data sources**: Connect to new databases
- **Apps**: Full applications within Grafana
- **Provisioning**: Configuration management

### Installing Plugins

```bash
# CLI
grafana-cli plugins install grafana-piechart-panel
grafana-cli plugins install grafana-worldmap-panel
grafana-cli plugins install grafana-clock-panel

# List installed plugins
grafana-cli plugins ls

# Update plugins
grafana-cli plugins update-all

# Remove a plugin
grafana-cli plugins uninstall grafana-piechart-panel
```

### Docker Plugin Installation

```yaml
environment:
  - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
```

### Popular Plugins

| Plugin | Type | Purpose |
|--------|------|---------|
| Pie Chart | Panel | Pie and donut charts |
| Worldmap | Panel | Geographic visualization |
| Clock | Panel | Show current time |
| Stat Panel | Panel | Single value display |
| Business Charts | Panel | ECharts visualizations |
| Flow Charting | Panel | Diagrams and flowcharts |
| Postgres | Data source | PostgreSQL queries |
| MQTT | Data source | IoT data |
| Grafana-ATM | App | ATM monitoring |

---

## 14. Templating and Variables

### Variable Types

| Type | Description |
|------|-------------|
| Query | Populated from a data source query |
| Custom | User-defined list of options |
| Text box | Free-form text input |
| Interval | Time range intervals |
| Data source | Data source selector |
| Constant | Fixed value |
| Ad hoc filters | Key-value pair filters |

### Creating Variables

1. Go to **Settings → Variables**
2. Click **Add variable**
3. Configure the variable

### Variable Configuration

```yaml
# Query variable
name: instance
type: query
query: label_values(http_requests_total, instance)
datasource: Prometheus
refresh: On time range change
regex: /(.+):.*/    # Extract host from host:port
includeAll: true
multi: true
allValue: '.*'
sort: 1    # Alphabetical asc

# Custom variable
name: environment
type: custom
query: production,staging,development
includeAll: false

# Interval variable
name: interval
type: interval
query: 1m,5m,15m,30m,1h
auto_min_interval: 1m
auto: true
```

### Using Variables in Queries

```promql
# Basic usage
rate(http_requests_total{instance="$instance"}[5m])

# Multiple values
rate(http_requests_total{instance=~"$instance"}[5m])

# Regex matching
rate(http_requests_total{job=~"$job"}[5m])

# Variable in legend
rate(http_requests_total{job="$job"}[5m])
# Legend format: {{ instance }}
```

### Variable Syntax

| Syntax | Description |
|--------|-------------|
| `$variable` | Variable value |
| `${variable}` | Variable value (explicit) |
| `$__range` | Dashboard time range |
| `$__rate_interval` | Auto-calculated rate interval |
| `$__interval` | Dashboard interval |
| `$__timeFilter` | SQL time filter |
| `$__unixEpochFrom` | Start time as Unix timestamp |
| `$__unixEpochTo` | End time as Unix timestamp |

### Ad Hoc Filters

```promql
# Automatically applied to all queries
# User selects key-value pairs from a dropdown
rate(http_requests_total{job="$job", instance="$instance"}[5m])
# Ad hoc filter: status=500
# Becomes: rate(http_requests_total{job="$job", instance="$instance", status="500"}[5m])
```

---

## 15. Integrations

### Prometheus

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    jsonData:
      httpMethod: POST
      exemplarTraceIdDestinations:
        - name: traceID
          datasourceUid: tempo
```

### Loki

```yaml
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
    access: proxy
    jsonData:
      derivedFields:
        - name: TraceID
          matcherRegex: '"traceID":"(\w+)"'
          url: "$${__value.raw}"
          datasourceUid: tempo
```

### Tempo

```yaml
datasources:
  - name: Tempo
    type: tempo
    url: http://tempo:3200
    access: proxy
    jsonData:
      tracesToLogsV2:
        datasourceUid: loki
        filterByTraceID: true
      nodeGraph:
        enabled: true
```

### Alertmanager

```yaml
# grafana.ini
[unified_alerting]
enabled = true

[alertmanager]
# Grafana manages Alertmanager configuration via UI/provisioning
```

### Kubernetes

```yaml
# Helm chart values
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-kube-prometheus-prometheus:9090
        isDefault: true
```

### Cloud Providers

- **AWS CloudWatch**: Native integration for AWS metrics
- **Azure Monitor**: Native integration for Azure metrics
- **Google Cloud Monitoring**: Native integration for GCP metrics
- **Amazon Timestream**: Time series data from AWS

---

## 16. Security

### Authentication

```ini
# OAuth (Google)
[auth.google]
enabled = true
client_id = CLIENT_ID
client_secret = CLIENT_SECRET
allowed_domains = example.com
allow_sign_up = true

# OAuth (GitHub)
[auth.github]
enabled = true
client_id = CLIENT_ID
client_secret = CLIENT_SECRET
allowed_organizations = my-org

# LDAP
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml

# SAML (Enterprise)
[auth.saml]
enabled = true
certificate = /path/to/cert.pem
private_key = /path/to/key.pem
```

### Authorization

```ini
[roles]
# Default role for new users
auto_assign_org_role = Viewer

# Disable sign-up
[users]
allow_sign_up = false
```

### API Keys

```bash
# Create API key
curl -X POST http://admin:admin@localhost:3000/api/auth/keys \
  -H "Content-Type: application/json" \
  -d '{"name":"my-key","role":"Viewer","secondsToLive":3600}'
```

### HTTPS

```ini
[server]
protocol = https
cert_file = /etc/grafana/cert.pem
cert_key = /etc/grafana/key.pem
```

### Content Security Policy

```ini
[security]
content_security_policy = true
content_security_policy_template = "script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self';"
```

### Data Source Proxy

Grafana proxies data source requests through its backend, preventing direct access to internal data sources from the browser.

### CORS

```ini
[auth]
disable_login_form = false
```

---

## 17. Performance Optimization

### Dashboard Performance

- **Reduce panel count**: Aim for 6-10 panels per row, max 30 panels per dashboard
- **Use recording rules**: Precompute expensive queries in Prometheus
- **Increase refresh interval**: Use 30s or 60s instead of 5s for non-critical dashboards
- **Use template variables**: Filter data at query time
- **Limit time range**: Default to 6h instead of 30d
- **Disable auto-refresh**: Use manual refresh for most dashboards

### Query Performance

- **Use rate() correctly**: `[5m]` is usually sufficient
- **Avoid high cardinality labels**: Labels with thousands of values slow queries
- **Use recording rules**: Precompute `job:http_requests:rate5m`
- **Aggregate in queries**: Use `sum by (job)` to reduce result size

### Grafana Server Performance

```ini
[database]
# Use MySQL or PostgreSQL instead of SQLite for production
type = mysql
host = mysql:3306
name = grafana
user = grafana
password = secret

[caching]
enabled = true

[dataproxy]
timeout = 60
```

### Caching

```ini
[dataproxy]
# Enable caching for data source queries
[cache]
enabled = true
backend = memory
memcached = []
ttl = 15m
```

### Alerting Performance

- Use grouping to batch alerts
- Set appropriate `group_wait` and `repeat_interval`
- Avoid excessive label cardinality in alert rules

---

## 18. Troubleshooting

### Issue 1: Cannot Log In

**Symptoms**: Login page shows "Invalid username or password"

**Resolution**:
```bash
# Reset admin password
grafana-cli admin reset-admin-password newpassword

# Check grafana.ini for auth configuration
cat /etc/grafana/grafana.ini | grep -A5 "\[auth\]"

# Check logs for auth errors
journalctl -u grafana-server | grep -i auth
```

### Issue 2: Dashboard Not Loading

**Symptoms**: Dashboard shows "Dashboard not found" or empty panels

**Resolution**:
```bash
# Check Grafana logs
journalctl -u grafana-server | tail -50

# Verify data source connectivity
curl http://localhost:3000/api/datasources

# Test data source from Grafana
curl http://localhost:3000/api/ds/query -d '{"queries":[{"datasource":{"type":"prometheus","uid":"prometheus"},"expr":"up"}]}'
```

### Issue 3: Data Source Connection Refused

**Symptoms**: "Data source is not working" error

**Resolution**:
```bash
# Check data source URL
curl http://prometheus:9090/-/healthy

# Check Grafana can reach the data source
docker exec grafana curl http://prometheus:9090/-/healthy

# Check network (Docker)
docker network ls
docker inspect grafana | grep NetworkMode
```

### Issue 4: Panels Show "No data"

**Symptoms**: Panels render but show no data points

**Resolution**:
- Check time range selector (top-right)
- Verify the PromQL query in the panel editor
- Check that metrics exist: `curl 'http://prometheus:9090/api/v1/label/__name__/values'`
- Check data source permissions

### Issue 5: Slow Dashboard Loading

**Symptoms**: Dashboard takes >10 seconds to load

**Resolution**:
- Reduce the number of panels
- Use recording rules in Prometheus
- Increase refresh interval
- Use PostgreSQL instead of SQLite
- Enable caching

### Issue 6: Alert Rules Not Evaluating

**Symptoms**: Alert rules exist but never fire

**Resolution**:
```bash
# Check alerting is enabled
curl http://localhost:3000/api/v1/admin/stats | jq '.alerting'

# Check rule evaluation
curl http://localhost:3000/api/prometheus/grafana/api/v1/rules | jq

# Check Prometheus data source is working
curl 'http://localhost:3000/api/ds/query' -d '{"queries":[{"expr":"up","datasource":{"type":"prometheus"}}]}'
```

### Issue 7: Plugin Installation Fails

**Symptoms**: `grafana-cli plugins install` fails

**Resolution**:
```bash
# Check internet connectivity
curl -I https://grafana.com

# Check plugin directory permissions
ls -la /var/lib/grafana/plugins/
sudo chown -R grafana:grafana /var/lib/grafana/plugins/

# Manual installation
cd /var/lib/grafana/plugins/
unzip plugin.zip
```

### Issue 8: provisioning Not Working

**Symptoms**: Data sources or dashboards not appearing after provisioning

**Resolution**:
```bash
# Validate YAML
python -c "import yaml; yaml.safe_load(open('/etc/grafana/provisioning/datasources/datasources.yaml'))"

# Check Grafana logs for provisioning errors
journalctl -u grafana-server | grep -i provision

# Verify file paths in provisioning config
ls -la /var/lib/grafana/dashboards/
```

### Issue 9: Variable Not Populating

**Symptoms**: Dropdown variable shows "No options found"

**Resolution**:
- Check the variable query returns results: test in Explore mode
- Verify data source is correct
- Check regex is not filtering out all values
- Ensure `includeAll` and `multi` are configured correctly

### Issue 10: Annotation Not Showing

**Symptoms**: Annotations configured but not appearing on dashboard

**Resolution**:
- Verify the annotation query returns data
- Check time range includes annotation events
- Ensure the data source is correct
- Check annotation colors are visible

### Issue 11: Export/Import Issues

**Symptoms**: Dashboard JSON import fails or data sources are missing

**Resolution**:
- Ensure all referenced data sources exist
- Check for deprecated panel types
- Import with data source mapping if IDs don't match

### Issue 12: High Memory Usage

**Symptoms**: Grafana consuming excessive RAM

**Resolution**:
```bash
# Check connected dashboards
curl http://localhost:3000/api/search | jq 'length'

# Check active users
curl http://localhost:3000/api/admin/stats | jq '.active_users'

# Reduce concurrent queries
# grafana.ini
[dataproxy]
max_idle_connections_per_host = 5
```

### Issue 13: SSL Certificate Errors

**Symptoms**: "x509: certificate signed by unknown authority"

**Resolution**:
```ini
[dataproxy]
ssl_mode = skip-verify    # Not recommended for production

# Better: add CA certificate
[datasources]
tls_ca = /path/to/ca.crt
```

### Issue 14: Anonymous Access Not Working

**Symptoms**: Anonymous users cannot access dashboards

**Resolution**:
```ini
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer

[users]
auto_assign_org = true
auto_assign_org_role = Viewer
```

### Issue 15: Dashboard Variables Not Refreshing

**Symptoms**: Variables don't update when time range changes

**Resolution**:
- Set `refresh: On time range change` in variable settings
- Use `label_values()` with a time-aware query
- Check variable dependencies ( chained variables)

### Issue 16: Alert Notifications Not Received

**Symptoms**: Alerts fire but no notification arrives

**Resolution**:
```bash
# Check contact points
curl http://localhost:3000/api/v1/provisioning/contact-points | jq

# Check notification policies
curl http://localhost:3000/api/v1/provisioning/policies | jq

# Test a contact point
curl -X POST http://localhost:3000/api/alertmanager/grafana/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"Test","severity":"critical"}}]'
```

---

## 19. Tips and Best Practices

### 1. Use Dashboard Folders Organized by Team

```
Dashboards/
├── Infrastructure/
│   ├── Node Overview
│   ├── Kubernetes Cluster
│   └── Network
├── Application/
│   ├── API Server
│   ├── Database
│   └── Worker
└── Business/
    ├── Revenue
    └── User Activity
```

### 2. Keep Dashboards Focused

Each dashboard should answer one question: "How is my service performing?" Split into Overview, Detailed, and Capacity dashboards.

### 3. Use Consistent Naming

- Dashboards: `{Team} - {Service} - {Aspect}` (e.g., `Backend - API - Performance`)
- Panels: Describe what is shown (e.g., "P99 Latency by Endpoint")
- Variables: Use snake_case (e.g., `namespace`, `pod_name`)

### 4. Set Appropriate Time Ranges

- Operations: last 6h or 12h
- Debugging: last 1h or 30m
- Capacity planning: last 7d or 30d

### 5. Use Recording Rules for Expensive Queries

Precompute in Prometheus and query the recording rule in Grafana.

### 6. Template Everything

Use variables for namespaces, jobs, instances, and any filterable dimension.

### 7. Use Annotations for Deployments

Mark deployments, config changes, and incidents on dashboards for context.

### 8. Limit Panel Queries

Each panel should have 1-2 queries. More queries = slower rendering.

### 9. Use the Right Visualization

| Data Type | Visualization |
|-----------|---------------|
| Trends over time | Time series |
| Single value | Stat or Gauge |
| Comparison | Bar chart |
| Distribution | Heatmap or Histogram |
| Log search | Logs panel |
| Trace view | Traces panel |

### 10. Version Control Dashboards

Export dashboard JSON to Git and use provisioning for deployment.

### 11. Use Provisioning for Production

Never rely on the UI alone for production dashboards. Use YAML provisioning files.

### 12. Set Dashboard Links

Link related dashboards for easy navigation between overview and detail views.

### 13. Use Panels as Navigation

Use the Text panel with links to create dashboard menus.

### 14. Monitor Grafana Itself

Track `grafana_*` metrics to monitor dashboard performance, query latency, and error rates.

### 15. Use Library Panels

Create reusable panels that can be shared across dashboards.

### 16. Configure Alert Silence Maintenance Windows

Use `muteTimeIntervals` to suppress alerts during known maintenance windows.

### 17. Use Correlations for Full Observability

Link metrics → logs → traces for a complete debugging workflow.

---

## 20. Command Reference

### grafana-server

```bash
# Start Grafana server
grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini

# Run as a specific user
grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid
```

### grafana-cli

```bash
# Plugins
grafana-cli plugins install <plugin-id>
grafana-cli plugins uninstall <plugin-id>
grafana-cli plugins ls
grafana-cli plugins update-all
grafana-cli plugins list-remote

# Admin
grafana-cli admin reset-admin-password <new-password>
grafana-cli admin export-dashboard <dashboard-uid>

# Database
grafana-cli migrations ls
grafana-cli migrations ensure-version <version>

# Data
grafana-cli admin data-migration run
```

### API Examples

```bash
# Health check
curl http://localhost:3000/api/health

# List data sources
curl http://localhost:3000/api/datasources

# List dashboards
curl http://localhost:3000/api/search

# Get dashboard by UID
curl http://localhost:3000/api/dashboards/uid/<uid>

# Create dashboard
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d '{"dashboard":{"title":"Test"},"overwrite":true}'

# List alert rules
curl http://localhost:3000/api/prometheus/grafana/api/v1/rules

# List organizations
curl http://localhost:3000/api/orgs

# List users
curl http://localhost:3000/api/admin/users
```

---

## 21. Configuration Reference

### server Section

```ini
[server]
protocol = http                   # http, https, socket
http_addr = 0.0.0.0              # Listen address
http_port = 3000                 # Listen port
domain = localhost               # Domain name
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = false
static_root_path = public
enable_gzip = false
cert_file =                      # TLS certificate
cert_key =                       # TLS key
socket =                         # Unix socket path
```

### database Section

```ini
[database]
type = sqlite3           # sqlite3, mysql, postgres
path = grafana.db        # SQLite path
host =                   # MySQL/PostgreSQL host
name = grafana           # Database name
user =                   # Database user
password =               # Database password
ssl_mode = disable       # disable, require, verify-ca, verify-full
ca_cert_path =           # CA certificate
client_key_path =        # Client key
client_cert_path =       # Client certificate
max_idle_conn = 2
max_open_conn = -
conn_max_lifetime = 14400
```

### security Section

```ini
[security]
admin_user = admin
admin_password = admin
secret_key = SW2YcwTIb9zpO1hA
disable_gravatar = true
cookie_secure = false
cookie_samesite = lax
allow_embedding = false
strict_transport_security = false
content_security_policy = false
x_content_type_options = true
x_xss_protection = true
```

### users Section

```ini
[users]
allow_sign_up = true
auto_assign_org = true
auto_assign_org_role = Viewer
default_theme = dark
login_minimum_password_length = 8
password_lifetime = 0
```

### log Section

```ini
[log]
mode = console file        # console, file, syslog
level = info               # debug, info, warn, error, critical
filters =
file_name = grafana.log
file_max_lines = 1000000
file_max_size = 1000
file_max_days = 7
```

### unified_alerting Section

```ini
[unified_alerting]
enabled = true
max_attempts = 3
min_interval_seconds = 10
max_alerts_per_rule = 0
```

### dataproxy Section

```ini
[dataproxy]
timeout = 60
max_idle_connections_per_host = 100
max_concurrent_shard_requests = 50
```

---

## 22. Real-World Examples

### Example 1: Kubernetes Cluster Dashboard

```json
{
  "title": "Kubernetes Cluster Overview",
  "tags": ["kubernetes"],
  "panels": [
    {
      "title": "Cluster CPU Usage",
      "type": "timeseries",
      "targets": [{
        "expr": "sum(rate(container_cpu_usage_seconds_total{namespace!=\"\"}[5m]))",
        "legendFormat": "Total CPU Usage"
      }, {
        "expr": "sum(kube_node_status_allocatable{resource=\"cpu\"})",
        "legendFormat": "Allocatable CPU"
      }]
    },
    {
      "title": "Pod Count by Namespace",
      "type": "piechart",
      "targets": [{
        "expr": "count by (namespace) (kube_pod_info)",
        "legendFormat": "{{ namespace }}"
      }]
    },
    {
      "title": "Node Memory",
      "type": "bargauge",
      "targets": [{
        "expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100",
        "legendFormat": "{{ instance }}"
      }]
    }
  ],
  "templating": {
    "list": [{
      "name": "namespace",
      "type": "query",
      "query": "label_values(kube_pod_info, namespace)"
    }]
  }
}
```

### Example 2: Microservices Dashboard

```json
{
  "title": "Microservices Overview",
  "panels": [
    {
      "title": "Request Rate by Service",
      "type": "timeseries",
      "targets": [{
        "expr": "sum(rate(http_requests_total[5m])) by (job)",
        "legendFormat": "{{ job }}"
      }]
    },
    {
      "title": "Error Rate by Service",
      "type": "timeseries",
      "targets": [{
        "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (job) / sum(rate(http_requests_total[5m])) by (job) * 100",
        "legendFormat": "{{ job }}"
      }]
    },
    {
      "title": "P99 Latency",
      "type": "timeseries",
      "targets": [{
        "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job))",
        "legendFormat": "{{ job }}"
      }]
    }
  ]
}
```

### Example 3: Database Performance Dashboard

```json
{
  "title": "PostgreSQL Performance",
  "panels": [
    {
      "title": "Active Connections",
      "type": "stat",
      "targets": [{
        "expr": "sum(pg_stat_activity_count)",
        "legendFormat": "Active"
      }]
    },
    {
      "title": "Queries per Second",
      "type": "timeseries",
      "targets": [{
        "expr": "rate(pg_stat_database_xact_commit[5m]) + rate(pg_stat_database_xact_rollback[5m])",
        "legendFormat": "{{ datname }}"
      }]
    },
    {
      "title": "Cache Hit Ratio",
      "type": "gauge",
      "targets": [{
        "expr": "pg_stat_database_blks_hit / (pg_stat_database_blks_hit + pg_stat_database_blks_read) * 100",
        "legendFormat": "{{ datname }}"
      }]
    }
  ]
}
```

### Example 4: SLO Dashboard

```json
{
  "title": "Service SLOs",
  "panels": [
    {
      "title": "Availability SLO (99.9%)",
      "type": "gauge",
      "targets": [{
        "expr": "1 - (sum(rate(http_requests_total{status=~\"5..\"}[30d])) / sum(rate(http_requests_total[30d])))",
        "legendFormat": "Availability"
      }]
    },
    {
      "title": "Error Budget Remaining",
      "type": "bargauge",
      "targets": [{
        "expr": "(1 - sum(increase(http_requests_total{status=~\"5..\"}[30d])) / sum(increase(http_requests_total[30d]))) / 0.001 * 100",
        "legendFormat": "Budget %"
      }]
    }
  ]
}
```

---

## 23. Further Reading

### Official Documentation

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Grafana Cloud](https://grafana.com/products/cloud/)
- [Grafana Play](https://play.grafana.org/) (Live demo)
- [Grafana Blog](https://grafana.com/blog/)

### Books

- *Monitoring with Grafana* by Marcus Ekström and Periklis Tsahalidis
- *Grafana Essentials* by Ryan Malesevic
- *Observability Engineering* by Charity Majors et al.

### Community Resources

- [Grafana Community](https://community.grafana.com/)
- [Grafana GitHub](https://github.com/grafana/grafana)
- [Awesome Grafana](https://github.com/zwardlon/awesome-grafana)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Grafana Plugins](https://grafana.com/grafana/plugins/)

### Related Tools

- [Loki](https://grafana.com/oss/loki/) - Log aggregation
- [Tempo](https://grafana.com/oss/tempo/) - Distributed tracing
- [Mimir](https://grafana.com/oss/mimir/) - Long-term Prometheus storage
- [Pyroscope](https://grafana.com/oss/pyroscope/) - Continuous profiling
- [k6](https://grafana.com/products/k6/) - Load testing
