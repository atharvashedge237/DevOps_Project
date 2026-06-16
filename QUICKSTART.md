# Getting Started Guide

Quick reference for common tasks.

## First Time Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd mlops-pipeline

# 2. Install dependencies
cd app && pip install -r requirements.txt && cd ..

# 3. Run tests
cd app && pytest test_main.py -v && cd ..

# 4. Start local environment
cd docker && docker-compose up -d && cd ..

# 5. Access services
# API: http://localhost:8000
# Grafana: http://localhost:3000
# Prometheus: http://localhost:9090
```

## Infrastructure Deployment

```bash
# 1. Azure Login
az login && az account set --subscription <subscription-id>

# 2. Initialize Terraform
cd terraform && terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstatestorage" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=mlops.tfstate"

# 3. Deploy infrastructure
bash deploy.sh

# 4. Configure kubectl
az aks get-credentials --resource-group mlops-rg --name mlops-aks

# 5. Create namespaces
kubectl create namespace production
kubectl create namespace monitoring
```

## Deploy Application

```bash
# 1. Update Helm values (if needed)
# vim kubernetes/helm-chart/values.yaml

# 2. Create ACR credentials
kubectl create secret docker-registry acr-credentials \
  --docker-server=<acr-login-server> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n production

# 3. Deploy with Helm
helm install mlops-api kubernetes/helm-chart \
  --namespace production \
  --values kubernetes/helm-chart/values.yaml

# 4. Verify
kubectl get pods -n production
```

## Monitoring Setup

```bash
# 1. Deploy monitoring stack
kubectl apply -f monitoring/prometheus-deployment.yaml
kubectl apply -f monitoring/grafana-deployment.yaml

# 2. Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# http://localhost:3000 (admin/changeme123)

# 3. Add Prometheus as datasource
# Prometheus URL: http://prometheus:9090
```

## Secrets Management

```bash
# 1. Setup Key Vault integration
cd kubernetes
bash setup-secrets.sh

# 2. Add secrets
az keyvault secret set \
  --vault-name mlops-vault \
  --name openai-api-key \
  --value "your-key"

# 3. Restart pods to fetch secrets
kubectl rollout restart deployment/mlops-api -n production
```

## CI/CD Configuration

```bash
# 1. Generate GitHub secrets
# ACR_USERNAME, ACR_PASSWORD, ACR_LOGIN_SERVER
# Encode kubeconfig: cat ~/.kube/config | base64 | tr -d '\n'

# 2. Add to GitHub repository secrets

# 3. Push code to trigger pipeline
git add .
git commit -m "Deploy to production"
git push origin main
```

## Common Commands

```bash
# Logs
kubectl logs -f deployment/mlops-api -n production

# Port forward
kubectl port-forward svc/mlops-api 8000:80 -n production

# Describe pod
kubectl describe pod <pod-name> -n production

# Scale
kubectl scale deployment mlops-api --replicas=5 -n production

# Check HPA
kubectl get hpa -n production

# Helm status
helm status mlops-api -n production

# Helm values
helm get values mlops-api -n production

# Rollback
helm rollback mlops-api -n production
```

## Cleanup

```bash
# Delete Helm release
helm uninstall mlops-api -n production

# Delete Kubernetes resources
kubectl delete namespace production monitoring

# Destroy infrastructure
cd terraform && terraform destroy
```