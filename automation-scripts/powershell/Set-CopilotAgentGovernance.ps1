<#
.SYNOPSIS
    Microsoft Agent 365 Governance Automation Script

.DESCRIPTION
    Automates governance policies for Copilot agents including:
    - Conditional Access policies for agents
    - Custom Security Attributes assignment
    - Policy compliance reporting
    - Agent lifecycle management

.PARAMETER Action
    The governance action to perform:
    - ListPolicies: List all Conditional Access policies for agents
    - ListAgents: List all agents with their governance status
    - AssignAttribute: Assign custom security attribute to agents
    - ComplianceReport: Generate compliance report
    - BlockAgent: Block an agent via Conditional Access
    - UnblockAgent: Unblock an agent

.PARAMETER AgentId
    The agent ID (app ID or object ID) to perform action on

.PARAMETER AttributeName
    Custom security attribute name (format: AttributeSet_AttributeName)

.PARAMETER AttributeValue
    Value to assign to the custom security attribute

.EXAMPLE
    .\Set-CopilotAgentGovernance.ps1 -Action ListPolicies
    Lists all Conditional Access policies that apply to agents

.EXAMPLE
    .\Set-CopilotAgentGovernance.ps1 -Action ListAgents
    Lists all agents with their governance and policy status

.EXAMPLE
    .\Set-CopilotAgentGovernance.ps1 -Action ComplianceReport
    Generates a comprehensive governance compliance report

.EXAMPLE
    .\Set-CopilotAgentGovernance.ps1 -Action AssignAttribute -AgentId "abc123" -AttributeName "Classification_RiskLevel" -AttributeValue "High"
    Assigns a custom security attribute to an agent
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('ListPolicies', 'ListAgents', 'AssignAttribute', 'ComplianceReport', 'BlockAgent', 'UnblockAgent')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$AgentId,
    
    [Parameter(Mandatory=$false)]
    [string]$AttributeName,
    
    [Parameter(Mandatory=$false)]
    [string]$AttributeValue
)

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

Write-Host "`n=== Microsoft Agent 365 Governance Automation ===" -ForegroundColor Cyan
Write-Host "Action: $Action`n" -ForegroundColor White

# Connect to Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $CLIENT_SECRET -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($CLIENT_ID, $secureSecret)
Connect-MgGraph -TenantId $TENANT_ID -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected successfully`n" -ForegroundColor Green

# Helper function to get all agents
function Get-AllAgents {
    Write-Host "Retrieving all Copilot agents..." -ForegroundColor Cyan
    $uri = "https://graph.microsoft.com/beta/copilot/admin/catalog/packages"
    $packages = @()
    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($response.value) {
            foreach ($pkg in $response.value) {
                $packages += [PSCustomObject]@{
                    DisplayName = $pkg.displayName
                    Id = $pkg.id
                    AppId = $pkg.appId
                    Type = $pkg.type
                    IsBlocked = $pkg.isBlocked
                    ElementTypes = ($pkg.elementTypes -join ', ')
                    SupportedHosts = ($pkg.supportedHosts -join ', ')
                    Publisher = $pkg.publisher
                }
            }
        }
        $uri = $response.'@odata.nextLink'
    } while ($uri)
    
    Write-Host "Retrieved $($packages.Count) agents`n" -ForegroundColor Green
    return $packages
}

# Helper function to get Conditional Access policies for agents
function Get-AgentConditionalAccessPolicies {
    Write-Host "Retrieving Conditional Access policies for agents..." -ForegroundColor Cyan
    try {
        $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies"
        $response = Invoke-MgGraphRequest -Method GET -Uri $uri
        
        # Filter policies that target agents
        $agentPolicies = $response.value | Where-Object {
            $_.conditions.users.includeUsers -contains 'All' -or
            $_.conditions.applications.includeApplications -contains 'All' -or
            $_.displayName -like '*agent*' -or
            $_.displayName -like '*copilot*' -or
            $_.displayName -like '*AI*'
        }
        
        Write-Host "Found $($agentPolicies.Count) policies potentially affecting agents`n" -ForegroundColor Green
        return $agentPolicies
    } catch {
        Write-Host "Note: Service principal may need Policy.Read.All permission to list policies" -ForegroundColor Yellow
        Write-Host "Error: $_`n" -ForegroundColor Red
        return @()
    }
}

# Execute requested action
switch ($Action) {
    'ListPolicies' {
        $policies = Get-AgentConditionalAccessPolicies
        
        if ($policies.Count -eq 0) {
            Write-Host "No agent-related Conditional Access policies found.`n" -ForegroundColor Yellow
            Write-Host "To create policies for agents:" -ForegroundColor Cyan
            Write-Host "1. Go to Entra Admin Center: https://entra.microsoft.com" -ForegroundColor White
            Write-Host "2. Navigate to Protection > Conditional Access" -ForegroundColor White
            Write-Host "3. Create new policy with 'Agents' as the user type`n" -ForegroundColor White
        } else {
            Write-Host "=== Conditional Access Policies for Agents ===" -ForegroundColor Green
            foreach ($policy in $policies) {
                Write-Host "`nPolicy: $($policy.displayName)" -ForegroundColor Cyan
                Write-Host "  ID: $($policy.id)" -ForegroundColor White
                Write-Host "  State: $($policy.state)" -ForegroundColor White
                Write-Host "  Created: $($policy.createdDateTime)" -ForegroundColor White
                Write-Host "  Modified: $($policy.modifiedDateTime)" -ForegroundColor White
            }
        }
    }
    
    'ListAgents' {
        $agents = Get-AllAgents
        
        Write-Host "=== Agent Governance Status ===" -ForegroundColor Green
        $agents | Format-Table -Property DisplayName, Type, IsBlocked, ElementTypes, Publisher -AutoSize
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "  Total Agents: $($agents.Count)" -ForegroundColor White
        Write-Host "  Blocked: $(($agents | Where-Object IsBlocked -eq $true).Count)" -ForegroundColor Red
        Write-Host "  Active: $(($agents | Where-Object IsBlocked -eq $false).Count)" -ForegroundColor Green
    }
    
    'ComplianceReport' {
        $agents = Get-AllAgents
        $policies = Get-AgentConditionalAccessPolicies
        
        Write-Host "=== Agent 365 Governance Compliance Report ===" -ForegroundColor Green
        Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor White
        
        Write-Host "Agent Inventory:" -ForegroundColor Cyan
        Write-Host "  Total Agents: $($agents.Count)" -ForegroundColor White
        Write-Host "  Declarative Agents: $(($agents | Where-Object {$_.ElementTypes -like '*DeclarativeAgent*'}).Count)" -ForegroundColor White
        Write-Host "  Custom Engine Agents: $(($agents | Where-Object {$_.ElementTypes -like '*CustomEngineAgent*'}).Count)" -ForegroundColor White
        Write-Host "  Bots: $(($agents | Where-Object {$_.ElementTypes -like '*Bot*'}).Count)" -ForegroundColor White
        
        Write-Host "`nGovernance Status:" -ForegroundColor Cyan
        Write-Host "  Blocked Agents: $(($agents | Where-Object IsBlocked -eq $true).Count)" -ForegroundColor Red
        Write-Host "  Active Agents: $(($agents | Where-Object IsBlocked -eq $false).Count)" -ForegroundColor Green
        
        Write-Host "`nConditional Access:" -ForegroundColor Cyan
        Write-Host "  Total Policies: $($policies.Count)" -ForegroundColor White
        Write-Host "  Enabled: $(($policies | Where-Object state -eq 'enabled').Count)" -ForegroundColor Green
        Write-Host "  Report-Only: $(($policies | Where-Object state -eq 'enabledForReportingButNotEnforced').Count)" -ForegroundColor Yellow
        Write-Host "  Disabled: $(($policies | Where-Object state -eq 'disabled').Count)" -ForegroundColor Red
        
        # Export report to CSV
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportPath = "$PSScriptRoot\AgentGovernanceReport_$timestamp.csv"
        
        $agents | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
        Write-Host "`nReport exported to: $reportPath" -ForegroundColor Green
        
        # Export policies
        if ($policies.Count -gt 0) {
            $policyPath = "$PSScriptRoot\AgentPolicies_$timestamp.csv"
            $policies | Select-Object displayName, id, state, createdDateTime, modifiedDateTime | 
                Export-Csv -Path $policyPath -NoTypeInformation -Encoding UTF8
            Write-Host "Policies exported to: $policyPath" -ForegroundColor Green
        }
    }
    
    'AssignAttribute' {
        if (-not $AgentId -or -not $AttributeName -or -not $AttributeValue) {
            Write-Error "AssignAttribute requires -AgentId, -AttributeName, and -AttributeValue parameters"
            exit 1
        }
        
        Write-Host "Assigning attribute to agent..." -ForegroundColor Cyan
        Write-Host "  Agent ID: $AgentId" -ForegroundColor White
        Write-Host "  Attribute: $AttributeName" -ForegroundColor White
        Write-Host "  Value: $AttributeValue" -ForegroundColor White
        
        try {
            # Note: This requires CustomSecAttributeAssignment.ReadWrite.All permission
            $attributeParts = $AttributeName -split '_'
            if ($attributeParts.Count -ne 2) {
                Write-Error "Attribute name must be in format 'AttributeSet_AttributeName' (e.g., 'Classification_RiskLevel')"
                exit 1
            }
            
            $attributeSet = $attributeParts[0]
            $attribute = $attributeParts[1]
            
            $body = @{
                "customSecurityAttributes" = @{
                    $attributeSet = @{
                        "@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
                        $attribute = $AttributeValue
                    }
                }
            } | ConvertTo-Json -Depth 10
            
            $uri = "https://graph.microsoft.com/beta/servicePrincipals/$AgentId"
            Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType "application/json"
            
            Write-Host "`nAttribute assigned successfully!" -ForegroundColor Green
        } catch {
            Write-Host "`nFailed to assign attribute: $_" -ForegroundColor Red
            Write-Host "Required permissions: CustomSecAttributeAssignment.ReadWrite.All" -ForegroundColor Yellow
        }
    }
    
    'BlockAgent' {
        Write-Host "Note: Blocking agents via API is typically done through the admin center" -ForegroundColor Yellow
        Write-Host "To block an agent:" -ForegroundColor Cyan
        Write-Host "1. Go to M365 Admin Center: https://admin.microsoft.com" -ForegroundColor White
        Write-Host "2. Navigate to Agents > Catalog" -ForegroundColor White
        Write-Host "3. Find the agent and select 'Block'`n" -ForegroundColor White
        Write-Host "Alternatively, create a Conditional Access policy to block the agent" -ForegroundColor Cyan
    }
    
    'UnblockAgent' {
        Write-Host "Note: Unblocking agents via API is typically done through the admin center" -ForegroundColor Yellow
        Write-Host "To unblock an agent:" -ForegroundColor Cyan
        Write-Host "1. Go to M365 Admin Center: https://admin.microsoft.com" -ForegroundColor White
        Write-Host "2. Navigate to Agents > Catalog" -ForegroundColor White
        Write-Host "3. Find the agent and select 'Unblock'`n" -ForegroundColor White
    }
}

# Disconnect
Disconnect-MgGraph | Out-Null
Write-Host "`nCompleted!`n" -ForegroundColor Green
