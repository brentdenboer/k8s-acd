module "hetzner-k8s-cluster" {
  source = "../../modules/hetzner-k8s-cluster"

  hcloud_token = var.hcloud_token
  cluster_name = "prod-eu-1"

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = [{
    name        = "cp",
    server_type = "cax11",
    location    = "nbg1",
    count       = 3,
    labels      = [],
    taints      = []
  }]
  agent_nodepools = [{
    name        = "agent",
    server_type = "cax11",
    location    = "nbg1",
    count       = 3
  }]
}

module "argocd-bootstrap" {
  source = "../../modules/argocd-bootstrap"

  is_management_cluster = true

  kubeconfig_raw  = module.hetzner-k8s-cluster.kubeconfig
  gitops_repo_url = "https://github.com/brentdenboer/gitops-config.git"
  cluster_name    = "prod-eu-1"
  environment     = "mgmt"
  region          = "eu-1"
}
