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


# Creating Layer 
pip install \
  --platform=manylinux2014_x86_64 \
  --only-binary=:all: \
  numpy==1.26.4 \
  scipy==1.12.0 \
  scikit-learn==1.4.0 \
  -t python

find python -type f -name "*.so*" -exec strip --strip-unneeded {} \;
rm -rf python/*/tests

find python -type d -name "*.dist-info" -exec rm -rf {} +
find python -type d -name "__pycache__" -exec rm -rf {} +

zip -r9 layer.zip python
du -h layer.zip



# ECR Commands
aws ecr create-repository --repository-name inference
docker buildx build --platform linux/amd64 -t inference .
docker tag inference:latest <your_account_id>.dkr.ecr.ap-south-1.amazonaws.com/inference:latest
docker push <your_account_id>.dkr.ecr.ap-south-1.amazonaws.com/inference:latest


# docker buildx rm lambda_builder
docker buildx create --name lambda_builder --use
docker buildx inspect --bootstrap
docker buildx build \
  --platform linux/amd64 \
  -t inference:latest \
  --load \
  .

