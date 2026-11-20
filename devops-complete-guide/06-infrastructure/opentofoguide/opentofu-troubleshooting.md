# OpenTofu Troubleshooting

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

## Problem 6: State file is locked

**Error:** `Error: Error acquiring the state lock`

**Cause:** Another tofu process is running, or it crashed mid-run.

**Fix:**
```bash
# Check if another process is running
ps aux | grep tofu

# If no process is running, force unlock
tofu force-unlock <LOCK_ID>
```

---

## Problem 7: Provider version mismatch

**Error:** `Error: Failed to install provider` with version error

**Cause:** The version constraint in `providers.tf` does not match available versions.

**Fix:** Check available versions:
```bash
# Check what version is installed
cat .terraform.lock.hcl

# Update version constraint
# In providers.tf, change:
version = "~> 1.1.0"
# To:
version = "~> 1.2.0"
```

---

## Problem 8: Variable not defined

**Error:** `Error: Missing required argument` or `Error: Reference to undeclared variable`

**Cause:** Using a variable that is not defined in `variables.tf`.

**Fix:** Add the variable definition:
```hcl
variable "my_variable" {
  description = "What this variable does"
  type        = string
  default     = "default_value"
}
```

---

## Problem 9: Syntax error in HCL

**Error:** `Error: Configuration is invalid`

**Cause:** Wrong syntax in `.tf` files.

**Fix:** Run `tofu fmt` to auto-format, then `tofu validate` to check syntax.

---

## Problem 10: Resource already exists

**Error:** `Error: Resource already managed by Terraform`

**Cause:** You created a resource manually that OpenTofu already knows about.

**Fix:**
```bash
# Option 1: Import the existing resource
tofu import incus_instance.existing k3s-existing

# Option 2: Remove from state (dangerous)
tofu state rm incus_instance.existing
```

---

## Quick Diagnostic Commands

```bash
# Check what exists
tofu state list

# Show details of a resource
tofu state show incus_instance.master

# Check outputs
tofu output

# Validate syntax
tofu validate

# Format files
tofu fmt

# Show current state
cat terraform.tfstate | head -50
```

---

## Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| `Failed to install provider` | Cannot download provider | Check internet, version |
| `Failed to create instance` | Incus error | Check Incus status |
| `Failed to destroy instance` | Cannot delete | Stop container first |
| `State lock acquired` | Another process running | Wait or force-unlock |
| `Missing required argument` | Variable not defined | Add to variables.tf |
| `Reference to undeclared variable` | Wrong variable name | Check spelling |
| `Configuration is invalid` | Syntax error | Run tofu fmt |
| `Resource already managed` | Duplicate resource | Import or remove from state |
