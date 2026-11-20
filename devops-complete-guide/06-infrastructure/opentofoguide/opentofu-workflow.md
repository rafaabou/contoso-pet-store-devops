# OpenTofu Workflow & Common Tasks

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

## Common Tasks

### Task 1: Change an IP Address

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

### Task 2: Add More RAM

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

### Task 3: Delete Everything and Start Over

```bash
tofu destroy -auto-approve
rm -rf .terraform/
tofu init
tofu apply -auto-approve
```

---

### Task 4: Add a New Container

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

### Task 5: Update an Existing Container

**Change CPU from 4 to 8:**
```hcl
# In main.tf
config = {
  "limits.cpu" = 8  # Changed from 4
}
```

**Then:**
```bash
tofu plan    # Shows "~ update in-place"
tofu apply   # Updates without destroying
```

---

### Task 6: Check What Exists

```bash
# List all resources
tofu state list

# Show details of one resource
tofu state show incus_instance.master

# Show all outputs
tofu output
```

---

## Best Practices

### 1. Always run `tofu plan` before `tofu apply`

Never skip the plan. It shows you what will happen.

### 2. Use variables for everything

Do not hardcode values in `main.tf`. Use variables so you can change them easily.

### 3. Keep files organized

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

### 4. Use `terraform.tfvars` for sensitive data

Do not put passwords or API keys in `variables.tf`. Use `terraform.tfvars` and add it to `.gitignore`.

### 5. Lock your provider versions

Use `~>` (pessimistic constraint) to allow patch updates but not major changes:
```hcl
version = "~> 1.1.0"  # Allows 1.1.x but not 1.2.0
```

### 6. Destroy before you create

If you want to start over, always `tofu destroy` first, then `tofu apply`.
