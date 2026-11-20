# 07 — Kubernetes Policy Enforcement

> Don't just hope people follow the rules — enforce them automatically at admission time with policy engines.

This category covers tools that enforce security and operational policies on your Kubernetes cluster. Policy engines validate resources at admission time, rejecting non-compliant workloads before they reach the API server. You'll learn OPA Gatekeeper, Kyverno, Pod Security Standards, Network Policies, and RBAC — the five pillars of Kubernetes policy.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **OPA Gatekeeper** | Rego-based policy engine — custom admission controller with OPA/Rego policies, audit mode, constraint templates | [opa-gatekeeper.md](opa-gatekeeper.md) |
| **Conftest** | Local policy testing — write and test OPA/Rego policies against Kubernetes manifests, Dockerfiles, Terraform | [conftest.md](conftest.md) |
| **Kyverno** | Kubernetes-native policy engine — YAML-based policies (no Rego), validate/mutate/generate, policy reports | [kyverno.md](kyverno.md) |
| **Pod Security Standards** | Built-in K8s admission — restricted/baseline/privilege profiles enforcing security contexts, volume types, capabilities | [pod-security-standards.md](pod-security-standards.md) |
| **Network Policies** | K8s native traffic control — deny-all defaults, namespace isolation, ingress/egress rules between pods | [network-policies.md](network-policies.md) |
| **RBAC** | Role-Based Access Control — fine-grained permissions for users, service accounts, and groups on K8s API resources | [rbac.md](rbac.md) |

## What You'll Learn

- Write Gatekeeper ConstraintTemplates and Rego policies for admission control
- Test policies locally with Conftest before deploying to the cluster
- Create Kyverno policies in native YAML (validate, mutate, generate, enforce)
- Apply Pod Security Standards (restricted profile) across namespaces
- Implement deny-all Network Policies with selective allow rules
- Design least-privilege RBAC roles for service accounts and users

## Prerequisites

- Running k3s cluster with admin access (from Category 01)
- Understanding of Kubernetes resource model (Pods, Deployments, Services)
- kubectl configured and connected to your cluster

## Difficulty

**Intermediate to Advanced** — Pod Security Standards and basic RBAC are approachable; OPA Gatekeeper Rego policies and complex Kyverno mutations require deeper study.

## Learning Path

```
Pod Security Standards (built-in) → RBAC (least-privilege)
→ Network Policies (deny-all) → Kyverno (YAML policies)
→ OPA Gatekeeper (Rego policies) → Conftest (local testing)
```
