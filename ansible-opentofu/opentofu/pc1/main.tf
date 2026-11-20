# ============================================
# PC1: antix (master + worker1)
# Run this on PC1 only
# ============================================

# ---- Master Node ----

resource "incus_instance" "master" {
  name  = "${var.prefix}-master"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.pc1_master_cpu
    "limits.memory"        = var.pc1_master_memory
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

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "80GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc1_master_ip
    }
  }

  # External HDD partitions for NFS/EFS storage
  device {
    name = "efs-shared"
    type = "disk"
    properties = {
      path   = "/srv/efs/shared"
      source = "/srv/efs/shared"
    }
  }

  device {
    name = "efs-volumes"
    type = "disk"
    properties = {
      path   = "/srv/efs/k3s-volumes"
      source = "/srv/efs/k3s-volumes"
    }
  }

  device {
    name = "efs-backups"
    type = "disk"
    properties = {
      path   = "/srv/efs/backups"
      source = "/srv/efs/backups"
    }
  }

  device {
    name = "efs-logs"
    type = "disk"
    properties = {
      path   = "/srv/efs/logs"
      source = "/srv/efs/logs"
    }
  }

  # NVMe partitions for S3/RDS
  device {
    name = "s3-data"
    type = "disk"
    properties = {
      path   = "/srv/s3-data"
      source = "/srv/s3-data"
    }
  }
}

# ---- Worker 1 (same PC as master) ----

resource "incus_instance" "worker1" {
  name  = "${var.prefix}-worker-1"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.pc1_worker_cpu
    "limits.memory"        = var.pc1_worker_memory
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

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "10GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.pc1_worker1_ip
    }
  }
}

# ---- Vault Server (standalone) ----

resource "incus_instance" "vault" {
  name  = "${var.prefix}-vault"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.vault_server_cpu
    "limits.memory"        = var.vault_server_memory
    "security.nesting"     = "true"
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
      runcmd:
        - [systemctl, daemon-reload]
        - [systemctl, enable, --now, dev-kmsg.service]
    EOT
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "10GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.vault_server_ip
    }
  }

  # Shared storage via host paths (unprivileged: can't NFS mount)
  device {
    name = "efs-shared"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/shared"
      source = "/srv/efs/shared"
    }
  }

  device {
    name = "efs-backups"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/backups"
      source = "/srv/efs/backups"
    }
  }

  device {
    name = "efs-logs"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/logs"
      source = "/srv/efs/logs"
    }
  }
}

# ---- Monitoring Server (standalone) ----

resource "incus_instance" "monitoring" {
  name  = "${var.prefix}-monitoring"
  image = var.image

  lifecycle {
    ignore_changes = [image]
  }

  config = {
    "limits.cpu"           = var.monitoring_server_cpu
    "limits.memory"        = var.monitoring_server_memory
    "security.nesting"     = "true"
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
      runcmd:
        - [systemctl, daemon-reload]
        - [systemctl, enable, --now, dev-kmsg.service]
    EOT
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "40GB"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype        = "bridged"
      parent         = "incusbr0"
      "ipv4.address" = var.monitoring_server_ip
    }
  }

  # Shared storage via host paths (unprivileged: can't NFS mount)
  device {
    name = "efs-shared"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/shared"
      source = "/srv/efs/shared"
    }
  }

  device {
    name = "efs-backups"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/backups"
      source = "/srv/efs/backups"
    }
  }

  device {
    name = "efs-logs"
    type = "disk"
    properties = {
      path   = "/mnt/nfs/logs"
      source = "/srv/efs/logs"
    }
  }
}
