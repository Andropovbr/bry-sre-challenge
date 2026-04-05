#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="bry-sre-challenge-eks"
AWS_REGION="us-east-1"
APP_NAMESPACE="app"
APP_MANIFEST_DIR="k8s/app"

echo "Checking EKS cluster status..."
CLUSTER_STATUS="$(aws eks describe-cluster \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" \
  --query 'cluster.status' \
  --output text)"

if [[ "${CLUSTER_STATUS}" != "ACTIVE" ]]; then
  echo "ERROR: EKS cluster '${CLUSTER_NAME}' is not ACTIVE. Current status: ${CLUSTER_STATUS}"
  exit 1
fi

echo "Updating kubeconfig..."
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" >/dev/null

echo "Validating cluster connectivity..."
kubectl cluster-info >/dev/null

echo "Applying application manifests..."
kubectl apply -f "${APP_MANIFEST_DIR}/namespace.yaml"
kubectl apply -f "${APP_MANIFEST_DIR}/deployment.yaml"
kubectl apply -f "${APP_MANIFEST_DIR}/service.yaml"
kubectl apply -f "${APP_MANIFEST_DIR}/ingress.yaml"

echo "Waiting for application rollout..."
kubectl rollout status deployment/whoami -n "${APP_NAMESPACE}" --timeout=300s

echo "Application deployed successfully."
kubectl get pods -n "${APP_NAMESPACE}"
kubectl get svc -n "${APP_NAMESPACE}"
kubectl get ingress -n "${APP_NAMESPACE}"