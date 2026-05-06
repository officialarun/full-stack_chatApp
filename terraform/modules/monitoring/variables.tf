variable "environment" {
  type        = string
  description = "Environment name"
}

variable "alert_email" {
  type        = string
  description = "Email for CloudWatch alerts"
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "Log retention period in days"
  default     = 30
}

variable "instance_id" {
  type        = string
  description = "EC2 instance ID for alarms"
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    Project   = "ChatApp"
    ManagedBy = "Terraform"
  }
}
