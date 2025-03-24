resource "azurerm_kubernetes_cluster" "flask_aks" {
  name                = "flask-aks"
  location            = data.azurerm_resource_group.aks_flaskapp_rg.location
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  dns_prefix          = "flaskkube"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"

    upgrade_settings {
      drain_timeout_in_minutes = 0
      max_surge = "10%"
      node_soak_duration_in_minutes = 0
   }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  oidc_issuer_enabled = true 

  identity {
     type = "SystemAssigned" 
  }

  tags = {
    environment = "dev"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.flask_aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_service_account" "cosmosdb_access" {
  metadata {
    name      = "cosmosdb-access-sa"
    namespace = "default"

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.k8s_identity.client_id
    }
  }
}

