# Terraform Deployment Guide

## Quick Start

### Initialize Terraform State Backend (First Time Only)

```bash
cd terraform/

# Create S3 bucket for state
aws s3 mb s3://chatapp-terraform-state --region ap-south-1

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-south-1
```

### Deploy Development Environment

```bash
cd environments/dev/

# Initialize Terraform
terraform init

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Deploy Production Environment

```bash
cd environments/prod/

# Initialize Terraform
terraform init

# Plan with variables
terraform plan \
  -var="alert_email=ops@company.com" \
  -out=tfplan

# Apply
terraform apply tfplan
```

## Terraform Modules

### VPC Module

Creates:
- VPC with configurable CIDR
- Public subnets (2 AZs)
- Private subnets (2 AZs)
- NAT Gateways
- Internet Gateway
- Security groups for EKS, MongoDB

**Usage:**
```hcl
module "vpc" {
  source = "../../modules/vpc"
  
  environment           = "prod"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

### EKS Module

Creates:
- EKS cluster with auto-scaling
- Managed node groups
- OIDC provider for IRSA
- EBS CSI driver
- ALB controller
- Core add-ons (VPC CNI, CoreDNS, kube-proxy)

**Variables:**
- `cluster_name`: EKS cluster name
- `desired_size`: Desired number of nodes (default: 2)
- `max_size`: Maximum nodes (default: 4)
- `instance_types`: EC2 instance types (default: t3.medium)

### MongoDB Module

Options:
1. **DocumentDB (Recommended)**: Managed MongoDB-compatible service
2. **Self-managed EC2**: MongoDB on EC2 instances

**For DocumentDB:**
```hcl
use_documentdb        = true
documentdb_instance_count = 3
documentdb_instance_class = "db.r6g.large"
```

**For EC2:**
```hcl
enable_mongodb_on_ec2 = true
mongodb_instance_count = 3
instance_type = "t3.medium"
```

### Monitoring Module

Creates:
- SNS topics for alerts
- CloudWatch log groups
- CloudWatch alarms (CPU, memory)
- IAM roles for monitoring

## Common Tasks

### Scale EKS Cluster

```hcl
# In environments/prod/main.tf
desired_size = 5  # Change from 3 to 5
max_size = 15     # Increase max

terraform plan
terraform apply
```

### Update Kubernetes Version

```hcl
# In modules/eks/main.tf
kubernetes_version = "1.29"  # Update version

terraform plan
terraform apply
```

### Add MongoDB Read Replicas

```hcl
# In environments/prod/main.tf
documentdb_instance_count = 5  # Add more read replicas

terraform apply
```

### Destroy Resources (Dev Only)

```bash
cd environments/dev/

terraform destroy -var="alert_email=ops@company.com"
```

## Best Practices

1. ✅ Always use `terraform plan` before `apply`
2. ✅ Keep state files in S3 with versioning
3. ✅ Use workspaces for separate environments
4. ✅ Tag all resources for cost tracking
5. ✅ Rotate sensitive values monthly
6. ✅ Use `terraform fmt` to format code
7. ✅ Validate with `terraform validate`
8. ✅ Keep modules DRY (Don't Repeat Yourself)

## Troubleshooting

### State Lock Timeout

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### AWS Credentials Not Found

```bash
# Set AWS credentials
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_REGION=ap-south-1
```

### Module Not Found

```bash
# Reinitialize Terraform
terraform init -upgrade
```

## Outputs

After successful apply, Terraform outputs:

```
eks_cluster_name = "chatapp-eks-prod"
eks_cluster_endpoint = "https://example.eks.amazonaws.com"
configure_kubectl = "aws eks update-kubeconfig --region ap-south-1 --name chatapp-eks-prod"
documentdb_endpoint = "chatapp-prod.cluster-xxx.ap-south-1.docdb.amazonaws.com:27017"
```

## Cost Estimation

```bash
terraform plan -out=tfplan

# Estimate costs (requires Infracost)
infracost breakdown --path tfplan
```

---

**For more help**: `terraform -help` or https://www.terraform.io/docs/
