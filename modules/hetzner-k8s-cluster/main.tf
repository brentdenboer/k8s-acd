terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.52.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "kube-hetzner" {
  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.18.1"

  hcloud_token = var.hcloud_token
  cluster_name = var.cluster_name

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = var.control_plane_nodepools
  agent_nodepools         = var.agent_nodepools

  network_region            = "eu-central"
  load_balancer_type        = "lb11"
  load_balancer_location    = "nbg1"
  automatically_upgrade_k3s = true
  automatically_upgrade_os  = true
}
