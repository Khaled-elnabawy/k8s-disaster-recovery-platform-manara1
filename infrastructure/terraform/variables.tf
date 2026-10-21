variable "project_name" {
  description = "Short lowercase project prefix used in AWS resource names."
  type        = string
  default     = "multi-region-dr"
}

variable "primary_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Warm-standby AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "bucket_suffix" {
  description = "Globally unique lowercase suffix for S3 bucket names."
  type        = string
}

variable "route53_hosted_zone_id" {
  description = "ID of the existing public Route 53 hosted zone."
  type        = string
}

variable "application_fqdn" {
  description = "Fully qualified application name managed by the failover records."
  type        = string
}

variable "primary_alb_dns_name" {
  description = "DNS name output by the primary regional CloudFormation stack."
  type        = string
}

variable "primary_alb_zone_id" {
  description = "ALB canonical hosted-zone ID output by the primary regional stack."
  type        = string
}

variable "secondary_alb_dns_name" {
  description = "DNS name output by the secondary regional CloudFormation stack."
  type        = string
}

variable "secondary_alb_zone_id" {
  description = "ALB canonical hosted-zone ID output by the secondary regional stack."
  type        = string
}

variable "primary_alb_arn_suffix" {
  description = "Primary ALB ARN suffix for CloudWatch dimensions, without the leading slash."
  type        = string
}

variable "primary_target_group_arn_suffix" {
  description = "Primary target-group ARN suffix for CloudWatch dimensions, without the leading slash."
  type        = string
}

variable "primary_asg_name" {
  description = "Auto Scaling group name output by the primary regional stack."
  type        = string
}

variable "secondary_asg_name" {
  description = "Auto Scaling group name output by the secondary regional stack."
  type        = string
}

variable "primary_private_subnet_ids" {
  description = "Private subnet IDs for the primary Aurora DB subnet group, across AZs."
  type        = list(string)
}

variable "secondary_private_subnet_ids" {
  description = "Private subnet IDs for the secondary Aurora DB subnet group, across AZs."
  type        = list(string)
}

variable "primary_database_security_group_id" {
  description = "Database security-group ID in the primary region."
  type        = string
}

variable "secondary_database_security_group_id" {
  description = "Database security-group ID in the secondary region."
  type        = string
}

variable "aurora_engine_version" {
  description = "Aurora MySQL engine version supported in both selected regions."
  type        = string
}

variable "database_name" {
  description = "Initial Aurora database name."
  type        = string
  default     = "applicationdb"
}

variable "database_master_username" {
  description = "Master username; AWS Secrets Manager manages the password."
  type        = string
  default     = "appadmin"
}

variable "primary_database_instance_class" {
  description = "Supported Aurora DB instance class in the primary region."
  type        = string
  default     = "db.r6g.large"
}

variable "secondary_database_instance_class" {
  description = "Supported Aurora DB instance class in the secondary region."
  type        = string
  default     = "db.r6g.large"
}

variable "secondary_recovery_capacity" {
  description = "Desired instance count after automated standby scale-up."
  type        = number
  default     = 2
}
