# MongoDB Module - Create MongoDB replication set on EC2 instances in private subnet
# For production, consider MongoDB Atlas for managed service

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# MongoDB security group is created in VPC module
# This module focuses on EC2 instances running MongoDB

# IAM role for MongoDB EC2 instances
resource "aws_iam_role" "mongodb" {
  name = "${var.environment}-mongodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_instance_profile" "mongodb" {
  name = "${var.environment}-mongodb-profile"
  role = aws_iam_role.mongodb.name
}

# Policy for CloudWatch monitoring and logs
resource "aws_iam_role_policy" "mongodb_cloudwatch" {
  name = "${var.environment}-mongodb-cloudwatch"
  role = aws_iam_role.mongodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# EBS volume for MongoDB data
resource "aws_ebs_volume" "mongodb_data" {
  count             = var.enable_mongodb_on_ec2 ? 1 : 0
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mongodb-data"
    }
  )
}

# MongoDB EC2 instances
resource "aws_instance" "mongodb" {
  count                    = var.enable_mongodb_on_ec2 ? var.mongodb_instance_count : 0
  ami                      = data.aws_ami.ubuntu.id
  instance_type            = var.instance_type
  subnet_id                = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  iam_instance_profile     = aws_iam_instance_profile.mongodb.name
  vpc_security_group_ids   = [var.mongodb_sg_id]
  associate_public_ip_address = false

  # User data script to install MongoDB
  user_data = base64encode(templatefile("${path.module}/mongodb_init.sh", {
    mongodb_version = var.mongodb_version
    root_username   = var.root_username
    root_password   = var.root_password
    environment     = var.environment
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mongodb-${count.index + 1}"
    }
  )

  depends_on = [aws_iam_role_policy.mongodb_cloudwatch]
}

# Attach EBS volume to MongoDB instance
resource "aws_volume_attachment" "mongodb_data" {
  count           = var.enable_mongodb_on_ec2 ? 1 : 0
  device_name     = "/dev/sdf"
  volume_id       = aws_ebs_volume.mongodb_data[0].id
  instance_id     = aws_instance.mongodb[0].id
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# RDS for MongoDB-compatible database (alternative to self-managed)
# DocumentDB is AWS's MongoDB-compatible database
resource "aws_docdb_cluster" "mongodb_managed" {
  count                           = var.use_documentdb ? 1 : 0
  cluster_identifier              = "${var.environment}-mongodb-cluster"
  engine                          = "docdb"
  master_username                 = var.root_username
  master_password                 = var.root_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = "03:00-04:00"
  skip_final_snapshot             = var.skip_final_snapshot
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.documentdb[0].arn
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  db_subnet_group_name            = aws_docdb_subnet_group.main[0].name
  vpc_security_group_ids          = [var.mongodb_sg_id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mongodb-cluster"
    }
  )
}

# DocumentDB cluster instances
resource "aws_docdb_cluster_instance" "mongodb_managed" {
  count              = var.use_documentdb ? var.documentdb_instance_count : 0
  cluster_identifier = aws_docdb_cluster.mongodb_managed[0].id
  instance_class     = var.documentdb_instance_class
  engine              = "docdb"
  auto_minor_version_upgrade = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-mongodb-instance-${count.index + 1}"
    }
  )
}

# DocumentDB subnet group
resource "aws_docdb_subnet_group" "main" {
  count           = var.use_documentdb ? 1 : 0
  name            = "${var.environment}-mongodb-subnet-group"
  subnet_ids      = var.private_subnet_ids
  tags            = var.common_tags
}

# KMS key for DocumentDB encryption
resource "aws_kms_key" "documentdb" {
  count                   = var.use_documentdb ? 1 : 0
  description             = "KMS key for DocumentDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-documentdb-kms"
    }
  )
}

resource "aws_kms_alias" "documentdb" {
  count         = var.use_documentdb ? 1 : 0
  name          = "alias/${var.environment}-documentdb"
  target_key_id = aws_kms_key.documentdb[0].key_id
}
