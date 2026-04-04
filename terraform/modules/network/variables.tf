variable "project_name" {
  description = "Logical name of the project."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones used by the environment."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway."
  type        = bool
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}