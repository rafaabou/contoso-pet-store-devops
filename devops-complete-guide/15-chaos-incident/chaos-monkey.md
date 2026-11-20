# Chaos Monkey Complete Guide

## Table of Contents

1. [What Is Chaos Monkey](#1-what-is-chaos-monkey)
2. [Why Use Chaos Monkey](#2-why-use-chaos-monkey)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Fault Injection](#8-custom-fault-injection)
9. [Simian Army](#9-simian-army)
10. [Integration with Cloud Providers](#10-integration-with-cloud-providers)
11. [Security](#11-security)
12. [Troubleshooting](#12-troubleshooting)
13. [Tips and Best Practices](#13-tips-and-best-practices)
14. [Command Reference](#14-command-reference)
15. [Configuration Reference](#15-configuration-reference)
16. [Real-World Examples](#16-real-world-examples)
17. [Further Reading](#17-further-reading)

---

## 1. What Is Chaos Monkey

Chaos Monkey is a resilience testing tool originally developed by Netflix as part of the Simian Army. It randomly terminates virtual machine instances and containers within a production environment to ensure that applications can tolerate failures gracefully.

### 1.1 History and Evolution

Netflix developed Chaos Monkey in 2011 as part of their migration to AWS. The tool was designed to test whether applications could survive the inevitable failures that occur in large-scale distributed systems. Over time, Netflix expanded the concept into a full "Simian Army" of tools, each designed to test different types of failures.

Key milestones:
- **2011**: Chaos Monkey v1 released as open source
- **2012**: Simian Army expanded with Latency Monkey, Conformity Monkey, and Security Monkey
- **2016**: Chaos Monkey rewritten in Go for better performance
- **2018**: Chaos Monkey moved to Kubernetes-native architecture
- **2020**: Improved integration with Spinnaker for controlled chaos
- **2023**: Chaos Monkey 3.0 with enhanced scheduling and multi-cloud support

### 1.2 How It Works

Chaos Monkey operates on the principle that failures are inevitable in distributed systems. Rather than trying to prevent all failures, Chaos Monkey proactively injects failures to:

1. **Identify weak points** in application architecture
2. **Validate failover mechanisms** work correctly
3. **Test auto-scaling and self-healing** capabilities
4. **Build confidence** in system resilience
5. **Reduce mean time to recovery (MTTR)** through practice

### 1.3 Key Features

- **Random Instance Termination**: Randomly selects and terminates instances
- **Scheduling**: Configurable schedules for chaos experiments
- **Exclusion Groups**: Protect critical infrastructure from termination
- **Minimum Cluster Size**: Ensure minimum capacity before terminating
- **Integration with Cloud APIs**: Native support for AWS, GCP, Azure
- **Monitoring and Reporting**: Detailed logs and metrics
- **Canary Deployments**: Test resilience during deployments

---

## 2. Why Use Chaos Monkey

### 2.1 Benefits

**Proactive Failure Testing**
- Discover weaknesses before they cause outages
- Validate assumptions about system behavior
- Build confidence in disaster recovery

**Cost Efficiency**
- Prevent costly outages through proactive testing
- Optimize infrastructure by identifying over-provisioning
- Reduce engineering time spent on reactive incident response

**Cultural Benefits**
- Foster a culture of resilience engineering
- Encourage blameless post-mortems
- Build muscle memory for incident response

### 2.2 Use Cases

**Microservices Architecture**
- Test service mesh resilience
- Validate circuit breaker patterns
- Verify retry and backoff mechanisms

**Cloud-Native Applications**
- Test auto-scaling behavior
- Validate rolling update strategies
- Verify pod disruption budgets (Kubernetes)

**Database and Stateful Systems**
- Test database failover mechanisms
- Verify data replication consistency
- Validate backup and recovery procedures

### 2.3 Prerequisites

- Running infrastructure on supported cloud providers (AWS, GCP, Azure)
- Applications designed for fault tolerance
- Monitoring and alerting in place
- Team buy-in for chaos engineering
- Staging environment for initial testing

---

## 3. Architecture Overview

### 3.1 Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Chaos Monkey Server                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐     │
│  │ Web UI   │  │ REST API │  │ Scheduler        │     │
│  │          │  │          │  │ (Cron-based)     │     │
│  └──────────┘  └──────────┘  └──────────────────┘     │
│         │              │              │                 │
│         └──────────────┼──────────────┘                 │
│                        │                                │
│              ┌─────────▼─────────┐                      │
│              │    MongoDB        │                      │
│              │ (configuration,  │                      │
│              │  results, logs)  │                      │
│              └───────────────────┘                      │
└──────────────────────────┬──────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐ ┌──▼──────┐ ┌──▼──────┐
       │  AWS        │ │ GCP     │ │ Azure   │
       │  Cloud API  │ │ Cloud   │ │ Cloud   │
       │             │ │ API     │ │ API     │
       └──────┬──────┘ └──┬──────┘ └──┬──────┘
              │            │            │
       ┌──────▼──────┐ ┌──▼──────┐ ┌──▼──────┐
       │ EC2/GCE     │ │ GCE     │ │ Azure   │
       │ Instances   │ │ VMs     │ │ VMs     │
       └─────────────┘ └─────────┘ └─────────┘
```

### 3.2 Core Components

**Chaos Monkey Server**
- REST API for configuration and execution
- Web UI for management and monitoring
- Scheduler for automated chaos experiments
- Result aggregator for experiment outcomes

**Cloud Provider Adapters**
- AWS adapter (EC2, ECS, EKS)
- GCP adapter (GCE, GKE)
- Azure adapter (VMs, AKS)

**Data Store**
- MongoDB for configuration storage
- Experiment results and logs
- History and audit trails

### 3.3 Workflow

1. **Configuration**: Define target groups, schedules, and exclusion rules
2. **Discovery**: Chaos Monkey discovers available instances/containers
3. **Selection**: Random selection based on configuration rules
4. **Safety Check**: Verify minimum cluster size and exclusion groups
5. **Termination**: Terminate selected instance/container
6. **Monitoring**: Monitor system recovery and log results
7. **Reporting**: Generate reports and update dashboards

---

## 4. Installation

### 4.1 Prerequisites

- Docker installed
- MongoDB instance available
- Cloud provider credentials (AWS/GCP/Azure)
- Network access to cloud APIs

### 4.2 Installation via Docker

**Step 1: Clone the repository**

```bash
git clone https://github.com/Netflix/chaosmonkey.git
cd chaosmonkey
```

**Step 2: Build the Docker image**

```bash
docker build -t chaosmonkey:latest .
```

**Step 3: Run with Docker Compose**

```yaml
# docker-compose.yml
version: '3.8'
services:
  chaosmonkey:
    image: chaosmonkey:latest
    ports:
      - "8080:8080"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/chaosmonkey
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=us-west-2
    depends_on:
      - mongo

  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

```bash
docker-compose up -d
```

**Step 4: Verify installation**

```bash
curl http://localhost:8080/api/health
```

### 4.3 Installation via Kubernetes

**Step 1: Create namespace**

```bash
kubectl create namespace chaosmonkey
```

**Step 2: Deploy MongoDB**

```yaml
# mongodb.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: chaosmonkey-mongodb
  namespace: chaosmonkey
spec:
  serviceName: chaosmonkey-mongodb
  replicas: 1
  selector:
    matchLabels:
      app: chaosmonkey-mongodb
  template:
    metadata:
      labels:
        app: chaosmonkey-mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: chaosmonkey-mongodb
  namespace: chaosmonkey
spec:
  selector:
    app: chaosmonkey-mongodb
  ports:
  - port: 27017
    targetPort: 27017
```

**Step 3: Deploy Chaos Monkey**

```yaml
# chaosmonkey.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chaosmonkey
  namespace: chaosmonkey
spec:
  replicas: 1
  selector:
    matchLabels:
      app: chaosmonkey
  template:
    metadata:
      labels:
        app: chaosmonkey
    spec:
      serviceAccountName: chaosmonkey
      containers:
      - name: chaosmonkey
        image: chaosmonkey:latest
        ports:
        - containerPort: 8080
        env:
        - name: MONGODB_URI
          value: "mongodb://chaosmonkey-mongodb:27017/chaosmonkey"
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret-access-key
        - name: AWS_REGION
          value: "us-west-2"
```

**Step 4: Create ServiceAccount and RBAC**

```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: chaosmonkey
  namespace: chaosmonkey
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: chaosmonkey
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: chaosmonkey
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: chaosmonkey
subjects:
- kind: ServiceAccount
  name: chaosmonkey
  namespace: chaosmonkey
```

### 4.4 Installation via Package Manager

```bash
# macOS
brew install chaosmonkey

# Linux (Debian/Ubuntu)
wget https://github.com/Netflix/chaosmonkey/releases/download/v3.0.0/chaosmonkey_3.0.0_linux_amd64.deb
sudo dpkg -i chaosmonkey_3.0.0_linux_amd64.deb

# Windows (Chocolatey)
choco install chaosmonkey
```

### 4.5 Verifying Installation

```bash
# Check version
chaosmonkey --version

# Test cloud provider connectivity
chaosmonkey status

# List available instances
chaosmonkey list --region us-west-2
```

---

## 5. Configuration

### 5.1 Main Configuration File

```yaml
# chaosmonkey.yml
server:
  host: "0.0.0.0"
  port: 8080
  tls:
    enabled: true
    cert: "/etc/chaosmonkey/tls.crt"
    key: "/etc/chaosmonkey/tls.key"

database:
  uri: "mongodb://localhost:27017/chaosmonkey"
  database: "chaosmonkey"

cloud:
  provider: "aws"
  region: "us-west-2"
  credentials:
    type: "environment"
    access_key_id: "${AWS_ACCESS_KEY_ID}"
    secret_access_key: "${AWS_SECRET_ACCESS_KEY}"

chaos:
  enabled: true
  schedule: "0 9 * * 1-5"  # Weekdays at 9 AM
  timezone: "America/Los_Angeles"
  
  # Safety settings
  min_cluster_size: 3
  max_termination_percentage: 20
  
  # Exclusion groups
  exclusion_groups:
    - name: "production-databases"
      tags:
        - "role:database"
        - "environment:production"
    - name: "critical-services"
      tags:
        - "critical:true"

monitoring:
  prometheus:
    enabled: true
    port: 9090
  
  grafana:
    enabled: true
    dashboard_url: "http://grafana:3000"

notifications:
  slack:
    enabled: true
    webhook_url: "${SLACK_WEBHOOK_URL}"
    channel: "#chaos-engineering"
  
  pagerduty:
    enabled: true
    integration_key: "${PAGERDUTY_KEY}"
```

### 5.2 Instance Group Configuration

```yaml
# instance-groups.yml
groups:
  - name: "web-servers"
    description: "Web server instances"
    cloud:
      provider: "aws"
      region: "us-west-2"
    filters:
      - type: "tag"
        key: "role"
        value: "web"
      - type: "tag"
        key: "environment"
        value: "production"
    settings:
      min_instances: 2
      max_termination_percentage: 30
      cooldown_period: 300  # seconds

  - name: "api-servers"
    description: "API server instances"
    cloud:
      provider: "aws"
      region: "us-west-2"
    filters:
      - type: "tag"
        key: "role"
        value: "api"
    settings:
      min_instances: 3
      max_termination_percentage: 20
      cooldown_period: 600

  - name: "worker-nodes"
    description: "Background worker instances"
    cloud:
      provider: "aws"
      region: "us-west-2"
    filters:
      - type: "tag"
        key: "role"
        value: "worker"
    settings:
      min_instances: 2
      max_termination_percentage: 50
      cooldown_period: 180
```

### 5.3 Schedule Configuration

```yaml
# schedules.yml
schedules:
  - name: "weekday-morning"
    description: "Run chaos during weekday mornings"
    cron: "0 9 * * 1-5"
    timezone: "America/Los_Angeles"
    groups:
      - "web-servers"
      - "api-servers"
    enabled: true

  - name: "weekend-evening"
    description: "Run chaos during weekend evenings"
    cron: "0 18 * * 0,6"
    timezone: "America/Los_Angeles"
    groups:
      - "worker-nodes"
    enabled: true

  - name: "monthly-stress"
    description: "Monthly comprehensive stress test"
    cron: "0 2 1 * *"
    timezone: "UTC"
    groups:
      - "web-servers"
      - "api-servers"
      - "worker-nodes"
    settings:
      max_termination_percentage: 50
    enabled: true
```

### 5.4 Exclusion Rules

```yaml
# exclusions.yml
exclusions:
  # Instance-level exclusions
  instances:
    - id: "i-0123456789abcdef0"
      reason: "Critical database instance"
    - id: "i-abcdef0123456789a"
      reason: "Primary load balancer"

  # Tag-based exclusions
  tags:
    - key: "role"
      values: ["database", "cache"]
    - key: "critical"
      values: ["true", "high"]
    - key: "chaos-protected"
      values: ["true"]

  # Time-based exclusions
  time_windows:
    - name: "maintenance-window"
      cron: "0 2 * * 0"  # Sundays at 2 AM
      duration: 4h
      reason: "Maintenance window"

  # Minimum capacity
  min_capacity:
    - group: "web-servers"
      min_instances: 3
    - group: "api-servers"
      min_instances: 2
```

---

## 6. Core Concepts

### 6.1 Instance Groups

Instance groups define collections of similar instances that Chaos Monkey can target for termination. Groups are defined by:

- **Cloud Provider**: AWS, GCP, Azure
- **Region**: Geographic region for the instances
- **Filters**: Tag-based or attribute-based filtering
- **Settings**: Minimum instances, termination percentage, cooldown

### 6.2 Termination Strategies

**Random Termination**
- Selects instances randomly from eligible groups
- Respects minimum capacity and exclusion rules
- Default strategy for most use cases

**Round-Robin Termination**
- Cycles through instances systematically
- Ensures even distribution of chaos over time
- Useful for long-term resilience testing

**Load-Based Termination**
- Targets instances with specific load characteristics
- Tests auto-scaling under failure conditions
- Requires integration with monitoring systems

### 6.3 Safety Mechanisms

**Minimum Cluster Size**
- Ensures minimum number of instances remain running
- Prevents complete service outage
- Configurable per instance group

**Maximum Termination Percentage**
- Limits percentage of instances terminated per experiment
- Prevents cascading failures
- Configurable per schedule

**Cooldown Period**
- Minimum time between terminating instances in a group
- Allows system to stabilize between chaos events
- Configurable per instance group

**Exclusion Groups**
- Protect specific instances from termination
- Based on tags, instance IDs, or custom rules
- Can be time-limited

### 6.4 Experiment Lifecycle

1. **Discovery**: Chaos Monkey discovers available instances
2. **Selection**: Selects instances based on configuration
3. **Safety Check**: Verifies minimum capacity and exclusions
4. **Pre-Chaos**: Captures system state before termination
5. **Termination**: Terminates selected instances
6. **Post-Chaos**: Monitors system recovery
7. **Reporting**: Logs results and updates dashboards
8. **Notification**: Sends notifications to configured channels

---

## 7. Usage Guide

### 7.1 Running Your First Experiment

**Step 1: Configure instance group**

```bash
# List available instances
chaosmonkey list --region us-west-2

# Check instance tags
chaosmonkey tags --instance-id i-0123456789abcdef0 --region us-west-2
```

**Step 2: Create exclusion rules**

```bash
# Add instance to exclusion list
chaosmonkey exclusion add --instance-id i-critical123 --reason "Primary database"

# Add tag-based exclusion
chaosmonkey exclusion add --tag "role=database" --reason "All databases"
```

**Step 3: Set minimum capacity**

```bash
# Set minimum instances for group
chaosmonkey config set --group web-servers --min-instances 3
```

**Step 4: Run a single experiment**

```bash
# Dry run (no actual termination)
chaosmonkey run --group web-servers --dry-run

# Actual termination
chaosmonkey run --group web-servers --region us-west-2
```

**Step 5: Monitor results**

```bash
# View experiment results
chaosmonkey results --group web-servers

# View detailed logs
chaosmonkey logs --group web-servers --limit 10
```

### 7.2 Scheduling Experiments

**Via CLI**

```bash
# Create a schedule
chaosmonkey schedule create \
  --name "weekday-morning" \
  --cron "0 9 * * 1-5" \
  --timezone "America/Los_Angeles" \
  --groups "web-servers,api-servers" \
  --max-percentage 20

# List schedules
chaosmonkey schedule list

# Enable/disable schedule
chaosmonkey schedule enable --name "weekday-morning"
chaosmonkey schedule disable --name "weekday-morning"
```

**Via API**

```bash
curl -X POST http://localhost:8080/api/schedules \
  -H "Content-Type: application/json" \
  -d '{
    "name": "weekday-morning",
    "cron": "0 9 * * 1-5",
    "timezone": "America/Los_Angeles",
    "groups": ["web-servers"],
    "enabled": true
  }'
```

### 7.3 Integration with Spinnaker

```yaml
# pipeline.yaml (Spinnaker pipeline stage)
stages:
  - name: "Chaos Test"
    type: "chaos"
    config:
      chaosMonkey:
        url: "http://chaosmonkey:8080"
        group: "web-servers"
        dryRun: false
        minInstances: 3
      expectedResult: "RECOVERED"
      timeout: 600
```

### 7.4 Monitoring Experiments

**Prometheus Metrics**

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'chaosmonkey'
    static_configs:
      - targets: ['chaosmonkey:8080']
    metrics_path: '/metrics'
```

Key metrics:
- `chaosmonkey_terminations_total` - Total terminations
- `chaosmonkey_terminations_failed_total` - Failed terminations
- `chaosmonkey_experiments_total` - Total experiments
- `chaosmonkey_experiment_duration_seconds` - Experiment duration

**Grafana Dashboard**

```json
{
  "panels": [
    {
      "title": "Chaos Experiments",
      "targets": [
        {
          "expr": "rate(chaosmonkey_terminations_total[5m])",
          "legendFormat": "{{group}}"
        }
      ]
    }
  ]
}
```

---

## 8. Custom Fault Injection

### 8.1 Custom Termination Strategies

```go
// custom_strategy.go
package chaosmonkey

import (
    "context"
    "log"
    "math/rand"
    "time"
)

type LoadBasedStrategy struct {
    prometheusClient *PrometheusClient
}

func (s *LoadBasedStrategy) SelectTarget(ctx context.Context, instances []Instance) ([]Instance, error) {
    // Get current load metrics
    metrics, err := s.prometheusClient.GetInstanceMetrics(ctx)
    if err != nil {
        return nil, err
    }

    // Sort by load (lowest first)
    var lowLoad, mediumLoad, highLoad []Instance
    for _, inst := range instances {
        load := metrics[inst.ID].CPUUsage
        switch {
        case load < 30:
            lowLoad = append(lowLoad, inst)
        case load < 70:
            mediumLoad = append(mediumLoad, inst)
        default:
            highLoad = append(highLoad, inst)
        }
    }

    // Prefer low-load instances
    if len(lowLoad) > 0 {
        idx := rand.Intn(len(lowLoad))
        return []Instance{lowLoad[idx]}, nil
    }
    if len(mediumLoad) > 0 {
        idx := rand.Intn(len(mediumLoad))
        return []Instance{mediumLoad[idx]}, nil
    }
    if len(highLoad) > 0 {
        idx := rand.Intn(len(highLoad))
        return []Instance{highLoad[idx]}, nil
    }

    return nil, fmt.Errorf("no eligible instances found")
}
```

### 8.2 Custom Pre-Chaos Hooks

```yaml
# hooks.yml
hooks:
  pre_chaos:
    - name: "backup-database"
      type: "http"
      url: "http://backup-service:8080/backup"
      method: "POST"
      timeout: 300
      retry: 3
    
    - name: "snapshot-filesystem"
      type: "command"
      command: "aws ec2 create-snapshot"
      args:
        - "--volume-id"
        - "{{volume_id}}"
      timeout: 120

  post_chaos:
    - name: "verify-recovery"
      type: "http"
      url: "http://health-check:8080/health"
      method: "GET"
      timeout: 60
      retry: 10
      interval: 5
    
    - name: "notify-teams"
      type: "webhook"
      url: "${SLACK_WEBHOOK_URL}"
      payload:
        text: "Chaos experiment completed for {{instance_id}}"
```

### 8.3 Custom Recovery Validators

```python
# recovery_validator.py
import time
import requests
from prometheus_api_client import PrometheusConnect

class RecoveryValidator:
    def __init__(self, prom_url, health_url):
        self.prom = PrometheusConnect(url=prom_url)
        self.health_url = health_url
    
    def validate_recovery(self, instance_id, timeout=300):
        """Validate that the system has recovered after chaos."""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            # Check health endpoint
            try:
                response = requests.get(self.health_url, timeout=5)
                if response.status_code != 200:
                    time.sleep(5)
                    continue
            except requests.RequestException:
                time.sleep(5)
                continue
            
            # Check error rate
            error_rate = self.prom.custom_query(
                query='rate(http_requests_total{status=~"5.."}[1m])'
            )
            if float(error_rate[0]['value'][1]) > 0.01:
                time.sleep(5)
                continue
            
            # Check latency
            latency = self.prom.custom_query(
                query='histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[1m]))'
            )
            if float(latency[0]['value'][1]) > 1.0:
                time.sleep(5)
                continue
            
            return True, "System recovered successfully"
        
        return False, "Recovery timeout exceeded"
```

---

## 9. Simian Army

### 9.1 Overview

The Simian Army is a collection of chaos engineering tools developed by Netflix. Each tool tests different aspects of system resilience:

- **Chaos Monkey**: Randomly terminates instances
- **Latency Monkey**: Injects network latency
- **Conformity Monkey**: Checks compliance with best practices
- **Security Monkey**: Monitors for security issues
- **Janitor Monkey**: Identifies and cleans up unused resources
- **Chaos Gorilla**: Simulates availability zone failures
- **Chaos Kong**: Simulates region failures

### 9.2 Latency Monkey

Injects network latency to test timeout and retry mechanisms.

```yaml
# latency-monkey.yml
latency:
  enabled: true
  target:
    service: "payment-service"
    endpoint: "/api/process"
  
  injection:
    type: "fixed"
    value: 500  # milliseconds
    duration: 300  # seconds
  
  conditions:
    - type: "time_window"
      start: "09:00"
      end: "17:00"
    - type: "traffic_threshold"
      min_requests_per_second: 100
```

### 9.3 Conformity Monkey

Checks that instances follow best practices.

```yaml
# conformity-monkey.yml
conformity:
  rules:
    - name: "instance-type"
      description: "Check instance type compliance"
      check: "instance_type in ['m5.large', 'm5.xlarge', 'c5.large']"
      action: "alert"
    
    - name: "auto-scaling"
      description: "Check auto-scaling enabled"
      check: "auto_scaling.enabled == true"
      action: "alert"
    
    - name: "monitoring"
      description: "Check monitoring enabled"
      check: "tags.monitoring == 'enabled'"
      action: "alert"
    
    - name: "backup"
      description: "Check backup enabled"
      check: "tags.backup == 'enabled'"
      action: "alert"
```

### 9.4 Security Monkey

Monitors for security issues and compliance violations.

```yaml
# security-monkey.yml
security:
  monitors:
    - name: "iam-key-rotation"
      description: "Check IAM key rotation"
      interval: 86400  # 24 hours
      check: "iam.access_key.last_rotated < 90 days"
      action: "alert"
    
    - name: "s3-public-access"
      description: "Check S3 bucket public access"
      interval: 3600  # 1 hour
      check: "s3.bucket.public_access == false"
      action: "alert"
    
    - name: "security-groups"
      description: "Check security group rules"
      interval: 3600
      check: "security_group.ingress not contains '0.0.0.0/0'"
      action: "alert"
```

### 9.5 Janitor Monkey

Identifies and cleans up unused resources.

```yaml
# janitor-monkey.yml
janitor:
  rules:
    - name: "unused-eips"
      description: "Find unused Elastic IPs"
      resource_type: "ec2:elastic-ip"
      criteria:
        - "attached_to_instance == false"
        - "age > 30 days"
      action: "cleanup"
    
    - name: "unused-volumes"
      description: "Find unattached EBS volumes"
      resource_type: "ec2:volume"
      criteria:
        - "status == 'available'"
        - "age > 14 days"
      action: "cleanup"
    
    - name: "old-snapshots"
      description: "Find old EBS snapshots"
      resource_type: "ec2:snapshot"
      criteria:
        - "age > 90 days"
      action: "cleanup"
```

---

## 10. Integration with Cloud Providers

### 10.1 AWS Integration

```yaml
# aws-config.yml
aws:
  access_key_id: "${AWS_ACCESS_KEY_ID}"
  secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
  region: "us-west-2"
  
  services:
    ec2:
      enabled: true
      actions:
        - "terminate-instances"
        - "stop-instances"
    
    ecs:
      enabled: true
      actions:
        - "stop-task"
        - "deregister-container-instance"
    
    eks:
      enabled: true
      actions:
        - "delete-pod"
        - "cordon-node"
        - "drain-node"
```

### 10.2 GCP Integration

```yaml
# gcp-config.yml
gcp:
  project_id: "my-project"
  service_account_key: "${GOOGLE_APPLICATION_CREDENTIALS}"
  region: "us-central1"
  
  services:
    compute:
      enabled: true
      actions:
        - "stop-instance"
        - "delete-instance"
    
    gke:
      enabled: true
      actions:
        - "delete-pod"
        - "cordon-node"
        - "drain-node"
```

### 10.3 Azure Integration

```yaml
# azure-config.yml
azure:
  subscription_id: "${AZURE_SUBSCRIPTION_ID}"
  client_id: "${AZURE_CLIENT_ID}"
  client_secret: "${AZURE_CLIENT_SECRET}"
  tenant_id: "${AZURE_TENANT_ID}"
  
  services:
    compute:
      enabled: true
      actions:
        - "deallocate-vm"
        - "delete-vm"
    
    aks:
      enabled: true
      actions:
        - "delete-pod"
        - "cordon-node"
        - "drain-node"
```

---

## 11. Security

### 11.1 Security Best Practices

**Credential Management**
- Use IAM roles instead of access keys when possible
- Rotate credentials regularly
- Use secrets management (Vault, AWS Secrets Manager)
- Never commit credentials to version control

**Network Security**
- Enable TLS for all Chaos Monkey communications
- Use VPC endpoints for cloud API access
- Implement network policies to restrict chaos traffic
- Monitor chaos-related API calls

**Access Control**
- Implement RBAC for Chaos Monkey users
- Use least-privilege IAM policies
- Audit all chaos operations
- Log all configuration changes

### 11.2 IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ChaosMonkeyPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:TerminateInstances",
        "ec2:StopInstances",
        "ec2:StartInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-west-2"
        }
      }
    },
    {
      "Sid": "ChaosMonkeyKubernetes",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups"
      ],
      "Resource": "*"
    }
  ]
}
```

### 11.3 TLS Configuration

```yaml
# tls-config.yml
tls:
  enabled: true
  cert_file: "/etc/chaosmonkey/tls.crt"
  key_file: "/etc/chaosmonkey/tls.key"
  ca_file: "/etc/chaosmonkey/ca.crt"
  
  min_version: "1.2"
  cipher_suites:
    - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
    - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
```

---

## 12. Troubleshooting

### 12.1 Common Issues and Solutions

**Issue 1: Cannot connect to cloud provider**

```bash
# Test cloud provider connectivity
aws sts get-caller-identity

# Check credentials
aws configure list

# Verify network connectivity
curl -v https://ec2.us-west-2.amazonaws.com

# Fix: Update credentials or check network
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

**Issue 2: No instances found**

```bash
# List all instances
aws ec2 describe-instances --region us-west-2

# Check instance tags
aws ec2 describe-instances --region us-west-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags]' \
  --output table

# Fix: Update filters or add tags to instances
```

**Issue 3: Minimum cluster size exceeded**

```bash
# Check current instance count
chaosmonkey list --group web-servers --count

# Update minimum cluster size
chaosmonkey config set --group web-servers --min-instances 2

# Fix: Adjust minimum capacity or add more instances
```

**Issue 4: Exclusion rules blocking termination**

```bash
# List exclusion rules
chaosmonkey exclusion list

# Check if instance is excluded
chaosmonkey exclusion check --instance-id i-0123456789abcdef0

# Fix: Modify or remove exclusion rules
chaosmonkey exclusion remove --instance-id i-0123456789abcdef0
```

**Issue 5: Schedule not running**

```bash
# Check schedule status
chaosmonkey schedule list

# View schedule logs
chaosmonkey schedule logs --name "weekday-morning"

# Fix: Verify cron expression and timezone
chaosmonkey schedule update --name "weekday-morning" --cron "0 9 * * 1-5"
```

**Issue 6: MongoDB connection failures**

```bash
# Test MongoDB connection
mongosh "mongodb://localhost:27017/chaosmonkey"

# Check MongoDB status
systemctl status mongod

# Fix: Verify MongoDB URI and credentials
chaosmonkey config set --database-uri "mongodb://localhost:27017/chaosmonkey"
```

**Issue 7: High error rate after termination**

```bash
# Check application logs
kubectl logs -l app=web-server --tail=100

# Check service health
curl -v http://web-server:8080/health

# Fix: Review application fault tolerance and recovery mechanisms
```

**Issue 8: Experiments not cleaning up**

```bash
# List active experiments
chaosmonkey experiments list --status running

# Force cleanup
chaosmonkey experiments cleanup --name "web-server-test"

# Fix: Implement proper experiment lifecycle management
```

**Issue 9: Slack notifications not working**

```bash
# Test webhook URL
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  ${SLACK_WEBHOOK_URL}

# Check notification configuration
chaosmonkey config get --notifications

# Fix: Verify webhook URL and channel permissions
```

**Issue 10: Performance issues with large clusters**

```bash
# Check Chaos Monkey resource usage
kubectl top pods -n chaosmonkey

# Increase resource limits
kubectl patch deployment chaosmonkey -n chaosmonkey \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"chaosmonkey","resources":{"limits":{"cpu":"2000m","memory":"2Gi"}}}]}}}}'

# Fix: Scale Chaos Monkey horizontally or optimize queries
```

**Issue 11: Region-specific API errors**

```bash
# Test region connectivity
aws ec2 describe-regions

# Check region-specific quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region us-west-2

# Fix: Verify region availability and request quota increases
```

**Issue 12: IAM permission errors**

```bash
# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/chaosmonkey \
  --action-names ec2:TerminateInstances

# Fix: Update IAM policy with required permissions
```

**Issue 13: Container orchestration issues (Kubernetes)**

```bash
# Check Chaos Monkey pods
kubectl get pods -n chaosmonkey

# Check RBAC
kubectl auth can-i list pods --as=system:serviceaccount:chaosmonkey:chaosmonkey

# Fix: Verify ServiceAccount and RBAC configuration
```

**Issue 14: Network connectivity issues**

```bash
# Test network connectivity
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl -v http://chaosmonkey:8080/health

# Check network policies
kubectl get networkpolicies -n chaosmonkey

# Fix: Update network policies to allow chaos traffic
```

**Issue 15: Monitoring gaps**

```bash
# Check Prometheus metrics
curl -s http://prometheus:9090/api/v1/query?query=chaosmonkey_terminations_total

# Check Grafana dashboards
curl -s http://grafana:3000/api/dashboards

# Fix: Update monitoring configuration and dashboards
```

---

## 13. Tips and Best Practices

### 13.1 Experiment Design

1. **Start small**: Begin with single instance termination in non-production
2. **Define success criteria**: Know what recovery looks like before starting
3. **Use canary deployments**: Test during deployments to validate rolling updates
4. **Implement circuit breakers**: Automatically stop experiments if system health degrades
5. **Document experiments**: Maintain a chaos experiment catalog

### 13.2 Safety Measures

6. **Set minimum capacity**: Always maintain minimum instances for critical services
7. **Use exclusion groups**: Protect databases and critical infrastructure
8. **Implement cooldown periods**: Allow system stabilization between experiments
9. **Notify stakeholders**: Always communicate before running experiments
10. **Start in staging**: Validate all experiments before production

### 13.3 Observability

11. **Monitor key metrics**: Track error rates, latency, and throughput during experiments
12. **Set up alerts**: Create alerts for anomaly detection
13. **Use dashboards**: Create dedicated chaos engineering dashboards
14. **Log everything**: Enable detailed logging for all chaos operations
15. **Track resilience scores**: Monitor long-term improvement trends

### 13.4 Team Collaboration

16. **Share learnings**: Conduct regular chaos engineering reviews
17. **Create runbooks**: Document manual intervention procedures
18. **Train team members**: Ensure everyone understands chaos principles
19. **Celebrate failures**: Treat failures as learning opportunities
20. **Build muscle memory**: Practice incident response regularly

### 13.5 Production Best Practices

21. **Run during business hours**: Have team available for manual intervention
22. **Limit blast radius**: Start with low percentages and increase gradually
23. **Use feature flags**: Disable experiments quickly if needed
24. **Implement rollback**: Have rollback procedures ready
25. **Review post-mortems**: Conduct blameless post-mortems after experiments

---

## 14. Command Reference

### 14.1 Chaos Monkey CLI Commands

```bash
# Core Commands
chaosmonkey --version                    # Show version
chaosmonkey status                       # Show Chaos Monkey status
chaosmonkey help                         # Show help

# Instance Management
chaosmonkey list                         # List all instances
chaosmonkey list --group web-servers     # List instances in group
chaosmonkey list --region us-west-2      # List instances in region
chaosmonkey tags --instance-id i-xxx     # Show instance tags

# Configuration
chaosmonkey config get                   # Show all config
chaosmonkey config get --group web-servers  # Show group config
chaosmonkey config set --group web-servers --min-instances 3

# Experiment Execution
chaosmonkey run --group web-servers      # Run experiment
chaosmonkey run --group web-servers --dry-run  # Dry run
chaosmonkey run --instance-id i-xxx      # Terminate specific instance

# Results and Logs
chaosmonkey results                      # Show recent results
chaosmonkey results --group web-servers  # Show group results
chaosmonkey logs                         # Show recent logs
chaosmonkey logs --limit 50              # Show last 50 logs

# Schedules
chaosmonkey schedule list                # List schedules
chaosmonkey schedule create --name test --cron "0 9 * * 1-5"
chaosmonkey schedule enable --name test
chaosmonkey schedule disable --name test

# Exclusions
chaosmonkey exclusion list               # List exclusions
chaosmonkey exclusion add --instance-id i-xxx --reason "Critical"
chaosmonkey exclusion remove --instance-id i-xxx

# Experiments
chaosmonkey experiments list             # List experiments
chaosmonkey experiments list --status running
chaosmonkey experiments cleanup --name test
```

### 14.2 API Endpoints

```bash
# Health Check
GET /api/health

# Instances
GET /api/instances
GET /api/instances/{id}
GET /api/instances/{id}/tags

# Configuration
GET /api/config
PUT /api/config
GET /api/config/groups
PUT /api/config/groups/{name}

# Experiments
POST /api/experiments
GET /api/experiments
GET /api/experiments/{id}
DELETE /api/experiments/{id}

# Results
GET /api/results
GET /api/results/{experiment_id}

# Schedules
GET /api/schedules
POST /api/schedules
PUT /api/schedules/{name}
DELETE /api/schedules/{name}

# Exclusions
GET /api/exclusions
POST /api/exclusions
DELETE /api/exclusions/{id}

# Metrics
GET /metrics
```

### 14.3 Docker Commands

```bash
# Build
docker build -t chaosmonkey:latest .

# Run
docker run -d \
  -p 8080:8080 \
  -e MONGODB_URI=mongodb://mongo:27017/chaosmonkey \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  chaosmonkey:latest

# Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f chaosmonkey
```

---

## 15. Configuration Reference

### 15.1 Server Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `server.host` | string | Server bind address | "0.0.0.0" |
| `server.port` | int | Server port | 8080 |
| `server.tls.enabled` | bool | Enable TLS | false |
| `server.tls.cert` | string | TLS certificate path | - |
| `server.tls.key` | string | TLS key path | - |

### 15.2 Database Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `database.uri` | string | MongoDB URI | - |
| `database.database` | string | Database name | "chaosmonkey" |

### 15.3 Cloud Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `cloud.provider` | string | Cloud provider (aws/gcp/azure) | "aws" |
| `cloud.region` | string | Default region | - |
| `cloud.credentials.type` | string | Credentials type | "environment" |

### 15.4 Chaos Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `chaos.enabled` | bool | Enable chaos experiments | true |
| `chaos.schedule` | string | Default cron schedule | - |
| `chaos.timezone` | string | Timezone | "UTC" |
| `chaos.min_cluster_size` | int | Minimum cluster size | 3 |
| `chaos.max_termination_percentage` | int | Max termination % | 20 |

### 15.5 Group Configuration

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `groups[].name` | string | Group name | - |
| `groups[].cloud.provider` | string | Cloud provider | - |
| `groups[].cloud.region` | string | Region | - |
| `groups[].filters[]` | array | Instance filters | - |
| `groups[].settings.min_instances` | int | Min instances | 2 |
| `groups[].settings.max_termination_percentage` | int | Max termination % | 20 |
| `groups[].settings.cooldown_period` | int | Cooldown (seconds) | 300 |

---

## 16. Real-World Examples

### 16.1 Netflix Production Example

```yaml
# netflix-chaos.yml
chaos:
  schedule: "0 10-16 * * 1-5"
  timezone: "America/Los_Angeles"
  
  groups:
    - name: "api-gateway"
      min_instances: 5
      max_termination_percentage: 10
      cooldown_period: 600
      filters:
        - key: "role"
          value: "api-gateway"
    
    - name: "video-streaming"
      min_instances: 10
      max_termination_percentage: 5
      cooldown_period: 900
      filters:
        - key: "role"
          value: "video-streaming"
  
  exclusions:
    - name: "primary-database"
      tags:
        - "role:database"
        - "tier:primary"
    - name: "authentication-service"
      tags:
        - "service:auth"
        - "critical:true"
  
  notifications:
    slack:
      webhook_url: "${SLACK_WEBHOOK_URL}"
      channel: "#chaos-engineering"
    pagerduty:
      integration_key: "${PAGERDUTY_KEY}"
```

### 16.2 E-Commerce Application

```yaml
# ecommerce-chaos.yml
chaos:
  schedule: "0 2 * * 0"
  timezone: "UTC"
  
  groups:
    - name: "web-frontend"
      min_instances: 3
      max_termination_percentage: 30
      filters:
        - key: "role"
          value: "frontend"
    
    - name: "api-backend"
      min_instances: 3
      max_termination_percentage: 20
      filters:
        - key: "role"
          value: "api"
    
    - name: "payment-service"
      min_instances: 2
      max_termination_percentage: 10
      filters:
        - key: "role"
          value: "payment"
  
  hooks:
    pre_chaos:
      - name: "backup-database"
        type: "http"
        url: "http://backup:8080/backup"
        method: "POST"
    
    post_chaos:
      - name: "verify-checkout"
        type: "http"
        url: "http://checkout:8080/health"
        method: "GET"
        timeout: 60
        retry: 10
```

### 16.3 Kubernetes-Native Example

```yaml
# k8s-chaos.yml
chaos:
  provider: "kubernetes"
  
  experiments:
    - name: "pod-termination"
      target:
        namespace: "production"
        label_selector: "app=web"
      settings:
        min_pods: 3
        max_termination_percentage: 20
    
    - name: "node-drain"
      target:
        label_selector: "node-role.kubernetes.io/worker="
      settings:
        min_nodes: 3
        drain_timeout: 60
    
    - name: "network-partition"
      target:
        namespace: "production"
        label_selector: "app=api"
      settings:
        duration: 300
        ports: [80, 443]
```

---

## 17. Further Reading

### 17.1 Official Documentation

- Chaos Monkey GitHub: https://github.com/Netflix/chaosmonkey
- Simian Army: https://github.com/Netflix/SimianArmy
- Netflix Tech Blog: https://netflix.github.io/
- Chaos Engineering Principles: https://principlesofchaos.org

### 17.2 Books and Guides

- "Chaos Engineering: System Resiliency in Practice" by Casey Rosenthal, Nora Jones
- "The Chaos Engineering Workbook" by Casey Rosenthal, Nora Jones
- "Building Secure & Reliable Systems" by Google SRE Team

### 17.3 Community Resources

- Chaos Engineering Slack: https://chaosengineering.slack.com
- CNCF Slack: https://cloud-native.slack.com
- Chaos Engineering Meetups: https://www.meetup.com/chaos-engineering

### 17.4 Related Tools

- LitmusChaos: https://litmuschaos.io
- Chaos Mesh: https://chaos-mesh.org
- Gremlin: https://www.gremlin.com
- AWS Fault Injection Simulator: https://aws.amazon.com/fis

### 17.5 Blog Posts and Tutorials

- Getting Started with Chaos Monkey
- Building Resilient Microservices with Chaos Engineering
- Chaos Engineering at Netflix: Lessons Learned
- Integrating Chaos Monkey into CI/CD Pipelines

---

*Last updated: 2026*
