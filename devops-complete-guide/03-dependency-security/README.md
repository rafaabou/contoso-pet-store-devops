# 03 — Dependency Security

> Every `npm install` or `pip install` pulls in code you didn't write — these tools tell you when that code has known vulnerabilities.

This category covers tools that scan your project dependencies (packages, libraries, transitive dependencies) for known CVEs and vulnerabilities. Modern applications depend on hundreds or thousands of third-party packages; maintaining visibility into their security posture is critical for any production system.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Dependabot** | GitHub-native dependency updater — automatically creates PRs when dependencies have known vulnerabilities or updates available | [dependabot.md](dependabot.md) |
| **Renovate** | Highly configurable dependency updater — supports 80+ package managers, auto-merge rules, monorepo-aware updates | [renovate.md](renovate.md) |
| **Snyk** | Developer-first security platform — finds and fixes vulnerabilities in dependencies, containers, and IaC with fix PRs | [snyk.md](snyk.md) |
| **OWASP Dependency-Check** | Open-source SCA — matches dependency versions against the NIST NVD database for known CVEs | [owasp-dependency-check.md](owasp-dependency-check.md) |
| **OSV-Scanner** | Google's open-source vulnerability scanner — uses the OSV database for comprehensive, language-agnostic dependency scanning | [osv-scanner.md](osv-scanner.md) |

## What You'll Learn

- Configure Dependabot for automated dependency updates with security alerts
- Set up Renovate with custom update rules and auto-merge policies
- Use Snyk to find and fix vulnerabilities with automated PRs
- Run OWASP Dependency-Check in CI for CVE reporting
- Scan dependencies with OSV-Scanner for language-agnostic vulnerability detection
- Understand transitive dependency risks and supply chain attacks

## Prerequisites

- Project with a dependency manifest (package.json, requirements.txt, go.mod, pom.xml, etc.)
- GitHub repository (for Dependabot) or CI pipeline
- Basic understanding of semver and package management

## Difficulty

**Beginner** — Most tools are plug-and-play (Dependabot is a single YAML config file).

## Learning Path

```
Dependabot or Renovate (automated updates) → OSV-Scanner (quick scan)
→ Snyk (full platform) → OWASP Dependency-Check (CVE reports)
→ Renovate advanced (auto-merge, grouping, scheduling)
```
