# Install Node Exporter
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install node-exporter prometheus-community/prometheus-node-exporter


# Normalizer test event
{
   "generate_dataset": true
}


# Chaos_Labeler test event
{
  "action": "start",
  "label": "cpu"
}
{
  "action": "end",
  "label": "cpu"
}


