cd "03-containerapp"

echo "NOTE: Destroying container app instance."

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform destroy -auto-approve
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




