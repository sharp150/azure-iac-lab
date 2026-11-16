// Starter: secure storage account in an existing resource group
@description('Location for resources')
param location string = resourceGroup().location

@description('Short prefix for names (lowercase, 3-11 chars)')
@minLength(3)
@maxLength(11)
param prefix string = 'wrlab'

var tags = {
  owner: 'wayne'
  env: 'lab'
  managedBy: 'bicep'
}

@description('Lab storage account: private, Entra-only access, TLS 1.2')
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${prefix}${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
    defaultToOAuthAuthentication: true
  }
}

@description('Lab Key Vault: RBAC, purge protection, private')
module kv 'br/public:avm/res/key-vault/vault:0.14.2' = {
  name: 'keyVaultDeployment'
  params: {
    name: 'kv${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
    sku: 'standard'
    enableRbacAuthorization: true
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    enableVaultForDeployment: false
    enableVaultForTemplateDeployment: false
    enableVaultForDiskEncryption: false
    enableTelemetry: false
  }
}

output storageAccountName string = sa.name
