# OSV-Scanner Complete Guide

## Table of Contents

1. [What Is OSV-Scanner](#what-is-osv-scanner)
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

## What Is OSV-Scanner

OSV-Scanner is a vulnerability scanner powered by the [Open Source Vulnerabilities (OSV)](https://osv.dev/) database. Created by Google, it provides an accurate, low-noise vulnerability scanning experience for open-source dependencies. OSV-Scanner is the official scanning tool for the OSV database and is designed to be fast, accurate, and easy to use.

### Key Features

- **Low false positives**: Uses lockfile-based scanning for precise dependency identification.
- **Fast scanning**: No database download required; queries the OSV API directly.
- **Multi-ecosystem**: Supports 16+ ecosystems including npm, PyPI, Go, Maven, crates.io, and more.
- **Monorepo support**: Scans multiple projects in a single run.
- **Call graph analysis**: Identifies actually reachable vulnerable code paths.
- **Offline support**: Can cache the database for offline scanning.
- **SARIF output**: Integrates with GitHub Code Scanning.

### How OSV-Scanner Works

1. **Discovery**: Scans the project for dependency files (lockfiles, manifests).
2. **Extraction**: Extracts package names and versions from lockfiles.
3. **Querying**: Queries the OSV database for known vulnerabilities.
4. **Matching**: Matches vulnerabilities against your specific dependency versions.
5. **Reporting**: Generates reports in various formats (text, JSON, SARIF).

### OSV Database

The OSV database is a collaborative, open-source vulnerability database that:
- Aggregates data from NVD, GitHub Advisories, and ecosystem-specific advisories.
- Provides precise affected version ranges.
- Is maintained by Google and the open-source community.
- Is freely accessible via API and web interface (https://osv.dev/).

### Relationship to Other Tools

| Feature | OSV-Scanner | OWASP DC | Snyk | Dependabot | Renovate |
|---------|-------------|----------|------|------------|----------|
| Database | OSV | NVD | Snyk DB | GitHub Advisory | GitHub Advisory |
| Cost | Free | Free | Freemium | Free | Free |
| Lockfile scanning | Yes | Limited | Yes | N/A | N/A |
| Call graph | Yes | No | Yes | No | No |
| False positives | Very low | Medium | Low | Low | Low |
| Speed | Very fast | Slow | Fast | Fast | Fast |
| Self-hosted | Yes | Yes | No (CLI) | No | Yes |

---

## Why Use It

### Accuracy

OSV-Scanner's lockfile-based scanning eliminates most false positives:
- **Lockfiles** contain exact versions of all dependencies (direct + transitive).
- **No guesswork**: The scanner knows exactly what versions are installed.
- **Precise matching**: Vulnerabilities are matched against exact package:version pairs.

Compare this to manifest-only scanning (which reads package.json but not package-lock.json), where transitive dependency versions are unknown and false positives are common.

### Speed

OSV-Scanner queries the OSV API directly, with no local database required:
- **No download**: No need to download a multi-GB NVD database.
- **No indexing**: No need to build or maintain a local index.
- **Caching**: Optional local cache for faster subsequent scans and offline use.
- **Parallel queries**: Queries multiple ecosystems in parallel.

### Low False Positives

OSV-Scanner's matching algorithm:
1. Extracts exact dependency versions from lockfiles.
2. Queries OSV for vulnerabilities affecting those exact versions.
3. Filters out vulnerabilities that don't apply to your configuration.
4. Reports only confirmed, applicable vulnerabilities.

### Call Graph Analysis

OSV-Scanner can trace code paths to determine if a vulnerable dependency is actually used:
- Identifies if the vulnerable function is reachable.
- Reduces noise from dependencies that are installed but not called.
- Provides confidence scores for vulnerability applicability.

### Open Source

OSV-Scanner is fully open-source (Apache 2.0):
- No vendor lock-in.
- Community-driven development.
- Transparent matching algorithms.
- Customizable and extensible.

### Google-Backed

Backed by Google's security team:
- Integrates with Google's vulnerability research.
- Used internally at Google.
- Maintained by experienced security engineers.

---

## Real-World Breaches

### Log4Shell (CVE-2021-44228)

**Context**: Critical RCE in Apache Log4j2.

**OSV-Scanner detection**: After the CVE was added to OSV, osv-scanner immediately flagged vulnerable Log4j versions in Java projects. The lockfile-based scanning precisely identified affected transitive dependencies.

### Spring4Shell (CVE-2022-22965)

**Context**: RCE in Spring Framework.

**OSV-Scanner detection**: osv-scanner detected vulnerable Spring Framework versions in Maven and Gradle projects by scanning lockfiles and matching against OSV entries.

### Prototype Pollution in Lodash (CVE-2020-28500)

**Context**: High-severity prototype pollution in a widely-used utility library.

**OSV-Scanner detection**: osv-scanner precisely identified vulnerable lodash versions in npm projects, even when lodash appeared as a transitive dependency through multiple paths.

### Regular Expression Denial of Service in ua-parser-js (CVE-2021-27292)

**Context**: ReDoS vulnerability affecting millions of web applications.

**OSV-Scanner detection**: osv-scanner detected the vulnerable version across npm and identified the exact path through which it was installed.

### JSON Parser Vulnerability in Jackson Databind (CVE-2019-12384)

**Context**: Deserialization vulnerability in a popular Java JSON library.

**OSV-Scanner detection**: osv-scanner identified vulnerable Jackson versions in Maven projects, even when the vulnerable classes were not directly used.

---

## Supported Ecosystems

OSV-Scanner supports 16+ ecosystems:

| Ecosystem | Lockfile / Manifest | Detection |
|-----------|-------------------|-----------|
| **npm** | package-lock.json, yarn.lock, pnpm-lock.yaml | Exact versions from lockfile |
| **PyPI** | requirements.txt, Pipfile.lock, poetry.lock | Exact versions from lockfile |
| **Go** | go.sum | Module versions from checksum database |
| **Maven** | pom.xml, build.gradle, build.gradle.kts | Dependency versions from build files |
| **crates.io** | Cargo.lock | Crate versions from lockfile |
| **RubyGems** | Gemfile.lock | Gem versions from lockfile |
| **Packagist** | composer.lock | Package versions from lockfile |
| **NuGet** | packages.lock.json, packages.config | Package versions from lockfile |
| **CocoaPods** | Podfile.lock | Pod versions from lockfile |
| **Pub** | pubspec.lock | Package versions from lockfile |
| **Hex** | mix.lock | Package versions from lockfile |
| **Conan** | conanfile.txt, conanfile.py | Package versions from build file |
| **Bitbucket Pipelines** | bitbucket-pipelines.yml | Image versions |
| **Docker** | Dockerfile | Image versions |
| **Alpine** | /etc/apk/world | OS packages |
| **Debian** | dpkg status | OS packages |

---

## Installation

### Option 1: Go Install

```bash
go install github.com/google/osv-scanner/cmd/osv-scanner@latest
```

### Option 2: Standalone Binary

```bash
# Linux (amd64)
curl -L https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64 -o osv-scanner
chmod +x osv-scanner
sudo mv osv-scanner /usr/local/bin/

# macOS (arm64)
curl -L https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_darwin_arm64 -o osv-scanner
chmod +x osv-scanner
sudo mv osv-scanner /usr/local/bin/

# Windows
curl -L https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_windows_amd64.exe -o osv-scanner.exe
```

### Option 3: Homebrew

```bash
brew install osv-scanner
```

### Option 4: Docker

```bash
# Scan current directory
docker run --rm -v $(pwd):/src ghcr.io/google/osv-scanner scan /src

# Scan specific file
docker run --rm -v $(pwd):/src ghcr.io/google/osv-scanner scan -r /src/package-lock.json
```

### Option 5: Binary Release

Download from https://github.com/google/osv-scanner/releases and add to PATH.

### Verify Installation

```bash
osv-scanner --version
```

---

## Configuration Reference

### Command-Line Options

```bash
# Basic scan
osv-scanner scan /path/to/project

# Scan with JSON output
osv-scanner scan --format json /path/to/project

# Scan with SARIF output
osv-scanner scan --format sarif /path/to/project

# Scan specific file
osv-scanner scan -r /path/to/package-lock.json

# Scan all projects
osv-scanner scan -r /path/to/project

# Offline mode (use cached database)
osv-scanner scan --offline /path/to/project

# Verbose output
osv-scanner scan --verbose /path/to/project

# Output to file
osv-scanner scan --output results.json /path/to/project
```

### Configuration File (.osv-scanner.toml)

```toml
# Global settings
[global]
# Offline mode (use cached database)
offline = false

# Output format
format = "json"

# Verbosity
verbose = false

# Output file
output = "results.json"

# Ignore specific vulnerabilities
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"

[[ignore]]
id = "CVE-2021-44228"
reason = "Log4j not used in production code"

# Ignore specific packages
[[ignore]]
package = "lodash"
version = "4.17.21"
reason = "Using patched version"

# Ignore vulnerabilities in specific paths
[[ignore]]
id = "CVE-2021-29425"
path = "test/.*"
reason = "Only used in test files"

# Call graph analysis
[call_graph]
# Enable call graph analysis
enabled = true

# Include transitive dependencies
include_transitive = true

# Cache settings
[cache]
# Enable caching
enabled = true

# Cache directory
directory = "~/.osv-scanner/cache"

# Cache TTL (in seconds)
ttl = 86400
```

### Environment Variables

```bash
# Offline mode
export OSV_SCANNER_OFFLINE=true

# Cache directory
export OSV_SCANNER_CACHE_DIR=~/.osv-scanner/cache

# API endpoint
export OSV_SCANNER_API_ENDPOINT=https://api.osv.dev/v1

# Verbose output
export OSV_SCANNER_VERBOSE=true
```

### CLI Configuration

```bash
# Scan with all options
osv-scanner scan \
  --format json \
  --output results.json \
  --verbose \
  --config .osv-scanner.toml \
  /path/to/project

# Scan with specific ignore file
osv-scanner scan \
  --config ignore-rules.toml \
  /path/to/project

# Scan with call graph analysis
osv-scanner scan \
  --call-graph \
  /path/to/project
```

---

## Core Concepts

### Lockfile-Based Scanning

OSV-Scanner's primary strength is lockfile-based scanning:

- **Lockfiles** contain exact versions of all dependencies (direct + transitive).
- **No guessing**: The scanner knows exactly what versions are installed.
- **Precise matching**: Vulnerabilities are matched against exact package:version pairs.
- **Low false positives**: Eliminates most false positives from version range ambiguity.

Example lockfile entries:
```json
// package-lock.json
{
  "dependencies": {
    "lodash": {
      "version": "4.17.20",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.20.tgz"
    }
  }
}
```

### OSV Database

The OSV database is a collaborative vulnerability database:

- **Structured data**: Each vulnerability has a precise affected version range.
- **Ecosystem-specific**: Vulnerabilities are tagged with the affected ecosystem.
- **Collaborative**: Multiple sources contribute vulnerability data.
- **Open**: Freely accessible via API and web interface.

### Call Graph Analysis

Call graph analysis determines if vulnerable code is actually reachable:

1. **Build call graph**: Maps function calls from entry points.
2. **Trace paths**: Follows call chains to vulnerable functions.
3. **Report reachability**: Indicates if the vulnerable code is actually called.

This reduces false positives from dependencies that are installed but never called.

### Severity Scoring

OSV-Scanner uses CVSS scores from the OSV database:

| Score | Severity | Default Behavior |
|-------|----------|------------------|
| 0.0 | None | Report only |
| 0.1-3.9 | Low | Report only |
| 4.0-6.9 | Medium | Report only |
| 7.0-8.9 | High | Report (exit code 1) |
| 9.0-10.0 | Critical | Report (exit code 1) |

### Offline Mode

OSV-Scanner can cache the database for offline use:

```bash
# Cache the database
osv-scanner scan --update-cache /path/to/project

# Use cached database
osv-scanner scan --offline /path/to/project
```

---

## Step-by-Step Usage Guide

### Step 1: Install OSV-Scanner

```bash
# Using Go
go install github.com/google/osv-scanner/cmd/osv-scanner@latest

# Using Homebrew
brew install osv-scanner

# Verify
osv-scanner --version
```

### Step 2: Scan Your Project

```bash
# Scan current directory
osv-scanner scan .

# Scan with JSON output
osv-scanner scan --format json . > results.json

# Scan with SARIF output
osv-scanner scan --format sarif . > results.sarif

# Scan specific file
osv-scanner scan -r package-lock.json
```

### Step 3: Review Results

```bash
# View text output (default)
osv-scanner scan .

# Analyze JSON output
jq '.results[] | select(.vulnerabilities | length > 0)' results.json

# Count vulnerabilities
jq '[.results[].vulnerabilities[]] | length' results.json

# View by severity
jq '.results[].vulnerabilities[] | {id: .id, severity: .database_specific.severity}' results.json
```

### Step 4: Address Vulnerabilities

```bash
# Check for fixes
jq '.results[].vulnerabilities[] | {id: .id, affected: .affected[] | .versions}' results.json

# Update vulnerable dependencies
npm update lodash  # For npm
pip install --upgrade lodash  # For pip
```

### Step 5: Set Up Ignore Rules

```bash
# Create ignore file
cat > .osv-scanner.toml << 'EOF'
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"
EOF

# Use ignore file
osv-scanner scan --config .osv-scanner.toml .
```

### Step 6: Integrate with CI/CD

```yaml
# GitHub Actions
- name: Run OSV-Scanner
  uses: google/osv-scanner/actions/osv-scanner@v1
  with:
    scan-args: --format sarif --output results.sarif ./

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

### Step 7: Enable Call Graph Analysis

```bash
# Scan with call graph analysis
osv-scanner scan --call-graph .

# This identifies if vulnerable code is actually reachable
```

### Step 8: Set Up Caching

```bash
# Enable caching
osv-scanner scan --cache-dir ~/.osv-scanner/cache .

# Offline mode
osv-scanner scan --offline .
```

### Step 9: Generate Reports

```bash
# HTML report (via SARIF conversion)
osv-scanner scan --format sarif . | sarif-to-html > report.html

# JSON report
osv-scanner scan --format json . > results.json

# SARIF report
osv-scanner scan --format sarif . > results.sarif
```

### Step 10: Continuous Monitoring

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

### Ignore Rules

Create `.osv-scanner.toml` to define ignore rules:

```toml
# Ignore specific vulnerability
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"

# Ignore specific package version
[[ignore]]
package = "lodash"
version = "4.17.21"
reason = "Using patched version"

# Ignore vulnerabilities in specific paths
[[ignore]]
id = "CVE-2021-29425"
path = "test/.*"
reason = "Only used in test files"

# Ignore all vulnerabilities for a package
[[ignore]]
package = "old-package"
reason = "Deprecated, not used in production"

# Ignore with expiration
[[ignore]]
id = "CVE-2024-XXXXX"
reason = "Review in 6 months"
expires = "2025-06-01"
```

### Severity Thresholds

```bash
# Report only high and critical
osv-scanner scan --severity high .

# Report all (default)
osv-scanner scan --severity all .

# Fail on high
osv-scanner scan --fail-on high .
```

### Custom Report Formats

```bash
# JSON output
osv-scanner scan --format json .

# SARIF output
osv-scanner scan --format sarif .

# Text output (default)
osv-scanner scan --format text .

# Custom output file
osv-scanner scan --format json --output results.json .
```

### Call Graph Rules

```toml
# Enable call graph analysis
[call_graph]
enabled = true

# Include transitive dependencies
include_transitive = true

# Entry points
entry_points = ["main", "index", "app"]
```

---

## Security Features

### Vulnerability Detection

OSV-Scanner detects:
- **Known vulnerabilities**: Mapped to specific CVEs and GHSA IDs.
- **Affected version ranges**: Precise identification of vulnerable versions.
- **Fix availability**: Indicates if a patched version exists.
- **Reachability**: Whether the vulnerable code is actually used (with call graph).

### Call Graph Analysis

```bash
# Enable call graph analysis
osv-scanner scan --call-graph .

# This determines if vulnerable code is actually reachable
```

### Offline Scanning

```bash
# Cache the database
osv-scanner scan --update-cache .

# Scan offline
osv-scanner scan --offline .
```

### SARIF Integration

```bash
# Generate SARIF for GitHub Code Scanning
osv-scanner scan --format sarif . > results.sarif

# Upload to GitHub
# In GitHub Actions:
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

### License Detection

```bash
# Check licenses
osv-scanner scan --format json . | jq '.results[].packages[] | {name, version, license}'
```

---

## GitHub Actions Integration

### Basic GitHub Action

```yaml
name: OSV-Scanner
on: [push, pull_request]

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run OSV-Scanner
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format sarif --output results.sarif ./

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

### Advanced GitHub Action with Multiple Formats

```yaml
name: OSV-Scanner
on: [push, pull_request]

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run OSV-Scanner
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: >-
            --format sarif
            --output results.sarif
            ./

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif

      - name: Upload Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: osv-scanner-report
          path: results.sarif
```

### Scheduled Scan

```yaml
name: Weekly OSV Scan
on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run OSV-Scanner
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format json --output results.json ./

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: osv-scanner-report
          path: results.json
```

### Monorepo Scan

```yaml
name: OSV-Scanner Monorepo
on: [push, pull_request]

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Scan Frontend
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format sarif --output frontend.sarif ./frontend

      - name: Scan Backend
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format sarif --output backend.sarif ./backend

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: frontend.sarif
```

---

## GitLab CI Integration

### Basic GitLab CI

```yaml
stages:
  - security

osv-scan:
  stage: security
  image: ghcr.io/google/osv-scanner
  script:
    - osv-scanner scan --format json --output results.json ./
    - osv-scanner scan --format sarif --output results.sarif ./
  artifacts:
    when: always
    paths:
      - results.json
      - results.sarif
    reports:
      dependency_scanning: results.json
  only:
    - merge_requests
    - main
```

### Advanced GitLab CI

```yaml
stages:
  - security

osv-scan:
  stage: security
  image: ghcr.io/google/osv-scanner
  script:
    - osv-scanner scan
        --format json
        --output results.json
        ./
  artifacts:
    when: always
    paths:
      - results.json
    reports:
      dependency_scanning: results.json
  allow_failure: true
```

### GitLab Security Dashboard Integration

```yaml
osv-scan:
  stage: security
  image: ghcr.io/google/osv-scanner
  script:
    - osv-scanner scan --format json --output results.json ./
  artifacts:
    reports:
      dependency_scanning: results.json
```

---

## Advanced Configuration

### Monorepo Scanning

```bash
# Scan multiple directories
osv-scanner scan ./frontend ./backend ./shared

# Scan with different configs per directory
osv-scanner scan --config frontend-config.toml ./frontend
osv-scanner scan --config backend-config.toml ./backend
```

### Offline Mode

```bash
# Update cache
osv-scanner scan --update-cache .

# Scan offline
osv-scanner scan --offline .
```

### Call Graph Analysis

```bash
# Enable call graph analysis
osv-scanner scan --call-graph .

# This determines if vulnerable code is actually reachable
# Reduces false positives from unused dependencies
```

### Custom API Endpoint

```bash
# Use custom OSV API endpoint
osv-scanner scan --api-endpoint https://custom-osv-api.example.com .

# Use local OSV database
osv-scanner scan --api-endpoint http://localhost:8080 .
```

### Output to File

```bash
# Save results to file
osv-scanner scan --format json --output results.json .

# Save multiple formats
osv-scanner scan --format json --output results.json \
  --format sarif --output results.sarif .
```

### Verbose Output

```bash
# Enable verbose output
osv-scanner scan --verbose .

# This shows detailed scanning information
```

### Ignore Rules

```toml
# .osv-scanner.toml
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"

[[ignore]]
package = "lodash"
version = "4.17.21"
reason = "Using patched version"

[[ignore]]
id = "CVE-2021-29425"
path = "test/.*"
reason = "Only used in test files"
```

### Cache Configuration

```toml
# Cache settings
[cache]
enabled = true
directory = "~/.osv-scanner/cache"
ttl = 86400  # 24 hours
```

---

## Troubleshooting

### 1. No Lockfile Found

**Symptom**: `No lockfile found in directory`.

**Fix**:
```bash
# Generate lockfile
npm install  # npm
pip install -r requirements.txt  # pip
bundle install  # Ruby
composer install  # PHP

# Or scan specific file
osv-scanner scan -r package-lock.json
```

### 2. OSV API Timeout

**Symptom**: `Request timeout` or `Connection refused`.

**Fix**:
```bash
# Check internet connection
curl -I https://api.osv.dev

# Use cached database
osv-scanner scan --offline .

# Increase timeout
osv-scanner scan --timeout 60 .
```

### 3. False Positives

**Symptom**: Vulnerabilities reported for code you don't use.

**Fix**:
```bash
# Use call graph analysis
osv-scanner scan --call-graph .

# Create ignore rules
cat > .osv-scanner.toml << 'EOF'
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"
EOF
```

### 4. SARIF Upload Fails

**Symptom**: GitHub Code Scanning doesn't show results.

**Fix**:
```yaml
# Generate SARIF correctly
osv-scanner scan --format sarif --output results.sarif ./

# Upload SARIF
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

### 5. Monorepo Scan Issues

**Symptom**: Only scanning one directory in monorepo.

**Fix**:
```bash
# Scan multiple directories
osv-scanner scan ./frontend ./backend ./shared

# Or scan all directories
osv-scanner scan .
```

### 6. Cache Issues

**Symptom**: Cache not working or outdated.

**Fix**:
```bash
# Update cache
osv-scanner scan --update-cache .

# Clear cache
rm -rf ~/.osv-scanner/cache

# Check cache location
ls -la ~/.osv-scanner/cache
```

### 7. Call Graph Analysis Fails

**Symptom**: Call graph analysis not working.

**Fix**:
```bash
# Ensure entry points are correct
osv-scanner scan --call-graph --entry-points main,index .

# Check language support
# Call graph analysis works best for: Go, Java, Python, JavaScript
```

### 8. Offline Mode Not Working

**Symptom**: Cannot scan offline.

**Fix**:
```bash
# Update cache first
osv-scanner scan --update-cache .

# Then scan offline
osv-scanner scan --offline .

# Check cache directory
ls -la ~/.osv-scanner/cache
```

### 9. JSON Output Issues

**Symptom**: JSON output not valid or missing fields.

**Fix**:
```bash
# Validate JSON
cat results.json | python -m json.tool

# Check specific fields
jq '.results[] | .vulnerabilities[] | .id' results.json
```

### 10. Version Mismatch

**Symptom**: Scanner reports wrong version.

**Fix**:
```bash
# Update osv-scanner
go install github.com/google/osv-scanner/cmd/osv-scanner@latest

# Check version
osv-scanner --version
```

### 11. Docker Scan Issues

**Symptom**: Cannot scan Docker images.

**Fix**:
```bash
# Scan Dockerfile
osv-scanner scan --format docker Dockerfile

# Scan built image
docker run --rm -v $(pwd):/src ghcr.io/google/osv-scanner scan /src
```

### 12. Large Project Timeout

**Symptom**: Scan times out on large projects.

**Fix**:
```bash
# Scan specific directories
osv-scanner scan ./src ./lib

# Use parallel scanning
osv-scanner scan --parallel 4 .

# Increase timeout
osv-scanner scan --timeout 300 .
```

### 13. License Detection Issues

**Symptom**: Licenses not detected correctly.

**Fix**:
```bash
# Check license information
osv-scanner scan --format json . | jq '.results[].packages[] | {name, version, license}'

# Some ecosystems don't provide license info in lockfiles
```

### 14. Ignore Rules Not Working

**Symptom**: Ignore rules not being applied.

**Fix**:
```bash
# Check ignore file syntax
cat .osv-scanner.toml

# Validate TOML
python -c "import tomli; tomli.load(open('.osv-scanner.toml', 'rb'))"

# Use correct ignore format
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "..."
```

### 15. Exit Code Issues

**Symptom**: Unexpected exit codes.

**Fix**:
```bash
# Check exit codes
osv-scanner scan . ; echo "Exit code: $?"

# Exit codes:
# 0 = No vulnerabilities found
# 1 = Vulnerabilities found
# 2 = Scanner error

# Always check exit code in CI
osv-scanner scan . || echo "Vulnerabilities found"
```

---

## Tips and Best Practices

### 1. Always Scan Lockfiles

Lockfiles provide exact dependency versions, eliminating false positives:

```bash
# Scan lockfile directly
osv-scanner scan -r package-lock.json

# Or scan directory (auto-detects lockfiles)
osv-scanner scan .
```

### 2. Use Call Graph Analysis

Enable call graph analysis to reduce false positives:

```bash
osv-scanner scan --call-graph .
```

### 3. Set Up Caching

Cache the database for faster subsequent scans:

```bash
# Enable caching
osv-scanner scan --cache-dir ~/.osv-scanner/cache .

# Use offline mode
osv-scanner scan --offline .
```

### 4. Integrate with CI/CD

Add OSV-Scanner to your CI pipeline:

```yaml
- name: OSV-Scanner
  uses: google/osv-scanner/actions/osv-scanner@v1
  with:
    scan-args: --format sarif --output results.sarif ./
```

### 5. Use Ignore Rules

Create ignore rules for false positives:

```toml
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"
```

### 6. Generate SARIF for GitHub

Use SARIF output for GitHub Code Scanning:

```bash
osv-scanner scan --format sarif . > results.sarif
```

### 7. Scan Monorepos

Scan multiple directories in a single run:

```bash
osv-scanner scan ./frontend ./backend ./shared
```

### 8. Use Verbose Output

Get detailed scanning information:

```bash
osv-scanner scan --verbose .
```

### 9. Combine with Other Tools

Use OSV-Scanner alongside:
- Snyk (for developer-first experience).
- OWASP DC (for NVD-based scanning).
- Trivy (for container scanning).

### 10. Monitor Vulnerability Trends

Track vulnerability counts over time:

```bash
# Count vulnerabilities
jq '[.results[].vulnerabilities[]] | length' results.json

# Count by severity
jq '[.results[].vulnerabilities[].database_specific.severity] | group_by(.) | map({(.[0]): length}) | add' results.json
```

### 11. Use Custom API Endpoint

For air-gapped environments:

```bash
# Use local OSV database
osv-scanner scan --api-endpoint http://localhost:8080 .
```

### 12. Generate Multiple Report Formats

```bash
# Generate multiple formats
osv-scanner scan --format json --output results.json \
  --format sarif --output results.sarif .
```

### 13. Set Up Scheduled Scans

Run scans weekly:

```yaml
on:
  schedule:
    - cron: '0 6 * * 1'
```

### 14. Review Results Regularly

Don't just check for failures. Review results for:
- New vulnerabilities.
- Outdated dependencies.
- License changes.

### 15. Use Ignore Rules with Expiration

```toml
[[ignore]]
id = "CVE-2024-XXXXX"
reason = "Review in 6 months"
expires = "2025-06-01"
```

### 16. Document Your Process

Add to your CONTRIBUTING.md:

```markdown
## Vulnerability Scanning

This project uses [OSV-Scanner](https://github.com/google/osv-scanner) for dependency vulnerability scanning.

- **CI**: OSV-Scanner runs on every PR and main branch push.
- **Reports**: SARIF results are uploaded to GitHub Code Scanning.
- **False positives**: Add ignore rules to `.osv-scanner.toml`.
- **Call graph**: Enabled for reduced false positives.
```

---

## Command Reference

### Core Commands

```bash
# Scan project
osv-scanner scan /path/to/project

# Scan specific file
osv-scanner scan -r /path/to/package-lock.json

# Scan with JSON output
osv-scanner scan --format json /path/to/project

# Scan with SARIF output
osv-scanner scan --format sarif /path/to/project

# Version
osv-scanner --version
```

### Scan Options

```bash
--format json             # Output format (json, sarif, text)
--output results.json     # Output file
--verbose                 # Verbose output
--config .osv-scanner.toml  # Configuration file
--call-graph              # Enable call graph analysis
--offline                 # Use cached database
--update-cache            # Update cache
--cache-dir ~/.cache      # Cache directory
--timeout 60              # Request timeout (seconds)
--api-endpoint URL        # Custom API endpoint
```

### Ignore Rules

```toml
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"

[[ignore]]
package = "lodash"
version = "4.17.21"
reason = "Using patched version"

[[ignore]]
id = "CVE-2021-29425"
path = "test/.*"
reason = "Only used in test files"
```

### Output Formats

```bash
# JSON (machine-readable)
osv-scanner scan --format json .

# SARIF (GitHub Code Scanning)
osv-scanner scan --format sarif .

# Text (human-readable, default)
osv-scanner scan --format text .
```

### Offline Mode

```bash
# Update cache
osv-scanner scan --update-cache .

# Scan offline
osv-scanner scan --offline .
```

### Call Graph Analysis

```bash
# Enable call graph analysis
osv-scanner scan --call-graph .

# This determines if vulnerable code is actually reachable
```

### API Options

```bash
# Custom API endpoint
osv-scanner scan --api-endpoint https://custom-api.example.com .

# Custom timeout
osv-scanner scan --timeout 120 .
```

### Cache Options

```bash
# Set cache directory
osv-scanner scan --cache-dir ~/.osv-scanner/cache .

# Update cache
osv-scanner scan --update-cache .

# Use cached database
osv-scanner scan --offline .
```

---

## Real-World Examples

### Example 1: Basic Node.js Project

```bash
# Scan
osv-scanner scan .

# Analyze
jq '.results[] | select(.vulnerabilities | length > 0)' results.json

# Fix
npm update lodash
```

### Example 2: CI/CD Pipeline (GitHub Actions)

```yaml
name: OSV-Scanner
on: [push, pull_request]

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run OSV-Scanner
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format sarif --output results.sarif ./

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

### Example 3: Python Project

```bash
# Install dependencies
pip install -r requirements.txt

# Scan
osv-scanner scan .

# Analyze
jq '.results[] | select(.vulnerabilities | length > 0)' results.json

# Fix
pip install --upgrade lodash
```

### Example 4: Monorepo

```bash
# Scan multiple directories
osv-scanner scan ./frontend ./backend ./shared

# Analyze
jq '.results[] | select(.vulnerabilities | length > 0)' results.json
```

### Example 5: Offline Scanning

```bash
# Update cache
osv-scanner scan --update-cache .

# Scan offline
osv-scanner scan --offline .

# Analyze
jq '.results[] | select(.vulnerabilities | length > 0)' results.json
```

### Example 6: Call Graph Analysis

```bash
# Scan with call graph analysis
osv-scanner scan --call-graph .

# This identifies if vulnerable code is actually reachable
jq '.results[] | select(.vulnerabilities | length > 0) | {id: .vulnerabilities[].id, reachable: .vulnerabilities[].reachable}' results.json
```

### Example 7: Custom Ignore Rules

```bash
# Create ignore file
cat > .osv-scanner.toml << 'EOF'
[[ignore]]
id = "GHSA-xxxx-xxxx-xxxx"
reason = "Not reachable from our code"

[[ignore]]
package = "lodash"
version = "4.17.21"
reason = "Using patched version"
EOF

# Scan with ignore rules
osv-scanner scan --config .osv-scanner.toml .
```

### Example 8: Scheduled Weekly Scan

```yaml
name: Weekly OSV Scan
on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

jobs:
  osv-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run OSV-Scanner
        uses: google/osv-scanner/actions/osv-scanner@v1
        with:
          scan-args: --format json --output results.json ./

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: osv-scanner-report
          path: results.json
```

### Example 9: Multiple Output Formats

```bash
# Generate multiple formats
osv-scanner scan \
  --format json --output results.json \
  --format sarif --output results.sarif \
  .

# Use JSON for analysis
jq '.results[] | select(.vulnerabilities | length > 0)' results.json

# Use SARIF for GitHub
# Upload results.sarif to GitHub Code Scanning
```

### Example 10: Docker Image Scanning

```bash
# Build image
docker build -t myapp:latest .

# Scan Dockerfile
osv-scanner scan --format docker Dockerfile

# Scan built image
docker run --rm -v $(pwd):/src ghcr.io/google/osv-scanner scan /src
```

---

## Further Reading

- [OSV-Scanner Official Documentation](https://github.com/google/osv-scanner)
- [OSV Database](https://osv.dev/)
- [OSV-Scanner GitHub](https://github.com/google/osv-scanner)
- [OSV API Documentation](https://osv.dev/docs/)
- [Google Security Blog](https://security.googleblog.com/)
- [OSV-Scanner Releases](https://github.com/google/osv-scanner/releases)
- [OSV-Scanner Examples](https://github.com/google/osv-scanner/tree/main/docs)
- [GitHub Code Scanning with SARIF](https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/using-sarif-outputs-from-code-scanning-tools)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [OWASP Dependency Check](https://jeremylong.github.io/DependencyCheck/) (alternative tool)
- [Snyk](https://snyk.io/) (alternative tool)
- [Trivy](https://trivy.dev/) (alternative tool for containers)
