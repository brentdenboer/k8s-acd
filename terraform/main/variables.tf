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

variable "firewall_ssh_source_ip" {
  description = "IP address allowed to access SSH"
  type        = string
  sensitive   = true
}
