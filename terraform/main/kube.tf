module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token

  source = "kube-hetzner/kube-hetzner/hcloud"

  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  hcloud_ssh_key_id          = var.hcloud_ssh_key_id
  ssh_additional_public_keys = [var.ssh_additional_public_keys]
  ssh_port                   = var.ssh_port

  network_region = "eu-central"

  control_plane_nodepools = [
    {
      name        = "cp",
      server_type = "cax11",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 3
    },
  ]

  agent_nodepools = [
    {
      name        = "agent",
      server_type = "cax11",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 3
    },
  ]

  load_balancer_type     = "lb11"
  load_balancer_location = "nbg1"

  hetzner_ccm_use_helm           = true
  automatically_upgrade_k3s      = true
  automatically_upgrade_os       = true

  cluster_name = "k8s-acd-main"

  firewall_kube_api_source = null

  extra_firewall_rules = [
    {
      description     = "To Allow ArgoCD access to resources via SSH"
      direction       = "out"
      protocol        = "tcp"
      port            = "22"
      source_ips      = []
      destination_ips = ["0.0.0.0/0", "::/0"]
    }
  ]

  enable_cert_manager = true

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig = false
  export_values     = false

  extra_kustomize_deployment_commands = <<-EOT
    echo "Waiting for ArgoCD CRDs to be established..."
    kubectl -n argocd wait --for condition=established --timeout=180s crd/applications.argoproj.io
    kubectl -n argocd wait --for condition=established --timeout=180s crd/appprojects.argoproj.io
    echo "ArgoCD CRDs are ready. Applying initial AppProject and App-of-Apps..."
    kubectl apply -f /var/user_kustomize/1-argocd-project.yaml
    kubectl apply -f /var/user_kustomize/2-argocd-app-of-apps.yaml
  EOT
}

provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_version = ">= 1.12.1"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51.0"
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
