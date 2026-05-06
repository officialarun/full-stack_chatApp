output "documentdb_endpoint" {
  value       = var.use_documentdb ? aws_docdb_cluster.mongodb_managed[0].endpoint : ""
  description = "DocumentDB cluster endpoint"
}

output "documentdb_reader_endpoint" {
  value       = var.use_documentdb ? aws_docdb_cluster.mongodb_managed[0].reader_endpoint : ""
  description = "DocumentDB reader endpoint"
}

output "documentdb_port" {
  value       = var.use_documentdb ? aws_docdb_cluster.mongodb_managed[0].port : 27017
  description = "DocumentDB port"
}

output "mongodb_instance_ids" {
  value       = var.enable_mongodb_on_ec2 ? aws_instance.mongodb[*].id : []
  description = "MongoDB EC2 instance IDs"
}

output "mongodb_instance_ips" {
  value       = var.enable_mongodb_on_ec2 ? aws_instance.mongodb[*].private_ip : []
  description = "MongoDB EC2 instance private IPs"
}
