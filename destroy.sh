cd "03-aks"

echo "NOTE: Destroying AKS cluster."

RESOURCE_GROUP="aks-flaskapp-rg"
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[?starts_with(name, 'flaskapp')].name | [0]" --output tsv)

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform destroy \
  -var="acr_name=${ACR_NAME}" \
  -auto-approve

rm -f -r .terraform terraform*
cd ..

echo "NOTE: Destroying ACR instance."

cd "01-acr"
if [ ! -d ".terraform" ]; then
    terraform init
fi

terraform destroy -auto-approve
rm -f -r .terraform terraform*
cd ..




