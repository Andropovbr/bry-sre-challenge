aws_region      = "us-east-1"
project_name    = "bry-sre-challenge"
cluster_name    = "bry-sre-challenge-eks"
cluster_version = "1.35"

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

enable_nat_gateway = true

node_group_name     = "bry-sre-challenge-ng"
node_instance_types = ["t3.medium"]
desired_size        = 2
min_size            = 2
max_size            = 3

endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["189.46.207.139/32"]

tags = {
  Project = "bry-sre-challenge"
  Owner   = "Andre Santos"
}