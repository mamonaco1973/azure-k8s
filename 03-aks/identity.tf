# ---------------------------------------------------------
# User-Assigned Managed Identity for AKS Workload Identity
# ---------------------------------------------------------

# This identity will be bound to Kubernetes service accounts via federated identity credentials.
# It allows AKS pods to securely access Azure resources like ACR and Cosmos DB without needing secrets.

resource "azurerm_user_assigned_identity" "k8s_identity" {
  location            = data.azurerm_resource_group.aks_flaskapp_rg.location     # Place identity in same region as AKS cluster
  name                = "k8s-identity"                                           # Friendly name for tracking in Azure portal
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name         # Identity lives in the same RG as AKS
}

resource "azurerm_role_assignment" "k8s_identity_network_contributor" {
  scope                = data.azurerm_resource_group.aks_flaskapp_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.k8s_identity.principal_id
}

# ---------------------------------------------------------
# Role Assignment: Allow Pulling Images from ACR
# ---------------------------------------------------------

# This gives the managed identity permission to pull container images from Azure Container Registry.
# Required if you're deploying workloads from private ACR into AKS.

resource "azurerm_role_assignment" "k8s_acr_role" {
  scope                = data.azurerm_container_registry.flask_acr.id             # Assign permission at ACR scope
  role_definition_name = "acrpull"                                                # Built-in role that grants pull-only access to ACR
  principal_id         = azurerm_user_assigned_identity.k8s_identity.principal_id # Target the AKS managed identity
}

# ---------------------------------------------------------
# Role Assignment: Custom Cosmos DB Role for AKS Identity
# ---------------------------------------------------------

# Grants AKS workloads (via managed identity) custom permissions on Cosmos DB.
# Ideal for fine-grained access (e.g., read/write to specific collections).

resource "azurerm_cosmosdb_sql_role_assignment" "k8s_cosmosdb_role" {
  principal_id        = azurerm_user_assigned_identity.k8s_identity.principal_id    # Bind Cosmos DB access to AKS identity
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.custom_cosmos_role.id  # Use a custom-defined Cosmos DB role (not built-in)
  scope               = azurerm_cosmosdb_account.candidate_account.id               # Apply at the Cosmos DB account level
  account_name        = azurerm_cosmosdb_account.candidate_account.name             # Name of Cosmos DB instance
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name            # RG containing Cosmos DB
}

# ---------------------------------------------------------
# Federated Identity Credential for CosmosDB Service Account
# ---------------------------------------------------------

# This binds the AKS Kubernetes service account `cosmosdb-access-sa` to the Azure managed identity.
# Enables Workload Identity: pods using this service account can obtain a token and access Cosmos DB.

resource "azurerm_federated_identity_credential" "cosmosdb_sa_binding" {
  name                = "flaskapp-federated-cred"                                 # Federated credential name in Azure
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name          # RG where the identity lives
  parent_id           = azurerm_user_assigned_identity.k8s_identity.id            # Link to the AKS identity

  issuer   = azurerm_kubernetes_cluster.flask_aks.oidc_issuer_url                 # OIDC URL exposed by the AKS cluster
  subject  = "system:serviceaccount:default:cosmosdb-access-sa"                   # Kubernetes subject (namespace + service account)
  audience = ["api://AzureADTokenExchange"]                                       # Required for Azure token exchange
}

# ---------------------------------------------------------
# Federated Identity Credential for Cluster Autoscaler
# ---------------------------------------------------------

# Binds the K8s service account `cluster-autoscaler` in `kube-system` to the Azure managed identity.
# Enables the autoscaler to authenticate to Azure (e.g., to interact with VMSS APIs).

resource "azurerm_federated_identity_credential" "autoscaler" {
  name                = "autoscaler-federated"                                   # Unique name for the autoscaler federated credential
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name         # Same RG as other components
  parent_id           = azurerm_user_assigned_identity.k8s_identity.id           # Attach to the shared identity

  issuer   = azurerm_kubernetes_cluster.flask_aks.oidc_issuer_url                # AKS cluster's OIDC issuer URL
  subject  = "system:serviceaccount:kube-system:cluster-autoscaler"              # Kubernetes SA for the autoscaler workload
  audience = ["api://AzureADTokenExchange"]                                      # Audience required for token validation in Azure
}
