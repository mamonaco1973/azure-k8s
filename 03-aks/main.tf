# Configure the AzureRM provider

provider "azurerm" {
  # Enables the default features of the provider
  features {}
}

# Data source to fetch details of the primary subscription
data "azurerm_subscription" "primary" {}

# Data source to fetch the details of the current Azure client
data "azurerm_client_config" "current" {}

# Resource group for the project

data "azurerm_resource_group" "aks_flaskapp_rg" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "flask_acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
}


data "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
}

data "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  virtual_network_name = data.azurerm_virtual_network.aks_vnet.name
  resource_group_name  = data.azurerm_resource_group.aks_flaskapp_rg.name
}
