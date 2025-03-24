# ------------------------------------------
# User-Assigned Managed Identity
# ------------------------------------------

# Creates a user-assigned managed identity for AKS.
# This identity is used to authenticate with Azure services (e.g., Azure Container Registry, Cosmos DB).

resource "azurerm_user_assigned_identity" "k8s_identity" {
  location            = data.azurerm_resource_group.aks_flaskapp_rg.location    # Same location as the resource group
  name                = "k8s-identity"                                          # Name of the managed identity
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name        # Resource group name
}

# --------------------------------------------------
# Assign ACRPULL Role to K8S Managed Identity 
# --------------------------------------------------

# Grants the container app's managed identity permission to pull images from Azure Container Registry.

resource "azurerm_role_assignment" "k8s_acr_role" {
  scope                = data.azurerm_container_registry.flask_acr.id
  role_definition_name = "acrpull"
  principal_id         = azurerm_user_assigned_identity.k8s_identity.principal_id
}

# -----------------------------------------------
# Assign CosmosDB Role to K8S Managed Identity
# -----------------------------------------------

resource "azurerm_cosmosdb_sql_role_assignment" "k8s_cosmosdb_role" {
  principal_id        = azurerm_user_assigned_identity.k8s_identity.principal_id   # Assigning the role to the container app's identity
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id # Using a custom CosmosDB role definition
  scope               = azurerm_cosmosdb_account.candidate_account.id              # Applying the role at the CosmosDB account level
  account_name        = azurerm_cosmosdb_account.candidate_account.name            # Target CosmosDB account
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name           # Resource group name
}


resource "azurerm_federated_identity_credential" "cosmosdb_sa_binding" {
  name                = "flaskapp-federated-cred"
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  parent_id           = azurerm_user_assigned_identity.k8s_identity.id

  issuer   = azurerm_kubernetes_cluster.flask_aks.oidc_issuer_url
  subject  = "system:serviceaccount:default:cosmosdb-access-sa"
  audience = ["api://AzureADTokenExchange"]
}
