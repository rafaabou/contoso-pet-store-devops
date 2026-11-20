# Jaeger Complete Guide

## Table of Contents

1. [What Is Jaeger](#1-what-is-jaeger)
2. [Why Use Jaeger](#2-why-use-jaeger)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide](#7-usage-guide)
8. [Custom Instrumentation](#8-custom-instrumentation)
9. [Collector & Agent Configuration](#9-collector--agent-configuration)
10. [Storage Backends](#10-storage-backends)
11. [Integration](#11-integration)
12. [Security](#12-security)
13. [Troubleshooting](#13-troubleshooting)
14. [Tips & Best Practices](#14-tips--best-practices)
15. [Command Reference](#15-command-reference)
16. [Configuration Reference](#16-configuration-reference)
17. [Real-World Examples](#17-real-world-examples)
18. [Further Reading](#18-further-reading)

---

## 1. What Is Jaeger

Jaeger is an open-source distributed tracing system originally developed by Uber Technologies. It implements the OpenTracing standard and is now a graduated project of the Cloud Native Computing Foundation (CNCF). Jaeger helps engineers monitor and troubleshoot microservice-based distributed systems by providing end-to-end visibility into request flows across service boundaries.

### 1.1 Purpose

Jaeger captures distributed traces — records of the causal relationships between operations across services. When a user request flows through multiple microservices, Jaeger records timing, errors, and metadata for each step, enabling developers to understand latency, identify bottlenecks, and diagnose failures.

### 1.2 History

- **2015**: Uber begins development of Jaeger internally
- **2017**: Jaeger open-sourced
- **2018**: Joined CNCF as an incubating project
- **2019**: Graduated from CNCF incubation
- **2022+**: Became the reference implementation for OpenTelemetry tracing backends

### 1.3 Key Features

- Multi-platform support: Java, Go, Python, Node.js, C++, .NET, and more
- Multiple storage backends: Cassandra, Elasticsearch, Kafka, memory
- Supports both OpenTracing and OpenTelemetry (OTLP) ingestion
- Service dependency graph visualization
- Trace comparison and diffing
- Intelligent sampling (adaptive, rate-limiting, probabilistic)
- High availability and horizontal scaling

---

## 2. Why Use Jaeger

### 2.1 Distributed Tracing Benefits

| Problem | How Jaeger Helps |
|---|---|
| Latency is high but unclear which service is slow | Shows per-span timing across the full call tree |
| Intermittent errors in production | Links error traces to root cause service |
| Request fails with no obvious error log | Full trace shows which downstream call returned 5xx |
| Debugging cross-service RPC failures | Visualizes the entire request path with timing |
| Capacity planning | Aggregated latency data informs SLO budgets |

### 2.2 Jaeger vs Other Tracing Systems

| Feature | Jaeger | Zipkin | Tempo |
|---|---|---|---|
| OpenTelemetry native | Yes | Partial | Yes |
| Storage | Cassandra, ES, Kafka | ES, Cassandra, MySQL | Object storage |
| Sampling | Adaptive, rate-limiting | Fixed, rate-limiting | N/A |
| Service graph | Yes (via Prometheus) | Yes (via Zipkin UI) | Yes (Grafana) |
| Kubernetes operator | Yes | No | No |
| CNCF status | Graduated | N/A | GA |

### 2.3 Use Cases

1. **Microservice latency optimization** — find the slowest hop
2. **Error propagation analysis** — trace where errors originate
3. **Service dependency mapping** — auto-discover service graph
4. **Performance regression detection** — compare traces across deploys
5. **SLA/SLO monitoring** — track p99 latencies per endpoint

---

## 3. Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  App Pod A   │    │  App Pod B   │    │  App Pod C   │
│  (SDK+Agent) │    │  (SDK+Agent) │    │  (SDK+Agent) │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │ UDP:6831          │ UDP:6831          │ UDP:6831
       └──────────┬────────┴────────┬──────────┘
                  ▼                 ▼
            ┌─────────────────────────────┐
            │     Jaeger Agent (per node) │
            │   Receives spans via UDP     │
            │   Batches and forwards       │
            └─────────────┬───────────────┘
                          │ gRPC:14250 / HTTP:14268
                          ▼
            ┌─────────────────────────────┐
            │     Jaeger Collector         │
            │   Validates & processes      │
            │   Writes to storage          │
            └─────────────┬───────────────┘
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
        ┌──────────┐ ┌─────────┐ ┌──────────┐
        │ Cassandra │ │  ES     │ │  Kafka   │
        └──────────┘ └─────────┘ └──────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │   Jaeger Query  │
                 │   + UI (port    │
                 │     16686)      │
                 └─────────────────┘
```

### 3.1 Components

| Component | Role | Port(s) |
|---|---|---|
| **Client SDK** | Instruments application code, creates spans | N/A |
| **Agent** | Sidecar/daemon; receives spans from SDK, batches, forwards | UDP 6831, gRPC 6832 |
| **Collector** | Receives spans from Agent, validates, writes to storage | HTTP 14268, gRPC 14250 |
| **Query** | Reads from storage, serves API | HTTP 16687 |
| **UI** | Web frontend for trace visualization | HTTP 16686 |
| **Ingester** | Optional; reads from Kafka, writes to storage (for HA) | N/A |

### 3.2 Data Flow

1. Application creates a span via the Jaeger SDK (or OpenTelemetry SDK with Jaeger exporter)
2. Span is sent via UDP/gRPC to the local Jaeger Agent
3. Agent batches spans and forwards them to the Collector
4. Collector validates, enriches, and writes spans to the configured storage backend
5. Query service reads spans from storage and serves them to the UI
6. UI renders traces as waterfall charts, dependency graphs, and service statistics

---

## 4. Installation

### 4.1 Docker Compose (Development)

```yaml
version: '3.8'
services:
  jaeger:
    image: jaegertracing/all-in-one:1.53
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "16686:16686"   # UI
      - "4317:4317"     # OTLP gRPC
      - "4318:4318"     # OTLP HTTP
      - "6831:6831/udp" # Agent compact thrift
      - "6832:6832"     # Agent binary thrift
      - "14268:14268"   # Collector HTTP
      - "14250:14250"   # Collector gRPC
    volumes:
      - jaeger-data:/badger
    restart: unless-stopped

volumes:
  jaeger-data:
```

Start with:
```bash
docker compose up -d
# UI at http://localhost:16686
```

### 4.2 Kubernetes with Operator

```bash
# Install the Jaeger Operator
kubectl create namespace observability
kubectl apply -n observability -f \
  https://github.com/jaegertracing/jaeger-operator/releases/latest/download/jaeger-operator.yaml

# Wait for operator
kubectl wait --for=condition=Available deployment/jaeger-operator \
  -n observability --timeout=120s

# Deploy Jaeger instance
cat <<EOF | kubectl apply -n observability -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: production
spec:
  strategy: production
  collector:
    replicas: 3
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: https://elasticsearch:9200
        index-prefix: jaeger
    esIndexCleaner:
      enabled: true
      numberOfDays: 14
      schedule: "55 23 * * *"
  query:
    replicas: 2
EOF
```

### 4.3 Kubernetes with Helm

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Production with Elasticsearch
helm install jaeger jaegertracing/jaeger -n observability --create-namespace \
  --set provisionDataStore.cassandra=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=elasticsearch \
  --set storage.elasticsearch.port=9200 \
  --set collector.replicaCount=3 \
  --set query.replicaCount=2
```

### 4.4 Bare Metal / Systemd

```bash
# Download binary
JAEGER_VERSION=1.53.0
curl -LO https://github.com/jaegertracing/jaeger/releases/download/v${JAEGER_VERSION}/jaeger-${JAEGER_VERSION}-linux-amd64.tar.gz
tar xzf jaeger-${JAEGER_VERSION}-linux-amd64.tar.gz
sudo cp jaeger-${JAEGER_VERSION}-linux-amd64/jaeger-* /usr/local/bin/

# Systemd service
cat <<EOF | sudo tee /etc/systemd/system/jaeger.service
[Unit]
Description=Jaeger Tracing Backend
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/jaeger-all-in-one \
  --collector.otlp.enabled=true \
  --badger.span-store-ttl=168h \
  --badger.span-store-directory=/var/lib/jaeger/badger
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /var/lib/jaeger/badger
sudo systemctl daemon-reload
sudo systemctl enable --now jaeger
```

### 4.5 Docker Standalone

```bash
# In-memory (development only)
docker run -d --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.53

# With Elasticsearch
docker run -d --name jaeger \
  -e SPAN_STORAGE_TYPE=elasticsearch \
  -e ES_SERVER_URLS=http://elasticsearch:9200 \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.53
```

---

## 5. Configuration

### 5.1 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `SPAN_STORAGE_TYPE` | `badger` | Storage backend: `cassandra`, `elasticsearch`, `badger`, `memory` |
| `COLLECTOR_OTLP_ENABLED` | `false` | Enable OpenTelemetry OTLP receiver |
| `ES_SERVER_URLS` | `http://localhost:9200` | Elasticsearch server URLs |
| `CASSANDRA_SERVERS` | `localhost` | Cassandra contact points |
| `KAFKA_BROKERS` | `localhost:9092` | Kafka broker addresses |
| `COLLECTOR_ZIPKIN_HOST_PORT` | `:0` | Zipkin-compatible endpoint port |
| `AGENT_HOST_PORT` | `:6831` | Agent UDP endpoint |
| `COLLECTOR_HTTP_HOST_PORT` | `:14268` | Collector HTTP endpoint |
| `COLLECTOR_GRPC_HOST_PORT` | `:14250` | Collector gRPC endpoint |
| `QUERY_HTTP_HOST_PORT` | `:16687` | Query API HTTP endpoint |
| `QUERY_UI_HOST_PORT` | `:16686` | UI HTTP endpoint |
| `BADGER_SPAN_STORE_DIRECTORY` | `/var/lib/jaeger/badger` | Badger storage path |
| `BADGER_SPAN_STORE_TTL` | `720h` | Span retention (hours) |

### 5.2 Command-Line Flags

```bash
# All-in-one with all features
jaeger-all-in-one \
  --span-storage.type=elasticsearch \
  --es.server-urls=http://elasticsearch:9200 \
  --es.index-prefix=jaeger-prod \
  --collector.otlp.enabled=true \
  --collector.zipkin.host-port=:9411 \
  --sampling.strategies-file=/etc/jaeger/sampling-strategies.json \
  --admin.http-host-port=:14269 \
  --log-level=info
```

### 5.3 Sampling Strategies File

```json
{
  "service_1": {
    "type": "probabilistic",
    "param": 0.01,
    "operation_1": {
      "type": "probabilistic",
      "param": 1.0
    }
  },
  "service_2": {
    "type": "rateLimiting",
    "param": 50
  },
  "_default": {
    "type": "adaptive",
    "param": 0.001,
    "maxTracesPerSecond": 50
  }
}
```

---

## 6. Core Concepts

### 6.1 Traces

A **trace** represents the entire journey of a request through the system. It is identified by a unique **trace ID** (128-bit) and consists of multiple **spans**.

```
Trace: abc123 (total: 320ms)
├── Frontend.handleRequest (320ms)
│   ├── UserService.getUser (80ms)
│   │   └── PostgreSQL.query (30ms)
│   ├── OrderService.getOrders (150ms)
│   │   ├── Redis.get (10ms)
│   │   └── OrderDB.query (120ms)
│   └── PaymentService.charge (85ms)
│       └── StripeAPI.charge (80ms)
```

### 6.2 Spans

A **span** is a single unit of work within a trace. Each span contains:

| Field | Description |
|---|---|
| `traceId` | Unique identifier for the entire trace |
| `spanId` | Unique identifier for this span |
| `parentSpanId` | ID of the parent span (null for root) |
| `operationName` | Name of the operation (e.g., `HTTP GET /api/users`) |
| `startTime` | Unix timestamp (microseconds) |
| `duration` | Span duration in microseconds |
| `tags` | Key-value metadata (e.g., `http.status_code=200`) |
| `logs` | Timestamped events (e.g., error messages) |
| `process` | Service name and tags |

### 6.3 Span Context

The **span context** propagates trace identity across process boundaries:

```
TraceId:  abc123def456...
SpanId:   789...
Flags:    sampled (bit 0)
```

Propagation formats:
- **HTTP Headers**: `uber-trace-id: {trace-id}:{span-id}:{parent-span-id}:{flags}`
- **W3C Trace Context**: `traceparent: 00-{trace-id}-{span-id}-{trace-flags}`
- **B3**: `X-B3-TraceId`, `X-B3-SpanId`, `X-B3-ParentSpanId`, `X-B3-Sampled`

### 6.4 Sampling

Sampling determines which traces are recorded. Strategies:

1. **Probabilistic**: Sample a fixed percentage (e.g., 1% of traces)
2. **Rate Limiting**: Sample N traces per second per service
3. **Adaptive**: Dynamically adjusts rate based on throughput (keeps error traces always)
4. **Remote**: Agent queries Collector for sampling strategy (default in production)

### 6.5 Process

A **process** represents a service instance. Process tags include:
- `jaeger.version`
- `hostname`
- `ip`
- Custom tags (e.g., `region`, `environment`, `version`)

---

## 7. Usage Guide

### 7.1 Instrumenting a Go Service

```go
package main

import (
    "context"
    "fmt"
    "net/http"
    "time"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/resource"
    tracing "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

func initTracer() func() {
    exporter, err := jaeger.New(jaeger.WithCollectorEndpoint(
        jaeger.WithEndpoint("http://jaeger-collector:14268/api/traces"),
    ))
    if err != nil {
        panic(err)
    }

    tp := tracing.NewTracerProvider(
        tracing.WithBatcher(exporter),
        tracing.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceName("my-service"),
            semconv.ServiceVersion("1.0.0"),
            attribute.String("environment", "production"),
        )),
        tracing.WithSampler(tracing.ParentBased(
            tracing.TraceIDRatioBased(0.1),
        )),
    )
    otel.SetTracerProvider(tp)

    return func() {
        ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        tp.Shutdown(ctx)
    }
}

func main() {
    shutdown := initTracer()
    defer shutdown()

    http.HandleFunc("/api/users", func(w http.ResponseWriter, r *http.Request) {
        ctx := r.Context()
        tracer := otel.Tracer("user-service")
        _, span := tracer.Start(ctx, "get-users",
            trace.WithAttributes(
                attribute.String("http.method", r.Method),
                attribute.String("http.url", r.URL.String()),
            ),
        )
        defer span.End()

        users, err := fetchUsers(ctx)
        if err != nil {
            span.RecordError(err)
            span.SetStatus(codes.Error, err.Error())
            http.Error(w, err.Error(), 500)
            return
        }
        fmt.Fprintf(w, "%v", users)
    })

    http.ListenAndServe(":8080", nil)
}
```

### 7.2 Instrumenting a Python Service

```python
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import Resource, SERVICE_NAME
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure Jaeger exporter
jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger-agent",
    agent_port=6831,
)

# Or use collector endpoint
# jaeger_exporter = JaegerExporter(
#     collector_endpoint="http://jaeger-collector:14268/api/traces",
# )

# Configure tracer
resource = Resource.create({SERVICE_NAME: "my-python-service"})
provider = TracerProvider(resource=resource)
provider.add_span_processor(BatchSpanProcessor(jaeger_exporter))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

def process_order(order_id: str):
    with tracer.start_as_current_span("process-order") as span:
        span.set_attribute("order.id", order_id)
        try:
            result = charge_payment(order_id)
            span.set_attribute("payment.status", "success")
            return result
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.StatusCode.ERROR, str(e))
            raise
```

### 7.3 Instrumenting a Node.js Service

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'my-node-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
  traceExporter: new JaegerExporter({
    host: 'jaeger-agent',
    port: 6831,
  }),
  instrumentations: [
    require('@opentelemetry/instrumentation-http'),
    require('@opentelemetry/instrumentation-express'),
    require('@opentelemetry/instrumentation-pg'),
    require('@opentelemetry/instrumentation-redis'),
  ],
});

sdk.start();

// Manual span creation
const { trace, SpanStatusCode } = require('@opentelemetry/api');
const tracer = trace.getTracer('order-service');

async function createOrder(items) {
  return tracer.startActiveSpan('create-order', async (span) => {
    try {
      span.setAttribute('order.item_count', items.length);
      const order = await db.insert('orders', { items });
      span.setAttribute('order.id', order.id);
      return order;
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

### 7.4 Java Instrumentation with OpenTelemetry Agent

```bash
# Download the Java agent
curl -LO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Run with auto-instrumentation
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=my-java-service \
  -Dotel.exporter.jaeger.endpoint=http://jaeger-collector:14268 \
  -Dotel.exporter.jaeger.protocol=grpc \
  -Dotel.resource.attributes=environment=production \
  -jar my-app.jar
```

### 7.5 Viewing Traces

1. Open the Jaeger UI at `http://localhost:16686`
2. Select your service from the "Service" dropdown
3. Click "Find Traces" to list recent traces
4. Click a trace to view its waterfall diagram
5. Click individual spans to see tags, logs, and timing

### 7.6 Using the Jaeger CLI

```bash
# Query traces by service
curl -s 'http://localhost:16687/api/traces?service=my-service&limit=10' | jq .

# Get specific trace by ID
curl -s 'http://localhost:16687/api/traces/{trace-id}' | jq .

# List all services
curl -s 'http://localhost:16687/api/services' | jq .

# Get service operations
curl -s 'http://localhost:16687/api/services/my-service/operations' | jq .

# Delete old traces
curl -X DELETE 'http://localhost:16687/api/traces?service=my-service&olderThan=24h'

# Health check
curl -s 'http://localhost:14269/' | jq .
```

---

## 8. Custom Instrumentation

### 8.1 Creating Custom Spans

```python
# Python custom instrumentation
from opentelemetry import trace

tracer = trace.get_tracer("payment-processor")

def process_payment(amount, currency):
    with tracer.start_as_current_span("charge-card") as span:
        span.set_attribute("payment.amount", amount)
        span.set_attribute("payment.currency", currency)
        
        # Add span event
        span.add_event("connecting-to-stripe", {"endpoint": "api.stripe.com"})
        
        try:
            result = stripe.charge(amount, currency)
            span.set_attribute("payment.id", result.id)
            return result
        except stripe.error.CardError as e:
            span.record_exception(e)
            span.set_status(trace.StatusCode.ERROR, "Card declined")
            raise
```

### 8.2 Span Links and Events

```go
// Span Links (for causal relationships between independent traces)
span.AddLink(trace.Link{
    SpanContext: trace.SpanContextFromTraceID(followUpTraceID),
    Attributes: []attribute.KeyValue{
        attribute.String("reason", "follow-up-request"),
    },
})

// Span Events (timestamped annotations)
span.AddEvent("cache.miss", trace.WithTimestamp(time.Now()))
span.AddEvent("retry.attempt", trace.WithAttributes(
    attribute.Int("attempt", 2),
    attribute.Duration("backoff", 100*time.Millisecond),
))
```

### 8.3 Baggage Propagation

```python
from opentelemetry import baggage, context

# Set baggage (propagated across services)
ctx = baggage.set_baggage("tenant.id", "abc-123")
ctx = baggage.set_baggage("user.role", "admin", context=ctx)

# Use context in downstream calls
with tracer.start_as_current_span("child-op", context=ctx):
    # baggage is automatically propagated
    tenant = baggage.get_baggage("tenant.id")
```

---

## 9. Collector & Agent Configuration

### 9.1 Collector Configuration

```yaml
# /etc/jaeger/collector.yaml
collector:
  # OTLP receiver
  otlp:
    enabled: true
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  # Zipkin-compatible receiver
  zipkin:
    host-port: 0.0.0.0:9411

  # Span processor
  processor:
    batch:
      max-batch-size: 8192
      timeout: 1s
      num-workers: 4

  # Authentication
  auth:
    enabled: true
    authenticator: token

  # Rate limiting
  rate-limiting:
    num-per-second: 500
    max-inflight-requests: 500
```

### 9.2 Agent Configuration

```yaml
# Agent deployed as DaemonSet
agent:
  host-port: 0.0.0.0:6831
  http-endpoint: 0.0.0.0:6832
  
  # Collector discovery
  collector:
    host-port: jaeger-collector:14250
    
  # Sampling strategy polling
  sampling:
    refresh-interval: 60s
    endpoint: http://jaeger-collector:14269/sampling
```

### 9.3 Production Collector Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger-collector
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: jaeger-collector
  template:
    metadata:
      labels:
        app: jaeger-collector
    spec:
      containers:
      - name: collector
        image: jaegertracing/jaeger-collector:1.53
        args:
          - --span-storage.type=elasticsearch
          - --es.server-urls=http://elasticsearch:9200
          - --collector.otlp.enabled=true
          - --collector.num-workers=50
          - --collector.queue-size=2000
        ports:
        - containerPort: 14250
          name: grpc
        - containerPort: 14268
          name: http
        - containerPort: 4317
          name: otlp-grpc
        - containerPort: 4318
          name: otlp-http
        - containerPort: 14269
          name: admin
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 2Gi
            cpu: 1000m
        livenessProbe:
          httpGet:
            path: /
            port: 14269
          initialDelaySeconds: 15
        readinessProbe:
          httpGet:
            path: /
            port: 14269
          initialDelaySeconds: 5
```

---

## 10. Storage Backends

### 10.1 Elasticsearch

```bash
# Environment variables
export SPAN_STORAGE_TYPE=elasticsearch
export ES_SERVER_URLS=http://elasticsearch:9200
export ES_INDEX_PREFIX=jaeger
export ES_USERNAME=elastic
export ES_PASSWORD=changeme

# Create index template
curl -X PUT "http://elasticsearch:9200/_index_template/jaeger" \
  -H 'Content-Type: application/json' \
  -d '{
    "index_patterns": ["jaeger-*"],
    "template": {
      "settings": {
        "number_of_shards": 5,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
      }
    }
  }'
```

### 10.2 Cassandra

```bash
export SPAN_STORAGE_TYPE=cassandra
export CASSANDRA_SERVERS=cassandra-0,cassandra-1,cassandra-2
export CASSANDRA_KEYSPACE=jaeger_v1
export CASSANDRA.replication_factor=3

# Schema creation
cassandra-schema-cql.sh | cqlsh cassandra-0
```

### 10.3 Kafka (for HA ingestion)

```
Agent → Kafka → Ingester → Storage
```

```bash
export SPAN_STORAGE_TYPE=elasticsearch
export KAFKA_BROKERS=kafka-0:9092,kafka-1:9092,kafka-2:9092
export KAFKA_TOPIC=jaeger-spans
export KAFKA_PROTOCOL_VERSION=2.8.1
```

---

## 11. Integration

### 11.1 OpenTelemetry Collector with Jaeger Exporter

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    send_batch_size: 8192
    timeout: 5s
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow-traces
        type: latency
        latency: {threshold_ms: 1000}

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true

  jaeger/exporter:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch]
      exporters: [jaeger/exporter]
```

### 11.2 Prometheus Integration

```yaml
# Scrape Jaeger Collector metrics
scrape_configs:
  - job_name: 'jaeger-collector'
    static_configs:
      - targets: ['jaeger-collector:14269']
    metrics_path: /

  - job_name: 'jaeger-query'
    static_configs:
      - targets: ['jaeger-query:16687']
    metrics_path: /
```

### 11.3 Grafana Dashboard

```json
{
  "panels": [
    {
      "title": "Jaeger Traces Ingested/sec",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(jaeger_collector_spans_received_total[5m])",
          "legendFormat": "{{service}}"
        }
      ]
    }
  ]
}
```

### 11.4 Envoy Integration

```yaml
# envoy.yaml
static_resources:
  listeners:
  - filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          tracing:
            provider:
              name: envoy.tracers.zipkin
              typed_config:
                "@type": type.googleapis.com/envoy.config.trace.v3.ZipkinConfig
                collector_cluster: jaeger
                collector_endpoint: "/api/v2/spans"
                trace_id_128bit: true
                collector_endpoint_namespace: v3
  clusters:
  - name: jaeger
    type: STRICT_DNS
    load_assignment:
      cluster_name: jaeger
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: jaeger-collector
                port_value: 9411
```

---

## 12. Security

### 12.1 TLS Configuration

```yaml
collector:
  tls:
    cert-file: /etc/jaeger/tls/collector.crt
    key-file: /etc/jaeger/tls/collector.key
    client-ca-file: /etc/jaeger/tls/ca.crt
    client-auth: RequireAndVerifyClientCert

query:
  tls:
    cert-file: /etc/jaeger/tls/query.crt
    key-file: /etc/jaeger/tls/query.key
    client-ca-file: /etc/jaeger/tls/ca.crt
```

### 12.2 Authentication

```yaml
# Token-based authentication
collector:
  auth:
    enabled: true
    authenticator: token

# OAuth2/OIDC for Query UI
query:
  auth:
    enabled: true
    authenticator: oauth2
    oauth2:
      issuer-url: https://auth.example.com
      client-id: jaeger
      client-secret-file: /etc/jaeger/oauth2/client-secret
      redirect-url: http://jaeger-query:16686/callback
```

### 12.3 Network Policies (Kubernetes)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jaeger-network-policy
spec:
  podSelector:
    matchLabels:
      app: jaeger
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: my-app
    ports:
    - port: 14250
      protocol: TCP
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: elasticsearch
    ports:
    - port: 9200
      protocol: TCP
```

---

## 13. Troubleshooting

### Issue 1: Traces Not Appearing in UI

**Symptoms**: Application sends spans but no traces show in Jaeger UI.

**Diagnosis**:
```bash
# Check agent is receiving spans
curl http://jaeger-agent:6832/metrics | grep spans_received

# Check collector is receiving spans
curl http://jaeger-collector:14269/ | jq .

# Check storage has data
curl 'http://localhost:16687/api/traces?service=my-service&limit=1' | jq .
```

**Fix**: Ensure service name in SDK matches what you're searching for. Check `COLLECTOR_OTLP_ENABLED=true` if using OTLP.

### Issue 2: High Memory Usage on Collector

**Symptoms**: Collector OOMKilled or using excessive memory.

**Diagnosis**:
```bash
kubectl top pod -l app=jaeger-collector
# Check queue size
curl http://jaeger-collector:14269/ | jq .queueSize
```

**Fix**:
```bash
# Reduce batch size and queue
--collector.num-workers=20
--collector.queue-size=1000
# Add memory limits
resources.limits.memory=1Gi
```

### Issue 3: Elasticsearch Index Overflow

**Symptoms**: ES disk usage >90%, write rejections.

**Fix**:
```bash
# Enable index cleaner
esIndexCleaner:
  enabled: true
  numberOfDays: 7
  schedule: "0 2 * * *"

# Or manually delete old indices
curl -X DELETE "http://elasticsearch:9200/jaeger-span-2024-01-*"
```

### Issue 4: Agent Cannot Connect to Collector

**Symptoms**: Agent logs show "connection refused" to collector.

**Diagnosis**:
```bash
kubectl logs -l app=jaeger-agent | grep -i error
kubectl get svc jaeger-collector
```

**Fix**: Ensure collector is reachable. Check service name and port (14250 for gRPC). Verify network policies allow agent → collector traffic.

### Issue 5: OTLP Spans Not Received

**Symptoms**: SDK configured with OTLP but no spans arrive.

**Fix**:
```bash
# Enable OTLP receiver on collector
--collector.otlp.enabled=true

# Verify endpoint in SDK
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger-collector:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
```

### Issue 6: Sampling Too Aggressive (Missing Spans)

**Symptoms**: Most traces not recorded; only 1% visible.

**Fix**: Update sampling strategy:
```json
{
  "_default": {
    "type": "probabilistic",
    "param": 0.1
  }
}
```
Or use adaptive sampling:
```json
{
  "_default": {
    "type": "adaptive",
    "param": 0.01,
    "maxTracesPerSecond": 100
  }
}
```

### Issue 7: Clock Skew Between Services

**Symptoms**: Spans appear out of order; negative durations.

**Fix**: Ensure NTP is configured on all hosts. Use `CLOCK_SYNC` environment variable. Jaeger performs some skew adjustment but it has limits (default: 0.5s max skew).

### Issue 8: Slow Query Performance

**Symptoms**: Trace search takes >10s, UI timeouts.

**Fix**:
```bash
# Add ES index aliases for faster queries
curl -X POST "http://elasticsearch:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [{"add": {"index": "jaeger-span-*", "alias": "jaeger-span-read"}}]
}'

# Increase query cache
curl -X PUT "http://elasticsearch:9200/jaeger-span-*/_settings" -d '{
  "index.requests.cache.enable": true
}'
```

### Issue 9: Jaeger Operator Not Creating Resources

**Symptoms**: Jaeger CR applied but no pods created.

**Diagnosis**:
```bash
kubectl describe jaeger production -n observability
kubectl logs -n observability deployment/jaeger-operator
```

**Fix**: Check operator RBAC permissions. Verify CRD is installed: `kubectl get crd jaegers.jaegertracing.io`. Check operator logs for errors.

### Issue 10: UDP Agent Drops Spans

**Symptoms**: Agent metric `spans_dropped` increasing.

**Fix**:
```bash
# Increase agent queue size
AGENT_QUEUE_SIZE=4096

# Switch to gRPC (more reliable, TCP-based)
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger-agent:6832
```

### Issue 11: Kafka Consumer Lag

**Symptoms**: Spans delayed, ingester falling behind.

**Diagnosis**:
```bash
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --describe --group jaeger-ingester
```

**Fix**:
```bash
# Increase ingester replicas
ingester:
  replicas: 5
  kafka:
    consumer:
      consumer-fetch-max-bytes: 10485760
```

### Issue 12: Storage Write Failures

**Symptoms**: Collector logs show "failed to write span" errors.

**Diagnosis**:
```bash
curl http://jaeger-collector:14269/ | jq .spansDropped
# Check ES health
curl http://elasticsearch:9200/_cluster/health?pretty
```

**Fix**: Check ES disk space, increase index replicas temporarily. Check ES thread pool for write rejections.

### Issue 13: Service Dependency Graph Empty

**Symptoms**: No edges in the dependency graph view.

**Fix**: Ensure spans have proper `peer.service` or `http.url` tags that Jaeger can use to infer dependencies. Check that spans are being stored (not dropped).

### Issue 14: Trace Comparison Fails

**Symptoms**: "Compare Traces" shows no differences.

**Fix**: Ensure both traces have the same number of spans. Jaeger compares spans by operation name and duration. Very different traces may not produce meaningful diffs.

### Issue 15: High Collector CPU

**Symptoms**: Collector pods consuming >2 cores.

**Fix**:
```bash
# Reduce parsing overhead
--collector.num-workers=10

# Use tail sampling in OTel Collector (pre-filter before Jaeger)
processors:
  tail_sampling:
    policies:
      - name: errors
        type: status_code
        status_codes: [ERROR]
      - name: slow
        type: latency
        latency: {threshold_ms: 500}
```

---

## 14. Tips & Best Practices

### Tip 1: Use OpenTelemetry SDKs
OpenTelemetry is the successor to OpenTracing and OpenCensus. Use OTel SDKs with Jaeger exporter for maximum flexibility.

### Tip 2: Start with Low Sampling Rates
Begin with 1-10% probabilistic sampling in production and increase only for debugging.

### Tip 3: Add Meaningful Span Names
```python
# Bad
span.set_name("database.query")
# Good  
span.set_name("SELECT users WHERE id = ?")
```

### Tip 4: Use Span Attributes for Filtering
```go
span.SetAttributes(
    attribute.String("http.method", "GET"),
    attribute.Int("http.status_code", 200),
    attribute.String("db.statement", "SELECT * FROM users"),
)
```

### Tip 5: Record Exceptions
Always record exceptions to spans:
```python
except Exception as e:
    span.record_exception(e)
    span.set_status(StatusCode.ERROR, str(e))
```

### Tip 6: Use Resource Attributes for Service Identity
```go
resource.NewWithAttributes(
    semconv.SchemaURL,
    semconv.ServiceName("order-service"),
    semconv.ServiceVersion("2.1.0"),
    attribute.String("deployment.environment", "production"),
)
```

### Tip 7: Propagate Context Across Async Boundaries
```python
# Async queue processing
ctx = trace.set_span_in_context(parent_span)
# Store context with message
queue.put({"data": payload, "trace_context": context.to_dict(ctx)})
```

### Tip 8: Use Adaptive Sampling in Production
Adaptive sampling adjusts rates based on traffic volume, maintaining SLOs for trace collection without overwhelming storage.

### Tip 9: Separate Collector for Ingestion
Use Kafka as a buffer between Collector and storage for HA:
```
Agent → Collector → Kafka → Ingester → Storage
```

### Tip 10: Monitor Jaeger Components
Track these metrics:
- `jaeger_collector_spans_received_total`
- `jaeger_collector_spans_dropped_total`
- `jaeger_agent_spans_dropped_total`
- `jaeger_query_latency_seconds`

### Tip 11: Use Index Cleaners
Configure TTL-based cleanup to prevent storage bloat:
```bash
esIndexCleaner:
  numberOfDays: 14
  schedule: "55 23 * * *"
```

### Tip 12: Tag Sensitive Data Carefully
```python
# Never tag PII
span.set_attribute("user.id", anonymize(user_id))
span.set_attribute("http.request.body.size", len(body))
# Do NOT: span.set_attribute("http.request.body", body)
```

### Tip 13: Use Span Links for Batch Operations
When processing a batch, use span links instead of parent-child:
```go
for _, item := range batch {
    span.AddLink(trace.Link{
        SpanContext: item.SpanContext,
    })
}
```

### Tip 14: Keep Sampling Strategy in Version Control
```bash
# /etc/jaeger/sampling-strategies.json
# Commit to git, deploy with ConfigMap
kubectl create configmap jaeger-sampling \
  --from-file=sampling-strategies.json \
  -n observability
```

### Tip 15: Use Separate Services for Different Tiers
Separate UI, collector, and query into different deployment tiers with independent scaling.

### Tip 16: Test Instrumentation with Hot Reload
Use `OTEL_TRACES_SAMPLER=always_on` in development/staging to capture all traces during testing.

### Tip 17: Export Traces to Object Storage for Long-Term
Use the S3-compatible storage exporter in OpenTelemetry Collector for archival beyond Jaeger's retention.

---

## 15. Command Reference

### Agent

```bash
jaeger-agent \
  --collector.host-port=jaeger-collector:14250 \
  --reporter.grpc.host-port=jaeger-collector:14250 \
  --agent.http.host-port=:6832 \
  --log-level=info
```

### Collector

```bash
jaeger-collector \
  --span-storage.type=elasticsearch \
  --es.server-urls=http://elasticsearch:9200 \
  --collector.otlp.enabled=true \
  --collector.num-workers=50 \
  --collector.queue-size=2000 \
  --admin.http-host-port=:14269 \
  --sampling.strategies-file=/etc/jaeger/sampling-strategies.json
```

### Query

```bash
jaeger-query \
  --span-storage.type=elasticsearch \
  --es.server-urls=http://elasticsearch:9200 \
  --query.base-path=/ \
  --query.bearer-token-file=/var/run/secrets/token \
  --log-level=info
```

### Ingester

```bash
jaeger-ingester \
  --span-storage.type=elasticsearch \
  --es.server-urls=http://elasticsearch:9200 \
  --kafka.brokers=kafka:9092 \
  --kafka.topic=jaeger-spans \
  --ingester.deadlock-interval=0
```

---

## 16. Configuration Reference

### Full Environment Variables

```bash
# Core
SPAN_STORAGE_TYPE=elasticsearch
COLLECTOR_OTLP_ENABLED=true
COLLECTOR_ZIPKIN_HOST_PORT=:9411

# Agent
AGENT_HOST_PORT=:6831
AGENT_HTTP_HOST_PORT=:6832
REPORTER_GRPC_HOST_PORT=jaeger-collector:14250

# Collector
COLLECTOR_HTTP_HOST_PORT=:14268
COLLECTOR_GRPC_HOST_PORT=:14250
COLLECTOR_ADMIN_HTTP_HOST_PORT=:14269
COLLECTOR_NUM_WORKERS=50
COLLECTOR_QUEUE_SIZE=2000

# Query
QUERY_HTTP_HOST_PORT=:16687
QUERY_UI_HOST_PORT=:16686

# Elasticsearch
ES_SERVER_URLS=http://elasticsearch:9200
ES_USERNAME=elastic
ES_PASSWORD=changeme
ES_INDEX_PREFIX=jaeger
ES_NUM_SHARDS=5
ES_NUM_REPLICAS=1
ES_REFRESH_INTERVAL=5s
ES_USERNAME=elastic
ES_PASSWORD=changeme

# Cassandra
CASSANDRA_SERVERS=cassandra-0,cassandra-1,cassandra-2
CASSANDRA_KEYSPACE=jaeger_v1
CASSANDRA_CONSISTENCY=QUORUM
CASSANDRA.replication_factor=3

# Kafka
KAFKA_BROKERS=kafka-0:9092,kafka-1:9092
KAFKA_TOPIC=jaeger-spans
KAFKA_PROTOCOL_VERSION=2.8.1

# Badger
BADGER_SPAN_STORE_DIRECTORY=/var/lib/jaeger/badger
BADGER_SPAN_STORE_TTL=720h
BADGER_SPAN_STORE_GC=10m

# Auth
TOKEN_FILE=/var/run/secrets/jaeger-token
BEARER_TOKEN_FILE=/var/run/secrets/bearer-token
```

### Sampling Strategies Reference

| Type | Param | Description |
|---|---|---|
| `probabilistic` | 0.0–1.0 | Sample this fraction of traces |
| `rateLimiting` | int | Max traces/sec per service |
| `adaptive` | (complex) | Dynamic rate; needs `maxTracesPerSecond` |
| `remote` | — | Agent queries Collector for strategy |
| `const` | 0 or 1 | Always sample or never sample |

---

## 17. Real-World Examples

### 17.1 E-Commerce Trace

```
Trace: order-123 (total: 1250ms)
├── API Gateway.handleRequest (1250ms)
│   ├── Auth.validateToken (45ms)
│   │   └── JWT.verify (12ms)
│   ├── CartService.calculateTotal (180ms)
│   │   ├── Redis.HGETALL cart:123 (8ms)
│   │   └── PriceService.calculateDiscount (150ms)
│   │       └── PostgreSQL.query (120ms)
│   ├── InventoryService.reserveStock (320ms)
│   │   ├── Redis.SETNX inventory:456 (5ms)
│   │   └── PostgreSQL.UPDATE (280ms)
│   ├── PaymentService.charge (600ms)
│   │   ├── StripeAPI.createCharge (580ms)
│   │   └── DB.logTransaction (15ms)
│   └── NotificationService.sendConfirmation (50ms)
│       └── SendGridAPI.send (40ms)
```

### 17.2 Microservices Sampling Strategy

```json
{
  "payment-service": {
    "type": "probabilistic",
    "param": 1.0,
    "_comment": "Always sample payment traces"
  },
  "auth-service": {
    "type": "rateLimiting",
    "param": 100,
    "operation_verify_token": {
      "type": "probabilistic",
      "param": 0.01
    }
  },
  "_default": {
    "type": "adaptive",
    "param": 0.001,
    "maxTracesPerSecond": 50
  }
}
```

### 17.3 Kubernetes Production Deployment

```yaml
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: production
spec:
  strategy: production
  collector:
    replicas: 3
    autoscale: true
    maxReplicas: 10
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
  query:
    replicas: 2
    autoscale: true
    maxReplicas: 5
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: https://elasticsearch:9200
        index-prefix: jaeger
        username: elastic
        password-from-secret:
          name: es-credentials
          key: password
    esIndexCleaner:
      enabled: true
      numberOfDays: 14
      schedule: "55 23 * * *"
  ingress:
    enabled: true
    hosts:
    - jaeger.example.com
```

---

## 18. Further Reading

### Official Documentation
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Jaeger GitHub](https://github.com/jaegertracing/jaeger)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/)
- [CNCF Jaeger Graduation](https://www.cncf.io/projects/jaeger/)

### Books
- "Distributed Tracing in Practice" — Austin Parker, Daniel Spoonhower, et al.
- "Observability Engineering" — Charity Majors, Liz Fong-Jones, George Miranda

### Tutorials
- [Jaeger Getting Started](https://www.jaegertracing.io/docs/latest/getting-started/)
- [OpenTelemetry with Jaeger](https://opentelemetry.io/docs/languages/go/getting-started/)
- [Kubernetes Operator Guide](https://www.jaegertracing.io/docs/latest/operator/)

### Related Projects
- [OpenTelemetry](https://opentelemetry.io/) — Vendor-neutral observability framework
- [OpenTracing](https://opentracing.io/) — Vendor-neutral tracing API (legacy)
- [OpenCensus](https://opencensus.io/) — Vendor-neutral metrics + tracing (legacy)
- [Grafana Tempo](https://grafana.com/oss/tempo/) — High-scale tracing backend
- [Zipkin](https://zipkin.io/) — Twitter's distributed tracing system

---

*Last updated: 2026-09-04*
