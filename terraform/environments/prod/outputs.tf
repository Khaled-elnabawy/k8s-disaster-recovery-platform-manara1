output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "velero_backup_bucket" {
  description = "S3 bucket name to configure as Velero's backup location."
  value       = module.s3.bucket_name
}

output "velero_iam_role_arn" {
  description = "IAM role ARN for the velero service account in namespace velero."
  value       = aws_iam_role.velero.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Flask demo image."
  value       = aws_ecr_repository.demo_app.repository_url
}
