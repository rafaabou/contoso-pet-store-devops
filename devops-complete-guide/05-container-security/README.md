# 05 — Container Security

> Secure the entire container lifecycle — scan images for CVEs, generate SBOMs, sign artifacts, and minimize attack surfaces.

This category covers tools for securing container images before and after they reach production. You'll scan images for known vulnerabilities, generate software bills of materials (SBOMs), cryptographically sign images to ensure integrity, and learn why distroless base images dramatically reduce your attack surface.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Trivy** | All-in-one vulnerability scanner — images, filesystems, git repos, IaC, Kubernetes. Supports OCI/SBOM output | [trivy.md](trivy.md) |
| **Grype** | Fast container image vulnerability scanner — pairs with Syft for SBOM-based scanning, Anchore ecosystem | [grype.md](grype.md) |
| **Syft** | SBOM generator — creates comprehensive bills of materials from container images in SPDX and CycloneDX formats | [syft.md](syft.md) |
| **Cosign** | Sigstore image signing — keyless signing with OIDC, verify supply chain integrity, signer identities | [cosign.md](cosign.md) |
| **Notary** | Content trust system — Docker Content Trust (DCT) signing, TUF-based key management, notary v2 for OCI | [notary.md](notary.md) |
| **Distroless** | Minimal container base images — no shell, no package manager, no attack surface. Just your app and its runtime | [distroless.md](distroless.md) |

## What You'll Learn

- Scan container images for CVEs with Trivy and Grype in CI pipelines
- Generate SBOMs with Syft for compliance and vulnerability tracking
- Sign container images with Cosign using keyless OIDC-based signing
- Understand Notary v2 and Docker Content Trust for image verification
- Build with distroless base images to minimize attack surface
- Integrate all tools into a secure CI/CD pipeline

## Prerequisites

- Docker installed and basic Dockerfile knowledge
- A container registry (Docker Hub, GHCR, or your own)
- Understanding of CVE scoring (CVSS) basics

## Difficulty

**Intermediate** — Scanning is straightforward; signing workflows and SBOM formats require deeper understanding.

## Learning Path

```
Trivy (quick scan) → Grype + Syft (SBOM-based scanning)
→ Distroless (minimize images) → Cosign (sign images)
→ Notary (advanced content trust)
```
