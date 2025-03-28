# ---------------------------------------------------------
# Resource Group Name Variable
# ---------------------------------------------------------
variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string                      # Enforce string-only input
  default     = "aks-flaskapp-rg"           # Default RG where AKS, ACR, Cosmos DB, etc. reside

  # 📝 Used to reference the existing Azure resource group in multiple modules and data sources.
  # You can override this value via CLI or Terraform workspace vars if needed.
}

# ---------------------------------------------------------
# Container Image Version Variable
# ---------------------------------------------------------
variable "image_version" {
  description = "Container image version to use"
  type        = string                      # Should match the tag of the container image in ACR
  default     = "rc1"                       # Example: rc1, v1.0.0, latest, etc.

  # 📝 Used when referencing the full container image path, e.g.:
  # <acr_login_server>/flask-api:<image_version>
  # Allows dynamic version pinning for staging, testing, or production releases.
}

# ---------------------------------------------------------
# Azure Container Registry Name Variable
# ---------------------------------------------------------
variable "acr_name" {
  description = "Name of the ACR repository"
  type        = string                      # Must be a valid Azure resource name (e.g., lowercase, no spaces)

  # 📝 Used to resolve ACR metadata using the azurerm_container_registry data source.
  # Enables role assignment (e.g., acrpull) and dynamic container image referencing.
}
