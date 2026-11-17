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
  sku: { name: 'Standard_ZRS' } // cheapest SKU that passes Azure.Storage.UseReplication
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
    defaultToOAuthAuthentication: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    deleteRetentionPolicy: { enabled: true, days: 7 }
    containerDeleteRetentionPolicy: { enabled: true, days: 7 }
  }
}

// Sink for diagnostic settings. Daily cap keeps ingestion cost bounded.
resource law 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: 'log-${prefix}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    workspaceCapping: { dailyQuotaGb: json('0.1') } // ~100 MB/day worst case
    replication: { enabled: true, location: 'ukwest' }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    features: { disableLocalAuth: true }
  }
}

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
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    diagnosticSettings: [
      {
        workspaceResourceId: law.id
        logCategoriesAndGroups: [{ categoryGroup: 'audit' }]
        metricCategories: [{ category: 'AllMetrics' }]
      }
    ]
    enableVaultForDeployment: false
    enableVaultForTemplateDeployment: false
    enableVaultForDiskEncryption: false
    enableTelemetry: false
  }
}

output storageAccountName string = sa.name
