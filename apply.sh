#!/bin/bash
# ---------------------------------------------------------
# Script to Provision ACR, Build & Push Docker Image,
# Deploy AKS Cluster, Configure Workload Identity,
# and Deploy Flask App to Kubernetes
# ---------------------------------------------------------

# ---------------------------------------------
# STEP 0: Environment validation
# ---------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# ---------------------------------------------
# STEP 1: Build Azure Container Registry (ACR)
# ---------------------------------------------
cd "01-acr"                     # Move into the ACR provisioning folder
echo "NOTE: Building ACR Instance."

# Initialize Terraform if .terraform folder is not present
if [ ! -d ".terraform" ]; then
    terraform init             # Ensures provider plugins are downloaded
fi

# Apply Terraform to create ACR (no prompt)
terraform apply -auto-approve

cd ..                          # Return to project root

# ---------------------------------------------
# STEP 2: Build and Push Flask App Docker Image
# ---------------------------------------------
cd "02-docker"
echo "NOTE: Building flask container with Docker."

RESOURCE_GROUP="aks-flaskapp-rg"

# Dynamically find the ACR name that starts with 'apps'
ACR_NAME=$(az acr list \
  --resource-group $RESOURCE_GROUP \
  --query "[?starts_with(name, 'apps')].name | [0]" \
  --output tsv)

# Authenticate Docker to the ACR
az acr login --name $ACR_NAME

# Set full image path with tag
ACR_REPOSITORY="${ACR_NAME}.azurecr.io/flask-app"
IMAGE_TAG="flask-app-rc1"

cd flask-app
# Build and push Docker image to ACR
docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push
cd ..

# Set full image path with tag
ACR_REPOSITORY="${ACR_NAME}.azurecr.io/games"
IMAGE_TAG="tetris-rc1"

cd tetris
# Build and push Docker image to ACR
docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push
cd ..

# Set full image path with tag
ACR_REPOSITORY="${ACR_NAME}.azurecr.io/games"
IMAGE_TAG="frogger-rc1"

cd frogger
# Build and push Docker image to ACR
docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push
cd ..

# Set full image path with tag
ACR_REPOSITORY="${ACR_NAME}.azurecr.io/games"
IMAGE_TAG="breakout-rc1"

cd breakout
# Build and push Docker image to ACR
docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push
cd ..
cd ..                          # Return to project root

# ---------------------------------------------
# STEP 3: Build AKS Cluster with Terraform
# ---------------------------------------------
cd 03-aks
echo "NOTE: Building AKS instance."

# Initialize Terraform if not already initialized
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Apply AKS configuration and pass the ACR name as a variable
terraform apply \
  -var="acr_name=${ACR_NAME}" \
  -auto-approve

# ---------------------------------------------
# STEP 4: Prepare Kubernetes Deployment Manifest
# ---------------------------------------------

# Replace ${ACR_NAME} in the deployment template
sed "s/\${ACR_NAME}/$ACR_NAME/g" yaml/flask-app.yaml.tmpl > ../flask-app.yaml || {
    echo "ERROR: Failed to generate Kubernetes deployment file. Exiting."
    exit 1
}

# Replace ${ACR_NAME} in the deployment template
sed "s/\${ACR_NAME}/$ACR_NAME/g" yaml/games.yaml.tmpl > ../games.yaml || {
    echo "ERROR: Failed to generate Kubernetes deployment file. Exiting."
    exit 1
}

# ---------------------------------------------
# STEP 5: Lookup CosmosDB endpoint dynamically
# ---------------------------------------------

# Find the CosmosDB account starting with 'candidates'
COSMOS_NAME=$(az cosmosdb list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[?starts_with(name, 'candidates')].name | [0]" \
  -o tsv)

if [[ -z "$COSMOS_NAME" ]]; then
  echo "❌ No Cosmos DB account starting with 'candidates' found in $RESOURCE_GROUP."
  exit 1
fi

# Get the Cosmos DB endpoint
COSMOS_ENDPOINT=$(az cosmosdb show \
  --name "$COSMOS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "documentEndpoint" \
  -o tsv)

# Inject Cosmos endpoint into the Kubernetes manifest
sed -i "s|\${COSMOS_ENDPOINT}|$COSMOS_ENDPOINT|g" ../flask-app.yaml

cd ..                          # Return to project root

# ---------------------------------------------
# STEP 6: Configure kubectl to connect to AKS
# ---------------------------------------------

rm -f -r ~/.kube               # Clear any existing kubeconfig
az aks get-credentials \
  --resource-group aks-flaskapp-rg \
  --name flask-aks             # Download AKS kubeconfig

# ---------------------------------------------
# STEP 7: Attach ACR to AKS for image pulling
# ---------------------------------------------
az aks update \
  --name flask-aks \
  --resource-group aks-flaskapp-rg \
  --attach-acr $ACR_NAME > /dev/null

# ---------------------------------------------
# STEP 8: Deploy the Flask App to Kubernetes
# ---------------------------------------------

kubectl apply -f flask-app.yaml
kubectl apply -f games.yaml

kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml
# (Optional check that autoscaler is properly configured)

# ---------------------------------------------
# STEP 9: Run post-deployment validation script
# ---------------------------------------------
./validate.sh
# This should verify endpoints, connectivity, and app health
