# ---------------------------------------------------------
# Helm Provider Configuration (for Helm Chart Installs)
# ---------------------------------------------------------
provider "helm" {
  # Uses the same kubeconfig as the Kubernetes provider
  kubernetes {
    host                   = azurerm_kubernetes_cluster.flask_aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].cluster_ca_certificate)
  }
}

# ---------------------------------------------------------
# Deploy the NGINX Ingress Controller via Helm Chart
# ---------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  create_namespace = true
  # Automatically creates the target namespace if it doesn't exist

  values = [file("${path.module}/yaml/nginx-values.yaml")]
  # Loads custom Helm chart values from the specified YAML file
}
