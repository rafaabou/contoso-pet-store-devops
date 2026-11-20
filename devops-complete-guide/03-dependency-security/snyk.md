# Snyk Complete Guide

## Table of Contents

1. [What Is Snyk](#what-is-snyk)
2. [Why Use It](#why-use-it)
3. [Real-World Breaches](#real-world-breaches)
4. [Supported Ecosystems](#supported-ecosystems)
5. [Installation](#installation)
6. [Configuration Reference](#configuration-reference)
7. [Core Concepts](#core-concepts)
8. [Step-by-Step Usage Guide](#step-by-step-usage-guide)
9. [Custom Rules](#custom-rules)
10. [Security Features](#security-features)
11. [GitHub Actions Integration](#github-actions-integration)
12. [GitLab CI Integration](#gitlab-ci-integration)
13. [Advanced Configuration](#advanced-configuration)
14. [Troubleshooting](#troubleshooting)
15. [Tips and Best Practices](#tips-and-best-practices)
16. [Command Reference](#command-reference)
17. [Real-World Examples](#real-world-examples)
18. [Further Reading](#further-reading)

---

## What Is Snyk

Snyk is a developer-first security platform that helps you find and fix vulnerabilities in your code, dependencies, containers, and infrastructure as code. Unlike Dependabot (which is GitHub-native) or Renovate (which is self-hostable), Snyk is a commercial SaaS platform with a free tier and CLI tool.

Snyk's core products:

- **Snyk Open Source (SCA)**: Scans your dependencies for known vulnerabilities with fix advice.
- **Snyk Code (SAST)**: Static analysis for security vulnerabilities in your source code.
- **Snyk Container**: Scans container images for OS and application vulnerabilities.
- **Snyk IaC**: Scans Terraform, Kubernetes, CloudFormation, ARM templates for misconfigurations.
- **Snyk AppRisk**: Application security posture management (ASPM).

### Key Differentiators

- **Developer-first**: Integrates directly into IDEs, CLIs, and CI/CD pipelines.
- **Fix-focused**: Provides actionable fix advice with upgrade paths, patches, and alternatives.
- **License compliance**: Detects problematic open-source licenses (GPL, AGPL, etc.).
- **Multi-ecosystem**: Supports 13+ languages and package managers.
- **Vulnerability database**: Curated by Snyk's security research team (not just NVD).
- **Priority scoring**: Snyk uses exploit maturity, CVSS, reachability, and impact to prioritize.

### Architecture

Snyk operates as:

1. **CLI scans**: Local analysis using `snyk test` and `snyk monitor`.
2. **Cloud service**: Stores results, provides dashboards, and enables continuous monitoring.
3. **IDE plugins**: Real-time vulnerability scanning as you code.
4. **CI/CD integrations**: Automated security gates in your pipeline.
5. **API**: Programmatic access to vulnerability data and scan results.

---

## Why Use It

### Vulnerability Detection

Snyk's vulnerability database is curated by their security research team and goes beyond NVD:
- Faster disclosure (often before NVD entries).
- Custom vulnerability IDs (SNYK-*).
- Reachability analysis (is the vulnerable function actually called?).
- Fix priority scoring based on multiple factors.

### Fix Recommendations

Snyk doesn't just find vulnerabilities — it tells you how to fix them:
- Upgrade to a patched version.
- Apply a patch (if available).
- Use an alternative package.
- Remove the dependency if unused.

### License Compliance

Snyk detects and reports on open-source licenses:
- Flags copyleft licenses (GPL, AGPL, LGPL) that may conflict with your business.
- Identifies custom and non-standard licenses.
- Provides license compliance reports.

### Developer Experience

Snyk integrates into existing developer workflows:
- IDE plugins (VS Code, IntelliJ, Eclipse) show vulnerabilities as you code.
- Git hooks prevent commits with known vulnerabilities.
- CLI scans run in seconds for rapid feedback.
- CI/CD gates block vulnerable code from reaching production.

### Enterprise Features

- Snyk AppRisk: ASPM dashboards.
- Snyk Learn: Security education platform.
- Custom policies: Organization-wide rules for severity thresholds, ignore rules, etc.
- SSO/SAML integration.
- Audit logging.

---

## Real-World Breaches

### Log4Shell (CVE-2021-44228)

**Context**: Critical RCE in Apache Log4j2, CVSS 10.0.

**Snyk's response**: Snyk's security research team identified and classified Log4Shell within hours of disclosure. Snyk customers received:
- Immediate vulnerability detection via `snyk test`.
- Fix recommendations (upgrade to Log4j 2.15.0+, then 2.16.0+).
- Custom SNYK-JAVA-APACHELOG4J advisory with detailed remediation.
- reachability analysis showing which Log4j features were actually used.

### Spring4Shell (CVE-2022-22965)

**Context**: RCE in Spring Framework affecting millions of Java applications.

**Snyk's response**: Snyk classified this within 24 hours and provided:
- Detection via `snyk test` and `snyk monitor`.
- Upgrade paths to patched Spring versions.
- Alternative remediation for applications that cannot upgrade immediately.

### ua-parser-js (CVE-2021-27292)

**Context**: ReDoS vulnerability in a package with 8M weekly downloads.

**Snyk's response**: Snyk detected this early and provided:
- Custom vulnerability advisory with severity assessment.
- Fix recommendations (upgrade to 0.7.28+ or 1.0.32+).
- Auto-fix via `snyk fix` command.

### colors.js Sabotage (January 2022)

**Context**: Maintainer intentionally broke the popular colors.js package.

**Snyk's response**: Snyk flagged this as a malicious package and:
- Classified it with a "malicious code" label.
- Provided alternative package recommendations.
- Blocked the compromised version in CI/CD pipelines.

---

## Supported Ecosystems

| Category | Ecosystems |
|----------|-----------|
| **Languages** | JavaScript, TypeScript, Python, Java, C#/.NET, Go, Ruby, PHP, Scala, Swift, Kotlin, C/C++, Rust |
| **Package Managers** | npm, yarn, pnpm, Maven, Gradle, NuGet, pip, Pipenv, Poetry, Bundler, Composer, CocoaPods, Carthage, SPM, Cargo, Go modules |
| **Frameworks** | React, Angular, Vue.js, Django, Flask, Rails, Laravel, Spring Boot, .NET Core |
| **Containers** | Docker, OCI, Kubernetes |
| **Infrastructure** | Terraform, Kubernetes, CloudFormation, ARM templates, Helm |
| **CI/CD** | GitHub Actions, GitLab CI, CircleCI, Jenkins, Azure Pipelines, Travis CI, Bitbucket Pipelines |

---

## Installation

### Option 1: Snyk CLI

```bash
# Using npm
npm install -g snyk

# Using Homebrew (macOS/Linux)
brew install snyk

# Using Scoop (Windows)
scoop install snyk

# Using Chocolatey (Windows)
choco install snyk
```

### Option 2: Standalone Binary

```bash
# Linux
curl -fsSL https://static.snyk.io/cli/latest/snyk-linux -o snyk
chmod +x snyk
sudo mv snyk /usr/local/bin/

# macOS
curl -fsSL https://static.snyk.io/cli/latest/snyk-mac -o snyk
chmod +x snyk
sudo mv snyk /usr/local/bin/

# Windows
curl -fsSL https://static.snyk.io/cli/latest/snyk-win.exe -o snyk.exe
```

### Option 3: Docker

```bash
docker run --rm \
  -v $(pwd):/app \
  -e SNYK_TOKEN=$SNYK_TOKEN \
  snyk/snyk:node \
  test
```

### Option 4: CI/CD Integration

```yaml
# GitHub Actions
- uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high
```

### Authentication

```bash
# Authenticate with Snyk
snyk auth

# Set token via environment variable
export SNYK_TOKEN=xxxx

# Or use .snyk file for team policies
```

---

## Configuration Reference

### .snyk Policy File

The `.snyk` file defines organization-wide security policies:

```yaml
version: v1.25.0
ignore:
  SNYK-JS-LODASH-567746:
    - path: src/utils/parser.js
      reason: "Not reachable from our code"
      expires: '2025-06-01T00:00:00.000Z'
  SNYK-JS-AXIOS-1747288:
    - '*':
        reason: "Accepted risk"
        expires: '2025-12-31T00:00:00.000Z'
patch:
  SNYK-JS-LODASH-567746:
    - lodash:
        upgrade: 4.17.21
        patches:
          - path: ./patches/lodash-567746.patch
            dev: true
```

### snyk.json Configuration

```json
{
  "isDocker": false,
  "showAllPaths": true,
  "pruneDepProjects": true,
  "severityThreshold": "medium",
  "json": true,
  "sarif": true
}
```

### CLI Configuration Options

```bash
# Basic test
snyk test

# Test with severity threshold
snyk test --severity-threshold=high

# Test all projects
snyk test --all-projects

# Test specific file
snyk test --file=package.json

# Test with JSON output
snyk test --json

# Test with SARIF output (for GitHub code scanning)
snyk test --sarif-file-output=snyk-results.sarif

# Monitor (creates a snapshot in Snyk dashboard)
snyk monitor

# Ignore specific issues
snyk test --ignore=SNYK-JS-LODASH-567746

# Exclude paths
snyk test --exclude=tests
snyk test --exclude=**/test/**
```

---

## Core Concepts

### Snyk Open Source (SCA)

Software Composition Analysis scans your dependencies:
- Direct dependencies (in package.json, requirements.txt, etc.)
- Transitive dependencies (dependencies of your dependencies)
- Dev dependencies (testing tools, linters, etc.)

Example:
```bash
# Scan npm project
snyk test

# Scan with full path
snyk test --file=frontend/package.json --package-manager=npm

# Scan all package managers in monorepo
snyk test --all-projects
```

### Snyk Code (SAST)

Static Application Security Testing scans your source code:
- Detects security vulnerabilities in your own code.
- Identifies code patterns that lead to vulnerabilities.
- Provides fix recommendations with code examples.

```bash
# Scan code
snyk code test

# Scan with SARIF output
snyk code test --sarif-file-output=code-results.sarif
```

### Snyk Container

Scans container images for vulnerabilities:
- OS packages (Alpine, Ubuntu, Debian, etc.)
- Application packages inside the image.
- Base image recommendations.

```bash
# Scan a Docker image
snyk container test myapp:latest

# Monitor a Docker image
snyk container monitor myapp:latest

# Scan Dockerfile
snyk container test --file=Dockerfile myapp:latest
```

### Snyk IaC

Scans Infrastructure as Code for misconfigurations:
- Terraform (.tf files)
- Kubernetes manifests (YAML)
- CloudFormation templates
- ARM templates
- Helm charts

```bash
# Scan Terraform
snyk iac test infra/

# Scan Kubernetes manifests
snyk iac test k8s/

# Scan with SARIF output
snyk iac test --sarif-file-output=iac-results.sarif
```

### Fixing Vulnerabilities

Snyk provides multiple fix strategies:

```bash
# Attempt automatic fixes
snyk fix

# Apply patches
snyk test --patch

# View fix recommendations
snyk test --json | jq '.remediation'
```

### Monitoring

Snyk Monitor creates a snapshot of your project's security posture:
```bash
# Monitor all projects
snyk monitor

# Monitor specific project
snyk monitor --file=frontend/package.json

# Monitor with tags
snyk monitor --tags=team:backend,env:production
```

---

## Step-by-Step Usage Guide

### Step 1: Install and Authenticate

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Verify authentication
snyk whoami
```

### Step 2: Scan Your Project

```bash
# Scan for vulnerabilities
snyk test

# Example output:
# Testing /path/to/project...
#
# Organization:      my-org
# Package manager:   npm
# Target file:       package.json
# Project name:      my-project
# Opening browser...
# Dependency test results for my-project:
#
# Test type: Standard
# | Dependency      | Severity | Vulnerability | Title                                      |
# | --------------- | -------- | ------------- | ------------------------------------------ |
# | lodash          | Medium   | SNYK-JS-...   | Prototype Pollution in lodash              |
# | minimist        | High     | SNYK-JS-...   | Prototype Pollution in minimist            |
```

### Step 3: View Detailed Results

```bash
# JSON output for programmatic analysis
snyk test --json > snyk-results.json

# SARIF output for GitHub code scanning
snyk test --sarif-file-output=snyk-results.sarif

# View specific vulnerability details
snyk test --json | jq '.vulnerabilities[] | select(.id == "SNYK-JS-LODASH-567746")'
```

### Step 4: Fix Vulnerabilities

```bash
# Attempt automatic fixes
snyk fix

# Example output:
# ✓ Automatic fixes (2)
#   ✓ lodash@4.17.20 → lodash@4.17.21 (package-lock.json)
#   ✓ minimist@1.2.5 → minimist@1.2.6 (package-lock.json)
#
# Manual fixes required (1)
#   × axios@0.21.0 → Upgrade axios to 0.21.2 or later

# Apply specific patch
snyk test --patch
```

### Step 5: Monitor Your Project

```bash
# Create a snapshot in Snyk dashboard
snyk monitor

# This creates a project entry in your Snyk dashboard
# You can track new vulnerabilities over time
```

### Step 6: Integrate with CI/CD

```yaml
# .github/workflows/snyk.yml
name: Snyk Security
on: pull_request

jobs:
  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        continue-on-error: true  # Don't fail the build on vulnerabilities (optional)
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: snyk.sarif
```

### Step 7: Set Up Continuous Monitoring

```bash
# In your CI pipeline, monitor after merge to main
snyk monitor --org=my-org --project-name=main

# This updates the Snyk dashboard with current vulnerability status
```

---

## Custom Rules

### Snyk Policies (.snyk)

```yaml
version: v1.25.0

# Ignore specific vulnerabilities
ignore:
  # Ignore a specific issue globally
  SNYK-JS-LODASH-567746:
    - '*':
        reason: "Not reachable in our codebase"
        expires: '2025-06-01T00:00:00.000Z'

  # Ignore a specific issue for a specific path
  SNYK-JS-AXIOS-1747288:
    - path: src/utils/http.js
      reason: "Using axios with timeout and error handling"
      expires: '2025-12-31T00:00:00.000Z'

  # Ignore a specific issue with custom expiration
  SNYK-JS-NODEFETCHEXEC-1082148:
    - '**':
        reason: "Only used in test files"
        expires: '2025-09-01T00:00:00.000Z'

# Patch vulnerabilities
patch:
  SNYK-JS-LODASH-567746:
    - lodash:
        upgrade: 4.17.21
        patches:
          - path: ./patches/lodash-567746.patch
            dev: true
```

### Snyk Code Rules

Snyk Code uses custom rules based on:
- Taint tracking (following data flow from source to sink).
- Pattern matching (identifying insecure code patterns).
- Data flow analysis (understanding how data moves through your code).

Custom rules can be configured in the Snyk UI under Organization Settings → Snyk Code.

### Priority Rules

Snyk's priority scoring considers:
- **CVSS Score**: Common Vulnerability Scoring System.
- **Exploit maturity**: Whether exploits exist in the wild.
- **Reachability**: Whether the vulnerable code is actually called.
- **Fix availability**: Whether a patch or upgrade exists.
- **Social attention**: CVE mentions on social media, news, etc.

---

## Security Features

### Vulnerability Database

Snyk maintains a curated vulnerability database that:
- Aggregates from NVD, GitHub Advisories, maintainer reports.
- Includes custom Snyk advisories (SNYK-* IDs).
- Provides faster disclosure than NVD.
- Includes reachability analysis.

### License Compliance

```bash
# Check licenses
snyk test --json | jq '.licenses'

# Exclude problematic licenses
snyk test --json | jq '.vulnerabilities[] | select(.license == "GPL-3.0")'
```

### Container Security

```bash
# Scan container for vulnerabilities
snyk container test myapp:latest

# Scan for OS and library vulnerabilities
snyk container test myapp:latest --file=Dockerfile

# Get fix recommendations for base image
snyk container test myapp:latest --file=Dockerfile --print-deps
```

### IaC Security

```bash
# Scan Terraform for misconfigurations
snyk iac test infra/

# Scan Kubernetes manifests
snyk iac test k8s/

# Scan with custom severity threshold
snyk iac test --severity-threshold=high k8s/
```

### Code Security (SAST)

```bash
# Scan source code
snyk code test

# Scan specific directory
snyk code test src/

# Generate SARIF report
snyk code test --sarif-file-output=code-results.sarif
```

---

## GitHub Actions Integration

### Snyk Security GitHub Action

```yaml
name: Snyk Security
on: [push, pull_request]

jobs:
  snyk-open-source:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Snyk Open Source
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  snyk-code:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Snyk Code
        uses: snyk/actions/node@master
        with:
          command: code test

  snyk-container:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
      - name: Run Snyk Container
        uses: snyk/actions/docker@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          image: myapp:${{ github.sha }}
          args: --severity-threshold=high
```

### SARIF Upload for GitHub Code Scanning

```yaml
name: Snyk SARIF
on: pull_request

jobs:
  snyk:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --sarif-file-output=snyk-results.sarif
      - name: Upload SARIF to GitHub
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: snyk-results.sarif
```

### Auto-Fix Workflow

```yaml
name: Snyk Auto-Fix
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly

jobs:
  auto-fix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Snyk Fix
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          command: fix
          args: --dry-run
```

---

## GitLab CI Integration

### Snyk in GitLab CI

```yaml
stages:
  - security

snyk-open-source:
  stage: security
  image: snyk/snyk:node
  script:
    - snyk test --severity-threshold=high --json-file-output=snyk-results.json
  artifacts:
    reports:
      dependency_scanning: snyk-results.json
  only:
    - merge_requests
    - main

snyk-code:
  stage: security
  image: snyk/snyk:node
  script:
    - snyk code test --sarif-file-output=code-results.sarif
  artifacts:
    reports:
      sast: code-results.sarif
  only:
    - merge_requests
    - main

snyk-container:
  stage: security
  image: snyk/snyk:docker
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - snyk container test $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --severity-threshold=high
  only:
    - main
```

### GitLab Security Dashboard Integration

```yaml
snyk-sast:
  stage: security
  image: snyk/snyk:node
  script:
    - snyk code test --json-file-output=snyk-code.json
    # Convert to GitLab SAST format
    - node convert-to-gitlab-sast.js snyk-code.json > gl-sast.json
  artifacts:
    reports:
      sast: gl-sast.json
```

---

## Advanced Configuration

### Monorepo Scanning

```bash
# Scan all projects in a monorepo
snyk test --all-projects

# Scan specific project
snyk test --file=frontend/package.json --package-manager=npm

# Monitor specific project
snyk monitor --file=frontend/package.json --project-name=frontend

# Scan with include/exclude paths
snyk test --exclude=tests,vendor
snyk test --include=src,lib
```

### Custom Severity Thresholds

```bash
# Only show high and critical vulnerabilities
snyk test --severity-threshold=high

# Show all vulnerabilities
snyk test

# Fail CI only on critical
snyk test --severity-threshold=critical
```

### Custom Ignores

```bash
# Ignore specific vulnerability
snyk test --ignore=SNYK-JS-LODASH-567746

# Ignore specific vulnerability for specific package
snyk test --ignore=SNYK-JS-LODASH-567746:lodash

# Ignore multiple vulnerabilities
snyk test --ignore=SNYK-JS-LODASH-567746,SNYK-JS-MINIMIST-559764

# Ignore vulnerabilities by ID from .snyk policy
snyk test
```

### Output Formats

```bash
# JSON output
snyk test --json

# SARIF output (for GitHub Code Scanning)
snyk test --sarif-file-output=snyk-results.sarif

# Table output (default)
snyk test

# Summary output
snyk test --json | jq '.vulnerabilities | length'
```

### Custom Policies

```yaml
# .snyk policy file
version: v1.25.0
ignore:
  # Global ignore
  SNYK-JS-LODACH-567746:
    - '*':
        reason: "Not reachable"
        expires: '2025-06-01'

  # Path-specific ignore
  SNYK-JS-AXIOS-1747288:
    - path: src/utils/parser.js
      reason: "Using patched version"
```

---

## Troubleshooting

### 1. Snyk Auth Error

**Symptom**: `snyk auth` fails or token not recognized.

**Fix**:
```bash
# Re-authenticate
snyk auth

# Or set token directly
export SNYK_TOKEN=xxxx

# Verify
snyk whoami
```

### 2. No Dependencies Found

**Symptom**: `snyk test` says "no supported projects found".

**Fix**:
```bash
# Specify file explicitly
snyk test --file=package.json

# Specify package manager
snyk test --package-manager=npm

# Check all projects
snyk test --all-projects
```

### 3. False Positives

**Symptom**: Vulnerabilities reported for code you don't use.

**Fix**: Use ignore rules in `.snyk` policy:
```yaml
ignore:
  SNYK-JS-LODASH-567746:
    - '*':
        reason: "Not reachable in our codebase"
        expires: '2025-06-01'
```

### 4. Snyk CI Failure

**Symptom**: CI pipeline fails on Snyk test.

**Fix**:
```yaml
# Don't fail on vulnerabilities (report only)
- uses: snyk/actions/node@master
  continue-on-error: true

# Or set severity threshold
- uses: snyk/actions/node@master
  with:
    args: --severity-threshold=high
```

### 5. Snyk Cannot Resolve Private Packages

**Symptom**: Cannot scan private npm packages.

**Fix**:
```bash
# Set npm registry
export npm_config_registry=https://registry.npmjs.org
export npm_config_//npm.pkg.github.com/:_authToken=YOUR_TOKEN

# Or use .npmrc
echo "//npm.pkg.github.com/:_authToken=YOUR_TOKEN" > .npmrc
```

### 6. Snyk Monitor Not Creating Projects

**Symptom**: `snyk monitor` doesn't create project in dashboard.

**Fix**:
```bash
# Specify organization
snyk monitor --org=my-org

# Specify project name
snyk monitor --project-name=my-project

# Verify
snyk monitor --json | jq '.projectUrl'
```

### 7. Snyk Code Not Finding Vulnerabilities

**Symptom**: Known code vulnerabilities not detected.

**Fix**:
```bash
# Ensure Snyk Code is enabled in your organization
# Check Snyk UI → Organization Settings → Snyk Code

# Scan specific directory
snyk code test src/
```

### 8. Snyk Container Scan Slow

**Symptom**: Container scanning takes too long.

**Fix**:
```bash
# Scan specific layers
snyk container test myapp:latest --file=Dockerfile

# Skip OS packages (only scan app dependencies)
snyk container test myapp:latest --exclude-base-image-vulns
```

### 9. Snyk IaC False Positives

**Symptom**: IaC scan reports issues you've addressed.

**Fix**:
```bash
# Ignore specific rules
snyk iac test --rules=custom-rules.json

# Or use .snyk policy for IaC ignores
```

### 10. Snyk CLI Version Issues

**Symptom**: Outdated CLI causing errors.

**Fix**:
```bash
# Update to latest
npm update -g snyk

# Check version
snyk --version

# Or reinstall
npm install -g snyk@latest
```

### 11. Snyk API Rate Limiting

**Symptom**: Too many requests error.

**Fix**:
```bash
# Wait and retry
sleep 60 && snyk test

# Or use cached results
snyk test --json > results.json
```

### 12. Snyk SARIF Upload Fails

**Symptom**: GitHub Code Scanning doesn't show Snyk results.

**Fix**:
```yaml
# Ensure SARIF file is generated
- name: Run Snyk
  uses: snyk/actions/node@master
  with:
    args: --sarif-file-output=snyk.sarif

# Upload SARIF
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: snyk.sarif
```

### 13. Snyk Monorepo Scan Issues

**Symptom**: Only scanning one project in monorepo.

**Fix**:
```bash
# Scan all projects
snyk test --all-projects

# Or specify multiple files
snyk test --file=package.json --file=services/*/package.json
```

### 14. Snyk License Violations

**Symptom**: GPL/AGPL licenses detected in dependencies.

**Fix**:
```bash
# Check specific licenses
snyk test --json | jq '.vulnerabilities[] | select(.license == "GPL-3.0")'

# Add to ignore policy
# .snyk
ignore:
  GPL-3.0-LICENSE:
    - '*':
        reason: "Approved by legal"
```

### 15. Snyk Not Detecting New Vulnerability

**Symptom**: Known CVE not flagged by Snyk.

**Fix**:
```bash
# Update Snyk database
snyk test --dry-run  # Forces fresh scan

# Check if vulnerability exists in Snyk's database
# Visit https://snyk.io/vuln/ and search

# If not in database, report it:
# https://snyk.io/vuln/report
```

---

## Tips and Best Practices

### 1. Start with `snyk test`

Scan your project before any other security tool. Snyk's vulnerability database is frequently more up-to-date than NVD.

### 2. Use Severity Thresholds in CI

```bash
# Only fail on high/critical
snyk test --severity-threshold=high
```

### 3. Monitor Your Projects

After fixing vulnerabilities, run `snyk monitor` to create a baseline. Snyk will alert you about new vulnerabilities affecting your dependencies.

### 4. Use .snyk Policy Files

Store ignore rules and patches in version control:
```yaml
# .snyk
version: v1.25.0
ignore:
  SNYK-JS-LODASH-567746:
    - '*':
        reason: "Not reachable"
        expires: '2025-06-01'
```

### 5. Integrate Early

Add Snyk to your IDE (VS Code, IntelliJ) for real-time vulnerability detection as you code.

### 6. Use SARIF for GitHub Code Scanning

Generate SARIF output and upload to GitHub for unified security reporting:
```yaml
- uses: snyk/actions/node@master
  with:
    args: --sarif-file-output=snyk.sarif
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: snyk.sarif
```

### 7. Scan Containers Too

```bash
snyk container test myapp:latest
snyk container monitor myapp:latest
```

### 8. Use Snyk Code for SAST

Scan your source code for vulnerabilities:
```bash
snyk code test
snyk code test --sarif-file-output=code.sarif
```

### 9. Set Up Auto-Fix

```bash
# Attempt automatic fixes
snyk fix

# Review changes
git diff
```

### 10. Use `--json` for Programmatic Analysis

```bash
# Get structured output
snyk test --json > results.json

# Analyze with jq
jq '.vulnerabilities[] | select(.severity == "high")' results.json
```

### 11. Combine with Other Tools

Use Snyk alongside other security tools for defense in depth:
- Snyk Open Source (SCA) + Snyk Code (SAST)
- Snyk Container + Trivy
- Snyk IaC + tfsec

### 12. Set Up Notifications

Configure Snyk notifications for:
- New vulnerabilities in monitored projects.
- Fix availability for known issues.
- License compliance changes.

### 13. Use Grouping in CI

```yaml
# Group all security scans in one job
snyk-test:
  script:
    - snyk test --severity-threshold=high
    - snyk code test
    - snyk iac test
```

### 14. Review Fix Recommendations

Snyk's fix recommendations are not always optimal. Review them:
```bash
snyk test --json | jq '.remediation'
```

### 15. Use Snyk in Pre-Commit Hooks

```bash
# .husky/pre-commit
snyk test --severity-threshold=high
```

### 16. Track Vulnerability Metrics

Use Snyk's API to track:
- Number of vulnerabilities by severity.
- Mean time to fix.
- Vulnerability trends over time.
- Fix rate.

---

## Command Reference

### Core Commands

```bash
# Test for vulnerabilities
snyk test
snyk test --severity-threshold=high
snyk test --json
snyk test --sarif-file-output=results.sarif

# Monitor project
snyk monitor
snyk monitor --org=my-org
snyk monitor --project-name=my-project

# Fix vulnerabilities
snyk fix
snyk fix --dry-run

# Authenticate
snyk auth
snyk whoami

# Version
snyk --version
```

### Open Source (SCA) Commands

```bash
# Test dependencies
snyk test
snyk test --all-projects
snyk test --file=package.json
snyk test --package-manager=npm
snyk test --severity-threshold=high
snyk test --json
snyk test --ignore=SNYK-JS-LODASH-567746

# Monitor dependencies
snyk monitor
snyk monitor --org=my-org --project-name=my-project
```

### Code (SAST) Commands

```bash
# Test source code
snyk code test
snyk code test src/
snyk code test --severity-threshold=high
snyk code test --sarif-file-output=code.sarif
```

### Container Commands

```bash
# Test container image
snyk container test myapp:latest
snyk container test myapp:latest --file=Dockerfile
snyk container test myapp:latest --severity-threshold=high

# Monitor container
snyk container monitor myapp:latest

# Test Dockerfile
snyk container test --file=Dockerfile myapp:latest
```

### IaC Commands

```bash
# Test IaC files
snyk iac test infra/
snyk iac test k8s/
snyk iac test --severity-threshold=high
snyk iac test --sarif-file-output=iac.sarif
```

### API Commands

```bash
# List projects
snyk api GET /orgs/{orgId}/projects

# Get project details
snyk api GET /orgs/{orgId}/projects/{projectId}/issues

# Get vulnerability details
snyk api GET /vuln/{vulnId}
```

---

## Real-World Examples

### Example 1: Basic Node.js Project

```bash
# Scan
snyk test

# Fix
snyk fix

# Monitor
snyk monitor
```

### Example 2: CI/CD Pipeline (GitHub Actions)

```yaml
name: Snyk Security
on: [push, pull_request]

jobs:
  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high --sarif-file-output=snyk.sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: snyk.sarif
```

### Example 3: Docker Image Scanning

```yaml
name: Snyk Container
on: push

jobs:
  container:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Scan image
        uses: snyk/actions/docker@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          image: myapp:${{ github.sha }}
          args: --severity-threshold=high
```

### Example 4: Terraform Scanning

```yaml
name: Snyk IaC
on: pull_request

jobs:
  iac:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Scan Terraform
        uses: snyk/actions/iac@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
          directory: infra/
```

### Example 5: Monorepo with Multiple Ecosystems

```yaml
name: Snyk Full Scan
on: [push, pull_request]

jobs:
  npm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/python@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  java:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
```

---

## Further Reading

- [Snyk Official Documentation](https://docs.snyk.io/)
- [Snyk CLI Reference](https://docs.snyk.io/snyk-cli/commands)
- [Snyk API Documentation](https://docs.snyk.io/snyk-api)
- [Snyk GitHub Actions](https://github.com/snyk/actions)
- [Snyk Learn](https://learn.snyk.io/)
- [Snyk Vulnerability Database](https://snyk.io/vuln/)
- [Snyk Container Scanning](https://docs.snyk.io/products/snyk-container)
- [Snyk IaC Scanning](https://docs.snyk.io/products/snyk-infrastructure-as-code)
- [Snyk Code (SAST)](https://docs.snyk.io/products/snyk-code)
- [Snyk AppRisk (ASPM)](https://docs.snyk.io/products/snyk-apprisk)
