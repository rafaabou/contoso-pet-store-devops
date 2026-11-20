# KEDA — Complete Guide

## Table of Contents

1. [What Is KEDA?](#1-what-is-keda)
2. [Why Use KEDA?](#2-why-use-keda)
3. [Architecture](#3-architecture)
4. [Installation](#4-installation)
5. [Core Concepts](#5-core-concepts)
6. [Trigger Types](#6-trigger-types)
7. [Scale to Zero](#7-scale-to-zero)
8. [ScaledObject Reference](#8-scaledobject-reference)
9. [TriggerAuthentication](#9-triggerauthentication)
10. [KEDA + Vault](#10-keda--vault)
11. [KEDA Metrics](#11-keda-metrics)
12. [KEDA + ArgoCD](#12-keda--argocd)
13. [KEDA + Helm](#13-keda--helm)
14. [Troubleshooting](#14-troubleshooting)
15. [Tips & Best Practices](#15-tips--best-practices)
16. [Real-World Example — Contoso Pet Store](#16-real-world-example--contoso-pet-store)
17. [Commands Reference](#17-commands-reference)
18. [Further Reading](#18-further-reading)

---

## 1. What Is KEDA?

KEDA (Kubernetes Event-Driven Autoscaler) is a CNCF-hosted project that enables
autoscaling of workloads in Kubernetes based on event-driven metrics. Unlike the
built-in Horizontal Pod Autoscaler (HPA), KEDA can scale workloads from zero
relicas, integrate directly with message brokers and event streams, and expose
custom metrics to the Kubernetes metrics pipeline.

### How KEDA Differs from HPA

| Feature | HPA | KEDA |
|---|---|---|
| Scale from zero | No | Yes |
| Event-driven metrics | No | Yes (RabbitMQ, Kafka, etc.) |
| Cron-based scaling | Via separate CronJobs | Built-in |
| Custom metrics adapter | Requires Prometheus adapter | Built-in |
| External metrics | Yes | Yes |
| Cooldown from zero | Not supported | Supported |
| Trigger authentication | N/A | Vault, K8s secrets, env vars |
| Operator pattern | Part of kube-controller-manager | Standalone operator |

HPA requires a running deployment to generate metrics. If you have 0 pods, there
are no metrics, so HPA cannot scale up. KEDA solves this by querying the metric
source directly (e.g., RabbitMQ queue length) and telling the HPA controller
what the desired replica count should be. KEDA acts as a metrics adapter, not a
replacement for HPA — it registers external metrics with the Kubernetes API
server and lets the HPA controller handle the actual scaling decisions.

### When to Use HPA vs KEDA

Use HPA when:
- You have a simple CPU/memory-based scaling policy
- Your workload always runs at least 1 replica
- You do not need to react to external event sources

Use KEDA when:
- You need scale-to-zero based on event backlog
- You want to scale based on queue depth, topic lag, cron schedules, or custom
  application metrics
- You need to integrate with external metric sources like Prometheus, Datadog,
  or cloud provider APIs
- You want to secure metric access with dedicated authentication objects

---

## 2. Why Use KEDA?

### Scale to Zero

The most compelling feature of KEDA is scale-to-zero. Traditional HPA keeps at
least one pod running at all times, which wastes resources during idle periods.
KEDA queries the event source directly — if a RabbitMQ queue has 0 messages,
KEDA scales the deployment to 0 replicas. When a message arrives, KEDA sees the
queue length increase and immediately scales up.

This is critical for:
- **Dev/staging environments** that should cost nothing when unused
- **Batch processing** that runs on a schedule (cron)
- **Async APIs** where requests sit in a queue and need workers only when busy
- **IoT ingestion** that is bursty and unpredictable

### Event-Driven Scaling

KEDA supports 50+ built-in scalers. Instead of writing a custom metrics
collector that polls your message broker and exposes a `/metrics` endpoint, you
just declare a trigger and KEDA handles the rest.

Examples:
- Scale based on RabbitMQ queue length
- Scale based on Kafka consumer group lag
- Scale based on the number of items in a PostgreSQL table
- Scale based on a Prometheus query result
- Scale based on a cron schedule (e.g., scale up at 9 AM)

### Custom Metrics Without Extra Infrastructure

Without KEDA, exposing custom metrics requires:
1. A Prometheus client library in your application
2. A Prometheus instance scraping the metrics
3. A Prometheus adapter translating Prometheus queries to Kubernetes metrics
4. An HPA referencing those metrics

With KEDA, you skip steps 1-3. KEDA connects directly to the data source and
exposes metrics through the Kubernetes custom metrics API.

### Decoupled Architecture

KEDA uses a `ScaledObject` CRD that declaratively describes what to scale and
what triggers to watch. This means:
- Developers define scaling behavior in YAML alongside their Deployment
- Platform teams manage the KEDA operator centrally
- No code changes needed in the application
- Scaling configuration is version-controlled and GitOps-friendly

---

## 3. Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│                    Kubernetes API Server             │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  HPA     │  │  Custom   │  │  ScaledObject    │   │
│  │Controller│  │  Metrics  │  │  CRD (user)      │   │
│  │          │  │  Adapter  │  │                  │   │
│  └────┬─────┘  └─────┬────┘  └────────┬─────────┘   │
│       │              │               │               │
│       └──────────────┼───────────────┘               │
│                      │                               │
└──────────────────────┼───────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │      KEDA Operator      │
          │  ┌──────────────────┐   │
          │  │  Metrics Server  │   │
          │  └──────────────────┘   │
          │  ┌──────────────────┐   │
          │  │  Scalers         │   │
          │  │  (RabbitMQ,      │   │
          │  │   Kafka, Cron,   │   │
          │  │   Prometheus...) │   │
          │  └──────────────────┘   │
          │  ┌──────────────────┐   │
          │  │  Authentication  │   │
          │  └──────────────────┘   │
          └─────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │  Event Sources          │
          │  (RabbitMQ, Kafka,      │
          │   Prometheus, DB, etc.) │
          └─────────────────────────┘
```

### How Scaling Works

1. User creates a `ScaledObject` resource in the cluster
2. KEDA operator detects the new ScaledObject
3. The operator creates or updates an HPA resource for the target Deployment
4. KEDA runs a polling loop against the configured event source
5. KEDA computes the desired replica count based on:
   - Current metric value
   - Target metric value (from `metadata.targetValue`)
   - `minReplicaCount` and `maxReplicaCount`
6. KEDA exposes the metric through the custom metrics API
7. HPA reads the metric and adjusts replicas

### Metrics Server Role

KEDA's built-in metrics server is what makes it work as a bridge between
external data sources and the Kubernetes custom metrics API. It:
- Registers as a metrics provider with the API server
- Responds to `getMetrics` requests for custom metrics
- Routes requests to the appropriate scaler
- Translates external metric values into HPA-compatible format

### Scaler Lifecycle

Each scaler follows this lifecycle:
1. **Initialize** — Connect to the event source using the provided metadata
2. **Get Metrics** — Query the current metric value (e.g., queue length)
3. **Get Metrics Spec** — Return the metric name and target value for HPA
4. **Close** — Clean up connections when the scaler is no longer needed

---

## 4. Installation

### Option 1: Helm (Recommended)

```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --set prometheus.metricServer.enabled=true \
  --set prometheus.enabled=true \
  --set admissionWebhooks.enabled=true
```

To install with the custom metrics adapter (recommended for exposing KEDA
metrics to HPA):

```bash
helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --set operator.replicaCount=1 \
  --set admissionWebhooks.enabled=true
```

To view available configuration options:

```bash
helm show values kedacore/keda
```

Key Helm values:

```yaml
# Number of KEDA operator replicas
operator:
  replicaCount: 1

# Webhook configuration
admissionWebhooks:
  enabled: true

# Metrics server (needed for custom metrics)
metricsServer:
  enabled: true
  image:
    repository: ghcr.io/kedacore/keda-metrics-server

# Service account
serviceAccount:
  create: true
  name: keda-operator
```

### Option 2: kubectl apply

For the latest version:

```bash
# Install CRDs
kubectl apply -f https://github.com/kedacore/keda/releases/latest/download/keda-crd.yaml

# Install the operator
kubectl apply -f https://github.com/kedacore/keda/releases/latest/download/keda-operator.yaml

# Install the metrics server (optional, for custom metrics)
kubectl apply -f https://github.com/kedacore/keda/releases/latest/download/keda-metrics-server.yaml
```

### Verify Installation

```bash
kubectl get pods -n keda
# NAME                                       READY   STATUS    RESTARTS   AGE
# keda-operator-5d9b6c4f7-xxxxx              1/1     Running   0          30s
# keda-operator-metrics-xxxxx                1/1     Running   0          30s
# keda-admission-webhooks-xxxxx              1/1     Running   0          30s
# keda-metrics-server-xxxxx                  1/1     Running   0          30s

kubectl get crd | grep keda
# scaledobjects.keda.sh
# triggerauthentications.keda.sh
# clustertriggerauthentications.keda.sh
```

### Uninstall

```bash
# Helm
helm uninstall keda -n keda
kubectl delete namespace keda

# kubectl
kubectl delete -f https://github.com/kedacore/keda/releases/latest/download/keda-metrics-server.yaml
kubectl delete -f https://github.com/kedacore/keda/releases/latest/download/keda-operator.yaml
kubectl delete -f https://github.com/kedacore/keda/releases/latest/download/keda-crd.yaml
```

---

## 5. Core Concepts

### ScaledObject

A ScaledObject is the primary CRD in KEDA. It defines:
- **What to scale** (the target Deployment, StatefulSet, etc.)
- **How to scale** (min/max replicas)
- **When to scale** (trigger conditions)
- **Scaling behavior** (cooldown, polling interval, stabilization)

Basic structure:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-scaled-object
  namespace: default
spec:
  scaleTargetRef:
    name: my-deployment           # Target workload name
    kind: Deployment              # Deployment, StatefulSet, etc.
  pollingInterval: 30             # Seconds between metric checks
  cooldownPeriod: 300             # Seconds to wait before scaling down
  minReplicaCount: 0              # Minimum replicas (0 = scale to zero)
  maxReplicaCount: 10             # Maximum replicas
  triggers: []                    # List of triggers
```

### ScaleTarget

The `scaleTargetRef` section identifies which workload to scale:

```yaml
spec:
  scaleTargetRef:
    name: my-deployment           # Required: name of the target
    kind: Deployment              # Default: Deployment
    apiVersion: apps/v1           # Default: apps/v1
```

You can target any scalable resource:
- `Deployment` (most common)
- `StatefulSet`
- `ReplicaSet`
- `CustomResourceDefinition` (any resource supporting scale subresource)

### Triggers

Triggers define the conditions that drive scaling. Each trigger connects to a
metric source and specifies what metric to watch and what target value to aim
for:

```yaml
spec:
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq.default.svc.cluster.local"
        queueLength: "50"
        queueName: "my-queue"
```

Multiple triggers are evaluated independently. The final replica count is the
maximum of all trigger calculations. This means if trigger A wants 5 replicas
and trigger B wants 3, KEDA will scale to 5.

### cooldownPeriod

`cooldownPeriod` specifies how many seconds KEDA should wait after the last
triggering event before scaling down to `minReplicaCount`. This prevents
thrashing — rapid scale up/down when metrics fluctuate.

```yaml
spec:
  cooldownPeriod: 300  # Wait 5 minutes after last trigger before scaling down
```

Key behaviors:
- Only applies to scale-down (not scale-up, which is immediate)
- If the metric is still above the target after the cooldown, scaling down
  does not happen
- If `minReplicaCount` is 0, the workload scales to 0 after cooldown
- If `minReplicaCount` is > 0, the workload scales to that minimum

### pollingInterval

`pollingInterval` specifies how often KEDA checks the metric source:

```yaml
spec:
  pollingInterval: 15  # Check every 15 seconds
```

Trade-offs:
- **Lower values** (5-15s): Faster reaction to events, but more load on the
  metric source
- **Higher values** (30-60s): Less load on the metric source, but slower
  reaction to events

### minReplicaCount vs minReplicaCount

KEDA distinguishes between `minReplicaCount` and the HPA's `minReplicas`:

- `minReplicaCount`: The absolute minimum replicas. If set to 0, the workload
  can scale to zero.
- The HPA's `minReplicas` is automatically set to `minReplicaCount` unless
  you override it via `advanced.minReplicaCount`.

```yaml
spec:
  minReplicaCount: 0          # KEDA minimum (scale to zero)
  advanced:
    minReplicaCount: 1        # HPA minimum (override)
```

---

## 6. Trigger Types

KEDA ships with 50+ built-in scalers. Here are the most commonly used:

### RabbitMQ

Scale based on queue length:

```yaml
triggers:
  - type: rabbitmq
    metadata:
      host: "amqp://user:pass@rabbitmq.default.svc.cluster.local:5672"
      queueName: "orders"
      queueLength: "50"
      mode: QueueLength
    authenticationRef:
      name: rabbitmq-auth
```

Modes:
- `QueueLength` (default): Scale based on the number of messages in the queue
- `MessageRate`: Scale based on the number of messages per second

Advanced options:

```yaml
metadata:
  host: "amqp://user:pass@rabbitmq.default.svc.cluster.local:5672"
  queueName: "orders"
  queueLength: "50"
  mode: QueueLength
  vhostName: "/"                    # Virtual host
  useRegex: "false"                 # Regex for queue name matching
  operation: "sum"                  # Aggregation for multiple queues
```

### Kafka

Scale based on consumer group lag:

```yaml
triggers:
  - type: kafka
    metadata:
      bootstrapServers: "kafka.default.svc.cluster.local:9092"
      consumerGroup: "order-consumer-group"
      topic: "orders"
      lagThreshold: "50"
      offsetResetPolicy: "latest"
    authenticationRef:
      name: kafka-auth
```

Advanced options:

```yaml
metadata:
  bootstrapServers: "kafka-0.kafka:9092,kafka-1.kafka:9092"
  consumerGroup: "my-group"
  topic: "my-topic"
  lagThreshold: "50"
  activationLagThreshold: "5"   # Scale from zero when lag >= this
  offsetResetPolicy: "latest"
  exposeStrategy: "plaintext"   # or "ssl"
  tls: "disable"                # or "enable"
  sasl: "none"                  # or "plain", "scram-sha-256", "scram-sha-512"
```

### Cron

Scale based on a cron schedule:

```yaml
triggers:
  - type: cron
    metadata:
      timezone: "America/New_York"
      start: "0 9 * * 1-5"      # 9 AM weekdays
      end: "17 * * 1-5"         # 5 PM weekdays
      desiredReplicas: "10"
```

The cron trigger is unique — it does not read a metric. Instead, it scales
to `desiredReplicas` during the `start`-`end` window and to
`minReplicaCount` outside of it.

You can have multiple cron triggers for different windows:

```yaml
triggers:
  - type: cron
    metadata:
      timezone: "UTC"
      start: "0 9 * * 1-5"
      end: "17 * * 1-5"
      desiredReplicas: "5"
  - type: cron
    metadata:
      timezone: "UTC"
      start: "0 0 * * 6,0"
      end: "23 * * 6,0"
      desiredReplicas: "1"
```

### CPU

Scale based on CPU utilization:

```yaml
triggers:
  - type: cpu
    metadata:
      type: Utilization
      value: "70"
```

### Memory

Scale based on memory utilization:

```yaml
triggers:
  - type: memory
    metadata:
      type: Utilization
      value: "80"
```

### HTTP (Prometheus-based)

Scale based on a custom HTTP metric endpoint:

```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: "http://prometheus.monitoring:9090"
      metricName: "http_requests_total"
      query: "sum(rate(http_requests_total{service='my-service'}[2m]))"
      threshold: "100"
      activationThreshold: "10"  # Scale from zero when metric >= this
```

### Prometheus

Scale based on a Prometheus query:

```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: "http://prometheus.monitoring:9090"
      metricName: "orders_pending"
      query: "sum(orders_pending_total) - sum(orders_processed_total)"
      threshold: "50"
      activationThreshold: "5"
```

### PostgreSQL

Scale based on a SQL query:

```yaml
triggers:
  - type: postgresql
    metadata:
      host: "postgres.default.svc.cluster.local"
      port: "5432"
      dbName: "mydb"
      query: "SELECT COUNT(*) FROM orders WHERE status = 'pending'"
      targetQueryValue: "50"
      sslmode: "require"
    authenticationRef:
      name: postgres-auth
```

### MongoDB

Scale based on a MongoDB query:

```yaml
triggers:
  - type: mongodb
    metadata:
      host: "mongodb.default.svc.cluster.local:27017"
      dbName: "mydb"
      collection: "orders"
      query: '{"status": "pending"}'
      targetQueryValue: "50"
      queryValue: "pendingCount"
      activationQueryValue: "5"
      metricName: "ordersPending"
    authenticationRef:
      name: mongodb-auth
```

### Redis

Scale based on Redis list length:

```yaml
triggers:
  - type: redis
    metadata:
      address: "redis.default.svc.cluster.local:6379"
      listName: "orders"
      listLength: "50"
      databaseIndex: "0"
      activationListLength: "5"
    authenticationRef:
      name: redis-auth
```

### Azure Service Bus

```yaml
triggers:
  - type: azure-servicebus
    metadata:
      namespace: "mysb"
      queueName: "orders"
      messageCount: "50"
```

### AWS SQS

```yaml
triggers:
  - type: aws-sqs-queue
    metadata:
      awsRegion: "us-east-1"
      queueURL: "https://sqs.us-east-1.amazonaws.com/123456789012/orders"
      queueLength: "50"
```

### Pending Connections (RabbitMQ)

```yaml
triggers:
  - type: rabbitmq
    metadata:
      host: "amqp://guest:guest@rabbitmq:5672"
      queueName: "orders"
      mode: QueueLength
      value: "50"
      queueDepth: "50"
```

### Multiple Triggers

Combine multiple triggers for complex scaling logic:

```yaml
spec:
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq:5672"
        queueName: "orders"
        queueLength: "50"
    - type: cron
      metadata:
        timezone: "UTC"
        start: "0 9 * * 1-5"
        end: "17 * * 1-5"
        desiredReplicas: "5"
    - type: cpu
      metadata:
        type: Utilization
        value: "80"
```

---

## 7. Scale to Zero

### How It Works

When `minReplicaCount` is 0, KEDA can scale a deployment to zero replicas.
This is the primary value proposition of KEDA.

The flow:
1. KEDA polls the metric source every `pollingInterval` seconds
2. If the metric value is at or below the target, KEDA checks if the current
   replica count exceeds `minReplicaCount`
3. If so, KEDA waits for `cooldownPeriod` seconds
4. If the metric is still below target after cooldown, KEDA scales down to
   `minReplicaCount` (which is 0)

### cooldownPeriod and Scale-Down

The cooldown period prevents premature scale-down. Consider a RabbitMQ queue
that briefly empties before new messages arrive:

```yaml
spec:
  minReplicaCount: 0
  cooldownPeriod: 600   # 10 minutes
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq:5672"
        queueName: "orders"
        queueLength: "10"
```

With this configuration:
- KEDA sees the queue has 0 messages
- KEDA waits 10 minutes (cooldown)
- If the queue is still empty after 10 minutes, KEDA scales to 0
- If a message arrives during the cooldown, the cooldown resets

### Pause

The `pause` attribute allows you to pause scaling for a specific duration after
the first scaling event:

```yaml
spec:
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq:5672"
        queueName: "orders"
        queueLength: "10"
      pause:
        duration: "60"   # Pause for 60 seconds after first scale event
```

This is useful for:
- Batch processing where you want to wait for a full batch
- Workloads that take time to initialize
- Avoiding thrashing in bursty scenarios

### Recovery

After scaling to zero, KEDA needs to scale back up when events arrive. The
recovery behavior depends on the metric source:

**RabbitMQ**: When a message arrives in an empty queue, the queue length becomes
1. KEDA detects this on the next poll (within `pollingInterval` seconds) and
scales up immediately.

**Kafka**: When a new message arrives in a topic with 0 consumers, the consumer
group lag increases. KEDA detects this and scales up.

**Cron**: KEDA scales up at the start of the cron window. If the deployment was
at 0, it scales to `desiredReplicaCount`.

### Scale-to-Zero Considerations

1. **Startup time**: If your application takes 30 seconds to start, that is 30
   seconds of latency for the first event. Consider setting `minReplicaCount: 1`
   for latency-sensitive workloads.

2. **Readiness probes**: Ensure your readiness probe is fast. KEDA considers a
   pod "ready" only when the readiness probe passes.

3. **Event loss**: No events are lost during scale-to-zero because the event
   source (e.g., RabbitMQ) holds events until a consumer connects.

4. **Multiple triggers**: If any trigger wants more than `minReplicaCount`, the
   maximum is used. So if trigger A wants 0 and trigger B wants 1, the result
   is 1.

---

## 8. ScaledObject Reference

### Full ScaledObject Spec

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
  annotations:
    scaledobject.keda.sh/paused-replica-count: "0"   # Force pause
spec:
  # Target workload
  scaleTargetRef:
    name: my-deployment                                # Required
    kind: Deployment                                   # Default: Deployment
    apiVersion: apps/v1                                # Default: apps/v1

  # Scaling parameters
  pollingInterval: 30                                  # Default: 30s
  cooldownPeriod: 300                                  # Default: 300s
  minReplicaCount: 0                                   # Default: 0
  maxReplicaCount: 100                                 # Default: 100

  # Advanced scaling behavior
  advanced:
    restoreToOriginalReplicaCount: false               # Restore after ScaledObject deletion
    horizontalPodAutoscalerConfig:
      name: hpa-custom-name                           # Custom HPA name
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
            - type: Percent
              value: 100
              periodSeconds: 15
            - type: Pods
              value: 4
              periodSeconds: 15
          selectPolicy: Max

    # Pause scaling for specific triggers
    scalingModifiers:
      formula: "max(coalesce(queue_scale, cron_scale))"
      targets:
        - name: queue_scale
          metricName: queue_length
        - name: cron_scale
          metricName: cron_replicas

  # Triggers
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq:5672"
        queueName: "orders"
        queueLength: "50"
      authenticationRef:
        name: rabbitmq-auth
```

### Field Reference

| Field | Type | Default | Description |
|---|---|---|---|
| `scaleTargetRef.name` | string | (required) | Name of the target workload |
| `scaleTargetRef.kind` | string | Deployment | Kind of workload (Deployment, StatefulSet, etc.) |
| `scaleTargetRef.apiVersion` | string | apps/v1 | API version of the workload |
| `pollingInterval` | int | 30 | Seconds between metric polls |
| `cooldownPeriod` | int | 300 | Seconds to wait before scaling down |
| `minReplicaCount` | int | 0 | Minimum replicas |
| `maxReplicaCount` | int | 100 | Maximum replicas |
| `advanced.restoreToOriginalReplicaCount` | bool | false | Restore original count on delete |
| `advanced.horizontalPodAutoscalerConfig` | object | (none) | Custom HPA configuration |
| `advanced.scalingModifiers` | object | (none) | Custom scaling formula |

### Annotations

KEDA supports annotations for runtime behavior:

```yaml
metadata:
  annotations:
    # Force pause all scaling (set to "true")
    autoscaling.keda.sh/paused: "true"

    # Set a specific paused replica count
    scaledobject.keda.sh/paused-replica-count: "3"
```

### Status Conditions

After creating a ScaledObject, check its status:

```bash
kubectl get scaledobject my-app -o yaml
```

Status fields:
- `conditions` — Standard Kubernetes conditions (Ready, Active, etc.)
- `currentMetricNames` — Currently active metric names
- `lastActiveTime` — When the ScaledObject was last active

---

## 9. TriggerAuthentication

TriggerAuthentication allows you to separate sensitive credentials from the
ScaledObject definition. This is critical for security — you do not want
passwords, API keys, or tokens in your ScaledObject YAML.

### TriggerAuthentication (Namespaced)

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
  namespace: default
spec:
  # Use a Kubernetes secret
  secretTargetRef:
    - parameter: host
      name: rabbitmq-secret
      key: host
    - parameter: password
      name: rabbitmq-secret
      key: password
  # Or use environment variables from a pod
  podAuthenticationRef:
    name: keda-auth-pod
    namespace: default
  # Or use parameters directly (less secure, not recommended)
  secretTargetRef: []
```

### ClusterTriggerAuthentication (Cluster-Wide)

```yaml
apiVersion: keda.sh/v1alpha1
kind: ClusterTriggerAuthentication
metadata:
  name: global-rabbitmq-auth
spec:
  secretTargetRef:
    - parameter: host
      name: rabbitmq-secret
      key: host
      # No namespace — uses the secret from any namespace
```

### Referencing TriggerAuthentication in ScaledObject

```yaml
spec:
  triggers:
    - type: rabbitmq
      metadata:
        queueName: "orders"
        queueLength: "50"
        # Host will be injected from the TriggerAuthentication
      authenticationRef:
        name: rabbitmq-auth
        kind: TriggerAuthentication   # or ClusterTriggerAuthentication
```

### Using SecretTargetRef

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
  namespace: default
spec:
  secretTargetRef:
    - parameter: host
      name: keda-secrets
      key: rabbitmq-host
    - parameter: username
      name: keda-secrets
      key: rabbitmq-username
    - parameter: password
      name: keda-secrets
      key: rabbitmq-password
```

With the corresponding Kubernetes Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: keda-secrets
  namespace: default
type: Opaque
data:
  rabbitmq-host: YW1xcDovL3VzZXI6cGFzc0ByYWJiaXRtcS5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2Fs
  rabbitmq-username: dXNlcg==
  rabbitmq-password: cGFzc3dvcmQ=
```

### Using Environment Variables from a Pod

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: env-auth
  namespace: default
spec:
  podAuthenticationRef:
    name: auth-pod
    namespace: default
```

The pod must have the environment variables set that match the trigger
metadata parameter names.

### Parameter Mapping

Different triggers expect different parameter names. Common mappings:

| Trigger | Parameter | Secret Key |
|---|---|---|
| RabbitMQ | `host` | `amqp://user:pass@host:5672` |
| Kafka | `bootstrapServers` | `kafka-0:9092,kafka-1:9092` |
| PostgreSQL | `host`, `username`, `password` | Separate keys |
| MongoDB | `host`, `username`, `password` | Separate keys |
| Redis | `address`, `password` | Separate keys |

---

## 10. KEDA + Vault

### HashiCorp Vault Integration

KEDA supports HashiCorp Vault as a secret backend. This allows you to use
Vault's dynamic secrets, rotation policies, and audit logging.

#### Setup

1. **Enable Kubernetes auth in Vault**:

```bash
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

2. **Create a Vault policy**:

```hcl
path "secret/data/keda/*" {
  capabilities = ["read"]
}

path "secret/data/rabbitmq/*" {
  capabilities = ["read"]
}
```

3. **Create a Vault role**:

```bash
vault write auth/kubernetes/role/keda-role \
  bound_service_account_names=keda-operator \
  bound_service_account_namespaces=keda \
  policies=keda-policy \
  ttl=1h
```

4. **Store secrets in Vault**:

```bash
vault kv put secret/keda/rabbitmq \
  host="amqp://user:pass@rabbitmq:5672" \
  password="secretpassword"
```

#### TriggerAuthentication with Vault

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: vault-auth
  namespace: default
spec:
  secretTargetRef:
    - parameter: host
      name: keda/rabbitmq
      key: host
      # KEDA uses the Vault provider to resolve this
```

Wait — KEDA does not have native Vault integration in the TriggerAuthentication
CRD. Instead, use the Vault Agent Injector pattern:

#### Vault Agent Injector Pattern

1. **Deploy Vault Agent Injector**:

```bash
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set "injector.enabled=true"
```

2. **Create a Vault secret**:

```bash
vault kv put secret/keda/rabbitmq \
  host="amqp://user:pass@rabbitmq:5672"
```

3. **Create an annotation-based injection**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keda-vault-proxy
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-config: "secret/keda/rabbitmq"
        vault.hashicorp.com/role: "keda-role"
```

4. **Use a sidecar or init container** to read Vault secrets and set
   environment variables that KEDA's `podAuthenticationRef` can reference.

#### Alternative: External Secrets Operator

The more practical approach for KEDA + Vault is the External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: keda-rabbitmq-secret
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: keda-rabbitmq-credentials
    creationPolicy: Owner
  data:
    - secretKey: host
      remoteRef:
        key: secret/keda/rabbitmq
        property: host
    - secretKey: password
      remoteRef:
        key: secret/keda/rabbitmq
        property: password
```

Then reference the resulting Kubernetes Secret in TriggerAuthentication.

---

## 11. KEDA Metrics

### Prometheus Metrics

KEDA exposes Prometheus metrics on the operator and metrics server. The default
port for the operator is `:8080` and for the metrics server is `:9090`.

Key metrics:

```
# Current metric value reported by a scaler
keda_scaler_metrics_value{scaledObject, scaler}

# Target value for the metric
keda_scaler_metrics_target{scaledObject, scaler}

# Whether the scaler is active (connected to event source)
keda_scaler_active{scaledObject, scaler}

# Current replica count of the target
keda_scaler_cur_replicas{scaledObject, scaler}

# Desired replica count calculated by KEDA
keda_scaler_desired_replicas{scaledObject, scaler}

# Error count for the scaler
keda_scaler_errors{scaledObject, scaler}

# Error count for the ScaledObject
keda_scaledobject_errors{scaledObject}
```

### Enabling Prometheus Scraping

```yaml
# In KEDA Helm values
metricsServer:
  enabled: true

# In your Prometheus config (ServiceMonitor)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: keda-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: keda-metrics-server
  endpoints:
    - port: http-metrics
      interval: 30s
```

### Grafana Dashboard

Import the official KEDA Grafana dashboard (ID: 13502) or create custom panels:

```json
{
  "panels": [
    {
      "title": "KEDA Scaler Active",
      "type": "stat",
      "targets": [
        {
          "expr": "keda_scaler_active{scaledObject=\"my-app\"}",
          "legendFormat": "{{scaler}}"
        }
      ]
    },
    {
      "title": "Current vs Desired Replicas",
      "type": "timeseries",
      "targets": [
        {
          "expr": "keda_scaler_cur_replicas{scaledObject=\"my-app\"}",
          "legendFormat": "Current"
        },
        {
          "expr": "keda_scaler_desired_replicas{scaledObject=\"my-app\"}",
          "legendFormat": "Desired"
        }
      ]
    }
  ]
}
```

### Custom Metrics Exposure

KEDA exposes custom metrics through the Kubernetes custom metrics API. This
means you can reference KEDA metrics in HPA directly:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: External
      external:
        metric:
          name: rabbitmq_queue_messages
          selector:
            matchLabels:
              queue: orders
        target:
          type: AverageValue
          averageValue: "50"
```

---

## 12. KEDA + ArgoCD

### GitOps for ScaledObjects

KEDA ScaledObjects are perfect for GitOps because they are declarative
Kubernetes resources. ArgoCD can manage them just like any other resource.

#### Directory Structure

```
argocd/
├── keda/
│   ├── keda-operator.yaml
│   └── keda-values.yaml
└── apps/
    ├── my-app/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── scaledobject.yaml      # KEDA ScaledObject
    └── another-app/
        ├── deployment.yaml
        └── scaledobject.yaml
```

#### ArgoCD Application for KEDA

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keda
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/gitops-repo.git
    targetRevision: main
    path: keda
  destination:
    server: https://kubernetes.default.svc
    namespace: keda
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### ArgoCD Application for Workloads with KEDA

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: order-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/gitops-repo.git
    targetRevision: main
    path: apps/order-service
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Handling KEDA in App of Apps

If you use the App of Apps pattern, ensure KEDA is installed before the
applications that depend on it:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: keda-apps
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/myorg/gitops-repo.git
        revision: main
        directories:
          - path: apps/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/gitops-repo.git
        targetRevision: main
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

#### Health Checks

ArgoCD can check KEDA ScaledObject health:

```yaml
configManagementPlugins: |
  keda:
    init:
      command: ["/bin/sh", "-c"]
      args: ["echo true"]
    generate:
      command: ["/bin/sh", "-c"]
      args: ["echo 'kind: ScaledObject'"]
```

#### Sync Waves

Use sync waves to ensure KEDA is installed before ScaledObjects:

```yaml
# KEDA operator
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keda-operator
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
# ...

# ScaledObject
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-app
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

---

## 13. KEDA + Helm

### Chart Structure

When packaging KEDA ScaledObjects in Helm charts:

```
charts/my-app/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── _helpers.tpl
│   └── scaledobject.yaml
└── templates/tests/
    └── test-connection.yaml
```

### values.yaml

```yaml
replicaCount: 1

image:
  repository: myregistry/my-app
  tag: "latest"
  pullPolicy: IfNotPresent

keda:
  enabled: true
  minReplicaCount: 0
  maxReplicaCount: 10
  pollingInterval: 30
  cooldownPeriod: 300
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://guest:guest@rabbitmq:5672"
        queueName: "orders"
        queueLength: "50"

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### templates/scaledobject.yaml

```yaml
{{- if .Values.keda.enabled }}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    name: {{ include "my-app.fullname" . }}
  pollingInterval: {{ .Values.keda.pollingInterval }}
  cooldownPeriod: {{ .Values.keda.cooldownPeriod }}
  minReplicaCount: {{ .Values.keda.minReplicaCount }}
  maxReplicaCount: {{ .Values.keda.maxReplicaCount }}
  triggers:
    {{- toYaml .Values.keda.triggers | nindent 4 }}
{{- end }}
```

### templates/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.keda.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

### Installing the Chart

```bash
# Install with KEDA enabled
helm install my-app ./charts/my-app \
  --set keda.enabled=true \
  --set keda.maxReplicaCount=20

# Install without KEDA (use HPA instead)
helm install my-app ./charts/my-app \
  --set keda.enabled=false \
  --set replicaCount=2
```

### Advanced: TriggerAuthentication in Helm

```yaml
# values.yaml
keda:
  triggerAuth:
    enabled: true
    name: rabbitmq-auth
    secretRef: keda-rabbitmq-credentials
    secretKeys:
      host: host
      password: password

# templates/trigger-authentication.yaml
{{- if .Values.keda.triggerAuth.enabled }}
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: {{ .Values.keda.triggerAuth.name }}
spec:
  secretTargetRef:
    - parameter: host
      name: {{ .Values.keda.triggerAuth.secretRef }}
      key: {{ .Values.keda.triggerAuth.secretKeys.host }}
    - parameter: password
      name: {{ .Values.keda.triggerAuth.secretRef }}
      key: {{ .Values.keda.triggerAuth.secretKeys.password }}
{{- end }}
```

---

## 14. Troubleshooting

### 1. ScaledObject stuck in "Pending" state

**Symptoms**:
```bash
kubectl get scaledobject my-app
# NAME      STATUS    TRIGGERS   READY   ACTIVE   SCALED
# my-app    Pending   1          False   Unknown  Unknown
```

**Diagnosis**:
```bash
kubectl describe scaledobject my-app
kubectl logs -n keda deployment/keda-operator
```

**Common causes**:
- Target deployment does not exist
- KEDA operator cannot access the event source
- RBAC issues (operator cannot read the target deployment)
- TriggerAuthentication is misconfigured

**Fix**:
```bash
# Check if target deployment exists
kubectl get deployment my-app

# Check operator logs for errors
kubectl logs -n keda deployment/keda-operator --tail=100

# Verify RBAC
kubectl auth can-i get deployments -n default
```

### 2. ScaledObject shows "Active" but deployment not scaling

**Symptoms**:
- ScaledObject shows `ACTIVE` status
- Deployment replica count does not change

**Diagnosis**:
```bash
kubectl get hpa
kubectl describe hpa <hpa-name>
```

**Common causes**:
- HPA minReplicas > 0 while KEDA minReplicaCount is 0
- HPA behavior policies limiting scale-up
- Deployment has maxUnavailable/maxSurge blocking scaling

**Fix**:
```bash
# Check HPA details
kubectl get hpa -o yaml

# Check deployment scaling config
kubectl get deployment my-app -o jsonpath='{.spec.strategy}'
```

### 3. Metrics server not returning metrics

**Symptoms**:
```bash
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/rabbitmq_queue_length"
# Error from server (NotFound): the server could not find the requested resource
```

**Diagnosis**:
```bash
kubectl get apiservice | grep metrics
kubectl logs -n keda deployment/keda-metrics-server
```

**Fix**:
```bash
# Ensure metrics server is running
kubectl get pods -n keda -l app=keda-metrics-server

# Check if apiservice is registered
kubectl get apiservice v1beta1.external.metrics.k8s.io -o yaml
```

### 4. RabbitMQ trigger shows "queue not found"

**Symptoms**:
```bash
kubectl logs -n keda deployment/keda-operator | grep "queue not found"
```

**Diagnosis**:
```bash
# Verify queue exists
kubectl exec -it rabbitmq-0 -- rabbitmqctl list_queues

# Test connectivity
kubectl run rmq-test --rm -it --image=busybox -- wget -qO- http://guest:guest@rabbitmq:15672/api/queues
```

**Fix**:
- Ensure `queueName` matches exactly (case-sensitive)
- Ensure `host` URL is correct (protocol, port, vhost)
- Check RabbitMQ network policies

### 5. Kafka trigger shows "consumer group not found"

**Symptoms**:
```bash
kubectl logs -n keda deployment/keda-operator | grep "consumer group"
```

**Fix**:
```bash
# Verify consumer group exists
kubectl exec -it kafka-0 -- kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Check topic exists
kubectl exec -it kafka-0 -- kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### 6. Scale-to-zero not working

**Symptoms**:
- Deployment never scales below 1 replica
- ScaledObject shows `minReplicaCount: 0`

**Diagnosis**:
```bash
kubectl get hpa -o yaml | grep minReplicas
kubectl get deployment my-app -o jsonpath='{.spec.replicas}'
```

**Common causes**:
- HPA has `minReplicas: 1` (not overridden by KEDA)
- `restoreToOriginalReplicaCount: true` restores original count on ScaledObject deletion
- A second trigger has a higher `minReplicaCount`

**Fix**:
```yaml
# Explicitly set HPA minimum
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      minReplicas: 0
```

### 7. Cron trigger not scaling

**Symptoms**:
- Cron trigger defined but deployment does not scale during the window

**Diagnosis**:
```bash
# Check timezone
date -u
date

# Verify cron expression
# "0 9 * * 1-5" = 9 AM weekdays
```

**Fix**:
- Ensure `timezone` is correct (e.g., `America/New_York`)
- Verify the cron expression syntax
- Check if another trigger is overriding (maximum wins)

### 8. PostgreSQL trigger connection refused

**Symptoms**:
```bash
kubectl logs -n keda deployment/keda-operator | grep "connection refused"
```

**Fix**:
```bash
# Test connectivity
kubectl run pg-test --rm -it --image=busybox -- nc -zv postgres 5432

# Verify credentials
kubectl exec -it postgres-0 -- psql -U user -d mydb -c "SELECT 1"
```

### 9. Memory leak in KEDA operator

**Symptoms**:
- KEDA operator pod OOMKilled
- Increasing memory usage over time

**Diagnosis**:
```bash
kubectl top pod -n keda
kubectl describe pod -n keda deployment/keda-operator
```

**Fix**:
- Set resource limits in KEDA Helm values
- Update to the latest KEDA version (memory leaks are often fixed)
- File a GitHub issue with heap dump

### 10. Scaling too aggressively (thrashing)

**Symptoms**:
- Pods constantly scaling up and down
- Application instability

**Fix**:
```yaml
spec:
  cooldownPeriod: 600          # Increase cooldown
  pollingInterval: 60          # Reduce polling frequency
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 600
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
```

### 11. Scale-up is too slow

**Symptoms**:
- Queue depth increases rapidly but pods scale up slowly

**Fix**:
```yaml
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
            - type: Percent
              value: 100
              periodSeconds: 15
            - type: Pods
              value: 10
              periodSeconds: 15
          selectPolicy: Max
```

### 12. TriggerAuthentication secrets not updating

**Symptoms**:
- Old password still being used after secret update

**Fix**:
- KEDA caches secrets; you may need to restart the operator
- TriggerAuthentication reads secrets on each poll (usually works)
- Verify the secret data matches the expected keys

```bash
kubectl rollout restart deployment keda-operator -n keda
```

### 13. KEDA conflicts with existing HPA

**Symptoms**:
- Two HPAs fighting over the same deployment
- Unexpected scaling behavior

**Fix**:
- KEDA creates its own HPA. Ensure no other HPA targets the same deployment
- Check for manual HPA creation:
```bash
kubectl get hpa
kubectl delete hpa <manual-hpa-name>
```

### 14. ScaledObject not being created by Helm

**Symptoms**:
- `helm upgrade` does not create ScaledObject

**Fix**:
- Check `keda.enabled` in values.yaml
- Ensure template syntax is correct
- Test with `helm template`:
```bash
helm template my-app ./charts/my-app --set keda.enabled=true
```

### 15. Network policies blocking KEDA

**Symptoms**:
- KEDA cannot reach event sources
- Connection timeouts in operator logs

**Fix**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-keda
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: keda
  ingress:
    - from: []
  egress:
    - to: []
```

---

## 15. Tips & Best Practices

### 1. Start with Conservative Settings

Begin with:
```yaml
pollingInterval: 30
cooldownPeriod: 300
minReplicaCount: 1   # Not 0 initially
maxReplicaCount: 10
```

Tune after observing behavior in production.

### 2. Use TriggerAuthentication for Secrets

Never hardcode credentials in ScaledObject metadata. Always use
TriggerAuthentication or ClusterTriggerAuthentication with Kubernetes Secrets.

### 3. Monitor KEDA Metrics

Set up Prometheus scraping and Grafana dashboards to visualize:
- Scaler activity and errors
- Current vs desired replicas
- Metric values over time

### 4. Test Trigger Configuration

Before deploying, test your trigger configuration:

```bash
# Dry-run the scaler logic
kubectl logs -n keda deployment/keda-operator -f | grep my-scaled-object

# Check metric values
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/my-metric"
```

### 5. Use Activation Thresholds for Scale-to-Zero

The `activationThreshold` (or `activationLagThreshold` for Kafka) determines
when to scale from zero. Set it lower than your main threshold:

```yaml
triggers:
  - type: rabbitmq
    metadata:
      queueLength: "50"          # Scale up when > 50
      activationThreshold: "5"   # Scale from 0 when > 5
```

This prevents scaling from zero for every single message but avoids waiting
until 50 messages accumulate.

### 6. Combine with HPA for Complex Scenarios

KEDA creates an HPA under the hood. You can customize the HPA behavior:

```yaml
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      name: my-custom-hpa
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
            - type: Pods
              value: 4
              periodSeconds: 60
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 10
              periodSeconds: 60
```

### 7. Use Pausing for Maintenance

During maintenance, pause scaling:

```bash
kubectl annotate scaledobject my-app \
  autoscaling.keda.sh/paused="true"
```

Or set a specific replica count:

```bash
kubectl annotate scaledobject my-app \
  scaledobject.keda.sh/paused-replica-count="3"
```

### 8. Use RestoreToOriginalReplicaCount

If you want the deployment to return to its original replica count when the
ScaledObject is deleted:

```yaml
spec:
  advanced:
    restoreToOriginalReplicaCount: true
```

### 9. Version Control ScaledObjects

Keep ScaledObjects in Git alongside deployments. This provides:
- Audit trail of scaling changes
- Rollback capability
- Consistency across environments
- Code review for scaling policy changes

### 10. Set Appropriate Resource Requests

Ensure pods have proper resource requests/limits so Kubernetes can schedule
them correctly:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 11. Use Multiple Triggers Wisely

Multiple triggers use a `max()` strategy — the highest replica count wins.
This can lead to over-provisioning. Consider using `scalingModifiers` for
custom logic.

### 12. Use Pause for Batch Processing

For workloads that process batches, use the `pause` attribute:

```yaml
triggers:
  - type: rabbitmq
    metadata:
      queueLength: "100"
    pause:
      duration: "120"   # Wait 2 minutes after first scale
```

### 13. Keep Polling Intervals Reasonable

Very low polling intervals (1-5s) can overload the event source. Very high
intervals (60-120s) can delay scaling. 15-30s is a good balance for most
workloads.

### 14. Use Activation Thresholds for Bursty Workloads

For workloads with sudden bursts, set a low activation threshold so KEDA
scales from zero quickly, and a higher main threshold for sustained scaling:

```yaml
triggers:
  - type: prometheus
    metadata:
      threshold: "100"
      activationThreshold: "1"
```

### 15. Monitor Queue Depth Independently

Even with KEDA, monitor your queues directly. KEDA might miss edge cases
like:
- Dead-letter queues
- Message TTL expiring
- Consumer errors causing message requeue

### 16. Document Scaling Policies

Add comments to your ScaledObjects explaining:
- Why these thresholds were chosen
- Expected behavior during peak/off-peak
- Who to contact for scaling issues
- Links to runbooks

### 17. Test Scaling Under Load

Before production, simulate load:

```bash
# Send messages to RabbitMQ
for i in $(seq 1 1000); do
  kubectl exec -it rabbitmq-0 -- rabbitmqadmin \
    publish exchange=amq.default routing_key=orders \
    payload="test-message-$i"
done

# Watch scaling
kubectl get scaledobject my-app -w
kubectl get pods -l app=my-app -w
```

### 18. Use KEDA for Dev/Prod Parity

Use the same ScaledObject definition across environments with different values:

```yaml
# values-dev.yaml
keda:
  minReplicaCount: 0
  maxReplicaCount: 3

# values-prod.yaml
keda:
  minReplicaCount: 2
  maxReplicaCount: 50
```

---

## 16. Real-World Example — Contoso Pet Store

### Architecture Overview

The Contoso Pet Store is an e-commerce application with the following
microservices:

- **order-service** — Receives orders via REST API, pushes to RabbitMQ
- **virtual-customer** — Simulates customer orders (for demo/testing)
- **virtual-worker** — Processes orders from RabbitMQ queue
- **core services** — Supporting services (catalog, auth, etc.)

### RabbitMQ Setup

```yaml
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: rabbitmq
  namespace: petstore
spec:
  replicas: 3
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1
      memory: 2Gi
```

### TriggerAuthentication for RabbitMQ

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmq-credentials
  namespace: petstore
type: Opaque
data:
  host: YW1xcDovL3VzZXI6cGFzc0ByYWJiaXRtcS5wZXRzdG9yZS5zdmMuY2x1c3Rlci5sb2NhbDo1Njcy
  password: Z3Vlc3Q=
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
  namespace: petstore
spec:
  secretTargetRef:
    - parameter: host
      name: rabbitmq-credentials
      key: host
    - parameter: password
      name: rabbitmq-credentials
      key: password
```

### order-service Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: petstore
  labels:
    app: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
        - name: order-service
          image: contoso/order-service:latest
          ports:
            - containerPort: 8080
          env:
            - name: RABBITMQ_HOST
              value: "rabbitmq.petstore.svc.cluster.local"
            - name: RABBITMQ_QUEUE
              value: "orders"
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 20
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-service-so
  namespace: petstore
spec:
  scaleTargetRef:
    name: order-service
  pollingInterval: 15
  cooldownPeriod: 300
  minReplicaCount: 2
  maxReplicaCount: 20
  triggers:
    - type: cpu
      metadata:
        type: Utilization
        value: "75"
    - type: memory
      metadata:
        type: Utilization
        value: "80"
```

### virtual-customer Deployment (Cron-Based)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: virtual-customer
  namespace: petstore
  labels:
    app: virtual-customer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: virtual-customer
  template:
    metadata:
      labels:
        app: virtual-customer
    spec:
      containers:
        - name: virtual-customer
          image: contoso/virtual-customer:latest
          env:
            - name: RABBITMQ_HOST
              value: "rabbitmq.petstore.svc.cluster.local"
            - name: RABBITMQ_QUEUE
              value: "orders"
            - name: ORDERS_PER_MINUTE
              value: "100"
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: virtual-customer-so
  namespace: petstore
spec:
  scaleTargetRef:
    name: virtual-customer
  pollingInterval: 30
  cooldownPeriod: 60
  minReplicaCount: 0
  maxReplicaCount: 5
  triggers:
    - type: cron
      metadata:
        timezone: "America/New_York"
        start: "0 9 * * 1-5"       # 9 AM weekdays
        end: "17 * * 1-5"          # 5 PM weekdays
        desiredReplicas: "3"
    - type: cron
      metadata:
        timezone: "America/New_York"
        start: "0 0 * * 6,0"       # All day weekends
        end: "23 * * 6,0"
        desiredReplicas: "1"
```

### virtual-worker Deployment (Queue-Based, Scale to Zero)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: virtual-worker
  namespace: petstore
  labels:
    app: virtual-worker
spec:
  replicas: 0
  selector:
    matchLabels:
      app: virtual-worker
  template:
    metadata:
      labels:
        app: virtual-worker
    spec:
      containers:
        - name: virtual-worker
          image: contoso/virtual-worker:latest
          env:
            - name: RABBITMQ_HOST
              value: "rabbitmq.petstore.svc.cluster.local"
            - name: RABBITMQ_QUEUE
              value: "orders"
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: virtual-worker-so
  namespace: petstore
spec:
  scaleTargetRef:
    name: virtual-worker
  pollingInterval: 10
  cooldownPeriod: 600        # 10 minutes — let workers finish processing
  minReplicaCount: 0
  maxReplicaCount: 30
  triggers:
    - type: rabbitmq
      metadata:
        host: "amqp://user:pass@rabbitmq.petstore.svc.cluster.local:5672"
        queueName: "orders"
        queueLength: "50"
        mode: QueueLength
      authenticationRef:
        name: rabbitmq-auth
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleUp:
          stabilizationWindowSeconds: 0
          policies:
            - type: Pods
              value: 5
              periodSeconds: 60
            - type: Percent
              value: 100
              periodSeconds: 60
          selectPolicy: Max
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 25
              periodSeconds: 120
```

### Core Services (CPU/Memory Based)

```yaml
# catalog-service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-service
  namespace: petstore
spec:
  replicas: 2
  selector:
    matchLabels:
      app: catalog-service
  template:
    metadata:
      labels:
        app: catalog-service
    spec:
      containers:
        - name: catalog-service
          image: contoso/catalog-service:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: catalog-service-so
  namespace: petstore
spec:
  scaleTargetRef:
    name: catalog-service
  pollingInterval: 30
  cooldownPeriod: 300
  minReplicaCount: 2
  maxReplicaCount: 10
  triggers:
    - type: cpu
      metadata:
        type: Utilization
        value: "70"
    - type: memory
      metadata:
        type: Utilization
        value: "80"

# auth-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: petstore
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
        - name: auth-service
          image: contoso/auth-service:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: auth-service-so
  namespace: petstore
spec:
  scaleTargetRef:
    name: auth-service
  pollingInterval: 30
  cooldownPeriod: 300
  minReplicaCount: 2
  maxReplicaCount: 5
  triggers:
    - type: cpu
      metadata:
        type: Utilization
        value: "80"
```

### Summary Table

| Service | Min | Max | Trigger | Cooldown |
|---|---|---|---|---|
| order-service | 2 | 20 | CPU 75%, Memory 80% | 300s |
| virtual-customer | 0 | 5 | Cron (business hours) | 60s |
| virtual-worker | 0 | 30 | RabbitMQ queue > 50 | 600s |
| catalog-service | 2 | 10 | CPU 70%, Memory 80% | 300s |
| auth-service | 2 | 5 | CPU 80% | 300s |

---

## 17. Commands Reference

### ScaledObject Operations

```bash
# List all ScaledObjects
kubectl get scaledobjects --all-namespaces

# Get details of a ScaledObject
kubectl describe scaledobject my-app

# Watch ScaledObject status
kubectl get scaledobject my-app -w

# Get ScaledObject as YAML
kubectl get scaledobject my-app -o yaml

# Delete a ScaledObject
kubectl delete scaledobject my-app

# Check ScaledObject conditions
kubectl get scaledobject my-app -o jsonpath='{.status.conditions}'
```

### TriggerAuthentication Operations

```bash
# List all TriggerAuthentications
kubectl get triggerauthentications --all-namespaces

# List ClusterTriggerAuthentications
kubectl get clustertriggerauthentications

# Get details
kubectl describe triggerauthentication my-auth

# Delete
kubectl delete triggerauthentication my-auth
```

### KEDA Operator Management

```bash
# Check KEDA pods
kubectl get pods -n keda

# View operator logs
kubectl logs -n keda deployment/keda-operator -f

# View metrics server logs
kubectl logs -n keda deployment/keda-metrics-server -f

# Restart KEDA operator
kubectl rollout restart deployment keda-operator -n keda

# Scale KEDA operator (for maintenance)
kubectl scale deployment keda-operator -n keda --replicas=2
```

### Metrics Inspection

```bash
# List available external metrics
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" | jq .

# List metrics in a namespace
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default" | jq .

# Get a specific metric
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/rabbitmq_queue_length" | jq .

# Check custom metrics
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .
```

### HPA Inspection

```bash
# List HPAs managed by KEDA
kubectl get hpa

# Get HPA details
kubectl describe hpa <hpa-name>

# Watch HPA scaling
kubectl get hpa -w

# Get HPA metrics
kubectl get hpa -o yaml
```

### Debugging

```bash
# Check KEDA events
kubectl get events -n keda --sort-by='.lastTimestamp'

# Check for RBAC issues
kubectl auth can-i get scaledobjects -n default
kubectl auth can-i create deployments -n default

# Test Prometheus connectivity
kubectl run prom-test --rm -it --image=curlimages/curl -- \
  curl -s "http://prometheus:9090/api/v1/query?query=up"

# Test RabbitMQ connectivity
kubectl run rmq-test --rm -it --image=busybox -- \
  wget -qO- "http://guest:guest@rabbitmq:15672/api/queues"

# Port-forward to KEDA metrics server
kubectl port-forward -n keda svc/keda-metrics-server 9090:9090

# Port-forward to KEDA operator
kubectl port-forward -n keda svc/keda-operator 8080:8080
```

### Pause/Resume Scaling

```bash
# Pause scaling
kubectl annotate scaledobject my-app \
  autoscaling.keda.sh/paused="true"

# Resume scaling
kubectl annotate scaledobject my-app \
  autoscaling.keda.sh/paused="false" --overwrite

# Set specific replica count while paused
kubectl annotate scaledobject my-app \
  scaledobject.keda.sh/paused-replica-count="3"
```

### Helm Operations

```bash
# Install KEDA with Helm
helm install keda kedacore/keda -n keda --create-namespace

# Upgrade KEDA
helm upgrade keda kedacore/keda -n keda

# View KEDA Helm values
helm show values kedacore/keda

# Uninstall KEDA
helm uninstall keda -n keda
```

### Load Testing

```bash
# Send test messages to RabbitMQ
kubectl exec -it rabbitmq-0 -- rabbitmqadmin \
  publish exchange=amq.default routing_key=orders \
  payload='{"orderId": "test-001", "item": "pet-food"}'

# Send messages in a loop
for i in $(seq 1 100); do
  kubectl exec -it rabbitmq-0 -- rabbitmqadmin \
    publish exchange=amq.default routing_key=orders \
    payload="{\"orderId\": \"test-$i\"}"
  sleep 0.1
done

# Watch scaling in real-time
kubectl get pods -l app=virtual-worker -w
```

---

## 18. Further Reading

### Official Documentation

- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA GitHub Repository](https://github.com/kedacore/keda)
- [KEDA Helm Chart](https://github.com/kedacore/charts)
- [KEDA Scalers List](https://keda.sh/docs/latest/scalers/)

### Tutorials and Guides

- [KEDA Quick Start](https://keda.sh/docs/latest/getting-started/)
- [KEDA RabbitMQ Scaler](https://keda.sh/docs/latest/scalers/rabbitmq-queue/)
- [KEDA Kafka Scaler](https://keda.sh/docs/latest/scalers/apache-kafka/)
- [KEDA Cron Scaler](https://keda.sh/docs/latest/scalers/cron/)
- [KEDA Prometheus Scaler](https://keda.sh/docs/latest/scalers/prometheus/)
- [Scale to Zero with KEDA](https://keda.sh/docs/latest/concepts/how-it-works/)

### Related Projects

- [KEDA HTTP Add-on](https://github.com/kedacore/http-add-on) — HTTP-based autoscaling
- [KEDA Terraform Provider](https://github.com/kedacore/terraform-provider-keda)
- [External Secrets Operator](https://external-secrets.io/) — For Vault integration
- [Prometheus Adapter](https://github.com/kubernetes-sigs/prometheus-adapter) — For custom metrics

### Community

- [KEDA Slack](https://cloud-native.slack.com/messages/keda)
- [CNCF Slack](https://cloud-native.slack.com)
- [KEDA Discussions](https://github.com/kedacore/keda/discussions)
- [KEDA Issues](https://github.com/kedacore/keda/issues)

### Books and Videos

- "Kubernetes Autoscaling" by Jérôme Petazzoni
- "Learning Kubernetes" by Vaishali S (Chapter on Autoscaling)
- CNCF Webinar: "KEDA: Event-Driven Autoscaling for Kubernetes"
- YouTube: "KEDA Deep Dive" by KEDA maintainers

### Example Repositories

- [KEDA Samples](https://github.com/kedacore/keda/tree/main/tests)
- [Contoso Pet Store Reference App](https://github.com/microsoft/samples-journey-to-the-cloud)
- [KEDA on Azure](https://docs.microsoft.com/azure/aks/keda-about)
- [KEDA on EKS](https://aws.amazon.com/blogs/containers/scaling-kubernetes-with-keda/)
- [KEDA on GKE](https://cloud.google.com/blog/products/containers-data-tools/autoscaling-with-keda-on-gke)

---

*Last updated: 2026*
*KEDA Version: 2.14+*
*Kubernetes Version: 1.28+*
