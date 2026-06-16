# Getting Help & Troubleshooting

This guide helps you troubleshoot issues and understand project components.

## Documentation Map

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **README.md** | Complete setup & deployment guide | First-time setup |
| **QUICKSTART.md** | Fast command reference | Quick lookups |
| **PROJECT_SUMMARY.md** | Project overview & features | Understanding scope |
| **INTERVIEW_GUIDE.md** | Interview preparation | Before interviews |
| **FILE_MANIFEST.md** | Complete file listing | Understanding structure |
| **CONTRIBUTING.md** | Code contribution guidelines | Making changes |
| **GETTING_HELP.md** | This file | Troubleshooting |

## 🔍 Troubleshooting by Symptom

### Local Development Issues

**Docker Compose won't start**
```bash
# Check if ports are in use
lsof -i :8000  # API
lsof -i :9090  # Prometheus
lsof -i :3000  # Grafana

# Clean up old containers
docker-compose down -v

# Rebuild images
docker-compose build --no-cache

# Start with verbose logging
docker-compose up --verbose
```

**API endpoint returns 404**
```bash
# Check container is running
docker ps | grep document-qa-api

# View logs
docker logs document-qa-api

# Test directly
curl -v http://localhost:8000/health

# Verify image
docker images | grep document-qa-api
```

**Tests fail locally**
```bash
# Install dependencies fresh
pip install -r app/requirements.txt --force-reinstall

# Run with verbose output
pytest app/test_main.py -v -s

# Run specific test
pytest app/test_main.py::test_health_check -v

# Check test coverage
pytest app/test_main.py --cov=app
```

### Terraform Issues

**Terraform initialization fails**
```bash
cd terraform

# Clear local state
rm -rf .terraform/

# Reinitialize
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstatestorage" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=mlops.tfstate"

# Check backend configuration
terraform backend show

# Validate configuration
terraform validate
```

**Azure authentication fails**
```bash
# Login again
az login

# Check current account
az account show

# Set subscription
az account set --subscription <subscription-id>

# Verify permissions
az role assignment list --include-inherited --output table
```

**Resource creation times out**
```bash
# Check AKS creation status
az aks show --name mlops-aks --resource-group mlops-rg \
  --query provisioningState

# Check specific resource
az resource show --id <resource-id> --query properties.provisioningState

# Increase timeout if needed
terraform apply -parallelism=1  # Reduce parallelism
```

### Kubernetes Issues

**kubectl commands not working**
```bash
# Verify kubeconfig
kubectl config view

# Check current context
kubectl current-context

# Set context
kubectl config use-context mlops-aks

# Test connection
kubectl get nodes

# Check credentials
cat ~/.kube/config | base64 -d | head -20
```

**Pod won't start**
```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n production

# Check resource availability
kubectl describe nodes

# Check resource requests vs available
kubectl top nodes
kubectl top pods -n production

# View pod logs
kubectl logs <pod-name> -n production

# Check for pull image errors
kubectl get events -n production --sort-by='.lastTimestamp'
```

**Pod crashing or restarting**
```bash
# Check restart count
kubectl get pods -n production

# View crash logs (previous)
kubectl logs <pod-name> -n production --previous

# Check limits
kubectl describe pod <pod-name> -n production | grep -A 5 "Limits"

# Increase resources in values.yaml if needed
helm upgrade mlops-api kubernetes/helm-chart \
  --set resources.requests.memory=512Mi \
  -n production
```

**Ingress not working**
```bash
# Check ingress status
kubectl get ingress -n production

# Describe ingress
kubectl describe ingress mlops-api -n production

# Verify backend service
kubectl get svc -n production

# Test service directly
kubectl port-forward svc/mlops-api 8000:80 -n production
curl http://localhost:8000/health

# Check ingress controller
kubectl get pods -n ingress-nginx
```

### Helm Issues

**Helm release won't deploy**
```bash
# Check Helm status
helm status mlops-api -n production

# Get release history
helm history mlops-api -n production

# Rollback to previous
helm rollback mlops-api -n production

# Check values
helm get values mlops-api -n production

# Dry-run to see what would deploy
helm upgrade mlops-api kubernetes/helm-chart \
  --dry-run \
  --debug \
  -n production
```

**Chart validation errors**
```bash
# Lint chart
helm lint kubernetes/helm-chart

# Template validation
helm template mlops-api kubernetes/helm-chart -n production

# Check for missing dependencies
helm dependency list kubernetes/helm-chart
helm dependency update kubernetes/helm-chart
```

### Monitoring Issues

**Prometheus not scraping metrics**
```bash
# Check Prometheus status
kubectl get pods -n monitoring

# Check Prometheus config
kubectl get cm prometheus-config -n monitoring -o yaml

# Check targets in Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check scrape errors
# In Prometheus UI, check: http://localhost:9090/service-discovery
```

**Grafana dashboards empty**
```bash
# Verify Grafana is running
kubectl get pods -n monitoring

# Check Grafana data source
kubectl port-forward -n monitoring svc/grafana 3000:3000
# In UI: Configuration → Data Sources → Prometheus

# Verify Prometheus has data
# Check targets, check metrics

# Restart Grafana if needed
kubectl rollout restart deployment/grafana -n monitoring
```

**Metrics not appearing**
```bash
# Check if API is exposing metrics
curl http://localhost:8000/metrics

# Verify Prometheus config includes the job
kubectl get cm prometheus-config -n monitoring -o yaml

# Check pod labels match Prometheus job selector
kubectl get pods -n production --show-labels

# Restart Prometheus to reload config
kubectl rollout restart deployment/prometheus -n monitoring
```

## Common Fixes

### Reset Everything
```bash
# Delete Helm release
helm uninstall mlops-api -n production

# Delete namespaces
kubectl delete namespace production monitoring

# Delete Terraform resources
cd terraform && terraform destroy

# Delete ACR images
az acr repository delete --registry mlopsacr --name document-qa-api
```

### Redeploy from Scratch
```bash
# 1. Infrastructure
cd terraform && bash deploy.sh

# 2. Configure kubectl
az aks get-credentials --resource-group mlops-rg --name mlops-aks

# 3. Create namespaces
kubectl create namespace production monitoring

# 4. Create ACR secret
kubectl create secret docker-registry acr-credentials \
  --docker-server=<login-server> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n production

# 5. Deploy application
helm install mlops-api kubernetes/helm-chart -n production
```

### Clear Docker Cache
```bash
# Remove all stopped containers
docker container prune -f

# Remove dangling images
docker image prune -f

# Remove all unused volumes
docker volume prune -f

# Clean everything (careful!)
docker system prune -a
```

## Useful Commands

### Viewing Logs
```bash
# Real-time pod logs
kubectl logs -f <pod-name> -n production

# Last 100 lines
kubectl logs <pod-name> -n production --tail=100

# Previous container (crash logs)
kubectl logs <pod-name> -n production --previous

# All pods in namespace
kubectl logs -n production -l app=mlops-api --all-containers=true

# Timestamp logs
kubectl logs <pod-name> -n production --timestamps=true
```

### Debugging Pods
```bash
# Execute command in pod
kubectl exec -it <pod-name> -n production -- /bin/sh

# Copy file from pod
kubectl cp production/<pod-name>:/app/file.txt ./file.txt

# Port forward to pod
kubectl port-forward <pod-name> 8000:8000 -n production

# Get pod shell for debugging
kubectl debug <pod-name> -n production -it
```

### Resource Management
```bash
# View resource usage
kubectl top pods -n production
kubectl top nodes

# Set resource requests/limits
kubectl set resources deployment mlops-api \
  --requests=cpu=250m,memory=256Mi \
  --limits=cpu=500m,memory=512Mi \
  -n production

# Scale deployment
kubectl scale deployment mlops-api --replicas=5 -n production
```

### Events and Troubleshooting
```bash
# View cluster events
kubectl get events -n production --sort-by='.lastTimestamp'

# Watch pods
kubectl get pods -n production -w

# Describe resource for details
kubectl describe <resource-type> <name> -n <namespace>

# Get resource in YAML format
kubectl get <resource> <name> -n <namespace> -o yaml
```

## When All Else Fails

### Check System Health
```bash
# Kubernetes cluster status
kubectl get nodes
kubectl get componentstatuses

# Check for cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Verify DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check persistent volumes
kubectl get pv
kubectl get pvc -A
```

### Contact Support
1. **Check logs first** - Most issues visible in logs
2. **Check GitHub Issues** - Search existing issues
3. **Review documentation** - README, QUICKSTART
4. **Check Azure status** - Service health dashboard
5. **Open GitHub Issue** - With logs and context

## Quick Reference

### Important Endpoints (when port-forwarded)
```
API: http://localhost:8000
API Docs: http://localhost:8000/docs
Metrics: http://localhost:8000/metrics
Prometheus: http://localhost:9090
Grafana: http://localhost:3000 (admin/admin)
```

### Important Namespaces
```
production  - Application deployment
monitoring  - Prometheus & Grafana
kube-system - K8s system components
```

### Important Secrets
```
acr-credentials      - ACR authentication
mlops-secrets        - Application secrets
grafana-secrets      - Grafana admin password
```

### Important ConfigMaps
```
prometheus-config    - Prometheus configuration
grafana-dashboards   - Grafana dashboard definitions
```

---

**Still having issues?**
1. Check the relevant documentation file
2. Review the logs carefully
3. Search GitHub issues
4. Create a detailed bug report with:
   - Error messages
   - Steps to reproduce
   - Environment details
   - Logs (sanitized)