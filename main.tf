terraform {
  # Defines where Terraform stores the state file.
  # Using Terraform Cloud is a good practice for collaboration and security.
  cloud {
    organization = "brentdenboer" # Replace with your TFC organization
    workspaces {
      name = "k8s-acd"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# --- Module to Provision the Kubernetes Cluster ---
module "hetzner-k8s-cluster" {
  source = "./modules/hetzner-k8s-cluster"

  hcloud_token = var.hcloud_token
  cluster_name = var.cluster_name

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = var.control_plane_nodepools
  agent_nodepools         = var.agent_nodepools

  providers = {
    hcloud = hcloud
  }
}

# --- Module to Bootstrap ArgoCD on the New Cluster ---
module "argocd-bootstrap" {
  source = "./modules/argocd-bootstrap"

  # Pass the kubeconfig from the newly created cluster
  kubeconfig_raw = module.hetzner-k8s-cluster.kubeconfig

  gitops_repo_url = var.gitops_repo_url
  cluster_name    = var.cluster_name
}
