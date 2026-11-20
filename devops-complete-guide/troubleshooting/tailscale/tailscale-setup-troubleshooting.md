# Tailscale Setup Guide — From Zero to Connected PCs
# With All Errors and Troubleshooting

## Prerequisites
- Two PCs on different WiFi networks
- Ubuntu/Debian on both PCs
- Internet access on both PCs
- GitHub or Google account (for Tailscale login)

---

## Phase 1: Install Tailscale on Both PCs

### PC1 (antix):
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
Browser opens → login with GitHub/Google.

### PC2 (i3 desktop):
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
Browser opens → login with **same account**.

---

## Phase 2: Verify Connection

### On PC1:
```bash
tailscale status
```

Expected output:
```
100.x.x.1  antix      user@  linux  -
100.x.x.2  i3-desktop user@  linux  -
```

### Get your Tailscale IP:
```bash
tailscale ip -4
```

### Test ping:
```bash
ping 100.x.x.2
```

---

## Phase 3: SSH Between PCs

### Option A: SSH Key (no password needed — recommended)

On PC1:
```bash
# Generate SSH key (press Enter for all defaults)
ssh-keygen -t ed25519

# Copy key to PC2 (asks for PC2 password ONE time)
ssh-copy-id antix@100.x.x.2

# Test — no password needed
ssh antix@100.x.x.2 "hostname"
```

### Option B: Set Password on PC2 (quick fix)

On PC2 (physically):
```bash
sudo passwd antix
```

Then on PC1:
```bash
ssh antix@100.x.x.2
```
Enter the password you just set.

---

## Phase 4: Enable SSH on PC2 (if not running)

On PC2 (physically or via existing SSH):
```bash
sudo apt update && sudo apt install openssh-server -y
sudo systemctl enable --now ssh
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

### Error 3: "ssh_askpass: exec(/usr/bin/ssh-askpass): No such file or directory"
**Cause:** SSH key was never copied to PC2, and no password available
**Fix:** Set password on PC2 first, then use ssh-copy-id:
```bash
# On PC2
sudo passwd antix

# On PC1
ssh-copy-id antix@100.x.x.2
```

### Error 4: "udo: command not found"
**Cause:** Typo — `udo` instead of `sudo`
**Fix:** Type `sudo` correctly

### Error 5: "-bash: cd: tmp: No such file or directory"
**Cause:** Typo — `cd tmp` instead of `cd /tmp`
**Fix:** Use full path: `cd /tmp`

### Error 6: "-bash: cd/tmp: No such file or directory"
**Cause:** Missing space between `cd` and `/tmp`
**Fix:** Type with space: `cd /tmp`

### Error 7: "Permission denied (publickey,password)"
**Cause:** SSH key not copied and no password set
**Fix:** Two options:
```bash
# Option 1: Set password on PC2
sudo passwd antix
# Then on PC1
ssh-copy-id antix@100.x.x.2

# Option 2: Copy key manually
# On PC1
cat ~/.ssh/id_ed25519.pub
# Copy the output, then on PC2
mkdir -p ~/.ssh
echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Error 8: "The requested network bridge "incusbr0" already exists"
**Cause:** Previous partial init created the bridge (related to Incus, not Tailscale)
**Fix:** Delete it first:
```bash
sudo incus profile device remove default eth0 2>/dev/null
sudo incus network delete incusbr0
```

### Error 9: "The network is currently in use"
**Cause:** Bridge is still referenced by a profile or container
**Fix:** Remove from profile first:
```bash
sudo incus profile device remove default eth0
sudo incus network delete incusbr0
```

### Error 10: "Error: Failed to parse the preseed: yaml: construct errors: line 9: field managed not found"
**Cause:** Preseed YAML has `managed: true` field which is invalid (Incus)
**Fix:** Remove `managed: true` from the YAML

### Error 11: "Device validation failed for eth0: Cannot use nictype property in conjunction with network property"
**Cause:** Preseed has both `nictype` and `network` on same device (Incus)
**Fix:** Use only `network` property:
```yaml
eth0:
  name: eth0
  network: incusbr0
  type: nic
```

### Error 12: "Error: unknown flag: --wipe"
**Cause:** `incus admin init --wipe` doesn't exist
**Fix:** Wipe manually:
```bash
for c in $(sudo incus list -c n -f csv 2>/dev/null); do sudo incus delete "$c" --force; done
sudo incus network delete incusbr0 2>/dev/null
sudo incus storage delete devops 2>/dev/null
```

### Error 13: "Error: unknown flag: --all"
**Cause:** `incus delete --all` doesn't exist
**Fix:** Use loop:
```bash
for c in $(sudo incus list -c n -f csv 2>/dev/null); do sudo incus delete "$c" --force; done
```

### Error 14: "Error: The remote "ubuntu" doesn't exist"
**Cause:** Ubuntu remote not added to Incus
**Fix:**
```bash
incus remote add ubuntu https://cloud-images.ubuntu.com/releases --protocol simplestreams
```

### Error 15: "Failed getting image: The requested image couldn't be found"
**Cause:** Ubuntu remote URL doesn't have the image
**Fix:** Use images remote instead:
```bash
incus remote add images https://images.linuxcontainers.org --protocol simplestreams
incus image copy images:ubuntu/24.04/amd64 local: --alias ubuntu-noble
```

### Error 16: "sudo: a terminal is required to read the password"
**Cause:** SSH session can't provide sudo password
**Fix:** Set up NOPASSWD sudo:
```bash
# On PC2 (physically)
echo "antix ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/antix
```

### Error 17: "Stopping 'incus.service', but its triggering units are still active"
**Cause:** Incus socket unit still active when stopping service
**Fix:** Normal behavior, just wait or:
```bash
sudo systemctl stop incus.socket incus.service
```

---

## Quick Reference Commands

### Check Status
```bash
tailscale status          # Show all devices
tailscale ip -4           # Show your Tailscale IPv4
tailscale ip -6           # Show your Tailscale IPv6
tailscale version         # Show version
```

### Test Connectivity
```bash
tailscale ping <device>           # Ping another device
tailscale ping --verbose <device> # Verbose ping
tailscale netcheck                # Check network conditions
```

### SSH Between PCs
```bash
ssh antix@100.x.x.2              # SSH to PC2
ssh antix@100.x.x.2 "hostname"   # Run command on PC2
ssh antix@100.x.x.2 "incus list" # Check Incus on PC2
```

### Manage Tailscale
```bash
sudo tailscale up                 # Connect
sudo tailscale down               # Disconnect
sudo tailscale logout             # Logout
tailscale set --hostname=new-name # Change hostname
```

### Advertise Subnet Routes (for Incus containers)
```bash
sudo tailscale set --advertise-routes=10.195.94.0/24
```
Then approve in admin console: https://login.tailscale.com/admin/machines

### Enable SSH via Tailscale (no keys needed)
```bash
sudo tailscale up --ssh
tailscale ssh user@device
```

---

## Key Rules to Remember

1. **Same account** — both PCs must login with same GitHub/Google account
2. **Tailscale IPs are 100.x.x.x** — not your WiFi IPs
3. **SSH uses Linux username** — not Tailscale hostname (`antix`, not `antix-1`)
4. **Set password first** — if ssh-copy-id fails, set password on target PC
5. **`whoami` on target PC** — always check the actual username
6. **Advertise routes** — if you want Incus containers reachable from other PC
7. **Free tier** — up to 100 devices, 3 users (enough for homelab)
8. **P2P when possible** — Tailscale tries direct connection first, falls back to DERP relay

---

## Our 2-PC Setup Reference

```
PC1 (antix, 14Gi)                       PC2 (home, 11Gi)
Tailscale: 100.99.186.85               Tailscale: 100.110.171.119
Incus: 10.195.94.1/24                  Incus: 10.195.95.1/24
├── k3s-master (10.195.94.80)          ├── k3s-worker-2 (100.100.13.113)
├── k3s-worker-1 (10.195.94.81)        ├── sonarqube (100.73.135.124)
├── vault (10.195.94.200, 750MB)       ├── forgejo-ci (100.88.159.38, TASK-262)
└── monitoring (10.195.94.210)         └── runner-1 (100.113.54.77, TASK-262)
    └── PC1 hosts: direct bridge            └── PC2 containers: Tailscale inside each
```

### Connectivity Matrix
| From | To | Method | Command |
|------|-----|--------|---------|
| PC1 | PC2 | Tailscale SSH | `ssh antix@100.110.171.119` |
| PC2 | PC1 | Tailscale SSH | `ssh antix@100.99.186.85` |
| PC1 | k3s-master | Direct Incus bridge | `ssh root@10.195.94.80` |
| PC1 | k3s-worker-1 | Direct Incus bridge | `ssh root@10.195.94.81` |
| PC1 | vault / monitoring | Direct Incus bridge | `ssh root@10.195.94.200` / `.210` |
| PC1 | k3s-worker-2 | Tailscale in container | `ssh root@100.100.13.113` |
| PC1 | sonarqube | Tailscale in container | `ssh root@100.73.135.124` |
| PC1 | forgejo / runner-1 | Tailscale in container | `ssh root@100.88.159.38` / `ssh root@100.113.54.77` |
| Ansible → all | every container | SSH (bridge PC1, Tailscale PC2) | `ansible all -m ping` |

---

## All Errors and Fixes

### ERROR 18: No route to host when pinging container on other PC

**Error message:**
```
ping: sendmsg: No route to host
From 10.195.94.1 icmp_seq=1 Destination Host Unreachable
```

**Cause:** Both PCs use the same Incus subnet (10.195.94.0/24). When PC1 tries to reach 10.195.94.82 on PC2, it thinks the destination is local and ARPs on its own bridge — but the container is on PC2's bridge.

**Fix — Option A (different subnets):**
```bash
# On PC2
sudo incus network set incusbr0 ipv4.address=10.195.95.1/24
sudo incus restart --all
incus config device set k3s-worker-2 eth0 ipv4.address=10.195.95.82
incus start k3s-worker-2
```

**Fix — Option B (Tailscale in container — recommended):**
```bash
# On PC2
incus exec k3s-worker-2 -- bash -c "curl -fsSL https://tailscale.com/install.sh | sh && tailscale up --hostname=k3s-worker-2"
incus exec k3s-worker-2 -- tailscale ip -4
# Use the Tailscale IP in Ansible inventory
```

**Prevention:** Always use different subnets on different PCs, or install Tailscale inside containers.

---

### ERROR 19: 1 route is approved but not advertised anymore

**Error message (in Tailscale admin console):**
```
1 route is approved but not advertised anymore
```

**Cause:** PC2 was advertising the subnet route but stopped (Tailscale restart, reboot, or network change).

**Fix:**
```bash
# On PC2
sudo tailscale set --advertise-routes=10.195.95.0/24
```

Then refresh the admin console page.

---

### ERROR 20: Some peers are advertising routes but --accept-routes is false

**Error message:**
```
Some peers are advertising routes but --accept-routes is false
```

**Cause:** Tailscale in container is not configured to accept routes from other peers.

**Fix:**
```bash
incus exec k3s-worker-2 -- tailscale up --accept-routes --hostname=k3s-worker-2
```

---

### ERROR 21: tailscale: unknown subcommand: route

**Error message:**
```
tailscale: unknown subcommand: route
```

**Cause:** The `route` subcommand does not exist in newer Tailscale versions.

**Fix:** Use the admin console to check routes:
```bash
tailscale status
# Check routes at https://login.tailscale.com/admin/machines
```

---

*Last Updated: 2026-09-10 — 8 tailnet peers (hosts + 6 containers); PC2-WiFi SPOF documented (multi-peer simultaneous offline = link first, kill-switch second); subnet route 10.195.94.0/24 advertised by PC1 + approved (SonarQube→Forgejo server path); `--accept-routes` per container daemon; full flags restatement required on every `tailscale up` change.*
