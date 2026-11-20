# AppArmor Complete Guide

## Table of Contents

1. [What Is AppArmor](#1-what-is-apparmor)
2. [Why Use AppArmor](#2-why-use-apparmor)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide (Step-by-Step)](#7-usage-guide)
8. [Writing Profiles](#8-writing-profiles)
9. [Profile Modes](#9-profile-modes)
10. [Integration](#10-integration)
11. [Security](#11-security)
12. [Troubleshooting](#12-troubleshooting)
13. [Tips & Best Practices](#13-tips--best-practices)
14. [Command Reference](#14-command-reference)
15. [Configuration Reference](#15-configuration-reference)
16. [Real-World Examples](#16-real-world-examples)
17. [Further Reading](#17-further-reading)

---

## 1. What Is AppArmor

AppArmor (Application Armor) is a Linux kernel security module that restricts the capabilities of individual programs using a per-program profile. It confines programs to a limited set of resources (files, network, capabilities, mount, etc.) and is an alternative to SELinux. AppArmor is included in the Linux kernel and is the default MAC (Mandatory Access Control) system on Ubuntu, SUSE, and Debian-based distributions.

### 1.1 Purpose

AppArmor confines applications by specifying what files, network, and capabilities each program is allowed to access. If a confined program tries to access a resource not explicitly allowed, AppArmor blocks it and optionally logs the attempt.

### 1.2 History

- **1998**: Novell begins development (originally called SubDomain)
- **2006**: OpenSUSE releases as AppArmor
- **2009**: Canonical integrates AppArmor into Ubuntu
- **2010**: AppArmor merged into mainline Linux kernel
- **2020+**: Container-focused profiles, Kubernetes integration

### 1.3 Key Features

- Per-program MAC profiles (easier than SELinux's labeling)
- File access control (read, write, execute, link)
- Network access control (TCP/UDP, ports)
- Capability restrictions (CAP_NET_ADMIN, CAP_SYS_ADMIN, etc.)
- Mount/umount restrictions
- ptrace restrictions
- Signal restrictions
- Profile stacking (multiple profiles per process)
- Container-friendly (Docker, Kubernetes, LXC)

---

## 2. Why Use AppArmor

### 2.1 Defense in Depth

| Without AppArmor | With AppArmor |
|---|---|
| Root can access everything | Even root confined by profile |
| Vulnerable app = full compromise | Vulnerable app = limited damage |
| Container escape = host access | Container escape = confined |
| Zero-day exploit = full access | Zero-day exploit = limited by profile |

### 2.2 AppArmor vs SELinux

| Feature | AppArmor | SELinux |
|---|---|---|
| Configuration | Path-based (profiles) | Label-based (contexts) |
| Learning curve | Lower | Higher |
| Default on | Ubuntu, SUSE, Debian | RHEL, CentOS, Fedora |
| Granularity | Per-program | Per-process, per-object |
| Container support | Excellent | Good |
| Profile generation | `aa-genprof` | `audit2allow` |

### 2.3 Use Cases

1. **Container security** — confine Docker/containerd workloads
2. **Server hardening** — restrict nginx, apache, mysql
3. **Desktop security** — confine browser, media player
4. **Compliance** — enforce least-privilege policies
5. **Kubernetes security** — Pod Security Standards with AppArmor

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────┐
│              User Space                       │
│  ┌───────────────────────────────────────┐  │
│  │  apparmor_parser  (profile compiler)  │  │
│  └───────────────────────┬───────────────┘  │
│                          │                   │
│  ┌───────────────────────▼───────────────┐  │
│  │  /etc/apparmor.d/ (profile files)     │  │
│  └───────────────────────┬───────────────┘  │
└──────────────────────────┼──────────────────┘
                           │
┌──────────────────────────▼──────────────────┐
│              Kernel Space                    │
│  ┌───────────────────────────────────────┐  │
│  │  AppArmor LSM (Linux Security Module) │  │
│  │                                       │  │
│  │  ┌──────────┐  ┌──────────────────┐  │  │
│  │  │ File     │  │ Network          │  │  │
│  │  │ Mediator │  │ Mediator         │  │  │
│  │  └──────────┘  └──────────────────┘  │  │
│  │  ┌──────────┐  ┌──────────────────┐  │  │
│  │  │ Capability│  │ Mount/Umount     │  │  │
│  │  │ Mediator │  │ Mediator         │  │  │
│  │  └──────────┘  └──────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 3.1 Components

| Component | Role |
|---|---|
| **apparmor_parser** | Compiles profiles into kernel-readable format |
| **/etc/apparmor.d/** | Directory containing profile files |
| **AppArmor kernel module** | LSM that enforces profiles |
| **aa-enforce** | Set profile to enforce mode |
| **aa-complain** | Set profile to complain mode |
| **aa-disable** | Disable a profile |
| **aa-genprof** | Profile generator tool |
| **aa-logprof** | Profile log reader/updater |

---

## 4. Installation

### 4.1 Debian/Ubuntu

```bash
# Install AppArmor
sudo apt-get update
sudo apt-get install apparmor apparmor-utils apparmor-profiles

# Verify installation
aa-status

# Check if AppArmor is enabled
cat /sys/module/apparmor/parameters/enabled
# Should output: Y
```

### 4.2 SUSE/openSUSE

```bash
# Install AppArmor
sudo zypper install apparmor apparmor-profiles apparmor-utils

# Enable AppArmor
sudo systemctl enable --now apparmor
```

### 4.3 Kernel Module (if not built-in)

```bash
# Check if AppArmor is built into kernel
cat /sys/kernel/security/apparmor/profiles
# If output shows profiles, it's built-in

# Load module if needed
sudo modprobe apparmor

# Make persistent
echo "apparmor" | sudo tee -a /etc/modules-load.d/apparmor.conf
```

### 4.4 Docker

```bash
# Run Docker with AppArmor
docker run --security-opt apparmor=my-profile -d nginx

# Check if AppArmor is loaded in Docker
docker info | grep -i security
# Should show: Security Options: apparmor
```

### 4.5 Kubernetes

```yaml
# Pod with AppArmor annotation
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-apparmor
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-default
spec:
  containers:
  - name: nginx
    image: nginx
```

### 4.6 Verify Installation

```bash
# Check AppArmor status
sudo aa-status

# Expected output:
# apparmor module is loaded.
# 37 profiles are loaded.
# 37 profiles are in enforce mode.
# 0 profiles are in complain mode.
# 0 processes are unconfined.
```

---

## 5. Configuration

### 5.1 Main Config File

```bash
# /etc/apparmor.d/ - main profile directory
/etc/apparmor.d/
├── tunables/           # Tunables for profiles
├── abstractions/       # Shared abstraction files
├── disable/            # Disabled profiles
├── usr.sbin.nginx      # nginx profile
├── usr.sbin.mysqld     # mysql profile
└── docker-nginx        # Docker nginx profile
```

### 5.2 Profile Format

```
#include <tunables/global>

profile nginx-default flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>

  # Binary
  /usr/sbin/nginx mr,
  /usr/sbin/nginx PUx,

  # Config files
  /etc/nginx/** r,
  /etc/nginx/nginx.conf r,
  /etc/nginx/mime.types r,

  # Web content
  /var/www/** r,
  /var/www/html/** r,

  # Logs
  /var/log/nginx/** w,
  /var/log/nginx/access.log w,
  /var/log/nginx/error.log w,

  # PID file
  /run/nginx.pid rw,

  # Network
  network inet stream,
  network inet6 stream,
  network inet dgram,
  network inet6 dgram,

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # Deny
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,
}
```

### 5.3 Environment Variables

| Variable | Default | Description |
|---|---|---|
| `AA_LOG` | — | Custom log file path |
| `APPARMOR_PARSER` | — | Custom parser path |
| `AA_CONF_DIR` | `/etc/apparmor.d` | Profile directory |

---

## 6. Core Concepts

### 6.1 Profile Structure

```
profile <name> [flags=(...)] {
  #include <abstractions/base>

  # Allow rules
  /path/to/file r,       # Read
  /path/to/file w,       # Write
  /path/to/file rw,      # Read + Write
  /path/to/file px,      # Execute (clean)
  /path/to/file ix,      # Execute (inherit)
  /path/to/file ux,      # Execute (unconfined)
  /path/to/file mx,      # Execute with mprotect
  /path/to/file Px,      # Execute with profile

  # Deny rules
  deny /path/to/file r,
  deny /path/to/file w,

  # Network
  network inet stream,   # TCP IPv4
  network inet6 stream,  # TCP IPv6
  network inet dgram,    # UDP IPv4
  network inet6 dgram,   # UDP IPv6
  network raw,           # Raw sockets
  network packet,        # Packet sockets

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # Mount
  mount /dev/sda1,
  umount /mnt/data,

  # Signals
  signal (send) set=(term, kill) peer=nginx,

  # ptrace
  ptrace (read, trace) peer=nginx,
}
```

### 6.2 File Permissions

| Permission | Meaning |
|---|---|
| `r` | Read |
| `w` | Write |
| `a` | Append |
| `l` | Link |
| `k` | Lock |
| `m` | mmap as executable |

### 6.3 Execution Permissions

| Permission | Meaning |
|---|---|
| `px` | Execute with profile (clean) |
| `ix` | Execute (inherit current profile) |
| `ux` | Execute unconfined (dangerous) |
| `mx` | Execute with mprotect (mmap) |
| `Px` | Execute with named profile |
| `Cx` | Execute with child profile |
| `Ux` | Execute unconfined with profile cleanup |

### 6.4 Capabilities

| Capability | Description |
|---|---|
| `CAP_NET_BIND_SERVICE` | Bind to privileged ports |
| `CAP_NET_RAW` | Use raw sockets |
| `CAP_SYS_ADMIN` | System administration (very broad) |
| `CAP_SYS_PTRACE` | Trace processes |
| `CAP_SYS_MODULE` | Load kernel modules |
| `CAP_SETUID` | Change UID |
| `CAP_SETGID` | Change GID |
| `CAP_CHOWN` | Change file ownership |

---

## 7. Usage Guide (Step-by-Step)

### Step 1: Check AppArmor Status

```bash
sudo aa-status
```

### Step 2: List Active Profiles

```bash
# List all profiles
cat /sys/kernel/security/apparmor/profiles

# List with modes
sudo aa-status | grep -E "enforce|complain"
```

### Step 3: Create a New Profile

```bash
# Using the generator tool
sudo aa-genprof /usr/bin/myapp

# Or manually create in /etc/apparmor.d/
sudo nano /etc/apparmor.d/usr.bin.myapp
```

### Step 4: Write the Profile

```
#include <tunables/global>

profile myapp flags=(attach_disconnected) {
  #include <abstractions/base>

  # Binary
  /usr/bin/myapp mr,

  # Config
  /etc/myapp/** r,
  /etc/myapp/config.yaml r,

  # Data
  /var/lib/myapp/** rw,
  /var/log/myapp/** w,

  # Network
  network inet stream,
  network inet6 stream,

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # Deny dangerous operations
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,
}
```

### Step 5: Load the Profile

```bash
# Parse and load
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.myapp

# Or reload all profiles
sudo systemctl reload apparmor
```

### Step 6: Set Profile Mode

```bash
# Enforce mode (blocks violations)
sudo aa-enforce /etc/apparmor.d/usr.bin.myapp

# Complain mode (logs but doesn't block)
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Disable profile
sudo aa-disable /etc/apparmor.d/usr.bin.myapp
```

### Step 7: Test the Profile

```bash
# Run the application
/usr/bin/myapp

# Check for AppArmor denials
sudo dmesg | grep apparmor
sudo journalctl -k | grep apparmor
```

### Step 8: Update Profile Based on Logs

```bash
# Read logs and update profile
sudo aa-logprof

# Or manually review and update
sudo nano /etc/apparmor.d/usr.bin.myapp
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.myapp
```

### Step 9: Docker Integration

```bash
# Run container with custom profile
docker run --security-opt apparmor=my-profile -d myapp

# Run with default Docker profile
docker run --security-opt apparmor=docker-default -d nginx

# List Docker AppArmor profiles
docker info | grep -i security
```

### Step 10: Kubernetes Integration

```yaml
# Pod annotation for AppArmor
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    container.apparmor.security.beta.kubernetes.io/myapp: localhost/myapp-profile
spec:
  containers:
  - name: myapp
    image: myapp:latest
```

---

## 8. Writing Profiles

### 8.1 Profile Structure

```
#include <tunables/global>

profile myapp flags=(attach_disconnected,mediate_deleted) {
  # Abstractions (shared rules)
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Binary execution
  /usr/bin/myapp mr,

  # Configuration
  /etc/myapp/** r,
  /etc/myapp/config.yml r,

  # Data directories
  /var/lib/myapp/** rw,
  /var/log/myapp/** w,

  # Temporary files
  /tmp/myapp/** rw,
  owner /tmp/myapp/** rw,

  # Network access
  network inet stream,
  network inet6 stream,

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # File operations
  /dev/null rw,
  /dev/urandom r,
  /proc/self/status r,

  # Deny dangerous operations
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,
  deny /home/**/.*history rw,
  deny /home/**/.ssh/** rw,

  # Mount restrictions
  deny mount,
  deny umount,
  deny pivot_root,

  # ptrace restrictions
  deny ptrace,
}
```

### 8.2 Common Abstractions

```bash
# Include common abstractions
#include <abstractions/base>           # Basic file access
#include <abstractions/nameservice>    # DNS resolution
#include <abstractions/openssl>        # OpenSSL library
#include <abstractions/apache2-common> # Apache
#include <abstractions/nvidia>         # NVIDIA drivers
#include <abstractions/kerberosclient> # Kerberos
#include <abstractions/ssl_certs>      # SSL certificates
```

### 8.3 Owner vs Non-Owner Rules

```
# Owner rules (only apply when running as the file's owner)
owner /var/lib/myapp/** rw,
owner /tmp/myapp/** rw,

# Non-owner rules (apply to any user)
/var/etc/myapp/** r,
```

### 8.4 Tunables

```
# Tunables for different environments
@{PROC}=/proc
@{SYSFS}=/sys
@{SECURITYFS}=/sys/kernel/security
@{TUNABLES}=/etc/apparmor.d/tunables

# Use tunables in rules
@{PROC}/sys/kernel/hostname r,
@{SYSFS}/devices/system/cpu/ r,
```

---

## 9. Profile Modes

### 9.1 Enforce Mode

```bash
# Set to enforce (blocks violations)
sudo aa-enforce /etc/apparmor.d/usr.bin.myapp

# Verify mode
cat /sys/kernel/security/apparmor/profiles | grep myapp
# myapp (enforce)
```

### 9.2 Complain Mode

```bash
# Set to complain (logs but doesn't block)
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Verify mode
cat /sys/kernel/security/apparmor/profiles | grep myapp
# myapp (complain)
```

### 9.3 Kill Mode

```bash
# Set profile to kill (terminates on violation)
# Edit profile flags:
profile myapp flags=(attach_disconnected) {
  # ...
}
```

### 9.4 Unconfined Mode

```bash
# Remove confinement entirely
sudo aa-disable /etc/apparmor.d/usr.bin.myapp

# Verify
cat /sys/kernel/security/apparmor/profiles | grep myapp
# (not found - profile unloaded)
```

### 9.5 Mode Transitions

```
1. Profile created: complain mode (default)
2. Test and refine: aa-logprof to update profile
3. Switch to enforce: aa-enforce
4. Monitor: dmesg/journalctl for denials
5. Update if needed: aa-logprof + reload
```

---

## 10. Integration

### 10.1 Docker

```bash
# Default Docker profile
docker run --security-opt apparmor=docker-default nginx

# Custom profile
docker run --security-opt apparmor=my-profile myapp

# Check Docker AppArmor support
docker info | grep -i security
# Security Options:
#  apparmor
#  seccomp Profile: default
```

### 10.2 Kubernetes

```yaml
# Pod Security Standard with AppArmor
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: localhost/restricted-profile
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

### 10.3 Systemd

```bash
# AppArmor profile for systemd service
# /etc/systemd/system/myapp.service.d/apparmor.conf
[Service]
AppArmorProfile=myapp
```

### 10.4 Log Analysis

```bash
# Monitor AppArmor logs
sudo journalctl -k | grep apparmor

# Real-time monitoring
sudo dmesg -w | grep apparmor

# Parse logs for profile updates
sudo aa-logprof -f /var/log/syslog
```

---

## 11. Security

### 11.1 Profile Hardening

```
# Deny all dangerous capabilities
deny capability sys_admin,
deny capability sys_module,
deny capability sys_ptrace,
deny capability net_raw,

# Deny mount operations
deny mount,
deny umount,
deny pivot_root,

# Deny sensitive file access
deny /etc/shadow r,
deny /etc/sudoers rw,
deny /root/** rw,
deny /home/**/.*history rw,
deny /home/**/.ssh/** rw,

# Deny ptrace
deny ptrace,

# Deny raw network
deny network raw,
deny network packet,
```

### 11.2 Container Profiles

```bash
# Docker default profile includes:
# - Deny mount
# - Deny write to /proc, /sys
# - Deny access to sensitive files
# - Network restrictions
```

### 11.3 Profile Stacking

```
# Stack multiple profiles
profile nginx /usr/sbin/nginx flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/openssl`
  /usr/sbin/nginx mr,
  /etc/nginx/** r,
  network inet stream,
  capability net_bind_service,
}

# Child profile for helper processes
profile nginx-helper /usr/sbin/nginx-helper flags=(attach_disconnected) {
  /usr/sbin/nginx-helper mr,
  /var/lib/nginx/** rw,
}
```

---

## 12. Troubleshooting

### Issue 1: AppArmor Not Loading Profiles

**Symptoms**: `aa-status` shows 0 profiles loaded.

**Diagnosis**:
```bash
cat /sys/module/apparmor/parameters/enabled
# Should be Y

ls /sys/kernel/security/apparmor/
# Should show profiles, policy, etc.
```

**Fix**:
```bash
# Enable AppArmor in kernel
# Add to GRUB: apparmor=1 security=apparmor
sudo nano /etc/default/grub
# Update GRUB
sudo update-grub
sudo reboot
```

### Issue 2: Profile Denies Valid Access

**Symptoms**: Application fails with "Permission denied".

**Diagnosis**:
```bash
# Check AppArmor logs
sudo dmesg | grep apparmor | tail -20

# Or
sudo journalctl -k | grep apparmor
```

**Fix**:
```bash
# Temporarily switch to complain mode
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Run application to discover needed permissions
sudo aa-logprof
```

### Issue 3: Profile Not Found

**Symptoms**: Error "profile not found" when running application.

**Fix**:
```bash
# Check profile name
cat /sys/kernel/security/apparmor/profiles | grep myapp

# Reload profiles
sudo systemctl reload apparmor

# Or manually reload
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.myapp
```

### Issue 4: AppArmor Module Not Loaded

**Symptoms**: `modprobe apparmor` fails.

**Fix**:
```bash
# Check if module is built-in
grep CONFIG_SECURITY_APPARMOR /boot/config-$(uname -r)

# If module:
sudo modprobe apparmor

# If built-in but disabled:
# Add kernel parameter
GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"
```

### Issue 5: Docker Profile Conflict

**Symptoms**: Container fails to start with AppArmor error.

**Fix**:
```bash
# Check if profile exists
sudo aa-status | grep docker

# Load Docker's default profile
sudo apparmor_parser -r /etc/apparmor.d/docker-default

# Or disable AppArmor for specific container
docker run --security-opt apparmor=unconfined myapp
```

### Issue 6: High CPU from AppArmor Logging

**Symptoms**: System slow, `/var/log/syslog` filling up.

**Fix**:
```bash
# Switch verbose profiles to complain mode
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Or reduce logging
# In profile, use quieter rules:
/usr/bin/myapp mr,
# Instead of:
/usr/bin/myapp r,
```

### Issue 7: Profile Compilation Error

**Symptoms**: `apparmor_parser` fails with syntax error.

**Fix**:
```bash
# Validate profile
sudo apparmor_parser -Q /etc/apparmor.d/usr.bin.myapp

# Check for common errors
# - Missing closing brace
# - Invalid permission character
# - Unclosed quotes
```

### Issue 8: AppArmor Blocks Kernel Module Loading

**Symptoms**: Cannot load kernel modules.

**Fix**:
```bash
# Check for kernel module restriction
sudo dmesg | grep apparmor | grep module

# Add exception to profile
/usr/lib/modules/** k,
```

### Issue 9: Container Profile Not Applied

**Symptoms**: Container starts but AppArmor not enforcing.

**Fix**:
```bash
# Check container AppArmor label
docker inspect myapp | grep AppArmor

# Verify annotation in Kubernetes
kubectl get pod myapp -o yaml | grep apparmor
```

### Issue 10: Profile Causes Segfault

**Symptoms**: Application crashes with segfault under AppArmor.

**Fix**:
```bash
# Switch to complain mode
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Check if profile blocks library loading
# Add necessary library paths:
/usr/lib/** mr,
```

### Issue 11: AppArmor Not Working in Container

**Symptoms**: AppArmor profiles not enforced in containers.

**Fix**:
```bash
# Ensure AppArmor is enabled on host
cat /sys/module/apparmor/parameters/enabled

# Check container runtime supports AppArmor
docker info | grep -i apparmor

# Verify profile is loaded
sudo aa-status | grep docker
```

### Issue 12: Profile Rules Conflict

**Symptoms**: Unexpected behavior due to rule ordering.

**Fix**:
```bash
# Rules are evaluated in order; deny rules take precedence
# Put deny rules before allow rules for clarity
deny /etc/shadow r,
/var/etc/myapp/** r,
```

### Issue 13: AppArmor Blocks ptrace

**Symptoms**: Debugging tools (strace, gdb) cannot trace application.

**Fix**:
```bash
# Add ptrace exception to profile
ptrace (read, trace) peer=unconfined,

# Or run debugging tool unconfined
sudo aa-teardown  # Temporary
```

### Issue 14: AppArmor Profile Not Persisting

**Symptoms**: Profile lost after reboot.

**Fix**:
```bash
# Ensure profile is in /etc/apparmor.d/
ls /etc/apparmor.d/usr.bin.myapp

# Reload on boot
sudo systemctl enable apparmor
```

### Issue 15: Conflicting with SELinux

**Symptoms**: Both AppArmor and SELinux active, causing conflicts.

**Fix**:
```bash
# Check which is active
cat /sys/kernel/security/apparmor/profiles | head
getenforce

# Only one LSM should be active; set in GRUB
GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"
```

---

## 13. Tips & Best Practices

### Tip 1: Start with Complain Mode
Always create profiles in complain mode first, test, then switch to enforce.

### Tip 2: Use aa-genprof for Initial Profiles
```bash
sudo aa-genprof /usr/bin/myapp
```
Let it generate a base profile, then refine manually.

### Tip 3: Use aa-logprof to Update Profiles
```bash
sudo aa-logprof -f /var/log/syslog
```
Read logs and suggest profile updates.

### Tip 4: Include Common Abstractions
```bash
#include <abstractions/base>
#include <abstractions/nameservice>
```
Reduce profile duplication.

### Tip 5: Use Deny Rules for Sensitive Resources
```bash
deny /etc/shadow r,
deny /root/** rw,
```

### Tip 6: Test Before Enforcing
```bash
# Always test in complain mode
sudo aa-complain /etc/apparmor.d/usr.bin.myapp
# Run tests
# Switch to enforce
sudo aa-enforce /etc/apparmor.d/usr.bin.myapp
```

### Tip 7: Use Tunables for Portability
```bash
@{PROC}=/proc
@{SYSFS}=/sys
```

### Tip 8: Keep Profiles in Version Control
```bash
git add /etc/apparmor.d/usr.bin.myapp
git commit -m "Update nginx AppArmor profile"
```

### Tip 9: Use Profile Stacking for Complex Apps
```bash
profile nginx /usr/sbin/nginx {
  #include <abstractions/base>
  ...
}
profile nginx-helper /usr/sbin/nginx-helper {
  ...
}
```

### Tip 10: Monitor AppArmor Logs
```bash
# Real-time monitoring
sudo dmesg -w | grep apparmor
```

### Tip 11: Use Owner Rules for User-Specific Files
```bash
owner /home/*/.config/myapp/** rw,
```

### Tip 12: Minimize Permissions
Only grant what the application actually needs. Start restrictive, then add as needed.

### Tip 13: Use Network Rules Carefully
```bash
network inet stream,    # TCP IPv4
network inet6 stream,   # TCP IPv6
```

### Tip 14: Document Your Profiles
Add comments explaining why specific permissions are needed.

### Tip 15: Test with Application Updates
When updating applications, re-test profiles with `aa-logprof`.

---

## 14. Command Reference

### Profile Management

```bash
# List all profiles
sudo aa-status

# List profile details
cat /sys/kernel/security/apparmor/profiles

# Load/reload profile
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.myapp

# Remove profile
sudo apparmor_parser -R /etc/apparmor.d/usr.bin.myapp

# Validate profile
sudo apparmor_parser -Q /etc/apparmor.d/usr.bin.myapp
```

### Mode Management

```bash
# Set enforce mode
sudo aa-enforce /etc/apparmor.d/usr.bin.myapp

# Set complain mode
sudo aa-complain /etc/apparmor.d/usr.bin.myapp

# Disable profile
sudo aa-disable /etc/apparmor.d/usr.bin.myapp

# Check mode
cat /sys/kernel/security/apparmor/profiles | grep myapp
```

### Profile Generation

```bash
# Generate profile interactively
sudo aa-genprof /usr/bin/myapp

# Update profile from logs
sudo aa-logprof -f /var/log/syslog

# Cleanprof (remove unused entries)
sudo aa-cleanprof /etc/apparmor.d/usr.bin.myapp
```

### Debugging

```bash
# View AppArmor logs
sudo dmesg | grep apparmor
sudo journalctl -k | grep apparmor

# Parse profile with debug
sudo apparmor_parser -d /etc/apparmor.d/usr.bin.myapp

# View loaded profiles
cat /sys/kernel/security/apparmor/profiles

# View policy
cat /sys/kernel/security/apparmor/policy
```

### Environment Variables

```bash
AA_LOG=/var/log/apparmor.log
APPARMOR_PARSER=/sbin/apparmor_parser
AA_CONF_DIR=/etc/apparmor.d
```

---

## 15. Configuration Reference

### Profile Syntax Reference

```
# Profile declaration
profile <name> [<binary>] flags=(<flags>) {
  # Include abstractions
  #include <abstractions/base>

  # File rules
  /path/to/file r,        # Read
  /path/to/file w,        # Write
  /path/to/file rw,       # Read + Write
  /path/to/file a,        # Append
  /path/to/file l,        # Link
  /path/to/file k,        # Lock
  /path/to/file mr,       # Memory map + read
  /path/to/file px,       # Execute (clean profile)
  /path/to/file ix,       # Execute (inherit)
  /path/to/file ux,       # Execute (unconfined)
  /path/to/file Px,       # Execute with named profile
  /path/to/file Cx,       # Execute with child profile

  # Directory rules
  /path/to/dir/ r,        # List directory
  /path/to/dir/** r,      # Recursive read
  /path/to/dir/** rw,     # Recursive read + write

  # Network rules
  network inet stream,    # TCP IPv4
  network inet6 stream,   # TCP IPv6
  network inet dgram,     # UDP IPv4
  network inet6 dgram,    # UDP IPv6
  network raw,            # Raw sockets
  network packet,         # Packet sockets

  # Capability rules
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # Mount rules
  mount /dev/sda1,
  mount /dev/sda1 -> /mnt/data,
  umount /mnt/data,
  pivot_root,

  # Signal rules
  signal (send) set=(term, kill) peer=nginx,

  # ptrace rules
  ptrace (read, trace) peer=nginx,

  # Deny rules (take precedence)
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,
  deny mount,
  deny ptrace,
}
```

### Flags Reference

| Flag | Description |
|---|---|
| `attach_disconnected` | Allow profile attachment for disconnected processes |
| `mediate_deleted` | Mediate access to deleted files |
| `complain` | Set to complain mode (default when creating) |
| `enforce` | Set to enforce mode |
| `kill` | Kill process on violation |
| `unconfined` | Process runs unconfined |

### Tunables Reference

```
@{PROC}=/proc
@{SYSFS}=/sys
@{SECURITYFS}=/sys/kernel/security
@{TUNABLES}=/etc/apparmor.d/tunables
@{run}=/run
@{HOME}=/home
@{USER_PROFILE}=/home/*
```

### Common Abstractions

```
#include <abstractions/base>           # Basic file access
#include <abstractions/nameservice>    # DNS, NSS
#include <abstractions/openssl>        # OpenSSL
#include <abstractions/apache2-common> # Apache
#include <abstractions/nvidia>         # NVIDIA
#include <abstractions/kerberosclient> # Kerberos
#include <abstractions/ssl_certs>      # SSL certs
#include <abstractions/perl>           # Perl
#include <abstractions/php>            # PHP
```

---

## 16. Real-World Examples

### 16.1 Nginx Profile

```
#include <tunables/global>

profile nginx-default flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>

  # Binary
  /usr/sbin/nginx mr,
  /usr/sbin/nginx PUx,

  # Config
  /etc/nginx/** r,
  /etc/nginx/nginx.conf r,
  /etc/nginx/mime.types r,
  /etc/nginx/fastcgi* r,

  # Web content
  /var/www/** r,
  /var/www/html/** r,

  # Logs
  /var/log/nginx/** w,
  /var/log/nginx/access.log w,
  /var/log/nginx/error.log w,

  # PID and sockets
  /run/nginx.pid rw,
  /run/nginx*.sock rw,

  # Temp files
  /var/lib/nginx/** rw,
  /var/cache/nginx/** rw,
  /tmp/nginx/** rw,

  # Network
  network inet stream,
  network inet6 stream,

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,

  # Deny
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,
}
```

### 16.2 MySQL Profile

```
#include <tunables/global>

profile mysqld flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>

  # Binary
  /usr/sbin/mysqld mr,

  # Config
  /etc/mysql/** r,
  /etc/mysql/my.cnf r,

  # Data
  /var/lib/mysql/** rw,
  /var/lib/mysql/ibdata1 rw,
  /var/lib/mysql/**.ibd rw,
  /var/lib/mysql/**.frm rw,

  # Logs
  /var/log/mysql/** w,
  /var/log/mysql/error.log w,

  # Temp
  /tmp/** rw,
  /var/tmp/** rw,

  # Network
  network inet stream,
  network inet6 stream,

  # Capabilities
  capability dac_override,
  capability setuid,
  capability setgid,

  # Deny
  deny /etc/shadow r,
  deny /root/** rw,
  deny /home/** rw,
}
```

### 16.3 Docker Default Profile

```
#include <tunables/global>

profile docker-default flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Deny mount
  deny mount,
  deny umount,
  deny pivot_root,

  # Deny write to sensitive paths
  deny /proc/** w,
  deny /sys/** w,
  deny /sys/firmware/** rw,

  # Deny access to sensitive files
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /root/** rw,

  # Allow basic operations
  / r,
  /** r,
  /tmp/** rw,
  /var/lib/docker/** rw,
  /dev/null rw,
  /dev/urandom r,

  # Network
  network inet stream,
  network inet6 stream,
  network inet dgram,
  network inet6 dgram,

  # Deny raw sockets
  deny network raw,
  deny network packet,

  # Deny capabilities
  deny capability sys_admin,
  deny capability sys_module,
  deny capability sys_ptrace,
  deny capability net_raw,
}
```

### 16.4 Kubernetes Restricted Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-nginx
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-restricted
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: nginx-cache
      mountPath: /var/cache/nginx
    - name: nginx-run
      mountPath: /var/run
  volumes:
  - name: nginx-cache
    emptyDir: {}
  - name: nginx-run
    emptyDir: {}
```

### 16.5 System Service Profile

```
#include <tunables/global>

profile myservice /usr/local/bin/myservice flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Binary
  /usr/local/bin/myservice mr,

  # Config
  /etc/myservice/** r,
  /etc/myservice/config.yaml r,

  # Data
  /var/lib/myservice/** rw,
  /var/log/myservice/** w,

  # System
  /proc/sys/kernel/hostname r,
  /sys/devices/system/cpu/** r,

  # Network
  network inet stream,
  network inet6 stream,
  network inet dgram,

  # Capabilities
  capability net_bind_service,
  capability setuid,
  capability setgid,
  capability dac_override,

  # Deny
  deny /etc/shadow r,
  deny /root/** rw,
  deny mount,
  deny ptrace,
}
```

---

## 17. Further Reading

### Official Documentation
- [AppArmor Documentation](https://apparmor.net/)
- [AppArmor Wiki](https://gitlab.com/apparmor/apparmor/-/wikis/)
- [Ubuntu AppArmor Guide](https://help.ubuntu.com/community/AppArmor)
- [SUSE AppArmor Guide](https://en.opensuse.org/AppArmor)

### Books
- "The Book of AppArmor" — NathanEOS
- "Linux Security Cookbook" — Daniel J. Barrett, et al.

### Tutorials
- [AppArmor Quickstart](https://apparmor.net/quickstart/)
- [Writing AppArmor Profiles](https://gitlab.com/apparmor/apparmor/-/wikis/Profile_Writing)
- [Docker AppArmor](https://docs.docker.com/engine/security/apparmor/)

### Related Projects
- [SELinux](https://selinuxproject.org/) — Security-Enhanced Linux
- [Seccomp](https://man7.org/linux/man-pages/man2/seccomp.2.html) — Secure computing mode
- [Landlock](https://landlock.io/) — Unprivileged access control
- [KubeArmor](https://github.com/kubearmor/KubeArmor) — Kubernetes runtime security

---

*Last updated: 2026-09-04*
