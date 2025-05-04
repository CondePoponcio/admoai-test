output "cluster_endpoint" {
  description = "API Server endpoint"
  value       = aws_eks_cluster.k8s.endpoint
}

output "cluster_ca" {
  description = "Cluster CA certificate (base64)"
  value       = aws_eks_cluster.k8s.certificate_authority[0].data
}

output "kubeconfig" {
  description = "Kubeconfig"
  value       = <<EOC
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.k8s.endpoint}
    certificate-authority-data: ${aws_eks_cluster.k8s.certificate_authority[0].data}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: aws
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${var.cluster_name}
EOC
}

output "argocd_server_url" {
  description = "Argo CD URL (port-forward)"
  value       = "http://localhost:8080"
}





# CI/CD Credentials
output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.app.repository_url
}
output "github_actions_ecr_role_arn" {
  description = "ARN del Role que asume GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

# Argo CD Image Updater
output "argocd_image_updater_role_arn" {
  description = "ARN del Role para Argo CD Image Updater"
  value       = aws_iam_role.argocd_image_updater.arn
}

# OIDC Providers
output "eks_oidc_provider_arn" {
  description = "ARN del OIDC Provider de EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}
output "github_oidc_provider_arn" {
  description = "ARN del OIDC Provider de GitHub"
  value       = aws_iam_openid_connect_provider.github.arn
}
