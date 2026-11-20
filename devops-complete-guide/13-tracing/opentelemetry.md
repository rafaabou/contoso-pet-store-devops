# OpenTelemetry Complete Guide

## Table of Contents

1. [What Is OpenTelemetry](#1-what-is-opentelemetry)
2. [Why Use OpenTelemetry](#2-why-use-opentelemetry)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide (Step-by-Step)](#7-usage-guide)
8. [Custom Instrumentation](#8-custom-instrumentation)
9. [Instrumentation Libraries](#9-instrumentation-libraries)
10. [OTel Collector Configuration](#10-otel-collector-configuration)
11. [Integration](#11-integration)
12. [Security](#12-security)
13. [Troubleshooting](#13-troubleshooting)
14. [Tips & Best Practices](#14-tips--best-practices)
15. [Command Reference](#15-command-reference)
16. [Configuration Reference](#16-configuration-reference)
17. [Real-World Examples](#17-real-world-examples)
18. [Further Reading](#18-further-reading)

---

## 1. What Is OpenTelemetry

OpenTelemetry (OTel) is a vendor-neutral, open-source observability framework for instrumenting, generating, collecting, and exporting telemetry data (traces, metrics, and logs). It is a CNCF graduated project, formed by the merger of OpenTracing and OpenCensus in 2019.

### 1.1 Purpose

OpenTelemetry provides a single set of APIs, SDKs, and tools that enable developers to instrument applications once and export telemetry to any observability backend — Jaeger, Prometheus, Grafana Tempo, Datadog, New Relic, or any OTLP-compatible system.

### 1.2 Key Components

| Component | Description |
|---|---|
| **API** | Interfaces for creating and managing telemetry (Tracer, Meter, Logger) |
| **SDK** | Reference implementation with configuration, sampling, processors, exporters |
| **OTLP** | Vendor-neutral protocol for exporting telemetry (gRPC + HTTP) |
| **OTel Collector** | Proxy that receives, processes, and exports telemetry |
| **Instrumentation Libraries** | Auto-instrumentation for popular frameworks |
| **Semantic Conventions** | Standard attribute names for spans, metrics, resources |
| **OpAMP** | Agent Management Protocol for remote configuration |

### 1.3 Three Pillars

| Pillar | Signal | Data Model |
|---|---|---|
| **Traces** | Distributed request paths | Spans, SpanEvents, SpanLinks |
| **Metrics** | Numeric measurements over time | Sum, Gauge, Histogram, ExponentialHistogram |
| **Logs** | Discrete event records | LogRecord with severity, body, attributes |

### 1.4 Version History

- **2019**: OpenTracing + OpenCensus merge into OpenTelemetry
- **2021**: Traces and Metrics reach v1.0 (stable)
- **2022**: Logs reach v1.0
- **2023**: Profiles (profiling signal) announced
- **2024**: OpAMP spec v0.10, Collector v0.90+
- **2025+**: Profiling signal maturing, ebpf instrumentation

---

## 2. Why Use OpenTelemetry

### 2.1 Vendor Lock-in Avoidance

| Without OTel | With OTel |
|---|---|
| Instrument once per vendor SDK | Instrument once with OTel API |
| Switching vendors = rewrite code | Switch only the exporter config |
| Proprietary data formats | Standard OTLP format |

### 2.2 Feature Comparison

| Feature | OTel SDK | Datadog SDK | New Relic SDK | AWS X-Ray SDK |
|---|---|---|---|---|
| Open source | Yes | No | No | Partial |
| Multi-signal | Traces + Metrics + Logs | Traces + Metrics | Traces + Metrics | Traces only |
| Vendor neutral | Yes | No | No | No |
| Auto-instrumentation | Yes (Java, Python, .NET, Node.js) | Yes | Yes | Yes |
| OTLP export | Native | Via OTel | Via OTel | Via OTel |
| Community size | Very large | Medium | Medium | Medium |

### 2.3 Use Cases

1. **Unified observability stack** — single instrumentation for all backends
2. **Multi-cloud/multi-vendor** — no lock-in; switch backends freely
3. **Microservice debugging** — distributed tracing across any language
4. **Performance monitoring** — custom metrics with semantic conventions
5. **SLA tracking** — standardized latency histograms and error rates

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Tracer  │  │  Meter   │  │  Logger  │  │  Profiler│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │              │              │              │       │
│  ┌────┴──────────────┴──────────────┴──────────────┴────┐│
│  │              OTel SDK (TracerProvider, MeterProvider) ││
│  │  ┌─────────┐  ┌──────────┐  ┌──────────┐             ││
│  │  │ Sampler │  │ Processor│  │ Exporter │             ││
│  │  └─────────┘  └──────────┘  └─────┬────┘             ││
│  └────────────────────────────────────┼─────────────────┘│
└───────────────────────────────────────┼──────────────────┘
                                        │ OTLP (gRPC/HTTP)
                                        ▼
                         ┌──────────────────────────┐
                         │      OTel Collector       │
                         │  ┌────────┐ ┌──────────┐ │
                         │  │Receiver│→│Processor │ │
                         │  └────────┘ └─────┬────┘ │
                         │  ┌────────┐ ┌─────▼────┐ │
                         │  │Export  │ │Pipeline  │ │
                         │  └───┬────┘ └──────────┘ │
                         └──────┼────────────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
        ┌──────────┐     ┌──────────┐      ┌──────────┐
        │  Jaeger  │     │Prometheus│      │  Loki    │
        └──────────┘     └──────────┘      └──────────┘
```

### 3.1 Components

| Component | Role |
|---|---|
| **OTel API** | Defines interfaces (Tracer, Meter, Logger) for instrumentation |
| **OTel SDK** | Implements API; handles sampling, processing, export |
| **OTLP Exporter** | Serializes and sends telemetry via OTLP (gRPC or HTTP) |
| **OTel Collector** | Receives OTLP, processes (batch, filter, transform), exports to backends |
| **Auto-instrumentation** | Libraries that instrument frameworks without manual code changes |
| **Semantic Conventions** | Standard attribute names (`http.method`, `db.system`, etc.) |
| **Resource** | Describes the entity producing telemetry (service name, version, environment) |

### 3.2 Signal Flow

1. Application code (or auto-instrumentation) creates spans/metrics/logs via the OTel API
2. SDK applies sampling, processing (batching, filtering), and enrichment (resource attributes)
3. OTLP exporter serializes and sends telemetry to the Collector (or directly to backends)
4. Collector receives, processes (tail sampling, attribute transformation, redaction), and exports to multiple backends

---

## 4. Installation

### 4.1 Java (Maven)

```xml
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-bom</artifactId>
    <version>1.38.0</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot-starter</artifactId>
</dependency>
```

### 4.2 Python (pip)

```bash
pip install opentelemetry-api opentelemetry-sdk \
  opentelemetry-exporter-otlp \
  opentelemetry-instrumentation-flask \
  opentelemetry-instrumentation-requests \
  opentelemetry-instrumentation-sqlalchemy
```

### 4.3 Node.js (npm)

```bash
npm install @opentelemetry/api \
  @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-grpc \
  @opentelemetry/exporter-metrics-otlp-grpc \
  @opentelemetry/exporter-logs-otlp-grpc
```

### 4.4 Go (go get)

```bash
go get go.opentelemetry.io/otel@latest
go get go.opentelemetry.io/otel/sdk@latest
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc@latest
go get go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc@latest
go get go.opentelemetry.io/otel/instrumentation/net/http/otelhttp@latest
```

### 4.5 .NET (NuGet)

```bash
dotnet add package OpenTelemetry
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
dotnet add package OpenTelemetry.Instrumentation.EntityFrameworkCore
```

### 4.6 OTel Collector (Docker)

```bash
# All-in-one
docker run -d --name otel-collector \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 8888:8888 \
  -p 8889:8889 \
  -v $(pwd)/otel-collector-config.yaml:/etc/otelcol/config.yaml \
  otel/opentelemetry-collector-contrib:latest

# Or without contrib
docker run -d --name otel-collector \
  -p 4317:4317 \
  -p 4318:4318 \
  -v $(pwd)/otel-collector-config.yaml:/etc/otelcol/config.yaml \
  otel/opentelemetry-collector:0.100.0
```

### 4.7 OTel Collector (Kubernetes)

```bash
# Using Helm
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm install otel-collector open-telemetry/opentelemetry-collector \
  --namespace observability --create-namespace \
  --set mode=deployment \
  --set replicas=2 \
  --set config.receivers.otlp.protocols.grpc.endpoint=0.0.0.0:4317 \
  --set config.receivers.otlp.protocols.http.endpoint=0.0.0.0:4318 \
  --set config.exporters.jaeger.endpoint=jaeger-collector:14250 \
  --set config.service.pipelines.traces.receivers='{otlp}' \
  --set config.service.pipelines.traces.exporters='{jaeger}'
```

### 4.8 Kubernetes Operator (OTel Collector)

```bash
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

# The operator auto-injects instrumentation sidecar when annotated
kubectl annotate namespace apps otel.opentelemetry.io/inject-sdk: "true"
```

---

## 5. Configuration

### 5.1 SDK Configuration

```python
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource, SERVICE_NAME
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

# Resource (describes this service)
resource = Resource.create({
    SERVICE_NAME: "my-service",
    "service.version": "1.2.3",
    "deployment.environment": "production",
    "host.name": "worker-01",
})

# Traces
trace_exporter = OTLPSpanExporter(endpoint="otel-collector:4317", insecure=True)
tracer_provider = TracerProvider(
    resource=resource,
    sampler=ParentBasedTraceIdRatio(0.1),
)
tracer_provider.add_span_processor(BatchSpanProcessor(trace_exporter))
trace.set_tracer_provider(tracer_provider)

# Metrics
metric_exporter = OTLPMetricExporter(endpoint="otel-collector:4317", insecure=True)
metric_reader = PeriodicExportingMetricReader(metric_exporter, export_interval_millis=30000)
meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)
```

### 5.2 Node.js Configuration

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');

const sdk = new NodeSDK({
  serviceName: 'my-node-service',
  traceExporter: new OTLPTraceExporter({
    url: 'otel-collector:4317',
    insecure: true,
  }),
  metricExporter: new OTLPMetricExporter({
    url: 'otel-collector:4317',
    insecure: true,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-pg': { enabled: true },
      '@opentelemetry/instrumentation-redis': { enabled: true },
    }),
  ],
});

sdk.start();
process.on('SIGTERM', () => sdk.shutdown());
```

---

## 6. Core Concepts

### 6.1 Traces and Spans

```
Trace ID: abc123def456 (128-bit)
Span ID:  789 (64-bit, unique per span)
Parent:   Span ID of caller (null for root)

┌────────────────────────────────────────────────┐
│ Trace: abc123 (total: 450ms)                   │
├── [789] HTTP GET /api/users (450ms)            │
│     ├── [aaa] auth.validate (40ms)             │
│     │     └── [bbb] jwt.verify (15ms)          │
│     ├── [ccc] db.query-users (200ms)           │
│     │     └── [ddd] postgres.execute (180ms)   │
│     └── [eee] cache.set (30ms)                 │
└────────────────────────────────────────────────┘
```

### 6.2 Span Attributes

```python
# Semantic conventions
span.set_attribute("http.method", "GET")
span.set_attribute("http.url", "http://localhost:8080/api/users")
span.set_attribute("http.status_code", 200)
span.set_attribute("http.request.header.content_type", "application/json")
span.set_attribute("db.system", "postgresql")
span.set_attribute("db.statement", "SELECT * FROM users WHERE id = $1")
span.set_attribute("db.name", "mydb")
span.set_attribute("net.peer.name", "db.example.com")
span.set_attribute("net.peer.port", 5432)
span.set_attribute("rpc.system", "grpc")
span.set_attribute("rpc.service", "UserService")
span.set_attribute("rpc.method", "GetUser")
```

### 6.3 Span Events and Links

```python
# Events (timestamped log-like annotations)
span.add_event("cache.miss", {
    "cache.key": "user:123",
    "cache.store": "redis",
})

span.add_event("retry.attempt", {
    "attempt.number": 2,
    "retry.delay_ms": 500,
})

# Links (causal relationship to other traces)
span.link(other_span_context, attributes={"reason": "follow-up"})
```

### 6.4 Metrics

| Type | Description | Use Case |
|---|---|---|
| **Counter** | Monotonically increasing value | Request count, bytes sent |
| **UpDownCounter** | Value that can increase or decrease | Active connections, queue size |
| **Gauge** | Point-in-time value | Temperature, CPU usage |
| **Histogram** | Distribution of values | Request latency, response size |
| **ExponentialHistogram** | Power-of-two bucketed histogram | High-resolution latency |

### 6.5 Resources

```python
resource = Resource.create({
    "service.name": "payment-service",
    "service.version": "2.1.0",
    "service.namespace": "payments",
    "deployment.environment": "production",
    "host.name": "worker-01",
    "host.arch": "amd64",
    "os.type": "linux",
    "cloud.provider": "aws",
    "cloud.region": "us-east-1",
})
```

### 6.6 Context Propagation

| Propagator | Format | Header |
|---|---|---|
| W3C TraceContext | `traceparent: 00-{trace-id}-{span-id}-{flags}` | `traceparent` |
| W3C Baggage | `baggage: key=value,key2=value2` | `baggage` |
| B3 | `X-B3-TraceId`, `X-B3-SpanId`, etc. | `X-B3-*` |
| Jaeger | `uber-trace-id: {tid}:{sid}:{psid}:{f}` | `uber-trace-id` |
| AWS X-Ray | `X-Amzn-Trace-Id` | `X-Amzn-Trace-Id` |

### 6.7 Sampling

| Sampler | Behavior |
|---|---|
| `AlwaysOn` | Sample 100% of traces |
| `AlwaysOff` | Sample 0% of traces |
| `TraceIdRatioBased(p)` | Sample fraction p of traces |
| `ParentBased(child)` | Use parent's sampling decision; child uses ratio |
| `ParentBased(root=AlwaysOn, remote=AlwaysOff)` | Sample local root, ignore remote |

---

## 7. Usage Guide (Step-by-Step)

### Step 1: Install SDK and Exporter

```bash
# Python
pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-grpc

# Node.js
npm install @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-grpc

# Go
go get go.opentelemetry.io/otel@latest go.opentelemetry.io/otel/sdk@latest
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc@latest
```

### Step 2: Initialize Tracer

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

provider = TracerProvider()
exporter = OTLPSpanExporter(endpoint="otel-collector:4317", insecure=True)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("my-service", "1.0.0")
```

### Step 3: Create Spans

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def handle_request(request):
    with tracer.start_as_current_span("handle-request") as span:
        span.set_attribute("http.method", request.method)
        span.set_attribute("http.url", request.url)
        
        result = process_request(request)
        
        span.set_attribute("http.status_code", result.status_code)
        return result

def process_request(request):
    with tracer.start_as_current_span("process-request") as span:
        data = validate_input(request.body)
        saved = save_to_database(data)
        return saved
```

### Step 4: Add Metrics

```python
from opentelemetry import metrics

meter = metrics.get_meter("my-service", "1.0.0")

# Counter
request_counter = meter.create_counter(
    "http.requests.total",
    description="Total HTTP requests",
    unit="1",
)

# Histogram
request_duration = meter.create_histogram(
    "http.request.duration",
    description="HTTP request duration",
    unit="ms",
)

def handle_request(request):
    start = time.time()
    request_counter.add(1, {"http.method": request.method})
    
    result = process_request(request)
    
    duration = (time.time() - start) * 1000
    request_duration.record(duration, {
        "http.method": request.method,
        "http.status_code": result.status_code,
    })
    return result
```

### Step 5: Add Logs

```python
import logging
from opentelemetry._logs import set_logger_provider
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor, OTLPLogExporter

log_provider = LoggerProvider()
log_exporter = OTLPLogExporter(endpoint="otel-collector:4317", insecure=True)
log_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))
set_logger_provider(log_provider)

# Attach OTel handler to root logger
handler = LoggingHandler(logger_provider=log_provider)
logging.getLogger().addHandler(handler)

logger = logging.getLogger(__name__)

def handle_request(request):
    logger.info("Processing request", extra={"http.method": request.method})
    try:
        result = process(request)
        logger.info("Request completed", extra={"http.status_code": 200})
        return result
    except Exception as e:
        logger.error("Request failed", extra={"error": str(e)}, exc_info=True)
        raise
```

### Step 6: Deploy OTel Collector

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
  attributes:
    actions:
      - key: environment
        action: upsert
        value: production

exporters:
  otlp/jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, attributes, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

### Step 7: Verify Telemetry

```bash
# Check Collector metrics
curl http://localhost:8889/metrics

# Check traces in Jaeger
curl 'http://localhost:16687/api/traces?service=my-service&limit=5' | jq .

# Check metrics in Prometheus
curl 'http://localhost:9090/api/v1/query?query=http_requests_total' | jq .
```

---

## 8. Custom Instrumentation

### 8.1 Creating Custom Spans

```go
func processOrder(ctx context.Context, orderID string) error {
    tracer := otel.Tracer("order-processor")
    ctx, span := tracer.Start(ctx, "process-order",
        trace.WithAttributes(
            attribute.String("order.id", orderID),
        ),
    )
    defer span.End()

    // Add event
    span.AddEvent("validating order", trace.WithTimestamp(time.Now()))

    if err := validate(ctx, orderID); err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return err
    }

    span.SetStatus(codes.Ok, "")
    return nil
}
```

### 8.2 Custom Metrics

```go
// Create instruments
requestCounter, _ := meter.Int64Counter("app.requests.total",
    metric.WithDescription("Total requests"),
)
requestDuration, _ := meter.Float64Histogram("app.request.duration",
    metric.WithDescription("Request duration in seconds"),
    metric.WithUnit("s"),
)
activeConns, _ := meter.Int64UpDownCounter("app.connections.active",
    metric.WithDescription("Active connections"),
)

// Use instruments
requestCounter.Add(ctx, 1,
    metric.WithAttributes(
        attribute.String("method", "GET"),
        attribute.Int("status", 200),
    ),
)
requestDuration.Record(ctx, duration.Seconds(),
    metric.WithAttributes(
        attribute.String("method", "GET"),
    ),
)
activeConns.Add(ctx, 1)
defer activeConns.Add(ctx, -1)
```

### 8.3 Context Propagation

```python
# Inject context into outgoing HTTP requests
from opentelemetry.propagate import inject

headers = {}
inject(headers)  # Adds traceparent header

response = requests.get("http://other-service/api", headers=headers)

# Extract context from incoming requests
from opentelemetry.propagate import extract

extracted_context = extract(carrier=request.headers)
with tracer.start_as_current_span("process-incoming", context=extracted_context):
    # This span is now a child of the remote span
    pass
```

---

## 9. Instrumentation Libraries

### 9.1 Auto-Instrumentation by Language

| Language | Frameworks |
|---|---|
| **Java** | Spring Boot, Servlet, JAX-RS, gRPC, JDBC, Redis, Kafka, MongoDB |
| **Python** | Flask, Django, FastAPI, SQLAlchemy, psycopg2, redis, requests, urllib3 |
| **Node.js** | Express, Fastify, Koa, Hapi, pg, mysql2, redis, amqplib, grpc |
| **Go** | net/http, gRPC, gorilla/mux, gin, database/sql |
| **.NET** | ASP.NET Core, HttpClient, EF Core, SQL Server, Redis |

### 9.2 Java Auto-Instrumentation Agent

```bash
# Download
curl -LO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Run with agent
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=my-java-service \
  -Dotel.exporter.otlp.endpoint=http://otel-collector:4317 \
  -Dotel.instrumentation.jdbc.enabled=true \
  -Dotel.instrumentation.servlet.enabled=true \
  -Dotel.propagators=tracecontext,baggage \
  -jar my-app.jar
```

### 9.3 Python Auto-Instrumentation

```bash
# Using the otel CLI
pip install opentelemetry-distro opentelemetry-exporter-otlp

# Auto-instrument a Python app
opentelemetry-instrument \
  --service_name my-python-service \
  --exporter_otlp_endpoint http://otel-collector:4317 \
  --exporter_otlp_insecure \
  python my-app.py
```

---

## 10. OTel Collector Configuration

### 10.1 Receivers

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        max_recv_msg_size_mib: 4
      http:
        endpoint: 0.0.0.0:4318

  # Prometheus scrape receiver
  prometheus:
    config:
      scrape_configs:
        - job_name: 'my-app'
          static_configs:
            - targets: ['my-app:8080']

  # Kafka receiver
  kafka:
    brokers: ['kafka:9092']
    topic: otel-traces
    encoding: otlp_protobuf
```

### 10.2 Processors

```yaml
processors:
  # Batch spans before export
  batch:
    send_batch_size: 8192
    send_batch_max_size: 16384
    timeout: 5s

  # Memory limiter to prevent OOM
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128

  # Tail-based sampling (decide after seeing full trace)
  tail_sampling:
    decision_wait: 10s
    num_traces: 100000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow-traces
        type: latency
        latency: {threshold_ms: 1000}
      - name: probabilistic
        type: probabilistic
        probabilistic: {sampling_percentage: 10}

  # Transform attributes
  attributes:
    actions:
      - key: http.request.header.authorization
        action: delete
      - key: environment
        action: upsert
        value: production

  # Redact sensitive data
  attributes/redact:
    actions:
      - key: db.statement
        action: hash
      - key: http.request.body
        action: delete

  # K8s metadata enrichment
  k8sattributes:
    extract:
      metadata:
        - k8s.namespace.name
        - k8s.deployment.name
        - k8s.pod.name
        - k8s.node.name
    pod_association:
      - sources:
        - from: resource_attribute
          name: k8s.pod.ip
```

### 10.3 Exporters

```yaml
exporters:
  # Jaeger
  otlp/jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true

  # Prometheus
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel
    const_labels:
      environment: production

  # Loki (logs)
  loki:
    endpoint: http://loki:3100/loki/api/v1/push

  # Kafka (buffer)
  kafka:
    brokers: ['kafka:9092']
    topic: otel-traces
    encoding: otlp_protobuf

  # Debug (stdout)
  debug:
    verbosity: detailed

  # File (archival)
  file:
    path: /var/lib/otelcol/traces.json
```

### 10.4 Complete Pipeline

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  batch:
    send_batch_size: 8192
    timeout: 5s
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 500}
      - name: sample-10pct
        type: probabilistic
        probabilistic: {sampling_percentage: 10}
  k8sattributes:
    extract:
      metadata: [k8s.namespace.name, k8s.pod.name, k8s.deployment.name]
  attributes:
    actions:
      - key: http.request.header.authorization
        action: delete

exporters:
  otlp/jaeger:
    endpoint: jaeger-collector:14250
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889

service:
  telemetry:
    logs:
      level: info
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, k8sattributes, tail_sampling, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
  extensions: []
```

---

## 11. Integration

### 11.1 Prometheus Integration

```yaml
# Prometheus scrape config
scrape_configs:
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8889']
    metrics_path: /

  - job_name: 'otel-collector-telemetry'
    static_configs:
      - targets: ['otel-collector:8888']
    metrics_path: /
```

### 11.2 Grafana Integration

```json
{
  "datasources": [
    {
      "name": "Prometheus",
      "type": "prometheus",
      "url": "http://prometheus:9090"
    },
    {
      "name": "Jaeger",
      "type": "jaeger",
      "url": "http://jaeger-query:16687"
    },
    {
      "name": "Loki",
      "type": "loki",
      "url": "http://loki:3100"
    }
  ]
}
```

### 11.3 Kubernetes Operator Sidecar Injection

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: apps
  annotations:
    otel.opentelemetry.io/inject-sdk: "true"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    metadata:
      annotations:
        otel.opentelemetry.io/inject-sdk: "true"
        otel.opentelemetry.io/service-name: "my-service"
    spec:
      containers:
      - name: app
        image: my-service:latest
        ports:
        - containerPort: 8080
```

---

## 12. Security

### 12.1 TLS Configuration

```yaml
# Collector with TLS
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
        tls:
          cert_file: /etc/otelcol/tls/server.crt
          key_file: /etc/otelcol/tls/server.key
          client_ca_file: /etc/otelcol/tls/ca.crt
          client_auth: RequireAndVerifyClientCert

# Exporter with TLS
exporters:
  otlp/jaeger:
    endpoint: jaeger-collector:14250
    tls:
      cert_file: /etc/otelcol/tls/client.crt
      key_file: /etc/otelcol/tls/client.key
      ca_file: /etc/otelcol/tls/ca.crt
```

### 12.2 Sensitive Data Handling

```yaml
processors:
  # Remove auth headers
  attributes:
    actions:
      - key: http.request.header.authorization
        action: delete
      - key: http.request.header.cookie
        action: delete
      - key: db.statement
        action: hash
      - key: http.request.body
        action: delete
```

### 12.3 RBAC (Kubernetes)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector
rules:
- apiGroups: [""]
  resources: ['pods', 'namespaces', 'nodes']
  verbs: ['get', 'list', 'watch']
- apiGroups: ['apps']
  resources: ['deployments', 'replicasets', 'statefulsets']
  verbs: ['get', 'list', 'watch']
```

---

## 13. Troubleshooting

### Issue 1: No Traces Appearing

**Symptoms**: Application instrumented but no traces in backend.

**Diagnosis**:
```bash
# Check Collector is running
kubectl logs -l app=otel-collector --tail=100

# Check Collector metrics
curl http://localhost:8888/metrics | grep otelcol_receiver_accepted_spans_total

# Check SDK configuration
OTEL_LOG_LEVEL=debug python my-app.py
```

**Fix**: Ensure `OTEL_EXPORTER_OTLP_ENDPOINT` points to the Collector. Verify the Collector has the correct pipeline configuration.

### Issue 2: High Latency in Application

**Symptoms**: Application performance degraded after instrumentation.

**Fix**:
```python
# Use BatchSpanProcessor (not SimpleSpanProcessor)
provider.add_span_processor(BatchSpanProcessor(exporter))

# Reduce export frequency
BatchSpanProcessor(exporter, max_queue_size=2048, schedule_delay_millis=5000)
```

### Issue 3: Collector OOMKilled

**Symptoms**: Collector pods killed by OOM.

**Fix**:
```yaml
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
resources:
  limits:
    memory: 1Gi
```

### Issue 4: Export Failures (Connection Refused)

**Symptoms**: SDK logs show connection refused to Collector.

**Fix**:
```bash
# Verify network connectivity
kubectl exec -it my-pod -- curl -s http://otel-collector:4317/health

# Check service exists
kubectl get svc otel-collector
```

### Issue 5: Duplicate Traces

**Symptoms**: Same trace appears multiple times in backend.

**Fix**: Check if multiple Collectors are writing to the same backend. Use a single pipeline or deduplicate at the backend.

### Issue 6: Missing Context Propagation

**Symptoms**: Traces show as separate traces instead of a single distributed trace.

**Fix**: Ensure propagators match across services:
```python
# All services must use the same propagator
from opentelemetry.propagate import set_global_textmap
from opentelemetry.propagators.composite import CompositePropagator
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator
from opentelemetry.baggage.propagation import W3CBaggagePropagator

set_global_textmap(CompositePropagator([
    TraceContextTextMapPropagator(),
    W3CBaggagePropagator(),
]))
```

### Issue 7: Missing Metrics

**Symptoms**: Metrics not exported to Prometheus.

**Fix**:
```yaml
exporters:
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: myapp
service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
```

### Issue 8: Spans Dropped by Collector

**Symptoms**: `otelcol_exporter_send_failed_spans_total` increasing.

**Fix**: Increase queue size or add more Collector replicas:
```yaml
processors:
  batch:
    send_batch_size: 16384
    timeout: 10s
```

### Issue 9: Resource Attributes Not Appearing

**Symptoms**: Service name shows as "unknown_service".

**Fix**: Set resource correctly:
```python
from opentelemetry.sdk.resources import Resource, SERVICE_NAME

resource = Resource.create({SERVICE_NAME: "my-service"})
provider = TracerProvider(resource=resource)
```

### Issue 10: Logs Not Correlated with Traces

**Symptoms**: Logs appear in Loki but not linked to traces.

**Fix**:
```python
from opentelemetry._logs import LoggerProvider
from opentelemetry.sdk._logs import LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor, OTLPLogExporter

log_provider = LoggerProvider()
log_provider.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter()))
handler = LoggingHandler(logger_provider=log_provider)
logging.getLogger().addHandler(handler)
```

### Issue 11: Auto-Instrumentation Conflicts

**Symptoms**: Multiple instrumentations conflict or produce incorrect spans.

**Fix**: Disable conflicting instrumentations:
```bash
# Java agent
-Dotel.instrumentation.jdbc.enabled=false

# Python
OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=urllib3,requests
```

### Issue 12: Tail Sampling Not Working

**Symptoms**: Error traces not being sampled.

**Fix**: Ensure `decision_wait` is long enough for the slowest trace:
```yaml
tail_sampling:
  decision_wait: 30s
  num_traces: 200000
```

### Issue 13: Kafka Consumer Lag

**Symptoms**: Collector → Kafka pipeline showing consumer lag.

**Fix**: Increase Kafka partitions and Collector instances:
```yaml
# Kafka topic with more partitions
kafka-topics.sh --create --topic otel-traces --partitions 12 --replication-factor 3

# Multiple Collector instances
otel-collector:
  replicas: 3
```

### Issue 14: gRPC Deadline Exceeded

**Symptoms**: SDK export fails with "context deadline exceeded".

**Fix**:
```python
exporter = OTLPSpanExporter(
    endpoint="otel-collector:4317",
    timeout=30,  # seconds
)
```

### Issue 15: High CPU on Collector

**Symptoms**: Collector pods consuming excessive CPU.

**Fix**: Reduce batch processing complexity, use fewer processors, or scale horizontally:
```yaml
processors:
  batch:
    send_batch_size: 4096  # Reduce from default
    timeout: 5s
```

---

## 14. Tips & Best Practices

### Tip 1: Use Resource Attributes Consistently
Define resources once and reuse across all signals:
```python
resource = Resource.create({
    "service.name": "my-service",
    "service.version": os.getenv("APP_VERSION", "dev"),
    "deployment.environment": os.getenv("ENV", "dev"),
})
```

### Tip 2: Prefer BatchSpanProcessor
Always use `BatchSpanProcessor` in production — `SimpleSpanProcessor` causes excessive network calls.

### Tip 3: Set Appropriate Sampling
```python
# Development: capture everything
sampler = AlwaysOn()

# Staging: 50%
sampler = TraceIdRatioBased(0.5)

# Production: 10% with parent-based
sampler = ParentBased(TraceIdRatioBased(0.1))
```

### Tip 4: Use Semantic Conventions
```python
# Always use semantic convention keys
span.set_attribute("http.method", "GET")  # Standard
# Not: span.set_attribute("method", "GET")  # Custom
```

### Tip 5: Keep Spans Focused
One span = one logical operation. Don't create spans for trivial operations.

### Tip 6: Use Span Events for Discrete Events
```python
span.add_event("cache.miss", {"key": "user:123"})
# Not: span.set_attribute("cache.miss", True)
```

### Tip 7: Handle Export Failures Gracefully
The SDK queues spans in memory; if the queue is full, spans are dropped. Monitor `otelcol_exporter_send_failed_spans_total`.

### Tip 8: Use the Collector for Production
Always route through the OTel Collector in production — it provides buffering, tail sampling, and backend switching without redeploying apps.

### Tip 9: Separate Traces, Metrics, and Logs Pipelines
```yaml
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [tail_sampling, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [loki]
```

### Tip 10: Use Memory Limiter Processor
Prevents OOM by dropping telemetry when memory is high:
```yaml
processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
```

### Tip 11: Tag Sensitive Data Carefully
```python
# Hash or redact PII
span.set_attribute("user.id", hashlib.sha256(user_id.encode()).hexdigest())
# Never: span.set_attribute("user.email", email)
```

### Tip 12: Use Propagators That Match Your Stack
Default: `tracecontext,baggage` (W3C). Add `b3` if migrating from Zipkin.

### Tip 13: Test Instrumentation Locally
```bash
OTEL_TRACES_EXPORTER=console OEL_METRICS_EXPORTER=console python my-app.py
```

### Tip 14: Monitor the Collector
Key metrics:
- `otelcol_receiver_accepted_spans_total`
- `otelcol_exporter_send_failed_spans_total`
- `otelcol_processor_batch_batch_size_sum`
- `otelcol_memory_limiter_heap_alloc`

### Tip 15: Use Profiles Signal for Performance
Enable profiling to correlate traces with CPU/memory profiling data (experimental in 2025+).

### Tip 16: Version Your Instrumentation
```python
tracer = trace.get_tracer("my-service", version="1.0.0")
meter = metrics.get_meter("my-service", version="1.0.0")
```

---

## 15. Command Reference

### OTel CLI

```bash
# Auto-instrument Python app
opentelemetry-instrument \
  --service_name my-service \
  --exporter_otlp_endpoint http://otel-collector:4317 \
  --exporter_otlp_protocol grpc \
  python app.py

# Bootstrap Go instrumentation
opentelemetry-install

# Instrument Node.js
npx @opentelemetry/instrumentation -r ./my-instrumentation.js node app.js
```

### OTel Collector

```bash
# Run collector
otelcol --config=otel-collector-config.yaml

# Validate config
otelcol validate --config=otel-collector-config.yaml

# Debug mode
OTEL_LOG_LEVEL=debug otelcol --config=otel-collector-config.yaml
```

### Environment Variables

```bash
# SDK
OTEL_SERVICE_NAME=my-service
OTEL_RESOURCE_ATTRIBUTES=service.version=1.0,environment=prod
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_PROPAGATORS=tracecontext,baggage
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1

# Exporter
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_EXPORTER_OTLP_HEADERS=authorization=Bearer-token
OTEL_EXPORTER_OTLP_CERTIFICATE=/path/to/cert.pem
OTEL_EXPORTER_OTLP_INSECURE=true

# Debug
OTEL_LOG_LEVEL=debug
OTEL_TRACES_EXPORTER=console
```

### cURL Commands

```bash
# OTLP HTTP trace export
curl -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  -d '{"resourceSpans": [...]}'

# Collector health
curl http://localhost:8888/

# Collector metrics
curl http://localhost:8889/metrics

# Prometheus query
curl 'http://localhost:9090/api/v1/query?query=rate(http_requests_total[5m])'
```

---

## 16. Configuration Reference

### Full SDK Configuration

```yaml
# Python SDK via env vars
OTEL_SERVICE_NAME: "my-service"
OTEL_RESOURCE_ATTRIBUTES: "service.version=1.0,deployment.environment=production"
OTEL_TRACES_EXPORTER: "otlp"
OTEL_METRICS_EXPORTER: "otlp"
OTEL_LOGS_EXPORTER: "otlp"
OTEL_PROPAGATORS: "tracecontext,baggage"
OTEL_TRACES_SAMPLER: "parentbased_traceidratio"
OTEL_TRACES_SAMPLER_ARG: "0.1"
OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector:4317"
OTEL_EXPORTER_OTLP_PROTOCOL: "grpc"
OTEL_EXPORTER_OTLP_INSECURE: "true"
OTEL_EXPORTER_OTLP_HEADERS: "authorization=Bearer token123"
OTEL_BSP_MAX_QUEUE_SIZE: "2048"
OTEL_BSP_SCHEDULE_DELAY_MILLIS: "5000"
OTEL_BSP_MAX_EXPORT_BATCH_SIZE: "512"
OTEL_BSP_EXPORT_TIMEOUT_MILLIS: "30000"
```

### Semantic Conventions Reference

| Category | Attribute | Type | Example |
|---|---|---|---|
| HTTP | `http.method` | string | `GET` |
| HTTP | `http.url` | string | `http://localhost:8080/api` |
| HTTP | `http.status_code` | int | `200` |
| HTTP | `http.request.header.content_type` | string | `application/json` |
| HTTP | `http.response.header.content_length` | int | `1234` |
| DB | `db.system` | string | `postgresql` |
| DB | `db.statement` | string | `SELECT * FROM users` |
| DB | `db.name` | string | `mydb` |
| DB | `db.sql.table` | string | `users` |
| Net | `net.peer.name` | string | `db.example.com` |
| Net | `net.peer.port` | int | `5432` |
| RPC | `rpc.system` | string | `grpc` |
| RPC | `rpc.service` | string | `UserService` |
| RPC | `rpc.method` | string | `GetUser` |
| Messaging | `messaging.system` | string | `kafka` |
| Messaging | `messaging.destination` | string | `orders` |
| Messaging | `messaging.operation` | string | `publish` |
| Exception | `exception.type` | string | `ValueError` |
| Exception | `exception.message` | string | `invalid input` |
| Exception | `exception.stacktrace` | string | `Traceback...` |

---

## 17. Real-World Examples

### 17.1 E-Commerce Application

```
Trace: order-789 (total: 2300ms)
├── [root] POST /api/orders (2300ms)
│   ├── [a1] auth.middleware (45ms)
│   │   └── [a2] jwt.verify (20ms)
│   ├── [b1] order.validate (120ms)
│   │   └── [b2] inventory.check (80ms)
│   │       └── [b3] redis.get inventory:sku-456 (8ms)
│   ├── [c1] order.calculate-total (180ms)
│   │   ├── [c2] discount.apply (50ms)
│   │   │   └── [c3] promo-code.verify (40ms)
│   │   └── [c4] tax.calculate (30ms)
│   ├── [d1] payment.process (800ms)
│   │   ├── [d2] stripe.charge (750ms)
│   │   └── [d3] db.insert transactions (25ms)
│   ├── [e1] inventory.reserve (150ms)
│   │   └── [e2] db.update inventory (120ms)
│   ├── [f1] order.confirm (300ms)
│   │   ├── [f2] email.send (250ms)
│   │   │   └── [f3] sendgrid.deliver (200ms)
│   │   └── [f4] notification.push (40ms)
│   └── [g1] cache.invalidate (50ms)
```

### 17.2 Go Microservice (Full Example)

```go
package main

import (
    "context"
    "log"
    "net/http"
    "time"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/metric"
    "go.opentelemetry.io/otel/sdk/resource"
    tracing "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func initTracer() func() {
    ctx := context.Background()
    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("otel-collector:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        log.Fatal(err)
    }

    res := resource.NewWithAttributes(
        semconv.SchemaURL,
        semconv.ServiceName("order-service"),
        semconv.ServiceVersion("1.0.0"),
        attribute.String("environment", "production"),
    )

    tp := tracing.NewTracerProvider(
        tracing.WithBatcher(exporter),
        tracing.WithResource(res),
        tracing.WithSampler(tracing.ParentBased(
            tracing.TraceIDRatioBased(0.1),
        )),
    )
    otel.SetTracerProvider(tp)

    // Register metrics
    meterProvider := metric.NewMeterProvider(
        metric.WithResource(res),
        metric.WithReader(metric.NewPeriodicReader(
            metric.NewExporter(exporter), // OTLP metric exporter
            metric.WithInterval(30*time.Second),
        )),
    )
    otel.SetMeterProvider(meterProvider)

    return func() {
        ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
        defer cancel()
        tp.Shutdown(ctx)
    }
}

func main() {
    shutdown := initTracer()
    defer shutdown()

    mux := http.NewServeMux()
    mux.HandleFunc("/api/orders", createOrderHandler)

    // Wrap handler with OTel instrumentation
    handler := otelhttp.NewHandler(mux, "server")

    log.Fatal(http.ListenAndServe(":8080", handler))
}
```

### 17.3 Java Spring Boot with OTel Agent

```bash
# Dockerfile
FROM eclipse-temurin:17-jre-alpine
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar /opt/otel-javaagent.jar
COPY target/my-service.jar /app/my-service.jar
ENTRYPOINT ["java", \
  "-javaagent:/opt/otel-javaagent.jar", \
  "-Dotel.service.name=my-service", \
  "-Dotel.exporter.otlp.endpoint=http://otel-collector:4317", \
  "-Dotel.resource.attributes=deployment.environment=production", \
  "-jar", "/app/my-service.jar"]
```

### 17.4 Kubernetes Deployment with Operator

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
spec:
  mode: deployment
  replicas: 3
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
    processors:
      batch:
        timeout: 5s
    exporters:
      otlp/jaeger:
        endpoint: jaeger-collector:14250
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [otlp/jaeger]
```

---

## 18. Further Reading

### Official Documentation
- [OpenTelemetry Docs](https://opentelemetry.io/docs/)
- [OTel Specification](https://opentelemetry.io/docs/specs/)
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
- [OTel Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- [OTel Collector Operator](https://github.com/open-telemetry/opentelemetry-operator)

### Books
- "Observability Engineering" — Charity Majors, Liz Fong-Jones, George Miranda
- "Distributed Tracing in Practice" — Austin Parker, Daniel Spoonhower, et al.

### Tutorials
- [OTel Getting Started (Go)](https://opentelemetry.io/docs/languages/go/getting-started/)
- [OTel Getting Started (Python)](https://opentelemetry.io/docs/languages/python/getting-started/)
- [OTel Getting Started (Java)](https://opentelemetry.io/docs/languages/java/getting-started/)
- [OTel Getting Started (Node.js)](https://opentelemetry.io/docs/languages/js/getting-started/)

### Related Projects
- [Jaeger](https://www.jaegertracing.io/) — Distributed tracing backend
- [Prometheus](https://prometheus.io/) — Metrics backend
- [Grafana Tempo](https://grafana.com/oss/tempo/) — Distributed tracing backend
- [OpenMetrics](https://openmetrics.io/) — Metrics exposition format

---

*Last updated: 2026-09-04*
