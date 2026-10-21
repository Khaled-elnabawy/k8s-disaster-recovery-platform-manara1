# Validation Status and Evidence

## Repository checks

The latest GitHub Actions run for commit f2d62face75bb820b93b14f69943caf417d481e3 completed successfully on 2026-10-21.

- [x] Terraform format check passed.
- [x] Terraform init and validate passed.
- [x] Python smoke tests passed.
- [x] Docker image build passed.
- [ ] ECR image publication not run (requires the repository's AWS OIDC role configuration).

Workflow run: https://github.com/Khaled-elnabawy/k8s-disaster-recovery-platform-manara1/actions/runs/39620036653

## AWS backup/restore evidence

No live AWS provisioning or destructive restore drill was executed as part of this repository update. Complete this section only after running the runbook in your own AWS account.

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
- [ ] Backup completed and includes the demo-app namespace.
- [ ] Persistent-volume recovery path is confirmed.
- [ ] Velero restore completed.
- [ ] API and database are healthy after restore.
- [ ] A known record written before the drill is present after restore.
- [ ] RTO/RPO calculated from actual timestamps, not estimates.

A repository CI pass verifies formatting, static Terraform validation, unit/smoke tests, and Docker build only. It does not verify that AWS resources currently exist or that a live disaster-recovery drill has succeeded.
