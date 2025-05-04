resource "aws_ecr_repository" "app" {
  name                 = var.application_name
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Environment = var.environment
    Project     = var.cluster_name
  }
}
