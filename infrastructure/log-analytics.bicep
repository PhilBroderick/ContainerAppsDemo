param location string = resourceGroup().location
param name string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: name
  location: location
  properties: any({
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  })
}

output customerId string = logAnalytics.properties.customerId
output primaryKey string = logAnalytics.listKeys().primarySharedKey
