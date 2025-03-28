# ---------------------------------------------------------
# AKS Cluster Resource Definition (with node labels)
# ---------------------------------------------------------
resource "azurerm_kubernetes_cluster" "flask_aks" {
  name                = "flask-aks"  # Name of the Azure Kubernetes Service (AKS) cluster
  location            = data.azurerm_resource_group.aks_flaskapp_rg.location  # Use the same region as the target resource group
  resource_group_name = data.azurerm_resource_group.aks_flaskapp_rg.name      # Reference the existing resource group
  dns_prefix          = "flaskkube"  # Used to create the public FQDN for the AKS API server

  # -------------------------------------------------------
  # Default Node Pool Configuration
  # -------------------------------------------------------
  default_node_pool {
    name       = "default"            # Name of the system node pool
    min_count  = 1                    # Minimum node count for autoscaler
    max_count  = 3                    # Maximum node count for autoscaler
    vm_size    = "Standard_D2s_v3"    # VM size used for the nodes
    auto_scaling_enabled = true       # Enables autoscaling for this node pool

    # Upgrade strategy for safer and faster rolling upgrades
    upgrade_settings {
      drain_timeout_in_minutes        = 0     # Graceful pod drain wait time is zero (aggressive drain)
      max_surge                       = "10%" # Allow temporary extra nodes during upgrades
      node_soak_duration_in_minutes   = 0     # Skip waiting period after upgrades
    }

    # Node labels to assist cluster autoscaler and workload scheduling
    node_labels = {
      cluster-autoscaler-enabled = "true"      # Label to indicate autoscaling is active on this node pool
      cluster-autoscaler-name    = "flask-aks" # Custom label (useful for autoscaler selectors)
    }
  }

  # -------------------------------------------------------
  # Networking Configuration
  # -------------------------------------------------------
  network_profile {
    network_plugin    = "azure"       # Use Azure CNI (supports VNet integration, custom IPs per pod)
    load_balancer_sku = "standard"    # Use Standard Load Balancer for higher availability and features
  }

  # -------------------------------------------------------
  # OIDC and Workload Identity (For Secure Pod-to-Azure Access)
  # -------------------------------------------------------
  oidc_issuer_enabled       = true   # Enables OIDC issuer URL on the cluster (required for federated identity)
  workload_identity_enabled = true   # Enables Azure Workload Identity integration with Kubernetes service accounts

  # -------------------------------------------------------
  # Cluster Identity (User-Assigned Managed Identity)
  # -------------------------------------------------------
  identity {
    type         = "UserAssigned"     # Use user-managed identity (preferred for reuse and least privilege)
    identity_ids = [azurerm_user_assigned_identity.k8s_identity.id]  # Reference to the managed identity to use
  }

  # -------------------------------------------------------
  # Metadata Tags
  # -------------------------------------------------------
  tags = {
    environment = "dev"               # Environment tag for organization, cost management, etc.
  }
}

# ---------------------------------------------------------
# Kubernetes Provider Configuration (for Terraform)
# ---------------------------------------------------------
provider "kubernetes" {
  # Connects to the AKS cluster using Terraform-provided credentials
  host                   = azurerm_kubernetes_cluster.flask_aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flask_aks.kube_config[0].cluster_ca_certificate)
}

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
# Service Account for CosmosDB Access (Workload Identity)
# ---------------------------------------------------------
resource "kubernetes_service_account" "cosmosdb_access" {
  metadata {
    name      = "cosmosdb-access-sa"  # Kubernetes service account used by pods accessing CosmosDB
    namespace = "default"             # Namespace where this service account is defined

    annotations = {
      # Bind the SA to the Azure managed identity for federated authentication
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.k8s_identity.client_id
    }
  }
}

# ---------------------------------------------------------
# Service Account for Cluster Autoscaler
# ---------------------------------------------------------
resource "kubernetes_service_account" "autoscaler" {
  metadata {
    name      = "cluster-autoscaler"  # Name expected by the autoscaler Helm chart or deployment
    namespace = "kube-system"         # System-level namespace (standard location for system services)

    annotations = {
      # Bind to the same managed identity for workload identity access
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.k8s_identity.client_id
    }
  }
}

# ---------------------------------------------------------
# Lookup the AKS-Generated Node Resource Group
# ---------------------------------------------------------
data "azurerm_resource_group" "aks_node_rg" {
  name = azurerm_kubernetes_cluster.flask_aks.node_resource_group
  # Dynamically resolves the special RG Azure creates for AKS agent resources (e.g., VMSS, NSGs, disks)
}
