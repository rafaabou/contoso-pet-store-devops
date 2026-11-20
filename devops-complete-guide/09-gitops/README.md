# 09 — GitOps

> Git as the single source of truth — declarative, auditable, and fully automated deployments from every commit.

This category covers the GitOps methodology and the ArgoCD ecosystem. GitOps means your git repository IS your deployment pipeline: every change to infrastructure or application config flows through git, gets reviewed, and is automatically reconciled by the cluster. ArgoCD watches your repo and ensures the cluster state always matches what's declared in git.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **ArgoCD** | GitOps delivery engine — continuous reconciliation, multi-cluster support, RBAC, SSO, drift detection, rollback | [argocd.md](argocd.md) |
| **Argo Rollouts** | Progressive delivery — canary, blue-green, and A/B deployments with automated analysis and rollback | [argo-rollouts.md](argo-rollouts.md) |
| **Argo Image Updater** | Automated image updates — watches container registries for new tags and updates ArgoCD applications automatically | [argo-image-updater.md](argo-image-updater.md) |

## What You'll Learn

- Deploy ArgoCD to your k3s cluster with Helm or manifests
- Configure ArgoCD Applications to watch git repos and sync to the cluster
- Implement canary and blue-green deployments with Argo Rollouts
- Set up automated image updates with Argo Image Updater
- Design multi-environment GitOps workflows (dev → staging → prod)
- Understand pull-based deployment vs. push-based CI/CD

## Prerequisites

- Running k3s cluster (from Category 01)
- Helm and kubectl configured (from Categories 01/04)
- A container registry with your application images
- Git repository with Kubernetes manifests or Helm charts

## Difficulty

**Intermediate** — ArgoCD basics are straightforward; Rollouts analysis templates and Image Updater annotations require deeper understanding.

## Learning Path

```
ArgoCD (basic sync) → Argo Rollouts (canary/blue-green)
→ Argo Image Updater (auto-updates) → Advanced patterns
(multi-cluster, multi-tenancy, RBAC, SSO)
```
