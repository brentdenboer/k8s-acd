output "kubeconfig" {
  description = "Kubeconfig file content for the newly created cluster. This is used to bootstrap ArgoCD."
  value       = module.kube-hetzner.kubeconfig
  sensitive   = true
}
