provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = merge(
    var.tags,
    {
      Name      = var.state_bucket_name
      Project   = var.project_name
      ManagedBy = "Terraform"
      Purpose   = "Terraform Remote State"
    }
  )
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}