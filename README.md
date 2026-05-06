# Production-Grade DevOps Architecture for ChatApp MERN Stack

## Overview

This is a **complete, production-ready DevOps infrastructure** for a full-stack MERN (MongoDB, Express, React, Node.js) chat application deployed on AWS EKS with Kubernetes, Terraform, and GitOps via Argo CD.

---

## Architecture Summary

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Cloud (ap-south-1)                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              VPC (10.0.0.0/16)                      │   │
│  │                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐         │   │
│  │  │  Public Subnet  │  │  Public Subnet  │         │   │
│  │  │  (ALB/NAT GW)   │  │  (ALB/NAT GW)   │         │   │
│  │  └────────┬────────┘  └────────┬────────┘         │   │
│  │           │                    │                   │   │
│  │           └───────┬────────────┘                   │   │
│  │                   │                                │   │
│  │           ┌───────▼─────────┐                      │   │
│  │           │  ALB (80/443)   │                      │   │
│  │           └───────┬─────────┘                      │   │
│  │                   │                                │   │
│  │  ┌────────────────▼──────────────────┐            │   │
│  │  │    EKS Cluster (Private)          │            │   │
│  │  │  ┌──────────┐  ┌──────────┐      │            │   │
│  │  │  │ Frontend │  │ Backend  │      │            │   │
│  │  │  │  Pods    │  │  Pods    │      │            │   │
│  │  │  └──────────┘  └──────┬───┘      │            │   │
│  │  │                       │          │            │   │
│  │  │                   ┌───▼──────┐   │            │   │
│  │  │                   │ MongoDB  │   │            │   │
│  │  │                   │ StatefulSet │            │   │
│  │  │                   └──────────┘   │            │   │
│  │  └───────────────────────────────────┘            │   │
│  │                                                     │   │
│  │  ┌─────────────────────────────────────────────┐  │   │
│  │  │    Private Subnets (EKS Worker Nodes)       │  │   │
│  │  │    Multi-AZ Deployment (2 AZs)             │  │   │
│  │  └─────────────────────────────────────────────┘  │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Monitoring & Logging                               │  │
│  │  - CloudWatch                                        │  │
│  │  - Prometheus & Grafana                             │  │
│  │  - Fluent Bit                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

CI/CD Pipeline (GitHub Actions → Argo CD)
├── Build & Test
├── Docker Image Push to ECR
├── Security Scan
├── Deploy to EKS via Argo CD
└── Smoke Tests
```

---

## Directory Structure

```
project/
│
├── frontend/                          # React/Vite application
├── backend/                           # Express.js API server
│
├── terraform/                         # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                      # VPC, subnets, security groups
│   │   ├── eks/                      # EKS cluster, node groups
│   │   ├── mongodb/                  # DocumentDB or EC2 MongoDB
│   │   └── monitoring/               # CloudWatch, SNS, alerts
│   │
│   ├── environments/
│   │   ├── dev/                      # Development environment
│   │   └── prod/                     # Production environment
│   │
│   └── state-backend.tf              # S3 + DynamoDB for state
│
├── k8s/                              # Kubernetes manifests
│   ├── base/                         # Base Kustomize resources
│   │   ├── namespace/
│   │   ├── mongodb/
│   │   ├── backend/
│   │   ├── frontend/
│   │   ├── ingress/
│   │   └── kustomization.yml
│   │
│   ├── overlays/                     # Environment-specific overlays
│   │   ├── dev/
│   │   └── prod/
│   │
│   └── argocd/                       # Argo CD configuration
│       ├── applications.yml
│       └── argocd-config.yml
│
├── monitoring/                        # Monitoring stack
│   ├── prometheus/
│   │   └── prometheus-config.yml
│   │
│   ├── grafana/
│   │   └── grafana-dashboard.yml
│   │
│   └── fluent-bit-config.yml
│
├── .github/
│   └── workflows/
│       └── deploy.yml                # GitHub Actions CI/CD
│
└── README.md                         # This file
```

---

## Key Features

###  High Availability
- **Multi-AZ Deployment**: EKS nodes spread across 2+ availability zones
- **Pod Anti-Affinity**: Pods scheduled on different nodes
- **Rolling Updates**: Zero-downtime deployments
- **Pod Disruption Budgets**: Ensure minimum replicas during maintenance
- **Read Replicas**: MongoDB replica set with 3 instances

###  Autoscaling
- **Horizontal Pod Autoscaler (HPA)**: Scale pods based on CPU/memory
- **Cluster Autoscaler**: Scale EKS nodes automatically
- **Frontend**: Min 2, Max 4 replicas (dev: 1 min)
- **Backend**: Min 2, Max 5 replicas (dev: 1 min)

###  Secure & Compliant
- **Network Policies**: Restrict traffic between pods
- **Security Groups**: Fine-grained AWS security
- **Secrets Management**: Kubernetes secrets + AWS Secrets Manager
- **RBAC**: Role-based access control in Kubernetes
- **TLS/SSL**: ALB with certificate management
- **Non-root Containers**: Security best practice

###  CI/CD & GitOps
- **GitHub Actions**: Automated build, test, push
- **Argo CD**: GitOps deployment, auto-sync
- **ECR**: Private Docker registry on AWS
- **Image Scanning**: Vulnerability scanning before deployment
- **Rollback**: Easy rollback via Argo CD

###  Monitoring & Logging
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Fluent Bit**: Log aggregation to CloudWatch
- **CloudWatch Alarms**: Alerts on metrics
- **Health Checks**: Liveness and readiness probes

###  Disaster Recovery
- **Multi-Region Ready**: Design for secondary region (ap-southeast-1)
- **Backup & Restore**: DocumentDB automatic backups
- **State Backup**: Terraform state in S3 with versioning

---

## Quick Start Guide

### Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.0
- kubectl >= 1.28
- Docker
- Git
- GitHub Personal Access Token (for Argo CD)

### Phase 1: Set Up AWS Infrastructure with Terraform

#### Step 1: Initialize Terraform backend

```bash
cd terraform/

# Create S3 bucket and DynamoDB table for state
terraform init -backend=false -config=state-backend.tf
terraform apply -target='aws_s3_bucket.terraform_state' \
                  -target='aws_dynamodb_table.terraform_locks'
```

#### Step 2: Deploy Development Environment

```bash
cd environments/dev/

terraform init
terraform plan
terraform apply
```

**Outputs**: EKS cluster name, endpoint, kubectl configuration command

#### Step 3: Deploy Production Environment (optional)

```bash
cd ../prod/

terraform init
terraform plan
terraform apply -var="alert_email=your-email@example.com"
```

### Phase 2: Configure Kubernetes Access

```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name chatapp-eks-dev

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### Phase 3: Deploy Argo CD

```bash
# Create argocd namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl -n argocd wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

# Port-forward to access Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Access Argo CD**: https://localhost:8080

### Phase 4: Deploy Applications via Argo CD

```bash
# Update GitHub token and repo URL in argocd-config.yml
kubectl apply -f k8s/argocd/argocd-config.yml
kubectl apply -f k8s/argocd/applications.yml

# Check application status
kubectl get applications -n argocd
```

### Phase 5: Deploy Monitoring Stack

```bash
kubectl create namespace monitoring

# Deploy Prometheus
kubectl apply -f monitoring/prometheus/prometheus-config.yml -n monitoring

# Deploy Grafana
kubectl apply -f monitoring/grafana/grafana-dashboard.yml -n monitoring

# Deploy Fluent Bit
kubectl apply -f monitoring/fluent-bit-config.yml -n monitoring
```

---

## Deployment Workflow

### Automated CI/CD Pipeline (GitHub Actions)

The pipeline is triggered on every push to `main` branch:

```
┌─────────────────┐
│  Push to main   │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Build   │  (backend & frontend tests/build)
    └────┬────┘
         │
    ┌────▼──────────────┐
    │ Build Docker      │  (multi-stage builds)
    │ Images & Push ECR │
    └────┬──────────────┘
         │
    ┌────▼────────────┐
    │ Security Scan   │  (ECR image scanning)
    └────┬────────────┘
         │
    ┌────▼──────────────┐
    │ Update K8s        │  (kustomization.yml)
    │ Manifests         │
    └────┬──────────────┘
         │
    ┌────▼────────────────┐
    │ Argo CD Auto-Sync   │  (GitOps deployment)
    └────┬────────────────┘
         │
    ┌────▼────────────┐
    │ Smoke Tests     │  (health checks)
    └────┬────────────┘
         │
    ┌────▼───────────────┐
    │ Notify Success      │  (Slack/email)
    │ or Rollback         │
    └─────────────────────┘
```

### GitHub Secrets Required

```
AWS_ACCOUNT_ID              # For ECR registry
AWS_ACCESS_KEY_ID          # AWS credentials
AWS_SECRET_ACCESS_KEY      # AWS credentials
ARGOCD_SERVER              # Argo CD server URL
ARGOCD_TOKEN               # Argo CD API token
SLACK_WEBHOOK_URL          # For notifications
```

---

## Production Checklist

### Pre-Deployment

- [ ] Update MongoDB credentials in `secrets.env`
- [ ] Set up AWS KMS for encryption
- [ ] Configure AWS WAF rules
- [ ] Add SSL certificate to ALB
- [ ] Update domain DNS records to ALB
- [ ] Configure CloudTrail for audit logs
- [ ] Set up AWS Budget alerts
- [ ] Create backup schedule

### Post-Deployment

- [ ] Verify all pods running: `kubectl get pods -n chatapp`
- [ ] Check service endpoints: `kubectl get endpoints -n chatapp`
- [ ] Test application health: `curl https://chat.yourdomain.com/health`
- [ ] Monitor initial metrics in Grafana
- [ ] Test failover scenarios
- [ ] Document runbooks for on-call team
- [ ] Set up PagerDuty/Opsgenie integration

---

## Scaling & Performance Tuning

### Horizontal Scaling (Pod Replicas)

```bash
# Override HPA manually (if needed)
kubectl autoscale deployment backend -n chatapp --min=3 --max=10 --cpu-percent=70
```

### Vertical Scaling (Resource Limits)

Update `resource.limits` in `k8s/base/{backend,frontend}/backend.yml`

### Database Scaling

For DocumentDB, upgrade instance class or add read replicas:

```bash
# In prod/main.tf
documentdb_instance_class = "db.r6g.xlarge"
documentdb_instance_count = 5
```

---

## Troubleshooting Guide

### Pod not starting

```bash
kubectl describe pod <pod-name> -n chatapp
kubectl logs <pod-name> -n chatapp --previous  # If crashed
```

### Database connection issues

```bash
# Test MongoDB connectivity
kubectl exec -it mongodb-0 -n chatapp -- mongosh -u admin -p <password>

# Check connection string
kubectl get secret mongodb-credentials -n chatapp -o jsonpath='{.data.MONGODB_URI}' | base64 -d
```

### Argo CD sync failures

```bash
kubectl get applications -n argocd
argocd app get chatapp-prod --server <ARGOCD_SERVER>
argocd app logs chatapp-prod --server <ARGOCD_SERVER>
```

### High latency/errors

```bash
# Check node resource usage
kubectl top nodes
kubectl top pods -n chatapp

# View metrics in Grafana dashboard
# kubectl port-forward svc/grafana -n monitoring 3000:80
```

---

## Cost Optimization

1. **Dev Environment**: Use smaller instances (`t3.small`)
2. **Pod resource requests**: Set appropriate requests to avoid overprovisioning
3. **Cluster Autoscaler**: Scale down unused nodes
4. **Reserved Instances**: For prod, use RI or Savings Plans
5. **Spot Instances**: For non-critical workloads (optional)
6. **EBS**: Use GP3 instead of GP2 for better cost-performance

---

## Multi-Region Failover Design

### Architecture (Design Level)

```
Primary Region: ap-south-1          Secondary Region: ap-southeast-1
┌─────────────────────────┐          ┌──────────────────────────┐
│   EKS Cluster           │          │   EKS Cluster (standby)  │
│   - Active              │          │   - On-demand replicas   │
│   - MongoDB Primary     │ ◄────────┤   - MongoDB Replicas     │
└─────────────────────────┘          └──────────────────────────┘
         │                                      ▲
         │ DNS Failover                         │
         │ (Route53 health checks)              │
         └──────────────────────────────────────┘
```

### Implementation Steps

1. **Route53**: Set up failover routing policy
2. **Health Checks**: Configure health check endpoints
3. **MongoDB Replication**: Enable cross-region replication
4. **State Sync**: S3 cross-region replication for Terraform state
5. **DNS TTL**: Set to 60s for faster failover
6. **Testing**: Regular DR drills (quarterly)

---

## Monitoring & Alerts

### Key Metrics

```
Backend:
  - HTTP request rate (5min)
  - Error rate (5xx errors)
  - Response time (p95, p99)
  - DB connection pool usage

Frontend:
  - Page load time
  - JavaScript errors
  - API error rate

Infrastructure:
  - Node CPU/Memory utilization
  - Pod restart count
  - Network latency
  - Storage IOPS
```

### Alert Rules

```yaml
- High CPU (>80%): 5min
- High Memory (>85%): 5min
- Pod CrashLoopBackOff: immediate
- Database unavailable: immediate
- High error rate (>5%): 5min
- High latency (p95>1s): 5min
```

---

## Security Best Practices

1.  **Network Policies**: Implemented (ingress/egress rules)
2.  **RBAC**: EKS IAM roles for service accounts (IRSA)
3.  **Secrets**: AWS Secrets Manager + K8s Secrets
4.  **Encryption**: EBS volumes, RDS, S3, TLS
5.  **Non-root**: All containers run as non-root
6.  **Image Scanning**: ECR image scan on push
7.  **Audit Logs**: CloudTrail enabled
8.  **WAF**: ALB integrated with AWS WAF
9.  **Secret Rotation**: Monthly rotation policy
10.  **Backup**: Automated backups with encryption

---

## Support & Documentation

- **Terraform Docs**: See `terraform/README.md`
- **Kubernetes Manifests**: See `k8s/README.md`
- **Argo CD Docs**: https://argo-cd.readthedocs.io/
- **AWS EKS**: https://docs.aws.amazon.com/eks/
- **MongoDB**: https://docs.mongodb.com/

---

## License

MIT - See LICENSE file

---

## Authors

- **Infrastructure**: Terraform modules by DevOps team
- **Kubernetes**: K8s manifests by Platform team
- **CI/CD**: GitHub Actions pipeline by DevOps team

---

**Last Updated**: May 6, 2026  
**Version**: 1.0.0  
**Status**: Production Ready
