// Starter: secure storage account in an existing resource group
@description('Location for resources')
param location string = 'uksouth'

@description('Short prefix for names (lowercase, 3-11 chars)')
@minLength(3)
@maxLength(11)
param prefix string = 'wrlab'

@description('Optional names of RSA keys to create; Key Vault generates the key material.')
param nonSecretKeyNames string[] = []

var tags = {
  owner: 'wayne'
  env: 'lab'
  managedBy: 'bicep'
}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: '${prefix}${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: { name: 'Standard_GRS' } // Supported in-place from LRS and passes Azure.Storage.UseReplication
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

resource kv 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: 'kv${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
  }
}

resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultAudit'
  scope: kv
  properties: {
    workspaceId: law.id
    logs: [{ categoryGroup: 'audit', enabled: true }]
    metrics: [{ category: 'AllMetrics', enabled: true }]
  }
}

resource kvKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = [for keyName in nonSecretKeyNames: {
  parent: kv
  name: keyName
  tags: tags
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
      'sign'
      'verify'
    ]
  }
}]

output storageAccountName string = sa.name
