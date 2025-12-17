<#

.SYNOPSIS

&nbsp; Retrieves and displays the full configuration of an Azure Monitor Data Collection Rule (DCR).



.DESCRIPTION

&nbsp; This script connects to Azure and retrieves the specified Data Collection Rule (DCR) as raw JSON

&nbsp; using the Azure Resource Manager REST API. It is intended for validation and troubleshooting of

&nbsp; Log Ingestion API deployments.



&nbsp; The output includes all DCR properties, including:

&nbsp;   - streamDeclarations

&nbsp;   - dataFlows

&nbsp;   - destinations

&nbsp;   - Data Collection Endpoint (DCE) association



&nbsp; This script is read-only and makes no changes to Azure resources.



.USE CASES

&nbsp; - Verify that a DCR was created successfully by an ARM/Bicep deployment

&nbsp; - Confirm stream names and column definitions used by Log Ingestion API scripts

&nbsp; - Troubleshoot scenarios where data is not appearing in Log Analytics

&nbsp; - Provide full DCR configuration to support for analysis



.REQUIREMENTS

&nbsp; - Windows PowerShell 5.1 or PowerShell 7+

&nbsp; - Az PowerShell modules (Az.Accounts, Az.Resources)

&nbsp; - Azure permissions to read Data Collection Rules in the target subscription



.NOTES

&nbsp; Author: PowerStacks

&nbsp; Product: PowerStacks Enhanced Inventory

&nbsp; API Version: Microsoft.Insights/dataCollectionRules (2024-03-11)



&nbsp; This script uses Invoke-AzRestMethod to avoid cmdlet version limitations and ensure

&nbsp; compatibility across PowerShell versions.



.DISCLAIMER

&nbsp; This script is provided "as-is" without warranty of any kind. It performs read-only

&nbsp; operations and does not modify Azure resources.

\#>



\# Prompt for required values

if (-not $subscriptionId) {

&nbsp;   $subscriptionId = Read-Host "Enter your Azure Subscription ID"

}

if (-not $resourceGroup) {

&nbsp;   $resourceGroup = Read-Host "Enter the Resource Group name containing the DCR"

}

if (-not $dcrName) {

&nbsp;   $dcrName = Read-Host "Enter the Data Collection Rule (DCR) name"

}



\# Connect to Azure

Connect-AzAccount -Subscription $subscriptionId | Out-Null



\# Retrieve the DCR as raw JSON

$raw = (Invoke-AzRestMethod `

&nbsp;   -Path "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Insights/dataCollectionRules/$dcrName?api-version=2024-03-11" `

&nbsp;   -Method GET

).Content



\# Display full DCR (PowerShell 5.1 compatible)

$raw | ConvertFrom-Json | ConvertTo-Json -Depth 50



