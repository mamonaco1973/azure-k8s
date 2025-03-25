resource "kubernetes_secret" "autoscaler_secret" {
  metadata {
    name      = "cluster-autoscaler-azure"
    namespace = "kube-system"
  }

  data = {
    "client-id"       = data.azurerm_client_config.current.client_id
    "client-secret"   = var.azure_client_secret             # Only this needs to be passed manually
    "tenant-id"       = data.azurerm_client_config.current.tenant_id
    "subscription-id" = data.azurerm_subscription.primary.subscription_id
    "resource-group"  = azurerm_kubernetes_cluster.flask_aks.node_resource_group
  }

  type = "Opaque"
}

variable "azure_client_secret" {}