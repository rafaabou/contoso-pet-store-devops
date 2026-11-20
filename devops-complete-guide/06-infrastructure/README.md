# 06 — Infrastructure as Code

> Define, provision, and configure infrastructure in code — repeatable, auditable, and version-controlled.

This category covers Infrastructure as Code (IaC) tools for provisioning cloud and on-prem resources, configuring servers, and enforcing security policies on your infrastructure definitions. Terraform handles provisioning, Ansible handles configuration, and Checkov/tfsec/Trivy IaC scan your IaC for security misconfigurations before they reach production.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Terraform** | Declarative IaC provisioning — cloud resources, networking, Kubernetes clusters, DNS, TLS certificates via providers | [terraform.md](terraform.md) |
| **Ansible** | Agentless configuration management — SSH-based playbooks for server setup, package installation, service management | [ansible.md](ansible.md) |
| **Checkov** | IaC security scanner — 1000+ policies for Terraform, CloudFormation, Kubernetes, Docker, Helm, and more | [checkov.md](checkov.md) |
| **tfsec** | Terraform-specific security scanner — deep analysis of Terraform plans and HCL for misconfigurations and vulnerabilities | [tfsec.md](tfsec.md) |
| **Trivy IaC** | Multi-format IaC scanner — Terraform, CloudFormation, Dockerfile, Kubernetes manifests, Helm charts | [trivy-iac.md](trivy-iac.md) |

## What You'll Learn

- Write Terraform configurations for provisioning Incus VMs, DNS, and Kubernetes resources
- Create Ansible playbooks for automated server configuration and hardening
- Scan Terraform code with Checkov, tfsec, and Trivy before `terraform apply`
- Understand the difference between provisioning (Terraform) and configuration (Ansible)
- Implement policy-as-code for infrastructure definitions
- Use drift detection to catch manual changes

## Prerequisites

- Running k3s cluster (from Category 01)
- Understanding of YAML and HCL basics
- SSH access to target machines
- Provider credentials (Incus, cloud providers if applicable)

## Difficulty

**Intermediate to Advanced** — Terraform basics are approachable; complex modules, state management, and security scanning require deeper expertise.

## Learning Path

```
Terraform basics (HCL, state, providers) → Ansible (playbooks, roles)
→ Checkov (IaC scanning) → tfsec (Terraform deep scan)
→ Trivy IaC (multi-format) → Advanced patterns (modules, workspaces)
```
