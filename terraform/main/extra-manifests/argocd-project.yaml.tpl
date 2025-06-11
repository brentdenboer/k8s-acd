apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: Project for core platform services (ArgoCD, cert-manager, etc.)
  sourceRepos:
  - '*'
  destinations:
  - server: https://kubernetes.default.svc
    namespace: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
