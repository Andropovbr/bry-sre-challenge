#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="bry-sre-challenge-eks"
AWS_REGION="us-east-1"
NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
REPO_NAME="jetstack"
REPO_URL="https://charts.jetstack.io"
CLUSTER_ISSUER_FILE="k8s/cert-manager/cluster-issuer.yaml"
CLUSTER_ISSUER_NAME="letsencrypt-prod"

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

if [[ ! -f "${CLUSTER_ISSUER_FILE}" ]]; then
  echo "ERROR: ClusterIssuer manifest not found: ${CLUSTER_ISSUER_FILE}"
  exit 1
fi

echo "Adding Helm repository..."
helm repo add "${REPO_NAME}" "${REPO_URL}" >/dev/null 2>&1 || true

echo "Updating Helm repositories..."
helm repo update

echo "Creating namespace if it does not exist..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

echo "Deploying cert-manager..."
helm upgrade --install "${RELEASE_NAME}" "${REPO_NAME}/cert-manager" \
  --namespace "${NAMESPACE}" \
  --set crds.enabled=true

echo "Waiting for cert-manager deployments..."
kubectl rollout status deployment/cert-manager -n "${NAMESPACE}" --timeout=300s
kubectl rollout status deployment/cert-manager-webhook -n "${NAMESPACE}" --timeout=300s
kubectl rollout status deployment/cert-manager-cainjector -n "${NAMESPACE}" --timeout=300s

echo "Applying ClusterIssuer..."
kubectl apply -f "${CLUSTER_ISSUER_FILE}"

echo "Validating ClusterIssuer..."
kubectl get clusterissuer "${CLUSTER_ISSUER_NAME}" >/dev/null

echo "cert-manager and ClusterIssuer deployed successfully."
kubectl get pods -n "${NAMESPACE}"
kubectl get clusterissuer