# Terraform variables file
# Usage: terraform plan -var-file="terraform.tfvars"

resource_group_name = "mlops-pipeline"
location            = "eastus"
environment         = "production"

cluster_name        = "mlops-aks"
# Updated to a supported AKS version in eastus (from `az aks get-versions -l eastus`)
kubernetes_version  = "1.35.5"
node_count          = 1
# Use a VM size allowed in this subscription/region (from `az aks get-versions -l eastus`)
vm_size             = "Standard_D2s_v7"

subscription_id     = "6a347507-72a8-4e66-87cf-9fffca3dfcce"
acr_name            = "mlopsacr6a347507"
keyvault_name       = "mlops-vault"