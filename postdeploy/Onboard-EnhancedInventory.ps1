<#
.SYNOPSIS
  Post-deploy onboarding for PowerStacks Enhanced Inventory (Log Ingestion API).

.DESCRIPTION
  This script needs to be ran AFTER the "Deploy to Azure" from the EnhancedInventoryDeploy repo has run succesfully.

  It will:
    - Detect the latest successful deployment in the specified resource group (or use -DeploymentName)
    - Read deployment outputs (DceURI, DcrImmutableId, WorkspaceName, WorkspaceResourceId)
    - Optionally create an Entra app registration + client secret (recommended)
    - Optionally assign "Monitoring Metrics Publisher" on the deployed DCR

  It prints the values customers need to paste into the Windows/Mac inventory scripts.

.NOTES
  - Requires Az PowerShell modules.
  - RBAC assignment requires the signed-in user to have permissions to create role assignments at the DCR scope.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $SubscriptionId,

  [Parameter(Mandatory)]
  [string] $ResourceGroupName,

  [Parameter()]
  [string] $DeploymentName,

  [Parameter()]
  [string] $Location,

  [Parameter()]
  [switch] $CreateAppRegistration,

  [Parameter()]
  [switch] $AssignRbac,

  # If the customer already created an app registration, they can pass these in
  [Parameter()]
  [string] $TenantId,

  [Parameter()]
  [string] $ClientId,

  [Parameter()]
  [string] $ClientSecret
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string] $Message)  { Write-Host $Message -ForegroundColor Cyan }
function Write-Ok([string] $Message)    { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string] $Message)  { Write-Host $Message -ForegroundColor Yellow }
function Write-Fail([string] $Message)  { Write-Host $Message -ForegroundColor Red }

function Get-LatestSuccessfulDeploymentName {
  param(
    [Parameter(Mandatory)] [string] $RgName
  )

  $deployments = Get-AzResourceGroupDeployment -ResourceGroupName $RgName -ErrorAction Stop |
    Where-Object { $_.ProvisioningState -eq 'Succeeded' } |
    Sort-Object Timestamp -Descending

  if (-not $deployments) {
    throw "No successful deployments were found in resource group '$RgName'."
  }

  return $deployments[0].DeploymentName
}

function Get-DeploymentOutputs {
  param(
    [Parameter(Mandatory)] [string] $RgName,
    [Parameter(Mandatory)] [string] $DepName
  )

  $dep = Get-AzResourceGroupDeployment -ResourceGroupName $RgName -Name $DepName -ErrorAction Stop

  if (-not $dep -or -not $dep.Outputs) {
    throw "Deployment '$DepName' in RG '$RgName' has no outputs."
  }

  # ARM outputs are commonly a Hashtable: @{ key = @{ type='String'; value='...' } }
  # Normalize to a simple PSCustomObject with direct properties.
  $flat = [ordered]@{}

  if ($dep.Outputs -is [hashtable]) {
    foreach ($k in $dep.Outputs.Keys) {
      $flat[$k] = $dep.Outputs[$k].Value
    }
  } else {
    # Sometimes Az returns a PSCustomObject with note properties
    foreach ($p in $dep.Outputs.PSObject.Properties) {
      $flat[$p.Name] = $p.Value.value
    }
  }

  return [pscustomobject]$flat
}


function Ensure-AzContext {
  param(
    [Parameter(Mandatory)] [string] $SubId
  )

  Write-Info "Signing in to Azure..."
  Connect-AzAccount -ErrorAction Stop | Out-Null

  Write-Info "Setting context to subscription $SubId ..."
  Set-AzContext -SubscriptionId $SubId -ErrorAction Stop | Out-Null
}

function New-IngestionAppRegistration {
  param(
    [Parameter(Mandatory)] [string] $DisplayName
  )

  # NOTE: This creates an Entra application + service principal and generates a client secret.
  # Using Az.Resources cmdlets keeps dependencies simple for customers already using Az.
  Write-Info "Creating Entra application: $DisplayName"

  $app = New-AzADApplication -DisplayName $DisplayName -ErrorAction Stop
  Start-Sleep -Seconds 2

  Write-Info "Creating service principal..."
  $sp = New-AzADServicePrincipal -ApplicationId $app.AppId -ErrorAction Stop
  Start-Sleep -Seconds 2

  Write-Info "Creating client secret..."
  $secret = New-AzADAppCredential -ObjectId $app.Id -EndDate (Get-Date).AddYears(2) -ErrorAction Stop

  $tenant = (Get-AzContext).Tenant.Id

  return [ordered]@{
    TenantId     = $tenant
    ClientId     = $app.AppId
    ClientSecret = $secret.SecretText
    ServicePrincipalObjectId = $sp.Id
  }
}

function Set-DcrRoleAssignment {
  param(
    [Parameter(Mandatory)] [string] $DcrResourceId,
    [Parameter(Mandatory)] [string] $ClientId
  )

  Write-Info "Resolving service principal from ClientId..."
  $sp = Get-AzADServicePrincipal -ApplicationId $ClientId -ErrorAction Stop
  if (-not $sp -or -not $sp.Id) {
    throw "Unable to resolve service principal for ClientId '$ClientId'. Ensure the service principal exists in this tenant."
  }

  Write-Info "Assigning 'Monitoring Metrics Publisher' on DCR..."
  New-AzRoleAssignment `
    -ObjectId $sp.Id `
    -RoleDefinitionName "Monitoring Metrics Publisher" `
    -Scope $DcrResourceId `
    -ErrorAction Stop | Out-Null

  Write-Ok "RBAC assignment completed."
}

# ---------------------------
# Main
# ---------------------------

Ensure-AzContext -SubId $SubscriptionId

if (-not $DeploymentName) {
  $DeploymentName = Get-LatestSuccessfulDeploymentName -RgName $ResourceGroupName
  Write-Info "Using latest successful deployment: $DeploymentName"
} else {
  Write-Info "Using specified deployment: $DeploymentName"
}

$outputs = Get-DeploymentOutputs -RgName $ResourceGroupName -DepName $DeploymentName

# DCR resource ID is deterministic based on RG + name in main.bicep (dcrName param default).
# If you later output DcrResourceId directly, switch to using the output instead.
$dcrNameDefault = 'dcr-PowerStacksInventory'
$dcrResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Insights/dataCollectionRules/$dcrNameDefault"

Write-Ok "Deployment outputs loaded."
Write-Host ("  Workspace: {0}" -f $outputs.WorkspaceName)
Write-Host ("  DCE URI:    {0}" -f $outputs.DceURI)
Write-Host ("  DCR ID:     {0}" -f $outputs.DcrImmutableId)

# Create App Registration (optional)
if ($CreateAppRegistration) {
  $appInfo = New-IngestionAppRegistration -DisplayName "PowerStacks Enhanced Inventory Ingestion"
  $TenantId = $appInfo.TenantId
  $ClientId = $appInfo.ClientId
  $ClientSecret = $appInfo.ClientSecret

  Write-Ok "App registration created."
  Write-Host ("  TenantId:  {0}" -f $TenantId)
  Write-Host ("  ClientId:  {0}" -f $ClientId)
}

# RBAC (optional)
if ($AssignRbac) {
  if ([string]::IsNullOrWhiteSpace($ClientId)) {
    throw "ClientId is required to assign RBAC. Provide -ClientId or use -CreateAppRegistration."
  }
  Set-DcrRoleAssignment -DcrResourceId $dcrResourceId -ClientId $ClientId
} else {
  Write-Warn "RBAC assignment skipped. If ingestion fails, assign 'Monitoring Metrics Publisher' on the DCR manually."
}

# Final output block
Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "Enhanced Inventory - Values to paste into inventory scripts" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host ("TenantId:       {0}" -f ($TenantId ?? "<Enter Tenant ID>"))
Write-Host ("ClientId:       {0}" -f ($ClientId ?? "<Enter Client ID>"))
Write-Host ("ClientSecret:   {0}" -f ($ClientSecret ?? "<Enter Client Secret>"))
Write-Host ("DceURI:         {0}" -f $outputs.DceURI)
Write-Host ("DcrImmutableId: {0}" -f $outputs.DcrImmutableId)
Write-Host "============================================================" -ForegroundColor White
Write-Host ""
Write-Ok "Done."
