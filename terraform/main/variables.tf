variable "hcloud_token" {
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
}

variable "firewall_ssh_source_ip" {
  type        = string
  description = "IP address allowed to access SSH"
  sensitive   = true
}
