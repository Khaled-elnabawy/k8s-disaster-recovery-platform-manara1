# Terraform configuration

Terraform in this folder describes the global DNS and data-protection layer and the secondary-region recovery automation. Regional VPC/ALB/EC2 application stacks are created by the CloudFormation template at `../cloudformation/regional-warm-standby.yaml`.

## Values required from CloudFormation

Create an untracked `terraform.tfvars` using the real outputs from both regional stacks. Required inputs include:

- Existing Route 53 public hosted-zone ID and application FQDN.
- Primary and secondary ALB DNS names and canonical hosted-zone IDs.
- Primary ALB and target-group ARN suffixes for CloudWatch dimensions.
- Primary and secondary Auto Scaling group names.
- Private subnet IDs and database security group IDs in both regions.
- A globally unique lowercase S3 bucket suffix.
- An Aurora engine version and regional instance classes supported by both regions.

## Suggested order

1. Deploy the regional template with CloudFormation StackSets.
2. Collect actual regional stack outputs.
3. Populate a local untracked `terraform.tfvars`.
4. Run `terraform init`, `terraform fmt -check -recursive`, `terraform validate`, and review `terraform plan`.
5. Apply only after reviewing cost, account quotas, network/security boundaries, service availability, backup retention, and IAM.
6. Test each failover/data recovery mechanism independently before calling the architecture recovered.

These are infrastructure templates, not evidence of an existing deployment or successful disaster-recovery exercise.