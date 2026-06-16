# MLOps Project - Quick Reference Card

## Documentation Index

### Getting Started (START HERE!)
- **START_HERE.md** - Project orientation & learning paths
- **README.md** - Complete setup & deployment guide

### Quick References
- **QUICKSTART.md** - Command quick reference
- **FILE_MANIFEST.md** - Every file explained
- **GETTING_HELP.md** - Troubleshooting guide

### Learning & Career
- **PROJECT_SUMMARY.md** - Project overview & features
- **INTERVIEW_GUIDE.md** - Interview preparation
- **CONTRIBUTING.md** - How to contribute

---

## Quick Start Commands

### Local Development (5 min)
```bash
cd docker
docker-compose up -d
# Visit: http://localhost:8000
```

### Run Tests (10 min)
```bash
cd app
pip install -r requirements.txt
pytest test_main.py -v
```

### Deploy to Azure (45 min)
```bash
cd terraform
bash deploy.sh
```

---

## Project Structure

```
mlops-pipeline/
├── app/               # Python FastAPI application
├── docker/            # Docker containerization
├── kubernetes/        # Helm charts & manifests
├── terraform/         # Infrastructure as Code
├── monitoring/        # Prometheus & Grafana
├── .github/workflows/ # GitHub Actions CI/CD
└── [8 docs]          # Guides & references
```

---

## Key Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Application | FastAPI | REST API with Q&A |
| Container | Docker | Multi-stage builds |
| Registry | ACR | Image storage |
| Orchestration | Kubernetes | Pod management |
| Deployment | Helm | K8s package manager |
| Infrastructure | Terraform | IaC for Azure |
| CI/CD | GitHub Actions | Automated pipeline |
| Monitoring | Prometheus | Metrics collection |
| Visualization | Grafana | Dashboards |
| Secrets | Key Vault | Secret management |

---

## CI/CD Pipeline Stages

1. **Test** (20s) - pytest validation
2. **Build** (3-5m) - Docker image creation
3. **Scan** (1m) - Trivy security scan
4. **Deploy** (5m) - Helm to AKS
5. **Verify** (2m) - Smoke tests
6. **Rollback** (auto) - On failure

---

## Key Metrics & Endpoints

### API Endpoints (localhost:8000)
- `/health` - Health check
- `/docs` - Swagger docs
- `/ask` - Q&A endpoint
- `/documents` - List documents
- `/upload` - Upload document
- `/metrics` - Prometheus metrics

### Services (when deployed)
- API: `http://localhost:8000`
- Grafana: `http://localhost:3000` (admin/admin)
- Prometheus: `http://localhost:9090`

---

## Infrastructure Overview

```
AKS Cluster (3 nodes)
├── Production Namespace
│   ├── API Pods (2-10 HPA)
│   ├── Service & Ingress
│   └── Secrets (Key Vault)
├── Monitoring Namespace
│   ├── Prometheus
│   └── Grafana
├── Virtual Network
│   ├── Subnets
│   └── Network Policies
└── Supporting Services
    ├── ACR (images)
    ├── Key Vault (secrets)
    └── Storage (artifacts)
```

---

## Scalability

- **Pods**: HPA scales 2-10 replicas based on CPU (>70%) or Memory (>80%)
- **Nodes**: AKS VMSS adds nodes as needed
- **Load Balancing**: Kubernetes service distributes traffic
- **Registry**: ACR stores unlimited images

---

## Security Features

✓ Non-root container user
✓ Resource limits & requests
✓ RBAC configuration
✓ Secrets in Key Vault
✓ Image vulnerability scanning
✓ Network policies ready
✓ Pod security policies
✓ Encrypted state management

---

## Alert Rules

| Alert | Threshold | Action |
|-------|-----------|--------|
| API Error Rate | >5% | Page on-call |
| API Latency P95 | >1s | Warning |
| Inference Latency P99 | >5s | Warning |
| Pod Restart | Any | Investigation |
| Memory Pressure | Any | Escalation |
| Disk Pressure | Any | Escalation |

---

## Common Commands

### Kubernetes
```bash
kubectl get pods -n production
kubectl logs -f <pod> -n production
kubectl describe pod <pod> -n production
kubectl top pods -n production
kubectl scale deployment mlops-api --replicas=5 -n production
```

### Helm
```bash
helm status mlops-api -n production
helm values mlops-api -n production
helm history mlops-api -n production
helm rollback mlops-api -n production
helm upgrade mlops-api kubernetes/helm-chart -n production
```

### Docker
```bash
docker build -f docker/Dockerfile -t mlopsacr.azurecr.io/document-qa-api:latest .
docker push mlopsacr.azurecr.io/document-qa-api:latest
docker-compose up -d
docker-compose logs -f
docker-compose down
```

### Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform destroy
terraform state list
```

---

## Interview Talking Points

### 30-Second Pitch
"I built a production-grade MLOps pipeline with a FastAPI application, complete infrastructure as code using Terraform for Azure AKS, containerized with Docker, automated CI/CD with GitHub Actions, and comprehensive monitoring with Prometheus and Grafana."

### Key Features
- Full DevOps pipeline (test → build → deploy)
- Kubernetes on AKS with auto-scaling
- Infrastructure as Code (Terraform)
- CI/CD with GitHub Actions
- Monitoring & alerting
- Security best practices

### Technologies
Python, FastAPI, Docker, Kubernetes, Helm, Terraform, GitHub Actions, Prometheus, Grafana, Azure

### Why This Project
- Demonstrates real-world DevOps skills
- Production-ready implementation
- Shows full pipeline understanding
- Perfect for interviews

---

## Troubleshooting Quick Links

| Issue | Solution |
|-------|----------|
| Docker won't start | `docker-compose down -v && docker-compose up` |
| Pods won't deploy | Check logs: `kubectl logs -f <pod> -n production` |
| Image push fails | `az acr login --name mlopsacr` |
| Terraform error | `terraform validate && terraform plan` |
| Prometheus no data | Verify scrape configs & target health |
| Grafana blank | Add Prometheus as datasource |

---

## Getting Help

1. **Quick answers** → QUICKSTART.md
2. **Troubleshooting** → GETTING_HELP.md
3. **Interview prep** → INTERVIEW_GUIDE.md
4. **Full setup** → README.md
5. **Understanding code** → FILE_MANIFEST.md

---

## Time Estimates

| Task | Time |
|------|------|
| Read documentation | 1 hour |
| Docker Compose setup | 5 min |
| Local testing | 10 min |
| Azure deployment | 45 min |
| Full mastery | 1-2 weeks |

---

## Estimated Azure Costs

- **AKS**: $150-200/month
- **ACR**: $10/month
- **Key Vault**: <$1/month
- **Storage**: $1-5/month
- **Total**: ~$160-220/month

---

## Production Readiness Checklist

✓ Security (RBAC, secrets, scanning)
✓ High availability (HPA, anti-affinity)
✓ Disaster recovery (rollback, backups)
✓ Monitoring (metrics, logs, alerts)
✓ Scalability (auto-scaling configured)
✓ Performance (resource limits set)
✓ Documentation (comprehensive guides)
✓ Testing (unit tests included)
✓ Infrastructure as Code (Terraform)
✓ CI/CD automation (fully automated)

---

**Last Updated:** June 2, 2026
**Project Status:** Production-Ready
**Perfect For:** DevOps/SRE/Cloud Engineering Interviews

---

## Your Next Action

1. Open `START_HERE.md` in your editor
2. Choose a learning path
3. Start with local Docker Compose
4. Progress to Azure deployment
5. Practice explaining each component

**Good luck!**