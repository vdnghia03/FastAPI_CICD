# -----------------------------------
# Resource Group
# -----------------------------------
resource "azurerm_resource_group" "fastapi_rg" {
  name     = "${var.prefix_app_name}-resource-group"
  location = var.location
}

# -----------------------------------
# Container Registry (ACR)
# -----------------------------------
resource "azurerm_container_registry" "acr" {
  name                = "acr${random_integer.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  location            = azurerm_resource_group.fastapi_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# -----------------------------------
# AKS Cluster
# -----------------------------------
resource "azurerm_kubernetes_cluster" "fastapi_aks" {
  name                = "${var.prefix_app_name}-aks-cluster"
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  dns_prefix          = "${var.prefix_app_name}-dns"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# -----------------------------------
# Role Assignment: AKS Pull từ ACR
# -----------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.fastapi_aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# -----------------------------------
# Outputs
# -----------------------------------
output "resource_group_name" {
  value = azurerm_resource_group.fastapi_rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.fastapi_aks.name
}
