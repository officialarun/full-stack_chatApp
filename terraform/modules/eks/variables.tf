variable "environment" {
  type        = string
  description = "Environment name"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.28"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for EKS cluster"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for node groups"
}

variable "eks_control_plane_sg_id" {
  type        = string
  description = "Security group ID for EKS control plane"
}

variable "desired_size" {
  type        = number
  description = "Desired number of nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of nodes"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of nodes"
  default     = 4
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for node group"
  default     = ["t3.medium"]
}

variable "disk_size" {
  type        = number
  description = "EBS volume size in GB"
  default     = 30
}

variable "key_pair_name" {
  type        = string
  description = "SSH key pair name"
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access EKS API"
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    Project   = "ChatApp"
    ManagedBy = "Terraform"
  }
}
