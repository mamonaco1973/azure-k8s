#!/bin/bash


# Parse the service object to get the service IP address

SERVICE_IP=$(kubectl get service flask-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')


# Check if the IP was successfully extracted
if [ -z "$SERVICE_IP" ]; then
  echo "ERROR: Failed to retrieve the service IP address."
  exit 1
fi

echo "NOTE: Ingress Load Balancer IP: $SERVICE_IP"

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
echo "NOTE: URL for AKS Deployent is $SERVICE_URL/gtg?details=true"
./test_candidates.py "$SERVICE_URL"

cd ..
