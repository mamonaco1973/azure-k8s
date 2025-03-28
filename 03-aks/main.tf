# ---------------------------------------------------------
# AzureRM Provider Configuration
# ---------------------------------------------------------

provider "azurerm" {
  features {}  # Enables all default provider features (required block even if empty)
}

# ---------------------------------------------------------
# Azure Data Sources
# Used to dynamically fetch existing Azure metadata
# ---------------------------------------------------------

# --------------------------------------
# Get information about the current subscription
# --------------------------------------
data "azurerm_subscription" "primary" {}
# - Useful for referencing subscription ID in other resources.
# - Can be used to scope role assignments, permissions, or diagnostics.

# --------------------------------------
# Get information about the authenticated Azure client
# --------------------------------------
data "azurerm_client_config" "current" {}
# - Provides the object_id, client_id, and tenant_id of the current Terraform identity.
# - Frequently used when assigning roles or granting permissions to the current user or service principal.

# ---------------------------------------------------------
# Existing Resource Group (Passed as Variable)
# ---------------------------------------------------------
data "azurerm_resource_group" "aks_flaskapp_rg" {
  name = var.resource_group_name
  # This RG is expected to be pre-created, and contains ACR, VNet, Subnets, etc.
}

# ---------------------------------------------------------
# Azure Container Registry Lookup (ACR)
# ---------------------------------------------------------
data "azurerm_container_registry" "flask_acr" {
  name                = var.acr_name  # Registry name provided via Terraform variable
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  # Used to grant ACR Pull permissions to AKS identity and to reference private image URIs.
}

# ---------------------------------------------------------
# Virtual Network Lookup (for AKS Networking)
# ---------------------------------------------------------
data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"    # Name of the VNet where AKS nodes will be deployed
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  # Required for custom networking setup (Azure CNI), especially when using Workload Identity
}

# ---------------------------------------------------------
# Subnet Lookup (for AKS Node Pool)
# ---------------------------------------------------------
data "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"                           # Subnet that AKS will use for worker nodes
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name  # Ensure subnet is in the correct VNet
  resource_group_name  = data.azurerm_resource_group.aks_flaskapp_rg.name
  # Must be delegated to "Microsoft.ContainerService/managedClusters" if using Azure CNI
}
