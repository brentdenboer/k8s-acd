variable "is_management_cluster" {
  description = "If true, this cluster will be designated as the management cluster and have ArgoCD installed on it."
  type        = bool
  default     = false
}

variable "kubeconfig_raw" {
  description = "The raw kubeconfig string of the newly created cluster."
  type        = string
  sensitive   = true
}

variable "gitops_repo_url" {
  description = "The URL of the gitops-config repository."
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster being bootstrapped."
  type        = string
}

variable "environment" {
  description = "The environment of the cluster (e.g., 'dev', 'prod')."
  type        = string
}

variable "region" {
  description = "The region of the cluster (e.g., 'eu-1', 'us-1')."
  type        = string
}
