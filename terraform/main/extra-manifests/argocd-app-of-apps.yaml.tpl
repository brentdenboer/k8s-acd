apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-apps
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: 'https://github.com/brentdenboer/k8s-acd.git'
    targetRevision: main
    path: argocd/platform
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
