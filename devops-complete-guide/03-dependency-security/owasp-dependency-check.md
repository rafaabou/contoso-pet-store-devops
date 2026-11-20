# OWASP Dependency Check Complete Guide

## Table of Contents

1. [What Is OWASP Dependency Check](#what-is-owasp-dependency-check)
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

## What Is OWASP Dependency Check

OWASP Dependency Check is a Software Composition Analysis (SCA) tool that identifies project dependencies and checks for publicly disclosed vulnerabilities. It is an official OWASP (Open Web Application Security Project) tool and is completely free and open-source (Apache 2.0 license).

Unlike commercial tools (Snyk, WhiteSource/Mend), OWASP Dependency Check:
- Is completely free with no usage limits.
- Uses the National Vulnerability Database (NVD) as its primary source.
- Can be run entirely offline after initial database download.
- Does not require authentication or cloud connectivity.
- Is widely used in compliance-heavy environments (PCI DSS, HIPAA, SOC 2).

### Key Features

- **Vulnerability detection**: Matches dependencies against NVD, NIS, and other vulnerability databases.
- **License detection**: Identifies open-source licenses in dependencies.
- **CVE enumeration**: Maps dependencies to specific CVEs.
- **Multiple report formats**: HTML, JSON, XML, SARIF, CSV, JUNIT, etc.
- **Incremental scanning**: Caches results for faster subsequent scans.
- **Monorepo support**: Scans multiple projects in a single run.
- **Offline capability**: Works without internet after initial database download.

### Architecture

OWASP Dependency Check operates in three phases:

1. **Collection**: Scans the project directory for dependency files (pom.xml, package.json, requirements.txt, etc.) and extracts dependency information.
2. **Analysis**: Matches extracted dependency identifiers (CPE, package coordinates) against the vulnerability database.
3. **Reporting**: Generates reports in various formats with vulnerability details, severity, and remediation advice.

---

## Why Use It

### Cost

OWASP Dependency Check is free and open-source. No licensing fees, no usage limits, no enterprise contracts. This makes it ideal for:
- Small projects and startups.
- Open-source projects.
- Compliance testing in regulated industries.
- Academic and research projects.

### Compliance

OWASP Dependency Check is recognized by:
- PCI DSS (Payment Card Industry Data Security Standard).
- HIPAA (Health Insurance Portability and Accountability Act).
- SOC 2 (Service Organization Control 2).
- ISO 27001.
- NIST SP 800-53.

Many compliance auditors accept OWASP Dependency Check reports as evidence of vulnerability scanning.

### Offline Capability

After downloading the NVD database, OWASP Dependency Check can run entirely offline. This is critical for:
- Air-gapped environments (military, government, financial).
- Restricted network environments.
- CI/CD pipelines with limited internet access.

### Transparency

As an open-source tool:
- Full source code is available for audit.
- No hidden data collection or telemetry.
- Community-driven development and bug fixes.
- Extensible via plugins and custom analyzers.

### Self-Hosted

No cloud dependency. You control:
- Where the tool runs.
- Where the data is stored.
- How long data is retained.
- What data is shared (none by default).

---

## Real-World Breaches

### Log4Shell (CVE-2021-44228)

**Impact**: Critical RCE in Apache Log4j2, affecting millions of Java applications.

**How OWASP Dependency Check helps**: After adding the CVE to NVD, OWASP Dependency Check detects vulnerable Log4j versions in any Java project. Organizations using OWASP DC in their CI/CD pipeline could immediately identify affected projects.

**Setup for detection**:
```bash
# Scan Java project
dependency-check --project "My Java App" \
  --scan ./src \
  --out ./report \
  --format HTML \
  --format JSON
```

### Spring4Shell (CVE-2022-22965)

**Impact**: RCE in Spring Framework affecting millions of Java applications.

**How OWASP Dependency Check helps**: Detects vulnerable Spring Framework versions via CPE matching. Organizations running regular scans could identify affected versions and prioritize upgrades.

### Apache Struts (CVE-2017-5638)

**Impact**: RCE in Apache Struts, famously exploited in the Equifax breach.

**How OWASP Dependency Check helps**: Detects vulnerable Struts versions. Organizations using OWASP DC could have identified the vulnerability before exploitation.

**Detection example**:
```bash
dependency-check --project "Equifax App" \
  --scan ./webapp/WEB-INF/lib \
  --out ./report \
  --format HTML
# Report shows: CVE-2017-5638 affecting struts2-core-2.3.32.jar
```

### OpenSSL (CVE-2014-0160) — Heartbleed

**Impact**: Critical information disclosure vulnerability in OpenSSL.

**How OWASP Dependency Check helps**: Detects vulnerable OpenSSL versions in projects that include the library. While primarily a system-level vulnerability, applications bundling OpenSSL would be flagged.

### Jackson Databind (CVE-2019-12384)

**Impact**: Deserialization vulnerability in a popular Java JSON library.

**How OWASP Dependency Check helps**: Detects vulnerable Jackson versions. OWASP DC's CPE matching identifies jackson-databind vulnerabilities and provides upgrade recommendations.

---

## Supported Ecosystems

OWASP Dependency Check supports a wide range of package managers and dependency files:

| Ecosystem | Supported Files | Detection Method |
|-----------|----------------|------------------|
| **Java** | pom.xml, build.gradle, build.gradle.kts, settings.gradle, ivy.xml, lib/*.jar | Maven Central, CPE |
| **JavaScript** | package.json, package-lock.json, yarn.lock, pnpm-lock.yaml | NPM registry, CPE |
| **Python** | requirements.txt, setup.py, setup.cfg, pyproject.toml, Pipfile, poetry.lock | PyPI, CPE |
| **Ruby** | Gemfile, Gemfile.lock | RubyGems, CPE |
| **PHP** | composer.json, composer.lock | Packagist, CPE |
| **.NET** | packages.config, *.csproj, project.json, paket.dependencies, paket.lock | NuGet, CPE |
| **Go** | go.mod, go.sum | Go modules, CPE |
| **Rust** | Cargo.toml, Cargo.lock | crates.io, CPE |
| **C/C++** | conanfile.txt, conanfile.py, vcpkg.json, CMakeLists.txt | Conan, vcpkg, CPE |
| **Swift** | Package.swift, Podfile, Cartfile | SPM, CocoaPods, CPE |
| **Kotlin** | build.gradle.kts, build.gradle | Maven Central, CPE |
| **Scala** | build.sbt, pom.xml | Maven Central, CPE |
| **Docker** | Dockerfile | Docker Hub, CPE |
| **OS Packages** | dpkg status, rpm -qa | NVD |
| **CocoaPods** | Podfile, Podfile.lock | CocoaPods, CPE |
| **Composer** | composer.json, composer.lock | Packagist, CPE |

---

## Installation

### Option 1: Standalone CLI

```bash
# Download latest release
wget https://github.com/jeremylong/DependencyCheck/releases/latest/download/dependency-check.zip

# Extract
unzip dependency-check.zip

# Add to PATH
export PATH=$PATH:/path/to/dependency-check/bin

# Verify
dependency-check --version
```

### Option 2: Homebrew (macOS)

```bash
brew install dependency-check
```

### Option 3: Docker

```bash
# Scan current directory
docker run --rm \
  -v $(pwd):/src \
  -v $(pwd)/report:/report \
  owasp/dependency-check \
  --project "My Project" \
  --scan /src \
  --out /report \
  --format HTML
```

### Option 4: Maven Plugin

```xml
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
  <version>9.0.9</version>
  <configuration>
    <failBuildOnCVSS>7</failBuildOnCVSS>
    <formats>
      <format>HTML</format>
      <format>JSON</format>
    </formats>
  </configuration>
</plugin>
```

### Option 5: Gradle Plugin

```groovy
plugins {
  id 'org.owasp.dependencycheck' version '9.0.9'
}

dependencyCheck {
  failBuildOnCVSS = 7
  formats = ['HTML', 'JSON']
}
```

### Option 6: npm Package

```bash
npm install -g @owasp/dependency-check-cli
```

### Option 7: pip Package

```bash
pip install dependency-check
```

### Initial Database Download

```bash
# Download NVD database (takes several minutes)
dependency-check --version  # Triggers initial download

# Or manually update
dependency-check --updateonly
```

---

## Configuration Reference

### Command-Line Options

```bash
dependency-check \
  --project "Project Name" \
  --scan /path/to/project \
  --out /path/to/report \
  --format HTML \
  --format JSON \
  --format SARIF \
  --format CSV \
  --format JUNIT \
  --format SARIF \
  --failBuildOnCVSS 7 \
  --nvdApiKey $NVD_API_KEY \
  --proxy http://proxy:8080 \
  --connectionTimeout 30000 \
  --data /path/to/data \
  --updateonly \
  --purge \
  --noupdate \
  --disableAssemblyAnalyzer \
  --disableNVD \
  --suppressionFile suppressions.xml
```

### Configuration File (dependency-check.properties)

```properties
# Proxy settings
proxy.url=http://proxy.example.com:8080
proxy.username=proxyuser
proxy.password=proxypass

# NVD API settings
nvd.api.delay=5000
nvd.api.batch.size=200
nvd.api.key=YOUR_API_KEY

# Scan settings
scan.directory=./src
project.name=My Project

# Report settings
report.output=./report
report.format=HTML,JSON,SARIF

# Database settings
data.directory=~/.dependency-check/data
database.drivername=org.h2.Driver

# Analyzer settings
analyzer.assembly.enabled=true
analyzer.archive.enabled=true
analyzer.jar.enabled=true
analyzer.central.enabled=true
analyzer.nexus.enabled=false
analyzer.maven.enabled=true

# CVSS settings
fail.build.on.cvss=7
cvss.score.description=summary

# Thread settings
analyzers.thread.count=4
```

### XML Configuration (dependency-check.xml for Maven)

```xml
<project>
  <plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>9.0.9</version>
    <configuration>
      <failBuildOnCVSS>7</failBuildOnCVSS>
      <suppressionFiles>
        <suppressionFile>suppressions.xml</suppressionFile>
      </suppressionFiles>
      <formats>
        <format>HTML</format>
        <format>JSON</format>
        <format>SARIF</format>
      </formats>
      <nvdApiKey>${env.NVD_API_KEY}</nvdApiKey>
      <retireJsUrl>https://js repositories.snyk.io/retire/</retireJsUrl>
    </configuration>
  </plugin>
</project>
```

### Suppression File

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <suppress>
    <notes>Not reachable from our codebase</notes>
    <filePath regex="true">.*log4j-.*\.jar</filePath>
    <cve>CVE-2021-44228</cve>
    <cve>CVE-2021-45046</cve>
    <cve>CVE-2021-45105</cve>
  </suppress>
  <suppress>
    <notes>Using patched version</notes>
    <filePath regex="true">.*jackson-databind-.*\.jar</filePath>
    <cve>CVE-2019-12384</cve>
  </suppress>
  <suppress>
    <notes>False positive - different package</notes>
    <gav regex="true">org\.apache\.commons:commons-io:.*</gav>
    <cve>CVE-2021-29425</cve>
  </suppress>
</suppressions>
```

---

## Core Concepts

### Common Platform Enumeration (CPE)

OWASP Dependency Check uses CPE identifiers to match dependencies to vulnerabilities:

```
cpe:2.3:a:apache:log4j:2.14.1:*:*:*:*:*:*:*
  |   |     |      |      |     | | | | | | | |
  |   |     |      |      |     | | | | | | | └─ Part (a=application)
  |   |     |      |      |     | | | | | | └─── Vendor (apache)
  |   |     |      |      |     | | | | | └───── Product (log4j)
  |   |     |      |      |     | | | | └─────── Version (2.14.1)
  |   |     |      |      |     | | | └───────── Other fields
```

The tool generates CPEs from dependency coordinates (groupId:artifactId:version) and matches them against NVD entries.

### Vulnerability Scoring

OWASP Dependency Check uses CVSS (Common Vulnerability Scoring System):

| Score | Severity | CI Behavior |
|-------|----------|-------------|
| 0.0 | None | Pass |
| 0.1-3.9 | Low | Pass (default) |
| 4.0-6.9 | Medium | Pass (default) |
| 7.0-8.9 | High | Fail (default) |
| 9.0-10.0 | Critical | Fail (default) |

Configure with `--failBuildOnCVSS`:
```bash
dependency-check --failBuildOnCVSS 7  # Fail on High and Critical
dependency-check --failBuildOnCVSS 4  # Fail on Medium, High, and Critical
dependency-check --failBuildOnCVSS 10 # Never fail (report only)
```

### Report Formats

| Format | Use Case |
|--------|----------|
| HTML | Human-readable reports |
| JSON | Programmatic analysis |
| SARIF | GitHub Code Scanning integration |
| CSV | Spreadsheet analysis |
| JUNIT | CI/CD test results |
| XML | Machine-readable (OWASP format) |
| Markdown | Documentation |
| JENKINS | Jenkins plugin integration |

### Database Management

OWASP Dependency Check maintains a local copy of the NVD database:

```bash
# Update database
dependency-check --updateonly

# Check database age
dependency-check --info

# Purge old data
dependency-check --purge

# Set custom data directory
dependency-check --data /path/to/data
```

### Analyzers

OWASP Dependency Check uses multiple analyzers:

- **JarAnalyzer**: Analyzes Java JAR files.
- **AssemblyAnalyzer**: Analyzes .NET assemblies.
- **NexusAnalyzer**: Queries Nexus repository for dependency info.
- **CentralAnalyzer**: Queries Maven Central.
- **RetireJSAnalyzer**: Checks JavaScript for known vulnerable versions.
- **NodePackageAnalyzer**: Analyzes node_modules.
- **PythonPackageAnalyzer**: Analyzes Python packages.
- **RubyGemAnalyzer**: Analyzes Ruby gems.
- **ComposerLockAnalyzer**: Analyzes PHP Composer lock files.

---

## Step-by-Step Usage Guide

### Step 1: Install OWASP Dependency Check

```bash
# Download
wget https://github.com/jeremylong/DependencyCheck/releases/latest/download/dependency-check.zip
unzip dependency-check.zip
export PATH=$PATH:$(pwd)/dependency-check/bin

# Verify
dependency-check --version
```

### Step 2: Download NVD Database

```bash
# First run downloads the database (takes several minutes)
dependency-check --updateonly

# Check database status
dependency-check --info
```

### Step 3: Scan Your Project

```bash
# Scan current directory
dependency-check \
  --project "My Project" \
  --scan . \
  --out ./report \
  --format HTML

# Scan specific directory
dependency-check \
  --project "My Project" \
  --scan ./src \
  --out ./report \
  --format HTML \
  --format JSON

# Scan with severity threshold
dependency-check \
  --project "My Project" \
  --scan . \
  --out ./report \
  --format HTML \
  --failBuildOnCVSS 7
```

### Step 4: Review the Report

```bash
# Open HTML report
open ./report/dependency-check-report.html

# Analyze JSON report
jq '.dependencies[] | select(.vulnerabilities | length > 0)' ./report/dependency-check-report.json

# Count vulnerabilities
jq '[.dependencies[].vulnerabilities[]] | length' ./report/dependency-check-report.json
```

### Step 5: Address Vulnerabilities

```bash
# Review specific CVE
jq '.dependencies[] | select(.vulnerabilities[].name == "CVE-2021-44228")' ./report/dependency-check-report.json

# Check for available fixes
jq '.dependencies[] | select(.vulnerabilities | length > 0) | {name, version, vulnerabilities: [.vulnerabilities[].name]}' ./report/dependency-check-report.json
```

### Step 6: Suppress False Positives

```bash
# Create suppression file
cat > suppressions.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <suppress>
    <notes>Not reachable</notes>
    <filePath regex="true">.*log4j-.*\.jar</filePath>
    <cve>CVE-2021-44228</cve>
  </suppress>
</suppressions>
EOF

# Use suppression file
dependency-check \
  --project "My Project" \
  --scan . \
  --out ./report \
  --format HTML \
  --suppressionFile suppressions.xml
```

### Step 7: Integrate with CI/CD

```yaml
# GitHub Actions
- name: OWASP Dependency Check
  uses: dependency-check/Dependency-Check_Action@main
  with:
    path: './src'
    format: 'HTML'
    args: '--failBuildOnCVSS 7'
```

### Step 8: Set Up Automated Scanning

```yaml
# Schedule regular scans
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly
  push:
    branches: [main]
  pull_request:
```

---

## Custom Rules

### Suppression Rules

Suppress specific vulnerabilities:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <!-- Suppress by CVE ID -->
  <suppress>
    <notes>False positive</notes>
    <cve>CVE-2021-44228</cve>
  </suppress>

  <!-- Suppress by file path -->
  <suppress>
    <notes>Not reachable</notes>
    <filePath regex="true">.*log4j-.*\.jar</filePath>
    <cve>CVE-2021-44228</cve>
  </suppress>

  <!-- Suppress by GAV (Group:Artifact:Version) -->
  <suppress>
    <notes>Using patched version</notes>
    <gav regex="true">org\.apache\.log4j:log4j-core:2\..*</gav>
    <cve>CVE-2021-44228</cve>
  </suppress>

  <!-- Suppress all CVEs for a dependency -->
  <suppress>
    <notes>Accepted risk</notes>
    <filePath regex="true">.*old-library-.*\.jar</filePath>
  </suppress>

  <!-- Suppress with expiration -->
  <suppress>
    <notes>Review in 6 months</notes>
    <filePath regex="true">.*problematic-.*\.jar</filePath>
    <cve>CVE-2024-XXXXX</cve>
    <expires>2025-06-01</expires>
  </suppress>
</suppressions>
```

### Custom CVSS Thresholds

```bash
# Fail on high (7.0+)
dependency-check --failBuildOnCVSS 7

# Fail on medium (4.0+)
dependency-check --failBuildOnCVSS 4

# Report only (never fail)
dependency-check --failBuildOnCVSS 10
```

### Custom Report Formats

```bash
# Multiple formats
dependency-check \
  --format HTML \
  --format JSON \
  --format SARIF \
  --format CSV \
  --format JUNIT \
  --format MARKDOWN

# Custom report name
dependency-check \
  --format HTML \
  --reportOutputFile custom-report.html
```

### RetireJS Integration

```bash
# Enable RetireJS for JavaScript
dependency-check \
  --enableRetireJS \
  --retireJsUrl https://js-retire.s3.amazonaws.com/retire.js

# Disable RetireJS
dependency-check \
  --disableRetireJS
```

---

## Security Features

### Vulnerability Detection

OWASP Dependency Check detects:
- **Known vulnerabilities**: Mapped to specific CVEs.
- **Outdated dependencies**: When newer versions are available.
- **License violations**: Detects problematic licenses.
- **Malicious packages**: RetireJS detection for known malicious packages.

### License Compliance

```bash
# Generate license report
dependency-check \
  --format HTML \
  --nvdApiKey $NVD_API_KEY

# Report includes license information for each dependency
```

### SARIF Integration

```bash
# Generate SARIF for GitHub Code Scanning
dependency-check \
  --format SARIF \
  --out ./report/dependency-check.sarif

# Upload to GitHub
# In GitHub Actions:
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: ./report/dependency-check.sarif
```

### NVD API Key

Using an NVD API key provides:
- Higher rate limits (5000 requests/hour vs 50 requests/hour).
- Faster database updates.
- More reliable vulnerability data.

```bash
# Set API key
export NVD_API_KEY=your-api-key

# Use in scan
dependency-check --nvdApiKey $NVD_API_KEY
```

---

## GitHub Actions Integration

### Basic GitHub Action

```yaml
name: OWASP Dependency Check
on: [push, pull_request]

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          path: './src'
          format: 'HTML'
          args: '--failBuildOnCVSS 7'

      - name: Upload Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: dependency-check-report
          path: reports/
```

### Advanced GitHub Action with SARIF

```yaml
name: OWASP Dependency Check
on: [push, pull_request]

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          path: '.'
          format: 'HTML SARIF JSON'
          args: '--failBuildOnCVSS 7 --nvdApiKey ${{ secrets.NVD_API_KEY }}'

      - name: Upload SARIF to GitHub
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: reports/dependency-check-report.sarif

      - name: Upload HTML Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: dependency-check-report
          path: reports/dependency-check-report.html
```

### Scheduled Scan

```yaml
name: Weekly Dependency Check
on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          path: '.'
          format: 'HTML JSON'
          args: '--failBuildOnCVSS 7 --nvdApiKey ${{ secrets.NVD_API_KEY }}'

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: dependency-check-report
          path: reports/
```

---

## GitLab CI Integration

### Basic GitLab CI

```yaml
stages:
  - security

dependency-check:
  stage: security
  image: owasp/dependency-check
  script:
    - dependency-check
        --project "$CI_PROJECT_NAME"
        --scan .
        --out ./report
        --format HTML
        --format JSON
        --format SARIF
        --failBuildOnCVSS 7
  artifacts:
    when: always
    paths:
      - report/
    reports:
      dependency_scanning: report/dependency-check-report.json
```

### Advanced GitLab CI with NVD API Key

```yaml
stages:
  - security

dependency-check:
  stage: security
  image: owasp/dependency-check
  variables:
    NVD_API_KEY: $NVD_API_KEY
  script:
    - dependency-check
        --project "$CI_PROJECT_NAME"
        --scan .
        --out ./report
        --format HTML
        --format JSON
        --format SARIF
        --failBuildOnCVSS 7
        --nvdApiKey $NVD_API_KEY
  artifacts:
    when: always
    paths:
      - report/
    reports:
      dependency_scanning: report/dependency-check-report.json
  only:
    - merge_requests
    - main
```

### GitLab Security Dashboard Integration

```yaml
dependency-check:
  stage: security
  image: owasp/dependency-check
  script:
    - dependency-check
        --project "$CI_PROJECT_NAME"
        --scan .
        --out ./report
        --format JSON
        --format SARIF
  artifacts:
    reports:
      dependency_scanning: report/dependency-check-report.json
```

---

## Advanced Configuration

### Monorepo Scanning

```bash
# Scan multiple directories
dependency-check \
  --scan ./frontend \
  --scan ./backend \
  --scan ./shared \
  --out ./report \
  --format HTML

# Scan with different settings per directory
dependency-check \
  --scan ./frontend --project "Frontend" \
  --scan ./backend --project "Backend" \
  --out ./report \
  --format HTML
```

### Custom Analyzers

```bash
# Enable specific analyzers
dependency-check \
  --enableAssemblyAnalyzer \
  --enableNexusAnalyzer \
  --enableCentralAnalyzer \
  --enableRetireJS \
  --scan . \
  --out ./report

# Disable specific analyzers
dependency-check \
  --disableAssemblyAnalyzer \
  --disableNexusAnalyzer \
  --scan . \
  --out ./report
```

### Proxy Configuration

```bash
# Set proxy
dependency-check \
  --proxy http://proxy:8080 \
  --proxyUser proxyuser \
  --proxyPassword proxypass \
  --scan . \
  --out ./report

# Or via environment
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
dependency-check --scan . --out ./report
```

### NVD API Configuration

```bash
# Set API key
export NVD_API_KEY=your-api-key

# Configure rate limiting
dependency-check \
  --nvdApiKey $NVD_API_KEY \
  --nvdApiDelay 5000 \
  --nvdApiBatchSize 200 \
  --scan . \
  --out ./report
```

### Custom Data Directory

```bash
# Use custom data directory
dependency-check \
  --data /path/to/data \
  --scan . \
  --out ./report

# Update database only
dependency-check \
  --data /path/to/data \
  --updateonly
```

### Thread Configuration

```bash
# Set thread count
dependency-check \
  --threadCount 8 \
  --scan . \
  --out ./report
```

---

## Troubleshooting

### 1. Database Download Fails

**Symptom**: `dependency-check --updateonly` fails.

**Fix**:
```bash
# Check network connectivity
curl -I https://nvd.nist.gov

# Use proxy
dependency-check --proxy http://proxy:8080 --updateonly

# Use NVD API key for higher rate limits
export NVD_API_KEY=your-key
dependency-check --updateonly

# Check data directory permissions
ls -la ~/.dependency-check/data
```

### 2. False Positives

**Symptom**: Vulnerabilities reported for code you don't use.

**Fix**: Create suppression file:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <suppress>
    <notes>Not reachable from our codebase</notes>
    <filePath regex="true">.*log4j-.*\.jar</filePath>
    <cve>CVE-2021-44228</cve>
  </suppress>
</suppressions>
```

### 3. Build Fails on CVSS Score

**Symptom**: CI pipeline fails due to vulnerability score.

**Fix**:
```bash
# Raise threshold
dependency-check --failBuildOnCVSS 10  # Never fail

# Or lower threshold
dependency-check --failBuildOnCVSS 7  # Fail on High+

# Or use suppression file
dependency-check --suppressionFile suppressions.xml
```

### 4. Scan Takes Too Long

**Symptom**: Dependency check scan is slow.

**Fix**:
```bash
# Increase threads
dependency-check --threadCount 8

# Update database incrementally
dependency-check --updateonly

# Scan specific directories
dependency-check --scan ./src --scan ./lib
```

### 5. Cannot Find Dependencies

**Symptom**: `No dependencies found`.

**Fix**:
```bash
# Scan correct directory
dependency-check --scan ./src --scan ./lib

# Enable all analyzers
dependency-check --enableAssemblyAnalyzer --enableCentralAnalyzer

# Check if dependencies exist
find . -name "*.jar" -o -name "pom.xml" -o -name "package.json"
```

### 6. SARIF Upload Fails

**Symptom**: GitHub Code Scanning doesn't show results.

**Fix**:
```yaml
# Generate SARIF correctly
dependency-check \
  --format SARIF \
  --out ./report/dependency-check.sarif

# Upload SARIF
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: ./report/dependency-check.sarif
```

### 7. NVD Rate Limiting

**Symptom**: `Rate limit exceeded` error.

**Fix**:
```bash
# Use NVD API key
export NVD_API_KEY=your-key
dependency-check --updateonly

# Reduce batch size
dependency-check --nvdApiBatchSize 50 --nvdApiDelay 10000
```

### 8. Memory Issues

**Symptom**: `OutOfMemoryError` during scan.

**Fix**:
```bash
# Increase heap size
export JAVA_OPTS="-Xmx4g"
dependency-check --scan . --out ./report

# Or
java -Xmx4g -jar dependency-check.jar --scan . --out ./report
```

### 9. License Detection Issues

**Symptom**: Licenses not detected correctly.

**Fix**:
```bash
# Enable license analyzer
dependency-check --enableLicenseAnalyzer --scan . --out ./report

# Check license in specific dependency
jq '.dependencies[] | select(.licenses | length > 0)' report.json
```

### 10. Node.js Dependencies Not Found

**Symptom**: npm packages not detected.

**Fix**:
```bash
# Ensure node_modules exists
npm install

# Scan specific directory
dependency-check --scan ./node_modules --out ./report

# Enable RetireJS
dependency-check --enableRetireJS --scan . --out ./report
```

### 11. Java Dependencies Not Found

**Symptom**: Maven dependencies not detected.

**Fix**:
```bash
# Build project first
mvn dependency:resolve

# Scan target directory
dependency-check --scan ./target --out ./report

# Use Maven plugin
mvn org.owasp:dependency-check-maven:check
```

### 12. Python Dependencies Not Found

**Symptom**: pip packages not detected.

**Fix**:
```bash
# Freeze requirements
pip freeze > requirements.txt

# Scan requirements.txt
dependency-check --scan ./requirements.txt --out ./report

# Ensure virtual environment is activated
source venv/bin/activate
dependency-check --scan . --out ./report
```

### 13. Docker Build Fails

**Symptom**: Docker image build fails with dependency check.

**Fix**:
```dockerfile
FROM owasp/dependency-check:latest AS dc
COPY . /src
RUN dependency-check --project "My App" --scan /src --out /report --format HTML

FROM alpine:latest
COPY --from=dc /report /report
```

### 14. Report Not Generating

**Symptom**: No report file created.

**Fix**:
```bash
# Ensure output directory exists
mkdir -p ./report

# Check write permissions
ls -la ./report

# Use absolute path
dependency-check --scan /path/to/project --out /path/to/report --format HTML
```

### 15. Gradle Plugin Issues

**Symptom**: Gradle plugin not finding dependencies.

**Fix**:
```groovy
// build.gradle
plugins {
  id 'org.owasp.dependencycheck' version '9.0.9'
}

dependencyCheck {
  failBuildOnCVSS = 7
  formats = ['HTML', 'JSON', 'SARIF']
  suppressionFile = 'suppressions.xml'
}

// Run
./gradlew dependencyCheckAnalyze
```

---

## Tips and Best Practices

### 1. Use NVD API Key

Register for a free NVD API key at https://nvd.nist.gov/developers/request-an-api-key. This provides 5000 requests/hour (vs 50 without a key).

### 2. Schedule Regular Scans

Run scans weekly to catch new vulnerabilities:
```yaml
on:
  schedule:
    - cron: '0 6 * * 1'
```

### 3. Integrate with CI/CD

Add dependency check to your pipeline:
```yaml
- name: Dependency Check
  uses: dependency-check/Dependency-Check_Action@main
  with:
    path: './src'
    format: 'HTML'
    args: '--failBuildOnCVSS 7'
```

### 4. Use Suppression Files

Create a suppression file for false positives:
```xml
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.3.xsd">
  <suppress>
    <notes>False positive</notes>
    <filePath regex="true">.*log4j-.*\.jar</filePath>
    <cve>CVE-2021-44228</cve>
  </suppress>
</suppressions>
```

### 5. Monitor Database Age

Keep the NVD database fresh:
```bash
# Update database
dependency-check --updateonly

# Check database age
dependency-check --info
```

### 6. Use SARIF for GitHub Code Scanning

Generate SARIF output for unified security reporting:
```bash
dependency-check --format SARIF --out ./report/dependency-check.sarif
```

### 7. Set Appropriate CVSS Threshold

```bash
# Fail on high (default)
dependency-check --failBuildOnCVSS 7

# Fail on medium
dependency-check --failBuildOnCVSS 4

# Report only
dependency-check --failBuildOnCVSS 10
```

### 8. Use Multiple Report Formats

```bash
dependency-check \
  --format HTML \    # Human-readable
  --format JSON \    # Programmatic analysis
  --format SARIF \   # GitHub integration
  --format CSV        # Spreadsheet analysis
```

### 9. Scan Monorepos

```bash
dependency-check \
  --scan ./frontend \
  --scan ./backend \
  --scan ./shared \
  --out ./report \
  --format HTML
```

### 10. Cache the Database

```bash
# Use a shared cache directory
docker run -v ~/.dependency-check/data:/data owasp/dependency-check \
  --data /data \
  --scan /src \
  --out /report
```

### 11. Review Reports Regularly

Don't just check for failures. Review reports for:
- New vulnerabilities in dependencies.
- License changes.
- Outdated dependencies.

### 12. Combine with Other Tools

Use OWASP Dependency Check alongside:
- Snyk (for developer-first experience).
- Trivy (for container scanning).
- Semgrep (for SAST).
- tfsec (for IaC security).

### 13. Document Suppressions

Add notes to suppression files explaining why each vulnerability is suppressed:
```xml
<suppress>
  <notes>Not reachable from our codebase. Log4j is only used in test code.</notes>
  <filePath regex="true">.*log4j-.*\.jar</filePath>
  <cve>CVE-2021-44228</cve>
</suppress>
```

### 14. Use Thread Count for Performance

```bash
# Use multiple threads
dependency-check --threadCount 8 --scan . --out ./report
```

### 15. Monitor Vulnerability Trends

Track vulnerability counts over time:
```bash
# Count vulnerabilities
jq '[.dependencies[].vulnerabilities[]] | length' report.json

# Count by severity
jq '[.dependencies[].vulnerabilities[].cvssScore] | group_by(floor) | map({(.[0] | tostring): length}) | add' report.json
```

### 16. Use Gradle/Maven Plugins

For Java projects, use build plugins:
```xml
<!-- Maven -->
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
</plugin>
```

```groovy
// Gradle
plugins {
  id 'org.owasp.dependencycheck'
}
```

---

## Command Reference

### Core Commands

```bash
# Scan project
dependency-check \
  --project "Project Name" \
  --scan /path/to/project \
  --out /path/to/report \
  --format HTML

# Update database
dependency-check --updateonly

# Check database info
dependency-check --info

# Purge old data
dependency-check --purge

# Version
dependency-check --version
```

### Scan Options

```bash
--project "Name"          # Project name
--scan /path              # Directory to scan
--out /path               # Output directory
--format HTML             # Report format (HTML, JSON, SARIF, CSV, JUNIT, XML, MARKDOWN)
--failBuildOnCVSS 7       # CVSS threshold for build failure
--suppressionFile file.xml # Suppression file
--nvdApiKey KEY           # NVD API key
--threadCount 8           # Number of threads
--data /path              # Data directory
```

### Analyzer Options

```bash
--enableAssemblyAnalyzer     # Enable .NET assembly analyzer
--disableAssemblyAnalyzer    # Disable .NET assembly analyzer
--enableCentralAnalyzer      # Enable Maven Central analyzer
--disableCentralAnalyzer     # Disable Maven Central analyzer
--enableRetireJS             # Enable RetireJS for JavaScript
--disableRetireJS            # Disable RetireJS
--enableNexusAnalyzer        # Enable Nexus repository analyzer
--disableNexusAnalyzer       # Disable Nexus analyzer
--enableLicenseAnalyzer      # Enable license detection
--disableLicenseAnalyzer     # Disable license detection
```

### Network Options

```bash
--proxy http://proxy:8080   # HTTP proxy
--proxyUser user            # Proxy username
--proxyPassword pass        # Proxy password
--connectionTimeout 30000   # Connection timeout (ms)
--nvdApiDelay 5000          # Delay between NVD requests (ms)
--nvdApiBatchSize 200       # Batch size for NVD requests
```

### Database Options

```bash
--updateonly                # Only update database
--purge                     # Purge old data
--noupdate                  # Don't update database
--data /path                # Data directory
```

### Report Options

```bash
--format HTML               # Report format
--reportOutputFile file     # Custom report filename
--showEcosystem             # Show ecosystem in report
--prettyPrint               # Pretty-print JSON
```

### Debug Options

```bash
--verbose                   # Verbose output
--debug                     # Debug output
--experimental               # Enable experimental features
--help                      # Show help
--version                   # Show version
```

---

## Real-World Examples

### Example 1: Java Maven Project

```bash
# Build and scan
mvn clean package
dependency-check \
  --project "My Java App" \
  --scan ./target \
  --out ./report \
  --format HTML \
  --format JSON \
  --failBuildOnCVSS 7

# Or use Maven plugin
mvn org.owasp:dependency-check-maven:check
```

### Example 2: Node.js Project

```bash
# Install dependencies
npm install

# Scan
dependency-check \
  --project "My Node App" \
  --scan ./node_modules \
  --scan ./src \
  --out ./report \
  --format HTML \
  --enableRetireJS \
  --failBuildOnCVSS 7
```

### Example 3: Python Project

```bash
# Install dependencies
pip install -r requirements.txt

# Scan
dependency-check \
  --project "My Python App" \
  --scan . \
  --out ./report \
  --format HTML \
  --failBuildOnCVSS 7
```

### Example 4: Monorepo

```bash
# Scan all projects
dependency-check \
  --project "Monorepo" \
  --scan ./frontend \
  --scan ./backend \
  --scan ./shared \
  --out ./report \
  --format HTML \
  --format JSON
```

### Example 5: CI/CD Pipeline (GitHub Actions)

```yaml
name: OWASP Dependency Check
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build
        run: mvn clean package -DskipTests

      - name: Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          path: './target'
          format: 'HTML SARIF JSON'
          args: '--failBuildOnCVSS 7 --nvdApiKey ${{ secrets.NVD_API_KEY }}'

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: reports/dependency-check-report.sarif

      - name: Upload Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: dependency-check-report
          path: reports/
```

### Example 6: Docker Image

```yaml
name: OWASP Dependency Check
on: push

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Scan Docker image
        run: |
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v $(pwd)/report:/report \
            owasp/dependency-check \
            --project "My App" \
            --scan /var/run/docker.sock \
            --out /report \
            --format HTML
```

### Example 7: Scheduled Weekly Scan

```yaml
name: Weekly Dependency Check
on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          path: '.'
          format: 'HTML JSON'
          args: '--failBuildOnCVSS 7 --nvdApiKey ${{ secrets.NVD_API_KEY }}'

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: dependency-check-report
          path: reports/
```

---

## Further Reading

- [OWASP Dependency Check Official Documentation](https://jeremylong.github.io/DependencyCheck/)
- [OWASP Dependency Check GitHub](https://github.com/jeremylong/DependencyCheck)
- [OWASP Dependency Check Maven Plugin](https://jeremylong.github.io/DependencyCheck/dependency-check-maven/)
- [OWASP Dependency Check Gradle Plugin](https://jeremylong.github.io/DependencyCheck/dependency-check-gradle/)
- [NVD API Documentation](https://nvd.nist.gov/developers)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP SCA Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [NIST National Vulnerability Database](https://nvd.nist.gov/)
- [CPE Dictionary](https://nvd.nist.gov/products/cpe)
