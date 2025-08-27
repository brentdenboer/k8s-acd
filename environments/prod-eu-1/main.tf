terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.52.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
  }
}

# Configure providers
provider "hcloud" {
  token = var.hcloud_token
}

# Provider for the management cluster (using kubeconfig from GitHub secrets)
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Provider for the new cluster - we'll configure this after the cluster is created
provider "kubernetes" {
  alias = "new_cluster"

  host                   = local.kubeconfig_parsed.host
  cluster_ca_certificate = base64decode(local.kubeconfig_parsed.cluster_ca_certificate)
  client_certificate     = base64decode(local.kubeconfig_parsed.client_certificate)
  client_key             = base64decode(local.kubeconfig_parsed.client_key)
}

provider "helm" {
  alias = "new_cluster"
  kubernetes {
    host                   = local.kubeconfig_parsed.host
    cluster_ca_certificate = base64decode(local.kubeconfig_parsed.cluster_ca_certificate)
    client_certificate     = base64decode(local.kubeconfig_parsed.client_certificate)
    client_key             = base64decode(local.kubeconfig_parsed.client_key)
  }
}

# Parse the kubeconfig from the cluster module
locals {
  kubeconfig_raw    = module.hetzner-k8s-cluster.kubeconfig
  kubeconfig_parsed = yamldecode(local.kubeconfig_raw)

  cluster_info = local.kubeconfig_parsed.clusters[0].cluster
  user_info    = local.kubeconfig_parsed.users[0].user

  kubeconfig_formatted = {
    host                   = local.cluster_info.server
    cluster_ca_certificate = local.cluster_info["certificate-authority-data"]
    client_certificate     = local.user_info["client-certificate-data"]
    client_key             = local.user_info["client-key-data"]
  }
}

module "hetzner-k8s-cluster" {
  source = "../../modules/hetzner-k8s-cluster"

  hcloud_token = var.hcloud_token
  cluster_name = "prod-eu-1"

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = [{
    name        = "cp"
    server_type = "cax11"
    location    = "nbg1"
    labels      = []
    taints      = []
    count       = 3
  }]

  agent_nodepools = [{
    name        = "agent"
    server_type = "cax11"
    location    = "nbg1"
    labels      = []
    taints      = []
    count       = 3
  }]
}

module "argocd-bootstrap" {
  source = "../../modules/argocd-bootstrap"

  providers = {
    kubernetes.new_cluster = kubernetes.new_cluster
    helm.new_cluster       = helm.new_cluster
  }

  is_management_cluster = true

  kubeconfig_raw  = module.hetzner-k8s-cluster.kubeconfig
  gitops_repo_url = "https://github.com/brentdenboer/gitops-config.git"
  cluster_name    = "prod-eu-1"
  environment     = "production"
  region          = "eu-1"
}
