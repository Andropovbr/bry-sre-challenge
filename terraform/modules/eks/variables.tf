variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version used by the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS managed node group."
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the managed node group."
  type        = string
}

variable "node_instance_types" {
  description = "List of EC2 instance types used by the managed node group."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
}

variable "endpoint_private_access" {
  description = "Whether the EKS cluster private endpoint is enabled."
  type        = bool
}

variable "endpoint_public_access" {
  description = "Whether the EKS cluster public endpoint is enabled."
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public endpoint."
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}