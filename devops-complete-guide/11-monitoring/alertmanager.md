# Alertmanager Complete Guide

## Table of Contents

1. [What Is Alertmanager](#1-what-is-alertmanager)
2. [Why Use Alertmanager](#2-why-use-alertmanager)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Routing](#7-routing)
8. [Receivers](#8-receivers)
9. [Inhibition Rules](#9-inhibition-rules)
10. [Silences](#10-silences)
11. [Mute Time Intervals](#11-mute-time-intervals)
12. [Usage Guide (Step-by-Step)](#12-usage-guide-step-by-step)
13. [High Availability](#13-high-availability)
14. [Integrations](#14-integrations)
15. [Security](#15-security)
16. [Troubleshooting](#16-troubleshooting)
17. [Tips and Best Practices](#17-tips-and-best-practices)
18. [Command Reference](#18-command-reference)
19. [Configuration Reference](#19-configuration-reference)
20. [Real-World Examples](#20-real-world-examples)
21. [Further Reading](#21-further-reading)

---

## 1. What Is Alertmanager

Alertmanager is a standalone tool that handles alerts sent by Prometheus. It takes care of deduplicating, grouping, routing, and delivering alerts to various receivers (Slack, email, PagerDuty, webhook, etc.). Alertmanager also handles silencing and inhibition of alerts.

### Key Features

- **Multi-tenancy**: Support for multiple independent Alertmanager instances
- **Grouping**: Combine similar alerts into a single notification
- **Routing**: Route alerts to different receivers based on labels
- **Inhibition**: Suppress lower-priority alerts when higher-priority ones fire
- **Silencing**: Temporarily suppress notifications during maintenance
- **Mute Time Intervals**: Schedule-based suppression (e.g., during business hours)
- **High Availability**: Native clustering for redundancy
- **Deduplication**: Identical alerts are not sent multiple times
- **Templateable**: Customize notification content with Go templates
- **API**: Full REST API for management

### Relationship with Prometheus

Prometheus fires alerts based on PromQL rules; Alertmanager receives them and manages delivery:

```
Prometheus ──firing──▶ Alertmanager ──routing──▶ Slack
                      Alertmanager ──routing──▶ Email
                      Alertmanager ──routing──▶ PagerDuty
```

---

## 2. Why Use Alertmanager

### Without Alertmanager

- Duplicated alerts for the same issue
- No alert grouping (alert fatigue)
- Manual silencing required
- No priority-based routing
- No high availability

### With Alertmanager

- **Deduplication**: Identical alerts merged automatically
- **Grouping**: Alerts from the same source batched into one notification
- **Routing**: Critical alerts to PagerDuty, warnings to Slack
- **Inhibition**: Node-down suppresses all service-down alerts on that node
- **Silences**: Suppress during known maintenance
- **HA**: Cluster mode ensures no alert is lost during failures

---

## 3. Architecture Overview

```
                    ┌─────────────────────────────────┐
                    │        Alertmanager Cluster       │
                    │                                   │
                    │  ┌──────────┐   ┌──────────┐    │
                    │  │Instance 1│◄─▶│Instance 2│    │
                    │  └─────┬────┘   └─────┬────┘    │
                    │        │              │          │
                    │  ┌─────┴──────────────┴────┐    │
                    │  │    Routing Engine        │    │
                    │  └───────────┬──────────────┘    │
                    │              │                    │
                    │  ┌───────────┴──────────────┐    │
                    │  │   Receiver Dispatchers    │    │
                    │  └───────────┬──────────────┘    │
                    └──────────────┼──────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
         ┌────┴────┐        ┌─────┴─────┐       ┌─────┴─────┐
         │  Slack  │        │  Email    │       │ PagerDuty  │
         └─────────┘        └───────────┘       └───────────┘
```

### Data Flow

1. **Prometheus fires alert** → sends HTTP POST to Alertmanager API
2. **Alertmanager receives alert** → checks for duplicates (dedup)
3. **Grouping** → waits for `group_wait` before sending first notification
4. **Routing** → matches alert labels against routing tree
5. **Inhibition** → checks if alert should be inhibited
6. **Silence** → checks if alert is silenced
7. **Mute Time** → checks if current time is in a mute interval
8. **Delivery** → sends notification to matched receiver

### Gossip Protocol

Alertmanager instances in a cluster use the gossip protocol (based on hashicorp/memberlist) to:
- Share silences and silences across instances
- Share inhibition state
- Coordinate notification deduplication

---

## 4. Installation

### Binary Download

```bash
ALERTMANAGER_VERSION="0.27.0"
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
tar xvf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
sudo cp alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/amtool /usr/local/bin/
```

### Systemd Service

```ini
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --web.listen-address=:9093 \
  --cluster.listen-address=0.0.0.0:9094
Restart=always

[Install]
WantedBy=multi-user.target
```

### Docker

```bash
docker run -d \
  --name alertmanager \
  -p 9093:9093 \
  -p 9094:9094 \
  -v /etc/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  -v alertmanager_data:/alertmanager \
  prom/alertmanager:v0.27.0 \
  --config.file=/etc/alertmanager/alertmanager.yml
```

### Docker Compose

```yaml
version: '3.8'
services:
  alertmanager:
    image: prom/alertmanager:v0.27.0
    ports:
      - "9093:9093"
      - "9094:9094"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.listen-address=:9093'
      - '--cluster.listen-address=0.0.0.0:9094'
    restart: unless-stopped

volumes:
  alertmanager_data:
```

### Kubernetes (Helm)

```bash
helm install alertmanager prometheus-community/alertmanager \
  --namespace monitoring \
  --create-namespace \
  --set config.global.resolve_timeout=5m
```

### Verifying Installation

```bash
# Check version
alertmanager --version

# Check health
curl http://localhost:9093/-/healthy

# Check readiness
curl http://localhost:9093/-/ready

# Validate config
amtool check-config /etc/alertmanager/alertmanager.yml
```

---

## 5. Configuration

### Main Configuration File

```yaml
# /etc/alertmanager/alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/xxx'
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'
  smtp_require_tls: true

templates:
  - '/etc/alertmanager/templates/*.tmpl'

route:
  receiver: 'default'
  group_by: ['alertname', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty'
      group_wait: 10s
      repeat_interval: 1h

    - match:
        severity: warning
      receiver: 'slack-warnings'

    - match_re:
        service: 'api|web'
      receiver: 'slack-services'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'xxx'

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#alerts-warnings'
        send_resolved: true

  - name: 'slack-services'
    slack_configs:
      - channel: '#alerts-services'
```

### Global Section

```yaml
global:
  resolve_timeout: 5m          # Timeout for resolving alerts
  slack_api_url: 'https://...'  # Default Slack webhook
  slack_api_url_file: '/path'   # File-based Slack webhook
  smtp_smarthost: 'smtp:587'
  smtp_from: 'alertmanager@'
  smtp_auth_username: 'user'
  smtp_auth_password: 'pass'
  smtp_auth_identity: ''
  smtp_auth_secret: ''
  smtp_require_tls: true
  smtp_hello: 'localhost'
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'
  pagerduty_service_key: ''
  pagerduty_images: []
  pagerduty_links: []
  opsgenie_api_key: 'xxx'
  opsgenie_api_url: 'https://api.opsgenie.com/v2/alerts'
  wechat_url: ''
  wechat_secret: ''
  wechat_corp_id: ''
  victorops_api_key: ''
  victorops_api_url: ''
  http_config:
    proxy_url: ''
    tls_config:
      ca_file: ''
      cert_file: ''
      key_file: ''
      insecure_skip_verify: false
    follow_redirects: true
```

---

## 6. Core Concepts

### Alerts

An alert is a named event that fires when a PromQL condition is met. Alerts are sent to Alertmanager as JSON:

```json
[
  {
    "labels": {
      "alertname": "HighCPU",
      "severity": "warning",
      "instance": "node1:9100",
      "job": "node-exporter"
    },
    "annotations": {
      "summary": "High CPU on node1",
      "description": "CPU usage > 85% for 10 minutes"
    },
    "startsAt": "2024-01-15T10:00:00Z",
    "endsAt": "0001-01-01T00:00:00Z",
    "generatorURL": "http://prometheus:9090/graph?g0.expr=..."
  }
]
```

### Labels

Labels are key-value pairs that identify and classify alerts:
- Used for routing decisions
- Used for grouping
- Used for inhibition matching
- Must be consistent across related alerts

### Annotations

Annotations provide additional context about an alert:
- `summary`: Brief description (used in notifications)
- `description`: Detailed explanation
- Custom annotations for specific receivers

### Grouping

Grouping combines multiple alerts with the same label set into a single notification:

```yaml
route:
  group_by: ['alertname', 'namespace']
  group_wait: 30s        # Wait before sending first notification
  group_interval: 5m     # Wait between notifications for the same group
  repeat_interval: 4h    # Wait before repeating an unresolved alert
```

### Deduplication

Identical alerts (same labels) are deduplicated:
- If an alert is already firing and a new instance with the same labels arrives, it is merged
- Only one notification is sent for the group

### Resolution

An alert is resolved when the PromQL condition returns false:
- Prometheus sends `endsAt` timestamp
- Alertmanager sends a "resolved" notification
- The alert is removed from the active alerts list

---

## 7. Routing

### Routing Tree

The routing tree is a hierarchy of routes, starting from the root:

```yaml
route:
  receiver: 'default'         # Root receiver
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    # Child route 1
    - match:
        severity: critical
      receiver: 'pagerduty'
      group_wait: 10s

    # Child route 2
    - match:
        severity: warning
      receiver: 'slack'

    # Nested route
    - match:
        team: backend
      receiver: 'slack-backend'
      routes:
        - match:
            service: api
          receiver: 'slack-api'
```

### Route Matching

```yaml
# Exact match
- match:
    severity: critical

# Regex match
- match_re:
    service: 'api|web|worker'

# Multiple labels (AND)
- match:
    severity: warning
    env: production
```

### Route Evaluation

Routes are evaluated depth-first:
1. Start at the root
2. Match child routes in order
3. First matching child is selected
4. If no child matches, use current route's receiver
5. Continue to grandchildren if they exist

### Continue

```yaml
routes:
  - match:
      severity: critical
    receiver: 'pagerduty'
    continue: true   # Also send to next matching route
  - match:
      severity: critical
    receiver: 'slack-critical'
```

### Group Wait, Group Interval, Repeat Interval

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `group_wait` | Time to wait before sending the first notification for a group | 30s |
| `group_interval` | Minimum time between notifications for the same group | 5m |
| `repeat_interval` | Time before re-sending an unresolved alert | 4h |

---

## 8. Receivers

### Slack

```yaml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
        title: |
          {{ if eq .Status "resolved" }}✅ Resolved{{ else }}🔴 Firing{{ end }}: {{ .GroupLabels.alertname }}
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Severity:* {{ .Labels.severity }}
          *Instance:* {{ .Labels.instance }}
          {{ end }}
        color: |
          {{ if eq .Status "resolved" }}good{{ else }}danger{{ end }}
        actions:
          - type: button
            text: 'Runbook'
            url: '{{ (index .Alerts 0).Annotations.runbook_url }}'
```

### Email

```yaml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'team@example.com'
        send_resolved: true
        subject: |
          {{ if eq .Status "resolved" }}[RESOLVED]{{ else }}[FIRING]{{ end }} {{ .GroupLabels.alertname }}
        html: |
          <h2>{{ .GroupLabels.alertname }}</h2>
          <p>Status: {{ .Status }}</p>
          {{ range .Alerts }}
          <h3>{{ .Annotations.summary }}</h3>
          <p>{{ .Annotations.description }}</p>
          <p>Severity: {{ .Labels.severity }}</p>
          {{ end }}
```

### PagerDuty

```yaml
receivers:
  - name: 'pagerduty-alerts'
    pagerduty_configs:
      - service_key: 'xxx'
        send_resolved: true
        description: '{{ .GroupLabels.alertname }}'
        severity: '{{ if eq .CommonLabels.severity "critical" }}critical{{ else }}warning{{ end }}'
        details:
          firing: '{{ .Alerts.Firing | len }}'
          resolved: '{{ .Alerts.Resolved | len }}'
```

### Webhook

```yaml
receivers:
  - name: 'webhook-alerts'
    webhook_configs:
      - url: 'http://alert-handler:5001/alerts'
        send_resolved: true
        http_config:
          bearer_token: 'xxx'
```

### OpsGenie

```yaml
receivers:
  - name: 'opsgenie-alerts'
    opsgenie_configs:
      - api_key: 'xxx'
        send_resolved: true
        message: '{{ .GroupLabels.alertname }}'
        description: '{{ (index .Alerts 0).Annotations.description }}'
        priority: '{{ if eq .CommonLabels.severity "critical" }}P1{{ else }}P2{{ end }}'
        tags: '{{ .CommonLabels | toLowerKeys | join "," }}'
```

### WeChat

```yaml
receivers:
  - name: 'wechat-alerts'
    wechat_configs:
      - corp_id: 'xxx'
        to_party: '1'
        to_tag: '2'
        agent_id: 'xxx'
        api_secret: 'xxx'
        message: '{{ .GroupLabels.alertname }}: {{ (index .Alerts 0).Annotations.summary }}'
```

### VictorOps

```yaml
receivers:
  - name: 'victorops-alerts'
    victorops_configs:
      - api_key: 'xxx'
        routing_key: 'team'
        message_type: '{{ if eq .CommonLabels.severity "critical" }}CRITICAL{{ else }}WARNING{{ end }}'
```

### Telegram

```yaml
receivers:
  - name: 'telegram-alerts'
    telegram_configs:
      - bot_token: 'xxx'
        chat_id: 123456
        parse_mode: 'HTML'
        message: |
          <b>{{ .GroupLabels.alertname }}</b>
          {{ range .Alerts }}
          <i>{{ .Annotations.summary }}</i>
          {{ end }}
```

### Microsoft Teams

```yaml
receivers:
  - name: 'teams-alerts'
    webhook_configs:
      - url: 'https://outlook.office.com/webhook/xxx'
        send_resolved: true
```

---

## 9. Inhibition Rules

### Purpose

Inhibition rules suppress alerts when a higher-priority alert is already firing. This prevents notification storms.

### Configuration

```yaml
inhibit_rules:
  # Suppress warnings when critical alert fires for same instance
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

  # Suppress all alerts for a service when the node is down
  - source_match:
      alertname: 'NodeDown'
    target_match_re:
      alertname: '.+Down'
    equal: ['instance']

  # Suppress all namespace alerts when cluster is down
  - source_match:
      alertname: 'ClusterDown'
    target_match:
      severity: 'warning'
    equal: ['namespace']
```

### How It Works

1. Source alert must be **firing** (not resolved)
2. Target alert must have matching labels
3. If `equal` is specified, those labels must match between source and target
4. If `equal` is empty or omitted, all target alerts are inhibited

### Inhibition Example

```
Firing: NodeDown{instance="node1:9100", severity="critical"}
Target: HighCPU{instance="node1:9100", severity="warning"} → INHIBITED
Target: HighMemory{instance="node1:9100", severity="warning"} → INHIBITED
Target: HighCPU{instance="node2:9100", severity="warning"} → NOT INHIBITED (different instance)
```

---

## 10. Silences

### Creating Silences

```bash
# Using amtool
amtool silence add alertname=HighCPU instance=node1:9100 --duration=2h --comment="Maintenance window"

# Using API
curl -X POST http://localhost:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {"name": "alertname", "value": "HighCPU", "isRegex": false},
      {"name": "instance", "value": "node1:9100", "isRegex": false}
    ],
    "startsAt": "2024-01-15T10:00:00Z",
    "endsAt": "2024-01-15T12:00:00Z",
    "createdBy": "admin",
    "comment": "Maintenance window"
  }'
```

### Listing Silences

```bash
# amtool
amtool silence query

# API
curl http://localhost:9093/api/v2/silences | jq
```

### Expiring Silences

```bash
# amtool
amtool silence expire <silence-id>

# API
curl -X DELETE http://localhost:9093/api/v2/silence/<silence-id>
```

### Silence Behavior

- Silences are **not** deleted when they expire; they are marked as "expired"
- A silence matching an alert prevents **all notifications** for that alert
- Silences are propagated across the cluster via gossip

---

## 11. Mute Time Intervals

### Purpose

Mute time intervals suppress notifications during scheduled maintenance windows without creating individual silences.

### Configuration

```yaml
# alertmanager.yml
mute_time_intervals:
  - name: 'maintenance-window'
    time_intervals:
      - times:
          - start_time: '02:00'
            end_time: '04:00'
        weekdays: ['saturday', 'sunday']
        months: ['january', 'february']
        days: ['1', '15']
        location: 'America/New_York'

  - name: 'business-hours'
    time_intervals:
      - times:
          - start_time: '09:00'
            end_time: '17:00'
        weekdays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
        location: 'Europe/London'
```

### Using Mute Time Intervals in Routes

```yaml
route:
  receiver: 'default'
  mute_time_intervals:
    - 'maintenance-window'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      mute_time_intervals: []    # Critical alerts are NOT muted
```

### Time Interval Format

```yaml
time_intervals:
  - times:
      - start_time: 'HH:MM'
        end_time: 'HH:MM'
    weekdays: ['monday', ..., 'sunday']
    days: ['1', '31']           # Day of month
    months: ['1', '12']         # Month number or name
    years: ['2024', '2025']     # Year
    location: 'America/New_York'
```

---

## 12. Usage Guide (Step-by-Step)

### Step 1: Configure Alertmanager

```yaml
# /etc/alertmanager/alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'slack-default'
  group_by: ['alertname', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
  - name: 'slack-default'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
```

### Step 2: Configure Prometheus to Send Alerts

```yaml
# prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml
```

### Step 3: Create Alert Rules

```yaml
# /etc/prometheus/rules/infrastructure.yml
groups:
  - name: infrastructure
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"

      - alert: HighCPU
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
```

### Step 4: Test Alert Firing

```bash
# Force fire an alert
curl -X POST http://localhost:9090/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "Test alert"
    },
    "for": "0m"
  }]'
```

### Step 5: Verify Alert in Alertmanager

```bash
curl http://localhost:9093/api/v2/alerts | jq
```

### Step 6: Create a Silence

```bash
amtool silence add alertname=TestAlert --duration=1h --comment="Testing silence"
```

### Step 7: Monitor Alertmanager

```bash
# Check metrics
curl http://localhost:9093/metrics | grep alertmanager_

# Key metrics:
# alertmanager_alerts_received_total
# alertmanager_alerts_forwarded_total
# alertmanager_notifications_total
# alertmanager_notifications_failed_total
# alertmanager_silences_queries_total
```

### Step 8: Use the Web UI

Navigate to `http://localhost:9093` to:
- View active alerts
- Create and manage silences
- View and edit routing tree
- Check cluster status

---

## 13. High Availability

### Cluster Mode

```bash
alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --cluster.listen-address=0.0.0.0:9094 \
  --cluster.peer=alertmanager-1:9094 \
  --cluster.peer=alertmanager-2:9094
```

### Cluster Configuration

```yaml
# alertmanager.yml (or CLI flags)
cluster:
  listen_address: '0.0.0.0:9094'
  peers:
    - 'alertmanager-1:9094'
    - 'alertmanager-2:9094'
  settle_timeout: 15s
  probe_interval: 15s
  probe_timeout: 5s
  probe_interval: 1s
```

### How HA Works

1. All instances receive the same alerts from Prometheus
2. Instances gossip to share silences and inhibition state
3. Only one instance sends notifications per group
4. If one instance fails, another takes over

### Load Balancing

Place a load balancer in front of Alertmanager:

```nginx
upstream alertmanager {
    server alertmanager-1:9093;
    server alertmanager-2:9093;
    server alertmanager-3:9093;
}

server {
    listen 9093;
    location / {
        proxy_pass http://alertmanager;
    }
}
```

---

## 14. Integrations

### Prometheus

```yaml
# prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
      timeout: 10s
    - static_configs:
        - targets: ['alertmanager-2:9093']
      timeout: 10s
```

### Grafana

```yaml
# grafana.ini
[unified_alerting]
enabled = true

# Or use Alertmanager data source
datasources:
  - name: Alertmanager
    type: alertmanager
    url: http://alertmanager:9093
    access: proxy
```

### Kubernetes

```yaml
# Kubernetes service
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  selector:
    app: alertmanager
  ports:
    - port: 9093
      targetPort: 9093
    - port: 9094
      targetPort: 9094
```

### Pushgateway

```bash
# Push alerts from scripts
curl -X POST http://alertmanager:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {"alertname": "ScriptAlert", "severity": "info"},
    "annotations": {"summary": "Script completed"}
  }]'
```

---

## 15. Security

### TLS

```yaml
# alertmanager.yml
tls_config:
  cert_file: /etc/alertmanager/server.crt
  key_file: /etc/alertmanager/server.key
  ca_file: /etc/alertmanager/ca.crt
```

### Basic Auth

```yaml
# alertmanager.yml
basic_auth:
  username: admin
  password: secret
```

### Web Configuration

```yaml
# /etc/alertmanager/web.yml
tls_server_config:
  cert_file: /etc/alertmanager/server.crt
  key_file: /etc/alertmanager/server.key
basic_auth_users:
  admin: $2y$10$hash
```

### API Authentication

```bash
# Create API key (not natively supported, use reverse proxy)
# Use OAuth2 proxy or similar for API auth
```

### Network Security

```bash
# Firewall rules
ufw allow from 10.0.0.0/8 to any port 9093
ufw allow from 10.0.0.0/8 to any port 9094
```

---

## 16. Troubleshooting

### Issue 1: Alerts Not Reaching Alertmanager

**Symptoms**: Prometheus shows alerts as "pending" or "firing" but Alertmanager has none.

**Diagnosis**:
```bash
# Check Prometheus alerting config
curl http://localhost:9090/api/v1/status/config | jq '.data.yaml' | grep alertmanager

# Check Alertmanager is reachable
curl http://alertmanager:9093/-/healthy

# Check Prometheus logs
journalctl -u prometheus | grep -i alert
```

**Resolution**: Verify `alerting` section in prometheus.yml, check network connectivity, ensure Alertmanager is running.

### Issue 2: Duplicate Notifications

**Symptoms**: Receiving the same alert multiple times.

**Diagnosis**:
```bash
# Check number of Alertmanager instances
curl http://alertmanager-1:9093/api/v2/alerts | jq 'length'
curl http://alertmanager-2:9093/api/v2/alerts | jq 'length'

# Check cluster status
curl http://alertmanager:9093/api/v2/status | jq
```

**Resolution**: Ensure `group_by` is correctly configured, check cluster gossip is working, verify Prometheus targets all Alertmanager instances.

### Issue 3: Alertmanager Cluster Not Forming

**Symptoms**: Cluster status shows only one peer.

**Diagnosis**:
```bash
curl http://alertmanager:9093/api/v2/status | jq '.cluster'
```

**Resolution**: Check firewall rules for port 9094, ensure all peers are listed, check DNS resolution.

### Issue 4: Notifications Not Sent

**Symptoms**: Alerts fire in Alertmanager but no notification arrives.

**Diagnosis**:
```bash
# Check notification metrics
curl http://alertmanager:9093/metrics | grep notifications_total
curl http://alertmanager:9093/metrics | grep notifications_failed_total

# Check receiver configuration
amtool config show
```

**Resolution**: Verify receiver configuration, check webhook URLs, validate SMTP settings, ensure templates are correct.

### Issue 5: Templates Not Rendering

**Symptoms**: Notifications show raw Go template syntax.

**Diagnosis**:
```bash
# Test template rendering
amtool template render --template=/etc/alertmanager/templates/alert.tmpl

# Check template syntax
amtool check-config /etc/alertmanager/alertmanager.yml
```

**Resolution**: Fix Go template syntax, ensure template files are loaded, check variable names.

### Issue 6: Silence Not Working

**Symptoms**: Silenced alerts still trigger notifications.

**Diagnosis**:
```bash
# List active silences
amtool silence query

# Check if silence matches the alert
amtool silence query alertname=HighCPU
```

**Resolution**: Verify matcher labels match exactly, check if silence has expired, ensure silence is created in the correct namespace.

### Issue 7: High Memory Usage

**Symptoms**: Alertmanager consuming excessive RAM.

**Diagnosis**:
```bash
# Check number of active alerts
curl http://alertmanager:9093/api/v2/alerts | jq 'length'

# Check number of silences
curl http://alertmanager:9093/api/v2/silences | jq 'length'
```

**Resolution**: Reduce alert cardinality, clean up old silences, increase memory limit.

### Issue 8: Configuration Reload Fails

**Symptoms**: `amtool check-config` fails.

**Diagnosis**:
```bash
amtool check-config /etc/alertmanager/alertmanager.yml
```

**Resolution**: Fix YAML syntax, verify required fields, check template paths.

### Issue 9: Alert Not Resolving

**Symptoms**: Alert stays "firing" even after the condition is false.

**Diagnosis**:
```bash
# Check Prometheus rule evaluation
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.name=="HighCPU")'

# Check Alertmanager received the resolution
curl http://alertmanager:9093/api/v2/alerts | jq '.[] | select(.labels.alertname=="HighCPU") | .status'
```

**Resolution**: Ensure `resolve_timeout` is configured, check Prometheus rule `for` duration, verify target is reachable.

### Issue 10: Webhook Returns Error

**Symptoms**: Alertmanager logs show webhook delivery failures.

**Diagnosis**:
```bash
# Check webhook logs
journalctl -u alertmanager | grep -i webhook

# Test webhook endpoint
curl -X POST http://webhook-receiver:5001/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"test"}}]'
```

**Resolution**: Verify webhook URL, check HTTP status code, ensure webhook service is running, validate request format.

### Issue 11: Alerts Not Grouped Correctly

**Symptoms**: Receiving one notification per alert instead of grouped.

**Diagnosis**:
```bash
# Check route configuration
amtool config show | grep group_by
```

**Resolution**: Add appropriate labels to `group_by`, ensure alerts share common labels, adjust `group_wait`.

### Issue 12: Repeat Notifications Too Frequent

**Symptoms**: Same alert re-sent every few minutes.

**Diagnosis**:
```bash
# Check repeat_interval
amtool config show | grep repeat_interval
```

**Resolution**: Increase `repeat_interval`, ensure alert is not being re-created by Prometheus.

### Issue 13: Alertmanager Crashes on Startup

**Symptoms**: Alertmanager exits immediately after starting.

**Diagnosis**:
```bash
journalctl -u alertmanager | tail -20
```

**Resolution**: Check storage path permissions, verify config file syntax, ensure required directories exist.

### Issue 14: Cluster Split Brain

**Symptoms**: Multiple instances sending notifications for the same group.

**Diagnosis**:
```bash
curl http://alertmanager-1:9093/api/v2/status | jq '.cluster.peers'
curl http://alertmanager-2:9093/api/v2/status | jq '.cluster.peers'
```

**Resolution**: Ensure all instances can reach each other, check firewall rules, verify DNS resolution, restart cluster.

### Issue 15: API Returns 401 Unauthorized

**Symptoms**: Cannot access Alertmanager API.

**Diagnosis**:
```bash
curl -v http://alertmanager:9093/api/v2/alerts
```

**Resolution**: Check basic auth configuration, verify credentials, ensure web.yml is loaded.

### Issue 16: Notifications Delayed

**Symptoms**: Notifications arrive minutes after the alert fires.

**Diagnosis**:
```bash
# Check group_wait and group_interval
amtool config show | grep -E 'group_wait|group_interval'
```

**Resolution**: Reduce `group_wait` for critical alerts, check network latency, ensure Alertmanager has sufficient resources.

---

## 17. Tips and Best Practices

### 1. Use Descriptive Alert Names

```yaml
# Bad
- alert: Alert1

# Good
- alert: NodeCPUHighUsage
```

### 2. Include Runbook URLs

```yaml
annotations:
  summary: "High CPU on {{ $labels.instance }}"
  runbook_url: "https://runbooks.example.com/high-cpu"
  dashboard_url: "https://grafana.example.com/d/node-overview"
```

### 3. Use Grouping Effectively

```yaml
# Group by alertname and namespace
group_by: ['alertname', 'namespace']
# This sends one notification per alert per namespace
```

### 4. Set Appropriate Repeat Intervals

| Severity | Repeat Interval |
|----------|-----------------|
| Critical | 1h |
| Warning | 4h |
| Info | 24h |

### 5. Use Inhibition to Reduce Noise

Suppress warnings when critical alerts are firing for the same target.

### 6. Test Alert Rules Before Deploying

```bash
promtool test rules tests/*.yml
```

### 7. Use Mute Time Intervals for Maintenance

Schedule suppression during known maintenance windows instead of creating manual silences.

### 8. Monitor Alertmanager Itself

Track these metrics:
- `alertmanager_notifications_total`
- `alertmanager_notifications_failed_total`
- `alertmanager_alerts_received_total`
- `alertmanager_cluster_members`

### 9. Use HA for Production

Run at least 3 Alertmanager instances in cluster mode for redundancy.

### 10. Keep Configuration as Code

Version control `alertmanager.yml` and deploy via provisioning.

### 11. Use Template Variables in Notifications

Include context like dashboard links, runbook URLs, and team information.

### 12. Set Up Dead Man's Switch

Create an alert that always fires to detect monitoring failures:

```yaml
- alert: DeadMansSwitch
  expr: vector(1)
  labels:
    severity: none
  annotations:
    summary: "Dead man's switch - monitoring is working"
```

### 13. Use `send_resolved: true`

Always send resolved notifications so teams know when issues are fixed.

### 14. Limit Group Size

Use `group_by` carefully to avoid extremely large notifications.

### 15. Use Labels Consistently

Standardize labels across all alert rules for effective routing and inhibition.

### 16. Document Alert Meanings

Maintain a wiki or runbook that explains each alert and its response procedure.

---

## 18. Command Reference

### alertmanager

```bash
alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --web.listen-address=:9093 \
  --web.external-url=http://alertmanager:9093 \
  --web.listen-address=:9093 \
  --cluster.listen-address=0.0.0.0:9094 \
  --cluster.peer=alertmanager-1:9094 \
  --cluster.settle-timeout=15s \
  --cluster.probe-interval=15s \
  --cluster.probe-timeout=5s \
  --cluster.probe-interval=1s \
  --log.level=info
```

### amtool

```bash
# Check configuration
amtool check-config /etc/alertmanager/alertmanager.yml

# Alert management
amtool alert query                          # List active alerts
amtool alert query alertname=HighCPU        # Filter by label
amtool alert add alertname=Test severity=warning  # Add test alert

# Silence management
amtool silence query                        # List silences
amtool silence add alertname=HighCPU --duration=1h
amtool silence expire <silence-id>

# Configuration
amtool config show                          # Show current config
amtool config routes                        # Show routing tree

# Template testing
amtool template render --template=alert.tmpl

# Cluster
amtool cluster                              # Show cluster status
amtool cluster peer                         # Show peers
```

### API Endpoints

```bash
# Health check
curl http://localhost:9093/-/healthy

# Ready check
curl http://localhost:9093/-/ready

# Alerts
curl http://localhost:9093/api/v2/alerts
curl http://localhost:9093/api/v2/alerts?silenced=true
curl http://localhost:9093/api/v2/alerts?inhibited=true

# Silences
curl http://localhost:9093/api/v2/silences
curl -X POST http://localhost:9093/api/v2/silences -d @silence.json
curl -X DELETE http://localhost:9093/api/v2/silence/<id>

# Status
curl http://localhost:9093/api/v2/status

# Metrics
curl http://localhost:9093/metrics
```

---

## 19. Configuration Reference

### Route

```yaml
route:
  receiver: string           # Required: default receiver
  group_by: [label, ...]    # Labels to group by
  group_wait: 30s            # Wait before first notification
  group_interval: 5m         # Wait between notifications
  repeat_interval: 4h        # Wait before repeating
  continue: false            # Continue to next route if true
  mute_time_intervals: []    # Mute time interval names

  routes:                    # Child routes
    - match:
        label: value
      match_re:
        label: regex
      receiver: string
      group_by: [...]
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      continue: false
      mute_time_intervals: [...]
      routes: [...]          # Nested routes
```

### Receiver

```yaml
receivers:
  - name: string             # Required: receiver name

    # Slack
    slack_configs:
      - channel: string
        send_resolved: true
        title: template
        text: template
        color: template
        actions: []
        http_config: {}

    # Email
    email_configs:
      - to: string
        send_resolved: true
        subject: template
        html: template
        text: template
        headers: {}

    # PagerDuty
    pagerduty_configs:
      - service_key: string
        send_resolved: true
        description: template
        severity: template
        details: {}

    # Webhook
    webhook_configs:
      - url: string
        send_resolved: true
        http_config: {}

    # OpsGenie
    opsgenie_configs:
      - api_key: string
        send_resolved: true
        message: template
        description: template
        priority: template
        tags: template

    # WeChat
    wechat_configs:
      - corp_id: string
        to_party: string
        to_tag: string
        agent_id: string
        api_secret: string
        message: template
```

### Inhibit Rules

```yaml
inhibit_rules:
  - source_match:
      label: value
    source_match_re:
      label: regex
    target_match:
      label: value
    target_match_re:
      label: regex
    equal: [label, ...]
```

### Mute Time Intervals

```yaml
mute_time_intervals:
  - name: string
    time_intervals:
      - times:
          - start_time: 'HH:MM'
            end_time: 'HH:MM'
        weekdays: [string, ...]
        days: [string, ...]
        months: [string, ...]
        years: [string, ...]
        location: string
```

---

## 20. Real-World Examples

### Example 1: Complete Alertmanager Configuration

```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/T00/B00/xxx'
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'app-password'

templates:
  - '/etc/alertmanager/templates/*.tmpl'

mute_time_intervals:
  - name: 'maintenance'
    time_intervals:
      - times:
          - start_time: '02:00'
            end_time: '04:00'
        weekdays: ['saturday', 'sunday']

route:
  receiver: 'slack-default'
  group_by: ['alertname', 'namespace', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty'
      group_wait: 10s
      repeat_interval: 1h

    - match:
        severity: warning
      receiver: 'slack-warnings'
      group_wait: 30s

    - match:
        severity: info
      receiver: 'slack-info'
      mute_time_intervals: ['maintenance']

inhibit_rules:
  - source_match:
      severity: critical
    target_match:
      severity: warning
    equal: ['alertname', 'instance']

  - source_match:
      alertname: NodeDown
    target_match_re:
      alertname: '.+Down'
    equal: ['instance']

receivers:
  - name: 'slack-default'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'xxx'
        send_resolved: true

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#alerts-warnings'
        send_resolved: true

  - name: 'slack-info'
    slack_configs:
      - channel: '#alerts-info'
        send_resolved: false
```

### Example 2: Custom Notification Template

```
{{ define "slack.custom" }}
{{ if eq .Status "resolved" }}
✅ *RESOLVED*: {{ .GroupLabels.alertname }}
{{ else }}
🔴 *FIRING*: {{ .GroupLabels.alertname }}
{{ end }}

*Severity:* {{ .CommonLabels.severity }}
*Namespace:* {{ .CommonLabels.namespace }}
*Description:* {{ (index .Alerts 0).Annotations.description }}

{{ range .Alerts }}
• *{{ .Labels.instance }}*: {{ .Annotations.summary }}
{{ end }}

<{{ (index .Alerts 0).GeneratorURL }}|View in Prometheus>
{{ end }}
```

### Example 3: Kubernetes Alertmanager ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m
    route:
      receiver: 'slack'
      group_by: ['alertname', 'namespace']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
    receivers:
      - name: 'slack'
        slack_configs:
          - channel: '#k8s-alerts'
            send_resolved: true
```

---

## 21. Further Reading

### Official Documentation

- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/configuration/)
- [Alertmanager GitHub](https://github.com/prometheus/alertmanager)
- [Prometheus Alerting Best Practices](https://prometheus.io/docs/practices/alerting/)

### Books

- *Monitoring with Prometheus* by James Turnbull
- *Prometheus: Up & Running* by Brian Brazil
- *Site Reliability Engineering* by Google

### Community Resources

- [Alertmanager Config Generator](https://prometheus.io/webtools/alerting/)
- [Alertmanager Cluster Examples](https://github.com/prometheus/alertmanager/tree/main/examples)
- [Awesome Prometheus Alerting Rules](https://github.com/samber/awesome-prometheus-alerts)

### Related Tools

- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/) - Grafana's unified alerting
- [Cortex Ruler](https://cortexmetrics.io/docs/apis/#ruler-api) - Rule evaluation in Cortex
- [Thanos Ruler](https://thanos.io/tip/components/ruler/) - Rule evaluation in Thanos
