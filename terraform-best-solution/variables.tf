variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devops-demo-cluster"
}

variable "extra_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_suffixes" {
  description = "Suffix indices for public subnets"
  type        = list(number)
  default     = [0, 1]
}

variable "private_subnet_suffixes" {
  description = "Suffix indices for private subnets"
  type        = list(number)
  default     = [2, 3]
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}


# Settings for CICD

variable "application_name" {
  description = "Nombre del repositorio ECR"
  type        = string
}

variable "repo_owner" {
  description = "Owner/organización del repo de GitHub"
  type        = string
}

variable "repo_name" {
  description = "Nombre del repo de GitHub"
  type        = string
}

variable "repo_branch" {
  description = "Rama de GitHub que usará OIDC (p.ej. main)"
  type        = string
  default     = "main"
}
