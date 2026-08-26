<#
.SYNOPSIS
    Lists all Copilot agents from Microsoft Graph API with comprehensive metrics.

.DESCRIPTION
    Retrieves all agents/packages from the Microsoft Graph Copilot Admin catalog endpoint
    and displays hero metrics including counts, status, types, and trends.
    Automatically loads credentials from .env file for secure credential management.

.PARAMETER OutputFormat
    Output format: Table, Json, or CSV. Default is Table.

.PARAMETER ExportPath
    Optional path to export detailed results to a file.

.PARAMETER ShowMetricsOnly
    Display only the hero metrics without the detailed agent list.

.PARAMETER SkipMetrics
    Skip metrics display and show only the detailed agent list.

.EXAMPLE
    .\Get-CopilotAgents.ps1

.EXAMPLE
    .\Get-CopilotAgents.ps1 -OutputFormat Json -ExportPath "agents.json"

.EXAMPLE
    .\Get-CopilotAgents.ps1 -ShowMetricsOnly

.NOTES
    Required API Permissions (Application):
    - CopilotSettings.Read.All or CopilotSettings.ReadWrite.All
    
    The app registration must be granted admin consent for these permissions.
    
    Setup:
    1. Copy .env.example to .env
    2. Configure TENANT_ID, CLIENT_ID, and CLIENT_SECRET in .env
    3. Run this script
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Table', 'Json', 'CSV')]
    [string]$OutputFormat = 'Table',

    [Parameter(Mandatory = $false)]
    [string]$ExportPath,

    [Parameter(Mandatory = $false)]
    [switch]$ShowMetricsOnly,

    [Parameter(Mandatory = $false)]
    [switch]$SkipMetrics
)

# Function to get access token using client credentials
function Get-GraphAccessToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )

    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    
    $body = @{
        client_id     = $ClientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    try {
        Write-Verbose "Requesting access token from Azure AD..."
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Verbose "Access token acquired successfully"
        return $response.access_token
    }
    catch {
        Write-Error "Failed to acquire access token: $_"
        throw
    }
}

# Function to get Copilot agents from Graph API
function Get-CopilotAgentsFromGraph {
    param(
        [string]$AccessToken
    )

    $apiUrl = "https://graph.microsoft.com/v1.0/copilot/admin/catalog/packages"
    
    $headers = @{
        Authorization  = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
    }

    try {
        Write-Verbose "Calling Microsoft Graph API: $apiUrl"
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        Write-Verbose "API call successful"
        return $response
    }
    catch {
        Write-Error "Failed to retrieve Copilot agents: $_"
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Error "HTTP Status Code: $statusCode"
            
            if ($statusCode -eq 403) {
                Write-Warning "Access denied. Ensure the app has the required permissions (CopilotSettings.Read.All) and admin consent has been granted."
            }
        }
        throw
    }
}

# Function to calculate and display hero metrics
function Show-AgentMetrics {
    param(
        [array]$Agents
    )

    Write-Host "`n" "=" * 70 -ForegroundColor Cyan
    Write-Host " COPILOT AGENTS - HERO METRICS" -ForegroundColor Cyan
    Write-Host " " "=" * 70 -ForegroundColor Cyan

    # Total count
    Write-Host "`n📊 TOTAL AGENTS: " -NoNewline -ForegroundColor Yellow
    Write-Host $Agents.Count -ForegroundColor Green

    # Status breakdown
    if ($Agents[0].PSObject.Properties.Name -contains 'status' -or 
        $Agents[0].PSObject.Properties.Name -contains 'state' -or
        $Agents[0].PSObject.Properties.Name -contains 'isEnabled') {
        
        Write-Host "`n🔄 STATUS BREAKDOWN:" -ForegroundColor Yellow
        
        $statusField = if ($Agents[0].PSObject.Properties.Name -contains 'status') { 'status' }
                       elseif ($Agents[0].PSObject.Properties.Name -contains 'state') { 'state' }
                       elseif ($Agents[0].PSObject.Properties.Name -contains 'isEnabled') { 'isEnabled' }
                       else { $null }
        
        if ($statusField) {
            $statusGroups = $Agents | Group-Object -Property $statusField
            foreach ($group in $statusGroups | Sort-Object Count -Descending) {
                Write-Host "  • $($group.Name): " -NoNewline -ForegroundColor White
                Write-Host $group.Count -ForegroundColor Cyan
            }
        }
    }

    # Type/Category breakdown
    if ($Agents[0].PSObject.Properties.Name -contains 'type' -or 
        $Agents[0].PSObject.Properties.Name -contains 'category' -or
        $Agents[0].PSObject.Properties.Name -contains 'packageType') {
        
        Write-Host "`n📦 TYPE/CATEGORY BREAKDOWN:" -ForegroundColor Yellow
        
        $typeField = if ($Agents[0].PSObject.Properties.Name -contains 'type') { 'type' }
                     elseif ($Agents[0].PSObject.Properties.Name -contains 'category') { 'category' }
                     elseif ($Agents[0].PSObject.Properties.Name -contains 'packageType') { 'packageType' }
                     else { $null }
        
        if ($typeField) {
            $typeGroups = $Agents | Group-Object -Property $typeField
            foreach ($group in $typeGroups | Sort-Object Count -Descending) {
                Write-Host "  • $($group.Name): " -NoNewline -ForegroundColor White
                Write-Host $group.Count -ForegroundColor Cyan
            }
        }
    }

    # Publisher/Source breakdown
    if ($Agents[0].PSObject.Properties.Name -contains 'publisher' -or 
        $Agents[0].PSObject.Properties.Name -contains 'source' -or
        $Agents[0].PSObject.Properties.Name -contains 'publisherName') {
        
        Write-Host "`n🏢 PUBLISHER/SOURCE BREAKDOWN:" -ForegroundColor Yellow
        
        $publisherField = if ($Agents[0].PSObject.Properties.Name -contains 'publisher') { 'publisher' }
                         elseif ($Agents[0].PSObject.Properties.Name -contains 'publisherName') { 'publisherName' }
                         elseif ($Agents[0].PSObject.Properties.Name -contains 'source') { 'source' }
                         else { $null }
        
        if ($publisherField) {
            $publisherGroups = $Agents | Group-Object -Property $publisherField
            foreach ($group in $publisherGroups | Sort-Object Count -Descending | Select-Object -First 10) {
                $publisherName = if ([string]::IsNullOrWhiteSpace($group.Name)) { "(Unknown)" } else { $group.Name }
                Write-Host "  • $publisherName : " -NoNewline -ForegroundColor White
                Write-Host $group.Count -ForegroundColor Cyan
            }
            if ($publisherGroups.Count -gt 10) {
                Write-Host "  ... and $($publisherGroups.Count - 10) more" -ForegroundColor Gray
            }
        }
    }

    # Recently added (last 30 days)
    if ($Agents[0].PSObject.Properties.Name -contains 'createdDateTime' -or 
        $Agents[0].PSObject.Properties.Name -contains 'addedDateTime' -or
        $Agents[0].PSObject.Properties.Name -contains 'publishedDateTime') {
        
        Write-Host "`n📅 RECENTLY ADDED (Last 30 Days):" -ForegroundColor Yellow
        
        $dateField = if ($Agents[0].PSObject.Properties.Name -contains 'createdDateTime') { 'createdDateTime' }
                     elseif ($Agents[0].PSObject.Properties.Name -contains 'addedDateTime') { 'addedDateTime' }
                     elseif ($Agents[0].PSObject.Properties.Name -contains 'publishedDateTime') { 'publishedDateTime' }
                     else { $null }
        
        if ($dateField) {
            $thirtyDaysAgo = (Get-Date).AddDays(-30)
            $recentAgents = $Agents | Where-Object { 
                try {
                    $dateValue = $_.$dateField
                    if ($dateValue) {
                        [DateTime]$dateValue -gt $thirtyDaysAgo
                    }
                }
                catch { $false }
            }
            Write-Host "  • New agents: " -NoNewline -ForegroundColor White
            Write-Host $recentAgents.Count -ForegroundColor Cyan
        }
    }

    Write-Host "`n" "=" * 70 -ForegroundColor Cyan
}

# Load environment variables from .env file
Write-Host "Loading configuration from .env file..." -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptDir ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found. Please copy .env.example to .env and configure your credentials."
    Write-Host "`nSetup Steps:" -ForegroundColor Yellow
    Write-Host "  1. Copy .env.example to .env" -ForegroundColor White
    Write-Host "  2. Edit .env and add your actual credentials" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    Write-Host "`nFor detailed setup instructions, see SETUP.md" -ForegroundColor Gray
    exit 1
}

# Parse .env file
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line -split '=', 2
        if ($parts.Length -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            $envVars[$key] = $value
        }
    }
}

# Validate required variables
$requiredVars = @('TENANT_ID', 'CLIENT_ID', 'CLIENT_SECRET')
$missingVars = $requiredVars | Where-Object { -not $envVars.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($envVars[$_]) }

if ($missingVars) {
    Write-Error "Missing required environment variables in .env file: $($missingVars -join ', ')"
    exit 1
}

$TenantId = $envVars['TENANT_ID']
$ClientId = $envVars['CLIENT_ID']
$ClientSecret = $envVars['CLIENT_SECRET']

# Main execution
try {
    Write-Host "Retrieving Copilot agents from Microsoft Graph..." -ForegroundColor Cyan

    # Get access token
    $accessToken = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

    # Get agents from Graph API
    $result = Get-CopilotAgentsFromGraph -AccessToken $accessToken

    # Process and display results
    if ($result.value) {
        $agents = $result.value

        # Show metrics unless explicitly skipped
        if (-not $SkipMetrics) {
            Show-AgentMetrics -Agents $agents
        }

        # Show detailed list unless ShowMetricsOnly is specified
        if (-not $ShowMetricsOnly) {
            Write-Host "`n📋 DETAILED AGENT LIST:" -ForegroundColor Yellow
            Write-Host ""

            switch ($OutputFormat) {
                'Table' {
                    $agents | Format-Table -AutoSize
                }
                'Json' {
                    $agents | ConvertTo-Json -Depth 10
                }
                'CSV' {
                    $agents | ConvertTo-Csv -NoTypeInformation
                }
            }
        }

        # Export to file if path specified
        if ($ExportPath) {
            switch ($OutputFormat) {
                'Json' {
                    $agents | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8
                }
                'CSV' {
                    $agents | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
                }
                default {
                    $agents | Out-File -FilePath $ExportPath -Encoding UTF8
                }
            }
            Write-Host "`n✅ Results exported to: $ExportPath" -ForegroundColor Green
        }

        # Handle pagination if needed
        if ($result.'@odata.nextLink') {
            Write-Host "`n⚠️  Results are paginated. This script retrieved the first page only." -ForegroundColor Yellow
            Write-Host "   Next page URL: $($result.'@odata.nextLink')" -ForegroundColor Gray
        }
    }
    else {
        Write-Warning "No agents found in the catalog"
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
