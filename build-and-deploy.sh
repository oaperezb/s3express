#!/bin/bash
set -euo pipefail

echo "Building S3Express Docker image..."
docker build -t s3express-mount:latest .

echo "Creating namespace if it doesn't exist..."
kubectl create namespace s3onezone --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Kubernetes resources..."
kubectl apply -f aws-credentials-secret.yaml
kubectl apply -f rbac.yaml
kubectl apply -f k8s-deployment.yaml

echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/s3express-app -n s3onezone

echo "Deployment complete! You can check the logs with:"
echo "kubectl logs -f deployment/s3express-app -n s3onezone"
