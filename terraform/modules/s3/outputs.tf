output "bucket_name" {
  value = aws_s3_bucket.velero_backups.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.velero_backups.arn
}
