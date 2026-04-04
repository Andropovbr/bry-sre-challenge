#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
REPO_NAME="ingress-nginx"
REPO_URL="https://kubernetes.github.io/ingress-nginx"

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

echo "Deployment submitted successfully."
kubectl get pods -n "${NAMESPACE}"
kubectl get svc -n "${NAMESPACE}"