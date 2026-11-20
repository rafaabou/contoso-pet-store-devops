# ============================================
# PC1 Variables (antix - master + worker1)
# ============================================

variable "prefix" {
  description = "Cluster name prefix"
  type        = string
  default     = "k3s"
}

variable "image" {
  description = "Incus image alias"
  type        = string
  default     = "ubuntu-noble"
}

variable "pc1_master_ip" {
  description = "Master node static IP on PC1"
  type        = string
  default     = "10.195.94.80"
}

variable "pc1_worker1_ip" {
  description = "Worker1 static IP on PC1"
  type        = string
  default     = "10.195.94.81"
}

variable "pc1_master_cpu" {
  description = "Master CPU cores"
  type        = number
  default     = 4
}

variable "pc1_master_memory" {
  description = "Master RAM"
  type        = string
  default     = "4GB"
}

variable "pc1_worker_cpu" {
  description = "Worker CPU cores"
  type        = number
  default     = 3
}

variable "pc1_worker_memory" {
  description = "Worker RAM"
  type        = string
  default     = "4GB"
}

# ============================================
# Vault Server Configuration
# ============================================

variable "vault_server_ip" {
  description = "Vault server static IP"
  type        = string
  default     = "10.195.94.200"
}

variable "vault_server_cpu" {
  description = "Vault server CPU cores"
  type        = number
  default     = 2
}

variable "vault_server_memory" {
  # Trimmed 2GB -> 750MB 2026-09-09 (TASK-262 step 0): live use ~108MB,
  # Go spikes peak ~350MB. Floor 512MB (OOM = sealed Vault). Live apply.
  description = "Vault server RAM"
  type        = string
  default     = "750MB"
}

# ============================================
# Monitoring Server Configuration
# ============================================

variable "monitoring_server_ip" {
  description = "Monitoring server static IP"
  type        = string
  default     = "10.195.94.210"
}

variable "monitoring_server_cpu" {
  description = "Monitoring server CPU cores"
  type        = number
  default     = 2
}

variable "monitoring_server_memory" {
  description = "Monitoring server RAM"
  type        = string
  default     = "4GB"
}
