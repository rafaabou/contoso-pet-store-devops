# ============================================
# PC2 Outputs
# ============================================

output "worker2_name" {
  value = incus_instance.worker2.name
}

output "worker2_ip" {
  value = incus_instance.worker2.ipv4_address
}

output "sonarqube_name" {
  value = incus_instance.sonarqube.name
}

output "sonarqube_ip" {
  value = incus_instance.sonarqube.ipv4_address
}

output "forgejo_ci_name" {
  value = incus_instance.forgejo_ci.name
}

output "forgejo_ci_ip" {
  value = incus_instance.forgejo_ci.ipv4_address
}

output "runner_1_name" {
  value = incus_instance.runner_1.name
}

output "runner_1_ip" {
  value = incus_instance.runner_1.ipv4_address
}
