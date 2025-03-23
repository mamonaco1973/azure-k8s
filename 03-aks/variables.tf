variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
  default     = "aks-flaskapp-rg"
}

variable "image_version" {
  description = "Container image version to use"
  type        = string
  default     = "rc1"
}

