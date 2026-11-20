# Incus Setup Guide — From Zero to K3s Ready
# With All Errors and Troubleshooting

## Prerequisites
- Tailscale installed on both PCs
- SSH working between PCs
- Both PCs on same Tailscale account

---

## Phase 1: Install Incus on PC2

### Step 1.1: Add Zabbly Repository
```bash
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc

echo 'Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: resolute
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/zabbly.asc' | sudo tee /etc/apt/sources.list.d/zabbly-incus-stable.sources
```

### Step 1.2: Install Incus
```bash
sudo apt update
sudo apt install incus incus-ui-canonical -y
sudo usermod -aG incus-admin $USER
newgrp incus-admin
```

### Step 1.3: Verify
```bash
incus version
```

---

## Phase 2: Initialize Incus

### Step 2.1: Interactive Init
```bash
sudo incus admin init
```

### Answers:
| Prompt | Answer |
|--------|--------|
| Clustering? | no |
| Storage pool? | yes |
| Pool name | devops |
| Backend | dir |
| Storage path | press Enter (default) |
| Create bridge? | yes |
| Bridge name | incusbr0 |
| IPv4 | 10.195.94.1/24 |
| NAT IPv4 | yes |
| IPv6 | fd42:ffc0:ad6f:6676::1/64 |
| NAT IPv6 | yes |
| Server over network | no |
| Auto-update images | yes |
| Print preseed | no |

### Step 2.2: Verify
```bash
incus network list
incus storage list
incus list
```

---

## Phase 3: Pull Ubuntu Image

### Step 3.1: Add Remotes
```bash
incus remote add images https://images.linuxcontainers.org --protocol simplestreams
```

### Step 3.2: List Available Images
```bash
incus image list images:ubuntu/24.04/
```

### Step 3.3: Copy Image
```bash
incus image copy images:ubuntu/24.04/amd64 local: --alias ubuntu-noble
```

### Step 3.4: Verify
```bash
incus image list
```

---

## All Errors and Fixes

### Error 1: "ssh: connect to host antix-1 port 22: Connection refused"
**Cause:** SSH server not installed or not running on PC2
**Fix:**
```bash
# On PC2
sudo apt update && sudo apt install openssh-server -y
sudo systemctl enable --now ssh
```

### Error 2: "Permission denied, please try again" (ssh-copy-id)
**Cause:** PC2 user has no password set
**Fix:**
```bash
# On PC2
sudo passwd antix
```

### Error 3: "udo: command not found"
**Cause:** Typo — `udo` instead of `sudo`
**Fix:** Type `sudo` correctly

### Error 4: "Error: unknown flag: --wipe"
**Cause:** `incus admin init --wipe` doesn't exist
**Fix:** Wipe manually:
```bash
sudo incus stop --all 2>/dev/null; true
for c in $(sudo incus list -c n -f csv 2>/dev/null); do sudo incus delete "$c" --force; done
sudo incus network delete incusbr0 2>/dev/null
sudo incus network delete default 2>/dev/null
sudo incus storage delete devops 2>/dev/null
sudo incus storage delete default 2>/dev/null
```

### Error 5: "Error: unknown flag: --all"
**Cause:** `incus delete --all` doesn't exist
**Fix:** Use loop:
```bash
for c in $(sudo incus list -c n -f csv 2>/dev/null); do sudo incus delete "$c" --force; done
```

### Error 6: "The requested network bridge "incusbr0" already exists"
**Cause:** Previous partial init created the bridge
**Fix:** Delete it first:
```bash
sudo incus profile device remove default eth0 2>/dev/null
sudo incus network delete incusbr0
```

### Error 7: "The network is currently in use"
**Cause:** Bridge is still referenced by a profile or container
**Fix:** Remove from profile first:
```bash
sudo incus profile device remove default eth0
sudo incus network delete incusbr0
```

### Error 8: "Error: Failed to parse the preseed: yaml: construct errors: line 9: field managed not found"
**Cause:** Preseed YAML has `managed: true` field which is invalid
**Fix:** Remove `managed: true` from the YAML

### Error 9: "Device validation failed for eth0: Cannot use nictype property in conjunction with network property"
**Cause:** Preseed has both `nictype` and `network` on same device
**Fix:** Use only `network` property:
```yaml
eth0:
  name: eth0
  network: incusbr0
  type: nic
```

### Error 10: "Where should this storage pool store its data? → yes"
**Cause:** Typed "yes" instead of pressing Enter for default path
**Fix:** Press Enter to accept default path, don't type anything

### Error 11: "The requested storage pool "default" already exists"
**Cause:** Previous init created a pool named "default"
**Fix:** Use a different name (e.g., "devops") or delete the existing one first

### Error 12: "Error: The remote "ubuntu" doesn't exist"
**Cause:** Ubuntu remote not added to Incus
**Fix:**
```bash
incus remote add ubuntu https://cloud-images.ubuntu.com/releases --protocol simplestreams
```

### Error 13: "Failed getting image: The requested image couldn't be found"
**Cause:** Ubuntu remote URL doesn't have the image
**Fix:** Use images remote instead:
```bash
incus remote add images https://images.linuxcontainers.org --protocol simplestreams
incus image copy images:ubuntu/24.04/amd64 local: --alias ubuntu-noble
```

### Error 14: "sudo: a terminal is required to read the password"
**Cause:** SSH session can't provide sudo password
**Fix:** Set up NOPASSWD sudo:
```bash
# On PC2 (physically)
echo "antix ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/antix
```

### Error 15: "Stopping 'incus.service', but its triggering units are still active"
**Cause:** Incus socket unit still active when stopping service
**Fix:** Normal behavior, just wait or:
```bash
sudo systemctl stop incus.socket incus.service
```

### Error 16: "-bash: cd: tmp: No such file or directory"
**Cause:** Typo — `cd tmp` instead of `cd /tmp`
**Fix:** Use full path: `cd /tmp`

### Error 17: "-bash: cd/tmp: No such file or directory"
**Cause:** Missing space between `cd` and `/tmp`
**Fix:** Type with space: `cd /tmp`

---

## Quick Reference

### Save Preseed to File (reusable on any PC)
```bash
cat << 'EOF' > /tmp/incus-preseed.yaml
config: {}
networks:
  - config:
      ipv4.address: 10.195.94.1/24
      ipv4.nat: "true"
      ipv6.address: fd42:ffc0:ad6f:6676::1/64
      ipv6.nat: "true"
    description: ""
    name: incusbr0
    type: bridge
storage_pools:
  - config:
      source: /var/lib/incus/storage-pools/devops
    description: ""
    name: devops
    driver: dir
profiles:
  - config: {}
    description: ""
    devices:
      eth0:
        name: eth0
        network: incusbr0
        type: nic
      root:
        path: /
        pool: devops
        type: disk
    name: default
cluster: null
EOF
```

### Apply Preseed (one command setup)
```bash
sudo incus admin init --preseed < /tmp/incus-preseed.yaml
```

### SSH from PC1 to PC2
```bash
ssh antix@100.110.171.119
```

### Run Command on PC2 from PC1
```bash
ssh antix@100.110.171.119 "command here"
```

### Check PC2 Status from PC1
```bash
ssh antix@100.110.171.119 "incus list; incus network list; incus storage list"
```

---

## Complete Wipe (Start Over)

```bash
# Stop all containers
for c in $(sudo incus list -c n -f csv 2>/dev/null); do sudo incus delete "$c" --force; done

# Delete all profiles (except default)
for p in $(sudo incus profile list -c n -f csv 2>/dev/null | grep -v default); do sudo incus profile delete "$p"; done

# Remove devices from default profile
sudo incus profile device remove default eth0 2>/dev/null
sudo incus profile device remove default root 2>/dev/null

# Delete networks
for n in $(sudo incus network list -c n -f csv 2>/dev/null | grep -v -E "^(eno|wlp|lo)"); do sudo incus network delete "$n"; done

# Delete storage
for s in $(sudo incus storage list -c n -f csv 2>/dev/null); do sudo incus storage delete "$s"; done

# Full reset (nuclear option)
sudo systemctl stop incus.socket incus.service
sudo rm -rf /var/lib/incus/*
sudo systemctl start incus

# Reinitialize
sudo incus admin init
```

---

## Key Rules to Remember

1. **Press Enter for defaults** — don't type "yes" for path prompts
2. **Delete before creating** — always clean up existing resources first
3. **Use `images:` remote** — not `ubuntu:` remote (doesn't work with Incus)
4. **Preseed YAML** — don't use `managed` or mix `nictype` with `network`
5. **SSH needs password once** — use `ssh-copy-id` to avoid it later
6. **sudo on SSH** — set NOPASSWD if you want to run remote commands

---

*Last Updated: 2026-09-10 — 8 containers verified (PC1x4 + PC2x4); wrong-PC `incus exec` = proof of location (ERROR 88); memory limits apply live (vault 750MB, sonarqube 3GB, both 0s).*
