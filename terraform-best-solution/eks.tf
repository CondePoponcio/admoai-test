resource "aws_eks_cluster" "k8s" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.cluster_name
  }
}

data "aws_eks_cluster_auth" "k8s" {
  name = aws_eks_cluster.k8s.name
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.k8s.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_capacity
    max_size     = var.node_max_capacity
  }

  instance_types = [var.node_instance_type]

  tags = {
    Name        = "${var.cluster_name}-workers"
    Environment = var.environment
    Project     = var.cluster_name
  }
}
