# Disaster Recovery Runbook

> **Warning:** The namespace deletion below is destructive. Use only a disposable test cluster and ensure the selected backup is complete before deleting anything.

## 1. Validate Terraform

From the repository root:

~~~bash
terraform -chdir=terraform/environments/prod init
terraform -chdir=terraform/environments/prod fmt -check
terraform -chdir=terraform/environments/prod validate
terraform -chdir=terraform/environments/prod plan
~~~

Inspect the plan carefully before applying it; EKS and NAT Gateway resources can incur ongoing charges.

## 2. Create application credentials securely

Create the namespace and PostgreSQL credentials from a local terminal. Do not commit passwords to Git:

~~~bash
kubectl apply -f k8s/demo-app/namespace.yaml
DB_PASSWORD="$(openssl rand -base64 32)"
kubectl -n demo-app create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=appuser \
  --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" \
  --from-literal=POSTGRES_DB=appdb
kubectl apply -f k8s/demo-app/postgres.yaml
~~~

Publish the application image to ECR, then replace ACCOUNT_ID in k8s/demo-app/flask-app.yaml with the AWS account ID and deploy:

~~~bash
kubectl apply -f k8s/demo-app/flask-app.yaml
kubectl -n demo-app rollout status statefulset/postgres --timeout=300s
kubectl -n demo-app rollout status deployment/flask-app --timeout=300s
~~~

## 3. Configure Velero

The file k8s/velero/values.yaml contains a Helm values template. Replace the bucket and role placeholders with the Terraform outputs for the backup bucket and Velero IAM role. The AWS plugin image/version and IAM permissions must match the Velero version being installed.

~~~bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update
helm upgrade --install velero vmware-tanzu/velero \
  --namespace velero --create-namespace \
  --values k8s/velero/values.yaml
kubectl -n velero get pods
velero backup-location get
velero snapshot-location get
~~~

Do not continue until Velero is Ready and the backup location is Available. Confirm the Velero service account is annotated with the intended IRSA role, and verify that the EBS CSI add-on is Active.

## 4. Insert a known test record

In terminal A, port-forward the API:

~~~bash
kubectl -n demo-app port-forward svc/flask-app 8080:80
~~~

In terminal B, save the response from before the drill:

~~~bash
curl -sS -X POST http://127.0.0.1:8080/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"dr-check-record"}'
curl -sS http://127.0.0.1:8080/users
~~~

## 5. Create and inspect a backup

~~~bash
BACKUP="demo-app-dr-$(date -u +%Y%m%dT%H%M%SZ)"
date -u +%Y-%m-%dT%H:%M:%SZ
velero backup create "$BACKUP" --include-namespaces demo-app --wait
velero backup describe "$BACKUP" --details
velero backup get "$BACKUP"
~~~

Only proceed if the backup phase is Completed and the database persistent-volume recovery path is confirmed.

## 6. Restore drill — destructive step

First verify the current context is the intended disposable cluster:

~~~bash
kubectl config current-context
read -r -p 'Type DELETE-demo-app to continue: ' CONFIRM
test "$CONFIRM" = "DELETE-demo-app" || { echo "Cancelled"; exit 1; }
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl delete namespace demo-app --wait=true
velero restore create demo-app-restore --from-backup "$BACKUP" --wait
kubectl wait --for=condition=Ready pods --all -n demo-app --timeout=300s
END_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'Recovery start: %s\nRecovery end: %s\nBackup: %s\n' "$START_UTC" "$END_UTC" "$BACKUP"
~~~

Check the restore description, events, deployments, pods, Services, PVCs, and the same test record from step 4.

## 7. Measure and record

- **RTO:** disruption start until the application is validated healthy.
- **RPO:** age of the newest application data confirmed recoverable at the disruption time.

Record actual command output, timestamps, pre/post restore record values, restore phase, and missing resources in docs/validation-status.md. Do not report numeric RTO/RPO until a live test verifies them.