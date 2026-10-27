variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "shared"
}

variable "state_bucket_name" {
  description = "Globally unique name of the Terraform state bucket."
  type        = string
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep noncurrent state versions before expiring them."
  type        = number
  default     = 90
}
