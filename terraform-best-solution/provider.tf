terraform {
  required_version = ">= 1.11.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Project     = var.cluster_name
      },
      var.extra_tags
    )
  }
}

data "aws_availability_zones" "available" {}

provider "kubernetes" {
  host                   = aws_eks_cluster.k8s.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.k8s.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.k8s.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.k8s.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.k8s.token
  }
}
