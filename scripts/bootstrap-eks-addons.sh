#!/usr/bin/env bash

set -euo pipefail

APP_HOSTNAME="${APP_HOSTNAME:-whoami.andresantos.click}"
GRAFANA_HOSTNAME="${GRAFANA_HOSTNAME:-grafana.andresantos.click}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
INGRESS_SERVICE_NAME="${INGRESS_SERVICE_NAME:-ingress-nginx-controller}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-600}"
WAIT_INTERVAL_SECONDS="${WAIT_INTERVAL_SECONDS:-10}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  echo
  echo "==> $1"
}

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: ${cmd}"
    exit 1
  fi
}

wait_for_ingress_lb() {
  log "Waiting for ingress LoadBalancer hostname..."

  local elapsed=0
  local lb_hostname=""

  while [[ "${elapsed}" -lt "${WAIT_TIMEOUT_SECONDS}" ]]; do
    lb_hostname="$(kubectl get svc "${INGRESS_SERVICE_NAME}" -n "${INGRESS_NAMESPACE}" \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

    if [[ -n "${lb_hostname}" ]]; then
      echo "Ingress LoadBalancer hostname: ${lb_hostname}"
      return 0
    fi

    echo "Still waiting for LoadBalancer hostname... (${elapsed}s elapsed)"
    sleep "${WAIT_INTERVAL_SECONDS}"
    elapsed=$((elapsed + WAIT_INTERVAL_SECONDS))
  done

  echo "ERROR: Timed out waiting for ingress LoadBalancer hostname"
  exit 1
}

log "Validating prerequisites..."
require_command kubectl
require_command helm
require_command aws

log "Deploying ingress-nginx..."
"${SCRIPT_DIR}/deploy-ingress-nginx.sh"

wait_for_ingress_lb

log "Deploying cert-manager..."
"${SCRIPT_DIR}/deploy-cert-manager.sh"

log "Deploying sample application..."
"${SCRIPT_DIR}/deploy-app.sh"

log "Updating Route53 record for application..."
"${SCRIPT_DIR}/update-route53.sh" "${APP_HOSTNAME}"

log "Creating/updating Grafana admin secret..."
"${SCRIPT_DIR}/create-grafana-secret.sh"

log "Installing observability stack..."
"${SCRIPT_DIR}/install-observability.sh"

log "Updating Route53 record for Grafana..."
"${SCRIPT_DIR}/update-route53.sh" "${GRAFANA_HOSTNAME}"

log "Bootstrap completed successfully."

echo
echo "Next validation steps:"
echo "  kubectl get pods -A"
echo "  kubectl get ingress -A"
echo "  kubectl get certificate -A"
echo "  curl -I https://${APP_HOSTNAME}"
echo "  curl -I https://${GRAFANA_HOSTNAME}"