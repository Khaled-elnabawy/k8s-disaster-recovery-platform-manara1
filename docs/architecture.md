# Solution Architecture

The architecture diagram is maintained in this folder and shown from the root README. The submission reviewer requires a diagram made with official AWS Architecture Icons, not an AI-generated diagram.

## Diagram components

- GitHub and GitHub Actions: source control, validation, tests, and Docker image build.
- Amazon ECR: stores the built application image.
- Terraform: provisions the network and core AWS resources.
- Amazon VPC: public/private subnet design across two Availability Zones.
- Amazon EKS: runs the Flask API and PostgreSQL StatefulSet.
- Amazon EBS: persistent storage for PostgreSQL through the EBS CSI driver and a PVC.
- Velero: creates Kubernetes backups and coordinates restores.
- Amazon S3: versioned and encrypted storage for Velero backup objects.
- EBS snapshots: persistent-volume recovery when configured and verified.
- IAM/OIDC/IRSA: grants the EBS CSI driver and Velero scoped AWS access.

## Architecture assumptions and limits

This is a single-region workload-recovery design in eu-central-1, not a multi-region Route 53 failover architecture. A diagram describes the intended design; it does not prove the AWS resources are deployed or a restore has passed. The deployed Helm values, IAM policy, backup location, and actual restore evidence must be checked before claiming recovery success.

## Icon source

Use the official AWS Architecture Icons in the submission diagram: https://aws.amazon.com/architecture/icons/
The SVG preview and editable Draw.io source use AWS service icon artwork. Review and finalize the Draw.io layout before submission if the reviewer requires the final diagram to be authored manually.