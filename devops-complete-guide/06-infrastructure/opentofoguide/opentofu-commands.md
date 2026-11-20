# OpenTofu Commands in Detail

## Command Reference

| Command | What it does |
|---------|-------------|
| `tofu init` | Download providers |
| `tofu plan` | Preview changes |
| `tofu apply` | Create resources |
| `tofu destroy` | Delete resources |
| `tofu output` | Show outputs |
| `tofu fmt` | Format files |
| `tofu validate` | Check syntax |
| `tofu state list` | List resources in state |
| `tofu state show` | Show resource details |
| `tofu import` | Import existing resource |

## Flags

| Flag | What it does |
|------|-------------|
| `-auto-approve` | Skip confirmation |
| `-var="key=value"` | Set a variable |
| `-var-file="file.tfvars"` | Use a vars file |
| `-target=resource` | Only affect specific resource |
| `-refresh=false` | Skip state refresh |
| `-parallelism=N` | Limit concurrent operations |

---

## `tofu init` — "Wake up and get ready"

### Full Output

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

### What Happens

1. OpenTofu reads `providers.tf`
2. Finds it needs `lxc/incus` version `~> 1.1.0`
3. Downloads from the Terraform Registry
4. Saves in `.terraform/` folder
5. Creates `.terraform.lock.hcl` (lock file)

### The `.terraform/` Folder

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

### The `.terraform.lock.hcl` File

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

## `tofu plan` — "Show me what you will do"

### Full Output

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

Plan: 2 to add, 0 to change, 0 to destroy.
```

### Symbols

| Symbol | Meaning |
|--------|---------|
| `+` | Will be created |
| `-` | Will be destroyed |
| `~` | Will be changed in-place |
| `#-` | Will be destroyed and recreated |

### Save Plan to File

```bash
tofu plan -out=planfile
```

### Apply Saved Plan

```bash
tofu apply planfile
```

---

## `tofu apply` — "Do it now"

### Full Output

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

### What Happens

1. OpenTofu shows the plan
2. Asks "Do you want to perform these actions?"
3. You type `yes`
4. OpenTofu calls Incus API
5. Incus creates the containers
6. OpenTofu prints the outputs

---

## `tofu destroy` — "Tear it down"

### Full Output

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

## `tofu output` — "Show me what was created"

```bash
tofu output
```

**Output:**
```
master_ip = "10.195.94.80"
master_name = "k3s-master"
worker1_ip = "10.195.94.81"
worker1_name = "k3s-worker-1"
```

### Get Specific Output

```bash
tofu output master_ip
```

**Output:**
```
"10.195.94.80"
```

### JSON Output

```bash
tofu output -json
```

---

## `tofu fmt` — "Format the files"

```bash
tofu fmt
```

**What it does:** Formats all `.tf` files to standard style.

**Why use it:** Keeps code readable and consistent.

---

## `tofu validate` — "Check for errors"

```bash
tofu validate
```

**What it does:** Checks syntax without making changes.

**Good output:**
```
Success! The configuration is valid.
```

**Bad output:**
```
Error: Missing required argument

  on main.tf line 5, in resource "incus_instance" "master":
   5: resource "incus_instance" "master" {

The argument "name" is required, but no definition was found.
```

---

## `tofu state list` — "What exists?"

```bash
tofu state list
```

**Output:**
```
incus_instance.master
incus_instance.worker1
```

---

## `tofu state show` — "Show me details"

```bash
tofu state show incus_instance.master
```

**Output:**
```
Resource: incus_instance.master
  id       = k3s-master
  name     = k3s-master
  image    = ubuntu-noble
  status   = Running
```

---

## `tofu import` — "Adopt existing resource"

```bash
tofu import incus_instance.existing k3s-existing
```

**What it does:** Adds an existing container to OpenTofu management.

**When to use it:** When you created a container manually but now want OpenTofu to manage it.
