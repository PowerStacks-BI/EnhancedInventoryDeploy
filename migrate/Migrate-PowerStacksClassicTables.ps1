<#
.SYNOPSIS
  Migrates legacy "Classic" PowerStacks Enhanced Inventory custom log tables to
  DCR-based tables so the Enhanced Inventory ARM template can upgrade them to the
  Log Ingestion API path.

.DESCRIPTION
  Environments that were originally deployed against the legacy HTTP Data Collector
  API have custom log tables (PowerStacksAppInventory_CL, PowerStacksDeviceInventory_CL,
  PowerStacksDriverInventory_CL) created as "Classic" tables. The current ARM template
  manages tables through the DCR-based tables API, and Azure forbids changing a Classic
  table's schema with that API. The result is a deployment error like:

    "Changing Classic table PowerStacksAppInventory_CL schema by using
     DataCollectionRuleBased tables api is forbidden, please migrate the table first."

  This script performs that one-time migration. For each target table it checks the
  current schema sub-type and migrates ONLY tables that are still Classic. Tables that
  are absent or already DCR-based are skipped, so the script is idempotent and safe to
  re-run. On a fresh install (no legacy tables) it does nothing.

  The migration:
    - is one-way (a table cannot be converted back to Classic),
    - preserves all existing data in the table,
    - lets the legacy Data Collector API keep writing during Microsoft's grace period,
      so there is no ingestion gap while the collector is cut over.

  It runs as the signed-in user and makes NO managed identity and NO role assignment.

.REQUIREMENTS
  - Windows PowerShell 5.1 or PowerShell 7+
  - Az PowerShell modules (Az.Accounts)
  - Azure permission to migrate tables on the workspace
    (Microsoft.OperationalInsights/workspaces/tables/write, e.g. Log Analytics
    Contributor or Owner on the workspace)

.PARAMETER SubscriptionId
  Subscription ID of the Log Analytics workspace.

.PARAMETER ResourceGroupName
  Resource group of the Log Analytics workspace.

.PARAMETER WorkspaceName
  Name of the Log Analytics workspace.

.PARAMETER TableName
  One or more custom table names to check. Defaults to the three legacy PowerStacks
  Enhanced Inventory tables.

.EXAMPLE
  # Preview what would change (no migration performed)
  .\Migrate-PowerStacksClassicTables.ps1 -SubscriptionId 752a... -ResourceGroupName 398314-Intune -WorkspaceName my-law -WhatIf

.EXAMPLE
  # Migrate any Classic tables, then re-run the Enhanced Inventory deployment
  .\Migrate-PowerStacksClassicTables.ps1 -SubscriptionId 752a... -ResourceGroupName 398314-Intune -WorkspaceName my-law

.NOTES
  Author: PowerStacks
  Product: PowerStacks Enhanced Inventory

  Uses Invoke-AzRestMethod to avoid cmdlet version limitations and ensure compatibility
  across PowerShell versions.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SubscriptionId,
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$WorkspaceName,
    [string]$TenantId,
    [string[]]$TableName = @(
        'PowerStacksAppInventory_CL',
        'PowerStacksDeviceInventory_CL',
        'PowerStacksDriverInventory_CL'
    )
)

$ErrorActionPreference = 'Stop'

# GET uses a GA tables api-version that returns schema.tableSubType.
# The migrate action is exposed on the 2021-12-01-preview tables api-version.
$getApiVersion     = '2022-10-01'
$migrateApiVersion = '2021-12-01-preview'

function Get-TablePath { param($Table) "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/tables/$Table" }

# --- Ensure a usable Azure session for the target subscription ---
# A cached token can go stale (common on tenants with conditional access, which
# also block device-code sign-in) and cannot always be refreshed silently. So we
# validate the session with a real token request and fall back to an interactive
# sign-in. Interactive sign-in is required on locked-down tenants: in Azure Cloud
# Shell you are already signed in; locally a browser window opens. Device-code
# auth is never used. If your tenant enforces conditional access, you can also run
# Connect-AzAccount yourself before this script.
$connect = @{ Subscription = $SubscriptionId }
if ($TenantId) { $connect['Tenant'] = $TenantId }

$haveSession = $false
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if ($ctx -and $ctx.Account) {
    try {
        if ($ctx.Subscription.Id -ne $SubscriptionId) {
            Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop | Out-Null
        }
        # Force a token request: a stale or conditional-access-blocked session
        # throws here instead of failing later, mid-run.
        Get-AzAccessToken -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
        $haveSession = $true
    } catch {
        $haveSession = $false
    }
}

if (-not $haveSession) {
    Write-Host 'Signing in to Azure (an interactive sign-in window may open)...' -ForegroundColor Yellow
    Connect-AzAccount @connect | Out-Null
    Set-AzContext -Subscription $SubscriptionId | Out-Null
}

Write-Host ''
Write-Host 'PowerStacks Enhanced Inventory - Classic table migration' -ForegroundColor Cyan
Write-Host ("Workspace : {0}" -f $WorkspaceName)
Write-Host ("Resource group : {0}" -f $ResourceGroupName)
Write-Host ("Subscription : {0}" -f $SubscriptionId)
Write-Host ''

$results = New-Object System.Collections.Generic.List[object]

foreach ($table in $TableName) {
    $row = [ordered]@{ Table = $table; Before = ''; Action = ''; After = '' }
    try {
        $get = Invoke-AzRestMethod -Method GET -Path ("{0}?api-version={1}" -f (Get-TablePath $table), $getApiVersion)

        if ($get.StatusCode -eq 404) {
            $row.Action = 'Skipped (not present)'
            Write-Host ("[{0}] not present - skipping" -f $table) -ForegroundColor DarkGray
            $results.Add([pscustomobject]$row); continue
        }
        if ($get.StatusCode -ge 400) {
            throw ("GET returned HTTP {0}: {1}" -f $get.StatusCode, $get.Content)
        }

        $subType = ($get.Content | ConvertFrom-Json).properties.schema.tableSubType
        $row.Before = $subType

        if ($subType -eq 'Classic') {
            if ($PSCmdlet.ShouldProcess($table, 'Migrate Classic table to DCR-based')) {
                $mig = Invoke-AzRestMethod -Method POST -Path ("{0}/migrate?api-version={1}" -f (Get-TablePath $table), $migrateApiVersion)
                if ($mig.StatusCode -ge 400) {
                    throw ("Migrate returned HTTP {0}: {1}" -f $mig.StatusCode, $mig.Content)
                }
                $after = Invoke-AzRestMethod -Method GET -Path ("{0}?api-version={1}" -f (Get-TablePath $table), $getApiVersion)
                $row.After  = ($after.Content | ConvertFrom-Json).properties.schema.tableSubType
                $row.Action = 'Migrated'
                Write-Host ("[{0}] migrated Classic -> {1}" -f $table, $row.After) -ForegroundColor Green
            } else {
                $row.Action = 'WhatIf (would migrate)'
                Write-Host ("[{0}] WhatIf - currently Classic, would migrate" -f $table) -ForegroundColor Yellow
            }
        } else {
            $row.After  = $subType
            $row.Action = 'Skipped (already DCR-based)'
            Write-Host ("[{0}] already '{1}' - skipping" -f $table, $subType) -ForegroundColor DarkGray
        }
    } catch {
        $row.Action = "ERROR: $($_.Exception.Message)"
        Write-Host ("[{0}] ERROR: {1}" -f $table, $_.Exception.Message) -ForegroundColor Red
    }
    $results.Add([pscustomobject]$row)
}

Write-Host ''
Write-Host 'Summary' -ForegroundColor Cyan
$results | Format-Table -AutoSize | Out-String | Write-Host

$migrated = @($results | Where-Object { $_.Action -eq 'Migrated' }).Count
$errors   = @($results | Where-Object { $_.Action -like 'ERROR*' }).Count
Write-Host ("Migrated: {0}   Errors: {1}" -f $migrated, $errors) -ForegroundColor Cyan

if ($migrated -gt 0) {
    Write-Host ''
    Write-Host 'Migration complete. Re-run the Enhanced Inventory deployment to finish the upgrade.' -ForegroundColor Green
}
if ($errors -gt 0) { exit 1 }
