variable "aws_region" {
  description = "AWS region where the Terraform remote state bucket will be created."
  type        = string
}

variable "project_name" {
  description = "Logical name of the project."
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique name for the S3 bucket that will store the Terraform remote state."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}