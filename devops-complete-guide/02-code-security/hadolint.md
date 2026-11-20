# Hadolint Complete Guide

## Table of Contents

1. [What Is Hadolint](#1-what-is-hadolint)
2. [Why Use Hadolint](#2-why-use-hadolint)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Rule Reference](#7-rule-reference)
8. [Custom Rules](#8-custom-rules)
9. [Integration](#9-integration)
10. [Security Considerations](#10-security-considerations)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips & Best Practices](#12-tips--best-practices)
13. [Command Reference](#13-command-reference)
14. [Configuration Reference](#14-configuration-reference)
15. [Real-World Examples](#15-real-world-examples-contoso-pet-store)
16. [Further Reading](#16-further-reading)

---

## 1. What Is Hadolint

Hadolint is a Dockerfile linter that helps build best-practice Docker images by parsing the Dockerfile, analyzing the instructions using [Haskell](https://www.haskell.org/), and applying rules based on the [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) and common security pitfalls.

### Key Characteristics

- **Dockerfile-native linter**: Understands Dockerfile syntax, not just line-based patterns
- **200+ built-in rules**: Covers best practices, security, performance, and maintainability
- **Shell-aware**: Analyzes shell commands within RUN instructions
- **Multi-stage aware**: Understands build stages and their interactions
- **JSON output**: Machine-readable output for CI/CD integration
- **Inline ignore**: Suppress specific rules per line with inline comments
- **Config file support**: `.hadolint.yaml` for persistent configuration
- **Standalone binary**: No Docker required to lint Dockerfiles
- **Cross-platform**: Linux, macOS, Windows, Docker

### History

Hadolint was created by Luca Londero in 2016 as a Haskell project. It has grown to become the most comprehensive Dockerfile linter, with rules covering everything from security best practices to layer optimization. The name "Hadolint" comes from "Hadolint" — a play on "hadolint" (Haskell + Docker + lint).

### Architecture

```
┌─────────────────────────────────────────┐
│             Hadolint                     │
├─────────────────────────────────────────┤
│  Parser                                 │
│  ├─ Dockerfile AST (Abstract Syntax)    │
│  ├─ Shell command parsing (Bash)        │
│  └─ Multi-stage resolution              │
├─────────────────────────────────────────┤
│  Rule Engine                            │
│  ├─ 200+ built-in rules                 │
│  ├─ Severity levels (error/warn/info)   │
│  ├─ Rule exclusions                     │
│  └─ Custom rule framework               │
├─────────────────────────────────────────┤
│  Output Formatters                      │
│  ├─ TTY (colored terminal)              │
│  ├─ JSON                                │
│  ├─ JSON (one-line per finding)         │
│  ├─ SARIF                               │
│  └─ Codeclimate                         │
└─────────────────────────────────────────┘
```

### Rule Severity Levels

| Level | Meaning | Default |
|-------|---------|---------|
| `error` | Must fix — violates best practices or security | Always shown |
| `warning` | Should fix — potential issues | Shown by default |
| `info` | Could fix — suggestions for improvement | Shown by default |
| `style` | Optional — style preferences | Hidden by default |
| `ignore` | Suppressed — not shown | Never shown |

---

## 2. Why Use Hadolint

### The Problem

Dockerfiles are deceptively simple but contain many pitfalls:

1. **Security vulnerabilities**: Running as root, using `latest` tag, embedding secrets
2. **Image bloat**: Unnecessary files, duplicate layers, large base images
3. **Build failures**: Inconsistent builds, missing dependencies, caching issues
4. **Maintainability**: Hardcoded values, complex RUN commands, poor layering

### Example: Common Dockerfile Mistakes

```dockerfile
# BAD: Multiple issues
FROM ubuntu:latest          # 1. Using :latest tag
RUN apt-get update          # 2. Not cleaning up
RUN apt-get install -y curl # 3. Separate RUN = extra layers
RUN curl https://example.com/secret.sh | bash  # 4. Piping curl to bash
EXPOSE 22                   # 5. Exposing SSH
USER root                   # 6. Running as root
ADD ./config /etc/app       # 7. Using ADD instead of COPY
```

Hadolint catches all of these and more.

### Why Hadolint Over Alternatives

| Feature | Hadolint | Dockerfilelint | Docker Scout | Trivy |
|---------|---------|----------------|--------------|-------|
| Standalone binary | Yes | No (Node.js) | No (Docker) | Yes |
| 200+ rules | Yes | ~50 | Security only | Security only |
| Shell analysis | Yes | Limited | No | No |
| Multi-stage aware | Yes | Limited | No | No |
| Custom rules | Yes | No | No | No |
| SARIF output | Yes | No | Yes | Yes |
| JSON output | Yes | Yes | Yes | Yes |
| Offline mode | Yes | No | No | Partial |
| No Docker required | Yes | Yes | No | Yes |

### Use Cases

1. **CI/CD gates**: Block PRs with Dockerfile violations
2. **Security audits**: Find root containers, secrets, and vulnerabilities
3. **Image optimization**: Reduce image size and layers
4. **Code review**: Automated Dockerfile review in pull requests
5. **Compliance**: Meet organizational Dockerfile standards
6. **Education**: Learn Dockerfile best practices

---

## 3. Installation

### Method 1: Binary Release (Recommended)

```bash
# Linux (amd64)
curl -sSL -o hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# Linux (arm64)
curl -sSL -o hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-arm64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# macOS (amd64)
curl -sSL -o hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-x86_64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# macOS (arm64 / Apple Silicon)
curl -sSL -o hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-arm64
chmod +x hadolint
sudo mv hadolint /usr/local/bin/

# Verify
hadolint --version
```

### Method 2: Docker

```bash
# Lint local Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile

# Lint with bind mount
docker run --rm -v "$PWD:/work" -w /work hadolint/hadolint Dockerfile

# Lint all Dockerfiles in directory
find . -name "Dockerfile*" | xargs -I {} docker run --rm -i hadolint/hadolint < {}
```

### Method 3: Homebrew (macOS)

```bash
brew install hadolint
```

### Method 4: pip (wraps Docker)

```bash
pip install dockerfilelint  # Note: this is a different tool
# For hadolint, use the binary or Docker approach
```

### Method 5: Snap (Linux)

```bash
sudo snap install hadolint
```

### Method 6: Chocolatey (Windows)

```powershell
choco install hadolint
```

### Method 7: Scoop (Windows)

```powershell
scoop install hadolint
```

### Method 8: Nix

```bash
nix-env -i hadolint
# Or in flake
nix run github:hadolint/hadolint
```

### Method 9: Build from Source (Haskell Stack)

```bash
# Install Haskell Stack first
curl -sSL https://get.haskellstack.org/ | sh

# Clone and build
git clone https://github.com/hadolint/hadolint.git
cd hadolint
stack build
stack install

# Binary will be in ~/.local/bin/hadolint
```

### Method 10: Pre-commit Framework

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
```

---

## 4. Configuration

### Configuration File: `.hadolint.yaml`

Place in project root or `~/.config/hadolint.yaml`:

```yaml
# .hadolint.yaml

# Override rule severity
override:
  error:
    - DL3000  # Use absolute WORKDIR
    - DL3001  # Invalid CMD form
    - DL3002  # Last USER should not be root
    - DL3003  # Use WORKDIR not cd
    - DL3006  # Always tag :version in FROM
    - DL3007  # Using latest is allowed
    - DL3008  # Pin versions in apt-get
    - DL3009  # Delete apt lists after install
    - DL3010  # Use ADD for archives
    - DL3011  # Valid EXPOSE port
    - DL3015  # Avoid additional packages
    - DL3016  # Pin versions in npm
    - DL3018  # Pin versions in apk add
    - DL3019  # Use --no-cache in apk
    - DL3020  # Use COPY instead of ADD for files
    - DL3021  # COPY has more than 2 args
    - DL3022  # COPY --from should reference previous stage
    - DL3023  # COPY --from should reference named stage
    - DL3024  # Use multi-stage builds
    - DL3025  # Use JSON form for CMD
    - DL3026  # Only one CMD allowed
    - DL3027  # Do not use apt-get upgrade
    - DL3028  # Pin versions in gem install
    - DL3029  # Do not use --platform
    - DL3030  # Use --no-cache in apk upgrade
    - DL3031  # Pin versions in pip
    - DL3032  # Pin versions in yarn
    - DL3033  # Pin versions in pacman
    - DL3034  # Use -y in pacman
    - DL3035  # Use --no-cache in pip
    - DL3036  # Use -y in apt-get
    - DL3037  # Pin versions in dnf
    - DL3038  # Pin versions in zypper
    - DL3039  # Use --no-cache in dnf
    - DL3040  # Pin versions in bower
    - DL3041  # Pin versions in composer
    - DL3042  # Avoid wget, use curl
    - DL3043  # Use COPY instead of RUN cd
    - DL3044  # Use ENV for environment variables
    - DL3045  # COPY should use --chown
    - DL3046  # Avoid imagecopyfrom
    - DL3047  # Avoid wget in curl form
    - DL3048  # Pin versions in conda
    - DL3049  # Use LABEL instead of maintainer
    - DL3050  # Use --no-install-recommends
    - DL3051  # Pin versions in cargo
    - DL3052  # Pin versions in nuget
    - DL3053  # Pin versions in dotnet
    - DL3056  # Do not define CMD or ENTRYPOINT in shell form
    - DL3057  # Use COPY instead of RUN echo
    - DL3058  # Pin versions in cabal
    - DL3059  # Multiple consecutive RUN
    - DL3060  # Use --no-cache-dir in pip
    - DL3061  # Pin versions in docker-compose
    - DL3062  # Use --no-install-recommends
    - DL3063  # Pin versions in go get
    - DL3064  # Pin versions in npm install
    - DL3065  # Pin versions in pip install
    - DL3066  # Pin versions in composer install
    - DL3067  # Pin versions in go install
    - DL3068  # Pin versions in yarn install
    - DL3069  # Pin versions in bundle install
    - DL3070  # Pin versions in gem install
    - DL3071  # Pin versions in npm install
    - DL3072  # Pin versions in composer require
    - DL3073  # Pin versions in go install
    - DL3074  # Pin versions in yarn add
    - DL3075  # Pin versions in bundle add
    - DL3076  # Pin versions in gem install
    - DL3077  # Pin versions in npm install
    - DL3078  # Pin versions in composer require
    - DL3079  # Pin versions in go install
    - DL3080  # Pin versions in yarn add
    - DL3081  # Pin versions in bundle add
    - DL3082  # Pin versions in gem install
    - DL3083  # Pin versions in npm install
    - DL3084  # Pin versions in composer require
    - DL3085  # Pin versions in go install
    - DL3086  # Pin versions in yarn add
    - DL3087  # Pin versions in bundle add
    - DL3088  # Pin versions in gem install
    - DL3089  # Pin versions in npm install
    - DL3090  # Pin versions in composer require
    - DL3091  # Pin versions in go install
    - DL3092  # Pin versions in yarn add
    - DL3093  # Pin versions in bundle add
    - DL3094  # Pin versions in gem install
    - DL3095  # Pin versions in npm install
    - DL3096  # Pin versions in composer require
    - DL3097  # Pin versions in go install
    - DL3098  # Pin versions in yarn add
    - DL3099  # Pin versions in bundle add

  warning:
    - DL3001  # Invalid CMD form
    - DL3003  # Use WORKDIR not cd
    - DL3006  # Always tag :version in FROM
    - DL3007  # Using latest tag
    - DL3015  # Avoid additional packages
    - DL3025  # Use JSON form for CMD

  info:
    - DL3000  # Use absolute WORKDIR

  style: []

# Trusted registries (don't require explicit registry in FROM)
trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io
  - registry.access.redhat.com
  - public.ecr.aws

# Global ignores (disable rules entirely)
ignored: []

# Dockerfile path (default: Dockerfile)
dockerfile: "Dockerfile"

# No color output
noColor: false

# Format: tty, json, json-failure-only, sarif, codeclimate
format: "tty"

# List of warning/error codes to treat as strict (non-zero exit)
strictLabels: false

```

### Minimal Configuration

```yaml
# .hadolint.yaml — minimal
ignored:
  - DL3008  # Don't require pinned apt-get versions (for dev images)
  - DL3015  # Don't require --no-install-recommends

trustedRegistries:
  - docker.io
  - gcr.io
```

### Per-File Configuration

```yaml
# .hadolint.yaml
perFileRules:
  "Dockerfile.test":
    ignored:
      - DL3002  # Allow root user in test containers
      - DL3008  # Allow unpinned versions in test

  "Dockerfile.prod":
    override:
      error:
        - DL3000  # Require absolute WORKDIR
        - DL3002  # Never run as root
        - DL3006  # Always tag versions
        - DL3008  # Pin all apt versions
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HADOLINT_CONFIG` | Path to config file | `.hadolint.yaml` |
| `HADOLINT_FAILURE_THRESHOLD` | Minimum severity to cause non-zero exit | `warning` |
| `HADOLINT_FORMAT` | Output format | `tty` |
| `HADOLINT_NO_COLOR` | Disable color output | `false` |

---

## 5. Core Concepts

### Dockerfile Parsing

Hadolint parses the Dockerfile into an Abstract Syntax Tree (AST), understanding:

- **Instructions**: FROM, RUN, COPY, ADD, ENV, ARG, EXPOSE, CMD, ENTRYPOINT, etc.
- **Multi-stage builds**: References between stages
- **Variable substitution**: ${VAR} in RUN, COPY, ENV
- **Shell form vs exec form**: Different semantics for RUN/CMD/ENTRYPOINT

```dockerfile
# Hadolint understands this is exec form (correct)
CMD ["nginx", "-g", "daemon off;"]

# And this is shell form (less optimal)
CMD nginx -g "daemon off;"
```

### Rule Categories

| Category | Rules | Description |
|----------|-------|-------------|
| Best Practice | DL3000-DL3099 | Dockerfile best practices |
| Security | DL3002, DL3007, DL4006 | Security-related rules |
| Performance | DL3003, DL3009, DL3059 | Image optimization |
| Maintainability | DL3001, DL3025, DL3042 | Code quality |
| Deprecated | DL3004, DL4001, DL4003 | Deprecated practices |

### Shell Analysis

Hadolint can analyze shell commands inside RUN instructions:

```dockerfile
# Hadolint detects:
RUN apt-get update && apt-get install -y curl  # Good: combined
RUN apt-get update  # Bad: separate RUN
RUN apt-get install -y curl  # Bad: separate RUN
```

It also detects:
- Pipe to bash (`curl | bash`) — security risk
- Missing `--no-install-recommends` — image bloat
- Not cleaning up apt cache — wasted space
- Using `cd` instead of `WORKDIR` — fragile

### Multi-Stage Build Analysis

```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Runtime
FROM gcr.io/distroless/static
COPY --from=builder /app/myapp /myapp
CMD ["/myapp"]
```

Hadolint checks:
- Are there unnecessary files being copied between stages?
- Is the final stage using a minimal base image?
- Are there unused stages?

### Severity Levels in Practice

```dockerfile
# ERROR: DL3007 - Using latest is prone to errors
FROM node:latest

# WARNING: DL3008 - Pin versions in apt-get
RUN apt-get update && apt-get install -y curl

# INFO: DL3015 - Consider using --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends curl

# STYLE: (not shown by default)

# IGNORED: (via inline comment)
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y curl
```

---

## 6. Usage Guide

### Step 1: Basic Linting

```bash
# Lint a Dockerfile
hadolint Dockerfile

# Lint from stdin
cat Dockerfile | hadolint -

# Lint with error severity only
hadolint --failure-threshold error Dockerfile
```

### Step 2: Configure Output Format

```bash
# JSON output for CI/CD
hadolint --format json Dockerfile

# SARIF output for security tools
hadolint --format sarif Dockerfile

# CodeClimate output
hadolint --format codeclimate Dockerfile

# No color
hadolint --no-color Dockerfile
```

### Step 3: Ignore Specific Rules

```bash
# Inline ignore (per line)
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y curl

# Command-line ignore
hadolint --ignore DL3008 --ignore DL3015 Dockerfile

# Config file ignore
cat > .hadolint.yaml << 'EOF'
ignored:
  - DL3008
  - DL3015
EOF
```

### Step 4: Enforce Strict Rules

```bash
# Exit with error for any finding
hadolint --failure-threshold info Dockerfile

# Exit with error only for errors
hadolint --failure-threshold error Dockerfile

# Ignore warnings, only fail on errors
hadolint --failure-threshold warning Dockerfile
```

### Step 5: Lint Multiple Dockerfiles

```bash
# Find and lint all Dockerfiles
find . -name "Dockerfile*" -exec hadolint {} \;

# With exclusions
find . -name "Dockerfile*" \
    ! -path "*/vendor/*" \
    ! -path "*/node_modules/*" \
    -exec hadolint {} \;

# Parallel linting
find . -name "Dockerfile*" | xargs -P 4 -I {} hadolint {}
```

### Step 6: CI/CD Integration

```bash
# GitHub Actions
hadolint --format sarif --failure-threshold warning Dockerfile > hadolint.sarif

# GitLab CI
hadolint --format json --failure-threshold error Dockerfile > hadolint-report.json

# Jenkins
hadolint --failure-threshold warning Dockerfile
if [ $? -ne 0 ]; then
    echo "Dockerfile linting failed"
    exit 1
fi
```

### Step 7: Custom Configuration

```yaml
# .hadolint.yaml
override:
  error:
    - DL3000  # Absolute WORKDIR
    - DL3002  # Last USER not root
    - DL3006  # Tag FROM versions
    - DL3008  # Pin apt versions
  warning:
    - DL3003  # Use WORKDIR not cd
    - DL3015  # Avoid extra packages
  info:
    - DL3007  # Using latest

trustedRegistries:
  - docker.io
  - gcr.io

ignored: []
```

### Step 8: SARIF Output for Security Dashboards

```bash
hadolint --format sarif Dockerfile > hadolint.sarif

# Upload to GitHub Security
gh api repos/{owner}/{repo}/code-scanning/sarifs \
    -H "Accept: application/vnd.github+json" \
    --input hadolint.sarif
```

---

## 7. Rule Reference

### Common Rules (DL3xxx)

#### DL3000: Use absolute WORKDIR

```dockerfile
# BAD
WORKDIR /app
WORKDIR src

# GOOD
WORKDIR /app
WORKDIR /app/src
```

#### DL3001: Invalid CMD form

```dockerfile
# BAD
CMD echo "Hello"

# GOOD
CMD ["echo", "Hello"]

# GOOD
CMD ["./myapp"]
```

#### DL3002: Last USER should not be root

```dockerfile
# BAD
USER root

# GOOD
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

#### DL3003: Use WORKDIR instead of cd

```dockerfile
# BAD
RUN cd /app && npm install

# GOOD
WORKDIR /app
RUN npm install
```

#### DL3006: Always tag :version in FROM

```dockerfile
# BAD
FROM node

# GOOD
FROM node:20-slim
```

#### DL3007: Using latest tag is prone to errors

```dockerfile
# BAD
FROM node:latest

# GOOD
FROM node:20.11-slim
```

#### DL3008: Pin versions in apt-get

```dockerfile
# BAD
RUN apt-get update && apt-get install -y curl

# GOOD
RUN apt-get update && apt-get install -y curl=7.88.1-10+deb12u5
```

#### DL3009: Delete apt lists after installing

```dockerfile
# BAD
RUN apt-get update && apt-get install -y curl

# GOOD
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

#### DL3010: Use ADD for archives that need extracting

```dockerfile
# BAD
RUN curl -L https://example.com/archive.tar.gz | tar -xz

# GOOD
ADD https://example.com/archive.tar.gz /tmp/
RUN tar -xzf /tmp/archive.tar.gz -C /opt/
```

#### DL3015: Avoid additional packages

```dockerfile
# BAD
RUN apt-get update && apt-get install -y curl wget

# GOOD
RUN apt-get update && apt-get install -y --no-install-recommends curl
```

#### DL3020: Use COPY instead of ADD for files

```dockerfile
# BAD
ADD ./config.yml /etc/app/

# GOOD
COPY ./config.yml /etc/app/
```

#### DL3025: Use JSON form for CMD

```dockerfile
# BAD
CMD nginx -g "daemon off;"

# GOOD
CMD ["nginx", "-g", "daemon off;"]
```

#### DL3042: Avoid wget; use curl

```dockerfile
# BAD
RUN wget https://example.com/file

# GOOD
RUN curl -fsSL https://example.com/file -o /tmp/file
```

#### DL3045: COPY should use --chown

```dockerfile
# BAD
COPY . /app/

# GOOD
COPY --chown=appuser:appuser . /app/
```

#### DL3047: Avoid wget; use curl form

```dockerfile
# BAD
RUN wget -O /tmp/file https://example.com/file

# GOOD
RUN curl -fsSL -o /tmp/file https://example.com/file
```

#### DL3049: Use LABEL instead of maintainer

```dockerfile
# BAD
MAINTAINER John Doe <john@example.com>

# GOOD
LABEL maintainer="John Doe <john@example.com>"
```

#### DL3050: Use --no-install-recommends

```dockerfile
# BAD
RUN apt-get install -y curl

# GOOD
RUN apt-get install -y --no-install-recommends curl
```

### Security Rules (DL4xxx)

#### DL4001: Use wget and curl; avoid single curl/wget piped to sh/bash

```dockerfile
# BAD
RUN curl https://example.com/install.sh | bash

# GOOD
RUN curl -fsSL https://example.com/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh \
    && rm /tmp/install.sh
```

#### DL4003: Use WORKDIR for directory changes

```dockerfile
# BAD
RUN cd /app && npm install

# GOOD
WORKDIR /app
RUN npm install
```

#### DL4006: Set the SHELL option -o pipefail before a pipe

```dockerfile
# BAD
RUN curl https://example.com | tar -xz

# GOOD
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://example.com | tar -xz
```

#### DL4009: Delete fetched archives after extracting

```dockerfile
# BAD
ADD https://example.com/archive.tar.gz /tmp/
RUN tar -xzf /tmp/archive.tar.gz

# GOOD
ADD https://example.com/archive.tar.gz /tmp/
RUN tar -xzf /tmp/archive.tar.gz && rm /tmp/archive.tar.gz
```

### Deprecated Rules

| Rule | Replacement |
|------|-------------|
| DL3004 | Use LABEL instead of MAINTAINER |
| DL4001 | DL4006 (SHELL pipefail) |
| DL4003 | DL3003 (Use WORKDIR) |

### Complete Rule List

Hadolint has 200+ rules. Key categories:

**DL3000-DL3099**: Best practices (workdir, cmd, user, apt, npm, pip, etc.)
**DL4000-DL4099**: Deprecated/incorrect usage
**DL5000-DL5099**: Buildkit features (HEALTHCHECK, etc.)
**SC2xxx**: ShellCheck rules (applied to RUN instructions)
**SHA1xxx**: Hadolint internal rules

---

## 8. Custom Rules

### Creating Custom Rules (Haskell)

Hadolint supports custom rules via Haskell:

```haskell
-- src/Hadolint/Rule/CustomRule.hs
module Hadolint.Rule.CustomRule (rule) where

import Hadolint.Syntax
import Hadolint.Rule

rule :: Rule
rule = Rule
    { code = "CR001"
    , severity = WarningC
    , message = "Custom: Use specific version in FROM"
    , checker = checkFrom
    }

checkFrom :: Dockerfile -> [CheckResult]
checkFrom dockerfile =
    [ CheckResult
        { code = "CR001"
        , severity = WarningC
        , message = "FROM uses 'latest' tag"
        , position = instructionPos instruction
        }
    | instruction <- dockerfile
    , isFrom instruction
    , hasLatestTag instruction
    ]

isFrom :: Instruction -> Bool
isFrom (From _) = True
isFrom _ = False

hasLatestTag :: Instruction -> Bool
hasLatestTag (From (BaseImage name _)) = name == "latest" || ':' `notElem` name
hasLatestTag _ = False
```

### Rule Definition

```haskell
data Rule = Rule
    { code     :: RuleCode      -- e.g., "DL3000"
    , severity :: Severity       -- ErrorC, WarningC, InfoC, StyleC
    , message  :: String         -- Human-readable message
    , checker  :: Dockerfile -> [CheckResult]
    }

data CheckResult = CheckResult
    { code     :: RuleCode
    , severity :: Severity
    , message  :: String
    , position :: Position       -- File, line, column
    }
```

### Registering Custom Rules

```haskell
-- src/Hadolint/Rule/List.hs
module Hadolint.Rule.List (rules) where

import qualified Hadolint.Rule.DL3000 as DL3000
import qualified Hadolint.Rule.DL3001 as DL3001
-- ...
import qualified Hadolint.Rule.CustomRule as CustomRule

rules :: [Rule]
rules =
    [ DL3000.rule
    , DL3001.rule
    -- ...
    , CustomRule.rule  -- Add custom rule here
    ]
```

### Regex-Based Rules (Config)

```yaml
# .hadolint.yaml
override:
  customRules:
    - code: "CUSTOM001"
      regex: "FROM.*:latest"
      severity: warning
      message: "Avoid using :latest tag"
    
    - code: "CUSTOM002"
      regex: "curl.*\\|.*bash"
      severity: error
      message: "Avoid piping curl to bash"
    
    - code: "CUSTOM003"
      regex: "EXPOSE.*22"
      severity: warning
      message: "Avoid exposing SSH port"
```

---

## 9. Integration

### Pre-commit Framework

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
        args: ['--failure-threshold', 'warning']
```

### GitHub Actions

```yaml
# .github/workflows/hadolint.yml
name: Hadolint

on:
  push:
    paths:
      - '**/Dockerfile*'
      - '**/docker-compose*.yml'
  pull_request:
    paths:
      - '**/Dockerfile*'

jobs:
  hadolint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          failure-threshold: warning
          format: sarif
          output-file: hadolint.sarif
          no-fail: false

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: hadolint.sarif

      - name: Lint all Dockerfiles
        run: |
          find . -name "Dockerfile*" | while read f; do
            echo "=== Linting $f ==="
            hadolint --failure-threshold warning "$f"
          done
```

### GitLab CI

```yaml
# .gitlab-ci.yml
hadolint:
  stage: lint
  image: hadolint/hadolint:latest-debian
  script:
    - hadolint --format json --failure-threshold warning Dockerfile > hadolint.json
  artifacts:
    reports:
      sast: hadolint.json
  allow_failure: false
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage('Hadolint') {
            steps {
                sh '''
                    docker run --rm \
                        -v "$WORKSPACE:/work" \
                        hadolint/hadolint:latest \
                        hadolint --format json /work/Dockerfile > hadolint.json
                '''
                
                archiveArtifacts artifacts: 'hadolint.json'
            }
            post {
                failure {
                    sh 'echo "Dockerfile linting failed - check Hadolint report"'
                }
            }
        }
    }
}
```

### VS Code Integration

Install the "Hadolint" extension from the marketplace:

```json
// .vscode/settings.json
{
    "hadolint.dockerfile": "Dockerfile",
    "hadolint.args": ["--failure-threshold", "warning"],
    "hadolint.enable": true
}
```

### IntelliJ IDEA

Install the "Dockerfile" plugin which includes Hadolint support:

1. Settings → Plugins → Dockerfile
2. Enable Hadolint in Settings → Tools → Dockerfile
3. Set Hadolint path and arguments

### Docker Compose Linting

```bash
# Lint docker-compose files (separate tool)
docker-compose -f docker-compose.yml config

# Lint all Dockerfiles in compose projects
for f in $(yq '.services.*.build.dockerfile // empty' docker-compose.yml); do
    hadolint "$f"
done
```

### Makefile Integration

```makefile
.PHONY: lint-docker

lint-docker:
	@echo "Linting Dockerfiles..."
	@find . -name "Dockerfile*" -exec hadolint --failure-threshold warning {} +
	@echo "All Dockerfiles pass linting"

lint-docker-strict:
	@echo "Strict linting Dockerfiles..."
	@find . -name "Dockerfile*" -exec hadolint --failure-threshold error {} +
	@echo "All Dockerfiles pass strict linting"
```

### CI/CD Pipeline Example (Complete)

```yaml
# .github/workflows/docker-lint-build-push.yml
name: Docker Lint, Build & Push

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint Dockerfile
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          failure-threshold: warning
          format: sarif
          output-file: hadolint.sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: hadolint.sarif

  build:
    needs: lint
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix=

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 10. Security Considerations

### Security-Focused Rules

```yaml
# .hadolint.yaml — strict security profile
override:
  error:
    - DL3002  # Never run as root
    - DL3006  # Always pin versions
    - DL3008  # Pin apt versions
    - DL3009  # Clean apt cache
    - DL4001  # No curl | bash
    - DL4006  # SHELL pipefail
```

### Security Scanning Integration

```yaml
# Combine hadolint with Trivy for comprehensive security
- name: Hadolint
  uses: hadolint/hadolint-action@v3.1.0
  with:
    dockerfile: Dockerfile
    failure-threshold: error

- name: Trivy vulnerability scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE_NAME }}
    format: sarif
    output: trivy.sarif
    severity: CRITICAL,HIGH
```

### Never Embed Secrets

```dockerfile
# BAD — secrets in Dockerfile
ENV API_KEY=sk_live_abc123
COPY .env /app/.env

# GOOD — use build secrets
COPY --from=secrets /run/secrets/api_key /app/api_key
# or BuildKit secrets
RUN --mount=type=secret,id=api_key cat /run/secrets/api_key > /app/api_key
```

### Distroless Base Images

```dockerfile
# GOOD — minimal attack surface
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/myapp /
CMD ["/myapp"]
```

### Non-Root User

```dockerfile
# GOOD — proper user setup
RUN groupadd -r appuser && useradd -r -g appuser -d /home/appuser -s /sbin/nologin appuser
RUN chown -R appuser:appuser /app
USER appuser
```

### Read-Only Filesystem

```yaml
# docker-compose.yml
services:
  app:
    image: myapp:latest
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    security_opt:
      - no-new-privileges:true
```

---

## 11. Troubleshooting

### Issue 1: "hadolint: command not found"

```bash
# Check if installed
which hadolint
hadolint --version

# If not found, reinstall
curl -sSL -o /usr/local/bin/hadolint \
  https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint
```

### Issue 2: "No such file or directory"

```bash
# Check file path
ls -la Dockerfile

# Lint from stdin if path issues
cat Dockerfile | hadolint -
```

### Issue 3: Rules not being suppressed

```bash
# Check inline comment syntax (must be exact)
# hadolint ignore=DL3008
RUN apt-get install -y curl

# Check config file location
cat .hadolint.yaml

# Verify with verbose output
hadolint --verbose Dockerfile
```

### Issue 4: Too many false positives

```yaml
# .hadolint.yaml
ignored:
  - DL3008  # Pin apt versions (not always practical)
  - DL3015  # --no-install-recommends (not always needed)
  - DL3007  # Using :latest (sometimes intentional)

# Or per-file overrides
perFileRules:
  "Dockerfile.dev":
    ignored:
      - DL3008
      - DL3015
```

### Issue 5: JSON output parsing

```bash
# Get error count
hadolint --format json Dockerfile | jq 'length'

# Get only errors
hadolint --format json Dockerfile | jq '.[] | select(.level == "error")'

# Get rule codes
hadolint --format json Dockerfile | jq -r '.[].code' | sort -u
```

### Issue 6: Hadolint exits with code 0 despite issues

```bash
# Ensure --failure-threshold is set appropriately
hadolint --failure-threshold warning Dockerfile

# Or use --strict for all issues
hadolint --failure-threshold info Dockerfile
```

### Issue 7: Docker-based hadolint can't access files

```bash
# Mount current directory
docker run --rm -v "$PWD:/work" -w /work hadolint/hadolint hadolint Dockerfile

# For multi-stage builds with COPY references
docker run --rm \
    -v "$PWD:/work:ro" \
    -w /work \
    hadolint/hadolint hadolint Dockerfile
```

### Issue 8: ShellCheck rules not triggering

```bash
# ShellCheck rules (SC2xxx) require valid shell syntax
# Ensure RUN instructions use proper shell syntax:
RUN /bin/bash -c "complex command here"

# Or use shell form for simple commands
RUN apt-get update && apt-get install -y curl
```

### Issue 9: Config file not being read

```bash
# Check file location (project root or ~/.config/)
ls -la .hadolint.yaml
ls -la ~/.config/hadolint.yaml

# Specify explicitly
hadolint --config .hadolint.yaml Dockerfile

# Set environment variable
export HADOLINT_CONFIG=.hadolint.yaml
hadolint Dockerfile
```

### Issue 10: "Unknown instruction" errors

```bash
# Check Dockerfile syntax
docker build --check .  # Docker 24.0+

# Ensure valid instruction names:
# FROM, RUN, CMD, LABEL, MAINTAINER, EXPOSE, ENV, ADD, COPY,
# ENTRYPOINT, VOLUME, USER, WORKDIR, ARG, ONBUILD, STOPSIGNAL,
# HEALTHCHECK, SHELL
```

### Issue 11: Hadolint is slow on large Dockerfiles

```bash
# Lint specific instructions only
hadolint --format json Dockerfile | jq 'length'

# Or parse and filter
hadolint --format json Dockerfile | \
    jq '[.[] | select(.level == "error")]'
```

### Issue 12: SARIF output is empty

```bash
# Ensure no findings at info level
hadolint --format sarif --failure-threshold warning Dockerfile > hadolint.sarif

# Check SARIF structure
cat hadolint.sarif | jq '.runs[0].results | length'
```

### Issue 13: Inconsistent results between local and CI

```bash
# Pin hadolint version in CI
# GitHub Actions
- uses: hadolint/hadolint-action@v3.1.0
  with:
    version: 'v2.12.0'

# Ensure same config is used
cp .hadolint.yaml $CI_PROJECT_DIR/
```

### Issue 14: Dockerfile syntax not recognized

```bash
# Check Dockerfile extension
ls -la Dockerfile* dockerfile*

# Hadolint expects: Dockerfile, Dockerfile.*, *.dockerfile, *.Dockerfile
hadolint Dockerfile.dev
hadolint docker-compose.dockerfile
```

### Issue 15: "Invalid FROM" error

```dockerfile
# Ensure FROM has valid base image reference
FROM ubuntu:22.04          # OK
FROM golang:1.22-alpine    # OK
FROM node                  # WARNING: no tag
FROM invalid-image:tag     # ERROR: invalid reference
```

### Issue 16: Hadolint can't find referenced files

```dockerfile
# COPY/ADD reference files relative to Dockerfile location
COPY ./config.yml /app/    # Must exist in build context

# For multi-stage builds
COPY --from=builder /app/binary /app/binary
# Ensure "builder" stage exists
```

---

## 12. Tips & Best Practices

### Tip 1: Always Pin Base Image Versions

```dockerfile
# BAD
FROM node

# GOOD
FROM node:20.11-slim
```

### Tip 2: Use Multi-Stage Builds

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Stage 2: Runtime
FROM alpine:3.19
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

### Tip 3: Combine RUN Commands

```dockerfile
# BAD — 3 layers
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# GOOD — 1 layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

### Tip 4: Clean Up in Same Layer

```dockerfile
# Downloads stay in image
RUN curl -fsSL https://example.com/archive.tar.gz -o /tmp/archive.tar.gz
RUN tar -xzf /tmp/archive.tar.gz

# Good: cleanup in same layer
RUN curl -fsSL https://example.com/archive.tar.gz -o /tmp/archive.tar.gz && \
    tar -xzf /tmp/archive.tar.gz && \
    rm /tmp/archive.tar.gz
```

### Tip 5: Use .dockerignore

```
# .dockerignore
.git
.github
.vscode
*.md
LICENSE
Dockerfile*
docker-compose*.yml
.env*
node_modules
__pycache__
*.pyc
```

### Tip 6: Use COPY Instead of ADD

```dockerfile
# BAD — ADD extracts archives automatically
ADD https://example.com/archive.tar.gz /tmp/

# GOOD — explicit and predictable
COPY ./archive.tar.gz /tmp/
RUN tar -xzf /tmp/archive.tar.gz && rm /tmp/archive.tar.gz
```

### Tip 7: Set SHELL pipefail

```dockerfile
# Always set this for RUN with pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -fsSL https://example.com | tar -xz
```

### Tip 8: Use LABEL Instead of MAINTAINER

```dockerfile
# BAD
MAINTAINER John Doe

# GOOD
LABEL maintainer="John Doe <john@example.com>"
LABEL org.opencontainers.image.source="https://github.com/org/repo"
```

### Tip 9: Pin Package Versions

```dockerfile
# BAD
RUN apt-get install -y curl

# GOOD
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl=7.88.1-10+deb12u5 \
    && rm -rf /var/lib/apt/lists/*
```

### Tip 10: Use non-root User

```dockerfile
RUN groupadd -r appuser && useradd -r -g appuser -m -s /sbin/nologin appuser
RUN chown -R appuser:appuser /app
USER appuser
```

### Tip 11: Minimize Layers

```dockerfile
# BAD — 4 layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN rm -rf /var/lib/apt/lists/*

# GOOD — 1 layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl wget && \
    rm -rf /var/lib/apt/lists/*
```

### Tip 12: Use Specific Base Image Tags

```dockerfile
# BAD — too generic
FROM ubuntu

# BETTER — specific version
FROM ubuntu:22.04

# BEST — minimal variant
FROM ubuntu:22.04-slim
```

### Tip 13: Validate Hadolint Output in CI

```bash
# Parse JSON for specific rules
ERRORS=$(hadolint --format json Dockerfile | jq '[.[] | select(.level == "error")] | length')
if [ "$ERRORS" -gt 0 ]; then
    echo "Dockerfile has $ERRORS errors"
    exit 1
fi
```

### Tip 14: Use Per-File Rules for Different Environments

```yaml
# .hadolint.yaml
perFileRules:
  "Dockerfile.dev":
    ignored:
      - DL3002  # Allow root in dev
      - DL3008  # Allow unpinned versions in dev

  "Dockerfile.prod":
    override:
      error:
        - DL3002  # Never root in prod
        - DL3006  # Always pin versions
        - DL3008  # Pin apt versions
```

### Tip 15: Run Hadolint Before Docker Build

```bash
# Catch issues before wasting build time
hadolint Dockerfile && docker build -t myapp .
```

### Tip 16: Use Hadolint in Editor

```bash
# VS Code: install Hadolint extension
# Vim/Neovim: use ale or coc.nvim
# Emacs: use flycheck-hadolint
```

### Tip 17: Combine with Other Security Tools

```yaml
# .github/workflows/security.yml
jobs:
  security:
    steps:
      - name: Hadolint (Dockerfile lint)
        uses: hadolint/hadolint-action@v3.1.0

      - name: Trivy (vulnerability scan)
        uses: aquasecurity/trivy-action@master

      - name: Dockle (best practices)
        uses: goodwithtech/dockle-action@main
```

---

## 13. Command Reference

### Basic Usage

```
hadolint [OPTIONS] [FILE...]

Options:
  -c, --config FILE      Load configuration from FILE
  -f, --format FORMAT    Output format (tty|json|sarif|codeclimate|json-failure-only)
  -t, --failure-threshold SEVERITY  Minimum severity to fail (error|warning|info|style)
  -i, --ignore CODE      Ignore a rule (can be repeated)
  -s, --strict           Treat warnings as errors
  --no-color             Disable colored output
  --verbose              Verbose output
  --version              Show version
  -h, --help             Show help
```

### Format Options

| Format | Description | Use Case |
|--------|-------------|----------|
| `tty` | Colored terminal output | Human reading |
| `json` | JSON array of findings | CI/CD parsing |
| `sarif` | SARIF 2.1.0 format | Security dashboards |
| `codeclimate` | CodeClimate format | Code review tools |
| `json-failure-only` | JSON with findings only (no header) | Minimal CI output |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No findings (or below threshold) |
| 1 | Findings at or above threshold |
| 2 | Invalid arguments |

### Examples

```bash
# Basic linting
hadolint Dockerfile

# JSON output
hadolint --format json Dockerfile

# Only fail on errors
hadolint --failure-threshold error Dockerfile

# Ignore specific rules
hadolint --ignore DL3008 --ignore DL3015 Dockerfile

# Strict mode
hadolint --strict Dockerfile

# Custom config
hadolint --config .hadolint.yaml Dockerfile

# Pipe from stdin
cat Dockerfile | hadolint -

# Lint multiple files
find . -name "Dockerfile*" -exec hadolint {} +

# CI mode (no color, failure threshold)
hadolint --no-color --failure-threshold warning Dockerfile

# SARIF for GitHub Security
hadolint --format sarif Dockerfile > hadolint.sarif
```

---

## 14. Configuration Reference

### Complete Configuration File

```yaml
# .hadolint.yaml — Complete Reference

# =============================================================================
# Output Settings
# =============================================================================
# Disable colored output
noColor: false

# Output format: tty, json, sarif, codeclimate, json-failure-only
format: "tty"

# Minimum severity to cause non-zero exit code
# Options: error, warning, info, style
failureThreshold: "warning"

# =============================================================================
# Rule Overrides
# =============================================================================
override:
  # Rules to treat as errors (always fail)
  error:
    - DL3000  # Use absolute WORKDIR
    - DL3002  # Last USER not root
    - DL3006  # Pin FROM versions
    - DL3008  # Pin apt versions
    - DL3009  # Clean apt cache
    - DL4001  # No curl | bash
    - DL4006  # SHELL pipefail

  # Rules to treat as warnings (fail if threshold is warning)
  warning:
    - DL3003  # Use WORKDIR not cd
    - DL3007  # Using :latest
    - DL3015  # Avoid extra packages
    - DL3025  # Use JSON CMD form

  # Rules to treat as informational
  info:
    - DL3000  # Absolute WORKDIR

  # Rules to show as style suggestions (hidden by default)
  style: []

# =============================================================================
# Rule Suppression
# =============================================================================
# Rules to ignore entirely (never shown)
ignored: []

# =============================================================================
# Trusted Registries
# =============================================================================
# Registries that don't require explicit registry in FROM
trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io
  - registry.access.redhat.com
  - public.ecr.aws
  - mcr.microsoft.com
  - quay.io

# =============================================================================
# Per-File Rules
# =============================================================================
perFileRules:
  # Dev/test Dockerfiles can be more relaxed
  "Dockerfile.dev":
    ignored:
      - DL3002  # Allow root
      - DL3008  # Allow unpinned versions
      - DL3015  # Allow extra packages
    override:
      warning:
        - DL3006  # Still warn on untagged FROM

  # Production Dockerfiles must be strict
  "Dockerfile.prod":
    override:
      error:
        - DL3000  # Absolute WORKDIR
        - DL3002  # Never root
        - DL3006  # Pin versions
        - DL3008  # Pin apt
        - DL3009  # Clean apt
        - DL3015  # Minimal packages
        - DL4001  # No curl | bash
        - DL4006  # SHELL pipefail

  # Test containers can run as root
  "Dockerfile.test":
    ignored:
      - DL3002  # Allow root for test

# =============================================================================
# Custom Rules (Regex-based)
# =============================================================================
customRules:
  - code: "CUSTOM001"
    regex: "FROM.*:latest"
    severity: warning
    message: "Avoid using :latest tag - use specific version"

  - code: "CUSTOM002"
    regex: "curl.*\\|.*bash"
    severity: error
    message: "Avoid piping curl/wget to bash - security risk"

  - code: "CUSTOM003"
    regex: "EXPOSE.*22"
    severity: warning
    message: "Avoid exposing SSH port - use exec instead"

  - code: "CUSTOM004"
    regex: "ADD.*https?://"
    severity: warning
    message: "Use RUN curl/wget instead of ADD for remote files"

  - code: "CUSTOM005"
    regex: "ENV.*PASSWORD|ENV.*SECRET|ENV.*KEY"
    severity: error
    message: "Never embed secrets in ENV - use build secrets"

# =============================================================================
# Dockerfile Path
# =============================================================================
# Default Dockerfile name to look for
dockerfile: "Dockerfile"

# =============================================================================
# Strict Labels
# =============================================================================
# If true, exit non-zero for style-level findings
strictLabels: false
```

### Minimal Production Configuration

```yaml
# .hadolint.yaml — minimal production
override:
  error:
    - DL3002  # Never run as root
    - DL3006  # Pin FROM versions
    - DL3008  # Pin apt versions
    - DL4001  # No curl | bash
    - DL4006  # SHELL pipefail
  warning:
    - DL3003  # Use WORKDIR not cd
    - DL3015  # Minimal packages

trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io

perFileRules:
  "Dockerfile.dev":
    ignored:
      - DL3002
      - DL3008
```

---

## 15. Real-World Examples (Contoso Pet Store)

### Scenario: Contoso Pet Store — Dockerfile Audit

Contoso Pet Store is modernizing their deployment with Docker containers. They have multiple services with different Dockerfiles and need to ensure all follow best practices.

### Step 1: Audit All Dockerfiles

```bash
# Find all Dockerfiles
find . -name "Dockerfile*" -type f

# Example output:
# ./services/api-gateway/Dockerfile
# ./services/payment-service/Dockerfile
# ./services/notification-service/Dockerfile
# ./services/frontend/Dockerfile
# ./services/analytics/Dockerfile

# Lint all Dockerfiles
for f in $(find . -name "Dockerfile*" -type f); do
    echo "=== $f ==="
    hadolint --format json "$f"
done > /tmp/dockerfile-audit.json
```

### Step 2: Analyze Findings

```bash
# Count findings by severity
cat /tmp/dockerfile-audit.json | jq -r '.level' | sort | uniq -c
# Output:
#  45 warning
#  12 error
#   8 info

# Count findings by rule
cat /tmp/dockerfile-audit.json | jq -r '.code' | sort | uniq -c | sort -rn
# Output:
#  15 DL3008  (Pin apt versions)
#  12 DL3015  (Avoid extra packages)
#   8 DL3006  (Tag FROM versions)
#   5 DL3009  (Clean apt cache)
#   4 DL3002  (Last USER not root)
#   3 DL4001  (curl | bash)
#   2 DL4006  (SHELL pipefail)
```

### Step 3: Fix Common Issues

#### API Gateway Dockerfile (Before)

```dockerfile
FROM node
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y python3
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD node server.js
```

#### API Gateway Dockerfile (After)

```dockerfile
# Stage 1: Build
FROM node:20.11-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Stage 2: Runtime
FROM node:20.11-slim
RUN groupadd -r appuser && useradd -r -g appuser -m -s /sbin/nologin appuser
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /app .
EXPOSE 3000
USER appuser
CMD ["node", "server.js"]
```

**Issues fixed:**
- ✅ Pinned FROM version (`node:20.11-slim`)
- ✅ Multi-stage build (smaller image)
- ✅ Non-root user
- ✅ JSON CMD form
- ✅ `npm ci` for reproducible builds
- ✅ Only production dependencies in runtime stage

#### Payment Service Dockerfile (Before)

```dockerfile
FROM python:3
RUN apt-get update && apt-get install -y gcc libpq-dev
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
ENV API_KEY=sk_live_abc123
CMD python app.py
```

#### Payment Service Dockerfile (After)

```dockerfile
FROM python:3.12-slim AS builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /app /app
RUN groupadd -r appuser && useradd -r -g appuser -m -s /sbin/nologin appuser
RUN chown -R appuser:appuser /app
USER appuser
# Use build secrets for API keys
# RUN --mount=type=secret,id=api_key cat /run/secrets/api_key > /app/api_key
CMD ["python", "app.py"]
```

**Issues fixed:**
- ✅ Pinned Python version
- ✅ Multi-stage build
- ✅ No hardcoded secrets
- ✅ `--no-cache-dir` for pip
- ✅ Non-root user
- ✅ JSON CMD form

### Step 4: Create Shared Dockerfile Template

```dockerfile
# templates/Dockerfile.base
# Shared template for all Contoso services

# Stage 1: Build
ARG BASE_IMAGE=node:20.11-slim
FROM ${BASE_IMAGE} AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Stage 2: Runtime
FROM ${BASE_IMAGE}
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r appuser && useradd -r -g appuser -m -s /sbin/nologin appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appuser /app .
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 3000
USER appuser
ENTRYPOINT ["tini", "--"]
CMD ["node", "server.js"]
```

### Step 5: CI/CD Pipeline for Dockerfile Linting

```yaml
# .github/workflows/docker-lint.yml
name: Dockerfile Lint

on:
  push:
    paths:
      - '**/Dockerfile*'
  pull_request:
    paths:
      - '**/Dockerfile*'

jobs:
  hadolint:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        dockerfile:
          - services/api-gateway/Dockerfile
          - services/payment-service/Dockerfile
          - services/notification-service/Dockerfile
          - services/frontend/Dockerfile
          - services/analytics/Dockerfile

    steps:
      - uses: actions/checkout@v4

      - name: Lint ${{ matrix.dockerfile }}
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: ${{ matrix.dockerfile }}
          failure-threshold: error
          format: sarif
          output-file: hadolint-${{ strategy.job-index }}.sarif

      - name: Upload results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: hadolint-results
          path: hadolint-*.sarif
```

### Step 6: Docker Image Security Hardening

```dockerfile
# services/secure-api/Dockerfile
FROM gcr.io/distroless/static-debian12

# Copy binary from build stage
COPY --from=builder /app/myapp /myapp

# Run as non-root (distroless default)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/myapp", "healthcheck"]

CMD ["/myapp"]
```

```yaml
# docker-compose.prod.yml
services:
  secure-api:
    image: gcr.io/contoso/secure-api:${VERSION}
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"
    healthcheck:
      test: ["CMD", "/myapp", "healthcheck"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Step 7: Generate Compliance Report

```bash
#!/bin/bash
# generate-dockerfile-report.sh

REPORT="/tmp/contoso-dockerfile-report.md"
DATE=$(date +%Y-%m-%d)

cat > "$REPORT" << EOF
# Contoso Pet Store — Dockerfile Compliance Report

Date: $DATE

## Summary

| Metric | Value |
|--------|-------|
| Dockerfiles scanned | $(find . -name "Dockerfile*" -type f | wc -l) |
| Total findings | $(cat /tmp/dockerfile-audit.json | wc -l) |
| Errors | $(cat /tmp/dockerfile-audit.json | jq '[.[] | select(.level == "error")] | length') |
| Warnings | $(cat /tmp/dockerfile-audit.json | jq '[.[] | select(.level == "warning")] | length') |

## Top Issues

| Rule | Description | Count |
|------|-------------|-------|
$(cat /tmp/dockerfile-audit.json | jq -r '.code' | sort | uniq -c | sort -rn | head -5 | awk '{printf "| %s | %s | %s |\n", $2, "See https://github.com/hadolint/hadolint/wiki/$2", $1}')

## Recommendations

1. Pin all base image versions in FROM instructions
2. Use multi-stage builds for smaller images
3. Run containers as non-root
4. Clean up apt/pip caches in same layer
5. Use COPY instead of ADD for local files
6. Use SHELL pipefail for piped commands
7. Never embed secrets in ENV or COPY

## Compliance Status

- [ ] All Dockerfiles pass hadolint --failure-threshold error
- [ ] No hardcoded secrets in any Dockerfile
- [ ] All images run as non-root
- [ ] All base images are pinned to specific versions
- [ ] Multi-stage builds used for all services
EOF

echo "Report generated: $REPORT"
```

---

## 16. Further Reading

### Official Resources

- [Hadolint GitHub Repository](https://github.com/hadolint/hadolint)
- [Hadolint Wiki (Rule Reference)](https://github.com/hadolint/hadolint/wiki)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Hadolint Playground](https://hadolint.github.io/hadolint/)

### Related Tools

- [Dockle](https://github.com/goodwithtech/dockle) — Container image security linter
- [Trivy](https://github.com/aquasecurity/trivy) — Vulnerability scanner
- [Docker Scout](https://www.docker.com/products/docker-scout/) — Docker's security scanning
- [Grype](https://github.com/anchore/grype) — Vulnerability scanner
- [Dive](https://github.com/wagoodman/dive) — Image layer analysis

### Security Standards

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST SP 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final) — Application Container Security Guide
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

### Books

- "Docker Deep Side" by Jérôme Petazzoni
- "Docker Security" by Adrian Mouat
- "Container Security" by Liz Rice

### Community

- [Docker Community Slack](https://dockercommunity.slack.com/)
- [Hadolint GitHub Discussions](https://github.com/hadolint/hadolint/discussions)
- [Stack Overflow: hadolint tag](https://stackoverflow.com/questions/tagged/hadolint)

---

*Last updated: 2026-09-03*
*Hadolint version: v2.12.x*
