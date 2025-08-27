terraform {
  required_providers {
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

locals {
  kubeconfig = yamldecode(var.kubeconfig_raw)
}

# Provider to interact with the NEWLY CREATED cluster
provider "kubernetes" {
  alias                  = "new_cluster"
  host                   = local.kubeconfig.clusters.cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig.users.user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig.users.user["client-key-data"])
}

provider "helm" {
  alias = "new_cluster"
  kubernetes {
    host                   = local.kubeconfig.clusters.cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters.cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig.users.user["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig.users.user["client-key-data"])
  }
}

# --- Step 1: Install ArgoCD ONLY on the management cluster ---
# UPDATED: The 'count' meta-argument makes this resource conditional.
resource "helm_release" "argocd" {
  count = var.is_management_cluster ? 1 : 0

  provider         = helm.new_cluster
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.4"
}

# --- Step 2 & 3: Create Service Account and Token (for ALL clusters) ---
# This logic is required for every cluster so the management cluster can connect to it.
resource "kubernetes_service_account" "argocd_manager" {
  provider = kubernetes.new_cluster
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "argocd_manager_binding" {
  provider = kubernetes.new_cluster
  metadata {
    name = "argocd-manager-admin-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd_manager.metadata.0.name
    namespace = kubernetes_service_account.argocd_manager.metadata.0.namespace
  }
}

resource "kubernetes_secret" "argocd_manager_token" {
  provider = kubernetes.new_cluster
  metadata {
    name      = "argocd-manager-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.argocd_manager.metadata.0.name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# --- Step 4: Create the ArgoCD Cluster Secret on the management cluster ---
# This resource ALWAYS runs, creating a secret on the management cluster
# that points to the newly created cluster (which could be itself or a workload cluster).
resource "kubernetes_secret" "argocd_cluster_secret" {
  provider = kubernetes # Uses the default provider, authenticated to the management cluster
  metadata {
    name      = "cluster-${var.cluster_name}"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "environment"                    = var.environment
      "region"                         = var.region
      "cloud"                          = "hetzner"
      "type"                           = "workload"
    }
  }
  data = {
    "name"   = var.cluster_name
    "server" = local.kubeconfig.clusters.cluster.server
    "config" = jsonencode({
      "bearerToken" = kubernetes_secret.argocd_manager_token.data.token
      "tlsClientConfig" = {
        "insecure" = false
        "caData"   = local.kubeconfig.clusters.cluster["certificate-authority-data"]
      }
    })
  }
}

# --- Step 5: Deploy the root Application ONLY on the management cluster ---
# UPDATED: This is also now conditional.
resource "kubernetes_manifest" "root_app" {
  count = var.is_management_cluster ? 1 : 0

  provider = kubernetes.new_cluster
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "root"
      "namespace" = "argocd"
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = var.gitops_repo_url
        "targetRevision" = "HEAD"
        "path"           = "bootstrap"
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "argocd"
      }
      "syncPolicy" = { "automated" = { "prune" = true, "selfHeal" = true } }
    }
  }
  depends_on = [helm_release.argocd]
}
