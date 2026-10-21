output "application_fqdn" {
  description = "Application hostname using Route 53 failover records."
  value       = var.application_fqdn
}

output "primary_s3_bucket" {
  description = "Primary bucket for object storage and cross-region replication."
  value       = aws_s3_bucket.primary_objects.bucket
}

output "secondary_s3_bucket" {
  description = "Secondary-region replica bucket."
  value       = aws_s3_bucket.secondary_objects.bucket
}

output "dynamodb_global_table_name" {
  description = "Name of the DynamoDB Global Table."
  value       = aws_dynamodb_table.global_app_data.name
}

output "aurora_global_cluster_identifier" {
  description = "Aurora Global Database identifier."
  value       = aws_rds_global_cluster.app.global_cluster_identifier
}

output "secondary_event_bus_arn" {
  description = "Custom EventBridge bus in the secondary region."
  value       = aws_cloudwatch_event_bus.secondary_failover.arn
}

output "secondary_failover_lambda_name" {
  description = "Lambda function that scales the warm-standby ASG."
  value       = aws_lambda_function.standby_scale.function_name
}
