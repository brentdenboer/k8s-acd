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
  description = "The name of the cluster, used for cosmetic purposes."
  type        = string
}
