targetScope = 'resourceGroup'

@allowed([
  'CreateNew'
  'UseExisting'
])
param workspaceMode string = 'CreateNew'

@description('Location for resources in this resource group.')
param location string = resourceGroup().location

// Scenario 1
@description('New Log Analytics workspace name (used only when workspaceMode=CreateNew).')
param newWorkspaceName string = 'law-PowerStacksEnhancedInventory'

// Scenario 2
@description('Existing workspace subscription id (used only when workspaceMode=UseExisting).')
param existingWorkspaceSubscriptionId string = subscription().subscriptionId

@description('Existing workspace resource group name (used only when workspaceMode=UseExisting).')
param existingWorkspaceResourceGroup string = ''

@description('Existing workspace name (used only when workspaceMode=UseExisting).')
param existingWorkspaceName string = ''

@description('Data Collection Endpoint name.')
param dceName string = 'dce-PowerStacksInventory'

@description('Data Collection Rule name.')
param dcrName string = 'dcr-PowerStacksInventory'

@description('OPTIONAL: Service principal OBJECT ID for the ingestion app. If blank, RBAC assignment is skipped.')
param ingestionSpObjectId string = ''

// ---------------------------
// Workspace (new or existing)
// ---------------------------
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

var workspaceResourceId = workspaceMode == 'CreateNew' ? lawNew.id : lawExisting.id
var workspaceNameEffective = workspaceMode == 'CreateNew' ? lawNew.name : lawExisting.name

// ---------------------------
// Tables (3)
// ---------------------------

var deviceTableName = 'PowerStacksDeviceInventory_CL'
var appTableName    = 'PowerStacksAppInventory_CL'
var driverTableName = 'PowerStacksDriverInventory_CL'

// Create tables under NEW workspace
resource deviceTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  name: '${workspaceNameEffective}/${deviceTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: deviceTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'Microsoft365_b', type: 'boolean' }
        { name: 'Warranty_b', type: 'boolean' }
        { name: 'DeviceDetails1_s', type: 'string' }
        { name: 'DeviceDetails2_s', type: 'string' }
        { name: 'DeviceDetails3_s', type: 'string' }
        { name: 'DeviceDetails4_s', type: 'string' }
        { name: 'DeviceDetails5_s', type: 'string' }
        { name: 'DeviceDetails6_s', type: 'string' }
        { name: 'DeviceDetails7_s', type: 'string' }
        { name: 'DeviceDetails8_s', type: 'string' }
        { name: 'DeviceDetails9_s', type: 'string' }
        { name: 'DeviceDetails10_s', type: 'string' }
      ]
    }
  }
  dependsOn: [lawNew]
}

resource appTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  name: '${workspaceNameEffective}/${appTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: appTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'InstalledApps1_s', type: 'string' }
        { name: 'InstalledApps2_s', type: 'string' }
        { name: 'InstalledApps3_s', type: 'string' }
        { name: 'InstalledApps4_s', type: 'string' }
        { name: 'InstalledApps5_s', type: 'string' }
        { name: 'InstalledApps6_s', type: 'string' }
        { name: 'InstalledApps7_s', type: 'string' }
        { name: 'InstalledApps8_s', type: 'string' }
        { name: 'InstalledApps9_s', type: 'string' }
        { name: 'InstalledApps10_s', type: 'string' }
      ]
    }
  }
  dependsOn: [lawNew]
}

resource driverTableNew 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'CreateNew') {
  name: '${workspaceNameEffective}/${driverTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: driverTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'ListedDrivers1_s', type: 'string' }
        { name: 'ListedDrivers2_s', type: 'string' }
        { name: 'ListedDrivers3_s', type: 'string' }
        { name: 'ListedDrivers4_s', type: 'string' }
        { name: 'ListedDrivers5_s', type: 'string' }
        { name: 'ListedDrivers6_s', type: 'string' }
        { name: 'ListedDrivers7_s', type: 'string' }
        { name: 'ListedDrivers8_s', type: 'string' }
        { name: 'ListedDrivers9_s', type: 'string' }
        { name: 'ListedDrivers10_s', type: 'string' }
      ]
    }
  }
  dependsOn: [lawNew]
}

// Create tables under EXISTING workspace
resource deviceTableExisting 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'UseExisting') {
  name: '${workspaceNameEffective}/${deviceTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: deviceTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'Microsoft365_b', type: 'boolean' }
        { name: 'Warranty_b', type: 'boolean' }
        { name: 'DeviceDetails1_s', type: 'string' }
        { name: 'DeviceDetails2_s', type: 'string' }
        { name: 'DeviceDetails3_s', type: 'string' }
        { name: 'DeviceDetails4_s', type: 'string' }
        { name: 'DeviceDetails5_s', type: 'string' }
        { name: 'DeviceDetails6_s', type: 'string' }
        { name: 'DeviceDetails7_s', type: 'string' }
        { name: 'DeviceDetails8_s', type: 'string' }
        { name: 'DeviceDetails9_s', type: 'string' }
        { name: 'DeviceDetails10_s', type: 'string' }
      ]
    }
  }
}

resource appTableExisting 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'UseExisting') {
  name: '${workspaceNameEffective}/${appTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: appTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'InstalledApps1_s', type: 'string' }
        { name: 'InstalledApps2_s', type: 'string' }
        { name: 'InstalledApps3_s', type: 'string' }
        { name: 'InstalledApps4_s', type: 'string' }
        { name: 'InstalledApps5_s', type: 'string' }
        { name: 'InstalledApps6_s', type: 'string' }
        { name: 'InstalledApps7_s', type: 'string' }
        { name: 'InstalledApps8_s', type: 'string' }
        { name: 'InstalledApps9_s', type: 'string' }
        { name: 'InstalledApps10_s', type: 'string' }
      ]
    }
  }
}

resource driverTableExisting 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (workspaceMode == 'UseExisting') {
  name: '${workspaceNameEffective}/${driverTableName}'
  properties: {
    plan: 'Analytics'
    schema: {
      name: driverTableName
      columns: [
        { name: 'TimeGenerated', type: 'datetime' }
        { name: 'ComputerName_s', type: 'string' }
        { name: 'ManagedDeviceID_g', type: 'string' }
        { name: 'ListedDrivers1_s', type: 'string' }
        { name: 'ListedDrivers2_s', type: 'string' }
        { name: 'ListedDrivers3_s', type: 'string' }
        { name: 'ListedDrivers4_s', type: 'string' }
        { name: 'ListedDrivers5_s', type: 'string' }
        { name: 'ListedDrivers6_s', type: 'string' }
        { name: 'ListedDrivers7_s', type: 'string' }
        { name: 'ListedDrivers8_s', type: 'string' }
        { name: 'ListedDrivers9_s', type: 'string' }
        { name: 'ListedDrivers10_s', type: 'string' }
      ]
    }
  }
}

// ---------------------------
// DCE
// ---------------------------
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2024-03-11' = {
  name: dceName
  location: location
  properties: {
    description: 'DCE for PowerStacks inventory ingestion'
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// ---------------------------
// DCR (3 streams -> 3 tables)
// ---------------------------
resource dcr 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: dcrName
  location: location
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

    streamDeclarations: {
      'Custom-PowerStacksDeviceInventory': {
        columns: [
          { name: 'TimeGenerated', type: 'datetime' }
          { name: 'ComputerName_s', type: 'string' }
          { name: 'ManagedDeviceID_g', type: 'string' }
          { name: 'Microsoft365_b', type: 'boolean' }
          { name: 'Warranty_b', type: 'boolean' }
          { name: 'DeviceDetails1_s', type: 'string' }
          { name: 'DeviceDetails2_s', type: 'string' }
          { name: 'DeviceDetails3_s', type: 'string' }
          { name: 'DeviceDetails4_s', type: 'string' }
          { name: 'DeviceDetails5_s', type: 'string' }
          { name: 'DeviceDetails6_s', type: 'string' }
          { name: 'DeviceDetails7_s', type: 'string' }
          { name: 'DeviceDetails8_s', type: 'string' }
          { name: 'DeviceDetails9_s', type: 'string' }
          { name: 'DeviceDetails10_s', type: 'string' }
        ]
      }
      'Custom-PowerStacksAppInventory': {
        columns: [
          { name: 'TimeGenerated', type: 'datetime' }
          { name: 'ComputerName_s', type: 'string' }
          { name: 'ManagedDeviceID_g', type: 'string' }
          { name: 'InstalledApps1_s', type: 'string' }
          { name: 'InstalledApps2_s', type: 'string' }
          { name: 'InstalledApps3_s', type: 'string' }
          { name: 'InstalledApps4_s', type: 'string' }
          { name: 'InstalledApps5_s', type: 'string' }
          { name: 'InstalledApps6_s', type: 'string' }
          { name: 'InstalledApps7_s', type: 'string' }
          { name: 'InstalledApps8_s', type: 'string' }
          { name: 'InstalledApps9_s', type: 'string' }
          { name: 'InstalledApps10_s', type: 'string' }
        ]
      }
      'Custom-PowerStacksDriverInventory': {
        columns: [
          { name: 'TimeGenerated', type: 'datetime' }
          { name: 'ComputerName_s', type: 'string' }
          { name: 'ManagedDeviceID_g', type: 'string' }
          { name: 'ListedDrivers1_s', type: 'string' }
          { name: 'ListedDrivers2_s', type: 'string' }
          { name: 'ListedDrivers3_s', type: 'string' }
          { name: 'ListedDrivers4_s', type: 'string' }
          { name: 'ListedDrivers5_s', type: 'string' }
          { name: 'ListedDrivers6_s', type: 'string' }
          { name: 'ListedDrivers7_s', type: 'string' }
          { name: 'ListedDrivers8_s', type: 'string' }
          { name: 'ListedDrivers9_s', type: 'string' }
          { name: 'ListedDrivers10_s', type: 'string' }
        ]
      }
    }

    dataFlows: [
      {
        streams: [ 'Custom-PowerStacksDeviceInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-PowerStacksDeviceInventory_CL'
      }
      {
        streams: [ 'Custom-PowerStacksAppInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-PowerStacksAppInventory_CL'
      }
      {
        streams: [ 'Custom-PowerStacksDriverInventory' ]
        destinations: [ 'la' ]
        outputStream: 'Custom-PowerStacksDriverInventory_CL'
      }
    ]
  }
}

// ---------------------------
// RBAC on DCR (optional)
// ---------------------------
var monitoringMetricsPublisherRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '3913510d-42f4-4e42-8a64-420c390055eb'
)

resource dcrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(ingestionSpObjectId)) {
  name: guid(dcr.id, ingestionSpObjectId, monitoringMetricsPublisherRoleDefinitionId)
  scope: dcr
  properties: {
    roleDefinitionId: monitoringMetricsPublisherRoleDefinitionId
    principalId: ingestionSpObjectId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------
// Outputs for endpoint scripts
// ---------------------------
output DceURI string = dce.properties.logsIngestion.endpoint
output DcrImmutableId string = dcr.properties.immutableId
output WorkspaceResourceId string = workspaceResourceId
output WorkspaceName string = workspaceNameEffective
output RoleAssignmentSkipped bool = empty(ingestionSpObjectId)
