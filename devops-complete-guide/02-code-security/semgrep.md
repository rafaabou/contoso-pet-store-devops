# Semgrep Complete Guide

## Table of Contents

1. [What Is Semgrep?](#1-what-is-semgrep)
2. [Why Use Semgrep?](#2-why-use-semgrep)
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

## 1. What Is Semgrep?

### Plain English Explanation

Semgrep is a fast, open-source static analysis tool that finds bugs and enforces code standards using pattern matching. Unlike traditional linters that check simple syntax, Semgrep understands code structure — it can match patterns like "any function call to `execute()` where the first argument comes from user input."

Think of it as a search engine for your code. You describe what you're looking for (using a pattern that looks like code), and Semgrep finds every instance across your entire codebase.

### Why It Exists

Developers write custom grep patterns to find code issues. Regular `grep` can't understand code structure — it matches text, not meaning. Semgrep exists to provide:

- **Pattern matching that understands code**: Match `sql.execute($QUERY)` without matching comments or strings containing that text
- **Multi-language support**: One pattern syntax works across Python, Java, JavaScript, Go, Ruby, C, and more
- **Speed**: Scans thousands of files in seconds (written in OCaml)
- **Auto-fix**: Can automatically rewrite code to fix issues
- **CI/CD integration**: Runs in GitHub Actions, GitLab CI, pre-commit, and more

### Architecture

```
┌─────────────────────────────────────────────┐
│                  Semgrep                     │
│                                              │
│  ┌────────────┐    ┌──────────────────────┐ │
│  │   Parser   │───▶│   Pattern Engine     │ │
│  │ (AST)      │    │                      │ │
│  │            │    │  Rule → Pattern →    │ │
│  │ Language   │    │  Match → Finding     │ │
│  │ Parsers    │    │                      │ │
│  │            │    │  Languages:          │ │
│  │ Python     │    │  Python, JS, TS,     │ │
│  │ JS/TS      │    │  Java, Go, Ruby,     │ │
│  │ Java       │    │  C, C++, Swift,      │ │
│  │ Go         │    │  Kotlin, C#, PHP,    │ │
│  │ Ruby       │    │  Rust, Terraform,    │ │
│  │ C/C++      │    │  YAML, JSON, Docker, │ │
│  │ ...        │    │  Bash, R, Scala, ... │ │
│  └────────────┘    └──────────────────────┘ │
│                                              │
│  ┌────────────┐    ┌──────────────────────┐ │
│  │ Autofix    │◀───│  Output Formatters   │ │
│  │ Engine     │    │                      │ │
│  │            │    │  - Text              │ │
│  │ Rewrite    │    │  - JSON              │ │
│  │ matched    │    │  - SARIF             │ │
│  │ code       │    │  - GitLab SAST       │ │
│  └────────────┘    └──────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Semgrep vs. Other Tools

| Feature | Semgrep | SonarQube | ESLint | Checkmarx |
|---------|---------|-----------|--------|-----------|
| Speed | Very fast | Moderate | Fast | Slow |
| Languages | 30+ | 20+ | JS/TS only | 25+ |
| Custom rules | Easy | Hard (Java) | Easy (JS) | Medium |
| Free tier | Yes | Community | Yes | No |
| Auto-fix | Yes | Limited | Yes | No |
| IDE support | Yes | Yes | Yes | Yes |
| Type-aware | Yes (Pro) | Yes | No | Yes |

---

## 2. Why Use Semgrep?

### Real-World Breaches

- **Log4Shell (CVE-2021-44228)**: Semgrep rule `java.lang.JNDI` patterns caught JNDI lookups in user-controlled input within hours of disclosure.
- **Spring4Shell (CVE-2022-22965)**: Pattern `class.module.classLoader.resources.context.parent.pipeline.first.pattern` matched the exploit pattern immediately.
- **Left-Pad NPM Incident (2016)**: Semgrep-style rules can detect dependency on single-function packages.

### When to Use Semgrep

- **Pull request checks**: Fast enough to run on every PR (< 30 seconds)
- **Security audits**: Search for specific vulnerability patterns across codebases
- **Code standards enforcement**: Ensure consistent patterns across teams
- **Migration assistance**: Find all instances of deprecated API usage
- **License compliance**: Detect GPL-licensed code in proprietary projects
- **Secret detection**: Find hardcoded credentials (pairs well with Gitleaks)

### What Happens Without It

- **SQL injection vulnerabilities** ship to production because developers forgot parameterized queries
- **Hardcoded secrets** get committed to Git history and deployed
- **Inconsistent error handling** leads to silent failures in production
- **Deprecated API usage** causes runtime errors after upgrades
- **Unsafe deserialization** leads to remote code execution

---

## 3. Installation

### Method 1: pip (Recommended)

```bash
# Install Semgrep
pip install semgrep

# Verify installation
semgrep --version

# Update to latest
pip install --upgrade semgrep
```

### Method 2: Docker

```bash
# Pull the image
docker pull semgrep/semgrep

# Run scan
docker run --rm \
  -v "$(pwd):/src" \
  semgrep/semgrep \
  semgrep scan --config auto

# Run with specific rules
docker run --rm \
  -v "$(pwd):/src" \
  semgrep/semgrep \
  semgrep scan --config p/security-audit
```

### Method 3: Binary Release

```bash
# Linux (x86_64)
curl -L https://github.com/semgrep/semgrep/releases/latest/download/semgrep-linux-x86_64.tar.gz | tar xz
sudo mv semgrep /usr/local/bin/

# macOS
brew install semgrep

# Verify
semgrep --version
```

### Method 4: Homebrew (macOS)

```bash
brew install semgrep

# Or with pipx for isolated environment
pipx install semgrep
```

### Method 5: From Source

```bash
# Clone repository
git clone https://github.com/semgrep/semgrep.git
cd semgrep

# Install dependencies
pip install -e .

# Build
make build

# Verify
semgrep --version
```

### Method 6: Semgrep App (Cloud)

```bash
# No installation needed — use the web interface
# Or install CLI and connect:
pip install semgrep
semgrep login
semgrep scan --config policy/<your-org>
```

### First-Time Setup

```bash
# Login to Semgrep App (optional, for managed policies)
semgrep login

# Run with auto-detected rules
semgrep scan --config auto

# Run with security rules
semgrep scan --config p/security-audit
```

---

## 4. Configuration

### .semgrepignore

Similar to `.gitignore`, this file excludes files/directories from scanning:

```
# .semgrepignore

# Dependencies
node_modules/
vendor/
venv/
.venv/

# Build artifacts
dist/
build/
target/
__pycache__/

# Test fixtures
test/fixtures/
tests/fixtures/

# Generated files
*.generated.*
autogenerated/

# Large files
*.min.js
*.min.css
*.map
```

### .semgrep.yml (Project Rules)

```yaml
# .semgrep.yml — Project-specific rules

rules:
  - id: no-print-debug
    pattern: print(...)
    message: Use logging instead of print()
    languages: [python]
    severity: WARNING
    metadata:
      category: best-practice
      technology: [python]

  - id: no-eval
    pattern-either:
      - pattern: eval(...)
      - pattern: exec(...)
    message: Avoid eval()/exec() — use safer alternatives
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-95: Eval Injection"

  - id: require-https
    pattern: "https://$URL"
    fix: "https://$URL"
    message: Ensure all URLs use HTTPS
    languages: [generic]
    severity: WARNING
```

### semgrep.config.yml (Enterprise)

```yaml
# semgrep.config.yml — Organization-wide policy

# Include rules from Semgrep registry
include:
  - p/security-audit
  - p/owasp-top-ten
  - p/typescript
  - p/python

# Exclude paths
exclude:
  - "vendor/"
  - "node_modules/"
  - "**/*.test.js"
  - "**/*.spec.ts"

# Override specific rules
rules:
  - id: javascript.lang.security.audit.xss.mustache-escape
    severity: INFO  # Downgrade from ERROR

# Auto-fix settings
autofix: true

# Maximum file size (bytes)
max-target-bytes: 1000000

# Timeout per file (seconds)
timeout: 30
```

### Configuration Hierarchy

```
1. Command line flags        (highest priority)
2. .semgrep.yml              (project-level)
3. .semgrep/ directory       (project-level, multiple files)
4. semgrep.config.yml        (organization policy via App)
5. Default rules             (lowest priority)
```

---

## 5. Core Concepts

### Pattern Syntax

Semgrep patterns look like code but with special operators:

**Simple pattern (matches any call to `execute`):**
```python
execute(...)
```

**Pattern with metavariable (captures and compares):**
```python
execute($QUERY)
```

**Pattern with ellipsis (matches any arguments):**
```python
execute(..., $QUERY)
```

**Pattern with restriction (only match specific values):**
```python
execute("SELECT ...")
```

### Metavariables

Metavariables (prefixed with `$`) capture and reuse values:

```yaml
rules:
  - id: copy-paste-bug
    patterns:
      - pattern: |
          if $COND:
              $STMT
          if $COND:
              $STMT2
    message: "Duplicate if condition: $COND"
    languages: [python]
    severity: WARNING
```

### Pattern Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `...` | Ellipsis — matches any sequence | `foo(...)` |
| `$X` | Metavariable — captures value | `foo($X)` |
| `<... $X ...>` | Pattern inside expression | `<... $X + $Y ...>` |
| `METAVAR` | Compare captured values | `$X == $X` |
| `pattern-either` | Match any of several patterns | See below |
| `patterns` | Match all of several patterns | See below |
| `pattern-not` | Exclude matches | See below |
| `pattern-inside` | Match inside a context | See below |
| `pattern-not-inside` | Exclude matches inside context | See below |
| `pattern-regex` | Regex on matched code | See below |
| `where` | Condition on metavariables | See below |
| `where regex` | Regex condition | See below |

### Operators in Detail

**`pattern-either` (OR):**
```yaml
rules:
  - id: unsafe-deserialization
    pattern-either:
      - pattern: pickle.loads(...)
      - pattern: yaml.load(...)
      - pattern: json.loads(...)
    message: "Unsafe deserialization detected"
    languages: [python]
    severity: ERROR
```

**`patterns` (AND):**
```yaml
rules:
  - id: sql-injection
    patterns:
      - pattern: |
          $QUERY = "..." + $INPUT
          ...
          cursor.execute($QUERY)
      - pattern-not: |
          $QUERY = "..." + "..."
    message: "Possible SQL injection via string concatenation"
    languages: [python]
    severity: ERROR
```

**`pattern-inside` (Context):**
```yaml
rules:
  - id: hardcoded-password
    patterns:
      - pattern: $PASSWORD = "..."
      - pattern-inside: |
          def $FUNC(...):
              ...
    message: "Hardcoded password in function $FUNC"
    languages: [python]
    severity: ERROR
```

**`pattern-not` (Exclusion):**
```yaml
rules:
  - id: no-random-for-security
    patterns:
      - pattern: random.random()
      - pattern-not: |
          # noqa: not used for security
          random.random()
    message: "Use secrets module instead of random for security"
    languages: [python]
    severity: WARNING
```

### Languages Supported

Semgrep supports 30+ languages:

**General Purpose:**
- Python, Java, JavaScript, TypeScript, Go, Ruby, C, C++, C#
- Kotlin, Swift, Rust, PHP, Scala, R, Lua, Bash

**Infrastructure:**
- Terraform, Dockerfile, YAML, JSON, Kubernetes manifests

**Shell Scripts:**
- Bash, Sh

**Other:**
- Generic (regex-based, language-agnostic)

### Rule Types

| Type | Description |
|------|-------------|
| `finding` | Default — reports matches |
| `taint` | Tracks data flow from source to sink |
| `join` | Correlates findings across files |

### Severity Levels

- `ERROR` — Must fix, blocks CI
- `WARNING` — Should fix, may block CI
- `INFO` — Informational, for awareness
- `OFF` — Disabled (but still parsed)

---

## 6. Usage Guide

### Step-by-Step: First Scan

**1. Install Semgrep:**
```bash
pip install semgrep
```

**2. Run auto-detection:**
```bash
semgrep scan --config auto
```

**3. Review results:**
```
┌──────────────────────────────────────────────┐
│ Scan results                                 │
│                                              │
│  Rules:      45 rules ran                    │
│  Findings:   12 findings                     │
│  Warnings:   3 warnings (parsing errors)     │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ ▶ src/utils.py                         │  │
│  │   ▶ Line 15: WARNING                   │  │
│  │     Use logging instead of print()     │  │
│  │                                         │  │
│  │ ▶ src/api.py                           │  │
│  │   ▶ Line 42: ERROR                     │  │
│  │     SQL injection via string concat    │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

### Running Specific Rule Sets

```bash
# Security audit rules
semgrep scan --config p/security-audit

# OWASP Top 10
semgrep scan --config p/owasp-top-ten

# Language-specific rules
semgrep scan --config p/python
semgrep scan --config p/typescript
semgrep scan --config p/java

# CIS benchmarks
semgrep scan --config p/ci

# Custom rules file
semgrep scan --config .semgrep.yml

# Multiple rule sets
semgrep scan --config p/security-audit --config p/owasp-top-ten

# From Semgrep App (organization policy)
semgrep scan --config policy/my-org
```

### Targeting Specific Files

```bash
# Scan specific directory
semgrep scan src/

# Scan specific file
semgrep scan src/api.py

# Scan with glob pattern
semgrep scan --include "*.py" --exclude "test_*"

# Scan only changed files (Git)
semgrep scan --config auto --diff
```

### Output Formats

```bash
# Text (default)
semgrep scan --config auto --text

# JSON
semgrep scan --config auto --json > results.json

# SARIF (for GitHub Security)
semgrep scan --config auto --sarif > results.sarif

# GitLab SAST
semgrep scan --config auto --gitlab-sast > gl-sast-report.json

# Emacs format
semgrep scan --config auto --emacs

# Vim format
semgrep scan --config auto --vim

# JSON with dataflow
semgrep scan --config auto --json --dataflow-traces
```

### Fixing Issues

```bash
# Dry-run autofix (see what would change)
semgrep scan --config auto --autofix --dry-run

# Apply autofix
semgrep scan --config auto --autofix

# Apply autofix for specific rule
semgrep scan --config .semgrep.yml --autofix --config-rule-id no-print-debug
```

### CI/CD Usage

```bash
# CI mode (non-interactive, exit code 1 if findings)
semgrep ci --config auto

# With specific exit codes
semgrep ci --config auto \
  --error \
  --strict \
  --max-target-bytes 1000000

# Upload results to Semgrep App
SEMGREP_APP_TOKEN=your_token semgrep ci --config auto
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/semgrep/semgrep
    rev: v1.65.0
    hooks:
      - id: semgrep
        args: ['--config', 'auto', '--error']
        stages: [push]
```

### Using Semgrep for Code Review

```bash
# Find all hardcoded credentials
semgrep scan --config p/secrets

# Find SQL injection patterns
semgrep scan --config p/sql-injection

# Find unsafe deserialization
semgrep scan --config p/unsafe-deserialization

# Find all eval() usage
semgrep scan --config '<pattern>eval(...)</pattern>' --json | jq '.results[] | .path'

# Custom search: Find all TODO comments
semgrep scan --config '<pattern>TODO(...)</pattern>' --json
```

### Testing Rules

```bash
# Validate rule YAML
semgrep --validate --config .semgrep.yml

# Dry-run rule
semgrep scan --config .semgrep.yml --test

# Run specific rule ID
semgrep scan --config .semgrep.yml --config-rule-id no-print-debug
```

---

## 7. Writing Custom Rules

### Rule Structure

```yaml
rules:
  - id: rule-unique-id
    pattern: <semgrep-pattern>
    message: <message-with-metavariables>
    languages: [language]
    severity: ERROR|WARNING|INFO
    metadata:
      category: security|best-practice|performance
      technology: [language]
      cwe:
        - "CWE-XX: Description"
      owasp:
        - A01:2021 - Broken Access Control
      confidence: HIGH|MEDIUM|LOW
      impact: HIGH|MEDIUM|LOW
    fix: <autofix-pattern>
    fix-regex:
      regex: <regex>
      replacement: <replacement>
      count: <match-number>
```

### Rule Writing Workflow

1. **Identify the pattern**: What does the vulnerable/bad code look like?
2. **Write the Semgrep pattern**: Translate to Semgrep syntax
3. **Test the pattern**: Does it match what you expect?
4. **Add exclusions**: Prevent false positives
5. **Write the message**: Explain what's wrong and how to fix
6. **Set metadata**: CWE, severity, category
7. **Add autofix**: If possible, make it automatic
8. **Test thoroughly**: Verify on real codebases

### Example 1: Detect Hardcoded Passwords

```yaml
rules:
  - id: hardcoded-password
    patterns:
      - pattern-either:
          - pattern: |
              password = "..."
          - pattern: |
              password = '...'
          - pattern: |
              $VAR = "..."
              ...
              password = $VAR
      - metavariable-regex:
          metavariable: $VAR
          regex: (?i)(password|passwd|pwd|secret|token)
    message: >
      Hardcoded password detected. Use environment variables
      or a secrets manager instead.
    languages: [python, javascript, java]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-798: Use of Hard-coded Credentials"
      confidence: HIGH
    fix: "os.environ.get('PASSWORD')"
```

### Example 2: SQL Injection

```yaml
rules:
  - id: sql-injection-python
    patterns:
      - pattern-either:
          - pattern: |
              $QUERY = "..." + $INPUT
              ...
              cursor.execute($QUERY)
          - pattern: |
              $QUERY = f"...{$INPUT}..."
              ...
              cursor.execute($QUERY)
          - pattern: |
              $QUERY = "..." % $INPUT
              ...
              cursor.execute($QUERY)
          - pattern: |
              $QUERY = "...".format($INPUT)
              ...
              cursor.execute($QUERY)
    message: >
      SQL injection risk: $INPUT is used in a SQL query via
      string concatenation. Use parameterized queries instead.
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-89: SQL Injection"
      confidence: HIGH
      impact: HIGH
    fix: "cursor.execute($QUERY, ($INPUT,))"
```

### Example 3: XSS in JavaScript

```yaml
rules:
  - id: xss-react-dangerouslysetinnerhtml
    pattern: <div dangerouslySetInnerHTML={{ __html: $HTML }} />
    message: >
      dangerouslySetInnerHTML with user input can cause XSS.
      Use a sanitization library like DOMPurify.
    languages: [javascript, typescript]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-79: Cross-site Scripting"
      confidence: MEDIUM
```

### Example 4: Debug Code Left in Production

```yaml
rules:
  - id: debug-code-python
    pattern-either:
      - pattern: print(...)
      - pattern: |
          import pdb; pdb.set_trace()
      - pattern: |
          import ipdb; ipdb.set_trace()
      - pattern: breakpoint()
    message: >
      Debug code found: remove before deploying to production.
    languages: [python]
    severity: WARNING
    metadata:
      category: best-practice
    fix: ""
```

### Example 5: Unsafe YAML Loading

```yaml
rules:
  - id: unsafe-yaml-load
    pattern-either:
      - pattern: yaml.load(...)
      - pattern: yaml.unsafe_load(...)
    message: >
      yaml.load() without Loader=yaml.SafeLoader is unsafe.
      Use yaml.safe_load() or specify Loader=yaml.SafeLoader.
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-502: Deserialization of Untrusted Data"
    fix-regex:
      regex: yaml\.load\(.*\)
      replacement: yaml.safe_load(...)
```

### Example 6: Taint Mode Rule

```yaml
rules:
  - id: command-injection-taint
    mode: taint
    pattern-sources:
      - pattern: |
          $INPUT = request.args.get(...)
      - pattern: |
          $INPUT = request.form[...]
      - pattern: |
          $INPUT = request.json[...]
    pattern-sinks:
      - pattern: |
          os.system($INPUT)
      - pattern: |
          subprocess.call($INPUT, shell=True)
      - pattern: |
          subprocess.call(..., shell=True)
    pattern-sanitizers:
      - pattern: shlex.quote(...)
      - pattern: |
          $X = shlex.quote(...)
          ...
    message: >
      User input from request flows into a shell command.
      Use subprocess with shell=False or sanitize with shlex.quote().
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-78: OS Command Injection"
```

### Example 7: Regex-Based Rules

```yaml
rules:
  - id: private-ip-address
    pattern-regex: "^(10\\.\\d{1,3}|172\\.(1[6-9]|2\\d|3[01])|192\\.168)\\.\\d{1,3}\\.\\d{1,3}$"
    message: Hardcoded private IP address detected. Use a config file or environment variable.
    languages: [generic]
    severity: WARNING
    metadata:
      category: security
```

### Example 8: Autofix Rules

```yaml
rules:
  - id: replace-os-system
    pattern: os.system(...)
    fix: subprocess.run(..., shell=False)
    message: >
      Use subprocess.run() with shell=False instead of os.system().
    languages: [python]
    severity: WARNING
    metadata:
      category: best-practice
```

### Testing Custom Rules

```yaml
# test.yaml — Rule with test cases
rules:
  - id: no-print-debug
    pattern: print(...)
    message: Use logging instead of print()
    languages: [python]
    severity: WARNING

# test/no-print-debug.py
# ruleid: no-print-debug
print("debug info")

# ok: no-print-debug
logging.info("debug info")
```

```bash
# Run tests
semgrep --test --config .semgrep.yml

# Expected output:
# 1/1 tests passed
```

### Pattern Cookbook

**Match function with specific argument name:**
```yaml
pattern: |
  def $FUNC(..., $ARG="default"):
      ...
```

**Match any method call on an object:**
```yaml
pattern: $OBJ.method(...)
```

**Match a class definition:**
```yaml
pattern: |
  class $CLASS($BASE):
      ...
```

**Match import statement:**
```yaml
pattern: import $MODULE
```

**Match string containing specific text:**
```yaml
pattern: "SELECT ... FROM ..."
```

**Match specific operator usage:**
```yaml
pattern: $X == $Y
```

**Match decorator usage:**
```yaml
pattern: |
  @app.route(...)
  def $FUNC(...):
      ...
```

---

## 8. Integration

### GitHub Actions

```yaml
# .github/workflows/semgrep.yml
name: Semgrep
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6am

jobs:
  semgrep:
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep
    steps:
      - uses: actions/checkout@v4

      - name: Semgrep scan
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
        run: semgrep ci --config auto

      # Or without Semgrep App:
      - name: Semgrep scan (standalone)
        run: |
          semgrep scan \
            --config auto \
            --sarif -o semgrep-results.sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: semgrep-results.sarif
```

### GitLab CI

```yaml
# .gitlab-ci.yml
semgrep:
  stage: test
  image: semgrep/semgrep
  script:
    - semgrep ci --config auto --gitlab-sast > gl-sast-report.json
  artifacts:
    reports:
      sast: gl-sast-report.json
  only:
    - main
    - merge_requests
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/semgrep/semgrep
    rev: v1.65.0
    hooks:
      - id: semgrep
        name: Semgrep
        entry: semgrep scan --config auto --error
        language: system
        types: [python, javascript, typescript, java, go]
        stages: [push, pull-request]

      # Custom rules
      - id: semgrep-custom
        name: Semgrep Custom Rules
        entry: semgrep scan --config .semgrep.yml --error
        language: system
        types: [python]
        stages: [push]
```

### ArgoCD Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: semgrep-scanner
spec:
  project: default
  source:
    repoURL: https://github.com/semgrep/semgrep.git
    path: .
    targetRevision: v1.65.0
    helm:
      values: |
        config:
          policy: p/security-audit
        resources:
          limits:
            cpu: 1
            memory: 2Gi
  destination:
    server: https://kubernetes.default.svc
    namespace: semgrep
```

### Jenkins Pipeline

```groovy
pipeline {
    agent {
        docker {
            image 'semgrep/semgrep'
        }
    }
    stages {
        stage('Semgrep Scan') {
            steps {
                sh '''
                    semgrep scan \
                      --config auto \
                      --sarif \
                      -o semgrep-results.sarif
                '''
            }
        }
        stage('Upload Results') {
            steps {
                archiveArtifacts artifacts: 'semgrep-results.sarif'
            }
        }
    }
    post {
        always {
            recordIssues tools: [sarif(pattern: 'semgrep-results.sarif')]
        }
    }
}
```

### VS Code Integration

```json
// .vscode/settings.json
{
  "semgrep.scanOnSave": true,
  "semgrep.scan configuration": "auto",
  "semgrep.scan.severity": ["ERROR", "WARNING"]
}
```

### Docker Compose for CI

```yaml
# docker-compose.semgrep.yml
version: '3.8'
services:
  semgrep:
    image: semgrep/semgrep
    volumes:
      - .:/src
    command: >
      semgrep scan
      --config auto
      --sarif
      -o /src/semgrep-results.sarif
    environment:
      - SEMGREP_TIMEOUT=300
```

---

## 9. Security Hardening

### Securing Semgrep in CI/CD

```yaml
# GitHub Actions — restricted permissions
jobs:
  semgrep:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write  # For SARIF upload
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: semgrep/semgrep-action@v1
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

### Protecting Secrets

```bash
# Never commit tokens to Git
# Use environment variables or secret managers

# GitHub Actions
env:
  SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}

# GitLab CI
variables:
  SEMGREP_APP_TOKEN: $CI_JOB_TOKEN

# Local development
export SEMGREP_APP_TOKEN=your_token
semgrep scan --config auto
```

### Network Security

```bash
# If scanning in restricted environments
# Use --no-git to avoid Git operations
semgrep scan --no-git --config auto

# Proxy configuration
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
semgrep scan --config auto
```

### Rule Validation

```bash
# Always validate rules before deployment
semgrep --validate --config .semgrep.yml

# Test rules against known patterns
semgrep --test --config .semgrep.yml

# Dry-run before applying autofix
semgrep scan --config .semgrep.yml --autofix --dry-run
```

### Audit Logging

```bash
# Enable verbose logging for audit trail
semgrep scan --config auto --verbose 2>&1 | tee semgrep-audit.log

# JSON output for machine parsing
semgrep scan --config auto --json > semgrep-results.json
```

---

## 10. Troubleshooting

### Issue 1: Semgrep is slow

**Cause:** Scanning large directories, many files, or complex patterns.

**Fix:**
```bash
# Limit file size
semgrep scan --max-target-bytes 1000000 --config auto

# Exclude directories
semgrep scan --exclude vendor/ --exclude node_modules/ --config auto

# Use specific languages only
semgrep scan --config auto --include "*.py" --include "*.js"

# Increase timeout
semgrep scan --timeout 60 --config auto
```

### Issue 2: "Parsing error" warnings

**Cause:** Semgrep can't parse some files (JSX, TypeScript generics, etc.).

**Fix:**
```bash
# Ignore specific files
echo "**/*.jsx" >> .semgrepignore

# Or disable specific rules that cause errors
semgrep scan --config auto --disable-nosem
```

### Issue 3: Too many false positives

**Fix:**
```yaml
# Add exclusions to rules
rules:
  - id: my-rule
    patterns:
      - pattern: <pattern>
      - pattern-not-inside: |
          # nosemgrep
          ...
```

### Issue 4: Rule not matching expected code

**Debug steps:**
```bash
# Use --json to see full match details
semgrep scan --config .semgrep.yml --json | jq '.results[]'

# Test with minimal example
echo 'print("hello")' > test.py
semgrep scan --config .semgrep.yml test.py

# Check pattern syntax
semgrep --validate --config .semgrep.yml
```

### Issue 5: "Rule ID already exists" error

**Fix:**
```bash
# Find duplicate rule IDs
grep -n "id:" .semgrep.yml | sort -t: -k3

# Rename duplicate IDs to be unique
```

### Issue 6: Semgrep can't find Python files

**Fix:**
```bash
# Ensure .py files are not in .semgrepignore
cat .semgrepignore | grep -v "\.py"

# Explicitly include
semgrep scan --include "*.py" --config auto
```

### Issue 7: CI build fails on Semgrep findings

**Fix:**
```bash
# Use --error flag to control exit codes
semgrep ci --config auto --error

# Or allow warnings without failing
semgrep ci --config auto --error --severity ERROR
```

### Issue 8: Docker permission denied

**Fix:**
```bash
# Run with correct user
docker run --rm \
  -v "$(pwd):/src" \
  -u "$(id -u):$(id -g)" \
  semgrep/semgrep \
  semgrep scan --config auto
```

### Issue 9: Memory limit exceeded

**Fix:**
```bash
# Increase Docker memory
docker run --rm -m 4g semgrep/semgrep semgrep scan --config auto

# Or limit analysis scope
semgrep scan --max-target-bytes 500000 --config auto
```

### Issue 10: Rule YAML syntax error

**Fix:**
```bash
# Validate YAML syntax
python -c "import yaml; yaml.safe_load(open('.semgrep.yml'))"

# Use yamllint
yamllint .semgrep.yml

# Check Semgrep-specific syntax
semgrep --validate --config .semgrep.yml
```

### Issue 11: Pattern doesn't match multiline code

**Fix:**
```yaml
# Use | for multiline patterns
rules:
  - id: multiline-pattern
    pattern: |
      if $COND:
          $STMT1
          $STMT2
    message: Found pattern
    languages: [python]
    severity: WARNING
```

### Issue 12: Metavariable comparison fails

**Fix:**
```yaml
# Ensure metavariables are in same scope
rules:
  - id: compare-vars
    pattern: |
      $X = ...
      $Y = $X
    message: $Y uses same value as $X
    languages: [python]
    severity: WARNING
```

### Issue 13: Regex pattern too complex

**Fix:**
```yaml
# Simplify regex or use pattern instead
rules:
  - id: simple-pattern
    pattern: "http://..."
    message: Use HTTPS
    languages: [generic]
    severity: WARNING
```

### Issue 14: SARIF output missing from GitHub

**Fix:**
```yaml
# Ensure correct upload step
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: semgrep-results.sarif
    category: semgrep
```

### Issue 15: Rules not loading from file

**Fix:**
```bash
# Check file path
semgrep scan --config .semgrep.yml --verbose

# Ensure correct YAML structure
# Must start with "rules:" at root level
head -5 .semgrep.yml
```

### Issue 16: Exclusion patterns not working

**Fix:**
```yaml
# .semgrepignore uses gitignore syntax
# Correct: vendor/
# Incorrect: /vendor/

# Test exclusions
semgrep scan --config auto --verbose 2>&1 | grep "excluded"
```

### Issue 17: Taint mode not tracking data flow

**Fix:**
```yaml
# Ensure sources and sinks are correct
# Taint mode requires explicit source/sink definitions
mode: taint
pattern-sources:
  - pattern: $INPUT = request.args.get(...)
pattern-sinks:
  - pattern: os.system($INPUT)
```

---

## 11. Tips & Best Practices

1. **Start with `--config auto`**: Let Semgrep detect the right rules for your languages.
2. **Use `--sarif` in CI**: Produces standard output for GitHub/GitLab integration.
3. **Add `.semgrepignore`**: Skip test files, vendored code, and generated files.
4. **Write small rules**: One pattern per rule is easier to maintain.
5. **Use metavariables wisely**: `$VAR` captures and reuses — powerful for comparing values.
6. **Test before deploying**: Use `--test` to validate rules against known patterns.
7. **Combine operators**: `patterns` (AND) + `pattern-either` (OR) + `pattern-not` (exclude) = precise rules.
8. **Use `pattern-inside` for context**: Match code inside functions, classes, or blocks.
9. **Add autofix when possible**: Makes adoption smoother — developers don't have to manually fix.
10. **Use taint mode for security**: It tracks data flow from source to sink, catching more issues.
11. **Review findings regularly**: Don't let findings pile up — triage weekly.
12. **Use `--error` in CI**: Make the build fail on errors, not just warnings.
13. **Organize rules by category**: Separate security, performance, and style rules.
14. **Use Semgrep App for dashboards**: Track trends and manage policies across teams.
15. **Share rules internally**: Build a library of organization-specific patterns.
16. **Use `--diff` to scan only changes**: Faster feedback on pull requests.
17. **Combine with SonarQube**: Semgrep for pattern matching, SonarQube for metrics/coverage.
18. **Use `--json` for machine parsing**: Pipe results to jq or custom scripts.
19. **Set `--max-target-bytes`**: Skip very large files to avoid slowdowns.
20. **Use `--timeout` for CI**: Prevent scans from hanging on complex files.

---

## 12. Command Reference

### Basic Commands

```bash
# Scan entire project
semgrep scan

# Scan with specific rules
semgrep scan --config auto
semgrep scan --config p/security-audit
semgrep scan --config .semgrep.yml

# Scan specific files/dirs
semgrep scan src/
semgrep scan src/api.py
```

### Output Options

```bash
# Text output (default)
semgrep scan --text

# JSON output
semgrep scan --json

# SARIF output
semgrep scan --sarif

# GitLab SAST
semgrep scan --gitlab-sast

# Emacs format
semgrep scan --emacs

# Vim format
semgrep scan --vim

# CSV output
semgrep scan --csv
```

### Filtering Options

```bash
# Filter by severity
semgrep scan --severity ERROR
semgrep scan --severity WARNING

# Filter by rule ID
semgrep scan --config-rule-id no-print-debug

# Filter by path
semgrep scan --include "*.py"
semgrep scan --exclude "test_*"

# Filter by file size
semgrep scan --max-target-bytes 1000000

# Filter by time
semgrep scan --timeout 30
```

### Fix Options

```bash
# Dry-run autofix
semgrep scan --autofix --dry-run

# Apply autofix
semgrep scan --autofix

# Autofix specific rule
semgrep scan --autofix --config-rule-id no-print-debug
```

### Validation Options

```bash
# Validate rules
semgrep --validate --config .semgrep.yml

# Test rules
semgrep --test --config .semgrep.yml

# Dry-run (show what would be scanned)
semgrep scan --dry-run --config auto
```

### CI Options

```bash
# CI mode (exit code 1 if findings)
semgrep ci --config auto

# Strict mode (exit code 1 for warnings too)
semgrep ci --config auto --strict

# Error mode
semgrep ci --config auto --error

# Upload to Semgrep App
SEMGREP_APP_TOKEN=your_token semgrep ci --config auto
```

### Debug Options

```bash
# Verbose output
semgrep scan --verbose

# Debug output
semgrep scan --debug

# Log to file
semgrep scan --config auto 2> semgrep.log

# Show parsing errors
semgrep scan --config auto --verbose 2>&1 | grep "parse error"
```

### Git Integration

```bash
# Scan only changed files
semgrep scan --diff

# Scan from specific Git ref
semgrep scan --config auto --from-ref main

# Scan uncommitted changes
semgrep scan --config auto --no-git
```

---

## 13. Configuration Reference

### .semgrep.yml Complete Reference

```yaml
rules:
  - id: unique-rule-id              # Required: unique identifier
    pattern: <semgrep-pattern>       # Semgrep pattern
    message: <message>               # Message with metavariables
    languages: [python]              # Target languages
    severity: ERROR                  # ERROR|WARNING|INFO
    paths:                           # Path filters
      include:
        - "src/"
        - "*.py"
      exclude:
        - "test_*"
        - "vendor/"
    metadata:                        # Additional metadata
      category: security
      technology: [python]
      cwe:
        - "CWE-798: Hard-coded Credentials"
      owasp:
        - A07:2021 - Identification and Authentication Failures
      confidence: HIGH
      impact: HIGH
      maturity: stable               # experimental|stable|mature
    fix: <fix-pattern>               # Autofix pattern
    fix-regex:                       # Regex-based autofix
      regex: <regex>
      replacement: <replacement>
      count: 1                       # Which match to fix (1-indexed)
    mode: taint                      # taint|join (advanced)
    pattern-sources:                 # For taint mode
      - pattern: <source-pattern>
    pattern-sinks:                   # For taint mode
      - pattern: <sink-pattern>
    pattern-sanitizers:              # For taint mode
      - pattern: <sanitizer-pattern>
    pattern-propagators:             # For taint mode
      - pattern: <propagator-pattern>
    equivalences:                    # Code equivalence definitions
      - id: equivalence
        pattern: <pattern-a>
        equivalent: <pattern-b>
```

### Global Configuration

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `SEMGREP_TIMEOUT` | Timeout per file (seconds) | 30 |
| `SEMGREP_MAX_TARGET_BYTES` | Max file size (bytes) | 1000000 |
| `SEMGREP_INCI` | CI mode flag | false |
| `SEMGREP_SEND_METRICS` | Send usage metrics | auto |
| `SEMGREP_APP_TOKEN` | Semgrep App token | (empty) |
| `SEMGREP_USER_REGISTRY_URL` | Custom rule registry URL | (empty) |

### Command-Line Flags Reference

| Flag | Description |
|------|-------------|
| `--config <config>` | Rule source (file, URL, or policy) |
| `--config auto` | Auto-detect rules |
| `--config p/<policy>` | Semgrep App policy |
| `--config-rule-id <id>` | Run specific rule ID |
| `--severity <level>` | Filter by severity |
| `--include <pattern>` | Include files matching pattern |
| `--exclude <pattern>` | Exclude files matching pattern |
| `--exclude-dir <dir>` | Exclude directories |
| `--max-target-bytes <n>` | Max file size |
| `--timeout <n>` | Timeout per file |
| `--autofix` | Apply autofixes |
| `--dry-run` | Show what autofix would change |
| `--sarif` | Output SARIF format |
| `--json` | Output JSON format |
| `--gitlab-sast` | Output GitLab SAST format |
| `--text` | Output text format |
| `--emacs` | Output Emacs format |
| `--vim` | Output Vim format |
| `--error` | Exit code 1 on findings |
| `--strict` | Exit code 1 on warnings too |
| `--no-git` | Don't use Git metadata |
| `--verbose` | Verbose output |
| `--debug` | Debug output |
| `--quiet` | Minimal output |
| `--validate` | Validate rules only |
| `--test` | Test rules against samples |
| `--diff` | Scan only changed files |
| `--from-ref <ref>` | Git ref to compare from |

---

## 14. Real-World Examples

### Example 1: Scanning Contoso Pet Store (Python/Flask)

```bash
# Project structure
contoso-petstore/
├── app.py
├── models/
│   └── pet.py
├── routes/
│   ├── __init__.py
│   └── pets.py
├── utils/
│   └── db.py
├── requirements.txt
├── .semgrepignore
└── .semgrep.yml
```

```yaml
# .semgrep.yml
rules:
  - id: sql-injection-flask
    patterns:
      - pattern-either:
          - pattern: |
              $QUERY = "..." + $INPUT
              ...
              db.execute($QUERY)
          - pattern: |
              $QUERY = f"...{$INPUT}..."
              ...
              db.execute($QUERY)
    message: >
      SQL injection risk: $INPUT is used in a SQL query.
      Use parameterized queries.
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-89: SQL Injection"

  - id: no-debug-in-production
    pattern-either:
      - pattern: |
          app.run(debug=True)
      - pattern: |
          DEBUG = True
    message: Disable debug mode in production.
    languages: [python]
    severity: WARNING
    metadata:
      category: best-practice

  - id: hardcoded-secret-key
    patterns:
      - pattern: |
          app.config['SECRET_KEY'] = "..."
    message: Hardcoded Flask secret key. Use environment variables.
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-798: Hard-coded Credentials"
```

```bash
# Run scan
semgrep scan --config .semgrep.yml

# Run with auto-detected rules
semgrep scan --config auto --config .semgrep.yml

# Run in CI
semgrep ci --config auto --config .semgrep.yml --sarif -o results.sarif
```

### Example 2: Scanning Contoso Pet Store (Node.js/Express)

```yaml
# .semgrep.yml
rules:
  - id: xss-express-res-send
    pattern: res.send($INPUT)
    message: >
      Avoid res.send() with user input — use res.json() or
      set Content-Type header explicitly.
    languages: [javascript, typescript]
    severity: WARNING
    metadata:
      category: security
      cwe:
        - "CWE-79: Cross-site Scripting"

  - id: eval-js
    pattern-either:
      - pattern: eval(...)
      - pattern: new Function(...)
      - pattern: setTimeout("...", ...)
    message: Avoid eval() and new Function() — use safer alternatives.
    languages: [javascript, typescript]
    severity: ERROR
    metadata:
      category: security

  - id: no-console-log
    pattern: console.log(...)
    message: Remove console.log() before deploying.
    languages: [javascript, typescript]
    severity: WARNING
    metadata:
      category: best-practice
```

### Example 3: Custom Rule Library

```yaml
# .semgrep.yml — Organization-wide rules
rules:
  # Security rules
  - id: org-no-eval
    pattern-either:
      - pattern: eval(...)
      - pattern: exec(...)
      - pattern: new Function(...)
    message: Use safer alternatives to eval/exec.
    languages: [python, javascript, java]
    severity: ERROR
    metadata:
      category: security
      org-level: true

  # Performance rules
  - id: org-no-nested-loops
    pattern: |
      for $X in $ITER1:
          for $Y in $ITER2:
              ...
    message: Nested loops detected — consider refactoring for performance.
    languages: [python]
    severity: WARNING
    metadata:
      category: performance
      org-level: true

  # Style rules
  - id: org-no-single-letter-variables
    pattern: |
      def $FUNC(..., $X, ...):
          ...
    message: Use descriptive variable names instead of single letters.
    languages: [python]
    severity: INFO
    metadata:
      category: style
      org-level: true
```

### Example 4: Taint Mode Security Rules

```yaml
rules:
  - id: command-injection-python
    mode: taint
    pattern-sources:
      - patterns:
          - pattern: $INPUT = request.args.get(...)
          - pattern: $INPUT = request.form[...]
          - pattern: $INPUT = request.json[...]
    pattern-sinks:
      - pattern: |
          os.system($INPUT)
      - pattern: |
          subprocess.call(..., shell=True, ...)
      - pattern: |
          subprocess.Popen(..., shell=True, ...)
    pattern-sanitizers:
      - pattern: shlex.quote(...)
    message: >
      User input flows into a shell command.
      Use subprocess with shell=False or sanitize input.
    languages: [python]
    severity: ERROR
    metadata:
      category: security
      cwe:
        - "CWE-78: OS Command Injection"
```

---

## 15. Further Reading

### Official Documentation
- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Semgrep Rule Writing Guide](https://semgrep.dev/docs/writing-rules/)
- [Semgrep Pattern Syntax](https://semgrep.dev/docs/writing-rules/pattern-syntax/)
- [Semgrep Operators](https://semgrep.dev/docs/writing-rules/operators/)
- [Semgrep Taint Mode](https://semgrep.dev/docs/writing-rules/taint-mode/)
- [Semgrep CI Integration](https://semgrep.dev/docs/integrations/)

### Semgrep Community
- [Semgrep Slack](https://semgrep.dev/slack)
- [Semgrep GitHub](https://github.com/semgrep/semgrep)
- [Semgrep Rules Registry](https://semgrep.dev/explore)
- [Semgrep Blog](https://semgrep.dev/blog)

### OWASP References
- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)

### Related Tools
- [SonarQube Guide](./sonarqube.md) — Comprehensive code quality platform
- [Gitleaks Guide](./gitleaks.md) — Secret detection in Git

### Books & Resources
- "Secure Coding in Python" — OWASP
- "The Tangled Web" — Michal Zalewski
- "Hacking: The Art of Exploitation" — Jon Erickson

---

*Last updated: 2026*
