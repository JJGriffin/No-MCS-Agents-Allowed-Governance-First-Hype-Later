<#
.SYNOPSIS
    Get Copilot agents inventory using service principal, export to CSV, and email

.DESCRIPTION
    Uses service principal authentication from .env file to avoid interactive prompts.
    Note: As of Aug 2026, Copilot Package Management API may only support delegated auth.
    If you get 403 errors, you'll need to use interactive auth or wait for Microsoft to enable app permissions.

.EXAMPLE
    .\Get-CopilotAgentsInventory.ps1
#>

# Load .env file
$envPath = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envPath)) {
    Write-Error ".env file not found at $envPath"
    exit 1
}

Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.+?)\s*$') {
        $name = $matches[1]
        $value = $matches[2]
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

# Validate required variables
if (-not $TENANT_ID -or -not $CLIENT_ID -or -not $CLIENT_SECRET) {
    Write-Error "Missing required variables in .env file: TENANT_ID, CLIENT_ID, CLIENT_SECRET"
    exit 1
}

if (-not $FROM_EMAIL) {
    Write-Error "FROM_EMAIL not found in .env file (needed for sending email with service principal)"
    exit 1
}

if (-not $EMAIL_TO) {
    Write-Warning "EMAIL_TO not found in .env, using default: richa.s.pandit@outlook.com"
    $EMAIL_TO = "richa.s.pandit@outlook.com"
}

# Connect to Graph using service principal
Write-Host "Connecting to Microsoft Graph using service principal..." -ForegroundColor Cyan
try {
    $secureSecret = ConvertTo-SecureString $CLIENT_SECRET -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($CLIENT_ID, $secureSecret)
    
    Connect-MgGraph -TenantId $TENANT_ID -ClientSecretCredential $credential -NoWelcome
    Write-Host "Connected successfully as service principal" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect with service principal: $_"
    Write-Warning "The Copilot Package Management API may only support delegated (interactive) authentication."
    Write-Warning "You may need to grant admin consent for application permissions in Azure AD."
    exit 1
}

# Get packages
Write-Host "Retrieving packages..." -ForegroundColor Cyan
$uri = "https://graph.microsoft.com/beta/copilot/admin/catalog/packages"
$packages = @()
do {
    $response = Invoke-MgGraphRequest -Method GET -Uri $uri
    if ($response.value) { $packages += $response.value }
    $uri = $response.'@odata.nextLink'
} while ($uri)

Write-Host "Retrieved $($packages.Count) packages" -ForegroundColor Green

# Format and export to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "$PSScriptRoot\CopilotAgentsInventory_$timestamp.csv"

# Convert hashtables to PSCustomObjects for proper CSV export
$exportData = $packages | ForEach-Object {
    [PSCustomObject]@{
        DisplayName = $_.displayName
        Id = $_.id
        Type = $_.type
        IsBlocked = $_.isBlocked
        AvailableTo = $_.availableTo
        DeployedTo = $_.deployedTo
        Publisher = $_.publisher
        Version = $_.version
        ElementTypes = ($_.elementTypes -join ', ')
        SupportedHosts = ($_.supportedHosts -join ', ')
        LastModifiedDateTime = $_.lastModifiedDateTime
        AppId = $_.appId
        ManifestId = $_.manifestId
        ShortDescription = $_.shortDescription
    }
}

$exportData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported to: $csvPath" -ForegroundColor Green

# Send email
Write-Host "Sending email to $EMAIL_TO..." -ForegroundColor Cyan

$fileBytes = [System.IO.File]::ReadAllBytes($csvPath)
$fileBase64 = [Convert]::ToBase64String($fileBytes)
$fileName = Split-Path $csvPath -Leaf

$emailBody = @{
    message = @{
        subject = "Copilot Agents Inventory - $(Get-Date -Format 'yyyy-MM-dd')"
        body = @{
            contentType = "HTML"
            content = "<h3>Copilot Agents Inventory Report</h3><p>Total packages: <strong>$($packages.Count)</strong></p><p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>"
        }
        toRecipients = @(@{ emailAddress = @{ address = $EMAIL_TO } })
        attachments = @(@{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            name = $fileName
            contentType = "text/csv"
            contentBytes = $fileBase64
        })
    }
    saveToSentItems = "true"
} | ConvertTo-Json -Depth 10

# Use specific user mailbox instead of /me (service principal auth doesn't support /me)
try {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$FROM_EMAIL/sendMail" -Body $emailBody -ContentType "application/json"
    Write-Host "Email sent successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to send email: $_"
    Write-Warning "Email sending failed. CSV has been saved to: $csvPath"
    Write-Warning "Check that:"
    Write-Warning "  1. FROM_EMAIL ($FROM_EMAIL) is a valid mailbox"
    Write-Warning "  2. App has Mail.Send permission with admin consent"
    Write-Warning "  3. FROM_EMAIL mailbox is licensed and can send mail"
}

# Disconnect
Disconnect-MgGraph | Out-Null

Write-Host "`nCompleted! CSV: $csvPath" -ForegroundColor Green