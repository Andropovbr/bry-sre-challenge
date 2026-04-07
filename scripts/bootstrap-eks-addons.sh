#!/usr/bin/env bash

set -euo pipefail

APP_HOSTNAME="${APP_HOSTNAME:-whoami.andresantos.click}"
GRAFANA_HOSTNAME="${GRAFANA_HOSTNAME:-grafana.andresantos.click}"
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
INGRESS_SERVICE_NAME="${INGRESS_SERVICE_NAME:-ingress-nginx-controller}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-600}"
WAIT_INTERVAL_SECONDS="${WAIT_INTERVAL_SECONDS:-10}"
START_FROM="${START_FROM:-}"
SKIP_INGRESS="${SKIP_INGRESS:-false}"
SKIP_CERT_MANAGER="${SKIP_CERT_MANAGER:-false}"
SKIP_APP="${SKIP_APP:-false}"
SKIP_ROUTE53_APP="${SKIP_ROUTE53_APP:-false}"
SKIP_GRAFANA_SECRET="${SKIP_GRAFANA_SECRET:-false}"
SKIP_OBSERVABILITY="${SKIP_OBSERVABILITY:-false}"
SKIP_ROUTE53_GRAFANA="${SKIP_ROUTE53_GRAFANA:-false}"
SKIP_INGRESS_SERVICEMONITOR="${SKIP_INGRESS_SERVICEMONITOR:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTED="false"

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

should_run_step() {
  local step_name="$1"

  if [[ -z "${START_FROM}" ]]; then
    return 0
  fi

  if [[ "${STARTED}" == "true" ]]; then
    return 0
  fi

  if [[ "${START_FROM}" == "${step_name}" ]]; then
    STARTED="true"
    return 0
  fi

  return 1
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

run_step() {
  local step_name="$1"
  local step_description="$2"
  local skip_flag="$3"
  shift 3

  if [[ "${skip_flag}" == "true" ]]; then
    echo "Skipping step: ${step_name}"
    return 0
  fi

  if should_run_step "${step_name}"; then
    log "${step_description}"
    "$@"
  else
    echo "Skipping step before START_FROM: ${step_name}"
  fi
}

log "Validating prerequisites..."
require_command kubectl
require_command helm
require_command aws

run_step "ingress" "Deploying ingress-nginx..." "${SKIP_INGRESS}" \
  "${SCRIPT_DIR}/deploy-ingress-nginx.sh"

if [[ "${SKIP_INGRESS}" != "true" ]]; then
  if should_run_step "ingress"; then
    wait_for_ingress_lb
  elif [[ -z "${START_FROM}" ]]; then
    wait_for_ingress_lb
  fi
fi

run_step "cert-manager" "Deploying cert-manager..." "${SKIP_CERT_MANAGER}" \
  "${SCRIPT_DIR}/deploy-cert-manager.sh"

if [[ "${SKIP_CERT_MANAGER}" != "true" ]]; then
  if ! kubectl get clusterissuer letsencrypt-prod >/dev/null 2>&1; then
    echo "ERROR: ClusterIssuer letsencrypt-prod was not created"
    exit 1
  fi
fi

run_step "app" "Deploying sample application..." "${SKIP_APP}" \
  "${SCRIPT_DIR}/deploy-app.sh"

run_step "route53-app" "Updating Route53 record for application..." "${SKIP_ROUTE53_APP}" \
  "${SCRIPT_DIR}/update-route53.sh" "${APP_HOSTNAME}"

run_step "grafana-secret" "Creating/updating Grafana admin secret..." "${SKIP_GRAFANA_SECRET}" \
  "${SCRIPT_DIR}/create-grafana-secret.sh"

run_step "observability" "Installing observability stack..." "${SKIP_OBSERVABILITY}" \
  "${SCRIPT_DIR}/install-observability.sh"

run_step "ingress-servicemonitor" "Enabling ingress-nginx ServiceMonitor..." "${SKIP_INGRESS_SERVICEMONITOR:-false}" \
  "${SCRIPT_DIR}/enable-ingress-metrics-servicemonitor.sh"

run_step "route53-grafana" "Updating Route53 record for Grafana..." "${SKIP_ROUTE53_GRAFANA}" \
  "${SCRIPT_DIR}/update-route53.sh" "${GRAFANA_HOSTNAME}"

log "Bootstrap completed successfully."

echo
echo "Next validation steps:"
echo "  kubectl get pods -A"
echo "  kubectl get ingress -A"
echo "  kubectl get certificate -A"
echo "  curl -I https://${APP_HOSTNAME}"
echo "  curl -I https://${GRAFANA_HOSTNAME}"