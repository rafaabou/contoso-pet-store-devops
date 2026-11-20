# 14 — Runtime Security

> Detect and prevent attacks in real time — monitor syscalls, enforce profiles, and respond to threats as they happen.

This category covers runtime security tools that protect your containers and nodes while they're running. Unlike scanning tools (which check images before deployment), these tools observe actual system behavior — monitoring syscalls, enforcing mandatory access control, and detecting suspicious activity in real time. They're the last line of defense when everything else has failed.

## Tools

| Tool | Purpose | Guide |
|------|---------|-------|
| **Falco** | Cloud-native runtime threat detection — real-time syscall monitoring with custom rules, integrates with Kubernetes audit logs | [falco.md](falco.md) |
| **Tetragon** | eBPF-based security observability — kernel-level syscall tracing, process lifecycle monitoring, network events, enforcement | [tetragon.md](tetragon.md) |
| **AppArmor** | Linux mandatory access control — per-program security profiles restricting file access, capabilities, network, and mount operations | [apparmor.md](apparmor.md) |
| **Seccomp** | System call filtering — whitelist or blacklist syscalls for containers, reduces kernel attack surface, used by Docker and Kubernetes | [seccomp.md](seccomp.md) |

## What You'll Learn

- Deploy Falco with custom rules for detecting container escapes and crypto mining
- Use Tetragon for eBPF-based process monitoring and network enforcement
- Write AppArmor profiles that restrict container capabilities
- Create Seccomp profiles to whitelist only necessary syscalls
- Integrate runtime alerts with Alertmanager and Slack
- Build defense-in-depth: AppArmor + Seccomp + Falco + Tetragon layered

## Prerequisites

- Running k3s cluster (from Category 01)
- Linux kernel 4.18+ (for eBPF/Tetragon), 5.4+ recommended
- Understanding of Linux syscalls, capabilities, and security namespaces
- Root access for deploying runtime security tools

## Difficulty

**Advanced** — Runtime security requires deep Linux kernel knowledge; AppArmor and Seccomp profiles demand understanding of per-application syscall needs.

## Learning Path

```
Seccomp (baseline syscall filtering) → AppArmor (mandatory access control)
→ Falco (runtime threat detection) → Tetragon (eBPF observability)
→ Combined defense-in-depth → Custom rule development
```
