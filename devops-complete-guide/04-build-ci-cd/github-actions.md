# GitHub Actions Complete Guide

## Table of Contents

1. [What Is GitHub Actions](#what-is-github-actions)
2. [Why Use GitHub Actions](#why-use-github-actions)
3. [Installation & Setup](#installation--setup)
4. [Core Concepts](#core-concepts)
5. [Workflow Syntax](#workflow-syntax)
6. [Usage Guide (Step-by-Step)](#usage-guide)
7. [Custom Configuration](#custom-configuration)
8. [Actions Marketplace](#actions-marketplace)
9. [Integration](#integration)
10. [Security](#security)
11. [Troubleshooting](#troubleshooting)
12. [Tips & Best Practices](#tips--best-practices)
13. [Command Reference](#command-reference)
14. [Configuration Reference](#configuration-reference)
15. [Real-World Examples](#real-world-examples)
16. [Further Reading](#further-reading)

---

## What Is GitHub Actions

GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that automates the build, test, and deployment pipelines directly within GitHub repositories. It was announced in October 2018 and generally available since November 2019. GitHub Actions allows you to create custom workflows triggered by repository events such as pushes, pull requests, issue creation, releases, and scheduled timers.

GitHub Actions workflows are defined using YAML files stored in the `.github/workflows/` directory of a repository. Each workflow consists of one or more jobs, and each job runs in its own virtual machine (runner) or container. Jobs contain steps that can run shell commands, execute scripts, or call pre-built actions from the marketplace or your own custom actions.

The platform runs on GitHub-hosted runners (Ubuntu, Windows, macOS) or can use self-hosted runners installed on your own infrastructure. GitHub Actions provides free tier minutes for public repositories and limited free minutes for private repositories depending on your GitHub plan.

GitHub Actions is tightly integrated with the GitHub ecosystem. It can read and write artifacts, interact with the GitHub API, manage secrets, deploy to cloud providers, and trigger workflows based on any GitHub event. The platform supports matrix builds, reusable workflows, composite actions, and nested workflows, making it highly flexible for complex CI/CD pipelines.

---

## Why Use GitHub Actions

**Native GitHub Integration**: Workflows live in the same repository as your code, use GitHub events as triggers, and interact seamlessly with issues, pull requests, releases, and packages. There is no external service to configure or maintain.

**Zero Infrastructure Management**: GitHub-hosted runners are fully managed. You do not need to provision, configure, or maintain build servers. Simply define your workflow and GitHub handles the execution environment.

**Massive Marketplace**: The GitHub Actions Marketplace offers thousands of pre-built actions for deploying to AWS, Azure, GCP, Docker, Kubernetes, Slack notifications, security scanning, code quality checks, and hundreds of other use cases.

**Matrix Builds**: Test your code across multiple operating systems, language versions, and dependency configurations simultaneously with a single workflow definition.

**Security and Secrets Management**: GitHub provides encrypted secrets, OIDC tokens for cloud provider authentication, and environment protection rules with required reviewers. Secrets are masked in logs and scoped to specific environments or repositories.

**Cost-Effective**: Public repositories get unlimited minutes. Private repositories receive a monthly allotment based on the plan (Free: 2,000 min/month, Pro: 3,000 min/month, Team: 3,000 min/month, Enterprise: 50,000 min/month). Self-hosted runners are always free.

**Reusable Workflows and Composite Actions**: Build once, use everywhere. Create shared workflows and composite actions that can be referenced by any repository in your organization.

**Ecosystem of Official Actions**: GitHub maintains official actions for common tasks: `actions/checkout`, `actions/setup-node`, `actions/setup-python`, `actions/upload-artifact`, `actions/cache`, and many more.

---

## Installation & Setup

### Prerequisites

1. A GitHub account (free tier is sufficient for public repositories)
2. A GitHub repository with write access
3. Basic understanding of YAML syntax
4. Git installed locally for committing workflow files

### Creating Your First Workflow

**Option 1: GitHub Web Interface**

1. Navigate to your repository on GitHub
2. Click the "Actions" tab
3. Click "New workflow"
4. Choose a template or click "set up a workflow yourself"
5. Edit the YAML in the web editor
6. Click "Commit changes"

**Option 2: Command Line**

```bash
# Clone your repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Create the workflows directory
mkdir -p .github/workflows

# Create a workflow file
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run a one-line script
        run: echo "Hello, GitHub Actions!"
EOF

# Commit and push
git add .github/workflows/ci.yml
git commit -m "Add CI workflow"
git push origin main
```

### Setting Up Self-Hosted Runners

```bash
# Download the runner package
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64.tar.gz

# Create the runner and configure it
./config.sh --url https://github.com/your-username/your-repo \
  --token YOUR_TOKEN

# Install as a service (Linux)
sudo ./svc.sh install
sudo ./svc.sh start
```

### Configuring Repository Secrets

1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Enter the name (e.g., `DOCKER_PASSWORD`) and value
4. Click "Add secret"

Secrets can be referenced in workflows as `${{ secrets.DOCKER_PASSWORD }}`.

### Configuring Environments

1. Go to your repository → Settings → Environments
2. Click "New environment"
3. Add protection rules (required reviewers, wait timer, branch restrictions)
4. Add environment-specific secrets

---

## Core Concepts

### Workflows

A workflow is an automated process defined in a YAML file under `.github/workflows/`. Each workflow has a name, triggers, and one or more jobs. A repository can have multiple workflows that run independently.

```yaml
name: Build and Test
# Trigger on push to main or PRs targeting main
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
# Jobs define the work to be done
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm test
```

### Events

Events are activities that trigger workflows. Common events include:

- `push` — Code pushed to a branch
- `pull_request` — PR opened, synchronized, reopened, or closed
- `schedule` — Cron-based scheduled runs
- `workflow_dispatch` — Manual trigger from the GitHub UI
- `release` — Release published, created, edited, deleted
- `issues` — Issue opened, edited, deleted
- `workflow_run` — Another workflow completed

```yaml
on:
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - '!src/**/*.test.js'
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2:00 UTC
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deploy to environment'
        required: true
        type: choice
        options:
          - staging
          - production
```

### Jobs

Jobs are sets of steps that run on the same runner. Jobs run in parallel by default; dependencies are declared with `needs`.

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint  # Runs after lint completes
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  deploy:
    runs-on: ubuntu-latest
    needs: [lint, test]  # Runs after both complete
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: npm run deploy
```

### Steps

Steps are individual tasks within a job. They can run shell commands (`run`) or use actions (`uses`). Steps share the same filesystem and environment within a job.

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4
    with:
      fetch-depth: 0  # Full history for changelog

  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'

  - name: Install dependencies
    run: npm ci

  - name: Run tests
    run: npm test
    env:
      CI: true
      NODE_ENV: test
```

### Runners

Runners are the execution environments for jobs:

- **GitHub-hosted runners**: `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-20.04`, `windows-latest`, `macos-latest`, `macos-14`
- **Self-hosted runners**: Any machine with the runner application installed

```yaml
jobs:
  linux-build:
    runs-on: ubuntu-latest

  windows-build:
    runs-on: windows-latest

  mac-build:
    runs-on: macos-latest

  custom-runner:
    runs-on: [self-hosted, linux, x64]
```

### Artifacts

Artifacts are files produced by workflow runs (build outputs, test results, logs). They can be uploaded, downloaded, and shared between jobs.

```yaml
steps:
  - name: Build
    run: npm run build

  - name: Upload build artifacts
    uses: actions/upload-artifact@v4
    with:
      name: build-output
      path: dist/
      retention-days: 7

  - name: Download artifacts in another job
    uses: actions/download-artifact@v4
    with:
      name: build-output
      path: dist/
```

### Caching

Cache dependencies between workflow runs to speed up builds:

```yaml
steps:
  - name: Cache Node.js modules
    uses: actions/cache@v4
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-

  - name: Cache pip packages
    uses: actions/cache@v4
    with:
      path: ~/.cache/pip
      key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

### Expressions and Contexts

GitHub Actions provides contexts and expressions to access workflow data:

```yaml
steps:
  - name: Print context information
    run: |
      echo "Event name: ${{ github.event_name }}"
      echo "Branch: ${{ github.ref }}"
      echo "Repository: ${{ github.repository }}"
      echo "Actor: ${{ github.actor }}"
      echo "Commit SHA: ${{ github.sha }}"
      echo "Runner OS: ${{ runner.os }}"
      echo "Job status: ${{ job.status }}"

  - name: Conditional step
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    run: echo "This only runs on pushes to main"
```

### Environments

Environments provide protection rules and environment-specific variables:

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: echo "Deploying to staging"

  deploy-production:
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - run: echo "Deploying to production"
```

---

## Workflow Syntax

### Complete Workflow Structure

```yaml
name: Workflow Name

on:
  push:
    branches: [main]
  pull_request:
    types: [opened, synchronize, reopened]

env:
  GLOBAL_VAR: value

defaults:
  run:
    shell: bash
    working-directory: src/

jobs:
  job-name:
    name: Human-readable job name
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, windows-latest]
      fail-fast: false
      max-parallel: 2
    
    env:
      JOB_VAR: value
    
    permissions:
      contents: read
      packages: write
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Run command
        run: echo "Hello"
        shell: pwsh  # Override default shell
```

### Trigger Configuration

```yaml
on:
  # Push events
  push:
    branches: [main, 'release/**']
    tags: ['v*']
    paths: ['src/**', '!src/**/*.test.js']
    paths-ignore: ['docs/**', '*.md']

  # Pull request events
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened, closed]
    paths: ['src/**']

  # Schedule (UTC only)
  schedule:
    - cron: '30 5 * * 1-5'  # 5:30 UTC on weekdays

  # Manual dispatch
  workflow_dispatch:
    inputs:
      debug_enabled:
        description: 'Enable debug logging'
        required: false
        type: boolean
        default: false

  # Workflow run
  workflow_run:
    workflows: ["Build"]
    types: [completed]
    branches: [main]

  # Repository dispatch
  repository_dispatch:
    types: [deploy-command]
```

### Matrix Strategy

```yaml
strategy:
  matrix:
    # Simple matrix
    os: [ubuntu-latest, windows-latest]
    node: [18, 20, 22]
    
    # Include additional combinations
    include:
      - os: ubuntu-latest
        node: 22
        experimental: true
    
    # Exclude specific combinations
    exclude:
      - os: windows-latest
        node: 18
  
  fail-fast: true  # Cancel other jobs on failure
  max-parallel: 4  # Limit concurrent jobs
```

### Conditional Execution

```yaml
steps:
  - name: Always run
    if: always()

  - name: Run on success
    if: success()

  - name: Run on failure
    if: failure()

  - name: Run on success or failure
    if: success() || failure()

  - name: Custom condition
    if: >-
      (github.event_name == 'push' || github.event.pull_request.head.repo.full_name == github.repository)

  - name: Check matrix variable
    if: matrix.node == 22
```

### Outputs and Artifacts

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
      image_tag: ${{ steps.meta.outputs.tags }}
    steps:
      - id: version
        run: echo "version=$(cat VERSION)" >> "$GITHUB_OUTPUT"
      
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: myapp
          tags: |
            type=sha
            type=semver,pattern={{version}}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying version ${{ needs.build.outputs.version }}"
```

### Concurrency Control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Or per-job concurrency
jobs:
  deploy:
    concurrency:
      group: deploy-${{ github.ref }}
      cancel-in-progress: false
```

### Reusable Workflows

```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      image:
        required: true
        type: string
    secrets:
      deploy_token:
        required: true
    outputs:
      deploy_url:
        value: ${{ jobs.deploy.outputs.url }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    outputs:
      url: ${{ steps.deploy.outputs.url }}
    steps:
      - id: deploy
        run: echo "url=https://${{ inputs.environment }}.example.com" >> "$GITHUB_OUTPUT"
```

```yaml
# .github/workflows/caller.yml
name: Deploy
on: push
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
      image: myapp:latest
    secrets:
      deploy_token: ${{ secrets.DEPLOY_TOKEN }}
```

---

## Usage Guide

### Step 1: Create a Basic CI Workflow

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Test
        run: npm test
      
      - name: Build
        run: npm run build
```

### Step 2: Add Matrix Testing

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
```

### Step 3: Add Docker Build

```yaml
jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Step 4: Add Deployment

```yaml
jobs:
  deploy-staging:
    needs: [test, docker]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging
        run: |
          kubectl set image deployment/myapp \
            myapp=${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }} \
            --namespace=staging
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG }}

  deploy-production:
    needs: [test, docker]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        run: |
          kubectl set image deployment/myapp \
            myapp=${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }} \
            --namespace=production
```

### Step 5: Add Notifications

```yaml
jobs:
  notify:
    needs: [deploy-production]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Slack notification
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment ${{ needs.deploy-production.result }}: ${{ github.sha }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Step 6: Add Caching

```yaml
steps:
  - uses: actions/checkout@v4
  
  - name: Cache Node modules
    uses: actions/cache@v4
    id: npm-cache
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-npm-
  
  - name: Install dependencies
    if: steps.npm-cache.outputs.cache-hit != 'true'
    run: npm ci
```

### Step 7: Add Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test
on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '20'
      run-e2e:
        required: false
        type: boolean
        default: false
    outputs:
      coverage:
        description: Coverage percentage
        value: ${{ jobs.test.outputs.coverage }}

jobs:
  test:
    runs-on: ubuntu-latest
    outputs:
      coverage: ${{ steps.coverage.outputs.percent }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
        id: coverage
```

---

## Custom Configuration

### Custom Actions

Create your own actions to encapsulate complex logic:

```yaml
# action.yml (in your repository root)
name: 'Custom Build'
description: 'Build and test application'
inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '20'
  test-command:
    description: 'Test command to run'
    required: false
    default: 'npm test'
outputs:
  version:
    description: 'Application version'
    value: ${{ steps.version.outputs.version }}
runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    
    - name: Install
      shell: bash
      run: npm ci
    
    - name: Get version
      id: version
      shell: bash
      run: echo "version=$(node -p 'require(\"./package.json\").version')" >> "$GITHUB_OUTPUT"
    
    - name: Test
      shell: bash
      run: ${{ inputs.test-command }}
```

### Composite Actions

Combine multiple steps into a reusable composite action:

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Setup project with caching and dependencies'
inputs:
  node-version:
    description: 'Node.js version'
    default: '20'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    - run: npm ci
      shell: bash
    - run: npm run build
      shell: bash
```

### Workflow-Level Defaults

```yaml
name: Project Workflows
on: push

defaults:
  run:
    shell: bash
    working-directory: ./app

env:
  NODE_ENV: production
  CI: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci  # Runs in ./app
      - run: npm test  # Also runs in ./app
```

### Custom Runner Labels

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, gpu]
    steps:
      - run: echo "Running on a GPU-equipped self-hosted runner"

  deploy:
    runs-on: [self-hosted, linux, deploy]
    steps:
      - run: echo "Running on a deploy runner with kubectl access"
```

### Service Containers

```yaml
jobs:
  integration-test:
    runs-on: ubuntu-latest
    services:
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: --health-cmd "redis-cli ping" --health-interval 10s
      
      mysql:
        image: mysql:8
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: testdb
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    
    steps:
      - uses: actions/checkout@v4
      - run: npm test
        env:
          REDIS_URL: redis://localhost:6379
          DATABASE_URL: mysql://root:root@localhost:3306/testdb
```

---

## Actions Marketplace

### Popular Official Actions

| Action | Description |
|--------|-------------|
| `actions/checkout@v4` | Check out repository |
| `actions/setup-node@v4` | Setup Node.js |
| `actions/setup-python@v5` | Setup Python |
| `actions/setup-go@v5` | Setup Go |
| `actions/setup-java@v4` | Setup Java |
| `actions/cache@v4` | Cache dependencies |
| `actions/upload-artifact@v4` | Upload build artifacts |
| `actions/download-artifact@v4` | Download artifacts |
| `actions/github-script@v7` | Execute GitHub API calls |
| `actions/upload-release-asset@v1` | Upload release assets |

### Popular Third-Party Actions

| Action | Description |
|--------|-------------|
| `docker/build-push-action@v5` | Build and push Docker images |
| `docker/login-action@v3` | Docker registry login |
| `docker/setup-buildx-action@v3` | Setup Docker Buildx |
| `docker/metadata-action@v5` | Docker metadata extraction |
| `aws-actions/configure-aws-credentials@v4` | AWS credentials |
| `azure/login@v2` | Azure login |
| `google-github-actions/auth@v2` | GCP authentication |
| `google-github-actions/deploy-cloudrun@v2` | Deploy to Cloud Run |
| `slackapi/slack-github-action@v1` | Slack notifications |
| `peaceiris/actions-gh-pages@v3` | Deploy to GitHub Pages |

### Using Actions from Marketplace

```yaml
steps:
  - uses: actions/checkout@v4
  
  - name: Deploy to AWS
    uses: aws-actions/configure-aws-credentials@v4
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-1
  
  - name: Deploy to S3
    run: aws s3 sync dist/ s3://my-bucket/
```

---

## Integration

### GitHub Actions + Docker

```yaml
name: Docker CI/CD
on: push

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=sha
            type=semver,pattern={{version}}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### GitHub Actions + Kubernetes

```yaml
name: K8s Deploy
on: push

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'
      
      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
      
      - name: Deploy
        run: |
          kubectl apply -f k8s/
          kubectl rollout status deployment/myapp --timeout=300s
```

### GitHub Actions + Terraform

```yaml
name: Terraform
on: push

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.0"
      
      - name: Terraform Init
        run: terraform init
        working-directory: infra/
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: infra/
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
        working-directory: infra/
```

### GitHub Actions + GitHub Packages

```yaml
name: Publish Package
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://npm.pkg.github.com'
      
      - run: npm ci
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Security

### Secrets Management

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Environment-specific secrets
    steps:
      # Repository secrets
      - run: echo "Token ${{ secrets.AWS_ACCESS_KEY_ID }}"
      
      # Environment secrets
      - run: echo "DB Password ${{ secrets.DB_PASSWORD }}"
      
      # GitHub token (automatic)
      - run: echo "Token ${{ secrets.GITHUB_TOKEN }}"
      
      # OIDC token (no long-lived credentials)
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/deploy
          aws-region: us-east-1
```

### OIDC for Cloud Providers

```yaml
# No secrets needed for AWS
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1

# For Azure
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Permissions

```yaml
# Repository-level permissions
permissions:
  contents: read
  packages: write
  issues: write
  pull-requests: write
  id-token: write  # For OIDC

# Job-level permissions
jobs:
  deploy:
    permissions:
      contents: read
      id-token: write
```

### Environment Protection Rules

1. Go to repository Settings → Environments
2. Select the environment
3. Add protection rules:
   - **Required reviewers**: Must approve before deployment
   - **Wait timer**: Delay before deployment (0-43200 minutes)
   - **Branch restrictions**: Only specific branches can deploy

### Security Best Practices

- Use OIDC tokens instead of long-lived credentials
- Scope secrets to specific environments
- Use `GITHUB_TOKEN` with minimal permissions
- Review third-party actions before using
- Pin actions to specific SHA instead of tags
- Use Dependabot to keep actions updated
- Enable branch protection rules
- Audit workflow runs regularly

---

## Troubleshooting

### Issue 1: Workflow Not Triggering

**Symptom**: Push to repository does not trigger the workflow.

**Solution**: Check that the workflow file is on the default branch (usually `main`). Workflows on non-default branches only trigger for events on that branch. Verify the filename ends in `.yml` or `.yaml`. Check the Actions tab for syntax errors.

### Issue 2: Secret Not Available

**Symptom**: `${{ secrets.MY_SECRET }}` is empty.

**Solution**: Verify the secret exists in Settings → Secrets and variables → Actions. Check that the secret is available at the correct scope (repository vs environment). Ensure the secret name matches exactly (case-sensitive).

### Issue 3: Runner Not Picking Up Job

**Symptom**: Job is queued but never runs.

**Solution**: Check runner labels match the `runs-on` configuration. Verify the runner is online and registered. Check that the runner group allows the repository. For self-hosted runners, ensure the runner application is running.

### Issue 4: Cache Not Restoring

**Symptom**: Cache is not found on subsequent runs.

**Solution**: Verify the cache key matches exactly. Check that `actions/cache` runs before dependency installation. Ensure the cache path is correct. Note that caches expire after 7 days of no access.

### Issue 5: Service Container Unreachable

**Symptom**: Cannot connect to service container.

**Solution**: Use `localhost` as the hostname. Ensure ports are mapped correctly. Check health check options are configured. Verify the service is ready before connecting.

### Issue 6: Matrix Build Fails on One Combination

**Symptom**: One matrix combination fails but others succeed.

**Solution**: Check `fail-fast: false` to prevent other jobs from being cancelled. Use `continue-on-error: true` for experimental combinations. Add conditions to skip specific matrix combinations.

### Issue 7: Workflow File Syntax Error

**Symptom**: "Invalid workflow file" error on GitHub.

**Solution**: Validate YAML syntax. Check indentation (use spaces, not tabs). Use GitHub's workflow editor which highlights errors. Run `actionlint` locally.

### Issue 8: Artifact Too Large

**Symptom**: Upload artifact fails with size error.

**Solution**: GitHub Actions has a 10GB limit per run for all artifacts. Compress artifacts before uploading. Use `retention-days` to auto-clean old artifacts. Consider using external storage for large files.

### Issue 9: Timeout Exceeded

**Symptom**: Job fails with timeout error.

**Solution**: Increase `timeout-minutes` (default is 360). Optimize long-running steps. Use caching to speed up builds. Split into smaller jobs.

### Issue 10: Permissions Error

**Symptom**: "Permission denied" when accessing resources.

**Solution**: Check job-level `permissions`. Ensure `GITHUB_TOKEN` has required scopes. For forked PRs, secrets are not available by default. Use `pull_request_target` for access to secrets in PR workflows.

### Issue 11: Workflow Consuming Too Many Minutes

**Symptom**: Running out of included minutes.

**Solution**: Use `concurrency` to cancel in-progress runs. Implement caching. Use `if` conditions to skip unnecessary jobs. Consider self-hosted runners for compute-intensive tasks.

### Issue 12: Docker Build Slow

**Symptom**: Docker builds take too long in CI.

**Solution**: Use BuildKit caching (`cache-from: type=gha`). Implement multi-stage builds. Use Docker layer caching. Push intermediate layers for better caching.

### Issue 13: Checkout Fetches Wrong Branch

**Symptom**: Workflow runs on wrong code.

**Solution**: Use `actions/checkout@v4` with explicit `ref`. For PRs, use `${{ github.event.pull_request.head.sha }}`. For push events, the default checkout is correct.

### Issue 14: Reusable Workflow Input Type Error

**Symptom**: "Input X is not a string" error.

**Solution**: Ensure input types match between caller and callee. Use `fromJSON()` for non-string types. Check that `workflow_call` inputs are properly defined.

### Issue 15: Workflow Stops at Cancel

**Symptom**: Workflow cancels unexpectedly.

**Solution**: Check for `concurrency` with `cancel-in-progress: true`. Another workflow run may have triggered cancellation. Review the workflow run log for the cancellation trigger.

### Issue 16: Conditional Step Not Running

**Symptom**: Step with `if` condition never executes.

**Solution**: Verify the expression syntax. Use `${{ }}` for expressions in `if` conditions (not for the `if:` keyword itself). Check the context data matches expectations.

### Issue 17: Output Not Available in Subsequent Jobs

**Symptom**: `${{ needs.job.outputs.X }}` is empty.

**Solution**: Ensure outputs are defined at the job level using `outputs:`. Verify the step that sets the output uses `>> "$GITHUB_OUTPUT"`. Check the output name matches exactly.

---

## Tips & Best Practices

### 1. Pin Actions to SHA

```yaml
# Instead of:
- uses: actions/checkout@v4

# Use:
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
```

### 2. Use Caching Aggressively

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules/
    key: ${{ runner.os }}-modules-${{ hashFiles('**/lockfiles') }}
```

### 3. Use Concurrency Control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 4. Implement Fast Feedback

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint  # Fast feedback

  test:
    needs: lint  # Only test if lint passes
    steps:
      - run: npm test
```

### 5. Use Reusable Workflows

```yaml
jobs:
  test:
    uses: ./.github/workflows/test.yml
    with:
      node-version: '20'
```

### 6. Implement Branch Protection

- Require PR reviews before merging
- Require status checks to pass
- Require branches to be up to date
- Restrict push access to certain branches

### 7. Use Environments for Deployments

```yaml
jobs:
  deploy:
    environment: production  # Requires approval
    steps:
      - run: echo "Deploying"
```

### 8. Add Status Badges

```markdown
![CI](https://github.com/owner/repo/actions/workflows/ci.yml/badge.svg)
```

### 9. Use `workflow_dispatch` for Manual Triggers

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        type: boolean
        description: Enable debug mode
```

### 10. Implement Retry Logic

```yaml
- name: Retry failed command
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: npm install
```

### 11. Use Composite Actions for Complex Logic

```yaml
# .github/actions/setup/action.yml
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - run: npm ci
      shell: bash
```

### 12. Monitor Workflow Duration

```yaml
- name: Track duration
  run: |
    START=$(date +%s)
    # ... your steps ...
    END=$(date +%s)
    echo "Duration: $((END - START)) seconds"
```

### 13. Implement Change Detection

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      src:
        - 'src/**'
      tests:
        - 'tests/**'

- name: Test
  if: steps.changes.outputs.src == 'true' || steps.changes.outputs.tests == 'true'
  run: npm test
```

### 14. Use Trusted Publishing for Packages

```yaml
- uses: pypa/gh-action-pypi-publish@release/v1
  with:
    password: ${{ secrets.PYPI_API_TOKEN }}
```

### 15. Implement Security Scanning

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'myapp:latest'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload Trivy scan results
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

### 16. Use Job Summaries

```yaml
- name: Add job summary
  run: |
    echo "## Build Summary" >> $GITHUB_STEP_SUMMARY
    echo "- Version: ${{ steps.version.outputs.version }}" >> $GITHUB_STEP_SUMMARY
    echo "- Build time: ${{ steps.time.outputs.duration }}" >> $GITHUB_STEP_SUMMARY
```

### 17. Leverage GitHub's Cache

```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'  # Built-in caching
```

### 18. Use Matrix Excludes for Unsupported Combinations

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
    exclude:
      - os: windows-latest
        node: 18
```

---

## Command Reference

### GitHub CLI (`gh`)

```bash
# List workflow runs
gh run list

# View workflow run details
gh run view 123456

# Watch a running workflow
gh run watch 123456

# Download artifacts
gh run download 123456

# Trigger a workflow
gh workflow run deploy.yml -f environment=staging

# List workflows
gh workflow list

# Enable/disable a workflow
gh workflow disable ci.yml
gh workflow enable ci.yml
```

### Local Testing with `act`

```bash
# Install act
brew install act          # macOS
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the default workflow
act

# Run a specific workflow
act -W .github/workflows/ci.yml

# List available workflows
act -l

# Run a specific job
act -j build

# Use a specific event
act push

# Pass secret
act -s MY_SECRET=value

# Use a specific platform
act --platform ubuntu-latest=catthehacker/ubuntu:act-latest

# Dry run (print what would run)
act -n
```

### Action Linting

```bash
# Install actionlint
brew install actionlint

# Lint all workflows
actionlint

# Lint specific file
actionlint .github/workflows/ci.yml
```

### YAML Validation

```bash
# Install yq
brew install yq

# Validate YAML syntax
yq '.' .github/workflows/ci.yml

# Check for errors
yq -e '.' .github/workflows/ci.yml
```

---

## Configuration Reference

### Workflow File Structure

```yaml
name: string              # Workflow name
on: trigger               # Trigger configuration
env: map                  # Environment variables
defaults: map             # Default settings
permissions: map          # Permissions
concurrency: map/concurrency-group
jobs:
  job-id:
    name: string          # Job display name
    runs-on: string/list  # Runner
    needs: string/list    # Dependencies
    if: expression        # Conditional
    strategy: map         # Matrix strategy
    timeout-minutes: int  # Timeout
    permissions: map      # Job permissions
    environment: string   # Environment name
    services: map         # Service containers
    outputs: map          # Job outputs
    env: map              # Job environment variables
    steps:
      - name: string      # Step name
        id: string        # Step ID
        if: expression    # Conditional
        uses: string      # Action reference
        run: string       # Shell command
        shell: string     # Shell type
        env: map          # Step environment variables
        with: map         # Action inputs
        continue-on-error: bool
        timeout-minutes: int
```

### Event Types

| Event | Description |
|-------|-------------|
| `branch_protection_rule` | Branch protection rule created/edited/deleted |
| `check_run` | Check run created/rerequested/completed |
| `check_suite` | Check suite completed |
| `create` | Branch/tag created |
| `delete` | Branch/tag deleted |
| `deployment` | Deployment created |
| `deployment_status` | Deployment status updated |
| `fork` | Repository forked |
| `gollum` | Wiki page created/updated |
| `installation` | GitHub App installed |
| `issue_comment` | Issue/pull request comment created |
| `issues` | Issue created/edited/deleted |
| `label` | Label created/edited/deleted |
| `membership` | Team membership added/removed |
| `milestone` | Milestone created/closed/opened |
| `page_build` | Pages build attempted |
| `project` | Project created/edited/deleted |
| `project_card` | Project card created/edited/moved/deleted |
| `project_column` | Project column created/edited/moved/deleted |
| `public` | Repository made public |
| `pull_request` | Pull request opened/synchronized/reopened |
| `pull_request_comment` | Pull request review comment created |
| `pull_request_review` | Pull request review submitted |
| `pull_request_review_comment` | Pull request review comment created |
| `push` | Code pushed |
| `release` | Release published/created/edited/deleted |
| `repository_dispatch` | External trigger via API |
| `schedule` | Cron schedule |
| `status` | Commit status updated |
| `watch` | Star event |
| `workflow_call` | Reusable workflow called |
| `workflow_dispatch` | Manual trigger |
| `workflow_run` | Workflow completed |

---

## Real-World Examples

### Complete CI/CD Pipeline

```yaml
name: Complete CI/CD

on:
  push:
    branches: [main]
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
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high

  build:
    needs: [lint, test, security]
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.meta.outputs.version }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha
            type=semver,pattern={{version}}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - run: |
          kubectl set image deployment/myapp \
            myapp=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build.outputs.version }} \
            --namespace=staging

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: |
          kubectl set image deployment/myapp \
            myapp=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.build.outputs.version }} \
            --namespace=production
```

### Monorepo with Path Filters

```yaml
name: Monorepo CI

on:
  push:
    branches: [main]

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      api: ${{ steps.changes.outputs.api }}
      web: ${{ steps.changes.outputs.web }}
      shared: ${{ steps.changes.outputs.shared }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: changes
        with:
          filters: |
            api:
              - 'services/api/**'
            web:
              - 'apps/web/**'
            shared:
              - 'libs/shared/**'

  api:
    needs: changes
    if: needs.changes.outputs.api == 'true' || needs.changes.outputs.shared == 'true'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: services/api
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: services/api/package-lock.json
      - run: npm ci
      - run: npm test
      - run: npm run build

  web:
    needs: changes
    if: needs.changes.outputs.web == 'true' || needs.changes.outputs.shared == 'true'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: apps/web
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: apps/web/package-lock.json
      - run: npm ci
      - run: npm test
      - run: npm run build
```

### Scheduled Maintenance Workflow

```yaml
name: Scheduled Maintenance

on:
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2 AM UTC
  workflow_dispatch:

jobs:
  dependency-update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: update dependencies'
          branch: dependency-updates
          commit-message: 'chore: update dependencies'
          body: |
            Automated dependency update.
            
            Updated packages:
            - npm audit fix
            - Minor version bumps
          labels: dependencies, automated
```

### Release Automation

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Generate changelog
        id: changelog
        run: |
          CHANGELOG=$(git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo "")..HEAD)
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          body: |
            ## Changes
            ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.ref_name }}
            ghcr.io/${{ github.repository }}:latest
```

---

## Further Reading

### Official Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)

### Tools
- [act](https://github.com/nektos/act) — Run GitHub Actions locally
- [actionlint](https://github.com/rhysd/actionlint) — GitHub Actions linter
- [actcker](https://github.com/actcker) — Additional act plugins

### Community Resources
- [GitHub Actions Community Forum](https://github.community/c/github-actions)
- [Awesome GitHub Actions](https://github.com/sdras/awesome-actions)
- [GitHub Actions Examples](https://github.com/practical-actions/workflows)

### Books and Tutorials
- "GitHub Actions in Action" by Michael Kaufman
- "Learning GitHub Actions" by Cupid Felipe
- GitHub Skills (https://skills.github.com)
