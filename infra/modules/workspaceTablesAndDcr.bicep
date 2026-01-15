targetScope = 'resourceGroup'

param workspaceName string
param dcrName string
param location string
param dceResourceId string

param deviceTableName string
param appTableName string
param driverTableName string

param deviceColumns array
param appColumns array
param driverColumns array

// NOTE:
// RBAC for log ingestion is intentionally handled in post-deploy onboarding.
// This avoids confusion between Application (client) ID vs service principal object ID.

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

output DcrImmutableId string = dcr.properties.immutableId
