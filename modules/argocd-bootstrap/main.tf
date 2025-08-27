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
  # Defensive kubeconfig parsing with better error handling
  kubeconfig_raw = var.kubeconfig_raw
  kubeconfig     = yamldecode(local.kubeconfig_raw)

  # Extract cluster info with error handling for different kubeconfig formats
  cluster_info = try(
    local.kubeconfig.clusters[0].cluster,
    local.kubeconfig.clusters.cluster,
    null
  )

  user_info = try(
    local.kubeconfig.users[0].user,
    local.kubeconfig.users.user,
    null
  )

  # Validate that we have the required fields
  cluster_server = try(
    local.cluster_info.server,
    ""
  )

  cluster_ca_data = try(
    local.cluster_info["certificate-authority-data"],
    ""
  )

  client_cert_data = try(
    local.user_info["client-certificate-data"],
    ""
  )

  client_key_data = try(
    local.user_info["client-key-data"],
    ""
  )
}

# Provider to interact with the NEWLY CREATED cluster
provider "kubernetes" {
  alias = "new_cluster"

  host                   = local.cluster_server
  cluster_ca_certificate = local.cluster_ca_data != "" ? base64decode(local.cluster_ca_data) : null
  client_certificate     = local.client_cert_data != "" ? base64decode(local.client_cert_data) : null
  client_key             = local.client_key_data != "" ? base64decode(local.client_key_data) : null
}

provider "helm" {
  alias = "new_cluster"
  kubernetes {
    host                   = local.cluster_server
    cluster_ca_certificate = local.cluster_ca_data != "" ? base64decode(local.cluster_ca_data) : null
    client_certificate     = local.client_cert_data != "" ? base64decode(local.client_cert_data) : null
    client_key             = local.client_key_data != "" ? base64decode(local.client_key_data) : null
  }
}

# --- Step 1: Install ArgoCD ONLY on the management cluster ---
resource "helm_release" "argocd" {
  count = var.is_management_cluster ? 1 : 0

  provider         = helm.new_cluster
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.6.12" # Updated to a more recent version

  # Basic ArgoCD configuration optimized for GitOps
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        config = {
          url = "https://argocd.${var.cluster_name}.local"
        }
      }
      configs = {
        params = {
          "server.insecure" = true # For initial setup - should be changed in production
        }
      }
    })
  ]

  timeout = 600 # 10 minutes timeout for installation
}

# --- Step 2 & 3: Create Service Account and Token (for ALL clusters) ---
resource "kubernetes_service_account" "argocd_manager" {
  provider = kubernetes.new_cluster

  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
    labels = {
      "managed-by" = "terraform"
      "cluster"    = var.cluster_name
    }
  }
}

resource "kubernetes_cluster_role_binding" "argocd_manager_binding" {
  provider = kubernetes.new_cluster

  metadata {
    name = "argocd-manager-admin-binding"
    labels = {
      "managed-by" = "terraform"
      "cluster"    = var.cluster_name
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd_manager.metadata[0].name
    namespace = kubernetes_service_account.argocd_manager.metadata[0].namespace
  }
}

resource "kubernetes_secret" "argocd_manager_token" {
  provider = kubernetes.new_cluster

  metadata {
    name      = "argocd-manager-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.argocd_manager.metadata[0].name
    }
    labels = {
      "managed-by" = "terraform"
      "cluster"    = var.cluster_name
    }
  }

  type = "kubernetes.io/service-account-token"

  # Wait for the service account to be fully created
  depends_on = [kubernetes_service_account.argocd_manager]
}

# --- Step 4: Create the ArgoCD Cluster Secret on the management cluster ---
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
      "type"                           = var.is_management_cluster ? "management" : "workload"
      "managed-by"                     = "terraform"
    }
  }

  data = {
    "name"   = var.cluster_name
    "server" = local.cluster_server
    "config" = jsonencode({
      "bearerToken" = kubernetes_secret.argocd_manager_token.data["token"]
      "tlsClientConfig" = {
        "insecure" = false
        "caData"   = local.cluster_ca_data
      }
    })
  }

  depends_on = [kubernetes_secret.argocd_manager_token]
}

# --- Step 5: Deploy the root Application ONLY on the management cluster ---
resource "kubernetes_manifest" "root_app" {
  count = var.is_management_cluster ? 1 : 0

  provider = kubernetes.new_cluster

  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "root"
      "namespace" = "argocd"
      "labels" = {
        "managed-by" = "terraform"
      }
      "finalizers" = ["resources-finalizer.argocd.argoproj.io"]
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
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
        "syncOptions" = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}
