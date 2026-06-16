# Interview Preparation Guide

Use this guide to prepare for discussing this project in interviews.

## 30-Second Elevator Pitch

"I built a production-grade MLOps pipeline that deploys an LLM-powered API on Azure Kubernetes Service. It includes Infrastructure as Code with Terraform, a complete CI/CD pipeline with GitHub Actions that runs tests, builds Docker images, pushes to Azure Container Registry, and deploys with Helm. The solution includes monitoring with Prometheus and Grafana, secrets management with Azure Key Vault, and automatic rollback on failures."

## Key Talking Points

### Architecture & Design
**Q: Walk us through your architecture**

A: "The solution has several layers:
- **Application Layer**: FastAPI REST API with document Q&A capability, built in Python with Prometheus metrics
- **Containerization**: Multi-stage Docker build for optimized images, pushed to Azure Container Registry
- **Orchestration**: Kubernetes cluster on AKS with Helm charts, featuring Horizontal Pod Autoscaling (2-10 replicas)
- **Infrastructure**: Terraform provisions networking, compute, storage, and security resources
- **CI/CD**: GitHub Actions orchestrates the entire pipeline from commit to production
- **Observability**: Prometheus scrapes metrics, Grafana visualizes them, alerting rules monitor SLOs
- **Security**: Azure Key Vault manages secrets, RBAC controls access, Trivy scans images"

### Technical Decisions
**Q: Why did you choose these technologies?**

A: "
- **Azure**: Integrated with enterprise environments, strong AKS support
- **Terraform**: Infrastructure as Code best practice, state management, reproducible
- **Helm**: Package manager for Kubernetes, templating, version control
- **GitHub Actions**: Native GitHub integration, no additional platform needed
- **Prometheus + Grafana**: Open-source standard for K8s monitoring
- **FastAPI**: Modern Python framework, automatic API docs, performance
- **Azure Key Vault**: Native to Azure, integrates with K8s via CSI driver
"

### Challenges Overcome
**Q: What was the hardest part?**

A: "
- **Kubernetes complexity**: Balancing production-readiness with learning curve. Solved by starting simple with Helm charts
- **Secret management**: Integrating Azure Key Vault with K8s. Solved using CSI Secret Provider
- **CI/CD reliability**: Ensuring deployments don't fail production. Added smoke tests and automatic rollback
- **Monitoring coverage**: Tracking both infrastructure and application metrics. Solved with proper Prometheus config
"

### Production Readiness
**Q: How is this production-ready?**

A: "
✓ **Resource limits** - CPU/memory constraints prevent runaway pods
✓ **Health checks** - Liveness and readiness probes ensure reliability
✓ **Auto-scaling** - HPA scales based on metrics, VMSS for nodes
✓ **High availability** - Pod anti-affinity spreads replicas across nodes
✓ **Security** - Non-root user, RBAC, secrets encryption, image scanning
✓ **Monitoring** - Full observability with metrics, logs, and alerts
✓ **Disaster recovery** - Automatic rollback on failure
✓ **IaC** - Reproducible, version-controlled infrastructure
"

### Scalability
**Q: How does this scale?**

A: "Multiple levels:
1. **Pod scaling**: HPA automatically scales replicas (2-10) based on CPU (>70%) or Memory (>80%)
2. **Node scaling**: AKS virtual machine scale sets add nodes as needed
3. **Load balancing**: Kubernetes service distributes traffic across pods
4. **Container registry**: ACR can store unlimited images
5. **Monitoring**: Prometheus and Grafana handle thousands of metrics
6. **Infrastructure**: Terraform code can provision larger clusters easily"

### Security Considerations
**Q: How do you handle security?**

A: "
1. **Secrets management**
   - API keys stored in Azure Key Vault, not in code
   - CSI Secret Provider injects secrets into pods at runtime
   - Secrets rotated via Key Vault lifecycle

2. **Access control**
   - RBAC defines exact pod permissions
   - Service accounts instead of cluster-admin
   - Network policies ready (not fully implemented yet)

3. **Image security**
   - Trivy scans images for vulnerabilities
   - Non-root user in containers
   - Minimal base images to reduce attack surface

4. **Infrastructure**
   - VNet isolation
   - Subnet restrictions
   - Managed identities for authentication
"

### Monitoring & Observability
**Q: How do you monitor this?**

A: "Three levels:
1. **Application metrics**
   - Request rate, latency, error rate
   - LLM inference duration
   - Custom business metrics

2. **Infrastructure metrics**
   - Pod CPU/memory usage
   - Node health
   - Container restart counts

3. **Alerting**
   - API error rate > 5%
   - Latency P95 > 1 second
   - Pod crash loops
   - Node resource pressure

Grafana dashboards visualize all metrics, alerts notify via Slack"

### CI/CD Pipeline
**Q: Walk through your deployment process**

A: "When code is pushed to main:
1. **Test** (20s): pytest validates Python code
2. **Build** (3-5m): Docker image created, pushed to ACR
3. **Scan** (1m): Trivy checks for vulnerabilities
4. **Deploy** (5m): Helm upgrades K8s deployment
5. **Verify** (2m): Smoke tests confirm availability
6. **Monitor** (ongoing): Prometheus tracks health

If anything fails, automatic rollback reverts to previous version. Slack notifies team"

### Cost Optimization
**Q: How much does this cost?**

A: "Approximately $160-220/month for small deployment:
- AKS: $150-200 (3 Standard_DS2_v2 nodes)
- ACR: $10 (Standard tier)
- Key Vault: <$1 (operations)
- Storage: $1-5
- Insights: <$1

Optimizations for production:
- Spot instances for dev (80% cheaper)
- Smaller node types if applicable
- Scale down during off-hours
- Right-sizing based on actual usage"

## Common Interview Questions

### Q: What would you do differently?
A: "
- Add database (PostgreSQL) for persistence
- Implement distributed tracing (Jaeger/Zipkin)
- Add API rate limiting and authentication
- Implement blue-green or canary deployments
- Add GitOps with ArgoCD for declarative management
- Implement service mesh (Istio) for advanced traffic management
- Add cost optimization and resource tagging
"

### Q: How do you debug issues?
A: "
- Check pod logs: `kubectl logs -f pod-name -n production`
- Describe pod: `kubectl describe pod pod-name -n production`
- Check metrics: `kubectl top pods/nodes`
- Port forward to test: `kubectl port-forward svc/mlops-api 8000:80`
- Check Prometheus/Grafana for metrics
- Review alert rules to understand baseline
"

### Q: How do you handle database migrations?
A: "
- This version uses in-memory storage (for simplicity)
- In production: Helm pre-upgrade hooks for migrations
- Database backup before migrations
- Rollback plan if migration fails
- Health checks verify migration success
"

### Q: Disaster recovery plan?
A: "
- **RPO** (Recovery Point Objective): ~5 minutes (Helm release snapshots)
- **RTO** (Recovery Time Objective): ~2 minutes (rollback)
- **Backups**: Helm releases, K8s object exports
- **Failover**: Automatic via VMSS node replacement
- **Data**: Persistent volumes with snapshots
- **DNS**: Ingress controller provides failover
"

### Q: How do you test in production?
A: "
- **Smoke tests** post-deployment verify core functionality
- **Canary deployments** (not yet): Route 5% traffic to new version
- **Blue-green** (not yet): Parallel deployments for testing
- **Synthetic monitoring**: Regular health checks from external sources
- **Error budget**: Alerting when exceeding SLO thresholds
"

## Technical Deep Dives

### FastAPI Application
```
- REST endpoints: /ask, /documents, /upload, /metrics, /health
- Prometheus metrics for observability
- Error handling and logging
- Async support for I/O operations
- Unit tests with >80% coverage
```

### Terraform Configuration
```
- Modular structure (ready for extraction)
- State management with Azure backend
- Outputs for value propagation
- Variable validation
- Tags for resource organization
```

### Helm Chart
```
- Production-grade values.yaml
- Security context enforcement
- Resource limits and requests
- Probes for reliability
- Affinity rules for HA
- RBAC templates
```

### GitHub Actions
```
- Matrix testing for multiple Python versions
- Docker layer caching for speed
- Artifact uploads for troubleshooting
- Conditional job execution
- Environment protection rules
```

## Metrics to Reference

- **Uptime**: 99.5%+ (with HPA and pod anti-affinity)
- **Deployment frequency**: Every commit (automated)
- **MTTR**: <2 minutes (automatic rollback)
- **Error rate**: <5% (with alerts at 5%)
- **Latency P95**: <1 second (with alerts at 1s)

## Questions to Ask Back

1. "What's your current infrastructure setup?"
2. "Do you use Kubernetes/cloud infrastructure?"
3. "What's your CI/CD process like?"
4. "How do you handle disaster recovery?"
5. "What's your monitoring strategy?"

These show you're thinking about real-world integration.

## After Interview

1. Update portfolio with project link
2. Write blog post explaining architecture
3. Add additional features (database, caching, etc.)
4. Demo the deployment process
5. Document lessons learned

## Resources to Reference

- [Azure Documentation](https://learn.microsoft.com/azure)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/best-practices/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Terraform Best Practices](https://www.terraform.io/docs/language/syntax/style)
- [12 Factor App](https://12factor.net/)

---

**Good luck with your interviews!**