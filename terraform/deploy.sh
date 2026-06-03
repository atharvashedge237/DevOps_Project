#!/bin/bash
set -e

echo "🚀 Deploying MLOps Infrastructure with Terraform..."

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan
echo "📋 Planning infrastructure..."
terraform plan -out=tfplan

# Apply
echo "🔨 Applying infrastructure..."
terraform apply tfplan

echo "✅ Infrastructure deployment complete!"
echo ""
echo "📊 Outputs:"
terraform output

echo ""
echo "Next steps:"
echo "1. Configure kubectl: az aks get-credentials --resource-group mlops-rg --name mlops-aks"
echo "2. Deploy application: cd ../kubernetes && helm install mlops-api ./helm-chart"
