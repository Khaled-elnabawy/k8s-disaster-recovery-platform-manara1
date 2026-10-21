# Disaster Recovery Runbook

This runbook describes a controlled Warm Standby exercise. Complete it only in a disposable test environment or under an approved change plan. Do not force a production outage for a portfolio demonstration.

## 1. Deploy the regional stacks

Deploy `infrastructure/cloudformation/regional-warm-standby.yaml` as a CloudFormation StackSet to `us-east-1` and `eu-west-1`.

For the primary stack, use an appropriate normal desired capacity. For the secondary stack, use a lower desired capacity while keeping at least one healthy standby instance. Supply an AMI ID valid in each target region. Each stack deploys a VPC across two Availability Zones, private application subnets, NAT gateways, a public ALB, an EC2 Auto Scaling group, and the database security group.

Record the output values from each region. The Terraform variables must be populated from real outputs; do not copy example or placeholder IDs.

## 2. Configure regional and global data services

1. Add the Route 53 zone ID, application FQDN, and actual regional ALB attributes to a local untracked `terraform.tfvars`.
2. Supply private subnet IDs and database security group IDs from both regional stacks.
3. Select an Aurora engine version supported in both regions and an instance class available in each region.
4. Review S3 replication, including source/destination bucket versioning and the replication role.
5. Confirm the DynamoDB Global Table has the requested replica region.
6. Review the AWS Backup selection tags and confirm the source-to-destination vault copy plan.
7. Review the EventBridge forwarding role/policy and the secondary event bus/Lambda permissions.

Keep passwords and `terraform.tfvars` out of Git. Review the cost of two VPCs, multiple NAT gateways, EC2, Aurora, backups, replicas, and cross-region transfer before applying.

## 3. Review the failover path before testing

- Route 53 health check points to the real primary ALB health endpoint.
- Primary and secondary failover records use the correct ALB DNS names and canonical hosted-zone IDs.
- Secondary ALB targets are healthy at warm capacity.
- Aurora Global Database replication is healthy and the secondary DB cluster is available.
- S3 test objects replicate to the destination bucket.
- DynamoDB test data is visible through the secondary replica.
- AWS Backup has recent recovery points in both vaults after cross-region copy.
- CloudWatch sends the primary alarm event; EventBridge forwards it; the secondary Lambda can update only the intended standby group.

## 4. Controlled failover exercise

1. Record the UTC start time and create a known application data record.
2. In a non-production test only, make the primary health check fail using an approved method.
3. Record when Route 53 health status changes and when the DNS response returns the secondary record from the test client. DNS caching can delay client convergence.
4. Confirm the primary target alarm enters ALARM state and the event reaches the secondary bus.
5. Confirm the Lambda invocation and desired-capacity update of the secondary ASG.
6. Wait until the secondary ALB reports healthy targets.
7. Follow the approved Aurora Global Database promotion procedure and verify that the intended secondary cluster is writable.
8. Verify the known application record, a replicated S3 object, and a DynamoDB test item.
9. Record timestamps, data replication lag, logs, alarms, errors, and recovery outcomes.

## 5. Failback

Do not automatically switch traffic back solely because the primary region has recovered. Rebuild and validate the original region, confirm Aurora role and data consistency, verify S3/DynamoDB state, then follow an approved change plan to switch DNS and data roles.

## 6. Calculate RTO/RPO

- RTO starts at the declared disruption and ends after the secondary application and writable database have both been verified.
- RPO is measured by comparing the last confirmed pre-disruption write with the newest data verified in the recovered application.

Fill out `docs/validation-status.md` from actual observations. Do not label an estimate as a measured result.
