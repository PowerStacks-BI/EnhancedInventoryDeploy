targetScope = 'resourceGroup'

// ==================================================
// Parameters
// ==================================================

@allowed([
  'CreateNew'
  'UseExisting'
])
@description('Choose CreateNew to create a new workspace, or UseExisting to use an existing Log Analytics workspace.')
param workspaceMode string = 'CreateNew'

@description('Azure region for resources created in this deployment resource group.')
param location string = resourceGroup().location

@description('Name for the Data Collection Endpoint (DCE).')
param dceName string = 'dce-PowerStacksInventory'

@description('Name for the Data Collection Rule (DCR).')
param dcrName string = 'dcr-PowerStacksInventory'

// New workspace settings
@description('Name of the new Log Analytics workspace. Used only when WorkspaceMode is CreateNew.')
param newWorkspaceName string = 'law-PowerStacksInventory'

// Existing workspace settings
@description('Subscription ID of the existing Log Analytics workspace. Required only when WorkspaceMode is UseExisting.')
param existingWorkspaceSubscriptionId string = subscription().subscriptionId

@description('Resource group name of the existing Log Analytics workspace. Required only when WorkspaceMode is UseExisting.')
param existingWorkspaceResourceGroup string = ''

@description('Name of the existing Log Analytics workspace. Required only when WorkspaceMode is UseExisting.')
param existingWorkspaceName string = ''

// Table names
@description('Custom table name for device inventory.')
param deviceTableName string = 'PowerStacksDeviceInventory_CL'

@description('Custom table name for app inventory.')
param appTableName string = 'PowerStacksAppInventory_CL'

@description('Custom table name for driver inventory.')
param driverTableName string = 'PowerStacksDriverInventory_CL'

// Column schemas
@description('Column schema for the device inventory table.')
param deviceColumns array

@description('Column schema for the app inventory table.')
param appColumns array

@description('Column schema for the driver inventory table.')
param driverColumns array

// ==================================================
// Workspace (new or existing)
// ==================================================

resource lawNew 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (workspaceMode == 'CreateNew') {
  name: newWorkspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource existingRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (workspaceMode == 'UseExisting') {
  name: existingWorkspaceResourceGroup
  scope: subscription(existingWorkspaceSubscriptionId)
}

resource lawExisting 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (workspaceMode == 'UseExisting') {
  name: existingWorkspaceName
  scope: existingRg
}

var workspaceResourceId    = workspaceMode == 'CreateNew' ? lawNew.id : lawExisting.id
var workspaceNameEffective = workspaceMode == 'CreateNew' ? lawNew.name : lawExisting.name

// ==================================================
// Tables
//   - CreateNew: create tables directly (same RG as the new workspace)
//   - UseExisting: create tables via module scoped to the workspace RG
// ==================================================

resource deviceTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  parent: lawNew
  name: deviceTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: deviceTableName
      columns: deviceColumns
    }
  }
}

resource appTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  parent: lawNew
  name: appTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: appTableName
      columns: appColumns
    }
  }
}

resource driverTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  parent: lawNew
  name: driverTableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: driverTableName
      columns: driverColumns
    }
  }
}

module existingWorkspaceTables 'modules/workspaceTables.bicep' = if (workspaceMode == 'UseExisting') {
  name: 'existingWorkspaceTables'
  scope: existingRg
  params: {
    workspaceName: existingWorkspaceName
    deviceTableName: deviceTableName
    appTableName: appTableName
    driverTableName: driverTableName
    deviceColumns: deviceColumns
    appColumns: appColumns
    driverColumns: driverColumns
  }
}

// ==================================================
// DCE (always in deployment resource group)
// ==================================================

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2024-03-11' = {
  name: dceName
  location: location
  properties: {
    description: 'PowerStacks Enhanced Inventory ingestion endpoint'
  }
}

// ==================================================
// DCR (always in deployment resource group)
// ==================================================

resource dcr 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: dcrName
  location: location

  dependsOn: concat(
    [dce],
    workspaceMode == 'CreateNew'
      ? [deviceTableNew, appTableNew, driverTableNew]
      : [existingWorkspaceTables]
  )

  properties: {
    description: 'PowerStacks Enhanced Inventory ingestion via Log Ingestion API'
    dataCollectionEndpointId: dce.id

    destinations: {
      logAnalytics: [
        {
          name: 'la'
          workspaceResourceId: workspaceResourceId
        }
      ]
    }

    // Stream declarations are NOT table names.
    // Output streams map to Custom-<TableName>, where <TableName> includes _CL.
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

// ==================================================
// Outputs
// ==================================================

output DceURI string = dce.properties.logsIngestion.endpoint
output DceResourceId string = dce.id

output DcrImmutableId string = dcr.properties.immutableId
output DcrResourceId string = dcr.id

output WorkspaceResourceId string = workspaceResourceId
output WorkspaceName string = workspaceNameEffective
