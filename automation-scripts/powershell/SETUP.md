# Setup Guide - Copilot Agents Automation Scripts

This guide walks you through setting up the automation scripts to list Copilot agents using the Microsoft Graph API.

## Prerequisites

- **PowerShell 5.1 or later** (Windows PowerShell or PowerShell Core)
- **Azure AD Tenant** with appropriate permissions
- **Global Administrator or Application Administrator** role in Azure AD (for app registration and consent)
- **Microsoft 365 Copilot** subscription and admin access

## Step 1: Create Azure AD App Registration

### 1.1 Navigate to Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Sign in with an account that has Global Administrator or Application Administrator role
3. Navigate to **Azure Active Directory** > **App registrations**

### 1.2 Register a New Application
1. Click **New registration**
2. Fill in the following details:
   - **Name**: `Copilot Agents Automation` (or your preferred name)
   - **Supported account types**: Select "Accounts in this organizational directory only (Single tenant)"
   - **Redirect URI**: Leave blank (not needed for client credentials flow)
3. Click **Register**

### 1.3 Note the Application Details
After registration, copy the following values (you'll need these later):
- **Application (client) ID**: Found on the Overview page
- **Directory (tenant) ID**: Found on the Overview page

## Step 2: Create a Client Secret

### 2.1 Generate Client Secret
1. In your app registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Fill in the details:
   - **Description**: `Copilot Agents Script` (or your preferred description)
   - **Expires**: Choose an appropriate expiration period (recommend 90 days or 6 months for security)
4. Click **Add**

### 2.2 Copy the Secret Value
⚠️ **IMPORTANT**: Copy the **Value** immediately - it won't be shown again!
- The **Secret ID** is NOT what you need
- Copy the **Value** field and store it securely

## Step 3: Configure API Permissions

### 3.1 Add Required Permissions
1. In your app registration, go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Select **Application permissions** (not Delegated permissions)
5. Search for and select:
   - `CopilotSettings.Read.All` (to read Copilot settings and agents)
   
   **OR**
   
   - `CopilotSettings.ReadWrite.All` (if you plan to add write capabilities later)

6. Click **Add permissions**

### 3.2 Grant Admin Consent
⚠️ **CRITICAL STEP**: Application permissions require admin consent
1. Click **Grant admin consent for [Your Organization]**
2. Click **Yes** to confirm
3. Verify that the **Status** column shows a green checkmark with "Granted for [Your Organization]"

## Step 4: Configure the Scripts

### 4.1 Create Environment File
1. Navigate to the `automation-scripts/powershell` directory
2. Copy the example environment file:
   ```powershell
   Copy-Item .env.example .env
   ```

### 4.2 Edit the .env File
Open the `.env` file and replace the placeholder values with your actual credentials:

```plaintext
TENANT_ID=your-tenant-id-here
CLIENT_ID=your-application-client-id-here
CLIENT_SECRET=your-client-secret-here
```

**Example:**
```plaintext
TENANT_ID=12345678-1234-1234-1234-123456789abc
CLIENT_ID=87654321-4321-4321-4321-cba987654321
CLIENT_SECRET=abc123~def456.ghi789_jkl012
```

### 4.3 Secure the .env File
⚠️ **SECURITY**: The `.env` file contains sensitive credentials
- Never commit the `.env` file to version control (already in `.gitignore`)
- Restrict file permissions if working on a shared system
- Consider using Azure Key Vault for production environments

## Step 5: Run the Script

The script automatically loads credentials from the `.env` file and displays comprehensive metrics:

```powershell
# Navigate to the scripts directory
cd automation-scripts/powershell

# Run with default output (shows metrics + table)
.\Get-CopilotAgents.ps1

# Show only metrics
.\Get-CopilotAgents.ps1 -ShowMetricsOnly

# Skip metrics, show only detailed list
.\Get-CopilotAgents.ps1 -SkipMetrics

# Export to JSON
.\Get-CopilotAgents.ps1 -OutputFormat Json -ExportPath "agents.json"

# Export to CSV
.\Get-CopilotAgents.ps1 -OutputFormat CSV -ExportPath "agents.csv"
```

### Script Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `OutputFormat` | Output format for detailed list | `Table` | `Table`, `Json`, `CSV` |
| `ExportPath` | File path to export results | None | Any valid file path |
| `ShowMetricsOnly` | Display only hero metrics | `false` | Switch parameter |
| `SkipMetrics` | Skip metrics, show only detailed list | `false` | Switch parameter |

### Hero Metrics Displayed

The script automatically calculates and displays:
- 📊 **Total Agent Count** - Total number of agents in the catalog
- 🔄 **Status Breakdown** - Distribution by enabled/disabled status
- 📦 **Type/Category Breakdown** - Distribution by agent type or category
- 🏢 **Publisher/Source Breakdown** - Top publishers (up to 10)
- 📅 **Recently Added** - Agents added in the last 30 days

### Examples

**Display metrics and detailed list:**
```powershell
.\Get-CopilotAgents.ps1
```

**Show only metrics (no detailed list):**
```powershell
.\Get-CopilotAgents.ps1 -ShowMetricsOnly
```

**Skip metrics, show only detailed list:**
```powershell
.\Get-CopilotAgents.ps1 -SkipMetrics
```

**Export to JSON with metrics:**
```powershell
.\Get-CopilotAgents.ps1 -OutputFormat Json -ExportPath "C:\Reports\copilot-agents.json"
```

**Export to CSV without metrics:**
```powershell
.\Get-CopilotAgents.ps1 -SkipMetrics -OutputFormat CSV -ExportPath "C:\Reports\copilot-agents.csv"
```

**Enable verbose logging:**
```powershell
.\Get-CopilotAgents.ps1 -Verbose
```

## Troubleshooting

### Error: "Failed to acquire access token"

**Possible causes:**
- Incorrect tenant ID, client ID, or client secret
- Client secret has expired

**Solution:**
1. Verify all values in the `.env` file match those in Azure Portal
2. Check if the client secret has expired in **Certificates & secrets**
3. Generate a new secret if needed and update `.env`

### Error: "HTTP Status Code: 403" or "Access denied"

**Possible causes:**
- Missing API permissions
- Admin consent not granted

**Solution:**
1. Verify `CopilotSettings.Read.All` permission is added in **API permissions**
2. Ensure **Admin consent** is granted (green checkmark in Status column)
3. Wait 5-10 minutes after granting consent for changes to propagate

### Error: ".env file not found"

**Possible causes:**
- The `.env` file hasn't been created
- Running script from wrong directory

**Solution:**
1. Copy `.env.example` to `.env`
2. Fill in the required values
3. Run the script from the `automation-scripts/powershell` directory

### Error: "Missing required environment variables"

**Possible causes:**
- `.env` file is empty or incomplete
- Environment variable names are misspelled

**Solution:**
1. Open `.env` file and verify all three variables are present:
   - `TENANT_ID`
   - `CLIENT_ID`
   - `CLIENT_SECRET`
2. Ensure there are no extra spaces or quotes around values

### Warning: "Results are paginated"

**Information:**
The Microsoft Graph API returns results in pages. If you see this warning, there are more results than shown.

**Future enhancement:**
The script currently retrieves the first page only. Pagination support can be added if needed.

## Security Best Practices

### Credential Management
- ✅ Use `.env` files (excluded from version control)
- ✅ Set client secret expiration to shortest acceptable period
- ✅ Rotate secrets regularly
- ✅ Use Azure Key Vault for production environments
- ❌ Never hardcode credentials in scripts
- ❌ Never commit `.env` files to Git

### Least Privilege
- ✅ Use `CopilotSettings.Read.All` if only reading data
- ✅ Create dedicated service account for automation
- ❌ Don't use personal admin accounts for automation
- ❌ Don't grant more permissions than necessary

### Monitoring
- ✅ Review Azure AD sign-in logs periodically
- ✅ Monitor for unusual API activity
- ✅ Set up alerts for failed authentication attempts

## Advanced Configuration

### Running as a Scheduled Task

To run the script on a schedule (e.g., daily reports):

1. Open **Task Scheduler**
2. Create a new task with these settings:
   - **Action**: Start a program
   - **Program**: `powershell.exe`
   - **Arguments**: `-ExecutionPolicy Bypass -File "C:\path\to\Get-CopilotAgents.ps1" -OutputFormat Json -ExportPath "C:\Reports\agents-$(Get-Date -Format 'yyyyMMdd').json"`
   - **Start in**: `C:\path\to\automation-scripts\powershell`

### Script Output Example

```
Loading configuration from .env file...
Retrieving Copilot agents from Microsoft Graph...

======================================================================
                    COPILOT AGENTS - HERO METRICS
======================================================================

📊 TOTAL AGENTS: 45

🔄 STATUS BREAKDOWN:
  • Enabled: 38
  • Disabled: 7

📦 TYPE/CATEGORY BREAKDOWN:
  • DeclarativeAgent: 25
  • CustomEngineAgent: 15
  • Plugin: 5

🏢 PUBLISHER/SOURCE BREAKDOWN:
  • Microsoft Corporation: 20
  • Contoso Ltd: 12
  • Internal: 8
  • Third Party Vendor A: 5

📅 RECENTLY ADDED (Last 30 Days):
  • New agents: 8

======================================================================

📋 DETAILED AGENT LIST:

[Table or JSON output follows...]
```

### Using Azure Key Vault (Production)

For production environments, store secrets in Azure Key Vault:

```powershell
# Install Azure PowerShell module
Install-Module -Name Az.KeyVault

# Connect to Azure
Connect-AzAccount

# Retrieve secrets
$tenantId = (Get-AzKeyVaultSecret -VaultName "YourVault" -Name "TenantId").SecretValueText
$clientId = (Get-AzKeyVaultSecret -VaultName "YourVault" -Name "ClientId").SecretValueText
$clientSecret = (Get-AzKeyVaultSecret -VaultName "YourVault" -Name "ClientSecret").SecretValueText

# Run script
.\Get-CopilotAgents.ps1 -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret
```

## API Reference

**Endpoint:** `GET https://graph.microsoft.com/v1.0/copilot/admin/catalog/packages`

**Required Permission:** `CopilotSettings.Read.All` or `CopilotSettings.ReadWrite.All`

**Documentation:** [Microsoft Graph API - Copilot](https://learn.microsoft.com/en-us/graph/api/resources/copilot)

## Support and Contribution

For issues or enhancements:
1. Check the troubleshooting section above
2. Review Azure AD audit logs for authentication issues
3. Verify API permissions and consent status
4. Open an issue in the repository with detailed error messages

---

**Last Updated:** 2026-08-26
