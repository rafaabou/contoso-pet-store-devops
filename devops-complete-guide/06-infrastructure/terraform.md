# Terraform Complete Guide

## Table of Contents

1. [What Is Terraform](#1-what-is-terraform)
2. [Why Use Terraform](#2-why-use-terraform)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide (Step-by-Step)](#6-usage-guide-step-by-step)
7. [Custom Providers and Modules](#7-custom-providers-and-modules)
8. [Integration](#8-integration)
9. [Security](#9-security)
10. [Troubleshooting (20 Issues)](#10-troubleshooting)
11. [Tips and Best Practices (20 Tips)](#11-tips-and-best-practices)
12. [Command Reference](#12-command-reference)
13. [Configuration Reference](#13-configuration-reference)
14. [Real-World Examples](#14-real-world-examples)
15. [Further Reading](#15-further-reading)

---

# 1. What Is Terraform

Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp that allows you to define, provision, and manage cloud infrastructure across multiple providers using a declarative configuration language called HCL (HashiCorp Configuration Language).

## 1.1 History

Terraform was first released in July 2014 by HashiCorp. It was designed to solve the problem of managing infrastructure across heterogeneous environments where organizations needed a single tool that could work across AWS, Azure, GCP, and many other providers.

Key milestones:
- **2014**: Initial release (v0.1)
- **2016**: Terraform 0.8 introduced workspaces and backends
- **2019**: Terraform 0.12 brought HCL2 with native type system
- **2020**: Terraform 0.13 added the Terraform Registry for community modules
- **2021**: Terraform 1.0 marked production stability
- **2023**: Terraform 1.5 introduced moved blocks and check blocks
- **2023**: HashiCorp changed Terraform license from MPL to BSL, sparking the OpenTofu fork
- **2024**: OpenTofu 1.6+ emerged as an open-source alternative under Linux Foundation

## 1.2 Architecture

Terraform operates on a provider-based architecture:

```
┌─────────────────────────────────────────┐
│           Terraform Core                │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │  Graph Engine│  │ State Manager    │  │
│  │  (DAG)       │  │ (Local/Remote)   │  │
│  └──────┬──────┘  └────────┬─────────┘  │
│         │                  │             │
│  ┌──────┴──────────────────┴─────────┐  │
│  │        Provider Framework         │  │
│  └──┬─────┬─────┬─────┬─────┬───────┘  │
│     │     │     │     │     │           │
│   AWS   Azure  GCP  K8s   Ali...       │
└─────────────────────────────────────────┘
```

## 1.3 How Terraform Works

1. **Write**: You declare resources in HCL files (`.tf`)
2. **Plan**: `terraform plan` shows what changes will be made
3. **Apply**: `terraform apply` executes the planned changes
4. **Destroy**: `terraform destroy` tears down all managed infrastructure

## 1.4 Key Features

- **Provider Agnostic**: Supports 3,000+ providers via the Terraform Registry
- **Declarative**: You describe the desired end state, not the steps to get there
- **Plan/Apply Workflow**: Preview changes before applying them
- **State Management**: Tracks the mapping between configuration and real infrastructure
- **Dependency Resolution**: Automatically builds a dependency graph and provisions resources in the correct order
- **Parallelism**: provisions independent resources concurrently
- **Refresh**: Reads real infrastructure state and compares with expected state
- **Immutability**: Resources are replaced, not patched, when they change

---

# 2. Why Use Terraform

## 2.1 The Problem Terraform Solves

Before IaC, infrastructure was managed manually or with ad-hoc scripts:

- **Drift**: Manual changes accumulate over time, environments diverge from documentation
- **Inconsistency**: Different teams configure similar resources differently
- **No version control**: Infrastructure changes are not tracked
- **Slow provisioning**: Manual setup of servers, networks, and databases takes hours or days
- **Fear of change**: No way to preview what a change will do; changes become risky
- **Documentation rot**: Runbooks and wiki pages become outdated immediately

## 2.2 Benefits

| Benefit | Description |
|---------|-------------|
| **Repeatability** | Same configuration produces identical infrastructure every time |
| **Version Control** | Infrastructure lives in Git, enabling history, review, and rollback |
| **Collaboration** | Teams work on infrastructure as they work on code |
| **Review** | Plan output can be reviewed in pull requests before applying |
| **Documentation** | Configuration IS the documentation |
| **Speed** | Provision complex environments in minutes instead of days |
| **Portability** | Same tool works across AWS, Azure, GCP, on-prem, and SaaS |
| **Dependency Management** | Automatic ordering of resource creation |
| **Multi-Environment** | Workspaces and modules enable managing dev/staging/prod with shared code |
| **Drift Detection** | Detect manual changes to infrastructure automatically |

## 2.3 When to Use Terraform

**Good fit:**
- Cloud infrastructure (VMs, networks, databases, load balancers)
- Kubernetes clusters and resources
- DNS and SSL certificate management
- SaaS configuration (GitHub, Datadog, PagerDuty)
- Hybrid cloud with on-prem resources (VMware, OpenStack)

**Not ideal:**
- Configuration management of running servers (use Ansible/Chef/Puppet)
- Running commands on remote machines (use Ansible or SSH)
- Installing packages on instances (use cloud-init or Ansible)

## 2.4 Terraform vs. Other IaC Tools

| Tool | Focus | Language | State | Best For |
|------|-------|----------|-------|----------|
| Terraform | Provisioning | HCL | File/S3 | Multi-cloud resource provisioning |
| Pulumi | Provisioning | Python/TS/Go | Backend | Developers who prefer general-purpose languages |
| CloudFormation | Provisioning (AWS) | YAML/JSON | AWS-managed | AWS-only environments |
| CDK | Provisioning (AWS) | TS/Python | AWS-managed | AWS with programming language constructs |
| Ansible | Configuration | YAML | None | Server configuration and automation |
| Chef | Configuration | Ruby | Chef Server | Large-scale configuration management |
| Puppet | Configuration | Puppet DSL | Puppet Server | Enterprise configuration management |
| SaltStack | Configuration | YAML/Python | Salt Master | Configuration with event-driven architecture |

---

# 3. Installation

## 3.1 Prerequisites

- **Operating System**: Linux, macOS, or Windows
- **Disk Space**: ~100MB for the binary
- **Memory**: 512MB+ recommended for large state files
- **Network**: Access to provider APIs (e.g., AWS, Azure, GCP)

## 3.2 Install on Linux

### Official Binary

```bash
# Download latest (check https://developer.hashicorp.com/terraform/install for current version)
TERRAFORM_VERSION="1.9.0"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Extract
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

### Via Package Manager (Debian/Ubuntu)

```bash
# Add HashiCorp GPG key and repo
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
```

### Via Package Manager (RHEL/CentOS/Fedora)

```bash
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install terraform
```

### Via AUR (Arch Linux)

```bash
yay -S terraform-bin
```

## 3.3 Install on macOS

```bash
# Homebrew (recommended)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Or via MacPorts
sudo port install terraform
```

## 3.4 Install on Windows

```powershell
# Chocolatey
choco install terraform

# Scoop
scoop install terraform

# winget
winget install HashiCorp.Terraform
```

## 3.5 Install via tfenv (Version Manager)

```bash
# Install tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

# Install specific version
tfenv install 1.9.0
tfenv use 1.9.0

# Install latest
tfenv install latest
tfenv use latest
```

## 3.6 Verify Installation

```bash
terraform version
# Terraform v1.9.0
# on linux_amd64

terraform -version
# Same output
```

## 3.7 Shell Completion

```bash
# Bash
terraform -install-autocomplete

# Zsh - add to ~/.zshrc
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform

# Fish
terraform -install-autocomplete --fish
```

---

# 4. Configuration

## 4.1 Terraform Configuration Files

Terraform reads `.tf` files in the current directory. File names don't matter beyond the extension, but convention is:

| File | Purpose |
|------|---------|
| `main.tf` | Primary resource definitions |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value declarations |
| `providers.tf` | Provider configuration |
| `versions.tf` | Required Terraform and provider versions |
| `backend.tf` | State backend configuration |
| `data.tf` | Data source queries |
| `locals.tf` | Local value definitions |

## 4.2 HCL Syntax Basics

### Comments

```hcl
# Single line comment

/*
  Multi-line
  comment
*/

// Also valid single line
```

### Blocks

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}
```

### Expressions

```hcl
# String interpolation
resource "aws_instance" "web" {
  tags = {
    Name = "server-${var.environment}-${count.index}"
  }
}

# Conditional
instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"

# For expressions
instance_ids = [for s in var.server_list : aws_instance.servers[s].id]

# Function calls
cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
```

## 4.3 Provider Configuration

```hcl
# providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azure = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
```

## 4.4 Variables

```hcl
# variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    allocated_storage = number
  })
}
```

Variable values can be provided via:

1. **Default values** in the variable block
2. **terraform.tfvars** file (auto-loaded)
3. **\*.auto.tfvars** files (auto-loaded)
4. **CLI flags**: `-var 'key=value'`
5. **Environment variables**: `TF_VAR_key=value`
6. **Variable definitions files**: `-var-file="prod.tfvars"`

## 4.5 Outputs

```hcl
# outputs.tf

output "instance_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "load_balancer_dns" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

## 4.6 Data Sources

```hcl
# data.tf

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-*-amd64-server-*"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "existing" {
  tags = {
    Name = "production-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  tags = {
    Type = "private"
  }
}
```

---

# 5. Core Concepts

## 5.1 Resources

Resources are the most important Terraform element. Each resource block describes one or more infrastructure objects.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = var.subnet_ids[0]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags["UpdatedAt"]]
  }
}
```

## 5.2 State

Terraform state is a JSON file that maps your configuration to real infrastructure. It records:
- The ID of each managed resource
- Resource attributes
- Dependencies between resources
- Metadata

### State Backend Types

| Backend | Use Case |
|---------|----------|
| Local | Default; files on disk |
| S3 + DynamoDB | AWS; recommended for teams |
| Azure Storage | Azure environments |
| GCS | Google Cloud environments |
| Terraform Cloud | HashiCorp's managed service |
| Consul | HashiCorp's service discovery |

### Remote State Configuration

```hcl
# backend.tf

terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## 5.3 Dependency Graph

Terraform builds a Directed Acyclic Graph (DAG) of all resources based on their dependencies:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Depends on aws_vpc.main
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id  # Depends on aws_subnet.public
  # Transitively depends on aws_vpc.main
}
```

## 5.4 Lifecycle Rules

```hcl
resource "aws_instance" "web" {
  # ...

  lifecycle {
    # Create new before destroying old
    create_before_destroy = true

    # Prevent accidental destruction
    prevent_destroy = true

    # Ignore changes to specific attributes
    ignore_changes = [tags, user_data]

    # Replace the resource if these change
    replace_triggered_by = [aws_security_group.web.id]

    # Provisioners run in this order
    provisioner "local-exec" {
      command = "echo Created ${self.id}"
    }
  }
}
```

## 5.5 Provisioners

Provisioners execute actions on resources after creation or before destruction.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
    ]
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' -u ubuntu configure.yml"
  }

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/nginx.conf"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo Destroyed ${self.private_ip} >> destroyed.txt"
  }
}
```

## 5.6 Modules

Modules are containers for multiple resources used together.

```hcl
# Using the AWS VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = var.environment != "prod"
}

# Custom module
module "web_server" {
  source = "./modules/web-server"

  name          = "api"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnets
  instance_type = var.instance_type
}
```

## 5.7 Workspaces

Workspaces allow managing multiple environments with the same configuration.

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod

# List workspaces
terraform workspace list

# Show current
terraform workspace show
```

```hcl
# Use workspace to vary configuration
locals {
  instance_type = terraform.workspace == "prod" ? "m5.large" : "t3.micro"
  min_count     = terraform.workspace == "prod" ? 3 : 1
}
```

## 5.8 Moving Resources

```hcl
# Rename a resource without destroying/recreating
moved {
  from = aws_instance.web
  to   = aws_instance.application
}

# Move to a module
moved {
  from = aws_instance.web
  to   = module.web_servers.aws_instance.web
}

# Move into a count
moved {
  from = aws_instance.web
  to   = aws_instance.web[0]
}
```

## 5.9 Import and Lifecycle

```bash
# Import existing infrastructure into Terraform
terraform import aws_instance.web i-0123456789abcdef0
terraform import module.vpc.aws_vpc.main vpc-abc123

# Import with ID mapping
terraform import 'aws_instance.web["server-1"]' i-0123456789abcdef0
```

---

# 6. Usage Guide (Step-by-Step)

## 6.1 Step 1: Initialize a Project

```bash
mkdir my-project && cd my-project

# Create main configuration
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

cat > variables.tf << 'EOF'
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
EOF

# Initialize (downloads providers)
terraform init
```

## 6.2 Step 2: Write Configuration

```hcl
# main.tf

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}
```

## 6.3 Step 3: Plan Changes

```bash
# Preview changes
terraform plan

# Save plan for later use
terraform plan -out=tfplan

# Plan with variables
terraform plan -var='aws_region=eu-west-1'
```

## 6.4 Step 4: Apply Changes

```bash
# Apply all changes
terraform apply

# Apply saved plan
terraform apply tfplan

# Auto-approve (CI/CD only)
terraform apply -auto-approve

# Apply with parallelism (default 10)
terraform apply -parallelism=5
```

## 6.5 Step 5: Inspect State

```bash
# List all resources
terraform state list

# Show resource details
terraform state show aws_instance.web[0]

# Show specific output
terraform output
terraform output instance_public_ip
terraform output -json
```

## 6.6 Step 6: Modify Infrastructure

```hcl
# Add a new resource
resource "aws_eip" "nat" {
  domain = "vpc"
}

# Modify existing resource
resource "aws_instance" "web" {
  count         = 3  # Changed from 2 to 3
  instance_type = "t3.medium"  # Changed from t3.micro
  # ...
}
```

## 6.7 Step 7: Destroy Infrastructure

```bash
# Destroy everything
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_instance.web[0]

# Preview destruction
terraform plan -destroy
```

## 6.8 Step 8: Manage State

```bash
# Move resource in state
terraform state mv aws_instance.web aws_instance.application

# Remove resource from state (keeps real resource)
terraform state rm aws_instance.web[1]

# Replace resource
terraform apply -replace=aws_instance.web[0]

# Force unlock state (after failed apply)
terraform force-unlock LOCK_ID
```

## 6.9 Step 9: Format and Validate

```bash
# Format all files
terraform fmt

# Check formatting without changing
terraform fmt -check

# Validate configuration
terraform validate

# Syntax check
terraform fmt -check -diff
```

---

# 7. Custom Providers and Modules

## 7.1 Creating a Custom Module

```
modules/
  web-server/
    main.tf
    variables.tf
    outputs.tf
```

### modules/web-server/main.tf

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_eip" "this" {
  count    = var.assign_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"
}
```

### modules/web-server/variables.tf

```hcl
variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "assign_eip" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### modules/web-server/outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "eip" {
  value = var.assign_eip ? aws_eip.this[0].public_ip : null
}
```

## 7.2 Using the Module

```hcl
module "api_server" {
  source = "./modules/web-server"

  name               = "api-server"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = "t3.medium"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.web_sg.id]
  assign_eip         = true
  tags               = { Team = "backend" }
}
```

## 7.3 Publishing Modules

```hcl
# Register with Terraform Registry (requires GitHub + Terraform Cloud)

# In module source
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
```

---

# 8. Integration

## 8.1 CI/CD with GitHub Actions

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  TF_VERSION: "1.9.0"
  AWS_REGION: "us-east-1"

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Plan
        run: terraform plan -no-color
        if: github.event_name == 'pull_request'

      - name: Terraform Apply
        run: terraform apply -auto-approve
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

## 8.2 Integration with Ansible

```hcl
# terraform output to ansible inventory
output "ansible_inventory" {
  value = <<-EOF
    [webservers]
    %{for i, instance in aws_instance.web~}
    web-${i + 1} ansible_host=${instance.public_ip}
    %{endfor~}

    [databases]
    %{for i, instance in aws_instance.db~}
    db-${i + 1} ansible_host=${instance.private_ip}
    %{endfor~}
  EOF
}
```

## 8.3 Terragrunt for DRY Configuration

```hcl
# terragrunt.hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "my-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamdb_table  = "terraform-locks"
  }
}
```

## 8.4 Sentinel Policies (Terraform Cloud)

```python
# policy.sentinel
import "tfplan/v2" as tfplan

# Require specific instance types
approved_instance_types = ["t3.micro", "t3.small", "t3.medium", "m5.large"]

enforce_instance_type = rule {
    all tfplan.resource_changes as _, rc {
        rc.type != "aws_instance" or
        rc.change.after.instance_type in approved_instance_types
    }
}
```

---

# 9. Security

## 9.1 Secrets Management

**Never store secrets in .tf files or state files.**

### Using HashiCorp Vault

```hcl
provider "vault" {
  address = "https://vault.example.com"
}

data "vault_generic_secret" "aws_creds" {
  path = "secret/aws/production"
}

provider "aws" {
  region     = "us-east-1"
  access_key = data.vault_generic_secret.aws_creds.data["access_key"]
  secret_key = data.vault_generic_secret.aws_creds.data["secret_key"]
}
```

### Using Environment Variables

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
terraform plan
```

### Using AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
  # ...
}
```

## 9.2 State File Security

```hcl
# Encrypt state at rest
terraform {
  backend "s3" {
    bucket  = "terraform-state"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true  # AES-256 encryption
  }
}
```

### Access Controls

```bash
# S3 bucket policy for state access
aws s3api put-bucket-policy --bucket terraform-state --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::ACCOUNT:role/terraform-role"},
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::terraform-state/*"
    }
  ]
}'
```

## 9.3 Network Security

```hcl
# Restrict SSH access
resource "aws_security_group" "ssh" {
  name_prefix = "ssh-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.office_cidr]  # Only office IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## 9.4 IAM Best Practices

```hcl
# Least privilege IAM policy
resource "aws_iam_policy" "terraform_role_policy" {
  name = "TerraformRolePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "rds:*",
          "iam:ListRoles",
          "iam:ListInstanceProfiles",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## 9.5 Drift Detection

```bash
# Detect manual changes to infrastructure
terraform plan -detailed-exitcode

# Exit codes:
# 0 = No changes
# 1 = Error
# 2 = Changes detected
```

## 9.6 Code Signing and Verification

```hcl
# Require signed modules
module "vpc" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "1.0.0"

  # Module must be from a trusted source
}
```

---

# 10. Troubleshooting

## Issue 1: Error: Provider Configuration Not Present

```
Error: Provider configuration not present

To work with aws_instance.web (original resource) its original provider
configuration at module.vpc.providers["registry.terraform.io/hashicorp/aws"]
is required, but it has been removed.
```

**Cause**: Provider block was moved or removed after resources were created.

**Fix**: Move providers to a root module, or configure `required_providers` with a `configuration_aliases` for cross-module provider usage.

## Issue 2: Error: Error acquiring the state lock

```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        abc123-def456
  Path:      terraform-state/terraform.tfstate
```

**Cause**: A previous apply crashed or was interrupted.

**Fix**:
```bash
# Review the lock
terraform force-unlock abc123-def456

# Then verify state consistency
terraform refresh
terraform plan
```

## Issue 3: Error: Error: Provider produced inconsistent result

```
Error: Provider produced inconsistent result after apply

After applying the changes to aws_instance.web, the provider indicated an
unknown value for attribute "public_ip".
```

**Cause**: Provider bug or timing issue with API responses.

**Fix**:
```bash
# Retry the apply
terraform apply

# Or if persistent, pin provider version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.31.0"
    }
  }
}
```

## Issue 4: Error: Error creating Security Group: DependencyViolation

```
Error: Error creating Security Group: DependencyViolation: resource sg-xxx has
a dependent object
```

**Cause**: Security group is still attached to resources.

**Fix**:
```bash
# Find what uses it
terraform state show aws_security_group.web
# Check all references in configuration

# Force target-based destroy order
terraform destroy -target=aws_instance.web
terraform destroy -target=aws_security_group.web
```

## Issue 5: Error: Invalid value for count

```
Error: Invalid value for count argument

The given "count" argument value is unsuitable: must be a number, and known
in advance.
```

**Cause**: Count depends on a value not known at plan time.

**Fix**:
```hcl
# Use for_each instead (supports unknown values at plan time)
resource "aws_instance" "web" {
  for_each = toset(var.subnet_ids)
  # ...
}
```

## Issue 6: Error: Cycle Detected

```
Error: Cycle: aws_instance.web, aws_security_group.web
```

**Cause**: Circular dependency between resources.

**Fix**:
```hcl
# Break the cycle by removing a dependency or restructuring
# Often caused by referencing back-attributes unnecessarily

# BAD (cycle):
resource "a" "x" { b_id = b.y.id }
resource "b" "y" { a_id = a.x.id }

# GOOD (break cycle):
resource "a" "x" { }
resource "b" "y" { a_id = a.x.id }
```

## Issue 7: Error: Error: Error deleting security group

```
Error: deleting Security Group (sg-xxx): DependencyViolation
```

**Cause**: Resources still reference the security group.

**Fix**:
```bash
# Check for any remaining resources
terraform state list | grep -v "aws_security_group.web"

# Or check AWS console for orphaned ENIs
aws ec2 describe-network-interfaces --filters "Name=group-id,Values=sg-xxx"
```

## Issue 8: Error: Error: Invalid for_each argument

```
Error: Invalid for_each argument

The given "for_each" argument value is unsuitable: must be a map, or set of
strings, and you have provided a value of type list of string.
```

**Fix**:
```hcl
# Convert list to set
for_each = toset(var.subnet_ids)

# Or use a map
for_each = { for s in var.subnet_ids : s => s }
```

## Issue 9: Error: Error: Missing required argument

```
Error: Missing required argument

The argument "ami" is required, but no definition was found.
```

**Fix**:
```hcl
# Check variable references
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id  # Ensure this is correct
  # ...
}
```

## Issue 10: Error: Error: Error retrieving SSM Parameter

```
Error: Error retrieving SSM Parameter /terraform/db-password
```

**Cause**: Parameter doesn't exist or IAM permissions insufficient.

**Fix**:
```bash
# Verify parameter exists
aws ssm get-parameter --name "/terraform/db-password"

# Check IAM permissions
aws sts get-caller-identity
```

## Issue 11: Error: Error: The plan cannot be applied

```
Error: The plan cannot be applied as it requires approval but was not expected
to require approval
```

**Cause**: Plan has unexpected changes due to drift or external modifications.

**Fix**:
```bash
# Refresh state first
terraform refresh

# Then re-plan
terraform plan
```

## Issue 12: Error: Error: Backend initialization required

```
Error: Backend initialization required

The backend has changed since the last initialization.
```

**Fix**:
```bash
# Reinitialize
terraform init -migrate-state

# Or reconfigure
terraform init -reconfigure
```

## Issue 13: Error: Error: Circular dependency between modules

**Cause**: Two modules reference each other's outputs.

**Fix**:
- Move shared resources to a third module
- Use data sources to reference existing resources
- Restructure to eliminate circular references

## Issue 14: Error: Error: count/for_each can't reference resource

```
Error: Reference to resource not allowed

Count references are not permitted in provider configuration.
```

**Cause**: Using `count` or `for_each` in provider blocks.

**Fix**:
```hcl
# Providers can't use count. Use aliases instead
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}
```

## Issue 15: Error: Error: State file corruption

```
Error: Error reading state file

Error: unexpected EOF
```

**Fix**:
```bash
# Check S3 versioning
aws s3api list-object-versions --bucket terraform-state --prefix prod/terraform.tfstate

# Restore from backup
aws s3api get-object --bucket terraform-state --key prod/terraform.tfstate.backup terraform.tfstate

# Or use terraform state pull/push
terraform state pull > backup.tfstate
terraform state push backup.tfstate
```

## Issue 16: Error: Error: Resource already managed

```
Error: resource already managed by Terraform

This resource already exists. To attach to an existing resource, use terraform import.
```

**Fix**:
```bash
# Import existing resource
terraform import aws_instance.existing i-0123456789abcdef0

# Or remove from state
terraform state rm aws_instance.existing
```

## Issue 17: Error: Error: Provider version constraints too strict

```
Error: Provider configuration not present

No configuration is present for provider "registry.terraform.io/hashicorp/aws"
with version constraint "~> 4.0" in module "vpc".
```

**Fix**:
```hcl
# Update version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Issue 18: Error: Error: Empty variable or output

```
Error: Output or variable value not set

The value of output "instance_ip" is null or empty.
```

**Fix**:
```hcl
# Ensure value is always set
output "instance_ip" {
  value = aws_instance.web.public_ip  # Ensure resource exists
}
```

## Issue 19: Error: Error: State drift after provider upgrade

After upgrading providers, some attributes may change format or behavior.

**Fix**:
```bash
# Review what will change
terraform plan

# Apply carefully
terraform apply

# Or pin versions and upgrade gradually
```

## Issue 20: Error: Error: Insufficient permissions

```
Error: UnauthorizedOperation: You are not authorized to perform this operation
```

**Fix**:
```bash
# Check current identity
aws sts get-caller-identity

# Check attached policies
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)

# Ensure required permissions
```

---

# 11. Tips and Best Practices

## Tip 1: Use Remote State with Locking

Always use a remote backend with state locking for team environments:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "env:/prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Tip 2: Pin Provider and Terraform Versions

```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Tip 3: Use terraform fmt and validate

Always run before committing:

```bash
terraform fmt -recursive
terraform validate
```

## Tip 4: Use Variables for Everything That Varies

```hcl
# BAD: hardcoded value
resource "aws_instance" "web" {
  instance_type = "t3.micro"
}

# GOOD: variable
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

## Tip 5: Use Locals for Derived Values

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

## Tip 6: Use for_each Over count When Possible

```hcl
# For_each survives element removal; count shifts indices
resource "aws_instance" "web" {
  for_each = toset(var.server_names)
  tags = {
    Name = each.value
  }
}
```

## Tip 7: Keep State Small

Split state files per component:
```
terraform -chdir=environments/prod/vpc apply
terraform -chdir=environments/prod/servers apply
terraform -chdir=environments/prod/databases apply
```

## Tip 8: Use Workspaces or Directory-Based Environments

```bash
# Directory-based (recommended for isolation)
environments/
  dev/
    main.tf
  staging/
    main.tf
  prod/
    main.tf
```

## Tip 9: Don't Hardcode Secrets

```bash
# Use environment variables
export TF_VAR_db_password="secret123"

# Or use a secrets manager
data "vault_generic_secret" "db" {
  path = "secret/db"
}
```

## Tip 10: Review Plan Output Carefully

```bash
# Save plan for review
terraform plan -out=tfplan
terraform show tfplan

# In CI/CD, post plan to PRs
```

## Tip 11: Use Sentinel or OPA for Policy Enforcement

```python
# Sentinel: enforce tagging
import "tfplan/v2" as tfplan

required_tags = ["Environment", "ManagedBy", "Team"]

enforce_tags = rule {
    all tfplan.resource_changes as _, rc {
        rc.mode is "managed" and
        (rc.type is not "null_resource") implies
        keys(rc.change.after.tags) contains required_tags
    }
}
```

## Tip 12: Use terraform import for Existing Resources

```bash
# Import before managing
terraform import aws_vpc.existing vpc-abc123

# Then write configuration matching the import
```

## Tip 13: Tag Everything

```hcl
locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
    Project     = var.project
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.common_tags
  }
}
```

## Tip 14: Use Data Sources for Lookup

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

## Tip 15: Use Output Values for Cross-Module Communication

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID for use by other modules"
}
```

## Tip 16: Use lifecycle.prevent_destroy for Critical Resources

```hcl
resource "aws_db_instance" "production" {
  # ...
  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }
}
```

## Tip 17: Use tflint and tfsec for Code Quality

```bash
# Install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Run linter
tflint --init
tflint

# Run tfsec security scanner
tfsec .
```

## Tip 18: Use -target for Selective Apply

```bash
# Apply only specific resources
terraform apply -target=aws_instance.web
terraform apply -target=module.vpc
```

## Tip 19: Use Provisioners as Last Resort

```hcl
# Prefer cloud-init over provisioners
resource "aws_instance" "web" {
  user_data = filebase64("cloud-init.yml")
}

# If you must use provisioners
resource "aws_instance" "web" {
  provisioner "remote-exec" {
    inline = ["sudo apt-get update"]
    connection {
      type = "ssh"
      host = self.public_ip
      user = "ubuntu"
    }
  }
}
```

## Tip 20: Document Your Infrastructure

```hcl
# Use descriptions everywhere
variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be /16 to allow 256 subnets."
  type        = string
}

output "vpc_id" {
  description = "The ID of the VPC. Use this to reference the VPC in other modules."
  value       = aws_vpc.main.id
}
```

---

# 12. Command Reference

## terraform init

Initialize a new or existing Terraform configuration.

```bash
terraform init [options]

# Options:
-backend-config=PATH    # Backend configuration file
-backend=true           # Initialize backend (default)
-force-copy             # Force overwrite state files in backend
-get=true               # Download modules
-migrate-state=false    # Migrate state to new backend
-plugin-dir=PATH        # Plugin directory
-reconfigure=false      # Reconfigure backend
-upgrade=false          # Upgrade modules/plugins
```

## terraform plan

Generate an execution plan.

```bash
terraform plan [options]

# Options:
-out=FILE               # Save plan to file
-destroy                # Plan for destruction
-target=RESOURCE        # Target specific resource
-var=NAME=VALUE         # Set variable
-var-file=FILE          # Load variables from file
-parallelism=N          # Max parallel operations (default 10)
-detailed-exitcode      # Return exit code 2 if changes detected
-no-color               # Disable colored output
-refresh=true           # Refresh state before planning
```

## terraform apply

Apply changes to infrastructure.

```bash
terraform apply [options] [PLAN-FILE]

# Options:
-auto-approve           # Skip interactive approval
-target=RESOURCE        # Target specific resource
-var=NAME=VALUE         # Set variable
-var-file=FILE          # Load variables from file
-parallelism=N          # Max parallel operations
-replace=RESOURCE       # Force replacement of resource
```

## terraform destroy

Destroy all infrastructure.

```bash
terraform destroy [options]

# Options:
-target=RESOURCE        # Target specific resource
-var=NAME=VALUE         # Set variable
-var-file=FILE          # Load variables from file
-auto-approve           # Skip interactive approval
-parallelism=N          # Max parallel operations
```

## terraform state

Advanced state management.

```bash
terraform state list                           # List all resources
terraform state show RESOURCE                  # Show resource details
terraform state mv SOURCE DEST                 # Move resource
terraform state rm RESOURCE                    # Remove from state
terraform state pull > backup.tfstate          # Pull state to file
terraform state push backup.tfstate            # Push state from file
```

## terraform import

Import existing infrastructure.

```bash
terraform import [options] RESOURCE ID

# Examples:
terraform import aws_instance.web i-0123456789abcdef0
terraform import 'aws_instance.web["server-1"]' i-0123456789abcdef0
```

## terraform output

Show output values.

```bash
terraform output [NAME]          # Show specific output
terraform output -json           # JSON format
terraform output -raw NAME      # Raw value
```

## terraform fmt

Format configuration files.

```bash
terraform fmt [PATH...]         # Format files
terraform fmt -check            # Check formatting
terraform fmt -recursive        # Format subdirectories
terraform fmt -diff             # Show formatting changes
```

## terraform validate

Validate configuration.

```bash
terraform validate
```

## terraform refresh

Refresh state with real infrastructure.

```bash
terraform refresh [options]
```

## terraform console

Interactive console for evaluating expressions.

```bash
terraform console              # Start console
> aws_instance.web.id          # Evaluate expressions
> var.environment
```

---

# 13. Configuration Reference

## 13.1 terraform Block

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## 13.2 Provider Block

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT:role/terraform"
  }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}
```

## 13.3 Resource Block

```hcl
resource "TYPE" "NAME" {
  # Required arguments

  # Optional arguments
  count     = 1
  for_each  = toset(["a", "b"])
  provider  = aws.us_east

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [attribute]
    replace_triggered_by  = [resource.id]
  }

  provisioner "local-exec" {
    command = "..."
    when    = create
  }
}
```

## 13.4 Data Source Block

```hcl
data "TYPE" "NAME" {
  # Arguments

  filter {
    name   = "attribute"
    values = ["value"]
  }
}
```

## 13.5 Variable Block

```hcl
variable "NAME" {
  description = "Description"
  type        = TYPE
  default     = DEFAULT
  sensitive   = false

  validation {
    condition     = CONDITION
    error_message = "Error message"
  }

  # Type examples
  # type = string
  # type = number
  # type = bool
  # type = list(string)
  # type = map(string)
  # type = object({ name = string, size = number })
  # type = set(string)
  # type = tuple([string, number])
  # type = object({ name = string, tags = map(string) })
}
```

## 13.6 Output Block

```hcl
output "NAME" {
  description = "Description"
  value       = EXPRESSION
  sensitive   = false
}
```

## 13.7 Locals Block

```hcl
locals {
  name    = "my-resource"
  tags    = { Name = local.name }
  subnets = [for s in var.subnets : s if s.availability_zone == "us-east-1a"]
}
```

## 13.8 Module Block

```hcl
module "NAME" {
  source = "./modules/vpc"

  # Module inputs
  cidr_block = "10.0.0.0/16"
}
```

---

# 14. Real-World Examples

## Example 1: Complete AWS VPC with Public/Private Subnets

```hcl
# main.tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "production-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Bastion host
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = { Name = "bastion" }
}

# Web servers
resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id     = module.vpc.private_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = templatefile("user-data.sh", {
    db_host = aws_db_instance.main.address
  })

  tags = { Name = "web-${count.index + 1}" }
}

# RDS
resource "aws_db_instance" "main" {
  identifier          = "production-db"
  engine              = "postgres"
  engine_version      = "15.4"
  instance_class      = "db.t3.medium"
  allocated_storage   = 100
  db_name             = "appdb"
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = false
  multi_az            = true

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
}
```

## Example 2: Kubernetes Cluster on AWS (EKS)

```hcl
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.0"
  cluster_name    = "production-eks"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    general = {
      desired_size = 2
      min_size     = 1
      max_size     = 5

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "production"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = { "kubernetes.io/cluster/production-eks" = "shared" }
}

# Kubectl provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "production"
  }
}
```

## Example 3: Multi-Region Infrastructure

```hcl
# main.tf
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}

# US East resources
module "us_east_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.us_east
  }
  cidr = "10.0.0.0/16"
}

# EU West resources
module "eu_west_vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.eu_west
  }
  cidr = "10.1.0.0/16"
}

# Global resources
resource "aws_route53_health_check" "us_east" {
  provider = aws.us_east
  fqdn     = module.us_east_vpc.alb_dns_name
  port     = 443
}

resource "aws_route53_health_check" "eu_west" {
  provider = aws.eu_west
  fqdn     = module.eu_west_vpc.alb_dns_name
  port     = 443
}

# Failover DNS
resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = "api.example.com"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "us-east"
  alias {
    name                   = module.us_east_vpc.alb_dns_name
    zone_id                = module.us_east_vpc.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.us_east.id
}
```

## Example 4: Complete CI/CD Pipeline Infrastructure

```hcl
# GitHub Actions + Terraform Cloud + AWS

module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.30.0"

  oidc_providers = {
    main = {
      provider_arn               = "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      clients                    = ["sts.amazonaws.com"]
      allowed_service_accounts   = ["github-actions"]
      allowed_repos              = ["org/repo"]
    }
  }
}

# ECR for container images
resource "aws_ecr_repository" "app" {
  name = "my-app"
}

# ECS Fargate service
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  # ...
}
```

## Example 5: Shared Module Library

```
infrastructure/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
    ecs-service/
      main.tf
      variables.tf
      outputs.tf
    rds/
      main.tf
      variables.tf
      outputs.tf
  environments/
    dev/
      main.tf (uses modules)
      terraform.tfvars
    staging/
      main.tf
      terraform.tfvars
    prod/
      main.tf
      terraform.tfvars
  global/
    iam/
      main.tf
    route53/
      main.tf
```

---

# 15. Further Reading

## Official Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Language](https://developer.hashicorp.com/terraform/language)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform GitHub](https://github.com/hashicorp/terraform)
- [OpenTofu](https://opentofu.org/) - Open-source Terraform alternative

## Learning Resources

- [HashiCorp Learn](https://developer.hashicorp.com/terraform/tutorials)
- [Terraform Up & Running](https://www.terraformupandrunning.com/) by Yevgeniy Brikman
- [Terraform in Action](https://www.manning.com/books/terraform-in-action) by Scott Winkler
- [How to Manage Terraform at Scale](https://www.terraform.io/docs/cloud/sentinel/index.html)

## Community

- [Terraform Discuss](https://discuss.hashicorp.com/c/terraform/)
- [Terraform subreddit](https://www.reddit.com/r/Terraform/)
- [Terraform Weekly Newsletter](https://www.terraform.io/newsletter)

## Related Tools

- **Terragrunt**: Thin wrapper for DRY Terraform configurations
- **TFLint**: Terraform linter
- **tfsec**: Security scanner
- **Infracost**: Cost estimation for Terraform
- **Atlantis**: Pull request automation for Terraform
- **Spacelift**: Managed Terraform platform
- **SpaceShip**: Terraform state management

---

*This guide covers Terraform as of version 1.9.x. For the latest features and changes, refer to the official documentation.*
