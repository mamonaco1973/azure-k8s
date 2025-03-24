resource "azurerm_kubernetes_cluster" "flask_aks" {
  name                = "flask-aks"
  location            = data.azurerm_resource_group.aks_flaskapp_rg.location
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name
  dns_prefix          = "flaskkube"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.k8s_identity.id]
  }

  tags = {
    environment = "dev"
  }
}

