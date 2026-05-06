# Dev Environment - Terraform configuration
# Minimal resources for development

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configure S3 backend for state
  backend "s3" {
    bucket         = "chatapp-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "ChatApp"
      ManagedBy   = "Terraform"
      CreatedAt   = "2026-05-06"
    }
  }
}

# Variables
variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "AWS region"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

variable "cluster_name" {
  type        = string
  default     = "chatapp-eks-dev"
  description = "EKS cluster name"
}

variable "desired_size" {
  type        = number
  default     = 1
  description = "Desired node count"
}

variable "max_size" {
  type        = number
  default     = 2
  description = "Maximum node count"
}

# Module: VPC
module "vpc" {
  source = "../../modules/vpc"

  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones      = ["ap-south-1a", "ap-south-1b"]
}

# Module: EKS
module "eks" {
  source = "../../modules/eks"

  environment                 = var.environment
  cluster_name                = var.cluster_name
  kubernetes_version          = "1.28"
  subnet_ids                  = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids          = module.vpc.private_subnet_ids
  eks_control_plane_sg_id     = module.vpc.eks_control_plane_sg_id
  desired_size                = var.desired_size
  max_size                    = var.max_size
  min_size                    = 1
  instance_types              = ["t3.small"]
  disk_size                   = 30
}

# Module: MongoDB
module "mongodb" {
  source = "../../modules/mongodb"

  environment              = var.environment
  use_documentdb           = false  # Use EC2 for dev (cheaper)
  enable_mongodb_on_ec2    = false  # Disabled for now; use managed service
  mongodb_instance_count   = 1
  instance_type            = "t3.small"
  private_subnet_ids       = module.vpc.private_subnet_ids
  mongodb_sg_id            = module.vpc.mongodb_sg_id
  root_username            = "admin"
  root_password            = "dev-password-change-me"  # Change in actual deployment
}

# Module: Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  environment      = var.environment
  aws_region       = var.aws_region
  alert_email      = "admin@chatapp.local"
  log_retention_days = 7  # Short retention for dev
}

# Outputs
output "eks_cluster_name" {
  value       = module.eks.cluster_id
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
  description = "Command to configure kubectl"
}
