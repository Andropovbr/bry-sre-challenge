#!/usr/bin/env bash

set -euo pipefail

AWS_REGION="us-east-1"
HOSTED_ZONE_NAME="andresantos.click"
RECORD_NAME="whoami.andresantos.click"

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

echo "Hosted Zone ID: ${HOSTED_ZONE_ID}"

echo "Fetching Load Balancer Hosted Zone ID..."
LB_ZONE_ID=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='${LB_HOSTNAME}'].CanonicalHostedZoneId" \
  --output text)

echo "Load Balancer Zone ID: ${LB_ZONE_ID}"

echo "Updating Route53 record..."

cat > /tmp/route53-change.json <<EOF
{
  "Comment": "Update record for whoami",
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
  --change-batch file:///tmp/route53-change.json

echo "Route53 record updated successfully."