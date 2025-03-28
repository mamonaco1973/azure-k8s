# ---------------------------------------------------------
# Resource Group Name Variable
# ---------------------------------------------------------

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string                       # Enforce that the input must be a string (e.g., "dev-rg", "prod-rg")

  default     = "aks-flaskapp-rg"            # Default value used when no override is provided

  # ✅ This variable is used to:
  #   - Look up an existing resource group (via data sources)
  #   - Deploy new resources into the specified group (VNet, ACR, AKS, CosmosDB, etc.)

  # 📝 Override examples:
  #   - CLI: `terraform apply -var="resource_group_name=staging-rg"`
  #   - TFVAR file: include `resource_group_name = "prod-rg"`
  #   - CI/CD: pass via environment variable `TF_VAR_resource_group_name`

  # 🔐 Keep names lowercase, alphanumeric, and consistent across environments to avoid confusion.
}
