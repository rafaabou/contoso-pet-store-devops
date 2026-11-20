# 16 — Compliance & Benchmarking

> Prove your cluster meets security standards — automated CIS benchmark checks that generate audit-ready reports.

This category covers compliance scanning and security benchmarking for Kubernetes clusters. CIS (Center for Internet Security) benchmarks define the security best practices for Kubernetes configuration. These tools automatically check your cluster against those benchmarks and generate reports showing exactly what passes, what fails, and how to fix it.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **CIS Benchmark** | Industry standard security configuration guide — 200+ controls covering API server, controller manager, scheduler, etcd, nodes, policies | [cis-benchmark.md](cis-benchmark.md) |
| **kube-bench** | Automated CIS benchmark checker — runs checks against your live cluster, generates pass/fail/warning reports, JSON output for CI | [kube-bench.md](kube-bench.md) |

## What You'll Learn

- Understand the CIS Kubernetes Benchmark (controls, severity levels, remediation)
- Run kube-bench against your k3s cluster and interpret results
- Fix common CIS failures: anonymous auth, audit logging, encryption, RBAC
- Integrate kube-bench into CI pipelines for continuous compliance monitoring
- Generate audit-ready compliance reports for SOC 2, PCI-DSS, HIPAA requirements
- Understand the difference between node-level and cluster-level checks

## Prerequisites

- Running k3s cluster with root access (from Category 01)
- kubectl configured (from Category 01)
- Understanding of Kubernetes security concepts (API server auth, RBAC, network policies)

## Difficulty

**Intermediate** — Running kube-bench is easy; remediating failures requires understanding of Kubernetes security architecture.

## Learning Path

```
CIS Benchmark (read the standard) → kube-bench (run checks)
→ Interpret results → Fix critical/high findings
→ Automate in CI → Continuous compliance monitoring
```
