# 04 — Build & CI/CD

> Automate everything from code push to production deploy — the pipeline is the backbone of DevOps.

This category covers CI/CD pipelines, container build tools, and deployment packaging. You'll learn to run GitHub Actions locally with Act, build optimized multi-stage images with BuildKit, and package Kubernetes manifests with Helm Charts and Kustomize for GitOps-ready deployments.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **GitHub Actions** | Cloud CI/CD platform — YAML workflows triggered by git events, 20,000+ marketplace actions, matrix builds, reusable workflows | [github-actions.md](github-actions.md) |
| **Act** | Run GitHub Actions locally — Docker-based runner that emulates the GitHub Actions environment on your machine | [act.md](act.md) |
| **BuildKit** | Next-gen Docker build engine — multi-stage builds, build secrets, parallel stages, SSH forwarding, caching | [buildkit.md](buildkit.md) |
| **Helm Charts** | Kubernetes packaging — templated manifests, values files, release management, dependency declaration | [helm-charts.md](helm-charts.md) |
| **Kustomize** | Declarative manifest customization — overlays, patches, and generators without templating | [kustomize.md](kustomize.md) |

## What You'll Learn

- Write GitHub Actions workflows with matrix builds, caching, and secrets
- Test workflows locally with Act before pushing to GitHub
- Optimize Docker builds with BuildKit (multi-stage, cache mounts, secrets)
- Create reusable Helm charts for microservice deployment
- Use Kustomize overlays for environment-specific configurations (dev/staging/prod)
- Combine Helm and Kustomize for layered GitOps deployments

## Prerequisites

- GitHub account and repository
- Docker installed locally (for Act and BuildKit)
- Basic understanding of YAML, Dockerfiles, and Kubernetes manifests
- k3s cluster running (from Category 01)

## Difficulty

**Beginner to Intermediate** — GitHub Actions is approachable; BuildKit advanced features and Helm chart design require deeper understanding.

## Learning Path

```
GitHub Actions basics → Act (local testing)
→ BuildKit (optimized images) → Helm Charts (packaging)
→ Kustomize (overlay strategy) → Combined workflows
```
