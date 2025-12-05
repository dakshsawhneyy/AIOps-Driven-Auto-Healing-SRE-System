resource "azurerm_role_assignment" "demo" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.demo.identity[0].principal_id
}
resource "azurerm_role_assignment" "demo-2" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.demo.identity[0].principal_id
}