variable "name" {
  description = "Name prefix applied to all VPC resources."
  type        = string
}

variable "environment" {
  description = "Environment name used for the Environment tag."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per availability zone."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per availability zone."
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones; must contain at least as many entries as the larger subnet list."
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
