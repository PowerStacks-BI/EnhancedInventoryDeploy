<#
.SYNOPSIS
  Retrieves and displays the full configuration of an Azure Monitor Data Collection Rule (DCR).

.DESCRIPTION
  This script connects to Azure and retrieves the specified Data Collection Rule (DCR) as raw JSON
  using the Azure Resource Manager REST API. It is intended for validation and troubleshooting of
  Log Ingestion API deployments.

  The output includes all DCR properties, including:
    - streamDeclarations
    - dataFlows
    - destinations
    - Data Collection Endpoint (DCE) association

  This script is read-only and makes no changes to Azure resources.

.NOTES
  Author: PowerStacks
  Product: PowerStacks Enhanced Inventory
  API Version: Microsoft.Insights/dataCollectionRules (2024-03-11)

  Use cases:
    - Verify that a DCR was created successfully by an ARM/Bicep deployment
    - Confirm stream names and column definitions used by Log Ingestion API scripts
    - Troubleshoot scenarios where data is not appearing in Log Analytics
    - Provide full DCR configuration to support for analysis

  Requirements:
    - Windows PowerShell 5.1 or PowerShell 7+
    - Az PowerShell modules (Az.Accounts, Az.Resources)
    - Azure permissions to read Data Collection Rules in the target subscription

  This script uses Invoke-AzRestMethod to avoid cmdlet version limitations and ensure
  compatibility across PowerShell versions.

  This script is provided "as-is" without warranty of any kind. It performs read-only
  operations and does not modify Azure resources.
#>

# Ensure the Az.Accounts module (provides Connect-AzAccount and Invoke-AzRestMethod) is present.
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Az.Accounts not found. Installing it for the current user..."
    # Windows PowerShell 5.1 defaults to TLS 1.0/1.1, which the PowerShell Gallery now rejects.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    try {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        }
        Install-Module -Name Az.Accounts -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    catch {
        Write-Error "Could not install Az.Accounts automatically: $($_.Exception.Message)"
        Write-Host  "Install it manually, then re-run: Install-Module Az.Accounts -Scope CurrentUser"
        return
    }
}
Import-Module Az.Accounts -ErrorAction Stop

# Prompt for required values
if (-not $subscriptionId) {
    $subscriptionId = Read-Host "Enter your Azure Subscription ID"
}

if (-not $resourceGroup) {
    $resourceGroup = Read-Host "Enter the Resource Group name containing the DCR"
}

if (-not $dcrName) {
    $dcrName = Read-Host "Enter the Data Collection Rule (DCR) name"
}

# Connect to Azure
Connect-AzAccount -Subscription $subscriptionId | Out-Null

# Retrieve the DCR as raw JSON
$raw = (Invoke-AzRestMethod `
        -Path "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Insights/dataCollectionRules/$dcrName?api-version=2024-03-11" `
        -Method GET).Content

# Display full DCR (PowerShell 5.1 compatible)
$raw | ConvertFrom-Json | ConvertTo-Json -Depth 50
