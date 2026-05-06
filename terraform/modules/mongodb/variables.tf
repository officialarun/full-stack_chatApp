variable "environment" {
  type        = string
  description = "Environment name"
}

variable "enable_mongodb_on_ec2" {
  type        = bool
  description = "Enable self-managed MongoDB on EC2"
  default     = false
}

variable "use_documentdb" {
  type        = bool
  description = "Use AWS DocumentDB (MongoDB-compatible)"
  default     = true
}

variable "mongodb_version" {
  type        = string
  description = "MongoDB version"
  default     = "5.0"
}

variable "root_username" {
  type        = string
  description = "MongoDB root username"
  default     = "admin"
  sensitive   = true
}

variable "root_password" {
  type        = string
  description = "MongoDB root password"
  sensitive   = true
}

variable "mongodb_instance_count" {
  type        = number
  description = "Number of MongoDB instances (EC2)"
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for MongoDB"
  default     = "t3.medium"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for MongoDB"
  default     = "ap-south-1a"
}

variable "ebs_volume_size" {
  type        = number
  description = "EBS volume size in GB"
  default     = 100
}

variable "ebs_volume_type" {
  type        = string
  description = "EBS volume type"
  default     = "gp3"
}

variable "mongodb_sg_id" {
  type        = string
  description = "Security group ID for MongoDB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "documentdb_instance_count" {
  type        = number
  description = "Number of DocumentDB instances"
  default     = 2
}

variable "documentdb_instance_class" {
  type        = string
  description = "DocumentDB instance class"
  default     = "db.t3.medium"
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion"
  default     = true
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    Project   = "ChatApp"
    ManagedBy = "Terraform"
  }
}
