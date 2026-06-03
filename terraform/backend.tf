terraform {
  backend "azurerm" {
    # Configure with: terraform init -backend-config="..."
    # Example:
    # terraform init -backend-config="resource_group_name=tfstate-rg" \
    #               -backend-config="storage_account_name=tfstatestorage" \
    #               -backend-config="container_name=tfstate" \
    #               -backend-config="key=mlops.tfstate"
  }
}
