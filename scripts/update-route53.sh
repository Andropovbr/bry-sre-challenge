#!/usr/bin/env bash

set -euo pipefail

AWS_REGION="us-east-1"
HOSTED_ZONE_NAME="andresantos.click"
RECORD_NAME="${1:-}"

if [[ -z "${RECORD_NAME}" ]]; then
  echo "Usage: $0 <record-name>"
  echo "Example: $0 whoami.andresantos.click"
  echo "Example: $0 grafana.andresantos.click"
  exit 1
fi

if [[ "${RECORD_NAME}" != *.${HOSTED_ZONE_NAME} && "${RECORD_NAME}" != "${HOSTED_ZONE_NAME}" ]]; then
  echo "ERROR: Record name must belong to hosted zone ${HOSTED_ZONE_NAME}"
  exit 1
fi

echo "Fetching ingress hostname..."
LB_HOSTNAME=$(kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [[ -z "${LB_HOSTNAME}" ]]; then
  echo "ERROR: Could not retrieve load balancer hostname"
  exit 1
fi

echo "Load Balancer hostname: ${LB_HOSTNAME}"

echo "Fetching Hosted Zone ID..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "${HOSTED_ZONE_NAME}" \
  --query 'HostedZones[0].Id' \
  --output text | sed 's|/hostedzone/||')

if [[ -z "${HOSTED_ZONE_ID}" || "${HOSTED_ZONE_ID}" == "None" ]]; then
  echo "ERROR: Could not retrieve hosted zone ID"
  exit 1
fi

echo "Hosted Zone ID: ${HOSTED_ZONE_ID}"

echo "Fetching Load Balancer Hosted Zone ID..."

LB_ZONE_ID=""
LB_TYPE=""

# Try ELBv2 first (ALB/NLB)
LB_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --region "${AWS_REGION}" \
  --query "LoadBalancers[?DNSName=='${LB_HOSTNAME}'].CanonicalHostedZoneId | [0]" \
  --output text 2>/dev/null || true)

if [[ -n "${LB_ZONE_ID}" && "${LB_ZONE_ID}" != "None" ]]; then
  LB_TYPE="elbv2"
else
  # Fallback to Classic ELB
  LB_ZONE_ID=$(aws elb describe-load-balancers \
    --region "${AWS_REGION}" \
    --query "LoadBalancerDescriptions[?DNSName=='${LB_HOSTNAME}'].CanonicalHostedZoneNameID | [0]" \
    --output text 2>/dev/null || true)

  if [[ -n "${LB_ZONE_ID}" && "${LB_ZONE_ID}" != "None" ]]; then
    LB_TYPE="elb"
  fi
fi

if [[ -z "${LB_ZONE_ID}" || "${LB_ZONE_ID}" == "None" ]]; then
  echo "ERROR: Could not retrieve load balancer hosted zone ID"
  exit 1
fi

echo "Load Balancer type: ${LB_TYPE}"
echo "Load Balancer Zone ID: ${LB_ZONE_ID}"

echo "Updating Route53 record: ${RECORD_NAME}"

cat > /tmp/route53-change.json <<EOF
{
  "Comment": "UPSERT alias record for ${RECORD_NAME}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD_NAME}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "${LB_ZONE_ID}",
          "DNSName": "${LB_HOSTNAME}",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --change-batch file:///tmp/route53-change.json \
  --region "${AWS_REGION}"

echo "Route53 record updated successfully for ${RECORD_NAME}."