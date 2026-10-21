# Validation Status and Evidence

This file is an evidence template, not a claim that a live restore test has passed.

## Repository checks

- [ ] Terraform formatting and validation passed in GitHub Actions.
- [ ] Python smoke tests passed.
- [ ] Docker image build passed.
- [ ] Image push to ECR completed (only if AWS OIDC publishing is configured).

## AWS backup/restore evidence

- AWS region: __________________
- EKS cluster name: __________________
- Test date (UTC): __________________
- Velero version / AWS plugin version: __________________
- Backup name / phase: __________________
- Restore name / phase: __________________
- Backup completed at (UTC): __________________
- Namespace deletion started at (UTC): __________________
- Application validated healthy at (UTC): __________________
- Measured RTO: __________________
- Newest recovered data timestamp / measured RPO: __________________
- Pre-disaster test record: __________________
- Post-restore verification result: __________________
- Restored resource count and missing resources: __________________
- Logs or screenshots committed with this report: __________________

## Evidence checklist

- [ ] Velero BackupStorageLocation is Available.
- [ ] Backup completed and includes the demo namespace.
- [ ] Persistent volume recovery path is confirmed.
- [ ] Velero restore completed.
- [ ] API and database are healthy after restore.
- [ ] A known record written before the drill is present after restore.
- [ ] RTO/RPO calculated from actual timestamps, not estimates.

**Current status:** repository documentation is being improved, but no live AWS provisioning or destructive recovery drill has been executed as part of these edits. Fill this file only after testing in your AWS account.