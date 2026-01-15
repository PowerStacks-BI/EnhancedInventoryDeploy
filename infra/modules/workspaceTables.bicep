targetScope = 'resourceGroup'

// ==================================================
// Parameters
// ==================================================

@description('Name of the Log Analytics workspace where custom tables will be created/updated.')
param workspaceName string

@description('Custom table name for device inventory (for example, PowerStacksDeviceInventory_CL).')
param deviceTableName string

@description('Custom table name for app inventory (for example, PowerStacksAppInventory_CL).')
param appTableName string

@description('Custom table name for driver inventory (for example, PowerStacksDriverInventory_CL).')
param driverTableName string

@description('Column schema for the device inventory table.')
param deviceColumns array

@description('Column schema for the app inventory table.')
param appColumns array

@description('Column schema for the driver inventory table.')
param driverColumns array

// ==================================================
// Existing workspace (in this module scope resource group)
// ==================================================

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// ==================================================
// Tables
// ==================================================

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

output DeviceTableName string = deviceTableName
output AppTableName string = appTableName
output DriverTableName string = driverTableName
