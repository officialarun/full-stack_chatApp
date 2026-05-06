output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "EKS cluster ID"
}

output "cluster_arn" {
  value       = aws_eks_cluster.main.arn
  description = "EKS cluster ARN"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint"
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
  description = "EKS cluster version"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
  description = "Base64 encoded certificate data"
}

output "node_group_id" {
  value       = aws_eks_node_group.main.id
  description = "Node group ID"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.cluster.arn
  description = "OIDC provider ARN for IRSA"
}

output "alb_controller_role_arn" {
  value       = aws_iam_role.alb_controller.arn
  description = "ALB controller IAM role ARN"
}

output "ebs_csi_driver_role_arn" {
  value       = aws_iam_role.ebs_csi_driver.arn
  description = "EBS CSI driver IAM role ARN"
}
