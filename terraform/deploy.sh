#!/bin/bash
set -e

echo "Deploying MLOps Infrastructure with Terraform..."

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan
echo "Planning infrastructure..."
terraform plan -out=tfplan

# Apply
echo "Applying infrastructure..."
terraform apply tfplan

echo "Infrastructure deployment complete!"
terraform output