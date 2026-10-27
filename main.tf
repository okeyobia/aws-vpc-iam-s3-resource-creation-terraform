terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Backend blocks cannot reference variables. The state bucket name is supplied
  # at init time so no account-specific values live in source control:
  #   terraform init -backend-config="bucket=<state-bucket-name>"
  backend "s3" {
    key          = "aws-resource-iac/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 locking via conditional writes; no DynamoDB
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  name                 = "${var.project_name}-${var.environment}"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "s3_storage" {
  source = "./modules/s3"

  bucket_name   = var.app_bucket_name
  environment   = var.environment
  force_destroy = var.bucket_force_destroy
}

module "iam_app_role" {
  source = "./modules/iam"

  role_name   = "${var.project_name}-${var.environment}-app-role"
  environment = var.environment
  bucket_arn  = module.s3_storage.bucket_arn
}
