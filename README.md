# EAUG CONTAINER APPS

This repository includes the code for my Container Apps demo at Edinburgh Azure User Group meetup #23 (27th September).

The talk covers deploying Container Apps using bicep, as well as creating a self-hosted Azure DevOps build agent that can be autoscaled based on the queue length of the given agent pool.

## Running locally

:warning: To run locally, ensure you have the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed, and you are logged into Azure via the [az login](https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login) command.

:warning: This assumes you have an [Azure DevOps](https://azure.microsoft.com/en-us/products/devops/) organization. This will show you through creating an Agent Pool however.

### Steps

1. Start by creating a resource group for all resources to reside in:

   ```cmd
   az group create -n <RG_NAME> -l <LOCATION>
   ```

2. Create the container registry (ensure you are in `/infrastructure` directory), providing any parameters required:

   ```cmd
   az deployment group create -g <RG_NAME> --template-file .\container-registry.bicep
   ```

3. Create the log analytics workspace:

   ```cmd
   az deployment group create -g <RG_NAME> --template-file .\log-analytics.bicep
   ```

4. Create the Container Apps Environment:

   Retrieve `logAnalyticsCustomerId` and `logAnalyticsPrimaryKey` from previous output and add to `container-app-env-parameters.json`

   ```cmd
   az deployment group create -g <RG_NAME> --template-file .\container-app-env.bicep --parameters container-app-env-parameters.json
   ```

5. Build and deploy Azure DevOps self-hosted docker agent to Container registry:

   ```cmd
       cd ../ado-agent
   ```

   Build image:

   ```cmd
      docker build -t ado-agent:latest .
   ```

   Tag/Push to ACR:

   ```cmd
      docker tag ado-agent:latest <ACR_LOGIN_SERVER>/ado-agent:latest
      az acr login -n <ACR_NAME>
      docker push <ACR_LOGIN_SERVER>/ado-agent:latest
   ```

6. Create Azure DevOps Agent Pool:

   - Navigate to Organization Settings > Agent pools > Add pool in Azure DevOps
   - Select `self-hosted` for Pool type
   - Provide a name for the Agent pool and click Create
   - Obtain the `poolId` by selecting the Pool and copying the `poolId` found in the URL, it should look similar to `https://dev.azure.com/<ORG_NAME>/_settings/agentpools?poolId=<POOL_ID>&view=jobs`

7. Create Personal Access Token:

   - A Personal Access token is required to read/create new agents dynamically based on autoscale triggers. The following [link](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) demonstrates how to create one
   - For scope, select **Agent Pools Read & manage**. This may require you to click _show all scopes_ at the bottom of the current panel.

8. Create the Self-Hosted Agent Container App:

   Retrieve `containerAppEnvId`, `containerRegistry` and `registryUsername` from previous steps and add to `ado-agent-container-app-parameters.json`, as well as changing `name`, `adoUrl`, `adoAgentPool` as appropriate

   ```cmd
   az deployment group create -g <RG_NAME> --template-file .\ado-agent-container-app.bicep --parameters ado-agent-container-app-parameters.json
   ```

   When prompted, enter `registryPassword`, which can be found from the Container Registry in Azure, and `adoToken`, which is the Personal Access Token created in the previous step.
