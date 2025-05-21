module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  source = "kube-hetzner/kube-hetzner/hcloud"

  ssh_public_key = var.ssh_public_key
  ssh_private_key = var.ssh_private_key
  hcloud_ssh_key_id = var.hcloud_ssh_key_id

  ssh_additional_public_keys = [var.ssh_additional_public_keys]

  network_region = "eu-central"

  control_plane_nodepools = [
    {
      name        = "cp",
      server_type = "cax11",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 1
    },
  ]

  agent_nodepools = [
    {
      name        = "agent",
      server_type = "cax11",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 1
    },
  ]

  load_balancer_type     = "lb11"
  load_balancer_location = "nbg1"

  enable_longhorn     = false
  disable_hetzner_csi = false

  ingress_controller = "none"

  hetzner_ccm_use_helm = true
  enable_klipper_metal_lb = "true"
  automatically_upgrade_k3s = false
  system_upgrade_use_drain = true
  system_upgrade_enable_eviction = false
  automatically_upgrade_os = false

  initial_k3s_channel = "v1.32"

  cluster_name = "k8s-acd-main"

  firewall_kube_api_source = null
  # firewall_ssh_source = [var.firewall_ssh_source_ip]

  extra_firewall_rules = [
    {
      description = "To Allow ArgoCD access to resources via SSH"
      direction       = "out"
      protocol        = "tcp"
      port            = "22"
      source_ips      = []
      destination_ips = ["0.0.0.0/0", "::/0"]
    }
  ]

  cni_plugin = "cilium"

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig = false
  export_values = false
}

provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.49.1"
    }
  }

  cloud {
    organization = "brentdenboer"

    workspaces {
      name = "k8s-acd"
    }
  }
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}
