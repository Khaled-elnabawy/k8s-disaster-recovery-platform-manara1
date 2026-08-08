# Kubernetes Disaster Recovery Platform
 
A production-style AWS infrastructure project demonstrating end-to-end disaster recovery for stateful Kubernetes workloads — built with Terraform, EKS, Velero, and a validated backup/restore drill with measured RTO and RPO.
 
## Overview
 
Most portfolio projects stop at "I deployed an app on Kubernetes." This project goes further: it proves the infrastructure can survive a disaster. A full namespace — including a stateful PostgreSQL database — was deliberately deleted and restored from backup, with the recovery time and data integrity documented below.
 
## Architecture
 
```
GitHub (source + CI)
   │
   ▼
GitHub Actions ──► Amazon ECR (Docker image)
   │
   ▼
Terraform ──► AWS (VPC, IAM, EKS, S3, ECR)
                        │
                        ▼
                 EKS Cluster
            ┌───────────┴───────────┐
            │                       │
      Flask API              PostgreSQL (StatefulSet + EBS PVC)
            │                       │
            └───────────┬───────────┘
                         ▼
                      Velero ──► S3 (backup metadata) + EBS Snapshots (volume data)
                         │
                         ▼
              Prometheus + Grafana (backup/restore monitoring)
```
 
## Tech Stack
 
| Category | Tools |
|---|---|
| Infrastructure as Code | Terraform (modular: VPC, IAM, EKS, S3) |
| Container Orchestration | Amazon EKS, kubectl, Helm |
| Backup & Disaster Recovery | Velero, AWS EBS Snapshots, S3 |
| Application | Flask API, PostgreSQL (StatefulSet) |
| CI | GitHub Actions (Terraform validation, Docker build/push to ECR) |
| Monitoring | Prometheus, Grafana |
| Cloud Provider | AWS (VPC, EKS, IAM/IRSA, S3, ECR, EBS) |
 
## Infrastructure
 
All infrastructure is provisioned through modular Terraform:
 
- **VPC module** — public/private subnets across 2 AZs, NAT Gateway, Internet Gateway, route tables
- **IAM module** — least-privilege roles for the EKS cluster and node group
- **EKS module** — managed EKS cluster (Kubernetes 1.34) with a managed node group
- **S3 module** — versioned, encrypted bucket for Velero backup storage
- IAM Roles for Service Accounts (IRSA) used for both the EBS CSI driver and Velero, avoiding long-lived static credentials
## Sample Application
 
A minimal Flask REST API backed by PostgreSQL, deployed as:
- Flask `Deployment` + `Service`
- PostgreSQL `StatefulSet` with a `PersistentVolumeClaim` backed by an EBS volume
This gives the backup/restore drill real, stateful data to work with — not just stateless manifests.
 
## Backup Strategy
 
Velero is installed via Helm with IRSA-based AWS access (no static credentials mounted in the pod). It performs:
 
- **Snapshot-based backups** of EBS-backed PersistentVolumes
- **On-demand backups** for testing and pre-change safety
- **Scheduled daily backups** (`0 2 * * *`, 30-day retention)
Backups are stored in S3; volume data is captured via native EBS snapshots.
 
## Disaster Recovery Drill
 
This is the core of the project. The steps performed, in order:
 
1. Inserted known test records into the PostgreSQL database via the Flask API
2. Took a Velero backup of the `demo-app` namespace
3. **Deleted the entire `demo-app` namespace** — Postgres, Flask, PVCs, Secrets, everything
4. Confirmed the namespace was fully gone (`NotFound`)
5. Ran `velero restore create --from-backup <backup-name>`
6. Verified every resource came back and the API returned the exact same records as before deletion
### Results
 
| Metric | Result |
|---|---|
| Resources restored | 19 / 19 (100%) |
| Data integrity | 100% match — all pre-disaster records recovered |
| RTO (Recovery Time Objective) | ~2 minutes |
| RPO (Recovery Point Objective) | 0 — no data loss |
 
## Monitoring
 
`kube-prometheus-stack` (Prometheus + Grafana + Alertmanager) is deployed via Helm. A `ServiceMonitor` exposes Velero's `/metrics` endpoint to Prometheus, feeding a Grafana dashboard that tracks:
 
- Total backup count and success/failure rate
- Total restore count
- Time since last successful backup
## CI Pipeline
 
GitHub Actions runs on every push to `main`:
 
1. **Terraform Format & Validate** — `terraform fmt -check` and `terraform validate` against all modules
2. **Build & Push Docker Image** — builds the Flask app image and pushes it to Amazon ECR, tagged with both `latest` and the commit SHA
AWS access uses a dedicated IAM user scoped to ECR push/pull only — not the account's primary credentials.
 
## Repository Structure
 
```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── iam/
│   │   ├── eks/
│   │   └── s3/
│   └── environments/
│       └── prod/
├── k8s/
│   └── demo-app/          # Postgres + Flask manifests
├── app/                    # Flask application source + Dockerfile
├── .github/
│   └── workflows/
│       └── ci.yml
└── docs/                    # Architecture diagram, DR report, screenshots
```
 
## Key Engineering Decisions
 
- **IRSA over static credentials** — both the EBS CSI driver and Velero authenticate via IAM Roles for Service Accounts rather than access keys baked into the cluster.
- **Modular Terraform** — infrastructure is split into reusable modules instead of one monolithic configuration, making it easier to extend or reuse across environments.
- **Namespace-scoped destruction, not simulated** — the DR drill deletes real Kubernetes resources rather than relying on a theoretical failure scenario, so the recovery numbers above are measured, not estimated.
- **Least-privilege IAM everywhere** — every role (cluster, nodes, EBS CSI, Velero, CI) is scoped to only the permissions it needs.
## What I'd Improve Next
 
- Cross-region backup replication for full region-loss resilience
- Automated alerting on backup failure via Alertmanager → Slack/email
- Scheduled, automated DR drills (not just a one-time manual test) with results tracked over time
## Author
 
Khaled Elnabawy — Junior DevOps Engineer
[LinkedIn](https://www.linkedin.com/in/khaled-elnabawy-379407268) · [GitHub](https://github.com/Khaled-elnabawy)
