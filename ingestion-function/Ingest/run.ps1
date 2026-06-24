using namespace System.Net

# PowerStacks secretless inventory ingestion forwarder.
#
# Receives an envelope of one or more inventory submissions from a collector,
# authenticates to Azure Monitor with this Function's system-assigned managed
# identity (no secret), and forwards each submission to the matching stream on
# the configured Data Collection Rule.
#
# Inbound body shape:
#   { "submissions": [ { "stream": "Custom-PowerStacksDeviceInventory_CL", "rows": [ { ... } ] }, ... ] }
#
# One inbound request is one Function execution regardless of how many streams it
# carries, which is what keeps the per-device cost at one execution per run.

param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'

$dceUri = $env:DceUri
$dcrId  = $env:DcrImmutableId

if (-not $dceUri -or -not $dcrId) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body       = 'Function is missing the DceUri or DcrImmutableId app setting.'
    })
    return
}

# Functions deserializes a JSON request body for us; handle a raw string too.
$envelope = $Request.Body
if ($envelope -is [string]) { $envelope = $envelope | ConvertFrom-Json }

$submissions = $envelope.submissions
if (-not $submissions) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body       = 'Request body has no "submissions" array.'
    })
    return
}

# Managed-identity token for Azure Monitor ingestion, straight from the App Service
# identity endpoint so no Az module has to load.
$tokenUri = "$($env:IDENTITY_ENDPOINT)?resource=https://monitor.azure.com&api-version=2019-08-01"
$token = (Invoke-RestMethod -Uri $tokenUri -Headers @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER }).access_token

$results = New-Object System.Collections.ArrayList

foreach ($sub in $submissions) {
    $stream = $sub.stream
    $rows   = $sub.rows

    if (-not $stream -or $null -eq $rows) {
        [void]$results.Add([pscustomobject]@{ stream = $stream; rows = 0; status = 'skipped: missing stream or rows' })
        continue
    }

    $rowArray  = @($rows)
    $ingestUri = "$dceUri/dataCollectionRules/$dcrId/streams/$stream" + "?api-version=2023-01-01"
    $payload   = ConvertTo-Json -InputObject $rowArray -Depth 20 -AsArray

    try {
        Invoke-RestMethod -Uri $ingestUri -Method Post -Body $payload -Headers @{
            Authorization  = "Bearer $token"
            'Content-Type' = 'application/json'
        } | Out-Null
        [void]$results.Add([pscustomobject]@{ stream = $stream; rows = $rowArray.Count; status = 'ok' })
    }
    catch {
        [void]$results.Add([pscustomobject]@{ stream = $stream; rows = $rowArray.Count; status = "error: $($_.Exception.Message)" })
    }
}

# Return a non-2xx status if any stream failed to ingest, so the caller's retry logic
# (exponential backoff on the endpoint, where there is time to wait) re-sends the
# submission. A failed DCR write here, for example a 403 while the role assignment is
# still propagating, surfaces as a retryable error rather than a silent 200.
$anyFailed = @($results | Where-Object { $_.status -ne 'ok' }).Count -gt 0
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = if ($anyFailed) { [HttpStatusCode]::BadGateway } else { [HttpStatusCode]::OK }
    Headers    = @{ 'Content-Type' = 'application/json' }
    Body       = (ConvertTo-Json -InputObject @($results) -Depth 5 -AsArray)
})
