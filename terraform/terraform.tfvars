# Terraform variables file
# Usage: terraform plan -var-file="terraform.tfvars"

resource_group_name = "mlops-pipeline"
location            = "eastus"
environment         = "production"

cluster_name        = "mlops-aks"
kubernetes_version  = "1.27"
node_count          = 1
vm_size             = "Standard_B2s"

subscription_id     = "6a347507-72a8-4e66-87cf-9fffca3dfcce"
acr_name            = "mlopsacr6a347507"
keyvault_name       = "mlops-vault"