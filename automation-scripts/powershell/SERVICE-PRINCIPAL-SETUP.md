# Service Principal Setup for Copilot Agents Inventory

## 🔥 Quick Fix: Why Am I Still Asked to Sign In?

**Your app registration exists**, but it's missing the correct **API permissions** and **admin consent**. Here's the 2-minute fix:

### Step 1: Add Application Permissions
1. Go to [Azure Portal](https://portal.azure.com) > **Azure Active Directory** > **App registrations**
2. Find your app: `f3a4e3dc-5dc9-4a80-949a-de40cbff4b3b`
3. Click **API permissions** > **Add a permission** > **Microsoft Graph**
4. Select **Application permissions** (⚠️ NOT "Delegated permissions")
5. Search and add:
   - ✅ `CopilotPackages.Read.All`
   - ✅ `Mail.Send`

### Step 2: Grant Admin Consent (CRITICAL!)
1. Click **Grant admin consent for [your tenant]**
2. Confirm with **Yes**
3. Wait for "Granted" to appear in the Status column

### Step 3: Test
Run the script - no more sign-in prompts! 🎉

---

## Overview
This script uses service principal (app-only) authentication to avoid interactive login prompts every time you run it.

## ⚠️ Important Limitation
As of **August 2026**, Microsoft's Copilot Package Management API documentation states that **application permissions are NOT supported** for read operations. The API only supports **delegated permissions** (interactive user auth).

**What this means:**
- Service principal auth may fail with `403 Forbidden` errors
- If it fails, you'll need to use interactive authentication
- Microsoft may enable app permissions in the future

## Setup Steps

### 1. Create Azure AD App Registration

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Click **New registration**
4. Fill in:
   - **Name**: `Copilot-Agents-Inventory-Automation`
   - **Supported account types**: Accounts in this organizational directory only
   - Click **Register**

### 2. Create Client Secret

1. In your new app registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Add description: `PowerShell Script Access`
4. Choose expiration (recommendation: 12-24 months)
5. Click **Add**
6. **Copy the secret value immediately** (you won't see it again!)

### 3. Grant API Permissions

1. Go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Choose **Application permissions** (not Delegated)
5. Add these permissions:
   - `CopilotPackages.Read.All` - Read Copilot packages **(may not work - see warning above)**
   - `Mail.Send` - Send email as the application
6. Click **Add permissions**
7. Click **Grant admin consent for [Your Tenant]** (requires Global Admin)
8. Confirm

### 4. Configure .env File

1. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Edit `.env` and fill in your values:
   ```
   TENANT_ID=your-tenant-id-here        # From Azure AD overview
   CLIENT_ID=your-app-client-id-here    # From app registration overview
   CLIENT_SECRET=your-secret-value-here # The secret you copied
   EMAIL_TO=richa.s.pandit@outlook.com  # Or your preferred recipient
   ```

3. **Never commit `.env` to source control!** (already in `.gitignore`)

## Usage

```powershell
# Simple run - uses .env for everything
.\Get-CopilotAgentsInventory.ps1
```

## Troubleshooting

### 403 Forbidden Error
```
Invoke-MgGraphRequest: Forbidden
```

**Cause**: The API doesn't support application permissions yet.

**Solutions**:
1. **Wait for Microsoft**: Check if they've enabled app permissions
2. **Use delegated auth**: Fall back to interactive authentication
3. **Use certificate auth**: Some APIs prefer certificate over secret

### Admin Consent Not Granted
```
Error: Insufficient privileges to complete the operation
```

**Solution**: Have a Global Administrator grant admin consent in Azure AD.

### Missing Required Permissions
```
Error: Authorization_RequestDenied
```

**Solution**: Verify both `CopilotPackages.Read.All` and `Mail.Send` permissions are added and consented.

## Alternative: Certificate-Based Authentication

If secrets are not preferred, you can use certificate authentication:

1. Create self-signed certificate:
   ```powershell
   $cert = New-SelfSignedCertificate -Subject "CN=CopilotInventory" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature
   ```

2. Upload to Azure AD app registration
3. Modify script to use certificate instead of secret

## Security Best Practices

✅ **DO:**
- Rotate client secrets every 6-12 months
- Use minimum required permissions
- Store secrets in Azure Key Vault for production
- Use managed identity when running in Azure

❌ **DON'T:**
- Commit `.env` to source control
- Share secrets via email or chat
- Use the same service principal for multiple purposes
- Grant more permissions than needed

## References

- [Microsoft Graph Application Permissions](https://learn.microsoft.com/graph/permissions-reference)
- [Service Principal Authentication](https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands)
- [Copilot Package Management API](https://learn.microsoft.com/graph/api/resources/copilotadmin-copilotadmin)
