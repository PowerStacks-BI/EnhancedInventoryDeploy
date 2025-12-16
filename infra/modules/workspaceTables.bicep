targetScope = 'resourceGroup'

@description('Name of the existing Log Analytics workspace in this resource group.')
param workspaceName string

@description('Table name to create/update.')
param tableName string

@description('Column schema for the table.')
param columns array

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource table 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: tableName
  properties: {
    plan: 'Analytics'
    schema: {
      name: tableName
      columns: columns
    }
  }
}

output tableId string = table.id
