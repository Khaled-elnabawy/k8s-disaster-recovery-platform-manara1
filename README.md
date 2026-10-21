# Multi-Region Disaster Recovery with Route 53 Failover

A reference architecture for a **Warm Standby** disaster recovery design on AWS. The primary application stack runs in **US East (N. Virginia), us-east-1**. A smaller standby stack runs in **Europe (Ireland), eu-west-1**. Amazon Route 53 health checks and failover records direct users to the healthy regional Application Load Balancer.

> **Project scope:** This repository aligns with Project 5 in the AWS Solutions Architect – Associate graduation-project guide. It contains architecture documentation and infrastructure templates. Do not interpret the templates as proof that the AWS resources have been deployed or that a live failover exercise has passed.

## Solution Architecture

**Architecture diagram requirement:** complete `docs/architecture.drawio` manually in diagrams.net using official AWS Architecture Icons, then export the finished diagram as PNG or SVG and embed it here before submission. The included file is only a layout scaffold; it is not the final architecture diagram.

## Project Objectives

- Build a multi-region Warm Standby design with `us-east-1` as primary and `eu-west-1` as secondary.
- Route users through Route 53 failover records with health checks and a deliberate DNS TTL.
- Keep a smaller EC2 Auto Scaling application tier in the secondary region and scale it when a primary-region alarm is received.
- Replicate relational data with Amazon Aurora Global Database.
- Replicate objects with S3 Cross-Region Replication (CRR).
- Use DynamoDB Global Tables for multi-region table replication.
- Create scheduled AWS Backup plans with cross-region copy.
- Use CloudWatch, EventBridge, and Lambda to trigger the secondary application scale-up workflow.
- Describe a repeatable failover/failback test and capture measured RTO/RPO evidence.

## Architecture at a Glance

| Layer | Primary: us-east-1 | Secondary: eu-west-1 | Recovery mechanism |
|---|---|---|---|
| DNS and traffic | Route 53 primary failover record | Route 53 secondary failover record | Health check detects unhealthy primary ALB; DNS routes clients to secondary |
| Application | ALB + EC2 Auto Scaling group at normal capacity | ALB + EC2 Auto Scaling group at warm-standby capacity | EventBridge receives the primary alarm event and Lambda raises standby capacity |
| Relational data | Aurora Global Database writer cluster | Aurora Global Database secondary cluster | Planned promotion of the secondary cluster during the recovery procedure |
| Object storage | Versioned S3 source bucket | Versioned S3 replica bucket | S3 Cross-Region Replication |
| NoSQL | DynamoDB Global Table replica | DynamoDB Global Table replica | DynamoDB manages multi-region replication |
| Backup | AWS Backup vault and plan | Destination AWS Backup vault | Scheduled backup copy to the secondary region |
| Operations | CloudWatch alarm and EventBridge rule | EventBridge bus/rule and failover Lambda | Alarm-to-event-bus forwarding and standby scale-up |

## Repository Layout

~~~text
.
├── .github/workflows/ci.yml
├── docs/
│   ├── architecture.md
│   ├── architecture.drawio
│   ├── disaster-recovery-runbook.md
│   └── validation-status.md
└── infrastructure/
    ├── cloudformation/
    │   └── regional-warm-standby.yaml
    ├── lambda/
    │   └── failover.py
    └── terraform/
        ├── providers.tf
        ├── variables.tf
        ├── dns-failover.tf
        ├── data-resilience.tf
        ├── backup.tf
        ├── automation.tf
        ├── outputs.tf
        └── README.md
~~~

## Deployment Approach

1. Use CloudFormation StackSets to deploy the regional application stack in both regions. Set a higher desired capacity for the primary stack and a smaller desired capacity for the standby stack.
2. Record each regional stack's outputs (ALB DNS name and hosted-zone ID, Auto Scaling group name, load-balancer and target-group ARN suffixes, private subnet IDs, and database security-group ID).
3. Set the Terraform input variables to the stack outputs and the existing Route 53 hosted-zone ID.
4. Apply the Terraform configuration to add Route 53 failover, Aurora Global Database, S3 CRR, DynamoDB Global Tables, AWS Backup, and the CloudWatch/EventBridge/Lambda automation.
5. Run the controlled disaster-recovery test in the runbook and record evidence in `docs/validation-status.md`.

Full steps and safety checks are in [the disaster-recovery runbook](docs/disaster-recovery-runbook.md). The infrastructure README describes the expected input values and ordering.

## Recovery Strategy Comparison

| Strategy | Recovery approach | Relative cost | Typical recovery characteristics |
|---|---|---|---|
| Backup & Restore | Rebuild from backups after an incident | Lowest standby cost | Longest RTO; RPO depends on backup frequency |
| Pilot Light | Keep critical data services and minimal core resources running | Low to medium | Faster than full rebuild; application tier still needs scaling/provisioning |
| Warm Standby | Keep a reduced but functional secondary stack running | Medium | Faster regional recovery; secondary scales up after failover |
| Multi-Site Active-Active | Serve live traffic from multiple regions | Highest | Low recovery delay but more complex data consistency and traffic management |

This project focuses on **Warm Standby** as requested by the guide. Actual RTO/RPO depend on the deployed services, database replication lag, DNS caching, and the tested recovery procedure.

## Security and Cost Considerations

- Restrict Route 53 health checks to a dedicated application health endpoint.
- Keep database security groups private and restrict ingress to the application security group.
- Use managed database credentials, KMS encryption, S3 public-access blocks, least-privilege IAM, and CloudFormation StackSets for repeatable regional deployment.
- EC2 instances accept application traffic only from the regional load balancer security group; SSH ingress is not opened by this template.
- Multi-AZ load balancers, NAT/networking, EC2, Aurora, DynamoDB replicas, AWS Backup, and cross-region data transfer can incur charges. Review estimates and plans before deployment.
- Failover to a secondary Route 53 record is not the same as promoting the Aurora secondary cluster. Follow the runbook and verify database role, write readiness, and application health before declaring recovery.

## Validation Status

Infrastructure templates and documentation are provided for review. No live AWS deployment or disaster-recovery drill is claimed by this repository update. The status and evidence checklist is in [validation-status.md](docs/validation-status.md).

## References

- [AWS Solutions Architect – Associate project guide context](docs/architecture.md)
- [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
- [Amazon Route 53 failover routing](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-failover.html)
- [Aurora Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)
- [S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [DynamoDB Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
- [AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
