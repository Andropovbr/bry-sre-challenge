#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="observability"
VALUES_FILE="k8s/observability/prometheus-values.yaml"
INGRESS_FILE="k8s/observability/grafana-ingress.yaml"

echo "Adding Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

echo "Creating namespace..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}"

echo "Applying Grafana ingress..."
kubectl apply -f "${INGRESS_FILE}"

echo "Done. Current pods:"
kubectl get pods -n "${NAMESPACE}"