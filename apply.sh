#!/bin/bash

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Navigate to the 01-acr directory
cd "01-acr" 
echo "NOTE: Building ACR Instance."

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform apply -auto-approve

# Return to the parent directory
cd ..

# Navigate to the 02-docker directory

cd "02-docker"
echo "NOTE: Building flask container with Docker."

RESOURCE_GROUP="aks-flaskapp-rg"
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[?starts_with(name, 'flaskapp')].name | [0]" --output tsv)
az acr login --name $ACR_NAME
ACR_REPOSITORY="${ACR_NAME}.azurecr.io/flask-app"
IMAGE_TAG="flask-app-rc1"
docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push

cd ..

# Navigate to the 03-aks directory
cd 03-aks
echo "NOTE: Building AKS instance."

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform apply -var="acr_name=$ACR_NAME" -auto-approve

# Replace placeholder in the Kubernetes deployment template
sed "s/\${ACR_NAME}/$ACR_NAME/g" yaml/flask-app.yaml.tmpl > ../flask-app.yaml || {
    echo "ERROR: Failed to generate Kubernetes deployment file. Exiting."
    exit 1
}

# Find Cosmos DB account in known resource group
COSMOS_NAME=$(az cosmosdb list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[?starts_with(name, 'candidates')].name | [0]" \
  -o tsv)

if [[ -z "$COSMOS_NAME" ]]; then
  echo "❌ No Cosmos DB account starting with 'candidates' found in $RESOURCE_GROUP."
  exit 1
fi

# Get the endpoint
COSMOS_ENDPOINT=$(az cosmosdb show \
  --name "$COSMOS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "documentEndpoint" \
  -o tsv)

sed -i "s|\${COSMOS_ENDPOINT}|$COSMOS_ENDPOINT|g" ../flask-app.yaml


# Return to the parent directory
cd ..

# Configure kubectl to point to new AKS cluster

rm -f -r ~/.kube
az aks get-credentials --resource-group aks-flaskapp-rg --name flask-aks

# Attach ACR repository to AKS instance

az aks update --name flask-aks --resource-group aks-flaskapp-rg --attach-acr $ACR_NAME  > /dev/null

# Execute the validation script

#helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
#helm repo update

#helm upgrade --install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
#  --namespace azure-workload-identity-system \
#  --create-namespace \
#  --set azureTenantID=$ARM_TENANT_ID

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace


#./validate.sh


