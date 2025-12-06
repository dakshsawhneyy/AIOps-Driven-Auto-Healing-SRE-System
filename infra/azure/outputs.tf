output "resource_group_name" {
  value = azurerm_resource_group.demo.name
}

output "aks_cluster_nodes" {
  value = azurerm_kubernetes_cluster.demo.default_node_pool
}

output "acr_repo_name" {
  value = azurerm_container_registry.acr.name
}