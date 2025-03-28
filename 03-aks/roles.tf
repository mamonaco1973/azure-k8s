# ---------------------------------------------------------
# Custom Cosmos DB Role Definition for Fine-Grained Access
# ---------------------------------------------------------

# This custom role will be assigned to the AKS-managed identity using Workload Identity.
# It grants only the necessary permissions to interact with Cosmos DB containers and items — nothing more.

resource "azurerm_cosmosdb_sql_role_definition" "custom_cosmos_role" {
  name                = "CustomCosmoDBRole"  # Logical name of the custom role (visible in Azure portal under Cosmos DB Roles)

  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  # Resource group where the Cosmos DB account exists

  account_name        = azurerm_cosmosdb_account.candidate_account.name
  # Cosmos DB SQL API account where the role will be defined

  type                = "CustomRole"
  # Required value — only "CustomRole" is allowed here when defining your own role

  assignable_scopes   = [
    azurerm_cosmosdb_account.candidate_account.id
  ]
  # List of resource scopes where this role is valid. In this case, the entire Cosmos DB account.
  # You could scope it further to a database or container for tighter access control.

  permissions {
    data_actions = [
      # Allows the identity to read account-level metadata (e.g., database/container names)
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",

      # Full access to all containers inside all SQL databases
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",

      # Full access to items (documents) in all containers
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"

      # 👆 These wildcards can be fine-tuned if needed — e.g., for read-only or limited access roles
    ]
  }
}
