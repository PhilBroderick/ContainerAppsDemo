param name string
param location string = resourceGroup().location
param containerAppEnvId string

param containerImage string
param containerRegistry string
param registryUsername string
@secure()
param registryPassword string

param adoUrl string
param adoAgentPool string
@secure()
param adoToken string

resource adoAgentContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: name
  location: location
  properties: {
    configuration: {
      registries: [
        {
          server: containerRegistry
          username: registryUsername
          passwordSecretRef: 'password'
        }
      ]
      secrets: [
        {
          name: 'password'
          value: registryPassword
        }
        {
          name: 'azp-token'
          value: adoToken
        }
        {
          name: 'azp-pool'
          value: adoAgentPool
        }
        {
          name: 'azp-url'
          value: adoUrl
        }
      ]
    }
    managedEnvironmentId: containerAppEnvId
    template: {
      containers: [
        {
          name: 'ado-agent'
          image: '${containerRegistry}/${containerImage}'
          resources: {
            cpu: json('1.75')
            memory: '3.5Gi'
          }
          env: [
            {
              name: 'AZP_URL'
              secretRef: 'azp-url'
            }
            {
              name: 'AZP_TOKEN'
              secretRef: 'azp-token'
            }
            {
              name: 'AZP_POOL'
              secretRef: 'azp-pool'
            }
          ]
        }
      ]
      scale: {
        maxReplicas: 3
        minReplicas: 0
        rules: [
          {
            name: 'auzre-pipelines-scalar'
            custom: {
              type: 'azure-pipelines'
              metadata: {
                poolID: '10'
                targetPipelinesQueueLength: '1'
              }
              auth: [
                {
                  secretRef: 'azp-token'
                  triggerParameter: 'personalAccessToken'
                }
                {
                  secretRef: 'azp-url'
                  triggerParameter: 'organizationURL'
                }
              ]
            }
          }
        ]
      }
    }
  }
}
