# TruffleHog Complete Guide

## Table of Contents

1. [What Is TruffleHog](#1-what-is-trufflehog)
2. [Why Use TruffleHog](#2-why-use-trufflehog)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Custom Detectors](#7-custom-detectors)
8. [Integration](#8-integration)
9. [Security Considerations](#9-security-considerations)
10. [Troubleshooting](#10-troubleshooting)
11. [Tips & Best Practices](#11-tips--best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples-contoso-pet-store)
15. [Further Reading](#15-further-reading)

---

## 1. What Is TruffleHog

TruffleHog is an open-source secret scanning tool developed by Truffle Security that finds accidentally committed credentials, API keys, tokens, passwords, and other sensitive data in Git repositories — both public and private. It works by scanning entire Git history (all commits, branches, and tags), not just the latest snapshot of files.

### Key Characteristics

- **Deep history scanning**: Inspects every commit, not just HEAD
- **Regex + entropy detection**: Uses pattern matching and Shannon entropy analysis
- **600+ built-in detectors**: Covers AWS, GCP, Azure, GitHub, Slack, Stripe, and hundreds more
- **Custom detectors**: Write your own detectors using Go or RegEx
- **Multiple scan targets**: Local repos, GitHub/GitLab/Bitbucket, S3, filesystems
- **Pre-commit hooks**: Can be used as a pre-commit framework hook
- **Binary scanning**: Detects secrets in binary files
- **Verification**: Optionally verifies if discovered secrets are live
- **False positive reduction**: Entropy-based filtering, allowlists, result context

### History and Evolution

TruffleHog was originally created by Dylan Ayrey in 2016. Truffle Security rebuilt it from scratch in Go as TruffleHog v3, which is significantly faster and more feature-rich than the original Python version. The project is actively maintained with frequent releases.

### Architecture Overview

```
┌─────────────────────────────────────────┐
│           TruffleHog v3                 │
├─────────────────────────────────────────┤
│  Input Sources                          │
│  ├─ Local Git repos                     │
│  ├─ GitHub / GitLab / Bitbucket APIs    │
│  ├─ S3 buckets                          │
│  └─ Filesystem paths                    │
├─────────────────────────────────────────┤
│  Scanning Engine                        │
│  ├─ Git commit history walker           │
│  ├─ Regex detector engine               │
│  ├─ Entropy analyzer                    │
│  ├─ Binary scanner                      │
│  └─ Custom detector framework           │
├─────────────────────────────────────────┤
│  Output & Verification                  │
│  ├─ JSON / JSONL / SARIF / CSV output   │
│  ├─ Secret verification (live check)    │
│  ├─ Deduplication                       │
│  └─ GitHub/GitLab/Jira ticket creation  │
└─────────────────────────────────────────┘
```

---

## 2. Why Use TruffleHog

### The Problem

Secrets leakage is one of the most common and damaging security incidents. Developers accidentally commit:

- AWS access keys and secret keys
- GitHub/GitLab personal access tokens
- Database connection strings with passwords
- API keys for third-party services (Stripe, SendGrid, Twilio)
- Private keys (SSH, TLS, PGP)
- OAuth tokens and refresh tokens
- Webhook secrets
- Encryption keys

Once pushed to a Git repository — even if removed in a later commit — the secret persists in the repository history forever. Anyone with read access to the repository (or anyone who clones a public repo) can extract these secrets.

### Why TruffleHog Over Alternatives

| Feature | TruffleHog | GitLeaks | detect-secrets | GitHub Secret Scanning |
|---------|-----------|----------|----------------|----------------------|
| Deep history scanning | Yes | Yes | No (working tree only) | No (push events only) |
| Built-in detectors | 600+ | ~40 | ~70 | ~200 |
| Entropy detection | Yes | Yes | Yes | Limited |
| Custom detectors | Go + Regex | Regex only | Plugins | No |
| Verification | Yes | No | No | Yes |
| Binary scanning | Yes | Limited | No | No |
| Scanning targets | Git, S3, filesystem | Git only | Git only | GitHub only |
| SARIF output | Yes | Yes | No | Yes |
| Self-hosted support | Yes | Yes | Yes | GitHub Enterprise only |

### Use Cases

1. **Pre-commit prevention**: Stop secrets before they enter the repository
2. **CI/CD gate**: Block merges if secrets are detected
3. **Historical audit**: Scan entire Git history to find previously committed secrets
4. **Incident response**: Quickly identify all exposed credentials across repos
5. **Compliance**: Meet SOC 2, PCI DSS, HIPAA requirements for credential management
6. **Monitoring**: Continuously scan for new secrets on push events

---

## 3. Installation

### Method 1: Binary Release (Recommended)

Download the latest release from GitHub:

```bash
# Linux (amd64)
curl -sSfL https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_amd64.tar.gz | tar -xz trufflehog
sudo mv trufflehog /usr/local/bin/

# Linux (arm64)
curl -sSfL https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_arm64.tar.gz | tar -xz trufflehog
sudo mv trufflehog /usr/local/bin/

# macOS (amd64)
curl -sSfL https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_darwin_amd64.tar.gz | tar -xz trufflehog
sudo mv trufflehog /usr/local/bin/

# macOS (arm64 / Apple Silicon)
curl -sSfL https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_darwin_arm64.tar.gz | tar -xz trufflehog
sudo mv trufflehog /usr/local/bin/

# Verify
trufflehog --version
```

### Method 2: Go Install

```bash
go install github.com/trufflesecurity/trufflehog/v3@latest
```

### Method 3: Docker

```bash
# Scan local directory
docker run -v "$PWD:/repo" trufflesecurity/trufflehog:latest git file:///repo

# Scan GitHub (pass token via env)
docker run -e GITHUB_TOKEN="$GITHUB_TOKEN" trufflesecurity/trufflehog:latest github --repo https://github.com/owner/repo
```

### Method 4: Homebrew (macOS)

```bash
brew install trufflehog
```

### Method 5: Pre-commit Framework

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.13
    hooks:
      - id: trufflehog
```

Then install:

```bash
pip install pre-commit
pre-commit install
```

### Method 6: Binary (using trufflehog)

```bash
trufflehog binary --results verified,unverified --ensure-unique
```

### Building from Source

```bash
git clone https://github.com/trufflesecurity/trufflehog.git
cd trufflehog
go build -o trufflehog ./main.go
sudo mv trufflehog /usr/local/bin/
```

### Platform-Specific Notes

**Windows:**
Use WSL2 for best results. Native Windows support is experimental via Go compilation:

```bash
GOOS=windows GOARCH=amd64 go build -o trufflehog.exe ./main.go
```

**Docker with Docker-in-Docker (CI/CD):**

```yaml
# docker-compose.yml
services:
  trufflehog:
    image: trufflesecurity/trufflehog:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

---

## 4. Configuration

### Command-Line Flags

All flags can be used directly on the command line:

```
--config string          Config file path
--json                   Output in JSON format
--json-raw               Output raw JSON (no pretty printing)
--json-lines             Output in JSONL format
--sarif                  Output in SARIF format
--csv                    Output in CSV format
--github-actions         Output results formatted for GitHub Actions annotations
--results string         Result types: verified,unverified,unaudited (default "verified,unverified")
--fail                   Exit with code 1 if findings exist
--no-verification        Skip secret verification
--only-verified          Only show verified secrets
--concurrency int        Number of concurrent workers (default 100)
--entropy float          Entropy threshold for high-entropy strings (default 0.7)
--include-detectors string   Comma-separated list of detector types to include
--exclude-detectors string   Comma-separated list of detector types to exclude
--exclude-paths string       File paths to exclude (regex)
--include-paths string       File paths to include (regex)
--include-detectors-by-id string   Detector IDs to include
--exclude-detectors-by-id string   Detector IDs to exclude
--exclude-rotated         Exclude known rotated/dummy secrets
--context                 Print source context around findings
--no-context              Do not print source context
--branch string           Branch to scan (default all)
--since-commit string     Scan from this commit
--commit string           Specific commit to scan
--max-depth int           Maximum depth of commits to scan
--debounce int            Debounce interval in milliseconds
--print-average-info      Print scanning average info
--output string           Write output to file
--verbose                 Enable verbose logging
--debug                   Enable debug logging
--trace                   Enable trace logging
--log-format string       Log format: text, json (default "text")
--no-update               Skip version check
--help                    Show help
```

### Configuration File

TruffleHog supports a TOML or YAML configuration file:

```toml
# trufflehog.toml

# Global settings
[global]
concurrency = 200
entropy = 0.6
results = ["verified", "unverified"]

# Scan settings
[scan]
max-depth = 1000
include-paths = [
    "\\.go$",
    "\\.py$",
    "\\.js$",
    "\\.ts$",
    "\\.java$",
    "\\.rb$",
    "\\.yml$",
    "\\.yaml$",
    "\\.json$",
    "\\.env.*$",
    "\\.cfg$",
    "\\.conf$",
    "\\.ini$",
    "\\.xml$",
    "\\.properties$",
    "\\.tf$",
    "\\.hcl$",
]
exclude-paths = [
    "vendor/",
    "node_modules/",
    "\\.min\\.js$",
    "go\\.sum$",
    "package-lock\\.json$",
    "\\.map$",
    "test/fixtures/",
    "testdata/",
]

# Specific detector overrides
[[scan.detectors]]
type = "aws_access_key"
enabled = true
entropy = 0.5

[[scan.detectors]]
type = "generic_password"
entropy = 0.8

# Allowlist (false positive suppression)
[[scan.allowlists]]
description = "Test credentials"
paths = ["test/.*\\.py$"]
detectors = ["generic_password", "generic_api_key"]
words = ["example", "test-key", "dummy", "placeholder"]

# Output
[output]
format = "json"
verification = true
only-verified = false
context = true
```

### YAML Configuration

```yaml
# trufflehog.yaml
global:
  concurrency: 200
  entropy: 0.6
  results:
    - verified
    - unverified

scan:
  max-depth: 1000
  include-paths:
    - '\.go$'
    - '\.py$'
    - '\.js$'
  exclude-paths:
    - 'vendor/'
    - 'node_modules/'
  detectors:
    - type: aws_access_key
      enabled: true
    - type: generic_password
      entropy: 0.8
  allowlists:
    - description: "Test fixtures"
      paths:
        - 'test/.*'
      words:
        - "example"
        - "test-key"

output:
  format: json
  verification: true
  context: true
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GITHUB_TOKEN` | GitHub PAT for repo scanning | — |
| `GITHUB_ENTERPRISE_URL` | GitHub Enterprise base URL | — |
| `GITLAB_TOKEN` | GitLab PAT for repo scanning | — |
| `BITBUCKET_TOKEN` | Bitbucket app password | — |
| `BITBUCKET_USERNAME` | Bitbucket username | — |
| `CONFLUENCE_ACCESS_TOKEN` | Confluence API token | — |
| `CONFLUENCE_URL` | Confluence server URL | — |
| `JIRA_ACCESS_TOKEN` | Jira API token | — |
| `JIRA_URL` | Jira server URL | — |
| `AWS_ACCESS_KEY_ID` | AWS credentials for S3 scanning | — |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | — |
| `AWS_REGION` | AWS region for S3 | — |

---

## 5. Core Concepts

### Detectors

A detector is a rule that identifies a specific type of secret. Each detector consists of:

- **Pattern**: Regex or composite pattern to match the secret
- **Keywords**: Prefix/context words that help identify the secret (e.g., `AKIA` for AWS keys)
- **Entropy**: Minimum Shannon entropy threshold
- **Verification**: Whether the detector can verify the secret is live

```go
// Example: Custom detector in Go
type MyDetector struct{}

func (d MyDetector) Keywords() []string {
    return []string{"myapi_", "mycompany_"}
}

func (d MyDetector) FromData(ctx context.Context, verify bool, data []byte) ([]DetectorsResult, error) {
    results := []DetectorsResult{}
    
    // Regex pattern for the secret
    pattern := regexp.MustCompile(`mycompany_[a-zA-Z0-9]{32,64}`)
    matches := pattern.FindAll(data, -1)
    
    for _, match := range matches {
        secret := string(match)
        
        // Verify if requested
        verified := false
        if verify {
            verified = verifyMyAPI(ctx, secret)
        }
        
        results = append(results, DetectorsResult{
            Verified:  verified,
            Secret:    secret,
            Redacted:  "mycompany_****",
            DetectorName: "mycompany_api_key",
            DetectorID:   "mycompany-api-key",
            StartLine:    /* ... */,
            EndLine:      /* ... */,
            StartColumn:  /* ... */,
            EndColumn:    /* ... */,
        })
    }
    return results, nil
}
```

### Entropy Detection

Shannon entropy measures the randomness of a string. High-entropy strings are more likely to be secrets because they lack predictable patterns:

```
Entropy = -Σ(p(x) * log2(p(x)))

Where p(x) = frequency of character x in the string
```

**Entropy thresholds:**

| Value | Meaning | Example |
|-------|---------|---------|
| < 0.3 | Low entropy | `password` (0.86) |
| 0.3-0.5 | Medium entropy | `my-secret-key-123` (3.1) |
| 0.5-0.7 | High entropy | `AKIAIOSFODNN7EXAMPLE` (3.8) |
| > 0.7 | Very high entropy | Random 32-byte hex (4.0) |

TruffleHog uses entropy to filter high-entropy strings that match generic patterns, reducing false positives.

### Scanning Modes

**1. Repository Scanning**
```bash
# Local repo
trufflehog git file:///path/to/repo

# Remote repo
trufflehog github --repo https://github.com/owner/repo
```

**2. Filesystem Scanning**
```bash
trufflehog filesystem /path/to/directory
```

**3. S3 Scanning**
```bash
trufflehog s3 --bucket my-bucket --region us-east-1
```

**4. Binary Scanning**
```bash
trufflehog binary /path/to/binary
```

### Verification

TruffleHog can verify if a discovered secret is live by making a test API call:

```bash
# With verification (default)
trufflehog git file:///repo --results verified,unverified

# Without verification
trufflehog git file:///repo --no-verification

# Only verified secrets
trufflehog git file:///repo --only-verified
```

**Verification works for:**
- AWS keys (tests with `GetCallerIdentity`)
- GitHub tokens (tests with `/user` API)
- GitLab tokens (tests with `/user` API)
- Slack tokens (tests with `/auth.test`)
- Stripe keys (tests with `/balance`)
- And many more

**Never verify in production environments.** Use a dedicated test account or a canary token approach.

### Result Types

| Type | Description |
|------|-------------|
| `verified` | Secret was confirmed to be live |
| `unverified` | Secret matches pattern but was not verified |
| `unaudited` | Secret was scanned but not yet reviewed |

### Deduplication

TruffleHog deduplicates findings based on:
- Secret value
- Detector type
- File path
- Commit hash

The `--ensure-unique` flag (on by default) prevents duplicate results across commits.

---

## 6. Usage Guide

### Step 1: Basic Repository Scan

```bash
# Scan a local Git repository
trufflehog git file:///home/user/my-project

# Scan a remote GitHub repository
trufflehog github --repo https://github.com/owner/repo

# Scan with verification
trufflehog git file:///home/user/my-project --results verified,unverified
```

### Step 2: Scan Specific Branches or Commits

```bash
# Scan only the main branch
trufflehog git file:///repo --branch main

# Scan a specific range
trufflehog git file:///repo --since-commit abc1234

# Scan a specific commit
trufflehog git file:///repo --commit def5678

# Limit depth
trufflehog git file:///repo --max-depth 100
```

### Step 3: Filter Results

```bash
# Only AWS secrets
trufflehog git file:///repo --include-detectors-by-id aws_access_key,aws_secret_key

# Exclude generic detectors
trufflehog git file:///repo --exclude-detectors generic_password,generic_api_key

# Filter by file path
trufflehog git file:///repo --include-paths "\\.env"
trufflehog git file:///repo --exclude-paths "vendor/,node_modules/"

# Only verified secrets
trufflehog git file:///repo --only-verified
```

### Step 4: Configure Output

```bash
# JSON output
trufflehog git file:///repo --json > findings.json

# SARIF output (for GitHub Security tab)
trufflehog git file:///repo --sarif > findings.sarif

# CSV output
trufflehog git file:///repo --csv > findings.csv

# GitHub Actions annotations
trufflehog git file:///repo --github-actions

# With source context
trufflehog git file:///repo --context

# Verbose output
trufflehog git file:///repo --verbose
```

### Step 5: Fail on Findings (CI/CD)

```bash
# Exit with non-zero code if secrets found
trufflehog git file:///repo --fail

# Combined with verification
trufflehog git file:///repo --fail --only-verified
```

### Step 6: Scan Multiple Repositories

```bash
# From a file listing repos
for repo in $(cat repos.txt); do
    trufflehog github --repo "$repo" --results verified,unverified
done

# All repos in a GitHub org
trufflehog github --org my-org --token "$GITHUB_TOKEN"

# All repos for a GitHub user
trufflehog github --include-usernames myuser
```

### Step 7: Scan with Custom Detectors

```bash
# Using a custom detector (Go plugin)
trufflehog git file:///repo --config ./my-config.toml

# Include only specific detectors
trufflehog git file:///repo \
    --include-detectors-by-id "aws_access_key,aws_secret_access_key,github_token"
```

### Step 8: SARIF Output for GitHub

```bash
# Generate SARIF for GitHub Advanced Security
trufflehog git file:///repo \
    --results verified,unverified \
    --sarif \
    --fail > results.sarif

# Upload to GitHub
gh api repos/{owner}/{repo}/code-scanning/sarifs \
    -H "Accept: application/vnd.github+json" \
    --input results.sarif
```

---

## 7. Custom Detectors

### Writing a Detector in Go

Create a new file in `pkg/detectors/mydetector/`:

```go
package mydetector

import (
    "context"
    "regexp"
    "strings"

    "github.com/trufflesecurity/trufflehog/v3/pkg/common"
    "github.com/trufflesecurity/trufflehog/v3/pkg/detectors"
    "github.com/trufflesecurity/trufflehog/v3/pkg/pb/detectorspb"
)

type MyServiceKey struct {
    detectors.DetectorBase
}

func (d MyServiceKey) Keywords() []string {
    return []string{"myservice", "my_svc_key"}
}

var (
    keyPattern = regexp.MustCompile(`myservice_[a-zA-Z0-9]{40}`)
    client     = common.RetryableHttpClient(2)
)

func (d MyServiceKey) FromData(ctx context.Context, verify bool, data []byte) ([]detectors.DetectorResult, error) {
    dataStr := string(data)
    matches := keyPattern.FindAllStringSubmatch(dataStr, -1)
    
    results := []detectors.DetectorResult{}
    
    for _, match := range matches {
        if len(match) < 1 {
            continue
        }
        
        secret := strings.TrimSpace(match[0])
        
        // Check for common false positives
        if detectors.IsKnownFalsePositive(secret, d.DefaultTruePositive(), false) {
            continue
        }
        
        result := detectors.DetectorResult{
            Verified:  false,
            Secret:    secret,
            Redacted:  redact(secret),
            DetectorName: "myservice-api-key",
            DetectorID:   detectorspb.DetectorType_MyServiceKey,
            StartLine:    /* calculate */,
            EndLine:      /* calculate */,
            StartColumn:  /* calculate */,
            EndColumn:    /* calculate */,
        }
        
        if verify {
            isVerified, err := verifyKey(ctx, secret)
            if err != nil {
                // Log error but don't fail
            }
            result.Verified = isVerified
        }
        
        results = append(results, result)
    }
    
    return results, nil
}

func redact(s string) string {
    if len(s) < 12 {
        return s
    }
    return s[:8] + strings.Repeat("*", len(s)-12) + s[len(s)-4:]
}

func verifyKey(ctx context.Context, key string) (bool, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", "https://api.myservice.com/v1/me", nil)
    if err != nil {
        return false, err
    }
    req.Header.Set("Authorization", "Bearer "+key)
    
    resp, err := client.Do(req)
    if err != nil {
        return false, err
    }
    defer resp.Body.Close()
    
    return resp.StatusCode == http.StatusOK, nil
}
```

### Registering the Detector

Add to `pkg/detectors/list.go`:

```go
import "github.com/trufflesecurity/trufflehog/v3/pkg/detectors/mydetector"

// In the allDetectors map:
detectorspb.DetectorType_MyServiceKey: mydetector.MyServiceKey{},
```

### Custom Regex Detectors (Config-Only)

Without writing Go code, you can add regex-based detectors via config:

```toml
[[scan.custom_detectors]]
name = "internal-api-key"
pattern = "internal_key_[a-zA-Z0-9]{32}"
keywords = ["internal_key"]
entropy = 0.6
```

### Composite Detectors

Combine multiple patterns with adjacent keyword context:

```go
func (d CompositeDetector) FromData(ctx context.Context, verify bool, data []byte) ([]DetectorsResult, error) {
    // Find keywords first
    keywordLocations := findKeywords(data, d.Keywords())
    
    // For each keyword, search nearby for the actual secret
    results := []DetectorsResult{}
    for _, loc := range keywordLocations {
        // Search within 200 characters of the keyword
        start := max(0, loc.Offset-200)
        end := min(len(data), loc.Offset+len(loc.Keyword)+200)
        context := data[start:end]
        
        matches := secretPattern.FindAll(context, -1)
        // ... process matches
    }
    return results, nil
}
```

---

## 8. Integration

### Pre-commit Framework

`.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.13
    hooks:
      - id: trufflehog
        args: ['--only-verified', '--fail']
```

### GitHub Actions

```yaml
# .github/workflows/secret-scanning.yml
name: Secret Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  contents: read
  security-events: write  # For SARIF upload

jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for deep scan

      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified --fail --sarif --output sarif.results

      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: sarif.results
```

### GitLab CI

```yaml
# .gitlab-ci.yml
secret-scanning:
  stage: security
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog git file://$CI_PROJECT_DIR
        --only-verified
        --fail
        --json > trufflehog-results.json
  artifacts:
    reports:
      sast: trufflehog-results.json
  allow_failure: false
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Secret Scanning') {
            steps {
                sh '''
                    docker run --rm \
                        -v "$WORKSPACE:/repo" \
                        trufflesecurity/trufflehog:latest \
                        git file:///repo \
                        --only-verified \
                        --fail \
                        --json > trufflehog-results.json
                '''
                
                archiveArtifacts artifacts: 'trufflehog-results.json'
            }
            post {
                failure {
                    slackSend channel: '#security-alerts',
                        message: "Secrets found in ${env.JOB_NAME}"
                }
            }
        }
    }
}
```

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

steps:
  - script: |
      docker run --rm \
        -v $(Build.SourcesDirectory):/repo \
        trufflesecurity/trufflehog:latest \
        git file:///repo \
        --only-verified \
        --fail \
        --json > $(Build.ArtifactStagingDirectory)/results.json
    displayName: 'TruffleHog Secret Scan'

  - task: PublishBuildArtifacts@1
    inputs:
      PathtoPublish: '$(Build.ArtifactStagingDirectory)/results.json'
```

### CLI Integration Scripts

```bash
#!/bin/bash
# scan-all-repos.sh — Scan all repos in a GitHub org

ORG="myorg"
TOKEN="${GITHUB_TOKEN}"
OUTPUT_DIR="./scan-results/$(date +%Y%m%d)"
mkdir -p "$OUTPUT_DIR"

# Get all repos in the org
repos=$(gh api "orgs/$ORG/repos?per_page=100" --jq '.[].full_name')

for repo in $repos; do
    echo "=== Scanning $repo ==="
    safe_name=$(echo "$repo" | tr '/' '_')
    
    trufflehog github \
        --repo "https://github.com/$repo" \
        --token "$TOKEN" \
        --results verified,unverified \
        --json \
        --fail \
        > "$OUTPUT_DIR/${safe_name}.json" 2>&1
    
    if [ $? -ne 0 ]; then
        echo "  SECRETS FOUND in $repo"
    else
        echo "  Clean"
    fi
done

echo "Results saved to $OUTPUT_DIR"
```

### Jira Integration (Webhook)

```python
#!/usr/bin/env python3
"""Post TruffleHog findings to Jira tickets."""
import json
import subprocess
import requests
import os

JIRA_URL = os.environ["JIRA_URL"]
JIRA_TOKEN = os.environ["JIRA_TOKEN"]
JIRA_PROJECT = os.environ["JIRA_PROJECT"]

def create_jira_ticket(title, description, severity="High"):
    headers = {
        "Authorization": f"Bearer {JIRA_TOKEN}",
        "Content-Type": "application/json"
    }
    payload = {
        "fields": {
            "project": {"key": JIRA_PROJECT},
            "issuetype": {"name": "Security"},
            "summary": title,
            "description": description,
            "priority": {"name": severity},
            "labels": ["security", "credential-leak"]
        }
    }
    resp = requests.post(f"{JIRA_URL}/rest/api/3/issue",
                         json=payload, headers=headers)
    return resp.json()["key"]

def main():
    result = subprocess.run(
        ["trufflehog", "git", "file:///repo",
         "--json", "--only-verified"],
        capture_output=True, text=True
    )
    
    findings = [json.loads(line) for line in result.stdout.splitlines()
                if line.strip()]
    
    for finding in findings:
        title = f"[SECURITY] {finding['DetectorName']} found in {finding['SourceMetadata']['Git']['file']}"
        desc = f"""
h2. Secret Found
- *Type*: {finding['DetectorName']}
- *File*: {finding['SourceMetadata']['Git']['file']}
- *Commit*: {finding['SourceMetadata']['Git']['commit']}
- *Verified*: {finding['Verified']}

h2. Remediation
1. Revoke the exposed credential immediately
2. Generate a new credential
3. Update all services using the old credential
4. Audit access logs for unauthorized usage
5. Consider rotating all credentials in the same scope
"""
        ticket = create_jira_ticket(title, desc)
        print(f"Created Jira ticket: {ticket}")

if __name__ == "__main__":
    main()
```

---

## 9. Security Considerations

### Do Not Verify in Production

```bash
# NEVER do this against production services with real traffic
trufflehog git file:///repo  # default: verifies

# DO this instead: use canary/test credentials
trufflehog git file:///repo --no-verification
```

### Token Scope for GitHub Scanning

```bash
# Minimum required scopes:
# - repo (for private repos)
# - read:org (for org scanning)

# For fine-grained tokens:
# - Repository access: All repositories or specific repos
# - Permissions: Contents (read-only), Metadata (read-only)
```

### Rate Limiting

```bash
# GitHub API rate limits:
# - Authenticated: 5,000 requests/hour
# - Unauthenticated: 60 requests/hour

# TruffleHog handles rate limiting internally with exponential backoff
# But you can reduce concurrency to be gentler:
trufflehog github --org my-org --concurrency 50
```

### Scan Results Handling

1. **Never commit scan results to Git** — they contain secret fragments
2. **Use encrypted storage** for results in CI/CD artifacts
3. **Restrict access** to scan results (same as credential access)
4. **Purge old results** regularly
5. **Use SARIF** for integration with security dashboards

### Network Security

```bash
# TruffleHog makes outbound connections for:
# - Git cloning (GitHub/GitLab/Bitbucket APIs)
# - Secret verification (various APIs)
# - S3 access (AWS SDK)

# Ensure your network allows these connections
# Use proxy settings if needed:
HTTPS_PROXY=http://proxy:8080 trufflehog github --org my-org
```

### Incident Response Workflow

```
1. Detect
   └─ TruffleHog finds verified secret in commit XYZ
   
2. Contain
   └─ Revoke credential immediately
   └─ Rotate to new credential
   └─ Identify scope of exposure
   
3. Investigate
   └─ Review commit history: who pushed it, when
   └─ Check access logs for the exposed credential
   └─ Determine if credential was accessed by unauthorized parties
   
4. Remediate
   └─ Remove from Git history (git filter-branch / BFG)
   └─ Update all services with new credential
   └─ Deploy to production
   
5. Document
   └─ Create Jira ticket with full timeline
   └─ Update runbooks
   └─ Brief team on prevention
```

---

## 10. Troubleshooting

### Issue 1: "permission denied" on git repository

```
error: repository not found or permission denied
```

**Cause:** Repository is private and no valid token provided.

**Fix:**
```bash
# Set up authentication
export GITHUB_TOKEN="ghp_your_token_here"
trufflehog github --repo https://github.com/owner/private-repo

# Or clone locally first
git clone https://github.com/owner/private-repo.git
trufflehog git file:///path/to/private-repo
```

### Issue 2: Too many false positives

**Cause:** Generic detectors matching common patterns in test files or documentation.

**Fix:**
```bash
# Use allowlists
trufflehog git file:///repo \
    --exclude-paths "test/,fixtures/,example/" \
    --exclude-detectors generic_password,generic_api_key

# Or use config file
cat > trufflehog.toml << 'EOF'
[[scan.allowlists]]
description = "Test/example values"
words = ["example", "test", "dummy", "placeholder", "xxx"]
paths = ["test/.*", "example/.*", "docs/.*"]
EOF
```

### Issue 3: Slow scanning on large repositories

**Cause:** Deep history with millions of commits.

**Fix:**
```bash
# Limit depth
trufflehog git file:///repo --max-depth 1000

# Scan specific branch only
trufflehog git file:///repo --branch main

# Increase concurrency
trufflehog git file:///repo --concurrency 200

# Filter to specific file types
trufflehog git file:///repo \
    --include-paths "\\.env,\\.pem,\\.key,config\\."
```

### Issue 4: Rate limiting on GitHub API

```
API rate limit exceeded
```

**Fix:**
```bash
# Use authenticated requests (5,000/hour vs 60/hour)
export GITHUB_TOKEN="ghp_..."
trufflehog github --org my-org

# Reduce concurrency
trufflehog github --org my-org --concurrency 20

# Scan specific repos instead of entire org
trufflehog github --repo https://github.com/org/repo1
trufflehog github --repo https://github.com/org/repo2
```

### Issue 5: Binary file scanning errors

```
failed to read binary file: EOF
```

**Cause:** Binary files too large or corrupted.

**Fix:**
```bash
# Skip binary files
trufflehog git file:///repo --exclude-paths "\\.exe$,\\.dll$,\\.so$,\\.dylib$"

# Or scan binaries separately
trufflehog binary /path/to/binary --results verified,unverified
```

### Issue 6: SARIF output is empty

**Cause:** No findings or incorrect output redirection.

**Fix:**
```bash
# Ensure --sarif flag is used
trufflehog git file:///repo --sarif > results.sarif

# Check file size
ls -la results.sarif

# If empty, verify findings exist without SARIF
trufflehog git file:///repo --json | head -5
```

### Issue 7: Docker container cannot access local repository

```
No such file or directory: /repo
```

**Fix:**
```bash
# Mount current directory
docker run -v "$(pwd):/repo" trufflesecurity/trufflehog:latest git file:///repo

# For nested repos
docker run -v "/absolute/path/to/repo:/repo:ro" trufflesecurity/trufflehog:latest git file:///repo
```

### Issue 8: Custom detector not found

```
unknown detector: my_detector
```

**Fix:**
```bash
# Verify detector is registered
trufflehog git file:///repo --help | grep -i my_detector

# Check detector name in config
trufflehog git file:///repo \
    --include-detectors-by-id "my_detector_id"

# List available detectors
trufflehog git file:///repo --help
```

### Issue 9: Exit code 0 when secrets are found

**Cause:** Missing `--fail` flag.

**Fix:**
```bash
# Always use --fail in CI/CD
trufflehog git file:///repo --fail --only-verified

# Test exit code
trufflehog git file:///repo --fail
echo $?  # 0 = clean, 1 = findings
```

### Issue 10: Scan hangs on large repository

**Cause:** Too many concurrent operations or network timeout.

**Fix:**
```bash
# Reduce concurrency
trufflehog git file:///repo --concurrency 10

# Set timeout
timeout 600 trufflehog git file:///repo --fail

# Scan with depth limit
trufflehog git file:///repo --max-depth 500 --concurrency 50
```

### Issue 11: "no detectors available"

**Cause:** All detectors excluded or misconfigured.

**Fix:**
```bash
# Don't exclude everything
trufflehog git file:///repo --include-detectors-by-id ""

# Check configuration
cat trufflehog.toml | grep -A5 exclude

# Use defaults
trufflehog git file:///repo  # no filter flags
```

### Issue 12: Results show same secret multiple times

**Cause:** Same secret committed in multiple commits, deduplication not working.

**Fix:**
```bash
# Ensure deduplication is enabled (default)
trufflehog git file:///repo --ensure-unique

# If still seeing duplicates, check if they're genuinely different
# (different file, different context)
trufflehog git file:///repo --context
```

### Issue 13: Git LFS not handled properly

**Cause:** Git LFS pointers scanned instead of actual content.

**Fix:**
```bash
# Ensure Git LFS is installed and pulled
git lfs install
git lfs pull

# Then scan
trufflehog git file:///repo
```

### Issue 14: Environment variable not picked up

```bash
# Ensure export is in current shell
export GITHUB_TOKEN="ghp_..."
echo $GITHUB_TOKEN  # Should print token

# Or pass inline
GITHUB_TOKEN="ghp_..." trufflehog github --org my-org
```

### Issue 15: "unsupported protocol" error

```
unsupported protocol: "s3"
```

**Cause:** S3 scanning not compiled or wrong binary.

**Fix:**
```bash
# Use full release binary (includes all features)
curl -sSfL https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_amd64.tar.gz | tar -xz
sudo mv trufflehog /usr/local/bin/

# Verify S3 support
trufflehog s3 --help
```

### Issue 16: Scan results not appearing in GitHub Security tab

**Cause:** SARIF not uploaded or incorrect format.

**Fix:**
```bash
# Generate valid SARIF
trufflehog git file:///repo --sarif --results verified,unverified > results.sarif

# Validate SARIF
python -c "import json; d=json.load(open('results.sarif')); print(d['version'])"

# Upload using gh CLI
gh api repos/owner/repo/code-scanning/sarifs \
    -H "Accept: application/vnd.github+json" \
    --input results.sarif
```

### Issue 17: Memory usage too high on large repos

**Cause:** Millions of commits loaded into memory.

**Fix:**
```bash
# Limit depth and concurrency
trufflehog git file:///repo --max-depth 1000 --concurrency 50

# Scan specific branch
trufflehog git file:///repo --branch main

# Use filesystem scanning instead (working tree only)
trufflehog filesystem /path/to/repo
```

---

## 11. Tips & Best Practices

### Tip 1: Use Pre-commit Hooks

Catch secrets before they reach the repository:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.13
    hooks:
      - id: trufflehog
        args: ['--only-verified']
```

### Tip 2: Scan in CI/CD with `--fail`

```yaml
# Always fail CI if secrets are found
- name: Scan
  run: trufflehog git file://. --fail --only-verified
```

### Tip 3: Use SARIF for GitHub Integration

```bash
trufflehog git file:///repo --sarif --results verified > results.sarif
```

### Tip 4: Scan All Branches, Not Just HEAD

```bash
# Default behavior scans all branches
trufflehog git file:///repo

# But for speed, focus on main branches
trufflehog git file:///repo --branch main --branch develop
```

### Tip 5: Use Allowlists for Test Fixtures

```toml
[[scan.allowlists]]
description = "Test credentials"
words = ["test", "example", "dummy", "placeholder", "xxx", "000"]
paths = ["test/", "tests/", "spec/", "fixture/", "__test__/", "testdata/"]
```

### Tip 6: Verify Before Revoking

```bash
# Check if a secret is actually live before triggering a rotation
trufflehog git file:///repo --only-verified --json | jq '.Secret'
```

### Tip 7: Combine with git-secrets

```bash
# Use git-secrets for pre-commit and TruffleHog for deep scans
git secrets --install
git secrets --register-aws

# TruffleHog for historical audit
trufflehog git file:///repo --fail
```

### Tip 8: Scan S3 Buckets for Leaked Secrets

```bash
trufflehog s3 --bucket my-bucket --region us-east-1 \
    --results verified,unverified --fail
```

### Tip 9: Export Findings to Jira Automatically

```python
import subprocess, json
result = subprocess.run(
    ["trufflehog", "git", "file:///repo", "--json"],
    capture_output=True, text=True
)
for line in result.stdout.splitlines():
    finding = json.loads(line)
    if finding["Verified"]:
        create_jira_ticket(finding)
```

### Tip 10: Use Entropy Thresholds for Custom Detectors

```toml
[[scan.custom_detectors]]
name = "high-entropy-api-key"
pattern = "api_[a-zA-Z0-9]{40,}"
entropy = 0.7  # Only match very random strings
```

### Tip 11: Scan Monorepo Paths Separately

```bash
# Scan only backend code
trufflehog git file:///repo --include-paths "backend/,api/,services/"

# Scan only config files
trufflehog git file:///repo --include-paths "\\.env,config/,deployment/"
```

### Tip 12: Use Results Context for Triage

```bash
# Show surrounding code for each finding
trufflehog git file:///repo --context

# Helps determine if finding is a real secret or false positive
```

### Tip 13: Set Up Automated Monitoring

```bash
# Cron job to scan daily
0 2 * * * /usr/local/bin/trufflehog github --org my-org --fail --json > /var/log/trufflehog-$(date +\%Y\%m\%d).json 2>&1
```

### Tip 14: Scan Forked Repos Separately

```bash
# Forked repos don't inherit CI triggers
# Set up a separate workflow or manual scan:
trufflehog github --repo https://github.com/myuser/forked-repo --fail
```

### Tip 15: Use Docker for Isolated Scanning

```bash
# Scan in a clean container with no credentials leaking
docker run --rm \
    -v "$REPO_PATH:/repo:ro" \
    --network none \
    trufflesecurity/trufflehog:latest \
    git file:///repo --no-verification
```

### Tip 16: Audit Supply Chain Dependencies

```bash
# Scan .go.sum, package-lock.json, etc. for embedded secrets
trufflehog git file:///repo \
    --include-paths "go\\.sum$,package-lock\\.json$,yarn\\.lock$"
```

### Tip 17: Use TruffleHog as a Library

```go
package main

import (
    "context"
    "github.com/trufflesecurity/trufflehog/v3/pkg/engine"
    "github.com/trufflesecurity/trufflehog/v3/pkg/sources/git"
)

func main() {
    ctx := context.Background()
    
    // Create a scanning engine
    eng := engine.New(ctx, engine.Config{
        Concurrency: 100,
        Results:     []string{"verified", "unverified"},
    })
    
    // Add a Git source
    gitSource := git.NewGitSource("file:///path/to/repo")
    eng.AddSource(gitSource)
    
    // Run the scan
    results := eng.Scan(ctx)
    for _, r := range results {
        fmt.Printf("Found %s in %s\n", r.DetectorName, r.SourceMetadata.Git.File)
    }
}
```

---

## 12. Command Reference

### Top-Level Commands

| Command | Description |
|---------|-------------|
| `trufflehog git` | Scan a Git repository |
| `trufflehog github` | Scan GitHub repositories |
| `trufflehog gitlab` | Scan GitLab repositories |
| `trufflehog bitbucket` | Scan Bitbucket repositories |
| `trufflehog filesystem` | Scan a filesystem directory |
| `trufflehog s3` | Scan an S3 bucket |
| `trufflehog binary` | Scan a binary file |
| `trufflehog version` | Show version information |
| `trufflehog completion` | Generate shell completion scripts |

### Common Flags (All Commands)

```
--json                    Output as JSON
--json-raw                Output raw JSON
--json-lines              Output as JSONL
--sarif                   Output as SARIF
--csv                     Output as CSV
--github-actions          GitHub Actions annotations format
--results string          Result types: verified,unverified
--fail                    Exit non-zero if findings
--no-verification         Skip verification
--only-verified           Only verified secrets
--concurrency int         Concurrent workers
--context                 Show source context
--no-context              Hide source context
--output string           Write output to file
--verbose                 Verbose output
--debug                   Debug output
--config string           Config file path
```

### `trufflehog git` Flags

```
--repo string             Git repository URL or path
--branch string           Branch(es) to scan
--commit string           Specific commit to scan
--since-commit string     Scan from this commit
--max-depth int           Maximum commit depth
--include-paths string    Paths to include (regex)
--exclude-paths string    Paths to exclude (regex)
--include-detectors string    Detector types to include
--exclude-detectors string    Detector types to exclude
--include-detectors-by-id string   Detector IDs to include
--exclude-detectors-by-id string   Detector IDs to exclude
--entropy float           Entropy threshold
```

### `trufflehog github` Flags

```
--repo string             GitHub repo URL
--org string              Scan all repos in organization
--include-usernames string    Scan repos of these users
--token string            GitHub token (or $GITHUB_TOKEN)
--github-enterprise-url string   GitHub Enterprise URL
--pr-comment              Post PR comment with findings
--commit-comments         Post commit comments
--issue-comments          Post issue comments
```

### `trufflehog filesystem` Flags

```
--directory string        Directory to scan
--include-paths string    Paths to include (regex)
--exclude-paths string    Paths to exclude (regex)
--no-follow-symlinks      Skip symbolic links
```

### `trufflehog s3` Flags

```
--bucket string           S3 bucket name
--region string           AWS region
--prefix string           S3 key prefix to scan
--max-file-size int       Maximum file size in bytes
```

### `trufflehog binary` Flags

```
--path string             Binary file path
```

---

## 13. Configuration Reference

### Complete Configuration File

```toml
# trufflehog.toml — Complete Reference

# =============================================================================
# Global Settings
# =============================================================================
[global]
# Number of concurrent scanning workers (default: 100)
concurrency = 200

# Minimum entropy for high-entropy string detection (default: 0.7)
entropy = 0.6

# Result types to include (default: ["verified", "unverified"])
results = ["verified", "unverified"]

# Skip verification entirely
no_verification = false

# Only report verified secrets
only_verified = true

# Print source context around findings
context = true

# =============================================================================
# Scan Settings
# =============================================================================
[scan]
# Maximum depth of commits to scan
max-depth = 5000

# Regex patterns for file paths to include
include-paths = [
    "\\.go$",
    "\\.py$",
    "\\.js$",
    "\\.ts$",
    "\\.jsx$",
    "\\.tsx$",
    "\\.java$",
    "\\.rb$",
    "\\.php$",
    "\\.cs$",
    "\\.c$",
    "\\.cpp$",
    "\\.h$",
    "\\.rs$",
    "\\.swift$",
    "\\.kt$",
    "\\.scala$",
    "\\.yml$",
    "\\.yaml$",
    "\\.json$",
    "\\.toml$",
    "\\.xml$",
    "\\.properties$",
    "\\.env.*$",
    "\\.cfg$",
    "\\.conf$",
    "\\.ini$",
    "\\.tf$",
    "\\.hcl$",
    "\\.sh$",
    "\\.bash$",
    "\\.zsh$",
    "\\.ps1$",
    "\\.bat$",
    "\\.cmd$",
    "\\.dockerfile$",
    "Dockerfile.*",
    "docker-compose.*",
    "\\.sql$",
    "\\.md$",
    "\\.txt$",
]

# Regex patterns for file paths to exclude
exclude-paths = [
    "vendor/",
    "node_modules/",
    "\\.min\\.js$",
    "\\.min\\.css$",
    "go\\.sum$",
    "package-lock\\.json$",
    "yarn\\.lock$",
    "Gemfile\\.lock$",
    "composer\\.lock$",
    "\\.map$",
    "test/fixtures/",
    "testdata/",
    "__test__/",
    "tests/",
    "\\.git/",
    "\\.svn/",
    "\\.hg/",
]

# =============================================================================
# Detectors
# =============================================================================
[[scan.detectors]]
# Detector type to configure
type = "aws_access_key"
# Enable/disable this detector
enabled = true
# Custom entropy threshold (overrides global)
entropy = 0.5

[[scan.detectors]]
type = "aws_secret_access_key"
enabled = true

[[scan.detectors]]
type = "github_token"
enabled = true

[[scan.detectors]]
type = "generic_password"
enabled = true
entropy = 0.8

[[scan.detectors]]
type = "generic_api_key"
enabled = true
entropy = 0.7

# =============================================================================
# Custom Detectors (Regex-based, no Go code needed)
# =============================================================================
[[scan.custom_detectors]]
name = "internal-api-key"
pattern = "internal_key_[a-zA-Z0-9]{32,}"
keywords = ["internal_key"]
entropy = 0.6

[[scan.custom_detectors]]
name = "database-url"
pattern = "postgres://[^\\s]+:[^\\s]+@[^\\s]+"
keywords = ["postgres://", "postgresql://"]
entropy = 0.4

[[scan.custom_detectors]]
name = "jwt-token"
pattern = "eyJ[a-zA-Z0-9_-]*\\.eyJ[a-zA-Z0-9_-]*\\.[a-zA-Z0-9_-]*"
keywords = ["eyJ"]
entropy = 0.6

# =============================================================================
# Allowlists (False Positive Suppression)
# =============================================================================
[[scan.allowlists]]
description = "Test/example credentials"
paths = ["test/.*", "example/.*", "spec/.*", "fixture/.*", "testdata/.*"]
words = [
    "example",
    "test",
    "dummy",
    "placeholder",
    "xxx",
    "000",
    "sample",
    "lorem",
    "ipsum",
    "foo",
    "bar",
    "baz",
]

[[scan.allowlists]]
description = "Documentation examples"
paths = ["docs/.*", "README.*", "*.md"]
words = ["your-api-key", "YOUR_TOKEN", "REPLACE_ME"]

[[scan.allowlists]]
description = "Generated files"
paths = ["\\.generated\\.", "generated/", "_generated/"]

[[scan.allowlists]]
description = "Vendor code"
paths = ["vendor/.*"]

[[scan.allowlists]]
description = "Minified JS"
paths = ["\\.min\\.js$"]

# =============================================================================
# Output
# =============================================================================
[output]
# Output format: json, jsonl, sarif, csv, github-actions
format = "json"

# Include source context
context = true

# Verification settings
verification = true
only-verified = false
```

---

## 14. Real-World Examples (Contoso Pet Store)

### Scenario: Contoso Pet Store — Security Audit

Contoso Pet Store is an e-commerce platform with microservices architecture. The security team discovered an API key was accidentally committed. They need to audit all repositories.

### Step 1: Audit the Main Repository

```bash
# Clone the repository
git clone https://github.com/contoso/pet-store-api.git
cd pet-store-api

# Full scan with all result types
trufflehog git file://. \
    --json \
    --results verified,unverified \
    --context \
    > /tmp/audit-api.json

# Check findings
cat /tmp/audit-api.json | python3 -m json.tool | head -100
```

### Step 2: Identify All Exposed Credentials

```bash
# Count findings by type
cat /tmp/audit-api.json | jq -r '.DetectorName' | sort | uniq -c | sort -rn

# Output:
#  12 generic_api_key
#   8 aws_access_key
#   5 github_token
#   3 stripe_api_key
#   2 database_url

# List all verified secrets
cat /tmp/audit-api.json | jq -r 'select(.Verified == true) | "\(.DetectorName): \(.SourceMetadata.Git.file):\(.SourceMetadata.Git.line)"'
```

### Step 3: Scan All Microservice Repositories

```bash
#!/bin/bash
# audit-all-repos.sh

REPOS=(
    "contoso/pet-store-api"
    "contoso/pet-store-frontend"
    "contoso/pet-store-infra"
    "contoso/pet-store-payments"
    "contoso/pet-store-notifications"
    "contoso/pet-store-analytics"
)

TOKEN="${GITHUB_TOKEN}"
REPORT_DIR="/tmp/contoso-audit"
mkdir -p "$REPORT_DIR"

TOTAL_SECRETS=0

for repo in "${REPOS[@]}"; do
    echo "=== Scanning $repo ==="
    safe=$(echo "$repo" | tr '/' '_')
    
    trufflehog github \
        --repo "https://github.com/$repo" \
        --token "$TOKEN" \
        --results verified,unverified \
        --json \
        --fail \
        > "$REPORT_DIR/$safe.json" 2>&1
    
    count=$(cat "$REPORT_DIR/$safe.json" | wc -l)
    TOTAL_SECRETS=$((TOTAL_SECRETS + count))
    
    echo "  Found: $count findings"
done

echo ""
echo "=== SUMMARY ==="
echo "Total findings across ${#REPOS[@]} repos: $TOTAL_SECRETS"
echo "Report saved to: $REPORT_DIR"
```

### Step 4: Create Pre-commit Prevention

```bash
# For each repository, add pre-commit hook
cd pet-store-api

cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.13
    hooks:
      - id: trufflehog
        args: ['--only-verified', '--fail']
EOF

git add .pre-commit-config.yaml
git commit -m "Add TruffleHog pre-commit hook for secret prevention"
```

### Step 5: CI/CD Pipeline Integration

```yaml
# .github/workflows/secret-scan.yml
name: Secret Scanning

on:
  push:
    branches: [main, develop, release/*]
  pull_request:
    branches: [main]

permissions:
  contents: read
  security-events: write

jobs:
  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout with full history
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run TruffleHog
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified --fail --sarif --output sarif.results

      - name: Upload to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: sarif.results

      - name: Upload to S3 for Compliance
        if: always()
        run: |
          aws s3 cp sarif.results \
            s3://contoso-security-reports/secrets/$(date +%Y%m%d)/${{ github.repository }}.sarif
```

### Step 6: Create Custom Detector for Contoso API Keys

```go
package contoso

import (
    "context"
    "regexp"
    
    "github.com/trufflesecurity/trufflehog/v3/pkg/detectors"
)

type ContosoAPIKey struct{}

func (d ContosoAPIKey) Keywords() []string {
    return []string{"contoso_", "CONTOSO_API"}
}

var contosoKeyPattern = regexp.MustCompile(`contoso_[a-zA-Z0-9]{40}`)

func (d ContosoAPIKey) FromData(ctx context.Context, verify bool, data []byte) ([]detectors.DetectorResult, error) {
    matches := contosoKeyPattern.FindAll(data, -1)
    results := []detectors.DetectorResult{}
    
    for _, match := range matches {
        result := detectors.DetectorResult{
            Secret:        string(match),
            DetectorName:  "contoso-api-key",
            DetectorID:    "contoso-api-key",
            Verified:      false,
        }
        
        if verify {
            result.Verified = verifyContosoKey(ctx, string(match))
        }
        
        results = append(results, result)
    }
    return results, nil
}
```

### Step 7: Automated Rotation Script

```python
#!/usr/bin/env python3
"""Automated credential rotation based on TruffleHog findings."""
import json
import subprocess
import boto3
import requests
import os

def rotate_aws_key(access_key_id):
    """Rotate an AWS access key."""
    iam = boto3.client('iam')
    
    # Create new key
    new_key = iam.create_access_key(UserName='deploy-user')
    
    # Update GitHub Actions secrets
    gh_token = os.environ['GITHUB_TOKEN']
    repo = "contoso/pet-store-api"
    
    requests.put(
        f"https://api.github.com/repos/{repo}/actions/secrets/AWS_ACCESS_KEY_ID",
        headers={"Authorization": f"token {gh_token}"},
        json={"encrypted_value": encrypt_secret(new_key['AccessKey']['AccessKeyId'])}
    )
    
    # Deactivate old key (don't delete yet — audit first)
    iam.update_access_key(
        UserName='deploy-user',
        AccessKeyId=access_key_id,
        Status='Inactive'
    )
    
    print(f"Rotated key: {access_key_id} -> {new_key['AccessKey']['AccessKeyId']}")

def main():
    # Read TruffleHog findings
    with open('/tmp/audit-api.json') as f:
        findings = [json.loads(line) for line in f if line.strip()]
    
    # Rotate verified AWS keys
    for finding in findings:
        if finding['DetectorName'] == 'aws_access_key' and finding['Verified']:
            key_id = finding['Secret'][:12]  # AWS key IDs are 12 chars
            rotate_aws_key(key_id)

if __name__ == '__main__':
    main()
```

### Step 8: Compliance Report Generation

```bash
#!/bin/bash
# compliance-report.sh — Generate compliance report from TruffleHog results

REPORT_DATE=$(date +%Y%m%d)
REPORT_FILE="/tmp/contoso-compliance-$REPORT_DATE.md"

cat > "$REPORT_FILE" << 'HEADER'
# Contoso Pet Store — Secret Scanning Compliance Report

## Executive Summary

This report summarizes the findings from TruffleHog secret scanning
across all Contoso Pet Store repositories.
HEADER

echo "Date: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Scan all repos and aggregate
REPOS=("pet-store-api" "pet-store-frontend" "pet-store-infra")
TOTAL_FOUND=0
TOTAL_VERIFIED=0

for repo in "${REPOS[@]}"; do
    echo "Scanning contoso/$repo..."
    
    FINDINGS=$(trufflehog github \
        --repo "https://github.com/contoso/$repo" \
        --results verified,unverified \
        --json 2>/dev/null | wc -l)
    
    VERIFIED=$(trufflehog github \
        --repo "https://github.com/contoso/$repo" \
        --only-verified \
        --json 2>/dev/null | wc -l)
    
    TOTAL_FOUND=$((TOTAL_FOUND + FINDINGS))
    TOTAL_VERIFIED=$((TOTAL_VERIFIED + VERIFIED))
    
    echo "## $repo" >> "$REPORT_FILE"
    echo "- Total findings: $FINDINGS" >> "$REPORT_FILE"
    echo "- Verified (live) secrets: $VERIFIED" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
## Summary

| Metric | Count |
|--------|-------|
| Total findings | $TOTAL_FOUND |
| Verified (live) secrets | $TOTAL_VERIFIED |
| Repositories scanned | ${#REPOS[@]} |
| Scan date | $(date) |

## Remediation Status

- [ ] All verified secrets rotated
- [ ] Pre-commit hooks installed on all repos
- [ ] CI/CD pipeline updated with TruffleHog
- [ ] Historical Git history cleaned (if applicable)
- [ ] Team trained on secret management

## Compliance Mapping

| Control | Status |
|---------|--------|
| SOC 2 CC6.1 (Logical Access) | Compliant |
| PCI DSS 8.2.1 (Unique IDs) | Needs Review |
| HIPAA §164.312(a)(1) | Compliant |
| ISO 27001 A.9.2 | Compliant |
EOF

echo "Report generated: $REPORT_FILE"
```

---

## 15. Further Reading

### Official Resources

- [TruffleHog GitHub Repository](https://github.com/trufflesecurity/trufflehog)
- [TruffleHog Documentation](https://trufflesecurity.com/trufflehog)
- [Truffle Security Blog](https://trufflesecurity.com/blog)
- [Detector List](https://github.com/trufflesecurity/trufflehog/tree/main/pkg/detectors)

### Related Tools

- [Gitleaks](https://github.com/gitleaks/gitleaks) — Git secret scanner
- [detect-secrets](https://github.com/Yelp/detect-secrets) — Yelp's secret scanner
- [git-secrets](https://github.com/awslabs/git-secrets) — AWS's pre-commit hook
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) — Remove secrets from Git history

### Security Articles

- "Secret Scanning in CI/CD" — OWASP DevSecOps Guideline
- "Credential Management Best Practices" — NIST SP 800-63
- "Preventing Secret Leakage" — SANS Institute
- "Git Security Best Practices" — GitHub Security Lab

### Community

- [Truffle Security Discord](https://discord.gg/trufflesecurity)
- [GitHub Discussions](https://github.com/trufflesecurity/trufflehog/discussions)
- [Stack Overflow: trufflehog tag](https://stackoverflow.com/questions/tagged/trufflehog)

### Books

- "Securing DevOps" by Julien Vehent
- "The DevOps Handbook" by Gene Kim et al.
- "Application Security in the ISO 27001 Environment" by Dan Bauman

---

*Last updated: 2026-09-03*
*TruffleHog version: v3.82.x*
