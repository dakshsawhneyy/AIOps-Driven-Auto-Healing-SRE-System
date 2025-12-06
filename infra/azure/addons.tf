# resource "helm_release" "fluentbit" {
#   name       = "fluent-bit"
#   repository = "https://fluent.github.io/helm-charts"
#   chart      = "fluent-bit"

#   # provider = helm.aks_cluster
#   depends_on = [ azurerm_kubernetes_cluster.demo, kubernetes_secret.fluentbit_aws_creds ]
#   timeout = 600

#   values = [
#     templatefile("values.yaml.tpl", {
#       aws_region          = var.region
#       log_group_name      = local.log_group_name
#       kinesis_stream_name = local.kinesis_stream_name
#     })
#   ]
# }