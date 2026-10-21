# Solution Architecture — Project 5

The intended topology follows Project 5 in the AWS Solutions Architect – Associate graduation-project guide.

- Primary: `us-east-1`.
- Secondary: `eu-west-1`, warm-standby capacity.
- DNS: Route 53 failover records and health checks.
- Application: an ALB and EC2 Auto Scaling group in each region, with reduced desired capacity in the secondary.
- Data: Aurora Global Database, S3 Cross-Region Replication, DynamoDB Global Tables.
- Backup: AWS Backup plan, primary vault, and cross-region copy to a destination vault.
- Automation: CloudWatch alarm, EventBridge event forwarding to the secondary region, and a Lambda scale-up action.

## Flow summary

1. Clients resolve the application FQDN through Route 53.
2. The primary failover record directs traffic to the primary regional ALB while its health check is healthy.
3. Route 53 returns the secondary record when the primary health check is unhealthy. Resolver caching and TTL affect the time until all clients use the secondary answer.
4. A CloudWatch alarm for unhealthy primary ALB targets enters ALARM state.
5. An EventBridge rule forwards the alarm event to the secondary region's custom event bus.
6. A Lambda function in the secondary region raises the standby Auto Scaling group's desired and minimum capacity.
7. The recovery operator validates secondary application targets and promotes the Aurora secondary cluster when required before confirming writable database recovery.

DNS failover and database promotion are distinct operations. The runbook requires explicit validation of database role and data consistency before declaring recovery complete.

## Required diagram work

The included `architecture.drawio` file is only a scaffold. The project reviewer explicitly said AI-generated flow diagrams will not qualify and the final drawing must use official AWS icons. Complete the architecture diagram manually in diagrams.net, use the official AWS Architecture Icons library, label region boundaries and every replication/failover path, export to `docs/architecture.png` or `docs/architecture.svg`, and embed the exported diagram in README before submitting.

Official icon catalog: https://aws.amazon.com/architecture/icons/

The completed diagram should show the Route 53 records/health check; both regions; regional ALB/ASG tiers and warm capacity; Aurora primary/secondary; S3 replication; DynamoDB Global Table replicas; AWS Backup cross-region copy; and CloudWatch → EventBridge → Lambda → standby ASG scaling.

## Assumptions

- Both regions are in one AWS account and the Route 53 public hosted zone already exists.
- Each regional CloudFormation StackSet deployment exports an ALB DNS name, canonical hosted-zone ID, ALB/target-group metric suffixes, ASG name, VPC ID, private subnet IDs, and database security group ID.
- The sample regional ALB listens on HTTP for demo health checks. Add ACM certificates/HTTPS, WAF, stricter egress, and a reviewed security baseline before production use.
- Engine versions, instance types, quotas, and per-region service support must be checked before deployment.
