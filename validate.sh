#!/bin/bash

# ---------------------------------------------------------
# CONFIG: Max retries and wait interval
# ---------------------------------------------------------
MAX_RETRIES=20
RETRY_DELAY=15
ATTEMPT=1

# ---------------------------------------------------------
# STEP 1: Wait for Ingress External IP from Kubernetes
# ---------------------------------------------------------
while [ $ATTEMPT -le $MAX_RETRIES ]; do

  # Attempt to retrieve the external IP from the Ingress resource
  INGRESS_IP=$(kubectl get ingress flask-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

  if [ -n "$INGRESS_IP" ]; then
    echo "NOTE: Ingress IP retrieved: $INGRESS_IP"
    break
  fi

  echo "WARNING: Ingress IP not yet assigned. Retrying in $RETRY_DELAY seconds..."
  sleep $RETRY_DELAY
  ((ATTEMPT++))
done

# Final validation after exhausting retries
if [ -z "$INGRESS_IP" ]; then
  echo "ERROR: Failed to retrieve the Ingress IP address after $MAX_RETRIES attempts."
  exit 1
fi

# ---------------------------------------------------------
# STEP 2: Wait Until Flask API Is Ready and Responding (HTTP 200)
# ---------------------------------------------------------
while true; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://$INGRESS_IP/flask-app/api/candidate/John%20Smith")

    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "NOTE: API is now reachable."
        break
    else
        echo "WARNING: API is not yet reachable (HTTP $HTTP_STATUS). Retrying in 30s..."
        sleep 30
    fi
done

# ---------------------------------------------------------
# STEP 3: Run End-to-End Test Script Against the Flask API
# ---------------------------------------------------------

DNS_NAME=$(az network public-ip show \
  --name nginx-ingress-ip \
  --resource-group aks-flaskapp-rg \
  --query "dnsSettings.fqdn" \
  --output tsv)

if [ -z "$DNS_NAME" ]; then
  echo "ERROR: Failed to retrieve DNS label from public IP."
  exit 1
fi

cd ./02-docker

SERVICE_URL="http://$DNS_NAME/flask-app/api"

echo "NOTE: Testing the AKS Solution."
echo "NOTE: URL for AKS Deployment is $SERVICE_URL/gtg?details=true"

./test_candidates.py "$SERVICE_URL"

cd ..
