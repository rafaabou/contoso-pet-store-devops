# OpenTofu Project Reference

## Our Project Structure

```
ansible-opentofu/terraform/
├── providers.tf          ← Incus provider (lxc/incus ~> 1.1.0)
├── variables.tf          ← 17 variables (prefix, IPs, CPU, RAM, etc.)
├── pc1/
│   ├── main.tf           ← Creates k3s-master + k3s-worker-1
│   └── outputs.tf        ← Shows master/worker names and IPs
└── pc2/
    ├── main.tf           ← Creates k3s-worker-2
    └── outputs.tf        ← Shows worker-2 name and IP
```

---

## Variables Reference

| Variable | Default | Used In |
|----------|---------|---------|
| `prefix` | `k3s` | pc1/main.tf, pc2/main.tf |
| `image` | `ubuntu-noble` | pc1/main.tf, pc2/main.tf |
| `k3s_version` | `v1.36.4+k3s1` | Ansible (Phase 6) |
| `pc1_master_ip` | `10.195.94.80` | pc1/main.tf |
| `pc1_worker1_ip` | `10.195.94.81` | pc1/main.tf |
| `pc1_master_cpu` | `4` | pc1/main.tf |
| `pc1_master_memory` | `4GB` | pc1/main.tf |
| `pc1_worker_cpu` | `3` | pc1/main.tf |
| `pc1_worker_memory` | `4GB` | pc1/main.tf |
| `pc2_worker2_ip` | `10.195.94.82` | pc2/main.tf |
| `pc2_worker_cpu` | `2` | pc2/main.tf |
| `pc2_worker_memory` | `4GB` | pc2/main.tf |
| `gateway` | `10.195.94.1` | Ansible |
| `dns` | `1.1.1.1` | Ansible |
| `metallb_pool` | `10.195.94.100-150` | Ansible |
| `domain` | `devops-devsecops.kdns.fr` | Ansible |
| `letsencrypt_email` | `rafaabou@proton.me` | Ansible |

---

## Containers Created

| Container | PC | IP | CPU | RAM |
|-----------|----|----|-----|-----|
| `k3s-master` | PC1 | 10.195.94.80 | 4 | 4GB |
| `k3s-worker-1` | PC1 | 10.195.94.81 | 3 | 4GB |
| `k3s-worker-2` | PC2 | 10.195.94.82 | 2 | 4GB |

---

## Container Configuration

### k3s-master (PC1)

```hcl
resource "incus_instance" "master" {
  name  = "k3s-master"
  image = "ubuntu-noble"

  config = {
    "limits.cpu"           = "4"
    "limits.memory"        = "4GB"
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
      "ipv4.address" = "10.195.94.80"
    }
  }
}
```

### k3s-worker-1 (PC1)

```hcl
resource "incus_instance" "worker1" {
  name  = "k3s-worker-1"
  image = "ubuntu-noble"

  config = {
    "limits.cpu"           = "3"
    "limits.memory"        = "4GB"
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
      "ipv4.address" = "10.195.94.81"
    }
  }
}
```

### k3s-worker-2 (PC2)

```hcl
resource "incus_instance" "worker2" {
  name  = "k3s-worker-2"
  image = "ubuntu-noble"

  config = {
    "limits.cpu"           = "2"
    "limits.memory"        = "4GB"
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
      "ipv4.address" = "10.195.94.82"
    }
  }
}
```

---

## Commands for Our Project

### PC1

```bash
cd ansible-opentofu/terraform/pc1
tofu init
tofu plan
tofu apply -auto-approve
```

### PC2

```bash
cd ansible-opentofu/terraform/pc2
tofu init
tofu plan
tofu apply -auto-approve
```

### Verify

```bash
incus list
incus exec k3s-master -- hostname
incus exec k3s-worker-1 -- hostname
incus exec k3s-worker-2 -- hostname
```

### Destroy

```bash
# PC1
cd ansible-opentofu/terraform/pc1
tofu destroy -auto-approve

# PC2
cd ansible-opentofu/terraform/pc2
tofu destroy -auto-approve
```

---

## Why These Settings?

| Setting | Value | Why |
|---------|-------|-----|
| `security.nesting` | `true` | K3s needs to run containers inside containers |
| `security.privileged` | `true` | K3s needs full access to host resources |
| `boot.autostart` | `true` | Containers start when PC boots |
| `linux.kernel_modules` | `ip_tables,...` | K3s needs these kernel modules for networking |
| `nictype` | `bridged` | Containers share PC's network |
| `parent` | `incusbr0` | Use the default Incus bridge |
