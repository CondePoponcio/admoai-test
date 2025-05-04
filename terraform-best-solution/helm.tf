resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.3.6"
  namespace        = "argocd"
  create_namespace = true

  values = [
    <<EOF
server:
  extraArgs: ["--insecure"]
EOF
  ]


  set {
    name  = "imageUpdater.enabled"
    value = "true"
  }
  set {
    name  = "imageUpdater.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "imageUpdater.serviceAccount.name"
    value = "argocd-image-updater"
  }
  set {
    name  = "imageUpdater.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.argocd_image_updater.arn
  }

  depends_on = [
    aws_eks_cluster.k8s,
    aws_eks_node_group.workers,
  ]
}
