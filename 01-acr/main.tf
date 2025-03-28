# ---------------------------------------------------------
# Azure Provider Configuration
# ---------------------------------------------------------

provider "azurerm" {
  features {}
  # Required block for azurerm provider — even if you're using no advanced features.
  # This line enables default settings for all supported Azure resource types.
}

# ---------------------------------------------------------
# Subscription Metadata Lookup
# ---------------------------------------------------------

data "azurerm_subscription" "primary" {}
# ✅ Fetches the current Azure subscription context.
# Useful for referencing subscription ID in role assignments, scoped policies, or logging.
# Example: data.azurerm_subscription.primary.subscription_id

# ---------------------------------------------------------
# Authenticated Client Configuration
# ---------------------------------------------------------

data "azurerm_client_config" "current" {}
# ✅ Fetches details of the current authenticated principal:
# - client_id (for app registrations)
# - object_id (for role assignments)
# - tenant_id (for service principal context)
# Useful when assigning IAM roles or configuring Workload Identity.

# ---------------------------------------------------------
# Resource Group Definition for All Azure Resources
# ---------------------------------------------------------

resource "azurerm_resource_group" "aks_flaskapp_rg" {
  name     = var.resource_group_name
  # Dynamically set by variable (typically "aks-flaskapp-rg").
  # Promotes reusability across environments like dev/staging/prod.

  location = "Central US"
  # Azure region where all dependent resources (ACR, AKS, Cosmos DB) will be deployed.
  # Should match the region used in Terraform modules to avoid latency and egress costs.
}
