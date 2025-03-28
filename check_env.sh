#!/bin/bash

# ---------------------------------------------------------
# Validate Required CLI Tools and Environment Variables
# ---------------------------------------------------------

echo "🔍 Checking required CLI tools in PATH..."

REQUIRED_COMMANDS=("az" "docker" "terraform")
MISSING_COMMANDS=false

for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: '$cmd' is not found in your PATH."
    MISSING_COMMANDS=true
  else
    echo "✅ '$cmd' is available."
  fi
done

if [ "$MISSING_COMMANDS" = true ]; then
  echo "❌ ERROR: One or more required commands are missing. Aborting."
  exit 1
fi

echo "✅ All required commands are available."

# ---------------------------------------------------------
# Validate Required Azure Environment Variables
# ---------------------------------------------------------

echo "🔍 Checking required Azure environment variables..."

REQUIRED_VARS=("ARM_CLIENT_ID" "ARM_CLIENT_SECRET" "ARM_SUBSCRIPTION_ID" "ARM_TENANT_ID")
MISSING_VARS=false

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ ERROR: '$var' is not set or is empty."
    MISSING_VARS=true
  else
    echo "✅ '$var' is set."
  fi
done

if [ "$MISSING_VARS" = true ]; then
  echo "❌ ERROR: One or more required environment variables are missing. Aborting."
  exit 1
fi

echo "✅ All required environment variables are set."

# ---------------------------------------------------------
# Log In to Azure via Service Principal
# ---------------------------------------------------------

echo "🔐 Logging into Azure using service principal credentials..."

if ! az login --service-principal \
              --username "$ARM_CLIENT_ID" \
              --password "$ARM_CLIENT_SECRET" \
              --tenant "$ARM_TENANT_ID" &>/dev/null; then
  echo "❌ ERROR: Azure login failed. Check your credentials and environment variables."
  exit 1
fi

echo "✅ Azure login successful."

# ---------------------------------------------------------
# Ensure Microsoft.App Resource Provider is Registered
# ---------------------------------------------------------

echo "🔄 Registering 'Microsoft.App' resource provider..."

az provider register --namespace Microsoft.App &>/dev/null

# Wait until registration is confirmed
until [[ "$(az provider show --namespace Microsoft.App --query "registrationState" -o tsv)" == "Registered" ]]; do
  echo "⏳ Waiting for 'Microsoft.App' to register..."
  sleep 10
done

echo "✅ 'Microsoft.App' is registered."

# ---------------------------------------------------------
# Validate Role Assignment
# ---------------------------------------------------------

echo "🔍 Checking for 'User Access Administrator' role assignment..."

ASSIGNEE=$(az account show --query "user.name" -o tsv)

if [ -z "$ASSIGNEE" ]; then
  echo "❌ ERROR: Failed to retrieve the current user or service principal."
  exit 1
fi

ROLE_ASSIGNED=$(az role assignment list \
  --assignee "$ASSIGNEE" \
  --query "[?roleDefinitionName=='User Access Administrator']" \
  -o tsv)

if [ -z "$ROLE_ASSIGNED" ]; then
  echo "❌ ERROR: 'User Access Administrator' role is NOT assigned to '$ASSIGNEE'."
  exit 1
fi

echo "✅ 'User Access Administrator' role is assigned to '$ASSIGNEE'."
