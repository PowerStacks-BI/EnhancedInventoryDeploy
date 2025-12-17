targetScope = 'resourceGroup'

@description('Name of the existing Log Analytics workspace (in this resource group).')
param workspaceName string

@description('Name of the Data Collection Rule (DCR) to create.')
param dcrName string

@description('Deployment location.')
param location string

@description('Resource ID of the Data Collection Endpoint (DCE).')
param dceResourceId string

@description('Custom table name for device inventory.')
param deviceTableName string

@description('Custom table name for app inventory.')
param appTableName string

@description('Custom table name for driver inventory.')
param driverTableName string

@description('Schema columns for device inventory stream/table.')
param deviceColumns array

@description('Schema columns for app inventory stream/table.')
param appColumns array

@description('Schema columns for driver inventory stream/table.')
param driverColumns array

@description('Optional. SERVICE PRINCIPAL OBJECT ID (not Application/Client ID) used for log ingestion. If provided, the deployment assigns DCR permissions automatically.')
param servicePrincipalObjectId string = ''

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource deviceTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: deviceTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: deviceTableName
      columns: deviceColumns
    }
  }
}

resource appTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: appTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: appTableName
      columns: appColumns
    }
  }
}

resource driverTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: driverTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: driverTableName
      columns: driverColumns
    }
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: dcrName
  location: location
  dependsOn: [
    deviceTable
    appTable
    driverTable
  ]
  properties: {
    description: 'PowerStacks Enhanced Inventory ingestion via Log Ingestion API'
    dataCollectionEndpointId: dceResourceId

    destinations: {
      logAnalytics: [
        {
          name: 'la'
          workspaceResourceId: law.id
        }
      ]
    }

    streamDeclarations: {
      'Custom-PowerStacksDeviceInventory': { columns: deviceColumns }
      'Custom-PowerStacksAppInventory':    { columns: appColumns }
      'Custom-PowerStacksDriverInventory': { columns: driverColumns }
    }

    dataFlows: [
      {
        streams: [ 'Custom-PowerStacksDeviceInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-${deviceTableName}'
      }
      {
        streams: [ 'Custom-PowerStacksAppInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-${appTableName}'
      }
      {
        streams: [ 'Custom-PowerStacksDriverInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-${driverTableName}'
      }
    ]
  }
}

var monitoringMetricsPublisherRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '3913510d-42f4-4e42-8a64-420c390055eb'
)

resource dcrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(servicePrincipalObjectId)) {
  name: guid(dcr.id, servicePrincipalObjectId, monitoringMetricsPublisherRoleDefinitionId)
  scope: dcr
  properties: {
    roleDefinitionId: monitoringMetricsPublisherRoleDefinitionId
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
  }
}

output DcrImmutableId string = dcr.properties.immutableId
