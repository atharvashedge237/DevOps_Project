# Terraform variables file
# Usage: terraform plan -var-file="terraform.tfvars"

resource_group_name = "mlops-rg"
location            = "eastus"
environment         = "production"
cluster_name        = "mlops-aks"
kubernetes_version  = "1.27"
node_count          = 3
vm_size             = "Standard_DS2_v2"
