aws_region              = "us-west-2"
environment             = "dev"
cluster_name            = "admoai-devops-demo-cluster"
extra_tags              = {}
vpc_cidr                = "10.0.0.0/16"
public_subnet_suffixes  = [0, 1]
private_subnet_suffixes = [2, 3]
node_instance_type      = "t3.medium"
node_desired_capacity   = 2
node_min_capacity       = 1
node_max_capacity       = 2

application_name = "eks-artifact-registry"
repo_owner       = "CondePoponcio"
repo_name        = "admoai-test"
repo_branch      = "main"

