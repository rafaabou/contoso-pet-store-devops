# ============================================
# PC2 Variables (i3 - worker2)
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

variable "pc2_worker2_ip" {
  description = "Worker 2 static IP"
  type        = string
  default     = "10.195.95.82"
}

variable "pc2_worker_cpu" {
  description = "PC2 Worker CPU cores"
  type        = number
  default     = 2
}

variable "pc2_worker_memory" {
  description = "PC2 Worker RAM"
  type        = string
  default     = "4GB"
}

variable "pc2_sonarqube_ip" {
  description = "SonarQube static IP (PC2 bridge subnet)"
  type        = string
  default     = "10.195.95.220"
}

variable "pc2_sonarqube_cpu" {
  description = "PC2 SonarQube CPU cores"
  type        = number
  default     = 2
}

variable "pc2_sonarqube_memory" {
  # 3072MB = 3GiB. Raised 2026-09-10: 2.5GB left ~214MB free with plugin
  # loaded (login page spinner/blank while API answered in 0.15s). Integer MB:
  # older Incus (PC2) rejects fractional "2.5GB" (ERROR 74). PC2 has room.
  description = "PC2 SonarQube RAM (SQ + Elasticsearch + PostgreSQL + auth plugin)"
  type        = string
  default     = "3072MB"
}

# ---- Forgejo CI (TASK-262) ----
# Measured PC2 2026-09-09: 11Gi total, ~8.6Gi available. 4GB + 3GB = 7GB
# committed, ~1.6GB spare. PC1 untouched (3.6Gi avail, apps incoming).

variable "pc2_forgejo_ip" {
  description = "Forgejo CI static IP (PC2 bridge subnet)"
  type        = string
  default     = "10.195.95.221"
}

variable "pc2_forgejo_cpu" {
  description = "PC2 Forgejo CPU cores (server sips; builds run on runners)"
  type        = number
  default     = 2
}

variable "pc2_forgejo_memory" {
  description = "PC2 Forgejo RAM (binary + SQLite + ci-light runner)"
  type        = string
  default     = "4GB"
}

variable "pc2_runner_ip" {
  description = "CI heavy runner static IP (PC2 bridge subnet)"
  type        = string
  default     = "10.195.95.222"
}

variable "pc2_runner_cpu" {
  description = "PC2 runner CPU cores (Rust/Node builds)"
  type        = number
  default     = 2
}

variable "pc2_runner_memory" {
  description = "PC2 runner RAM (host-exec jobs spike during builds)"
  type        = string
  default     = "3GB"
}
