# Kubernetes Manifests Guide

## Structure

```
k8s/
├── base/                      # Base manifests (kustomize)
│   ├── namespace/
│   ├── mongodb/               # StatefulSet, Service, Secret
│   ├── backend/               # Deployment, Service, HPA, PDB
│   ├── frontend/              # Deployment, Service, HPA, PDB
│   ├── ingress/               # Ingress, NetworkPolicies
│   └── kustomization.yml      # Base kustomization
│
├── overlays/                  # Environment-specific
│   ├── dev/                   # Dev overrides
│   │   └── kustomization.yml
│   │
│   └── prod/                  # Prod overrides
│       ├── kustomization.yml
│       └── secrets.env        # Prod secrets
│
└── argocd/                    # Argo CD config
    ├── applications.yml       # App definitions
    └── argocd-config.yml      # Argo CD setup
```

## Deployment

### Deploy to Development

```bash
# Using kubectl + kustomize
kubectl apply -k k8s/overlays/dev

# Or using kustomize directly
kustomize build k8s/overlays/dev | kubectl apply -f -
```

### Deploy to Production

```bash
# Manual (not recommended for prod)
kubectl apply -k k8s/overlays/prod

# Preferred: Via Argo CD (GitOps)
kubectl apply -f k8s/argocd/applications.yml
```

## Kustomize Configuration

### Base Resources

The base configuration includes:

- **Namespace**: `chatapp`
- **MongoDB**: StatefulSet with 3 replicas
- **Backend**: Deployment with 2 replicas, HPA, PDB
- **Frontend**: Deployment with 2 replicas, HPA, PDB
- **Ingress**: ALB ingress controller
- **Network Policies**: Restrict traffic

### Development Overlay

Changes from base:

```yaml
replicas:
  - name: backend
    count: 1    # Reduce from 2
  - name: frontend
    count: 1    # Reduce from 2
  - name: mongodb
    count: 1    # Reduce from 3

resource.limits:
  backend: 256Mi / 200m
  frontend: 128Mi / 100m
```

### Production Overlay

```yaml
replicas:
  - name: backend
    count: 3    # Maintain HA
  - name: frontend
    count: 3
  - name: mongodb
    count: 3

resource.limits:
  backend: 512Mi / 500m
  frontend: 256Mi / 200m

secrets: prod-specific values
```

## Managing Secrets

### Create Secrets

```bash
# Create MongoDB credentials secret
kubectl create secret generic mongodb-credentials \
  --from-literal=MONGO_INITDB_ROOT_USERNAME=admin \
  --from-literal=MONGO_INITDB_ROOT_PASSWORD=changeme \
  --from-literal=MONGODB_URI='mongodb://admin:changeme@mongodb:27017' \
  -n chatapp

# Create backend secrets
kubectl create secret generic backend-secrets \
  --from-literal=JWT_SECRET=your-secret \
  --from-literal=CLOUDINARY_CLOUD_NAME=... \
  -n chatapp
```

### Rotate Secrets

```bash
# Update secret
kubectl patch secret backend-secrets -n chatapp -p \
  '{"data":{"JWT_SECRET":"'$(echo -n newvalue | base64)'"}}'

# Restart pods to pick up new secret
kubectl rollout restart deployment/backend -n chatapp
```

### Use AWS Secrets Manager

For production, use External Secrets Operator:

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system --create-namespace

# Create SecretStore
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: chatapp
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-south-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF
```

## Scaling

### Horizontal Pod Autoscaler (HPA)

```bash
# Check current HPA status
kubectl get hpa -n chatapp

# Manually trigger scaling
kubectl autoscale deployment backend \
  --min=2 --max=10 \
  --cpu-percent=70 \
  -n chatapp

# View HPA metrics
kubectl get hpa -n chatapp -w
```

### Manual Pod Scaling

```bash
# Scale backend to 5 replicas
kubectl scale deployment backend --replicas=5 -n chatapp

# Watch scaling progress
kubectl get pods -n chatapp -w
```

## Monitoring Pods

### View Logs

```bash
# Current logs
kubectl logs deployment/backend -n chatapp

# Previous logs (if crashed)
kubectl logs deployment/backend -n chatapp --previous

# Follow logs (tail -f)
kubectl logs deployment/backend -n chatapp -f

# Logs from all pods
kubectl logs -l app=backend -n chatapp --all-containers=true
```

### View Events

```bash
# Pod events
kubectl describe pod <pod-name> -n chatapp

# Deployment events
kubectl describe deployment backend -n chatapp

# All events
kubectl get events -n chatapp --sort-by='.lastTimestamp'
```

### Port Forward

```bash
# Access backend service locally
kubectl port-forward svc/backend 5001:5001 -n chatapp

# Access MongoDB
kubectl port-forward svc/mongodb-client 27017:27017 -n chatapp

# Access Grafana (if deployed)
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

## Rolling Updates

### Update Deployment Image

```bash
# Set new image
kubectl set image deployment/backend backend=myrepo/backend:v2 \
  -n chatapp --record

# Check rollout status
kubectl rollout status deployment/backend -n chatapp

# View rollout history
kubectl rollout history deployment/backend -n chatapp

# Rollback to previous version
kubectl rollout undo deployment/backend -n chatapp
```

### Canary Deployment (Manual)

```bash
# Scale current to 1 replica
kubectl scale deployment backend --replicas=1 -n chatapp

# Deploy new version separately
kubectl run backend-canary --image=myrepo/backend:v2 -n chatapp

# Monitor metrics
kubectl top pods -n chatapp

# Promote canary to full rollout
kubectl set image deployment/backend backend=myrepo/backend:v2 -n chatapp
```

## Debugging

### Pod Debugging

```bash
# Exec into pod
kubectl exec -it <pod-name> -n chatapp -- /bin/sh

# Check environment variables
kubectl exec <pod-name> -n chatapp -- env

# Test connectivity
kubectl exec <pod-name> -n chatapp -- curl http://backend:5001/health
```

### DNS Debugging

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=alpine --restart=Never -- \
  nslookup mongodb.chatapp.svc.cluster.local

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://backend:5001/health
```

### Network Policies

```bash
# View network policies
kubectl get networkpolicies -n chatapp

# Verify connectivity
kubectl exec <pod> -n chatapp -- curl http://backend:5001

# Check iptables rules on node
kubectl debug node/<node-name> -it --image=ubuntu
```

## Validating Manifests

```bash
# Validate syntax
kubectl apply -f k8s/base/ --dry-run=client

# Validate with schema
kustomize build k8s/overlays/prod | kubectl apply -f - --dry-run=client

# Check for deprecated APIs
kubewarden run k8s/overlays/prod
```

## Best Practices

1. ✅ Use Kustomize for environment management
2. ✅ Define resource requests and limits
3. ✅ Use health checks (liveness + readiness)
4. ✅ Implement Pod Disruption Budgets
5. ✅ Use NetworkPolicies for security
6. ✅ Apply RBAC policies
7. ✅ Use secrets for sensitive data
8. ✅ Version control all manifests
9. ✅ Use labels for organization
10. ✅ Monitor resource usage

---

For more info: https://kubernetes.io/docs/
