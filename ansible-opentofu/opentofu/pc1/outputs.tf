# ============================================
# PC1 Outputs
# ============================================

output "master_name" {
  value = incus_instance.master.name
}

output "master_ip" {
  value = incus_instance.master.ipv4_address
}

output "worker1_name" {
  value = incus_instance.worker1.name
}

output "worker1_ip" {
  value = incus_instance.worker1.ipv4_address
}

output "vault_name" {
  value = incus_instance.vault.name
}

output "vault_ip" {
  value = incus_instance.vault.ipv4_address
}

output "monitoring_name" {
  value = incus_instance.monitoring.name
}

output "monitoring_ip" {
  value = incus_instance.monitoring.ipv4_address
}

output "cluster_nodes" {
  value = {
    master     = incus_instance.master.ipv4_address
    worker1    = incus_instance.worker1.ipv4_address
    vault      = incus_instance.vault.ipv4_address
    monitoring = incus_instance.monitoring.ipv4_address
  }
}
