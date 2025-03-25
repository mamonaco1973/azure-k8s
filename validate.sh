#!/bin/bash

MAX_RETRIES=5
RETRY_DELAY=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
#  echo "Attempt $ATTEMPT to retrieve service IP..."
  SERVICE_IP=$(kubectl get service flask-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

  if [ -n "$SERVICE_IP" ]; then
    echo "NOTE: Service IP retrieved: $SERVICE_IP"
    break
  fi

  echo "WARNING: Failed to retrieve service IP. Retrying in $RETRY_DELAY seconds..."
  sleep $RETRY_DELAY
  ((ATTEMPT++))
done

# Final check after retries
if [ -z "$SERVICE_IP" ]; then
  echo "ERROR: Failed to retrieve the service IP address after $MAX_RETRIES attempts."
  exit 1
fi


while true; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://$SERVICE_IP/candidate/John%20Smith")

    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "NOTE: API is now reachable."
        break
    else
        echo "WARNING: API is not yet reachable (HTTP $HTTP_STATUS). Retrying..." 
        sleep 30
    fi
done

# Move to the directory and run the test script
cd ./02-docker
SERVICE_URL="http://$SERVICE_IP"
echo "NOTE: Testing the AKS Solution."
echo "NOTE: URL for AKS Deployment is $SERVICE_URL/gtg?details=true"
./test_candidates.py "$SERVICE_URL"

cd ..
