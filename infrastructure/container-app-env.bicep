param name string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
param logAnalyticsPrimaryKey string

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: name
  location: location
  properties: any({
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsPrimaryKey
      }
    }
    zoneRedunant: false
  })
}

output managedEnvId string = containerAppEnv.id
