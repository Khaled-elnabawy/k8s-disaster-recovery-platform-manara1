# Validation Status

This file distinguishes repository-level checks from actual AWS deployment and recovery evidence.

## Repository artifact checks

The GitHub Actions run below completed successfully for the infrastructure templates, Lambda file, README, and SVG architecture preview:

- [x] Terraform formatting passed.
- [x] Terraform initialization and static validation passed.
- [x] CloudFormation lint passed for the regional StackSet template.
- [x] Failover Lambda Python compilation passed.
- [x] GitHub Actions validation workflow completed successfully.

Validated commit: `c4d3fdd9131fba012261023f386481a84db0c990`  
Workflow: https://github.com/Khaled-elnabawy/multi-region-disaster-recovery-route53-failover/actions/runs/39632218823

- [ ] Manually inspect the editable `docs/architecture.drawio` in diagrams.net, verify service icons against the official AWS Architecture Icons library, and adjust any labels/connectors needed to meet the reviewer's diagram requirement. The README currently embeds the SVG visual preview.

## Configuration review — not yet verified against an AWS account

- [ ] Regional CloudFormation StackSets deployed and outputs recorded.
- [ ] Route 53 hosted zone, health checks and failover records configured.
- [ ] Aurora Global Database versions, network access and replica topology verified.
- [ ] S3 Cross-Region Replication tested with a real source object.
- [ ] DynamoDB Global Table replica status verified.
- [ ] AWS Backup cross-region copy verified.
- [ ] CloudWatch alarm, EventBridge forwarding and secondary Lambda permissions reviewed.
- [ ] Estimated costs and service quotas reviewed.

## Live failover test evidence

No live AWS deployment or failover is claimed by this repository update. Fill this section after actually running the test.

- Test date/time (UTC): __________________
- Primary region: us-east-1
- Secondary region: eu-west-1
- Test hostname: __________________
- Primary health-check transition (UTC): __________________
- Secondary DNS response first observed (UTC): __________________
- EventBridge event received in secondary region (UTC): __________________
- Lambda invocation/result: __________________
- Secondary ASG desired/current capacity: __________________
- Secondary ALB healthy-target result: __________________
- Aurora cluster role after promotion: __________________
- Database write/read validation: __________________
- S3 CRR test object validation: __________________
- DynamoDB replica test item validation: __________________
- AWS Backup cross-region recovery point: __________________
- Measured RTO: __________________
- Measured RPO / last confirmed data: __________________
- Errors / corrective actions: __________________

A passing Terraform or CloudFormation static check does not prove that AWS resources exist or that a multi-region failover test succeeded.
