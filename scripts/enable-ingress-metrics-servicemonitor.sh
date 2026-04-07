#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="bry-sre-challenge-eks"
AWS_REGION="us-east-1"
NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
REPO_NAME="ingress-nginx"
REPO_URL="https://kubernetes.github.io/ingress-nginx"
VALUES_FILE="k8s/ingress-nginx/values-observability.yaml"

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

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

if ! kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
  echo "ERROR: ServiceMonitor CRD not found. Install kube-prometheus-stack first."
  exit 1
fi

echo "Adding Helm repository..."
helm repo add "${REPO_NAME}" "${REPO_URL}" >/dev/null 2>&1 || true

echo "Updating Helm repositories..."
helm repo update

echo "Enabling ingress-nginx ServiceMonitor..."
helm upgrade --install "${RELEASE_NAME}" "${REPO_NAME}/ingress-nginx" \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}"

echo "Waiting for ingress-nginx controller deployment..."
kubectl rollout status deployment/ingress-nginx-controller -n "${NAMESPACE}" --timeout=300s

echo "Ingress ServiceMonitor enabled successfully."
kubectl get svc -n "${NAMESPACE}"
kubectl get servicemonitor -n "${NAMESPACE}"