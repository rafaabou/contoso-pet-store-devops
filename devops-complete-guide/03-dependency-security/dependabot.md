# Dependabot Complete Guide

## Table of Contents

1. [What Is Dependabot](#what-is-dependabot)
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

## What Is Dependabot

Dependabot is GitHub's native automated dependency update tool. It scans your repository's dependency files (package-lock.json, Gemfile.lock, go.sum, requirements.txt, etc.) and automatically creates pull requests to update outdated or vulnerable dependencies. It is deeply integrated into the GitHub platform and requires no external CI/CD configuration.

Dependabot operates in two primary modes:

- **Version Updates**: Monitors dependencies and creates PRs when newer versions are available, respecting your version constraints.
- **Security Updates**: Scans GitHub's Advisory Database and creates PRs specifically when a known vulnerability affects one of your dependencies.

### Architecture Overview

Dependabot runs as a managed service inside GitHub's infrastructure. It:

1. Clones your repository (read-only) on a schedule you define.
2. Parses dependency manifests and lock files using ecosystem-specific parsers.
3. Resolves the dependency graph and checks for known vulnerabilities via GitHub Advisory Database.
4. Determines available updates based on your configuration constraints.
5. Creates pull requests with updated lock files and manifests.
6. Optionally rebases PRs when base branch changes.

Unlike external tools, Dependabot does not execute arbitrary code from your repository during its analysis. It parses dependency files statically, which means it is both fast and secure by design.

### Relationship to GitHub Ecosystem

- **Dependabot alerts**: Security notifications created automatically when GitHub detects a vulnerable dependency in your repository. Found under the "Security" tab.
- **Dependabot security updates**: Automated PRs that fix vulnerabilities by bumping dependencies to patched versions.
- **Dependabot version updates**: Scheduled PRs that keep dependencies current, configured via `dependabot.yml`.
- **GitHub Advisory Database**: The centralized vulnerability database that Dependabot queries (sourced from NVD, maintainer reports, and security researchers).
- **Code scanning / CodeQL**: Complementary static analysis that finds vulnerabilities in your own code, while Dependabot handles third-party dependencies.

---

## Why Use It

### Security

Every day, new vulnerabilities are disclosed in open-source packages. The average modern application has 100+ direct dependencies and 1,000+ transitive dependencies. Manually tracking every CVE is impossible. Dependabot automates this by:

- Checking every dependency against the GitHub Advisory Database every 6 hours.
- Creating PRs the moment a patch is available, often within hours of disclosure.
- Providing visibility into your dependency risk posture via the Security tab.

### Compliance

Many compliance frameworks (SOC 2, PCI DSS, HIPAA, ISO 27001) require organizations to:
- Track and remediate known vulnerabilities in software components.
- Demonstrate timely patching of security issues.
- Maintain a software bill of materials (SBOM).

Dependabot provides automated evidence of vulnerability tracking and a clear audit trail through PR history.

### Developer Productivity

Manually checking for updates across 12+ ecosystems is a full-time job. Dependabot:
- Reduces security review burden by grouping related updates.
- Auto-merges minor/patch updates when configured correctly.
- Provides clear PR descriptions with changelogs and release notes.

### Supply Chain Security

Software supply chain attacks (SolarWinds, Log4Shell, event-stream) have made dependency security critical. Dependabot helps by:
- Detecting known vulnerabilities before they are exploited.
- Keeping dependencies updated reduces exposure window.
- Providing dependency graph visualization for impact analysis.

---

## Real-World Breaches

### Log4Shell (CVE-2021-44228) — December 2021

**Impact**: Critical RCE in Apache Log4j2, CVSS 10.0. Affects virtually every Java application.

**Scale**: 35,863 Java packages affected (93% of the ecosystem). Companies including Apple, Twitter, Cloudflare, Minecraft, and thousands of others were impacted. Estimated global cost exceeded $100 billion.

**How Dependabot helps**: After Apache released patched versions (2.15.0, 2.16.0, 2.17.0), Dependabot automatically created security update PRs for Java projects within hours. Projects using Dependabot with security updates enabled patched within days; those without took weeks or months.

**Lesson**: Automated dependency updates reduce mean time to patch from months to hours.

### event-stream (CVE-2018-16487) — November 2018

**Impact**: Malicious code injected into popular npm package event-stream (2M weekly downloads) targeting Copay Bitcoin wallet. The maintainer handed off package rights to an unknown contributor who added flatmap-stream as a dependency.

**How Dependabot helps**: While Dependabot cannot detect malicious packages (it tracks known vulnerabilities, not intent), version update PRs would have flagged the unexpected dependency addition and the version bump.

**Lesson**: Supply chain attacks exploit trust models. Automated dependency review helps maintain visibility.

### ua-parser-js (CVE-2021-27292) — March 2021

**Impact**: ReDoS vulnerability in a package with 8M weekly downloads. An attacker could cause denial of service via crafted User-Agent strings.

**How Dependabot helps**: Dependabot flagged this CVE across millions of repositories and created security update PRs automatically. Projects with security updates enabled patched within days.

**Lesson**: High-impact vulnerabilities in popular packages affect massive numbers of applications simultaneously. Automation is essential.

### colors.js / faker.js Sabotage — January 2022

**Impact**: Maintainer intentionally broke popular packages (colors.js v1.4.1, faker.js v6.6.6) in protest. 20M+ weekly downloads affected.

**How Dependabot helps**: Dependabot version update PRs flagged these breaking changes immediately, allowing teams to pin to safe versions or find alternatives.

**Lesson**: Maintainer sabotage is a real threat. Version pinning + automated review catches intentional breakage.

### ua-parser-js Supply Chain Attack — October 2021

**Impact**: Compromised maintainer account pushed malicious versions (0.7.29, 1.0.0) containing credential-stealing malware. Affects npm with 7M weekly downloads.

**How Dependabot helps**: Dependabot security updates would not catch this directly (it was a new malicious package, not a known CVE), but version update PRs for the bump would trigger review.

**Lesson**: Defense in depth: use Dependabot + CodeQL + license scanning + manual review.

### Spring4Shell (CVE-2022-22965) — March 2022

**Impact**: Critical RCE in Spring Framework. Affects Spring Framework versions 5.3.0 to 5.3.17 and 5.2.0 to 5.2.19.

**How Dependabot helps**: Dependabot created security update PRs within hours of the patch release. Organizations with Dependabot security updates enabled patched their Spring applications automatically.

**Lesson**: Framework vulnerabilities require coordinated patching across thousands of projects. Dependabot's automation is essential for timely remediation.

---

## Supported Ecosystems

Dependabot supports 12+ package ecosystems:

| Ecosystem | Manifest Files | Package Registries |
|-----------|----------------|-------------------|
| npm | package.json, package-lock.json, yarn.lock, pnpm-lock.yaml | npmjs.com, GitHub Packages, private registries |
| pip | requirements.txt, Pipfile, Pipfile.lock, pyproject.toml | PyPI, private indexes |
| Composer | composer.json, composer.lock | Packagist, private repos |
| Bundler | Gemfile, Gemfile.lock | RubyGems, private sources |
| Cargo | Cargo.toml, Cargo.lock | crates.io |
| Go | go.mod, go.sum | proxy.golang.org, private modules |
| Maven | pom.xml | Maven Central, private repos |
| Gradle | build.gradle, build.gradle.kts | Maven Central, private repos |
| NuGet | .csproj, packages.config | nuget.org, private feeds |
| Hex | mix.exs | hex.pm |
| Docker | Dockerfile | Docker Hub, private registries |
| Terraform | *.tf | registry.terraform.io, private registries |
| Elm | elm.json | package.elm-lang.org |
| Git submodules | .gitmodules | GitHub |

---

## Installation

### Prerequisites

- A GitHub repository (public or private with GitHub Advanced Security enabled).
- Write access to the repository or admin access to the organization.
- GitHub Advanced Security enabled for private repositories (included in GitHub Enterprise, or available as add-on).

### Step 1: Create the Configuration File

Create `.github/dependabot.yml` in your repository root:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Step 2: Commit and Push

```bash
git add .github/dependabot.yml
git commit -m "ci: add Dependabot configuration"
git push origin main
```

### Step 3: Verify

Navigate to your repository on GitHub → Insights → Dependency graph → Dependabot. You should see Dependabot active and processing your dependencies.

### Enabling Security Updates

Security updates are enabled by default for public repositories. For private repositories:

1. Go to repository Settings → Code security and analysis.
2. Enable "Dependabot security updates".
3. Enable "GitHub Advanced Security" if not already enabled.

### Using GitHub CLI

```bash
# Check Dependabot status
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[].security_advisory.summary'

# List open Dependabot PRs
gh pr list --author "app/dependabot" --state open

# Merge a Dependabot PR
gh pr merge {pr-number} --squash
```

---

## Configuration Reference

### Full Configuration Schema

```yaml
version: 2
updates:
  # Required: package ecosystem
  - package-ecosystem: "npm"

    # Required: directory containing the manifest
    directory: "/"

    # Optional: path to lock file (auto-detected by default)
    # manifest: "package.json"

    # Required: update schedule
    schedule:
      interval: "daily"           # daily, weekly, monthly
      day: "monday"              # monday-sunday (for weekly)
      time: "06:00"              # HH:MM in UTC
      timezone: "America/Los_Angeles"  # IANA timezone

    # Optional: target branch
    target-branch: "main"

    # Optional: review assignment
    reviewers:
      - "username"
      - "org/team-name"

    # Optional: PR assignment
    assignees:
      - "username"

    # Optional: commit message prefix
    commit-message:
      prefix: "deps"            # or "chore", "build", etc.
      include: "scope"          # include dependency name in scope

    # Optional: labels
    labels:
      - "dependencies"
      - "automated"

    # Optional: open PR limit (default: 5 per ecosystem)
    open-pull-requests-limit: 10

    # Optional: version constraints
    versioning-strategy: increase        # increase, increase-if-necessary, lockfile-only, widen
    allow:
      - dependency-type: "direct"
      - dependency-type: "indirect"
    ignore:
      - dependency-name: "lodash"
        update-types:
          - "version-update:semver-major"
      - dependency-name: "aws-sdk"
        versions:
          - ">= 3.0.0"

    # Optional: grouping
    groups:
      # Group all minor and patch updates together
      production-dependencies:
        dependency-type: "production"
        update-types:
          - "minor"
          - "patch"
      # Group all dev dependencies
      dev-dependencies:
        dependency-type: "development"
      # Group specific dependencies
      eslint:
        patterns:
          - "eslint*"
          - "@typescript-eslint/*"
      testing:
        patterns:
          - "jest*"
          - "@testing-library/*"
          - "cypress"

    # Optional: registry configuration (for private registries)
    registries:
      - type: npm
        url: https://npm.pkg.github.com
        username: ${{ secrets.NPM_USERNAME }}
        password: ${{ secrets.NPM_TOKEN }}

    # Optional: version updates only (not security)
    # (omit to also receive security updates)

    # Optional: groups for security updates
    # (only in version updates config)
```

### Schedule Configuration Details

```yaml
schedule:
  # How often to check for updates
  interval: "daily"    # Check daily (3am UTC default)
  interval: "weekly"   # Check weekly
  interval: "monthly"  # Check monthly

  # Day of week for weekly checks (ignored for daily/monthly)
  day: "monday"
  day: "tuesday"
  day: "wednesday"
  day: "thursday"
  day: "friday"
  day: "saturday"
  day: "sunday"

  # Time of day to check (UTC, or timezone-adjusted)
  time: "06:00"

  # IANA timezone for the time
  timezone: "America/Los_Angeles"
  timezone: "Europe/London"
  timezone: "Asia/Tokyo"
```

### Versioning Strategies

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `increase` | Bumps version to the minimum required to satisfy constraints | Default. Good for most cases. |
| `increase-if-necessary` | Only bumps if current version constraint doesn't cover the latest | When you want minimal changes |
| `lockfile-only` | Only updates lock files, never bumps manifest constraints | When you want to update transitive deps only |
| `widen` | Widens version constraints to include new versions | When you want maximum flexibility |

### Ignore Rules

```yaml
ignore:
  # Ignore all major version updates for a dependency
  - dependency-name: "express"
    update-types:
      - "version-update:semver-major"

  # Ignore specific version ranges
  - dependency-name: "lodash"
    versions:
      - ">= 5.0.0"

  # Ignore all updates for a dependency
  - dependency-name: "deprecated-package"

  # Ignore updates until a certain date
  - dependency-name: "some-package"
    update-types:
      - "version-update:semver-minor"
    until: "2025-01-01"
```

---

## Core Concepts

### Dependency Graph

GitHub's dependency graph maps all direct and transitive dependencies in your repository. Dependabot uses this graph to:

- Identify vulnerable packages anywhere in the tree.
- Determine compatible versions for updates.
- Assess blast radius of vulnerabilities.

The dependency graph is built from:
- **npm**: package.json + package-lock.json
- **pip**: requirements.txt + setup.py + Pipfile
- **Gemfile**: Gemfile + Gemfile.lock
- **Go**: go.mod + go.sum
- **Maven**: pom.xml
- **Cargo**: Cargo.toml + Cargo.lock
- **Composer**: composer.json + composer.lock

### Pull Request Lifecycle

1. **Created**: Dependabot creates a PR with updated dependency files.
2. **Checks run**: CI/CD pipelines execute against the PR.
3. **Review**: Human reviewers assess the changes.
4. **Merge**: PR is merged (manually or via auto-merge).
5. **Cleanup**: Dependabot closes the PR and may create follow-up PRs for other dependencies.

### Grouped Updates

Grouping combines multiple dependency updates into a single PR:

```yaml
groups:
  # Group all React-related packages
  react:
    patterns:
      - "react"
      - "react-dom"
      - "@types/react*"

  # Group by dependency type
  production:
    dependency-type: "production"
  development:
    dependency-type: "development"
```

Benefits:
- Fewer PRs to review.
- Atomic updates for related packages.
- Reduced CI resource consumption.

### Security vs. Version Updates

| Feature | Security Updates | Version Updates |
|---------|-----------------|-----------------|
| Trigger | Known vulnerability in GitHub Advisory Database | New version available |
| Config | Repository settings (not in dependabot.yml) | dependabot.yml |
| Priority | Higher (security-critical) | Lower (maintenance) |
| Groups | Cannot be grouped | Can be grouped |
| Schedule | Checked every 6 hours | Your configured schedule |
| PR label | `dependencies` + security label | Your configured labels |

---

## Step-by-Step Usage Guide

### Step 1: Initial Setup

```bash
# Create the directory
mkdir -p .github

# Create basic dependabot.yml
cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    commit-message:
      prefix: "deps"
    labels:
      - "dependencies"
EOF

# Commit
git add .github/dependabot.yml
git commit -m "ci: add Dependabot for npm dependencies"
git push
```

### Step 2: Multi-Ecosystem Configuration

For a monorepo with multiple package managers:

```yaml
version: 2
updates:
  # Frontend
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    groups:
      react:
        patterns: ["react", "react-dom", "@types/react*"]
      testing:
        patterns: ["jest*", "@testing-library/*", "cypress"]

  # Backend
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "deps"

  # Infrastructure
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "terraform"
    directory: "/infra"
    schedule:
      interval: "monthly"
```

### Step 3: Private Registry Configuration

For npm packages from private registries:

```yaml
- package-ecosystem: "npm"
  directory: "/frontend"
  schedule:
    interval: "weekly"
  registries:
    - type: npm
      url: https://npm.pkg.github.com
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
    - type: npm
      url: https://registry.npmjs.org
      # Public registry (default)
```

For PyPI with private index:

```yaml
- package-ecosystem: "pip"
  directory: "/backend"
  schedule:
    interval: "weekly"
  registries:
    - type: pip
      url: https://pypi.org/simple
    - type: pip
      url: https://private.pypi.company.com/simple
      username: ${{ secrets.PYPI_USER }}
      password: ${{ secrets.PYPI_TOKEN }}
```

### Step 4: Auto-Merge Configuration

Combine Dependabot with GitHub Actions for auto-merging:

```yaml
# .github/workflows/dependabot-auto-merge.yml
name: Dependabot Auto-Merge
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Fetch Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: "${{ secrets.GITHUB_TOKEN }}"

      - name: Auto-merge minor and patch updates
        if: steps.metadata.outputs.update-type != 'version-update:semver-major'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Approve PR
        if: steps.metadata.outputs.update-type != 'version-update:semver-major'
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Step 5: Reviewing Dependabot PRs

```bash
# List all open Dependabot PRs
gh pr list --author "app/dependabot"

# View Dependabot PR details
gh pr view {pr-number}

# Check what changed
gh pr diff {pr-number}

# Merge a PR
gh pr merge {pr-number} --squash

# Check Dependabot alerts for your repo
gh api repos/{owner}/{repo}/dependabot/alerts
```

### Step 6: Monitoring and Metrics

```bash
# Get count of open Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[] | select(.state=="open")' | wc -l

# Get alerts by severity
gh api repos/{owner}/{repo}/dependabot/alerts --jq '
  [.[] | select(.state=="open") | .security_advisory.severity] |
  group_by(.) |
  map({(.[0]): length}) |
  add
'

# List repositories in org with most Dependabot alerts
gh api "/orgs/{org}/repos?per_page=100" --jq '.[].name' | while read repo; do
  count=$(gh api "repos/{org}/$repo/dependabot/alerts" --jq '[.[] | select(.state=="open")] | length' 2>/dev/null || echo "0")
  echo "$count $repo"
done | sort -rn | head -20
```

---

## Custom Rules

### Ignoring Specific Dependencies

```yaml
# Ignore a specific dependency entirely
ignore:
  - dependency-name: "deprecated-package"

# Ignore major version updates only
ignore:
  - dependency-name: "express"
    update-types:
      - "version-update:semver-major"

# Ignore until a specific date
ignore:
  - dependency-name: "migration-package"
    until: "2025-06-01"

# Ignore specific version ranges
ignore:
  - dependency-name: "typescript"
    versions:
      - ">= 5.0.0"
```

### Allowing Specific Dependency Types

```yaml
# Only update direct production dependencies
allow:
  - dependency-type: "direct"
  - dependency-type: "indirect"
```

### Custom Grouping Strategies

```yaml
groups:
  # Group all packages from a specific scope
  aws:
    patterns:
      - "@aws-sdk/*"
      - "aws-*"

  # Group all packages matching a pattern
  babel:
    patterns:
      - "@babel/*"
      - "babel-*"

  # Group by dependency type + version update type
  safe-production-updates:
    dependency-type: "production"
    update-types:
      - "minor"
      - "patch"

  # Group dev dependencies separately
  dev-tools:
    dependency-type: "development"
```

### Custom Commit Messages

```yaml
commit-message:
  # Prefix for all commits
  prefix: "deps"

  # Include dependency name in scope
  include: "scope"
  # Result: "deps(build-tools): bump webpack from 5.88.0 to 5.89.0"

  # Custom separator
  separator: ": "
```

### Custom Labels

```yaml
labels:
  - "dependencies"
  - "automated"
  - "patch"
```

---

## Security Features

### Vulnerability Scanning

Dependabot checks dependencies against GitHub Advisory Database, which aggregates:
- National Vulnerability Database (NVD)
- GitHub Security Advisories (maintainer-reported)
- Security researcher reports
- Linux distributions' security databases

### Security Update PRs

When a vulnerability is detected:
1. Dependabot creates a security update PR with the minimum version bump that fixes the vulnerability.
2. The PR includes a security advisory link and severity information.
3. Auto-fix PRs are created even if you have not configured version updates.

### Dependency Review

The `dependency-review-action` checks PRs for newly introduced vulnerable dependencies:

```yaml
# .github/workflows/dependency-review.yml
name: Dependency Review
on: pull_request

permissions:
  contents: read

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Dependency Review
        uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: moderate
          deny-licenses: GPL-3.0, AGPL-3.0
          comment-summary-in-pr: always
```

### License Compliance

```yaml
- name: Dependency Review
  uses: actions/dependency-review-action@v4
  with:
    deny-licenses: GPL-3.0, AGPL-3.0, SSPL-1.0
    allow-licenses: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC
```

### SBOM Generation

Generate Software Bill of Materials with CycloneDX or SPDX:

```yaml
- name: Generate SBOM
  uses: CycloneDX/github-action/generate-bom@v2
  with:
    path: .
    output-file: sbom.json
    schema-version: "1.5"
```

---

## GitHub Actions Integration

### Dependabot Metadata Action

```yaml
- name: Fetch Dependabot metadata
  id: metadata
  uses: dependabot/fetch-metadata@v2
  with:
    github-token: "${{ secrets.GITHUB_TOKEN }}"
```

Available outputs:
- `update-type`: `version-update:semver-major`, `version-update:semver-minor`, `version-update:semver-patch`
- `dependency-type`: `direct` or `indirect`
- `dependency-name`: Name of the dependency
- `previous-version`: Version before update
- `new-version`: Version after update
- `alerts-count`: Number of alerts fixed
- `alert-severity`: `low`, `medium`, `high`, `critical`
- `alert-summary`: Human-readable summary

### Auto-Merge Workflow (Complete)

```yaml
name: Dependabot Auto-Merge
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Fetch Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: "${{ secrets.GITHUB_TOKEN }}"

      - name: Approve PR
        if: steps.metadata.outputs.update-type != 'version-update:semver-major'
        run: gh pr review --approve "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge
        if: steps.metadata.outputs.update-type != 'version-update:semver-major'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Add label for major updates
        if: steps.metadata.outputs.update-type == 'version-update:semver-major'
        run: gh pr edit "$PR_URL" --add-label "major-update"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Group Auto-Merge by Severity

```yaml
name: Dependabot Auto-Merge by Severity
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Fetch metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge patches
        if: |
          steps.metadata.outputs.update-type == 'version-update:semver-patch' &&
          steps.metadata.outputs.dependency-type == 'direct'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge minor updates
        if: |
          steps.metadata.outputs.update-type == 'version-update:semver-minor' &&
          steps.metadata.outputs.dependency-type == 'direct'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## GitLab CI Integration

While Dependabot is GitHub-native, you can run it on GitLab using the `dependabot` CLI or the [Dependabot for GitLab](https://gitlab.com/dependabot-gitlab/dependabot) project:

### Using dependabot-core CLI

```yaml
# .gitlab-ci.yml
stages:
  - dependabot

dependabot:
  stage: dependabot
  image: dependabot/dependabot-core
  script:
    - bundle exec dependabot update npm / --branch main
  only:
    - schedules
```

### GitLab Native Alternative

GitLab has built-in dependency scanning via `include: template: Security/Dependency-Scanning.gitlab-ci.yml`:

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

dependency_scanning:
  variables:
    DS_EXCLUDED_PATHS: "spec/,test/"
```

---

## Advanced Configuration

### Monorepo Support

For repositories with multiple packages:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/packages/frontend"
    schedule:
      interval: "weekly"
    groups:
      react:
        patterns: ["react", "react-dom"]

  - package-ecosystem: "npm"
    directory: "/packages/backend"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/packages/shared"
    schedule:
      interval: "weekly"

  - package-ecosystem: "pip"
    directory: "/services/ml"
    schedule:
      interval: "monthly"
```

### Multiple Registries

```yaml
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "weekly"
  registries:
    - type: npm
      url: https://registry.npmjs.org
      # Public registry (default, no config needed)
    - type: npm
      url: https://npm.pkg.github.com
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
    - type: npm
      url: https://verdaccio.company.com
      username: ${{ secrets.NPM_USER }}
      password: ${{ secrets.NPM_PASS }}
```

### Custom Target Branch

```yaml
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "weekly"
  target-branch: "develop"  # Create PRs against develop instead of main
```

### Reviewer and Assignee Configuration

```yaml
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "weekly"
  reviewers:
    - "lead-developer"
    - "org/security-team"
  assignees:
    - "dependency-manager"
```

### Open PR Limits

```yaml
# Default is 5 PRs per ecosystem
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "daily"
  open-pull-requests-limit: 20

# Disable version updates (only security updates)
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "daily"
  open-pull-requests-limit: 0
```

---

## Troubleshooting

### 1. Dependabot Not Creating PRs

**Symptom**: No Dependabot PRs appear after configuration.

**Causes and fixes**:
- **Wrong manifest path**: Verify the `directory` value matches your manifest location. Use `ls` to check.
- **No dependencies found**: Ensure the manifest file exists and has dependencies listed.
- **All dependencies up to date**: Check the Insights → Dependency graph → Dependabot tab for status.
- **Rate limiting**: Dependabot limits PRs per ecosystem. Increase `open-pull-requests-limit`.
- **Private repo without GitHub Advanced Security**: Enable GHAS in repo settings.

### 2. Dependabot PR Fails CI

**Symptom**: Dependabot PRs fail your CI/CD pipeline.

**Fixes**:
- Add `on: pull_request` to your CI workflows (Dependabot PRs trigger this event).
- Check if the update introduces breaking changes.
- Test with `versioning-strategy: increase-if-necessary` to minimize changes.

### 3. Dependabot Configuration Syntax Error

**Symptom**: "Dependabot encountered an error" in the Security tab.

**Fix**: Validate your YAML:
```bash
# Check YAML syntax
python -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"

# Use GitHub's schema validator
gh api repos/{owner}/{repo}/contents/.github/dependabot.yml --jq '.content' | base64 -d | python -c "import sys, json, yaml; yaml.safe_load(sys.stdin)"
```

### 4. Wrong Version Selected

**Symptom**: Dependabot picks a version that breaks your code.

**Fix**: Use ignore rules or versioning strategy:
```yaml
ignore:
  - dependency-name: "problematic-package"
    update-types:
      - "version-update:semver-major"
```

### 5. Dependabot Creating Too Many PRs

**Symptom**: Overwhelmed with PRs.

**Fix**: Group updates:
```yaml
groups:
  all-minor-and-patch:
    update-types:
      - "minor"
      - "patch"
```

### 6. Dependabot Ignoring Private Registry

**Symptom**: Cannot resolve private packages.

**Fix**: Configure registries in dependabot.yml:
```yaml
registries:
  - type: npm
    url: https://npm.pkg.github.com
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### 7. Dependabot Not Detecting Vulnerability

**Symptom**: Known CVE not flagged.

**Causes**:
- Advisory not yet in GitHub Advisory Database.
- Dependency not in the dependency graph (not in lock file).
- Advisory is in a different package name.

### 8. Dependabot PR Conflicts with Main Branch

**Symptom**: PR shows merge conflicts.

**Fix**: Dependabot automatically rebases PRs. If persistent, check:
- Conflicting lock file changes from other PRs.
- Use `target-branch` if your workflow uses non-default branches.

### 9. Dependabot Not Updating Lock File

**Symptom**: Manifest updated but lock file unchanged.

**Fix**: Use `versioning-strategy: increase` or `lockfile-only` explicitly.

### 10. Dependabot PR Breaks Tests

**Symptom**: Tests fail on the Dependabot PR.

**Fix**: 
- Review the changelog in the PR description.
- Add test dependencies to the update pipeline.
- Configure auto-merge only after tests pass.

### 11. Dependabot Not Running on Schedule

**Symptom**: Dependabot runs once but doesn't re-check.

**Fix**: Check schedule configuration. Dependabot caches results for the configured interval.

### 12. Wrong Ecosystem Selected

**Symptom**: Dependabot says "no dependencies found".

**Fix**: Ensure `package-ecosystem` matches your lock file:
- `npm` for package-lock.json
- `pip` for requirements.txt
- `composer` for composer.lock

### 13. Dependabot Security Update Not Fixing Vulnerability

**Symptom**: Security update PR created but vulnerability persists.

**Fix**: Check if the patch version actually fixes the specific CVE. Some vulnerabilities require major version bumps or configuration changes.

### 14. Dependabot PR Missing Changelog

**Symptom**: PR description doesn't show changelog.

**Fix**: Dependabot automatically includes changelogs from GitHub releases. If missing, the dependency may not have GitHub releases configured.

### 15. Dependabot Stale PRs Accumulating

**Symptom**: Many old Dependabot PRs piling up.

**Fix**: 
```bash
# Close old PRs
gh pr list --author "app/dependabot" --state open --json number,createdAt --jq '.[] | select(.createdAt < "2025-01-01") | .number' | xargs -I {} gh pr close {}
```

---

## Tips and Best Practices

### 1. Start with Security Updates Only

Enable security updates first, then gradually add version updates. This minimizes PR noise while ensuring critical vulnerabilities are addressed.

### 2. Group Minor and Patch Updates

```yaml
groups:
  minor-and-patch:
    update-types:
      - "minor"
      - "patch"
```

This reduces PR volume by 80%+ for most projects.

### 3. Auto-Merge Patch Updates

For well-tested projects, auto-merge patch updates after CI passes:

```yaml
- name: Auto-merge patches
  if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
  run: gh pr merge --auto --squash "$PR_URL"
```

### 4. Pin GitHub Actions

Always use SHA pinning for GitHub Actions in workflows:

```yaml
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

Dependabot can update these pins too with `package-ecosystem: "github-actions"`.

### 5. Use Groups for Related Packages

Group packages that are updated together:

```yaml
groups:
  eslint:
    patterns: ["eslint*", "@typescript-eslint/*"]
  testing:
    patterns: ["jest*", "@testing-library/*"]
  react:
    patterns: ["react", "react-dom", "@types/react*"]
```

### 6. Configure Reviewers for Security Updates

Assign security team members to security update PRs:

```yaml
reviewers:
  - "org/security-team"
```

### 7. Use Commit Message Prefixes

```yaml
commit-message:
  prefix: "deps"
  include: "scope"
```

This makes dependency updates easy to identify in git log and enables automated changelog generation.

### 8. Set Appropriate Schedule

- **Daily**: For high-velocity projects with good test coverage.
- **Weekly**: For most projects (recommended).
- **Monthly**: For stable, low-risk projects.

### 9. Monitor Dependabot Alerts

Regularly review the Security tab for unresolved vulnerabilities. Use the GitHub API to automate monitoring:

```bash
gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[] | select(.state=="open") | {severity: .security_advisory.severity, package: .dependency.package.name}'
```

### 10. Use Dependency Review Action

Catch new vulnerabilities introduced in PRs before they're merged:

```yaml
- uses: actions/dependency-review-action@v4
  with:
    fail-on-severity: moderate
```

### 11. Keep Dependabot Configuration in Version Control

Always store `dependabot.yml` in your repository. This ensures:
- Changes to configuration are tracked and auditable.
- Configuration is consistent across branches.
- Team members can review configuration changes.

### 12. Limit Open PRs Initially

Start with a low limit and increase as your team gets comfortable:

```yaml
open-pull-requests-limit: 5  # Default, good starting point
```

### 13. Review Before Auto-Merge

Even for patch updates, ensure your test suite is comprehensive before enabling auto-merge.

### 14. Use Version Constraints Wisely

Understand how version constraints affect Dependabot:
- `"^1.0.0"` → Dependabot creates PR for 1.x.x updates.
- `"~1.0.0"` → Dependabot creates PR for 1.0.x updates only.
- `"1.0.0"` → Dependabot creates PR for exact version updates.

### 15. Document Your Dependabot Strategy

Add a section to your CONTRIBUTING.md or README:

```markdown
## Dependabot

This repository uses Dependabot for automated dependency updates.
- **Schedule**: Weekly on Monday at 6am UTC
- **Auto-merge**: Patch and minor updates auto-merge after CI passes
- **Security updates**: Enabled, assigned to security team
- **Groups**: Related packages are grouped to reduce PR noise
```

### 16. Use Dependabot with Code Owners

Combine with CODEOWNERS to ensure dependency PRs are reviewed by appropriate team members.

### 17. Track Dependabot Metrics

Monitor:
- Number of open alerts by severity.
- Mean time to merge Dependabot PRs.
- Percentage of dependencies up to date.
- Number of security updates vs. version updates.

---

## Command Reference

### GitHub CLI Commands

```bash
# List Dependabot alerts
gh api repos/{owner}/{repo}/dependabot/alerts

# List open Dependabot PRs
gh pr list --author "app/dependabot" --state open

# View a Dependabot alert
gh api repos/{owner}/{repo}/dependabot/alerts/{alert-number}

# Dismiss an alert
gh api -X PATCH repos/{owner}/{repo}/dependabot/alerts/{alert-number} -f state=dismissed -f dismissed_reason=tolerable

# Merge a Dependabot PR
gh pr merge {pr-number} --squash

# Check Dependabot configuration
gh api repos/{owner}/{repo}/contents/.github/dependabot.yml --jq '.content' | base64 -d
```

### API Endpoints

```bash
# Get all Dependabot alerts
GET /repos/{owner}/{repo}/dependabot/alerts

# Get a specific alert
GET /repos/{owner}/{repo}/dependabot/alerts/{alert_number}

# Update an alert (dismiss/resolve)
PATCH /repos/{owner}/{repo}/dependabot/alerts/{alert_number}

# Get Dependabot security updates
GET /repos/{owner}/{repo}/dependabot/updates

# Get dependency graph
GET /repos/{owner}/{repo}/dependency-graph/sbom

# Get dependency review
GET /repos/{owner}/{repo}/dependency-review
```

### Web Interface Navigation

- **Repository → Insights → Dependency graph → Dependabot**: View all Dependabot activity.
- **Repository → Security → Dependabot alerts**: View and manage security alerts.
- **Repository → Pull requests → Author: dependabot**: View Dependabot PRs.
- **Organization → Security → Dependabot**: View organization-wide Dependabot status.

---

## Real-World Examples

### Example 1: Small Project (Single Ecosystem)

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "chore(deps)"
```

### Example 2: Full-Stack Monorepo

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    labels: ["frontend", "dependencies"]
    groups:
      react:
        patterns: ["react", "react-dom"]
      eslint:
        patterns: ["eslint*", "@typescript-eslint/*"]

  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    labels: ["backend", "dependencies"]
    commit-message:
      prefix: "deps"

  - package-ecosystem: "docker"
    directory: "/backend"
    schedule:
      interval: "monthly"
    labels: ["docker", "dependencies"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels: ["ci", "dependencies"]

  - package-ecosystem: "terraform"
    directory: "/infra"
    schedule:
      interval: "monthly"
    labels: ["infrastructure", "dependencies"]
```

### Example 3: Enterprise with Private Registries

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/apps/web"
    schedule:
      interval: "daily"
    registries:
      - type: npm
        url: https://npm.pkg.github.com
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      - type: npm
        url: https://registry.npmjs.org
    groups:
      company-packages:
        patterns: ["@mycompany/*"]
    reviewers:
      - "org/frontend-leads"
    labels: ["dependencies", "automated"]

  - package-ecosystem: "pip"
    directory: "/apps/api"
    schedule:
      interval: "daily"
    registries:
      - type: pip
        url: https://pypi.org/simple
      - type: pip
        url: https://pypi.company.internal/simple
        username: ${{ secrets.PYPI_USER }}
        password: ${{ secrets.PYPI_PASS }}
    reviewers:
      - "org/backend-leads"
    labels: ["dependencies", "automated"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "org/devops"
    labels: ["ci", "dependencies"]

  - package-ecosystem: "docker"
    directory: "/apps/api"
    schedule:
      interval: "weekly"
    reviewers:
      - "org/platform-team"
    labels: ["docker", "dependencies"]

  - package-ecosystem: "maven"
    directory: "/services/legacy"
    schedule:
      interval: "monthly"
    labels: ["dependencies", "java"]
```

### Example 4: Infrastructure as Code

```yaml
version: 2
updates:
  - package-ecosystem: "terraform"
    directory: "/infra/environments/production"
    schedule:
      interval: "weekly"
    labels: ["terraform", "production"]
    reviewers:
      - "org/platform-team"

  - package-ecosystem: "terraform"
    directory: "/infra/environments/staging"
    schedule:
      interval: "weekly"
    labels: ["terraform", "staging"]

  - package-ecosystem: "github-actions"
    directory: "/.github/workflows"
    schedule:
      interval: "weekly"
    labels: ["ci", "dependencies"]
```

### Example 5: Microservices Architecture

```yaml
version: 2
updates:
  # Each microservice gets its own entry
  - package-ecosystem: "npm"
    directory: "/services/auth"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/services/api-gateway"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/services/user-service"
    schedule:
      interval: "weekly"

  - package-ecosystem: "npm"
    directory: "/services/payment-service"
    schedule:
      interval: "weekly"

  - package-ecosystem: "pip"
    directory: "/services/ml-engine"
    schedule:
      interval: "weekly"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Further Reading

- [Dependabot Official Documentation](https://docs.github.com/en/code-security/dependabot)
- [Dependabot Configuration Options](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file)
- [Dependabot Security Updates](https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates)
- [GitHub Advisory Database](https://github.com/advisories)
- [Dependabot Core](https://github.com/dependabot/dependabot-core) (open-source engine)
- [Dependabot Examples](https://github.com/dependabot/dependabot-core/tree/main Dependabot examples)
- [GitHub Actions: Dependabot Metadata](https://github.com/dependabot/fetch-metadata)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security/getting-started/github-security-features)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/) (alternative tool)
- [Renovate Bot](https://docs.renovatebot.com/) (alternative tool)
