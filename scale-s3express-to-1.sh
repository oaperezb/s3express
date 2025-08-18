#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-s3onezone}
DEPLOYMENT=${DEPLOYMENT:-s3express-app}
REPLICAS=${REPLICAS:-1}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but not installed or not in PATH" >&2
  exit 1
fi

echo "Scaling deployment/$DEPLOYMENT to $REPLICAS in namespace $NAMESPACE..."
kubectl scale deployment "$DEPLOYMENT" -n "$NAMESPACE" --replicas="$REPLICAS"

echo "Waiting for rollout to complete..."
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"

echo "Current replica summary:"
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
  -o custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,AVAILABLE:.status.availableReplicas --no-headers
