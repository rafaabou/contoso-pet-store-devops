# Seccomp Complete Guide

## Table of Contents

1. [What Is Seccomp](#1-what-is-seccomp)
2. [Why Use Seccomp](#2-why-use-seccomp)
3. [Architecture Overview](#3-architecture-overview)
4. [Installation](#4-installation)
5. [Configuration](#5-configuration)
6. [Core Concepts](#6-core-concepts)
7. [Usage Guide (Step-by-Step)](#7-usage-guide)
8. [Writing Profiles](#8-writing-profiles)
9. [Seccomp Modes](#9-seccomp-modes)
10. [Integration](#10-integration)
11. [Security](#11-security)
12. [Troubleshooting](#12-troubleshooting)
13. [Tips & Best Practices](#13-tips--best-practices)
14. [Command Reference](#14-command-reference)
15. [Configuration Reference](#15-configuration-reference)
16. [Real-World Examples](#16-real-world-examples)
17. [Further Reading](#17-further-reading)

---

## 1. What Is Seccomp

Seccomp (Secure Computing Mode) is a Linux kernel feature that restricts the system calls a process can make. It acts as a syscall firewall, allowing administrators to whitelist or blacklist specific system calls. Seccomp is one of the most fundamental security mechanisms in Linux and is used extensively in container runtimes (Docker, containerd, CRI-O) and sandboxing applications.

### 1.1 Purpose

Seccomp limits the attack surface of a process by restricting which system calls it can invoke. Even if an attacker compromises a process, they cannot use system calls that are blocked by the seccomp filter.

### 1.2 History

- **2005**: Seccomp introduced in Linux kernel 2.6.12 (strict mode)
- **2009**: Seccomp-bpf added in Linux kernel 2.6.23 (filter mode using BPF)
- **2014**: Docker uses seccomp profiles by default
- **2017**: Kubernetes supports seccomp profiles via Pod Security Policies
- **2020+**: Seccomp support in Pod Security Standards, OCI runtime spec

### 1.3 Key Features

- Kernel-level syscall filtering (no userspace overhead)
- Two modes: strict (only read/write/exit/sigreturn) and filter (BPF-based)
- Fine-grained control: allow/deny individual syscalls
- Argument-based filtering (filter by syscall arguments)
- Audit mode (log denials without blocking)
- Container-native (Docker, Kubernetes, CRI-O)
- Single binary, no daemon required

---

## 2. Why Use Seccomp

### 2.1 Attack Surface Reduction

| Without Seccomp | With Seccomp |
|---|---|
| ~300+ syscalls available | Only necessary syscalls allowed |
| Full kernel attack surface | Minimal attack surface |
| Container escape via syscall | Blocked syscall attempt |
| Privilege escalation via ptrace | ptrace blocked |
| Kernel exploit via uncommon syscall | Uncommon syscall blocked |

### 2.2 Seccomp vs Other Sandboxing

| Feature | Seccomp | AppArmor | SELinux | Landlock |
|---|---|---|---|---|
| Scope | Syscalls only | Files, network, capabilities | Files, processes, network | Files, network, processes |
| Granularity | Per-syscall | Per-path | Per-label | Per-object |
| Kernel-level | Yes | Yes (LSM) | Yes (LSM) | Yes (LSM) |
| Filter mode | BPF-based | Profile-based | Label-based | Rule-based |
| Container support | Native | Native | Native | Native |
| Performance | Very low overhead | Low overhead | Low overhead | Low overhead |

### 2.3 Use Cases

1. **Container security** — limit syscalls in containers
2. **Sandboxing** — confine untrusted applications
3. **Privilege reduction** — drop unnecessary capabilities
4. **Compliance** — enforce syscall whitelists
5. **Kernel exploit mitigation** — block uncommon syscalls

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                User Space                        │
│  ┌───────────────────────────────────────────┐  │
│  │  Application Process                      │  │
│  │  (makes syscall)                          │  │
│  └───────────────────┬───────────────────────┘  │
└──────────────────────┼──────────────────────────┘
                       │ syscall (e.g., execve)
┌──────────────────────▼──────────────────────────┐
│              Kernel Space                        │
│  ┌───────────────────────────────────────────┐  │
│  │  Seccomp BPF Filter                      │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │ 1. Check syscall number             │  │  │
│  │  │ 2. Check syscall arguments          │  │  │
│  │  │ 3. Return ALLOW, DENY, or TRAP      │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  └───────────────────┬───────────────────────┘  │
│                      │                           │
│  ┌───────────────────▼───────────────────────┐  │
│  │  Syscall Handler                          │  │
│  │  (executes if ALLOW, else returns EPERM)  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 3.1 Components

| Component | Role |
|---|---|
| **BPF Filter** | Program that evaluates syscalls |
| **Syscall Number** | Identifies the system call (e.g., 59 = execve) |
| **Syscall Arguments** | Up to 6 arguments per syscall |
| **Return Values** | ALLOW, DENY, ERRNO, TRAP, KILL, LOG |

### 3.2 Seccomp Modes

| Mode | Description |
|---|---|
| **SECCOMP_MODE_STRICT** | Only read, write, exit, sigreturn allowed |
| **SECCOMP_MODE_FILTER** | BPF-based filter (flexible, container-default) |
| **Disabled** | No seccomp filtering |

---

## 4. Installation

### 4.1 Kernel Requirements

```bash
# Check kernel version (need 2.6.23+ for BPF filter)
uname -r

# Check seccomp support
grep CONFIG_SECCOMP /boot/config-$(uname -r)
# Should show: CONFIG_SECCOMP=y

# Check seccomp support at runtime
cat /proc/self/status | grep Seccomp
# Seccomp:  2  (0=disabled, 1=strict, 2=filter)
```

### 4.2 Docker (Default Enabled)

```bash
# Docker uses seccomp by default
docker info | grep -i seccomp
# Security Options:
#  seccomp Profile: default

# Run without seccomp (NOT recommended)
docker run --security-opt seccomp=unconfined alpine

# Run with custom seccomp profile
docker run --security-opt seccomp=my-profile.json alpine
```

### 4.3 Kubernetes

```yaml
# Pod Security Standards (PSS) enforces seccomp
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: alpine
```

### 4.4 libseccomp

```bash
# Install libseccomp (for seccomp-tools)
# Debian/Ubuntu
sudo apt-get install libseccomp-dev

# RHEL/CentOS
sudo yum install libseccomp-devel

# Check version
pkg-config --modversion libseccomp
```

### 4.5 seccomp-tools (Ruby)

```bash
# Install seccomp-tools
gem install seccomp-tools

# Usage
seccomp-tools dump my-binary
seccomp-tools trace my-binary
```

---

## 5. Configuration

### 5.1 Default Docker Profile

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86", "SCMP_ARCH_AARCH64"],
  "syscalls": [
    {
      "names": [
        "accept", "access", "alarm", "bind", "brk",
        "clock_gettime", "clone", "close", "connect",
        "dup", "dup2", "epoll_create", "epoll_wait",
        "execve", "exit", "exit_group", "fcntl",
        "fstat", "futex", "getdents", "getpid",
        "getsockname", "gettid", "gettimeofday",
        "ioctl", "listen", "lseek", "mmap",
        "mprotect", "munmap", "nanosleep", "open",
        "openat", "poll", "read", "recvfrom",
        "recvmsg", "rename", "rt_sigaction",
        "rt_sigprocmask", "rt_sigreturn", "sendmsg",
        "sendto", "set_robust_list", "set_tid_address",
        "setsockopt", "shutdown", "sigaltstack",
        "socket", "stat", "tgkill", "umask",
        "uname", "unlink", "wait4", "write",
        "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["clone"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": 2114060288, "op": "SCMP_CMP_MASKED_EQ", "valueTwo": 0 }
      ]
    }
  ]
}
```

### 5.2 Custom Profile Format

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_AARCH64"
  ],
  "syscalls": [
    {
      "names": ["read", "write", "close", "fstat", "lseek"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["execve"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": "/usr/bin/safe-program", "op": "SCMP_CMP_EQ" }
      ]
    },
    {
      "names": ["socket"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": 2, "op": "SCMP_CMP_EQ" },
        { "index": 1, "value": 1, "op": "SCMP_CMP_EQ" }
      ]
    },
    {
      "names": ["ptrace", "kexec_load", "reboot", "init_module", "finit_module", "delete_module"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 5.3 Action Types

| Action | Description |
|---|---|
| `SCMP_ACT_ALLOW` | Allow the syscall |
| `SCMP_ACT_ERRNO` | Return error (EPERM by default) |
| `SCMP_ACT_TRAP` | Send SIGSYS signal |
| `SCMP_ACT_KILL_PROCESS` | Kill the process |
| `SCMP_ACT_KILL` | Kill the thread |
| `SCMP_ACT_LOG` | Allow but log the syscall |
| `SCMP_ACT_NOTIFY` | Notify userspace (seccomp notify) |

---

## 6. Core Concepts

### 6.1 Syscall Filtering

Seccomp works by installing a BPF (Berkeley Packet Filter) program that runs before every system call. The filter inspects the syscall number and arguments, then returns an action:

```
Process makes syscall (e.g., execve)
    ↓
Seccomp filter intercepts
    ↓
Filter evaluates:
  1. Syscall number == execve?
  2. Arguments match allowed pattern?
    ↓
Returns: ALLOW, DENY, ERRNO, TRAP, KILL
```

### 6.2 Syscall Numbers

| Syscall | x86_64 | ARM64 | x86 |
|---|---|---|---|
| `read` | 0 | 63 | 3 |
| `write` | 1 | 64 | 4 |
| `open` | 2 | — | 5 |
| `openat` | 257 | 56 | 294 |
| `close` | 3 | 57 | 6 |
| `execve` | 59 | 221 | 11 |
| `clone` | 56 | 220 | 120 |
| `ptrace` | 101 | 117 | 19 |
| `mount` | 165 | 40 | 21 |
| `reboot` | 169 | 142 | 88 |
| `kexec_load` | 246 | — | — |
| `init_module` | 175 | 105 | 128 |
| `delete_module` | 176 | 106 | 129 |
| `socket` | 41 | 198 | 359 |
| `connect` | 42 | 203 | 362 |

### 6.3 Argument Filtering

```json
{
  "args": [
    { "index": 0, "value": 2, "op": "SCMP_CMP_EQ" },
    { "index": 1, "value": 1, "op": "SCMP_CMP_EQ" },
    { "index": 2, "value": 6, "op": "SCMP_CMP_MASKED_EQ", "valueTwo": 0 }
  ]
}
```

| Operator | Description |
|---|---|
| `SCMP_CMP_EQ` | Equal |
| `SCMP_CMP_NE` | Not equal |
| `SCMP_CMP_LT` | Less than |
| `SCMP_CMP_LE` | Less than or equal |
| `SCMP_CMP_GT` | Greater than |
| `SCMP_CMP_GE` | Greater than or equal |
| `SCMP_CMP_MASKED_EQ` | (value & valueTwo) == value |
| `SCMP_CMP_MASKED_NE` | (value & valueTwo) != value |

### 6.4 Multi-Architecture

Seccomp profiles can specify multiple architectures:

```json
{
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_AARCH64"
  ]
}
```

---

## 7. Usage Guide (Step-by-Step)

### Step 1: Check Seccomp Support

```bash
# Check kernel support
grep CONFIG_SECCOMP /boot/config-$(uname -r)

# Check if Docker supports seccomp
docker info | grep -i seccomp
```

### Step 2: Create Custom Profile

```bash
# Create a basic profile
cat > /etc/docker/seccomp/my-profile.json << 'EOF'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "close", "fstat", "lseek", "mmap", "mprotect", "munmap", "brk", "rt_sigaction", "rt_sigprocmask", "ioctl", "access", "pipe", "select", "sched_yield", "mremap", "msync", "mincore", "madvise", "dup", "dup2", "nanosleep", "getpid", "clone", "fork", "vfork", "execve", "exit", "exit_group", "wait4", "kill", "uname", "fcntl", "flock", "fsync", "fdatasync", "truncate", "ftruncate", "getdents", "getcwd", "chdir", "rename", "mkdir", "rmdir", "link", "unlink", "symlink", "readlink", "chmod", "fchmod", "chown", "fchown", "umask", "gettimeofday", "getuid", "getgid", "geteuid", "getegid", "getppid", "getpgrp", "setpgid", "getgroups", "setgroups", "setresuid", "getresuid", "setresgid", "getresgid", "getpgid", "setfsuid", "setfsgid", "getsid", "setsid", "getgroups", "setgroups", "sigaltstack", "statfs", "fstatfs", "sysfs", "personality", "prlimit64", "getrusage", "gettimeofday", "clock_gettime", "clock_getres", "clock_nanosleep", "trace", "seccomp", "futex", "sched_setaffinity", "sched_getaffinity", "set_thread_area", "io_setup", "io_destroy", "io_getevents", "io_submit", "io_cancel", "remap_file_pages", "mbind", "set_mempolicy", "get_mempolicy", "mkdirat", "newfstatat", "linkat", "symlinkat", "unlinkat", "renameat", "fchmodat", "fchownat", "futimesat", "newfstatat", "readlinkat", "faccessat", "pselect6", "ppoll", "set_robust_list", "get_robust_list", "splice", "tee", "sync_file_range", "utimensat", "epoll_pwait", "signalfd", "timerfd_create", "eventfd", "fallocate", "timerfd_settime", "timerfd_gettime", "accept4", "signalfd4", "eventfd2", "epoll_create1", "dup3", "pipe2", "inotify_init1", "preadv", "pwritev", "rt_tgsigqueueinfo", "perf_event_open", "recvmmsg", "fanotify_init", "prlimit64", "name_to_handle_at", "open_by_handle_at", "clock_adjtime", "syncfs", "sendmmsg", "setns", "getcpu", "process_vm_readv", "process_vm_writev", "kcmp", "finit_module", "sched_setattr", "sched_getattr", "renameat2", "seccomp", "getrandom", "memfd_create", "kexec_file_load", "bpf", "execveat", "userfaultfd", "membarrier", "mlock2", "copy_file_range", "preadv2", "pwritev2", "pkey_mprotect", "pkey_alloc", "pkey_free", "statx", "io_pgetevents", "rseq", "kexec_file_load"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF
```

### Step 3: Test Profile with Docker

```bash
# Run container with custom profile
docker run --rm -it \
  --security-opt seccomp=/etc/docker/seccomp/my-profile.json \
  alpine sh

# Check if syscalls are blocked
docker run --rm -it \
  --security-opt seccomp=/etc/docker/seccomp/my-profile.json \
  alpine cat /etc/passwd
```

### Step 4: Apply to Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/my-profile.json
  containers:
  - name: app
    image: alpine
```

### Step 5: Generate Profile with strace

```bash
# Generate profile from strace output
strace -f -o /tmp/syscalls.log ./my-program

# Parse and create profile
cat /tmp/syscalls.log | grep -oP '^[a-z_]+(?=\()' | sort -u
```

### Step 6: Use seccomp-tools

```bash
# Dump seccomp profile from binary
seccomp-tools dump ./my-binary

# Trace syscalls
seccomp-tools trace ./my-binary

# Format output
seccomp-tools dump ./my-binary --format json
```

### Step 7: Enable Audit Mode

```json
{
  "defaultAction": "SCMP_ACT_LOG",
  "syscalls": [
    {
      "names": ["ptrace", "kexec_load"],
      "action": "SCMP_ACT_LOG"
    }
  ]
}
```

### Step 8: Validate Profile

```bash
# Validate JSON syntax
cat profile.json | jq .

# Validate with seccomp-tools
seccomp-tools dump --format json profile.json

# Test in Docker
docker run --security-opt seccomp=profile.json alpine echo test
```

---

## 8. Writing Profiles

### 8.1 Profile Structure

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86"],
  "syscalls": [
    {
      "names": ["read", "write", "close"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["execve"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": "/usr/bin/safe", "op": "SCMP_CMP_EQ" }
      ]
    },
    {
      "names": ["socket"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": 2, "op": "SCMP_CMP_EQ" },
        { "index": 1, "value": 1, "op": "SCMP_CMP_EQ" }
      ]
    },
    {
      "names": ["ptrace"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 8.2 Minimal Profile (Read-Only)

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "close", "fstat", "lseek",
        "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
        "access", "pipe", "select", "nanosleep",
        "getpid", "exit", "exit_group",
        "uname", "fcntl", "getcwd", "chdir",
        "stat", "fstat", "lstat",
        "getuid", "getgid", "geteuid", "getegid",
        "getppid", "getpgrp", "gettid",
        "writev", "readv", "pread64", "pwrite64"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### 8.3 Network Server Profile

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "read", "write", "close", "fstat", "lseek",
        "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn",
        "socket", "bind", "listen", "accept", "accept4",
        "connect", "sendto", "recvfrom", "sendmsg", "recvmsg",
        "setsockopt", "getsockopt", "getsockname", "getpeername",
        "shutdown", "epoll_create", "epoll_ctl", "epoll_wait",
        "select", "poll", "ppoll",
        "clone", "fork", "vfork", "execve", "exit", "exit_group",
        "getpid", "gettid", "getuid", "getgid",
        "geteuid", "getegid", "getppid", "getpgrp",
        "uname", "fcntl", "ioctl", "dup", "dup2", "dup3",
        "pipe", "pipe2", "eventfd", "eventfd2",
        "futex", "nanosleep", "clock_nanosleep",
        "access", "openat", "stat", "fstat", "newfstatat",
        "writev", "readv", "pread64", "pwrite64",
        "prlimit64", "set_robust_list", "get_robust_list",
        "arch_prctl", "set_tid_address"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["socket"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        { "index": 0, "value": 2, "op": "SCMP_CMP_EQ" },
        { "index": 1, "value": 1, "op": "SCMP_CMP_EQ" }
      ]
    },
    {
      "names": ["ptrace", "kexec_load", "reboot", "init_module", "finit_module", "delete_module", "mount", "umount2", "pivot_root", "swapon", "swapoff", "sethostname", "setdomainname", "iopl", "ioperm", "create_module", "query_module", "quotactl", "nfsservctl", "getpmsg", "putpmsg", "afs_syscall", "tuxcall", "security", "settimeofday", "clock_settime", "vhangup", "vm86", "modify_ldt", "pivot_root", "lookup_dcookie", "vserver", "add_key", "request_key", "keyctl", "ioprio_set", "ioprio_get", "inotify_add_watch", "inotify_rm_watch", "migrate_pages", "openat", "mkdirat", "mknodat", "fchownat", "futimesat", "newfstatat", "unlinkat", "renameat", "linkat", "symlinkat", "readlinkat", "fchmodat", "faccessat", "pselect6", "ppoll", "unshare", "set_robust_list", "get_robust_list", "splice", "tee", "sync_file_range", "utimensat", "epoll_pwait", "signalfd", "timerfd_create", "eventfd", "fallocate", "timerfd_settime", "timerfd_gettime", "accept4", "signalfd4", "eventfd2", "epoll_create1", "dup3", "pipe2", "inotify_init1", "preadv", "pwritev", "rt_tgsigqueueinfo", "perf_event_open", "recvmmsg", "fanotify_init", "prlimit64", "name_to_handle_at", "open_by_handle_at", "clock_adjtime", "syncfs", "sendmmsg", "setns", "getcpu", "process_vm_readv", "process_vm_writev", "kcmp", "finit_module", "sched_setattr", "sched_getattr", "renameat2", "seccomp", "getrandom", "memfd_create", "kexec_file_load", "bpf", "execveat", "userfaultfd", "membarrier", "mlock2", "copy_file_range", "preadv2", "pwritev2", "pkey_mprotect", "pkey_alloc", "pkey_free", "statx", "io_pgetevents", "rseq", "kexec_file_load"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 8.4 Drop Privileges Profile

```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "ptrace", "kexec_load", "reboot", "init_module",
        "finit_module", "delete_module", "mount", "umount2",
        "pivot_root", "swapon", "swapoff", "sethostname",
        "setdomainname", "iopl", "ioperm", "create_module",
        "query_module", "quotactl", "nfsservctl", "vhangup",
        "vm86", "modify_ldt", "lookup_dcookie", "vserver",
        "add_key", "request_key", "keyctl", "ioprio_set",
        "unshare", "setns", "process_vm_readv",
        "process_vm_writev", "kcmp", "bpf", "userfaultfd",
        "membarrier", "mlock2", "pkey_mprotect", "pkey_alloc",
        "pkey_free"
      ],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

---

## 9. Seccomp Modes

### 9.1 Strict Mode

```c
// Only allows: read, write, exit, sigreturn
seccomp(SECCOMP_SET_MODE_STRICT, 0, NULL, 0);
```

```bash
# Apply strict mode to a process
# (usually via Docker or programmatic)
```

### 9.2 Filter Mode (BPF)

```c
// Install BPF filter
struct sock_filter filter[] = {
    // Load syscall number
    BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
    // Check if execve (59 on x86_64)
    BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, 59, 0, 1),
    // Allow execve
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    // Deny all other syscalls
    BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | (EPERM & SECCOMP_RET_DATA)),
};

struct sock_fprog prog = {
    .len = sizeof(filter) / sizeof(filter[0]),
    .filter = filter,
};

seccomp(SECCOMP_SET_MODE_FILTER, 0, &prog, 0);
```

### 9.3 Audit Mode

```json
{
  "defaultAction": "SCMP_ACT_LOG",
  "syscalls": []
}
```

All syscalls are allowed but logged. Useful for profiling.

### 9.4 Notify Mode

```json
{
  "defaultAction": "SCMP_ACT_NOTIFY",
  "syscalls": [
    {
      "names": ["execve"],
      "action": "SCMP_ACT_NOTIFY"
    }
  ]
}
```

Userspace daemon decides per-syscall. Used by container runtimes.

---

## 10. Integration

### 10.1 Docker

```bash
# Default profile
docker run alpine echo test

# Custom profile
docker run --security-opt seccomp=my-profile.json alpine echo test

# No profile (unconfined)
docker run --security-opt seccomp=unconfined alpine echo test

# Check seccomp status
docker inspect --format '{{.HostConfig.SecurityOpt}}' my-container
```

### 10.2 Kubernetes

```yaml
# Pod Security Standards (PSS)
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: alpine

# Localhost profile
apiVersion: v1
kind: Pod
metadata:
  name: custom-seccomp
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/my-profile.json
  containers:
  - name: app
    image: alpine
```

### 10.3 Container Runtimes

```bash
# containerd
nerdctl run --security-opt seccomp=my-profile.json alpine

# CRI-O
crictl run --security-opt seccomp=my-profile.json alpine

# Podman
podman run --security-opt seccomp=my-profile.json alpine
```

### 10.4 Systemd

```bash
# Systemd service with seccomp
# /etc/systemd/system/myapp.service
[Service]
ExecStart=/usr/bin/myapp
SystemCallFilter=@system-service
SystemCallArchitectures=native
SeccompProfile=/etc/seccomp/myapp.json
```

---

## 11. Security

### 11.1 Profile Hardening

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "close", "fstat", "lseek", "mmap", "mprotect", "munmap", "brk", "rt_sigaction", "rt_sigprocmask", "rt_sigreturn", "access", "pipe", "select", "nanosleep", "getpid", "exit", "exit_group", "uname", "fcntl", "getcwd", "chdir", "stat", "fstat", "lstat", "getuid", "getgid", "geteuid", "getegid", "getppid", "getpgrp", "gettid", "writev", "readv", "pread64", "pwrite64"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["ptrace", "kexec_load", "reboot", "init_module", "finit_module", "delete_module", "mount", "umount2", "pivot_root", "swapon", "swapoff", "sethostname", "setdomainname", "iopl", "ioperm", "create_module", "query_module", "quotactl", "nfsservctl", "getpmsg", "putpmsg", "afs_syscall", "tuxcall", "security", "settimeofday", "clock_settime", "vhangup", "vm86", "modify_ldt", "pivot_root", "lookup_dcookie", "vserver", "add_key", "request_key", "keyctl", "ioprio_set", "ioprio_get", "inotify_add_watch", "inotify_rm_watch", "migrate_pages", "openat", "mkdirat", "mknodat", "fchownat", "futimesat", "newfstatat", "unlinkat", "renameat", "linkat", "symlinkat", "readlinkat", "fchmodat", "faccessat", "pselect6", "ppoll", "unshare", "set_robust_list", "get_robust_list", "splice", "tee", "sync_file_range", "utimensat", "epoll_pwait", "signalfd", "timerfd_create", "eventfd", "fallocate", "timerfd_settime", "timerfd_gettime", "accept4", "signalfd4", "eventfd2", "epoll_create1", "dup3", "pipe2", "inotify_init1", "preadv", "pwritev", "rt_tgsigqueueinfo", "perf_event_open", "recvmmsg", "fanotify_init", "prlimit64", "name_to_handle_at", "open_by_handle_at", "clock_adjtime", "syncfs", "sendmmsg", "setns", "getcpu", "process_vm_readv", "process_vm_writev", "kcmp", "finit_module", "sched_setattr", "sched_getattr", "renameat2", "seccomp", "getrandom", "memfd_create", "kexec_file_load", "bpf", "execveat", "userfaultfd", "membarrier", "mlock2", "copy_file_range", "preadv2", "pwritev2", "pkey_mprotect", "pkey_alloc", "pkey_free", "statx", "io_pgetevents", "rseq", "kexec_file_load"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 11.2 Capabilities + Seccomp

```yaml
# Kubernetes: combine with capabilities
apiVersion: v1
kind: Pod
metadata:
  name: hardened-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: alpine
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
```

---

## 12. Troubleshooting

### Issue 1: Container Fails to Start

**Symptoms**: Container exits immediately with "permission denied".

**Diagnosis**:
```bash
# Check container logs
docker logs my-container

# Check seccomp profile
docker inspect my-container | jq '.[0].HostConfig.SecurityOpt'

# Test profile manually
docker run --security-opt seccomp=profile.json alpine echo test
```

**Fix**: The profile blocks a required syscall. Use `SCMP_ACT_LOG` to audit, then add needed syscalls.

### Issue 2: Syscall Not Allowed

**Symptoms**: Application fails with "Operation not permitted".

**Diagnosis**:
```bash
# Trace syscalls
strace -f -e trace=network ./my-app 2>&1 | grep EPERM

# Check which syscall is blocked
dmesg | grep seccomp
```

**Fix**: Add the blocked syscall to the profile:
```json
{
  "names": ["blocked_syscall"],
  "action": "SCMP_ACT_ALLOW"
}
```

### Issue 3: Profile Not Applied

**Symptoms**: Container runs without seccomp restrictions.

**Diagnosis**:
```bash
# Check if seccomp is enabled
docker info | grep -i seccomp

# Check container security options
docker inspect my-container | jq '.[0].HostConfig.SecurityOpt'
```

**Fix**: Ensure seccomp profile is properly formatted and path is correct.

### Issue 4: Audit Mode Not Logging

**Symptoms**: `SCMP_ACT_LOG` not producing output.

**Fix**:
```bash
# Check audit log
sudo ausearch -m SECCOMP

# Or check dmesg
sudo dmesg | grep seccomp
```

### Issue 5: Wrong Syscall Numbers

**Symptoms**: Profile blocks wrong syscalls.

**Fix**: Syscall numbers differ by architecture:
```json
{
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
  "syscalls": [...]
}
```

### Issue 6: Container Runtime Ignoring Profile

**Symptoms**: seccomp profile not applied.

**Diagnosis**:
```bash
# Check container runtime version
docker version

# Check if profile is loaded
docker inspect my-container | jq '.[0].HostConfig.SecurityOpt'
```

**Fix**: Update container runtime to version that supports seccomp.

### Issue 7: Application Segfaults

**Symptoms**: Application crashes under seccomp.

**Fix**:
```bash
# Switch to audit mode
"defaultAction": "SCMP_ACT_LOG"

# Check which syscalls are being denied
sudo dmesg | grep seccomp
```

### Issue 8: Cannot Trace Blocked Syscalls

**Symptoms**: `strace` cannot trace syscalls blocked by seccomp.

**Fix**: Use `SCMP_ACT_LOG` mode or run tracing tool before seccomp filter is applied.

### Issue 9: Profile JSON Syntax Error

**Symptoms**: "invalid profile" error.

**Fix**:
```bash
# Validate JSON
cat profile.json | jq .

# Check for common errors
# - Missing commas
# - Trailing commas
# - Invalid action names
```

### Issue 10: Docker Daemon Default Profile

**Symptoms**: Custom profile not used by default.

**Fix**:
```bash
# Configure Docker daemon
cat /etc/docker/daemon.json
{
  "seccomp-profile": "/etc/docker/seccomp/my-profile.json"
}

sudo systemctl restart docker
```

### Issue 11: Kubernetes Pod Security Standards

**Symptoms**: Pod rejected by admission controller.

**Fix**:
```yaml
# Ensure seccomp profile is set
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

### Issue 12: Application Uses Uncommon Syscalls

**Symptoms**: Application fails due to blocked uncommon syscall.

**Fix**:
```bash
# Trace application to find syscalls
strace -f -o /tmp/syscalls.log ./my-app
grep -oP '^[a-z_]+(?=\()' /tmp/syscalls.log | sort -u
```

### Issue 13: Cannot Use Seccomp in Container

**Symptoms**: "seccomp not supported" error.

**Fix**:
```bash
# Check kernel support
grep CONFIG_SECCOMP /boot/config-$(uname -r)

# Check Docker support
docker info | grep -i security
```

### Issue 14: Profile Too Restrictive

**Symptoms**: Application cannot start at all.

**Fix**:
```bash
# Use Docker's default profile as base
docker run --security-opt seccomp=/etc/docker/seccomp/default.json alpine

# Modify from there
```

### Issue 15: Cannot Modify Running Container's Seccomp

**Symptoms**: Cannot change seccomp profile after container starts.

**Fix**: Seccomp profiles are immutable after application. Recreate container with new profile.

---

## 13. Tips & Best Practices

### Tip 1: Start with Docker's Default Profile
Docker's default profile is well-tested. Use it as a starting point.

### Tip 2: Use Audit Mode First
```json
{ "defaultAction": "SCMP_ACT_LOG" }
```
Profile your application, then create a restrictive profile.

### Tip 3: Use seccomp-tools
```bash
seccomp-tools dump ./my-binary
```
Auto-generate profiles from binaries.

### Tip 4: Test with Docker
```bash
docker run --security-opt seccomp=profile.json my-app
```
Test profiles before deploying to production.

### Tip 5: Combine with Capabilities
```yaml
securityContext:
  capabilities:
    drop: ["ALL"]
    add: ["NET_BIND_SERVICE"]
  seccompProfile:
    type: RuntimeDefault
```

### Tip 6: Use RuntimeDefault for Kubernetes
`RuntimeDefault` uses the container runtime's default profile (well-tested).

### Tip 7: Keep Profiles in Version Control
```bash
git add /etc/docker/seccomp/my-profile.json
git commit -m "Update seccomp profile for nginx"
```

### Tip 8: Monitor Seccomp Denials
```bash
# Check audit logs
sudo ausearch -m SECCOMP

# Check dmesg
sudo dmesg | grep seccomp
```

### Tip 9: Use Argument Filtering for Security
```json
{
  "args": [
    { "index": 0, "value": 2, "op": "SCMP_CMP_EQ" }
  ]
}
```
Filter by syscall arguments, not just number.

### Tip 10: Use Multi-Architecture Profiles
```json
{
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"]
}
```

### Tip 11: Minimal Profiles for Sandboxing
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [{ "names": ["read", "write", "exit"], "action": "SCMP_ACT_ALLOW" }]
}
```

### Tip 12: Use SCMP_ACT_TRAP for Debugging
Send SIGSYS to process on blocked syscall — useful for debugging.

### Tip 13: Use SCMP_ACT_KILL_PROCESS for Critical Security
Kill entire process (not just thread) on violation.

### Tip 14: Profile Per Container
Each container should have its own seccomp profile.

### Tip 15: Don't Use Unconfined in Production
```bash
# NEVER do this in production
docker run --security-opt seccomp=unconfined my-app
```

### Tip 16: Test Profiles Regularly
Re-test profiles when updating applications.

---

## 14. Command Reference

### Docker

```bash
# Run with custom profile
docker run --security-opt seccomp=profile.json alpine

# Run unconfined (NOT recommended)
docker run --security-opt seccomp=unconfined alpine

# Check seccomp status
docker inspect --format '{{.HostConfig.SecurityOpt}}' my-container

# Docker daemon default profile
# /etc/docker/daemon.json
{ "seccomp-profile": "/etc/docker/seccomp/default.json" }
```

### Kubernetes

```yaml
# Pod with RuntimeDefault
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault

# Pod with Localhost profile
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/my-profile.json
```

### seccomp-tools

```bash
# Dump profile from binary
seccomp-tools dump ./my-binary

# Dump to JSON
seccomp-tools dump ./my-binary --format json

# Trace syscalls
seccomp-tools trace ./my-binary

# Format output
seccomp-tools dump --format pretty ./my-binary
```

### System

```bash
# Check seccomp support
grep CONFIG_SECCOMP /boot/config-$(uname -r)

# Check process seccomp status
cat /proc/self/status | grep Seccomp

# Trace syscalls
strace -f -e trace=network ./my-app

# Audit seccomp denials
sudo ausearch -m SECCOMP
sudo dmesg | grep seccomp
```

---

## 15. Configuration Reference

### Profile JSON Reference

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        {
          "index": 0,
          "value": 0,
          "op": "SCMP_CMP_EQ",
          "valueTwo": 0
        }
      ]
    }
  ]
}
```

### Action Types

| Action | Description |
|---|---|
| `SCMP_ACT_ALLOW` | Allow the syscall |
| `SCMP_ACT_ERRNO` | Return error (EPERM) |
| `SCMP_ACT_TRAP` | Send SIGSYS signal |
| `SCMP_ACT_KILL_PROCESS` | Kill the process |
| `SCMP_ACT_KILL` | Kill the thread |
| `SCMP_ACT_LOG` | Allow but log |
| `SCMP_ACT_NOTIFY` | Notify userspace |

### Argument Operators

| Operator | Description |
|---|---|
| `SCMP_CMP_EQ` | Equal |
| `SCMP_CMP_NE` | Not equal |
| `SCMP_CMP_LT` | Less than |
| `SCMP_CMP_LE` | Less than or equal |
| `SCMP_CMP_GT` | Greater than |
| `SCMP_CMP_GE` | Greater than or equal |
| `SCMP_CMP_MASKED_EQ` | (value & mask) == value |
| `SCMP_CMP_MASKED_NE` | (value & mask) != value |

### Architecture Constants

| Constant | Description |
|---|---|
| `SCMP_ARCH_X86_64` | x86_64 (AMD64) |
| `SCMP_ARCH_X86` | x86 (i386) |
| `SCMP_ARCH_AARCH64` | ARM64 |
| `SCMP_ARCH_ARM` | ARM (32-bit) |
| `SCMP_ARCH_MIPS` | MIPS |
| `SCMP_ARCH_PPC64` | PowerPC 64 |
| `SCMP_ARCH_S390X` | IBM System z |

### Common Syscall Groups

| Group | Syscalls |
|---|---|
| **File I/O** | read, write, open, openat, close, stat, fstat, lstat, lseek, pread64, pwrite64 |
| **Process** | fork, vfork, clone, clone3, execve, execveat, exit, exit_group, wait4, waitid |
| **Network** | socket, connect, accept, accept4, sendto, recvfrom, sendmsg, recvmsg, bind, listen |
| **Memory** | mmap, munmap, mprotect, mremap, madvise, brk, sbrk, mlock, munlock |
| **Signals** | kill, tkill, tgkill, rt_sigaction, rt_sigprocmask, rt_sigreturn, signalfd |
| **Security** | ptrace, kexec_load, reboot, init_module, finit_module, delete_module, bpf |

---

## 16. Real-World Examples

### 16.1 Nginx Profile

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86"],
  "syscalls": [
    {
      "names": [
        "read", "write", "close", "fstat", "lseek", "mmap", "mprotect", "munmap", "brk",
        "rt_sigaction", "rt_sigprocmask", "rt_sigreturn", "access", "pipe", "select",
        "nanosleep", "getpid", "exit", "exit_group", "uname", "fcntl", "getcwd", "chdir",
        "stat", "fstat", "lstat", "getuid", "getgid", "geteuid", "getegid", "getppid",
        "getpgrp", "gettid", "writev", "readv", "pread64", "pwrite64", "socket", "bind",
        "listen", "accept", "accept4", "connect", "sendto", "recvfrom", "sendmsg", "recvmsg",
        "setsockopt", "getsockopt", "getsockname", "getpeername", "shutdown", "epoll_create",
        "epoll_ctl", "epoll_wait", "epoll_create1", "eventfd", "eventfd2", "clone", "fork",
        "vfork", "execve", "prlimit64", "set_robust_list", "get_robust_list", "arch_prctl",
        "set_tid_address", "futex", "clock_gettime", "clock_getres", "clock_nanosleep",
        "openat", "newfstatat", "pipe2", "dup", "dup2", "dup3", "ioctl"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["ptrace", "kexec_load", "reboot", "init_module", "finit_module", "delete_module", "mount", "umount2", "pivot_root"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### 16.2 Kubernetes Restricted Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: alpine:3.19
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

### 16.3 Systemd Service

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/myapp
User=myapp
Group=myapp
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
MemoryDenyWriteExecute=yes
LockPersonality=yes
SystemCallFilter=@system-service
SystemCallArchitectures=native
SeccompProfile=/etc/seccomp/myapp.json

[Install]
WantedBy=multi-user.target
```

### 16.4 Minimal Sandboxing

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "close", "exit", "exit_group", "fstat", "lseek", "mmap", "mprotect", "munmap", "brk", "rt_sigreturn", "access", "pipe", "select", "nanosleep", "getpid", "uname", "fcntl", "getcwd", "chdir", "stat", "writev", "readv", "openat", "newfstatat"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### 16.5 Audit-Only Profile

```json
{
  "defaultAction": "SCMP_ACT_LOG",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": []
}
```

All syscalls allowed, all logged. Use for profiling before restricting.

---

## 17. Further Reading

### Official Documentation
- [Seccomp(2) man page](https://man7.org/linux/man-pages/man2/seccomp.2.html)
- [Docker Seccomp Security](https://docs.docker.com/engine/security/seccomp/)
- [Kubernetes Seccomp](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#seccomp-profile)
- [OCI Runtime Spec - Seccomp](https://github.com/opencontainers/runtime-spec/blob/main/config-linux.md#seccomp)
- [libseccomp Documentation](https://github.com/seccomp/libseccomp)

### Books
- "Container Security" — Liz Rice
- "Linux Security Cookbook" — Daniel J. Barrett, et al.

### Tutorials
- [Seccomp BPF Tutorial](https://www.kernel.org/doc/Documentation/prctl/seccomp_filter.txt)
- [seccomp-tools](https://github.com/st0012/seccomp-tools)
- [Docker Seccomp Default Profile](https://github.com/moby/moby/blob/master/profiles/seccomp/default.json)

### Related Projects
- [Landlock](https://landlock.io/) — Unprivileged access control
- [AppArmor](https://apparmor.net/) — Application Armor
- [SELinux](https://selinuxproject.org/) — Security-Enhanced Linux
- [gVisor](https://gvisor.dev/) — Container runtime with syscall filtering
- [Kata Containers](https://katacontainers.io/) — Lightweight VM containers

---

*Last updated: 2026-09-04*
