resource "helm_release" "fluentbit" {
  name       = "fluentbit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"

  values = [
    templatefile("values.yaml.tpl", {
      aws_region          = var.region
      log_group_name      = local.log_group_name
      kinesis_stream_name = local.kinesis_stream_name
      role_arn            = local.role_arn
    })
  ]
}