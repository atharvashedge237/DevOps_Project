#!/bin/bash
set -e

echo "🔐 Setting up Secrets Management with Azure Key Vault..."

# Variables
RESOURCE_GROUP="mlops-rg"
VAULT_NAME="mlops-vault"
AKS_CLUSTER="mlops-aks"
NAMESPACE="production"
IDENTITY_NAME="mlops-identity"

# Create managed identity for AKS
echo "📝 Creating managed identity..."
IDENTITY=$(az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query id -o tsv)

echo "✅ Managed identity created: $IDENTITY"

# Get managed identity details
CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query clientId -o tsv)

PRINCIPAL_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query principalId -o tsv)

echo "Client ID: $CLIENT_ID"
echo "Principal ID: $PRINCIPAL_ID"

# Add role assignment for Key Vault access
echo "🔑 Granting Key Vault access..."
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id $PRINCIPAL_ID \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$VAULT_NAME

echo "✅ Key Vault access granted"

# Create secrets in Key Vault
echo "🔒 Creating secrets in Key Vault..."
az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name openai-api-key \
  --value "your-openai-api-key-here"

az keyvault secret set \
  --vault-name $VAULT_NAME \
  --name db-connection-string \
  --value "your-db-connection-string-here"

echo "✅ Secrets created"

# Install Azure Key Vault CSI Driver
echo "📦 Installing Azure Key Vault CSI Driver..."
helm repo add csi-secrets-store-provider-azure https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts
helm repo update

helm install csi-secrets-store-provider-azure csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set secrets-store-csi-driver.install=true \
  --set secrets-store-csi-driver.syncSecret.enabled=true

echo "✅ CSI Driver installed"

# Install AAD Pod Identity
echo "📦 Installing AAD Pod Identity..."
helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
helm repo update

helm install aad-pod-identity aad-pod-identity/aad-pod-identity \
  --namespace kube-system

echo "✅ AAD Pod Identity installed"

# Create namespace and secrets provider
echo "📋 Creating SecretProviderClass..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

cat > secrets-provider-updated.yaml << EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-provider
  namespace: $NAMESPACE
spec:
  provider: azure
  parameters:
    usePodIdentity: "true"
    keyvaultName: "$VAULT_NAME"
    cloudName: "AzurePublicCloud"
    objects: |
      array:
        - |
          objectName: openai-api-key
          objectType: secret
          objectAlias: OPENAI_API_KEY
        - |
          objectName: db-connection-string
          objectType: secret
          objectAlias: DB_CONNECTION_STRING
    tenantID: "$(az account show --query tenantId -o tsv)"
EOF

kubectl apply -f secrets-provider-updated.yaml

# Create Azure Identity and binding
cat > identity-binding.yaml << EOF
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentity
metadata:
  name: mlops-identity
  namespace: $NAMESPACE
spec:
  type: 0
  resourceID: $IDENTITY
  clientID: $CLIENT_ID
---
apiVersion: aadpodidentity.k8s.io/v1
kind: AzureIdentityBinding
metadata:
  name: mlops-identity-binding
  namespace: $NAMESPACE
spec:
  azureIdentity: mlops-identity
  selector: mlops-api
EOF

kubectl apply -f identity-binding.yaml

echo "✅ Secrets management setup complete!"

echo ""
echo "🎯 Next steps:"
echo "1. Update your Deployment to mount the secrets:"
echo "   - Add volumeMount for secrets-store"
echo "   - Add aadpodidbinding label"
echo "2. Update helm values with secret references"
echo "3. Deploy: helm upgrade --install mlops-api ./helm-chart"

# Cleanup temp files
rm -f secrets-provider-updated.yaml identity-binding.yaml
