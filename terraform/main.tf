terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  type        = string
  default     = "mlops-rg"
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for resources"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name"
}

variable "cluster_name" {
  type        = string
  default     = "mlops-aks"
  description = "AKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.27"
  description = "Kubernetes version"
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Number of nodes in the cluster"
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM size for nodes"
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "MLOps"
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Container Registry
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = var.environment
  }
}

# Create AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    tags = {
      Environment = var.environment
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }
    azure_policy {
      enabled = false
    }
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Attach ACR to AKS
resource "azurerm_role_assignment" "aks_acr" {
  scope       = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Create Key Vault for secrets
resource "azurerm_key_vault" "vault" {
  name                       = "${var.cluster_name}-vault"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "List",
      "Recover",
      "Backup",
      "Restore"
    ]
  }

  tags = {
    Environment = var.environment
  }
}

# Get current Azure context
data "azurerm_client_config" "current" {}

# Create Storage Account for ML artifacts
resource "azurerm_storage_account" "ml_storage" {
  name                     = replace("${var.cluster_name}storage", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
  }
}

# Create Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.cluster_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    Environment = var.environment
  }
}

# Outputs
output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "AKS cluster name"
}

output "aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "AKS cluster ID"
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR login server"
}

output "acr_id" {
  value       = azurerm_container_registry.acr.id
  description = "ACR ID"
}

output "key_vault_id" {
  value       = azurerm_key_vault.vault.id
  description = "Key Vault ID"
}

output "storage_account_id" {
  value       = azurerm_storage_account.ml_storage.id
  description = "Storage account ID"
}

output "kubeconfig" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "Kubernetes config"
}