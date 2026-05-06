output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs"
}

output "nat_gateway_ips" {
  value       = aws_eip.nat[*].public_ip
  description = "NAT Gateway public IPs"
}

output "eks_control_plane_sg_id" {
  value       = aws_security_group.eks_control_plane.id
  description = "EKS control plane security group ID"
}

output "eks_nodes_sg_id" {
  value       = aws_security_group.eks_nodes.id
  description = "EKS nodes security group ID"
}

output "mongodb_sg_id" {
  value       = aws_security_group.mongodb.id
  description = "MongoDB security group ID"
}
