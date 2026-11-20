# ============================================
# PC2: i3 worker (worker2)
# Run this on PC2 only
# ============================================

# ---- Worker 2 ----

resource "incus_instance" "worker2" {
  name  = "${var.prefix}-worker-2"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.pc2_worker_cpu
    "limits.memory"        = var.pc2_worker_memory
    "security.nesting"     = "true"
    "security.privileged"  = "true"
    "boot.autostart"       = "true"
    "linux.kernel_modules" = "ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter,overlay"
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      write_files:
        - path: /etc/systemd/system/dev-kmsg.service
          content: |
            [Unit]
            Description=Symlink /dev/kmsg to /dev/console
            DefaultDependencies=no
            Before=local-fs.target
            [Service]
            Type=oneshot
            ExecStart=/bin/ln -sf /dev/console /dev/kmsg
            RemainAfterExit=yes
            [Install]
            WantedBy=sysinit.target
        - path: /etc/systemd/system/proc-sys-rw.service
          content: |
            [Unit]
            Description=Remount /proc/sys read-write for kubelet
            DefaultDependencies=no
            Before=k3s.service k3s-agent.service
            After=local-fs.target
            [Service]
            Type=oneshot
            ExecStart=/bin/mount -o remount,rw /proc/sys
            RemainAfterExit=yes
            [Install]
            WantedBy=multi-user.target
      runcmd:
        - [systemctl, daemon-reload]
        - [systemctl, enable, --now, dev-kmsg.service]
        - [systemctl, enable, --now, proc-sys-rw.service]
    EOT
  }

  # NOTE: no explicit root device — worker2's root disk comes from the
  # default profile. Adding one with pool= fails: Incus refuses to rewrite
  # the existing device's pool (ERROR 74).
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

# ---- SonarQube Server (migrated from PC1, 2026-09-09) ----
# Blue-green: PC1 k3s-sonarqube stays up until this one serves traffic.
# Needs Tailscale inside (ansible_host = its 100.x IP, PC2 bridge is
# invisible from PC1) + SSH keys, same as k3s-worker-2 pattern.
# Postgres data fresh on root disk (old DB was virgin); privileged for
# postgres chown + Elasticsearch vm.max_map_count sysctl.

resource "incus_instance" "sonarqube" {
  name  = "${var.prefix}-sonarqube"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.pc2_sonarqube_cpu
    "limits.memory"        = var.pc2_sonarqube_memory
    "security.nesting"     = "true"
    "security.privileged"  = "true"
    "boot.autostart"       = "true"
    "linux.kernel_modules" = "ip_tables,ip6_tables,iptable_nat,iptable_filter,ip6table_nat,nf_tables,br_netfilter,overlay"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "20GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc2_sonarqube_ip
    }
  }
}

# ---- Forgejo CI server (TASK-262) ----
# Forgejo 16.0.3 binary + SQLite + ci-light runner on the box.
# Privileged (git chown + runner job processes); Tailscale inside for
# PC1 reachability (PC2 bridge invisible from PC1) — record its 100.x
# IP in inventory after first boot, same as sonarqube pattern.

resource "incus_instance" "forgejo_ci" {
  name  = "${var.prefix}-forgejo-ci"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"          = var.pc2_forgejo_cpu
    "limits.memory"       = var.pc2_forgejo_memory
    "security.nesting"    = "true"
    "security.privileged" = "true"
    "boot.autostart"      = "true"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "30GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc2_forgejo_ip
    }
  }
}

# ---- CI heavy runner (TASK-262) ----
# ci-heavy label (Rust/Node builds, Trivy, image pushes). Unprivileged:
# host-exec runner needs no container nesting. Tailscale inside, same as above.

resource "incus_instance" "runner_1" {
  name  = "${var.prefix}-runner-1"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"          = var.pc2_runner_cpu
    "limits.memory"       = var.pc2_runner_memory
    "security.nesting"    = "true"
    "security.privileged" = "false"
    "boot.autostart"      = "true"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "20GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc2_runner_ip
    }
  }
}
