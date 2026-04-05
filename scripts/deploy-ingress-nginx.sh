#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="bry-sre-challenge-eks"
AWS_REGION="us-east-1"
NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
REPO_NAME="ingress-nginx"
REPO_URL="https://kubernetes.github.io/ingress-nginx"

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

echo "Adding Helm repository..."
helm repo add "${REPO_NAME}" "${REPO_URL}" >/dev/null 2>&1 || true

echo "Updating Helm repositories..."
helm repo update

echo "Creating namespace if it does not exist..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

echo "Deploying NGINX Ingress Controller..."
helm upgrade --install "${RELEASE_NAME}" "${REPO_NAME}/ingress-nginx" \
  --namespace "${NAMESPACE}" \
  --set controller.service.type=LoadBalancer

echo "Waiting for ingress-nginx pods..."
kubectl rollout status deployment/ingress-nginx-controller -n "${NAMESPACE}" --timeout=300s

echo "Ingress NGINX deployment completed successfully."
kubectl get pods -n "${NAMESPACE}"
kubectl get svc -n "${NAMESPACE}"