# Gitleaks Complete Guide

## Table of Contents

1. [What Is Gitleaks?](#1-what-is-gitleaks)
2. [Why Use Gitleaks?](#2-why-use-gitleaks)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Writing Custom Rules](#7-writing-custom-rules)
8. [Integration](#8-integration)
9. [Security Hardening](#9-security-hardening)
10. [Troubleshooting](#10-troubleshooting)
11. [Tips & Best Practices](#11-tips--best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

## 1. What Is Gitleaks?

### Plain English Explanation

Gitleaks is a tool that scans your Git repository for secrets — passwords, API keys, tokens, private keys, and other sensitive data that should never be committed to version control. It examines every commit, every file, and every line to find hardcoded credentials before they reach production or public repositories.

Think of it as a security guard for your Git history. Even if you delete a secret from your code, it still exists in Git history forever. Gitleaks finds these secrets across all commits — past and present.

### Why It Exists

Developers accidentally commit secrets every day:
- API keys pasted into config files
- Database passwords hardcoded in source
- Private keys committed with code
- Access tokens left in environment files
- Credentials in CI/CD pipeline files

Once committed, these secrets are:
- **Permanent**: Git history is immutable (without force-push and rewrite)
- **Accessible**: Anyone with repo access can see them
- **Exploitable**: Attackers scan public repos specifically for leaked secrets
- **Compliance violations**: PCI DSS, HIPAA, SOC 2 all require credential management

Gitleaks exists to catch these mistakes before they become breaches.

### Architecture

```
                  Gitleaks

  Git Parser ----> Regex Engine
                   Rules defined in .gitleaks.toml
  Reads:           Pattern matching on:
  - Commits        - File contents
  - Files          - Commit messages
  - Diffs          - Diffs
  - History        - Filenames
  Uses go-git
  (pure Go)

  Entropy         Output Formatter
  Checker
                 - Text
  Detects         - JSON
  random          - SARIF
  strings         - JUnit XML
  (tokens)        - CSV
```

### Gitleaks vs. Other Tools

| Feature | Gitleaks | TruffleHog | detect-secrets |
|---------|----------|------------|----------------|
| Speed | Very fast | Moderate | Slow |
| Written in | Go | Python/Go | Python |
| Git integration | Excellent | Good | Limited |
| Pre-commit hook | Yes | Yes | Yes |
| CI/CD support | Excellent | Good | Good |
| Custom rules | Yes (TOML) | Yes (JSON) | Yes (YAML) |
| Entropy detection | Yes | Yes | Yes |
| Free | Yes | Yes | Yes |
| Actively maintained | Yes | Yes | Yes |

---

## 2. Why Use Gitleaks?

### Real-World Breaches

- **Uber (2016)**: AWS credentials hardcoded in a GitHub repo. Attacker gained access to 57 million user records.
- **Samsung (2019)**: Private keys for Tizen OS committed to public GitHub. Exposed millions of smart TVs and phones.
- **Twitch (2021)**: Source code and streamer payout data leaked, partly via exposed Git repositories.

### When to Use Gitleaks

- **Pre-commit**: Catch secrets before they enter Git
- **CI/CD pipeline**: Block merges that contain secrets
- **Repository audit**: Scan entire Git history for existing secrets
- **Migration**: Scan repos before moving to public or shared infrastructure
- **Compliance**: Demonstrate proactive secret management for auditors
- **Incident response**: Quickly identify which repos contain leaked credentials

### What Happens Without It

- **Secrets accumulate in Git history**: Even if removed from HEAD, they exist in all previous commits
- **Attackers scan public repos**: Tools like git-all-secrets automatically scan GitHub for leaked credentials
- **Compliance failures**: Auditors will flag missing secret scanning as a control gap
- **Breach impact increases**: Leaked database credentials mean full data compromise
- **Recovery is expensive**: Rotating all credentials, notifying affected parties, and investigating scope costs millions

---

## 3. Installation

### Method 1: Go Install (Recommended)

```bash
go install github.com/gitleaks/gitleaks/v8@latest

# Verify
gitleaks version

# Install specific version
go install github.com/gitleaks/gitleaks/v8.18.1@latest
```

### Method 2: Binary Release

```bash
# Linux (x86_64)
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz
tar xzf gitleaks_8.18.1_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/

# macOS (ARM64/M1)
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_macos_arm64.tar.gz
tar xzf gitleaks_8.18.1_macos_arm64.tar.gz
sudo mv gitleaks /usr/local/bin/

# macOS (x86_64)
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_macos_x64.tar.gz
tar xzf gitleaks_8.18.1_macos_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

### Method 3: Docker

```bash
# Pull the image
docker pull ghcr.io/gitleaks/gitleaks:latest

# Scan current repo
docker run --rm \
  -v "$(pwd):/src" \
  ghcr.io/gitleaks/gitleaks:latest \
  gitleaks detect --source /src --verbose

# Scan staged changes (pre-commit mode)
docker run --rm \
  -v "$(pwd):/src" \
  ghcr.io/gitleaks/gitleaks:latest \
  gitleaks protect --source /src --staged
```

### Method 4: Homebrew (macOS)

```bash
brew install gitleaks

# Verify
gitleaks version
```

### Method 5: apt (Debian/Ubuntu)

```bash
# Add Gitleaks repository
echo "deb [signed-by=/usr/share/keyrings/gitleaks-archive-keyring.gpg] https://gitleaks.io/repos/debian stable main" | \
  sudo tee /etc/apt/sources.list.d/gitleaks.list

# Import GPG key
wget -qO - https://gitleaks.io/repos/debian/pubkey.gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/gitleaks-archive-keyring.gpg

# Install
sudo apt update
sudo apt install gitleaks

# Verify
gitleaks version
```

### Method 6: From Source

```bash
# Clone repository
git clone https://github.com/gitleaks/gitleaks.git
cd gitleaks

# Build
go build -o gitleaks .

# Verify
./gitleaks version
```

### First-Time Setup

```bash
# Check version
gitleaks version

# Run on your repo
cd /path/to/your/repo
gitleaks detect

# Or with verbose output
gitleaks detect --verbose
```

---

## 4. Configuration

### .gitleaks.toml (Primary Config)

```toml
# .gitleaks.toml — Project-level configuration

# Title for the report
title = "Gitleaks Scan Results"

# Set to true to use default rules (built-in rules)
# If false, only rules defined below are used
useDefault = true

# Paths to ignore
[allowlist]
  description = "Global allowlist"
  # Regex patterns for paths to ignore
  paths = [
    '''vendor/''',
    '''node_modules/''',
    '''\.env\.example$''',
    '''test/fixtures/''',
    '''testdata/''',
  ]
  # Regex patterns for specific secrets to ignore
  secrets = [
    '''(?i)test[_-]?secret''',
    '''(?i)example[_-]?key''',
    '''PLACEHOLDER''',
  ]
  # Commits to ignore
  commits = [
    "commit-hash-to-ignore",
    "another-commit-hash",
  ]

# Custom rules
[[rules]]
  id = "custom-api-key"
  description = "Custom API Key Pattern"
  regex = '''(?i)api[_-]?key\s*[:=]\s*['"]([a-zA-Z0-9]{32,64})['"]'''
  tags = ["api", "key"]

  # Entropy threshold (0.0-1.0)
  # Higher = more selective (fewer false positives)
  # Lower = more matches (more false positives)
  entropy = 3.5

  # Path pattern (only scan matching files)
  path = '''(?i)(config|settings|\.env)'''

  # Keywords that indicate a secret
  keywords = [
    "api_key",
    "apikey",
    "api-key",
    "API_KEY",
  ]

[[rules]]
  id = "aws-access-key"
  description = "AWS Access Key ID"
  regex = '''(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
  tags = ["aws", "key"]

[[rules]]
  id = "private-key"
  description = "Private Key"
  regex = '''-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----'''
  tags = ["key", "private"]

[[rules]]
  id = "password-in-url"
  description = "Password embedded in URL"
  regex = '''(?:ftp|http|https)://[^:/\s]+:([^@/\s]+)@'''
  tags = ["password", "url"]
```

### .gitleaks.toml Complete Reference

```toml
# ──── Global Settings ────
title = "Report Title"              # Report title
useDefault = true                   # Use built-in rules
maxTargetMegabytes = 10             # Max file size (MB)
exitCode = 1                        # Exit code on findings (0=success, 1=findings)
reportFormat = "json"               # Output format: json|csv|junit|sarif

# ──── Allowlist (Global) ────
[allowlist]
  description = "Global allowlist"
  paths = ['''regex''']             # Paths to skip
  secrets = ['''regex''']           # Secrets to skip
  commits = ["hash"]                # Commits to skip
  files = ['''regex''']             # Files to skip (by name)

# ──── Rules ────
[[rules]]
  id = "unique-id"                  # Required: unique identifier
  description = "Description"       # Human-readable description
  regex = '''pattern'''             # Regex pattern to match
  entropy = 3.5                     # Entropy threshold (0-1)
  path = '''regex'''                # Only scan matching file paths
  tags = ["tag1", "tag2"]          # Tags for categorization
  keywords = ["keyword1"]          # Keywords for fast filtering
  
  # Allowlist for this specific rule
  [[rules.allowlist]]
    description = "Rule allowlist"
    paths = ['''regex''']
    secrets = ['''regex''']
    commits = ["hash"]
```

### Configuration Hierarchy

```
1. Command line flags          (highest priority)
2. .gitleaks.toml              (project-level)
3. ~/.gitleaks.toml            (user-level)
4. Default built-in rules      (lowest priority)
```

### Environment Variables

```bash
# Gitleaks-specific environment variables
GITLEAKS_CONFIG="/path/to/.gitleaks.toml"
GITLEAKS_ENABLE_RULES="rule1,rule2"
GITLEAKS_DISABLE_RULES="rule3,rule4"
GITLEAKS_LOG_LEVEL="debug"        # debug|info|warn|error
```

---

## 5. Core Concepts

### How Scanning Works

Gitleaks operates in two modes:

**Detect Mode** (default):
Scans the entire Git repository — all commits, all files, all history.

```
Git History
    |
    v
Commit 1 --> Commit 2 --> Commit 3 (HEAD)
    |            |            |
    v            v            v
  files        files        files
  diffs        diffs        diffs
    |            |            |
    v            v            v
Regex Matching Engine
  1. Apply keyword pre-filter
  2. Run regex patterns
  3. Check entropy threshold
  4. Check allowlists
  5. Report findings
```

**Protect Mode** (pre-commit):
Scans only staged changes (like pre-commit hooks).

```
Staged Changes
    |
    v
Staged Diff Analysis
  1. Get staged files (git diff --cached)
  2. For each added/modified line:
     a. Apply keyword pre-filter
     b. Run regex patterns
     c. Check entropy
     d. Check allowlists
     e. Report findings
```

### Entropy

Entropy measures the randomness of a string. Real secrets have high entropy because they are randomly generated.

- `"password123"` — Low entropy (predictable)
- `"*******"` — High entropy (random)
- `"AAAA-BBBB-CCCC-DDDD"` — Medium entropy (structured but unique)

Entropy is calculated using Shannon entropy:

```
H = -SUM( p(x) * log2(p(x)) )

Where:
- p(x) = probability of character x
- Higher H = more random = more likely a real secret
```

### Regex Patterns

Gitleaks uses Go's RE2 regex engine. Key patterns:

| Pattern | Meaning |
|---------|---------|
| `'''...'''` | Raw string (no escaping needed) |
| `(?i)` | Case-insensitive |
| `[A-Z0-9]` | Character class |
| `{16,}` | Quantifier (16 or more) |
| `(?:...)` | Non-capturing group |
| `(?=...)` | Lookahead |
| `(?!...)` | Negative lookahead |

### Keywords

Keywords are fast pre-filters. Before running expensive regex, Gitleaks checks if the line contains any keyword. If no keyword matches, the regex is not run — dramatically improving speed.

```toml
keywords = [
  "api_key",      # Match lines containing "api_key"
  "apikey",       # Match lines containing "apikey"
  "api-key",      # Match lines containing "api-key"
  "API_KEY",      # Match lines containing "API_KEY"
]
```

### Findings

Each finding includes:
- **Rule ID**: Which rule matched
- **Secret**: The actual secret found
- **Start line**: Line number in the file
- **End line**: Line number in the file
- **Commit**: Which commit contains the secret
- **Author**: Who committed the secret
- **Date**: When it was committed
- **File path**: Which file contains the secret
- **Entropy**: Randomness score of the secret

---

## 6. Usage Guide

### Step-by-Step: First Scan

**1. Install Gitleaks:**
```bash
go install github.com/gitleaks/gitleaks/v8@latest
```

**2. Navigate to your repo:**
```bash
cd /path/to/your/repo
```

**3. Run detect:**
```bash
gitleaks detect --verbose
```

**4. Review results:**
```
Finding:     Found *******
Rule:        aws-access-key
Entropy:     4.2
File:        config/api.py
Line:        15
Commit:      abc123def456
Author:      John Doe
Date:        2024-01-15
Message:     Add API configuration
```

**5. Fix and protect:**
```bash
# Add to .gitleaks.toml allowlist (if false positive)
# Or remove the secret and rotate it
# Then commit with Gitleaks pre-commit hook
```

### Scanning Entire History

```bash
# Scan all commits
gitleaks detect

# Scan from specific commit
gitleaks detect --log-opts="--since=2024-01-01"

# Scan specific branch
gitleaks detect --log-opts="main..feature-branch"

# Scan uncommitted changes
gitleaks detect --unstaged

# Scan staged changes only (pre-commit mode)
gitleaks protect --staged
```

### Output Formats

```bash
# JSON output
gitleaks detect --report-format json --report-path results.json

# SARIF output (for GitHub)
gitleaks detect --report-format sarif --report-path results.sarif

# JUnit XML (for CI)
gitleaks detect --report-format junit --report-path results.xml

# CSV output
gitleaks detect --report-format csv --report-path results.csv

# Text output (default, no report file needed)
gitleaks detect --report-format text
```

### Pre-commit Hook

```bash
# Install pre-commit hook
gitleaks protect --staged

# Or using pre-commit framework
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.1
    hooks:
      - id: gitleaks
EOF

# Install pre-commit
pip install pre-commit
pre-commit install
```

### CI/CD Usage

```bash
# CI mode (exit code 1 if findings)
gitleaks detect --source . --report-format sarif --report-path results.sarif

# With specific exit code
gitleaks detect --exit-code 1

# Redact secrets in output
gitleaks detect --redact
```

### Scanning Specific Files

```bash
# Scan specific file
gitleaks detect --source /path/to/file.py

# Scan specific directory
gitleaks detect --source /path/to/dir/

# Scan with specific config
gitleaks detect --config /path/to/.gitleaks.toml

# Scan with verbose output
gitleaks detect --verbose

# Scan with no banner
gitleaks detect --no-banner
```

### Verbose vs Normal Mode

```bash
# Normal mode (default)
gitleaks detect

# Verbose mode (shows more detail)
gitleaks detect --verbose

# Debug mode
GITLEAKS_LOG_LEVEL=debug gitleaks detect --verbose

# Quiet mode (minimal output)
gitleaks detect --quiet
```

### Managing False Positives

```bash
# Add to allowlist in .gitleaks.toml
[[rules.allowlist]]
  description = "Known test secret"
  secrets = ['''test_secret_123''']

# Or use command-line flag
gitleaks detect --allowlist-path /path/to/allowlist.txt

# Mark as false positive in report
gitleaks detect --report-format json --report-path results.json
# Then filter with jq
jq '.Results[] | select(.FalsePositive == false)' results.json
```

---

## 7. Writing Custom Rules

### Rule Structure

```toml
[[rules]]
  id = "rule-unique-id"              # Required: unique identifier
  description = "Description"       # Human-readable description
  regex = '''pattern'''             # Regex pattern to match
  entropy = 3.5                     # Entropy threshold (0-1)
  path = '''regex'''                # Only scan matching file paths
  tags = ["tag1", "tag2"]          # Tags for categorization
  keywords = ["keyword1"]          # Keywords for fast filtering
  
  # Allowlist for this specific rule
  [[rules.allowlist]]
    description = "Rule allowlist"
    paths = ['''regex''']
    secrets = ['''regex''']
    commits = ["hash"]
```

### Rule Writing Workflow

1. **Identify the pattern**: What does the secret look like?
2. **Write the regex**: Translate to Go regex syntax
3. **Set entropy**: How random is the real secret?
4. **Add keywords**: What words appear near the secret?
5. **Test the rule**: Does it match what you expect?
6. **Add exclusions**: Prevent false positives
7. **Document the rule**: Description and tags

### Example 1: AWS Access Key

```toml
[[rules]]
  id = "aws-access-key"
  description = "AWS Access Key ID"
  regex = '''(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
  tags = ["aws", "key"]
  keywords = ["AKIA", "AGPA", "AIDA", "AROA", "AIPA", "ANPA", "ANVA", "ASIA"]
```

### Example 2: Private Key

```toml
[[rules]]
  id = "private-key"
  description = "Private Key"
  regex = '''-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----'''
  tags = ["key", "private"]
  keywords = ["BEGIN PRIVATE KEY", "BEGIN RSA PRIVATE KEY", "BEGIN EC PRIVATE KEY", "BEGIN DSA PRIVATE KEY"]
```

### Example 3: Generic Secret Assignment

```toml
[[rules]]
  id = "generic-secret"
  description = "Generic Secret Assignment"
  regex = '''(?i)(secret|token|password|credential)\s*[:=]\s*['"]([^'"]{8,})['"]'''
  entropy = 4.0
  tags = ["generic", "secret"]
  keywords = ["secret", "token", "password", "credential"]
```

### Example 4: Database Connection String

```toml
[[rules]]
  id = "database-url"
  description = "Database Connection String"
  regex = '''(?i)(mysql|postgres|postgresql|mongodb|redis)://[^:/\s]+:[^@/\s]+@[^\s]+'''
  entropy = 3.5
  tags = ["database", "url"]
  keywords = ["mysql", "postgres", "postgresql", "mongodb", "redis"]
```

### Example 5: Slack Token

```toml
[[rules]]
  id = "slack-token"
  description = "Slack Bot/User Token"
  regex = '''xox[baprs]-[0-9a-zA-Z\-]+'''
  tags = ["slack", "token"]
  keywords = ["xoxb-", "xoxp-", "xoxa-", "xoxr-"]
```

### Example 6: GitHub Token

```toml
[[rules]]
  id = "github-token"
  description = "GitHub Personal Access Token"
  regex = '''ghp_[0-9a-zA-Z]{36}'''
  tags = ["github", "token"]
  keywords = ["ghp_"]

[[rules]]
  id = "github-fine-grained-pat"
  description = "GitHub Fine-Grained PAT"
  regex = '''github_pat_[0-9a-zA-Z]{22}_[0-9a-zA-Z]{59}'''
  tags = ["github", "token"]
  keywords = ["github_pat_"]
```

### Example 7: Stripe Key

```toml
[[rules]]
  id = "stripe-secret-key"
  description = "Stripe Secret Key"
  regex = '''sk_live_[0-9a-zA-Z]{24,}'''
  tags = ["stripe", "key"]
  keywords = ["sk_live_"]

[[rules]]
  id = "stripe-publishable-key"
  description = "Stripe Publishable Key"
  regex = '''pk_live_[0-9a-zA-Z]{24,}'''
  tags = ["stripe", "key"]
  keywords = ["pk_live_"]
```

### Example 8: Generic High-Entropy Token

```toml
[[rules]]
  id = "high-entropy-token"
  description = "High-Entropy Token Assignment"
  regex = '''(?i)(token|key|secret|api_key)\s*[:=]\s*['"]([a-zA-Z0-9+/=_\-]{32,})['"]'''
  entropy = 4.5
  tags = ["generic", "token"]
  keywords = ["token", "key", "secret", "api_key"]
```

### Testing Custom Rules

```bash
# Validate config
gitleaks detect --config .gitleaks.toml --verbose

# Test on specific file
echo "api_key = '*******'" > test.txt
gitleaks detect --source test.txt --config .gitleaks.toml --verbose

# Test on specific directory
gitleaks detect --source test-data/ --config .gitleaks.toml --verbose

# Dry-run (no exit code on findings)
gitleaks detect --config .gitleaks.toml --exit-code 0
```

### Pattern Cookbook

**Match key-value pairs:**
```regex
(?i)(api_key|apikey|api-key)\s*[:=]\s*['"]([^'"]+)['"]
```

**Match URL with credentials:**
```regex
(?:ftp|http|https)://[^:/\s]+:([^@/\s]+)@[^/\s]+
```

**Match PEM header:**
```regex
-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----
```

**Match AWS key prefix:**
```regex
(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}
```

**Match JWT:**
```regex
eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_.+/=
]*

**Match hex string (token):**
```regex
(?i)(?:token|key|secret)\s*[:=]\s*['"]([0-9a-f]{32,})['"]
```

**Match base64 string:**
```regex
(?i)(?:token|key|secret)\s*[:=]\s*['"]([A-Za-z0-9+/]{32,}={0,2})['"]
```

---

## 8. Integration

### GitHub Actions

```yaml
# .github/workflows/gitleaks.yml
name: Gitleaks
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Gitleaks scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}  # Optional for pro features

      # Or run directly
      - name: Gitleaks scan (direct)
        uses: zricethezav/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Upload SARIF for GitHub Security
      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - test
  - security

gitleaks:
  stage: security
  image: ghcr.io/gitleaks/gitleaks:latest
  script:
    - gitleaks detect --source . --report-format sarif --report-path gl-secret-detection-report.sarif
  artifacts:
    reports:
      secret_detection: gl-secret-detection-report.sarif
  only:
    - main
    - merge_requests
```

### Pre-commit Framework

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.1
    hooks:
      - id: gitleaks
        name: Gitleaks Secret Detection
        stages: [commit, push]
```

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files

# Run on specific files
pre-commit run --files src/api.py src/config.py
```

### ArgoCD Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gitleaks-scanner
spec:
  project: default
  source:
    repoURL: https://github.com/zricethezav/gitleaks.git
    path: .
    targetRevision: v8.18.0
    directory:
      recurse: false
  destination:
    server: https://kubernetes.default.svc
    namespace: security
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Gitleaks Scan') {
            steps {
                sh '''
                    gitleaks detect \
                      --source . \
                      --report-format sarif \
                      --report-path gitleaks-results.sarif \
                      --verbose
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'gitleaks-results.sarif'
                    recordIssues tools: [sarif(pattern: 'gitleaks-results.sarif')]
                }
            }
        }
    }
}
```

### Docker Compose for CI

```yaml
# docker-compose.gitleaks.yml
version: '3.8'
services:
  gitleaks:
    image: ghcr.io/gitleaks/gitleaks:latest
    volumes:
      - .:/src
    command: >
      gitleaks detect
      --source /src
      --report-format sarif
      --report-path /src/gitleaks-results.sarif
      --verbose
```

### VS Code Integration

```json
// .vscode/settings.json
{
  "gitleaks.enableTelemetry": false,
  "gitleaks.path": "/usr/local/bin/gitleaks"
}
```

### Maven Integration

```xml
<!-- pom.xml -->
<plugin>
    <groupId>com.github.zricethezav</groupId>
    <artifactId>gitleaks-maven-plugin</artifactId>
    <version>1.0.0</version>
    <executions>
        <execution>
            <phase>verify</phase>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

---

## 9. Security Hardening

### Securing Gitleaks in CI/CD

```yaml
# GitHub Actions — restricted permissions
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Protecting Secrets

```bash
# Never commit Gitleaks config with real secrets
# Use .gitignore to exclude
echo ".env" >> .gitignore
echo "*.key" >> .gitignore

# Scan before committing
gitleaks protect --staged

# Rotate any secrets found
# 1. Remove from code
# 2. Remove from Git history (if necessary)
# 3. Rotate the secret in the provider
# 4. Add to allowlist if false positive
```

### Network Security

```bash
# If scanning in restricted environments
# Use --no-git to avoid Git operations
gitleaks detect --no-git --config .gitleaks.toml

# Proxy configuration
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
gitleaks detect
```

### Audit Logging

```bash
# Enable verbose logging for audit trail
gitleaks detect --verbose 2>&1 | tee gitleaks-audit.log

# JSON output for machine parsing
gitleaks detect --report-format json --report-path gitleaks-results.json
```

### Git History Cleanup

```bash
# If secrets are found in history, options:
# 1. Rotate the secret (recommended)
# 2. Rewrite Git history (dangerous, affects all collaborators)

# Using git-filter-repo (recommended over BFG)
pip install git-filter-repo
git filter-repo --path-glob '*.env' --invert-paths

# Or using BFG Repo-Cleaner
java -jar bfg.jar --delete-files '*.env' repo.git
git reflog expire --expire=now --all && git gc --prune=now
```

---

## 10. Troubleshooting

### Issue 1: "no git repo found" error

**Cause:** Gitleaks not run from inside a Git repository.

**Fix:**
```bash
# Ensure you are in a Git repo
git status

# Or specify source
gitleaks detect --source /path/to/repo
```

### Issue 2: Too many false positives

**Fix:**
```toml
# Add to allowlist
[allowlist]
  paths = ['''test/''', '''example/''']
  secrets = ['''PLACEHOLDER''', '''test_secret''']

# Or increase entropy threshold
[[rules]]
  entropy = 4.5  # Higher = fewer matches
```

### Issue 3: Gitleaks is slow

**Fix:**
```bash
# Limit scan to recent commits
gitleaks detect --log-opts="--since=2024-01-01"

# Scan specific files
gitleaks detect --source src/config.py

# Use keywords for fast filtering
# In .gitleaks.toml, ensure keywords are set
```

### Issue 4: "rule already exists" error

**Fix:**
```bash
# Find duplicate rule IDs
grep -n "id = " .gitleaks.toml | sort -t'"' -k2

# Rename duplicate IDs to be unique
```

### Issue 5: Custom rules not matching

**Debug steps:**
```bash
# Test with verbose output
gitleaks detect --verbose

# Test on specific file
echo "api_key = '*******'" > test.txt
gitleaks detect --source test.txt --config .gitleaks.toml --verbose

# Check regex syntax (use online regex tester)
# Verify entropy threshold is appropriate
```

### Issue 6: Gitleaks not finding known secrets

**Fix:**
```bash
# Check if path is excluded
gitleaks detect --verbose 2>&1 | grep "excluded"

# Check if commit is in allowlist
gitleaks detect --verbose 2>&1 | grep "allowlist"

# Check if file is too large
gitleaks detect --verbose 2>&1 | grep "too large"
```

### Issue 7: CI build fails on Gitleaks findings

**Fix:**
```bash
# Use --exit-code to control exit behavior
gitleaks detect --exit-code 1  # Exit 1 if findings
gitleaks detect --exit-code 0  # Always exit 0 (informational)

# Or use allowlist for known false positives
```

### Issue 8: Docker permission denied

**Fix:**
```bash
# Run with correct user
docker run --rm \
  -v "$(pwd):/src" \
  -u "$(id -u):$(id -g)" \
  ghcr.io/gitleaks/gitleaks:latest \
  gitleaks detect --source /src
```

### Issue 9: Entropy threshold too strict

**Fix:**
```toml
# Lower entropy threshold to match more
[[rules]]
  entropy = 2.5  # Lower = more matches

# Or remove entropy check entirely (not recommended)
[[rules]]
  entropy = 0.0
```

### Issue 10: Regex too broad

**Fix:**
```toml
# Add path restriction
[[rules]]
  path = '''(?i)(config|settings|\.env)'''

# Add keywords for context
[[rules]]
  keywords = ["api_key", "secret_key"]

# Increase entropy
[[rules]]
  entropy = 4.0
```

### Issue 11: "unknown option" error

**Fix:**
```bash
# Check available options
gitleaks detect --help

# Ensure correct flag syntax
gitleaks detect --source . --verbose
# Not: gitleaks detect --source=. --verbose
```

### Issue 12: Exit code not working as expected

**Fix:**
```bash
# Exit code 0 = no findings (success)
# Exit code 1 = findings detected
# Exit code 2 = scan error

# Force exit code 0 even with findings
gitleaks detect --exit-code 0

# Force exit code 1 on any error
gitleaks detect --exit-code 1
```

### Issue 13: Report file not created

**Fix:**
```bash
# Ensure report directory exists
mkdir -p reports/

# Use absolute path
gitleaks detect --report-format json --report-path /absolute/path/results.json

# Check permissions
ls -la reports/
```

### Issue 14: Gitleaks not scanning specific file types

**Fix:**
```bash
# Check if file is in exclude list
gitleaks detect --verbose 2>&1 | grep "skipped"

# Ensure file is tracked by Git
git ls-files | grep "filename"

# Or scan untracked files
gitleaks detect --unstaged
```

### Issue 15: Memory issues on large repos

**Fix:**
```bash
# Limit commit history
gitleaks detect --log-opts="--since=2024-01-01"

# Scan specific directory
gitleaks detect --source src/

# Use --no-git to avoid loading full history
gitleaks detect --no-git --source src/
```

---

## 11. Tips & Best Practices

1. **Run pre-commit**: Catch secrets before they enter Git.
2. **Run in CI/CD**: Block merges that contain secrets.
3. **Scan entire history**: Don't just scan HEAD — scan all commits.
4. **Use entropy**: Real secrets have high entropy (4.0+).
5. **Add keywords**: Fast pre-filtering improves speed dramatically.
6. **Allowlist carefully**: Only allowlist known false positives.
7. **Rotate found secrets**: Don't just remove from code — rotate them.
8. **Use SARIF for GitHub**: Enables GitHub Security tab integration.
9. **Redact output**: Use --redact to prevent leaking secrets in logs.
10. **Scan before migration**: Check repos before making them public.
11. **Combine with other tools**: Gitleaks + Semgrep + SonarQube = comprehensive security.
12. **Document rules**: Add descriptions and tags to every rule.
13. **Test custom rules**: Validate on known test data before deploying.
14. **Keep config in Git**: Version control your .gitleaks.toml.
15. **Use global config**: ~/.gitleaks.toml for organization-wide defaults.
16. **Monitor entropy**: Adjust thresholds based on false positive rates.
17. **Use path restrictions**: Only scan files that could contain secrets.
18. **Review findings regularly**: Triage and address findings promptly.
19. **Train developers**: Explain why secrets in Git are dangerous.
20. **Automate rotation**: When a secret is found, rotate it automatically.

---

## 12. Command Reference

### Basic Commands

```bash
# Scan entire repo
gitleaks detect

# Scan with specific config
gitleaks detect --config .gitleaks.toml

# Scan specific source
gitleaks detect --source /path/to/repo

# Scan staged changes
gitleaks protect --staged
```

### Output Options

```bash
# Text output (default)
gitleaks detect --report-format text

# JSON output
gitleaks detect --report-format json --report-path results.json

# SARIF output
gitleaks detect --report-format sarif --report-path results.sarif

# JUnit XML
gitleaks detect --report-format junit --report-path results.xml

# CSV output
gitleaks detect --report-format csv --report-path results.csv
```

### Filtering Options

```bash
# Scan specific file
gitleaks detect --source file.py

# Scan specific directory
gitleaks detect --source dir/

# Scan from specific commit
gitleaks detect --log-opts="--since=2024-01-01"

# Scan specific branch
gitleaks detect --log-opts="main..feature"

# Scan uncommitted changes
gitleaks detect --unstaged
```

### Output Control

```bash
# Verbose output
gitleaks detect --verbose

# Quiet output
gitleaks detect --quiet

# No banner
gitleaks detect --no-banner

# Redact secrets
gitleaks detect --redact

# Debug mode
GITLEAKS_LOG_LEVEL=debug gitleaks detect --verbose
```

### Exit Code Control

```bash
# Exit code 1 if findings (default)
gitleaks detect --exit-code 1

# Always exit 0 (informational)
gitleaks detect --exit-code 0

# Exit code 2 on error
gitleaks detect --exit-code 2
```

### Configuration Options

```bash
# Specify config file
gitleaks detect --config /path/to/.gitleaks.toml

# Enable specific rules
GITLEAKS_ENABLE_RULES="rule1,rule2" gitleaks detect

# Disable specific rules
GITLEAKS_DISABLE_RULES="rule3,rule4" gitleaks detect

# Config path environment variable
GITLEAKS_CONFIG="/path/to/.gitleaks.toml" gitleaks detect
```

### CI/CD Options

```bash
# CI mode (exit code 1 if findings)
gitleaks detect --source . --exit-code 1

# Upload results
gitleaks detect --report-format sarif --report-path results.sarif

# Redact secrets in output
gitleaks detect --redact

# No banner (cleaner CI logs)
gitleaks detect --no-banner
```

### Debug Options

```bash
# Verbose output
gitleaks detect --verbose

# Debug output
GITLEAKS_LOG_LEVEL=debug gitleaks detect --verbose

# Log to file
gitleaks detect --verbose 2> gitleaks.log

# Show scanning progress
gitleaks detect --verbose
```

### Git Integration

```bash
# Scan only Git-tracked files
gitleaks detect

# Scan untracked files
gitleaks detect --unstaged

# Scan from specific ref
gitleaks detect --log-opts="--from=abc123"

# Scan to specific ref
gitleaks detect --log-opts="--to=def456"
```

---

## 13. Configuration Reference

### .gitleaks.toml Complete Reference

```toml
# ──── Global Settings ────
title = "Report Title"              # Report title
useDefault = true                   # Use built-in rules
maxTargetMegabytes = 10             # Max file size (MB)
exitCode = 1                        # Exit code on findings (0=success, 1=findings)
reportFormat = "json"               # Output format: json|csv|junit|sarif

# ──── Allowlist (Global) ────
[allowlist]
  description = "Global allowlist"
  paths = ['''regex''']             # Paths to skip
  secrets = ['''regex''']           # Secrets to skip
  commits = ["hash"]                # Commits to skip
  files = ['''regex''']             # Files to skip (by name)

# ──── Rules ────
[[rules]]
  id = "unique-id"                  # Required: unique identifier
  description = "Description"       # Human-readable description
  regex = '''pattern'''             # Regex pattern to match
  entropy = 3.5                     # Entropy threshold (0-1)
  path = '''regex'''                # Only scan matching file paths
  tags = ["tag1", "tag2"]          # Tags for categorization
  keywords = ["keyword1"]          # Keywords for fast filtering
  
  # Allowlist for this specific rule
  [[rules.allowlist]]
    description = "Rule allowlist"
    paths = ['''regex''']
    secrets = ['''regex''']
    commits = ["hash"]
```

### Rule Fields Reference

| Field | Description | Required | Default |
|-------|-------------|----------|---------|
| `id` | Unique rule identifier | Yes | - |
| `description` | Human-readable description | No | (empty) |
| `regex` | Regex pattern to match | Yes | - |
| `entropy` | Entropy threshold (0-1) | No | 0.0 (disabled) |
| `path` | Regex for file path matching | No | (all files) |
| `tags` | Tags for categorization | No | (empty) |
| `keywords` | Keywords for fast filtering | No | (empty) |

### Allowlist Fields Reference

| Field | Description | Required |
|-------|-------------|----------|
| `description` | Reason for allowlist | No |
| `paths` | Regex patterns for paths to skip | No |
| `secrets` | Regex patterns for secrets to skip | No |
| `commits` | Git commit hashes to skip | No |
| `files` | Regex patterns for file names to skip | No |

### Built-in Rules

Gitleaks includes 100+ built-in rules covering:

- AWS (Access Key, Secret Key, Session Token)
- Azure (Storage Account, Key Vault, AD Client Secret)
- GCP (Service Account Key, API Key)
- GitHub (Personal Access Token, OAuth Access Token, App Token)
- GitLab (Personal Access Token, Pipeline Token, Runner Token)
- Slack (Bot Token, User Token, Webhook URL)
- Stripe (Secret Key, Publishable Key, Restricted Key)
- Twilio (API Key, Auth Token)
- SendGrid (API Key)
- Mailgun (API Key, SMTP Password)
- PayPal (Client Secret, Secret)
- Heroku (API Key)
- MongoDB (Connection URI)
- PostgreSQL (Connection URI)
- MySQL (Connection URI)
- Redis (Connection URI)
- Generic (API Key, Secret, Password, Token, Private Key)

### Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `GITLEAKS_CONFIG` | Path to config file | .gitleaks.toml |
| `GITLEAKS_ENABLE_RULES` | Comma-separated rule IDs to enable | (all) |
| `GITLEAKS_DISABLE_RULES` | Comma-separated rule IDs to disable | (none) |
| `GITLEAKS_LOG_LEVEL` | Log level (debug, info, warn, error) | info |
| `GITLEAKS_ENABLE_TELEMETRY` | Enable telemetry (true/false) | true |

---

## 14. Real-World Examples

### Example 1: Scanning Contoso Pet Store (Python)

```toml
# .gitleaks.toml
title = "Contoso Pet Store Secret Scan"

useDefault = true

[allowlist]
  description = "Contoso allowlist"
  paths = [
    '''vendor/''',
    '''node_modules/''',
    '''\.env\.example$''',
    '''test/''',
    '''tests/''',
  ]
  secrets = [
    '''(?i)test[_-]?secret''',
    '''(?i)example[_-]?key''',
    '''PLACEHOLDER''',
    '''changeme''',
  ]

[[rules]]
  id = "contoso-api-key"
  description = "Contoso API Key Pattern"
  regex = '''(?i)contoso[_-]?api[_-]?key\s*[:=]\s*['"]([a-zA-Z0-9]{32,64})['"]'''
  entropy = 3.5
  tags = ["contoso", "api", "key"]
  keywords = ["contoso_api_key", "contoso-api-key", "CONTOSO_API_KEY"]

[[rules]]
  id = "database-credentials"
  description = "Database Credentials"
  regex = '''(?i)(db_password|database_password|mysql_password|postgres_password)\s*[:=]\s*['"]([^'"]+)['"]'''
  entropy = 3.0
  tags = ["database", "password"]
  keywords = ["db_password", "database_password", "mysql_password", "postgres_password"]
```

```bash
# Run scan
gitleaks detect --config .gitleaks.toml --verbose

# Run in CI
gitleaks detect --config .gitleaks.toml --report-format sarif --report-path results.sarif

# Scan entire history
gitleaks detect --config .gitleaks.toml --log-opts="--all"
```

### Example 2: Scanning Contoso Pet Store (Node.js)

```toml
# .gitleaks.toml
title = "Contoso Pet Store API Secret Scan"

useDefault = true

[allowlist]
  description = "Node.js allowlist"
  paths = [
    '''node_modules/''',
    '''dist/''',
    '''build/''',
    '''\.env\.example$''',
    '''test/''',
    '''__tests__/''',
  ]
  secrets = [
    '''(?i)test[_-]?secret''',
    '''(?i)mock[_-]?key''',
    '''PLACEHOLDER''',
  ]

[[rules]]
  id = "jwt-secret"
  description = "JWT Secret Key"
  regex = '''(?i)(jwt_secret|JWT_SECRET)\s*[:=]\s*['"]([^'"]{16,})['"]'''
  entropy = 3.5
  tags = ["jwt", "secret"]
  keywords = ["jwt_secret", "JWT_SECRET"]

[[rules]]
  id = "aws-secrets"
  description = "AWS Secrets in Node.js"
  regex = '''(?i)(AWS_SECRET_ACCESS_KEY|aws_secret_access_key)\s*[:=]\s*['"]([A-Za-z0-9/+=]{40})['"]'''
  entropy = 4.0
  tags = ["aws", "secret"]
  keywords = ["AWS_SECRET_ACCESS_KEY", "aws_secret_access_key"]
```

### Example 3: GitHub Actions Pipeline

```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: results.sarif
```

### Example 4: Monorepo Scanning

```bash
# Scan specific service
gitleaks detect --source services/auth/ --config .gitleaks.toml

# Scan with specific rules
gitleaks detect --config .gitleaks.toml --log-opts="--since=2024-01-01"

# Scan all services
for service in services/*/; do
  echo "Scanning $service"
  gitleaks detect --source "$service" --config .gitleaks.toml
done
```

### Example 5: Docker Compose for CI

```yaml
# docker-compose.gitleaks.yml
version: '3.8'
services:
  gitleaks:
    image: ghcr.io/gitleaks/gitleaks:latest
    volumes:
      - .:/src
    command: >
      gitleaks detect
      --source /src
      --config /src/.gitleaks.toml
      --report-format sarif
      --report-path /src/gitleaks-results.sarif
      --verbose
    environment:
      - GITLEAKS_LOG_LEVEL=debug
```

---

## 15. Further Reading

### Official Documentation
- [Gitleaks Documentation](https://gitleaks.io/)
- [Gitleaks GitHub](https://github.com/zricethezav/gitleaks)
- [Gitleaks Configuration](https://github.com/zricethezav/gitleaks#configuration)
- [Gitleaks Rules](https://github.com/zricethezav/gitleaks/tree/master/config)

### Gitleaks Community
- [Gitleaks GitHub Issues](https://github.com/zricethezav/gitleaks/issues)
- [Gitleaks Discord](https://discord.gg/x3UWVd4)
- [Gitleaks Twitter](https://twitter.com/gitleaks)

### OWASP References
- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [OWASP Credential Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Credential_Storage_Cheat_Sheet.html)

### Related Tools in This Guide
- [SonarQube Guide](./sonarqube.md) — Comprehensive code quality platform
- [Semgrep Guide](./semgrep.md) — Lightweight semantic analysis

### Books & Resources
- "Secrets of a Young Billionaire" — Understanding credential management
- "The Phoenix Project" — DevOps culture and automation
- "Accelerate" — High-performing IT organizations
- "Continuous Delivery" — Jez Humble & David Farley

---

*Last updated: 2026*
