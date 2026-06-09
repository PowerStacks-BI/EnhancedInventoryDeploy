# Enhanced Inventory Deploy (Log Ingestion API)

This repository provides a **one-click Azure deployment** that sets up the required Azure resources for **PowerStacks Enhanced Inventory** using the **Azure Monitor Logs Ingestion API**.

The deployment creates (or reuses) a **Log Analytics Workspace**, configures required **custom tables**, and sets up the **Data Collection Endpoint (DCE)** and **Data Collection Rule (DCR)** used by the Enhanced Inventory Windows and macOS inventory scripts.

---

## 🚀 Deploy to Azure

Click the button below to deploy the required Azure resources:

<p>
  <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fpowerstacks-corp%2FEnhancedInventoryDeploy%2Fmain%2Finfra%2Fmain.json">
    <img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure">
  </a>
</p>

> ⚠️ **Important**  
> Before clicking **Deploy to Azure**, review the **Prerequisites** section below.  
> One required value must be obtained from the Azure portal.

---

## What this deployment sets up

- Log Analytics Workspace (new or existing)
- Custom Log Analytics tables:
  - `PowerStacksDeviceInventory_CL`
  - `PowerStacksAppInventory_CL`
  - `PowerStacksDriverInventory_CL`
  - `PowerStacksAppUsage_CL`
- Data Collection Endpoint (DCE)
- Data Collection Rule (DCR) with one stream per table
- Outputs required by the inventory scripts:
  - **DCE Logs Ingestion URI**
  - **DCR Immutable ID**

See [Custom table schemas](#custom-table-schemas) below for the column layout of each table.

---

## Prerequisites (Required Before Deployment)

### 1. Create an Entra ID application

You must create an **Entra ID App Registration** that will be used by the Enhanced Inventory scripts to authenticate to Azure.

From the app registration, record:
- **Tenant ID**
- **Application (Client) ID**
- **Client Secret**

These values are used **by the inventory scripts**, not by the Azure deployment itself.

---

### 2. Copy the *Enterprise Application Object ID* (Required for RBAC)

The Azure deployment needs the **Object ID of the Enterprise Application (service principal)** so it can automatically assign permissions to the Data Collection Rule.

> ⚠️ This is **NOT** the Application (Client) ID.

#### How to find it in the Azure portal

1. Go to **https://entra.microsoft.com**
2. Navigate to **Applications → Enterprise applications**
3. Locate the application you created for Enhanced Inventory
   - You may search by **name** or filter by **Application ID**
4. Open the application and copy the **Object ID** from the Overview page

This value will be entered in the deployment wizard as:

**Enterprise App Object Id**

---

## Required permissions

### Azure permissions
The user deploying the template must be:
- **Owner**, or
- **Contributor + User Access Administrator**

### Entra ID permissions
The user creating the app registration must be able to:
- Create app registrations
- View Enterprise Applications

---

## Deployment options

### Option 1: Create a new Log Analytics workspace
Choose **Create a new workspace** and provide a workspace name.

### Option 2: Use an existing Log Analytics workspace
Choose **Use an existing workspace** and provide:
- Subscription ID
- Resource group name
- Workspace name

> This is commonly used when deploying alongside **Windows Update for Business Reports** or other shared workspaces.

---

## Deployment wizard input summary

During deployment you will be prompted for:

- Workspace selection (new or existing)
- Workspace details (if using existing)
- **Enterprise App Object Id** (recommended)

> If the **Enterprise App Object Id** is provided:
> - The deployment automatically assigns the required **Monitoring Metrics Publisher** role to the DCR  
> - No manual RBAC steps are required after deployment

If the field is left blank, permissions must be assigned manually.

---

## After deployment

From the **Deployment Outputs**, copy the following values:

- **DceURI**
- **DcrImmutableId**

These values are required by the Windows and macOS inventory scripts.

---

## Configure inventory scripts

### Windows
Configure the following settings in the Windows inventory script:

- `LogAPIMode = LogIngestionAPI`
- `TenantId`
- `ClientId`
- `ClientSecret`
- `DceURI`
- `DcrImmutableId`

### macOS
Configure the same values in the macOS inventory script:

- `LogAPIMode = LogIngestionAPI`
- `TenantId`
- `ClientId`
- `ClientSecret`
- `DceURI`
- `DcrImmutableId`

### App Usage collector

The `PowerStacksAppUsage_CL` table is populated by a separate Windows-only collector that reads the local SRUM database to track per-(user, app) usage. It uses the same DCE URI, DCR immutable ID, and Entra app registration as the inventory scripts, so once those values are captured from the deployment output no additional Azure configuration is needed.

The collector is shipped from the private `intune-app-usage` repository to customers who have licensed the app usage feature. Customers do not need to do anything in this repository to enable it beyond running the standard deployment.

---

## Verify the deployment (Optional)

Use the validation script:

- `LogIngestionAPI_CheckDCR_v2.0`

This script retrieves and displays the full DCR configuration and is useful for troubleshooting ingestion issues.

---

## Custom table schemas

All four tables share a common identity header (`TimeGenerated`, `ComputerName_s`, `ManagedDeviceID_g`). Each table also carries the data specific to its inventory type.

### PowerStacksDeviceInventory_CL

| Column | Type |
|---|---|
| `TimeGenerated` | datetime |
| `ComputerName_s` | string |
| `ManagedDeviceID_g` | string (GUID) |
| `Microsoft365_b` | boolean |
| `Warranty_b` | boolean |
| `DeviceDetails1_s` ... `DeviceDetails10_s` | string |

The ten `DeviceDetails` slots carry inventory payloads serialized by the Windows / macOS inventory scripts. Each slot can hold up to the LAW string column limit (~32 KB).

### PowerStacksAppInventory_CL

| Column | Type |
|---|---|
| `TimeGenerated` | datetime |
| `ComputerName_s` | string |
| `ManagedDeviceID_g` | string (GUID) |
| `InstalledApps1_s` ... `InstalledApps10_s` | string |

Same slot convention as device inventory. Each `InstalledApps` slot holds a chunk of the installed-application list.

### PowerStacksDriverInventory_CL

| Column | Type |
|---|---|
| `TimeGenerated` | datetime |
| `ComputerName_s` | string |
| `ManagedDeviceID_g` | string (GUID) |
| `ListedDrivers1_s` ... `ListedDrivers10_s` | string |

Same slot convention. Each `ListedDrivers` slot holds a chunk of the driver list.

### PowerStacksAppUsage_CL

| Column | Type | Description |
|---|---|---|
| `TimeGenerated` | datetime | Ingestion timestamp. |
| `ComputerName_s` | string | Device hostname. |
| `ManagedDeviceID_g` | string (GUID) | Intune managed device ID. Joins to `PowerStacksDeviceInventory_CL`. |
| `UserSid_s` | string | Raw Windows SID of the user the row is attributed to. |
| `UserSidType_s` | string | One of `CloudOnly`, `Hybrid`, `System`, `Service`, `Unknown`. |
| `AadUserId_g` | string (GUID) | Microsoft Entra object ID. Decoded from the SID locally for cloud-only users. Populated from `dsregcmd` for the currently signed-in hybrid user. Empty for unloaded hybrid profiles and for service accounts. |
| `UPN_s` | string | User principal name resolved from the IdentityStore cache. |
| `UserName_s` | string | Local user name. |
| `ResolvedAppName_s` | string | Add/Remove Programs display name when the exe could be resolved, otherwise empty. |
| `Publisher_s` | string | Add/Remove Programs publisher when known. |
| `ProductCode_g` | string (GUID) | MSI product code when the exe maps to an MSI-installed product. |
| `ExeInfo_s` | string | Exe basename for Win32 rows, or the SRUM-decorated AppX identifier for UWP rows. |
| `ResolutionSource_s` | string | One of `ARP`, `ARP (ambiguous)`, `UWP`, `None`. Indicates how the exe was resolved. |
| `LastUsedTime` | datetime | Most recent time the user touched the app (high-water mark; never regresses). |
| `FirstSeen` | datetime | First time this (user, app) ledger entry was written. |
| `InFocusSeconds` | integer | Accumulated in-focus or tracked-activity time. |

The `PowerStacksAppUsage_CL` schema is per-(user, app) rather than per-device, because app usage is a user-attributable signal. The collector that produces these rows lives in the private `intune-app-usage` repository and uses the Windows SRUM database as its source.

Typical query patterns:

```kql
// Per-app usage rollup across all users, last 30 days
PowerStacksAppUsage_CL
| where LastUsedTime > ago(30d)
| where isnotempty(ResolvedAppName_s)
| summarize total = sum(InFocusSeconds), last = max(LastUsedTime) by ResolvedAppName_s

// License reclamation candidates: users who haven't touched an app in 90 days
PowerStacksAppUsage_CL
| where ResolvedAppName_s == "Microsoft 365 Apps for enterprise - en-us"
| where UserSidType_s in ("CloudOnly", "Hybrid")
| summarize last = max(LastUsedTime) by AadUserId_g, UPN_s
| where last < ago(90d)
```

---

## Repository contents

- `infra/main.bicep` – Source Bicep template
- `infra/main.json` – Compiled ARM template used by the portal
- `infra/createUiDefinition.json` – Custom UI definition (used for managed app scenarios)

---

## Support

For questions or issues:
- Open an issue in this repository
- Or contact **PowerStacks Support**
