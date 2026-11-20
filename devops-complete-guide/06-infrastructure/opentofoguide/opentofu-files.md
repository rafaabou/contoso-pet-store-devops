# OpenTofu File Types

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
