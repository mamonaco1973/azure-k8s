# ---------------------------------------------------------
# STEP 1: Destroy AKS Cluster and Related Resources
# ---------------------------------------------------------
cd "03-aks"  # Navigate to the AKS Terraform module directory

echo "NOTE: Destroying AKS cluster."

RESOURCE_GROUP="aks-flaskapp-rg"

# Dynamically look up the ACR name that starts with 'apps'
# Required because `acr_name` is a Terraform input variable used during apply/destroy
ACR_NAME=$(az acr list \
  --resource-group $RESOURCE_GROUP \
  --query "[?starts_with(name, 'apps')].name | [0]" \
  --output tsv)

# Initialize Terraform backend if not already initialized
# This ensures we can run `terraform destroy` without errors
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Destroy all AKS-related resources (cluster, identity bindings, federated creds, etc.)
# Pass in the ACR name as a variable to match the original apply command
terraform destroy \
  -var="acr_name=${ACR_NAME}" \
  -auto-approve              # Run without prompt for confirmation (forceful destroy)

# Clean up local Terraform state and cache
rm -f -r .terraform terraform*
cd ..  # Return to root directory

# ---------------------------------------------------------
# STEP 2: Destroy ACR Instance
# ---------------------------------------------------------
echo "NOTE: Destroying ACR instance."

cd "01-acr"  # Navigate to the ACR Terraform module directory

# Initialize Terraform if needed (required before running destroy)
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Destroy the ACR registry and any associated role assignments
terraform destroy -auto-approve

# Clean up local Terraform state and plugin cache
rm -f -r .terraform terraform*
cd ..  # Return to root directory
