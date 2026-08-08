output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
output "ecr_repository_url" {
  value = aws_ecr_repository.demo_app.repository_url
}
