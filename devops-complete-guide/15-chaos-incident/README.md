# 15 — Chaos Engineering & Incident Response

> Break things on purpose — find weaknesses before production does, and know exactly what to do when incidents happen.

This category covers chaos engineering (deliberately injecting failures to test resilience) and incident response (structured runbooks for when things break in production). Chaos tools simulate real-world failures — pod kills, network latency, node failures — so you can verify your monitoring, alerting, and recovery procedures work before a real outage.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Litmus Chaos** | Kubernetes-native chaos engineering — experiment library, ChaosHub, ChaosCenter, CRD-based fault injection for pods, nodes, network, I/O | [litmus-chaos.md](litmus-chaos.md) |
| **Chaos Monkey** | Netflix's classic chaos tool — randomly terminates production instances to test auto-scaling and fault tolerance | [chaos-monkey.md](chaos-monkey.md) |
| **Runbooks** | Structured incident response — step-by-step procedures for common failures, escalation paths, post-mortem templates | [runbooks.md](runbooks.md) |

## What You'll Learn

- Deploy Litmus ChaosCenter and run chaos experiments on Kubernetes
- Inject pod delete, network latency, pod CPU/memory stress, and node drain faults
- Design chaos experiments with hypothesis, steady-state, and blast radius
- Write operational runbooks for common incidents (pod crash, node failure, OOM)
- Integrate chaos experiments into CI/CD pipelines for continuous resilience testing
- Build a culture of blameless post-mortems and continuous improvement

## Prerequisites

- Running k3s cluster with deployed workloads (from Categories 01, 17)
- Monitoring and alerting in place (from Category 11)
- Understanding of Kubernetes pod lifecycle and node management

## Difficulty

**Advanced** — Chaos engineering requires a mature infrastructure; incident response runbooks require organizational commitment.

## Learning Path

```
Runbooks (document procedures first) → Litmus Chaos (basic experiments)
→ Chaos Monkey (instance termination) → Litmus advanced (network, I/O)
→ Chaos engineering principles (steady-state, blast radius)
→ Continuous chaos (CI/CD integration)
```
