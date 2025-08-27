# This file acts as a wrapper around the public kube-hetzner module,
# simplifying its configuration for our specific use case.

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51.0"
    }
  }
}

module "kube-hetzner" {
  # Use the official module from the Terraform Registry
  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.18.1" # Pinning to a specific version for stability

  providers = {
    hcloud = hcloud
  }

  # --- Pass-through Variables ---
  hcloud_token = var.hcloud_token
  cluster_name = var.cluster_name

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = var.control_plane_nodepools
  agent_nodepools         = var.agent_nodepools

  # --- Hardcoded Defaults for Simplicity ---
  network_region            = "eu-central"
  load_balancer_type        = "lb11"
  load_balancer_location    = "nbg1" # Or fsn1, hel1
  automatically_upgrade_k3s = true
  automatically_upgrade_os  = true
}
