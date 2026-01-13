# ==============================================================
#  FULL SCRIPT – Creates DCE + 3 Tables + 1 DCR (3 streams)
# =============================================================

# === 1. Variables (change only if needed) ===

# Replace with your Subscription ID
$SubscriptionId = "<Enter Your Subscripion ID>"

# Replace with your Resource Group
$ResourceGroup = "<Enter Your Resource Group>"

# Replace with your Location (e.g.: eastus)
$Location = "<Enter Your Location>"

# Replace with your Workspace name
$WorkspaceName = "<Enter Your Workspace Name>"

# Replace with your Client ID
$ClientId = "<Enter Your Client ID>"

# === 2. Login once (uncomment if not already logged in) ===
Connect-AzAccount -Subscription $SubscriptionId

# === 3. CREATE DATA COLLECTION ENDPOINT (DCE) ===
# Set DCE name
$dceName = "dce-PowerStacksInventory"

Write-Host "Creating Data Collection Endpoint: $dceName ..." -ForegroundColor Cyan

$dcePayload = @"
{
  "location": "$Location",
  "properties": {
    "description": "DCE for PowerStacksInventory multi-table ingestion"
  }
}
"@

Invoke-AzRestMethod `
  -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionEndpoints/$dceName`?api-version=2024-03-11" `
  -Method PUT `
  -Payload $dcePayload | Out-Null

# Wait a couple of seconds for propagation
Start-Sleep -Seconds 5

# === 4. MIGRATE TABLE – DeviceInventory ===
Write-Host "Migrating classic table $tableNameDevice to DCR-based..." -ForegroundColor Cyan

Invoke-AzRestMethod `
  -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$tableNameDevice/migrate?api-version=2021-12-01-preview" `
  -Method POST | Out-Null

Write-Host "Migration complete! Table $tableNameDevice is now DCR-based." -ForegroundColor Green

# === 5. MIGRATE TABLE – AppInventory ===
Write-Host "Migrating classic table $tableNameApp to DCR-based..." -ForegroundColor Cyan

Invoke-AzRestMethod `
  -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$tableNameApp/migrate?api-version=2021-12-01-preview" `
  -Method POST | Out-Null

Write-Host "Migration complete! Table $tableNameApp is now DCR-based." -ForegroundColor Green

# === 7. MIGRATE TABLE – DriverInventory ===
# Migrate the table
Write-Host "Migrating classic table $tableNameDriver to DCR-based..." -ForegroundColor Cyan

Invoke-AzRestMethod `
  -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$tableNameDriver/migrate?api-version=2021-12-01-preview" `
  -Method POST | Out-Null

Write-Host "Migration complete! Table $tableNameDriver is now DCR-based." -ForegroundColor Green

# === 8. CREATE TABLE 1 – DeviceInventory ===
# Set DeviceInventory table name
$tableNameDevice = "PowerStacksDeviceInventory_CL"

Write-Host "Creating table: $tableNameDevice ..." -ForegroundColor Cyan

$tablePayloadDevice = @"
{
  "properties": {
    "schema": {
      "name": "$tableNameDevice",
      "columns": [
        { "name": "TimeGenerated",      "type": "datetime" },
        { "name": "ComputerName_s",     "type": "string"   },
        { "name": "ManagedDeviceID_g",  "type": "string"   },
        { "name": "Microsoft365_b",     "type": "boolean"  },
        { "name": "Warranty_b",         "type": "boolean"  },
        { "name": "DeviceDetails1_s",   "type": "string"   },
        { "name": "DeviceDetails2_s",   "type": "string"   },
        { "name": "DeviceDetails3_s",   "type": "string"   },
        { "name": "DeviceDetails4_s",   "type": "string"   },
        { "name": "DeviceDetails5_s",   "type": "string"   },
        { "name": "DeviceDetails6_s",   "type": "string"   },
        { "name": "DeviceDetails7_s",   "type": "string"   },
        { "name": "DeviceDetails8_s",   "type": "string"   },
        { "name": "DeviceDetails9_s",   "type": "string"   },
        { "name": "DeviceDetails10_s",  "type": "string"   }
      ]
    }
  }
}
"@

Invoke-AzRestMethod -Path "/subscriptions/$SubscriptionId/resourcegroups/$Resourcegroup/providers/microsoft.operationalinsights/workspaces/$WorkspaceName/tables/$tableNameDevice`?api-version=2021-12-01-preview" -Method PUT -Payload $tablePayloadDevice

# === 9. CREATE TABLE 2 – AppInventory ===
# Set AppInventory table name
$tableNameApp = "PowerStacksAppInventory_CL"

Write-Host "Creating table: $tableNameApp ..." -ForegroundColor Cyan

$tablePayloadApp = @"
{
  "properties": {
    "schema": {
      "name": "$tableNameApp",
      "columns": [
        { "name": "TimeGenerated",      "type": "datetime" },
        { "name": "ComputerName_s",     "type": "string"   },
        { "name": "ManagedDeviceID_g",  "type": "string"   },
        { "name": "InstalledApps1_s",   "type": "string"   },
        { "name": "InstalledApps2_s",   "type": "string"   },
        { "name": "InstalledApps3_s",   "type": "string"   },
        { "name": "InstalledApps4_s",   "type": "string"   },
        { "name": "InstalledApps5_s",   "type": "string"   },
        { "name": "InstalledApps6_s",   "type": "string"   },
        { "name": "InstalledApps7_s",   "type": "string"   },
        { "name": "InstalledApps8_s",   "type": "string"   },
        { "name": "InstalledApps9_s",   "type": "string"   },
        { "name": "InstalledApps10_s",  "type": "string"   }
      ]
    }
  }
}
"@

Invoke-AzRestMethod -Path "/subscriptions/$SubscriptionId/resourcegroups/$Resourcegroup/providers/microsoft.operationalinsights/workspaces/$WorkspaceName/tables/$tableNameApp`?api-version=2021-12-01-preview" -Method PUT -Payload $tablePayloadApp

# === 10. CREATE TABLE 3 – DriverInventory ===
# Set DriverInventory table name
$tableNameDriver = "PowerStacksDriverInventory_CL"

Write-Host "Creating table: $tableNameDriver ..." -ForegroundColor Cyan

$tablePayloadDriver = @"
{
  "properties": {
    "schema": {
      "name": "$tableNameDriver",
      "columns": [
        { "name": "TimeGenerated",      "type": "datetime" },
        { "name": "ComputerName_s",     "type": "string"   },
        { "name": "ManagedDeviceID_g",  "type": "string"   },
        { "name": "ListedDrivers1_s",   "type": "string"   },
        { "name": "ListedDrivers2_s",   "type": "string"   },
        { "name": "ListedDrivers3_s",   "type": "string"   },
        { "name": "ListedDrivers4_s",   "type": "string"   },
        { "name": "ListedDrivers5_s",   "type": "string"   },
        { "name": "ListedDrivers6_s",   "type": "string"   },
        { "name": "ListedDrivers7_s",   "type": "string"   },
        { "name": "ListedDrivers8_s",   "type": "string"   },
        { "name": "ListedDrivers9_s",   "type": "string"   },
        { "name": "ListedDrivers10_s",  "type": "string"   }
      ]
    }
  }
}
"@

Invoke-AzRestMethod -Path "/subscriptions/$SubscriptionId/resourcegroups/$Resourcegroup/providers/microsoft.operationalinsights/workspaces/$WorkspaceName/tables/$tableNameDriver`?api-version=2021-12-01-preview" -Method PUT -Payload $tablePayloadDriver

# === 11. CREATE SINGLE DCR THAT FEEDS BOTH TABLES ===
# Set DCR name
$dcrName = "dcr-PowerStacksInventory"

Write-Host "Creating/updating DCR: $dcrName (3 streams) ..." -ForegroundColor Cyan

$dcrPayload = @"
{
  "location": "$Location",
  "properties": {
    "description": "PowerStacks device inventory → custom table via Log Ingestion API",
    "dataCollectionEndpointId": "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionEndpoints/$dceName",
    "streamDeclarations": {
      "Custom-$tableNameDevice": {
        "columns": [
          { "name": "TimeGenerated",      "type": "datetime" },
          { "name": "ComputerName_s",     "type": "string"   },
          { "name": "ManagedDeviceID_g",  "type": "string"   },
          { "name": "Microsoft365_b",     "type": "boolean"  },
          { "name": "Warranty_b",         "type": "boolean"  },
          { "name": "DeviceDetails1_s",   "type": "string"   },
          { "name": "DeviceDetails2_s",   "type": "string"   },
          { "name": "DeviceDetails3_s",   "type": "string"   },
          { "name": "DeviceDetails4_s",   "type": "string"   },
          { "name": "DeviceDetails5_s",   "type": "string"   },
          { "name": "DeviceDetails6_s",   "type": "string"   },
          { "name": "DeviceDetails7_s",   "type": "string"   },
          { "name": "DeviceDetails8_s",   "type": "string"   },
          { "name": "DeviceDetails9_s",   "type": "string"   },
          { "name": "DeviceDetails10_s",  "type": "string"   }
        ]
      },
      "Custom-$tableNameApp": {
        "columns": [
          { "name": "TimeGenerated",      "type": "datetime" },
          { "name": "ComputerName_s",     "type": "string"   },
          { "name": "ManagedDeviceID_g",  "type": "string"   },
          { "name": "InstalledApps1_s",   "type": "string"   },
          { "name": "InstalledApps2_s",   "type": "string"   },
          { "name": "InstalledApps3_s",   "type": "string"   },
          { "name": "InstalledApps4_s",   "type": "string"   },
          { "name": "InstalledApps5_s",   "type": "string"   },
          { "name": "InstalledApps6_s",   "type": "string"   },
          { "name": "InstalledApps7_s",   "type": "string"   },
          { "name": "InstalledApps8_s",   "type": "string"   },
          { "name": "InstalledApps9_s",   "type": "string"   },
          { "name": "InstalledApps10_s",  "type": "string"   }
        ]
      },
      "Custom-$tableNameDriver": {
        "columns": [
          { "name": "TimeGenerated",      "type": "datetime" },
          { "name": "ComputerName_s",     "type": "string"   },
          { "name": "ManagedDeviceID_g",  "type": "string"   },
          { "name": "ListedDrivers1_s",   "type": "string"   },
          { "name": "ListedDrivers2_s",   "type": "string"   },
          { "name": "ListedDrivers3_s",   "type": "string"   },
          { "name": "ListedDrivers4_s",   "type": "string"   },
          { "name": "ListedDrivers5_s",   "type": "string"   },
          { "name": "ListedDrivers6_s",   "type": "string"   },
          { "name": "ListedDrivers7_s",   "type": "string"   },
          { "name": "ListedDrivers8_s",   "type": "string"   },
          { "name": "ListedDrivers9_s",   "type": "string"   },
          { "name": "ListedDrivers10_s",  "type": "string"   }
        ]
      }
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName",
          "name": "la-destination"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": [ "Custom-$tableNameDevice" ],
        "destinations": [ "la-destination" ],
        "transformKql": "source | extend TimeGenerated = now()",
        "outputStream": "Custom-$tableNameDevice"
      },
      {
        "streams": [ "Custom-$tableNameApp" ],
        "destinations": [ "la-destination" ],
        "transformKql": "source | extend TimeGenerated = now()",
        "outputStream": "Custom-$tableNameApp"
      },
      {
        "streams": [ "Custom-$tableNameDriver" ],
        "destinations": [ "la-destination" ],
        "transformKql": "source | extend TimeGenerated = now()",
        "outputStream": "Custom-$tableNameDriver"
      }
    ]
  }
}
"@

# === 12. CREATE DCR THAT FEEDS THE THREE TABLES ===
Invoke-AzRestMethod `
  -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$dcrName`?api-version=2024-03-11" `
  -Method PUT `
  -Payload $dcrPayload

# === 13. ASSIGN ROLE TO DCR ===
Write-Host "Assigning 'Monitoring Metrics Publisher' role on DCR..." -ForegroundColor Cyan

New-AzRoleAssignment `
    -ObjectId (Get-AzADServicePrincipal -ApplicationId $ClientId).Id `
    -RoleDefinitionName "Monitoring Metrics Publisher" `
    -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$dcrName" `
    -ErrorAction SilentlyContinue | Out-Null

Write-Host "Role assignment completed!" -ForegroundColor Green

# === 14. GET DCE LOG INGESTION URI ===
$dce = (Invoke-AzRestMethod -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionEndpoints/$dceName`?api-version=2024-03-11" -Method GET).Content | ConvertFrom-Json
Write-Host "DCE Ingestion URL base: $($dce.properties.logsIngestion.endpoint)" -ForegroundColor Yellow

# === 15. GET DCR IMMUTABLEID ===
$dcr = (Invoke-AzRestMethod -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/dataCollectionRules/$dcrName`?api-version=2024-03-11" -Method GET).Content | ConvertFrom-Json
$immutableId = $dcr.properties.immutableId
Write-Host "DCR ImmutableId: $immutableId" -ForegroundColor Yellow
