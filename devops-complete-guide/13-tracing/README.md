# 13 — Distributed Tracing

> Follow a single request across 8 microservices — find exactly where it's slow, failing, or lost.

This category covers distributed tracing, which tracks requests as they flow through multiple services. When a user request touches the API gateway, order service, payment service, and database, tracing shows you the full journey with timing, errors, and context at each hop. OpenTelemetry provides the instrumentation standard; Jaeger stores and visualizes the traces.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Jaeger** | Distributed tracing backend — trace collection, storage (Elasticsearch/Cassandra), query API, trace visualization, dependency analysis | [jaeger.md](jaeger.md) |
| **OpenTelemetry** | Vendor-neutral instrumentation standard — SDKs for 11+ languages, auto-instrumentation, context propagation, traces + metrics + logs | [opentelemetry.md](opentelemetry.md) |

## What You'll Learn

- Deploy Jaeger on Kubernetes (all-in-one or production with Elasticsearch)
- Instrument microservices with OpenTelemetry SDKs (Python, Go, Node.js)
- Use auto-instrumentation to add tracing without code changes
- Understand trace context propagation across service boundaries
- Query traces by service, operation, duration, and error status
- Correlate traces with Prometheus metrics and Loki logs
- Analyze service dependency graphs from trace data

## Prerequisites

- Running k3s cluster with microservices (from Categories 01, 17)
- Understanding of HTTP request/response flow
- Familiarity with Prometheus metrics (from Category 11)

## Difficulty

**Intermediate to Advanced** — Jaeger deployment is straightforward; OpenTelemetry instrumentation and context propagation require deeper understanding of distributed systems concepts.

## Learning Path

```
Jaeger (all-in-one deploy) → OpenTelemetry Collector
→ Auto-instrumentation (Python/Go/Node.js)
→ Manual instrumentation (custom spans) → Context propagation
→ Trace ↔ metrics/logs correlation → Advanced (sampling, tail-based)
```
