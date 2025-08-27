# --- Provider Credentials ---
variable "hcloud_token" {
  description = "Hetzner Cloud API token."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "The content of the SSH public key for node access."
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "The content of the SSH private key for node access."
  type        = string
  sensitive   = true
}

# --- Cluster Configuration ---
variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
  default     = "prod-eu-1"
}

variable "control_plane_nodepools" {
  description = "A list of objects defining the control plane node pools."
  type        = any # Using 'any' for simplicity in this example
  default = [{
    name        = "cp"
    server_type = "cax11"
    location    = "nbg1"
    count       = 3
  }]
}

variable "agent_nodepools" {
  description = "A list of objects defining the agent node pools."
  type        = any # Using 'any' for simplicity in this example
  default = [{
    name        = "agent"
    server_type = "cpx21"
    location    = "nbg1"
    count       = 3
  }]
}

# --- ArgoCD Configuration ---
variable "gitops_repo_url" {
  description = "The URL of the gitops-config repository."
  type        = string
  default     = "https://github.com/brentdenboer/gitops-config.git"
}
