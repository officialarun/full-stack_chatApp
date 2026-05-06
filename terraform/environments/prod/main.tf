# Production Environment - Terraform configuration
# Full HA setup with monitoring and backups

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
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  alias  = "primary"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "ChatApp"
      ManagedBy   = "Terraform"
      CreatedAt   = "2026-05-06"
      CostCenter  = "Engineering"
    }
  }
}

# Secondary region provider for multi-region setup
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "ChatApp"
      ManagedBy   = "Terraform"
      CreatedAt   = "2026-05-06"
      CostCenter  = "Engineering"
    }
  }
}

# Variables
variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "Primary AWS region"
}

variable "secondary_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "Secondary AWS region for DR"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Environment"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

variable "cluster_name" {
  type        = string
  default     = "chatapp-eks-prod"
  description = "EKS cluster name"
}

variable "desired_size" {
  type        = number
  default     = 3
  description = "Desired node count"
}

variable "max_size" {
  type        = number
  default     = 10
  description = "Maximum node count"
}

variable "alert_email" {
  type        = string
  default     = "alerts@chatapp.io"
  description = "Alert email"
}

# Module: VPC (Primary Region)
module "vpc_primary" {
  source = "../../modules/vpc"
  providers = {
    aws = aws.primary
  }

  environment             = "${var.environment}-primary"
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones      = ["ap-south-1a", "ap-south-1b"]
}

# Module: EKS (Primary Region)
module "eks_primary" {
  source = "../../modules/eks"
  providers = {
    aws = aws.primary
  }

  environment                 = "${var.environment}-primary"
  cluster_name                = var.cluster_name
  kubernetes_version          = "1.28"
  subnet_ids                  = concat(module.vpc_primary.public_subnet_ids, module.vpc_primary.private_subnet_ids)
  private_subnet_ids          = module.vpc_primary.private_subnet_ids
  eks_control_plane_sg_id     = module.vpc_primary.eks_control_plane_sg_id
  desired_size                = var.desired_size
  max_size                    = var.max_size
  min_size                    = 2
  instance_types              = ["t3.large"]
  disk_size                   = 50
}

# Module: MongoDB (Primary Region - DocumentDB for managed service)
module "mongodb_primary" {
  source = "../../modules/mongodb"
  providers = {
    aws = aws.primary
  }

  environment              = "${var.environment}-primary"
  use_documentdb           = true  # Use managed DocumentDB for production
  enable_mongodb_on_ec2    = false
  documentdb_instance_count = 3
  documentdb_instance_class = "db.r6g.large"
  private_subnet_ids       = module.vpc_primary.private_subnet_ids
  mongodb_sg_id            = module.vpc_primary.mongodb_sg_id
  root_username            = "admin"
  root_password            = random_password.mongodb_password.result
  backup_retention_period  = 35
  skip_final_snapshot      = false
}

# Module: Monitoring (Primary Region)
module "monitoring_primary" {
  source = "../../modules/monitoring"
  providers = {
    aws = aws.primary
  }

  environment        = "${var.environment}-primary"
  aws_region         = var.aws_region
  alert_email        = var.alert_email
  log_retention_days = 90  # Extended retention for prod
}

# Generate random password for MongoDB
resource "random_password" "mongodb_password" {
  length  = 32
  special = true
}

# Store MongoDB password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "mongodb_password" {
  name                    = "${var.environment}/mongodb/root-password"
  recovery_window_in_days = 7

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id      = aws_secretsmanager_secret.mongodb_password.id
  secret_string  = random_password.mongodb_password.result
}

# Outputs
output "eks_cluster_name" {
  value       = module.eks_primary.cluster_id
  description = "EKS cluster name"
}

output "eks_cluster_endpoint" {
  value       = module.eks_primary.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "documentdb_endpoint" {
  value       = module.mongodb_primary.documentdb_endpoint
  sensitive   = true
  description = "DocumentDB cluster endpoint"
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_primary.cluster_id}"
  description = "Command to configure kubectl"
}
