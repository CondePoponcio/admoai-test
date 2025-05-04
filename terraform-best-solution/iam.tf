data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "${var.cluster_name}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_role" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}




# ── IRSA: EKS OIDC Provider ───────────────────────────
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.k8s.name
}

data "tls_certificate" "oidc_thumb" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumb.certificates[0].sha1_fingerprint]
}


# ── IAM Role para Argo CD Image Updater ────────────────
data "aws_iam_policy_document" "argocd_image_updater_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:argocd:argocd-image-updater"]
    }
  }
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "${var.cluster_name}-argocd-image-updater-role"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater_assume.json
}

data "aws_iam_policy_document" "argocd_image_updater_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_role_policy" "argocd_image_updater_ecr" {
  name   = "${var.cluster_name}-argocd-image-updater-ecr"
  role   = aws_iam_role.argocd_image_updater.id
  policy = data.aws_iam_policy_document.argocd_image_updater_ecr.json
}


# ── OIDC provider de GitHub Actions ────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gh_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # 1) Debe coincidir el repositorio y rama
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repo_owner}/${var.repo_name}:ref:refs/heads/${var.repo_branch}"]
    }

    # 2) Debe venir dirigido al público correcto (sts.amazonaws.com)
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-gh-actions-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.gh_assume.json
}

data "aws_iam_policy_document" "gh_ecr" {
  # 1) Permitir always GetAuthorizationToken en "*"
  statement {
    sid    = "AllowECRGetAuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  # 2) Permitir push/pull de imágenes solo en tu repo
  statement {
    sid    = "AllowECRRepoOperations"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [ aws_ecr_repository.app.arn ]
  }
}

resource "aws_iam_role_policy" "github_ecr" {
  name   = "${var.cluster_name}-gh-actions-ecr-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.gh_ecr.json
}
