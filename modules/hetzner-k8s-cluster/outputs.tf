output "kubeconfig" {
  description = "Kubeconfig file content for the cluster."
  value       = module.kube-hetzner.kubeconfig
  sensitive   = true
}
