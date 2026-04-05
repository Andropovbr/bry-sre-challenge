#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="observability"
SECRET_NAME="grafana-admin-credentials"
GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"

# Se não vier por variável, pede interativamente
if [[ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]]; then
  echo "Enter Grafana admin password:"
  read -s GRAFANA_ADMIN_PASSWORD
  echo

  echo "Confirm Grafana admin password:"
  read -s CONFIRM_PASSWORD
  echo

  if [[ "${GRAFANA_ADMIN_PASSWORD}" != "${CONFIRM_PASSWORD}" ]]; then
    echo "ERROR: Passwords do not match"
    exit 1
  fi
fi

# Validação mínima (evita senha zoada na demo)
if [[ ${#GRAFANA_ADMIN_PASSWORD} -lt 8 ]]; then
  echo "ERROR: Password must be at least 8 characters long"
  exit 1
fi

echo "Creating namespace if needed..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "Creating/updating Grafana secret..."
kubectl create secret generic "${SECRET_NAME}" \
  -n "${NAMESPACE}" \
  --from-literal=admin-user="${GRAFANA_ADMIN_USER}" \
  --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Grafana admin secret applied successfully."