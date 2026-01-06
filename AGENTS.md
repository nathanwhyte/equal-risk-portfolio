# Repository Guidelines

This repository is a monorepo containing a Rails frontend and a Python backend API for financial portfolio analysis.

## Prerequisites

- **Ruby**: Version specified in `.ruby-version` (Rails 8.0+)
- **Python**: 3.13+ (for the Python API)
- **Node.js**: Bun is used for JavaScript tooling
- **Database**: PostgreSQL
- **Package Managers**: `bundler` (Ruby), `bun` (JavaScript), `uv` (Python)

## Quick Setup

1. **Install system dependencies**: Ruby, Python 3.13+, Bun, PostgreSQL
2. **Run setup script**: `bin/setup`
3. **Install pre-commit hooks**: `pre-commit install`
4. **Set up Python API dependencies**: `uv pip sync api/uv.lock`

## Essential Commands

### Development
- `bin/dev` - Run Rails server with asset watchers
- `bin/rails server` - Run Rails server only
- `bin/rails console` - Open Rails console
- `bin/fmt` - Format all code (run before committing)
- `bin/rails test` - Run all tests
- `bin/rails test:system` - Run system tests

### Python API
- `uvicorn app.main:app --reload --app-dir api` - Run FastAPI server locally
- `python api/scripts/seed.py` - Run seed script

## Kubernetes Deployment

### Postgres Migration from Docker to Kubernetes

The Postgres database can be migrated from a Docker volume backup (created with `docker-volume-backup`) into a Kubernetes PVC-backed StatefulSet.

#### Prerequisites
- Kubernetes cluster with kubectl access
- Backup file in `.tar.gz` format (from docker-volume-backup)
- StatefulSet deployed (via `equal-risk-stack.yaml`)

#### Migration Steps

1. **Deploy the Postgres StatefulSet** (if not already deployed):
   ```bash
   kubectl apply -f equal-risk-stack.yaml
   ```

2. **Run the migration script**:
   ```bash
   bin/migrate-postgres-to-k8s ~/backups/backup-latest.tar.gz
   ```

   The script will:
   - Scale down the Postgres StatefulSet
   - Create a temporary pod with access to the PVC
   - Extract and restore the backup data
   - Fix file permissions
   - Scale the StatefulSet back up

3. **Verify the migration**:
   ```bash
   # Check Postgres pod is running
   kubectl get pods -n equal-risk -l app=postgres

   # Connect to database and verify data
   kubectl exec -it postgres-0 -n equal-risk -- psql -U equal_risk_portfolio_user -d equal_risk_portfolio_production -c "SELECT COUNT(*) FROM users;"
   ```

4. **Update application connections** (if needed):
   - The stack file already configures apps to use `postgres.equal-risk.svc.cluster.local`
   - After migration, you can remove the `external-postgres` Service and EndpointSlice from `equal-risk-stack.yaml`

#### Alternative: Manual Restore Job

If you prefer to use the Kubernetes Job manifest directly:

1. Scale down StatefulSet: `kubectl scale statefulset postgres --replicas=0 -n equal-risk`
2. Copy backup file into cluster (e.g., via `kubectl cp` or web server)
3. Update `BACKUP_FILE_PATH` in `k8s-restore-job.yaml`
4. Apply the job: `kubectl apply -f k8s-restore-job.yaml`
5. Monitor: `kubectl logs -f job/postgres-restore -n equal-risk`
6. Scale up: `kubectl scale statefulset postgres --replicas=1 -n equal-risk`

### Daily Postgres Backups to Garage

The Postgres StatefulSet is automatically backed up daily to Garage S3-compatible storage using a Kubernetes CronJob.

#### Prerequisites

- Garage deployment accessible from the `equal-risk` namespace
- Garage bucket `equal-risk-postgres-backups` must exist (create via garage-manager or manually)
- Garage S3 credentials secret `s3-provider-credentials` in the `equal-risk` namespace

#### Setup Steps

1. **Create the Garage bucket** (if not already created):
   ```bash
   # Using garage-manager
   kubectl exec -it deployment/garage-manager -n garage -- python /app/garage-manager.py list-buckets
   # Create bucket if needed (via Garage admin API or garage-manager)
   ```

2. **Create the S3 credentials secret** in the `equal-risk` namespace:
   ```bash
   # Option 1: Create new credentials
   kubectl exec -it garage-0 -n garage -- garage key new --name postgres-backup-key
   # Use the output to create the secret:
   kubectl create secret generic s3-provider-credentials \
     --from-literal=S3_PROVIDER_ACCESS_KEY='your-access-key-id' \
     --from-literal=S3_PROVIDER_SECRET_KEY='your-secret-key' \
     -n equal-risk

   # Option 2: Copy from garage namespace (if secret already exists there)
   kubectl get secret s3-provider-credentials -n garage -o yaml | \
     sed 's/namespace: garage/namespace: equal-risk/' | \
     kubectl apply -f -
   ```

3. **Deploy the backup resources**:
   ```bash
   kubectl apply -f k8s/postgres-backup-config.yaml
   kubectl apply -f k8s/postgres-backup-cronjob.yaml
   ```

4. **Verify the CronJob**:
   ```bash
   kubectl get cronjob postgres-backup -n equal-risk
   ```

#### Backup Details

- **Schedule**: Daily at midnight UTC (`0 0 * * *`)
- **Format**: Compressed SQL dump (`.sql.gz`) created with `pg_dump`
- **Retention**: 7 days (automatically cleaned up)
- **Storage**: Garage S3 bucket `equal-risk-postgres-backups`
- **Naming**: `postgres-backup-YYYY-MM-DD-HHMMSS.sql.gz`

#### Manual Backup Trigger

To manually trigger a backup job:

```bash
kubectl create job --from=cronjob/postgres-backup postgres-backup-manual -n equal-risk
```

Monitor the backup:

```bash
kubectl logs -f job/postgres-backup-manual -n equal-risk
```

#### Restoring from Backup

1. **Download backup from Garage**:
   ```bash
   kubectl exec -it deployment/garage-manager -n garage -- python /app/garage-manager.py download equal-risk-postgres-backups postgres-backup-2024-01-15-000000.sql.gz /tmp/backup.sql.gz
   ```

2. **Copy backup to local machine** (if needed):
   ```bash
   kubectl cp garage/garage-manager-<pod-id>:/tmp/backup.sql.gz ./backup.sql.gz
   ```

3. **Restore to Postgres**:
   ```bash
   # Get database credentials
   DB_USER=$(kubectl get secret equal-risk-secrets -n equal-risk -o jsonpath='{.data.EQUAL_RISK_PORTFOLIO_DATABASE_USERNAME}' | base64 -d)
   DB_NAME=$(kubectl get secret equal-risk-secrets -n equal-risk -o jsonpath='{.data.EQUAL_RISK_PORTFOLIO_DATABASE}' | base64 -d)

   # Restore (scale down StatefulSet first if needed)
   gunzip < backup.sql.gz | kubectl exec -i postgres-0 -n equal-risk -- psql -U $DB_USER -d $DB_NAME
   ```

   Or restore to a specific database:

   ```bash
   kubectl exec -i postgres-0 -n equal-risk -- psql -U $DB_USER -d $DB_NAME < <(gunzip < backup.sql.gz)
   ```

#### Troubleshooting

- **Check CronJob status**: `kubectl get cronjob postgres-backup -n equal-risk`
- **View recent jobs**: `kubectl get jobs -n equal-risk -l job-name=postgres-backup`
- **Check job logs**: `kubectl logs job/postgres-backup-<timestamp> -n equal-risk`
- **Verify bucket exists**: `kubectl exec -it deployment/garage-manager -n garage -- python /app/garage-manager.py list-files equal-risk-postgres-backups`
- **Check secret exists**: `kubectl get secret s3-provider-credentials -n equal-risk`

## Detailed Guidelines

For comprehensive development guidelines, coding standards, testing requirements, and workflow rules, see **`.cursor/rules/project-guidelines.mdc`**.

**Note**: If `.cursor/rules/project-guidelines.mdc` does not exist, generate it based on the content from this repository's development guidelines. The rules file provides optional context for Cursor AI assistance.
