# MLOps Pipeline for Document Q&A API

A production-grade MLOps project showcasing a complete DevOps pipeline for deploying an LLM-powered document Q&A application on Azure Kubernetes Service (AKS).

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Local Development](#local-development)
- [Infrastructure Setup](#infrastructure-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring](#monitoring)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                       │
│  Push code → GitHub Actions CI/CD Pipeline                      │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├─→ Run Tests (pytest)
             ├─→ Build Docker Image (multi-stage)
             ├─→ Push to ACR (Azure Container Registry)
             ├─→ Security Scan (Trivy)
             └─→ Deploy to AKS with Helm
                 │
                 ├─→ Kubernetes Cluster (AKS)
                 │   ├─→ API Pods (mlops-api)
                 │   ├─→ Horizontal Pod Autoscaler (HPA)
                 │   └─→ Service & Ingress
                 │
                 ├─→ Monitoring Stack
                 │   ├─→ Prometheus (metrics scraping)
                 │   └─→ Grafana (visualization)
                 │
                 ├─→ Secrets Management
                 │   ├─→ Azure Key Vault
                 │   └─→ CSI Secret Provider
                 │
                 └─→ Infrastructure (IaC)
                     ├─→ Virtual Networks
                     ├─→ ACR (Container Registry)
                     └─→ Key Vault
```

## Project Structure

```
mlops-pipeline/
├── app/                           # Python FastAPI Application
│   ├── main.py                    # Main application code
│   ├── requirements.txt           # Python dependencies
│   └── test_main.py              # Unit tests
├── docker/                        # Docker Configuration
│   ├── Dockerfile                 # Multi-stage build
│   ├── .dockerignore             # Docker build context exclusions
│   ├── docker-compose.yml        # Local development stack
│   └── prometheus.yml            # Prometheus config
├── kubernetes/                    # Kubernetes Manifests
│   ├── helm-chart/               # Helm chart for deployment
│   │   ├── Chart.yaml           # Chart metadata
│   │   ├── values.yaml          # Default values
│   │   └── templates/           # Kubernetes templates
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── hpa.yaml
│   │       ├── ingress.yaml
│   │       ├── rbac.yaml
│   │       └── configmap.yaml
│   ├── secrets-provider.yaml     # Secret provider config
│   └── setup-secrets.sh          # Secrets setup automation
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                   # Main infrastructure
│   ├── backend.tf                # State management
│   ├── terraform.tfvars          # Variables
│   └── deploy.sh                 # Deployment script
├── monitoring/                    # Monitoring Configuration
│   ├── prometheus.yml            # Prometheus scrape config
│   ├── alert-rules.yml           # Alert rules
│   ├── prometheus-deployment.yaml
│   └── grafana-deployment.yaml
├── cicd/                         # CI/CD Configuration
│   └── (GitHub Actions workflows in .github/workflows/)
├── .github/
│   └── workflows/
│       └── mlops-pipeline.yml    # Main CI/CD pipeline
└── README.md                     # This file
```

## Prerequisites

### Local Development
- Docker & Docker Compose
- Python 3.11+
- kubectl CLI
- Helm 3.x
- Terraform >= 1.0

### Azure Setup
- Azure Account with active subscription
- Azure CLI installed and configured
- Appropriate IAM permissions

### Git
- GitHub account with repository access
- Generate Personal Access Token (PAT) for CI/CD

## Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd mlops-pipeline
```

### 2. Local Testing with Docker Compose
```bash
cd docker
docker-compose up -d

# Test API health
curl http://localhost:8000/health

# View API documentation
open http://localhost:8000/docs

# View Prometheus metrics
open http://localhost:9090

# View Grafana dashboards (admin/admin)
open http://localhost:3000
```

### 3. Run Unit Tests
```bash
cd app
pip install -r requirements.txt
pytest test_main.py -v --cov=.
```

## Local Development

### Setup Python Environment
```bash
cd app
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run API Locally
```bash
cd app
python main.py
```

API will be available at `http://localhost:8000`

### API Endpoints

**Health Check**
```bash
GET /health
```

**List Documents**
```bash
GET /documents
```

**Ask Question**
```bash
POST /ask
Content-Type: application/json

{
  "question": "What is Kubernetes?",
  "document_id": "doc1",
  "max_tokens": 150
}
```

**Upload Document**
```bash
POST /upload?document_id=doc3
Content-Type: multipart/form-data

[binary file data]
```

**Metrics**
```bash
GET /metrics
```

## Infrastructure Setup

### 1. Azure Authentication
```bash
az login
az account set --subscription <your-subscription-id>
```

### 2. Create Terraform State Backend
```bash
# Create storage account for Terraform state
az storage account create \
  --name tfstatestorage \
  --resource-group tfstate-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstatestorage
```

### 3. Initialize & Deploy Infrastructure
```bash
cd terraform
terraform init -backend-config="resource_group_name=tfstate-rg" \
              -backend-config="storage_account_name=tfstatestorage" \
              -backend-config="container_name=tfstate" \
              -backend-config="key=mlops.tfstate"

bash deploy.sh
```

### 4. Configure kubectl
```bash
az aks get-credentials \
  --resource-group mlops-rg \
  --name mlops-aks

# Verify connection
kubectl get nodes
```

### 5. Create Namespaces
```bash
kubectl create namespace production
kubectl create namespace monitoring
```

## Container Registry Setup

### Build and Push Image Manually
```bash
# Login to ACR
az acr login --name mlopsacr

# Build image
docker build -f docker/Dockerfile -t mlopsacr.azurecr.io/document-qa-api:v1.0.0 .

# Push to ACR
docker push mlopsacr.azurecr.io/document-qa-api:v1.0.0

# List images
az acr repository list --name mlopsacr
```

## Deployment

### Deploy with Helm

**1. Update values.yaml**
```bash
# Edit kubernetes/helm-chart/values.yaml
# Update image registry, repository, and tag
```

**2. Create ACR credentials secret**
```bash
kubectl create secret docker-registry acr-credentials \
  --docker-server=mlopsacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=your@email.com \
  -n production
```

**3. Deploy**
```bash
helm install mlops-api kubernetes/helm-chart \
  --namespace production \
  --values kubernetes/helm-chart/values.yaml
```

**4. Verify deployment**
```bash
kubectl get deployments -n production
kubectl get pods -n production
kubectl get svc -n production
```

### Upgrade Deployment
```bash
helm upgrade mlops-api kubernetes/helm-chart \
  --namespace production \
  --values kubernetes/helm-chart/values.yaml
```

### Rollback
```bash
helm rollback mlops-api -n production
```

## CI/CD Pipeline

### GitHub Actions Workflow

The pipeline (`mlops-pipeline.yml`) runs:

1. **Test** - pytest on Python application
2. **Build & Push** - Docker image to ACR
3. **Deploy** - Helm chart to AKS
4. **Monitor** - Verify deployment health
5. **Rollback** - If deployment fails

### Configure Secrets in GitHub

Add these secrets to your GitHub repository:

```
ACR_USERNAME              # Azure Container Registry username
ACR_PASSWORD              # Azure Container Registry password
ACR_LOGIN_SERVER          # ACR login server (e.g., mlopsacr.azurecr.io)
KUBE_CONFIG              # Base64-encoded kubeconfig
SLACK_WEBHOOK            # (Optional) Slack notifications
```

### Encode Kubeconfig
```bash
cat ~/.kube/config | base64 | tr -d '\n'
# Copy output to GitHub Secrets as KUBE_CONFIG
```

## Monitoring

### Access Grafana
```bash
# Get Grafana service IP
kubectl get svc grafana -n monitoring

# Port forward
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Access: http://localhost:3000 (admin/changeme123)
```

### Access Prometheus
```bash
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Access: http://localhost:9090
```

### Key Metrics
- `api_requests_total` - Total API requests by status
- `api_request_duration_seconds` - Request latency (histogram)
- `inference_duration_seconds` - LLM inference latency
- `container_cpu_usage_seconds_total` - Pod CPU usage
- `container_memory_usage_bytes` - Pod memory usage

### Alert Rules
- API High Error Rate (> 5%)
- API High Latency (P95 > 1s)
- LLM Inference Slow (P99 > 5s)
- Pod Crash Looping
- Node Memory/Disk Pressure

## Security

### Secrets Management

#### Setup Azure Key Vault
```bash
cd kubernetes
bash setup-secrets.sh
```

This script:
- Creates Azure managed identity
- Sets up RBAC permissions
- Installs CSI Secret Provider
- Configures pod identity binding

#### Add Secrets to Key Vault
```bash
az keyvault secret set \
  --vault-name mlops-vault \
  --name openai-api-key \
  --value "your-key-here"
```

#### Update Deployment
```yaml
# In helm-chart/templates/deployment.yaml
volumeMounts:
  - name: secrets-store
    mountPath: "/mnt/secrets"
    readOnly: true
volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "azure-keyvault-provider"
```

### Security Best Practices Implemented

Non-root container user
Resource limits (CPU/Memory)
Network policies
RBAC for service accounts
Secrets encryption
Image scanning (Trivy)
Pod security policies
Ingress with TLS
Horizontal pod autoscaling

## Troubleshooting

### Check Pod Logs
```bash
kubectl logs -f deployment/mlops-api -n production
```

### Describe Pod for Events
```bash
kubectl describe pod <pod-name> -n production
```

### Check Resource Usage
```bash
kubectl top pods -n production
kubectl top nodes
```

### Test API Connectivity
```bash
# Port forward to pod
kubectl port-forward svc/mlops-api 8000:80 -n production

# Test endpoint
curl http://localhost:8000/health
```

### Helm Issues
```bash
# Validate chart
helm lint kubernetes/helm-chart

# Dry run deployment
helm install mlops-api kubernetes/helm-chart \
  --namespace production \
  --dry-run \
  --debug
```

### Terraform Issues
```bash
# Plan before apply
terraform plan -out=tfplan

# Destroy if needed
terraform destroy
```

## 📈 Scalability

### Horizontal Pod Autoscaling
```bash
# Check HPA status
kubectl get hpa -n production

# View HPA metrics
kubectl describe hpa mlops-api -n production
```

Configured to scale based on:
- CPU utilization > 70%
- Memory utilization > 80%
- Min replicas: 2
- Max replicas: 10

### Node Scaling
Terraform AKS cluster uses virtual machine scale sets for automatic node scaling.

## Maintenance

### Update Dependencies
```bash
# Python
pip list --outdated
pip install --upgrade -r app/requirements.txt

# Helm charts
helm repo update
helm upgrade mlops-api kubernetes/helm-chart -n production

# Kubernetes
az aks upgrade --resource-group mlops-rg --name mlops-aks
```

### Backup & Disaster Recovery
```bash
# Backup Helm release
helm get values mlops-api -n production > backup.yaml

# Backup Kubernetes objects
kubectl get all -n production -o yaml > backup.yaml
```

## Learning Resources

- [Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Prometheus & Grafana](https://prometheus.io/docs/)
- [FastAPI](https://fastapi.tiangolo.com/)
- [GitHub Actions](https://docs.github.com/en/actions)