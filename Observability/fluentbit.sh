# Add the Fluent Helm repository:
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

# Install Fluent Bit in a dedicated namespace (e.g., fluent-bit):
helm upgrade --install fluent-bit fluent/fluent-bit -f fluent-bit.conf
# helm upgrade --install fluent-bit fluent/fluent-bit --namespace fluent-bit --create-namespace -f values.yaml

# Verify pods
kubectl get pods -n fluent-bit -o wide