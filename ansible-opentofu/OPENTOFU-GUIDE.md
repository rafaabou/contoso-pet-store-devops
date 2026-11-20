# OPENTOFU USER GUIDE — ZERO TO HERO

## For the Contoso Pet Store K3s Cluster Project

---

# PART 1: WHAT IS OPENTOFU?

## The Simple Explanation

OpenTofu is a **robot that builds computers for you**.

Instead of clicking buttons and typing commands to create containers, you write a **plan** (a text file) that says "make 2 containers with these settings" and the robot does it.

**Why use it?**
- Faster: 3 minutes instead of 30 minutes
- Safer: You check the plan before the robot builds
- Repeatable: Run the same plan 10 times, get the same result
- Undoable: Tell the robot "destroy everything" and it does

## Where Did It Come From?

In 2023, a company called HashiCorp changed the license of their tool "Terraform" from free to restricted. The community got angry and created OpenTofu — a free copy that stays open forever. It is maintained by the Linux Foundation.

**OpenTofu reads the same files as Terraform.** If you learn OpenTofu, you also know Terraform.

---

# PART 2: INSTALLATION

## Install on Ubuntu

```bash
# Step 1: Update package list
sudo apt update

# Step 2: Install required tools
sudo apt install -y gnupg software-properties-common

# Step 3: Add HashiCorp GPG key (security key to verify downloads)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Step 4: Add HashiCorp repository (where to download from)
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Step 5: Update again (now includes HashiCorp repo)
sudo apt update

# Step 6: Install OpenTofu
sudo apt install tofu
```

## Verify Installation

```bash
tofu version
```

**Expected output:**
```
OpenTofu v1.8.x
on linux_amd64
```

---

# PART 3: THE 4 BASIC COMMANDS

## Command 1: `tofu init` — "Wake up and get ready"

```bash
tofu init
```

**What it does:** Downloads the tools (providers) OpenTofu needs to work.

**When to run it:** Only once, when you first start or when you add new providers.

**What you see:**
```
Initializing the backend...

Initializing provider plugins...
- Finding lxc/incus versions matching "~> 1.1.0"...
- Installing lxc/incus v1.1.0...

Terraform has been successfully initialized!
```

**Analogy:** It is like a chef getting their ingredients before cooking. You do this once, not every time you cook.

---

## Command 2: `tofu plan` — "Show me what you will do"

```bash
tofu plan
```

**What it does:** Shows you what OpenTofu WILL do before it actually does it.

**When to run it:** Every time before `tofu apply`. Always check the plan first.

**What you see:**
```
Terraform will perform the following actions:

  # incus_instance.master will be created
  + resource "incus_instance" "master" {
      + id   = (known after apply)
      + name = "k3s-master"
      ...
    }

  # incus_instance.worker1 will be created
  + resource "incus_instance" "worker1" {
      + id   = (known after apply)
      + name = "k3s-worker-1"
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**The important line:** `Plan: 2 to add, 0 to change, 0 to destroy.`

| Number | Meaning |
|--------|---------|
| `2 to add` | Will create 2 new things |
| `0 to change` | Will not change anything existing |
| `0 to destroy` | Will not delete anything |

**Analogy:** It is like a contractor showing you the blueprints before building. You check "yes, that is what I want" before they start.

---

## Command 3: `tofu apply` — "Do it now"

```bash
tofu apply
```

**What it does:** Actually creates the containers.

**When to run it:** After you checked the plan and it looks correct.

**What you see:**
```
incus_instance.master: Creating...
incus_instance.master: Creation complete after 45s [id=k3s-master]
incus_instance.worker1: Creating...
incus_instance.worker1: Creation complete after 38s [id=k3s-worker-1]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

master_name = "k3s-master"
master_ip = "10.195.94.80"
worker1_name = "k3s-worker-1"
worker1_ip = "10.195.94.81"
```

**The important line:** `Apply complete! Resources: 2 added, 0 changed, 0 destroyed.`

**To skip the confirmation prompt:**
```bash
tofu apply -auto-approve
```

**Analogy:** It is like the contractor actually building the house after you approved the blueprints.

---

## Command 4: `tofu destroy` — "Tear it down"

```bash
tofu destroy
```

**What it does:** Deletes everything that was created.

**When to run it:** When you want to start over or clean up.

**What you see:**
```
incus_instance.worker1: Destroying...
incus_instance.worker1: Destruction complete after 12s
incus_instance.master: Destroying...
incus_instance.master: Destruction complete after 15s

Destroy complete! Resources: 2 destroyed.
```

**To skip the confirmation prompt:**
```bash
tofu destroy -auto-approve
```

**Analogy:** It is like demolishing the house. Everything goes back to empty land.

---

# PART 4: THE FILE TYPES

## Overview

OpenTofu uses text files with the extension `.tf`. There are 5 types:

| File | Purpose | Required? |
|------|---------|-----------|
| `providers.tf` | "Which tools to use" | Yes |
| `variables.tf` | "What settings" | Yes |
| `main.tf` | "What to build" | Yes |
| `outputs.tf` | "What to show after" | No |
| `terraform.tfvars` | "Override defaults" | No |

---

## File Type 1: `providers.tf` — "Which tools to use"

```hcl
terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.1.0"
    }
  }
}

provider "incus" {
  generate_client_certificates = true
}
```

**What each part does:**

| Part | Meaning |
|------|---------|
| `terraform {` | "Hey OpenTofu, listen" |
| `required_providers {` | "You need a helper tool" |
| `incus = {` | "The helper is called Incus" |
| `source = "lxc/incus"` | "Get it from the Incus company" |
| `version = "~> 1.1.0"` | "Version 1.1.x is fine" |
| `provider "incus" {` | "Now configure it" |
| `generate_client_certificates = true` | "Make security keys" |

**Analogy:** This is like telling Amazon "I want to order from your store, version 2.0 of the app is fine, and here is my login."

---

## File Type 2: `variables.tf` — "What settings"

```hcl
variable "prefix" {
  description = "Cluster name prefix"
  type        = string
  default     = "k3s"
}
```

**What each part does:**

| Part | Meaning |
|------|---------|
| `variable "prefix"` | "I have a setting called prefix" |
| `description = "Cluster name prefix"` | "This controls the cluster name prefix" |
| `type = string` | "It is text" |
| `default = "k3s"` | "If not changed, use k3s" |

**Variable types:**

| Type | Example | Use for |
|------|---------|---------|
| `string` | `"hello"` | Text values |
| `number` | `4` | Numbers |
| `bool` | `true` or `false` | True/false |
| `list` | `["a", "b", "c"]` | Lists of items |
| `map` | `{key1 = "val1", key2 = "val2"}` | Key-value pairs |

**How to use variables:**
```hcl
# In variables.tf:
variable "prefix" {
  default = "k3s"
}

# In main.tf:
name = "${var.prefix}-master"  # Becomes "k3s-master"
```

**How to override variables:**

Option 1: Edit `variables.tf`
```hcl
default = "petstore"  # Change from "k3s" to "petstore"
```

Option 2: Create `terraform.tfvars`
```hcl
prefix = "petstore"
```

Option 3: Command line
```bash
tofu apply -var="prefix=petstore"
```

---

## File Type 3: `main.tf` — "What to build"

```hcl
resource "incus_instance" "master" {
  name  = "k3s-master"
  image = "ubuntu-noble"
}
```

**What each part does:**

| Part | Meaning |
|------|---------|
| `resource` | "I want to create something" |
| `incus_instance` | "An Incus container" |
| `"master"` | "This one is called master" (internal name) |
| `name = "k3s-master"` | "Its name is k3s-master" |
| `image = "ubuntu-noble"` | "It runs Ubuntu 24.04" |

**Resource types in our project:**

| Resource | What it creates |
|----------|----------------|
| `incus_instance` | An Incus container |
| `null_resource` | Runs a command (no actual resource) |
| `local_file` | Creates a file on disk |

---

## File Type 4: `outputs.tf` — "What to show after"

```hcl
output "master_ip" {
  value = incus_instance.master.ipv4_address
}
```

**What each part does:**

| Part | Meaning |
|------|---------|
| `output` | "Show this after building" |
| `"master_ip"` | "The output is called master_ip" |
| `value = incus_instance.master.ipv4_address` | "The value is the master's IP" |

**How to reference a resource attribute:**
```
<resource_type>.<resource_name>.<attribute>
```

**Example:**
```
incus_instance.master.ipv4_address
|               |      |
|               |      └── attribute (IP address)
|               └── resource name (master)
└── resource type (incus_instance)
```

---

## File Type 5: `terraform.tfvars` — "Override defaults"

```hcl
prefix = "petstore"
pc1_master_ip = "10.195.94.99"
```

**What it does:** Overrides values from `variables.tf` without editing the file.

**When to use it:** When you want different settings for different environments (dev, staging, prod).

**Example:**
```
terraform.tfvars         ← Used for development
terraform.prod.tfvars    ← Used for production
```

**Run with specific vars file:**
```bash
tofu apply -var-file="terraform.prod.tfvars"
```

---

# PART 5: THE INCUS PROVIDER

## What is a Provider?

A provider is a **plugin** that tells OpenTofu how to talk to a specific service.

| Provider | What it manages |
|----------|----------------|
| `lxc/incus` | Incus containers |
| `hashicorp/aws` | Amazon Web Services |
| `hashicorp/azure` | Microsoft Azure |
| `hashicorp/google` | Google Cloud |
| `hashicorp/kubernetes` | Kubernetes clusters |

## The Incus Provider

**Source:** `lxc/incus`

**Config:**
```hcl
provider "incus" {
  generate_client_certificates = true
}
```

**What it does:**
- Talks to Incus API on your PC
- Creates, reads, updates, and deletes containers
- Manages networking, storage, and images

**Resource types it supports:**

| Resource | What it creates |
|----------|----------------|
| `incus_instance` | A container or VM |
| `incus_network` | A network bridge |
| `incus_storage_pool` | A storage pool |
| `incus_profile` | A container profile |
| `incus_image` | Import an image |

---

# PART 6: THE HCL LANGUAGE

## What is HCL?

HCL stands for **HashiCorp Configuration Language**. It is a special language made for configuration files.

## Basic Syntax

```hcl
# This is a comment

resource "incus_instance" "master" {
  name = "k3s-master"

  config = {
    "limits.cpu" = 4
  }
}
```

**Rules:**
- `#` starts a comment (ignored by OpenTofu)
- `=` means "equals" (not `==`)
- `{` and `}` group things together
- Strings use `"` quotes
- Numbers do not need quotes
- Indentation does not matter (but use 2 spaces for readability)

## String Interpolation

You can put variables inside strings:

```hcl
name = "${var.prefix}-master"
```

**What happens:**
1. `var.prefix` = `"k3s"`
2. `${var.prefix}` = `"k3s"`
3. Result: `"k3s-master"`

**The `${}` syntax** means "replace this with its value."

## Heredoc (Multi-line strings)

```hcl
content = <<-EOT
  Line 1
  Line 2
  Line 3
EOT
```

**What it does:** Creates a multi-line string.

**The `<<-EOT` syntax:**
- `<<` means "start a heredoc"
- `-` means "strip leading whitespace"
- `EOT` is the delimiter (any word works)

**When to use it:** When you have long text that spans multiple lines (like cloud-init configs).

---

# PART 7: THE COMMANDS IN DETAIL

## `tofu init`

**Full output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding lxc/incus versions matching "~> 1.1.0"...
- Installing lxc/incus v1.1.0...
- Checking whether provider lxc/incus v1.1.0 is compatible with config...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure.

All of the necessary Terraform providers are configured correctly.
```

**What happens:**
1. OpenTofu reads `providers.tf`
2. Finds it needs `lxc/incus` version `~> 1.1.0`
3. Downloads from the Terraform Registry
4. Saves in `.terraform/` folder
5. Creates `.terraform.lock.hcl` (lock file)

**The `.terraform/` folder:**
```
.terraform/
├── providers/
│   └── registry.terraform.io/
│       └── lxc/
│           └── incus/
│               └── 1.1.0/
│                   └── terraform-provider-incus_v1.1.0
└── ...
```

**The `.terraform.lock.hcl` file:**
```
provider "registry.terraform.io/lxc/incus" {
  version     = "1.1.0"
  hashes = [
    "h1:...",
    "zh:...",
  ]
}
```

**Why a lock file?** So you always get the same version. If someone else runs `tofu init`, they get the exact same provider version.

---

## `tofu plan`

**Full output:**
```
incus_instance.master: Refreshing state... [id=k3s-master]

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # incus_instance.master will be created
  + resource "incus_instance" "master" {
      + id     = (known after apply)
      + name   = "k3s-master"
      + image  = "ubuntu-noble"
      + config = {
          + "limits.cpu"           = "4"
          + "limits.memory"        = "4GB"
          + "security.nesting"     = "true"
          + "security.privileged"  = "true"
          + "boot.autostart"       = "true"
        }
      + device {
          + name = "eth0"
          + type = "nic"
          + properties = {
              + "ipv4.address" = "10.195.94.80"
              + "nictype"     = "bridged"
              + "parent"      = "incusbr0"
            }
        }
    }

  # incus_instance.worker1 will be created
  + resource "incus_instance" "worker1" {
      + id     = (known after apply)
      + name   = "k3s-worker-1"
      + image  = "ubuntu-noble"
      + config = {
          + "limits.cpu"           = "3"
          + "limits.memory"        = "4GB"
          + "security.nesting"     = "true"
          + "security.privileged"  = "true"
          + "boot.autostart"       = "true"
        }
      + device {
          + name = "eth0"
          + type = "nic"
          + properties = {
              + "ipv4.address" = "10.195.94.81"
              + "nictype"     = "bridged"
              + "parent"      = "incusbr0"
            }
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

**Symbols:**

| Symbol | Meaning |
|--------|---------|
| `+` | Will be created |
| `-` | Will be destroyed |
| `~` | Will be changed in-place |
| `#-` | Will be destroyed and recreated |

**The important line:** `Plan: 2 to add, 0 to change, 0 to destroy.`

---

## `tofu apply`

**Full output:**
```
incus_instance.master: Creating...
incus_instance.master: Creation complete after 45s [id=k3s-master]
incus_instance.worker1: Creating...
incus_instance.worker1: Creation complete after 38s [id=k3s-worker-1]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

master_name = "k3s-master"
master_ip = "10.195.94.80"
worker1_name = "k3s-worker-1"
worker1_ip = "10.195.94.81"

cluster_nodes = {
  "master"  = "10.195.94.80"
  "worker1" = "10.195.94.81"
}
```

**What happens:**
1. OpenTofu shows the plan
2. Asks "Do you want to perform these actions?"
3. You type `yes`
4. OpenTofu calls Incus API
5. Incus creates the containers
6. OpenTofu prints the outputs

---

## `tofu destroy`

**Full output:**
```
incus_instance.worker1: Refreshing state... [id=k3s-worker-1]
incus_instance.master: Refreshing state... [id=k3s-master]

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # incus_instance.master will be destroyed
  - resource "incus_instance" "master" {
      - id     = "k3s-master" -> null
      - name   = "k3s-master" -> null
      ...
    }

  # incus_instance.worker1 will be destroyed
  - resource "incus_instance" "worker1" {
      - id     = "k3s-worker-1" -> null
      - name   = "k3s-worker-1" -> null
      ...
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?

  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. For example, Terraform is not able to recover remote
  services such as managed relational database services or monitoring
  platform services.

  Enter a value: yes

incus_instance.worker1: Destroying... [id=k3s-worker-1]
incus_instance.worker1: Destruction complete after 12s
incus_instance.master: Destroying... [id=k3s-master]
incus_instance.master: Destruction complete after 15s

Destroy complete! Resources: 2 destroyed.
```

---

# PART 8: WORKFLOW

## The Standard Workflow

```
1. Edit files (main.tf, variables.tf, etc.)
   ↓
2. tofu init (if you added new providers)
   ↓
3. tofu plan (check what will happen)
   ↓
4. tofu apply (make it happen)
   ↓
5. Verify (check that things work)
```

## For Our Project

```
Step 1: cd ansible-opentofu/terraform/pc1
Step 2: tofu init
Step 3: tofu plan
Step 4: tofu apply -auto-approve
Step 5: incus list
```

---

# PART 9: COMMON TASKS

## Task 1: Change an IP Address

**Before:**
```hcl
# In variables.tf
variable "pc1_master_ip" {
  default = "10.195.94.80"
}
```

**Change to:**
```hcl
variable "pc1_master_ip" {
  default = "10.195.94.99"
}
```

**Then:**
```bash
tofu plan    # Shows what will change
tofu apply   # Applies the change
```

---

## Task 2: Add More RAM

**Before:**
```hcl
variable "pc1_master_memory" {
  default = "4GB"
}
```

**Change to:**
```hcl
variable "pc1_master_memory" {
  default = "8GB"
}
```

**Then:**
```bash
tofu plan
tofu apply
```

---

## Task 3: Delete Everything and Start Over

```bash
tofu destroy -auto-approve
rm -rf .terraform/
tofu init
tofu apply -auto-approve
```

---

## Task 4: Add a New Container

**Add to `pc1/main.tf`:**
```hcl
resource "incus_instance" "worker2" {
  name  = "${var.prefix}-worker-2"
  image = var.image

  config = {
    "limits.cpu"           = var.pc2_worker_cpu
    "limits.memory"        = var.pc2_worker_memory
    "security.nesting"     = "true"
    "security.privileged"  = "true"
    "boot.autostart"       = "true"
    "linux.kernel_modules" = "ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc2_worker2_ip
    }
  }
}
```

**Add to `pc1/outputs.tf`:**
```hcl
output "worker2_name" {
  value = incus_instance.worker2.name
}

output "worker2_ip" {
  value = incus_instance.worker2.ipv4_address
}
```

**Then:**
```bash
tofu plan    # Shows 1 new resource to add
tofu apply   # Creates the new container
```

---

# PART 10: TROUBLESHOOTING

## Problem 1: `tofu init` fails

**Error:** `Error: Failed to install provider`

**Cause:** No internet connection or wrong version.

**Fix:** Check internet, check version number in `providers.tf`.

---

## Problem 2: `tofu plan` shows unexpected changes

**Error:** Shows `- destroy` and `+ create` for the same resource

**Cause:** You changed something that forces replacement (like the image).

**Fix:** This is normal. Some changes require destroying and recreating.

---

## Problem 3: `tofu apply` fails

**Error:** `Error: Failed to create instance`

**Cause:** Incus is not running, or the image is not downloaded.

**Fix:**
```bash
# Check if Incus is running
sudo systemctl status incus

# Check if image exists
incus image list

# Download image if missing
incus image copy images:ubuntu/24.04/amd64 local: --alias ubuntu-noble
```

---

## Problem 4: Container starts but K3s fails

**Error:** K3s logs show "Permission denied" or "Module not found"

**Cause:** Missing cloud-init services or kernel modules.

**Fix:** Check that `cloud-init.user-data` is in the config and `linux.kernel_modules` is set.

---

## Problem 5: `tofu destroy` fails

**Error:** `Error: Failed to destroy instance`

**Cause:** Container is still running or has dependent resources.

**Fix:**
```bash
# Stop the container manually
incus stop k3s-master

# Then destroy
tofu destroy -auto-approve
```

---

# PART 11: BEST PRACTICES

## 1. Always run `tofu plan` before `tofu apply`

Never skip the plan. It shows you what will happen.

## 2. Use variables for everything

Do not hardcode values in `main.tf`. Use variables so you can change them easily.

## 3. Keep files organized

```
terraform/
├── providers.tf        ← Provider config
├── variables.tf        ← All variables
├── pc1/
│   ├── main.tf         ← PC1 resources
│   └── outputs.tf      ← PC1 outputs
└── pc2/
    ├── main.tf         ← PC2 resources
    └── outputs.tf      ← PC2 outputs
```

## 4. Use `terraform.tfvars` for sensitive data

Do not put passwords or API keys in `variables.tf`. Use `terraform.tfvars` and add it to `.gitignore`.

## 5. Lock your provider versions

Use `~>` (pessimistic constraint) to allow patch updates but not major changes:
```hcl
version = "~> 1.1.0"  # Allows 1.1.x but not 1.2.0
```

## 6. Destroy before you create

If you want to start over, always `tofu destroy` first, then `tofu apply`.

---

# PART 12: QUICK REFERENCE

## Commands

| Command | What it does |
|---------|-------------|
| `tofu init` | Download providers |
| `tofu plan` | Preview changes |
| `tofu apply` | Create resources |
| `tofu destroy` | Delete resources |
| `tofu output` | Show outputs |
| `tofu fmt` | Format files |
| `tofu validate` | Check syntax |

## Flags

| Flag | What it does |
|------|-------------|
| `-auto-approve` | Skip confirmation |
| `-var="key=value"` | Set a variable |
| `-var-file="file.tfvars"` | Use a vars file |
| `-target=resource` | Only affect specific resource |
| `-refresh=false` | Skip state refresh |

## Resource Attributes

| Attribute | What it is |
|-----------|-----------|
| `id` | Unique identifier |
| `name` | Resource name |
| `ipv4_address` | IP address |
| `status` | Running/stopped |

---

# PART 13: OUR PROJECT REFERENCE

## Files in Our Project

```
ansible-opentofu/terraform/
├── providers.tf          ← Incus provider (lxc/incus ~> 1.1.0)
├── variables.tf          ← 17 variables (prefix, IPs, CPU, RAM, etc.)
├── pc1/
│   ├── main.tf           ← Creates k3s-master + k3s-worker-1
│   └── outputs.tf        ← Shows master/worker names and IPs
└── pc2/
    ├── main.tf           ← Creates k3s-worker-2
    └── outputs.tf        ← Shows worker-2 name and IP
```

## Variables Reference

| Variable | Default | Used In |
|----------|---------|---------|
| `prefix` | `k3s` | pc1/main.tf, pc2/main.tf |
| `image` | `ubuntu-noble` | pc1/main.tf, pc2/main.tf |
| `k3s_version` | `v1.36.4+k3s1` | Ansible (Phase 6) |
| `pc1_master_ip` | `10.195.94.80` | pc1/main.tf |
| `pc1_worker1_ip` | `10.195.94.81` | pc1/main.tf |
| `pc1_master_cpu` | `4` | pc1/main.tf |
| `pc1_master_memory` | `4GB` | pc1/main.tf |
| `pc1_worker_cpu` | `3` | pc1/main.tf |
| `pc1_worker_memory` | `4GB` | pc1/main.tf |
| `pc2_worker2_ip` | `10.195.94.82` | pc2/main.tf |
| `pc2_worker_cpu` | `2` | pc2/main.tf |
| `pc2_worker_memory` | `4GB` | pc2/main.tf |
| `gateway` | `10.195.94.1` | Ansible |
| `dns` | `1.1.1.1` | Ansible |
| `metallb_pool` | `10.195.94.100-150` | Ansible |
| `domain` | `devops-devsecops.kdns.fr` | Ansible |
| `letsencrypt_email` | `rafaabou@proton.me` | Ansible |

## Containers Created

| Container | PC | IP | CPU | RAM |
|-----------|----|----|-----|-----|
| `k3s-master` | PC1 | 10.195.94.80 | 4 | 4GB |
| `k3s-worker-1` | PC1 | 10.195.94.81 | 3 | 4GB |
| `k3s-worker-2` | PC2 | 10.195.94.82 | 2 | 4GB |

## Commands for Our Project

```bash
# PC1
cd ansible-opentofu/terraform/pc1
tofu init
tofu plan
tofu apply -auto-approve

# PC2
cd ansible-opentofu/terraform/pc2
tofu init
tofu plan
tofu apply -auto-approve

# Verify
incus list
incus exec k3s-master -- hostname
incus exec k3s-worker-1 -- hostname
incus exec k3s-worker-2 -- hostname
```

---

*Guide created for the Contoso Pet Store K3s Cluster Project*
*Last Updated: 2026-09-07*
