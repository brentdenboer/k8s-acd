variable "hcloud_token" {
  description = "Hetzner Cloud API token."
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9\\-]+$", var.cluster_name))
    error_message = "The cluster name must be in the form of lowercase alphanumeric characters and/or dashes."
  }
}

variable "ssh_public_key" {
  description = "The content of the SSH public key for node access."
  type        = string
}

variable "ssh_private_key" {
  description = "The content of the SSH private key for node access."
  type        = string
  sensitive   = true
}

variable "control_plane_nodepools" {
  description = "A list of objects defining the control plane node pools."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    labels      = list(string)
    taints      = list(string)
    count       = number
  }))
  default = []
  validation {
    condition = length(
      [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      ) == length(
      distinct(
        [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      )
    )
    error_message = "Names in control_plane_nodepools must be unique."
  }
}

variable "agent_nodepools" {
  description = "A list of objects defining the agent node pools."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    labels      = list(string)
    taints      = list(string)
    count       = optional(number, null)
  }))
  default = []

  validation {
    condition = length(
      [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      ) == length(
      distinct(
        [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      )
    )
    error_message = "Names in agent_nodepools must be unique."
  }
}
