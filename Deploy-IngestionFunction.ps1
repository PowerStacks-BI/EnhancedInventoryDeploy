<#
.SYNOPSIS
    Provisions the secretless inventory ingestion Function into an existing
    PowerStacks Enhanced Inventory deployment. Validation helper only.

.DESCRIPTION
    Creates a Consumption-plan PowerShell Azure Function with a system-assigned
    managed identity, grants that identity Monitoring Metrics Publisher on your
    existing Data Collection Rule, deploys the forwarder code, and prints the
    Function URL plus key to paste into the inventory script.

    This does NOT touch the ARM template. It stands up the Function alongside your
    current deployment so you can validate the managed-identity ingestion path
    before any of the production work is built.

.PREREQUISITES
    - Azure CLI (az), signed in (az login) to the tenant and subscription that hold
      your Log Analytics workspace and DCR.
    - Rights to create resources and assign roles on the DCR (Owner, or Contributor
      plus User Access Administrator).

.PARAMETER DcrResourceId
    The full resource ID of the existing DCR, for the role assignment scope. Find it
    at: Azure portal > your DCR > JSON View (or Properties) > Resource ID.

.EXAMPLE
    .\Deploy-IngestionFunction.ps1 -SubscriptionId <sub> -ResourceGroup <rg> `
        -Location eastus -FunctionAppName ps-inv-ingest-01 -StorageAccountName psinvingest01 `
        -DceUri "https://<dce>.<region>.ingest.monitor.azure.com" `
        -DcrImmutableId "dcr-xxxxxxxxxxxxxxxx" `
        -DcrResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Insights/dataCollectionRules/<dcrName>"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$Location,
    [Parameter(Mandatory)] [string]$FunctionAppName,
    [Parameter(Mandatory)] [string]$StorageAccountName,
    [Parameter(Mandatory)] [string]$DceUri,
    [Parameter(Mandatory)] [string]$DcrImmutableId,
    [Parameter(Mandatory)] [string]$DcrResourceId
)

$ErrorActionPreference = 'Stop'

function Test-LastExit([string]$What) {
    if ($LASTEXITCODE -ne 0) { throw "Step failed: $What" }
}

$funcSource = Join-Path $PSScriptRoot 'ingestion-function'
if (-not (Test-Path $funcSource)) { throw "Function source folder not found: $funcSource" }

Write-Host "==> Setting subscription context"
az account set --subscription $SubscriptionId
Test-LastExit "set subscription"

Write-Host "==> Creating storage account $StorageAccountName"
az storage account create --name $StorageAccountName --resource-group $ResourceGroup `
    --location $Location --sku Standard_LRS --allow-blob-public-access false | Out-Null
Test-LastExit "create storage account"

Write-Host "==> Creating Function App $FunctionAppName (Consumption, PowerShell 7.4)"
az functionapp create --name $FunctionAppName --resource-group $ResourceGroup `
    --consumption-plan-location $Location --storage-account $StorageAccountName `
    --runtime powershell --runtime-version 7.4 --functions-version 4 --os-type Windows | Out-Null
Test-LastExit "create function app"

Write-Host "==> Enabling system-assigned managed identity"
$principalId = az functionapp identity assign --name $FunctionAppName --resource-group $ResourceGroup --query principalId -o tsv
Test-LastExit "assign managed identity"

Write-Host "==> Granting Monitoring Metrics Publisher on the DCR to the Function identity"
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal `
    --role "Monitoring Metrics Publisher" --scope $DcrResourceId | Out-Null
Test-LastExit "create role assignment"

Write-Host "==> Setting app settings (DceUri, DcrImmutableId)"
az functionapp config appsettings set --name $FunctionAppName --resource-group $ResourceGroup `
    --settings "DceUri=$DceUri" "DcrImmutableId=$DcrImmutableId" | Out-Null
Test-LastExit "set app settings"

Write-Host "==> Packaging and deploying the Function code"
$zipPath = Join-Path $env:TEMP 'ps-ingestion-function.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $funcSource '*') -DestinationPath $zipPath -Force
az functionapp deployment source config-zip --name $FunctionAppName --resource-group $ResourceGroup --src $zipPath | Out-Null
Test-LastExit "deploy function code"

Write-Host "==> Retrieving the host function key"
$funcKey = az functionapp keys list --name $FunctionAppName --resource-group $ResourceGroup --query "functionKeys.default" -o tsv
Test-LastExit "list function keys"

$functionUrl = "https://$FunctionAppName.azurewebsites.net/api/Ingest?code=$funcKey"

Write-Host ""
Write-Host "==================================================================="
Write-Host " Done. Paste this into Intune_Windows_Inventory.ps1:"
Write-Host ""
Write-Host "   `$FunctionUrl = `"$functionUrl`""
Write-Host ""
Write-Host " Leave LogAPIMode = LogIngestionAPI and leave the Tenant/Client/Secret"
Write-Host " fields as placeholders. Setting FunctionUrl bypasses the secret path."
Write-Host ""
Write-Host " Role propagation can take a few minutes. If the first run reports a 403"
Write-Host " from the DCR, wait a bit and run again."
Write-Host "==================================================================="
