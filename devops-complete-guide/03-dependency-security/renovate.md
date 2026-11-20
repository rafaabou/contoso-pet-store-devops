# Renovate Complete Guide

## Table of Contents

1. [What Is Renovate](#what-is-renovate)
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

## What Is Renovate

Renovate is a highly configurable, open-source dependency update tool created by Mend (formerly WhiteSource). Unlike Dependabot, Renovate runs as a self-hosted bot or GitHub App and supports an enormous range of package managers, version control systems, and platforms. It is known for its extremely granular configuration options and advanced grouping capabilities.

Renovate operates by:
1. Scanning your repository for dependency manifests.
2. Resolving available updates from package registries.
3. Creating pull requests based on your configuration rules.
4. Scheduling and batching updates according to your preferences.

### Key Differentiators

- **Self-hosted or hosted**: Run on your own infrastructure or use the Mend-hosted app.
- **Platform-agnostic**: Works with GitHub, GitLab, Bitbucket, Azure DevOps, Gerrit, and more.
- **Extremely configurable**: Hundreds of configuration options with JSON Schema validation.
- **Advanced scheduling**: Granular control over when PRs are created and merged.
- **Dependency dashboard**: A single issue that tracks all available updates.
- **Monorepo support**: First-class support for complex dependency structures.

### Architecture

Renovate's core engine (`renovate` npm package) is a Node.js application that:

1. **Discovery**: Scans repositories for manifest files using an extensible plugin system.
2. **Resolution**: Queries package registries for available versions.
3. **Application**: Applies configuration rules (matchPackageNames, matchUpdateTypes, etc.).
4. **Generation**: Creates or updates pull requests with dependency updates.
5. **Orchestration**: Manages PR lifecycle (create, update, rebase, close).

---

## Why Use It

### Flexibility

Renovate's configuration is far more granular than Dependabot:
- Match by package name pattern, version range, update type, ecosystem, and more.
- Custom grouping rules with complex logic.
- Schedule updates by day, time, timezone, and dependency type.
- Pin dependencies, replace lockfile-only updates, or widen ranges.

### Multi-Platform Support

Renovate works across platforms where Dependabot does not:
- GitHub (Cloud and Enterprise)
- GitLab (SaaS and self-managed)
- Bitbucket Cloud and Server
- Azure DevOps
- Gitea and Forgejo
- Gerrit

### Self-Hosted Option

For organizations that cannot use cloud-based bots:
- Run Renovate as a Docker container, Node.js process, or Kubernetes Job.
- Full control over execution environment and secrets.
- Audit every action taken by the bot.

### Advanced Dependency Management

- **Dependency Dashboard**: A single issue tracking all available updates, letting you approve/reject/snooze individual updates.
- **On-demand updates**: Trigger specific updates via issue comments.
- **Grouping**: Combine related updates into single PRs with fine-grained control.
- **Rebasing**: Automatic or manual rebasing strategies.

### Security

- Rate limiting and safe default behaviors.
- Lockfile maintenance mode for indirect dependency updates.
- Integration with vulnerability databases (npm audit, safety, Snyk).
- No access to secrets or environment variables during resolution.

---

## Real-World Breaches

### event-stream (CVE-2018-16487)

**Context**: Malicious dependency injection in a popular npm package. Renovate would have flagged the unexpected version bump and new dependency, triggering review.

**Renovate benefit**: The `matchPackagePatterns` rule could detect when a dependency adds a new transitive dependency from an unknown publisher.

### ua-parser-js (CVE-2021-27292)

**Context**: ReDoS in a package with 8M weekly downloads.

**Renovate benefit**: Renovate's `vulnerabilityAlerts` feature (npm audit integration) would flag this, and automatic patch PRs would be created.

### colors.js / faker.js Sabotage (January 2022)

**Context**: Maintainer intentionally broke packages with infinite loops.

**Renovate benefit**: Renovate's ` stabilityDays` feature can delay PR merges until a version has been out for a specified number of days, catching sabotage quickly.

### Log4Shell (CVE-2021-44228)

**Context**: Critical RCE in Log4j2, affecting millions of Java applications.

**Renovate benefit**: Renovate's `packageRules` can match all Log4j dependencies and create grouped PRs, or `ignoreDeps` can be used to temporarily pin while investigation proceeds.

### node-ipc Protests (March 2022)

**Context**: Maintainer modified node-ipc to delete files in Russia/Belarus.

**Renovate benefit**: Renovate's `matchPackageNames` with `enabled=false` can disable updates for specific packages, and the `dependencyDashboardApproval` feature requires manual approval before any update proceeds.

---

## Supported Ecosystems

Renovate supports 80+ package managers and platforms:

| Category | Managers |
|----------|----------|
| **JavaScript** | npm, Yarn, Lerna, pnpm |
| **Python** | pip, pipenv, Poetry, pip-tools, conda |
| **Ruby** | Bundler |
| **Java** | Maven, Gradle |
| **Go** | Go modules |
| **Rust** | Cargo |
| **PHP** | Composer |
| **.NET** | NuGet, .NET CLI, Cake |
| **Docker** | Dockerfile, Docker Compose |
| **Terraform** | Terraform, Terragrunt |
| **CI/CD** | GitHub Actions, GitLab CI, CircleCI, Jenkins, Travis CI, Azure Pipelines |
| **Cloud** | Helm, Kubernetes, Ansible, Chef |
| **Databases** | Flyway, Liquibase |
| **Mobile** | iOS (CocoaPods, Carthage, Swift Package Manager), Android (Gradle) |
| **Documentation** | MkDocs, Sphinx, Asciidoctor |

---

## Installation

### Option 1: GitHub App (Recommended for GitHub)

1. Visit https://github.com/apps/renovate
2. Click "Install"
3. Select repositories or organizations
4. Renovate creates an onboarding PR with default configuration
5. Merge the onboarding PR to activate

### Option 2: Self-Hosted on GitHub

```bash
# Using Docker
docker run --rm \
  -e RENOVATE_TOKEN=ghp_xxxx \
  -e RENOVATE_REPOSITORIES=owner/repo \
  renovate/renovate

# Using Docker Compose
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  renovate:
    image: renovate/renovate:latest
    environment:
      - RENOVATE_TOKEN=${RENOVATE_TOKEN}
      - RENOVATE_REPOSITORIES=owner/repo1,owner/repo2
      - RENOVATE_BASE_DIR=/tmp/renovate
      - LOG_LEVEL=info
    volumes:
      - renovate-cache:/tmp/renovate
    restart: unless-stopped

volumes:
  renovate-cache:
EOF
```

### Option 3: GitLab Self-Managed

```bash
# Using Docker
docker run --rm \
  -e RENOVATE_PLATFORM=gitlab \
  -e RENOVATE_TOKEN=glpat-xxxx \
  -e RENOVATE_REPOSITORIES=group/project \
  renovate/renovate
```

### Option 4: GitHub Actions Self-Hosted

```yaml
# .github/workflows/renovate.yml
name: Renovate
on:
  schedule:
    - cron: '0 6 * * 1'  # Weekly on Monday at 6am
  workflow_dispatch:

jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Self-hosted Renovate
        uses: renovatebot/github-action@v40
        with:
          token: ${{ secrets.RENOVATE_TOKEN }}
          configurationFile: renovate.json
```

### Option 5: Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: renovate
spec:
  schedule: "0 6 * * 1"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: renovate
              image: renovate/renovate:latest
              env:
                - name: RENOVATE_TOKEN
                  valueFrom:
                    secretKeyRef:
                      name: renovate-secrets
                      key: token
                - name: RENOVATE_REPOSITORIES
                  value: "owner/repo1,owner/repo2"
          restartPolicy: OnFailure
```

---

## Configuration Reference

### Configuration File Formats

Renovate supports multiple configuration file formats:

- `renovate.json` (JSON)
- `renovate.json5` (JSON5 with comments)
- `.renovaterc` (JSON)
- `.renovaterc.json` (JSON)
- `package.json` (under `"renovate"` key)

### Basic Configuration

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base"
  ],
  "schedule": ["before 6am on monday"],
  "labels": ["dependencies"],
  "assignees": ["team-infra"],
  "reviewers": ["team:security"]
}
```

### Full Configuration Schema

```json5
{
  // Extends: inherit from shared configs
  "extends": [
    "config:base",
    ":semanticCommits",
    "group:allNonMajor",
    "security:openssf-scorecard"
  ],

  // Repository basics
  "repository": "owner/repo",
  "branchPrefix": "renovate/",
  "prConcurrentLimit": 10,
  "prHourlyLimit": 4,

  // Scheduling
  "schedule": [
    "before 6am on monday",
    "every weekend",
    "before 3am"
  ],
  "timezone": "America/Los_Angeles",
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on the first day of the month"],
    "automerge": true
  },

  // Labels and assignees
  "labels": ["renovate", "dependencies"],
  "assignees": ["username"],
  "reviewers": ["team:platform"],
  "addLabels": [],

  // Commit messages
  "commitMessageAction": "Update",
  "commitMessagePrefix": "chore(deps):",
  "commitMessageTopic": "{{depName}} to {{newVersion}}",
  "semanticCommits": "enabled",

  // PR configuration
  "prTitle": "{{renovate groupName}} dependency updates",
  "prBodyNotes": ["This PR updates dependencies."],
  "platformAutomerge": true,
  "automerge": false,
  "automergeType": "pr",
  "recreateWhen": "never",

  // Grouping
  "group": {
    "allNonMajor": {
      "matchUpdateTypes": ["minor", "patch"],
      "matchDepTypes": ["dependencies"]
    }
  },

  // Package rules (array of rule objects)
  "packageRules": [
    {
      "description": "Group React packages",
      "matchPackageNames": ["react", "react-dom", "@types/react"],
      "groupName": "react",
      "automerge": true
    },
    {
      "description": "Pin TypeScript to exact version",
      "matchPackageNames": ["typescript"],
      "rangeStrategy": "pin"
    },
    {
      "description": "Ignore major updates for AWS SDK",
      "matchPackageNames": ["@aws-sdk/*"],
      "matchUpdateTypes": ["major"],
      "enabled": false
    },
    {
      "description": "Auto-merge patch updates for dev dependencies",
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "description": "Group all ESLint packages",
      "matchPackageNames": ["eslint", "@typescript-eslint/*"],
      "groupName": "eslint"
    }
  ],

  // Vulnerability alerts
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"],
    "automerge": false
  },

  // Registry authentication
  "npmrc": "//registry.npmjs.org/:_authToken=${NPM_TOKEN}",
  "registryUrls": ["https://registry.npmjs.org"],

  // Version strategy
  "rangeStrategy": "auto",
  // Options: auto, bump, increase, increase-if-necessary, lockfile-only, replace, widen

  // Stability
  "stabilityDays": 3,
  "ignoreDeps": [],

  // Post-upgrade tasks
  "postUpdateOptions": ["npmDedupe", "yarnDedupe"],

  // Experimental
  "internalChecksAsSuccess": false,
  "requireConfig": "required"
}
```

### Package Rules Deep Dive

Package rules are the core of Renovate's power:

```json5
{
  "packageRules": [
    {
      // Description (for documentation)
      "description": "Group all AWS packages",

      // Matchers (what this rule applies to)
      "matchPackageNames": ["@aws-sdk/*", "aws-*"],
      "matchPackagePatterns": ["^@aws-sdk/"],
      "matchPackagePrefixes": ["@aws-sdk/"],
      "matchManagers": ["npm", "yarn"],
      "matchDepTypes": ["dependencies", "devDependencies"],
      "matchUpdateTypes": ["major", "minor", "patch"],
      "matchCurrentVersion": "^1.0.0",
      "matchSourceUrlPrefixes": ["https://github.com/aws/"],
      "matchFileNames": ["frontend/package.json", "services/*/package.json"],
      "excludePackageNames": ["@aws-sdk/client-s3"],
      "excludePackagePrefixes": ["@aws-sdk/client-"],

      // Actions (what this rule does)
      "groupName": "aws-sdk",
      "groupSlug": "aws-sdk",
      "automerge": true,
      "automergeType": "pr",
      "automergeStrategy": "squash",
      "dependencyDashboardApproval": true,
      "enabled": true,
      "ignoreUnstable": true,
      "respectLatest": true,
      "stabilityDays": 7,

      // Version strategy
      "rangeStrategy": "bump",
      "extractVersionTemplate": "^{{major}}.{{minor}}",

      // Pinning
      "pinVersions": true,
      "allowedVersions": ">= 2.0.0",
      "ignoreDeps": [],

      // PR customization
      "prBodyNotes": ["This is an AWS SDK update."],
      "labels": ["aws", "dependencies"],
      "reviewers": ["team:cloud"],
      "platformAutomerge": true,

      // Post-update
      "postUpdateOptions": ["npmDedupe"],

      // Visibility
      "includePaths": ["frontend/", "services/"],
      "excludePaths": ["tests/", "docs/"]
    }
  ]
}
```

---

## Core Concepts

### Extends and Config Inheritance

Renovate supports configuration inheritance through the `extends` field:

```json5
{
  "extends": [
    // Built-in presets
    "config:base",
    "config:recommended",
    ":semanticCommits",
    "group:allNonMajor",
    "workarounds:all",

    // Shared configs from other repositories
    "github>org/shared-renovate-config//default.json",

    // Local config files
    "local>./renovate-base.json5"
  ]
}
```

Available built-in presets include:
- `config:base` — Default recommended config.
- `config:recommended` — Alias for config:base.
- `:semanticCommits` — Enables semantic commit messages.
- `group:allNonMajor` — Groups all minor and patch updates.
- `group:monorepos` — Groups monorepo packages.
- `group:recommended` — Recommended grouping.
- `workarounds:all` — Known workarounds for package issues.

### Dependency Dashboard

The Dependency Dashboard is a GitHub/GitLab issue that provides a single view of all available updates:

```json5
{
  "dependencyDashboard": true,
  "dependencyDashboardApproval": true,  // Require approval before updates proceed
  "dependencyDashboardAutoclose": true,  // Auto-close when all updates done
  "dependencyDashboardTitle": "Renovate Dependency Dashboard",
  "dependencyDashboardIssueContent": "full"  // or "workaround" or "minimal"
}
```

The dashboard issue lists:
- Approved updates (ready to create PRs)
- Pending updates (awaiting approval)
- Rejected updates (explicitly ignored)
- All currently open PRs

Comments on the issue can approve/reject specific updates:
```
/rebbit approve 1,3,5
/rebbit reject 2,4
```

### Range Strategies

Renovate uses different strategies for updating version ranges in package.json:

| Strategy | Before | After | Use Case |
|----------|--------|-------|----------|
| `auto` | `^1.0.0` | `^1.1.0` | Default, lets Renovate choose |
| `bump` | `^1.0.0` | `^1.1.0` | Bump range to include new version |
| `increase` | `^1.0.0` | `^1.1.0` | Increase range minimum |
| `increase-if-necessary` | `^1.0.0` | `^1.0.5` | Only increase if needed |
| `lockfile-only` | `^1.0.0` (no change) | `^1.0.0` | Only update lockfile |
| `replace` | `^1.0.0` | `1.1.0` | Replace with exact version |
| `widen` | `^1.0.0` | `>=1.0.0 <2.0.0` | Widen to include new major |

### Automerge

Renovate can automatically merge PRs that meet certain criteria:

```json5
{
  "automerge": true,  // Enable automerge globally
  "automergeType": "pr",  // or "branch" for direct pushes
  "automergeStrategy": "squash",  // squash, merge, rebase
  "platformAutomerge": true,  // Use platform-native automerge (GitHub)
  "requiredStatusChecks": ["ci/test", "ci/lint"],
  "ignoreTests": false  // Wait for CI to pass
}
```

### Grouping

Grouping combines multiple dependency updates into a single PR:

```json5
{
  "group": {
    // Simple grouping
    "react": {
      "matchPackageNames": ["react", "react-dom"],
      "matchUpdateTypes": ["minor", "patch"]
    },

    // Pattern-based grouping
    "eslint": {
      "matchPackagePrefixes": ["@eslint/", "eslint-"],
      "matchPackageNames": ["eslint"]
    },

    // Dependency type grouping
    "allDevDependencies": {
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["minor", "patch"]
    }
  }
}
```

### Scheduling

```json5
{
  // Simple schedules
  "schedule": ["before 6am on monday"],
  "schedule": ["every weekend"],
  "schedule": ["before 3am"],
  "schedule": ["on the first day of the month"],

  // Complex schedules
  "schedule": [
    "before 6am on monday",
    "every weekend",
    "before 3am"
  ],

  // Exclusion schedules (when NOT to run)
  "schedule": ["before 6am on monday", "except: december"],

  // Timezone
  "timezone": "America/Los_Angeles"
}
```

---

## Step-by-Step Usage Guide

### Step 1: Installation

For GitHub, install the Renovate GitHub App:
1. Visit https://github.com/apps/renovate
2. Click "Install"
3. Select repositories

For self-hosted:
```bash
docker run --rm \
  -e RENOVATE_TOKEN=ghp_xxxx \
  -e RENOVATE_REPOSITORIES=owner/repo \
  -e RENOVATE_BASE_DIR=/tmp/renovate \
  -v /tmp/renovate:/tmp/renovate \
  renovate/renovate
```

### Step 2: Create Configuration

Create `renovate.json` in your repository root:

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base"
  ]
}
```

### Step 3: Onboarding

When Renovate first runs on a repository:
1. It creates an "Configure Renovate" PR with the configuration file.
2. Review the configuration.
3. Merge the PR to activate Renovate.

### Step 4: Initial Dependency Scan

After merging:
- Renovate scans all dependency manifests.
- Creates PRs for available updates (respecting your configuration).
- Creates a Dependency Dashboard issue (if enabled).

### Step 5: Review and Configure

Review the initial PRs and refine your configuration:

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base",
    "group:allNonMajor"
  ],
  "schedule": ["before 6am on monday"],
  "labels": ["dependencies"],
  "automerge": false,
  "prConcurrentLimit": 10,
  "packageRules": [
    {
      "description": "Auto-merge patch updates",
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "pr"
    },
    {
      "description": "Group React",
      "matchPackageNames": ["react", "react-dom"],
      "groupName": "react"
    }
  ]
}
```

### Step 6: Enable Auto-Merge

For projects with solid test coverage:

```json5
{
  "extends": ["config:base"],
  "automerge": true,
  "automergeType": "pr",
  "platformAutomerge": true,
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["minor"],
      "automerge": true,
      "stabilityDays": 3
    }
  ]
}
```

### Step 7: Monitor and Maintain

- Review the Dependency Dashboard regularly.
- Adjust `packageRules` based on PR quality.
- Update `schedule` as your team's capacity changes.

---

## Custom Rules

### Package Matching

```json5
{
  "packageRules": [
    // Match by exact name
    {
      "matchPackageNames": ["react", "react-dom"],
      "groupName": "react"
    },

    // Match by prefix pattern
    {
      "matchPackagePrefixes": ["@types/"],
      "groupName": "type-defs"
    },

    // Match by regex pattern
    {
      "matchPackagePatterns": ["^eslint.*$", "^@typescript-eslint/"],
      "groupName": "eslint"
    },

    // Match by current version
    {
      "matchCurrentVersion": "^1.0.0",
      "matchUpdateTypes": ["major"],
      "automerge": true
    },

    // Match by source URL
    {
      "matchSourceUrlPrefixes": ["https://github.com/facebook/"],
      "groupName": "facebook-packages"
    },

    // Match by file path
    {
      "matchFileNames": ["frontend/**"],
      "matchPackageNames": ["react"],
      "groupName": "frontend-react"
    },

    // Exclude specific packages
    {
      "excludePackageNames": ["react"],
      "matchPackagePrefixes": ["@types/react"]
    }
  ]
}
```

### Version Range Strategies

```json5
{
  "packageRules": [
    // Pin exact versions for critical deps
    {
      "matchPackageNames": ["lodash", "minimist"],
      "rangeStrategy": "pin",
      "pinVersions": true
    },

    // Widen ranges for peer dependencies
    {
      "matchDepTypes": ["peerDependencies"],
      "rangeStrategy": "widen"
    },

    // Lockfile-only for production
    {
      "matchDepTypes": ["dependencies"],
      "matchUpdateTypes": ["minor"],
      "rangeStrategy": "lockfile-only"
    },

    // Bump for dev dependencies
    {
      "matchDepTypes": ["devDependencies"],
      "rangeStrategy": "bump"
    }
  ]
}
```

### Conditional Automerge

```json5
{
  "packageRules": [
    // Auto-merge patches for well-tested deps
    {
      "matchUpdateTypes": ["patch"],
      "matchDepTypes": ["devDependencies"],
      "automerge": true,
      "automergeType": "pr",
      "automergeStrategy": "squash"
    },

    // Auto-merge minor with stability requirement
    {
      "matchUpdateTypes": ["minor"],
      "automerge": true,
      "stabilityDays": 7,
      "ignoreUnstable": true
    },

    // Require approval for majors
    {
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true,
      "automerge": false
    }
  ]
}
```

### Custom PR Templates

```json5
{
  "prBodyNotes": [
    "## Dependency Updates",
    "",
    "This PR was created by [Renovate](https://docs.renovatebot.com/).",
    "",
    "**Updated Packages:**",
    "{{#each groupName}}"
    "- {{depName}}: {{currentVersion}} → {{newVersion}}"
    "{{/each}}",
    "",
    "**Changelog:**",
    "{{#each groupName}}"
    "- [{{depName}}]({{sourceUrl}}/blob/main/CHANGELOG.md)"
    "{{/each}}"
  ]
}
```

---

## Security Features

### Vulnerability Alerts

```json5
{
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security", "vulnerability"],
    "automerge": false,
    "dependencyDashboardApproval": false,  // Bypass dashboard for security
    "prPriority": 10,  // Higher priority
    "schedule": ["at any time"]  // Create immediately
  }
}
```

### Security Auditing

```json5
{
  "extends": [
    "config:base",
    "security:openssf-scorecard"
  ],
  "packageRules": [
    {
      "matchCurrentVersion": "< 1.0.0",
      "description": "Flag pre-1.0 packages for review",
      "dependencyDashboardApproval": true
    }
  ]
}
```

### Lockfile Maintenance

```json5
{
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on the first day of the month"],
    "automerge": true,
    "automergeType": "pr",
    "commitMessageAction": "Lock file maintenance"
  }
}
```

### npm Audit Integration

```json5
{
  "vulnerabilityAlerts": {
    "enabled": true
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["pin", "digest", "patch"],
      "description": "Security updates should be fast-tracked",
      "automerge": true,
      "schedule": ["at any time"]
    }
  ]
}
```

---

## GitHub Actions Integration

### Self-Hosted Renovate on GitHub Actions

```yaml
name: Renovate
on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:
    inputs:
      dryRun:
        description: 'Dry run'
        type: boolean
        default: false

jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Self-hosted Renovate
        uses: renovatebot/github-action@v40
        with:
          token: ${{ secrets.RENOVATE_TOKEN }}
          configurationFile: renovate.json
          dryRun: ${{ github.event.inputs.dryRun }}
```

### Auto-Merge Workflow

```yaml
name: Auto-Merge Renovate PRs
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'renovate[bot]'
    steps:
      - name: Fetch metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - name: Auto-merge patch updates
        if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Dependency Review

```yaml
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
          fail-on-severity: critical
```

---

## GitLab CI Integration

### Self-Hosted Renovate on GitLab CI

```yaml
stages:
  - renovate

renovate:
  stage: renovate
  image: renovate/renovate:latest
  variables:
    RENOVATE_PLATFORM: "gitlab"
    RENOVATE_TOKEN: $RENOVATE_TOKEN
    RENOVATE_REPOSITORIES: $CI_PROJECT_PATH
    LOG_LEVEL: "info"
  script:
    - renovate
  only:
    - schedules
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

### GitLab Native Dependency Scanning

```yaml
include:
  - template: Security/Dependency-Scanning.gitlab-ci.yml

dependency_scanning:
  variables:
    DS_EXCLUDED_PATHS: "spec/,test/"
```

### GitLab Renovate Bot

```yaml
# Using GitLab's built-in dependency update (similar to Renovate)
include:
  - template: Jobs/Dependency-Update.gitlab-ci.yml

dependency_update:
  variables:
    UPDATE_STRATEGY: "semver"
```

---

## Advanced Configuration

### Monorepo Support

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"],
  "ignorePaths": [
    "**/node_modules/**",
    "**/vendor/**",
    "**/tests/**"
  ],
  "packageRules": [
    {
      "matchFileNames": ["apps/web/**"],
      "matchPackageNames": ["react"],
      "groupName": "web-react",
      "reviewers": ["team:web"]
    },
    {
      "matchFileNames": ["apps/mobile/**"],
      "matchPackageNames": ["react-native"],
      "groupName": "mobile-react-native",
      "reviewers": ["team:mobile"]
    },
    {
      "matchFileNames": ["services/**"],
      "groupName": "services-deps",
      "reviewers": ["team:platform"]
    }
  ]
}
```

### Multiple Registries

```json5
{
  "npmrc": "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}\n//registry.npmjs.org/:_authToken=${NPM_TOKEN}",
  "registryUrls": [
    "https://registry.npmjs.org",
    "https://npm.pkg.github.com"
  ]
}
```

### Custom Managers

```json5
{
  "customManagers": [
    {
      "customType": "regex",
      "fileMatch": ["\\.yaml$", "\\.$yml$"],
      "matchStrings": [
        "image:\\s*(?<depName>[^:]+):(?<currentValue>[^\\s]+)"
      ],
      "datasourceTemplate": "docker"
    },
    {
      "customType": "regex",
      "fileMatch": ["Makefile$"],
      "matchStrings": [
        "(?<depName>[A-Z_]+)_VERSION\\s*[:=]\\s*(?<currentValue>[\\d.]+)"
      ],
      "datasourceTemplate": "github-tags"
    }
  ]
}
```

### Post-Update Tasks

```json5
{
  "postUpdateOptions": [
    "npmDedupe",
    "yarnDedupe",
    "yarnLockMaintenance",
    "bundlerLockMaintenance",
    "composerDedupeFiles"
  ]
}
```

### Dependency Dashboard Issue Template

```json5
{
  "dependencyDashboard": true,
  "dependencyDashboardTitle": "Renovate Updates Dashboard",
  "dependencyDashboardIssueContent": "full",
  "dependencyDashboardAutoclose": true,
  "dependencyDashboardApproval": false
}
```

---

## Troubleshooting

### 1. Renovate Not Creating PRs

**Symptom**: No PRs appear after configuration.

**Causes and fixes**:
- **Invalid configuration**: Check logs for configuration errors. Use `renovate-config-validator` to validate.
- **No dependencies found**: Verify manifest files are in the expected locations.
- **Schedule mismatch**: Check `schedule` configuration. Use `["at any time"]` to test.
- **Rate limiting**: Check `prConcurrentLimit` and `prHourlyLimit`.
- **Renovate not enabled**: Ensure the GitHub App is installed and has repository access.

### 2. Renovate Creating Too Many PRs

**Symptom**: Overwhelmed with PRs.

**Fix**: Group updates:
```json5
{
  "extends": ["group:allNonMajor"],
  "prConcurrentLimit": 5
}
```

### 3. Renovate PR Conflicts

**Symptom**: PRs have merge conflicts.

**Fix**:
```json5
{
  "recreateWhen": "always",  // Recreate PRs instead of updating
  "rebaseStrict": true
}
```

### 4. Renovate Not Detecting Dependencies

**Symptom**: Manifest files not found.

**Fix**: Check `fileMatch` configuration:
```json5
{
  "fileMatch": ["(^|/)package\\.json$", "(^|/)yarn\\.lock$"]
}
```

### 5. Renovate Not Grouping Correctly

**Symptom**: Expected grouped PRs but got individual PRs.

**Fix**: Ensure package names/patterns match:
```json5
{
  "packageRules": [
    {
      "matchPackageNames": ["react", "react-dom"],
      "groupName": "react"
    }
  ]
}
```

### 6. Renovate Automerge Not Working

**Symptom**: Automerge enabled but PRs not merging.

**Causes**:
- CI checks failing.
- Branch protection rules blocking merge.
- `platformAutomerge` not enabled.
- `automergeType` mismatch with branch protection.

### 7. Renovate Schedule Not Working

**Symptom**: PRs created at wrong times.

**Fix**: Check timezone configuration:
```json5
{
  "schedule": ["before 6am on monday"],
  "timezone": "America/New_York"
}
```

### 8. Renovate Not Updating Lock Files

**Symptom**: Manifest updated but lock file unchanged.

**Fix**: Use explicit range strategy:
```json5
{
  "rangeStrategy": "bump"
}
```

### 9. Renovate Private Registry Authentication

**Symptom**: Cannot resolve private packages.

**Fix**: Configure npmrc:
```json5
{
  "npmrc": "//private.registry.com/:_authToken=${REGISTRY_TOKEN}"
}
```

### 10. Renovate Dependency Dashboard Not Updating

**Symptom**: Dashboard issue not reflecting current state.

**Fix**: Check if `dependencyDashboard` is enabled. The dashboard updates on each Renovate run.

### 11. Renovate Creating PRs for Ignored Packages

**Symptom**: PRs for packages in `ignoreDeps`.

**Fix**: Ensure package names match exactly:
```json5
{
  "ignoreDeps": ["lodash", "minimist"]
}
```

### 12. Renovate Not Rebasing PRs

**Symptom**: PRs are stale after base branch updates.

**Fix**:
```json5
{
  "rebaseWhen": "behind-base-branch"
}
```

### 13. Renovate PR Title Not Matching Expected Format

**Symptom**: PR titles don't follow your convention.

**Fix**:
```json5
{
  "prTitle": "{{renovate groupName}} dependency updates",
  "commitMessageTopic": "{{depName}} to {{newVersion}}"
}
```

### 14. Renovate Not Detecting Vulnerabilities

**Symptom**: Known CVEs not flagged.

**Fix**: Enable vulnerability alerts:
```json5
{
  "vulnerabilityAlerts": {
    "enabled": true
  }
}
```

### 15. Renovate Self-Hosted Not Connecting to GitHub

**Symptom**: Self-hosted Renovate cannot reach GitHub API.

**Fix**: Check token permissions and network connectivity:
```bash
# Test token
curl -H "Authorization: token $RENOVATE_TOKEN" https://api.github.com/repos/owner/repo

# Check DNS
nslookup api.github.com

# Check proxy settings
echo $http_proxy $https_proxy
```

---

## Tips and Best Practices

### 1. Start with `config:base`

Always start with the recommended base configuration and customize from there:
```json5
{
  "extends": ["config:base"]
}
```

### 2. Use Grouping Aggressively

Grouping reduces PR noise:
```json5
{
  "extends": ["group:allNonMajor"]
}
```

### 3. Enable the Dependency Dashboard

The dashboard provides a single view of all updates:
```json5
{
  "dependencyDashboard": true
}
```

### 4. Use Stability Days

Prevent updates to versions that are too new:
```json5
{
  "stabilityDays": 3,
  "ignoreUnstable": true
}
```

### 5. Automerge with Caution

Only automerge when:
- You have comprehensive test coverage.
- The update is a patch or minor version.
- CI passes consistently.

### 6. Use Semantic Commits

```json5
{
  "semanticCommits": "enabled",
  "commitMessagePrefix": "chore(deps):"
}
```

### 7. Configure Reviewers by Package

```json5
{
  "packageRules": [
    {
      "matchPackageNames": ["@aws-sdk/*"],
      "reviewers": ["team:cloud"]
    },
    {
      "matchPackageNames": ["react", "react-dom"],
      "reviewers": ["team:frontend"]
    }
  ]
}
```

### 8. Pin Critical Dependencies

```json5
{
  "packageRules": [
    {
      "matchPackageNames": ["lodash", "minimist"],
      "pinVersions": true,
      "rangeStrategy": "pin"
    }
  ]
}
```

### 9. Use lockFileMaintenance

Keep lock files fresh:
```json5
{
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on the first day of the month"]
  }
}
```

### 10. Validate Configuration

Use the Renovate Config Validator:
```bash
npx --yes -- renovate-config-validator renovate.json
```

### 11. Use Custom Managers

For non-standard dependency files:
```json5
{
  "customManagers": [
    {
      "customType": "regex",
      "fileMatch": ["Makefile$"],
      "matchStrings": ["VERSION=(?<currentValue>[\\d.]+)"],
      "depNameTemplate": "my-tool",
      "datasourceTemplate": "github-tags"
    }
  ]
}
```

### 12. Monitor Renovate Logs

For self-hosted, monitor logs:
```bash
docker logs renovate-container --tail 100
```

### 13. Use Package Overrides

For npm, force specific versions:
```json5
{
  "packageRules": [
    {
      "matchPackageNames": ["minimist"],
      "allowedVersions": ">= 1.2.6"
    }
  ]
}
```

### 14. Configure for Monorepos

```json5
{
  "ignorePaths": [
    "**/node_modules/**",
    "**/vendor/**"
  ],
  "packageRules": [
    {
      "matchFileNames": ["apps/frontend/**"],
      "groupName": "frontend"
    }
  ]
}
```

### 15. Use Replace Strategy for Breaking Changes

When a dependency needs to be replaced entirely:
```json5
{
  "packageRules": [
    {
      "matchPackageNames": ["moment"],
      "replacementName": "dayjs",
      "replacementVersion": "1.11.10"
    }
  ]
}
```

### 16. Document Your Renovate Policy

Add to your CONTRIBUTING.md:
```markdown
## Dependency Updates

This project uses [Renovate](https://docs.renovatebot.com/) for automated dependency updates.

- **Schedule**: Weekly on Monday mornings
- **Automerge**: Patch updates auto-merge after CI passes
- **Review**: Minor and major updates require manual review
- **Grouping**: Related packages are grouped to reduce PR noise
```

---

## Command Reference

### GitHub CLI

```bash
# List Renovate PRs
gh pr list --author "app/renovate[bot]"

# View Renovate PR
gh pr view {pr-number}

# Merge Renovate PR
gh pr merge {pr-number} --squash

# Check Dependency Dashboard
gh issue list --author "app/renovate[bot]"

# Comment on Dependency Dashboard to approve updates
gh issue comment {issue-number} --body "/rebase"

# Close stale Renovate PRs
gh pr list --author "app/renovate[bot]" --state open --json number,createdAt \
  --jq '.[] | select(.createdAt < "2025-01-01") | .number' | \
  xargs -I {} gh pr close {}
```

### Renovate CLI (Self-Hosted)

```bash
# Run Renovate
renovate

# Dry run
renovate --dry-run

# Validate configuration
npx renovate-config-validator renovate.json

# Run with specific config
renovate --config-file renovate.json

# Debug logging
LOG_LEVEL=debug renovate

# Run for specific repository
RENOVATE_REPOSITORIES=owner/repo renovate

# Run with custom base directory
RENOVATE_BASE_DIR=/tmp/renovate renovate
```

### API Endpoints (GitHub)

```bash
# List Renovate PRs
GET /repos/{owner}/{repo}/pulls?user=renovate[bot]

# List Dependency Dashboard
GET /repos/{owner}/{repo}/issues?user=renovate[bot]

# Check Renovate installation
GET /repos/{owner}/{repo}/installation

# List repository automations
GET /repos/{owner}/{repo}/automations
```

### Renovate Configuration Validation

```bash
# Validate JSON
cat renovate.json | python -m json.tool

# Validate with schema
npx --yes -- renovate-config-validator renovate.json

# Check for deprecated options
npx renovate-config-validator --config renovate.json
```

---

## Real-World Examples

### Example 1: Minimal Configuration

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"]
}
```

### Example 2: Production-Ready

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base",
    "group:allNonMajor",
    ":semanticCommits"
  ],
  "schedule": ["before 6am on monday"],
  "timezone": "America/Los_Angeles",
  "labels": ["dependencies"],
  "assignees": ["team-infra"],
  "reviewers": ["team:platform"],
  "prConcurrentLimit": 10,
  "dependencyDashboard": true,
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on the first day of the month"]
  },
  "packageRules": [
    {
      "description": "Auto-merge patch updates",
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "pr"
    },
    {
      "description": "Group React",
      "matchPackageNames": ["react", "react-dom", "@types/react"],
      "groupName": "react"
    },
    {
      "description": "Group ESLint",
      "matchPackagePatterns": ["^eslint", "^@typescript-eslint/"],
      "groupName": "eslint"
    },
    {
      "description": "Group Testing",
      "matchPackageNames": ["jest", "@testing-library/*", "cypress"],
      "groupName": "testing"
    },
    {
      "description": "Require approval for major updates",
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true,
      "automerge": false
    }
  ]
}
```

### Example 3: Enterprise Monorepo

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base",
    "group:allNonMajor",
    "group:monorepos"
  ],
  "schedule": ["before 6am on monday", "every weekend"],
  "timezone": "Europe/London",
  "labels": ["dependencies"],
  "prConcurrentLimit": 20,
  "dependencyDashboard": true,
  "lockFileMaintenance": {
    "enabled": true
  },
  "packageRules": [
    {
      "matchFileNames": ["apps/web/**"],
      "groupName": "web-deps",
      "reviewers": ["team:web"]
    },
    {
      "matchFileNames": ["apps/api/**"],
      "groupName": "api-deps",
      "reviewers": ["team:api"]
    },
    {
      "matchFileNames": ["infrastructure/**"],
      "groupName": "infra-deps",
      "reviewers": ["team:platform"]
    },
    {
      "matchPackageNames": ["@company/*"],
      "enabled": false,
      "description": "Internal packages updated manually"
    },
    {
      "matchPackageNames": ["typescript"],
      "rangeStrategy": "pin",
      "automerge": false,
      "reviewers": ["team:leads"]
    }
  ],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"],
    "schedule": ["at any time"]
  }
}
```

### Example 4: Python Project

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"],
  "pip_requirements": {
    "fileMatch": ["requirements.*\\.txt$"],
    "schedule": ["before 6am on monday"]
  },
  "poetry": {
    "fileMatch": ["pyproject.toml"]
  },
  "packageRules": [
    {
      "matchManagers": ["pip_requirements"],
      "groupName": "python-deps"
    },
    {
      "matchPackageNames": ["django"],
      "rangeStrategy": "bump"
    },
    {
      "matchPackageNames": ["pytest"],
      "automerge": true
    }
  ]
}
```

### Example 5: Docker and Kubernetes

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"],
  "docker": {
    "fileMatch": ["Dockerfile.*$"]
  },
  "helmfile": {
    "fileMatch": ["charts/.+\\.ya?ml$"]
  },
  "kubernetes": {
    "fileMatch": ["k8s/.+\\.ya?ml$"]
  },
  "packageRules": [
    {
      "matchManagers": ["dockerfile"],
      "groupName": "docker-images"
    },
    {
      "matchManagers": ["helmfile", "helmv3"],
      "groupName": "helm-charts"
    },
    {
      "matchManagers": ["kubernetes"],
      "groupName": "k8s-resources"
    }
  ]
}
```

---

## Further Reading

- [Renovate Official Documentation](https://docs.renovatebot.com/)
- [Renovate Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Renovate Presets](https://docs.renovatebot.com/presets/)
- [Renovate Self-Hosted](https://docs.renovatebot.com/modules/self-hosted/)
- [Renovate GitHub Action](https://github.com/renovatebot/github-action)
- [Renovate Config Playground](https://preview.renovatebot.com/playground/)
- [Mend Platform](https://www.mend.io/)
- [Renovate Blog](https://www.mend.io/blog/)
- [Renovate vs Dependabot Comparison](https://docs.renovatebot.com/comparison/)
- [Renovate GitHub Repository](https://github.com/renovatebot/renovate)
