# GitHub Actions CI/CD Pipeline

## Overview

Automated pipeline for building, testing, and deploying the ChatApp MERN stack.

## Pipeline Stages

### 1. Build & Test (Parallel)

- **Backend Build**: Node dependencies, linting, testing
- **Frontend Build**: Node dependencies, linting, build

### 2. Build Docker Images

- Build backend image with multi-stage build
- Build frontend image with Nginx
- Push to AWS ECR with commit SHA tag

### 3. Security Scan

- ECR image scanning for vulnerabilities
- (Optional) Trivy scanning

### 4. Update Manifests

- Update `kustomization.yml` with new image tags
- Commit and push to repository

### 5. Deploy via Argo CD

- Argo CD auto-sync triggers
- Manifests deployed to EKS cluster

### 6. Smoke Tests

- Health check endpoints
- Verify services are responding

### 7. Notifications

- Slack notifications on success/failure
- (Optional) PagerDuty for critical failures

## Setup

### 1. Create GitHub Secrets

Go to: Settings → Secrets and variables → Actions

Required secrets:

```
AWS_ACCOUNT_ID              (e.g., 123456789012)
AWS_ACCESS_KEY_ID           (IAM user key)
AWS_SECRET_ACCESS_KEY       (IAM user secret)
ARGOCD_SERVER               (e.g., https://argocd.example.com)
ARGOCD_TOKEN                (Argo CD API token)
SLACK_WEBHOOK_URL           (Slack incoming webhook)
```

### 2. Create ECR Repositories

```bash
aws ecr create-repository --repository-name chatapp-backend --region ap-south-1
aws ecr create-repository --repository-name chatapp-frontend --region ap-south-1
```

### 3. Create IAM User for CI/CD

```bash
# Create user
aws iam create-user --user-name github-actions

# Create access key
aws iam create-access-key --user-name github-actions

# Attach ECR push policy
aws iam attach-user-policy --user-name github-actions \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Attach EKS access for Argo CD sync
aws iam attach-user-policy --user-name github-actions \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy
```

### 4. Get Argo CD Token

```bash
# Forward Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login and get token
argocd login localhost:8080 --insecure --username=admin --password=<initial-password>

# Get API token
argocd account generate-token --account=admin
```

## Triggering Deployments

### Automatic (Recommended)

Deployments trigger automatically on:

```yaml
on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'backend/**'
      - 'frontend/**'
      - 'k8s/**'
```

### Manual Trigger

```bash
# Via GitHub CLI
gh workflow run deploy.yml -r main

# Via GitHub UI: Actions → CI/CD Pipeline → Run workflow
```

## Debugging Pipeline

### View Workflow Runs

```bash
# Via CLI
gh run list -w deploy.yml

# View specific run
gh run view <run-id>

# Stream logs
gh run view <run-id> --log
```

### View Docker Build Logs

In GitHub Actions UI:
- Click on workflow run
- Click "Build Docker Images" step
- Expand logs

### Common Issues

#### 1. AWS Credentials Error

```
Error: An error occurred (InvalidClientTokenId) when calling...
```

**Fix**: Verify AWS credentials in GitHub Secrets

#### 2. ECR Push Failed

```
Error: Unable to push image to registry...
```

**Fix**: Ensure ECR repositories exist and IAM user has push permissions

#### 3. Argo CD Sync Failed

```
Error: application not found
```

**Fix**: Verify application exists: `kubectl get applications -n argocd`

#### 4. Health Check Failed

```
Error: health check failed for backend
```

**Fix**: Wait longer or verify service endpoints are ready

## Customizing Pipeline

### Skip Deployment

Add `[skip deploy]` to commit message:

```bash
git commit -m "docs: update readme [skip deploy]"
```

### Change Deployment Branch

Edit `.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches:
      - main           # Only deploy from main
      # - develop     # Remove develop
```

### Add Additional Tests

```yaml
- name: Run integration tests
  working-directory: backend
  run: npm run test:integration

- name: Run E2E tests
  working-directory: frontend
  run: npm run test:e2e
```

### Add SonarQube Scanning

```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Monitoring

### Dashboard

View all workflow runs:
```
https://github.com/officialarun/full-stack_chatApp/actions
```

### Slack Integration

Get real-time notifications:
- ✅ Success: "Deployment successful"
- ❌ Failure: "Deployment failed"

Click "View Workflow" link in notification to debug

## Rollback

If deployment fails or has issues:

```bash
# Via Argo CD UI
# Applications → chatapp-prod → History → Rollback

# Or via CLI
argocd app rollback chatapp-prod --revision=0 \
  --server <ARGOCD_SERVER> \
  --auth-token <TOKEN>
```

## Performance Optimization

### Cache Docker Layers

```yaml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Parallel Jobs

Current pipeline already runs builds in parallel:

```
backend-build ──┐
                ├─→ build-and-push → security-scan → argocd-deploy
frontend-build ─┘
```

### Cancel Previous Runs

Add concurrency:

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true
```

## Secrets Management

### Rotate Secrets Regularly

```bash
# Regenerate AWS access key
aws iam create-access-key --user-name github-actions
aws iam delete-access-key --user-name github-actions --access-key-id <OLD_KEY>

# Update GitHub Secrets with new values
```

### Audit Secret Access

```bash
# View when secrets were last used
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=github-actions
```

## Advanced: Multi-Environment

Deploy to both dev and prod:

```yaml
jobs:
  deploy-dev:
    # Deploy to dev cluster
    
  deploy-prod:
    needs: deploy-dev
    # Manual approval required
    environment: production
    # Deploy to prod cluster
```

---

**For more help**: https://docs.github.com/en/actions
