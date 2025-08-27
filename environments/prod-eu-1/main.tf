# Configure providers first
provider "hcloud" {
  token = var.hcloud_token
}

# Provider for the management cluster
provider "kubernetes" {
  config_path = "~/.kube/config" # Or use the ARGOCD_MANAGEMENT_KUBECONFIG
}

# Provider configurations for the new cluster
provider "kubernetes" {
  alias = "new_cluster"

  host                   = module.hetzner-k8s-cluster.kubeconfig.host
  cluster_ca_certificate = base64decode(module.hetzner-k8s-cluster.kubeconfig.cluster_ca_certificate)
  client_certificate     = base64decode(module.hetzner-k8s-cluster.kubeconfig.client_certificate)
  client_key             = base64decode(module.hetzner-k8s-cluster.kubeconfig.client_key)
}

provider "helm" {
  alias = "new_cluster"
  kubernetes {
    host                   = module.hetzner-k8s-cluster.kubeconfig.host
    cluster_ca_certificate = base64decode(module.hetzner-k8s-cluster.kubeconfig.cluster_ca_certificate)
    client_certificate     = base64decode(module.hetzner-k8s-cluster.kubeconfig.client_certificate)
    client_key             = base64decode(module.hetzner-k8s-cluster.kubeconfig.client_key)
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
