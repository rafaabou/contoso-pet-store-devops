# Act Complete Guide — Run GitHub Actions Locally

## Table of Contents

1. [What Is Act](#what-is-act)
2. [Why Use Act](#why-use-act)
3. [Installation](#installation)
4. [Core Concepts](#core-concepts)
5. [Configuration](#configuration)
6. [Usage Guide (Step-by-Step)](#usage-guide)
7. [Custom Configuration](#custom-configuration)
8. [Integration](#integration)
9. [Security](#security)
10. [Troubleshooting](#troubleshooting)
11. [Tips & Best Practices](#tips--best-practices)
12. [Command Reference](#command-reference)
13. [Configuration Reference](#configuration-reference)
14. [Real-World Examples](#real-world-examples)
15. [Further Reading](#further-reading)

---

## What Is Act

Act is a tool that runs your GitHub Actions workflows locally. Created by [nektos](https://github.com/nektos/act), it allows you to test and debug GitHub Actions workflows on your development machine before pushing to GitHub. Act parses the workflow YAML files, determines which jobs and steps need to run based on the event, and executes them inside Docker containers that replicate the GitHub Actions runner environment.

Act works by mapping GitHub Actions concepts to local equivalents. GitHub-hosted runners are replaced with Docker containers, GitHub event payloads are generated locally, secrets can be provided via command line or environment variables, and the workflow file structure is preserved exactly as it would run on GitHub.

The tool supports all major GitHub Actions features including matrix builds, service containers, artifact handling, conditional execution, reusable workflows, and composite actions. It can simulate push events, pull request events, schedule events, manual dispatch events, and more.

Act is particularly valuable for rapid iteration on workflow development. Instead of pushing a commit, waiting for GitHub to pick up the workflow, waiting for the workflow to run, and then checking the results, you can iterate locally in seconds. It is also invaluable for debugging workflow failures, testing secrets handling, and validating complex workflow logic.

---

## Why Use Act

**Rapid Feedback Loop**: Push → GitHub → workflow runs → check results takes minutes. Running locally with act takes seconds. This dramatically accelerates workflow development and debugging.

**Cost Savings**: Every workflow run on GitHub consumes runner minutes. Act is free and runs on your local machine, preserving your GitHub Actions minutes for actual CI/CD.

**Offline Development**: Work on and test workflows without internet access. Act runs entirely locally using Docker containers.

**Debugging**: When a workflow fails on GitHub, reproducing the issue locally with act provides full access to the environment, step-by-step execution, and interactive debugging capabilities.

**Secrets Testing**: Test workflows with real secrets locally without committing them to GitHub. Use `.env` files or environment variables to provide secrets securely.

**Environment Validation**: Verify that workflow steps, commands, and configurations work correctly before pushing to GitHub.

**Consistency**: Act uses Docker containers that closely replicate the GitHub Actions runner environment, ensuring that what runs locally will run correctly on GitHub.

**Support for All Event Types**: Simulate any GitHub event — push, pull_request, schedule, workflow_dispatch, release, issue events, and more.

**Matrix Builds**: Test matrix configurations locally to verify all combinations work before pushing.

**Service Containers**: Test workflows that depend on databases, Redis, or other services using Docker service containers.

---

## Installation

### macOS

```bash
# Using Homebrew
brew install act

# Using MacPorts
sudo port install act
```

### Linux

```bash
# Using the install script
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Or download a specific release
ACT_VERSION=0.2.70
curl -sL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_x86_64.tar.gz" | sudo tar xz -C /usr/local/bin act
```

### Windows

```bash
# Using Scoop
scoop install act

# Using Chocolatey
choco install act-cli

# Using winget
winget install nektos.act
```

### Docker

```bash
# Run act via Docker
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/workspace \
  -w /workspace \
  catthehacker/act:latest
```

### Building from Source

```bash
# Requires Go 1.21+
git clone https://github.com/nektos/act.git
cd act
go build -o act
sudo mv act /usr/local/bin/
```

### Verify Installation

```bash
act --version
# Output: act version 0.2.70
```

### Docker Requirement

Act requires Docker to run. Ensure Docker is installed and running:

```bash
# Check Docker installation
docker --version
docker ps

# If Docker is not running
sudo systemctl start docker  # Linux
# Or start Docker Desktop on macOS/Windows
```

### Selecting a Platform Image

Act downloads Docker images to simulate GitHub Actions runners. On first run, you will be prompted to select a platform:

```bash
act
# ? Please choose the default image you want to use with act:
#   -Large size image: 20GB+ image, contains almost all tools used on GitHub Actions (IMPORTANT: this image is not maintained by act, it's just a snapshot of GitHub Actions runner)
#   -Medium size image: ~500MB, includes only necessary tools to bootstrap actions and aims to be compatible with most actions
#   -Micro size image: ~200MB, contains only necessary things to run actions and aims to be compatible with supported actions
#   -Default image: 1GB, image with popular tools installed (busted) [recommended]

# Or specify directly
act --platform ubuntu-latest=catthehacker/act:latest
```

Platform images:
- `catthehacker/act:latest` — Default, recommended
- `catthehacker/act:ubuntu-latest` — Ubuntu latest with many tools
- `catthehacker/act:ubuntu-22.04` — Ubuntu 22.04
- `catthehacker/act:ubuntu-20.04` — Ubuntu 20.04
- `ghcr.io/catthehacker/ubuntu:act-latest` — GitHub Container Registry version

---

## Core Concepts

### Event Simulation

Act simulates GitHub events locally. Each event type generates a mock event payload that GitHub Actions would normally receive:

```bash
# Simulate a push event (default)
act push

# Simulate a pull request event
act pull_request

# Simulate a manual dispatch
act workflow_dispatch

# Simulate a schedule event
act schedule

# Simulate a release
act release

# Simulate an issue comment
act issue_comment
```

### Job Mapping

Act maps each job in your workflow to a Docker container. The container runs on the specified runner image and executes all steps in that job sequentially. Steps that use `actions/checkout@v4` are intercepted and replaced with act's local checkout mechanism.

### Step Execution

Each step runs in sequence within the container. Shell steps execute via bash, and action steps are downloaded (or cached) and executed using the action runner. The Docker socket is mounted into containers by default, allowing Docker-in-Docker workflows.

### Artifacts

Act supports artifact upload and download between jobs using a local volume. Artifacts are stored in `.act/artifacts/` in the repository root by default.

### Secrets

Secrets can be provided via environment variables, `.env` files, or the `--secret-file` flag. They are injected into the workflow environment just as GitHub would.

### Service Containers

Workflows that define `services:` blocks will have those services started as Docker containers. Act manages the lifecycle of these containers and provides network connectivity between the service and the job container.

### Matrix Builds

Act supports matrix strategies exactly as defined in workflow files. Each matrix combination runs in its own container, and `fail-fast` behavior is preserved.

---

## Configuration

### The `.act.yml` File

Act can be configured via a `.act.yml` file in the repository root. This file controls default behavior:

```yaml
# .act.yml
artifact-server-path: .act/artifacts
bind-workspace: true
env:
  CI: "true"
  ACT: "true"
platforms:
  ubuntu-latest: catthehacker/act:latest
  ubuntu-22.04: catthehacker/act:ubuntu-22.04
  ubuntu-20.04: catthehacker/act:ubuntu-20.04
  macos-latest: catthehacker/act:macos-12
  windows-latest: catthehacker/act:windows-latest
secret-files:
  - .env
```

### Environment Variables

```bash
# Set default environment variables
export ACT_DEFAULT_ENV_FILE=.env

# Set Docker options
export ACT_DOCKER_OPTIONS="--pull always"

# Set the event name
export ACT_DEFAULT_EVENT=push
```

### Event Payload Files

Create custom event payloads in `.github/event.json` or specify them with `-e`:

```json
{
  "action": "opened",
  "pull_request": {
    "number": 1,
    "head": {
      "ref": "feature-branch",
      "sha": "abc123"
    },
    "base": {
      "ref": "main"
    },
    "title": "Add new feature",
    "body": "This PR adds a new feature"
  }
}
```

### Container Configuration

```yaml
# .act.yml
container-options: >-
  --cpus 2
  --memory 4g
  --network host
  --pull always
```

### Platform Overrides

```yaml
# .act.yml
platforms:
  ubuntu-latest: catthehacker/act:ubuntu-latest
  # Override with a custom image
  ubuntu-latest: myregistry/my-action-runner:latest
  # Use arm64 image
  ubuntu-latest: catthehacker/act:ubuntu-latest
```

---

## Usage Guide

### Step 1: Basic Workflow Execution

```bash
# Run the default push event workflow
act

# Or explicitly
act push
```

### Step 2: List Available Workflows and Jobs

```bash
# List all workflows
act -l

# Output:
# Stage  Job ID  Job name  Workflow name  Workflow file
# 0      build   Build     CI             .github/workflows/ci.yml
# 0      test    Test      CI             .github/workflows/ci.yml
```

### Step 3: Run a Specific Job

```bash
# Run only the build job
act -j build

# Run only the test job
act -j test
```

### Step 4: Run a Specific Workflow File

```bash
# Run a specific workflow file
act -W .github/workflows/ci.yml

# Run a workflow by name
act -W .github/workflows/deploy.yml
```

### Step 5: Simulate Different Events

```bash
# Push event (default)
act push

# Pull request event
act pull_request

# Manual dispatch
act workflow_dispatch

# Schedule event
act schedule

# Release event
act release
```

### Step 6: Pass Secrets

```bash
# Pass individual secrets
act -s AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
act -s AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Pass from a file
act --secret-file .secrets

# Pass from environment
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
act -s AWS_ACCESS_KEY_ID
```

### Step 7: Use Custom Event Payloads

```bash
# Create a custom event file
cat > .github/event.json << 'EOF'
{
  "action": "opened",
  "pull_request": {
    "number": 1,
    "head": { "ref": "feature-branch", "sha": "abc123" },
    "base": { "ref": "main" }
  }
}
EOF

# Run with custom event
act pull_request -e .github/event.json
```

### Step 8: Use Environment Files

```bash
# Create a .env file
cat > .env << 'EOF'
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
DATABASE_URL=postgres://localhost:5432/test
EOF

# Run with env file
act --env-file .env
```

### Step 9: Bind Workspace

```bash
# Bind the workspace into containers (for file modifications)
act --bind

# Or configure in .act.yml
echo 'bind-workspace: true' >> .act.yml
```

### Step 10: Debug Step-by-Step

```bash
# Use a specific platform image with more tools
act --platform ubuntu-latest=catthehacker/act:ubuntu-latest

# Run with verbose output
act -v

# Run with debug output
act --verbose

# Dry run (see what would execute)
act -n
```

### Step 11: Run with Specific Runner Image

```bash
# Use a specific image
act --platform ubuntu-latest=catthehacker/act:ubuntu-latest

# Use a custom image
act --platform ubuntu-latest=myregistry/my-runner:latest
```

### Step 12: Cache Actions

```bash
# Actions are cached by default in ~/.cache/act/
# To force re-download
act --pull always

# To use cached actions
act --no-cache-dir
```

### Step 13: Handle Artifacts

```bash
# Artifacts are stored in .act/artifacts/
act --artifact-server-path .act/artifacts

# Remove old artifacts before run
rm -rf .act/artifacts
```

### Step 14: Run in CI

```bash
# In a GitHub Actions workflow, run act locally
jobs:
  test-workflows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run act locally
        uses: catthehacker/act-gh-workflow@v1
        with:
          workflow: ci.yml
```

### Step 15: Clean Up

```bash
# Remove act containers
docker ps -a --filter "label=com.catthehacker.act" -q | xargs docker rm

# Remove act images
docker images --filter "reference=catthehacker/*" -q | xargs docker rmi

# Remove artifacts
rm -rf .act/
```

---

## Custom Configuration

### Custom Workflow Files

```yaml
# .github/workflows/ci.yml
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
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Test
        run: npm test
```

### Custom Actions

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Setup project with dependencies'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    - run: npm ci
      shell: bash
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
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
```

### Composite Actions with Act

```yaml
# .github/actions/local-setup/action.yml
name: 'Local Setup'
description: 'Setup for local development'
inputs:
  node-version:
    description: 'Node.js version'
    default: '20'
runs:
  using: 'composite'
  steps:
    - name: Check Docker
      shell: bash
      run: docker --version
    
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    
    - run: npm ci
      shell: bash
    
    - run: npm run build
      shell: bash
```

---

## Integration

### Act + Docker Compose

```yaml
# docker-compose.act.yml
version: '3.8'
services:
  act-runner:
    image: catthehacker/act:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - .:/workspace
    working_dir: /workspace
    environment:
      - CI=true
    command: act push
```

```bash
# Run act via docker-compose
docker-compose -f docker-compose.act.yml up
```

### Act + VS Code

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run CI Workflow",
      "type": "shell",
      "command": "act push",
      "group": "test",
      "presentation": {
        "reveal": "always"
      }
    },
    {
      "label": "Run Specific Job",
      "type": "shell",
      "command": "act -j build",
      "group": "test"
    },
    {
      "label": "List Workflows",
      "type": "shell",
      "command": "act -l"
    }
  ]
}
```

### Act + Makefile

```makefile
# Makefile
.PHONY: act act-lint act-test act-full

act:
	act push

act-lint:
	act -j lint

act-test:
	act -j test

act-full:
	act push --verbose

act-deploy:
	act workflow_dispatch -s DEPLOY_TOKEN=$(DEPLOY_TOKEN)

act-clean:
	docker ps -a --filter "label=com.catthehacker.act" -q | xargs docker rm -f
	rm -rf .act/artifacts
```

### Act + Pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/nektos/act
    rev: v0.2.70
    hooks:
      - id: act-check
        name: Check GitHub Actions workflows
        entry: act -l
        language: system
        pass_filenames: false
        files: \.github/workflows/.*\.yml$
```

### Act + CI/CD

```yaml
# .github/workflows/test-workflows.yml
name: Test Workflows Locally

on:
  pull_request:
    paths:
      - '.github/workflows/**'

jobs:
  test-act:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install act
        run: |
          curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
      
      - name: Validate workflows
        run: act -l
      
      - name: Run act dry run
        run: act -n
```

### Act + Terragrunt

```yaml
# terragrunt.hcl (using act to test Terraform workflows)
# .github/workflows/terraform.yml
name: Terraform
on: push
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan
```

---

## Security

### Handling Secrets Locally

```bash
# Never commit secrets to git
# Use environment variables
export MY_SECRET=value
act -s MY_SECRET

# Or use a .env file (add to .gitignore)
echo ".env" >> .gitignore

# Create .env file with secrets
cat > .env << 'EOF'
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
DOCKER_PASSWORD=your_password
EOF

# Pass all secrets from .env
act --env-file .env
```

### Secret File Format

```bash
# .secrets file format (one per line)
MY_SECRET=my_secret_value
ANOTHER_SECRET=another_value

# Pass to act
act --secret-file .secrets
```

### Docker Socket Security

```bash
# The Docker socket is mounted by default
# This allows Docker-in-Docker workflows
# Only mount if necessary
act --no-bind-workspace

# Or mount read-only when possible
act --bind --container-options "-v /var/run/docker.sock:/var/run/docker.sock:ro"
```

### Container Security

```bash
# Use official images only
act --platform ubuntu-latest=catthehacker/act:latest

# Avoid running with --privileged unless absolutely necessary
# Only add if workflow requires it
act --container-options "--privileged"

# Use non-root containers when possible
act --platform ubuntu-latest=myregistry/my-runner:latest
```

### Network Isolation

```bash
# Disable network access for testing
act --container-options "--network none"

# Use host network for local services
act --container-options "--network host"
```

### Secret Scoping

```bash
# Pass secrets only to specific steps
# In workflow file:
# steps:
#   - name: Use secret
#     env:
#       MY_SECRET: ${{ secrets.MY_SECRET }}
#     run: echo $MY_SECRET

# Act passes secrets as environment variables
# They are only available when referenced in workflow
```

### Audit and Review

```bash
# Review what act would execute before running
act -n

# Verbose mode shows all commands
act -v

# Check workflow syntax
act -l
```

---

## Troubleshooting

### Issue 1: Docker Permission Denied

**Symptom**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**: Add your user to the docker group or run with sudo:
```bash
sudo usermod -aG docker $USER
newgrp docker
# Or
sudo act
```

### Issue 2: Actions Not Found

**Symptom**: `Error: Unable to resolve action`

**Solution**: Check that the action exists and the reference is correct:
```yaml
# Use full reference
- uses: actions/checkout@v4
# Not just
- uses: checkout@v4
```

### Issue 3: Container Cannot Reach Network

**Symptom**: `Could not resolve host: github.com`

**Solution**: Use host networking or fix DNS:
```bash
act --container-options "--network host"
# Or fix Docker DNS
echo '{"dns": ["8.8.8.8"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

### Issue 4: Artifacts Not Shared Between Jobs

**Symptom**: Download artifact step cannot find the artifact

**Solution**: Enable artifact server:
```bash
act --artifact-server-path .act/artifacts
# Or in .act.yml
echo 'artifact-server-path: .act/artifacts' >> .act.yml
```

### Issue 5: Event Payload Missing

**Symptom**: `${{ github.event.pull_request.number }}` is empty

**Solution**: Provide a complete event payload:
```bash
cat > .github/event.json << 'EOF'
{
  "action": "opened",
  "pull_request": {
    "number": 1,
    "head": { "ref": "feature", "sha": "abc123" },
    "base": { "ref": "main" }
  }
}
EOF
act pull_request -e .github/event.json
```

### Issue 6: Workflow Steps Skip

**Symptom**: Steps with `if` conditions are not running

**Solution**: Check the event context. Some conditions depend on event-specific data:
```bash
# Debug by printing context
act -v  # Verbose mode shows skipped steps
```

### Issue 7: Service Containers Cannot Connect

**Symptom**: Cannot connect to service container

**Solution**: Use `localhost` and ensure the service is healthy:
```yaml
services:
  postgres:
    image: postgres:16
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
```

### Issue 8: Large Image Download

**Symptom**: First run takes a long time to download images

**Solution**: Pre-download images or use smaller images:
```bash
# Pull the image first
docker pull catthehacker/act:latest

# Use smaller image if tools aren't needed
act --platform ubuntu-latest=catthehacker/act:micro
```

### Issue 9: Go Version Mismatch

**Symptom**: `go: error loading module requirements`

**Solution**: Ensure the correct Go version is available or use setup-go:
```yaml
steps:
  - uses: actions/setup-go@v5
    with:
      go-version: '1.21'
```

### Issue 10: Windows Line Endings

**Symptom**: Scripts fail with `/bin/bash\r: no such file or directory`

**Solution**: Normalize line endings:
```bash
# On Windows
git config --global core.autocrlf input
# Or
dos2unix script.sh
```

### Issue 11: Matrix Build Error

**Symptom**: Matrix strategy not working correctly

**Solution**: Verify the matrix syntax and check that all combinations are valid:
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
  fail-fast: false
```

### Issue 12: Secret Not Available

**Symptom**: `${{ secrets.MY_SECRET }}` is empty

**Solution**: Verify the secret is passed correctly:
```bash
# Check secret is set
echo $MY_SECRET

# Pass to act
act -s MY_SECRET

# Or via file
act --secret-file .secrets
```

### Issue 13: Cache Not Working

**Symptom**: `actions/cache` not finding cached data

**Solution**: Ensure cache directory is shared:
```bash
# Bind the cache directory
act --bind --container-options "-v ~/.cache/act:/root/.cache/act"
```

### Issue 14: Reusable Workflow Error

**Symptom**: Cannot call reusable workflow

**Solution**: Ensure the reusable workflow is in the same repository and uses `workflow_call`:
```yaml
# .github/workflows/reusable.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
```

### Issue 15: Docker-in-Docker Fails

**Symptom**: `Cannot connect to the Docker daemon`

**Solution**: Mount the Docker socket:
```bash
act --container-options "-v /var/run/docker.sock:/var/run/docker.sock"
```

### Issue 16: Image Pull Failed

**Symptom**: `Error response from daemon: pull access denied`

**Solution**: Check image name and authentication:
```bash
# For public images
act --platform ubuntu-latest=catthehacker/act:latest

# For private images
docker login
act --platform ubuntu-latest=myregistry/myimage:latest
```

### Issue 17: Timeout

**Symptom**: Step or job times out

**Solution**: Increase timeout or optimize the step:
```bash
# Increase timeout
act --timeout 30m

# Or in workflow
# timeout-minutes: 60
```

### Issue 18: Workflow Not Found

**Symptom**: `No workflows found`

**Solution**: Check the file path and name:
```bash
# List available workflows
act -l

# Specify the workflow file
act -W .github/workflows/ci.yml
```

### Issue 19: Platform Image Mismatch

**Symptom**: Tools not available in container

**Solution**: Use the correct platform image:
```bash
# Full image with all tools
act --platform ubuntu-latest=catthehacker/act:latest

# Or install tools in workflow
steps:
  - name: Install tools
    run: apt-get update && apt-get install -y curl git
```

### Issue 20: Output Variable Not Set

**Symptom**: `${{ steps.my-step.outputs.value }}` is empty

**Solution**: Ensure the step has an `id` and uses `>> "$GITHUB_OUTPUT"`:
```yaml
steps:
  - id: my-step
    run: echo "value=hello" >> "$GITHUB_OUTPUT"
```

---

## Tips & Best Practices

### 1. Start with Dry Run

```bash
# Always start with dry run to see what would execute
act -n
```

### 2. Use Verbose Mode for Debugging

```bash
# Verbose mode shows detailed execution information
act -v
```

### 3. Use a .act.yml for Defaults

```yaml
# .act.yml
artifact-server-path: .act/artifacts
bind-workspace: true
platforms:
  ubuntu-latest: catthehacker/act:latest
```

### 4. Create a .secrets File (in .gitignore)

```bash
# .secrets (DO NOT COMMIT)
MY_SECRET=value
AWS_KEY=your_key
echo ".secrets" >> .gitignore
```

### 5. Pre-pull Docker Images

```bash
# Pull images before running act
docker pull catthehacker/act:latest
```

### 6. Use Specific Runner Images

```bash
# Use specific image for better compatibility
act --platform ubuntu-latest=catthehacker/act:ubuntu-latest
```

### 7. Test One Job at a Time

```bash
# Instead of running all jobs
act -j build  # Test build job only
act -j test   # Test test job only
```

### 8. Bind Workspace for Local Changes

```bash
# Bind workspace to see local changes in containers
act --bind
```

### 9. Use Environment Files

```bash
# Pass multiple secrets at once
act --env-file .env
```

### 10. Clean Up After Testing

```bash
# Remove act containers
docker ps -a --filter "label=com.catthehacker.act" -q | xargs docker rm -f

# Remove artifacts
rm -rf .act/artifacts
```

### 11. Check Workflow Syntax

```bash
# List workflows to verify syntax
act -l
```

### 12. Use Act in CI

```yaml
# Test your workflows in CI
jobs:
  test-workflows:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: catthehacker/act-gh-workflow@v1
        with:
          workflow: ci.yml
```

### 13. Use Make Targets

```makefile
# Makefile
.PHONY: act act-test act-deploy

act:
	act push

act-test:
	act -j test

act-deploy:
	act workflow_dispatch -s DEPLOY_TOKEN=$(DEPLOY_TOKEN)
```

### 14. Use Act with VS Code Tasks

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run CI",
      "type": "shell",
      "command": "act push"
    }
  ]
}
```

### 15. Monitor Container Resources

```bash
# Check container resource usage
docker stats $(docker ps --filter "label=com.catthehacker.act" -q)
```

### 16. Use Act to Test Secrets Handling

```bash
# Test that secrets are properly masked in output
act -s MY_SECRET=secret_value | grep -v secret_value
```

### 17. Use Act for Workflow Validation

```bash
# Validate workflow syntax
act -n  # Dry run
act -l  # List workflows
```

### 18. Use Act with Docker Compose for Complex Environments

```yaml
# docker-compose.act.yml
version: '3.8'
services:
  act-runner:
    image: catthehacker/act:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - .:/workspace
    environment:
      - CI=true
```

---

## Command Reference

### Basic Commands

```bash
# Run the default push event workflow
act push

# Run a specific event
act <event>
# Events: push, pull_request, schedule, workflow_dispatch, release, etc.

# List all workflows and jobs
act -l

# Dry run (show what would execute)
act -n
```

### Job and Workflow Selection

```bash
# Run a specific job
act -j <job-id>

# Run a specific workflow file
act -W <path/to/workflow.yml>

# Run a specific workflow by name
act -W .github/workflows/ci.yml
```

### Secrets and Environment

```bash
# Pass a secret
act -s <SECRET_NAME>=<value>

# Pass a secret from environment
act -s <SECRET_NAME>

# Pass secrets from a file
act --secret-file <path>

# Pass environment variables
act -e <VAR>=<value>

# Pass environment variables from a file
act --env-file <path>
```

### Platform and Images

```bash
# Specify a platform image
act --platform <os>=<image>

# Example
act --platform ubuntu-latest=catthehacker/act:latest

# Pull latest images
act --pull always
```

### Container Options

```bash
# Bind workspace
act --bind

# Set artifact server path
act --artifact-server-path <path>

# Container options
act --container-options "<options>"

# Network mode
act --network host
```

### Verbosity and Debugging

```bash
# Verbose output
act -v

# Debug mode
act --verbose

# Show action logs
act --action-log-file <path>
```

### Event Configuration

```bash
# Custom event payload
act <event> -e <event.json>

# Custom event type for issue_comment
act issue_comment -f payload=<event.json>
```

### Miscellaneous

```bash
# Timeout in minutes
act --timeout <minutes>

# No cache
act --no-cache-dir

# Pull latest images
act --pull always

# Show version
act --version

# Show help
act --help
```

### Common Combinations

```bash
# Test a specific job with secrets
act -j build -s MY_SECRET=value

# Test workflow dispatch with environment
act workflow_dispatch -e env=staging -s TOKEN=abc123

# Full test with verbose output
act push -v --bind

# Clean test
act push --pull always --bind

# Test with custom platform
act push --platform ubuntu-latest=catthehacker/act:ubuntu-latest
```

---

## Configuration Reference

### .act.yml Schema

```yaml
# Artifact server configuration
artifact-server-path: string  # Path to store artifacts

# Workspace binding
bind-workspace: boolean  # Bind workspace into containers

# Default environment variables
env:
  KEY: VALUE

# Platform images
platforms:
  <os>: <image>
  ubuntu-latest: catthehacker/act:latest
  ubuntu-22.04: catthehacker/act:ubuntu-22.04
  macos-latest: catthehacker/act:macos-12
  windows-latest: catthehacker/act:windows-latest

# Secret files
secret-files:
  - path/to/secrets
  - .env

# Container options
container-options: string  # Docker run options

# Event directory
event: string  # Event directory path
```

### Event Payload Structure

```json
{
  "action": "opened",
  "sender": {
    "login": "username",
    "id": 12345
  },
  "repository": {
    "name": "repo-name",
    "full_name": "owner/repo-name"
  },
  "ref": "refs/heads/main",
  "head": {
    "ref": "feature-branch",
    "sha": "abc123"
  },
  "base": {
    "ref": "main",
    "sha": "def456"
  }
}
```

### Platform Image Tags

| Tag | Description | Size |
|-----|-------------|------|
| `latest` | Default image with most tools | ~2GB |
| `ubuntu-latest` | Ubuntu latest with tools | ~2GB |
| `ubuntu-22.04` | Ubuntu 22.04 with tools | ~2GB |
| `ubuntu-20.04` | Ubuntu 20.04 with tools | ~2GB |
| `micro` | Minimal image | ~200MB |
| `large` | GitHub Actions runner snapshot | ~20GB |

---

## Real-World Examples

### Example 1: Testing a Node.js CI Workflow

```yaml
# .github/workflows/ci.yml
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

```bash
# Test locally
act -l  # List jobs
act -j build  # Run build job
act push  # Run full workflow
```

### Example 2: Testing Docker Build

```yaml
# .github/workflows/docker.yml
name: Docker Build

on: push

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: myapp:test
```

```bash
# Test Docker build locally
act push -j docker
```

### Example 3: Testing Deployment with Secrets

```yaml
# .github/workflows/deploy.yml
name: Deploy

on: workflow_dispatch

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy
        run: |
          echo "Deploying with token: ${{ secrets.DEPLOY_TOKEN }}"
          ./deploy.sh
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

```bash
# Test deployment with secrets
act workflow_dispatch -s DEPLOY_TOKEN=abc123
```

### Example 4: Testing Matrix Builds

```yaml
# .github/workflows/matrix.yml
name: Matrix Build

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, windows-latest]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
```

```bash
# Test matrix builds
act push  # Runs all combinations
```

### Example 5: Testing Scheduled Workflows

```yaml
# .github/workflows/scheduled.yml
name: Scheduled Task

on:
  schedule:
    - cron: '0 2 * * 1'

jobs:
  maintenance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./maintenance.sh
```

```bash
# Test scheduled workflow
act schedule
```

### Example 6: Testing Service Containers

```yaml
# .github/workflows/integration.yml
name: Integration Tests

on: push

jobs:
  test:
    runs-on: ubuntu-latest
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
      
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/postgres
          REDIS_URL: redis://localhost:6379
```

```bash
# Test with service containers
act push -j test
```

---

## Further Reading

### Official Documentation
- [Act GitHub Repository](https://github.com/nektos/act)
- [Act Documentation](https://nektosact.com/)
- [Act Configuration Reference](https://github.com/nektos/act#configuration-file)

### Related Tools
- [actionlint](https://github.com/rhysd/actionlint) — GitHub Actions linter
- [act-gh-workflow](https://github.com/catthehacker/act-gh-workflow) — GitHub Action for running act in CI
- [act-runner](https://github.com/catthehacker/act-runner) — Custom act runner

### Community
- [Act Discussions](https://github.com/nektos/act/discussions)
- [GitHub Actions Community Forum](https://github.community/c/github-actions)

### Learning Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
