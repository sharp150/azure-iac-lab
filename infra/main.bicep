// Starter: secure storage account in an existing resource group
@description('Location for resources')
param location string = 'uksouth'

@description('Short prefix for names (lowercase, 3-11 chars)')
@minLength(3)
@maxLength(11)
param prefix string = 'wrlab'

var tags = {
  owner: 'wayne'
  env: 'lab'
  managedBy: 'bicep'
}

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

output storageAccountName string = sa.name
