# Validation Status

This file distinguishes repository-level checks from actual AWS deployment and recovery evidence.

## Repository artifacts

- [ ] Root README matches Project 5 (Warm Standby multi-region DR).
- [ ] CloudFormation StackSet template reviewed for both target regions.
- [ ] Terraform formatting/validation passed.
- [ ] CloudFormation lint passed.
- [ ] Failover Lambda compiles.
- [ ] GitHub Actions passed on the final commit.
- [ ] Final architecture diagram was manually completed using official AWS Architecture Icons and embedded in README.

## Configuration review

- [ ] Actual primary and secondary CloudFormation outputs recorded in an untracked tfvars file.
- [ ] Route 53 hosted zone and failover records reviewed.
- [ ] Aurora Global Database version and replica topology reviewed.
- [ ] S3 versioning/CRR verified.
- [ ] DynamoDB Global Table replica status verified.
- [ ] AWS Backup cross-region copy verified.
- [ ] CloudWatch alarm, EventBridge forwarding, and secondary Lambda permissions reviewed.
- [ ] Estimated recurring costs and regional service quotas reviewed.

## Live failover test evidence

No live AWS deployment or failover is claimed by this repository update. Complete after actually running the test.

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

A passing Terraform or CloudFormation static check does not prove that the AWS resources exist or that the failover test succeeded.
