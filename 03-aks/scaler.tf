# resource "kubernetes_deployment" "cluster_autoscaler" {
#   metadata {
#     name      = "cluster-autoscaler"
#     namespace = "kube-system"
#     labels = {
#       app = "cluster-autoscaler"
#     }
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "cluster-autoscaler"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "cluster-autoscaler"
#         }
#         annotations = {
#           "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
#         }
#       }

#       spec {
#         service_account_name = "cluster-autoscaler"

#         container {
#           name  = "cluster-autoscaler"
#           image = "registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.0"

#           command = [
#             "./cluster-autoscaler",
#             "--v=4",
#             "--cloud-provider=azure",
#             "--skip-nodes-with-local-storage=false",
#             "--expander=least-waste",
#             "--balance-similar-node-groups",
#             "--nodes=1:5:default"
#           ]

#           resources {
#             limits = {
#               cpu    = "100m"
#               memory = "300Mi"
#             }
#             requests = {
#               cpu    = "100m"
#               memory = "300Mi"
#             }
#           }

#           env {
#             name = "AZURE_ARM_SUBSCRIPTION_ID"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.autoscaler_secret.metadata[0].name
#                 key  = "subscription-id"
#               }
#             }
#           }

#           env {
#             name = "AZURE_ARM_RESOURCE_GROUP"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.autoscaler_secret.metadata[0].name
#                 key  = "resource-group"
#               }
#             }
#           }

#           env {
#             name = "AZURE_ARM_TENANT_ID"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.autoscaler_secret.metadata[0].name
#                 key  = "tenant-id"
#               }
#             }
#           }

#           env {
#             name = "AZURE_ARM_CLIENT_ID"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.autoscaler_secret.metadata[0].name
#                 key  = "client-id"
#               }
#             }
#           }

#           env {
#             name = "AZURE_ARM_CLIENT_SECRET"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.autoscaler_secret.metadata[0].name
#                 key  = "client-secret"
#               }
#             }
#           }
#         }

#         toleration {
#           key      = "CriticalAddonsOnly"
#           operator = "Exists"
#         }
#       }
#     }
#   }
# }
