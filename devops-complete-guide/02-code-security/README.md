# 02 — Code Security

> Catch vulnerabilities, secrets, and bad patterns before code ever reaches CI — shift-left security starts at the editor.

This category covers static analysis, secret detection, and linting tools that scan your source code for security issues. These tools run locally or in CI pipelines to catch problems at the earliest possible moment, when they're cheapest to fix. Combined, they form the first layer of defense in a DevSecOps pipeline.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **SonarQube** | Comprehensive SAST platform — bugs, code smells, vulnerabilities, and security hotspots across 30+ languages | [sonarqube.md](sonarqube.md) |
| **Semgrep** | Lightweight, fast SAST — custom rules, pattern matching, and 1000+ community rules for finding bugs and vulnerabilities | [semgrep.md](semgrep.md) |
| **Gitleaks** | Pre-commit/CI secret detection — scans git history and staged changes for API keys, tokens, and passwords | [gitleaks.md](gitleaks.md) |
| **TruffleHog** | Deep secret scanning — regex + entropy detection across git repos, with verification against live APIs | [trufflehog.md](trufflehog.md) |
| **Hadolint** | Dockerfile linter — enforces best practices, detects security anti-patterns (latest tag, root user, exposed ports) | [hadolint.md](hadolint.md) |
| **ESLint** | JavaScript/TypeScript linter — catches bugs, enforces code quality, and with security plugins detects unsafe patterns | [eslint.md](eslint.md) |

## What You'll Learn

- Run SonarQube locally or in CI to scan codebases for vulnerabilities
- Write custom Semgrep rules for project-specific security checks
- Set up pre-commit hooks with Gitleaks to prevent secret commits
- Use TruffleHog to scan entire git histories for leaked credentials
- Lint Dockerfiles with Hadolint for security best practices
- Configure ESLint security plugins for JavaScript/TypeScript projects

## Prerequisites

- Source code in a git repository
- Docker or Node.js (varies by tool)
- Basic understanding of common vulnerabilities (OWASP Top 10)

## Difficulty

**Beginner to Intermediate** — Easy to start with (pre-commit hooks), deeper customization requires understanding of AST patterns and rule writing.

## Learning Path

```
Gitleaks (quick win, pre-commit) → Hadolint (Dockerfile lint)
→ Semgrep (custom rules) → ESLint (JS/TS security)
→ SonarQube (full SAST platform) → TruffleHog (history scan)
```
