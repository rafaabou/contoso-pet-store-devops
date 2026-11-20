# OpenTofu Setup Guide — From Zero to K3s Ready
# With All Errors and Troubleshooting

## Prerequisites
- Incus installed on both PCs
- Tailscale VPN working between PCs
- SSH working between PCs
- Ubuntu noble image pulled on both PCs

---

## Phase 1: Install OpenTofu on PC1

### Step 1.1: Add HashiCorp GPG Key
```bash
sudo apt update
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

### Step 1.2: Add HashiCorp Repository
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
```

### Step 1.3: Install OpenTofu
```bash
sudo apt install tofu -y
```

### Step 1.4: Verify
```bash
tofu version
```

**Expected output:**
```
OpenTofu v1.8.x
on linux_amd64
```

---

## Phase 2: OpenTofu Init on PC1

### Step 2.1: Navigate to OpenTofu Directory
```bash
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc1
```

### Step 2.2: Initialize
```bash
tofu init
```

---

### ERROR 1: Provider Not Found

**Error message:**
```
Warning: Automatically-inferred provider dependency

  on main.tf line 8:
   8: resource "incus_instance" "master" {

Due to the prefix of the resource type name OpenTofu guessed that you intended
to associate incus_instance.master with a provider whose local name is "incus",
but that name is not declared in this module's required_providers block.

Error: Failed to query available provider packages

Could not retrieve the list of available versions for provider hashicorp/incus:
provider registry registry.opentofu.org does not have a provider named
registry.opentofu.org/hashicorp/incus
```

**Cause:** `providers.tf` was in the parent `opentofu/` directory, but `tofu init` was run from `opentofu/pc1/`. OpenTofu only reads `.tf` files in the current directory — it does NOT look up to parent directories.

**Fix:**
```bash
# Copy providers.tf and variables.tf into each subdirectory
cp ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/providers.tf ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc1/
cp ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/variables.tf ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc1/

# Then retry
tofu init
```

**Expected output:**
```
Initializing provider plugins...
- Finding lxc/incus versions matching "~> 1.1.0"...
- Installing lxc/incus v1.1.1...

OpenTofu has been successfully initialized!
```

**Prevention:** Always ensure `providers.tf` and `variables.tf` are in the same directory as `main.tf` where you run `tofu init`.

---

## Phase 3: OpenTofu Apply on PC1

### Step 3.1: Preview Changes
```bash
tofu plan
```

### Step 3.2: Apply
```bash
tofu apply -auto-approve
```

---

### ERROR 2: Image Not Found

**Error message:**
```
Error: Failed to retrieve image info for instance "k3s-master"

  with incus_instance.master,
  on main.tf line 8, in resource "incus_instance" "master":

Image "ubuntu-noble" not found
```

**Cause:** The Ubuntu image was pulled from the images remote but no alias was created. OpenTofu needs an alias to reference the image.

**Check available images:**
```bash
incus image list
```

**Output shows images without aliases:**
```
┌───────┬──────────────┬────────┬─────────────────────────────────────┐
│ ALIAS │ FINGERPRINT  │ PUBLIC │             DESCRIPTION             │
├───────┼──────────────┼────────┼─────────────────────────────────────┤
│       │ 26cc9d99144f │ no     │ Ubuntu noble amd64 (20260803_07:42) │
│       │ e9c4d39709b9 │ no     │ Ubuntu noble amd64 (20260903_07:42) │
└───────┴──────────────┴────────┴─────────────────────────────────────┘
```

**Fix:**
```bash
# Create alias for the latest image
incus image alias create ubuntu-noble e9c4d39709b9

# Verify
incus image list
```

**Now shows alias:**
```
┌─────────────┬──────────────┬────────┬─────────────────────────────────────┐
│    ALIAS    │ FINGERPRINT  │ PUBLIC │             DESCRIPTION             │
├─────────────┼──────────────┼────────┼─────────────────────────────────────┤
│ ubuntu-noble│ e9c4d39709b9 │ no     │ Ubuntu noble amd64 (20260903_07:42) │
└─────────────┴──────────────┴────────┴─────────────────────────────────────┘
```

**Retry apply:**
```bash
tofu apply -auto-approve
```

**Expected output:**
```
incus_instance.master: Creating...
incus_instance.worker1: Creating...
incus_instance.worker1: Creation complete after 3s [name=k3s-worker-1]
incus_instance.master: Creation complete after 3s [name=k3s-master]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

master_ip = "10.195.94.80"
master_name = "k3s-master"
worker1_ip = "10.195.94.81"
worker1_name = "k3s-worker-1"
```

**Prevention:** Always create image aliases after pulling images: `incus image alias create <alias> <fingerprint>`

---

## Phase 4: Verify PC1 Containers

### Step 4.1: List Containers
```bash
incus list
```

**Expected output:**
```
┌────────────────┬─────────┬──────────────────────┬───────────┬─────────────┐
│      NAME      │  STATE  │         IPV4         │   TYPE    │ SNAPSHOTS   │
├────────────────┼─────────┼──────────────────────┼───────────┼─────────────┤
│ k3s-master     │ RUNNING │ 10.195.94.80 (eth0)  │ CONTAINER │ 0           │
│ k3s-monitoring │ RUNNING │ 10.195.94.210 (eth0) │ CONTAINER │ 0           │
│ k3s-vault      │ RUNNING │ 10.195.94.200 (eth0) │ CONTAINER │ 0           │
│ k3s-worker-1   │ RUNNING │ 10.195.94.81 (eth0)  │ CONTAINER │ 0           │
└────────────────┴─────────┴──────────────────────┴───────────┴─────────────┘
```

### Step 4.2: Verify Hostnames
```bash
incus exec k3s-master -- hostname
incus exec k3s-worker-1 -- hostname
incus exec k3s-vault -- hostname
incus exec k3s-monitoring -- hostname
```

**Expected output:**
```
k3s-master
k3s-worker-1
k3s-vault
k3s-monitoring
```

---

## Phase 5: Sync Files to PC2

### Step 5.1: Sync Entire Repo
```bash
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

---

### ERROR 3: SCP Path Not Found

**Error message:**
```
scp: realpath Videos/Store-App_Soruce_Code-GitHub/: No such file
scp: upload "Videos/Store-App_Soruce_Code-GitHub/": path canonicalization failed
scp: failed to upload directory /home/antix/Videos/Store-App_Soruce_Code-GitHub to ~/Videos/Store-App_Soruce_Code-GitHub/
```

**Cause:** The destination directory does not exist on PC2.

**Fix:**
```bash
# Create directory first
ssh antix@100.110.171.119 "mkdir -p ~/Videos/Store-App_Soruce_Code-GitHub"

# Then sync
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

---

### ERROR 4: SCP Permission Denied (Wrong Username)

**Error message:**
```
ssh@100.110.171.119's password:
Permission denied, please try again.
ssh@100.110.171.119's password:
Permission denied, please try again.
ssh@100.110.171.119: Permission denied (publickey,password).
scp: Connection closed
```

**Cause:** Wrong username. The username on PC2 is `antix`, not `ssh`.

**Fix:**
```bash
# Use correct username
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

**Prevention:** Always use `antix@` for both PCs.

---

### ERROR 5: SCP Stat Local Failed

**Error message:**
```
scp: stat local "/home/antix/Videos/Store-App_Soruce_Code-GitHub/": No such file or directory
```

**Cause:** The command was run from PC2 (`home`), not PC1 (`antix`). The path exists on PC1, not PC2.

**Fix:**
```bash
# Make sure you are on PC1 (antix)
hostname
# Should show: antix

# Then run rsync from PC1
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

**Prevention:** Always run rsync from the source machine (PC1), not the destination.

---

## Phase 6: OpenTofu on PC2

### Step 6.1: SSH to PC2
```bash
ssh antix@100.110.171.119
```

### Step 6.2: Navigate to OpenTofu Directory
```bash
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc2
```

### Step 6.3: Create Image Alias on PC2
```bash
# Check available images
incus image list

# Create alias (use the fingerprint from the list)
incus image alias create ubuntu-noble <fingerprint>
```

### Step 6.4: Initialize
```bash
tofu init
```

### Step 6.5: Preview
```bash
tofu plan
```

### Step 6.6: Apply
```bash
tofu apply -auto-approve
```

**Expected output:**
```
incus_instance.worker2: Creating...
incus_instance.worker2: Creation complete after 3s [name=k3s-worker-2]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

worker2_ip = "100.100.13.113"  # Tailscale IP — use this in Ansible inventory
worker2_name = "k3s-worker-2"
```

### Step 6.7: Verify
```bash
incus list
incus exec k3s-worker-2 -- hostname
```

**Expected output:**
```
┌──────────────┬─────────┬─────────────────────┬───────────┬─────────────┐
│     NAME     │  STATE  │        IPV4         │   TYPE    │ SNAPSHOTS   │
├──────────────┼─────────┼─────────────────────┼───────────┼─────────────┤
│ k3s-worker-2 │ RUNNING │ 10.195.95.82 (eth0) │ CONTAINER │ 0           │
└──────────────┴─────────┴─────────────────────┴───────────┴─────────────┘

k3s-worker-2
```

---

## Phase 7: Import Existing Containers into OpenTofu State

If containers already exist (created manually or from a previous run), OpenTofu doesn't know about them. You must import them before running `tofu plan`.

### Step 7.1: Check Current State
```bash
tofu state list
```

**If empty:** No resources are managed. You need to import.

### Step 7.2: Import Containers
```bash
# On PC1
tofu import incus_instance.master k3s-master
tofu import incus_instance.worker1 k3s-worker-1
tofu import incus_instance.vault k3s-vault
tofu import incus_instance.monitoring k3s-monitoring

# On PC2
tofu import incus_instance.worker2 k3s-worker-2
```

### Step 7.3: Verify Import
```bash
tofu state list
```

**Expected output:**
```
incus_instance.master
incus_instance.monitoring
incus_instance.sonarqube
incus_instance.vault
incus_instance.worker1
```

---

### ERROR 6: Device IP address not within network subnet

**Error message:**
```
Error: local: The following instances failed to update state:
 - Instance: k3s-worker-2: Failed start validation for device "eth0": Device IP address "10.195.94.82" not within network "incusbr0" subnet
```

**Cause:** The Incus bridge was changed to a new subnet (10.195.95.0/24) but the container still has an IP on the old subnet (10.195.94.82).

**Fix:**
```bash
# Update container IP before starting
incus config device set k3s-worker-2 eth0 ipv4.address=10.195.95.82
incus start k3s-worker-2
```

**Prevention:** Always update container IPs before changing the bridge subnet.

---

### ERROR 7: Instance already exists

**Error message:**
```
Error: Failed to create instance "k3s-worker-2"

  with incus_instance.worker2,
  on main.tf line 8, in resource "incus_instance" "worker2":
   8: resource "incus_instance" "worker2" {

Instance "k3s-worker-2" already exists
```

**Cause:** The container was created in a previous run, but OpenTofu's state file is empty — it doesn't know about the existing container.

**Fix:**
```bash
# Import the existing container into OpenTofu state
tofu import incus_instance.worker2 k3s-worker-2

# Then verify
tofu plan
```

**Prevention:** Always check `tofu state list` before running `tofu apply`. If containers exist but aren't in state, import them first.

---

### ERROR 8: IP mismatch — config vs reality

**Error message (in `tofu plan` output):**
```
  # incus_instance.worker2 must be replaced
-/+ resource "incus_instance" "worker2" {
      ~ ipv4_address = "10.195.95.82" -> (known after apply)
      + device {
          + properties = {
              + "ipv4.address" = "10.195.94.82"  # config says this
            }
        }
    }
```

**Cause:** Config says worker-2 should be `10.195.94.82`, but the actual container has `10.195.95.82`. OpenTofu sees the difference and wants to destroy/recreate.

**Fix:** Update the config to match reality (safer than changing the running container):
```bash
# Edit variables to match actual IP
# In opentofu/variables.tf and opentofu/pc2/variables.tf:
# Change:  default = "10.195.94.82"
# To:      default = "10.195.95.82"
```

**Important:** Always use the Tailscale IP (`100.100.13.113`) in the Ansible inventory for cross-PC communication — the local bridge IP (`10.195.95.82`) only works within PC2.

**Why update config, not container:** Changing a running container's IP breaks K3s agent connections. Updating a config file is zero-risk.

**Prevention:** After importing, check `tofu state list` and `tofu show` to see actual IPs before writing config.

---

### ERROR 9: Image forces replacement on import

**Error message (in `tofu plan` output):**
```
  # incus_instance.worker2 must be replaced
-/+ resource "incus_instance" "worker2" {
      + image = "ubuntu-noble" # forces replacement
    }
```

**Cause:** The imported container's image name doesn't match the config. OpenTofu sees a difference in the `image` attribute, and since `image` forces replacement, it wants to destroy/recreate.

**Fix:** Add a `lifecycle` block to ignore the image difference:
```hcl
resource "incus_instance" "worker2" {
  name  = "${var.prefix}-worker-2"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  # ... rest of config
}
```

**Why ignore, not fix:** The container is already running with a working image. Changing it would destroy the container and all its data.

**Prevention:** After importing, run `tofu plan` and check for "forces replacement" warnings. Add `lifecycle { ignore_changes = [...] }` for attributes that shouldn't change.

---

### ERROR 10: Inconsistent dependency lock file

**Error message:**
```
Error: Inconsistent dependency lock file

The following dependency selections recorded in the lock file are
inconsistent with the current configuration:
  - provider registry.opentofu.org/lxc/incus: required by this configuration but no version is selected

To make the initial dependency selections that will initialize the
dependency lock file, run:
  tofu init
```

**Cause:** The `.terraform.lock.hcl` file was deleted or corrupted, or `tofu init` was run with a different provider version requirement.

**Fix:**
```bash
tofu init
```

This regenerates the lock file with the correct provider version.

---

### ERROR 11: Resource already managed by OpenTofu

**Error message:**
```
Error: Resource already managed by OpenTofu

OpenTofu is already managing a remote object for incus_instance.worker2. To
import to this address you must first remove the existing object from the
state.
```

**Cause:** The resource was already imported in a previous attempt. It's already in the state.

**Fix:** Just run `tofu plan` — the resource is already imported and managed.

```bash
tofu plan
```

---

## Summary: All Errors Encountered

| # | Error | Cause | Fix |
|---|-------|-------|-----|
| 1 | `provider hashicorp/incus does not exist` | providers.tf in parent dir | Copy providers.tf + variables.tf into pc1/ and pc2/ |
| 2 | `Image "ubuntu-noble" not found` | No alias on image | `incus image alias create ubuntu-noble <fingerprint>` |
| 3 | `scp: realpath: No such file` | Dest dir doesn't exist on PC2 | `mkdir -p` before rsync |
| 4 | `Permission denied (publickey,password)` | Wrong username (ssh@ vs antix@) | Use `antix@100.110.171.119` |
| 5 | `scp: stat local: No such file` | rsync run from wrong machine | Run rsync from PC1, not PC2 |
| 6 | `Device IP not within subnet` | IP on wrong subnet | Update container IP to match new subnet |
| 7 | `Instance already exists` | Container exists but state is empty | `tofu import incus_instance.worker2 k3s-worker-2` |
| 8 | IP mismatch in plan | Config IP != actual IP | Update config to match reality |
| 9 | Image forces replacement | Imported image name differs | Add `lifecycle { ignore_changes = [image] }` |
| 10 | Inconsistent dependency lock | Lock file corrupted/missing | `tofu init` to regenerate |
| 11 | Resource already managed | Already imported | Just run `tofu plan` |

---

## Quick Reference: All Commands

### PC1 (antix)
```bash
# Install OpenTofu
sudo apt update && sudo apt install tofu -y

# Create image alias
incus image alias create ubuntu-noble <fingerprint>

# Run OpenTofu
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc1
tofu init
tofu plan
tofu apply -auto-approve

# Import existing containers
tofu import incus_instance.master k3s-master
tofu import incus_instance.worker1 k3s-worker-1
tofu import incus_instance.vault k3s-vault
tofu import incus_instance.monitoring k3s-monitoring

# Verify
incus list
tofu state list
```

### PC2 (antix)
```bash
# Install OpenTofu
sudo apt update && sudo apt install tofu -y

# Create image alias
incus image alias create ubuntu-noble <fingerprint>

# Run OpenTofu
cd ~/Videos/Store-App_Soruce_Code-GitHub/ansible-opentofu/opentofu/pc2
tofu init
tofu plan
tofu apply -auto-approve

# Import existing container
tofu import incus_instance.worker2 k3s-worker-2

# Verify
incus list
tofu state list
```

### Sync Files to PC2 (from PC1)
```bash
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

---

## Container Final State

| Container | PC | IP | CPU | RAM | Status |
|-----------|----|----|-----|-----|--------|
| k3s-master | PC1 | 10.195.94.80 | 4 | 4GB | RUNNING |
| k3s-worker-1 | PC1 | 10.195.94.81 | 3 | 4GB | RUNNING |
| vault | PC1 | 10.195.94.200 | 2 | 750MB (trimmed 2026-09-09) | RUNNING |
| monitoring | PC1 | 10.195.94.210 | 2 | 4GB | RUNNING |
| k3s-worker-2 | PC2 | 100.100.13.113 (Tailscale) | 2 | 4GB | RUNNING |
| sonarqube | PC2 | 100.73.135.124 (Tailscale, migrated PC1→PC2) | 2 | 2560MB | RUNNING |
| forgejo-ci | PC2 | 100.88.159.38 (Tailscale, TASK-262) | 2 | 4GB | RUNNING |
| runner-1 | PC2 | 100.113.54.77 (Tailscale, TASK-262) | 2 | 3GB | RUNNING |

---

## Sync Rule

After ANY update to files in `~/Videos/Store-App_Soruce_Code-GitHub/`, run:

```bash
rsync -avz --exclude='terraform.tfstate*' --progress ~/Videos/Store-App_Soruce_Code-GitHub/ antix@100.110.171.119:~/Videos/Store-App_Soruce_Code-GitHub/
```

This keeps PC1 and PC2 in sync. Always sync before running `tofu` or `ansible` on PC2.

**State ownership (hard rule):** the `--exclude='terraform.tfstate*'` is load-bearing, not cosmetic. Each PC owns its state files; syncing them clobbers the other PC's memory of its containers → phantom "N to add" plans for running instances (lived through it: full state wipe, recovered via Phase 7 imports). Symptom of clobbered state: plan shows creates for containers `incus list` proves exist → NEVER apply; re-import per Phase 7, then plan must show only intended changes.

---

*Troubleshooting guide created from actual errors encountered during setup.*
*Last Updated: 2026-09-10 — 8 containers (PC1x4 + PC2x4 incl. forgejo-ci/runner-1 TASK-262); vault 750MB; sonarqube PC2 2560MB. Run PC2 tofu ON PC2 (ERROR 85). lifecycle on all resources, root disk devices with size (limits.disk is INVALID, see ansible ERROR 43), overlay module, external HDD + NVMe disk mounts*
