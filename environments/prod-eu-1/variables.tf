variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for cluster node access"
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "SSH private key for cluster node access"
  type        = string
  sensitive   = true
}
