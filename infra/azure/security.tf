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

# Kubernetes Secret for storing credentials
resource "kubernetes_secret" "fluentbit_aws_creds" {
  metadata {
    name      = "fluentbit-aws-credentials" 
  }
  type = "Opaque"
  data = {
    AWS_ACCESS_KEY_ID     = local.fluentbit_access_key
    AWS_SECRET_ACCESS_KEY = local.fluentbit_secret_key
    AWS_REGION = "ap-south-1"
  }
}
