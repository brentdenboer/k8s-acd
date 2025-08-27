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

# --- Provider Configuration ---
# This section configures the providers to interact with the
# Kubernetes cluster that was just created by the hetzner-k8s-cluster module.

locals {
  kubeconfig = yamldecode(var.kubeconfig_raw)
  cluster    = local.kubeconfig.clusters[0].cluster
  user       = local.kubeconfig.users[0].user
}

provider "kubernetes" {
  host = local.cluster.server
  cluster_ca_certificate = base64decode(
    local.cluster["certificate-authority-data"]
  )
  client_certificate = base64decode(local.user["client-certificate-data"])
  client_key         = base64decode(local.user["client-key-data"])
}

provider "helm" {
  kubernetes {
    host = local.cluster.server
    cluster_ca_certificate = base64decode(
      local.cluster["certificate-authority-data"]
    )
    client_certificate = base64decode(local.user["client-certificate-data"])
    client_key         = base64decode(local.user["client-key-data"])
  }
}

# --- Step 1: Install ArgoCD ---
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.3.1"

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        # This makes it easier to access the UI initially.
        # For production, you would configure proper ingress and TLS.
        extraArgs = ["--insecure"]
      }
    })
  ]

  timeout = 600
}

# --- Step 2: Deploy the Root Application ---
# This Application tells ArgoCD to manage itself by syncing with your gitops-config repo.
resource "kubernetes_manifest" "root_app" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"       = "root"
      "namespace"  = "argocd"
      "finalizers" = ["resources-finalizer.argocd.argoproj.io"]
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = var.gitops_repo_url
        "targetRevision" = "HEAD"
        "path"           = "bootstrap" # Assumes your root app-of-apps is in this path
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
}
