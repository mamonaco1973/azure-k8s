provider "azurerm" {
  features {}
}

variable "container_name" {
  default = "tfstate"
}

# Generate a random string for uniqueness
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "terraform-backend-${random_string.unique.result}"
  location = "Central US"
}

# Create a Storage Account for Terraform state
resource "azurerm_storage_account" "storage" {
  name                     = "tfstate${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Storage Container for Terraform state
resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.storage.id 
  container_access_type = "private"
}

# Assign 'Storage Blob Data Contributor' role to current user for Terraform state access
resource "azurerm_role_assignment" "terraform_storage_role" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Fetch authenticated user details
data "azurerm_client_config" "current" {}

# Create a local file for backend configuration
resource "local_file" "backend_config_acr" {
  filename = "../01-acr/01-acr-backend.tf"
  content  = <<EOT
terraform {
  backend "azurerm" {
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    storage_account_name  = "${azurerm_storage_account.storage.name}"
    container_name        = "${azurerm_storage_container.container.name}"
    key                  = "01-acr/terraform.tfstate.json"
  }
}
EOT
}

# Create a local file for backend configuration
resource "local_file" "backend_config_container_app" {
  filename = "../03-containerapp/03-containerapp-backend.tf"
  content  = <<EOT
terraform {
  backend "azurerm" {
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    storage_account_name  = "${azurerm_storage_account.storage.name}"
    container_name        = "${azurerm_storage_container.container.name}"
    key                  = "03-containerapp/terraform.tfstate.json"
  }
}
EOT
}
