terraform {
  # Defines where Terraform stores the state file.
  # Using Terraform Cloud is a good practice for collaboration and security.
  cloud {
    organization = "brentdenboer" # Replace with your TFC organization
    workspaces {
      name = "infra-live-main"
    }
  }
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
}

# --- Module to Bootstrap ArgoCD on the New Cluster ---
module "argocd-bootstrap" {
  source = "./modules/argocd-bootstrap"

  # Pass the kubeconfig from the newly created cluster
  kubeconfig_raw = module.hetzner-k8s-cluster.kubeconfig

  gitops_repo_url = var.gitops_repo_url
  cluster_name    = var.cluster_name

  # Ensure the cluster exists before trying to bootstrap it
  depends_on = [module.hetzner-k8s-cluster]
}
