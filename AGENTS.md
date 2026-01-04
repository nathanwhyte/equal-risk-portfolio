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

## Detailed Guidelines

For comprehensive development guidelines, coding standards, testing requirements, and workflow rules, see **`.cursor/rules/project-guidelines.mdc`**.

**Note**: If `.cursor/rules/project-guidelines.mdc` does not exist, generate it based on the content from this repository's development guidelines. The rules file provides optional context for Cursor AI assistance.
