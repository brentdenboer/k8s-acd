variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "SSH private key content"
  type        = string
  sensitive   = true
}

variable "hcloud_ssh_key_id" {
  description = "SSH key id in Hetzner Cloud project"
  type        = string
  sensitive   = true
}

variable "ssh_additional_public_keys" {
  description = "Additional SSH public keys (comma separated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_port" {
  description = "SSH port to use for the cluster"
  type        = number
  default     = 22
  sensitive   = true
}
