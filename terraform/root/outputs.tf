# output "vpc_id" {
#   description = "VPC ID created for the environment."
#   value       = module.network.vpc_id
# }

# output "public_subnet_ids" {
#   description = "Public subnet IDs."
#   value       = module.network.public_subnet_ids
# }

# output "private_subnet_ids" {
#   description = "Private subnet IDs."
#   value       = module.network.private_subnet_ids
# }

# output "cluster_name" {
#   description = "EKS cluster name."
#   value       = module.eks.cluster_name
# }

# output "cluster_endpoint" {
#   description = "EKS cluster API server endpoint."
#   value       = module.eks.cluster_endpoint
# }

# output "cluster_certificate_authority_data" {
#   description = "EKS cluster certificate authority data."
#   value       = module.eks.cluster_certificate_authority_data
#   sensitive   = true
# }